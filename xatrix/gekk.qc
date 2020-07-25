#ifdef THE_RECKONING

#include "m_gekk.h"

static int	sound_swing;
static int	sound_hit;
static int	sound_hit2;
static int	sound_death;
static int	sound_pain1;
static int	sound_sight;
static int	sound_search;
static int	sound_step1;
static int	sound_step2;
static int	sound_step3;
static int	sound_thud;
static int  sound_chantlow;
static int  sound_chantmid;
static int  sound_chanthigh;

//
// CHECKATTACK
//

static bool(entity self) gekk_check_melee =
{
	if (!self.enemy && self.enemy.health <= 0)
		return false;

	if (range (self, self.enemy) == RANGE_MELEE)
		return true;
	return false;
}

static bool(entity self) gekk_check_jump =
{
	vector	v;
	float	distance;

	if (self.absmin[2] > (self.enemy.absmin[2] + 0.75 * self.enemy.size[2]))
		return false;

	if (self.absmax[2] < (self.enemy.absmin[2] + 0.25 * self.enemy.size[2]))
		return false;

	v[0] = self.s.origin[0] - self.enemy.s.origin[0];
	v[1] = self.s.origin[1] - self.enemy.s.origin[1];
	v[2] = 0;
	distance = VectorLength(v);

	if (distance < 100)
	{
		return false;
	}
	if (distance > 100)
	{
		if (random() < 0.9)
			return false;
	}

	return true;
}

static bool(entity self) gekk_check_jump_close =
{
	vector	v;
	float	distance;

	v[0] = self.s.origin[0] - self.enemy.s.origin[0];
	v[1] = self.s.origin[1] - self.enemy.s.origin[1];
	v[2] = 0;
	
	distance = VectorLength(v);

	if (distance < 100)
	{
		if (self.s.origin[2] < self.enemy.s.origin[2])
			return true;
		else
			return false;
	}
	
	return true;
}


static bool(entity self) gekk_checkattack =
{
	if (!self.enemy || self.enemy.health <= 0)
		return false;

	if (gekk_check_melee(self))
	{
		self.monsterinfo.attack_state = AS_MELEE;
		return true;
	}

	if (gekk_check_jump(self))
	{
		self.monsterinfo.attack_state = AS_MISSILE;
		return true;
	}

	if (gekk_check_jump_close (self) && !self.waterlevel)
	{	
		self.monsterinfo.attack_state = AS_MISSILE;
		return true;
	}

	return false;
}


//
// SOUNDS
//

static void(entity self) gekk_step =
{
	int		n;
	n = (Q_rand() + 1) % 3;
	if (n == 0)
		gi.sound (self, CHAN_VOICE, sound_step1, 1, ATTN_NORM, 0);		
	else if (n == 1)
		gi.sound (self, CHAN_VOICE, sound_step2, 1, ATTN_NORM, 0);
	else
		gi.sound (self, CHAN_VOICE, sound_step3, 1, ATTN_NORM, 0);
}

static void(entity self, entity other) gekk_sight =
{
	gi.sound (self, CHAN_VOICE, sound_sight, 1, ATTN_NORM, 0);
}

static void(entity self) gekk_search =
{
	float r;

	if (self.spawnflags & 8)
	{
		r = random();
		if (r < 0.33)
			gi.sound (self, CHAN_VOICE, sound_chantlow, 1, ATTN_NORM, 0);
		else if (r < 0.66)
			gi.sound (self, CHAN_VOICE, sound_chantmid, 1, ATTN_NORM, 0);
		else
			gi.sound (self, CHAN_VOICE, sound_chanthigh, 1, ATTN_NORM, 0);
	}
	else
		gi.sound (self, CHAN_VOICE, sound_search, 1, ATTN_NORM, 0);
	

	self.health += (int)random(10f, 20f);
	if (self.health > self.max_health)
		self.health = self.max_health;

	if (self.health < (self.max_health /4))
		self.s.skinnum = 2;
	else if (self.health < (self.max_health / 2))
		self.s.skinnum = 1;
	else 
		self.s.skinnum = 0;
}

static void(entity self) gekk_swing =
{
	gi.sound (self, CHAN_VOICE, sound_swing, 1, ATTN_NORM, 0);
}


//
// ATTACK
//

static void(entity self, entity other, cplane_t plane, csurface_t surf) gekk_jump_touch =
{
	if (self.health <= 0)
	{
		self.touch = 0;
		return;
	}

	if (other.takedamage)
	{
		if (VectorLength(self.velocity) > 200)
		{
			vector	point;
			vector	normal;
			int	damage;

			normal = self.velocity;
			VectorNormalize(normal);
			point = self.s.origin + (normal * self.maxs[0]);
			damage = (int)random(10f, 20f);
			T_Damage (other, self, self, self.velocity, point, normal, damage, damage, 0, MOD_GEKK);
		}
	}

	if (!M_CheckBottom (self))
	{
		if (self.groundentity != null_entity)
		{
			self.monsterinfo.nextframe = FRAME_leapatk_11;
			self.touch = 0;
		}
		return;
	}

	self.touch = 0;
}

static void(entity self) gekk_jump_takeoff =
{
	vector	forward;

	gi.sound (self, CHAN_VOICE, sound_sight, 1, ATTN_NORM, 0);
	AngleVectors (self.s.angles, &forward, 0, 0);
	self.s.origin[2] += 1;
	
	// high jump
	if (gekk_check_jump (self))
	{
		self.velocity = forward * 700;
		self.velocity[2] = 250f;
	}
	else
	{
		self.velocity = forward * 250;
		self.velocity[2] = 400f;
	}

	
	self.groundentity = null_entity;
	self.monsterinfo.aiflags |= AI_DUCKED;
	self.monsterinfo.attack_finished = level.framenum + 3 * BASE_FRAMERATE;
	self.touch = gekk_jump_touch;
}

