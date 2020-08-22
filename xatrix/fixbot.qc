#ifdef THE_RECKONING

#include "m_fixbot.h"

const int MZ2_fixbot_BLASTER_1 = MZ2_HOVER_BLASTER_1;

static int	sound_pain1;
static int	sound_die;
static int	sound_weld1;
static int	sound_weld2;
static int	sound_weld3;

static entity(entity self) fixbot_FindDeadMonster =
{
	entity	ent = world;
	entity	best = world;

	while ((ent = findradius(ent, self.s.origin, 1024)))
	{
		if (ent == self)
			continue;
		if (!(ent.svflags & SVF_MONSTER))
			continue;
		if (ent.monsterinfo.aiflags & AI_GOOD_GUY)
			continue;
		if (ent.owner)
			continue;
		if (ent.health > 0)
			continue;
		if (ent.nextthink)
			continue;
		if (!visible(self, ent))
			continue;
		if (!best)
			best = ent;
		else if (ent.max_health > best.max_health)
			best = ent;
	}

	return best;
}

static int(entity self) fixbot_search =
{
	entity	ent;

	if (!self.goalentity)
	{
		ent = fixbot_FindDeadMonster(self);
		if (ent != null_entity)
		{
			self.oldenemy = self.enemy;
			self.enemy = ent;
			self.enemy.owner = self;
			self.monsterinfo.aiflags |= AI_MEDIC;
			FoundTarget (self);
			return 1;
		}
	}
	return 0;
}

static var mmove_t fixbot_move_weld = { FRAME_weldmiddle_01, FRAME_weldmiddle_07 };
static var mmove_t fixbot_move_weld_end = { FRAME_weldend_01, FRAME_weldend_07 };
static var mmove_t fixbot_move_stand = { FRAME_ambient_01, FRAME_ambient_19 };

static void(entity self) weldstate =
{
	if (self.s.frame == FRAME_weldstart_10)
		self.monsterinfo.currentmove = &fixbot_move_weld;
	else if (self.s.frame == FRAME_weldmiddle_07)
	{
		if (self.goalentity.health < 0) 
		{
			self.enemy.owner = 0;
			self.monsterinfo.currentmove = &fixbot_move_weld_end;
		}
		else
			self.goalentity.health -= 10;
	}
	else
	{
		self.goalentity = self.enemy = 0;
		self.monsterinfo.currentmove = &fixbot_move_stand;
	}
}

static void(entity self, float dist) ai_move2 =
{
	vector	v;
	
	if (dist)
		M_walkmove (self, self.s.angles[YAW], dist);

	v = self.goalentity.s.origin - self.s.origin;
	self.ideal_yaw = vectoyaw(v);	
	M_ChangeYaw (self);
};

static mframe_t fixbot_frames_weld_start [] = 
{
	{ ai_move2 },
	{ ai_move2 },
	{ ai_move2 },
	{ ai_move2 },
	{ ai_move2 },
	{ ai_move2 },
	{ ai_move2 },
	{ ai_move2 },
	{ ai_move2 },
	{ ai_move2, 0, weldstate }
};
static var mmove_t fixbot_move_weld_start = { FRAME_weldstart_01, FRAME_weldstart_10 };

static void(entity self) use_scanner =
{
	entity	ent = world;
	float   radius = 1024;
	vector	vec;
	float	len;
	float	oldlen = 0x10000;

	while ((ent = findradius(ent, self.s.origin, radius)))
	{
		if (ent.health >= 100)
		{
			if (ent.classname == "object_repair")
			{
				if (visible(self, ent))
				{	
					// remove the old one
					if (self.goalentity.classname == "bot_goal")
					{
						self.goalentity.nextthink = level.framenum + 1;
						self.goalentity.think = G_FreeEdict;
					}	
					
					self.goalentity = self.enemy = ent;
					
					vec = self.s.origin - self.goalentity.s.origin;
					len = VectorNormalize (vec);

					if (len < 32)
					{
						self.monsterinfo.currentmove = &fixbot_move_weld_start;
						return;
					}
					return;
				}
			}
		}
	}

	vec = self.s.origin - self.goalentity.s.origin;
	len = VectorLength (vec);

	if (len < 32)
	{
		if (self.goalentity.classname == "object_repair")
			self.monsterinfo.currentmove = &fixbot_move_weld_start;
		else 
		{
			self.goalentity.nextthink = level.framenum + 1;
			self.goalentity.think = G_FreeEdict;
			self.goalentity = self.enemy = 0;
			self.monsterinfo.currentmove = &fixbot_move_stand;
		}
		return;
	}

	vec = self.s.origin - self.s.old_origin;
	len = VectorLength (vec);

	/* 
	  bot is stuck get new goalentity
	*/
	if (len == 0)
	{
		if (self.goalentity.classname == "object_repair")
		{
			self.monsterinfo.currentmove = &fixbot_move_stand;
		}
		else 
		{
			self.goalentity.nextthink = level.framenum + 1;
			self.goalentity.think = G_FreeEdict;
			self.goalentity = self.enemy = 0;
			self.monsterinfo.currentmove = &fixbot_move_stand;
		}
	}
}

