#ifdef SINGLE_PLAYER
#include "m_chick.h"

static int  sound_missile_prelaunch;
static int  sound_missile_launch;
static int  sound_melee_swing;
static int  sound_melee_hit;
static int  sound_missile_reload;
static int  sound_death1;
static int  sound_death2;
static int  sound_fall_down;
static int  sound_idle1;
static int  sound_idle2;
static int  sound_pain1;
static int  sound_pain2;
static int  sound_pain3;
static int  sound_sight;
static int  sound_search;


static void ChickMoan(entity self)
{
	if (random() < 0.5f)
		gi.sound(self, CHAN_VOICE, sound_idle1, 1, ATTN_IDLE, 0);
	else
		gi.sound(self, CHAN_VOICE, sound_idle2, 1, ATTN_IDLE, 0);
}

static mframe_t chick_frames_fidget [] = {
	{ ai_stand },
	{ ai_stand },
	{ ai_stand },
	{ ai_stand },
	{ ai_stand },
	{ ai_stand },
	{ ai_stand },
	{ ai_stand },
	{ ai_stand, 0,  ChickMoan },
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
static var mmove_t chick_move_fidget = { FRAME_stand201, FRAME_stand230 };

static void chick_fidget(entity self)
{
	if (self.monsterinfo.aiflags & AI_STAND_GROUND)
		return;
	if (random() <= 0.3f)
		self.monsterinfo.currentmove = &chick_move_fidget;
}

static mframe_t chick_frames_stand [] = {
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
	{ ai_stand, 0, chick_fidget },
};
static var mmove_t chick_move_stand = { FRAME_stand101, FRAME_stand130 };

static void chick_stand(entity self)
{
	self.monsterinfo.currentmove = &chick_move_stand;
}

static mframe_t chick_frames_start_run [] = {
	{ ai_run, 1 },
	{ ai_run },
	{ ai_run },
	{ ai_run, -1 },
	{ ai_run, -1 },
	{ ai_run },
	{ ai_run, 1 },
	{ ai_run, 3 },
	{ ai_run, 6 },
	{ ai_run, 3 }
};
static var mmove_t chick_move_start_run = { FRAME_walk01, FRAME_walk10 };

static mframe_t chick_frames_run [] = {
	{ ai_run, 6 },
	{ ai_run, 8 },
	{ ai_run, 13 },
	{ ai_run, 5
#ifdef GROUND_ZERO
		, monster_done_dodge
#endif
	},
	{ ai_run, 7 },
	{ ai_run, 4 },
	{ ai_run, 11 },
	{ ai_run, 5 },
	{ ai_run, 9 },
	{ ai_run, 7 }
};
static var mmove_t chick_move_run = { FRAME_walk11, FRAME_walk20 };

static mframe_t chick_frames_walk [] = {
	{ ai_walk, 6 },
	{ ai_walk, 8 },
	{ ai_walk, 13 },
	{ ai_walk, 5 },
	{ ai_walk, 7 },
	{ ai_walk, 4 },
	{ ai_walk, 11 },
	{ ai_walk, 5 },
	{ ai_walk, 9 },
	{ ai_walk, 7 }
};
static var mmove_t chick_move_walk = { FRAME_walk11, FRAME_walk20 };

static void chick_walk(entity self)
{
	self.monsterinfo.currentmove = &chick_move_walk;
}

static void chick_run(entity self)
{
#ifdef GROUND_ZERO
	monster_done_dodge(self);
#endif

	if (self.monsterinfo.aiflags & AI_STAND_GROUND) {
		self.monsterinfo.currentmove = &chick_move_stand;
		return;
	}

	if (self.monsterinfo.currentmove == &chick_move_walk ||
		self.monsterinfo.currentmove == &chick_move_start_run) {
		self.monsterinfo.currentmove = &chick_move_run;
	} else {
		self.monsterinfo.currentmove = &chick_move_start_run;
	}
}

static mframe_t chick_frames_pain1 [] = {
	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move }
};
static var mmove_t chick_move_pain1 = { FRAME_pain101, FRAME_pain105, chick_run };

