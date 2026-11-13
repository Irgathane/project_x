#!/bin/sh
# Launch vkQuake built from source (../vkQuake/build/vkquake) with the LunarG SDK runtime.
cd "$(dirname "$0")/.." || exit 1
SDK="${HOME}/VulkanSDK/1.4.363.1"

if [ -x ./vkQuake/build/vkquake ]; then
  VK=./vkQuake/build/vkquake
  LD_LIBRARY_PATH="${SDK}/x86_64/lib:${LD_LIBRARY_PATH:-}" exec "$VK" -game slipgate +map starter
elif command -v vkquake >/dev/null 2>&1; then
  exec vkquake -game slipgate +map starter
else
  echo "Build the engine first: (cd vkQuake && meson setup build && ninja -C build)"
  exit 1
fi
