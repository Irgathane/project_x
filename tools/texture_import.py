#!/usr/bin/env python3
"""Bring a texture from an extracted pack into slipgate/textures/ as a PNG override.

vkQuake loads external textures before WAD textures (Quake/gl_model.c):
    textures/<mapname>/<texname>   then   textures/<texname>
so a full-color `slipgate/textures/sg_brick.png` overrides the WAD lump named
`sg_brick` with no QuakeC or map rebuild. Use this instead of rebuilding the WAD.

Usage:
    python3 tools/texture_import.py --list                       # inventory of extracted packs
    python3 tools/texture_import.py <src.png> sg_metal           # import one texture
    python3 tools/texture_import.py <src.png> sg_metal --resize 256
    python3 tools/texture_import.py --check                      # validate slipgate/textures/

Rules enforced:
  * square, power-of-two dimensions (16..1024); --resize rescales instead of failing
  * texture names are lowercase [a-z0-9_] and should be prefixed sg_
  * CREDITS.md is never auto-edited: the license row is printed for you to paste
"""
import argparse
import re
import shutil
import sys
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parent.parent
WORK = ROOT / "assests" / "work"
DEST = ROOT / "slipgate" / "textures"
NAME_RE = re.compile(r"^[a-z][a-z0-9_]{1,15}$")  # 16-char WAD lump limit
POT = {1 << n for n in range(4, 11)}  # 16..1024


def pow2_issue(w: int, h: int) -> str | None:
    if w != h:
        return f"not square ({w}x{h})"
    if w not in POT:
        return f"not a power of two ({w})"
    return None


def cmd_list() -> None:
    if not WORK.is_dir():
        sys.exit(f"No extracted packs yet. Run: python3 tools/extract_packs.py")
    for pack in sorted(p for p in WORK.iterdir() if p.is_dir()):
        pngs = sorted(pack.rglob("*.png"))
        print(f"\n## {pack.name}  ({len(pngs)} png)")
        for p in pngs[:40]:
            try:
                with Image.open(p) as im:
                    flag = "" if not pow2_issue(*im.size) else f"  <-- {pow2_issue(*im.size)}"
                    print(f"   {p.relative_to(pack)}  {im.size[0]}x{im.size[1]}{flag}")
            except Exception:
                print(f"   {p.relative_to(pack)}  UNREADABLE ({p.stat().st_size} bytes) — re-run extract_packs.py")
        if len(pngs) > 40:
            print(f"   ... {len(pngs) - 40} more")


def cmd_check() -> None:
    bad = 0
    for p in sorted(DEST.glob("*.png")):
        with Image.open(p) as im:
            issue = pow2_issue(*im.size)
            name_ok = bool(NAME_RE.match(p.stem))
            status = "ok"
            if issue:
                status = issue
                bad += 1
            elif not name_ok:
                status = "bad name (want lowercase sg_*, <=16 chars)"
                bad += 1
            print(f"{p.name:24} {im.size[0]}x{im.size[1]:<5} {status}")
    print(f"\n{len(list(DEST.glob('*.png')))} textures, {bad} with problems")
    sys.exit(1 if bad else 0)


def cmd_import(src: Path, name: str, resize: int | None, credits: str | None) -> None:
    if not src.is_file():
        sys.exit(f"ERROR: {src} not found")
    name = name.lower()
    if not NAME_RE.match(name):
        sys.exit(f"ERROR: '{name}' must be lowercase [a-z0-9_], <=16 chars (WAD lump limit)")

    with Image.open(src) as im:
        im = im.convert("RGBA")
        issue = pow2_issue(*im.size)
        if issue:
            if not resize:
                sys.exit(f"ERROR: {issue}. Re-run with --resize {im.size[0]} to fix, or use a 256x256 source.")
            im = im.resize((resize, resize), Image.LANCZOS)
            issue2 = pow2_issue(*im.size)
            if issue2:
                sys.exit(f"ERROR: --resize {resize} is not square power-of-two (16/32/64/128/256/512/1024)")
            print(f"resized -> {resize}x{resize} (was {'x'.join(map(str, Image.open(src).size))})")

        DEST.mkdir(parents=True, exist_ok=True)
        out = DEST / f"{name}.png"
        im.save(out, "PNG", optimize=True)

    print(f"wrote {out.relative_to(ROOT)}  ({out.stat().st_size // 1024} KiB)")
    print("\nNo map or QC rebuild needed: vkQuake prefers .png over the WAD lump.")
    print("Verify in-game with: r_showimages 1  (or just look at the wall)")
    if credits:
        parts = [c.strip() for c in credits.split("|")]
        parts += [""] * (5 - len(parts))
        print("\nPaste this row into the table in slipgate/CREDITS.md:")
        print(f"| {parts[0]} | {parts[1]} | {parts[2]} | {parts[3]} | {parts[4]} |")


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("src", nargs="?", type=Path, help="source png from assests/work/")
    ap.add_argument("name", nargs="?", help="target texture name, e.g. sg_metal")
    ap.add_argument("--resize", type=int, help="resize to this square power-of-two size")
    ap.add_argument("--credits", help='"Pack|Author|Link|License|Used for" row to print')
    ap.add_argument("--list", action="store_true", help="inventory extracted packs")
    ap.add_argument("--check", action="store_true", help="validate slipgate/textures/")
    args = ap.parse_args()

    if args.list:
        cmd_list()
    elif args.check:
        cmd_check()
    elif args.src and args.name:
        cmd_import(args.src, args.name, args.resize, args.credits)
    else:
        ap.print_help()


if __name__ == "__main__":
    main()