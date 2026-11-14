// ============================================================
// items.qc — health, shells, shotgun pickup. All respawn.
// Models use id-standard names so LibreQuake works out of the box.
// ============================================================

void() health_touch = {
	if (other.classname != "player") return;
	if (other.health >= TUNE_MAX_HEALTH) return;
	other.health = other.health + TUNE_HEALTH_AMT;
	if (other.health > TUNE_MAX_HEALTH) other.health = TUNE_MAX_HEALTH;
	sprint(other, PRINT_LOW, "Picked up health\n");
	sound(other, CHAN_ITEM, "items/health1.wav", 1, ATTN_NORM);
	self.solid = SOLID_NOT;
	self.model = "";
	setmodel(self, self.model);
	self.think = SUB_regen;
	self.nextthink = time + 15;
};

void() ammo_touch = {
	if (other.classname != "player") return;
	if (other.ammo_shells >= 200) return;
	other.ammo_shells = other.ammo_shells + 10;
	sprint(other, PRINT_LOW, "Picked up 10 shells\n");
	sound(other, CHAN_ITEM, "weapons/pkup.wav", 1, ATTN_NORM);
	self.solid = SOLID_NOT;
	self.model = "";
	setmodel(self, self.model);
	self.think = SUB_regen;
	self.nextthink = time + 20;
};

void() weapon_touch = {
	if (other.classname != "player") return;
	other.items = other.items | IT_SHOTGUN;
	other.ammo_shells = other.ammo_shells + 10;
	sprint(other, PRINT_LOW, "Shells +10\n");
	sound(other, CHAN_ITEM, "weapons/pkup.wav", 1, ATTN_NORM);
	self.solid = SOLID_NOT;
	self.model = "";
	setmodel(self, self.model);
	self.think = SUB_regen;
	self.nextthink = time + 25;
};

void(string itemmodel) PlaceItem = {
	setmodel(self, itemmodel);
	setsize(self, '-16 -16 0', '16 16 56');
	self.solid = SOLID_TRIGGER;
	self.movetype = MOVETYPE_NONE;
	droptofloor();
};

void() item_health1  = { PlaceItem("maps/b_bh25.bsp"); self.touch = health_touch; };
void() item_shells   = { PlaceItem("maps/b_shell0.bsp"); self.touch = ammo_touch; };
void() weapon_shotgun = { PlaceItem("progs/g_shot.mdl"); self.touch = weapon_touch; };
