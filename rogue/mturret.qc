#ifdef GROUND_ZERO

#include "m_turret.h"

const int SPAWN_BLASTER			= 0x0008;
const int SPAWN_MACHINEGUN		= 0x0010;
const int SPAWN_ROCKET			= 0x0020;
const int SPAWN_HEATBEAM		= 0x0040;
const int SPAWN_WEAPONCHOICE	= 0x0078;
const int SPAWN_INSTANT_WEAPON	= 0x0050;
const int SPAWN_WALL_UNIT		= 0x0080;

static var mmove_t turret_move_stand = { FRAME_stand01, FRAME_stand02 };
static var mmove_t turret_move_ready_gun = { FRAME_active01, FRAME_run01 };
static var mmove_t turret_move_fire_blind = { FRAME_pow01, FRAME_pow04 };
static var mmove_t turret_move_run = {FRAME_run01, FRAME_run02 };
static var mmove_t turret_move_seek = { FRAME_run01, FRAME_run02 };
static var mmove_t turret_move_fire = { FRAME_pow01, FRAME_pow04 };

static inline void(entity self) turret_ready_gun =
{
	self.monsterinfo.currentmove = &turret_move_ready_gun;
}

static void(entity self) TurretAim =
{
	if (!self.enemy && !FindTarget (self))
		return;

	// if turret is still in inactive mode, ready the gun, but don't aim
	if (self.s.frame < FRAME_active01)
	{
		turret_ready_gun(self);
		return;
	}

	// if turret is still readying, don't aim.
	if (self.s.frame < FRAME_run01)
		return;

	// PMM - blindfire aiming here
	vector end;

	if (self.monsterinfo.currentmove == &turret_move_fire_blind)
	{
		end = self.monsterinfo.blind_fire_target;
		if (self.enemy.s.origin[2] < self.monsterinfo.blind_fire_target[2])
			end[2] += self.enemy.viewheight + 10;
		else
			end[2] += self.enemy.mins[2] - 10;
	}
	else
	{
		end = self.enemy.s.origin;
		if (self.enemy.is_client)
			end[2] += self.enemy.viewheight;
	}

	vector dir = end - self.s.origin;
	vector ang = vectoangles(dir);

	//
	// Clamp first
	//
	float idealPitch = ang[PITCH];
	float idealYaw = ang[YAW];
	int orientation = (int)self.offset[1];

	switch (orientation)
	{
		case -1:			// up		pitch: 0 to 90
			if (idealPitch < -90)
				idealPitch += 360;
			if (idealPitch > -5)
				idealPitch = -5f;
			break;
		case -2:			// down		pitch: -180 to -360
			if (idealPitch > -90)
				idealPitch -= 360;
			if (idealPitch < -355)
				idealPitch = -355f;
			else if (idealPitch > -185)
				idealPitch = -185f;
			break;
		case 0:				// +X		pitch: 0 to -90, -270 to -360 (or 0 to 90)
			if (idealPitch < -180)
				idealPitch += 360;

			if (idealPitch > 85)
				idealPitch = 85f;
			else if (idealPitch < -85)
				idealPitch = -85f;

							//			yaw: 270 to 360, 0 to 90
							//			yaw: -90 to 90 (270-360 == -90-0)
			if (idealYaw > 180)
				idealYaw -= 360;
			if (idealYaw > 85)
				idealYaw = 85f;
			else if (idealYaw < -85)
				idealYaw = -85f;
			break;
		case 90:			// +Y	pitch: 0 to 90, -270 to -360 (or 0 to 90)
			if (idealPitch < -180)
				idealPitch += 360;

			if (idealPitch > 85)
				idealPitch = 85f;
			else if (idealPitch < -85)
				idealPitch = -85f;

							//			yaw: 0 to 180
			if (idealYaw > 270)
				idealYaw -= 360;
			if (idealYaw > 175)
				idealYaw = 175f;
			else if (idealYaw < 5)
				idealYaw = 5f;

			break;
		case 180:			// -X	pitch: 0 to 90, -270 to -360 (or 0 to 90)
			if (idealPitch < -180)
				idealPitch += 360;

			if (idealPitch > 85)
				idealPitch = 85f;
			else if (idealPitch < -85)
				idealPitch = -85f;

							//			yaw: 90 to 270
			if (idealYaw > 265)
				idealYaw = 265f;
			else if (idealYaw < 95)
				idealYaw = 95f;

			break;
		case 270:			// -Y	pitch: 0 to 90, -270 to -360 (or 0 to 90)
			if (idealPitch < -180)
				idealPitch += 360;

			if (idealPitch > 85)
				idealPitch = 85f;
			else if (idealPitch < -85)
				idealPitch = -85f;

							//			yaw: 180 to 360
			if (idealYaw < 90)
				idealYaw += 360;

			if (idealYaw > 355)
				idealYaw = 355f;
			else if (idealYaw < 185)
				idealYaw = 185f;

			break;
	}

	//
	// adjust pitch
	//
	float current = self.s.angles[PITCH];
	float speed = self.yaw_speed;

	if (idealPitch != current)
	{
		float move = idealPitch - current;

		while (move >= 360)
			move -= 360;
		if (move >= 90)
			move = move - 360;

		while (move <= -360)
			move += 360;
		if (move <= -90)
			move = move + 360;

		if (move > 0)
		{
			if (move > speed)
				move = speed;
		}
		else
		{
			if (move < -speed)
				move = -speed;
		}

		self.s.angles[PITCH] = anglemod(current + move);
	}

	//
	// adjust yaw
	//
	current = self.s.angles[YAW];
	speed = self.yaw_speed;

	if (idealYaw != current)
	{
		float move = idealYaw - current;

		if (move >= 180)
			move = move - 360;

		if (move <= -180)
			move = move + 360;

		if (move > 0)
		{
			if (move > speed)
				move = speed;
		}
		else
		{
			if (move < -speed)
				move = -speed;
		}

		self.s.angles[YAW] = anglemod(current + move);
	}

}

