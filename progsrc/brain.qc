#include "m_brain.h"


static int  sound_chest_open;
static int  sound_tentacles_extend;
static int  sound_tentacles_retract;
static int  sound_death;
static int  sound_idle1;
static int  sound_idle2;
static int  sound_idle3;
static int  sound_pain1;
static int  sound_pain2;
static int  sound_sight;
static int  sound_search;
static int  sound_melee1;
static int  sound_melee2;
static int  sound_melee3;


static void brain_sight(entity self, entity other)
{
	gi.sound(self, CHAN_VOICE, sound_sight, 1, ATTN_NORM, 0);
}

static void brain_search(entity self)
{
	gi.sound(self, CHAN_VOICE, sound_search, 1, ATTN_NORM, 0);
}

//
// STAND
//

static mframe_t brain_frames_stand [] = {
	{ ai_stand },
	{ ai_stand },
	{ ai_stand },
	{ ai_stand },
	{ ai_stand },
	{ ai_stand },
	{ ai_stand },
	{ ai_stand },
	{ ai_stand },
	{ ai_stand },

	{ ai_stand },
	{ ai_stand },
	{ ai_stand },
	{ ai_stand },
	{ ai_stand },
	{ ai_stand },
	{ ai_stand },
	{ ai_stand },
	{ ai_stand },
	{ ai_stand },

	{ ai_stand },
	{ ai_stand },
	{ ai_stand },
	{ ai_stand },
	{ ai_stand },
	{ ai_stand },
	{ ai_stand },
	{ ai_stand },
	{ ai_stand },
	{ ai_stand }
};
static var mmove_t brain_move_stand = { FRAME_stand01, FRAME_stand30 };

static void brain_stand(entity self)
{
	self.monsterinfo.currentmove = &brain_move_stand;
}


//
// IDLE
//

static mframe_t brain_frames_idle [] = {
	{ ai_stand },
	{ ai_stand },
	{ ai_stand },
	{ ai_stand },
	{ ai_stand },
	{ ai_stand },
	{ ai_stand },
	{ ai_stand },
	{ ai_stand },
	{ ai_stand },

	{ ai_stand },
	{ ai_stand },
	{ ai_stand },
	{ ai_stand },
	{ ai_stand },
	{ ai_stand },
	{ ai_stand },
	{ ai_stand },
	{ ai_stand },
	{ ai_stand },

	{ ai_stand },
	{ ai_stand },
	{ ai_stand },
	{ ai_stand },
	{ ai_stand },
	{ ai_stand },
	{ ai_stand },
	{ ai_stand },
	{ ai_stand },
	{ ai_stand }
};
static var mmove_t brain_move_idle = { FRAME_stand31, FRAME_stand60, brain_stand };

static void brain_idle(entity self)
{
	gi.sound(self, CHAN_AUTO, sound_idle3, 1, ATTN_IDLE, 0);
	self.monsterinfo.currentmove = &brain_move_idle;
}

//
// WALK
//
static mframe_t brain_frames_walk1 [] = {
	{ ai_walk,    7 },
	{ ai_walk,    2 },
	{ ai_walk,    3 },
	{ ai_walk,    3 },
	{ ai_walk,    1 },
	{ ai_walk },
	{ ai_walk },
	{ ai_walk,    9 },
	{ ai_walk,    -4 },
	{ ai_walk,    -1 },
	{ ai_walk,    2 }
};
static var mmove_t brain_move_walk1 = { FRAME_walk101, FRAME_walk111 };

static void brain_walk(entity self) {
	self.monsterinfo.currentmove = &brain_move_walk1;
}

static mframe_t brain_frames_pain3 [] =
{
	{ ai_move,    -2 },
	{ ai_move,    2 },
	{ ai_move,    1 },
	{ ai_move,    3 },
	{ ai_move },
	{ ai_move,    -4 }
};
static var mmove_t brain_move_pain3 = { FRAME_pain301, FRAME_pain306 };

