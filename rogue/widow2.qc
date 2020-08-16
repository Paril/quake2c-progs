#ifdef GROUND_ZERO

#include "m_widow2.h"

const float DISRUPT_TIME		= 3;

static int	sound_pain1;
static int	sound_pain2;
static int	sound_pain3;
static int	sound_death;
static int	sound_search1;
static int	sound_tentacles_retract;

// sqrt(64*64*2) + sqrt(28*28*2) => 130.1
static const vector spawnpoints[] = {
	[ 30,  135, 0 ],
	[ 30, -135, 0 ]
};

static const float sweep_angles[] = {
	-40.0, -32.0, -24.0, -16.0, -8.0, 0.0, 8.0, 16.0, 24.0, 32.0, 40.0
};

// these offsets used by the tongue
static const vector offsets[] = {
	[ 17.48, 0.10, 68.92 ],
	[ 17.47, 0.29, 68.91 ],
	[ 17.45, 0.53, 68.87 ],
	[ 17.42, 0.78, 68.81 ],
	[ 17.39, 1.02, 68.75 ],
	[ 17.37, 1.20, 68.70 ],
	[ 17.36, 1.24, 68.71 ],
	[ 17.37, 1.21, 68.72 ],
};

static void pauseme (entity self)
{
	self.monsterinfo.aiflags |= AI_HOLD_FRAME;
}

static void widow2_search (entity self)
{
	if (random() < 0.5)
		gi.sound (self, CHAN_VOICE, sound_search1, 1, ATTN_NONE, 0);
}

static void Widow2BeamTargetRemove (entity self)
{
	self.pos1 = self.pos2 = vec3_origin;
}

static void Widow2SaveBeamTarget (entity self)
{
	if (self.enemy && self.enemy.inuse)
	{
		self.pos2 = self.pos1;
		self.pos1 = self.enemy.s.origin;	//save for aiming the shot
	}
	else
		Widow2BeamTargetRemove(self);
}

static void Widow2Beam (entity self)
{
	vector	forward, right, target;
	vector	start, targ_angles, vec;
	int	flashnum;

	if (!self.enemy || !self.enemy.inuse)
		return;

	AngleVectors (self.s.angles, &forward, &right, 0);
	
	if ((self.s.frame >= FRAME_fireb05) && (self.s.frame <= FRAME_fireb09))
	{
		// regular beam attack
		Widow2SaveBeamTarget(self);
		flashnum = MZ2_WIDOW2_BEAMER_1 + self.s.frame - FRAME_fireb05;
		start = G_ProjectSource (self.s.origin, monster_flash_offset[flashnum], forward, right);
		target = self.pos2;
		target[2] += self.enemy.viewheight-10;
		forward = target - start;
		VectorNormalize (forward);
		monster_fire_heatbeam (self, start, forward, vec3_origin, 10, 50, flashnum);
	}
	else if ((self.s.frame >= FRAME_spawn04) && (self.s.frame <= FRAME_spawn14))
	{
		// sweep
		flashnum = MZ2_WIDOW2_BEAM_SWEEP_1 + self.s.frame - FRAME_spawn04;
		start = G_ProjectSource (self.s.origin, monster_flash_offset[flashnum], forward, right);
		target = self.enemy.s.origin - start;
		targ_angles = vectoangles (target);
		
		vec = self.s.angles;

		vec[PITCH] += targ_angles[PITCH];
		vec[YAW] -= sweep_angles[flashnum-MZ2_WIDOW2_BEAM_SWEEP_1];

		AngleVectors (vec, &forward, 0, 0);
		monster_fire_heatbeam (self, start, forward, vec3_origin, 10, 50, flashnum);
	}
	else
	{
		Widow2SaveBeamTarget(self);
		start = G_ProjectSource (self.s.origin, monster_flash_offset[MZ2_WIDOW2_BEAMER_1], forward, right);

		target = self.pos2;
		target[2] += self.enemy.viewheight-10;
		
		forward = target - start;
		VectorNormalize (forward);

		monster_fire_heatbeam (self, start, forward, vec3_origin, 10, 50, 0);
	}	
}

static void Widow2Spawn (entity self)
{
	vector f, r, u, offset, startpoint, spawnpoint;
	entity ent, designated_enemy;
	int		i;

	AngleVectors (self.s.angles, &f, &r, &u);

	for (i=0; i < 2; i++)
	{
		offset = spawnpoints[i];

		startpoint = G_ProjectSource2 (self.s.origin, offset, f, r, u);

		if (FindSpawnPoint (startpoint, stalker_mins, stalker_maxs, &spawnpoint, 64))
		{
			ent = CreateGroundMonster (spawnpoint, self.s.angles, stalker_mins, stalker_maxs, "monster_stalker", 256);

			if (!ent)
				continue;

			self.monsterinfo.monster_used++;
			ent.monsterinfo.commander = self;

			ent.nextthink = level.framenum;
			ent.think (ent);
			
			ent.monsterinfo.aiflags |= AI_SPAWNED_WIDOW|AI_DO_NOT_COUNT|AI_IGNORE_SHOTS;

			if (!coop.intVal)
				designated_enemy = self.enemy;
			else
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

			if ((designated_enemy.inuse) && (designated_enemy.health > 0))
			{
				ent.enemy = designated_enemy;
				FoundTarget (ent);
				ent.monsterinfo.attack(ent);
			}
		}
	}
}

