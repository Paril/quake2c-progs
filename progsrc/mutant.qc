#include "m_mutant.h"

static int  sound_swing;
static int  sound_hit;
static int  sound_hit2;
static int  sound_death;
static int  sound_idle;
static int  sound_pain1;
static int  sound_pain2;
static int  sound_sight;
static int  sound_search;
static int  sound_step1;
static int  sound_step2;
static int  sound_step3;
static int  sound_thud;

//
// SOUNDS
//
static void mutant_step(entity self)
{
	int     n;
	n = (Q_rand() + 1) % 3;
	if (n == 0)
		gi.sound(self, CHAN_VOICE, sound_step1, 1, ATTN_NORM, 0);
	else if (n == 1)
		gi.sound(self, CHAN_VOICE, sound_step2, 1, ATTN_NORM, 0);
	else
		gi.sound(self, CHAN_VOICE, sound_step3, 1, ATTN_NORM, 0);
}

static void mutant_sight(entity self, entity other)
{
	gi.sound(self, CHAN_VOICE, sound_sight, 1, ATTN_NORM, 0);
}

static void mutant_search(entity self)
{
	gi.sound(self, CHAN_VOICE, sound_search, 1, ATTN_NORM, 0);
}

static void mutant_swing(entity self)
{
	gi.sound(self, CHAN_VOICE, sound_swing, 1, ATTN_NORM, 0);
}


//
// STAND
//

static mframe_t mutant_frames_stand [] = {
	{ ai_stand },
	{ ai_stand },
	{ ai_stand },
	{ ai_stand },
	{ ai_stand },
	{ ai_stand },
	{ ai_stand },
	{ ai_stand },
	{ ai_stand },
	{ ai_stand },      // 10

	{ ai_stand },
	{ ai_stand },
	{ ai_stand },
	{ ai_stand },
	{ ai_stand },
	{ ai_stand },
	{ ai_stand },
	{ ai_stand },
	{ ai_stand },
	{ ai_stand },      // 20

	{ ai_stand },
	{ ai_stand },
	{ ai_stand },
	{ ai_stand },
	{ ai_stand },
	{ ai_stand },
	{ ai_stand },
	{ ai_stand },
	{ ai_stand },
	{ ai_stand },      // 30

	{ ai_stand },
	{ ai_stand },
	{ ai_stand },
	{ ai_stand },
	{ ai_stand },
	{ ai_stand },
	{ ai_stand },
	{ ai_stand },
	{ ai_stand },
	{ ai_stand },      // 40

	{ ai_stand },
	{ ai_stand },
	{ ai_stand },
	{ ai_stand },
	{ ai_stand },
	{ ai_stand },
	{ ai_stand },
	{ ai_stand },
	{ ai_stand },
	{ ai_stand },      // 50

	{ ai_stand }
};
static var mmove_t mutant_move_stand = { FRAME_stand101, FRAME_stand151 };

static void mutant_stand(entity self)
{
	self.monsterinfo.currentmove = &mutant_move_stand;
}


//
// IDLE
//

static void mutant_idle_loop(entity self)
{
	if (random() < 0.75f)
		self.monsterinfo.nextframe = FRAME_stand155;
}

static mframe_t mutant_frames_idle [] = {
	{ ai_stand },
	{ ai_stand },
	{ ai_stand },
	{ ai_stand },                  // scratch loop start
	{ ai_stand },
	{ ai_stand },
	{ ai_stand, 0, mutant_idle_loop },      // scratch loop end
	{ ai_stand },
	{ ai_stand },
	{ ai_stand },
	{ ai_stand },
	{ ai_stand },
	{ ai_stand }
};
static var mmove_t mutant_move_idle = { FRAME_stand152, FRAME_stand164, mutant_stand };

static void mutant_idle(entity self)
{
	self.monsterinfo.currentmove = &mutant_move_idle;
	gi.sound(self, CHAN_VOICE, sound_idle, 1, ATTN_IDLE, 0);
}


//
// WALK
//

