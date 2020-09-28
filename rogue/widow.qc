#if defined(GROUND_ZERO) && defined(SINGLE_PLAYER)
// self.timestamp used to prevent rapid fire of railgun
// self.plat2flags used for fire count (flashes)
// self.monsterinfo.pausetime used for timing of blaster shots
#include "m_widow.h"

const int NUM_STALKERS_SPAWNED		= 6;		// max # of stalkers she can spawn

const float RAIL_TIME				= 3;
const float BLASTER_TIME			= 2;
const int BLASTER2_DAMAGE			= 10;
const int WIDOW_RAIL_DAMAGE			= 50;

static int	sound_pain1;
static int	sound_pain2;
static int	sound_pain3;
static int	sound_rail;

static int	shotsfired;

static const vector spawnpoints[] = {
	'30  100 16',
	'30 -100 16'
};

static const vector beameffects[] = {
	'12.58 -43.71 68.88',
	'3.43 58.72 68.41'
};

static const float sweep_angles[] = {
	32.0, 26.0, 20.0, 10.0, 0.0, -6.5, -13.0, -27.0, -41.0
};

const vector stalker_mins = '-28 -28 -18';
const vector stalker_maxs = '28 28 18';

static int	widow_damage_multiplier;

static void(entity self, entity other) widow_sight =
{
	self.monsterinfo.pause_framenum = 0;
}

static float(entity self) target_angle =
{
	vector target = self.s.origin - self.enemy.s.origin;
	float enemy_yaw = self.s.angles[YAW] - vectoyaw(target);

	if (enemy_yaw < 0)
		enemy_yaw += 360.0;

	// this gets me 0 degrees = forward
	enemy_yaw -= 180.0;
	// positive is to right, negative to left

	return enemy_yaw;
}

static var mmove_t widow_move_attack_post_blaster_r = { FRAME_transa01, FRAME_transa05 };
static var mmove_t widow_move_attack_post_blaster_l = { FRAME_transb01, FRAME_transb05 };

static int(entity self) WidowTorso =
{
	float enemy_yaw = target_angle (self);

	if (enemy_yaw >= 105)
	{
		self.monsterinfo.currentmove = &widow_move_attack_post_blaster_r;
		self.monsterinfo.aiflags &= ~AI_MANUAL_STEERING;
		return 0;
	}

	if (enemy_yaw <= -75.0)
	{
		self.monsterinfo.currentmove = &widow_move_attack_post_blaster_l;
		self.monsterinfo.aiflags &= ~AI_MANUAL_STEERING;
		return 0;
	}

	if (enemy_yaw >= 95)
		return FRAME_fired03;
	else if (enemy_yaw >= 85)
		return FRAME_fired04;
	else if (enemy_yaw >= 75)
		return FRAME_fired05;
	else if (enemy_yaw >= 65)
		return FRAME_fired06;
	else if (enemy_yaw >= 55)
		return FRAME_fired07;
	else if (enemy_yaw >= 45)
		return FRAME_fired08;
	else if (enemy_yaw >= 35)
		return FRAME_fired09;
	else if (enemy_yaw >= 25)
		return FRAME_fired10;
	else if (enemy_yaw >= 15)
		return FRAME_fired11;
	else if (enemy_yaw >= 5)
		return FRAME_fired12;
	else if (enemy_yaw >= -5)
		return FRAME_fired13;
	else if (enemy_yaw >= -15)
		return FRAME_fired14;
	else if (enemy_yaw >= -25)
		return FRAME_fired15;
	else if (enemy_yaw >= -35)
		return FRAME_fired16;
	else if (enemy_yaw >= -45)
		return FRAME_fired17;
	else if (enemy_yaw >= -55)
		return FRAME_fired18;
	else if (enemy_yaw >= -65)
		return FRAME_fired19;
	else if (enemy_yaw >= -75)
		return FRAME_fired20;

	return 0;	// Knightmare- warning fix
}

const float	VARIANCE = 15.0;