static mframe_t turret_frames_stand [] =
{
	{ ai_stand },
	{ ai_stand }
};

static void(entity self) turret_stand =
{
	self.monsterinfo.currentmove = &turret_move_stand;
}

static mframe_t turret_frames_ready_gun [] =
{
	{ ai_stand },
	{ ai_stand },
	{ ai_stand },

	{ ai_stand },
	{ ai_stand },
	{ ai_stand },
	
	{ ai_stand }
};

static mframe_t turret_frames_seek [] =
{
	{ ai_walk, 0, TurretAim },
	{ ai_walk, 0, TurretAim }
};

static void(entity self) turret_walk =
{
	if (self.s.frame < FRAME_run01)
		turret_ready_gun(self);
	else
		self.monsterinfo.currentmove = &turret_move_seek;
}

static mframe_t turret_frames_run [] =
{
	{ ai_run, 0, TurretAim },
	{ ai_run, 0, TurretAim }
};

static void(entity self) turret_run =
{
	if(self.s.frame < FRAME_run01)
		turret_ready_gun(self);
	else
		self.monsterinfo.currentmove = &turret_move_run;
}

// **********************
//  ATTACK
// **********************
const int TURRET_BULLET_DAMAGE	= 4;
const int TURRET_HEAT_DAMAGE	= 4;

