#!/bin/sh
# Launch vkQuake built from source, with the slipgate mod and LibreQuake id1 data.
#   basedir = repo root  ->  ./id1 (game data)  ./slipgate (mod, progs.dat)
set -e
cd "$(dirname "$0")/.."

SDK="${HOME}/VulkanSDK/1.4.363.1"
VK=./vkQuake/build/vkquake

if [ ! -x "$VK" ]; then
    echo "Engine not built. Run:" >&2
    echo "  (cd vkQuake && meson setup build && ninja -C build)" >&2
    exit 1
fi
if [ ! -d ./id1 ]; then
    echo "Missing ./id1 game data (LibreQuake). See assests/README.md." >&2
    exit 1
fi

# Explicit SDK paths: setup-env.sh resolves against BASH_SOURCE, which is wrong
# when it is sourced from a script rather than entered by hand.
if [ -d "$SDK/x86_64/lib" ]; then
    LD_LIBRARY_PATH="$SDK/x86_64/lib/VulkanLoader/lib:$SDK/x86_64/lib:${LD_LIBRARY_PATH:-}"
    export LD_LIBRARY_PATH
fi

exec "$VK" -game slipgate +map "${1:-starter}"