static mframe_t chick_frames_pain2 [] = {
	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move }
};
static var mmove_t chick_move_pain2 = { FRAME_pain201, FRAME_pain205, chick_run };

static mframe_t chick_frames_pain3 [] = {
	{ ai_move },
	{ ai_move },
	{ ai_move, -6 },
	{ ai_move, 3 },
	{ ai_move, 11 },
	{ ai_move, 3 },
	{ ai_move },
	{ ai_move },
	{ ai_move, 4 },
	{ ai_move, 1 },
	{ ai_move },
	{ ai_move, -3 },
	{ ai_move, -4 },
	{ ai_move, 5 },
	{ ai_move, 7 },
	{ ai_move, -2 },
	{ ai_move, 3 },
	{ ai_move, -5 },
	{ ai_move, -2 },
	{ ai_move, -8 },
	{ ai_move, 2 }
};
static var mmove_t chick_move_pain3 = { FRAME_pain301, FRAME_pain321, chick_run };

static void chick_pain(entity self, entity other, float kick, int damage)
{
	float   r;

#ifdef GROUND_ZERO
	monster_done_dodge(self);
#endif

	if (self.health < (self.max_health / 2))
	{
#ifdef THE_RECKONING
		// Knightmare- show right pain skin for beta class
		if (self.classname == "monster_chick_heat")
			self.s.skinnum = 2;
		else
#endif
			self.s.skinnum = 1;
	}

	if (level.framenum < self.pain_debounce_framenum)
		return;

	self.pain_debounce_framenum = level.framenum + 3 * BASE_FRAMERATE;

	r = random();
	if (r < 0.33f)
		gi.sound(self, CHAN_VOICE, sound_pain1, 1, ATTN_NORM, 0);
	else if (r < 0.66f)
		gi.sound(self, CHAN_VOICE, sound_pain2, 1, ATTN_NORM, 0);
	else
		gi.sound(self, CHAN_VOICE, sound_pain3, 1, ATTN_NORM, 0);

	if (skill.intVal == 3)
		return;     // no pain anims in nightmare

#ifdef GROUND_ZERO
	// PMM - clear this from blindfire
	self.monsterinfo.aiflags &= ~AI_MANUAL_STEERING;

	// PMM - clear duck flag
	if (self.monsterinfo.aiflags & AI_DUCKED)
		monster_duck_up(self);
#endif

	if (damage <= 10)
		self.monsterinfo.currentmove = &chick_move_pain1;
	else if (damage <= 25)
		self.monsterinfo.currentmove = &chick_move_pain2;
	else
		self.monsterinfo.currentmove = &chick_move_pain3;
}

static void chick_dead(entity self)
{
	self.mins = '-16 -16 0';
	self.maxs = '16 16 16';
	self.movetype = MOVETYPE_TOSS;
	self.svflags |= SVF_DEADMONSTER;
	self.nextthink = 0;
	gi.linkentity(self);
}

static mframe_t chick_frames_death2 [] = {
	{ ai_move, -6 },
	{ ai_move },
	{ ai_move, -1 },
	{ ai_move, -5 },
	{ ai_move },
	{ ai_move, -1 },
	{ ai_move, -2 },
	{ ai_move, 1 },
	{ ai_move, 10 },
	{ ai_move, 2 },
	{ ai_move, 3 },
	{ ai_move, 1 },
	{ ai_move, 2 },
	{ ai_move },
	{ ai_move, 3 },
	{ ai_move, 3 },
	{ ai_move, 1 },
	{ ai_move, -3 },
	{ ai_move, -5 },
	{ ai_move, 4 },
	{ ai_move, 15 },
	{ ai_move, 14 },
	{ ai_move, 1 }
};
static var mmove_t chick_move_death2 = { FRAME_death201, FRAME_death223, chick_dead };

