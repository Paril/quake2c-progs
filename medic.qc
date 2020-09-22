#include "m_medic.h"

#ifdef GROUND_ZERO
const int MEDIC_MIN_DISTANCE	= 32;
const float MEDIC_MAX_HEAL_DISTANCE	= 400f;
const float MEDIC_TRY_TIME		= 10.0;
#endif

static int  sound_idle1;
static int  sound_pain1;
static int  sound_pain2;
static int  sound_die;
static int  sound_sight;
static int  sound_search;
static int  sound_hook_launch;
static int  sound_hook_hit;
static int  sound_hook_heal;
static int  sound_hook_retract;

#ifdef GROUND_ZERO
// PMM - commander sounds
static int	commander_sound_idle1;
static int	commander_sound_pain1;
static int	commander_sound_pain2;
static int	commander_sound_die;
static int	commander_sound_sight;
static int	commander_sound_search;
static int	commander_sound_hook_launch;
static int	commander_sound_hook_hit;
static int	commander_sound_hook_heal;
static int	commander_sound_hook_retract;
static int	commander_sound_spawn;

static const string reinforcements[] = {
	"monster_soldier_light",	// 0
	"monster_soldier",		// 1
	"monster_soldier_ss",		// 2
	"monster_infantry",		// 3
	"monster_gunner",			// 4
	"monster_medic",			// 5
	"monster_gladiator"		// 6
};

static const vector reinforcement_mins[] = {
	'-16 -16 -24',
	'-16 -16 -24',
	'-16 -16 -24',
	'-16 -16 -24',
	'-16 -16 -24',
	'-16 -16 -24',
	'-32 -32 -24'
};

static const vector reinforcement_maxs[] = {
	'16 16 32',
	'16 16 32',
	'16 16 32',
	'16 16 32',
	'16 16 32',
	'16 16 32',
	'32 32 64'
};

static const vector reinforcement_position[] = {
	'80 0 0',
	'40 60 0',
	'40 -60 0',
	'0 80 0',
	'0 -80 0'
};

static void cleanupHeal (entity self, bool change_frame)
{
	// clean up target, if we have one and it's legit
	if (self.enemy && self.enemy.inuse)
	{
		self.enemy.monsterinfo.healer = 0;
		self.enemy.monsterinfo.aiflags &= ~AI_RESURRECTING;
		self.enemy.takedamage = true;
		M_SetEffects (self.enemy);
	}

	if (change_frame)
		self.monsterinfo.nextframe = FRAME_attack52;
}

static void abortHeal (entity self, bool change_frame, bool gib, bool mark)
{
	int hurt;
	static const vector pain_normal = '0 0 1';

	// clean up target
	cleanupHeal (self, change_frame);
	// gib em!
	if ((mark) && (self.enemy) && (self.enemy.inuse))
	{
		// if the first badMedic slot is filled by a medic, skip it and use the second one
		if ((self.enemy.monsterinfo.badMedic1) && (self.enemy.monsterinfo.badMedic1.inuse)
			&& (!strncmp(self.enemy.monsterinfo.badMedic1.classname, "monster_medic", 13)) )
			self.enemy.monsterinfo.badMedic2 = self;
		else
			self.enemy.monsterinfo.badMedic1 = self;
	}
	if ((gib) && (self.enemy) && (self.enemy.inuse))
	{
		if(self.enemy.gib_health)
			hurt = - self.enemy.gib_health;
		else
			hurt = 500;

		T_Damage (self.enemy, self, self, vec3_origin, self.enemy.s.origin,
					pain_normal, hurt, 0, 0, MOD_UNKNOWN);
	}
	// clean up self

	self.monsterinfo.aiflags &= ~AI_MEDIC;
	if ((self.oldenemy) && (self.oldenemy.inuse))
		self.enemy = self.oldenemy;
	else
		self.enemy = 0;

	self.monsterinfo.medicTries = 0;
}
#endif

static entity medic_FindDeadMonster(entity self)
{
	entity ent = world, best = world;
	float radius = 1024;

#ifdef GROUND_ZERO
	if (self.monsterinfo.aiflags & AI_STAND_GROUND)
		radius = MEDIC_MAX_HEAL_DISTANCE;
#endif

	while ((ent = findradius(ent, self.s.origin, radius)))
	{
		if (ent == self)
			continue;
		if (!(ent.svflags & SVF_MONSTER))
			continue;
		if (ent.monsterinfo.aiflags & AI_GOOD_GUY)
			continue;
#ifdef GROUND_ZERO
		// check to make sure we haven't bailed on this guy already
		if ((ent.monsterinfo.badMedic1 == self) || (ent.monsterinfo.badMedic2 == self))
			continue;
		if (ent.monsterinfo.healer)
			// FIXME - this is correcting a bug that is somewhere else
			// if the healer is a monster, and it's in medic mode .. continue .. otherwise
			//   we will override the healer, if it passes all the other tests
			if ((ent.monsterinfo.healer.inuse) && (ent.monsterinfo.healer.health > 0) &&
				(ent.monsterinfo.healer.svflags & SVF_MONSTER) && (ent.monsterinfo.healer.monsterinfo.aiflags & AI_MEDIC))
				continue;
#else
		if (ent.owner)
			continue;
#endif
		if (ent.health > 0)
			continue;
		if (ent.nextthink)
			continue;
		if (!visible(self, ent))
			continue;
#ifdef GROUND_ZERO
		if (!strncmp(ent.classname, "player", 6))		 // stop it from trying to heal player_noise entities
			continue;
		if (realrange(self, ent) <= MEDIC_MIN_DISTANCE)
			continue;
#endif
		if !(best)
			best = ent;
		else if (ent.max_health > best.max_health)
			best = ent;
	}

#ifdef GROUND_ZERO
	if (best)
		self.timestamp = level.framenum + (int)(MEDIC_TRY_TIME * BASE_FRAMERATE);
#endif

	return best;
}