static mframe_t brain_frames_pain2 [] =
{
	{ ai_move,    -2 },
	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move,    3 },
	{ ai_move,    1 },
	{ ai_move,    -2 }
};
static var mmove_t brain_move_pain2 = { FRAME_pain201, FRAME_pain208 };

static mframe_t brain_frames_pain1 [] =
{
	{ ai_move,    -6 },
	{ ai_move,    -2 },
	{ ai_move,    -6 },
	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move,    2 },
	{ ai_move },
	{ ai_move,    2 },
	{ ai_move,    1 },
	{ ai_move,    7 },
	{ ai_move },
	{ ai_move,    3 },
	{ ai_move,    -1 }
};
static var mmove_t brain_move_pain1 = { FRAME_pain101, FRAME_pain121 };

//
// DUCK
//
#ifdef GROUND_ZERO
#define brain_duck_down monster_duck_down
#define brain_duck_hold monster_duck_hold
#define brain_duck_up monster_duck_up
#else
static void brain_duck_down(entity self) {
	if (self.monsterinfo.aiflags & AI_DUCKED)
		return;
	self.monsterinfo.aiflags |= AI_DUCKED;
	self.maxs[2] -= 32;
	self.takedamage = true;
	gi.linkentity(self);
}

static void brain_duck_hold(entity self) {
	if (level.framenum >= self.monsterinfo.pause_framenum)
		self.monsterinfo.aiflags &= ~AI_HOLD_FRAME;
	else
		self.monsterinfo.aiflags |= AI_HOLD_FRAME;
}

static void brain_duck_up(entity self) {
	self.monsterinfo.aiflags &= ~AI_DUCKED;
	self.maxs[2] += 32;
	self.takedamage = true;
	gi.linkentity(self);
}
#endif

static mframe_t brain_frames_duck [] =
{
	{ ai_move },
	{ ai_move,    -2, brain_duck_down },
	{ ai_move,    17, brain_duck_hold },
	{ ai_move,    -3 },
	{ ai_move,    -1, brain_duck_up },
	{ ai_move,    -5 },
	{ ai_move,    -6 },
	{ ai_move,    -6 }
};
static var mmove_t brain_move_duck = { FRAME_duck01, FRAME_duck08 };

#ifdef GROUND_ZERO
static void brain_duck (entity self, float eta)
{
	// has to be done immediately otherwise he can get stuck
	monster_duck_down(self);

	if (skill.intVal == 0)
		self.monsterinfo.duck_wait_framenum = level.framenum + (int)((eta + 1) * BASE_FRAMERATE);
	else
		self.monsterinfo.duck_wait_framenum = level.framenum + (int)((eta + (0.1 * (3 - skill.intVal))) * BASE_FRAMERATE);

	self.monsterinfo.currentmove = &brain_move_duck;
	self.monsterinfo.nextframe = FRAME_duck01;
}
#else
static void brain_dodge(entity self, entity attacker, float eta)
{
	if (random() > 0.25f)
		return;

	if (!self.enemy)
		self.enemy = attacker;

	self.monsterinfo.pause_framenum = level.framenum + (int)((eta + 0.5f) * BASE_FRAMERATE);
	self.monsterinfo.currentmove = &brain_move_duck;
}
#endif

static mframe_t brain_frames_death2 [] =
{
	{ ai_move},
	{ ai_move},
	{ ai_move},
	{ ai_move,    9 },
	{ ai_move }
};
static var mmove_t brain_move_death2 = { FRAME_death201, FRAME_death205 };

static mframe_t brain_frames_death1 [] =
{
	{ ai_move },
	{ ai_move },
	{ ai_move,    -2 },
	{ ai_move,    9 },
	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move }
};
static var mmove_t brain_move_death1 = { FRAME_death101, FRAME_death118 };


//
// MELEE
//