static void(entity self, float dist) ai_movetogoal =
{
	M_MoveToGoal (self, dist);
}

static mframe_t fixbot_frames_forward [] =
{
	{ ai_movetogoal,	5,	use_scanner }
};
static var mmove_t fixbot_move_forward = { FRAME_freeze_01, FRAME_freeze_01 };

static void(entity self, float dist) ai_facing =
{
	vector	v;

	if (infront (self, self.goalentity))
		self.monsterinfo.currentmove = &fixbot_move_forward;
	else
	{
		v = self.goalentity.s.origin - self.s.origin;
		self.ideal_yaw = vectoyaw(v);	
		M_ChangeYaw (self);
	}
}

static mframe_t fixbot_frames_turn [] =
{
	{ ai_facing }
};
static var mmove_t fixbot_move_turn = { FRAME_freeze_01, FRAME_freeze_01 };

static void(entity self) roam_goal =
{
	trace_t		tr;
	vector	forward, right, up;
	vector	end;
	entity	ent;
	vector	dang;
	float	len, oldlen;
	int	whichi, i;
	vector	vec;
	vector	whichvec = vec3_origin;
		
	ent = G_Spawn ();	
	ent.classname = "bot_goal";
	ent.solid = SOLID_BBOX;
	ent.owner = self;
	gi.linkentity (ent);

	oldlen = 0;
	whichi = 0;
	for (i=0; i<12; i++) 
	{
		
		dang = self.s.angles;

		if (i < 6)
			dang[YAW] += 30 * i;
		else 
			dang[YAW] -= 30 * (i-6);

		AngleVectors (dang, &forward, &right, &up);
		end = self.s.origin + (forward * 8192);
		gi.traceline (&tr, self.s.origin, end, self, MASK_SHOT);

		vec = self.s.origin - tr.endpos;
		len = VectorNormalize (vec);
		
		if (len > oldlen)
		{
			oldlen = len;
			whichvec = tr.endpos;
		}
		
	}
	
	ent.s.origin = whichvec;
	self.goalentity = self.enemy = ent;
	
	self.monsterinfo.currentmove = &fixbot_move_turn;
}

/*
	generic frame to move bot
*/
static mframe_t fixbot_frames_roamgoal [] =
{
	{ ai_move, 0, roam_goal }
};
static var mmove_t fixbot_move_roamgoal = { FRAME_freeze_01, FRAME_freeze_01 };

static mframe_t fixbot_frames_stand2 [] =
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
	{ ai_stand },
	{ ai_stand },
	{ ai_stand },
	{ ai_stand },
	{ ai_stand },
	{ ai_stand },
	{ ai_stand }
	
};
static var mmove_t fixbot_move_stand2 = { FRAME_ambient_01, FRAME_ambient_19 };

static void(entity self) landing_goal;
static void(entity self) takeoff_goal;

static void(entity self) change_to_roam =
{
	if (fixbot_search(self))
		return;

	self.monsterinfo.currentmove = &fixbot_move_roamgoal;
	
	if (self.spawnflags & 16)
	{
		landing_goal (self);
		self.spawnflags &= ~16;
		self.spawnflags = 32;
	}
	if (self.spawnflags & 8) 
	{
		takeoff_goal (self);
		self.spawnflags &= ~8;
		self.spawnflags = 32;
	}
	if (self.spawnflags & 4)
	{
		self.monsterinfo.currentmove = &fixbot_move_roamgoal;
		self.spawnflags &= ~4;
		self.spawnflags = 32;
	}
	if (!self.spawnflags)
	{
		self.monsterinfo.currentmove = &fixbot_move_stand2;
	}
}