static void(entity self) gekk_jump_takeoff2 =
{
	vector	forward;

	gi.sound (self, CHAN_VOICE, sound_sight, 1, ATTN_NORM, 0);
	AngleVectors (self.s.angles, &forward, 0, 0);
	self.s.origin[2] = self.enemy.s.origin[2];
	
	if (gekk_check_jump (self))
	{
		self.velocity = forward * 300;
		self.velocity[2] = 250f;
	}
	else 
	{
		self.velocity = forward * 150;
		self.velocity[2] = 300f;
	}

	self.groundentity = null_entity;
	self.monsterinfo.aiflags |= AI_DUCKED;
	self.monsterinfo.attack_finished = level.framenum + 3 * BASE_FRAMERATE;
	self.touch = gekk_jump_touch;
}

static void(entity self) gekk_stop_skid =
{
	if (self.groundentity != null_entity)
	{
		self.velocity = vec3_origin;
	}
}

static void(entity self) gekk_check_landing =
{
	if (self.groundentity != null_entity)
	{
		gi.sound (self, CHAN_WEAPON, sound_thud, 1, ATTN_NORM, 0);
		self.monsterinfo.attack_finished = 0;
		self.monsterinfo.aiflags &= ~AI_DUCKED;

		self.velocity = vec3_origin;
		return;
	}

	// note to self
	// causing skid
	if (level.framenum > self.monsterinfo.attack_finished)
		self.monsterinfo.nextframe = FRAME_leapatk_11;
	else
		self.monsterinfo.nextframe = FRAME_leapatk_12;
}

static void(entity self) land_to_water;

static void(entity self) gekk_check_underwater =
{
	if (self.waterlevel)
		land_to_water (self);
}

static mframe_t gekk_frames_leapatk2[] = 
{
 { ai_charge,   0.000 }, // frame 0
 { ai_charge,  -0.387 }, // frame 1
 { ai_charge,  -1.113 }, // frame 2
 { ai_charge,  -0.237 }, // frame 3
 { ai_charge,   6.720, gekk_jump_takeoff2 }, // frame 4  last frame on ground
 { ai_charge,   6.414 }, // frame 5  leaves ground
 { ai_charge,   0.163 }, // frame 6
 { ai_charge,  28.316 }, // frame 7
 { ai_charge,  24.198 }, // frame 8
 { ai_charge,  31.742 }, // frame 9
 { ai_charge,  35.977, gekk_check_landing }, // frame 10  last frame in air
 { ai_charge,  12.303, gekk_stop_skid }, // frame 11  feet back on ground
 { ai_charge,  20.122, gekk_stop_skid }, // frame 12
 { ai_charge,  -1.042, gekk_stop_skid }, // frame 13
 { ai_charge,   2.556, gekk_stop_skid }, // frame 14
 { ai_charge,   0.544, gekk_stop_skid }, // frame 15
 { ai_charge,   1.862, gekk_stop_skid }, // frame 16
 { ai_charge,   1.224, gekk_stop_skid }, // frame 17
 
 { ai_charge,  -0.457, gekk_check_underwater }, // frame 18
};
static var mmove_t gekk_move_leapatk2 = { FRAME_leapatk_01, FRAME_leapatk_19 };

static void(entity self) water_to_land =
{
	self.flags &= ~FL_SWIM;
	self.yaw_speed = 20f;
	self.viewheight = 25;
	
	self.monsterinfo.currentmove = &gekk_move_leapatk2;
	
	self.mins = '-24 -24 -24';
	self.maxs = '24 24 24';
}

static void(entity self) gekk_run;

static void(entity self) gekk_swim =
{
	if (gekk_checkattack(self))	// Knightmare fixed, added argument
		if (!self.enemy.waterlevel && random() > 0.7)
			water_to_land (self);
	else
		gekk_run(self);
}

static mframe_t gekk_frames_swim [] =
{
	{ ai_run, 16 },	
	{ ai_run, 16 },
	{ ai_run, 16 },
	
	{ ai_run, 16, gekk_swim }
};
static var mmove_t gekk_move_swim_loop = { FRAME_amb_01, FRAME_amb_04 };

static void(entity self) gekk_swim_loop =
{
	self.flags |= FL_SWIM;	
	self.monsterinfo.currentmove = &gekk_move_swim_loop;
}

static void(entity self) gekk_hit_left =
{
	static const vector aim = [ MELEE_DISTANCE, self.mins[0], 8 ];

	if (fire_hit (self, aim, (15 + (Q_rand() %5)), 100))
		gi.sound (self, CHAN_WEAPON, sound_hit, 1, ATTN_NORM, 0);
	else
		gi.sound (self, CHAN_WEAPON, sound_swing, 1, ATTN_NORM, 0);
}

static void(entity self) gekk_hit_right =
{
	static const vector aim = [ MELEE_DISTANCE, self.maxs[0], 8 ];

	if (fire_hit (self, aim, (15 + (Q_rand() %5)), 100))
		gi.sound (self, CHAN_WEAPON, sound_hit2, 1, ATTN_NORM, 0);
	else
		gi.sound (self, CHAN_WEAPON, sound_swing, 1, ATTN_NORM, 0);
}

static void(entity self) gekk_bite =
{
	static const vector aim = [ MELEE_DISTANCE, 0, 0 ];
	fire_hit (self, aim, 5, 0);
}

static mframe_t gekk_frames_swim_start [] =
{
	{ ai_run, 14 },
	{ ai_run, 14 },
	{ ai_run, 14 },
	{ ai_run, 14 },
	{ ai_run, 16 },
	{ ai_run, 16 },
	{ ai_run, 16 },
	{ ai_run, 18 },
	{ ai_run, 18, gekk_hit_left },
	{ ai_run, 18 },
	
	{ ai_run, 20 },
	{ ai_run, 20 },
	{ ai_run, 22 },
	{ ai_run, 22 },
	{ ai_run, 24, gekk_hit_right },
	{ ai_run, 24 },
	{ ai_run, 26 },
	{ ai_run, 26 },
	{ ai_run, 24 },
	{ ai_run, 24 },
	
	{ ai_run, 22, gekk_bite },
	{ ai_run, 22 },
	{ ai_run, 22 },
	{ ai_run, 22 },
	{ ai_run, 22 },
	{ ai_run, 22 },
	{ ai_run, 22 },
	{ ai_run, 22 },
	{ ai_run, 18 },
	{ ai_run, 18 },

	{ ai_run, 18 },
	{ ai_run, 18 }
};
static var mmove_t gekk_move_swim_start = { FRAME_swim_01, FRAME_swim_32, gekk_swim_loop };