static void(entity self) WidowBlaster =
{
	if (!self.enemy)
		return;

	shotsfired++;
	
	int effect = !(shotsfired % 4) ? EF_BLASTER : 0;

	vector forward, right;
	AngleVectors (self.s.angles, &forward, &right, 0);

	if ((self.s.frame >= FRAME_spawn05) && (self.s.frame <= FRAME_spawn13))
	{
		// sweep
		int flashnum = MZ2_WIDOW_BLASTER_SWEEP1 + self.s.frame - FRAME_spawn05;
		vector start = G_ProjectSource (self.s.origin, monster_flash_offset[flashnum], forward, right);
		vector target = self.enemy.s.origin - start;
		vector targ_angles = vectoangles (target);
		
		vector vec = self.s.angles;
		vec[PITCH] += targ_angles[PITCH];
		vec[YAW] -= sweep_angles[flashnum-MZ2_WIDOW_BLASTER_SWEEP1];

		AngleVectors (vec, &forward, 0, 0);
		monster_fire_blaster2 (self, start, forward, BLASTER2_DAMAGE*widow_damage_multiplier, 1000, flashnum, effect);
	}
	else if ((self.s.frame >= FRAME_fired02a) && (self.s.frame <= FRAME_fired20))
	{
		self.monsterinfo.aiflags |= AI_MANUAL_STEERING;

		self.monsterinfo.nextframe = WidowTorso (self);

		if (!self.monsterinfo.nextframe)
			self.monsterinfo.nextframe = self.s.frame;

		int flashnum;

		if (self.s.frame == FRAME_fired02a)
			flashnum = MZ2_WIDOW_BLASTER_0;
		else
			flashnum = MZ2_WIDOW_BLASTER_100 + self.s.frame - FRAME_fired03;

		vector start = G_ProjectSource (self.s.origin, monster_flash_offset[flashnum], forward, right);

		PredictAim (self.enemy, start, 1000, true, (random(0.1) - 0.05), &forward, 0);

		// clamp it to within 10 degrees of the aiming angle (where she's facing)
		vector angles = vectoangles (forward);
		// give me 100 . -70
		float aim_angle = 100f - (10*(flashnum-MZ2_WIDOW_BLASTER_100));
		if (aim_angle <= 0)
			aim_angle += 360;
		float target_angle = self.s.angles[YAW] - angles[YAW];
		if (target_angle <= 0)
			target_angle += 360;

		float error = aim_angle - target_angle;

		if (error > VARIANCE)
		{
			angles[YAW] = (self.s.angles[YAW] - aim_angle) + VARIANCE;
			AngleVectors (angles, &forward, 0, 0);
		}
		else if (error < -VARIANCE)
		{
			angles[YAW] = (self.s.angles[YAW] - aim_angle) - VARIANCE;
			AngleVectors (angles, &forward, 0, 0);
		}

		monster_fire_blaster2 (self, start, forward, BLASTER2_DAMAGE*widow_damage_multiplier, 1000, flashnum, effect);
	}
	else if ((self.s.frame >= FRAME_run01) && (self.s.frame <= FRAME_run08))
	{
		int flashnum = MZ2_WIDOW_RUN_1 + self.s.frame - FRAME_run01;
		vector start = G_ProjectSource (self.s.origin, monster_flash_offset[flashnum], forward, right);
		
		vector target = self.enemy.s.origin - start;
		target[2] += self.enemy.viewheight;

		monster_fire_blaster2 (self, start, target, BLASTER2_DAMAGE*widow_damage_multiplier, 1000, flashnum, effect);
	}
}	

static void(entity self) WidowSpawn =
{
	vector f, r, u;
	AngleVectors (self.s.angles, &f, &r, &u);

	for (int i = 0; i < 2; i++)
	{
		vector offset = spawnpoints[i];
		vector startpoint = G_ProjectSource2 (self.s.origin, offset, f, r, u);
		vector spawnpoint;

		if (!FindSpawnPoint (startpoint, stalker_mins, stalker_maxs, &spawnpoint, 64))
			continue;

		entity ent = CreateGroundMonster (spawnpoint, self.s.angles, stalker_mins, stalker_maxs, "monster_stalker", 256);

		if (!ent)
			continue;
		
		self.monsterinfo.monster_used++;
		ent.monsterinfo.commander = self;

		ent.nextthink = level.framenum;
		ent.think (ent);
		
		ent.monsterinfo.aiflags |= AI_SPAWNED_WIDOW|AI_DO_NOT_COUNT|AI_IGNORE_SHOTS;

		entity designated_enemy;

		if (!coop.intVal)
			designated_enemy = self.enemy;
		else if ((designated_enemy = PickCoopTarget(ent)))
		{
			// try to avoid using my enemy
			if (designated_enemy == self.enemy)
				if (!(designated_enemy = PickCoopTarget(ent)))
					designated_enemy = self.enemy;
		}
		else
			designated_enemy = self.enemy;

		if ((designated_enemy.inuse) && (designated_enemy.health > 0))
		{
			ent.enemy = designated_enemy;
			FoundTarget(ent);
			ent.monsterinfo.attack(ent);
		}
	}
}

static void(entity self) widow_spawn_check =
{
	WidowBlaster(self);
	WidowSpawn(self);
}

static void(entity self) widow_ready_spawn =
{
	WidowBlaster(self);

	vector f, r, u;
	AngleVectors (self.s.angles, &f, &r, &u);

	for (int i = 0; i < 2; i++)
	{
		vector offset = spawnpoints[i];
		vector startpoint = G_ProjectSource2 (self.s.origin, offset, f, r, u);
		vector spawnpoint;

		if (FindSpawnPoint(startpoint, stalker_mins, stalker_maxs, &spawnpoint, 64))
			SpawnGrow_Spawn(spawnpoint, 1);
	}
}

static void(entity self) widow_step =
{
	gi.sound (self, CHAN_BODY, gi.soundindex("widow/bwstep3.wav"), 1, ATTN_NORM, 0);
}

static mframe_t widow_frames_stand [] =
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
	{ ai_stand }
};
static var mmove_t widow_move_stand = { FRAME_idle01, FRAME_idle11 };

static mframe_t widow_frames_walk [] =
{
	{ ai_walk,	2.79,	widow_step },
	{ ai_walk,	2.77 },
	{ ai_walk,	3.53 },
	{ ai_walk,	3.97 },
	{ ai_walk,	4.13 },			//5
	{ ai_walk,	4.09 },
	{ ai_walk,	3.84 },
	{ ai_walk,	3.62,	widow_step },
	{ ai_walk,	3.29 },
	{ ai_walk,	6.08 },			//10
	{ ai_walk,	6.94 },
	{ ai_walk,	5.73 },
	{ ai_walk,	2.85 }
};
static var mmove_t widow_move_walk = { FRAME_walk01, FRAME_walk13 };

static mframe_t widow_frames_run [] =
{
	{ ai_run,	2.79,	widow_step },
	{ ai_run,	2.77 },
	{ ai_run,	3.53 },
	{ ai_run,	3.97 },
	{ ai_run,	4.13 },			//5
	{ ai_run,	4.09 },
	{ ai_run,	3.84 },
	{ ai_run,	3.62,	widow_step },
	{ ai_run,	3.29 },
	{ ai_run,	6.08 },			//10
	{ ai_run,	6.94 },
	{ ai_run,	5.73 },
	{ ai_run,	2.85 }
};
static var mmove_t widow_move_run = { FRAME_walk01, FRAME_walk13 };