static void brain_swing_right(entity self) {
	gi.sound(self, CHAN_BODY, sound_melee1, 1, ATTN_NORM, 0);
}

static void brain_hit_right(entity self) {
	const vector  aim = [MELEE_DISTANCE, self.maxs.x, 8 ];
	if (fire_hit(self, aim, (15 + (Q_rand() % 5)), 40))
		gi.sound(self, CHAN_WEAPON, sound_melee3, 1, ATTN_NORM, 0);
}

static void brain_swing_left(entity self) {
	gi.sound(self, CHAN_BODY, sound_melee2, 1, ATTN_NORM, 0);
}

static void brain_hit_left(entity self) {
	const vector  aim = [ MELEE_DISTANCE, self.mins.x, 8 ];
	if (fire_hit(self, aim, (15 + (Q_rand() % 5)), 40))
		gi.sound(self, CHAN_WEAPON, sound_melee3, 1, ATTN_NORM, 0);
}

static mframe_t brain_frames_attack1 [] =
{
	{ ai_charge,  8 },
	{ ai_charge,  3 },
	{ ai_charge,  5 },
	{ ai_charge },
	{ ai_charge,  -3, brain_swing_right },
	{ ai_charge },
	{ ai_charge,  -5 },
	{ ai_charge,  -7, brain_hit_right },
	{ ai_charge },
	{ ai_charge,  6,  brain_swing_left },
	{ ai_charge,  1 },
	{ ai_charge,  2,  brain_hit_left },
	{ ai_charge,  -3 },
	{ ai_charge,  6 },
	{ ai_charge,  -1 },
	{ ai_charge,  -3 },
	{ ai_charge,  2 },
	{ ai_charge,  -11 }
};
static var mmove_t brain_move_attack1 = { FRAME_attak101, FRAME_attak118 };

static void brain_chest_open(entity self) {
	self.spawnflags &= ~65536;
	self.monsterinfo.power_armor_type = POWER_ARMOR_NONE;
	gi.sound(self, CHAN_BODY, sound_chest_open, 1, ATTN_NORM, 0);
}

static void brain_tentacle_attack(entity self) {
	static const vector aim = [ MELEE_DISTANCE, 0, 8 ];
	if (fire_hit(self, aim, (10 + (Q_rand() % 5)), -600) && skill.intVal > 0)
		self.spawnflags |= 65536;
	gi.sound(self, CHAN_WEAPON, sound_tentacles_retract, 1, ATTN_NORM, 0);
}

static void brain_chest_closed(entity self) {
	self.monsterinfo.power_armor_type = POWER_ARMOR_SCREEN;
	if (self.spawnflags & 65536) {
		self.spawnflags &= ~65536;
		self.monsterinfo.currentmove = &brain_move_attack1;
	}
}

static mframe_t brain_frames_attack2 [] =
{
	{ ai_charge,  5 },
	{ ai_charge,  -4 },
	{ ai_charge,  -4 },
	{ ai_charge,  -3 },
	{ ai_charge,  0,  brain_chest_open },
	{ ai_charge },
	{ ai_charge,  13, brain_tentacle_attack },
	{ ai_charge },
	{ ai_charge,  2 },
	{ ai_charge },
	{ ai_charge,  -9, brain_chest_closed },
	{ ai_charge },
	{ ai_charge,  4 },
	{ ai_charge,  3 },
	{ ai_charge,  2 },
	{ ai_charge,  -3 },
	{ ai_charge,  -6 }
};
static var mmove_t brain_move_attack2 = { FRAME_attak201, FRAME_attak217 };

static void brain_melee(entity self) {
	if (random() <= 0.5f)
		self.monsterinfo.currentmove = &brain_move_attack1;
	else
		self.monsterinfo.currentmove = &brain_move_attack2;
}

