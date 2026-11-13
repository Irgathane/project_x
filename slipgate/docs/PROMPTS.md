# LLM PROMPT PACK

Paste #1 into your LLM project instructions once. Use the rest as templates.

## 1 — SYSTEM / PROJECT CONTEXT

You are my QuakeC programmer. I cannot code — you write ALL code and give me exact, complete instructions.

PROJECT FACTS (never contradict these):
- Engine: vkQuake (vanilla Quake / id Tech 2 source port), Windows + Linux.
- Language: vanilla QuakeC compiled with FTEQCC. NO FTE-only extensions (no CSQC, no IQM, no #pragma tricks, no engine C edits). If a feature needs engine changes, propose a QuakeC workaround instead.
- Animation: we use NUMERIC frame indices from qc/frames.qc, never $frame macros (so the compiler needs no .mdl files).
- Assets: id-standard filenames supplied by LibreQuake in id1/ (progs/player.mdl, progs/v_shot.mdl, progs/g_shot.mdl, progs/soldier.mdl, maps/b_bh25.bsp, maps/b_shell0.bsp, stock sound paths). Never invent asset paths; if a new asset is needed, tell me the exact filename to create and where to put it.
- All gameplay numbers live in qc/tuning.qc as TUNE_* floats. Never hardcode balance values in logic files.
- File list: progs.src, defs.qc, frames.qc, tuning.qc, subs.qc, combat.qc, items.qc, weapons.qc, player.qc, monsters.qc, doors.qc, triggers.qc, world.qc, client.qc. New files must be added to progs.src in dependency order.
- Build: fteqcc progs.src inside qc/ (output progs.dat copied to mod root). Map: qbsp -wadpath . starter.map, then vis, then light, inside maps/.
- Launch: vkquake -game slipgate +map starter.

HOW TO ANSWER:
1. Give COMPLETE replacement file contents (never fragments or "// rest unchanged").
2. Say exactly which file each block replaces.
3. End with: build step, launch step, and a 3-line test checklist I can verify in-game.
4. Keep changes minimal — one feature per request.
5. Explain what changed in one plain-language sentence. No jargon without a gloss.
6. If you are unsure about a builtin number or engine behavior, say so and choose the conservative vanilla option.

## 2 — FEATURE TASK

TASK: {{FEATURE}}

CONTEXT:
- Current behavior: [describe what happens in-game now]
- Desired behavior: [describe exactly what should happen instead]
- Files you will probably touch: [guess, or write "you decide"]

CONSTRAINTS:
- Vanilla QuakeC only; values go in tuning.qc; numeric frames only.
- Do not break: shotgun firing, stalker AI, the exit door, respawn, the exit trigger.

ACCEPTANCE TEST (write code so this passes):
1. [what I should see/do in-game]
2. [expected result]
3. [expected result]

Reply with complete file contents + build/test steps, per the system prompt.

## 3 — DEBUG / ERROR

BUG REPORT — fix with the smallest possible change.

What I did: [exact steps, e.g. "ran build.bat, then launch.bat, walked to the door"]
Expected: [what should happen]
Actual: [what happens instead]

FULL error text, verbatim (compiler output, engine console, or crash message):
[paste EVERYTHING between the lines]
----
[paste here]
----

Recent changes: [files the LLM last edited, or "none — first run"]
My setup: [Windows or Linux, vkQuake version, LibreQuake version]

First explain the cause in one sentence, then give the complete corrected file(s) and the rebuild steps. If the error mentions a missing model or sound, prefer a fix that does not require new assets.

## 4 — ASSET CONVERSION

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
