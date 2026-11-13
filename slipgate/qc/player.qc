// ============================================================
// player.qc — jump, pain, death, respawn, water, run animation.
// ============================================================

void() PlayerJump = {
	if (self.waterlevel > 2) return;
	if (!(self.flags & FL_ONGROUND)) return;
	self.velocity_z = TUNE_JUMP_SPEED;
	sound(self, CHAN_BODY, "player/plyrjmp8.wav", 1, ATTN_NORM);
};

void() player_run = {
	if (self.deadflag) return;
	if (self.velocity_x * self.velocity_x + self.velocity_y * self.velocity_y < 100) {
		self.frame = PF_RUN1;
		return;
	}
	if (!(self.flags & FL_ONGROUND)) return;
	if (time < self.anim_next) return;
	self.anim_next = time + 0.1;
	self.anim_frame = self.anim_frame + 1;
	if (self.anim_frame >= PF_RUN_COUNT) self.anim_frame = 0;
	self.frame = PF_RUN1 + self.anim_frame;
};

void() player_die = {
	self.deadflag = DEAD_DEAD;
	self.solid = SOLID_NOT;
	self.movetype = MOVETYPE_NONE;
	self.velocity = '0 0 0';
	self.view_ofs = '0 0 -8';
	self.weaponmodel = "";
	self.weaponframe = 0;
	self.respawn_at = time + TUNE_RESPAWN_TIME;
	sound(self, CHAN_VOICE, "player/death1.wav", 1, ATTN_NORM);
	particle(self.origin + '0 0 24', '0 0 40', 73, 20);
	sprint(self, PRINT_HIGH, "You died. Respawning in ", ftos(TUNE_RESPAWN_TIME), " seconds...\n");
};

void(entity attacker, float damage) player_pain = {
	if (time < self.pain_finished) return;
	self.pain_finished = time + 0.5;
	sound(self, CHAN_VOICE, "player/pain1.wav", 1, ATTN_NORM);
};

// lava/slime burn, deep water drowns. Map has none yet — ready for later.
void() WaterMove = {
	if (self.waterlevel == 0) { self.air_finished = time + 12; return; }
	if (self.watertype == CONTENT_LAVA || self.watertype == CONTENT_SLIME) {
		if (time > self.pain_finished) {
			self.pain_finished = time + 1;
			T_Damage(self, world, 10);
		}
	}
	if (self.waterlevel == 3) {
		if (time > self.air_finished) {
			self.air_finished = time + 1;
			T_Damage(self, world, 4);
		}
	} else {
		self.air_finished = time + 12;
	}
};
