#!/bin/sh
# SLIPGATE KIT BUILD (Linux)
cd "$(dirname "$0")" || exit 1
echo "=== SLIPGATE KIT BUILD ==="

QCC=fteqcc
if ! command -v fteqcc >/dev/null 2>&1; then
  if [ -x tools/fteqcc ]; then QCC=tools/fteqcc; else
    echo "[!] fteqcc not found. Put it in tools/ or add it to PATH."
    echo "    Download: https://www.fteqcc.org/"
    exit 1
  fi
fi

(cd qc && "$QCC" progs.src) || exit 1
cp qc/progs.dat progs.dat || exit 1
echo "[ok] progs.dat built"

if ! command -v qbsp >/dev/null 2>&1; then
  echo "[skip] qbsp not in PATH - map not compiled."
  echo "       ericw-tools: https://github.com/ericwa/ericw-tools/releases"
else
  (cd maps && qbsp -wadpath . starter.map && vis starter.bsp && light starter.bsp) || exit 1
  echo "[ok] starter.bsp built"
fi
echo "Done. Run ./launch.sh"