static void medic_idle(entity self)
{
	entity ent;

#ifdef GROUND_ZERO
	if (self.mass > 400)
		gi.sound (self, CHAN_VOICE, commander_sound_idle1, 1, ATTN_IDLE, 0);
	else
#endif
		gi.sound(self, CHAN_VOICE, sound_idle1, 1, ATTN_IDLE, 0);

#ifdef GROUND_ZERO
	if (!self.oldenemy)
	{
#endif
		ent = medic_FindDeadMonster(self);
		if (ent)
		{
#ifdef GROUND_ZERO
			self.oldenemy = self.enemy;
#endif
			self.enemy = ent;
#ifdef GROUND_ZERO
			self.enemy.monsterinfo.healer = self;
#else
			self.enemy.owner = self;
#endif
			self.monsterinfo.aiflags |= AI_MEDIC;
			FoundTarget(self);
		}
#ifdef GROUND_ZERO
	}
#endif
}

static void medic_search(entity self)
{
	entity ent;

#ifdef GROUND_ZERO
	if (self.mass > 400)
		gi.sound (self, CHAN_VOICE, commander_sound_search, 1, ATTN_IDLE, 0);
	else
#endif
		gi.sound(self, CHAN_VOICE, sound_search, 1, ATTN_IDLE, 0);

	if (!self.oldenemy) {
		ent = medic_FindDeadMonster(self);
		if (ent)
		{
			self.oldenemy = self.enemy;
			self.enemy = ent;
#ifdef GROUND_ZERO
			self.enemy.monsterinfo.healer = self;
#else
			self.enemy.owner = self;
#endif
			self.monsterinfo.aiflags |= AI_MEDIC;
			FoundTarget(self);
		}
	}
}

static void medic_sight(entity self, entity other)
{
#ifdef GROUND_ZERO
	if (self.mass > 400)
		gi.sound (self, CHAN_VOICE, commander_sound_sight, 1, ATTN_NORM, 0);
	else
#endif
		gi.sound(self, CHAN_VOICE, sound_sight, 1, ATTN_NORM, 0);
}


static mframe_t medic_frames_stand [] = {
	{ ai_stand, 0, medic_idle },
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
	{ ai_stand },
	{ ai_stand },

};
static var mmove_t medic_move_stand = { FRAME_wait1, FRAME_wait90 };

static void medic_stand(entity self)
{
	self.monsterinfo.currentmove = &medic_move_stand;
}

static mframe_t medic_frames_walk [] = {
	{ ai_walk, 6.2 },
	{ ai_walk, 18.1 },
	{ ai_walk, 1 },
	{ ai_walk, 9 },
	{ ai_walk, 10 },
	{ ai_walk, 9 },
	{ ai_walk, 11 },
	{ ai_walk, 11.6 },
	{ ai_walk, 2 },
	{ ai_walk, 9.9 },
	{ ai_walk, 14 },
	{ ai_walk, 9.3 }
};
static var mmove_t medic_move_walk = { FRAME_walk1, FRAME_walk12 };

static void medic_walk(entity self)
{
	self.monsterinfo.currentmove = &medic_move_walk;
}

static mframe_t medic_frames_run [] = {
	{ ai_run, 18 },
	{ ai_run, 22.5 },
	{ ai_run, 25.4
#ifdef GROUND_ZERO
		, monster_done_dodge
#endif
	},
	{ ai_run, 23.4 },
	{ ai_run, 24 },
	{ ai_run, 35.6 }

};
static var mmove_t medic_move_run = { FRAME_run1, FRAME_run6 };

static void medic_run(entity self)
{
#ifdef GROUND_ZERO
	monster_done_dodge (self);
#endif

	if (!(self.monsterinfo.aiflags & AI_MEDIC)) {
		entity ent;

		ent = medic_FindDeadMonster(self);
		if (ent)
		{
			self.oldenemy = self.enemy;
			self.enemy = ent;
#ifdef GROUND_ZERO
			self.enemy.monsterinfo.healer = self;
#else
			self.enemy.owner = self;
#endif
			self.monsterinfo.aiflags |= AI_MEDIC;
			FoundTarget(self);
			return;
		}
	}

	if (self.monsterinfo.aiflags & AI_STAND_GROUND)
		self.monsterinfo.currentmove = &medic_move_stand;
	else
		self.monsterinfo.currentmove = &medic_move_run;
}


static mframe_t medic_frames_pain1 [] = {
	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move }
};
static var mmove_t medic_move_pain1 = { FRAME_paina1, FRAME_paina8, medic_run };

static mframe_t medic_frames_pain2 [] = {
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
	{ ai_move },
	{ ai_move }
};
static var mmove_t medic_move_pain2 = { FRAME_painb1, FRAME_painb15, medic_run };

static void medic_pain(entity self, entity other, float kick, int damage)
{
#ifdef GROUND_ZERO
	monster_done_dodge (self);
#endif

	if (self.health < (self.max_health / 2))
#ifdef GROUND_ZERO
		if (self.mass > 400)
			self.s.skinnum = 3;
		else
#endif
			self.s.skinnum = 1;

	if (level.framenum < self.pain_debounce_framenum)
		return;

	self.pain_debounce_framenum = level.framenum + 3 * BASE_FRAMERATE;

	if (skill.intVal == 3)
		return;     // no pain anims in nightmare

#ifdef GROUND_ZERO
	// if we're healing someone, we ignore pain
	if (self.monsterinfo.aiflags & AI_MEDIC)
		return;

	if (self.mass > 400)
	{
		if (damage < 35)
		{
			gi.sound (self, CHAN_VOICE, commander_sound_pain1, 1, ATTN_NORM, 0);
			return;
		}

		self.monsterinfo.aiflags &= ~(AI_MANUAL_STEERING | AI_HOLD_FRAME);

		gi.sound (self, CHAN_VOICE, commander_sound_pain2, 1, ATTN_NORM, 0);

		if (random() < minf(damage * 0.005, 0.5))		// no more than 50% chance of big pain
			self.monsterinfo.currentmove = &medic_move_pain2;
		else
			self.monsterinfo.currentmove = &medic_move_pain1;
	}
	else
#endif
	if (random() < 0.5f)
	{
		self.monsterinfo.currentmove = &medic_move_pain1;
		gi.sound(self, CHAN_VOICE, sound_pain1, 1, ATTN_NORM, 0);
	}
	else
	{
		self.monsterinfo.currentmove = &medic_move_pain2;
		gi.sound(self, CHAN_VOICE, sound_pain2, 1, ATTN_NORM, 0);
	}

#ifdef GROUND_ZERO
	if (self.monsterinfo.aiflags & AI_DUCKED)
		monster_duck_up(self);
#endif
}