static void(entity self) widow_stepshoot =
{
	gi.sound (self, CHAN_BODY, gi.soundindex("widow/bwstep2.wav"), 1, ATTN_NORM,0);
	WidowBlaster (self);
}

static mframe_t widow_frames_run_attack [] =
{
	{ ai_charge,	13,	widow_stepshoot },
	{ ai_charge,	11.72,	WidowBlaster },
	{ ai_charge,	18.04,	WidowBlaster },
	{ ai_charge,	14.58,	WidowBlaster },
	{ ai_charge,	13,	widow_stepshoot },			//5
	{ ai_charge,	12.12,	WidowBlaster },
	{ ai_charge,	19.63,	WidowBlaster },
	{ ai_charge,	11.37,	WidowBlaster }
};
static var mmove_t widow_move_run_attack = { FRAME_run01, FRAME_run08 };

//
// These three allow specific entry into the run sequence
//

static void(entity self) widow_start_run_5 =
{
	self.monsterinfo.currentmove = &widow_move_run;
	self.monsterinfo.nextframe = FRAME_walk05;
}

static void(entity self) widow_start_run_10 =
{
	self.monsterinfo.currentmove = &widow_move_run;
	self.monsterinfo.nextframe = FRAME_walk10;
}

static void(entity self) widow_start_run_12 =
{
	self.monsterinfo.currentmove = &widow_move_run;
	self.monsterinfo.nextframe = FRAME_walk12;
}

static var mmove_t widow_move_attack_blaster = { FRAME_fired02a, FRAME_fired20 };

static void(entity self) widow_attack_blaster =
{
	self.monsterinfo.pause_framenum = level.framenum + (int)(random(1.0, 3.0) * BASE_FRAMERATE);
	self.monsterinfo.currentmove = &widow_move_attack_blaster;
	self.monsterinfo.nextframe = WidowTorso (self);
}

static mframe_t widow_frames_attack_pre_blaster [] =
{
	{ ai_charge },
	{ ai_charge },
	{ ai_charge,	0,	widow_attack_blaster }
};
static var mmove_t widow_move_attack_pre_blaster = { FRAME_fired01, FRAME_fired02a };
static var mmove_t widow_move_attack_post_blaster = { FRAME_fired21, FRAME_fired22 };

static void(entity self) widow_reattack_blaster =
{
	WidowBlaster(self);

	// if WidowBlaster bailed us out of the frames, just bail
	if ((self.monsterinfo.currentmove == &widow_move_attack_post_blaster_l) ||
		(self.monsterinfo.currentmove == &widow_move_attack_post_blaster_r))
		return;

	// if we're not done with the attack, don't leave the sequence
	if (self.monsterinfo.pause_framenum >= level.framenum)
		return;

	self.monsterinfo.aiflags &= ~AI_MANUAL_STEERING;
	self.monsterinfo.currentmove = &widow_move_attack_post_blaster;
}

// Loop this
static mframe_t widow_frames_attack_blaster [] =
{
	{ ai_charge,	0,	widow_reattack_blaster },		// straight ahead
	{ ai_charge,	0,	widow_reattack_blaster },		// 100 degrees right
	{ ai_charge,	0,	widow_reattack_blaster },
	{ ai_charge,	0,	widow_reattack_blaster },
	{ ai_charge,	0,	widow_reattack_blaster },
	{ ai_charge,	0,	widow_reattack_blaster },
	{ ai_charge,	0,	widow_reattack_blaster },		// 50 degrees right
	{ ai_charge,	0,	widow_reattack_blaster },
	{ ai_charge,	0,	widow_reattack_blaster },
	{ ai_charge,	0,	widow_reattack_blaster },
	{ ai_charge,	0,	widow_reattack_blaster },
	{ ai_charge,	0,	widow_reattack_blaster },		// straight
	{ ai_charge,	0,	widow_reattack_blaster },
	{ ai_charge,	0,	widow_reattack_blaster },
	{ ai_charge,	0,	widow_reattack_blaster },
	{ ai_charge,	0,	widow_reattack_blaster },
	{ ai_charge,	0,	widow_reattack_blaster },		// 50 degrees left
	{ ai_charge,	0,	widow_reattack_blaster },
	{ ai_charge,	0,	widow_reattack_blaster }		// 70 degrees left
};

static mframe_t widow_frames_attack_post_blaster [] =
{
	{ ai_charge },
	{ ai_charge }
};

static mframe_t widow_frames_attack_post_blaster_r [] =
{
	{ ai_charge,	-2 },
	{ ai_charge,	-10 },
	{ ai_charge,	-2 },
	{ ai_charge },
	{ ai_charge,	0,	widow_start_run_12 }
};

static mframe_t widow_frames_attack_post_blaster_l [] =
{
	{ ai_charge },
	{ ai_charge,	14 },
	{ ai_charge,	-2 },
	{ ai_charge,	10 },
	{ ai_charge,	10,	widow_start_run_12 }
};

static var mmove_t widow_move_attack_rail = { FRAME_firea01, FRAME_firea09 };
static var mmove_t widow_move_attack_rail_r = { FRAME_fireb01, FRAME_fireb09 };
static var mmove_t widow_move_attack_rail_l = { FRAME_firec01, FRAME_firec09 };

