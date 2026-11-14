// ============================================================
// monsters.qc — the Stalker: a melee chaser built on soldier.mdl.
// Simple, readable state machine: stand -> walk -> melee -> die.
// Precaches happen HERE (a spawn function), so with monsters
// disabled — or none placed in a map — missing monster assets
// can never crash the game.
// ============================================================

void() stalker_walk;   // forward declaration
void() stalker_stand;  // forward declaration

void() stalker_melee_hit = {
	self.think = stalker_walk;
	self.nextthink = time + 0.6;
	if (!self.enemy || self.enemy.health <= 0) return;
	if (vlen(self.enemy.origin - self.origin) > 80) return;
	T_Damage(self.enemy, self, TUNE_MON_DAMAGE);
};

void() stalker_melee = {
	self.think = stalker_melee_hit;
	self.nextthink = time + 0.4;
	self.frame = MS_ATTACK;
	sound(self, CHAN_WEAPON, "soldier/sattck1.wav", 1, ATTN_NORM);
};

void() stalker_walk = {
	local float d;
	if (!self.enemy || self.enemy.health <= 0) {
		self.enemy = world;
		self.think = stalker_stand;
		self.nextthink = time + 0.2;
		return;
	}
	self.think = stalker_walk;
	self.nextthink = time + 0.1;
	self.ideal_yaw = vectoyaw(self.enemy.origin - self.origin);
	ChangeYaw();
	d = vlen(self.enemy.origin - self.origin);
	if (d < 64) { stalker_melee(); return; }
	if (!walkmove(self.ideal_yaw, TUNE_MON_SPEED * 0.1)) {
		if (!walkmove(self.ideal_yaw + 60, TUNE_MON_SPEED * 0.1))
			walkmove(self.ideal_yaw - 60, TUNE_MON_SPEED * 0.1);
	}
	self.anim_frame = self.anim_frame + 1;
	if (self.anim_frame >= MS_WALK_COUNT) self.anim_frame = 0;
	self.frame = MS_WALK1 + self.anim_frame;
};

void() stalker_stand = {
	local entity e;
	self.think = stalker_stand;
	self.nextthink = time + 0.2;
	self.frame = MS_STAND;
	if (random() < 0.04)
		sound(self, CHAN_VOICE, "soldier/idle.wav", 1, ATTN_IDLE);
	e = checkclient();               // engine does the visibility test
	if (!e) return;
	if (vlen(e.origin - self.origin) > TUNE_MON_SIGHT) return;
	self.enemy = e;
	sound(self, CHAN_VOICE, "soldier/sight1.wav", 1, ATTN_NORM);
	stalker_walk();
};

void(entity attacker, float damage) stalker_pain = {
	if (time < self.pain_finished) return;
	self.pain_finished = time + 0.4;
	sound(self, CHAN_VOICE, "soldier/pain1.wav", 1, ATTN_NORM);
	self.think = stalker_walk;
	self.nextthink = time + 0.2;     // brief flinch
};

void() stalker_die = {
	sound(self, CHAN_VOICE, "soldier/death1.wav", 1, ATTN_NORM);
	particle(self.origin + '0 0 24', '0 0 30', 73, 24);
	self.solid = SOLID_NOT;
	self.frame = MS_STAND;
	self.think = SUB_Remove;         // placeholder death: burst + remove
	self.nextthink = time + 0.6;
};

void() monster_stalker = {
	if (!TUNE_MONSTERS_ON) { remove(self); return; }
	precache_model("progs/soldier.mdl");
	precache_sound("soldier/idle.wav");
	precache_sound("soldier/sight1.wav");
	precache_sound("soldier/sattck1.wav");
	precache_sound("soldier/pain1.wav");
	precache_sound("soldier/death1.wav");
	setmodel(self, "progs/soldier.mdl");
	setsize(self, '-16 -16 -24', '16 16 24');
	self.solid = SOLID_SLIDEBOX;
	self.movetype = MOVETYPE_STEP;
	self.flags = self.flags | FL_MONSTER;
	self.health = TUNE_MON_HEALTH;
	self.takedamage = DAMAGE_AIM;
	self.view_ofs = '0 0 24';
	self.yaw_speed = 40;
	self.th_die = stalker_die;
	self.th_pain = stalker_pain;
	droptofloor();
	total_monsters = total_monsters + 1;
	stalker_stand();
};