/*
	generic ambient stand
*/
static mframe_t fixbot_frames_stand [] =
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
	{ ai_move },

	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move, 0, change_to_roam }
};

static void(entity self) fly_vertical2 =
{
	vector v;
	float len;
	
	v = self.goalentity.s.origin - self.s.origin;
	len = VectorLength (v);
	self.ideal_yaw = vectoyaw(v);	
	M_ChangeYaw (self);
	
	if (len < 32)
	{
		self.goalentity.nextthink = level.framenum + 1;
		self.goalentity.think = G_FreeEdict;
		self.monsterinfo.currentmove = &fixbot_move_stand;
		self.goalentity = self.enemy = 0;
	}
		
	// needs sound
}

static mframe_t fixbot_frames_landing [] =
{
	{ ai_move },
	{ ai_move, 0, fly_vertical2 },
	{ ai_move, 0, fly_vertical2 },
	{ ai_move, 0, fly_vertical2 },
	{ ai_move, 0, fly_vertical2 },
	{ ai_move, 0, fly_vertical2 },
	{ ai_move, 0, fly_vertical2 },
	{ ai_move, 0, fly_vertical2 },
	{ ai_move, 0, fly_vertical2 },
	{ ai_move, 0, fly_vertical2 },

	{ ai_move, 0, fly_vertical2 },
	{ ai_move, 0, fly_vertical2 },
	{ ai_move, 0, fly_vertical2 },
	{ ai_move, 0, fly_vertical2 },
	{ ai_move, 0, fly_vertical2 },
	{ ai_move, 0, fly_vertical2 },
	{ ai_move, 0, fly_vertical2 },
	{ ai_move, 0, fly_vertical2 },
	{ ai_move, 0, fly_vertical2 },
	{ ai_move, 0, fly_vertical2 },

	{ ai_move, 0, fly_vertical2 },
	{ ai_move, 0, fly_vertical2 },
	{ ai_move, 0, fly_vertical2 },
	{ ai_move, 0, fly_vertical2 },
	{ ai_move, 0, fly_vertical2 },
	{ ai_move, 0, fly_vertical2 },
	{ ai_move, 0, fly_vertical2 },
	{ ai_move, 0, fly_vertical2 },
	{ ai_move, 0, fly_vertical2 },
	{ ai_move, 0, fly_vertical2 },

	{ ai_move, 0, fly_vertical2 },
	{ ai_move, 0, fly_vertical2 },
	{ ai_move, 0, fly_vertical2 },
	{ ai_move, 0, fly_vertical2 },
	{ ai_move, 0, fly_vertical2 },
	{ ai_move, 0, fly_vertical2 },
	{ ai_move, 0, fly_vertical2 },
	{ ai_move, 0, fly_vertical2 },
	{ ai_move, 0, fly_vertical2 },
	{ ai_move, 0, fly_vertical2 },

	{ ai_move, 0, fly_vertical2 },
	{ ai_move, 0, fly_vertical2 },
	{ ai_move, 0, fly_vertical2 },
	{ ai_move, 0, fly_vertical2 },
	{ ai_move, 0, fly_vertical2 },
	{ ai_move, 0, fly_vertical2 },
	{ ai_move, 0, fly_vertical2 },
	{ ai_move, 0, fly_vertical2 },
	{ ai_move, 0, fly_vertical2 },
	{ ai_move, 0, fly_vertical2 },

	{ ai_move, 0, fly_vertical2 },
	{ ai_move, 0, fly_vertical2 },
	{ ai_move, 0, fly_vertical2 },
	{ ai_move, 0, fly_vertical2 },
	{ ai_move, 0, fly_vertical2 },
	{ ai_move, 0, fly_vertical2 },
	{ ai_move, 0, fly_vertical2 },
	{ ai_move, 0, fly_vertical2 }
};
static var mmove_t fixbot_move_landing = { FRAME_landing_01, FRAME_landing_58 };

