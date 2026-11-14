// ============================================================
// world.qc — worldspawn precaches + static map entities.
// Monster assets are precached by monster_stalker itself.
// ============================================================

void() worldspawn = {
	skill = cvar("skill");
	precache_model("progs/player.mdl");
	precache_model("progs/v_shot.mdl");
	precache_model("progs/g_shot.mdl");
	precache_model("maps/b_bh25.bsp");
	precache_model("maps/b_shell0.bsp");
	precache_sound("weapons/shotgn2.wav");
	precache_sound("weapons/dryfire.wav");
	precache_sound("weapons/pkup.wav");
	precache_sound("items/health1.wav");
	precache_sound("player/plyrjmp8.wav");
	precache_sound("player/pain1.wav");
	precache_sound("player/death1.wav");
	precache_sound("doors/airdoor1.wav");
	precache_sound("doors/airdoor2.wav");
};

void() info_player_start = { self.angles_y = self.angle; };
void() info_intermission = {};
void() info_null = { remove(self); };   // spotlight aim target
// NB: classname "light" stubs are baked by the light tool, so no spawn function is
// needed. The name `light` itself is taken by the .float field in defs.qc (line 61),
// hence light_baked.
void() light_baked = { remove(self); };
