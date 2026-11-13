# assests/ — third-party art packs (not committed)

The `.rar` archives here are **gitignored**: they are ~92 MB of binary art whose
licences belong to their authors, not to this repo. This file is the committed
manifest — it records what was downloaded and what it was used for, so a fresh
clone can restore the same art.

## Manifest

| Pack | Archive | Contents | Images | Used for |
|------|---------|----------|--------|----------|
| SBS Tiny Texture Pack | `SBS - Tiny Texture Pack - 256x256.rar` | 5 categories (Wood, Tile, Roofs, Grass, Bricks) × 25 | 125 PNG | walls, floors (256×256) |
| SBS Tiny Texture Pack 2 | `SBS - Tiny Texture Pack 2 - 256x256.rar` | 8 categories (Wood, Brick, Metal, …) | 160 PNG | metal, crates (256×256) |
| SBS Tiny Texture Pack 3 | `SBS - Tiny Texture Pack 3 - Medium.rar` | 10 categories (Stone, Terrain, Weave, Metal, Grating, Gem, …) | 240 PNG | interiors, trim |
| Guns & Explosives | `Guns&Explosives.rar` | FBX models + PBR maps (`*_Base_Color`, `*_Normal_DirectX`, `*_Metallic`) | 95 PNG + FBX | *candidate* for weapon viewmodels (unused so far) |

⚠️ **Fill this in per pack, at download time** — the licensing fields are deliberately
left empty rather than guessed:

| Pack | Author | Source URL | Licence (verbatim from the pack page) |
|------|--------|-----------|----------------------------------------|
| SBS Tiny Texture Pack | | | |
| SBS Tiny Texture Pack 2 | | | |
| SBS Tiny Texture Pack 3 | | | |
| Guns & Explosives | | | |

The same rows must appear in `slipgate/CREDITS.md` (that table is the one that
ships with the game). `tools/texture_import.py --credits "Pack|Author|Link|License|Used for"`
prints a correctly shaped row to paste into it.

## Restoring on a fresh clone

```sh
# drop the archives back into assests/, then:
python3 tools/extract_packs.py            # → assests/work/<pack>/  (also gitignored)
python3 tools/texture_import.py --list    # inventory with dimensions
```

`assests/work/` is the extraction scratch space and is gitignored too — never
edit art there, always import into `slipgate/textures/` via the tool.

## Texture rules (enforced by tools/texture_import.py)

- square, power-of-two: 16 / 32 / 64 / 128 / 256 / 512 / 1024
- name ≤ 15 characters, lowercase (`sg_brick`, `sg_metal`, …)
- reusing the six names the map already references means **no map rebuild**:
  `sg_brick  sg_crate  sg_floor  sg_metal  sg_rune  sg_trim`

See `tools/README.md` for the full pipeline.