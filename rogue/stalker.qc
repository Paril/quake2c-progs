#ifdef GROUND_ZERO

#include "m_stalker.h"

static int	sound_pain;
static int	sound_die;
static int	sound_sight;
static int	sound_punch_hit1;
static int	sound_punch_hit2;
static int	sound_idle;

static inline bool(entity ent) STALKER_ON_CEILING =
{
	return ent.gravityVector[2] > 0;
}

//=========================
//=========================
static bool(entity self) stalker_ok_to_transition =
{
	float		max_dist, margin;

	if (STALKER_ON_CEILING(self))
	{
		max_dist = -384f;
		margin = self.mins[2] - 8;
	}	
	else
	{
		// her stalkers are just better
		if (self.monsterinfo.aiflags & AI_SPAWNED_WIDOW)
			max_dist = 256f;
		else
			max_dist = 180f;
		margin = self.maxs[2] + 8;
	}

	vector pt = self.s.origin;
	pt[2] += max_dist;

	trace_t trace;
	gi.trace(&trace, self.s.origin, self.mins, self.maxs, pt, self, MASK_MONSTERSOLID);

	if(trace.fraction == 1.0 || 
	   !(trace.contents & CONTENTS_SOLID) ||
	   (trace.ent != world))
	{
		if (STALKER_ON_CEILING(self))
		{
			if (trace.normal[2] < 0.9)
				return false;
		}
		else
		{
			if (trace.normal[2] > -0.9)
				return false;
		}
	}

	float end_height = trace.endpos[2];

	// check the four corners, tracing only to the endpoint of the center trace (vertically).
	pt[0] = self.absmin[0];
	pt[1] = self.absmin[1];
	pt[2] = trace.endpos[2] + margin;	// give a little margin of error to allow slight inclines
	vector start = pt;
	start[2] = self.s.origin[2];
	gi.traceline(&trace, start, pt, self, MASK_MONSTERSOLID);
	if (trace.fraction == 1.0 || !(trace.contents & CONTENTS_SOLID) || (trace.ent != world))
		return false;

	if (fabs(end_height + margin - trace.endpos[2]) > 8)
		return false;

	pt[0] = self.absmax[0];
	pt[1] = self.absmin[1];
	start = pt;
	start[2] = self.s.origin[2];
	gi.traceline(&trace, start, pt, self, MASK_MONSTERSOLID);
	if (trace.fraction == 1.0 || !(trace.contents & CONTENTS_SOLID) || (trace.ent != world))
		return false;

	if (fabs(end_height + margin - trace.endpos[2]) > 8)
		return false;

	pt[0] = self.absmax[0];
	pt[1] = self.absmax[1];
	start = pt;
	start[2] = self.s.origin[2];
	gi.traceline(&trace, start, pt, self, MASK_MONSTERSOLID);
	if (trace.fraction == 1.0 || !(trace.contents & CONTENTS_SOLID) || (trace.ent != world))
		return false;

	if (fabs(end_height + margin - trace.endpos[2]) > 8)
		return false;

	pt[0] = self.absmin[0];
	pt[1] = self.absmax[1];
	start = pt;
	start[2] = self.s.origin[2];
	gi.traceline(&trace, start, pt, self, MASK_MONSTERSOLID);
	if (trace.fraction == 1.0 || !(trace.contents & CONTENTS_SOLID) || (trace.ent != world))
		return false;

	if (fabs(end_height + margin - trace.endpos[2]) > 8)
		return false;

	return true;
}

//=========================
//=========================
static void(entity self, entity other) stalker_sight =
{
	gi.sound (self, CHAN_WEAPON, sound_sight, 1, ATTN_NORM, 0);
}

// ******************
// IDLE
// ******************

static void(entity self) stalker_idle_noise =
{
	gi.sound (self, CHAN_WEAPON, sound_idle, 0.5, ATTN_IDLE, 0);
}