static void(entity self) TurretFire =
{
	TurretAim(self);

	if(!self.enemy || !self.enemy.inuse)
		return;

	vector dir = self.enemy.s.origin - self.s.origin;
	VectorNormalize(dir);

	vector forward;
	AngleVectors(self.s.angles, &forward, 0, 0);

	float chance = dir * forward;

	if (chance < 0.98)
		return;

	chance = random();

	// rockets fire less often than the others do.
	int	rocketSpeed = 0;

	if (self.spawnflags & SPAWN_ROCKET)
	{
		chance *= 3;

		rocketSpeed = 550;
		if (skill.intVal == 2)
			rocketSpeed += (int)random(200f);
		else if (skill.intVal == 3)
			rocketSpeed += (int)random(100f, 300f);
	}
	else if (self.spawnflags & SPAWN_BLASTER)
	{
		if (skill.intVal == 0)
			rocketSpeed = 600;
		else if (skill.intVal == 1)
			rocketSpeed = 800;
		else
			rocketSpeed = 1000;
		chance *= 2;
	}
	
	// up the fire chance 20% per skill level.
	chance = chance - (0.2 * skill.intVal);

	if (visible(self, self.enemy))
	{
		vector start = self.s.origin;
		vector end = self.enemy.s.origin;
		
		// aim for the head.
		if (self.enemy && self.enemy.is_client)
			end[2] += self.enemy.viewheight;
		else
			end[2] += 22;

		vector dir = end - start;
		float dist = VectorLength(dir);
		
		// check for predictive fire if distance less than 512
		if (!(self.spawnflags & SPAWN_INSTANT_WEAPON) && dist < 512)
		{
			chance = random();
			// ramp chance. easy - 50%, avg - 60%, hard - 70%, nightmare - 80%
			chance += (3 - skill.intVal) * 0.1;

			if (chance < 0.8)
			{
				// lead the target....
				float time = dist / 1000;
				end += time * self.enemy.velocity;
				dir = end - start;
			}
		}

		VectorNormalize(dir);

		trace_t trace;
		gi.traceline(&trace, start, end, self, MASK_SHOT);

		if (trace.ent == self.enemy || trace.ent == world)
		{
			if (self.spawnflags & SPAWN_BLASTER)
				monster_fire_blaster(self, start, dir, 20, rocketSpeed, MZ2_TURRET_BLASTER, EF_BLASTER);
			else if (self.spawnflags & SPAWN_MACHINEGUN)
				monster_fire_bullet (self, start, dir, TURRET_BULLET_DAMAGE, 0, DEFAULT_BULLET_HSPREAD, DEFAULT_BULLET_VSPREAD, MZ2_TURRET_MACHINEGUN);
			else if (self.spawnflags & SPAWN_ROCKET && (dist * trace.fraction > 72))
				monster_fire_rocket (self, start, dir, 50, rocketSpeed, MZ2_TURRET_ROCKET);
		}	
	}
}

static void(entity self) TurretFireBlind =
{
	TurretAim(self);

	if (!self.enemy || !self.enemy.inuse)
		return;

	vector dir = self.monsterinfo.blind_fire_target - self.s.origin;
	VectorNormalize(dir);

	vector forward;
	AngleVectors(self.s.angles, &forward, 0, 0);

	float chance = dir * forward;

	if (chance < 0.98)
		return;

	int rocketSpeed = 0;

	if (self.spawnflags & SPAWN_ROCKET)
	{
		rocketSpeed = 550;
		if (skill.intVal == 2)
			rocketSpeed += (int)random(200f);
		else if (skill.intVal == 3)
			rocketSpeed += (int)random(100f, 300f);
	}

	vector start = self.s.origin;
	vector end = self.monsterinfo.blind_fire_target;

	if (self.enemy.s.origin[2] < self.monsterinfo.blind_fire_target[2])
		end[2] += self.enemy.viewheight + 10;
	else
		end[2] += self.enemy.mins[2] - 10;

	vector dir = end - start;
	float dist = VectorLength(dir);
		
	VectorNormalize(dir);

	if (self.spawnflags & SPAWN_BLASTER)
		monster_fire_blaster(self, start, dir, 20, 1000, MZ2_TURRET_BLASTER, EF_BLASTER);
	else if (self.spawnflags & SPAWN_ROCKET)
		monster_fire_rocket (self, start, dir, 50, rocketSpeed, MZ2_TURRET_ROCKET);
}

