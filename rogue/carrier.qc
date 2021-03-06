#if defined(GROUND_ZERO) && defined(SINGLE_PLAYER)
// self.timestamp used for frame calculations in grenade & spawn code
// self.wait used to prevent rapid refire of rocket launcher

#include "m_carrier.h"

static var mmove_t carrier_move_stand = {FRAME_search01, FRAME_search13 };
static var mmove_t carrier_move_walk = { FRAME_search01, FRAME_search13 };
static var mmove_t carrier_move_run = { FRAME_search01, FRAME_search13 };
static var mmove_t carrier_move_attack_pre_mg = { FRAME_firea01, FRAME_firea08 };
static var mmove_t carrier_move_attack_mg = { FRAME_firea09, FRAME_firea11 };
static var mmove_t carrier_move_attack_post_mg = { FRAME_firea12, FRAME_firea15 };
static var mmove_t carrier_move_attack_pre_gren = { FRAME_fireb01, FRAME_fireb06 };
static var mmove_t carrier_move_attack_gren = { FRAME_fireb07, FRAME_fireb10 };
static var mmove_t carrier_move_attack_post_gren = { FRAME_fireb11, FRAME_fireb16 };
static var mmove_t carrier_move_attack_rocket = { FRAME_fireb01, FRAME_fireb01 };
static var mmove_t carrier_move_attack_rail = { FRAME_search01, FRAME_search09 };
static var mmove_t carrier_move_spawn = { FRAME_spawn01, FRAME_spawn18 };
static var mmove_t carrier_move_pain_heavy = { FRAME_death01, FRAME_death10 };
static var mmove_t carrier_move_pain_light = { FRAME_spawn01, FRAME_spawn04 };
static var mmove_t carrier_move_death = { FRAME_death01, FRAME_death16 };

const float CARRIER_ROCKET_TIME	= 2;		// number of seconds between rocket shots
const int CARRIER_ROCKET_SPEED	= 750;
const int NUM_FLYERS_SPAWNED	= 6;		// max # of flyers he can spawn
const float RAIL_FIRE_TIME		= 3;

static int	sound_pain1;
static int	sound_pain2;
static int	sound_pain3;
static int	sound_death;
static int	sound_sight;
static int	sound_rail;
static int	sound_spawn;

PROGS_LOCAL_STATIC float orig_yaw_speed;

static const vector flyer_mins = '-16 -16 -24';
static const vector flyer_maxs = '16 16 16';

static void(entity self, entity other) carrier_sight =
{
	gi.sound (self, CHAN_VOICE, sound_sight, 1, ATTN_NORM, 0);
}

static INLINE void(entity self) CarrierPredictiveRocket =
{
	vector forward, right;
	AngleVectors (self.s.angles, &forward, &right, 0);

//1
	vector start = G_ProjectSource (self.s.origin, monster_flash_offset[MZ2_CARRIER_ROCKET_1], forward, right);
	vector dir;
	PredictAim (self.enemy, start, CARRIER_ROCKET_SPEED, false, -0.3, &dir, 0);
	monster_fire_rocket (self, start, dir, 50, CARRIER_ROCKET_SPEED, MZ2_CARRIER_ROCKET_1);

//2
	start = G_ProjectSource (self.s.origin, monster_flash_offset[MZ2_CARRIER_ROCKET_2], forward, right);
	PredictAim (self.enemy, start, CARRIER_ROCKET_SPEED, false, -0.15, &dir, 0);
	monster_fire_rocket (self, start, dir, 50, CARRIER_ROCKET_SPEED, MZ2_CARRIER_ROCKET_2);

//3
	start = G_ProjectSource (self.s.origin, monster_flash_offset[MZ2_CARRIER_ROCKET_3], forward, right);
	PredictAim (self.enemy, start, CARRIER_ROCKET_SPEED, false, 0, &dir, 0);
	monster_fire_rocket (self, start, dir, 50, CARRIER_ROCKET_SPEED, MZ2_CARRIER_ROCKET_3);

//4
	start = G_ProjectSource (self.s.origin, monster_flash_offset[MZ2_CARRIER_ROCKET_4], forward, right);
	PredictAim (self.enemy, start, CARRIER_ROCKET_SPEED, false, 0.15, &dir, 0);
	monster_fire_rocket (self, start, dir, 50, CARRIER_ROCKET_SPEED, MZ2_CARRIER_ROCKET_4);
}