static void medic_fire_blaster(entity self)
{
	vector  start;
	vector  forward, right;
	vector  end;
	vector  dir;
	int     effect;
	int	damage = 2;

#ifdef GROUND_ZERO
	if (!(self.enemy && self.enemy.inuse))
		return;
#endif

	if ((self.s.frame == FRAME_attack9) || (self.s.frame == FRAME_attack12))
		effect = EF_BLASTER;
	else if ((self.s.frame == FRAME_attack19) || (self.s.frame == FRAME_attack22) || (self.s.frame == FRAME_attack25) || (self.s.frame == FRAME_attack28))
		effect = EF_HYPERBLASTER;
	else
		effect = 0;

	AngleVectors(self.s.angles, &forward, &right, 0);
	start = G_ProjectSource(self.s.origin, monster_flash_offset[MZ2_MEDIC_BLASTER_1], forward, right);

	end = self.enemy.s.origin;
	end[2] += self.enemy.viewheight;
	dir = end - start;

#ifdef GROUND_ZERO
	if (self.enemy.classname == "tesla")
		damage = 3;

	if (self.mass > 400)
		monster_fire_blaster2 (self, start, dir, damage, 1000, MZ2_MEDIC_BLASTER_2, effect);
	else
#endif
		monster_fire_blaster(self, start, dir, damage, 1000, MZ2_MEDIC_BLASTER_1, effect);
}


static void medic_dead(entity self)
{
	self.mins = '-16 -16 -24';
	self.maxs = '16 16 -8';
	self.movetype = MOVETYPE_TOSS;
	self.svflags |= SVF_DEADMONSTER;
	self.nextthink = 0;
	gi.linkentity(self);
}

static mframe_t medic_frames_death [] = {
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
	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move }
};
static var mmove_t medic_move_death = { FRAME_death1, FRAME_death30, medic_dead };

static void medic_die(entity self, entity inflictor, entity attacker, int damage, vector point)
{
	int     n;

#ifndef GROUND_ZERO
	// if we had a pending patient, free him up for another medic
	if ((self.enemy) && (self.enemy.owner == self))
		self.enemy.owner = 0;
#endif

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
#ifdef GROUND_ZERO
	if (self.mass > 400)
		gi.sound (self, CHAN_VOICE, commander_sound_die, 1, ATTN_NORM, 0);
	else
#endif
		gi.sound(self, CHAN_VOICE, sound_die, 1, ATTN_NORM, 0);
	self.deadflag = DEAD_DEAD;
	self.takedamage = true;

	self.monsterinfo.currentmove = &medic_move_death;
}

#ifdef GROUND_ZERO
#define medic_duck_down monster_duck_down
#define medic_duck_hold monster_duck_hold
#define medic_duck_up monster_duck_up
#else
static void medic_duck_down(entity self)
{
	if (self.monsterinfo.aiflags & AI_DUCKED)
		return;
	self.monsterinfo.aiflags |= AI_DUCKED;
	self.maxs[2] -= 32;
	self.takedamage = true;
	self.monsterinfo.pause_framenum = level.framenum + 1 * BASE_FRAMERATE;
	gi.linkentity(self);
}

static void medic_duck_hold(entity self)
{
	if (level.framenum >= self.monsterinfo.pause_framenum)
		self.monsterinfo.aiflags &= ~AI_HOLD_FRAME;
	else
		self.monsterinfo.aiflags |= AI_HOLD_FRAME;
}

static void medic_duck_up(entity self)
{
	self.monsterinfo.aiflags &= ~AI_DUCKED;
	self.maxs[2] += 32;
	self.takedamage = true;
	gi.linkentity(self);
}
#endif

static mframe_t medic_frames_duck [] = {
	{ ai_move, -1 },
	{ ai_move, -1 },
	{ ai_move, -1,    medic_duck_down },
	{ ai_move, -1,    medic_duck_hold },
	{ ai_move, -1 },
	{ ai_move, -1 },
#ifndef GROUND_ZERO
	{ ai_move, -1,    medic_duck_up },
#endif
	{ ai_move, -1 },
	{ ai_move, -1 },
	{ ai_move, -1 },
	{ ai_move, -1 },
	{ ai_move, -1 },
	{ ai_move, -1 },
	{ ai_move, -1 },
#ifdef GROUND_ZERO
	{ ai_move, -1,    medic_duck_up },
#endif
	{ ai_move, -1 },
	{ ai_move, -1 }
};
static var mmove_t medic_move_duck = { FRAME_duck1, FRAME_duck16, medic_run };

#ifndef GROUND_ZERO
static void medic_dodge(entity self, entity attacker, float eta)
{
	if (random() > 0.25f)
		return;

	if (!self.enemy)
		self.enemy = attacker;

	self.monsterinfo.currentmove = &medic_move_duck;
}
#endif

static mframe_t medic_frames_attackHyperBlaster [] = {
	{ ai_charge },
	{ ai_charge },
	{ ai_charge },
	{ ai_charge },
	{ ai_charge, 0,   medic_fire_blaster },
	{ ai_charge, 0,   medic_fire_blaster },
	{ ai_charge, 0,   medic_fire_blaster },
	{ ai_charge, 0,   medic_fire_blaster },
	{ ai_charge, 0,   medic_fire_blaster },
	{ ai_charge, 0,   medic_fire_blaster },
	{ ai_charge, 0,   medic_fire_blaster },
	{ ai_charge, 0,   medic_fire_blaster },
	{ ai_charge, 0,   medic_fire_blaster },
	{ ai_charge, 0,   medic_fire_blaster },
	{ ai_charge, 0,   medic_fire_blaster },
	{ ai_charge, 0,   medic_fire_blaster }
};
static var mmove_t medic_move_attackHyperBlaster = { FRAME_attack15, FRAME_attack30, medic_run };

static void medic_continue(entity self)
{
	if (visible(self, self.enemy))
		if (random() <= 0.95f)
			self.monsterinfo.currentmove = &medic_move_attackHyperBlaster;
}