static mframe_t mutant_frames_walk [] = {
	{ ai_walk,    3 },
	{ ai_walk,    1 },
	{ ai_walk,    5 },
	{ ai_walk,    10 },
	{ ai_walk,    13 },
	{ ai_walk,    10 },
	{ ai_walk },
	{ ai_walk,    5 },
	{ ai_walk,    6 },
	{ ai_walk,    16 },
	{ ai_walk,    15 },
	{ ai_walk,    6 }
};
static var mmove_t mutant_move_walk = { FRAME_walk05, FRAME_walk16 };

static void mutant_walk_loop(entity self)
{
	self.monsterinfo.currentmove = &mutant_move_walk;
}

static mframe_t mutant_frames_start_walk [] = {
	{ ai_walk,    5 },
	{ ai_walk,    5 },
	{ ai_walk,    -2 },
	{ ai_walk,    1 }
};
static var mmove_t mutant_move_start_walk = { FRAME_walk01, FRAME_walk04, mutant_walk_loop };

static void mutant_walk(entity self)
{
	self.monsterinfo.currentmove = &mutant_move_start_walk;
}


//
// RUN
//

static mframe_t mutant_frames_run [] = {
	{ ai_run, 40 },
	{ ai_run, 40,     mutant_step },
	{ ai_run, 24 },
	{ ai_run, 5,      mutant_step },
	{ ai_run, 17 },
	{ ai_run, 10 }
};
static var mmove_t mutant_move_run = { FRAME_run03, FRAME_run08 };

static void mutant_run(entity self)
{
	if (self.monsterinfo.aiflags & AI_STAND_GROUND)
		self.monsterinfo.currentmove = &mutant_move_stand;
	else
		self.monsterinfo.currentmove = &mutant_move_run;
}


//
// MELEE
//

static void mutant_hit_left(entity self)
{
	const vector  aim = [MELEE_DISTANCE, self.mins.x, 8 ];
	if (fire_hit(self, aim, (10 + (Q_rand() % 5)), 100))
		gi.sound(self, CHAN_WEAPON, sound_hit, 1, ATTN_NORM, 0);
	else
		gi.sound(self, CHAN_WEAPON, sound_swing, 1, ATTN_NORM, 0);
}

static void mutant_hit_right(entity self)
{
	const vector  aim = [ MELEE_DISTANCE, self.maxs.x, 8 ];
	if (fire_hit(self, aim, (10 + (Q_rand() % 5)), 100))
		gi.sound(self, CHAN_WEAPON, sound_hit2, 1, ATTN_NORM, 0);
	else
		gi.sound(self, CHAN_WEAPON, sound_swing, 1, ATTN_NORM, 0);
}

static void mutant_check_refire(entity self)
{
	if (!self.enemy || !self.enemy.inuse || self.enemy.health <= 0)
		return;

	if (((skill.intVal == 3) && (random() < 0.5f)) || (range(self, self.enemy) == RANGE_MELEE))
		self.monsterinfo.nextframe = FRAME_attack09;
}

static mframe_t mutant_frames_attack [] = {
	{ ai_charge },
	{ ai_charge },
	{ ai_charge,  0,  mutant_hit_left },
	{ ai_charge },
	{ ai_charge },
	{ ai_charge,  0,  mutant_hit_right },
	{ ai_charge,  0,  mutant_check_refire }
};
static var mmove_t mutant_move_attack = { FRAME_attack09, FRAME_attack15, mutant_run };

static void mutant_melee(entity self)
{
	self.monsterinfo.currentmove = &mutant_move_attack;
}


//
// ATTACK
//