static void(entity self) land_to_water =
{
	self.flags |= FL_SWIM;
	self.yaw_speed = 10f;
	self.viewheight = 10;
	
	self.monsterinfo.currentmove = &gekk_move_swim_start;
	
	self.mins = '-24 -24 -24';
	self.maxs = '24 24 16';
}

static mframe_t gekk_frames_run[] = 
{
	{ ai_run,   3.849, gekk_check_underwater }, // frame 0
	{ ai_run,  19.606 }, // frame 1
	{ ai_run,  25.583 }, // frame 2
	{ ai_run,  34.625, gekk_step }, // frame 3
	{ ai_run,  27.365 }, // frame 4
	{ ai_run,  28.480 }, // frame 5
};
static var mmove_t gekk_move_run = { FRAME_run_01, FRAME_run_06 };

static void(entity self) gekk_face =
{
	self.monsterinfo.currentmove = &gekk_move_run;	
}

//
// STAND
//

static void(entity self, float dist) ai_stand2 =
{
	if (self.spawnflags & 8)
	{
		ai_move (self, dist);
		if (!(self.spawnflags & 1) && (self.monsterinfo.idle) && (level.framenum > self.monsterinfo.idle_framenum))
		{
			if (self.monsterinfo.idle_framenum)
			{
				self.monsterinfo.idle (self);
				self.monsterinfo.idle_framenum = level.framenum + (int)(random(15f, 30f) * BASE_FRAMETIME);
			}
			else
			{
				self.monsterinfo.idle_framenum = level.framenum + (int)(random(15f) * BASE_FRAMETIME);
			}
		}
	}
	else
		ai_stand (self, dist);
}

static mframe_t gekk_frames_stand [] =
{
	{ ai_stand2 },
	{ ai_stand2 },
	{ ai_stand2 },
	{ ai_stand2 },
	{ ai_stand2 },
	{ ai_stand2 },
	{ ai_stand2 },
	{ ai_stand2 },
	{ ai_stand2 },
	{ ai_stand2 },		// 10

	{ ai_stand2 },
	{ ai_stand2 },
	{ ai_stand2 },
	{ ai_stand2 },
	{ ai_stand2 },
	{ ai_stand2 },
	{ ai_stand2 },
	{ ai_stand2 },
	{ ai_stand2 },
	{ ai_stand2 },		// 20

	{ ai_stand2 },
	{ ai_stand2 },
	{ ai_stand2 },
	{ ai_stand2 },
	{ ai_stand2 },
	{ ai_stand2 },
	{ ai_stand2 },
	{ ai_stand2 },
	{ ai_stand2 },
	{ ai_stand2 },		// 30

	{ ai_stand2 },
	{ ai_stand2 },
	{ ai_stand2 },
	{ ai_stand2 },
	{ ai_stand2 },
	{ ai_stand2 },
	{ ai_stand2 },
	{ ai_stand2 },
	
	{ ai_stand2, 0, gekk_check_underwater },
};
static var mmove_t gekk_move_stand = { FRAME_stand_01, FRAME_stand_39 };

static mframe_t gekk_frames_standunderwater[] =
{
	{ ai_stand2 },	
	{ ai_stand2 },
	{ ai_stand2 },
	
	{ ai_stand2, 0, gekk_check_underwater }
};
static var mmove_t gekk_move_standunderwater = { FRAME_amb_01, FRAME_amb_04 };

static void(entity self) gekk_stand =
{
	if (self.waterlevel)
		self.monsterinfo.currentmove = &gekk_move_standunderwater;
	else
		self.monsterinfo.currentmove = &gekk_move_stand;
}

static var mmove_t gekk_move_chant;

static void(entity self) gekk_chant =
{
	self.monsterinfo.currentmove = &gekk_move_chant;
}

//
// IDLE
//

static void(entity self) gekk_idle_loop =
{
	if (random() > 0.75 && self.health < self.max_health)
		self.monsterinfo.nextframe = FRAME_idle_01;
}

static mframe_t gekk_frames_idle [] =
{
	{ ai_stand2, 0, gekk_search },
	{ ai_stand2 },
	{ ai_stand2 },
	{ ai_stand2 },
	{ ai_stand2 },
	{ ai_stand2 },
	{ ai_stand2 },
	{ ai_stand2 },
	{ ai_stand2 },
	{ ai_stand2 },
	
	{ ai_stand2 },
	{ ai_stand2 },
	{ ai_stand2 },
	{ ai_stand2 },
	{ ai_stand2 },
	{ ai_stand2 },
	{ ai_stand2 },
	{ ai_stand2 },
	{ ai_stand2 },
	{ ai_stand2 },
	
	{ ai_stand2 },
	{ ai_stand2 },
	{ ai_stand2 },
	{ ai_stand2 },
	{ ai_stand2 },
	{ ai_stand2 },
	{ ai_stand2 },
	{ ai_stand2 },
	{ ai_stand2 },
	{ ai_stand2 },
	
	{ ai_stand2 },
	{ ai_stand2, 0, gekk_idle_loop }
};
static var mmove_t gekk_move_idle = { FRAME_idle_01, FRAME_idle_32, gekk_stand };
static var mmove_t gekk_move_idle2 = { FRAME_idle_01, FRAME_idle_32, gekk_face };

static mframe_t gekk_frames_idle2 [] =
{
	{ ai_move, 0, gekk_search },		
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
	
	{ ai_move },
	{ ai_move, 0, gekk_idle_loop }
};
static var mmove_t gekk_move_chant = { FRAME_idle_01, FRAME_idle_32, gekk_chant };

static void(entity self) gekk_idle =
{
	if (!self.waterlevel)
		self.monsterinfo.currentmove = &gekk_move_idle;
	else
		self.monsterinfo.currentmove = &gekk_move_swim_start;
	// gi.sound (self, CHAN_VOICE, sound_idle, 1, ATTN_IDLE, 0);
}


//
// WALK
//

