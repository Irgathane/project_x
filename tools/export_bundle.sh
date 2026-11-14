#!/usr/bin/env bash
# export_bundle.sh — pack this project for carrying to another machine (USB stick).
#
# Creates, in the output directory:
#   project_x-src.tar.gz   working tree (tracked + untracked-not-ignored), no git history
#   id1.tar.gz             LibreQuake game data (242 MB, not in git)
#   assests-packs.tar.gz   the original art archives (92 MB, not in git)
#   setup-machine.sh       the installer to run on the target machine
#   SHA256SUMS.txt         integrity check
#   README-MIGRATION.txt   how to use the bundle
#
# The engine is NOT packed: it must be built on the target (different GPU/driver),
# and its build dir is ~1 GB of objects that are meaningless elsewhere.
#
# Usage:
#   ./tools/export_bundle.sh /media/$USER/USBSTICK
#   ./tools/export_bundle.sh /media/$USER/USBSTICK --no-engine     # smaller, engine gets cloned
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT="${1:-}"
WITH_ENGINE=1
[[ "${2:-}" == "--no-engine" ]] && WITH_ENGINE=0

if [[ -z "$OUT" ]]; then
    echo "usage: $0 <output-dir-on-usb> [--no-engine]" >&2
    exit 2
fi
mkdir -p "$OUT"
OUT="$(cd "$OUT" && pwd)"

say() { printf '\n\033[1m== %s\033[0m\n' "$*"; }
size() { du -sh "$1" | cut -f1; }

say "packing code (git working tree, no history, no ignored files)"
mapfile -d '' FILES < <(git -C "$ROOT" ls-files -z; git -C "$ROOT" ls-files -z --others --exclude-standard)
tar -czf "$OUT/project_x-src.tar.gz" -C "$ROOT" --null -T <(printf '%s\0' "${FILES[@]}")
echo "  project_x-src.tar.gz  $(size "$OUT/project_x-src.tar.gz")  (${#FILES[@]} files)"

if [[ -d "$ROOT/id1" ]]; then
    say "packing game data (LibreQuake id1)"
    tar -czf "$OUT/id1.tar.gz" -C "$ROOT" id1
    echo "  id1.tar.gz            $(size "$OUT/id1.tar.gz")"
else
    echo "WARNING: no id1/ directory — the target machine will have no game data" >&2
fi

if compgen -G "$ROOT/assests/*.rar" > /dev/null; then
    say "packing original art archives"
    # --exclude work/: that is extraction scratch (~250 MB of PNGs), rebuildable
    # locally with tools/extract_packs.py and deliberately not carried around.
    tar -czf "$OUT/assests-packs.tar.gz" -C "$ROOT" --exclude='assests/work' assests
    echo "  assests-packs.tar.gz  $(size "$OUT/assests-packs.tar.gz")"
fi

if (( WITH_ENGINE )); then
    say "packing vkQuake source (build dir excluded)"
    tar -czf "$OUT/vkQuake-src.tar.gz" -C "$ROOT" --exclude='vkQuake/build' vkQuake
    echo "  vkQuake-src.tar.gz    $(size "$OUT/vkQuake-src.tar.gz")"
fi

# User-level pi config (context-management policy). The GitHub PAT is deliberately
# NOT packed: it is a secret, copy it by hand from ~/.pi/agent/.github_pat.
if [[ -f "$HOME/.pi/agent/instructions.md" ]]; then
    say "packing pi agent config"
    cp "$HOME/.pi/agent/instructions.md" "$OUT/agent-instructions.md"
    echo "  agent-instructions.md (copy to ~/.pi/agent/instructions.md)"
    echo "  NOT packed: .github_pat — copy it yourself, mode 600"
fi

say "packing installer"
cp "$ROOT/tools/setup-machine.sh" "$OUT/setup-machine.sh"
chmod +x "$OUT/setup-machine.sh"

say "writing manifest"
cat > "$OUT/README-MIGRATION.txt" <<'TXT'
project_x — migration bundle
============================

Everything here is either source or third-party data. Nothing is generated:
the engine, progs.dat and the .bsp are rebuilt on the target machine.

On the NEW machine (antiX / Debian, sysvinit is fine):

  1. mount the stick, e.g.  udisksctl mount -b /dev/sdX1
  2. cd /media/<user>/<stick>
  3. sha256sum -c SHA256SUMS.txt
  4. ./setup-machine.sh --bundle "$PWD"

The installer will:
  - apt-install build + runtime dependencies (gcc, meson, ninja, SDL3, Vulkan, PIL, fteqcc…)
  - install the LunarG Vulkan SDK into ~/VulkanSDK (Debian's loaders are too old)
  - unpack the code to ~/Desktop/project_x
  - unpack id1/ and the art archives
  - fetch + install ericw-tools (qbsp/vis/light)
  - build vkQuake from source
  - compile progs.dat (and stamp the ABI crc), verify the ABI layout
  - compile starter.bsp (qbsp/vis/light)
  - run a GPU/Vulkan sanity check

Then:  cd ~/Desktop/project_x && ./slipgate/launch.sh

Notes
  * The engine is deliberately not packed: it is machine-specific (GPU driver,
    shader compiler) and its build tree is ~1 GB. Rebuilding takes ~5 minutes.
  * id1.tar.gz (242 MB) and assests-packs.tar.gz (92 MB) are not in git because
    of size and third-party licensing. Copy them, don't commit them.
  * Your GitHub repo has the code; you only need the USB stick for the big data.
    If the target has internet + your SSH key, you can skip project_x-src.tar.gz
    and instead:  git clone git@github.com:Irgathane/project_x.git
TXT

say "checksums"
( cd "$OUT"
  shopt -s nullglob
  files=( *.tar.gz setup-machine.sh README-MIGRATION.txt agent-instructions.md )
  sha256sum "${files[@]}" > SHA256SUMS.txt
)
cat "$OUT/SHA256SUMS.txt"

say "done — bundle in $OUT"
du -sh "$OUT"