static void mutant_jump_touch(entity self, entity other, vector plane, csurface_t surf)
{
	if (self.health <= 0) {
		self.touch = 0;
		return;
	}

	if (other.takedamage) {
		if (VectorLength(self.velocity) > 400) {
			vector  point;
			vector  normal;
			int     damage;

			normal = self.velocity;
			VectorNormalize(normal);
			point = self.s.origin + (self.maxs[0] * normal);
			damage = (int)random(40f, 50f);
			T_Damage(other, self, self, self.velocity, point, normal, damage, damage, 0, MOD_UNKNOWN);
		}
	}

	if (!M_CheckBottom(self)) {
		if (self.groundentity != null_entity) {
			self.monsterinfo.nextframe = FRAME_attack02;
			self.touch = 0;
		}
		return;
	}

	self.touch = 0;
}

void mutant_jump_takeoff(entity self)
{
	vector  forward;

	gi.sound(self, CHAN_VOICE, sound_sight, 1, ATTN_NORM, 0);
	AngleVectors(self.s.angles, &forward, 0, 0);
	self.s.origin[2] += 1;
	self.velocity = forward * 600;
	self.velocity[2] = 250f;
	self.groundentity = null_entity;
	self.monsterinfo.aiflags |= AI_DUCKED;
	self.monsterinfo.attack_finished = level.framenum + 3 * BASE_FRAMERATE;
	self.touch = mutant_jump_touch;
}

void mutant_check_landing(entity self)
{
	if (self.groundentity != null_entity) {
		gi.sound(self, CHAN_WEAPON, sound_thud, 1, ATTN_NORM, 0);
		self.monsterinfo.attack_finished = 0;
		self.monsterinfo.aiflags &= ~AI_DUCKED;
		return;
	}

	if (level.framenum > self.monsterinfo.attack_finished)
		self.monsterinfo.nextframe = FRAME_attack02;
	else
		self.monsterinfo.nextframe = FRAME_attack05;
}

static mframe_t mutant_frames_jump [] = {
	{ ai_charge },
	{ ai_charge,  17 },
	{ ai_charge,  15, mutant_jump_takeoff },
	{ ai_charge,  15 },
	{ ai_charge,  15, mutant_check_landing },
	{ ai_charge },
	{ ai_charge,   3 },
	{ ai_charge }
};
static var mmove_t mutant_move_jump = { FRAME_attack01, FRAME_attack08, mutant_run };

static void mutant_jump(entity self)
{
	self.monsterinfo.currentmove = &mutant_move_jump;
}


//
// CHECKATTACK
//

static bool mutant_check_melee(entity self)
{
	if (range(self, self.enemy) == RANGE_MELEE)
		return true;
	return false;
}

static bool mutant_check_jump(entity self)
{
	vector  v;
	float   distance;

	if (self.absmin[2] > (self.enemy.absmin[2] + 0.75f * self.enemy.size[2]))
		return false;

	if (self.absmax[2] < (self.enemy.absmin[2] + 0.25f * self.enemy.size[2]))
		return false;

	v[0] = self.s.origin[0] - self.enemy.s.origin[0];
	v[1] = self.s.origin[1] - self.enemy.s.origin[1];
	v[2] = 0;
	distance = VectorLength(v);

	if (distance < 100)
		return false;
	if (distance > 100) {
		if (random() < 0.9f)
			return false;
	}

	return true;
}

static bool mutant_checkattack(entity self)
{
	if (!self.enemy || self.enemy.health <= 0)
		return false;

	if (mutant_check_melee(self)) {
		self.monsterinfo.attack_state = AS_MELEE;
		return true;
	}

	if (mutant_check_jump(self)) {
		self.monsterinfo.attack_state = AS_MISSILE;
		// FIXME play a jump sound here
		return true;
	}

	return false;
}


//
// PAIN
//

static mframe_t mutant_frames_pain1 [] = {
	{ ai_move,    4 },
	{ ai_move,    -3 },
	{ ai_move,    -8 },
	{ ai_move,    2 },
	{ ai_move,    5 }
};
static var mmove_t mutant_move_pain1 = { FRAME_pain101, FRAME_pain105, mutant_run };

static mframe_t mutant_frames_pain2 [] = {
	{ ai_move,    -24 },
	{ ai_move,    11 },
	{ ai_move,    5 },
	{ ai_move,    -2 },
	{ ai_move,    6 },
	{ ai_move,    4 }
};
static var mmove_t mutant_move_pain2 = { FRAME_pain201, FRAME_pain206, mutant_run };