static mframe_t turret_frames_fire [] =
{
	{ ai_run,   0, TurretFire },
	{ ai_run,   0, TurretAim },
	{ ai_run,   0, TurretAim },
	{ ai_run,   0, TurretAim }
};

// the blind frames need to aim first
static mframe_t turret_frames_fire_blind [] =
{
	{ ai_run,   0, TurretAim },
	{ ai_run,   0, TurretAim },
	{ ai_run,   0, TurretAim },
	{ ai_run,   0, TurretFireBlind }
};

static void(entity self) turret_attack =
{
	if (self.s.frame < FRAME_run01)
		turret_ready_gun(self);
	else if (self.monsterinfo.attack_state != AS_BLIND)
	{
		self.monsterinfo.nextframe = FRAME_pow01;
		self.monsterinfo.currentmove = &turret_move_fire;
	}
	else
	{
		float chance;

		// setup shot probabilities
		if (self.monsterinfo.blind_fire_framedelay < (1 * BASE_FRAMERATE))
			chance = 1.0;
		else if (self.monsterinfo.blind_fire_framedelay < (int)(7.5 * BASE_FRAMERATE))
			chance = 0.4;
		else
			chance = 0.1;

		// minimum of 3 seconds, plus 0-4, after the shots are done - total time should be max less than 7.5
		self.monsterinfo.blind_fire_framedelay += (int)(random(3.4f, 7.4f) * BASE_FRAMERATE);

		// don't shoot at the origin
		if (!self.monsterinfo.blind_fire_target)
			return;

		// don't shoot if the dice say not to
		if (random() > chance)
			return;

		self.monsterinfo.nextframe = FRAME_pow01;
		self.monsterinfo.currentmove = &turret_move_fire_blind;
	}
}

// **********************
//  DEATH
// **********************

static void(entity self, entity inflictor, entity attacker, int damage, vector point) turret_die =
{
	gi.WriteByte (svc_temp_entity);
	gi.WriteByte (TE_PLAIN_EXPLOSION);
	gi.WritePosition (self.s.origin);
	gi.multicast (self.s.origin, MULTICAST_PHS);

	vector forward;
	AngleVectors(self.s.angles, &forward, 0, 0);

	vector start = self.s.origin + forward;
	ThrowDebris (self, "models/objects/debris1/tris.md2", 1, start);
	ThrowDebris (self, "models/objects/debris1/tris.md2", 2, start);
	ThrowDebris (self, "models/objects/debris1/tris.md2", 1, start);
	ThrowDebris (self, "models/objects/debris1/tris.md2", 2, start);

	if (self.teamchain)
	{
		entity base = self.teamchain;
		base.solid = SOLID_BBOX;
		base.takedamage = false;
		base.movetype = MOVETYPE_NONE;
		gi.linkentity (base);
	}

	if (self.target)
	{
		if (self.enemy && self.enemy.inuse)
			G_UseTargets (self, self.enemy);
		else
			G_UseTargets (self, self);
	}

	G_FreeEdict(self);
}

// **********************
//  WALL SPAWN
// **********************
static void(entity turret) turret_wall_spawn =
{
	entity ent = G_Spawn();

	ent.s.origin = turret.s.origin;
	ent.s.angles = turret.s.angles;
	
	int angle = (int)ent.s.angles[1];

	if (ent.s.angles[0] == 90)
		angle = -1;
	else if (ent.s.angles[0] == 270)
		angle = -2;

	switch (angle)
	{
		case -1:
			ent.mins = '-16 -16 -8';
			ent.maxs = '16 16 0';
			break;
		case -2:
			ent.mins = '-16 -16 0';
			ent.maxs = '16 16 8';
			break;
		case 0:
			ent.mins = '-8 -16 -16';
			ent.maxs = '0 16 16';
			break;
		case 90:
			ent.mins = '-16 -8 -16';
			ent.maxs = '16 0 16';
			break;
		case 180:
			ent.mins = '0 -16 -16';
			ent.maxs = '8 16 16';
			break;
		case 270:
			ent.mins = '-16 0 -16';
			ent.maxs = '16 8 16';
			break;
	}

	ent.movetype = MOVETYPE_PUSH;
	ent.solid = SOLID_NOT;
	ent.teammaster = turret;
	turret.teammaster = turret;
	turret.teamchain = ent;
	ent.teamchain = 0;
	ent.flags |= FL_TEAMSLAVE;
	ent.owner = turret;
	ent.s.modelindex = gi.modelindex("models/monsters/turretbase/tris.md2");

	gi.linkentity (ent);
}