static mframe_t stalker_frames_idle [] =
{
	{ ai_stand },
	{ ai_stand },
	{ ai_stand },
	{ ai_stand },
	{ ai_stand },

	{ ai_stand },
	{ ai_stand, 0, stalker_idle_noise },
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
static var mmove_t stalker_move_idle = { FRAME_idle01, FRAME_idle21 };

static mframe_t stalker_frames_idle2 [] =
{
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
static var mmove_t stalker_move_idle2 = { FRAME_idle201, FRAME_idle213 };

static void(entity self) stalker_idle =
{ 
	if (random() < 0.35)
		self.monsterinfo.currentmove = &stalker_move_idle;
	else
		self.monsterinfo.currentmove = &stalker_move_idle2;
}

// ******************
// STAND
// ******************
static mframe_t stalker_frames_stand [] =
{
	{ ai_stand },
	{ ai_stand },
	{ ai_stand },
	{ ai_stand },
	{ ai_stand },

	{ ai_stand },
	{ ai_stand, 0, stalker_idle_noise },
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
static var mmove_t	stalker_move_stand = { FRAME_idle01, FRAME_idle21 };

static void(entity self) stalker_stand =
{
	if (random() < 0.25)
		self.monsterinfo.currentmove = &stalker_move_stand;
	else
		self.monsterinfo.currentmove = &stalker_move_idle2;
}

// ******************
// RUN
// ******************

static mframe_t stalker_frames_run [] =
{
	{ ai_run, 13 },
	{ ai_run, 17 },
	{ ai_run, 21 },
	{ ai_run, 18 }
};
static var mmove_t stalker_move_run = { FRAME_run01, FRAME_run04 };

static void(entity self) stalker_run =
{
	if (self.monsterinfo.aiflags & AI_STAND_GROUND)
		self.monsterinfo.currentmove = &stalker_move_stand;
	else
		self.monsterinfo.currentmove = &stalker_move_run;
}

// ******************
// WALK
// ******************

static mframe_t stalker_frames_walk [] =
{
	{ ai_walk, 4 },
	{ ai_walk, 6 },
	{ ai_walk, 8 },
	{ ai_walk, 5 },

	{ ai_walk, 4 },
	{ ai_walk, 6 },
	{ ai_walk, 8 },
	{ ai_walk, 4 }
};
static var mmove_t stalker_move_walk = { FRAME_walk01, FRAME_walk08 };

static void(entity self) stalker_walk =
{
	self.monsterinfo.currentmove = &stalker_move_walk;
}

// ******************
// false death
// ******************
static mframe_t stalker_frames_reactivate [] = 
{
	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move }
};
static var mmove_t stalker_move_false_death_end = { FRAME_reactive01, FRAME_reactive04, stalker_run };

static inline void(entity self) stalker_reactivate =
{
	self.monsterinfo.aiflags &= ~AI_STAND_GROUND;
	self.monsterinfo.currentmove = &stalker_move_false_death_end;
}

static void(entity self) stalker_heal =
{
	self.health += maxi(1, skill.intVal);

	if (self.health > (self.max_health/2))
		self.s.skinnum = 0;

	if (self.health >= self.max_health)
	{
		self.health = self.max_health;
		stalker_reactivate(self);
	}
}

static mframe_t stalker_frames_false_death [] =
{
	{ ai_move, 0, stalker_heal },
	{ ai_move, 0, stalker_heal },
	{ ai_move, 0, stalker_heal },
	{ ai_move, 0, stalker_heal },
	{ ai_move, 0, stalker_heal },

	{ ai_move, 0, stalker_heal },
	{ ai_move, 0, stalker_heal },
	{ ai_move, 0, stalker_heal },
	{ ai_move, 0, stalker_heal },
	{ ai_move, 0, stalker_heal }
};
static var mmove_t stalker_move_false_death = { FRAME_twitch01, FRAME_twitch10 };

static void(entity self) stalker_false_death =
{
	self.monsterinfo.currentmove = &stalker_move_false_death;
}

static mframe_t stalker_frames_false_death_start [] =
{
	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move },

	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move },
};
static var mmove_t stalker_move_false_death_start = { FRAME_death01, FRAME_death09, stalker_false_death };