static void(entity self) landing_goal =
{
	trace_t	tr;
	vector	forward, right, up;
	vector	end;
	entity	ent;
	
	ent = G_Spawn ();	
	ent.classname = "bot_goal";
	ent.solid = SOLID_BBOX;
	ent.owner = self;
	gi.linkentity (ent);
	
	ent.mins = '-32 -32 -24';
	ent.maxs = '32 32 24';
	
	AngleVectors (self.s.angles, &forward, &right, &up);
	end = self.s.origin + (forward * 32); // Paril: this wasn't right in vanilla
	end += up * -8192;
		
	gi.trace (&tr, self.s.origin, ent.mins, ent.maxs, end, self, MASK_MONSTERSOLID);

	ent.s.origin = tr.endpos;
	
	self.goalentity = self.enemy = ent;
	self.monsterinfo.currentmove = &fixbot_move_landing;
}



/*
	when the bot has found a landing pad
	it will proceed to its goalentity
	just above the landing pad and
	decend translated along the z the current
	frames are at 10fps
*/ 
static void(entity self, vector start, vector aimdir, int damage, int kick, int te_impact, int hspread, int vspread) blastoff =
{
	trace_t	tr;
	vector	dir = vec3_origin;
	vector	forward, right, up;
	vector	end;
	float	r;
	float	u;
	vector	water_start = vec3_origin;
	bool	water = false;
	int	content_mask = MASK_SHOT | MASK_WATER;

	hspread += (self.s.frame - FRAME_takeoff_01);
	vspread += (self.s.frame - FRAME_takeoff_01);

	gi.traceline (&tr, self.s.origin, start, self, MASK_SHOT);

	if (!(tr.fraction < 1.0))
	{
		dir = vectoangles (aimdir);
		AngleVectors (dir, &forward, &right, &up);

		r = crandom()*hspread;
		u = crandom()*vspread;
		end = start + (forward * 8192);
		end += right * r;
		end += up * u;

		if (gi.pointcontents (start) & MASK_WATER)
		{
			water = true;
			water_start = start;
			content_mask &= ~MASK_WATER;
		}

		gi.traceline(&tr, start, end, self, content_mask);

		// see if we hit water
		if (tr.contents & MASK_WATER)
		{
			int		color;

			water = true;
			water_start = tr.endpos;

			if (start != tr.endpos)
			{
				if (tr.contents & CONTENTS_WATER)
				{
					if (tr.surface.name == "*brwater")
						color = SPLASH_BROWN_WATER;
					else
						color = SPLASH_BLUE_WATER;
				}
				else if (tr.contents & CONTENTS_SLIME)
					color = SPLASH_SLIME;
				else if (tr.contents & CONTENTS_LAVA)
					color = SPLASH_LAVA;
				else
					color = SPLASH_UNKNOWN;

				if (color != SPLASH_UNKNOWN)
				{
					gi.WriteByte (svc_temp_entity);
					gi.WriteByte (TE_SPLASH);
					gi.WriteByte (8);
					gi.WritePosition (tr.endpos);
					gi.WriteDir (tr.normal);
					gi.WriteByte (color);
					gi.multicast (tr.endpos, MULTICAST_PVS);
				}

				// change bullet's course when it enters water
				dir = end - start;
				dir = vectoangles (dir);
				AngleVectors (dir, &forward, &right, &up);
				r = crandom()*hspread*2;
				u = crandom()*vspread*2;
				end = water_start + (forward * 8192);
				end += right * u;
				end += up * u;
			}

			// re-trace ignoring water this time
			gi.traceline(&tr, water_start, end, self, MASK_SHOT);
		}
	}

	// send gun puff / flash
	if (!((tr.surface) && (tr.surface.flags & SURF_SKY)))
	{
		if (tr.fraction < 1.0)
		{
			if (tr.ent.takedamage)
			{
				T_Damage (tr.ent, self, self, aimdir, tr.endpos, tr.normal, damage, kick, DAMAGE_BULLET, MOD_BLASTOFF);
			}
			else
			{
				if (strncmp (tr.surface.name, "sky", 3) != 0)
				{
					gi.WriteByte (svc_temp_entity);
					gi.WriteByte (te_impact);
					gi.WritePosition (tr.endpos);
					gi.WriteDir (tr.normal);
					gi.multicast (tr.endpos, MULTICAST_PVS);

					if (self.is_client)
						PlayerNoise(self, tr.endpos, PNOISE_IMPACT);
				}
			}
		}
	}

	// if went through water, determine where the end and make a bubble trail
	if (water)
	{
		vector	pos;

		pos = tr.endpos - water_start;
		VectorNormalize (dir);
		pos = tr.endpos + (dir * -2);
		if (gi.pointcontents (pos) & MASK_WATER)
			tr.endpos = pos;
		else
			gi.traceline (&tr, pos, water_start, tr.ent, MASK_WATER);

		pos = water_start + tr.endpos;
		pos *= 0.5f;

		gi.WriteByte (svc_temp_entity);
		gi.WriteByte (TE_BUBBLETRAIL);
		gi.WritePosition (water_start);
		gi.WritePosition (tr.endpos);
		gi.multicast (pos, MULTICAST_PVS);
	}
}

