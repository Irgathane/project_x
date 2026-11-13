// ============================================================
// combat.qc — damage, bullets, visibility.
// ============================================================

// One clean damage path for everything. Armor saves a third.
void(entity targ, entity attacker, float damage) T_Damage = {
	local entity st;
	local float save;
	if (!targ.takedamage) return;
	if (targ.health <= 0) return;

	if (targ.classname == "player") {
		if (targ.armortype > 0 && targ.armorvalue > 0) {
			save = damage * 0.3;
			if (save > targ.armorvalue) save = targ.armorvalue;
			targ.armorvalue = targ.armorvalue - save;
			damage = damage - save;
		}
		targ.punchangle_x = -1;
	}

	targ.health = targ.health - damage;

	if (targ.health <= 0) {
		if (targ.classname == "monster_stalker")
			killed_monsters = killed_monsters + 1;
		if (targ.th_die) {
			st = self; self = targ;
			targ.th_die();
			self = st;
		}
		return;
	}
	if (targ.th_pain) {
		st = self; self = targ;
		targ.th_pain(attacker, damage);
		self = st;
	}
};

// Hitscan spread. self = shooter.
void(float count, vector spread, float damage) FireBullets = {
	local vector src, dir;
	src = self.origin + self.view_ofs;
	makevectors(self.v_angle);
	while (count > 0) {
		count = count - 1;
		dir = normalize(v_forward
			+ v_right * crandom() * spread_x
			+ v_up    * crandom() * spread_y);
		traceline(src, src + dir * 2048, FALSE, self);
		if (trace_fraction == 1) continue;
		if (trace_ent.takedamage) {
			particle(trace_endpos, '0 0 0', 73, 6);
			T_Damage(trace_ent, self, damage);
		} else {
			particle(trace_endpos, trace_plane_normal * 12, 15, 3);
		}
	}
};

float(entity targ) visible = {
	traceline(self.origin + self.view_ofs, targ.origin, TRUE, self);
	return trace_fraction == 1;
};