static mframe_t gekk_frames_walk[] = 
{
 { ai_walk,   3.849, gekk_check_underwater }, // frame 0
 { ai_walk,  19.606 }, // frame 1
 { ai_walk,  25.583 }, // frame 2
 { ai_walk,  34.625, gekk_step }, // frame 3
 { ai_walk,  27.365 }, // frame 4
 { ai_walk,  28.480 }, // frame 5
};
static var mmove_t gekk_move_walk = { FRAME_run_01, FRAME_run_06 };

static void(entity self) gekk_walk =
{
	self.monsterinfo.currentmove = &gekk_move_walk;
}


//
// RUN
//

static void(entity self) gekk_run =
{
	
	if (self.waterlevel)
	{
		self.monsterinfo.currentmove = &gekk_move_swim_start;
		return;
	}
	else
	{
		if (self.monsterinfo.aiflags & AI_STAND_GROUND)
			self.monsterinfo.currentmove = &gekk_move_stand;
		else
			self.monsterinfo.currentmove = &gekk_move_run;
	}

}

static mframe_t gekk_frames_run_st[] = 
{
 { ai_run,   0.212 }, // frame 0
 { ai_run,  19.753 }, // frame 1
};
static var mmove_t gekk_move_run_start = { FRAME_stand_01, FRAME_stand_02, gekk_run };

static void(entity self) gekk_run_start =
{
	if (self.waterlevel)
	{
		self.monsterinfo.currentmove = &gekk_move_swim_start;
	}	
	else
	{
		self.monsterinfo.currentmove = &gekk_move_run_start;
	}
}

//
// MELEE
//

static void(entity self, entity other, cplane_t plane, csurface_t surf) loogie_touch =
{

	if (other == self.owner)
		return;

	if (surf && (surf.flags & SURF_SKY))
	{
		G_FreeEdict (self);
		return;
	}

	if (self.owner.is_client)
		PlayerNoise(self.owner, self.s.origin, PNOISE_IMPACT);

	if (other.takedamage)
		T_Damage (other, self, self.owner, self.velocity, self.s.origin, plane.normal, self.dmg, 1, DAMAGE_ENERGY, MOD_GEKK);
	
	G_FreeEdict (self);
};
	

static void(entity self, vector start, vector dir, int damage, int speed) fire_loogie =
{
	entity loogie;
	trace_t	tr;

	VectorNormalize (dir);

	loogie = G_Spawn();
	loogie.s.origin = start;
	loogie.s.old_origin = start;
	loogie.s.angles = vectoangles (dir);
	loogie.velocity = dir * speed;
	loogie.movetype = MOVETYPE_FLYMISSILE;
	loogie.clipmask = MASK_SHOT;
	loogie.solid = SOLID_BBOX;
	loogie.s.effects |= RF_FULLBRIGHT;
	
	loogie.s.modelindex = gi.modelindex ("models/objects/loogy/tris.md2");
	loogie.owner = self;
	loogie.touch = loogie_touch;
	loogie.nextthink = level.framenum + (2 * BASE_FRAMETIME);
	loogie.think = G_FreeEdict;
	loogie.dmg = damage;
	gi.linkentity (loogie);

	gi.trace (&tr, self.s.origin, vec3_origin, vec3_origin, loogie.s.origin, loogie, MASK_SHOT);
	if (tr.fraction < 1.0)
	{
		loogie.s.origin += dir * -10;
		loogie.touch (loogie, tr.ent, null_plane, null_surface);
	}

}	

static void(entity self) loogie =
{
	vector	start;
	vector	forward, right, up;
	vector	end;
	vector	dir;
	vector	gekkoffset = '-18 -0.8 24';

	if (!self.enemy || self.enemy.health <= 0)
		return;
	
	AngleVectors (self.s.angles, &forward, &right, &up);
	start = G_ProjectSource (self.s.origin, gekkoffset, forward, right);

	start += up * 2;
	
	end = self.enemy.s.origin;
	end[2] += self.enemy.viewheight;
	dir = end - start;

	fire_loogie (self, start, dir, 5, 550);
}

static void(entity self) do_spit;

static void(entity self) reloogie =
{
	if (random() > 0.8 && self.health < self.max_health)
	{
		self.monsterinfo.currentmove = &gekk_move_idle2;
		return;
	}
		
	if (self.enemy.health >= 0)
		if (random() > 0.7 && (range(self, self.enemy) == RANGE_NEAR))
			do_spit(self);
}


static mframe_t gekk_frames_spit [] =
{
 { ai_charge }, 
 { ai_charge }, 
 { ai_charge }, 
 { ai_charge }, 
 { ai_charge }, 
 
 { ai_charge,   0.000, loogie },
 { ai_charge,   0.000, reloogie }
};
static var mmove_t gekk_move_spit = { FRAME_spit_01, FRAME_spit_07, gekk_run_start };

static void(entity self) do_spit =
{
	self.monsterinfo.currentmove = &gekk_move_spit;
};

static var mmove_t gekk_move_attack1 = { FRAME_clawatk3_01, FRAME_clawatk3_09, gekk_run_start };
static var mmove_t gekk_move_attack2 = { FRAME_clawatk5_01, FRAME_clawatk5_09, gekk_run_start };

static void(entity self) gekk_check_refire =
{
	if (!self.enemy || !self.enemy.inuse || self.enemy.health <= 0)
		return;
	
	if (random() < (skill.intVal * 0.1))
	{
		if (range (self, self.enemy) == RANGE_MELEE)
		{
			if (self.s.frame == FRAME_clawatk3_09)
				self.monsterinfo.currentmove = &gekk_move_attack2;
			else if (self.s.frame == FRAME_clawatk5_09)
				self.monsterinfo.currentmove = &gekk_move_attack1;
		}
	}
}

static mframe_t gekk_frames_attack1 [] =
{
	{ ai_charge }, 
	{ ai_charge }, 
	{ ai_charge }, 
	
	{ ai_charge,   0, gekk_hit_left }, 
	{ ai_charge }, 
	{ ai_charge }, 
	
	{ ai_charge }, 
	{ ai_charge }, 
	{ ai_charge,   0, gekk_check_refire }
		
};

static mframe_t gekk_frames_attack2[] = 
{
 { ai_charge },
 { ai_charge },
 { ai_charge,   0.000, gekk_hit_left }, 
 
 { ai_charge },
 { ai_charge },
 { ai_charge,   0.000, gekk_hit_right }, 
 
 { ai_charge },
 { ai_charge },
 { ai_charge,   0.000, gekk_check_refire  }
 
};