static mframe_t chick_frames_death1 [] = {
	{ ai_move },
	{ ai_move },
	{ ai_move, -7 },
	{ ai_move, 4 },
	{ ai_move, 11 },
	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move }
};
static var mmove_t chick_move_death1 = { FRAME_death101, FRAME_death112, chick_dead };

static void chick_die(entity self, entity inflictor, entity attacker, int damage, vector point)
{
	int     n;

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
	self.deadflag = DEAD_DEAD;
	self.takedamage = true;

	n = Q_rand() % 2;
	if (n == 0) {
		self.monsterinfo.currentmove = &chick_move_death1;
		gi.sound(self, CHAN_VOICE, sound_death1, 1, ATTN_NORM, 0);
	} else {
		self.monsterinfo.currentmove = &chick_move_death2;
		gi.sound(self, CHAN_VOICE, sound_death2, 1, ATTN_NORM, 0);
	}
}

#ifdef GROUND_ZERO
#define chick_duck_down monster_duck_down
#define chick_duck_hold monster_duck_hold
#define chick_duck_up monster_duck_up
#else
static void chick_duck_down(entity self)
{
	if (self.monsterinfo.aiflags & AI_DUCKED)
		return;
	self.monsterinfo.aiflags |= AI_DUCKED;
	self.maxs[2] -= 32;
	self.takedamage = true;
	self.monsterinfo.pause_framenum = level.framenum + 1 * BASE_FRAMERATE;
	gi.linkentity(self);
}

static void chick_duck_hold(entity self)
{
	if (level.framenum >= self.monsterinfo.pause_framenum)
		self.monsterinfo.aiflags &= ~AI_HOLD_FRAME;
	else
		self.monsterinfo.aiflags |= AI_HOLD_FRAME;
}

static void chick_duck_up(entity self)
{
	self.monsterinfo.aiflags &= ~AI_DUCKED;
	self.maxs[2] += 32;
	self.takedamage = true;
	gi.linkentity(self);
}
#endif

static mframe_t chick_frames_duck [] = {
	{ ai_move, 0, chick_duck_down },
	{ ai_move, 1 },
	{ ai_move, 4, chick_duck_hold },
	{ ai_move, -4 },
	{ ai_move, -5,  chick_duck_up },
	{ ai_move, 3 },
	{ ai_move, 1 }
};
static var mmove_t chick_move_duck = { FRAME_duck01, FRAME_duck07, chick_run };

#ifndef GROUND_ZERO
static void chick_dodge(entity self, entity attacker, float eta)
{
	if (random() > 0.25f)
		return;

	if (!self.enemy)
		self.enemy = attacker;

	self.monsterinfo.currentmove = &chick_move_duck;
}
#endif

static void ChickSlash(entity self)
{
	const vector  aim = [ MELEE_DISTANCE, self.mins.x, 10 ];
	gi.sound(self, CHAN_WEAPON, sound_melee_swing, 1, ATTN_NORM, 0);
	fire_hit(self, aim, (10 + (Q_rand() % 6)), 100);
}