static void(entity self) turret_wake =
{
	// the wall section will call this when it stops moving.
	// just return without doing anything. easiest way to have a null function.
	if (self.flags & FL_TEAMSLAVE)
		return;

	self.monsterinfo.stand = turret_stand;
	self.monsterinfo.walk = turret_walk;
	self.monsterinfo.run = turret_run;
	self.monsterinfo.dodge = 0;
	self.monsterinfo.attack = turret_attack;
	self.monsterinfo.melee = 0;
	self.monsterinfo.currentmove = &turret_move_stand;
	self.takedamage = true;
	self.movetype = MOVETYPE_NONE;
	// prevent counting twice
	self.monsterinfo.aiflags |= AI_DO_NOT_COUNT;

	gi.linkentity (self);

	stationarymonster_start (self);
	
	if (self.spawnflags & SPAWN_MACHINEGUN)
		self.s.skinnum = 1;
	else if (self.spawnflags & SPAWN_ROCKET)
		self.s.skinnum = 2;

	// but we do want the death to count
	self.monsterinfo.aiflags &= ~AI_DO_NOT_COUNT;
}

void(entity ent, vector dest, void(entity) func) Move_Calc;

static void(entity self, entity other, entity cactivator) turret_activate =
{
	self.movetype = MOVETYPE_PUSH;
	if(!self.speed)
		self.speed = 15f;
	self.moveinfo.speed = self.speed;
	self.moveinfo.accel = self.speed;
	self.moveinfo.decel = self.speed;

	vector forward;
	if (self.s.angles[0] == 270)
		forward = '0 0 1';
	else if (self.s.angles[0] == 90)
		forward = '0 0 -1';
	else if (self.s.angles[1] == 0)
		forward = '1 0 0';
	else if (self.s.angles[1] == 90)
		forward = '0 1 0';
	else if (self.s.angles[1] == 180)
		forward = '-1 0 0';
	else
		forward = '0 -1 0';

	// start up the turret
	vector endpos = self.s.origin + (32 * forward);
	Move_Calc(self, endpos, turret_wake);

	entity base = self.teamchain;
	if(base)
	{
		base.movetype = MOVETYPE_PUSH;
		base.speed = self.speed;
		base.moveinfo.speed = base.speed;
		base.moveinfo.accel = base.speed;
		base.moveinfo.decel = base.speed;

		// start up the wall section
		endpos = self.teamchain.s.origin + (32 * forward);
		Move_Calc(self.teamchain, endpos, turret_wake);
	}

	gi.sound (self, CHAN_VOICE, gi.soundindex ("world/dr_short.wav"), 1, ATTN_NORM, 0);
}