static inline void(entity self) stalker_false_death_start =
{
	self.s.angles[2] = 0;
	self.gravityVector = '0 0 -1';

	self.monsterinfo.aiflags |= AI_STAND_GROUND;
	self.monsterinfo.currentmove = &stalker_move_false_death_start;
}

// ******************
// PAIN
// ******************

static mframe_t stalker_frames_pain [] =
{
	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move }
};
static var mmove_t stalker_move_pain = { FRAME_pain01, FRAME_pain04, stalker_run };

static var mmove_t	stalker_move_jump_straightup = { FRAME_jump04, FRAME_jump07, stalker_run };

//===================
// stalker_dodge_jump - abstraction so pain function can trigger a dodge jump too without
//		faking the inputs to stalker_dodge
//===================
static inline void(entity self) stalker_dodge_jump =
{
	self.monsterinfo.currentmove = &stalker_move_jump_straightup;
}

static void(entity self, entity other, float kick, int damage) stalker_pain =
{
	if (self.deadflag == DEAD_DEAD)
		return;

	if (self.health < (self.max_health / 2)) 
		self.s.skinnum = 1;

	if (skill.intVal == 3)
		return;		// no pain anims in nightmare

	if (self.groundentity == null_entity)
		return;

	// if we're reactivating or false dying, ignore the pain.
	if (self.monsterinfo.currentmove == &stalker_move_false_death_end ||
		self.monsterinfo.currentmove == &stalker_move_false_death_start )
		return;

	if (self.monsterinfo.currentmove == &stalker_move_false_death)
	{
		stalker_reactivate(self);
		return;
	}

	if ((self.health > 0) && (self.health < (self.max_health / 4)))
	{
		if (random() < (0.2 * skill.intVal))
		{
			if(!STALKER_ON_CEILING(self) || stalker_ok_to_transition(self) )
			{
				stalker_false_death_start(self);
				return;
			}
		}	
	}

	if (level.framenum < self.pain_debounce_framenum)
		return;

	self.pain_debounce_framenum = level.framenum + (3 * BASE_FRAMERATE);

	if (damage > 10)		// don't react unless the damage was significant
	{
		// stalker should dodge jump periodically to help avoid damage.
		if (self.groundentity != null_entity && (random() < 0.5))
			stalker_dodge_jump(self);
		else
			self.monsterinfo.currentmove = &stalker_move_pain;

		gi.sound (self, CHAN_WEAPON, sound_pain, 1, ATTN_NORM, 0);
	}
}

static bool(entity self, vector dest) stalker_do_pounce;
static void(entity self) stalker_jump_straightup;

// ******************
// STALKER ATTACK
// ******************
static void(entity self) stalker_shoot_attack =
{
	if (!has_valid_enemy(self))
		return;

	if (self.groundentity != null_entity && random() < 0.33)
	{
		vector dir = self.enemy.s.origin - self.s.origin;
		float dist = VectorLength (dir);

		if((dist > 256) || (random() < 0.5))
			stalker_do_pounce(self, self.enemy.s.origin);
		else
			stalker_jump_straightup (self);
	}

	vector f, r;
	AngleVectors (self.s.angles, &f, &r, 0);
	vector start = G_ProjectSource (self.s.origin, '24 0 6', f, r);

	vector dir = self.enemy.s.origin - start;
	vector end;

	if (random() < (0.20 + 0.1 * skill.intVal))
	{
		float dist = VectorLength(dir);
		float time = dist / 1000;
		end = self.enemy.s.origin + (self.enemy.velocity * time);
		dir = end - start;
	}
	else
		end = self.enemy.s.origin;

	trace_t	trace;
	gi.traceline(&trace, start, end, self, MASK_SHOT);

	if (trace.ent == self.enemy || trace.ent == world)
		monster_fire_blaster2(self, start, dir, 15, 800, MZ2_STALKER_BLASTER, EF_BLASTER);
}