static void(entity self) WidowRail =
{
	vector forward, right;
	AngleVectors (self.s.angles, &forward, &right, 0);

	int	flash;

	if (self.monsterinfo.currentmove == &widow_move_attack_rail_l)
		flash = MZ2_WIDOW_RAIL_LEFT;
	else if (self.monsterinfo.currentmove == &widow_move_attack_rail_r)
		flash = MZ2_WIDOW_RAIL_RIGHT;
	else
		flash = MZ2_WIDOW_RAIL;

	vector start = G_ProjectSource (self.s.origin, monster_flash_offset[flash], forward, right);

	// calc direction to where we targeted
	vector dir = self.pos1 - start;
	VectorNormalize (dir);

	monster_fire_railgun (self, start, dir, WIDOW_RAIL_DAMAGE*widow_damage_multiplier, 100, flash);
	self.timestamp = level.framenum + (int)(RAIL_TIME * BASE_FRAMERATE);
}

static void(entity self) WidowSaveLoc =
{
	self.pos1 = self.enemy.s.origin;	//save for aiming the shot
	self.pos1[2] += self.enemy.viewheight;
}

static void(entity self) widow_start_rail =
{
	self.monsterinfo.aiflags |= AI_MANUAL_STEERING;
}

static void(entity self) widow_rail_done =
{
	self.monsterinfo.aiflags &= ~AI_MANUAL_STEERING;
}

static void(entity self) widow_attack_rail =
{
	float enemy_angle = target_angle (self);

	if (enemy_angle < -15)
		self.monsterinfo.currentmove = &widow_move_attack_rail_l;
	else if (enemy_angle > 15)
		self.monsterinfo.currentmove = &widow_move_attack_rail_r;
	else
		self.monsterinfo.currentmove = &widow_move_attack_rail;
}

static mframe_t widow_frames_attack_pre_rail [] =
{
	{ ai_charge,	0,	widow_start_rail },
	{ ai_charge },
	{ ai_charge },
	{ ai_charge,	0,	widow_attack_rail }
};
static var mmove_t widow_move_attack_pre_rail = { FRAME_transc01, FRAME_transc04 };

static mframe_t widow_frames_attack_rail [] =
{
	{ ai_charge },
	{ ai_charge },
	{ ai_charge, 0, WidowSaveLoc },
	{ ai_charge, -10, WidowRail },
	{ ai_charge },
	{ ai_charge },
	{ ai_charge },
	{ ai_charge },
	{ ai_charge, 0, widow_rail_done }
};

static mframe_t widow_frames_attack_rail_r [] =
{
	{ ai_charge },
	{ ai_charge },
	{ ai_charge, 0, WidowSaveLoc },
	{ ai_charge, -10, WidowRail },
	{ ai_charge },
	{ ai_charge },
	{ ai_charge },
	{ ai_charge },
	{ ai_charge, 0, widow_rail_done }
};

static mframe_t widow_frames_attack_rail_l [] =
{
	{ ai_charge },
	{ ai_charge },
	{ ai_charge, 0, WidowSaveLoc },
	{ ai_charge, -10, WidowRail },
	{ ai_charge },
	{ ai_charge },
	{ ai_charge },
	{ ai_charge },
	{ ai_charge, 0, widow_rail_done }
};

void(entity self) widow_start_spawn =
{
	self.monsterinfo.aiflags |= AI_MANUAL_STEERING;
}

void(entity self) widow_done_spawn =
{
	self.monsterinfo.aiflags &= ~AI_MANUAL_STEERING;
}

static mframe_t widow_frames_spawn [] =
{
	{ ai_charge },						//1
	{ ai_charge },
	{ ai_charge },
	{ ai_charge,	0,	widow_start_spawn },
	{ ai_charge },						//5
	{ ai_charge,	0,	WidowBlaster },				//6
	{ ai_charge,	0,	widow_ready_spawn },			//7
	{ ai_charge,	0,	WidowBlaster },
	{ ai_charge,	0,	WidowBlaster },				//9
	{ ai_charge,	0,	widow_spawn_check },
	{ ai_charge,	0,	WidowBlaster },				//11
	{ ai_charge,	0,	WidowBlaster },
	{ ai_charge,	0,	WidowBlaster },				//13
	{ ai_charge },
	{ ai_charge },
	{ ai_charge },
	{ ai_charge },
	{ ai_charge,	0,	widow_done_spawn }
};
static var mmove_t widow_move_spawn = { FRAME_spawn01, FRAME_spawn18 };

static mframe_t widow_frames_pain_heavy [] =
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
	{ ai_move }
};
static var mmove_t widow_move_pain_heavy = { FRAME_pain01, FRAME_pain13 };

static mframe_t widow_frames_pain_light [] =
{
	{ ai_move },
	{ ai_move },
	{ ai_move }
};
static var mmove_t widow_move_pain_light = { FRAME_pain201, FRAME_pain203 };

static void(entity self) spawn_out_start =
{
	self.wait = level.framenum + (2.0 * BASE_FRAMERATE);

	vector f, r, u;
	AngleVectors (self.s.angles, &f, &r, &u);

	vector startpoint = G_ProjectSource2 (self.s.origin, beameffects[0], f, r, u);
	gi.WriteByte (svc_temp_entity);
	gi.WriteByte (TE_WIDOWBEAMOUT);
	gi.WriteShort (20001);
	gi.WritePosition (startpoint);
	gi.multicast (startpoint, MULTICAST_ALL);

	startpoint = G_ProjectSource2 (self.s.origin, beameffects[1], f, r, u);
	gi.WriteByte (svc_temp_entity);
	gi.WriteByte (TE_WIDOWBEAMOUT);
	gi.WriteShort (20002);
	gi.WritePosition (startpoint);
	gi.multicast (startpoint, MULTICAST_ALL);

	gi.sound (self, CHAN_VOICE, gi.soundindex ("misc/bwidowbeamout.wav"), 1, ATTN_NORM, 0);
}

