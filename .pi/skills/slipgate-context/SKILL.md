---
name: slipgate-context
description: System/project context for the slipgate vkQuake QuakeC mod. Load FIRST for any slipgate work — contains project facts (engine, language, assets, build, launch) and how-to-answer rules. Use when writing, reviewing, or discussing any QuakeC code in this project.
---

# SYSTEM / PROJECT CONTEXT

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