static void(entity self) stalker_shoot_attack2 =
{
	if (random() < (0.4 + (0.1 * skill.intVal)))
		stalker_shoot_attack (self);
}

static mframe_t stalker_frames_shoot [] =
{
	{ ai_charge, 13 },
	{ ai_charge, 17, stalker_shoot_attack },
	{ ai_charge, 21 },
	{ ai_charge, 18, stalker_shoot_attack2 }
};
static var mmove_t stalker_move_shoot = { FRAME_run01, FRAME_run04, stalker_run };

static void(entity self) stalker_attack_ranged =
{
	if (!has_valid_enemy(self))
		return;

	// PMM - circle strafe stuff
	if (random() > (1.0 - (0.5 / skill.intVal)))
		self.monsterinfo.attack_state = AS_STRAIGHT;
	else
	{
		if (random () <= 0.5) // switch directions
			self.monsterinfo.lefty = !self.monsterinfo.lefty;
		self.monsterinfo.attack_state = AS_SLIDING;
	}

	self.monsterinfo.currentmove = &stalker_move_shoot;
}

// ******************
// close combat
// ******************
static void(entity self) stalker_swing_attack =
{
	if (fire_hit (self, [ MELEE_DISTANCE, 0, 0 ], (5 + (Q_rand() % 5)), 50))
		if (self.s.frame < FRAME_attack08)
			gi.sound (self, CHAN_WEAPON, sound_punch_hit2, 1, ATTN_NORM, 0);
		else
			gi.sound (self, CHAN_WEAPON, sound_punch_hit1, 1, ATTN_NORM, 0);
}

static mframe_t stalker_frames_swing_l [] =
{
	{ ai_charge, 2 },
	{ ai_charge, 4 },
	{ ai_charge, 6 },
	{ ai_charge, 10 },

	{ ai_charge, 5, stalker_swing_attack },
	{ ai_charge, 5 },
	{ ai_charge, 5 },
	{ ai_charge, 5 }  // stalker_swing_check_l
};
static var mmove_t stalker_move_swing_l = { FRAME_attack01, FRAME_attack08, stalker_run };

static mframe_t stalker_frames_swing_r [] =
{
	{ ai_charge, 4 },
	{ ai_charge, 6 },
	{ ai_charge, 6, stalker_swing_attack },
	{ ai_charge, 10 },
	{ ai_charge, 5 }	// stalker_swing_check_r
};
static var mmove_t stalker_move_swing_r = { FRAME_attack11, FRAME_attack15, stalker_run };

static void(entity self) stalker_attack_melee =
{
	if (!has_valid_enemy(self))
		return;

	if (random() < 0.5)
		self.monsterinfo.currentmove = &stalker_move_swing_l;
	else
		self.monsterinfo.currentmove = &stalker_move_swing_r;
}

// ******************
// POUNCE
// ******************

const float FAUX_GRAVITY	= 800.0f;

// ====================
// ====================
static vector(vector start, vector end, float velocity) calcJumpAngle =
{
	vector dist = end - start;
	float distH = sqrt(dist[0]*dist[0] + dist[1]*dist[1]);
	float distV = dist[2];
	if (distV < 0)
		distV = -distV;

	vector angles;

	if (distV)
	{
		float l = sqrt(distH*distH + distV*distV);
		float U = atan(distV / distH);
		if (dist[2] > 0)
			U = -U;

		angles[2] = 0.0f;

		float cosU = cos(U);
		float one = l * FAUX_GRAVITY * (cosU * cosU);
		one = one / (velocity * velocity);
		one = one - sin(U);
		angles[0] = asin(one);
		if (isnan(angles[0]))
			angles[2] = 1.0;
		angles[1] = M_PI - angles[0];
		if (isnan(angles[1]))
			angles[2] = 1.0;

		angles[0] = RAD2DEG((angles[0] - U) / 2.0);
		angles[1] = RAD2DEG((angles[1] - U) / 2.0);
	}
	else
	{
		float l = sqrt(distH*distH + distV*distV);

		angles[2] = 0.0f;

		float one = l * FAUX_GRAVITY;
		one = one / (velocity * velocity);
		angles[0] = asin(one);
		if(isnan(angles[0]))
			angles[2] = 1.0;
		angles[1] = M_PI - angles[0];
		if(isnan(angles[1]))
			angles[2] = 1.0;

		angles[0] = RAD2DEG ( (angles[0]) / 2.0 );
		angles[1] = RAD2DEG ( (angles[1]) / 2.0 );
	}
	
	return angles;
}

