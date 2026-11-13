// ============================================================
// doors.qc — trigger-opened door that closes itself.
// Wire it: trigger_multiple "target" "exitdoor" -> func_door
// "targetname" "exitdoor". angle -1 = up, -2 = down.
// ============================================================

void() door_go_down;   // forward declaration

void() door_wait_return = {
	self.think = door_go_down;
	self.nextthink = self.ltime + self.wait;
};

void() door_go_up = {
	if (self.state) return;          // already open / opening
	self.state = 1;
	sound(self, CHAN_VOICE, "doors/airdoor1.wav", 1, ATTN_NORM);
	SUB_CalcMove(self.pos2, self.speed, door_wait_return);
};

void() door_go_down = {
	self.state = 0;
	sound(self, CHAN_VOICE, "doors/airdoor2.wav", 1, ATTN_NORM);
	SUB_CalcMove(self.pos1, self.speed, SUB_Null);
};

void() door_use = { door_go_up(); };

void() func_door = {
	local float travel;
	if (!self.speed) self.speed = 100;
	if (!self.wait) self.wait = 3;
	if (!self.lip) self.lip = 8;
	if (self.angle == -1) self.movedir = '0 0 1';
	else if (self.angle == -2) self.movedir = '0 0 -1';
	else {
		makevectors('0 1 0' * self.angle);
		self.movedir = v_forward;
		self.movedir_z = 0;
	}
	setmodel(self, self.model);
	self.solid = SOLID_BSP;
	self.movetype = MOVETYPE_PUSH;
	self.pos1 = self.origin;
	travel = self.movedir_x * self.size_x + self.movedir_y * self.size_y
		+ self.movedir_z * self.size_z - self.lip;
	if (travel < 0) travel = 0;
	self.pos2 = self.pos1 + self.movedir * travel;
	self.use = door_use;
};