static mframe_t medic_frames_attackBlaster [] = {
	{ ai_charge },
	{ ai_charge, 5 },
	{ ai_charge, 5 },
	{ ai_charge, 3 },
	{ ai_charge, 2 },
	{ ai_charge },
	{ ai_charge },
	{ ai_charge },
	{ ai_charge, 0,   medic_fire_blaster },
	{ ai_charge },
	{ ai_charge },
	{ ai_charge, 0,   medic_fire_blaster },
	{ ai_charge },
	{ ai_charge, 0,   medic_continue }  // Change to medic_continue... Else, go to frame 32
};
static var mmove_t medic_move_attackBlaster = { FRAME_attack1, FRAME_attack14, medic_run };

static void medic_hook_launch(entity self)
{
#ifdef GROUND_ZERO
	if (self.mass > 400)
		gi.sound (self, CHAN_WEAPON, commander_sound_hook_launch, 1, ATTN_NORM, 0);
	else
#endif
		gi.sound(self, CHAN_WEAPON, sound_hook_launch, 1, ATTN_NORM, 0);
}

static const vector medic_cable_offsets[] = {
	{ 45.0,  -9.2, 15.5 },
	{ 48.4,  -9.7, 15.2 },
	{ 47.8,  -9.8, 15.8 },
	{ 47.3,  -9.3, 14.3 },
	{ 45.4, -10.1, 13.1 },
	{ 41.9, -12.7, 12.0 },
	{ 37.8, -15.8, 11.2 },
	{ 34.3, -18.4, 10.7 },
	{ 32.7, -19.7, 10.4 },
	{ 32.7, -19.7, 10.4 }
};

