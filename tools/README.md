# tools/ — asset pipeline helpers

Scripts for getting itch.io art into the mod **without touching QuakeC or the map**.
Everything here is deterministic and committed, so a conversion can be repeated
exactly (unlike hand-editing in an app).

Run everything from the repo root.

| Script | Purpose | Deps |
|---|---|---|
| `extract_packs.py` | unpack the RAR/ZIP packs in `assests/` → `assests/work/` | `libarchive-tools` (bsdtar) |
| `texture_import.py` | validate + install a PNG texture as a vkQuake override | `python3-pil` |
| `make_wad.py` | *optional* rebuild `slipgate.wad` from the PNGs | `python3-pil` + `id1/gfx/palette.lmp` |
| `blender_asset.py` | *optional* headless Blender: model pack → `.obj`/`.mtl` | Blender 4.x |

---

## 1. Textures (the normal path)

vkQuake loads external images **before** WAD lumps (`Quake/gl_model.c`):

```
textures/<mapname>/<texname>   →   textures/<texname>   →   WAD lump
```

So a plain `slipgate/textures/sg_brick.png` overrides the `sg_brick` lump at full
24-bit colour. **No map rebuild, no QC rebuild.** This is why we don't rebuild the
WAD for art swaps.

```sh
python3 tools/extract_packs.py                 # all packs → assests/work/
python3 tools/extract_packs.py --list          # just look inside
python3 tools/texture_import.py --list         # inventory with dimensions

# pick a wall, name it after a texture the map already uses
python3 tools/texture_import.py \
  "assests/work/SBS - Tiny Texture Pack 2 - 256x256/256x256/Brick/Brick_01-256x256.png" \
  sg_brick \
  --credits "SBS Tiny Texture Pack 2|SBS|https://sbs.itch.io|CC0|brick walls"

python3 tools/texture_import.py --check        # validate slipgate/textures/
```

Rules the scripts enforce (and why):

- **square, power-of-two** (16/32/64/128/256/512/1024) — GL mipmapping and
  Quake's texture math assume POT. Non-conforming files are rejected; `--resize N`
  rescales instead.
- **names ≤ 15 chars, lowercase** — WAD lump names are 16 bytes including NUL.
- **existing names only**, unless you also add a new lump: the six textures the
  map references are `sg_brick sg_crate sg_floor sg_metal sg_rune sg_trim`.
  Reusing those names means zero map work.
- Import never edits `CREDITS.md`: it prints the exact row to paste, so licensing
  stays a deliberate human act.

Our existing overrides are `128x128`; the packs are `256x256`. Both are valid —
`--resize 128` if you want to match the current look exactly.

## 2. WAD rebuild (rarely needed)

Only when the map must reference a texture name that does not exist in the WAD.
Needs the Quake palette from the game data, which is **not** in this repo:

```sh
# id1/gfx/palette.lmp comes from pak0.pak / LibreQuake
python3 tools/make_wad.py --palette id1/gfx/palette.lmp
```

It rebuilds miptex lumps from `slipgate/textures/*.png`, preserves any
non-texture lumps (`trigger`, `clip`, `skip`) and the original lump order, and
requires `qbsp`/`vis`/`light` to recompile the `.bsp` afterwards.

Tested behaviour: rebuilding the current WAD reproduces all 7 texture lumps
(now at the PNG resolution) and copies `trigger`/`clip`/`skip` byte-identically.

## 3. Models (Blender, headless)

```sh
blender --background --python tools/blender_asset.py -- --selftest

blender --background --python tools/blender_asset.py -- \
  --input "assests/work/SomePack/tree.fbx" --name tree --origin feet --scale 1.0
```

It starts from an empty scene, imports `.glb/.gltf/.fbx/.obj`, triangulates,
bakes transforms, moves the origin (feet = bottom-centre for monsters/items,
centre for props), reports bounds and MDL-limit violations (>2000 tris /
>1024 verts), and writes `slipgate/models/src/<name>.obj` + `.mtl`.

**It deliberately stops at `.obj`.** The Quake MDL *export* addons are the weak
link: most target Blender 2.7x–2.9x and need patching for 4.x. The OBJ is the
stable intermediate, so the MDL step can change without redoing this one.
Frame indices for any animation still go into `qc/frames.qc` as numbers.

## Licences

Every pack needs a row in `slipgate/CREDITS.md` at download time — use the
`--credits` flag to print a correctly shaped row, then paste it into the table.