static void ChickRocket(entity self)
{
#ifdef GROUND_ZERO
	trace_t	trace;	// PMM - check target
	int	rocketSpeed;
	float	dist;
	// pmm - blindfire
	vector	target;
	bool blindfire = (self.monsterinfo.aiflags & AI_MANUAL_STEERING);

	if(!self.enemy || !self.enemy.inuse)		//PGM
		return;									//PGM
#endif

	vector  forward, right;
	vector  start;
	vector  dir;
	vector  vec;

	AngleVectors(self.s.angles, &forward, &right, 0);
	start = G_ProjectSource(self.s.origin, monster_flash_offset[MZ2_CHICK_ROCKET_1], forward, right);

#ifdef GROUND_ZERO
	rocketSpeed = 500 + (100 * skill.intVal);	// PGM rock & roll.... :)

	// put a debug trail from start to endpoint, confirm that the start point is
	// correct for the trace

	// PMM
	if (blindfire)
		target = self.monsterinfo.blind_fire_target;
	else
		target = self.enemy.s.origin;

	if (blindfire)
	{
		vec = target;
		dir = vec - start;
	}

	// don't shoot at feet if they're above where i'm shooting from.
	else if(random() < 0.33 || (start[2] < self.enemy.absmin[2]))
	{
		vec = target;
#else
		vec = self.enemy.s.origin;
#endif
		vec[2] += self.enemy.viewheight;
		dir = vec - start;
#ifdef GROUND_ZERO
	}
	else
	{
		vec = target;
		vec[2] = self.enemy.absmin[2];
		dir = vec - start;
	}

	if (!blindfire && random() < (0.2 + ((3 - skill.intVal) * 0.15)))
	{
		dist = VectorLength (dir);
		float time = dist/rocketSpeed;
		vec += time * self.enemy.velocity;
		dir = vec - start;
	}
#endif

	VectorNormalize(dir);
	void(entity self, vector start, vector dir, int damage, int kick, int flashtype) fire_func = monster_fire_rocket;

#ifdef THE_RECKONING
	if (self.s.skinnum > 1)
		fire_func = monster_fire_heat;
#endif
	
#ifdef GROUND_ZERO
	// pmm blindfire doesn't check target (done in checkattack)
	// paranoia, make sure we're not shooting a target right next to us
	gi.traceline(&trace, start, vec, self, MASK_SHOT);
	if (blindfire)
	{
		// blindfire has different fail criteria for the trace
		if (!(trace.startsolid || trace.allsolid || (trace.fraction < 0.5)))
			fire_func (self, start, dir, 50, rocketSpeed, MZ2_CHICK_ROCKET_1);
		else 
		{
			// geez, this is bad.  she's avoiding about 80% of her blindfires due to hitting things.
			// hunt around for a good shot
			// try shifting the target to the left a little (to help counter her large offset)
			vec = target;
			vec += -10 * right;
			vec -= start;
			VectorNormalize (dir);
			gi.traceline(&trace, start, vec, self, MASK_SHOT);
			if (!(trace.startsolid || trace.allsolid || (trace.fraction < 0.5)))
				fire_func (self, start, dir, 50, rocketSpeed, MZ2_CHICK_ROCKET_1);
			else 
			{
				// ok, that failed.  try to the right
				vec = target;
				vec += 10 * right;
				dir = vec - start;
				VectorNormalize (dir);
				gi.traceline(&trace, start, vec, self, MASK_SHOT);
				if (!(trace.startsolid || trace.allsolid || (trace.fraction < 0.5)))
					fire_func (self, start, dir, 50, rocketSpeed, MZ2_CHICK_ROCKET_1);
			}
		}
	}
	else
	{
		gi.traceline(&trace, start, vec, self, MASK_SHOT);
		if(trace.ent == self.enemy || trace.ent == world)
		{
			if(trace.fraction > 0.5 || (trace.ent && trace.ent.is_client))
				fire_func (self, start, dir, 50, rocketSpeed, MZ2_CHICK_ROCKET_1);
		}
	}
#else
	fire_func(self, start, dir, 50, 500, MZ2_CHICK_ROCKET_1);
#endif
}

static void Chick_PreAttack1(entity self)
{
	gi.sound(self, CHAN_VOICE, sound_missile_prelaunch, 1, ATTN_NORM, 0);
}

static void ChickReload(entity self)
{
	gi.sound(self, CHAN_VOICE, sound_missile_reload, 1, ATTN_NORM, 0);
}

static void chick_attack1(entity self);