// ====================
// ====================
static bool(entity self, entity target, vector dest) stalker_check_lz =
{
	if ((gi.pointcontents(dest) & MASK_WATER) || (target.waterlevel))
		return false;

	if (target.groundentity == null_entity)
		return false;

	// check under the player's four corners
	// if they're not solid, bail.
	vector jumpLZ = self.enemy.mins;
	jumpLZ[2] -= 0.25;
	if (!(gi.pointcontents (jumpLZ) & MASK_SOLID))
		return false;

	jumpLZ[0] = self.enemy.maxs[0];
	jumpLZ[1] = self.enemy.mins[1];
	if (!(gi.pointcontents (jumpLZ) & MASK_SOLID))
		return false;

	jumpLZ[0] = self.enemy.maxs[0];
	jumpLZ[1] = self.enemy.maxs[1];
	if (!(gi.pointcontents (jumpLZ) & MASK_SOLID))
		return false;

	jumpLZ[0] = self.enemy.mins[0];
	jumpLZ[1] = self.enemy.maxs[1];
	if (!(gi.pointcontents (jumpLZ) & MASK_SOLID))
		return false;

	return true;
}

// ====================
// ====================
static bool(entity self, vector dest) stalker_do_pounce =
{
	// don't pounce when we're on the ceiling
	if (STALKER_ON_CEILING(self))
		return false;

	if (!stalker_check_lz (self, self.enemy, dest))
		return false;

	vector dist = dest - self.s.origin;
	
	// make sure we're pointing in that direction 15deg margin of error.
	vector jumpAngles = vectoangles (dist);
	if (fabs(jumpAngles[YAW] - self.s.angles[YAW]) > 45)
		return false;			// not facing the player...

	self.ideal_yaw = jumpAngles[YAW];
	M_ChangeYaw(self);

	float length = VectorLength(dist);
	if (length > 450)
		return false;			// can't jump that far...

	vector jumpLZ = dest;
	bool preferHighJump = false;

	// if we're having to jump up a distance, jump a little too high to compensate.
	if (dist[2] >= 32.0)
	{
		preferHighJump = true;
		jumpLZ[2] += 32f;
	}

	trace_t	trace;
	gi.traceline(&trace, self.s.origin, dest, self, MASK_MONSTERSOLID);

	if ((trace.fraction < 1) && (trace.ent != self.enemy))
		preferHighJump = true;

	// find a valid angle/velocity combination
	float cvelocity = 400.1f;

	while (cvelocity <= 800)
	{
		jumpAngles = calcJumpAngle(self.s.origin, jumpLZ, cvelocity);

		if (!isnan(jumpAngles[0]) || !isnan(jumpAngles[1]))
			break;
		
		cvelocity += 200;
	}

	if (!preferHighJump && (!isnan(jumpAngles[0])))
	{
		vector forward;
		AngleVectors (self.s.angles, &forward, 0, 0);
		VectorNormalize(forward);

		self.velocity = forward * (cvelocity * cos(DEG2RAD(jumpAngles[0])));
		self.velocity[2] = cvelocity * sin(DEG2RAD(jumpAngles[0])) + (0.5 * sv_gravity.floatVal * FRAMETIME);

		return true;
	}

	if (!isnan(jumpAngles[1]))
	{
		vector forward;
		AngleVectors (self.s.angles, &forward, 0, 0);
		VectorNormalize(forward);

		self.velocity = forward * (cvelocity * cos(DEG2RAD(jumpAngles[1])));
		self.velocity[2] = cvelocity * sin(DEG2RAD(jumpAngles[1])) + (0.5 * sv_gravity.floatVal * FRAMETIME);

		return true;
	}

	return false;
}