static void widow2_spawn_check (entity self)
{
	Widow2Beam(self);
	Widow2Spawn (self);
}

static void widow2_ready_spawn (entity self)
{
	vector	f, r, u, offset, startpoint, spawnpoint;
	int	i;

	Widow2Beam(self);
	AngleVectors (self.s.angles, &f, &r, &u);

	for (i=0; i < 2; i++)
	{
		offset = spawnpoints[i];
		startpoint = G_ProjectSource2 (self.s.origin, offset, f, r, u);
		if (FindSpawnPoint (startpoint, stalker_mins, stalker_maxs, &spawnpoint, 64))
			SpawnGrow_Spawn (spawnpoint, 1);
	}
}

static mframe_t widow2_frames_stand [] =
{
	{ ai_stand }
};
static var mmove_t widow2_move_stand = { FRAME_blackwidow3, FRAME_blackwidow3 };

static mframe_t widow2_frames_walk [] =
{
	{ ai_walk,	9.01 },
	{ ai_walk,	7.55 },
	{ ai_walk,	7.01 },
	{ ai_walk,	6.66 },
	{ ai_walk,	6.20 },
	{ ai_walk,	5.78 },
	{ ai_walk,	7.25 },
	{ ai_walk,	8.37 },
	{ ai_walk,	10.41 }
};
static var mmove_t widow2_move_walk = { FRAME_walk01, FRAME_walk09 };

static mframe_t widow2_frames_run [] =
{
	{ ai_run,	9.01 },
	{ ai_run,	7.55 },
	{ ai_run,	7.01 },
	{ ai_run,	6.66 },
	{ ai_run,	6.20 },
	{ ai_run,	5.78 },
	{ ai_run,	7.25 },
	{ ai_run,	8.37 },
	{ ai_run,	10.41 }
};
static var mmove_t widow2_move_run = { FRAME_walk01, FRAME_walk09 };

static var mmove_t widow2_move_attack_beam = { FRAME_fireb05, FRAME_fireb09 };

static void widow2_attack_beam (entity self)
{
	self.monsterinfo.currentmove = &widow2_move_attack_beam;
}

static mframe_t widow2_frames_attack_pre_beam [] =
{
	{ ai_charge,	4 },
	{ ai_charge,	4 },
	{ ai_charge,	4 },
	{ ai_charge,	4,	widow2_attack_beam }
};
static var mmove_t widow2_move_attack_pre_beam = { FRAME_fireb01, FRAME_fireb04 };

static var mmove_t widow2_move_spawn = { FRAME_spawn01, FRAME_spawn18 };
static var mmove_t widow2_move_attack_post_beam = { FRAME_fireb06, FRAME_fireb07 };

static void widow2_reattack_beam (entity self)
{
	self.monsterinfo.aiflags &= ~AI_MANUAL_STEERING;

	if (infront(self, self.enemy))
		if (random() <= 0.5)
			if ((random() < 0.7) || (SELF_SLOTS_LEFT(self) < 2))
				self.monsterinfo.currentmove = &widow2_move_attack_beam;
			else
				self.monsterinfo.currentmove = &widow2_move_spawn;
		else
			self.monsterinfo.currentmove = &widow2_move_attack_post_beam;
	else
		self.monsterinfo.currentmove = &widow2_move_attack_post_beam;
}

// Loop this
static mframe_t widow2_frames_attack_beam [] =
{
	{ ai_charge,	0,	Widow2Beam },
	{ ai_charge,	0,	Widow2Beam },
	{ ai_charge,	0,	Widow2Beam },
	{ ai_charge,	0,	Widow2Beam },
	{ ai_charge,	0,	widow2_reattack_beam }
};

static mframe_t widow2_frames_attack_post_beam [] =
{
	{ ai_charge,	4 },
	{ ai_charge,	4 },
	{ ai_charge,	4 }
};