static mframe_t gekk_frames_leapatk[] = 
{
 { ai_charge }, // frame 0
 { ai_charge,  -0.387 }, // frame 1
 { ai_charge,  -1.113 }, // frame 2
 { ai_charge,  -0.237 }, // frame 3
 { ai_charge,   6.720, gekk_jump_takeoff }, // frame 4  last frame on ground
 { ai_charge,   6.414 }, // frame 5  leaves ground
 { ai_charge,   0.163 }, // frame 6
 { ai_charge,  28.316 }, // frame 7
 { ai_charge,  24.198 }, // frame 8
 { ai_charge,  31.742 }, // frame 9
 { ai_charge,  35.977, gekk_check_landing }, // frame 10  last frame in air
 { ai_charge,  12.303, gekk_stop_skid }, // frame 11  feet back on ground
 { ai_charge,  20.122, gekk_stop_skid }, // frame 12
 { ai_charge,  -1.042, gekk_stop_skid }, // frame 13
 { ai_charge,   2.556, gekk_stop_skid }, // frame 14
 { ai_charge,   0.544, gekk_stop_skid }, // frame 15
 { ai_charge,   1.862, gekk_stop_skid }, // frame 16
 { ai_charge,   1.224, gekk_stop_skid }, // frame 17

 { ai_charge,  -0.457, gekk_check_underwater }, // frame 18
};
static var mmove_t gekk_move_leapatk = { FRAME_leapatk_01, FRAME_leapatk_19, gekk_run_start };

static mframe_t gekk_frames_attack [] =
{
	{ ai_charge, 16 },
	{ ai_charge, 16 },
	{ ai_charge, 16 },
	{ ai_charge, 16 },
	{ ai_charge, 16,	gekk_bite },
	{ ai_charge, 16 },
	{ ai_charge, 16 },
	{ ai_charge, 16 },
	{ ai_charge, 16 },
	{ ai_charge, 16,	gekk_bite },
	
	{ ai_charge, 16 },
	{ ai_charge, 16 },
	{ ai_charge, 16 },
	{ ai_charge, 16,	gekk_hit_left },
	{ ai_charge, 16 },
	{ ai_charge, 16 },
	{ ai_charge, 16 },
	{ ai_charge, 16 },
	{ ai_charge, 16,	gekk_hit_right },
	{ ai_charge, 16 },

	{ ai_charge, 16 }
};
static var mmove_t gekk_move_attack = { FRAME_attack_01, FRAME_attack_21, gekk_run_start };

static void(entity self) gekk_melee =
{
	
	float r;
	
	if (self.waterlevel)
	{
		self.monsterinfo.currentmove = &gekk_move_attack;	
	}
	else
	{
		r = random();

		if (r > 0.66)
			self.monsterinfo.currentmove = &gekk_move_attack1;
		else 
			self.monsterinfo.currentmove = &gekk_move_attack2;
		
	}

}

static void(entity self) gekk_jump =
{
	if (self.flags & FL_SWIM || self.waterlevel)
	{
		return;
	}
	else
	{
		//if (random() > 0.8 && self.health < self.max_health)
		//	self.monsterinfo.currentmove = &gekk_move_idle2;
		//else
		{
			if (random() > 0.5 && (range (self, self.enemy) >= RANGE_NEAR))
				self.monsterinfo.currentmove = &gekk_move_spit;
			else if (random() > 0.8)
				self.monsterinfo.currentmove = &gekk_move_spit;
			else
				self.monsterinfo.currentmove = &gekk_move_leapatk;
			
		}
	}
}

//
// PAIN
//

static mframe_t gekk_frames_pain[] = 
{
	{ ai_move }, // frame 0
	{ ai_move }, // frame 1
	{ ai_move }, // frame 2
	{ ai_move }, // frame 3
	{ ai_move }, // frame 4
	{ ai_move }, // frame 5
};
static var mmove_t gekk_move_pain = { FRAME_pain_01, FRAME_pain_06, gekk_run_start };

mframe_t gekk_frames_pain1[] = 
{
 { ai_move }, // frame 0
 { ai_move }, // frame 1
 { ai_move }, // frame 2
 { ai_move }, // frame 3
 { ai_move }, // frame 4
 { ai_move }, // frame 5
 { ai_move }, // frame 6
 { ai_move }, // frame 7
 { ai_move }, // frame 8
 { ai_move }, // frame 9
 
 { ai_move,   0.000, gekk_check_underwater }
};
static var mmove_t gekk_move_pain1 = { FRAME_pain3_01, FRAME_pain3_11, gekk_run_start };

static mframe_t gekk_frames_pain2[] = 
{
 { ai_move }, // frame 0
 { ai_move }, // frame 1
 { ai_move }, // frame 2
 { ai_move }, // frame 3
 { ai_move }, // frame 4
 { ai_move }, // frame 5
 { ai_move }, // frame 6
 { ai_move }, // frame 7
 { ai_move }, // frame 8
 { ai_move }, // frame 9
 
 { ai_move }, // frame 10
 { ai_move }, // frame 11
 { ai_move,   0.000, gekk_check_underwater }, 
};
static var mmove_t gekk_move_pain2 = { FRAME_pain4_01, FRAME_pain4_13, gekk_run_start };

static void(entity self, entity other, float kick, int damage) gekk_pain =
{
	float	r;

	if (self.spawnflags & 8)
	{
		self.spawnflags &= ~8;
		return;
	}
	
	if (self.health < (self.max_health /4))
		self.s.skinnum = 2;
	else if (self.health < (self.max_health / 2))
		self.s.skinnum = 1;

	if (level.framenum < self.pain_debounce_framenum)
		return;

	self.pain_debounce_framenum = level.framenum + 3 * BASE_FRAMERATE;

	gi.sound (self, CHAN_VOICE, sound_pain1, 1, ATTN_NORM, 0);
		
	if (self.waterlevel)
	{
		if (!(self.flags & FL_SWIM))
			self.flags |= FL_SWIM;
		
		self.monsterinfo.currentmove = &gekk_move_pain;
	}
	else
	{
		r = random();

		if (r > 0.5)
			self.monsterinfo.currentmove = &gekk_move_pain1;
		else
			self.monsterinfo.currentmove = &gekk_move_pain2;
	}
}


