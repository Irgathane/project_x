#!/usr/bin/env python3
"""Unpack the itch.io asset packs (RAR/ZIP) into assests/work/<pack>/.

Usage:
    python3 tools/extract_packs.py                # extract all packs found in assests/
    python3 tools/extract_packs.py --list         # just show what's inside
    python3 tools/extract_packs.py "Tiny Texture Pack 2"   # one pack (substring match)

Original archives are never modified. Output goes to assests/work/ which is
gitignored, so extracted art never lands in the repo.
"""
import argparse
import shutil
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SRC = ROOT / "assests"
OUT = SRC / "work"
EXTS = {".rar", ".zip", ".7z"}


def find_packs(pattern: str | None) -> list[Path]:
    packs = sorted(p for p in SRC.iterdir() if p.suffix.lower() in EXTS)
    if pattern:
        needle = pattern.lower()
        packs = [p for p in packs if needle in p.name.lower()]
    return packs


def tools_for(pack: Path) -> list[tuple[str, list[str]]]:
    """(label, argv-without-destination) pairs to try in order. RAR5 (":m3" methods)
    defeats p7zip, but libarchive/bsdtar reads it, so .rar prefers bsdtar."""
    out: list[tuple[str, list[str]]] = []
    if shutil.which("bsdtar"):
        out.append(("bsdtar", ["bsdtar", "-xf", str(pack), "-C"]))
    for exe in ("7zz", "7z", "7za"):
        if shutil.which(exe):
            out.append((exe, [exe, "x", "-y"]))
    if pack.suffix.lower() == ".rar":
        out.sort(key=lambda t: 0 if t[0] == "bsdtar" else 1)
    if not out:
        sys.exit("ERROR: no archive tool found. Install: sudo apt install libarchive-tools p7zip-full")
    return out


def list_pack(pack: Path) -> None:
    r = subprocess.run(["bsdtar", "-tf", str(pack)] if shutil.which("bsdtar") else ["7z", "l", str(pack)], capture_output=True, text=True)
    lines = [l for l in r.stdout.splitlines() if l.strip()]
    print(f"\n## {pack.name}  ({len(lines)} lines)")
    for l in lines[-8:] if len(lines) > 8 else lines:
        print("   ", l)


def extract(pack: Path) -> Path:
    dest = OUT / pack.stem
    dest.mkdir(parents=True, exist_ok=True)

    for tool, base in tools_for(pack):
        full = base + ([str(dest)] if tool == "bsdtar" else [f"-o{dest}", str(pack)])
        r = subprocess.run(full, capture_output=True, text=True)
        files = [p for p in dest.rglob("*") if p.is_file()]
        good = [p for p in files if p.stat().st_size > 0]
        pngs = [p for p in good if p.suffix.lower() == ".png"]
        # p7zip exits 0 even when entries fail ("Unsupported Method") and leaves
        # 0-byte files, so judge success by bytes on disk, not exit codes.
        if good and len(good) == len(files):
            print(f"OK  {pack.name} -> {dest.relative_to(ROOT)}  ({len(good)} files, {len(pngs)} png) via {tool}")
            return dest
        for p in files:
            p.unlink()
        print(f"  {tool}: {len(good)}/{len(files)} usable files — trying next tool")

    print(f"FAILED: {pack.name}: no tool could extract it. Try installing 'unrar' (non-free) or 7-Zip 24+ (7zz).")
    return dest


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("pattern", nargs="?", help="substring of the pack name")
    ap.add_argument("--list", action="store_true", help="list contents, do not extract")
    args = ap.parse_args()

    packs = find_packs(args.pattern)
    if not packs:
        sys.exit(f"ERROR: no archives matched in {SRC}")

    for pack in packs:
        print(f"\n## {pack.name}")
        if args.list:
            list_pack(pack)
        else:
            extract(pack)


if __name__ == "__main__":
    main()