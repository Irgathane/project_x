// ============================================================
// client.qc — engine entry points, spawning, the main loop glue.
// ============================================================

entity() FindSpawnPoint = {
	local entity spot;
	spot = find(world, classname, "info_player_start");
	if (!spot) objerror("Map has no info_player_start!");
	return spot;
};

void() DecodeLevelParms = {
	if (parm1 > 0) {
		self.health = parm1;
		self.ammo_shells = parm2;
	} else {
		self.health = TUNE_MAX_HEALTH;
		self.ammo_shells = TUNE_START_SHELLS;
	}
};

void() PutClientInServer = {
	local entity spot;
	spot = FindSpawnPoint();
	self.classname = "player";
	self.solid = SOLID_SLIDEBOX;
	self.movetype = MOVETYPE_WALK;
	self.flags = FL_CLIENT;
	self.takedamage = DAMAGE_AIM;
	self.deadflag = DEAD_NO;
	DecodeLevelParms();
	self.max_health = TUNE_MAX_HEALTH;
	self.weapon = IT_SHOTGUN;
	self.items = IT_SHOTGUN | IT_SHELLS | IT_AXE;
	self.armortype = 0;
	self.armorvalue = 0;
	self.currentammo = self.ammo_shells;
	setmodel(self, "progs/player.mdl");
	setsize(self, '-16 -16 -24', '16 16 32');
	self.view_ofs = '0 0 22';
	setorigin(self, spot.origin + '0 0 1');
	self.angles = spot.angles;
	self.v_angle = self.angles;
	self.fixangle = TRUE;
	self.velocity = '0 0 0';
	self.punchangle = '0 0 0';
	self.weaponmodel = "progs/v_shot.mdl";
	self.weaponframe = 0;
	self.attack_finished = time;
	self.pain_finished = time;
	self.air_finished = time + 12;
	self.anim_frame = 0;
	self.anim_next = 0;
	self.frame = PF_RUN1;
	self.th_die = player_die;
	self.th_pain = player_pain;
};

void() RespawnPlayer = {
	local float shells;
	shells = self.ammo_shells;
	parm1 = TUNE_MAX_HEALTH;
	PutClientInServer();
	self.ammo_shells = shells;
	if (self.ammo_shells < 10) self.ammo_shells = 10;
	sprint(self, "Back in the fight.\n");
};

void() ClientConnect = { bprint(self.netname, " entered the slipgate\n"); };
void() ClientDisconnect = { bprint(self.netname, " left the slipgate\n"); };
void() ClientKill = { T_Damage(self, self, 9999); };

void() PlayerPreThink = {
	if (intermission_running) {
		self.velocity = '0 0 0';
		if (time >= intermission_end) changelevel(nextmap);
		return;
	}
	if (self.deadflag) {
		if (time >= self.respawn_at) RespawnPlayer();
		return;
	}
	WaterMove();
	if (self.button2) PlayerJump();
	if (self.button0) W_Attack();
	self.impulse = 0;
};

void() PlayerPostThink = {
	if (self.deadflag) return;
	W_WeaponFrame();
	player_run();
	self.currentammo = self.ammo_shells;
};

void() SetNewParms = {
	parm1 = TUNE_MAX_HEALTH;
	parm2 = TUNE_START_SHELLS;
};

void() SetChangeParms = {
	parm1 = self.health;
	if (parm1 <= 0) parm1 = TUNE_MAX_HEALTH;
	parm2 = self.ammo_shells;
};

void() StartFrame = {};
void() main = { dprint("slipgate progs loaded — good hunting.\n"); };