static void WidowDisrupt (entity self)
{
	vector	start;
	vector	dir;
	vector	forward, right;
	float	len;

	AngleVectors (self.s.angles, &forward, &right, 0);
	start = G_ProjectSource (self.s.origin, monster_flash_offset[MZ2_WIDOW_DISRUPTOR], forward, right);

	dir = self.pos1 - self.enemy.s.origin;
	len = VectorLength (dir);

	if (len < 30)
	{
		// calc direction to where we targeted
		dir = self.pos1 - start;
		VectorNormalize (dir);

		monster_fire_tracker(self, start, dir, 20, 500, self.enemy, MZ2_WIDOW_DISRUPTOR);
	}
	else
	{
		PredictAim (self.enemy, start, 1200, true, 0, &dir, 0);
		monster_fire_tracker(self, start, dir, 20, 1200, 0, MZ2_WIDOW_DISRUPTOR);
	}
}

static void Widow2SaveDisruptLoc (entity self)
{
	if (self.enemy && self.enemy.inuse)
	{
		self.pos1 = self.enemy.s.origin;	//save for aiming the shot
		self.pos1[2] += self.enemy.viewheight;
	}
	else
		self.pos1 = vec3_origin;
}

static void widow2_disrupt_reattack (entity self)
{
	float  luck = random();

	if (luck < (0.25 + (skill.intVal) * 0.15))
		self.monsterinfo.nextframe = FRAME_firea01;
}

static mframe_t widow2_frames_attack_disrupt [] =
{
	{ ai_charge, 2 },
	{ ai_charge, 2 },
	{ ai_charge, 2, Widow2SaveDisruptLoc },
	{ ai_charge, -20, WidowDisrupt },
	{ ai_charge, 2 },
	{ ai_charge, 2 },
	{ ai_charge, 2, widow2_disrupt_reattack }
};
static var mmove_t widow2_move_attack_disrupt = { FRAME_firea01, FRAME_firea07 };

static void Widow2StartSweep (entity self)
{
	Widow2SaveBeamTarget (self);
}

static mframe_t widow2_frames_spawn [] =
{
	{ ai_charge },
	{ ai_charge },
	{ ai_charge,	0,	widow_start_spawn },
	{ ai_charge,	0,	Widow2Beam },
	{ ai_charge,	0,	Widow2Beam },				//5
	{ ai_charge,	0,	Widow2Beam },
	{ ai_charge,	0,	Widow2Beam },
	{ ai_charge,	0,	Widow2Beam },
	{ ai_charge,	0,	Widow2Beam },
	{ ai_charge,	0,	widow2_ready_spawn },				//10
	{ ai_charge,	0,	Widow2Beam },
	{ ai_charge,	0,	Widow2Beam },
	{ ai_charge,	0,	Widow2Beam },
	{ ai_charge,	0,	widow2_spawn_check },
	{ ai_charge },				//15
	{ ai_charge },
	{ ai_charge },
	{ ai_charge,	0,	widow2_reattack_beam }
};

static bool widow2_tongue_attack_ok (vector start, vector end, float range)
{
	vector dir, angles;

	// check for max distance
	dir = start - end;
	if (VectorLength(dir) > range)
		return false;

	// check for min/max pitch
	angles = vectoangles (dir);
	if (angles[0] < -180)
		angles[0] += 360;
	if (fabs(angles[0]) > 30)
		return false;

	return true;
}

static void Widow2Tongue (entity self)
{
	vector	f, r, u;
	vector	start, end, dir;
	trace_t	tr;

	AngleVectors (self.s.angles, &f, &r, &u);
	start = G_ProjectSource2 (self.s.origin, offsets[self.s.frame - FRAME_tongs01], f, r, u);
	end = self.enemy.s.origin;
	if (!widow2_tongue_attack_ok(start, end, 256))
	{
		end[2] = self.enemy.s.origin[2] + self.enemy.maxs[2] - 8;
		if (!widow2_tongue_attack_ok(start, end, 256))
		{
			end[2] = self.enemy.s.origin[2] + self.enemy.mins[2] + 8;
			if (!widow2_tongue_attack_ok(start, end, 256))
				return;
		}
	}
	end = self.enemy.s.origin;

	gi.trace (&tr, start, vec3_origin, vec3_origin, end, self, MASK_SHOT);
	if (tr.ent != self.enemy)
		return;

	gi.sound (self, CHAN_WEAPON, sound_tentacles_retract, 1, ATTN_NORM, 0);

	gi.WriteByte (svc_temp_entity);
	gi.WriteByte (TE_PARASITE_ATTACK);
	gi.WriteShort (self.s.number);
	gi.WritePosition (start);
	gi.WritePosition (end);
	gi.multicast (self.s.origin, MULTICAST_PVS);

	dir = start - end;
	T_Damage (self.enemy, self, self, dir, self.enemy.s.origin, vec3_origin, 2, 0, DAMAGE_NO_KNOCKBACK, MOD_UNKNOWN);
}