// ******************
// DODGE
// ******************

//===================
// stalker_jump_straightup
//===================
static void(entity self) stalker_jump_straightup =
{
	if (self.deadflag == DEAD_DEAD)
		return;

	if (STALKER_ON_CEILING(self))
	{
		if (stalker_ok_to_transition(self))
		{
			self.gravityVector[2] = -1f;
			self.s.angles[2] += 180.0;
			if (self.s.angles[2] > 360.0)
				self.s.angles[2] -= 360.0;
			self.groundentity = null_entity;
		}
	}
	else if (self.groundentity != null_entity)	// make sure we're standing on SOMETHING...
	{
		self.velocity[0] += random(-5f, 5f);
		self.velocity[1] += random(-5f, 5f);
		self.velocity[2] += -400 * self.gravityVector[2];
		if (stalker_ok_to_transition(self))
		{
			self.gravityVector[2] = 1f;
			self.s.angles[2] = 180.0;
			self.groundentity = null_entity;
		}
	}
}

static void(entity self) stalker_jump_wait_land =
{
	if ((random() < (0.3 + (0.1* skill.floatVal))) && (level.framenum >= self.monsterinfo.attack_finished))
	{
		self.monsterinfo.attack_finished = level.framenum + (int)(0.3 * BASE_FRAMERATE);
		stalker_shoot_attack(self);
	}

	if (self.groundentity == null_entity)
	{
		self.gravity = 1.3f;
		self.monsterinfo.nextframe = self.s.frame;

		if (monster_jump_finished (self))
		{
			self.gravity = 1f;
			self.monsterinfo.nextframe = self.s.frame + 1;
		}
	}
	else 
	{
		self.gravity = 1f;
		self.monsterinfo.nextframe = self.s.frame + 1;
	}
}

static mframe_t stalker_frames_jump_straightup [] =
{
	{ ai_move, 1,  stalker_jump_straightup },
	{ ai_move, 1,  stalker_jump_wait_land },
	{ ai_move, -1 },
	{ ai_move, -1 }
};

static mframe_t stalker_frames_dodge_run [] =
{
	{ ai_run, 13 },
	{ ai_run, 17 },
	{ ai_run, 21 },
	{ ai_run, 18, monster_done_dodge }
};
static var mmove_t stalker_move_dodge_run = { FRAME_run01, FRAME_run04 };

static void(entity self, entity attacker, float eta, trace_t *tr) stalker_dodge =
{
	if (self.groundentity == null_entity || self.health <= 0)
		return;

	if (!self.enemy)
	{
		self.enemy = attacker;
		FoundTarget(self);
		return;
	}
	
	// PMM - don't bother if it's going to hit anyway; fix for weird in-your-face etas (I was
	// seeing numbers like 13 and 14)
	if ((eta < 0.1) || (eta > 5))
		return;

	// this will override the foundtarget call of stalker_run
	stalker_dodge_jump(self);
}


// ******************
// Jump onto / off of things
// ******************

//===================
//===================
static void(entity self) stalker_jump_down =
{
	monster_jump_start(self);

	vector forward, up;
	AngleVectors (self.s.angles, &forward, 0, &up);
	self.velocity += (forward * 100);
	self.velocity += (up * 300);
}

//===================
//===================
static void(entity self) stalker_jump_up =
{
	monster_jump_start (self);

	vector forward,up;
	AngleVectors (self.s.angles, &forward, 0, &up);
	self.velocity += (forward * 200);
	self.velocity += (up * 450);
}

//===================
//===================