static void(entity self) CarrierRocket =
{
	if (!self.enemy)
		return;

	if (self.enemy.is_client && random() < 0.5)
	{
		CarrierPredictiveRocket(self);
		return;
	}

	vector forward, right;
	AngleVectors (self.s.angles, &forward, &right, 0);

//1
	vector start = G_ProjectSource (self.s.origin, monster_flash_offset[MZ2_CARRIER_ROCKET_1], forward, right);
	vector vec = self.enemy.s.origin;
	vec[2] -= 15;
	vector dir = vec - start;
	VectorNormalize (dir);
	dir += 0.4 * right;
	VectorNormalize (dir);
	monster_fire_rocket (self, start, dir, 50, 500, MZ2_CARRIER_ROCKET_1);

//2
	start = G_ProjectSource (self.s.origin, monster_flash_offset[MZ2_CARRIER_ROCKET_2], forward, right);
	vec = self.enemy.s.origin;
	dir = vec - start;
	VectorNormalize (dir);
	dir += 0.025 * right;
	VectorNormalize (dir);
	monster_fire_rocket (self, start, dir, 50, 500, MZ2_CARRIER_ROCKET_2);

//3
	start = G_ProjectSource (self.s.origin, monster_flash_offset[MZ2_CARRIER_ROCKET_3], forward, right);
	vec = self.enemy.s.origin;
	dir = vec - start;
	VectorNormalize (dir);
	dir += -0.025 * right;
	VectorNormalize (dir);
	monster_fire_rocket (self, start, dir, 50, 500, MZ2_CARRIER_ROCKET_3);

//4
	start = G_ProjectSource (self.s.origin, monster_flash_offset[MZ2_CARRIER_ROCKET_4], forward, right);
	vec = self.enemy.s.origin;
	vec[2] -= 15;
	dir = vec - start;
	VectorNormalize (dir);
	dir += -0.4 * right;
	VectorNormalize (dir);
	monster_fire_rocket (self, start, dir, 50, 500, MZ2_CARRIER_ROCKET_4);
}

//
// this is the smarts for the rocket launcher in coop
//
// if there is a player behind/below the carrier, and we can shoot, and we can trace a LOS to them ..
// pick one of the group, and let it rip
static void(entity self) CarrierCoopCheck =
{
	// if we're not in coop, this is a noop
	if (!coop.intVal)
		return;
	// if we are, and we have recently fired, bail
	if (self.wait > level.framenum)
		return;

	// no more than 4 players in coop, so..
	entity targets[4] = { 0 };
	int	num_targets = 0;

	// cycle through players
	for (int player = 1; player <= game.maxclients; player++)
	{
		entity ent = itoe(player);
		if (!ent.inuse)
			continue;
		if (!ent.is_client)
			continue;
		if (inback(self, ent) || below(self, ent))
		{
			trace_t	tr;
			gi.traceline(&tr, self.s.origin, ent.s.origin, self, MASK_SOLID);
			if (tr.fraction == 1.0)
				targets[num_targets++] = ent;
		}
	}

	if (!num_targets)
		return;

	// make sure to prevent rapid fire rockets
	self.wait = level.framenum + (CARRIER_ROCKET_TIME * BASE_FRAMERATE);

	// save off the real enemy
	entity ent = self.enemy;
	// set the new guy as temporary enemy
	self.enemy = targets[Q_rand_uniform(num_targets)];
	CarrierRocket (self);
	// put the real enemy back
	self.enemy = ent;
}

static void(entity self) CarrierGrenade =
{
	CarrierCoopCheck(self);

	if (!self.enemy)
		return;

	// from lower left to upper right, or lower right to upper left
	int direction = (random() < 0.5) ? -1.0 : 1.0;

	int mytime = (int)((level.framenum - self.timestamp) / (0.4 * BASE_FRAMERATE));
	float spreadR = 0, spreadU = 0;

	if (mytime == 0)
	{
		spreadR = 0.15 * direction;
		spreadU = 0.1 - 0.1 * direction;
	}
	else if (mytime == 1)
		spreadU = 0.1;
	else if (mytime == 2)
	{
		spreadR = -0.15 * direction;
		spreadU = 0.1 - -0.1 * direction;
	}
	else if (mytime == 3)
		spreadU = 0.1;

	vector forward, right, up;
	AngleVectors (self.s.angles, &forward, &right, &up);

	vector start = G_ProjectSource (self.s.origin, monster_flash_offset[MZ2_CARRIER_GRENADE], forward, right);
	vector aim = self.enemy.s.origin - start;
	VectorNormalize (aim);

	aim += spreadR * right;
	aim += spreadU * up;

	if (aim[2] > 0.15)
		aim[2] = 0.15;
	else if (aim[2] < -0.5)
		aim[2] = -0.5;

	monster_fire_grenade (self, start, aim, 50, 600, MZ2_GUNNER_GRENADE_1);
}