static void medic_cable_attack(entity self)
{
	vector  offset, start, end, f, r;
	trace_t tr;
	vector  dir;
#ifndef GROUND_ZERO
	vector	angles;
#endif
	float   distance;

#ifdef GROUND_ZERO
	if ((!self.enemy) || (!self.enemy.inuse) || (self.enemy.s.effects & EF_GIB) || (self.enemy.is_client) || (self.enemy.health > 0))
	{
		abortHeal (self, true, false, false);
		return;
	}
#else
	if (!self.enemy || !self.enemy.inuse)
		return;
#endif

	AngleVectors(self.s.angles, &f, &r, 0);
	offset = medic_cable_offsets[self.s.frame - FRAME_attack42];
	start = G_ProjectSource(self.s.origin, offset, f, r);

	// check for max distance
	dir = start - self.enemy.s.origin;
	distance = VectorLength(dir);

#ifdef GROUND_ZERO
	if (distance < MEDIC_MIN_DISTANCE)
	{
		abortHeal (self, true, true, false);
		return;
	}
#else
	if (distance > 256)
		return;
#endif

	// check for min/max pitch
#ifndef GROUND_ZERO
	angles = vectoangles(dir);
	if (angles[0] < -180)
		angles[0] += 360;
	if (fabs(angles[0]) > 45)
		return;
#endif

	gi.traceline(&tr, start, self.enemy.s.origin, self, MASK_SOLID);
	if (tr.fraction != 1.0f && tr.ent != self.enemy)
	{
#ifdef GROUND_ZERO

		if (tr.ent == world)
		{
			// give up on second try
			if (self.monsterinfo.medicTries > 1)
			{
				abortHeal (self, true, false, true);
				return;
			}
			self.monsterinfo.medicTries++;
			cleanupHeal (self, 1);
			return;
		}

		abortHeal (self, true, false, false);
#endif
		return;
	}

	if (self.s.frame == FRAME_attack43)
	{
#ifdef GROUND_ZERO
		self.enemy.takedamage = false;
		M_SetEffects (self.enemy);

		if (self.mass > 400)
			gi.sound (self.enemy, CHAN_AUTO, commander_sound_hook_hit, 1, ATTN_NORM, 0);
		else
#endif
			gi.sound(self.enemy, CHAN_AUTO, sound_hook_hit, 1, ATTN_NORM, 0);
		self.enemy.monsterinfo.aiflags |= AI_RESURRECTING;
	}
	else if (self.s.frame == FRAME_attack50)
	{
		self.enemy.spawnflags = 0;
		self.enemy.monsterinfo.aiflags = 0;
		self.enemy.target = 0;
		self.enemy.targetname = 0;
		self.enemy.combattarget = 0;
		self.enemy.deathtarget = 0;
#ifdef GROUND_ZERO
		self.enemy.monsterinfo.healer = self;
#else
		self.enemy.owner = self;
#endif

#ifdef GROUND_ZERO
		vector cmaxs = self.enemy.maxs;
		cmaxs[2] += 48;   // compensate for change when they die

		gi.trace (&tr, self.enemy.s.origin, self.enemy.mins, cmaxs, self.enemy.s.origin, self.enemy, MASK_MONSTERSOLID);
		if (tr.startsolid || tr.allsolid)
		{
			abortHeal (self, true, true, false);
			return;
		} 
		else if (tr.ent != world)
		{
			abortHeal (self, true, true, false);
			return;
		}
		else
		{
			self.enemy.monsterinfo.aiflags |= AI_DO_NOT_COUNT;
#endif

			ED_CallSpawn(self.enemy);

#ifndef GROUND_ZERO
			self.enemy.owner = 0;
#endif
			if (self.enemy.think)
			{
				self.enemy.nextthink = level.framenum;
				self.enemy.think(self.enemy);
			}
#ifdef GROUND_ZERO
			self.enemy.monsterinfo.aiflags &= ~AI_RESURRECTING;
			self.enemy.monsterinfo.aiflags |= AI_IGNORE_SHOTS|AI_DO_NOT_COUNT;
			// turn off flies
			self.enemy.s.effects &= ~EF_FLIES;
			self.enemy.monsterinfo.healer = 0;

			if ((self.oldenemy) && (self.oldenemy.inuse) && (self.oldenemy.health > 0))
			{
#else
			self.enemy.monsterinfo.aiflags |= AI_RESURRECTING;
			if (self.oldenemy && self.oldenemy.is_client)
			{
#endif
				self.enemy.enemy = self.oldenemy;
				FoundTarget(self.enemy);
			}
#ifdef GROUND_ZERO

			else
			{
				self.enemy.enemy = 0;
				if (!FindTarget (self.enemy))
				{
					// no valid enemy, so stop acting
					self.enemy.monsterinfo.pause_framenum = INT_MAX;
					self.enemy.monsterinfo.stand (self.enemy);
				}
				self.enemy = self.oldenemy = 0;
				if (!FindTarget (self))
				{
					// no valid enemy, so stop acting
					self.monsterinfo.pause_framenum = INT_MAX;
					self.monsterinfo.stand (self);
					return;
				}
			}
		}
#endif
	}
	else
	{
		if (self.s.frame == FRAME_attack44)
#ifdef GROUND_ZERO
			// PMM - medic commander sounds
			if (self.mass > 400)
				gi.sound (self, CHAN_WEAPON, commander_sound_hook_heal, 1, ATTN_NORM, 0);
			else
#endif
				gi.sound(self, CHAN_WEAPON, sound_hook_heal, 1, ATTN_NORM, 0);
	}

	// adjust start for beam origin being in middle of a segment
	start = start + (8 * f);

	// adjust end z for end spot since the monster is currently dead
	end = self.enemy.s.origin;
	end[2] = self.enemy.absmin[2] + self.enemy.size[2] / 2;

	gi.WriteByte(svc_temp_entity);
	gi.WriteByte(TE_MEDIC_CABLE_ATTACK);
	gi.WriteShort(self.s.number);
	gi.WritePosition(start);
	gi.WritePosition(end);
	gi.multicast(self.s.origin, MULTICAST_PVS);
}

static void medic_hook_retract(entity self)
{
#ifdef GROUND_ZERO
	if (self.mass > 400)
		gi.sound (self, CHAN_WEAPON, commander_sound_hook_retract, 1, ATTN_NORM, 0);
	else
#endif
		gi.sound(self, CHAN_WEAPON, sound_hook_retract, 1, ATTN_NORM, 0);

#ifdef GROUND_ZERO
	self.monsterinfo.aiflags &= ~AI_MEDIC;

	if (self.oldenemy && self.oldenemy.inuse)
		self.enemy = self.oldenemy;
	else
	{
		self.enemy = self.oldenemy = 0;
		if (!FindTarget (self))
		{
			// no valid enemy, so stop acting
			self.monsterinfo.pause_framenum = INT_MAX;
			self.monsterinfo.stand (self);
			return;
		}
	}
#else
	self.enemy.monsterinfo.aiflags &= ~AI_RESURRECTING;
#endif
}

static mframe_t medic_frames_attackCable [] = {
#ifdef GROUND_ZERO
	{ ai_charge, 2 },					//33
	{ ai_charge, 3 },
	{ ai_charge, 5 },
	{ ai_charge, -4.4 },					//36
	{ ai_charge, -4.7 },					//37
	{ ai_charge, -5 },
	{ ai_charge, -6 },
	{ ai_charge, -4 },					//40
#else
	{ ai_move, 2 },
	{ ai_move, 3 },
	{ ai_move, 5 },
	{ ai_move, 4.4 },
	{ ai_charge, 4.7 },
	{ ai_charge, 5 },
	{ ai_charge, 6 },
	{ ai_charge, 4 },
#endif
	{ ai_charge },
	{ ai_move, 0,     medic_hook_launch },
	{ ai_move, 0,     medic_cable_attack },
	{ ai_move, 0,     medic_cable_attack },
	{ ai_move, 0,     medic_cable_attack },
	{ ai_move, 0,     medic_cable_attack },
	{ ai_move, 0,     medic_cable_attack },
	{ ai_move, 0,     medic_cable_attack },
	{ ai_move, 0,     medic_cable_attack },
	{ ai_move, 0,     medic_cable_attack },
	{ ai_move, 0,     medic_cable_attack },
	{ ai_move, -15,   medic_hook_retract },
	{ ai_move, -1.5 },
	{ ai_move, -1.2 },
	{ ai_move, -3 },
	{ ai_move, -2 },
	{ ai_move, 0.3 },
	{ ai_move, 0.7 },
	{ ai_move, 1.2 },
	{ ai_move, 1.3 }
};
static var mmove_t medic_move_attackCable = { FRAME_attack33, FRAME_attack60, medic_run };

#ifdef GROUND_ZERO
static void medic_start_spawn (entity self)
{
	gi.sound (self, CHAN_WEAPON, commander_sound_spawn, 1, ATTN_NORM, 0);
	self.monsterinfo.nextframe = FRAME_attack48;
}

static void medic_determine_spawn (entity self)
{
	vector	f, r, offset, startpoint, spawnpoint;
	float	lucky;
	int		summonStr;
	int		count;
	int		inc;
	int		num_summoned; // should be 1, 3, or 5
	int		num_success = 0;

	lucky = random();
	summonStr = skill.intVal;

	// bell curve - 0 = 67%, 1 = 93%, 2 = 99% -- too steep
	// this ends up with
	// -3 = 5%
	// -2 = 10%
	// -1 = 15%
	// 0  = 40%
	// +1 = 15%
	// +2 = 10%
	// +3 = 5%
	if (lucky < 0.05)
		summonStr -= 3;
	else if (lucky < 0.15)
		summonStr -= 2;
	else if (lucky < 0.3)
		summonStr -= 1;
	else if (lucky > 0.95)
		summonStr += 3;
	else if (lucky > 0.85)
		summonStr += 2;
	else if (lucky > 0.7)
		summonStr += 1;

	if (summonStr < 0)
		summonStr = 0;

	self.plat2flags = summonStr;
	AngleVectors (self.s.angles, &f, &r, 0);

// this yields either 1, 3, or 5
	if (summonStr)
		num_summoned = (summonStr - 1) + (summonStr % 2);
	else
		num_summoned = 1;

	for (count = 0; count < num_summoned; count++)
	{
		inc = count + (count%2); // 0, 2, 2, 4, 4
		offset = reinforcement_position[count];

		startpoint = G_ProjectSource (self.s.origin, offset, f, r);
		// a little off the ground
		startpoint[2] += 10;

		if (FindSpawnPoint (startpoint, reinforcement_mins[summonStr-inc], reinforcement_maxs[summonStr-inc], &spawnpoint, 32))
		{
			if (CheckGroundSpawnPoint(spawnpoint, 
				reinforcement_mins[summonStr-inc], reinforcement_maxs[summonStr-inc], 
				256, -1))
			{
				num_success++;
				// we found a spot, we're done here
				count = num_summoned;
			}
		}
	}

	if (num_success == 0)
	{
		for (count = 0; count < num_summoned; count++)
		{
			inc = count + (count%2); // 0, 2, 2, 4, 4
			offset = reinforcement_position[count];
			
			// check behind
			offset[0] *= -1;
			offset[1] *= -1;

			startpoint = G_ProjectSource (self.s.origin, offset, f, r);
			// a little off the ground
			startpoint[2] += 10;

			if (FindSpawnPoint (startpoint, reinforcement_mins[summonStr-inc], reinforcement_maxs[summonStr-inc], &spawnpoint, 32))
			{
				if (CheckGroundSpawnPoint(spawnpoint, 
					reinforcement_mins[summonStr-inc], reinforcement_maxs[summonStr-inc], 
					256, -1))
				{
					num_success++;
					// we found a spot, we're done here
					count = num_summoned;
				}
			}
		}

		if (num_success)
		{
			self.monsterinfo.aiflags |= AI_MANUAL_STEERING;
			self.ideal_yaw = anglemod(self.s.angles[YAW]) + 180;
			if (self.ideal_yaw > 360.0)
				self.ideal_yaw -= 360.0;
		}
	}

	if (num_success == 0)
		self.monsterinfo.nextframe = FRAME_attack53;
}

static void medic_spawngrows (entity self)
{
	vector	f, r, offset, startpoint, spawnpoint;
	int		summonStr;
	int		count;
	int		inc;
	int		num_summoned; // should be 1, 3, or 5
	int		num_success = 0;
	float		current_yaw;
	bool		behind = false;

	// if we've been directed to turn around
	if (self.monsterinfo.aiflags & AI_MANUAL_STEERING)
	{
		current_yaw = anglemod(self.s.angles[YAW]);
		if (fabs(current_yaw - self.ideal_yaw) > 0.1)
		{
			self.monsterinfo.aiflags |= AI_HOLD_FRAME;
			return;
		}

		// done turning around
		self.monsterinfo.aiflags &= ~AI_HOLD_FRAME;
		self.monsterinfo.aiflags &= ~AI_MANUAL_STEERING;
	}

	summonStr = self.plat2flags;

	AngleVectors (self.s.angles, &f, &r, 0);

	if (summonStr)
		num_summoned = (summonStr - 1) + (summonStr % 2);
	else
		num_summoned = 1;

	for (count = 0; count < num_summoned; count++)
	{
		inc = count + (count%2); // 0, 2, 2, 4, 4
		offset = reinforcement_position[count];

		startpoint = G_ProjectSource (self.s.origin, offset, f, r);
		// a little off the ground
		startpoint[2] += 10;

		if (FindSpawnPoint (startpoint, reinforcement_mins[summonStr-inc], reinforcement_maxs[summonStr-inc], &spawnpoint, 32))
		{
			if (CheckGroundSpawnPoint(spawnpoint, 
				reinforcement_mins[summonStr-inc], reinforcement_maxs[summonStr-inc], 
				256, -1))
			{
				num_success++;
				if ((summonStr-inc) > 3)
					SpawnGrow_Spawn (spawnpoint, 1);		// big monster
				else
					SpawnGrow_Spawn (spawnpoint, 0);		// normal size
			}
		}
	}

	if (num_success == 0)
		self.monsterinfo.nextframe = FRAME_attack53;
}

static void medic_finish_spawn (entity self)
{
	entity	ent;
	vector	f, r, offset, startpoint, spawnpoint;
	int		summonStr;
	int		count;
	int		inc;
	int		num_summoned; // should be 1, 3, or 5
	bool		behind = false;
	entity	designated_enemy;

	if (self.plat2flags < 0)
	{
		behind = true;
		self.plat2flags *= -1;
	}
	summonStr = self.plat2flags;

	AngleVectors (self.s.angles, &f, &r, 0);

	if (summonStr)
		num_summoned = (summonStr - 1) + (summonStr % 2);
	else
		num_summoned = 1;

	for (count = 0; count < num_summoned; count++)
	{
		inc = count + (count%2); // 0, 2, 2, 4, 4
		offset = reinforcement_position[count];

		startpoint = G_ProjectSource (self.s.origin, offset, f, r);

		// a little off the ground
		startpoint[2] += 10;

		ent = 0;
		if (FindSpawnPoint (startpoint, reinforcement_mins[summonStr-inc], reinforcement_maxs[summonStr-inc], &spawnpoint, 32))
		{
			if (CheckSpawnPoint (spawnpoint, reinforcement_mins[summonStr-inc], reinforcement_maxs[summonStr-inc]))
				ent = CreateGroundMonster (spawnpoint, self.s.angles,
					reinforcement_mins[summonStr-inc], reinforcement_maxs[summonStr-inc],
					reinforcements[summonStr-inc], 256);
		}

		if (!ent)
			continue;

		if (ent.think)
		{
			ent.nextthink = level.framenum;
			ent.think (ent);
		}

		ent.monsterinfo.aiflags |= AI_IGNORE_SHOTS|AI_DO_NOT_COUNT|AI_SPAWNED_MEDIC_C;
		ent.monsterinfo.commander = self;
		self.monsterinfo.monster_slots--;

		if (self.monsterinfo.aiflags & AI_MEDIC)
			designated_enemy = self.oldenemy;
		else
			designated_enemy = self.enemy;

		if (coop.intVal)
		{
			designated_enemy = PickCoopTarget(ent);
			if (designated_enemy)
			{
				// try to avoid using my enemy
				if (designated_enemy == self.enemy)
				{
					designated_enemy = PickCoopTarget(ent);
					if (!designated_enemy)
						designated_enemy = self.enemy;
				}
			}
			else
				designated_enemy = self.enemy;
		}

		if ((designated_enemy) && (designated_enemy.inuse) && (designated_enemy.health > 0))
		{
			ent.enemy = designated_enemy;
			FoundTarget (ent);
		}
		else
		{
			ent.enemy = 0;
			ent.monsterinfo.stand (ent);
		}
	}
}

static mframe_t medic_frames_callReinforcements [] =
{
	// ROGUE - 33-36 now ai_charge
	{ ai_charge, 2 },					//33
	{ ai_charge, 3 },
	{ ai_charge, 5 },
	{ ai_charge, 4.4 },					//36
	{ ai_charge, 4.7 },
	{ ai_charge, 5 },
	{ ai_charge, 6 },
	{ ai_charge, 4 },					//40
	{ ai_charge },
	{ ai_move, 0,		medic_start_spawn },		//42
	{ ai_move },		//43 -- 43 through 47 are skipped
	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move, 0,		medic_determine_spawn },		//48
	{ ai_charge, 0,		medic_spawngrows },			//49
	{ ai_move },		//50
	{ ai_move },		//51
	{ ai_move, -15,	medic_finish_spawn },		//52
	{ ai_move, -1.5 },
	{ ai_move, -1.2 },
	{ ai_move, -3 },
	{ ai_move, -2 },
	{ ai_move, 0.3 },
	{ ai_move, 0.7 },
	{ ai_move, 1.2 },
	{ ai_move, 1.3 }					//60
};
static var mmove_t medic_move_callReinforcements = { FRAME_attack33, FRAME_attack60, medic_run };