static mframe_t stalker_frames_jump_up [] =
{
	{ ai_move, -8 },
	{ ai_move, -8 },
	{ ai_move, -8 },
	{ ai_move, -8 },

	{ ai_move, 0, stalker_jump_up },
	{ ai_move, 0, stalker_jump_wait_land },
	{ ai_move }
};
static var mmove_t stalker_move_jump_up = { FRAME_jump01, FRAME_jump07, stalker_run };

static mframe_t stalker_frames_jump_down [] =
{
	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move },

	{ ai_move, 0, stalker_jump_down },
	{ ai_move, 0, stalker_jump_wait_land },
	{ ai_move }
};
static var mmove_t stalker_move_jump_down = { FRAME_jump01, FRAME_jump07, stalker_run };

//============
// stalker_jump - this is only used for jumping onto or off of things. for dodge jumping,
//		use stalker_dodge_jump
//============
static void(entity self) stalker_jump =
{
	if (!self.enemy)
		return;

	if (self.enemy.s.origin[2] >= self.s.origin[2])
		self.monsterinfo.currentmove = &stalker_move_jump_up;
	else
		self.monsterinfo.currentmove = &stalker_move_jump_down;
}


// ******************
// Blocked
// ******************
static bool(entity self, float dist) stalker_blocked =
{
	if (!has_valid_enemy(self))
		return false;

	bool onCeiling = (self.gravityVector[2] > 0);

	if (!onCeiling)
	{
		if (blocked_checkshot(self, 0.25 + (0.05 * skill.floatVal)))
			return true;

		if (visible (self, self.enemy))
		{
			stalker_do_pounce(self, self.enemy.s.origin);
			return true;
		}

		if (blocked_checkjump (self, dist, 256, 68))
		{
			stalker_jump (self);
			return true;
		}

		if (blocked_checkplat (self, dist))
			return true;
	}
	else if (blocked_checkshot(self, 0.25 + (0.05 * skill.floatVal) ))
		return true;
	else if (stalker_ok_to_transition(self))
	{
		self.gravityVector[2] = -1f;
		self.s.angles[2] += 180.0;
		if(self.s.angles[2] > 360.0)
			self.s.angles[2] -= 360.0;
		self.groundentity = null_entity;
		
		return true;
	}

	return false;
}

// ******************
// Death
// ******************

static void(entity self) stalker_dead =
{
	self.mins = '-28 -28 -18';
	self.maxs = '28 28 -4';
	self.movetype = MOVETYPE_TOSS;
	self.svflags |= SVF_DEADMONSTER;
	self.nextthink = 0;
	gi.linkentity (self);
}

static mframe_t stalker_frames_death [] =
{
	{ ai_move },
	{ ai_move, -5 },
	{ ai_move, -10 },
	{ ai_move, -20 },

	{ ai_move, -10 },
	{ ai_move, -10 },
	{ ai_move, -5 },
	{ ai_move, -5 },

	{ ai_move }
};
static var mmove_t stalker_move_death = { FRAME_death01, FRAME_death09, stalker_dead };

static void(entity self, entity inflictor, entity attacker, int damage, vector point) stalker_die =
{
// dude bit it, make him fall!
	self.movetype = MOVETYPE_TOSS;
	self.s.angles[2] = 0;
	self.gravityVector = '0 0 -1';

// check for gib
	if (self.health <= self.gib_health)
	{
		gi.sound (self, CHAN_VOICE, gi.soundindex ("misc/udeath.wav"), 1, ATTN_NORM, 0);
		for (int n = 0; n < 2; n++)
			ThrowGib (self, "models/objects/gibs/bone/tris.md2", damage, GIB_ORGANIC);
		for (int n = 0; n < 4; n++)
			ThrowGib (self, "models/objects/gibs/sm_meat/tris.md2", damage, GIB_ORGANIC);
		ThrowHead (self, "models/objects/gibs/head2/tris.md2", damage, GIB_ORGANIC);
		self.deadflag = DEAD_DEAD;
		return;
	}

	if (self.deadflag == DEAD_DEAD)
		return;

// regular death
	gi.sound (self, CHAN_VOICE, sound_die, 1, ATTN_NORM, 0);
	self.deadflag = DEAD_DEAD;
	self.takedamage = true;
	self.monsterinfo.currentmove = &stalker_move_death;
}