static void(entity self, monster_muzzleflash_t manual, monster_muzzleflash_t auto, float lead) carrier_firebullet =
{
	// if we're in manual steering mode, it means we're leaning down .. use the lower shot
	int	flashnum = (self.monsterinfo.aiflags & AI_MANUAL_STEERING) ? manual : auto;

	vector forward, right;
	AngleVectors (self.s.angles, &forward, &right, 0);
	vector start = G_ProjectSource (self.s.origin, monster_flash_offset[flashnum], forward, right);

	vector target = self.enemy.s.origin + (lead * self.enemy.velocity);
	target[2] += self.enemy.viewheight;

	forward = target - start;
	VectorNormalize (forward);

	monster_fire_bullet (self, start, forward, 6, 4, DEFAULT_BULLET_HSPREAD*3, DEFAULT_BULLET_VSPREAD, flashnum);
}	

static void(entity self) CarrierMachineGun =
{
	CarrierCoopCheck(self);
	if (!self.enemy)
		return;

	carrier_firebullet(self, MZ2_CARRIER_MACHINEGUN_L2, MZ2_CARRIER_MACHINEGUN_L1, -0.2);
	carrier_firebullet(self, MZ2_CARRIER_MACHINEGUN_R2, MZ2_CARRIER_MACHINEGUN_R1, 0.2);
}	

static void(entity self) CarrierSpawn =
{
	vector f, r;
	AngleVectors (self.s.angles, &f, &r, 0);

	vector startpoint = G_ProjectSource (self.s.origin, '105 0 -58', f, r);

	// the +0.1 is because level.time is sometimes a little low
	int mytime = (int)((level.framenum + (0.1 * BASE_FRAMERATE) - self.timestamp) / (0.5 * BASE_FRAMERATE));

	vector spawnpoint;

	if (!FindSpawnPoint (startpoint, flyer_mins, flyer_maxs, &spawnpoint, 32))
		return;

	// the second flier should be a kamikaze flyer
	entity ent = CreateMonster (spawnpoint, self.s.angles, (mytime != 2) ? "monster_flyer" : "monster_kamikaze");

	if (!ent)
		return;

	gi.sound (self, CHAN_BODY, sound_spawn, 1, ATTN_NONE, 0);

	self.monsterinfo.monster_slots--;

	ent.nextthink = level.framenum;
	ent.think (ent);
	
	ent.monsterinfo.aiflags |= AI_SPAWNED_CARRIER|AI_DO_NOT_COUNT|AI_IGNORE_SHOTS;
	ent.monsterinfo.commander = self;

	if ((self.enemy.inuse) && (self.enemy.health > 0))
	{
		ent.enemy = self.enemy;
		FoundTarget (ent);
		if (mytime == 1)
		{
			ent.monsterinfo.lefty = false;
			ent.monsterinfo.attack_state = AS_SLIDING;
			ent.monsterinfo.currentmove = &flyer_move_attack3;
		}
		else if (mytime == 2)
		{
			ent.monsterinfo.lefty = false;
			ent.monsterinfo.attack_state = AS_STRAIGHT;
			ent.monsterinfo.currentmove = &flyer_move_kamikaze;
			ent.mass = 100;
			ent.monsterinfo.aiflags |= AI_CHARGING;
		}
		else if (mytime == 3)
		{
			ent.monsterinfo.lefty = true;
			ent.monsterinfo.attack_state = AS_SLIDING;
			ent.monsterinfo.currentmove = &flyer_move_attack3;
		}
	}
}

static void(entity self) carrier_prep_spawn =
{
	CarrierCoopCheck(self);
	self.monsterinfo.aiflags |= AI_MANUAL_STEERING;
	self.timestamp = level.framenum;
	self.yaw_speed = 10f;
	CarrierMachineGun(self);
}

static void(entity self) carrier_spawn_check =
{
	CarrierCoopCheck(self);
	CarrierMachineGun(self);
	CarrierSpawn (self);

	if (level.framenum > (self.timestamp + (1.1 * BASE_FRAMERATE)))  // 0.5 seconds per flyer.  this gets three
	{
		self.monsterinfo.aiflags &= ~AI_MANUAL_STEERING;
		self.yaw_speed = orig_yaw_speed;
		return;
	}

	self.monsterinfo.nextframe = FRAME_spawn08;
}

static void(entity self) carrier_ready_spawn =
{
	CarrierCoopCheck(self);
	CarrierMachineGun(self);

	float current_yaw = anglemod(self.s.angles[YAW]);

	if (fabs(current_yaw - self.ideal_yaw) > 0.1)
	{
		self.monsterinfo.aiflags |= AI_HOLD_FRAME;
		self.timestamp += 1;
		return;
	}

	self.monsterinfo.aiflags &= ~AI_HOLD_FRAME;

	vector f, r;
	AngleVectors (self.s.angles, &f, &r, 0);

	vector startpoint = G_ProjectSource (self.s.origin, '105 0 -58', f, r);
	vector spawnpoint;

	if (FindSpawnPoint (startpoint, flyer_mins, flyer_maxs, &spawnpoint, 32))
		SpawnGrow_Spawn (spawnpoint, 0);
}