static void(entity self) fly_vertical =
{
	vector	v;
	vector	forward, right, up;
	vector	start;
	vector	tempvec;
	
	v = self.goalentity.s.origin - self.s.origin;
	self.ideal_yaw = vectoyaw(v);	
	M_ChangeYaw (self);
	
	if (self.s.frame == FRAME_landing_58 || self.s.frame == FRAME_takeoff_16)
	{
		self.goalentity.nextthink = level.framenum + 1;
		self.goalentity.think = G_FreeEdict;
		self.monsterinfo.currentmove = &fixbot_move_stand;
		self.goalentity = self.enemy = world;
	}

	// kick up some particles
	tempvec = self.s.angles;
	tempvec[PITCH] += 90;

	AngleVectors (tempvec, &forward, &right, &up);
	start = self.s.origin;
	
	for (int i = 0; i < 10; i++)
		blastoff (self, start, forward, 2, 1, TE_SHOTGUN, DEFAULT_SHOTGUN_HSPREAD, DEFAULT_SHOTGUN_VSPREAD);

	// needs sound
}

/*
	takeoff
*/
static mframe_t fixbot_frames_takeoff [] =
{
	{ ai_move,	0.01,	fly_vertical },
	{ ai_move,	0.01,	fly_vertical },
	{ ai_move,	0.01,	fly_vertical },
	{ ai_move,	0.01,	fly_vertical },
	{ ai_move,	0.01,	fly_vertical },
	{ ai_move,	0.01,	fly_vertical },
	{ ai_move,	0.01,	fly_vertical },
	{ ai_move,	0.01,	fly_vertical },
	{ ai_move,	0.01,	fly_vertical },
	{ ai_move,	0.01,	fly_vertical },

	{ ai_move,	0.01,	fly_vertical },
	{ ai_move,	0.01,	fly_vertical },
	{ ai_move,	0.01,	fly_vertical },
	{ ai_move,	0.01,	fly_vertical },
	{ ai_move,	0.01,	fly_vertical },
	{ ai_move,	0.01,	fly_vertical }
};
static var mmove_t fixbot_move_takeoff = { FRAME_takeoff_01, FRAME_takeoff_16 };

static void(entity self) takeoff_goal =
{
	trace_t	tr;
	vector	forward, right, up;
	vector	end;
	entity	ent;
	
	ent = G_Spawn ();	
	ent.classname = "bot_goal";
	ent.solid = SOLID_BBOX;
	ent.owner = self;
	gi.linkentity (ent);
	
	ent.mins = '-32 -32 -24';
	ent.maxs = '32 32 24';

	AngleVectors (self.s.angles, &forward, &right, &up);
	end = self.s.origin + (forward * 32); // Paril: this wasn't right in vanilla
	end += up * 128;
		
	gi.trace (&tr, self.s.origin, ent.mins, ent.maxs, end, self, MASK_MONSTERSOLID);

	ent.s.origin = tr.endpos;
	
	self.goalentity = self.enemy = ent;
	self.monsterinfo.currentmove = &fixbot_move_takeoff;
}

static void(entity self) fixbot_fire_welder =
{
	vector	start;
	vector	forward, right, up;
	vector	end;
	vector	dir;
	int	count = 2;
	vector	vec;
	float	r;
	
	if (!self.enemy)
		return;

	vec = '24.0 -0.8 -10.0';

	AngleVectors (self.s.angles, &forward, &right, &up);
	start = G_ProjectSource (self.s.origin, vec, forward, right);

	end = self.enemy.s.origin;
	
	dir = end - start;

	gi.WriteByte (svc_temp_entity);
	gi.WriteByte (TE_WELDING_SPARKS);
	gi.WriteByte (10);
	gi.WritePosition (start);
	gi.WriteDir (vec3_origin);
	gi.WriteByte (0xe0 + (Q_rand()&7));
	gi.multicast (self.s.origin, MULTICAST_PVS);


	if (random() > 0.8)
	{
		r = random();

		if (r < 0.33)
			gi.sound (self, CHAN_VOICE, sound_weld1, 1, ATTN_IDLE, 0);
		else if (r < 0.66)
			gi.sound (self, CHAN_VOICE, sound_weld2, 1, ATTN_IDLE, 0);
		else
			gi.sound (self, CHAN_VOICE, sound_weld3, 1, ATTN_IDLE, 0);
	}
}

