// ============================================================
// frames.qc — numeric animation frames.
// We use plain numbers (NOT $frame macros) so FTEQCC never needs
// the .mdl files at compile time. Values target the stock /
// LibreQuake models. Swap in custom models? Update these numbers
// to match the new model's frame order (ask your LLM, prompt #4).
// All indices are kept low so they are valid on any stock model.
// ============================================================

// player.mdl — first run cycle
float PF_RUN1 = 0;      // cycle PF_RUN1 .. PF_RUN1+5
float PF_RUN_COUNT = 6;

// v_shot.mdl — view-model fire animation
float VF_FIRE1 = 1;     // cycle VF_FIRE1 .. VF_FIRE1+4
float VF_FIRE_COUNT = 5;

// soldier.mdl — the stalker
float MS_STAND  = 0;
float MS_WALK1  = 1;    // cycle MS_WALK1 .. MS_WALK1+5
float MS_WALK_COUNT = 6;
float MS_ATTACK = 7;
