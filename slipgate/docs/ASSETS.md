# ASSET PIPELINE — itch.io to Quake

## Models (low-poly is perfect for Quake)
1. Buy/download a pack. Check the license FIRST (CC0 = easiest;
   CC-BY = fine + credit; avoid NC if you might ever sell the game).
2. Blender: File > Import your format (FBX/OBJ/glTF all work).
3. Install the MDL plugin: https://github.com/robrohan/blender_ie_quake_mdl
   Edit > Preferences > Add-ons > Install > pick the plugin zip > enable.
4. Scale sanity: the Quake player is 56 units tall (1 unit ~ 1 inch).
   Apply transforms (Ctrl+A > All Transforms) before export.
5. Export MDL. Keep it under ~1000 triangles for the classic look.
   Animations bake to vertex frames — keep the ones you need, in order.
6. Name the output EXACTLY like the file it replaces (see README table)
   and drop it into slipgate/progs/ — mod files override id1 files.
7. Frame order changed? Update qc/frames.qc (numeric indices). Use
   LLM prompt #4 and tell it the frame list from Blender.

## Textures
- In-game overrides: put PNG/TGA files in slipgate/textures/ named after
  the texture (sg_brick.png ...). vkQuake loads them over the wad.
  Sizes: power of two (64/128/256/512). This is the easy path.
- New map textures: add them to a WAD2 for TrenchBroom + qbsp. Ask the
  LLM to walk you through a wad tool; keep names lowercase, max 15 chars.

## Sounds & music
- Sounds: WAV, mono, 22050 Hz (44100 works too). Replace stock paths or
  add new ones + a precache_sound line in world.qc.
- Music: OGG named track02.ogg, track03.ogg ... in id1/music/ (or
  slipgate/music/). Maps reference tracks by number ("sounds" key on
  worldspawn, e.g. "sounds" "2").

## License hygiene
Every download gets a row in CREDITS.md: pack, author, link, license,
what you used it for. Do it AT DOWNLOAD TIME, not at release time.