#ifdef THE_RECKONING
static bool(vector start, vector end) brain_tounge_attack_ok =
{
	vector	dir, angles;

	// check for max distance
	dir = start - end;
	if (VectorLength(dir) > 512)
		return false;

	// check for min/max pitch
	angles = vectoangles (dir);
	if (angles[0] < -180)
		angles[0] += 360;
	if (fabs(angles[0]) > 30)
		return false;

	return true;
}

static void(entity self) brain_tounge_attack =
{
	vector offset, start, f, r, end, dir;
	trace_t	tr;
	int damage;

	AngleVectors (self.s.angles, &f, &r, 0);
	offset = [ 24, 0, 16 ];
	start = G_ProjectSource (self.s.origin, offset, f, r);

	end = self.enemy.s.origin;
	if (!brain_tounge_attack_ok(start, end))
	{
		end[2] = self.enemy.s.origin[2] + self.enemy.maxs[2] - 8;
		if (!brain_tounge_attack_ok(start, end))
		{
			end[2] = self.enemy.s.origin[2] + self.enemy.mins[2] + 8;
			if (!brain_tounge_attack_ok(start, end))
				return;
		}
	}
	end = self.enemy.s.origin;

	gi.traceline(&tr, start, end, self, MASK_SHOT);
	if (tr.ent != self.enemy)
		return;

	damage = 5;
	gi.sound (self, CHAN_WEAPON, sound_tentacles_retract, 1, ATTN_NORM, 0);

	gi.WriteByte (svc_temp_entity);
	gi.WriteByte (TE_PARASITE_ATTACK);
	gi.WriteShort (self.s.number);
	gi.WritePosition (start);
	gi.WritePosition (end);
	gi.multicast (self.s.origin, MULTICAST_PVS);

	dir = start - end;
	T_Damage (self.enemy, self, self, dir, self.enemy.s.origin, vec3_origin, damage, 0, DAMAGE_NO_KNOCKBACK, MOD_BRAINTENTACLE);

	// pull the enemy in
	{
		vector forward;
		self.s.origin[2] += 1;
		AngleVectors (self.s.angles, &forward, 0, 0);
		self.enemy.velocity = forward * -1200;
	}
	
}

// Brian right eye center
PROGS_LOCAL_STATIC const vector brain_reye [11] = {
	[ 0.746700, 0.238370, 34.167690 ],
	[ -1.076390, 0.238370, 33.386372 ],
	[ -1.335500, 5.334300, 32.177170 ],
	[ -0.175360, 8.846370, 30.635479 ],
	[ -2.757590, 7.804610, 30.150860 ],
	[ -5.575090, 5.152840, 30.056160 ],
	[ -7.017550, 3.262470, 30.552521 ],
	[ -7.915740, 0.638800, 33.176189 ],
	[ -3.915390, 8.285730, 33.976349 ],
	[ -0.913540, 10.933030, 34.141811 ],
	[ -0.369900, 8.923900, 34.189079 ]
};

// Brain left eye center
PROGS_LOCAL_STATIC const vector brain_leye [11] = {
	[ -3.364710, 0.327750, 33.938381 ],
	[ -5.140450, 0.493480, 32.659851 ],
	[ -5.341980, 5.646980, 31.277901 ],
	[ -4.134480, 9.277440, 29.925621 ],
	[ -6.598340, 6.815090, 29.322620 ],
	[ -8.610840, 2.529650, 29.251591 ],
	[ -9.231360, 0.093280, 29.747959 ],
	[ -11.004110, 1.936930, 32.395260 ],
	[ -7.878310, 7.648190, 33.148151 ],
	[ -4.947370, 11.430050, 33.313610 ],
	[ -4.332820, 9.444570, 33.526340 ]
};

