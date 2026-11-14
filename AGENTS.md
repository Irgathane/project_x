# project_x — slipgate (vkQuake QuakeC mod)

I do not code. You write ALL the code and give me exact, complete instructions.

## Project facts — never contradict these

- **Engine**: vkQuake (vanilla Quake / id Tech 2 source port), Windows + Linux.
- **Language**: vanilla QuakeC compiled with FTEQCC. NO FTE-only extensions — no
  CSQC, no IQM, no `#pragma` tricks, no engine C edits. If a feature needs engine
  changes, propose a QuakeC workaround instead.
- **Animation**: numeric frame indices from `slipgate/qc/frames.qc`, never `$frame`
  macros (so the compiler needs no `.mdl` files).
- **Assets**: id-standard filenames supplied by LibreQuake in `id1/`
  (`progs/player.mdl`, `progs/v_shot.mdl`, `progs/g_shot.mdl`, `progs/soldier.mdl`,
  `maps/b_bh25.bsp`, `maps/b_shell0.bsp`, stock sound paths). Never invent asset
  paths — say the exact filename to create and where it goes.
- **Balance**: all gameplay numbers live in `slipgate/qc/tuning.qc` as `TUNE_*`
  floats. Never hardcode balance values in logic files.
- **QC file list** (`slipgate/qc/progs.src`, dependency order): defs, frames,
  tuning, subs, combat, items, weapons, player, monsters, doors, triggers, world,
  client. New files must be added to `progs.src` in dependency order.

## Build and run

| Step | Command (from repo root unless noted) |
|---|---|
| QuakeC | `cd slipgate/qc && fteqcc progs.src` |
| CRC stamp | `python3 tools/fix_progs_crc.py slipgate/qc/progs.dat` then copy to `slipgate/progs.dat` |
| ABI check | `python3 tools/check_abi.py` |
| Map | `cd slipgate/maps && qbsp -wadpath . starter.map && vis starter.bsp && light -extra4 starter.bsp` |
| Engine | `cd vkQuake && meson setup build && ninja -C build` (needs the LunarG SDK env) |
| Launch | `./slipgate/launch.sh` (basedir = repo root: `./id1` + `./slipgate`) |

Non-obvious rules:

- **The CRC stamp is mandatory.** vkQuake hard-requires `progs.dat` crc 5927; fteqcc
  can never produce it. Safe only because the first 54 globals and 77 entity fields
  are vanilla and in vanilla order — extras append, `tools/check_abi.py` verifies.
- **`id1/` sits at the repo root**, not inside `slipgate/`. Launching from inside
  the mod directory breaks the basedir.
- **The LunarG SDK env must not be `.setup-env.sh`-sourced** from a script (its
  `BASH_SOURCE` resolves wrong); set `VK_*`/`PKG_CONFIG_PATH`/`LD_LIBRARY_PATH`
  explicitly.
- This machine has **no hardware Vulkan** (Radeon RV710, GL 3.0 via Mesa). The
  `vkQuake` build only runs on llvmpipe — slow. A QuakeSpasm OpenGL build lives in
  `quakespasm/` as the playable fallback.

## How to answer

1. Give COMPLETE replacement file contents — never fragments or "// rest unchanged".
2. Say exactly which file each block replaces.
3. End with: build step, launch step, and a 3-line in-game test checklist.
4. Keep changes minimal — one feature per request.
5. Explain what changed in one plain-language sentence. No jargon without a gloss.
6. If unsure about a builtin number or engine behavior, say so and take the
   conservative vanilla option.