static void(entity self) spawn_out_do =
{
	vector f, r, u;
	AngleVectors (self.s.angles, &f, &r, &u);

	vector startpoint = G_ProjectSource2 (self.s.origin, beameffects[0], f, r, u);
	gi.WriteByte (svc_temp_entity);
	gi.WriteByte (TE_WIDOWSPLASH);
	gi.WritePosition (startpoint);
	gi.multicast (startpoint, MULTICAST_ALL);

	startpoint = G_ProjectSource2 (self.s.origin, beameffects[1], f, r, u);
	gi.WriteByte (svc_temp_entity);
	gi.WriteByte (TE_WIDOWSPLASH);
	gi.WritePosition (startpoint);
	gi.multicast (startpoint, MULTICAST_ALL);

	startpoint = self.s.origin;
	startpoint[2] += 36;
	gi.WriteByte (svc_temp_entity);
	gi.WriteByte (TE_BOSSTPORT);
	gi.WritePosition (startpoint);
	gi.multicast (startpoint, MULTICAST_PVS);

	Widowlegs_Spawn (self.s.origin, self.s.angles);
	G_FreeEdict (self);
}

static mframe_t widow_frames_death [] =
{
	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move },		//5
	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move,	0,	spawn_out_start },	//10
	{ ai_move },		
	{ ai_move },		
	{ ai_move },		
	{ ai_move },		
	{ ai_move },				//15	
	{ ai_move },		
	{ ai_move },		
	{ ai_move },		
	{ ai_move },		
	{ ai_move },				//20	
	{ ai_move },		
	{ ai_move },		
	{ ai_move },		
	{ ai_move },		
	{ ai_move },				//25
	{ ai_move },		
	{ ai_move },		
	{ ai_move },		
	{ ai_move },		
	{ ai_move },				//30	
	{ ai_move,	0,	spawn_out_do }
};
static var mmove_t widow_move_death = { FRAME_death01, FRAME_death31 };

static void(entity self) widow_attack_kick =
{
	static const vector aim = '100 0 4';

	if (self.enemy.groundentity != null_entity)
		fire_hit (self, aim, (50 + (Q_rand() % 6)), 500);
	else	// not as much kick if they're in the air .. makes it harder to land on her head
		fire_hit (self, aim, (50 + (Q_rand() % 6)), 250);
}

static mframe_t widow_frames_attack_kick [] =
{
	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move, 0, widow_attack_kick },
	{ ai_move },				// 5
	{ ai_move },
	{ ai_move },
	{ ai_move }
};
static var mmove_t widow_move_attack_kick = { FRAME_kick01, FRAME_kick08 };

static void(entity self) widow_stand =
{
	gi.sound (self, CHAN_WEAPON, gi.soundindex ("widow/laugh.wav"), 1, ATTN_NORM, 0);
	self.monsterinfo.currentmove = &widow_move_stand;
}

static void(entity self) widow_run =
{
	self.monsterinfo.aiflags &= ~AI_HOLD_FRAME;

	if (self.monsterinfo.aiflags & AI_STAND_GROUND)
		self.monsterinfo.currentmove = &widow_move_stand;
	else
		self.monsterinfo.currentmove = &widow_move_run;
}

static void(entity self) widow_walk =
{
	self.monsterinfo.currentmove = &widow_move_walk;
}

void(entity self) WidowCalcSlots =
{
	int old_slots = self.monsterinfo.monster_slots;

	switch (skill.intVal)
	{
		case 0:
		case 1:
		default:
			self.monsterinfo.monster_slots = 3;
			break;
		case 2:
			self.monsterinfo.monster_slots = 4;
			break;
		case 3:
			self.monsterinfo.monster_slots = 6;
			break;
	}

	if (coop.intVal)
		self.monsterinfo.monster_slots = mini(6, self.monsterinfo.monster_slots + (skill.intVal * (CountPlayers() - 1)));
}