static void Widow2TonguePull (entity self)
{
	vector	vec;
	float	len;
	vector	f, r, u;
	vector	start, end;

	if ((!self.enemy) || (!self.enemy.inuse))
	{
		self.monsterinfo.run (self);
		return;
	}

	AngleVectors (self.s.angles, &f, &r, &u);
	start = G_ProjectSource2 (self.s.origin, offsets[self.s.frame - FRAME_tongs01], f, r, u);
	end = self.enemy.s.origin;

	if (!widow2_tongue_attack_ok(start, end, 256))
		return;

	if (self.enemy.groundentity != null_entity)
	{
		self.enemy.s.origin[2] += 1;
		self.enemy.groundentity = null_entity;
		gi.linkentity(self.enemy);
	}
	
	vec = self.s.origin - self.enemy.s.origin;
	len = VectorLength (vec);
	if (self.enemy.is_client)
	{
		VectorNormalize (vec);
		self.enemy.velocity += 1000 * vec;
	}
	else
	{
		self.enemy.ideal_yaw = vectoyaw(vec);	
		M_ChangeYaw (self.enemy);
		self.enemy.velocity = f * 1000;
	}
}

static void Widow2Crunch (entity self)
{
	vector	aim;

	if ((!self.enemy) || (!self.enemy.inuse))
	{
		self.monsterinfo.run (self);
		return;
	}

	Widow2TonguePull (self);

	// 70 + 32
	aim = '150 0 4';
	if (self.s.frame != FRAME_tongs07)
		fire_hit (self, aim, 20 + (Q_rand() % 6), 0);
	else if (self.enemy.groundentity != null_entity)
		fire_hit (self, aim, (20 + (Q_rand() % 6)), 500);
	else	// not as much kick if they're in the air .. makes it harder to land on her head
		fire_hit (self, aim, (20 + (Q_rand() % 6)), 250);
}

static void Widow2Toss (entity self)
{
	self.timestamp = level.framenum + (3 * BASE_FRAMERATE);
}

static mframe_t widow2_frames_tongs [] =
{
	{ ai_charge,	0,	Widow2Tongue },
	{ ai_charge,	0,	Widow2Tongue },
	{ ai_charge,	0,	Widow2Tongue },
	{ ai_charge,	0,	Widow2TonguePull },
	{ ai_charge,	0,	Widow2TonguePull },				//5
	{ ai_charge,	0,	Widow2TonguePull },
	{ ai_charge,	0,	Widow2Crunch },
	{ ai_charge,	0,	Widow2Toss }
};
static var mmove_t widow2_move_tongs = { FRAME_tongs01, FRAME_tongs08 };

static mframe_t widow2_frames_pain [] =
{
	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move }
};
static var mmove_t widow2_move_pain = { FRAME_pain01, FRAME_pain05 };

static var mmove_t widow2_move_dead = { FRAME_dthsrh01, FRAME_dthsrh15 };

void WidowExplode (entity self)
{
	vector	org;
	int	n;

	self.think = WidowExplode;

	org = self.s.origin;
	org[2] += 24 + (Q_rand()&15);
	if (self.count < 8)
		org[2] += 24 + (Q_rand()&31);
	switch (self.count)
	{
	case 0:
		org[0] -= 24;
		org[1] -= 24;
		break;
	case 1:
		org[0] += 24;
		org[1] += 24;
		ThrowSmallStuff(self, org);
		break;
	case 2:
		org[0] += 24;
		org[1] -= 24;
		break;
	case 3:
		org[0] -= 24;
		org[1] += 24;
		ThrowMoreStuff(self, org);
		break;
	case 4:
		org[0] -= 48;
		org[1] -= 48;
		break;
	case 5:
		org[0] += 48;
		org[1] += 48;
		ThrowArm1 (self);
		break;
	case 6:
		org[0] -= 48;
		org[1] += 48;
		ThrowArm2 (self);
		break;
	case 7:
		org[0] += 48;
		org[1] -= 48;
		ThrowSmallStuff(self, org);
		break;
	case 8:
		org[0] += 18;
		org[1] += 18;
		org[2] = self.s.origin[2] + 48;
		ThrowMoreStuff(self, org);
		break;
	case 9:
		org[0] -= 18;
		org[1] += 18;
		org[2] = self.s.origin[2] + 48;
		break;
	case 10:
		org[0] += 18;
		org[1] -= 18;
		org[2] = self.s.origin[2] + 48;
		break;
	case 11:
		org[0] -= 18;
		org[1] -= 18;
		org[2] = self.s.origin[2] + 48;
		break;
	case 12:
		self.s.sound = 0;
		for (n= 0; n < 1; n++)
			ThrowWidowGib (self, "models/objects/gibs/sm_meat/tris.md2", 400, GIB_ORGANIC);
		for (n= 0; n < 2; n++)
			ThrowWidowGib (self, "models/objects/gibs/sm_metal/tris.md2", 100, GIB_METALLIC);
		for (n= 0; n < 2; n++)
			ThrowWidowGib (self, "models/objects/gibs/sm_metal/tris.md2", 400, GIB_METALLIC);

		self.deadflag = DEAD_DEAD;
		self.think = monster_think;
		self.nextthink = level.framenum + 1;
		self.monsterinfo.currentmove = &widow2_move_dead;
		return;
	}

	self.count++;
	if (self.count >=9 && self.count <=12)
	{
		gi.WriteByte (svc_temp_entity);
		gi.WriteByte (TE_EXPLOSION1_BIG);
		gi.WritePosition (org);
		gi.multicast (self.s.origin, MULTICAST_ALL);
	} 
	else
	{
		// else
		gi.WriteByte (svc_temp_entity);
		if (self.count %2)
			gi.WriteByte (TE_EXPLOSION1);
		else
			gi.WriteByte (TE_EXPLOSION1_NP);
		gi.WritePosition (org);
		gi.multicast (self.s.origin, MULTICAST_ALL);
	}

	self.nextthink = level.framenum + 1;
}