static mframe_t mutant_frames_pain3 [] = {
	{ ai_move,    -22 },
	{ ai_move,    3 },
	{ ai_move,    3 },
	{ ai_move,    2 },
	{ ai_move,    1 },
	{ ai_move,    1 },
	{ ai_move,    6 },
	{ ai_move,    3 },
	{ ai_move,    2 },
	{ ai_move },
	{ ai_move,    1 }
};
static var mmove_t mutant_move_pain3 = { FRAME_pain301, FRAME_pain311, mutant_run };

static void mutant_pain(entity self, entity other, float kick, int damage)
{
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
		self.monsterinfo.currentmove = &mutant_move_pain1;
	} else if (r < 0.66f) {
		gi.sound(self, CHAN_VOICE, sound_pain2, 1, ATTN_NORM, 0);
		self.monsterinfo.currentmove = &mutant_move_pain2;
	} else {
		gi.sound(self, CHAN_VOICE, sound_pain1, 1, ATTN_NORM, 0);
		self.monsterinfo.currentmove = &mutant_move_pain3;
	}
}


//
// DEATH
//

static void mutant_dead(entity self)
{
	self.mins = '-16 -16 -24';
	self.maxs = '16 16 -8';
	self.movetype = MOVETYPE_TOSS;
	self.svflags |= SVF_DEADMONSTER;
	gi.linkentity(self);

	M_FlyCheck(self);
}

