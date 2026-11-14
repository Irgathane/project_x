#!/usr/bin/env bash
# setup-machine.sh — provision a fresh Debian/antiX machine for the slipgate mod.
#
# Works with sysvinit (antiX): nothing here assumes systemd.
#
#   ./setup-machine.sh --bundle /media/user/STICK     # from a USB bundle
#   ./setup-machine.sh --git git@github.com:you/project_x.git
#   ./setup-machine.sh --deps-only                    # just install packages
#
# Exit codes: 0 ok, 1 a build step failed, 2 usage/environment problem.
set -euo pipefail

SDK_VERSION="1.4.363.1"
SDK_DIR="$HOME/VulkanSDK/$SDK_VERSION"
SDK_URL="https://sdk.lunarg.com/sdk/download/latest/linux/vulkan-sdk.tar.xz"
ENGINE_REPO="https://github.com/Novum/vkQuake.git"
ENGINE_COMMIT="308ff19d"   # the revision this project was validated against (1.37.x)
ERICW_VERSION="v0.18.1"
ERICW_URL="https://github.com/ericwa/ericw-tools/releases/download/${ERICW_VERSION}/ericw-tools-${ERICW_VERSION}-Linux.zip"
TARGET="$HOME/Desktop/project_x"

BUNDLE=""; GIT_URL=""; DEPS_ONLY=0; NO_APT=0
while [[ $# -gt 0 ]]; do
    case "$1" in
        --bundle) BUNDLE="${2:-}"; shift 2 ;;
        --git)    GIT_URL="${2:-}"; shift 2 ;;
        --target) TARGET="${2:-}"; shift 2 ;;
        --no-apt) NO_APT=1; shift ;;
        --deps-only) DEPS_ONLY=1; shift ;;
        -h|--help) sed -n '2,12p' "$0"; exit 0 ;;
        *) echo "unknown arg: $1" >&2; exit 2 ;;
    esac
done

say()  { printf '\n\033[1m== %s\033[0m\n' "$*"; }
warn() { printf '\033[33mWARN: %s\033[0m\n' "$*" >&2; }
die()  { printf '\033[31mERROR: %s\033[0m\n' "$*" >&2; exit 1; }

[[ -f /etc/debian_version ]] || warn "not a Debian-family system; apt steps may fail"

say "environment"
echo "  distro : $(. /etc/os-release 2>/dev/null && echo "${PRETTY_NAME:-unknown}")"
echo "  init   : $(ps -p 1 -o comm= 2>/dev/null || echo unknown)"
echo "  arch   : $(uname -m)   kernel: $(uname -r)"
echo "  target : $TARGET"
[[ "$(uname -m)" == "x86_64" ]] || die "vkQuake needs a 64-bit x86 system"

SUDO=""
if [[ $EUID -ne 0 ]]; then
    command -v sudo >/dev/null || die "need root or sudo to install packages"
    SUDO="sudo"
fi

say "installing packages (apt)"
if (( NO_APT )); then
    echo "  skipped (--no-apt)"
    SUDO=""
else
$SUDO apt-get update -qq
$SUDO apt-get install -y --no-install-recommends \
    build-essential git meson ninja-build pkg-config python3 python3-pil \
    glslang-tools spirv-tools libsdl3-dev libvulkan-dev \
    libvorbis-dev libmpg123-dev libx11-xcb-dev libflac-dev libopusfile-dev \
    libarchive-tools unzip curl ca-certificates \
    vulkan-tools mesa-vulkan-drivers \
    || warn "some packages failed to install — check the names against your release"

# fteqcc is packaged in Debian; fall back to a clear message if not.
if ! command -v fteqcc >/dev/null; then
    $SUDO apt-get install -y fteqcc || warn "fteqcc unavailable in apt — get it from https://fte.triptohell.info/"
fi
fi

(( DEPS_ONLY )) && { say "dependencies installed"; exit 0; }

say "Vulkan SDK"
if [[ -d "$SDK_DIR" ]]; then
    echo "  already present: $SDK_DIR"
