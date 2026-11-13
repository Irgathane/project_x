# SLIPGATE//KIT — a vkQuake starter mod

A complete, compile-ready skeleton for a classic-Quake FPS. One weapon
(the shotgun), one enemy (the stalker), items, a trigger-opened door,
an exit that loops the level, auto-respawn, and a graybox arena map
with generated textures. Free, hobby-friendly, Windows + Linux.

## What is inside

    slipgate/
      qc/            14 QuakeC sources + progs.src (the whole game logic)
      maps/          starter.map (TrenchBroom source) + slipgate.wad (textures)
      textures/      full-color PNG overrides vkQuake loads automatically
      docs/          ASSETS.md (itch.io pipeline) + PROMPTS.md (LLM pack)
      build.bat/.sh  compiles progs.dat and starter.bsp
      launch.bat/.sh runs the game
      quake.rc       sane default config
      CREDITS.md     license notices — keep adding to it
      LICENSE        MIT for the kit code itself

## Requirements (all free)

1. vkQuake — https://github.com/Novum/vkQuake/releases
   Windows: installer (needs the MS VC++ redistributable, linked on the
   release page). Linux: AppImage (chmod +x, needs glibc 2.35+, FUSE).
   Any Vulkan-capable GPU from the last decade works.
2. LibreQuake — https://github.com/lavenderdotpet/LibreQuake/releases
   Put its .pak files into the id1/ folder next to the vkQuake executable.
   This is your free base content: player, weapons, monsters, sounds, HUD.
   NEVER copy id Software's commercial Quake .pak files into a release.
3. FTEQCC — https://www.fteqcc.org/  (get the GUI build; put fteqcc.exe
   in slipgate/tools/ or add it to PATH)
4. ericw-tools — https://github.com/ericwa/ericw-tools/releases
   (qbsp, vis, light — add the bin folder to PATH)
5. TrenchBroom — https://github.com/TrenchBroom/TrenchBroom/releases
6. Later, for custom models: Blender + the MDL import/export plugin
   https://github.com/robrohan/blender_ie_quake_mdl

## Quickstart

Windows:
    1. Unzip this kit next to id1/ so you have: vkquake.exe, id1/, slipgate/
    2. Double-click build.bat   (compiles QC + map)
    3. Double-click launch.bat  (play)

Linux:
    1. Same layout; AppImage named vkquake.AppImage next to id1/
    2. chmod +x build.sh launch.sh vkquake.AppImage
    3. ./build.sh && ./launch.sh

In TrenchBroom: choose game "Quake", point it at your vkQuake folder,
open maps/starter.map, and add maps/slipgate.wad in the map's wad list.

## The dev loop (you + your LLM)

    edit qc/*.qc (LLM writes) -> build -> launch -> test -> git commit

Paste docs/PROMPTS.md #1 into your LLM's project instructions ONCE.
Use prompt #2 for features, #3 for errors, #4 for asset conversion.
Commit every working state: git init, git add -A, git commit.
When the LLM breaks something, roll back instead of debugging blind.

## Swapping in itch.io assets

The kit uses id-standard filenames, so replacing a file with the same
name changes the game with ZERO code edits:

    progs/player.mdl    your body (third person / death cam)
    progs/v_shot.mdl    shotgun viewmodel
    progs/g_shot.mdl    shotgun pickup
    progs/soldier.mdl   the stalker monster
    maps/b_bh25.bsp     health pickup      maps/b_shell0.bsp  shells
    sound paths         see precache lists in qc/world.qc + monsters.qc

Models: low-poly MDL (Blender plugin). Keep animations in the first
frames or update qc/frames.qc. Textures: the PNGs in textures/ override
the graybox wad in-game — replace them with your pack's art (power-of-two
sizes). Sounds: WAV mono 22050 Hz. Music: id1/music/track02.ogg etc.
Log EVERY pack's license in CREDITS.md as you download it.

## Tuning

All balance lives in qc/tuning.qc (TUNE_* values) — the web workbench
generates this file from sliders. Change numbers, rebuild, feel it.

## Troubleshooting

    "progs.dat not found"        run build first; check qc/progs.dat exists
    "couldn't load progs/X.mdl"  LibreQuake missing/incomplete in id1/, or a
                                 typo in a precache path. Monsters can be
                                 switched off in tuning.qc while you fix art.
    "couldn't load sound X"      same: base content gap — fix the path in
                                 world.qc / monsters.qc to a file you have
    "no spawn function for X"    entity classname typo in the .map
    fteqcc errors                paste verbatim into LLM prompt #3
    Vulkan init failure          update GPU drivers; try another port
                                 (Ironwail) to confirm the data is fine
    Textures look gray           PNG overrides not found — the wad graybox
                                 still works; check textures/ folder names

## Licenses

Kit code: MIT (LICENSE). vkQuake: GPL-2.0-or-later — if you redistribute
its binaries, include the license and a link to its source. LibreQuake:
BSD-3-Clause — keep its attribution. Your itch.io packs: per-pack terms.
See CREDITS.md. Not affiliated with id Software.