// PMM
// checkattack .. ignore range, just attack if available
static bool(entity self) turret_checkattack =
{
	if (self.enemy.health > 0)
	{
		// see if any entities are in the way of the shot
		vector spot1 = self.s.origin;
		spot1[2] += self.viewheight;
		vector spot2 = self.enemy.s.origin;
		spot2[2] += self.enemy.viewheight;

		trace_t	tr;
		gi.traceline(&tr, spot1, spot2, self, CONTENTS_SOLID|CONTENTS_MONSTER|CONTENTS_SLIME|CONTENTS_LAVA|CONTENTS_WINDOW);

		// do we have a clear shot?
		if (tr.ent != self.enemy)
		{	
			// PGM - we want them to go ahead and shoot at info_notnulls if they can.
			if(self.enemy.solid != SOLID_NOT || tr.fraction < 1.0)		//PGM
			{
				// PMM - if we can't see our target, and we're not blocked by a monster, go into blind fire if available
				if ((!(tr.ent.svflags & SVF_MONSTER)) && (!visible(self, self.enemy)))
				{
					if ((self.monsterinfo.blindfire) && (self.monsterinfo.blind_fire_framedelay <= (10.0 * BASE_FRAMERATE)))
					{
						if (level.framenum < self.monsterinfo.attack_finished)
							return false;

						if (level.framenum < (self.monsterinfo.trail_framenum + self.monsterinfo.blind_fire_framedelay))
							// wait for our time
							return false;

						// make sure we're not going to shoot something we don't want to shoot
						gi.traceline (&tr, spot1, self.monsterinfo.blind_fire_target, self, CONTENTS_MONSTER);
						if (tr.allsolid || tr.startsolid || ((tr.fraction < 1.0) && (tr.ent != self.enemy)))
							return false;

						self.monsterinfo.attack_state = AS_BLIND;
						self.monsterinfo.attack_finished = level.framenum + (int)(random(0.5f, 2.5f) * BASE_FRAMERATE);
						return true;
					}
				}

				return false;
			}
		}
	}
	
	if (level.framenum < self.monsterinfo.attack_finished)
		return false;

	range_t enemy_range = range(self, self.enemy);

	if (enemy_range == RANGE_MELEE)
	{
		// don't always melee in easy mode
		if (skill.intVal == 0 && (Q_rand() & 3))
			return false;

		self.monsterinfo.attack_state = AS_MISSILE;
		return true;
	}

	float chance, nexttime;
	
	if (self.spawnflags & SPAWN_ROCKET)
	{
		chance = 0.10;
		nexttime = (1.8 - (0.2 * skill.intVal));
	}
	else if (self.spawnflags & SPAWN_BLASTER)
	{
		chance = 0.35;
		nexttime = (1.2 - (0.2 * skill.intVal));
	}
	else
	{
		chance = 0.50;
		nexttime = (0.8 - (0.1 * skill.intVal));
	}

	if (skill.intVal == 0)
		chance *= 0.5;
	else if (skill.intVal > 1)
		chance *= 2;

	// PGM - go ahead and shoot every time if it's a info_notnull
	// PMM - added visibility check
	if (((random() < chance) && visible(self, self.enemy)) || (self.enemy.solid == SOLID_NOT))
	{
		self.monsterinfo.attack_state = AS_MISSILE;
		self.monsterinfo.attack_finished = level.framenum + (int)(nexttime * BASE_FRAMERATE);
		return true;
	}

	self.monsterinfo.attack_state = AS_STRAIGHT;
	return false;
}


// **********************
//  SPAWN
// **********************

