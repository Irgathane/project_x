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
| `fix_map_winding.py` | repair inside-out brushes in a `.map` (WARNING 09) | none |
| `blender_asset.py` | *optional* headless Blender: model pack → `.obj`/`.mtl` | Blender 4.x |
| `check_abi.py` | verify `defs.qc` still matches the engine's 54/77 layout | — |
| `fix_progs_crc.py` | stamp `progs.dat` with the vanilla ABI crc (5927) | — |
| `export_bundle.sh` | pack everything for a USB stick (`--no-engine` for a smaller one) | — |
| `setup-machine.sh` | provision a fresh machine from that bundle | apt |

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

## 2. Map brushes come out inside-out

Symptom: `qbsp` prints `WARNING 09: Couldn't create brush faces` once per brush,
reports `0 brushes / 0 planes`, and writes no `.bsp`.

Cause: a Quake face's three points must be wound so the plane normal points *out*
of the solid. Some editors/generators emit the conventional counter-clockwise
order, which ericw-tools reads as inward-facing, so every face is discarded.

```sh
python3 tools/fix_map_winding.py slipgate/maps/starter.map   # swaps 2nd/3rd point per face, backs up .orig
qbsp -wadpath . slipgate/maps/starter.map                    # warnings must be gone
```

`starter.map` was fixed this way (102 faces); `starter.map.orig` keeps the
broken original for comparison. Fix the generator or re-run this tool after
every export.

## 3. WAD rebuild (rarely needed)

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

## 4. Models (Blender, headless)

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

## 5. Moving the project to another machine

Code lives in git; the big third-party data (`id1/` 242 MB, art packs 246 MB) does not.
A USB bundle carries both and the installer rebuilds the machine-specific parts
(the engine and every artifact).

```sh
# on the old machine, with the stick mounted at /media/$USER/STICK
./tools/export_bundle.sh /media/$USER/STICK
sha256sum -c /media/$USER/STICK/SHA256SUMS.txt   # optional integrity check

# on the new machine
cd /media/$USER/STICK && ./setup-machine.sh --bundle "$PWD"
```

`setup-machine.sh` installs packages (gcc/meson/ninja/SDL3/Vulkan/fteqcc/ericw-tools),
installs the **LunarG Vulkan SDK**, unpacks code + data, then builds vkQuake,
`progs.dat` (with the crc stamp and an ABI check) and `starter.bsp`, and finally
runs a Vulkan sanity check. It works on sysvinit (antiX) — nothing assumes systemd.

Two gotchas baked into it, both found the hard way:

- **Never `eval`/`source` the SDK's `setup-env.sh` from a script.** It derives
  `VULKAN_SDK` from `BASH_SOURCE`, which resolves to the caller, so every path
  silently points at the wrong directory and meson falls back to the distro's
  too-old Vulkan loader. The installer exports the paths explicitly instead.
- **The engine is not packed.** It is machine-specific (GPU driver, shader
  compiler) and its build tree is ~1 GB. Rebuilding takes ~5 minutes.