static mframe_t chick_frames_end_attack1 [] = {
	{ ai_charge, -3 },
	{ ai_charge },
	{ ai_charge, -6 },
	{ ai_charge, -4 },
	{ ai_charge, -2 }
};
static var mmove_t chick_move_end_attack1 = { FRAME_attak128, FRAME_attak132, chick_run };

static void chick_rerocket(entity self)
{
#ifdef GROUND_ZERO

	if (self.monsterinfo.aiflags & AI_MANUAL_STEERING)
	{
		self.monsterinfo.aiflags &= ~AI_MANUAL_STEERING;
		self.monsterinfo.currentmove = &chick_move_end_attack1;
		return;
	}
#endif

	if (self.enemy.health > 0) {
		if (range(self, self.enemy) > RANGE_MELEE)
			if (visible(self, self.enemy))
#ifdef GROUND_ZERO
				if (random() <= (0.6 + (0.05* skill.intVal)))
#else
				if (random() <= 0.6f)
#endif
				{
					chick_attack1(self);
					return;
				}
	}
	self.monsterinfo.currentmove = &chick_move_end_attack1;
}

static mframe_t chick_frames_attack1 [] = {
	{ ai_charge, 19,  ChickRocket },
	{ ai_charge, -6 },
	{ ai_charge, -5 },
	{ ai_charge, -2 },
	{ ai_charge, -7 },
	{ ai_charge },
	{ ai_charge, 1 },
	{ ai_charge, 10,  ChickReload },
	{ ai_charge, 4 },
	{ ai_charge, 5 },
	{ ai_charge, 6 },
	{ ai_charge, 6 },
	{ ai_charge, 4 },
	{ ai_charge, 3,   chick_rerocket }

};
static var mmove_t chick_move_attack1 = { FRAME_attak114, FRAME_attak127 };

static void chick_attack1(entity self)
{
	self.monsterinfo.currentmove = &chick_move_attack1;
}

static mframe_t chick_frames_start_attack1 [] = {
	{ ai_charge, 0,   Chick_PreAttack1 },
	{ ai_charge },
	{ ai_charge },
	{ ai_charge, 4 },
	{ ai_charge },
	{ ai_charge, -3 },
	{ ai_charge, 3 },
	{ ai_charge, 5 },
	{ ai_charge, 7 },
	{ ai_charge },
	{ ai_charge },
	{ ai_charge },
	{ ai_charge, 0,   chick_attack1 }
};
static var mmove_t chick_move_start_attack1 = { FRAME_attak101, FRAME_attak113 };

static mframe_t chick_frames_end_slash [] = {
	{ ai_charge, -6 },
	{ ai_charge, -1 },
	{ ai_charge, -6 },
	{ ai_charge }
};
static var mmove_t chick_move_end_slash = { FRAME_attak213, FRAME_attak216, chick_run };

static void chick_slash(entity self);

static void chick_reslash(entity self)
{
	if (self.enemy.health > 0) {
		if (range(self, self.enemy) == RANGE_MELEE) {
			if (random() <= 0.9f) {
				chick_slash(self);
				return;
			} else {
				self.monsterinfo.currentmove = &chick_move_end_slash;
				return;
			}
		}
	}
	self.monsterinfo.currentmove = &chick_move_end_slash;
}

static mframe_t chick_frames_slash [] = {
	{ ai_charge, 1 },
	{ ai_charge, 7,   ChickSlash },
	{ ai_charge, -7 },
	{ ai_charge, 1 },
	{ ai_charge, -1 },
	{ ai_charge, 1 },
	{ ai_charge },
	{ ai_charge, 1 },
	{ ai_charge, -2,  chick_reslash }
};
static var mmove_t chick_move_slash = { FRAME_attak204, FRAME_attak212 };

static void chick_slash(entity self)
{
	self.monsterinfo.currentmove = &chick_move_slash;
}

static mframe_t chick_frames_start_slash [] = {
	{ ai_charge, 1 },
	{ ai_charge, 8 },
	{ ai_charge, 3 }
};
static var mmove_t chick_move_start_slash = { FRAME_attak201, FRAME_attak203, chick_slash };