static void(entity self) carrier_start_spawn =
{
	CarrierCoopCheck(self);

	if (!orig_yaw_speed)
		orig_yaw_speed = self.yaw_speed;

	if (!self.enemy)
		return;

	int mytime = (int)((level.framenum - self.timestamp) / (0.5 * BASE_FRAMERATE));

	vector temp = self.enemy.s.origin - self.s.origin;
	float enemy_yaw = vectoyaw(temp);

	// note that the offsets are based on a forward of 105 from the end angle
	if (mytime == 0)
		self.ideal_yaw = anglemod(enemy_yaw - 30);
	else if (mytime == 1)
		self.ideal_yaw = anglemod(enemy_yaw);
	else if (mytime == 2)
		self.ideal_yaw = anglemod(enemy_yaw + 30);

	CarrierMachineGun (self);
}

static void(entity self) CarrierRail =
{
	CarrierCoopCheck(self);

	vector forward, right;
	AngleVectors (self.s.angles, &forward, &right, 0);

	// calc direction to where we targeted
	vector start = G_ProjectSource (self.s.origin, monster_flash_offset[MZ2_CARRIER_RAILGUN], forward, right);
	vector dir = self.pos1 - start;
	VectorNormalize (dir);

	monster_fire_railgun (self, start, dir, 50, 100, MZ2_CARRIER_RAILGUN);
	self.monsterinfo.attack_finished = level.framenum + (int)(RAIL_FIRE_TIME * BASE_FRAMERATE);
}

static void(entity self) CarrierSaveLoc =
{
	CarrierCoopCheck(self);
	self.pos1 = self.enemy.s.origin;	//save for aiming the shot
	self.pos1[2] += self.enemy.viewheight;
}

static void(entity self) carrier_stand =
{
	self.monsterinfo.currentmove = &carrier_move_stand;
}

static void(entity self) carrier_run =
{
	self.monsterinfo.aiflags &= ~AI_HOLD_FRAME;

	if (self.monsterinfo.aiflags & AI_STAND_GROUND)
		self.monsterinfo.currentmove = &carrier_move_stand;
	else
		self.monsterinfo.currentmove = &carrier_move_run;
}

static void(entity self) carrier_walk =
{
	self.monsterinfo.currentmove = &carrier_move_walk;
}

static void(entity self) carrier_attack =
{
	self.monsterinfo.aiflags &= ~AI_HOLD_FRAME;

	if ((!self.enemy) || (!self.enemy.inuse))
		return;

	bool enemy_inback = inback(self, self.enemy);
	bool enemy_infront = infront (self, self.enemy);
	bool enemy_below = below (self, self.enemy);

	if (self.bad_area)
	{
		if ((enemy_inback) || (enemy_below))
			self.monsterinfo.currentmove = &carrier_move_attack_rocket;
		else if ((random() < 0.1) || (level.framenum < self.monsterinfo.attack_finished))
			self.monsterinfo.currentmove = &carrier_move_attack_pre_mg;
		else
		{
			gi.sound (self, CHAN_WEAPON, sound_rail, 1, ATTN_NORM, 0);
			self.monsterinfo.currentmove = &carrier_move_attack_rail;
		}
		return;
	}

	if (self.monsterinfo.attack_state == AS_BLIND)
	{
		self.monsterinfo.currentmove = &carrier_move_spawn;
		return;
	}

	if (!enemy_inback && !enemy_infront && !enemy_below) // to side and not under
	{
		if ((random() < 0.1) || (level.framenum < self.monsterinfo.attack_finished)) 
			self.monsterinfo.currentmove = &carrier_move_attack_pre_mg;
		else
		{
			gi.sound (self, CHAN_WEAPON, sound_rail, 1, ATTN_NORM, 0);
			self.monsterinfo.currentmove = &carrier_move_attack_rail;
		}
		return;
	}

	if (enemy_infront)
	{
		float range = VectorLength (self.enemy.s.origin - self.s.origin);

		if (range <= 125)
		{
			if ((random() < 0.8) || (level.framenum < self.monsterinfo.attack_finished))
				self.monsterinfo.currentmove = &carrier_move_attack_pre_mg;
			else
			{
				gi.sound (self, CHAN_WEAPON, sound_rail, 1, ATTN_NORM, 0);
				self.monsterinfo.currentmove = &carrier_move_attack_rail;
			}
		}
		else if (range < 600)
		{
			float luck = random();

			if (self.monsterinfo.monster_slots > 2)
			{
				if (luck <= 0.20)
					self.monsterinfo.currentmove = &carrier_move_attack_pre_mg;
				else if (luck <= 0.40)
					self.monsterinfo.currentmove = &carrier_move_attack_pre_gren;
				else if ((luck <= 0.7) && !(level.framenum < self.monsterinfo.attack_finished))
				{
					gi.sound (self, CHAN_WEAPON, sound_rail, 1, ATTN_NORM, 0);
					self.monsterinfo.currentmove = &carrier_move_attack_rail;
				}
				else
					self.monsterinfo.currentmove = &carrier_move_spawn;
			}
			else if (luck <= 0.30)
				self.monsterinfo.currentmove = &carrier_move_attack_pre_mg;
			else if (luck <= 0.65)
				self.monsterinfo.currentmove = &carrier_move_attack_pre_gren;
			else if (level.framenum >= self.monsterinfo.attack_finished)
			{
				gi.sound (self, CHAN_WEAPON, sound_rail, 1, ATTN_NORM, 0);
				self.monsterinfo.currentmove = &carrier_move_attack_rail;
			}
			else
				self.monsterinfo.currentmove = &carrier_move_attack_pre_mg;
		}
		else // won't use grenades at this range
		{
			float luck = random();

			if (self.monsterinfo.monster_slots > 2)
			{
				if (luck < 0.3)
					self.monsterinfo.currentmove = &carrier_move_attack_pre_mg;
				else if ((luck < 0.65) && !(level.framenum < self.monsterinfo.attack_finished))
				{
					gi.sound (self, CHAN_WEAPON, sound_rail, 1, ATTN_NORM, 0);
					self.pos1 = self.enemy.s.origin;	//save for aiming the shot
					self.pos1[2] += self.enemy.viewheight;
					self.monsterinfo.currentmove = &carrier_move_attack_rail;
				}
				else
					self.monsterinfo.currentmove = &carrier_move_spawn;
			}
			else if ((luck < 0.45) || (level.framenum < self.monsterinfo.attack_finished))
				self.monsterinfo.currentmove = &carrier_move_attack_pre_mg;
			else
			{
				gi.sound (self, CHAN_WEAPON, sound_rail, 1, ATTN_NORM, 0);
				self.monsterinfo.currentmove = &carrier_move_attack_rail;
			}
		}
	}
	else if ((enemy_below) || (enemy_inback))
		self.monsterinfo.currentmove = &carrier_move_attack_rocket;
}