else
    echo "  downloading $(basename "$SDK_URL") (~350 MB)…"
    tmp="$(mktemp -d)"
    curl -L --fail --progress-bar -o "$tmp/sdk.tar.xz" "$SDK_URL" || die "SDK download failed"
    mkdir -p "$HOME/VulkanSDK"
    tar -xJf "$tmp/sdk.tar.xz" -C "$HOME/VulkanSDK" || die "SDK extraction failed"
    rm -rf "$tmp"
    [[ -d "$SDK_DIR" ]] || SDK_DIR="$(find "$HOME/VulkanSDK" -maxdepth 1 -mindepth 1 -type d | sort | tail -1)"
    echo "  installed: $SDK_DIR"
fi
# The SDK's setup-env.sh derives VULKAN_SDK from BASH_SOURCE, which resolves to the
# caller under `eval` — so its paths silently point at the wrong directory. Set them
# explicitly instead (mirrors what the SDK script does).
sdk_env() {
    cat <<ENV
export VULKAN_SDK="$SDK_DIR/x86_64"
export PATH="$SDK_DIR/x86_64/bin:\$PATH"
export PKG_CONFIG_PATH="$SDK_DIR/x86_64/lib/VulkanLoader/lib/pkgconfig:$SDK_DIR/x86_64/share/pkgconfig:$SDK_DIR/x86_64/lib/pkgconfig:\${PKG_CONFIG_PATH:-}"
export LD_LIBRARY_PATH="$SDK_DIR/x86_64/lib/VulkanLoader/lib:$SDK_DIR/x86_64/lib:\${LD_LIBRARY_PATH:-}"
ENV
}

say "source code"
if [[ -n "$BUNDLE" ]]; then
    [[ -f "$BUNDLE/project_x-src.tar.gz" ]] || die "no project_x-src.tar.gz in $BUNDLE"
    mkdir -p "$TARGET"
    tar -xzf "$BUNDLE/project_x-src.tar.gz" -C "$TARGET"
    echo "  unpacked bundle -> $TARGET"
elif [[ -n "$GIT_URL" ]]; then
    if [[ -d "$TARGET/.git" ]]; then
        git -C "$TARGET" pull --ff-only
    else
        mkdir -p "$(dirname "$TARGET")"
        git clone "$GIT_URL" "$TARGET"
    fi
    echo "  cloned -> $TARGET"
elif [[ -f ./progs.src || -d ./slipgate ]]; then
    TARGET="$(pwd)"
    echo "  running inside an existing checkout: $TARGET"
else
    die "pass --bundle DIR or --git URL (or run from the project root)"