static mframe_t widow2_frames_death [] =
{
	{ ai_move },
	{ ai_move },
	{ ai_move,	0,	WidowExplosion1 },	// 3 boom
	{ ai_move },
	{ ai_move },				// 5

	{ ai_move,	0,	WidowExplosion2 },	// 6 boom
	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move },				// 10

	{ ai_move },
	{ ai_move },				// 12
	{ ai_move },
	{ ai_move },
	{ ai_move },				// 15

	{ ai_move },
	{ ai_move },
	{ ai_move,	0,	WidowExplosion3 },	// 18
	{ ai_move },				// 19
	{ ai_move },				// 20

	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move,	0,	WidowExplosion4 },	// 25

	{ ai_move },				// 26
	{ ai_move },
	{ ai_move },
	{ ai_move,	0,	WidowExplosion5 },
	{ ai_move,	0,	WidowExplosionLeg },	// 30

	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move,	0,	WidowExplosion6 },
	{ ai_move },				// 35

	{ ai_move },
	{ ai_move },
	{ ai_move,	0,	WidowExplosion7 },
	{ ai_move },
	{ ai_move },				// 40

	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move,	0,	WidowExplode }		// 44
};
static var mmove_t widow2_move_death = { FRAME_death01, FRAME_death44 };

static void widow2_start_searching (entity self)
{
	self.count = 0;
}
static var mmove_t widow2_move_really_dead = { FRAME_dthsrh16, FRAME_dthsrh22 };

static void widow2_keep_searching (entity self)
{
	if (self.count <= 2)
	{
		self.monsterinfo.currentmove = &widow2_move_dead;
		self.s.frame = FRAME_dthsrh01;
		self.count++;
		return;
	}

	self.monsterinfo.currentmove = &widow2_move_really_dead;
}

static mframe_t widow2_frames_dead [] =
{
	{ ai_move,	0,	widow2_start_searching },
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
	{ ai_move,	0,	widow2_keep_searching }
};

static void widow2_finaldeath (entity self)
{
	self.mins = '-70 -70 0';
	self.maxs = '70 70 80';
	self.movetype = MOVETYPE_TOSS;
	self.takedamage = DAMAGE_YES;
	self.nextthink = 0;
	gi.linkentity (self);
}

mframe_t widow2_frames_really_dead [] =
{
	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move },

	{ ai_move },
	{ ai_move,	0,	widow2_finaldeath }
};

static void widow2_stand (entity self)
{
	self.monsterinfo.currentmove = &widow2_move_stand;
}

static void widow2_run (entity self)
{
	self.monsterinfo.aiflags &= ~AI_HOLD_FRAME;

	if (self.monsterinfo.aiflags & AI_STAND_GROUND)
		self.monsterinfo.currentmove = &widow2_move_stand;
	else
		self.monsterinfo.currentmove = &widow2_move_run;
}

static void widow2_walk (entity self)
{
	self.monsterinfo.currentmove = &widow2_move_walk;
}

static void widow2_melee (entity self)
{
	self.monsterinfo.currentmove = &widow2_move_tongs;
}