// ******************
// SPAWN
// ******************

/*QUAKED monster_stalker (1 .5 0) (-28 -28 -18) (28 28 18) Ambush Trigger_Spawn Sight OnRoof
Spider Monster

  ONROOF - Monster starts sticking to the roof.
*/
API_FUNC static void(entity self) SP_monster_stalker =
{
	if (deathmatch.intVal)
	{
		G_FreeEdict (self);
		return;
	}

	if (!stalker_move_idle.frame)
	{
		stalker_move_idle.frame = &stalker_frames_idle;
		stalker_move_idle.endfunc = stalker_stand;
		stalker_move_idle2.frame = &stalker_frames_idle2;
		stalker_move_idle2.endfunc = stalker_stand;
		stalker_move_stand.frame = &stalker_frames_stand;
		stalker_move_stand.endfunc = stalker_stand;
		stalker_move_run.frame = &stalker_frames_run;
		stalker_move_walk.frame = &stalker_frames_walk;
		stalker_move_walk.endfunc = stalker_walk;
		stalker_move_false_death_end.frame = &stalker_frames_reactivate;
		stalker_move_false_death.frame = &stalker_frames_false_death;
		stalker_move_false_death.endfunc = stalker_false_death;
		stalker_move_false_death_start.frame = &stalker_frames_false_death_start;
		stalker_move_pain.frame = &stalker_frames_pain;
		stalker_move_shoot.frame = &stalker_frames_shoot;
		stalker_move_swing_l.frame = &stalker_frames_swing_l;
		stalker_move_swing_r.frame = &stalker_frames_swing_r;
		stalker_move_jump_straightup.frame = &stalker_frames_jump_straightup;
		stalker_move_dodge_run.frame = &stalker_frames_dodge_run;
		stalker_move_jump_up.frame = &stalker_frames_jump_up;
		stalker_move_jump_down.frame = &stalker_frames_jump_down;
		stalker_move_death.frame = &stalker_frames_death;
	}

	sound_pain = gi.soundindex ("stalker/pain.wav");	
	sound_die = gi.soundindex ("stalker/death.wav");	
	sound_sight = gi.soundindex("stalker/sight.wav");
	sound_punch_hit1 = gi.soundindex ("stalker/melee1.wav");
	sound_punch_hit2 = gi.soundindex ("stalker/melee2.wav");
	sound_idle = gi.soundindex ("stalker/idle.wav");

	// PMM - precache bolt2
	gi.modelindex ("models/proj/laser2/tris.md2");

	self.s.modelindex = gi.modelindex ("models/monsters/stalker/tris.md2");
	self.mins = '-28 -28 -18';
	self.maxs = '28 28 18';
	self.movetype = MOVETYPE_STEP;
	self.solid = SOLID_BBOX;

	self.health = 250;
	self.gib_health = -50;
	self.mass = 250;

	self.pain = stalker_pain;
	self.die = stalker_die;

	self.monsterinfo.stand = stalker_stand;
	self.monsterinfo.walk = stalker_walk;
	self.monsterinfo.run = stalker_run;
	self.monsterinfo.attack = stalker_attack_ranged;
	self.monsterinfo.sight = stalker_sight;
	self.monsterinfo.idle = stalker_idle;
	self.monsterinfo.dodge = stalker_dodge;
	self.monsterinfo.blocked = stalker_blocked;
	self.monsterinfo.melee = stalker_attack_melee;

	gi.linkentity (self);

	self.monsterinfo.currentmove = &stalker_move_stand;	
	self.monsterinfo.scale = MODEL_SCALE;

	self.monsterinfo.aiflags |= AI_WALK_WALLS;

	if (self.spawnflags & 8)
	{
		self.s.angles[2] = 180f;
		self.gravityVector[2] = 1f;
	}

	walkmonster_start (self);
}

#endif