static mframe_t fixbot_frames_weld [] =
{
	{ ai_move2, 0, fixbot_fire_welder },
	{ ai_move2, 0, fixbot_fire_welder },
	{ ai_move2, 0, fixbot_fire_welder },
	{ ai_move2, 0, fixbot_fire_welder },
	{ ai_move2, 0, fixbot_fire_welder },
	{ ai_move2, 0, fixbot_fire_welder },
	{ ai_move2, 0, weldstate }
};

static mframe_t fixbot_frames_weld_end [] =
{
	{ ai_move2, -2 },
	{ ai_move2, -2 },
	{ ai_move2, -2 },
	{ ai_move2, -2 },
	{ ai_move2, -2 },
	{ ai_move2, -2 },
	{ ai_move2, -2, weldstate }
};

static void(entity self) fixbot_stand =
{
	self.monsterinfo.currentmove = &fixbot_move_stand;
}

/*
	
*/
static mframe_t fixbot_frames_run [] =
{
	{ ai_run,	10 }
};
static var mmove_t fixbot_move_run = { FRAME_freeze_01, FRAME_freeze_01 };

static void(entity self) fixbot_run =
{
	if (self.monsterinfo.aiflags & AI_STAND_GROUND)
		self.monsterinfo.currentmove = &fixbot_move_stand;
	else
		self.monsterinfo.currentmove = &fixbot_move_run;
}

/* findout what this is */
static mframe_t fixbot_frames_paina [] =
{
	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move }
};
static var mmove_t fixbot_move_paina = { FRAME_paina_01, FRAME_paina_06, fixbot_run };