#endif

static void medic_attack(entity self)
{
#ifdef GROUND_ZERO
	monster_done_dodge (self);

	range_t enemy_range = range(self, self.enemy);

	// signal from checkattack to spawn
	if (self.monsterinfo.aiflags & AI_BLOCKED)
	{
		self.monsterinfo.currentmove = &medic_move_callReinforcements;
		self.monsterinfo.aiflags &= ~AI_BLOCKED;
	}

	float r = random();
#endif
	if (self.monsterinfo.aiflags & AI_MEDIC)
	{
#ifdef GROUND_ZERO
		if ((self.mass > 400) && (r > 0.8) && (self.monsterinfo.monster_slots > 2))
			self.monsterinfo.currentmove = &medic_move_callReinforcements;
		else
#endif
			self.monsterinfo.currentmove = &medic_move_attackCable;
	}
	else
	{
#ifdef GROUND_ZERO
		if (self.monsterinfo.attack_state == AS_BLIND)
		{
			self.monsterinfo.currentmove = &medic_move_callReinforcements;
			return;
		}

		if ((self.mass > 400) && (r > 0.2) && (enemy_range != RANGE_MELEE) && (self.monsterinfo.monster_slots > 2))
			self.monsterinfo.currentmove = &medic_move_callReinforcements;
		else
#endif
			self.monsterinfo.currentmove = &medic_move_attackBlaster;
	}
}