static void widow2_attack (entity self)
{
	float	range, luck;
	bool	blocked = false;

	if (self.monsterinfo.aiflags & AI_BLOCKED)
	{
		blocked = true;
		self.monsterinfo.aiflags &= ~AI_BLOCKED;
	}

	if (!self.enemy)
		return;

	if (self.bad_area)
	{
		if ((random() < 0.75) || (level.framenum < self.monsterinfo.attack_finished))
			self.monsterinfo.currentmove = &widow2_move_attack_pre_beam;
		else
			self.monsterinfo.currentmove = &widow2_move_attack_disrupt;

		return;
	}

	WidowCalcSlots(self);

	// if we can't see the target, spawn stuff
	if ((self.monsterinfo.attack_state == AS_BLIND) && (SELF_SLOTS_LEFT(self) >= 2))
	{
		self.monsterinfo.currentmove = &widow2_move_spawn;
		return;
	}

	// accept bias towards spawning
	if (blocked && (SELF_SLOTS_LEFT(self) >= 2))
	{
		self.monsterinfo.currentmove = &widow2_move_spawn;
		return;
	}

	range = realrange (self, self.enemy);

	if (range < 600)
	{
		luck = random();
		if (SELF_SLOTS_LEFT(self) >= 2)
		{
			if (luck <= 0.40)
				self.monsterinfo.currentmove = &widow2_move_attack_pre_beam;
			else if ((luck <= 0.7) && !(level.framenum < self.monsterinfo.attack_finished))
				self.monsterinfo.currentmove = &widow2_move_attack_disrupt;
			else
				self.monsterinfo.currentmove = &widow2_move_spawn;
		}
		else
		{
			if ((luck <= 0.50) || (level.framenum < self.monsterinfo.attack_finished))
				self.monsterinfo.currentmove = &widow2_move_attack_pre_beam;
			else
				self.monsterinfo.currentmove = &widow2_move_attack_disrupt;
		}
	}
	else
	{
		luck = random();
		if (SELF_SLOTS_LEFT(self) >= 2)
		{
			if (luck < 0.3)
				self.monsterinfo.currentmove = &widow2_move_attack_pre_beam;
			else if ((luck < 0.65) || (level.framenum < self.monsterinfo.attack_finished))
				self.monsterinfo.currentmove = &widow2_move_spawn;
			else
				self.monsterinfo.currentmove = &widow2_move_attack_disrupt;
		}
		else
		{
			if ((luck < 0.45) || (level.framenum < self.monsterinfo.attack_finished))
				self.monsterinfo.currentmove = &widow2_move_attack_pre_beam;
			else
				self.monsterinfo.currentmove = &widow2_move_attack_disrupt;
		}
	}
}

static void widow2_pain (entity self, entity other, float kick, int damage)
{
	if (self.health < (self.max_health / 2))
		self.s.skinnum = 1;

	if (skill.intVal == 3)
		return;		// no pain anims in nightmare

	if (level.framenum < self.pain_debounce_framenum)
		return;

	self.pain_debounce_framenum = level.framenum + (5 * BASE_FRAMERATE);

	if (damage < 15)
		gi.sound (self, CHAN_VOICE, sound_pain1, 1, ATTN_NONE, 0);
	else if (damage < 75)
	{
		gi.sound (self, CHAN_VOICE, sound_pain2, 1, ATTN_NONE, 0);
		if ((skill.intVal < 3) && (random() < (0.6 - (0.2*skill.intVal))))
		{
			self.monsterinfo.aiflags &= ~AI_MANUAL_STEERING;
			self.monsterinfo.currentmove = &widow2_move_pain;
		}
	}
	else 
	{
		gi.sound (self, CHAN_VOICE, sound_pain3, 1, ATTN_NONE, 0);
		if ((skill.intVal < 3) && (random() < (0.75 - (0.1*skill.intVal))))
		{
			self.monsterinfo.aiflags &= ~AI_MANUAL_STEERING;
			self.monsterinfo.currentmove = &widow2_move_pain;
		}
	}
}

static void widow2_dead (entity self)
{
}

static void KillChildren (entity self)
{
	entity ent = world;
	.string field = classname;
	while ((ent = G_Find (ent, field, "monster_stalker")))
	{
		// FIXME - may need to stagger
		if ((ent.inuse) && (ent.health > 0))
			T_Damage (ent, self, self, vec3_origin, self.enemy.s.origin, vec3_origin, (ent.health + 1), 0, DAMAGE_NO_KNOCKBACK, MOD_UNKNOWN);
	}
}

static void widow2_die (entity self, entity inflictor, entity attacker, int damage, vector point)
{
	int n;
	int	clipped;

// check for gib
	if (self.health <= self.gib_health)
	{
		clipped = mini (damage, 100);

		gi.sound (self, CHAN_VOICE, gi.soundindex ("misc/udeath.wav"), 1, ATTN_NORM, 0);
		for (n= 0; n < 2; n++)
			ThrowWidowGibLoc (self, "models/objects/gibs/bone/tris.md2", clipped, GIB_ORGANIC, 0, false);
		for (n= 0; n < 3; n++)
			ThrowWidowGibLoc (self, "models/objects/gibs/sm_meat/tris.md2", clipped, GIB_ORGANIC, 0, false);
		for (n= 0; n < 3; n++)
		{
			ThrowWidowGibSized (self, "models/monsters/blackwidow2/gib1/tris.md2", clipped, GIB_METALLIC, 0,
				0, false);
			ThrowWidowGibSized (self, "models/monsters/blackwidow2/gib2/tris.md2", clipped, GIB_METALLIC, 0, 
				gi.soundindex ("misc/fhit3.wav"), false);
		}
		for (n= 0; n < 2; n++)
		{
			ThrowWidowGibSized (self, "models/monsters/blackwidow2/gib3/tris.md2", clipped, GIB_METALLIC, 0, 
				0, false);
			ThrowWidowGibSized (self, "models/monsters/blackwidow/gib3/tris.md2", clipped, GIB_METALLIC, 0, 
				0, false);
		}
		ThrowGib (self, "models/objects/gibs/chest/tris.md2", clipped, GIB_ORGANIC);
		ThrowHead (self, "models/objects/gibs/head2/tris.md2", clipped, GIB_ORGANIC);
		self.deadflag = DEAD_DEAD;
		return;
	}

	if (self.deadflag == DEAD_DEAD)
		return;

	gi.sound (self, CHAN_VOICE, sound_death, 1, ATTN_NONE, 0);
	self.deadflag = DEAD_DEAD;
	self.takedamage = DAMAGE_NO;
	self.count = 0;
	KillChildren (self);
	self.monsterinfo.quad_framenum = 0;
	self.monsterinfo.double_framenum = 0;
	self.monsterinfo.invincible_framenum = 0;
	self.monsterinfo.currentmove = &widow2_move_death;
}