//
// DEATH
//

static void(entity self) gekk_dead =
{
	// fix this because of no blocking problem
	if (self.waterlevel)
		return;
		
	self.mins = '-16 -16 -24';
	self.maxs = '16 16 -8';
	self.movetype = MOVETYPE_TOSS;
	self.svflags |= SVF_DEADMONSTER;
	self.nextthink = 0;
	gi.linkentity (self);
}

// from xatrix/misc.qc
void(entity self, string gibname, int damage, int type) ThrowGibACID;
void(entity self, string gibname, int damage, int type) ThrowHeadACID;

static void(entity self) gekk_gibfest =
{
	int damage = 20;
	
	gi.sound (self, CHAN_VOICE, gi.soundindex ("misc/udeath.wav"), 1, ATTN_NORM, 0);
	
	ThrowGibACID (self, "models/objects/gekkgib/pelvis/tris.md2", damage, GIB_ORGANIC);
	ThrowGibACID (self, "models/objects/gekkgib/arm/tris.md2", damage, GIB_ORGANIC);
	ThrowGibACID (self, "models/objects/gekkgib/arm/tris.md2", damage, GIB_ORGANIC);
	ThrowGibACID (self, "models/objects/gekkgib/torso/tris.md2", damage, GIB_ORGANIC);
	ThrowGibACID (self, "models/objects/gekkgib/claw/tris.md2", damage, GIB_ORGANIC);
	ThrowGibACID (self, "models/objects/gekkgib/leg/tris.md2", damage, GIB_ORGANIC);
	ThrowGibACID (self, "models/objects/gekkgib/leg/tris.md2", damage, GIB_ORGANIC);
	
	ThrowHeadACID (self, "models/objects/gekkgib/head/tris.md2", damage, GIB_ORGANIC);
	

	self.deadflag = DEAD_DEAD;
}

static void(entity self) isgibfest =
{
	if (random() > 0.9)
		gekk_gibfest (self);
}

static mframe_t gekk_frames_death1[] =
{
	{ ai_move,  -5.151 }, // frame 0
	{ ai_move, -12.223 }, // frame 1
	{ ai_move, -11.484 }, // frame 2
	{ ai_move, -17.952 }, // frame 3
	{ ai_move,  -6.953 }, // frame 4
	{ ai_move,  -7.393 }, // frame 5
	{ ai_move, -10.713 }, // frame 6
	{ ai_move, -17.464 }, // frame 7
	{ ai_move, -11.678 }, // frame 8
	{ ai_move, -11.678 }  // frame 9
};
static var mmove_t gekk_move_death1 = { FRAME_death1_01, FRAME_death1_10, gekk_dead };

static mframe_t gekk_frames_death3[] =
{
	{ ai_move }, // frame 0
	{ ai_move,   0.022 }, // frame 1
	{ ai_move,   0.169 }, // frame 2
	{ ai_move,  -0.710 }, // frame 3
	{ ai_move, -13.446 }, // frame 4
	{ ai_move,  -7.654, isgibfest }, // frame 5
	{ ai_move, -31.951 }, // frame 6
};
static var mmove_t gekk_move_death3 = { FRAME_death3_01, FRAME_death3_07, gekk_dead };

static mframe_t gekk_frames_death4[] = 
{
 { ai_move,   5.103 }, // frame 0
 { ai_move,  -4.808 }, // frame 1
 { ai_move, -10.509 }, // frame 2
 { ai_move,  -9.899 }, // frame 3
 { ai_move,   4.033, isgibfest }, // frame 4
 { ai_move,  -5.197 }, // frame 5
 { ai_move,  -0.919 }, // frame 6
 { ai_move,  -8.821 }, // frame 7
 { ai_move,  -5.626 }, // frame 8
 { ai_move,  -8.865, isgibfest }, // frame 9
 { ai_move,  -0.845 }, // frame 10
 { ai_move,   1.986 }, // frame 11
 { ai_move,   0.170 }, // frame 12
 { ai_move,   1.339, isgibfest }, // frame 13
 { ai_move,  -0.922 }, // frame 14
 { ai_move,   0.818 }, // frame 15
 { ai_move,  -1.288 }, // frame 16
 { ai_move,  -1.408, isgibfest }, // frame 17
 { ai_move,  -7.787 }, // frame 18
 { ai_move,  -3.995 }, // frame 19
 { ai_move,  -4.604 }, // frame 20
 { ai_move,  -1.715, isgibfest }, // frame 21
 { ai_move,  -0.564 }, // frame 22
 { ai_move,  -0.597 }, // frame 23
 { ai_move,   0.074 }, // frame 24
 { ai_move,  -0.309, isgibfest }, // frame 25
 { ai_move,  -0.395 }, // frame 26
 { ai_move,  -0.501 }, // frame 27
 { ai_move,  -0.325 }, // frame 28
 { ai_move,  -0.931, isgibfest }, // frame 29
 { ai_move,  -1.433 }, // frame 30
 { ai_move,  -1.626 }, // frame 31
 { ai_move,   4.680 }, // frame 32
 { ai_move,   0.560 }, // frame 33
 { ai_move,  -0.549, gekk_gibfest } // frame 34
};
static var mmove_t gekk_move_death4 = { FRAME_death4_01, FRAME_death4_35, gekk_dead };