// note to self
// need to get an x,y,z offset for
// each frame of the run cycle
static void(entity self) brain_laserbeam =
{
	vector	forward, right, up;
	vector	tempang, start;
	vector	dir, angles, end;
	entity	ent;

	// RAFAEL
	// cant call sound this frequent
	if (random() > 0.8)
		gi.sound(self, CHAN_AUTO, gi.soundindex("misc/lasfly.wav"), 1, ATTN_STATIC, 0);

	// check for max distance
	
	start = self.s.origin;
	end = self.enemy.s.origin;
	dir = end - start;
	angles = vectoangles(dir);
	
	// dis is my right eye
	ent = G_Spawn ();
	ent.s.origin = self.s.origin;
	tempang = angles;
	AngleVectors (tempang, &forward, &right, &up);
	ent.s.angles = tempang;
	start = ent.s.origin;
	start += brain_reye[self.s.frame - FRAME_walk101][0] * right;
	start += brain_reye[self.s.frame - FRAME_walk101][1] * forward;
	start += brain_reye[self.s.frame - FRAME_walk101][2] * up;
	ent.s.origin = start;
	ent.enemy = self.enemy;
	ent.owner = self;
	ent.dmg = 1;
	monster_dabeam (ent);
   
	// dis is me left eye
	ent = G_Spawn ();  
	ent.s.origin = self.s.origin;
	tempang = angles;
	AngleVectors (tempang, &forward, &right, &up);
	ent.s.angles = tempang;
	start = ent.s.origin;
	start += brain_leye[self.s.frame - FRAME_walk101][0] * right;
	start += brain_leye[self.s.frame - FRAME_walk101][1] * forward;
	start += brain_leye[self.s.frame - FRAME_walk101][2] * up;
	ent.s.origin = start;
	ent.enemy = self.enemy;
	ent.owner = self;
	ent.dmg = 1;
	monster_dabeam (ent);
	
}

static void(entity self) brain_laserbeam_reattack =
{
	if (random() < 0.5)
		if (visible (self, self.enemy))
			if (self.enemy.health > 0)
				self.s.frame = FRAME_walk101;
}


static mframe_t brain_frames_attack3 [] =
{
	{ ai_charge,	5 },
	{ ai_charge,	-4 },
	{ ai_charge,	-4 },
	{ ai_charge,	-3 },
	{ ai_charge,	0,	brain_chest_open },
	{ ai_charge,	0,	brain_tounge_attack },
	{ ai_charge,	13 },
	{ ai_charge,	0,	brain_tentacle_attack },
	{ ai_charge,	2 },
	{ ai_charge,	0,	brain_tounge_attack },
	{ ai_charge,	-9,	brain_chest_closed },
	{ ai_charge },
	{ ai_charge,	4 },
	{ ai_charge,	3 },
	{ ai_charge,	2 },
	{ ai_charge,	-3 },
	{ ai_charge,	-6 }
};
static var mmove_t brain_move_attack3 = { FRAME_attak201, FRAME_attak217 };

static mframe_t brain_frames_attack4 [] =
{
	{ ai_charge,	9,	brain_laserbeam },
	{ ai_charge,	2,	brain_laserbeam },
	{ ai_charge,	3,	brain_laserbeam },
	{ ai_charge,	3,	brain_laserbeam },
	{ ai_charge,	1,	brain_laserbeam },
	{ ai_charge,	0,	brain_laserbeam },
	{ ai_charge,	0,	brain_laserbeam },
	{ ai_charge,	10,	brain_laserbeam },
	{ ai_charge,	-4,	brain_laserbeam },
	{ ai_charge,	-1,	brain_laserbeam },
	{ ai_charge,	2,	brain_laserbeam_reattack }
};
static var mmove_t brain_move_attack4 = { FRAME_walk101, FRAME_walk111 };

// RAFAEL
static void(entity self) brain_attack =
{
	int r;
	
	if (random() < 0.8)
	{
		r = range (self, self.enemy);
		if (r == RANGE_NEAR)
		{
			if (random() < 0.5)
				self.monsterinfo.currentmove = &brain_move_attack3;
			else 
				self.monsterinfo.currentmove = &brain_move_attack4;
		}
		else if (r > RANGE_NEAR)
			self.monsterinfo.currentmove = &brain_move_attack4;
	}
	
}
#endif

