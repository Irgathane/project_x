#!/usr/bin/env python3
"""Rebuild slipgate/maps/slipgate.wad from PNGs — OPTIONAL, and usually unnecessary.

vkQuake prefers external PNGs (`textures/<texname>.png`) over WAD lumps, so for
art swaps you normally only run texture_import.py. Rebuild the WAD only when you
add a *new* texture name that the .map references but the WAD lacks.

Requires the Quake palette, which ships with the game data, not this repo:
    id1/gfx/palette.lmp   (extract from pak0.pak, or copy from LibreQuake)

Usage:
    python3 tools/make_wad.py --palette id1/gfx/palette.lmp
    python3 tools/make_wad.py --palette ... --out slipgate/maps/slipgate.wad

WAD2 format: 12-byte header ("WAD2", nlumps, dirofs) then 32-byte directory
entries {filepos, disksize, size, type, compression, pad, pad, name[16]}.
Texture lumps are type 0x43 ('C') with a 40-byte miptex header and 4 mip levels.
"""
import argparse
import struct
import sys
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parent.parent
TEXDIR = ROOT / "slipgate" / "textures"
WAD = ROOT / "slipgate" / "maps" / "slipgate.wad"
MIP_LEVELS = 4
TYPE_TEXTURE = 0x42  # TYP_QPIC: how Quake WAD2 stores miptex lumps


def load_palette(path: Path) -> list[tuple[int, int, int]]:
    data = path.read_bytes()
    if len(data) < 768:
        sys.exit(f"ERROR: {path} is {len(data)} bytes, expected 768 (256 x RGB)")
    return [(data[i], data[i + 1], data[i + 2]) for i in range(0, 768, 3)]


def quantize(img: Image.Image, pal: list[tuple[int, int, int]]) -> bytes:
    """Nearest-colour map to the fixed Quake palette (no dithering: keeps pixel art crisp)."""
    rgb = img.convert("RGB")
    data = rgb.tobytes()
    out = bytearray()
    cache: dict[bytes, int] = {}
    for i in range(0, len(data), 3):
        px = data[i:i + 3]
        idx = cache.get(px)
        if idx is None:
            r, g, b = px
            idx = min(range(256), key=lambda j: (pal[j][0] - r) ** 2 + (pal[j][1] - g) ** 2 + (pal[j][2] - b) ** 2)
            cache[px] = idx
        out.append(idx)
    return bytes(out)


def build_lump(name: str, pixels: bytes, w: int, h: int) -> bytes:
    assert name.isascii() and len(name) <= 15
    # miptex_t: char name[16]; uint w, h (bytes 16..23); uint offsets[4] (bytes 24..39)
    header = struct.pack("<16sII", name.encode(), w, h) + b"\0" * 16
    data = bytearray(header)  # 40 bytes total
    offs = []
    level = pixels
    lw, lh = w, h
    for _ in range(MIP_LEVELS):
        offs.append(len(data))
        data += level
        # box-filter downsample
        nxt = bytearray()
        for y in range(0, lh, 2):
            for x in range(0, lw, 2):
                nxt.append(level[(y * lw + x)])
        level, lw, lh = bytes(nxt), lw // 2, lh // 2
        if lw == 0 or lh == 0:
            break
    while len(offs) < 4:  # pad tiny textures so the header still parses
        offs.append(offs[-1])
    for i, o in enumerate(offs[:4]):
        struct.pack_into("<I", data, 24 + i * 4, o)
    return bytes(data)


def read_existing(path: Path) -> list[tuple[str, int, bytes]]:
    """Return [(name, type, raw_lump)] from an existing WAD so non-texture lumps
    (trigger/clip/skip...) survive a rebuild. Missing/corrupt WAD -> empty list."""
    if not path.is_file():
        return []
    d = path.read_bytes()
    sig, n, off = struct.unpack("<4sii", d[:12])
    if sig != b"WAD2":
        print(f"WARN: {path.name} is {sig!r}, not WAD2 — starting fresh")
        return []
    lumps = []
    for i in range(n):
        fp, ds, sz, typ, comp, _p1, _p2, nm = struct.unpack("<iiiBBBB16s", d[off + i * 32:off + i * 32 + 32])
        name = nm.split(b"\0")[0].decode("latin1")
        lumps.append((name, typ, d[fp:fp + sz]))
    return lumps


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--palette", type=Path, required=True, help="id1/gfx/palette.lmp (768 bytes)")
    ap.add_argument("--out", type=Path, default=WAD)
    ap.add_argument("--texdir", type=Path, default=TEXDIR)
    ap.add_argument("--base", type=Path, default=WAD,
                    help="existing WAD whose non-texture lumps (trigger/clip/skip) are preserved")
    args = ap.parse_args()

    if not args.palette.is_file():
        sys.exit(f"ERROR: palette not found: {args.palette}\n"
                 "The Quake palette lives in the game data (id1/gfx/palette.lmp), not this repo.")
    pal = load_palette(args.palette)

    pngs = sorted(p for p in args.texdir.glob("*.png") if len(p.stem) <= 15)
    if not pngs:
        sys.exit(f"ERROR: no textures in {args.texdir}")

    existing = read_existing(args.base)
    existing_names = {n for n, _t, _d in existing}
    png_names = {p.stem for p in pngs}
    missing = png_names - existing_names
    if missing:
        print(f"adding new texture(s): {', '.join(sorted(missing))}")
    preserved = [n for n, _t, _d in existing if n not in png_names]
    if preserved:
        print(f"preserving non-texture lumps: {', '.join(preserved)}")

    rebuilt: dict[str, bytes] = {}
    for p in pngs:
        with Image.open(p) as img:
            img = img.convert("RGB")
            w, h = img.size
            if w != h or (w & (w - 1)) or not 16 <= w <= 1024:
                sys.exit(f"ERROR: {p.name} must be square power-of-two 16..1024 (is {w}x{h})")
            pixels = quantize(img, pal)
        rebuilt[p.stem] = build_lump(p.stem, pixels, w, h)
        print(f"  {p.stem:16} {w}x{h}")

    # keep the original lump order, then append genuinely new textures
    lumps: list[tuple[str, int, bytes]] = []
    for name, typ, raw in existing:
        if name in rebuilt:
            lumps.append((name, TYPE_TEXTURE, rebuilt[name]))
        else:
            lumps.append((name, typ, raw))
    for p in pngs:
        if p.stem not in existing_names:
            lumps.append((p.stem, TYPE_TEXTURE, rebuilt[p.stem]))

    body = bytearray()
    directory = []
    pos = 12
    for name, typ, lump in lumps:
        directory.append((pos, len(lump), len(lump), typ, name))
        body += lump
        pos += len(lump)

    header = struct.pack("<4sII", b"WAD2", len(lumps), pos)
    dirblob = b"".join(
        struct.pack("<IIIBBBB16s", fp, ds, sz, typ, 0, 0, 0, nm.encode()) for fp, ds, sz, typ, nm in directory
    )
    args.out.parent.mkdir(parents=True, exist_ok=True)
    args.out.write_bytes(header + bytes(body) + dirblob)
    shown = args.out.relative_to(ROOT) if ROOT in args.out.parents else args.out
    print(f"\nwrote {shown}  {len(lumps)} lumps, {args.out.stat().st_size // 1024} KiB")


if __name__ == "__main__":
    main()