static mframe_t gekk_frames_wdeath[] = 
{
	 { ai_move }, // frame 0
	 { ai_move }, // frame 1
	 { ai_move }, // frame 2
	 { ai_move }, // frame 3
	 { ai_move }, // frame 4
	 { ai_move }, // frame 5
	 { ai_move }, // frame 6
	 { ai_move }, // frame 7
	 { ai_move }, // frame 8
	 { ai_move }, // frame 9
	 { ai_move }, // frame 10
	 { ai_move }, // frame 11
	 { ai_move }, // frame 12
	 { ai_move }, // frame 13
	 { ai_move }, // frame 14
	 { ai_move }, // frame 15
	 { ai_move }, // frame 16
	 { ai_move }, // frame 17
	 { ai_move }, // frame 18
	 { ai_move }, // frame 19
	 { ai_move }, // frame 20
	 { ai_move }, // frame 21
	 { ai_move }, // frame 22
	 { ai_move }, // frame 23
	 { ai_move }, // frame 24
	 { ai_move }, // frame 25
	 { ai_move }, // frame 26
	 { ai_move }, // frame 27
	 { ai_move }, // frame 28
	 { ai_move }, // frame 29
	 { ai_move }, // frame 30
	 { ai_move }, // frame 31
	 { ai_move }, // frame 32
	 { ai_move }, // frame 33
	 { ai_move }, // frame 34
	 { ai_move }, // frame 35
	 { ai_move }, // frame 36
	 { ai_move }, // frame 37
	 { ai_move }, // frame 38
	 { ai_move }, // frame 39
	 { ai_move }, // frame 40
	 { ai_move }, // frame 41
	 { ai_move }, // frame 42
	 { ai_move }, // frame 43
	 { ai_move }  // frame 44
};
static var mmove_t gekk_move_wdeath = { FRAME_wdeath_01, FRAME_wdeath_45, gekk_dead };

static void(entity self, entity inflictor, entity attacker, int damage, vector point) gekk_die =
{
	float	r;

	if (self.health <= self.gib_health)
	{
		gi.sound (self, CHAN_VOICE, gi.soundindex ("misc/udeath.wav"), 1, ATTN_NORM, 0);

		ThrowGibACID (self, "models/objects/gekkgib/pelvis/tris.md2", damage, GIB_ORGANIC);
		ThrowGibACID (self, "models/objects/gekkgib/arm/tris.md2", damage, GIB_ORGANIC);
		ThrowGibACID (self, "models/objects/gekkgib/arm/tris.md2", damage, GIB_ORGANIC);
		ThrowGibACID (self, "models/objects/gekkgib/torso/tris.md2", damage, GIB_ORGANIC);
		ThrowGibACID (self, "models/objects/gekkgib/claw/tris.md2", damage, GIB_ORGANIC);
		ThrowGibACID (self, "models/objects/gekkgib/leg/tris.md2", damage, GIB_ORGANIC);
		ThrowGibACID (self, "models/objects/gekkgib/leg/tris.md2", damage, GIB_ORGANIC);
	
		ThrowHeadACID (self, "models/objects/gekkgib/head/tris.md2", damage, GIB_ORGANIC);

		self.deadflag = DEAD_DEAD;
		return;
	}

	if (self.deadflag == DEAD_DEAD)
		return;

	gi.sound (self, CHAN_VOICE, sound_death, 1, ATTN_NORM, 0);
	self.deadflag = DEAD_DEAD;
	self.takedamage = DAMAGE_YES;
	self.s.skinnum = 2;

	if (self.waterlevel)
		self.monsterinfo.currentmove = &gekk_move_wdeath;
	else
	{
		r = random();
		if (r > 0.66)
			self.monsterinfo.currentmove = &gekk_move_death1;
		else if (r > 0.33)
			self.monsterinfo.currentmove = &gekk_move_death3;
		else
			self.monsterinfo.currentmove = &gekk_move_death4;
	}
}


/*
	duck
*/
static void(entity self) gekk_duck_down =
{
	if (self.monsterinfo.aiflags & AI_DUCKED)
		return;
	self.monsterinfo.aiflags |= AI_DUCKED;
	self.maxs[2] -= 32;
	self.takedamage = DAMAGE_YES;
	self.monsterinfo.pause_framenum = level.framenum + 1 * BASE_FRAMERATE;
	gi.linkentity (self);
}

static void(entity self) gekk_duck_up =
{
	self.monsterinfo.aiflags &= ~AI_DUCKED;
	self.maxs[2] += 32;
	self.takedamage = DAMAGE_AIM;
	gi.linkentity (self);
}

static void(entity self) gekk_duck_hold =
{
	if (level.framenum >= self.monsterinfo.pause_framenum)
		self.monsterinfo.aiflags &= ~AI_HOLD_FRAME;
	else
		self.monsterinfo.aiflags |= AI_HOLD_FRAME;
}

static mframe_t gekk_frames_lduck[] = 
{
 { ai_move }, // frame 0
 { ai_move }, // frame 1
 { ai_move }, // frame 2
 { ai_move }, // frame 3
 { ai_move }, // frame 4
 { ai_move }, // frame 5
 { ai_move }, // frame 6
 { ai_move }, // frame 7
 { ai_move }, // frame 8
 { ai_move }, // frame 9
 
 { ai_move }, // frame 10
 { ai_move }, // frame 11
 { ai_move }  // frame 12
};
static var mmove_t gekk_move_lduck = { FRAME_lduck_01, FRAME_lduck_13, gekk_run_start };

static mframe_t gekk_frames_rduck[] = 
{
 { ai_move }, // frame 0
 { ai_move }, // frame 1
 { ai_move }, // frame 2
 { ai_move }, // frame 3
 { ai_move }, // frame 4
 { ai_move }, // frame 5
 { ai_move }, // frame 6
 { ai_move }, // frame 7
 { ai_move }, // frame 8
 { ai_move }, // frame 9
 { ai_move }, // frame 10
 { ai_move }, // frame 11
 { ai_move } // frame 12
};
static var mmove_t gekk_move_rduck = { FRAME_rduck_01, FRAME_rduck_13, gekk_run_start };