//
// RUN
//

static mframe_t brain_frames_run [] =
{
	{ ai_run, 9 },
	{ ai_run, 2 },
	{ ai_run, 3 },
	{ ai_run, 3 },
	{ ai_run, 1 },
	{ ai_run },
	{ ai_run },
	{ ai_run, 10 },
	{ ai_run, -4 },
	{ ai_run, -1 },
	{ ai_run, 2 }
};
static var mmove_t brain_move_run = { FRAME_walk101, FRAME_walk111 };

static void brain_run(entity self) {
	self.monsterinfo.power_armor_type = POWER_ARMOR_SCREEN;
	if (self.monsterinfo.aiflags & AI_STAND_GROUND)
		self.monsterinfo.currentmove = &brain_move_stand;
	else
		self.monsterinfo.currentmove = &brain_move_run;
}

static void brain_pain(entity self, entity other, float kick, int damage) {
	float   r;

	if (self.health < (self.max_health / 2))
		self.s.skinnum = 1;

	if (level.framenum < self.pain_debounce_framenum)
		return;

	self.pain_debounce_framenum = level.framenum + 3 * BASE_FRAMERATE;
	if (skill.intVal == 3)
		return;     // no pain anims in nightmare

	r = random();
	if (r < 0.33f) {
		gi.sound(self, CHAN_VOICE, sound_pain1, 1, ATTN_NORM, 0);
		self.monsterinfo.currentmove = &brain_move_pain1;
	} else if (r < 0.66f) {
		gi.sound(self, CHAN_VOICE, sound_pain2, 1, ATTN_NORM, 0);
		self.monsterinfo.currentmove = &brain_move_pain2;
	} else {
		gi.sound(self, CHAN_VOICE, sound_pain1, 1, ATTN_NORM, 0);
		self.monsterinfo.currentmove = &brain_move_pain3;
	}
}

static void brain_dead(entity self) {
	self.mins = '-16 -16 -24';
	self.maxs = '16 16 -8';
	self.movetype = MOVETYPE_TOSS;
	self.svflags |= SVF_DEADMONSTER;
	self.nextthink = 0;
	gi.linkentity(self);
}

static void brain_die(entity self, entity inflictor, entity attacker, int damage, vector point) {
	int     n;

	self.s.effects = 0;
	self.monsterinfo.power_armor_type = POWER_ARMOR_NONE;

// check for gib
	if (self.health <= self.gib_health) {
		gi.sound(self, CHAN_VOICE, gi.soundindex("misc/udeath.wav"), 1, ATTN_NORM, 0);
		for (n = 0; n < 2; n++)
			ThrowGib(self, "models/objects/gibs/bone/tris.md2", damage, GIB_ORGANIC);
		for (n = 0; n < 4; n++)
			ThrowGib(self, "models/objects/gibs/sm_meat/tris.md2", damage, GIB_ORGANIC);
		ThrowHead(self, "models/objects/gibs/head2/tris.md2", damage, GIB_ORGANIC);
		self.deadflag = DEAD_DEAD;
		return;
	}

	if (self.deadflag == DEAD_DEAD)
		return;

// regular death
	gi.sound(self, CHAN_VOICE, sound_death, 1, ATTN_NORM, 0);
	self.deadflag = DEAD_DEAD;
	self.takedamage = true;
	if (random() <= 0.5f)
		self.monsterinfo.currentmove = &brain_move_death1;
	else
		self.monsterinfo.currentmove = &brain_move_death2;
}