/*QUAKED monster_turret (1 .5 0) (-16 -16 -16) (16 16 16) Ambush Trigger_Spawn Sight Blaster MachineGun Rocket Heatbeam WallUnit

The automated defense turret that mounts on walls. 
Check the weapon you want it to use: blaster, machinegun, rocket, heatbeam.
Default weapon is blaster.
When activated, wall units move 32 units in the direction they're facing.
*/
API_FUNC static void(entity self) SP_monster_turret =
{
	if (deathmatch.intVal)
	{
		G_FreeEdict (self);
		return;
	}

	if (!turret_move_stand.frame)
	{
		turret_move_stand.frame = &turret_frames_stand;
		turret_move_ready_gun.frame = &turret_frames_ready_gun;
		turret_move_ready_gun.endfunc = turret_run;
		turret_move_fire_blind.frame = &turret_frames_fire_blind;
		turret_move_fire_blind.endfunc = turret_run;
		turret_move_run.frame = &turret_frames_run;
		turret_move_run.endfunc = turret_run;
		turret_move_seek.frame = &turret_frames_seek;
		turret_move_fire.frame = &turret_frames_fire;
		turret_move_fire.endfunc = turret_run;
	}

	// pre-caches
	gi.soundindex ("world/dr_short.wav");
	gi.modelindex ("models/objects/debris1/tris.md2");

	self.s.modelindex = gi.modelindex("models/monsters/turret/tris.md2");

	self.mins = '-12 -12 -12';
	self.maxs = '12 12 12';
	self.movetype = MOVETYPE_NONE;
	self.solid = SOLID_BBOX;

	self.health = 240;
	self.gib_health = -100;
	self.mass = 250;
	self.yaw_speed = 45f;

	self.flags |= FL_MECHANICAL;

	self.die = turret_die;

	// map designer didn't specify weapon type. set it now.
	if (!(self.spawnflags & SPAWN_WEAPONCHOICE))
		self.spawnflags |= SPAWN_BLASTER;

	if (self.spawnflags & SPAWN_HEATBEAM)
	{
		self.spawnflags &= ~SPAWN_HEATBEAM;
		self.spawnflags |= SPAWN_BLASTER;
	}

	if (!(self.spawnflags & SPAWN_WALL_UNIT))
	{
		self.monsterinfo.stand = turret_stand;
		self.monsterinfo.walk = turret_walk;
		self.monsterinfo.run = turret_run;
		self.monsterinfo.dodge = 0;
		self.monsterinfo.attack = turret_attack;
		self.monsterinfo.melee = 0;
		self.monsterinfo.currentmove = &turret_move_stand;
	}

	// PMM
	self.monsterinfo.checkattack = turret_checkattack;

	self.monsterinfo.aiflags |= AI_MANUAL_STEERING;
	self.monsterinfo.scale = MODEL_SCALE;
	self.gravity = 0;

	self.offset = self.s.angles;
	int angle = (int)self.s.angles[1];

	switch(angle)
	{
		case -1:					// up
			self.s.angles[0] = 270f;
			self.s.angles[1] = 0;
			self.s.origin[2] += 2;
			break;
		case -2:					// down
			self.s.angles[0] = 90f;
			self.s.angles[1] = 0;
			self.s.origin[2] -= 2;
			break;
		case 0:
			self.s.origin[0] += 2;
			break;
		case 90:
			self.s.origin[1] += 2;
			break;
		case 180:
			self.s.origin[0] -= 2;
			break;
		case 270:
			self.s.origin[1] -= 2;
			break;
	}

	gi.linkentity (self);

	if (self.spawnflags & SPAWN_WALL_UNIT)
	{
		if(!self.targetname)
		{
			G_FreeEdict(self);
			return;
		}

		self.takedamage = false;
		self.use = turret_activate;
		turret_wall_spawn(self);

		if (!(self.monsterinfo.aiflags & AI_GOOD_GUY_MASK))
			level.total_monsters++;
	}
	else
		stationarymonster_start (self);

	if (self.spawnflags & SPAWN_MACHINEGUN)
	{
		gi.soundindex ("infantry/infatck1.wav");
		self.s.skinnum = 1;
	}
	else if (self.spawnflags & SPAWN_ROCKET)
	{
		gi.soundindex ("weapons/rockfly.wav");
		gi.modelindex ("models/objects/rocket/tris.md2");
		gi.soundindex ("chick/chkatck2.wav");
		self.s.skinnum = 2;
	}
	else
	{
		if (!(self.spawnflags & SPAWN_BLASTER))
			self.spawnflags |= SPAWN_BLASTER;

		gi.modelindex ("models/objects/laser/tris.md2");
		gi.soundindex ("misc/lasfly.wav");
		gi.soundindex ("soldier/solatck2.wav");
	}
	
	// PMM  - turrets don't get mad at monsters, and visa versa
	self.monsterinfo.aiflags |= AI_IGNORE_SHOTS;

	if (self.spawnflags & (SPAWN_ROCKET | SPAWN_BLASTER))
		self.monsterinfo.blindfire = true;
}

#endif