static void(entity self) carrier_attack_mg =
{
	CarrierCoopCheck(self);
	self.monsterinfo.currentmove = &carrier_move_attack_mg;
}

static void(entity self) carrier_reattack_mg =
{
	CarrierCoopCheck(self);
	if (infront(self, self.enemy))
		if (random() <= 0.5)
			if ((random() < 0.7) || (self.monsterinfo.monster_slots <= 2))
				self.monsterinfo.currentmove = &carrier_move_attack_mg;
			else
				self.monsterinfo.currentmove = &carrier_move_spawn;
		else
			self.monsterinfo.currentmove = &carrier_move_attack_post_mg;
	else
		self.monsterinfo.currentmove = &carrier_move_attack_post_mg;
}


static void(entity self) carrier_attack_gren =
{
	CarrierCoopCheck(self);
	self.timestamp = level.framenum;
	self.monsterinfo.currentmove = &carrier_move_attack_gren;
}

static void(entity self) carrier_reattack_gren =
{
	CarrierCoopCheck(self);

	if (infront(self, self.enemy))
		if (self.timestamp + (1.3 * BASE_FRAMERATE) > level.framenum ) // four grenades
		{
			self.monsterinfo.currentmove = &carrier_move_attack_gren;
			return;
		}

	self.monsterinfo.currentmove = &carrier_move_attack_post_gren;
}

static void(entity self, entity other, float kick, int damage) carrier_pain =
{
	if (self.health < (self.max_health / 2))
		self.s.skinnum = 1;

	if (skill.intVal == 3)
		return;		// no pain anims in nightmare

	if (level.framenum < self.pain_debounce_framenum)
		return;

	self.pain_debounce_framenum = level.framenum + (5 * BASE_FRAMERATE);

	bool changed = false;

	if (damage < 10)
		gi.sound (self, CHAN_VOICE, sound_pain3, 1, ATTN_NONE, 0);
	else if (damage < 30)
	{
		gi.sound (self, CHAN_VOICE, sound_pain1, 1, ATTN_NONE, 0);
		if (random() < 0.5)
		{
			changed = true;
			self.monsterinfo.currentmove = &carrier_move_pain_light;
		}
	}
	else 
	{
		gi.sound (self, CHAN_VOICE, sound_pain2, 1, ATTN_NONE, 0);
		self.monsterinfo.currentmove = &carrier_move_pain_heavy;
		changed = true;
	}

	// if we changed frames, clean up our little messes
	if (changed)
	{
		self.monsterinfo.aiflags &= ~(AI_HOLD_FRAME | AI_MANUAL_STEERING);
		self.yaw_speed = orig_yaw_speed;
	}
}

static void(entity self) carrier_dead =
{
	self.mins = '-56 -56 0';
	self.maxs = '56 56 80';
	self.movetype = MOVETYPE_TOSS;
	self.svflags |= SVF_DEADMONSTER;
	self.nextthink = 0;
	gi.linkentity (self);
}