/*QUAKED monster_brain (1 .5 0) (-16 -16 -24) (16 16 32) Ambush Trigger_Spawn Sight
*/
API_FUNC static void SP_monster_brain(entity self) {
	if (deathmatch.intVal) {
		G_FreeEdict(self);
		return;
	}
	
	if (!brain_move_stand.frame)
	{
		brain_move_stand.frame = &brain_frames_stand;
		brain_move_idle.frame = &brain_frames_idle;
		brain_move_walk1.frame = &brain_frames_walk1;
		brain_move_pain1.frame = &brain_frames_pain1;
		brain_move_pain1.endfunc = brain_run;
		brain_move_pain2.frame = &brain_frames_pain2;
		brain_move_pain2.endfunc = brain_run;
		brain_move_pain3.frame = &brain_frames_pain3;
		brain_move_pain3.endfunc = brain_run;
		brain_move_duck.frame = &brain_frames_duck;
		brain_move_duck.endfunc = brain_run;
		brain_move_death1.frame = &brain_frames_death1;
		brain_move_death1.endfunc = brain_dead;
		brain_move_death2.frame = &brain_frames_death2;
		brain_move_death2.endfunc = brain_dead;
		brain_move_attack1.frame = &brain_frames_attack1;
		brain_move_attack1.endfunc = brain_run;
		brain_move_attack2.frame = &brain_frames_attack2;
		brain_move_attack2.endfunc = brain_run;
		brain_move_run.frame = &brain_frames_run;

#ifdef THE_RECKONING
		brain_move_attack3.frame = &brain_frames_attack3;
		brain_move_attack3.endfunc = brain_run;
		brain_move_attack4.frame = &brain_frames_attack4;
		brain_move_attack4.endfunc = brain_run;
#endif
	}

	sound_chest_open = gi.soundindex("brain/brnatck1.wav");
	sound_tentacles_extend = gi.soundindex("brain/brnatck2.wav");
	sound_tentacles_retract = gi.soundindex("brain/brnatck3.wav");
	sound_death = gi.soundindex("brain/brndeth1.wav");
	sound_idle1 = gi.soundindex("brain/brnidle1.wav");
	sound_idle2 = gi.soundindex("brain/brnidle2.wav");
	sound_idle3 = gi.soundindex("brain/brnlens1.wav");
	sound_pain1 = gi.soundindex("brain/brnpain1.wav");
	sound_pain2 = gi.soundindex("brain/brnpain2.wav");
	sound_sight = gi.soundindex("brain/brnsght1.wav");
	sound_search = gi.soundindex("brain/brnsrch1.wav");
	sound_melee1 = gi.soundindex("brain/melee1.wav");
	sound_melee2 = gi.soundindex("brain/melee2.wav");
	sound_melee3 = gi.soundindex("brain/melee3.wav");

	self.movetype = MOVETYPE_STEP;
	self.solid = SOLID_BBOX;
	self.s.modelindex = gi.modelindex("models/monsters/brain/tris.md2");
	self.mins = '-16 -16 -24';
	self.maxs = '16 16 32';

	self.health = 300;
	self.gib_health = -150;
	self.mass = 400;

	self.pain = brain_pain;
	self.die = brain_die;

	self.monsterinfo.stand = brain_stand;
	self.monsterinfo.walk = brain_walk;
	self.monsterinfo.run = brain_run;
#ifdef GROUND_ZERO
	self.monsterinfo.dodge = M_MonsterDodge;
	self.monsterinfo.duck = brain_duck;
	self.monsterinfo.unduck = monster_duck_up;
#else
	self.monsterinfo.dodge = brain_dodge;
#endif
#ifdef THE_RECKONING
	self.monsterinfo.attack = brain_attack;
#endif
	self.monsterinfo.melee = brain_melee;
	self.monsterinfo.sight = brain_sight;
	self.monsterinfo.search = brain_search;
	self.monsterinfo.idle = brain_idle;

	self.monsterinfo.power_armor_type = POWER_ARMOR_SCREEN;
	self.monsterinfo.power_armor_power = 100;

	gi.linkentity(self);

	self.monsterinfo.currentmove = &brain_move_stand;
	self.monsterinfo.scale = MODEL_SCALE;

	walkmonster_start(self);
}
