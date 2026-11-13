// ============================================================
// subs.qc — small shared helpers.
// ============================================================

void() SUB_Null = {};
void() SUB_Remove = { remove(self); };

float() crandom = { return 2 * (random() - 0.5); };

// Fire the "use" function of every entity whose targetname
// matches self.target. Classic trigger -> target wiring.
void() SUB_UseTargets = {
	local entity t, st;
	if (!self.target) return;
	st = self;
	t = world;
	while ( (t = find(t, targetname, self.target)) ) {
		if (t.use) {
			self = t;
			self.use();
			self = st;
		}
	}
};

// ---- linear movement for MOVETYPE_PUSH (doors) ----
void() SUB_CalcMoveDone = {
	setorigin(self, self.finaldest);
	self.velocity = '0 0 0';
	self.nextthink = -1;
	if (self.think1) self.think1();
};

void(vector tdest, float tspeed, void() func) SUB_CalcMove = {
	local vector vdestdelta;
	local float len, traveltime;
	if (!tspeed) objerror("SUB_CalcMove: no speed defined");
	self.think1 = func;
	self.finaldest = tdest;
	self.think = SUB_CalcMoveDone;
	vdestdelta = tdest - self.origin;
	len = vlen(vdestdelta);
	traveltime = len / tspeed;
	if (traveltime <= 0) {
		self.velocity = '0 0 0';
		self.nextthink = self.ltime + 0.1;
		return;
	}
	self.nextthink = self.ltime + traveltime;
	self.velocity = vdestdelta * (1 / traveltime);
};

// items hide on pickup, then come back
void() SUB_regen = {
	self.model = self.mdl;
	setmodel(self, self.model);
	self.solid = SOLID_TRIGGER;
};