static void(entity self, entity inflictor, entity attacker, int damage, vector point) carrier_die =
{
	gi.sound (self, CHAN_VOICE, sound_death, 1, ATTN_NONE, 0);
	self.deadflag = DEAD_DEAD;
	self.takedamage = false;
	self.count = 0;
	self.monsterinfo.currentmove = &carrier_move_death;
}

static bool(entity self) Carrier_CheckAttack =
{
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
			if (self.enemy.is_client && self.monsterinfo.monster_slots > 2)
			{
				self.monsterinfo.attack_state = AS_BLIND;
				return true;
			}
				
			// PGM - we want them to go ahead and shoot at info_notnulls if they can.
			if (self.enemy.solid != SOLID_NOT || tr.fraction < 1.0)		//PGM
				return false;
		}
	}
	
	bool enemy_infront = infront(self, self.enemy);
	bool enemy_inback = inback(self, self.enemy);
	bool enemy_below = below (self, self.enemy);

	float enemy_range = range(self, self.enemy);

	self.ideal_yaw = vectoyaw(self.enemy.s.origin - self.s.origin);

	// PMM - shoot out the back if appropriate
	if ((enemy_inback) || (!enemy_infront && enemy_below))
	{
		// this is using wait because the attack is supposed to be independent
		if (level.framenum >= self.wait)
		{
			self.wait = level.framenum + (CARRIER_ROCKET_TIME * BASE_FRAMERATE);
			self.monsterinfo.attack(self);
			if (random() < 0.6)
				self.monsterinfo.attack_state = AS_SLIDING;
			else
				self.monsterinfo.attack_state = AS_STRAIGHT;
			return true;
		}
	}

	// melee attack
	if (enemy_range == RANGE_MELEE)
	{
		self.monsterinfo.attack_state = AS_MISSILE;
		return true;
	}

	float chance = 0;

	if (self.monsterinfo.aiflags & AI_STAND_GROUND)
		chance = 0.4;
	else if (enemy_range == RANGE_MELEE)
		chance = 0.8;
	else if (enemy_range == RANGE_NEAR)
		chance = 0.8;
	else if (enemy_range == RANGE_MID)
		chance = 0.8;
	else if (enemy_range == RANGE_FAR)
		chance = 0.5;

	// PGM - go ahead and shoot every time if it's a info_notnull
	if ((random () < chance) || (self.enemy.solid == SOLID_NOT))
	{
		self.monsterinfo.attack_state = AS_MISSILE;
		return true;
	}

	if (self.flags & FL_FLY)
	{
		if (random() < 0.6)
			self.monsterinfo.attack_state = AS_SLIDING;
		else
			self.monsterinfo.attack_state = AS_STRAIGHT;
	}

	return false;
}

static mframe_t carrier_frames_stand [] =
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

static mframe_t carrier_frames_walk [] =
{
	{ ai_walk,	4 },
	{ ai_walk,	4 },
	{ ai_walk,	4 },
	{ ai_walk,	4 },
	{ ai_walk,	4 },
	{ ai_walk,	4 },
	{ ai_walk,	4 },
	{ ai_walk,	4 },
	{ ai_walk,	4 },
	{ ai_walk,	4 },
	{ ai_walk,	4 },
	{ ai_walk,	4 },
	{ ai_walk,	4 }
};

static mframe_t carrier_frames_run [] =
{
	{ ai_run,	6,	CarrierCoopCheck },
	{ ai_run,	6,	CarrierCoopCheck },
	{ ai_run,	6,	CarrierCoopCheck },
	{ ai_run,	6,	CarrierCoopCheck },
	{ ai_run,	6,	CarrierCoopCheck },
	{ ai_run,	6,	CarrierCoopCheck },
	{ ai_run,	6,	CarrierCoopCheck },
	{ ai_run,	6,	CarrierCoopCheck },
	{ ai_run,	6,	CarrierCoopCheck },
	{ ai_run,	6,	CarrierCoopCheck },
	{ ai_run,	6,	CarrierCoopCheck },
	{ ai_run,	6,	CarrierCoopCheck },
	{ ai_run,	6,	CarrierCoopCheck }
};

static mframe_t carrier_frames_attack_pre_mg [] =
{
	{ ai_charge,	4,	CarrierCoopCheck },
	{ ai_charge,	4,	CarrierCoopCheck },
	{ ai_charge,	4,	CarrierCoopCheck },
	{ ai_charge,	4,	CarrierCoopCheck },
	{ ai_charge,	4,	CarrierCoopCheck },
	{ ai_charge,	4,	CarrierCoopCheck },
	{ ai_charge,	4,	CarrierCoopCheck },
	{ ai_charge,	4,	carrier_attack_mg }
};