static void chick_melee(entity self)
{
	self.monsterinfo.currentmove = &chick_move_start_slash;
}

static void chick_attack(entity self)
{
#ifdef GROUND_ZERO
	monster_done_dodge (self);

	if (self.monsterinfo.attack_state == AS_BLIND)
	{
		float chance = 0.1;
		
		// setup shot probabilities
		if (self.monsterinfo.blind_fire_framedelay < (int)(1.0 * BASE_FRAMERATE))
			chance = 1.0;
		else if (self.monsterinfo.blind_fire_framedelay < (int)(7.5 * BASE_FRAMERATE))
			chance = 0.4;

		float r = random();

		// minimum of 2 seconds, plus 0-3, after the shots are done
		self.monsterinfo.blind_fire_framedelay += (int)(random(5.5f, 6.5f) * BASE_FRAMERATE);

		// don't shoot at the origin
		if (!self.monsterinfo.blind_fire_target)
			return;

		// don't shoot if the dice say not to
		if (r > chance)
			return;

		// turn on manual steering to signal both manual steering and blindfire
		self.monsterinfo.aiflags |= AI_MANUAL_STEERING;
		self.monsterinfo.currentmove = &chick_move_start_attack1;
		self.monsterinfo.attack_finished = level.framenum + (int)(random(2f) * BASE_FRAMERATE);
		return;
	}
#endif

	self.monsterinfo.currentmove = &chick_move_start_attack1;
}

static void chick_sight(entity self, entity other)
{
	gi.sound(self, CHAN_VOICE, sound_sight, 1, ATTN_NORM, 0);
}

#ifdef GROUND_ZERO
static bool chick_blocked (entity self, float dist)
{
	if(blocked_checkshot (self, 0.25 + (0.05 * skill.intVal)))
		return true;

	if(blocked_checkplat (self, dist))
		return true;

	return false;
}

static void chick_duck (entity self, float eta)
{
	if ((self.monsterinfo.currentmove == &chick_move_start_attack1) ||
		(self.monsterinfo.currentmove == &chick_move_attack1))
	{
		// if we're shooting, and not on easy, don't dodge
		if (skill.intVal)
		{
			self.monsterinfo.aiflags &= ~AI_DUCKED;
			return;
		}
	}

	if (skill.intVal == 0)
		// PMM - stupid dodge
		self.monsterinfo.duck_wait_framenum = level.framenum + (int)((eta + 1) * BASE_FRAMERATE);
	else
		self.monsterinfo.duck_wait_framenum = level.framenum + (int)((eta + (0.1 * (3 - skill.intVal))) * BASE_FRAMERATE);

	// has to be done immediately otherwise she can get stuck
	monster_duck_down(self);

	self.monsterinfo.nextframe = FRAME_duck01;
	self.monsterinfo.currentmove = &chick_move_duck;
}

void chick_sidestep (entity self)
{
	if ((self.monsterinfo.currentmove == &chick_move_start_attack1) ||
		(self.monsterinfo.currentmove == &chick_move_attack1))
	{
		// if we're shooting, and not on easy, don't dodge
		if (skill.intVal)
		{
			self.monsterinfo.aiflags &= ~AI_DODGING;
			return;
		}
	}

	if (self.monsterinfo.currentmove != &chick_move_run)
		self.monsterinfo.currentmove = &chick_move_run;
}
#endif

