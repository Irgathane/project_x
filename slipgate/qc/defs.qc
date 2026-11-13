// ============================================================
// defs.qc — engine interface: globals, entity fields, builtins.
// Names here must match what the engine expects. Do not rename.
// ============================================================

// ---- globals the engine writes ----
entity self, other, world;
float  time, frametime, force_retouch;
string mapname, startspot;
float  deathmatch, coop, teamplay, serverflags;
float  total_secrets, total_monsters, found_secrets, killed_monsters;
float  parm1, parm2, parm3, parm4, parm5, parm6, parm7, parm8;
float  parm9, parm10, parm11, parm12, parm13, parm14, parm15, parm16;
vector v_forward, v_up, v_right;
float  trace_allsolid, trace_startsolid, trace_fraction, trace_inopen, trace_inwater;
entity trace_ent;
vector trace_endpos, trace_plane_normal;
float  trace_plane_dist;
entity msg_entity;
float  skill;

// ---- kit globals ----
entity activator;
float  intermission_running, intermission_end;
string nextmap;

// ---- entity fields the engine reads/writes ----
.float modelindex;
.vector absmin, absmax;
.float ltime;
.float movetype, solid;
.vector origin, oldorigin, velocity, angles, avelocity, punchangle;
.string classname, model;
.float frame, skin, effects;
.vector mins, maxs, size;
.void() touch, use, think;
.float nextthink;
.entity groundentity;
.float health, frags, weapon;
.string weaponmodel;
.float weaponframe, currentammo;
.float ammo_shells, ammo_nails, ammo_rockets, ammo_cells;
.float items;
.float takedamage;
.entity chain;
.float deadflag;
.vector view_ofs;
.float button0, button1, button2, impulse;
.float fixangle;
.vector v_angle;
.float idealpitch, flags, colormap, team, max_health, teleport_time;
.float armortype, armorvalue, waterlevel, watertype, ideal_yaw, yaw_speed;
.entity goalentity, enemy, owner, dmg_inflictor, aiment;
.float spawnflags;
.string target, targetname, netname;
.vector movedir;
.string message, noise, noise1, noise2, noise3;
.float dmg_take, dmg_save;

// ---- map keys + kit fields ----
.float cnt, wait, delay, speed, lip, angle, light, sounds, style, dmg;
.string wad, killtarget, map, mdl;
.float state, attack_finished, pain_finished, respawn_at;
.float weaponanim_next, anim_next, anim_frame, air_finished;
.vector pos1, pos2, finaldest;
.void() think1, th_stand, th_walk, th_melee, th_die;
.void(entity, float) th_pain;

// ---- constants ----
float TRUE = 1, FALSE = 0;
float MOVETYPE_NONE = 0, MOVETYPE_WALK = 3, MOVETYPE_FLY = 4;
float MOVETYPE_TOSS = 5, MOVETYPE_STEP = 6, MOVETYPE_PUSH = 7, MOVETYPE_NOCLIP = 8;
float SOLID_NOT = 0, SOLID_TRIGGER = 1, SOLID_BBOX = 2, SOLID_SLIDEBOX = 3, SOLID_BSP = 4;
float FL_CLIENT = 8, FL_MONSTER = 32, FL_ITEM = 256, FL_ONGROUND = 512;
float FL_GODMODE = 64, FL_NOTARGET = 128;
float DEAD_NO = 0, DEAD_DYING = 1, DEAD_DEAD = 2;
float DAMAGE_NO = 0, DAMAGE_YES = 1, DAMAGE_AIM = 2;
float CHAN_AUTO = 0, CHAN_WEAPON = 1, CHAN_VOICE = 2, CHAN_ITEM = 3, CHAN_BODY = 4;
float ATTN_NONE = 0, ATTN_NORM = 1, ATTN_IDLE = 2, ATTN_STATIC = 3;
float CONTENT_EMPTY = -1, CONTENT_SOLID = -2, CONTENT_WATER = -3;
float CONTENT_SLIME = -4, CONTENT_LAVA = -5, CONTENT_SKY = -6;
float PRINT_LOW = 0, PRINT_MEDIUM = 1, PRINT_HIGH = 2;
float IT_SHOTGUN = 1, IT_SHELLS = 256, IT_AXE = 4096;

// ---- builtins (vanilla Quake / vkQuake safe) ----
void(vector ang) makevectors = #1;
void(entity e, vector o) setorigin = #2;
void(entity e, string m) setmodel = #3;
void(entity e, vector min, vector max) setsize = #4;
float() random = #7;
void(entity e, float chan, string samp, float vol, float atten) sound = #8;
vector(vector v) normalize = #9;
void(string e) objerror = #11;
float(vector v) vlen = #12;
float(vector v) vectoyaw = #13;
void(entity e) remove = #15;
void(vector v1, vector v2, float nomonsters, entity forent) traceline = #16;
entity() checkclient = #17;
entity(entity start, .string fld, string match) find = #18;
string(string s) precache_sound = #19;
string(string s) precache_model = #20;
void(string s, ...) bprint = #23;
void(entity client, float level, string s, ...) sprint = #24;
void(string s, ...) dprint = #25;
string(float f) ftos = #26;
string(vector v) vtos = #27;
float(float yaw, float dist) walkmove = #32;
float() droptofloor = #34;
float(float v) floor = #37;
float(float v) fabs = #42;
float(string s) cvar = #45;
void(vector o, vector d, float color, float count) particle = #48;
void() ChangeYaw = #49;
void(string s) changelevel = #70;
void(string s, ...) centerprint = #73;