static void(entity self, entity attacker, float eta) gekk_dodge =
{
	float	r;

	r = random();
	if (r > 0.25)
		return;

	if (!self.enemy)
		self.enemy = attacker;

	if (self.waterlevel)
	{
		self.monsterinfo.currentmove = &gekk_move_attack;
		return;
	}
	
	if (skill.intVal == 0)
	{
		r = random();
		if (r > 0.5)
			self.monsterinfo.currentmove = &gekk_move_lduck;
		else 
			self.monsterinfo.currentmove = &gekk_move_rduck;
		return;
	}

	self.monsterinfo.pause_framenum = level.framenum + (int)(eta + 0.3 * BASE_FRAMERATE);
	r = random();

	if (skill.intVal == 1)
	{
		if (r > 0.33)
		{
			r = random();
			if (r > 0.5)
				self.monsterinfo.currentmove = &gekk_move_lduck;
			else 
				self.monsterinfo.currentmove = &gekk_move_rduck;
		}
		else
		{
			r = random();
			if (r > 0.66)
				self.monsterinfo.currentmove = &gekk_move_attack1;
			else 
				self.monsterinfo.currentmove = &gekk_move_attack2;
			
		}
		return;
	}

	if (skill.intVal == 2)
	{
		if (r > 0.66)
		{
			r = random();
			if (r > 0.5)
				self.monsterinfo.currentmove = &gekk_move_lduck;
			else 
				self.monsterinfo.currentmove = &gekk_move_rduck;
		}
		else
		{
			r = random();
			if (r > 0.66)
				self.monsterinfo.currentmove = &gekk_move_attack1;
			else 
				self.monsterinfo.currentmove = &gekk_move_attack2;
		}
		return;
	}

	r = random();
	if (r > 0.66)
		self.monsterinfo.currentmove = &gekk_move_attack1;
	else 
		self.monsterinfo.currentmove = &gekk_move_attack2;
}

//
// SPAWN
//

/*QUAKED monster_gekk (1 .5 0) (-24 -24 -24) (24 24 24) Ambush Trigger_Spawn Sight Chant
*/
API_FUNC static void(entity self) SP_monster_gekk =
{
	if (deathmatch.intVal)
	{
		G_FreeEdict (self);
		return;
	}
	
	if (!gekk_move_run.frame)
	{
		gekk_move_run.frame = &gekk_frames_run;
		gekk_move_leapatk2.frame = &gekk_frames_leapatk2;
		gekk_move_leapatk2.endfunc = gekk_run_start;
		gekk_move_swim_loop.frame = &gekk_frames_swim;
		gekk_move_swim_loop.endfunc = gekk_swim_loop;
		gekk_move_swim_start.frame = &gekk_frames_swim_start;
		gekk_move_stand.frame = &gekk_frames_stand;
		gekk_move_standunderwater.frame = &gekk_frames_standunderwater;
		gekk_move_idle.frame = &gekk_frames_idle;
		gekk_move_idle2.frame = &gekk_frames_idle;
		gekk_move_chant.frame = &gekk_frames_idle2;
		gekk_move_walk.frame = &gekk_frames_walk;
		gekk_move_run_start.frame = &gekk_frames_run_st;
		gekk_move_spit.frame = &gekk_frames_spit;
		gekk_move_attack1.frame = &gekk_frames_attack1;
		gekk_move_attack2.frame = &gekk_frames_attack2;
		gekk_move_leapatk.frame = &gekk_frames_leapatk;
		gekk_move_attack.frame = &gekk_frames_attack;
		gekk_move_pain.frame = &gekk_frames_pain;
		gekk_move_pain1.frame = &gekk_frames_pain1;
		gekk_move_pain2.frame = &gekk_frames_pain2;
		gekk_move_death1.frame = &gekk_frames_death1;
		gekk_move_death3.frame = &gekk_frames_death3;
		gekk_move_death4.frame = &gekk_frames_death4;
		gekk_move_wdeath.frame = &gekk_frames_wdeath;
		gekk_move_lduck.frame = &gekk_frames_lduck;
		gekk_move_rduck.frame = &gekk_frames_rduck;
	}

	sound_swing = gi.soundindex ("gek/gk_atck1.wav");
	sound_hit = gi.soundindex ("gek/gk_atck2.wav");
	sound_hit2 = gi.soundindex ("gek/gk_atck3.wav");
	sound_death = gi.soundindex ("gek/gk_deth1.wav");
	sound_pain1 = gi.soundindex ("gek/gk_pain1.wav");
	sound_sight = gi.soundindex ("gek/gk_sght1.wav");
	sound_search = gi.soundindex ("gek/gk_idle1.wav");
	sound_step1 = gi.soundindex ("gek/gk_step1.wav");
	sound_step2 = gi.soundindex ("gek/gk_step2.wav");
	sound_step3 = gi.soundindex ("gek/gk_step3.wav");
	sound_thud = gi.soundindex ("mutant/thud1.wav");
	
	sound_chantlow = gi.soundindex ("gek/gek_low.wav");
	sound_chantmid = gi.soundindex ("gek/gek_mid.wav");
	sound_chanthigh = gi.soundindex ("gek/gek_high.wav");
	
	self.movetype = MOVETYPE_STEP;
	self.solid = SOLID_BBOX;
	self.s.modelindex = gi.modelindex ("models/monsters/gekk/tris.md2");
	self.mins = '-24 -24 -24';
	self.maxs = '24 24 24';

	gi.modelindex ("models/objects/gekkgib/pelvis/tris.md2");
	gi.modelindex ("models/objects/gekkgib/arm/tris.md2");
	gi.modelindex ("models/objects/gekkgib/torso/tris.md2");
	gi.modelindex ("models/objects/gekkgib/claw/tris.md2");
	gi.modelindex ("models/objects/gekkgib/leg/tris.md2");
	gi.modelindex ("models/objects/gekkgib/head/tris.md2");
		
	self.health = 125;
	self.gib_health = -30;
	self.mass = 300;

	self.pain = gekk_pain;
	self.die = gekk_die;

	self.monsterinfo.stand = gekk_stand;

	self.monsterinfo.walk = gekk_walk;
	self.monsterinfo.run = gekk_run_start;
	self.monsterinfo.dodge = gekk_dodge;
	self.monsterinfo.attack = gekk_jump;
	self.monsterinfo.melee = gekk_melee;
	self.monsterinfo.sight = gekk_sight;
	
	self.monsterinfo.search = gekk_search;
	self.monsterinfo.idle = gekk_idle;
	self.monsterinfo.checkattack = gekk_checkattack;

	gi.linkentity (self);
	
	self.monsterinfo.currentmove = &gekk_move_stand;

	self.monsterinfo.scale = MODEL_SCALE;
	walkmonster_start (self);

	if (self.spawnflags & 8)
		self.monsterinfo.currentmove = &gekk_move_chant;
	
}

#endif