fi
cd "$TARGET"
[[ -d slipgate/qc ]] || die "$TARGET does not look like project_x (slipgate/qc missing)"
chmod +x slipgate/*.sh tools/*.sh 2>/dev/null || true

if [[ -n "$BUNDLE" && -f "$BUNDLE/id1.tar.gz" ]]; then
    say "game data (id1)"
    tar -xzf "$BUNDLE/id1.tar.gz" -C "$TARGET"
    echo "  id1/ unpacked ($(du -sh id1 | cut -f1))"
elif [[ ! -d id1 ]]; then
    warn "no id1/ — the game will not run until you provide LibreQuake (see assests/README.md)"
fi

if [[ -n "$BUNDLE" && -f "$BUNDLE/assests-packs.tar.gz" ]]; then
    say "art archives"
    tar -xzf "$BUNDLE/assests-packs.tar.gz" -C "$TARGET"
    echo "  assests/ restored"
fi

if [[ ! -d vkQuake/src && ! -f vkQuake/meson.build ]]; then
    if [[ -n "$BUNDLE" && -f "$BUNDLE/vkQuake-src.tar.gz" ]]; then
        say "engine source (from bundle)"
        tar -xzf "$BUNDLE/vkQuake-src.tar.gz" -C "$TARGET"
        echo "  vkQuake/ unpacked"
    else
        say "engine source (clone $ENGINE_REPO @ $ENGINE_COMMIT)"
        git clone "$ENGINE_REPO" vkQuake || die "could not clone vkQuake; re-export the bundle with the engine included"
        git -C vkQuake checkout "$ENGINE_COMMIT" || warn "could not check out $ENGINE_COMMIT — building HEAD instead"
        echo "  vkQuake/ at $(git -C vkQuake rev-parse --short HEAD)"
    fi
else
    say "engine source"
    echo "  already present: $TARGET/vkQuake"
fi

say "ericw-tools (qbsp/vis/light)"
if command -v qbsp >/dev/null; then
    echo "  already on PATH: $(command -v qbsp)"
else
    tmp="$(mktemp -d)"
    curl -L --fail -o "$tmp/ericw.zip" "$ERICW_URL" || warn "ericw-tools download failed; map compile will be skipped"
    if [[ -s "$tmp/ericw.zip" ]]; then
        $SUDO rm -rf /opt/ericw-tools && $SUDO mkdir -p /opt/ericw-tools
        $SUDO unzip -q "$tmp/ericw.zip" -d /opt/ericw-tools
        BIN="$(dirname "$(find /opt/ericw-tools -name qbsp -type f | head -1)")"
        for t in qbsp vis light; do $SUDO ln -sf "$BIN/$t" "/usr/local/bin/$t"; done
        echo "  installed to $BIN (symlinked into /usr/local/bin)"
    fi
    rm -rf "$tmp"
fi

say "GPU / Vulkan check"
if command -v vulkaninfo >/dev/null; then
    vulkaninfo --summary 2>/dev/null | sed -n '/GPU0:/,/^$/p;/deviceName/p;/apiVersion/p' | head -12 || true
    if ! vulkaninfo --summary 2>/dev/null | grep -qi "deviceName"; then
        warn "no Vulkan device found. vkQuake requires Vulkan 1.1+; the mod will not run."
        warn "On old GPUs try: $SUDO apt install mesa-vulkan-drivers (installed) and check dmesg for driver load."
    fi
fi

say "building vkQuake (this takes a few minutes)"
eval "$(sdk_env)"
if [[ ! -f vkQuake/build/build.ninja ]]; then
    ( cd vkQuake && meson setup build ) || die "meson setup failed"
fi
( cd vkQuake && ninja -C build ) || die "engine build failed"
[[ -x vkQuake/build/vkquake ]] || die "vkquake binary not produced"
echo "  built: $TARGET/vkQuake/build/vkquake"

say "compiling QuakeC"
( cd slipgate/qc && fteqcc progs.src ) || die "fteqcc failed — see errors above"
python3 tools/check_abi.py || die "messages above: defs.qc ABI layout is broken; fix before playing"
python3 tools/fix_progs_crc.py slipgate/qc/progs.dat
cp slipgate/qc/progs.dat slipgate/progs.dat
echo "  slipgate/progs.dat -> $(ls -l slipgate/progs.dat | awk '{print $5}') bytes"

say "compiling map"
if command -v qbsp >/dev/null; then
    ( cd slipgate/maps && qbsp -wadpath . starter.map >/dev/null && vis starter.bsp >/dev/null && light -extra4 starter.bsp >/dev/null ) \
        && echo "  slipgate/maps/starter.bsp -> $(ls -l slipgate/maps/starter.bsp | awk '{print $5}') bytes" \
        || warn "map build failed — run it by hand to see why"
else
    warn "qbsp not available; skipping map build"
fi

say "ready"
cat <<EOF
  launch:   cd "$TARGET" && ./slipgate/launch.sh
  rebuild:  ./slipgate/launch.sh            (add args: ./slipgate/launch.sh <mapname>)

  If the mouse feels inverted, edit slipgate/autoexec.cfg (m_pitch / m_yaw).
  If the game is slow, your GPU may be on llvmpipe software rendering:
      vulkaninfo --summary | grep -i deviceName
EOF