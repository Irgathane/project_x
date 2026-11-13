---
name: slipgate-assets
description: Asset conversion template for the slipgate QuakeC mod. Use when the user wants to replace a stock asset (model, texture, sound) with one from an itch.io pack or similar, including Blender import/export walkthrough, MDL conversion, id-standard naming, frames.qc updates, and CREDITS.md licensing. Load slipgate-context first.
---

# ASSET CONVERSION

Load the `slipgate-context` skill first and follow its project facts and answer rules.

ASSET CONVERSION — help me replace a stock asset with my itch.io pack.

Asset: [pack name + link]
License on the pack page: [e.g. CC0 / CC-BY / "free for any use"]
Files in the pack: [e.g. .fbx + .png textures, or .obj, or .wav]
Target: replace [e.g. the stalker monster / shotgun viewmodel / a wall texture / a sound]

Walk me through, click by click:
1. Blender import settings for this format, and the export settings for the Quake MDL plugin (scale, origin, animation baking, triangle/vertex limits for low-poly).
2. Exact output filename + destination folder so the game picks it up WITHOUT code changes (id-standard naming), or the exact QC lines to change if renaming is unavoidable.
3. If frame order changed: give me the new numbers for qc/frames.qc.
4. Texture rules: size (power of two), and how external PNG overrides in textures/ work in vkQuake.
5. Sound rules: WAV, mono, 22050 Hz; music goes in id1/music as trackNN.ogg.
6. The exact row to add to CREDITS.md for this pack's license.
Assume I have never opened Blender before.
