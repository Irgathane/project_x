// ============================================================
// weapons.qc — one weapon done well: the shotgun.
// All feel-values come from tuning.qc. Add weapon #2 by copying
// this file's pattern (ask your LLM, task prompt).
// ============================================================

void() W_FireShotgun = {
	sound(self, CHAN_WEAPON, "weapons/shotgn2.wav", 1, ATTN_NORM);
	self.punchangle_x = -2;
	FireBullets(TUNE_PELLETS, '0.05 0.05 0', TUNE_PELLET_DMG);
};

void() W_Attack = {
	if (self.attack_finished > time) return;
	if (self.ammo_shells <= 0 && !TUNE_DEV_INFINITE_AMMO) {
		self.attack_finished = time + 0.3;
		sound(self, CHAN_WEAPON, "weapons/dryfire.wav", 1, ATTN_NORM);
		return;
	}
	if (!TUNE_DEV_INFINITE_AMMO)
		self.ammo_shells = self.ammo_shells - 1;
	self.attack_finished = time + TUNE_FIRE_DELAY;
	self.weaponframe = VF_FIRE1;
	self.weaponanim_next = time + 0.07;
	W_FireShotgun();
};

// called every frame from PlayerPostThink
void() W_WeaponFrame = {
	if (self.weaponframe > 0 && time >= self.weaponanim_next) {
		self.weaponanim_next = time + 0.07;
		self.weaponframe = self.weaponframe + 1;
		if (self.weaponframe >= VF_FIRE1 + VF_FIRE_COUNT)
			self.weaponframe = 0;
	}
};