static bool Widow2_CheckAttack (entity self)
{
	vector		spot1, spot2;
	vector		temp;
	float		chance;
	trace_t		tr;
	bool		enemy_infront;
	int		enemy_range;
	float		enemy_yaw;
	float		real_enemy_range;
	vector		f, r, u;

	if (!self.enemy)
		return false;

	WidowPowerups(self);

	if ((random() < 0.8) && (SELF_SLOTS_LEFT(self) >= 2) && (realrange(self, self.enemy) > 150))
	{
		self.monsterinfo.aiflags |= AI_BLOCKED;
		self.monsterinfo.attack_state = AS_MISSILE;
		return true;
	}

	if (self.enemy.health > 0)
	{
		spot1 = self.s.origin;
		spot1[2] += self.viewheight;
		spot2 = self.enemy.s.origin;
		spot2[2] += self.enemy.viewheight;

		gi.trace (&tr, spot1, vec3_origin, vec3_origin, spot2, self, CONTENTS_SOLID|CONTENTS_MONSTER|CONTENTS_SLIME|CONTENTS_LAVA);

		// do we have a clear shot?
		if (tr.ent != self.enemy)
		{	
			// go ahead and spawn stuff if we're mad a a client
			if (self.enemy.is_client && SELF_SLOTS_LEFT(self) >= 2)
			{
				self.monsterinfo.attack_state = AS_BLIND;
				return true;
			}
				
			// PGM - we want them to go ahead and shoot at info_notnulls if they can.
			if(self.enemy.solid != SOLID_NOT || tr.fraction < 1.0)		//PGM
				return false;
		}
	}
	
	enemy_infront = infront(self, self.enemy);

	enemy_range = range(self, self.enemy);
	temp = self.enemy.s.origin - self.s.origin;
	enemy_yaw = vectoyaw(temp);

	self.ideal_yaw = enemy_yaw;

	// melee attack
	if (self.timestamp < level.framenum)
	{
		real_enemy_range = realrange (self, self.enemy);
		if (real_enemy_range < 300)
		{
			AngleVectors (self.s.angles, &f, &r, &u);
			spot1 = G_ProjectSource2 (self.s.origin, offsets[0], f, r, u);
			spot2 = self.enemy.s.origin;
			if (widow2_tongue_attack_ok(spot1, spot2, 256))
			{
				// melee attack ok
				// be nice in easy mode
				if (skill.intVal == 0 && (Q_rand()&3) )
					return false;

				if (self.monsterinfo.melee)
					self.monsterinfo.attack_state = AS_MELEE;
				else
					self.monsterinfo.attack_state = AS_MISSILE;
				return true;
			}
		}
	}
	
	if (level.framenum < self.monsterinfo.attack_finished)
		return false;
		
	if (self.monsterinfo.aiflags & AI_STAND_GROUND)
		chance = 0.4;
	else if (enemy_range == RANGE_NEAR || enemy_range == RANGE_MID)
		chance = 0.8;
	else
		chance = 0.5;

	// PGM - go ahead and shoot every time if it's a info_notnull
	if ((random () < chance) || (self.enemy.solid == SOLID_NOT))
	{
		self.monsterinfo.attack_state = AS_MISSILE;
		return true;
	}

	return false;
}

