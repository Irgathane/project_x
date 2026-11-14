#!/usr/bin/env python3
"""Fix inside-out brushes in a Quake .map: reverse each face's point order.

Symptom this fixes:
    qbsp: "*** WARNING 09: Couldn't create brush faces" for EVERY brush,
    then "0 brushes / 0 planes", then no .bsp is written.

Cause: a Quake face's three points must be wound so the plane normal points
*out* of the solid. Some generators emit the mathematically conventional
counter-clockwise order, which ericw-tools' qbsp reads as inward-facing: every
face of every brush is discarded, so brushes vanish.

Usage:
    python3 tools/fix_map_winding.py slipgate/maps/starter.map            # rewrite in place
    python3 tools/fix_map_winding.py map.map --out fixed.map              # keep the original
    python3 tools/fix_map_winding.py slipgate/maps/starter.map --print    # count faces only

Reversing a fixed file back produces a broken map again, so verify with a qbsp
run: the fix is correct when "Couldn't create brush faces" disappears.
"""
import argparse
import re
import sys
from pathlib import Path

# ( x y z ) ( x y z ) ( x y z ) texture rest...
FACE = re.compile(
    r"^\(\s*(-?[\d.]+)\s+(-?[\d.]+)\s+(-?[\d.]+)\s*\)"
    r"\s*\(\s*(-?[\d.]+)\s+(-?[\d.]+)\s+(-?[\d.]+)\s*\)"
    r"\s*\(\s*(-?[\d.]+)\s+(-?[\d.]+)\s+(-?[\d.]+)\s*\)"
    r"\s*(\S+.*)$"
)


def reverse_faces(text: str) -> tuple[str, int]:
    out, n = [], 0
    for line in text.splitlines():
        m = FACE.match(line.strip())
        if m:
            g = m.groups()
            p1 = f"( {g[0]} {g[1]} {g[2]} )"
            p2 = f"( {g[3]} {g[4]} {g[5]} )"
            p3 = f"( {g[6]} {g[7]} {g[8]} )"
            out.append(f"{p1} {p3} {p2} {g[9]}")  # swap 2nd and 3rd point
            n += 1
        else:
            out.append(line)
    return "\n".join(out) + "\n", n


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("map", type=Path)
    ap.add_argument("--out", type=Path, help="write here instead of in place")
    ap.add_argument("--print", dest="dry", action="store_true", help="count faces, write nothing")
    args = ap.parse_args()

    if not args.map.is_file():
        sys.exit(f"ERROR: {args.map} not found")
    fixed, n = reverse_faces(args.map.read_text())

    if args.dry:
        print(f"{args.map}: {n} face lines would be reversed")
        return

    dest = args.out or args.map
    if dest == args.map:
        args.map.with_suffix(args.map.suffix + ".orig").write_text(args.map.read_text())
        print(f"backup -> {args.map.name}.orig")
    dest.write_text(fixed)
    print(f"{dest}: reversed {n} face lines")
    print("verify: qbsp -wadpath . %s   (the 'Couldn't create brush faces' warnings must be gone)" % dest.name)


if __name__ == "__main__":
    main()