// Loop this
static mframe_t carrier_frames_attack_mg [] =
{
	{ ai_charge,	-2,	CarrierMachineGun },
	{ ai_charge,	-2,	CarrierMachineGun },
	{ ai_charge,	-2,	carrier_reattack_mg }
};

static mframe_t carrier_frames_attack_post_mg [] =
{
	{ ai_charge,	4,	CarrierCoopCheck },
	{ ai_charge,	4,	CarrierCoopCheck },
	{ ai_charge,	4,	CarrierCoopCheck },
	{ ai_charge,	4,	CarrierCoopCheck }
};

static mframe_t carrier_frames_attack_pre_gren [] =
{
	{ ai_charge, 4, CarrierCoopCheck },
	{ ai_charge, 4, CarrierCoopCheck },
	{ ai_charge, 4, CarrierCoopCheck },
	{ ai_charge, 4, CarrierCoopCheck },
	{ ai_charge, 4, CarrierCoopCheck },
	{ ai_charge, 4, carrier_attack_gren }
};

static mframe_t carrier_frames_attack_gren [] =
{
	{ ai_charge, -15, CarrierGrenade },
	{ ai_charge, 4, CarrierCoopCheck },
	{ ai_charge, 4, CarrierCoopCheck },
	{ ai_charge, 4, carrier_reattack_gren }
};

static mframe_t carrier_frames_attack_post_gren [] =
{
	{ ai_charge, 4, CarrierCoopCheck },
	{ ai_charge, 4, CarrierCoopCheck },
	{ ai_charge, 4, CarrierCoopCheck },
	{ ai_charge, 4, CarrierCoopCheck },
	{ ai_charge, 4, CarrierCoopCheck },
	{ ai_charge, 4, CarrierCoopCheck }
};

static mframe_t carrier_frames_attack_rocket [] =
{
	{ ai_charge,	15,	CarrierRocket }
};

static mframe_t carrier_frames_attack_rail [] =
{
	{ ai_charge, 2, CarrierCoopCheck },
	{ ai_charge, 2, CarrierSaveLoc },
	{ ai_charge, 2, CarrierCoopCheck },
	{ ai_charge, -20, CarrierRail },
	{ ai_charge, 2, CarrierCoopCheck },
	{ ai_charge, 2, CarrierCoopCheck },
	{ ai_charge, 2, CarrierCoopCheck },
	{ ai_charge, 2, CarrierCoopCheck },
	{ ai_charge, 2, CarrierCoopCheck }
};

static mframe_t carrier_frames_spawn [] =
{
	{ ai_charge,	-2,	CarrierMachineGun },
	{ ai_charge,	-2,	CarrierMachineGun },
	{ ai_charge,	-2,	CarrierMachineGun },
	{ ai_charge,	-2,	CarrierMachineGun },
	{ ai_charge,	-2,	CarrierMachineGun },
	{ ai_charge,	-2,	CarrierMachineGun },
	{ ai_charge,	-2,	carrier_prep_spawn },		// 7 - end of wind down
	{ ai_charge,	-2,	carrier_start_spawn },		// 8 - start of spawn
	{ ai_charge,	-2,	carrier_ready_spawn },
	{ ai_charge,	-2,	CarrierMachineGun },
	{ ai_charge,	-2,	CarrierMachineGun },
	{ ai_charge,	-10, carrier_spawn_check },		//12 - actual spawn
	{ ai_charge,	-2,	CarrierMachineGun },		//13 - begin of wind down
	{ ai_charge,	-2,	CarrierMachineGun },
	{ ai_charge,	-2,	CarrierMachineGun },
	{ ai_charge,	-2,	CarrierMachineGun },
	{ ai_charge,	-2,	CarrierMachineGun },
	{ ai_charge,	-2,	carrier_reattack_mg }		//18 - end of wind down
};

static mframe_t carrier_frames_pain_heavy [] =
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
	{ ai_move }
};

static mframe_t carrier_frames_pain_light [] =
{
	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move }
};

static mframe_t carrier_frames_death [] =
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
	{ ai_move,	0,	BossExplode }
};