/*QUAKED monster_chick (1 .5 0) (-16 -16 -24) (16 16 32) Ambush Trigger_Spawn Sight
*/
API_FUNC static void SP_monster_chick(entity self)
{
	if (deathmatch.intVal) {
		G_FreeEdict(self);
		return;
	}
	
	if (!chick_move_fidget.frame)
	{
		chick_move_fidget.frame = &chick_frames_fidget;
		chick_move_fidget.endfunc = chick_stand;
		chick_move_stand.frame = &chick_frames_stand;
		chick_move_start_run.frame = &chick_frames_start_run;
		chick_move_start_run.endfunc = chick_run;
		chick_move_run.frame = &chick_frames_run;
		chick_move_walk.frame = &chick_frames_walk;
		chick_move_pain1.frame = &chick_frames_pain1;
		chick_move_pain2.frame = &chick_frames_pain2;
		chick_move_pain3.frame = &chick_frames_pain3;
		chick_move_death2.frame = &chick_frames_death2;
		chick_move_death1.frame = &chick_frames_death1;
		chick_move_duck.frame = &chick_frames_duck;

		chick_move_attack1.frame = &chick_frames_attack1;
		chick_move_start_attack1.frame = &chick_frames_start_attack1;
		chick_move_end_attack1.frame = &chick_frames_end_attack1;

		chick_move_slash.frame = &chick_frames_slash;
		chick_move_end_slash.frame = &chick_frames_end_slash;

		chick_move_start_slash.frame = &chick_frames_start_slash;
	}

	sound_missile_prelaunch = gi.soundindex("chick/chkatck1.wav");
	sound_missile_launch    = gi.soundindex("chick/chkatck2.wav");
	sound_melee_swing       = gi.soundindex("chick/chkatck3.wav");
	sound_melee_hit         = gi.soundindex("chick/chkatck4.wav");
	sound_missile_reload    = gi.soundindex("chick/chkatck5.wav");
	sound_death1            = gi.soundindex("chick/chkdeth1.wav");
	sound_death2            = gi.soundindex("chick/chkdeth2.wav");
	sound_fall_down         = gi.soundindex("chick/chkfall1.wav");
	sound_idle1             = gi.soundindex("chick/chkidle1.wav");
	sound_idle2             = gi.soundindex("chick/chkidle2.wav");
	sound_pain1             = gi.soundindex("chick/chkpain1.wav");
	sound_pain2             = gi.soundindex("chick/chkpain2.wav");
	sound_pain3             = gi.soundindex("chick/chkpain3.wav");
	sound_sight             = gi.soundindex("chick/chksght1.wav");
	sound_search            = gi.soundindex("chick/chksrch1.wav");

	self.movetype = MOVETYPE_STEP;
	self.solid = SOLID_BBOX;
	self.s.modelindex = gi.modelindex("models/monsters/bitch/tris.md2");
	self.mins = '-16 -16 0';
	self.maxs = '16 16 56';

	self.health = 175;
	self.gib_health = -70;
	self.mass = 200;

	self.pain = chick_pain;
	self.die = chick_die;

	self.monsterinfo.stand = chick_stand;
	self.monsterinfo.walk = chick_walk;
	self.monsterinfo.run = chick_run;
#ifdef GROUND_ZERO
	self.monsterinfo.dodge = M_MonsterDodge;
	self.monsterinfo.duck = chick_duck;
	self.monsterinfo.unduck = monster_duck_up;
	self.monsterinfo.sidestep = chick_sidestep;
#else
	self.monsterinfo.dodge = chick_dodge;
#endif
	self.monsterinfo.attack = chick_attack;
	self.monsterinfo.melee = chick_melee;
	self.monsterinfo.sight = chick_sight;

	gi.linkentity(self);

	self.monsterinfo.currentmove = &chick_move_stand;
	self.monsterinfo.scale = MODEL_SCALE;

	walkmonster_start(self);

#ifdef GROUND_ZERO
	self.monsterinfo.blindfire = true;
#endif
}

#ifdef THE_RECKONING
/*QUAKED monster_chick_heat (1 .5 0) (-16 -16 -24) (16 16 32) Ambush Trigger_Spawn Sight 
*/
API_FUNC static void(entity self) SP_monster_chick_heat =
{
	SP_monster_chick (self);
	self.s.skinnum = 3;
}
#endif
#endif