static void(entity self) widow_attack =
{
	self.movetarget = 0;

	bool rail_frames = false, blaster_frames = false, blocked = false, anger = false;

	if (self.monsterinfo.aiflags & AI_BLOCKED)
	{
		blocked = true;
		self.monsterinfo.aiflags &= ~AI_BLOCKED;
	}
	
	if (self.monsterinfo.aiflags & AI_TARGET_ANGER)
	{
		anger = true;
		self.monsterinfo.aiflags &= ~AI_TARGET_ANGER;
	}

	if ((!self.enemy) || (!self.enemy.inuse))
		return;

	if (self.bad_area)
	{
		if ((random() < 0.1) || (level.framenum < self.timestamp))
			self.monsterinfo.currentmove = &widow_move_attack_pre_blaster;
		else
		{
			gi.sound (self, CHAN_WEAPON, sound_rail, 1, ATTN_NORM, 0);
			self.monsterinfo.currentmove = &widow_move_attack_pre_rail;
		}
		return;
	}

	if ((self.s.frame == FRAME_walk13) || ((self.s.frame >= FRAME_walk01) && (self.s.frame <= FRAME_walk03)))
		rail_frames = true;

	if ((self.s.frame >= FRAME_walk09) && (self.s.frame <= FRAME_walk12))
		blaster_frames = true;

	WidowCalcSlots(self);

	// if we can't see the target, spawn stuff regardless of frame
	if ((self.monsterinfo.attack_state == AS_BLIND) && (SELF_SLOTS_LEFT(self) >= 2))
	{
		self.monsterinfo.currentmove = &widow_move_spawn;
		return;
	}

	// accept bias towards spawning regardless of frame
	if (blocked && (SELF_SLOTS_LEFT(self) >= 2))
	{
		self.monsterinfo.currentmove = &widow_move_spawn;
		return;
	}

	if ((realrange(self, self.enemy) > 300) && (!anger) && (random() < 0.5)  && (!blocked))
	{
		self.monsterinfo.currentmove = &widow_move_run_attack;
		return;
	}

	if (blaster_frames)
	{
		if (SELF_SLOTS_LEFT(self) >= 2)
		{
			self.monsterinfo.currentmove = &widow_move_spawn;
			return;
		}
		else if (self.monsterinfo.pause_framenum + (int)(BLASTER_TIME * BASE_FRAMERATE) <= level.framenum)
		{
			self.monsterinfo.currentmove = &widow_move_attack_pre_blaster;
			return;
		}
	}

	if (rail_frames)
	{
		if (!(level.framenum < self.timestamp))
		{
			gi.sound (self, CHAN_WEAPON, sound_rail, 1, ATTN_NORM, 0);
			self.monsterinfo.currentmove = &widow_move_attack_pre_rail;
		}
	}

	if ((rail_frames) || (blaster_frames))
		return;

	float luck = random();

	if (SELF_SLOTS_LEFT(self) >= 2)
	{
		if ((luck <= 0.40) && (self.monsterinfo.pause_framenum + (int)(BLASTER_TIME * BASE_FRAMERATE) <= level.framenum))
			self.monsterinfo.currentmove = &widow_move_attack_pre_blaster;
		else if ((luck <= 0.7) && !(level.framenum < self.timestamp))
		{
			gi.sound (self, CHAN_WEAPON, sound_rail, 1, ATTN_NORM, 0);
			self.monsterinfo.currentmove = &widow_move_attack_pre_rail;
		}
		else
			self.monsterinfo.currentmove = &widow_move_spawn;
	}
	else if (level.framenum < self.timestamp)
		self.monsterinfo.currentmove = &widow_move_attack_pre_blaster;
	else if ((luck <= 0.50) || (level.framenum + (int)(BLASTER_TIME * BASE_FRAMERATE) >= self.monsterinfo.pause_framenum))
	{
		gi.sound (self, CHAN_WEAPON, sound_rail, 1, ATTN_NORM, 0);
		self.monsterinfo.currentmove = &widow_move_attack_pre_rail;
	}
	else // holdout to blaster
		self.monsterinfo.currentmove = &widow_move_attack_pre_blaster;
}

static void(entity self, entity other, float kick, int damage) widow_pain =
{
	if (self.health < (self.max_health / 2))
		self.s.skinnum = 1;

	if (skill.intVal == 3)
		return;		// no pain anims in nightmare

	if (level.framenum < self.pain_debounce_framenum)
		return;

	if (self.monsterinfo.pause_framenum == INT_MAX)
		self.monsterinfo.pause_framenum = 0;

	self.pain_debounce_framenum = level.framenum + (5 * BASE_FRAMERATE);

	if (damage < 15)
		gi.sound (self, CHAN_VOICE, sound_pain1, 1, ATTN_NONE, 0);
	else if (damage < 75)
	{
		if ((skill.intVal < 3) && (random() < (0.6 - (0.2*skill.intVal))))
		{
			self.monsterinfo.currentmove = &widow_move_pain_light;
			self.monsterinfo.aiflags &= ~AI_MANUAL_STEERING;
		}
		gi.sound (self, CHAN_VOICE, sound_pain2, 1, ATTN_NONE, 0);
	}
	else 
	{
		if ((skill.intVal < 3) && (random() < (0.75 - (0.1*skill.intVal))))
		{
			self.monsterinfo.currentmove = &widow_move_pain_heavy;
			self.monsterinfo.aiflags &= ~AI_MANUAL_STEERING;
		}
		gi.sound (self, CHAN_VOICE, sound_pain3, 1, ATTN_NONE, 0);
	}
}

static void(entity self) widow_dead =
{
	self.mins = '-56 -56 0';
	self.maxs = '56 56 80';
	self.movetype = MOVETYPE_TOSS;
	self.svflags |= SVF_DEADMONSTER;
	self.nextthink = 0;
	gi.linkentity (self);
}

static void(entity self, entity inflictor, entity attacker, int damage, vector point) widow_die =
{
	self.deadflag = DEAD_DEAD;
	self.takedamage = false;
	self.count = 0;
	self.monsterinfo.quad_framenum = 0;
	self.monsterinfo.double_framenum = 0;
	self.monsterinfo.invincible_framenum = 0;
	self.monsterinfo.currentmove = &widow_move_death;
}

static void(entity self) widow_melee =
{
	self.monsterinfo.currentmove = &widow_move_attack_kick;
}

static inline void(entity self, int framenum) WidowGoinQuad =
{
	self.monsterinfo.quad_framenum = framenum;
	widow_damage_multiplier = 4;
}

static inline void(entity self, int framenum) WidowDouble =
{
	self.monsterinfo.double_framenum = framenum;
	widow_damage_multiplier = 2;
}

static inline void(entity self, int framenum) WidowPent =
{
	self.monsterinfo.invincible_framenum = framenum;
}

static INLINE void(entity self) WidowPowerArmor =
{
	self.monsterinfo.power_armor_type = POWER_ARMOR_SHIELD;

	// I don't like this, but it works
	if (self.monsterinfo.power_armor_power <= 0)
		self.monsterinfo.power_armor_power += 250 * skill.intVal;
}

