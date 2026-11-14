// ============================================================
// triggers.qc — invisible brush volumes from the map.
// ============================================================

void() InitTrigger = {
	if (self.model != "") setmodel(self, self.model);
	setsize(self, self.mins, self.maxs);
	self.solid = SOLID_TRIGGER;
	self.movetype = MOVETYPE_NONE;
};

void() multi_touch = {
	if (other.classname != "player") return;
	if (time < self.attack_finished) return;
	self.attack_finished = time + self.wait;
	activator = other;
	SUB_UseTargets();
};

void() trigger_multiple = {
	if (!self.wait) self.wait = 1;
	InitTrigger();
	self.touch = multi_touch;
};

void() once_touch = {
	if (other.classname != "player") return;
	activator = other;
	SUB_UseTargets();
	self.think = SUB_Remove;
	self.nextthink = time + 0.2;
};

void() trigger_once = {
	InitTrigger();
	self.touch = once_touch;
};

void() changelevel_touch = {
	if (other.classname != "player") return;
	if (intermission_running) return;
	intermission_running = 1;
	intermission_end = time + 5;
	nextmap = self.map;
	if (!nextmap) nextmap = mapname;
	centerprint(other, "SLIPGATE REACHED\n\nMonsters: ", ftos(killed_monsters),
		" / ", ftos(total_monsters), "\n\nHold on...");
	bprint(other.netname, " reached the exit\n");
};

void() trigger_changelevel = {
	InitTrigger();
	self.touch = changelevel_touch;
};