static mframe_t mutant_frames_death1 [] = {
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
static var mmove_t mutant_move_death1 = { FRAME_death101, FRAME_death109, mutant_dead };

static mframe_t mutant_frames_death2 [] = {
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
static var mmove_t mutant_move_death2 = { FRAME_death201, FRAME_death210, mutant_dead };

static void mutant_die(entity self, entity inflictor, entity attacker, int damage, vector point)
{
	int     n;

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

	gi.sound(self, CHAN_VOICE, sound_death, 1, ATTN_NORM, 0);
	self.deadflag = DEAD_DEAD;
	self.takedamage = true;
	self.s.skinnum = 1;

	if (random() < 0.5f)
		self.monsterinfo.currentmove = &mutant_move_death1;
	else
		self.monsterinfo.currentmove = &mutant_move_death2;
}

#ifdef GROUND_ZERO
static void mutant_jump_down (entity self)
{
	vector	forward,up;

	AngleVectors (self.s.angles, &forward, 0, &up);
	self.velocity += 100 * forward;
	self.velocity += 300 * up;
}

static void mutant_jump_up (entity self)
{
	vector	forward,up;

	AngleVectors (self.s.angles, &forward, 0, &up);
	self.velocity += 200 * forward;
	self.velocity += 450 * up;
}

static void mutant_jump_wait_land (entity self)
{
	if (self.groundentity == null_entity)
		self.monsterinfo.nextframe = self.s.frame;
	else 
		self.monsterinfo.nextframe = self.s.frame + 1;
}

static mframe_t mutant_frames_jump_up [] =
{
	{ ai_move, -8 },
	{ ai_move, -8, mutant_jump_up },
	{ ai_move, 0, mutant_jump_wait_land },
	{ ai_move },
	{ ai_move }
};
static var mmove_t mutant_move_jump_up = { FRAME_jump01, FRAME_jump05, mutant_run };

static mframe_t mutant_frames_jump_down [] =
{
	{ ai_move },
	{ ai_move, 0, mutant_jump_down },
	{ ai_move, 0, mutant_jump_wait_land },
	{ ai_move },
	{ ai_move }
};
static var mmove_t mutant_move_jump_down = { FRAME_jump01, FRAME_jump05, mutant_run };

static void mutant_jump_updown (entity self)
{
	if(!self.enemy)
		return;

	if(self.enemy.s.origin[2] > self.s.origin[2])
		self.monsterinfo.currentmove = &mutant_move_jump_up;
	else
		self.monsterinfo.currentmove = &mutant_move_jump_down;
}

/*
===
Blocked
===
*/
static bool mutant_blocked (entity self, float dist)
{
	if(blocked_checkjump (self, dist, 256, 68))
	{
		mutant_jump_updown (self);
		return true;
	}

	if(blocked_checkplat (self, dist))
		return true;

	return false;	// Knightmare- warning fix
}
#endif

//
// SPAWN
//

/*QUAKED monster_mutant (1 .5 0) (-32 -32 -24) (32 32 32) Ambush Trigger_Spawn Sight
*/
API_FUNC static void SP_monster_mutant(entity self)
{
	if (deathmatch.intVal) {
		G_FreeEdict(self);
		return;
	}
	
	if (!mutant_move_stand.frame)
	{
		mutant_move_stand.frame = &mutant_frames_stand;
		mutant_move_idle.frame = &mutant_frames_idle;
		mutant_move_walk.frame = &mutant_frames_walk;
		mutant_move_start_walk.frame = &mutant_frames_start_walk;
		mutant_move_run.frame = &mutant_frames_run;
		mutant_move_attack.frame = &mutant_frames_attack;
		mutant_move_jump.frame = &mutant_frames_jump;
		mutant_move_pain1.frame = &mutant_frames_pain1;
		mutant_move_pain2.frame = &mutant_frames_pain2;
		mutant_move_pain3.frame = &mutant_frames_pain3;
		mutant_move_death1.frame = &mutant_frames_death1;
		mutant_move_death2.frame = &mutant_frames_death2;

#ifdef GROUND_ZERO
		mutant_move_jump_up.frame = &mutant_frames_jump_up;
		mutant_move_jump_down.frame = &mutant_frames_jump_down;
#endif
	}

	sound_swing = gi.soundindex("mutant/mutatck1.wav");
	sound_hit = gi.soundindex("mutant/mutatck2.wav");
	sound_hit2 = gi.soundindex("mutant/mutatck3.wav");
	sound_death = gi.soundindex("mutant/mutdeth1.wav");
	sound_idle = gi.soundindex("mutant/mutidle1.wav");
	sound_pain1 = gi.soundindex("mutant/mutpain1.wav");
	sound_pain2 = gi.soundindex("mutant/mutpain2.wav");
	sound_sight = gi.soundindex("mutant/mutsght1.wav");
	sound_search = gi.soundindex("mutant/mutsrch1.wav");
	sound_step1 = gi.soundindex("mutant/step1.wav");
	sound_step2 = gi.soundindex("mutant/step2.wav");
	sound_step3 = gi.soundindex("mutant/step3.wav");
	sound_thud = gi.soundindex("mutant/thud1.wav");

	self.movetype = MOVETYPE_STEP;
	self.solid = SOLID_BBOX;
	self.s.modelindex = gi.modelindex("models/monsters/mutant/tris.md2");
	self.mins = '-32 -32 -24';
	self.maxs = '32 32 48';

	self.health = 300;
	self.gib_health = -120;
	self.mass = 300;

	self.pain = mutant_pain;
	self.die = mutant_die;

	self.monsterinfo.stand = mutant_stand;
	self.monsterinfo.walk = mutant_walk;
	self.monsterinfo.run = mutant_run;
	self.monsterinfo.dodge = 0;
#ifdef GROUND_ZERO
	self.monsterinfo.blocked = mutant_blocked;
#endif
	self.monsterinfo.attack = mutant_jump;
	self.monsterinfo.melee = mutant_melee;
	self.monsterinfo.sight = mutant_sight;
	self.monsterinfo.search = mutant_search;
	self.monsterinfo.idle = mutant_idle;
	self.monsterinfo.checkattack = mutant_checkattack;

	gi.linkentity(self);

	self.monsterinfo.currentmove = &mutant_move_stand;

	self.monsterinfo.scale = MODEL_SCALE;
	walkmonster_start(self);
}