static bool medic_checkattack(entity self)
{
	if (self.monsterinfo.aiflags & AI_MEDIC)
	{
#ifdef GROUND_ZERO
		// if our target went away
		if ((!self.enemy) || (!self.enemy.inuse))
		{
			abortHeal (self, true, false, false);
			return false;
		}

		// if we ran out of time, give up
		if (self.timestamp < level.framenum)
		{
			abortHeal (self, true, false, true);
			self.timestamp = 0;
			return false;
		}
	
		if (realrange(self, self.enemy) < MEDIC_MAX_HEAL_DISTANCE+10)
		{
#endif
			medic_attack(self);
			return true;
#ifdef GROUND_ZERO
		}
		else
		{
			self.monsterinfo.attack_state = AS_STRAIGHT;
			return false;
		}
#endif
	}

#ifdef GROUND_ZERO
	if (self.enemy.is_client && !visible(self, self.enemy) && (self.monsterinfo.monster_slots > 2))
	{
		self.monsterinfo.attack_state = AS_BLIND;
		return true;
	}

	// give a LARGE bias to spawning things when we have room
	// use AI_BLOCKED as a signal to attack to spawn
	if ((random() < 0.8) && (self.monsterinfo.monster_slots > 5) && (realrange(self, self.enemy) > 150))
	{
		self.monsterinfo.aiflags |= AI_BLOCKED;
		self.monsterinfo.attack_state = AS_MISSILE;
		return true;
	}
	
	// ROGUE
	// since his idle animation looks kinda bad in combat, if we're not in easy mode, always attack
	// when he's on a combat point
	if (skill.intVal > 0)
		if (self.monsterinfo.aiflags & AI_STAND_GROUND)
		{
			self.monsterinfo.attack_state = AS_MISSILE;
			return true;
		}
#endif

	return M_CheckAttack(self);
}

#ifdef GROUND_ZERO
static void MedicCommanderCache ()
{
	entity	newEnt;
	int	modelidx;
	int i;

	//FIXME - better way to do this?  this is quick and dirty
	for (i = 0; i < 7; i++)
	{
		newEnt = G_Spawn();

		newEnt.classname = reinforcements[i];

		newEnt.monsterinfo.aiflags |= AI_DO_NOT_COUNT;

		ED_CallSpawn(newEnt);

		G_FreeEdict (newEnt);
	}

	modelidx = gi.modelindex("models/items/spawngro/tris.md2");
	modelidx = gi.modelindex("models/items/spawngro2/tris.md2");
}

static void medic_duck (entity self, float eta)
{
//	don't dodge if you're healing
	if (self.monsterinfo.aiflags & AI_MEDIC)
		return;

	if ((self.monsterinfo.currentmove == &medic_move_attackHyperBlaster) ||
		(self.monsterinfo.currentmove == &medic_move_attackCable) ||
		(self.monsterinfo.currentmove == &medic_move_attackBlaster) ||
		(self.monsterinfo.currentmove == &medic_move_callReinforcements))
	{
		// he ignores skill
		self.monsterinfo.aiflags &= ~AI_DUCKED;
		return;
	}

	if (skill.intVal == 0)
		// PMM - stupid dodge
		self.monsterinfo.duck_wait_framenum = level.framenum + (int)((eta + 1) * BASE_FRAMERATE);
	else
		self.monsterinfo.duck_wait_framenum = level.framenum + (int)((eta + (0.1 * (3 - skill.intVal))) * BASE_FRAMERATE);

	// has to be done immediately otherwise he can get stuck
	monster_duck_down(self);

	self.monsterinfo.nextframe = FRAME_duck1;
	self.monsterinfo.currentmove = &medic_move_duck;
}