static void() CarrierPrecache =
{
	gi.soundindex ("flyer/flysght1.wav");
	gi.soundindex ("flyer/flysrch1.wav");
	gi.soundindex ("flyer/flypain1.wav");
	gi.soundindex ("flyer/flypain2.wav");
	gi.soundindex ("flyer/flyatck2.wav");
	gi.soundindex ("flyer/flyatck1.wav");
	gi.soundindex ("flyer/flydeth1.wav");
	gi.soundindex ("flyer/flyatck3.wav");
	gi.soundindex ("flyer/flyidle1.wav");
	gi.soundindex ("weapons/rockfly.wav");
	gi.soundindex ("infantry/infatck1.wav");
	gi.soundindex ("gunner/gunatck3.wav");
	gi.soundindex ("weapons/grenlb1b.wav");
	gi.soundindex ("tank/rocket.wav");

	gi.modelindex ("models/monsters/flyer/tris.md2");
	gi.modelindex ("models/objects/rocket/tris.md2");
	gi.modelindex ("models/objects/debris2/tris.md2");
	gi.modelindex ("models/objects/grenade/tris.md2");
	gi.modelindex("models/items/spawngro/tris.md2");
	gi.modelindex("models/items/spawngro2/tris.md2");
	gi.modelindex ("models/objects/gibs/sm_metal/tris.md2");
	gi.modelindex ("models/objects/gibs/gear/tris.md2");

	if (!carrier_move_death.frame)
	{
		carrier_move_death.frame = &carrier_frames_death;
		carrier_move_death.endfunc = carrier_dead;
		carrier_move_pain_light.frame = &carrier_frames_pain_light;
		carrier_move_pain_light.endfunc = carrier_run;
		carrier_move_pain_heavy.frame = &carrier_frames_pain_heavy;
		carrier_move_pain_heavy.endfunc = carrier_run;
		carrier_move_spawn.frame = &carrier_frames_spawn;
		carrier_move_attack_rail.frame = &carrier_frames_attack_rail;
		carrier_move_attack_rail.endfunc = carrier_run;
		carrier_move_attack_rocket.frame = &carrier_frames_attack_rocket;
		carrier_move_attack_rocket.endfunc = carrier_run;
		carrier_move_attack_post_gren.frame = &carrier_frames_attack_post_gren;
		carrier_move_attack_post_gren.endfunc = carrier_run;
		carrier_move_attack_gren.frame = &carrier_frames_attack_gren;
		carrier_move_attack_pre_gren.frame = &carrier_frames_attack_pre_gren;
		carrier_move_attack_post_mg.frame = &carrier_frames_attack_post_mg;
		carrier_move_attack_post_mg.endfunc = carrier_run;
		carrier_move_attack_mg.frame = &carrier_frames_attack_mg;
		carrier_move_attack_pre_mg.frame = &carrier_frames_attack_pre_mg;
		carrier_move_run.frame = &carrier_frames_run;
		carrier_move_walk.frame = &carrier_frames_walk;
		carrier_move_stand.frame = &carrier_frames_stand;
	}
}

/*QUAKED monster_carrier (1 .5 0) (-56 -56 -44) (56 56 44) Ambush Trigger_Spawn Sight
*/
void SP_monster_carrier (entity self)
{
	if (deathmatch.intVal)
	{
		G_FreeEdict (self);
		return;
	}

	sound_pain1 = gi.soundindex ("carrier/pain_md.wav");
	sound_pain2 = gi.soundindex ("carrier/pain_lg.wav");
	sound_pain3 = gi.soundindex ("carrier/pain_sm.wav");
	sound_death = gi.soundindex ("carrier/death.wav");
	sound_rail = gi.soundindex ("gladiator/railgun.wav");
	sound_sight = gi.soundindex ("carrier/sight.wav");
	sound_spawn = gi.soundindex ("medic_commander/monsterspawn1.wav");

	self.s.sound = gi.soundindex ("bosshovr/bhvengn1.wav");

	self.movetype = MOVETYPE_STEP;
	self.solid = SOLID_BBOX;
	self.s.modelindex = gi.modelindex ("models/monsters/carrier/tris.md2");
	self.mins = '-56 -56 -44';
	self.maxs = '56 56 44';

	// 2000 - 4000 health
	self.health = maxi (2000, 2000 + 1000 * (skill.intVal - 1));
	// add health in coop (500 * skill)
	if (coop.intVal)
		self.health += 500 * skill.intVal;	

	self.gib_health = -200;
	self.mass = 1000;

	self.yaw_speed = 15f;
	orig_yaw_speed = self.yaw_speed;
	
	self.flags |= FL_IMMUNE_LASER;
	self.monsterinfo.aiflags |= AI_IGNORE_SHOTS;

	self.pain = carrier_pain;
	self.die = carrier_die;

	self.monsterinfo.melee = 0;
	self.monsterinfo.stand = carrier_stand;
	self.monsterinfo.walk = carrier_walk;
	self.monsterinfo.run = carrier_run;
	self.monsterinfo.attack = carrier_attack;
	self.monsterinfo.sight = carrier_sight;
	self.monsterinfo.checkattack = Carrier_CheckAttack;
	gi.linkentity (self);

	self.monsterinfo.currentmove = &carrier_move_stand;	
	self.monsterinfo.scale = MODEL_SCALE;

	CarrierPrecache();

	flymonster_start (self);

	self.monsterinfo.attack_finished = 6;
	switch (skill.intVal)
	{
	case 0:
		self.monsterinfo.monster_slots = 3;
		break;
	case 3:
		self.monsterinfo.monster_slots = 9;
		break;
	}
}

#endif