static void(entity self, entity other) WidowRespondPowerup =
{
	if (other.s.effects & EF_QUAD)
	{
		if (skill.intVal == 1)
			WidowDouble (self, other.client.quad_framenum);
		else if (skill.intVal == 2)
			WidowGoinQuad (self, other.client.quad_framenum);
		else if (skill.intVal == 3)
		{
			WidowGoinQuad (self, other.client.quad_framenum);
			WidowPowerArmor (self);
		}
	}
	else if (other.s.effects & EF_DOUBLE)
	{
		if (skill.intVal == 2)
			WidowDouble (self, other.client.double_framenum);
		else if (skill.intVal == 3)
		{
			WidowDouble (self, other.client.double_framenum);
			WidowPowerArmor (self);
		}
	}
	else
		widow_damage_multiplier = 1;

	if (other.s.effects & EF_PENT)
	{
		if (skill.intVal == 1)
			WidowPowerArmor (self);
		else if (skill.intVal == 2)
			WidowPent (self, other.client.invincible_framenum);
		else if (skill.intVal == 3)
		{
			WidowPent (self, other.client.invincible_framenum);
			WidowPowerArmor (self);
		}
	}
}

void(entity self) WidowPowerups =
{
	if (!coop.intVal)
	{
		WidowRespondPowerup (self, self.enemy);
		return;
	}

	// in coop, check for pents, then quads, then doubles
	entity best = world;
	
	for (int player = 1; player <= game.maxclients; player++)
	{
		entity ent = itoe(player);
		if (!ent.inuse)
			continue;
		if (!ent.is_client)
			continue;
		if (ent.s.effects & EF_PENT)
		{
			best = ent;
			break;
		}
		else if (ent.s.effects & EF_QUAD)
		{
			if (!best || (best.s.effects & EF_DOUBLE))
				best = ent;
		}
		else if (ent.s.effects & EF_DOUBLE)
		{
			if (!best)
				best = ent;
		}
	}

	if (best)
		WidowRespondPowerup (self, best);
}