static void Widow2Precache ()
{
	// cache in all of the stalker stuff, widow stuff, spawngro stuff, gibs
	gi.soundindex ("parasite/parpain1.wav");	
	gi.soundindex ("parasite/parpain2.wav");	
	gi.soundindex ("parasite/pardeth1.wav");	
	gi.soundindex ("parasite/paratck1.wav");
	gi.soundindex ("parasite/parsght1.wav");
	gi.soundindex ("infantry/melee2.wav");
	gi.soundindex ("misc/fhit3.wav");

	gi.soundindex ("tank/tnkatck3.wav");
	gi.soundindex ("weapons/disrupt.wav");
	gi.soundindex ("weapons/disint2.wav");

	gi.modelindex ("models/monsters/stalker/tris.md2");
	gi.modelindex ("models/items/spawngro2/tris.md2");
	gi.modelindex ("models/objects/gibs/sm_metal/tris.md2");
	gi.modelindex ("models/proj/laser2/tris.md2");
	gi.modelindex ("models/proj/disintegrator/tris.md2");

	gi.modelindex ("models/monsters/blackwidow/gib1/tris.md2");
	gi.modelindex ("models/monsters/blackwidow/gib2/tris.md2");
	gi.modelindex ("models/monsters/blackwidow/gib3/tris.md2");
	gi.modelindex ("models/monsters/blackwidow/gib4/tris.md2");
	gi.modelindex ("models/monsters/blackwidow2/gib1/tris.md2");
	gi.modelindex ("models/monsters/blackwidow2/gib2/tris.md2");
	gi.modelindex ("models/monsters/blackwidow2/gib3/tris.md2");
	gi.modelindex ("models/monsters/blackwidow2/gib4/tris.md2");
	
	if (!widow2_move_run.frame)
	{
		widow2_move_run.frame = &widow2_frames_run;
		widow2_move_stand.frame = &widow2_frames_stand;
		widow2_move_walk.frame = &widow2_frames_walk;
		widow2_move_attack_pre_beam.frame = &widow2_frames_attack_pre_beam;
		widow2_move_attack_beam.frame = &widow2_frames_attack_beam;
		widow2_move_attack_post_beam.frame = &widow2_frames_attack_post_beam;
		widow2_move_attack_post_beam.endfunc = widow2_run;
		widow2_move_attack_disrupt.frame = &widow2_frames_attack_disrupt;
		widow2_move_attack_disrupt.endfunc = widow2_run;
		widow2_move_spawn.frame = &widow2_frames_spawn;
		widow2_move_tongs.frame = &widow2_frames_tongs;
		widow2_move_tongs.endfunc = widow2_run;
		widow2_move_pain.frame = &widow2_frames_pain;
		widow2_move_pain.endfunc = widow2_run;
		widow2_move_death.frame = &widow2_frames_death;
		widow2_move_dead.frame = &widow2_frames_dead;
		widow2_move_really_dead.frame = &widow2_frames_really_dead;
	}
}

/*QUAKED monster_widow2 (1 .5 0) (-70 -70 0) (70 70 144) Ambush Trigger_Spawn Sight
*/
API_FUNC static void SP_monster_widow2 (entity self)
{
	if (deathmatch.intVal)
	{
		G_FreeEdict (self);
		return;
	}

	sound_pain1 = gi.soundindex ("widow/bw2pain1.wav");
	sound_pain2 = gi.soundindex ("widow/bw2pain2.wav");
	sound_pain3 = gi.soundindex ("widow/bw2pain3.wav");
	sound_death = gi.soundindex ("widow/death.wav");
	sound_search1 = gi.soundindex ("bosshovr/bhvunqv1.wav");
	sound_tentacles_retract = gi.soundindex ("brain/brnatck3.wav");

	self.movetype = MOVETYPE_STEP;
	self.solid = SOLID_BBOX;
	self.s.modelindex = gi.modelindex ("models/monsters/blackwidow2/tris.md2");
	self.mins = '-70 -70 0';
	self.maxs = '70 70 144';

	self.health = 2000 + 800 + 1000*(skill.intVal);
	if (coop.intVal)
		self.health += 500*(skill.intVal);
	self.gib_health = -900;
	self.mass = 2500;

	if (skill.intVal == 3)
	{
		self.monsterinfo.power_armor_type = POWER_ARMOR_SHIELD;
		self.monsterinfo.power_armor_power = 750;
	}

	self.yaw_speed = 30f;
	
	self.flags |= FL_IMMUNE_LASER;
	self.monsterinfo.aiflags |= AI_IGNORE_SHOTS;

	self.pain = widow2_pain;
	self.die = widow2_die;

	self.monsterinfo.melee = widow2_melee;
	self.monsterinfo.stand = widow2_stand;
	self.monsterinfo.walk = widow2_walk;
	self.monsterinfo.run = widow2_run;
	self.monsterinfo.attack = widow2_attack;
	self.monsterinfo.search = widow2_search;
	self.monsterinfo.checkattack = Widow2_CheckAttack;
	gi.linkentity (self);

	self.monsterinfo.currentmove = &widow2_move_stand;	
	self.monsterinfo.scale = MODEL_SCALE;

	Widow2Precache();
	WidowCalcSlots(self);
	walkmonster_start (self);
}

#endif