static void medic_sidestep (entity self)
{
	if ((self.monsterinfo.currentmove == &medic_move_attackHyperBlaster) ||
		(self.monsterinfo.currentmove == &medic_move_attackCable) ||
		(self.monsterinfo.currentmove == &medic_move_attackBlaster) ||
		(self.monsterinfo.currentmove == &medic_move_callReinforcements))
	{
		// if we're shooting, and not on easy, don't dodge
		if (skill.intVal)
		{
			self.monsterinfo.aiflags &= ~AI_DODGING;
			return;
		}
	}

	if (self.monsterinfo.currentmove != &medic_move_run)
		self.monsterinfo.currentmove = &medic_move_run;
}

static bool medic_blocked (entity self, float dist)
{
	if(blocked_checkshot (self, 0.25 + (0.05 * skill.intVal)))
		return true;

	if(blocked_checkplat (self, dist))
		return true;

	return false;
}
#endif

/*QUAKED monster_medic (1 .5 0) (-16 -16 -24) (16 16 32) Ambush Trigger_Spawn Sight
*/
API_FUNC static void SP_monster_medic(entity self)
{
	if (deathmatch.intVal) {
		G_FreeEdict(self);
		return;
	}
	
	if (!medic_move_stand.frame)
	{
		medic_move_stand.frame = &medic_frames_stand;
		medic_move_walk.frame = &medic_frames_walk;
		medic_move_run.frame = &medic_frames_run;
		medic_move_pain1.frame = &medic_frames_pain1;
		medic_move_pain2.frame = &medic_frames_pain2;
		medic_move_death.frame = &medic_frames_death;
		medic_move_duck.frame = &medic_frames_duck;
		medic_move_attackHyperBlaster.frame = &medic_frames_attackHyperBlaster;
		medic_move_attackBlaster.frame = &medic_frames_attackBlaster;
		medic_move_attackCable.frame = &medic_frames_attackCable;

#ifdef GROUND_ZERO
		medic_move_callReinforcements.frame = &medic_frames_callReinforcements;
#endif
	}

	self.movetype = MOVETYPE_STEP;
	self.solid = SOLID_BBOX;
	self.s.modelindex = gi.modelindex("models/monsters/medic/tris.md2");
	self.mins = '-24 -24 -24';
	self.maxs = '24 24 32';

#ifdef GROUND_ZERO
	self.monsterinfo.aiflags |= AI_IGNORE_SHOTS;
	self.monsterinfo.blocked = medic_blocked;
	self.monsterinfo.dodge = M_MonsterDodge;
	self.monsterinfo.duck = medic_duck;
	self.monsterinfo.unduck = monster_duck_up;
	self.monsterinfo.sidestep = medic_sidestep;
	
	if (self.classname == "monster_medic_commander")
	{
		// commander sounds
		commander_sound_idle1 = gi.soundindex ("medic_commander/medidle.wav");
		commander_sound_pain1 = gi.soundindex ("medic_commander/medpain1.wav");
		commander_sound_pain2 = gi.soundindex ("medic_commander/medpain2.wav");
		commander_sound_die = gi.soundindex ("medic_commander/meddeth.wav");
		commander_sound_sight = gi.soundindex ("medic_commander/medsght.wav");
		commander_sound_search = gi.soundindex ("medic_commander/medsrch.wav");
		commander_sound_hook_launch = gi.soundindex ("medic_commander/medatck2c.wav");
		commander_sound_hook_hit = gi.soundindex ("medic_commander/medatck3a.wav");
		commander_sound_hook_heal = gi.soundindex ("medic_commander/medatck4a.wav");
		commander_sound_hook_retract = gi.soundindex ("medic_commander/medatck5a.wav");
		commander_sound_spawn = gi.soundindex ("medic_commander/monsterspawn1.wav");
		gi.soundindex ("tank/tnkatck3.wav");

		MedicCommanderCache();

		self.health = 600;
		self.gib_health = -130;
		self.mass = 600;
		self.yaw_speed = 40f;

		if (skill.intVal == 0)
			self.monsterinfo.monster_slots = 3;
		else if (skill.intVal == 1)
			self.monsterinfo.monster_slots = 4;
		else
			self.monsterinfo.monster_slots = 6;
	}
	else
	{
#endif
		sound_idle1 = gi.soundindex("medic/idle.wav");
		sound_pain1 = gi.soundindex("medic/medpain1.wav");
		sound_pain2 = gi.soundindex("medic/medpain2.wav");
		sound_die = gi.soundindex("medic/meddeth1.wav");
		sound_sight = gi.soundindex("medic/medsght1.wav");
		sound_search = gi.soundindex("medic/medsrch1.wav");
		sound_hook_launch = gi.soundindex("medic/medatck2.wav");
		sound_hook_hit = gi.soundindex("medic/medatck3.wav");
		sound_hook_heal = gi.soundindex("medic/medatck4.wav");
		sound_hook_retract = gi.soundindex("medic/medatck5.wav");

		gi.soundindex("medic/medatck1.wav");
		
		self.health = 300;
		self.gib_health = -130;
		self.mass = 400;
#ifdef GROUND_ZERO
	}
#else
	self.monsterinfo.dodge = medic_dodge;
#endif

	self.pain = medic_pain;
	self.die = medic_die;

	self.monsterinfo.stand = medic_stand;
	self.monsterinfo.walk = medic_walk;
	self.monsterinfo.run = medic_run;
	self.monsterinfo.attack = medic_attack;
	self.monsterinfo.melee = 0;
	self.monsterinfo.sight = medic_sight;
	self.monsterinfo.idle = medic_idle;
	self.monsterinfo.search = medic_search;
	self.monsterinfo.checkattack = medic_checkattack;

	gi.linkentity(self);

	self.monsterinfo.currentmove = &medic_move_stand;
	self.monsterinfo.scale = MODEL_SCALE;

	walkmonster_start(self);
}

#ifdef GROUND_ZERO
API_FUNC static void SP_monster_medic_commander (entity self)
{
	SP_monster_medic(self);
	self.s.skinnum = 2;
}
#endif