static bool(entity self) Widow_CheckAttack =
{
	if (!self.enemy)
		return false;

	WidowPowerups(self);

	if (self.monsterinfo.currentmove == &widow_move_run)
	{
		// if we're in run, make sure we're in a good frame for attacking before doing anything else
		// frames 1,2,3,9,10,11,13 good to fire
		switch (self.s.frame)
		{
			case FRAME_walk04:
			case FRAME_walk05:
			case FRAME_walk06:
			case FRAME_walk07:
			case FRAME_walk08:
			case FRAME_walk12:
					return false;
			default:
				break;
		}
	}

	// give a LARGE bias to spawning things when we have room
	// use AI_BLOCKED as a signal to attack to spawn
	if ((random() < 0.8) && (SELF_SLOTS_LEFT(self) >= 2) && (realrange(self, self.enemy) > 150))
	{
		self.monsterinfo.aiflags |= AI_BLOCKED;
		self.monsterinfo.attack_state = AS_MISSILE;
		return true;
	}

	if (self.enemy.health > 0)
	{
	// see if any entities are in the way of the shot
		vector spot1 = self.s.origin;
		spot1[2] += self.viewheight;
		vector spot2 = self.enemy.s.origin;
		spot2[2] += self.enemy.viewheight;

		trace_t	tr;
		gi.traceline(&tr, spot1, spot2, self, CONTENTS_SOLID|CONTENTS_MONSTER|CONTENTS_SLIME|CONTENTS_LAVA);

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
	
	bool enemy_infront = infront(self, self.enemy);

	range_t enemy_range = range(self, self.enemy);
	vector temp = self.enemy.s.origin - self.s.origin;
	float enemy_yaw = vectoyaw(temp);

	self.ideal_yaw = enemy_yaw;

	float real_enemy_range = realrange (self, self.enemy);

	if (real_enemy_range <= (MELEE_DISTANCE+20))
	{
		// don't always melee in easy mode
		if (skill.intVal == 0 && (Q_rand()&3) )
			return false;
		if (self.monsterinfo.melee)
			self.monsterinfo.attack_state = AS_MELEE;
		else
			self.monsterinfo.attack_state = AS_MISSILE;
		return true;
	}

	if (level.framenum < self.monsterinfo.attack_finished)
		return false;

	float chance;
		
	if (self.monsterinfo.aiflags & AI_STAND_GROUND)
		chance = 0.4;
	else if (enemy_range == RANGE_MELEE)
		chance = 0.8;
	else if (enemy_range == RANGE_NEAR)
		chance = 0.7;
	else if (enemy_range == RANGE_MID)
		chance = 0.6;
	else
		chance = 0.5;

	// PGM - go ahead and shoot every time if it's a info_notnull
	if ((random() < chance) || (self.enemy.solid == SOLID_NOT))
	{
		self.monsterinfo.attack_state = AS_MISSILE;
		return true;
	}

	return false;
}

static bool(entity self, float dist) widow_blocked =
{
	// if we get blocked while we're in our run/attack mode, turn on a meaningless (in this context)AI flag, 
	// and call attack to get a new attack sequence.  make sure to turn it off when we're done.
	//
	// I'm using AI_TARGET_ANGER for this purpose

	if (self.monsterinfo.currentmove == &widow_move_run_attack)
	{
		self.monsterinfo.aiflags |= AI_TARGET_ANGER;

		if (self.monsterinfo.checkattack(self))
			self.monsterinfo.attack(self);
		else
			self.monsterinfo.run(self);

		return true;
	}

	return blocked_checkshot (self, 0.25 + (0.05 * skill.intVal));
}

static void() WidowPrecache =
{
	// cache in all of the stalker stuff, widow stuff, spawngro stuff, gibs
	gi.soundindex ("stalker/pain.wav");	
	gi.soundindex ("stalker/death.wav");	
	gi.soundindex ("stalker/sight.wav");
	gi.soundindex ("stalker/melee1.wav");
	gi.soundindex ("stalker/melee2.wav");
	gi.soundindex ("stalker/idle.wav");

	gi.soundindex ("tank/tnkatck3.wav");
	gi.modelindex ("models/proj/laser2/tris.md2");

	gi.modelindex ("models/monsters/stalker/tris.md2");
	gi.modelindex ("models/items/spawngro2/tris.md2");
	gi.modelindex ("models/objects/gibs/sm_metal/tris.md2");
	gi.modelindex ("models/objects/gibs/gear/tris.md2");
	gi.modelindex ("models/monsters/blackwidow/gib1/tris.md2");
	gi.modelindex ("models/monsters/blackwidow/gib2/tris.md2");
	gi.modelindex ("models/monsters/blackwidow/gib3/tris.md2");
	gi.modelindex ("models/monsters/blackwidow/gib4/tris.md2");
	gi.modelindex ("models/monsters/blackwidow2/gib1/tris.md2");
	gi.modelindex ("models/monsters/blackwidow2/gib2/tris.md2");
	gi.modelindex ("models/monsters/blackwidow2/gib3/tris.md2");
	gi.modelindex ("models/monsters/blackwidow2/gib4/tris.md2");
	gi.modelindex ("models/monsters/legs/tris.md2");
	gi.soundindex ("misc/bwidowbeamout.wav");

	gi.soundindex ("misc/bigtele.wav");
	gi.soundindex ("widow/bwstep3.wav");
	gi.soundindex ("widow/bwstep2.wav");

	if (!widow_move_stand.frame)
	{
		widow_move_stand.frame = &widow_frames_stand;
		widow_move_walk.frame = &widow_frames_walk;
		widow_move_run.frame = &widow_frames_run;
		widow_move_run_attack.frame = &widow_frames_run;
		widow_move_run_attack.endfunc = widow_run;
		widow_move_attack_pre_blaster.frame = &widow_frames_attack_pre_blaster;
		widow_move_attack_blaster.frame = &widow_frames_attack_blaster;
		widow_move_attack_post_blaster.frame = &widow_frames_attack_post_blaster;
		widow_move_attack_post_blaster.endfunc = widow_run;
		widow_move_attack_post_blaster_r.frame = &widow_frames_attack_post_blaster_r;
		widow_move_attack_post_blaster_l.frame = &widow_frames_attack_post_blaster_l;
		widow_move_attack_pre_rail.frame = &widow_frames_attack_pre_rail;
		widow_move_attack_rail.frame = &widow_frames_attack_rail;
		widow_move_attack_rail.endfunc = widow_run;
		widow_move_attack_rail_r.frame = &widow_frames_attack_rail_r;
		widow_move_attack_rail_r.endfunc = widow_run;
		widow_move_attack_rail_l.frame = &widow_frames_attack_rail_l;
		widow_move_attack_rail_l.endfunc = widow_run;
		widow_move_spawn.frame = &widow_frames_spawn;
		widow_move_spawn.endfunc = widow_run;
		widow_move_pain_heavy.frame = &widow_frames_pain_heavy;
		widow_move_pain_heavy.endfunc = widow_run;
		widow_move_pain_light.frame = &widow_frames_pain_light;
		widow_move_pain_light.endfunc = widow_run;
		widow_move_death.frame = &widow_frames_death;
		widow_move_attack_kick.frame = &widow_frames_attack_kick;
		widow_move_attack_kick.endfunc = widow_run;
	}
}

/*QUAKED monster_widow (1 .5 0) (-40 -40 0) (40 40 144) Ambush Trigger_Spawn Sight
*/
API_FUNC static void(entity self) SP_monster_widow =
{
	if (deathmatch.intVal)
	{
		G_FreeEdict (self);
		return;
	}

	sound_pain1 = gi.soundindex ("widow/bw1pain1.wav");
	sound_pain2 = gi.soundindex ("widow/bw1pain2.wav");
	sound_pain3 = gi.soundindex ("widow/bw1pain3.wav");
	sound_rail = gi.soundindex ("gladiator/railgun.wav");

	self.movetype = MOVETYPE_STEP;
	self.solid = SOLID_BBOX;
	self.s.modelindex = gi.modelindex ("models/monsters/blackwidow/tris.md2");
	self.mins = '-40 -40 0';
	self.maxs = '40 40 144';

	self.health = 2000 + 1000*(skill.intVal);
	if (coop.intVal)
		self.health += 500*(skill.intVal);
	self.gib_health = -5000;
	self.mass = 1500;

	if (skill.intVal == 3)
	{
		self.monsterinfo.power_armor_type = POWER_ARMOR_SHIELD;
		self.monsterinfo.power_armor_power = 500;
	}

	self.yaw_speed = 30f;
	
	self.flags |= FL_IMMUNE_LASER;
	self.monsterinfo.aiflags |= AI_IGNORE_SHOTS;

	self.pain = widow_pain;
	self.die = widow_die;

	self.monsterinfo.melee = widow_melee;
	self.monsterinfo.stand = widow_stand;
	self.monsterinfo.walk = widow_walk;
	self.monsterinfo.run = widow_run;
	self.monsterinfo.attack = widow_attack;
	self.monsterinfo.checkattack = Widow_CheckAttack;
	self.monsterinfo.sight = widow_sight;
	
	self.monsterinfo.blocked = widow_blocked;

	gi.linkentity (self);

	self.monsterinfo.currentmove = &widow_move_stand;	
	self.monsterinfo.scale = MODEL_SCALE;

	WidowPrecache();
	WidowCalcSlots(self);
	widow_damage_multiplier = 1;

	walkmonster_start (self);
}

#endif