/* findout what this is */
static mframe_t fixbot_frames_painb [] =
{
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
static var mmove_t fixbot_move_painb = { FRAME_painb_01, FRAME_painb_08, fixbot_run };

/*
	backup from pain
	call a generic painsound
	some spark effects
*/
static mframe_t fixbot_frames_pain3 [] =
{
	{ ai_move, -1 }
};
static var mmove_t fixbot_move_pain3 = { FRAME_freeze_01, FRAME_freeze_01, fixbot_run };


/*
	
*/
static mframe_t fixbot_frames_walk [] =
{
	{ ai_walk,	5 }
};
static var mmove_t fixbot_move_walk = { FRAME_freeze_01, FRAME_freeze_01 };

static int(entity self) check_telefrag =
{
	vector start = vec3_origin;
	vector	forward, right, up;
	trace_t	tr;

	AngleVectors (self.enemy.s.angles, &forward, &right, &up);
	start = self.enemy.s.origin + (up * 48); // Paril: this was broken in vanilla
	gi.trace (&tr, self.enemy.s.origin, self.enemy.mins, self.enemy.maxs, start, self, MASK_MONSTERSOLID);
	
	if (tr.ent.takedamage)
	{
		tr.ent.health = -1000;
		return 0;
	}
			
	return 1;
}

static void(entity self) fixbot_fire_laser =
{
	vector	forward, right, up;
	vector	tempang, start;
	vector	dir, angles, end;
	entity	ent;

	// critter dun got blown up while bein' fixed
	if (self.enemy.health <= self.enemy.gib_health)
	{
		self.monsterinfo.currentmove = &fixbot_move_stand;
		self.monsterinfo.aiflags &= ~AI_MEDIC;
		return;
	}

	gi.sound(self, CHAN_AUTO, gi.soundindex("misc/lasfly.wav"), 1, ATTN_STATIC, 0);

	start = self.s.origin;
	end = self.enemy.s.origin;
	dir = end - start;
	angles = vectoangles (dir);
	
	ent = G_Spawn ();
	ent.s.origin = self.s.origin;
	tempang = angles;
	AngleVectors (tempang, &forward, &right, &up);
	ent.s.angles = tempang;
	start = ent.s.origin;
	
	start += forward * 16;
	
	ent.s.origin = start;
	ent.enemy = self.enemy;
	ent.owner = self;
	ent.dmg = -1;
	monster_dabeam (ent);

	if (self.enemy.health > (self.enemy.mass / 10))
	{
		// sorry guys but had to fix the problem this way
		// if it doesn't do this then two creatures can share the same space
		// and its real bad.
		if (check_telefrag (self)) 
		{
			self.enemy.spawnflags = 0;
			self.enemy.monsterinfo.aiflags = 0;
			self.enemy.target = 0;
			self.enemy.targetname = 0;
			self.enemy.combattarget = 0;
			self.enemy.deathtarget = 0;
			self.enemy.owner = self;
			ED_CallSpawn (self.enemy);
			self.enemy.owner = 0;
			self.s.origin[2] += 1;
		
			self.enemy.monsterinfo.aiflags &= ~AI_RESURRECTING;

			self.monsterinfo.currentmove = &fixbot_move_stand;
			self.monsterinfo.aiflags &= ~AI_MEDIC;

		}
	}
	else
		self.enemy.monsterinfo.aiflags |= AI_RESURRECTING;
}

static mframe_t fixbot_frames_laserattack [] =
{
	{ ai_charge,	0,	fixbot_fire_laser },
	{ ai_charge,	0,	fixbot_fire_laser },
	{ ai_charge,	0,	fixbot_fire_laser },
	{ ai_charge,	0,	fixbot_fire_laser },
	{ ai_charge,	0,	fixbot_fire_laser },
	{ ai_charge,	0,	fixbot_fire_laser }
};
static var mmove_t fixbot_move_laserattack = { FRAME_shoot_01, FRAME_shoot_06 };

static void(entity self) fixbot_fire_blaster =
{
	vector	start;
	vector	forward, right, up;
	vector	end;
	vector	dir;

	if (!visible(self, self.enemy))
		self.monsterinfo.currentmove = &fixbot_move_run;	
	
	AngleVectors (self.s.angles, &forward, &right, &up);
	start = G_ProjectSource (self.s.origin, monster_flash_offset[MZ2_fixbot_BLASTER_1], forward, right);

	end = self.enemy.s.origin;
	end[2] += self.enemy.viewheight;
	dir = end - start;

	monster_fire_blaster (self, start, dir, 15, 1000, MZ2_fixbot_BLASTER_1, EF_BLASTER);
	
}

/*
	need to get forward translation data
	for the charge attack
*/
static mframe_t fixbot_frames_attack2 [] =
{
	{ ai_charge },
	{ ai_charge },
	{ ai_charge },
	{ ai_charge },
	{ ai_charge },
	{ ai_charge },
	{ ai_charge },
	{ ai_charge },
	{ ai_charge },
	{ ai_charge },

	{ ai_charge,	-10 },
	{ ai_charge,  -10 },
	{ ai_charge,	-10 },
	{ ai_charge,  -10 },
	{ ai_charge,	-10 },
	{ ai_charge,  -10 },
	{ ai_charge,	-10 },
	{ ai_charge,  -10 },
	{ ai_charge,	-10 },
	{ ai_charge,  -10 },

	{ ai_charge,	0,	fixbot_fire_blaster },
	{ ai_charge },
	{ ai_charge },
	{ ai_charge },
	{ ai_charge },
	{ ai_charge },
	{ ai_charge },
	{ ai_charge },
	{ ai_charge },
	{ ai_charge },

	{ ai_charge }
};
static var mmove_t fixbot_move_attack2 = { FRAME_charging_01, FRAME_charging_31, fixbot_run };

static void(entity self) fixbot_attack =
{
	vector	vec;
	float	len;
	
	if (self.monsterinfo.aiflags & AI_MEDIC)
	{
		if (!visible (self, self.goalentity))
			return;
		vec = self.s.origin - self.enemy.s.origin;
		len = VectorLength(vec);
		if (len > 128)
			return;
		else
			self.monsterinfo.currentmove = &fixbot_move_laserattack;
	}
	else
		self.monsterinfo.currentmove = &fixbot_move_attack2;
	
}

//
static mframe_t fixbot_frames_start_attack [] =
{
	{ ai_charge }
};
static var mmove_t fixbot_move_start_attack = { FRAME_freeze_01, FRAME_freeze_01, fixbot_attack };

static void(entity self) fixbot_walk =
{
	vector	vec;
	float	len;

	if (self.goalentity.classname == "object_repair")
	{
		vec = self.s.origin - self.goalentity.s.origin;
		len = VectorLength (vec);
		if (len < 32)
		{
			self.monsterinfo.currentmove = &fixbot_move_weld_start;
			return;
		}
	}
	self.monsterinfo.currentmove = &fixbot_move_walk;
}

static void(entity self) fixbot_start_attack =
{
	self.monsterinfo.currentmove = &fixbot_move_start_attack;
}

static void(entity self, entity other, float kick, int damage) fixbot_pain =
{
//	if (self.health < (self.max_health / 2))
//		self.s.skinnum = 1;
	// gi.dprintf("pain\n");

	if (level.framenum < self.pain_debounce_framenum)
		return;

	self.pain_debounce_framenum = level.framenum + (int)(3 * BASE_FRAMERATE);
	gi.sound (self, CHAN_VOICE, sound_pain1, 1, ATTN_NORM, 0);

	if (damage <= 10)
		self.monsterinfo.currentmove = &fixbot_move_pain3;
	else if (damage <= 25)
		self.monsterinfo.currentmove = &fixbot_move_painb;
	else
		self.monsterinfo.currentmove = &fixbot_move_paina;
}

static void(entity self, entity inflictor, entity attacker, int damage, vector point) fixbot_die =
{
	gi.sound (self, CHAN_VOICE, sound_die, 1, ATTN_NORM, 0);
	BecomeExplosion1(self);

	// shards
	
}

/*QUAKED monster_fixbot (1 .5 0) (-32 -32 -24) (32 32 24) Ambush Trigger_Spawn Fixit Takeoff Landing
*/
API_FUNC static void(entity self) SP_monster_fixbot =
{
	if (deathmatch.intVal)
	{
		G_FreeEdict (self);
		return;
	}
	
	if (!fixbot_move_attack2.frame)
	{
		fixbot_move_attack2.frame = &fixbot_frames_attack2;
		fixbot_move_laserattack.frame = &fixbot_frames_laserattack;
		fixbot_move_start_attack.frame = &fixbot_frames_start_attack;
		fixbot_move_walk.frame = &fixbot_frames_walk;
		fixbot_move_run.frame = &fixbot_frames_run;
		fixbot_move_paina.frame = &fixbot_frames_paina;
		fixbot_move_painb.frame = &fixbot_frames_painb;
		fixbot_move_pain3.frame = &fixbot_frames_pain3;
		fixbot_move_weld_start.frame = &fixbot_frames_weld_start;
		fixbot_move_weld.frame = &fixbot_frames_weld;
		fixbot_move_weld_end.frame = &fixbot_frames_weld_end;
		fixbot_move_turn.frame = &fixbot_frames_turn;
		fixbot_move_forward.frame = &fixbot_frames_forward;
		fixbot_move_stand2.frame = &fixbot_frames_stand2;
		fixbot_move_roamgoal.frame = &fixbot_frames_roamgoal;
		fixbot_move_stand.frame = &fixbot_frames_stand;
		fixbot_move_landing.frame = &fixbot_frames_landing;
		fixbot_move_takeoff.frame = &fixbot_frames_takeoff;
	}

	sound_pain1 = gi.soundindex ("flyer/flypain1.wav");
	sound_die = gi.soundindex ("flyer/flydeth1.wav");

	sound_weld1 = gi.soundindex ("misc/welder1.wav");
	sound_weld2 = gi.soundindex ("misc/welder2.wav");
	sound_weld3 = gi.soundindex ("misc/welder3.wav");

	self.s.modelindex = gi.modelindex ("models/monsters/fixbot/tris.md2");
	
	self.mins = '-32 -32 -24';
	self.maxs = '32 32 24';
	
	self.movetype = MOVETYPE_STEP;
	self.solid = SOLID_BBOX;

	self.health = 150;
	self.mass = 150;

	self.pain = fixbot_pain;
	self.die = fixbot_die;

	self.monsterinfo.stand = fixbot_stand;
	self.monsterinfo.walk = fixbot_walk;
	self.monsterinfo.run = fixbot_run;
	self.monsterinfo.attack = fixbot_attack;
	
	gi.linkentity (self);

	self.monsterinfo.currentmove = &fixbot_move_stand;	
	self.monsterinfo.scale = MODEL_SCALE;
			
	flymonster_start (self);
				
}

#endif
