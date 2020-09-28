#ifdef SINGLE_PLAYER

// from ai.qc
bool(entity self) FindTarget;
bool(entity self, float dist) ai_checkattack;

//range
typedef enum : int
{
	RANGE_MELEE,
	RANGE_NEAR,
	RANGE_MID,
	RANGE_FAR
} range_t;

PROGS_LOCAL bool	enemy_vis;
PROGS_LOCAL range_t	enemy_range;
PROGS_LOCAL float	enemy_yaw;

//============================================================================


/*
=================
AI_SetSightClient

Called once each frame to set level.sight_client to the
player to be checked for in findtarget.

If all clients are either dead or in notarget, sight_client
will be null.

In coop games, sight_client will cycle between the clients.
=================
*/
void() AI_SetSightClient =
{
	entity	ent;
	int	start, check;

	if (level.sight_client == world)
		start = 1;
	else
		start = level.sight_client.s.number;

	check = start;
	while (1)
	{
		check++;
		if (check > game.maxclients)
			check = 1;
		ent = itoe(check);
		if (ent.inuse && ent.health > 0 && !(ent.flags & FL_VISIBLE_MASK))
		{
			level.sight_client = ent;
			return;     // got one
		}
		if (check == start)
		{
			level.sight_client = world;
			return;     // nobody to see
		}
	}
}

//============================================================================

// from move.qc
bool(entity ent, float yaw, float dist) M_walkmove;

/*
=============
ai_move

Move the specified distance at current facing.
This replaces the QC functions: ai_forward, ai_back, ai_pain, and ai_painforward
==============
*/
void(entity self, float dist) ai_move =
{
	M_walkmove(self, self.s.angles[YAW], dist);
}

// from move.qc
void(entity ent) M_ChangeYaw;
void(entity ent, float dist) M_MoveToGoal;

/*
=============
ai_stand

Used for standing around and looking for players
Distance is for slight position adjustments needed by the animations
==============
*/
void(entity self, float dist) ai_stand =
{
	if (dist)
		M_walkmove(self, self.s.angles[YAW], dist);

	if (self.monsterinfo.aiflags & AI_STAND_GROUND)
	{
		if (self.enemy)
		{
			vector v = self.enemy.s.origin - self.s.origin;
			self.ideal_yaw = vectoyaw(v);
			if (self.s.angles[YAW] != self.ideal_yaw && self.monsterinfo.aiflags & AI_TEMP_STAND_GROUND)
			{
				self.monsterinfo.aiflags &= ~(AI_STAND_GROUND | AI_TEMP_STAND_GROUND);
				self.monsterinfo.run(self);
			}
			
#ifdef GROUND_ZERO
			if (!(self.monsterinfo.aiflags & AI_MANUAL_STEERING))
				M_ChangeYaw (self);

			// find out if we're going to be shooting
			bool retval = ai_checkattack (self, 0);

			// record sightings of player
			if (self.enemy && self.enemy.inuse && visible(self, self.enemy))
			{
				self.monsterinfo.aiflags &= ~AI_LOST_SIGHT;
				self.monsterinfo.last_sighting = self.enemy.s.origin;
				self.monsterinfo.blind_fire_target = self.enemy.s.origin;
				self.monsterinfo.trail_framenum = level.framenum;
				self.monsterinfo.blind_fire_framedelay = 0;
			}
			// check retval to make sure we're not blindfiring
			else if (!retval)
			{
				FindTarget (self);
				return;
			}
#else
			M_ChangeYaw(self);
			ai_checkattack(self, 0);
#endif
		}
		else
			FindTarget(self);
		return;
	}

	if (FindTarget(self))
		return;

	if (level.framenum > self.monsterinfo.pause_framenum)
	{
		self.monsterinfo.walk(self);
		return;
	}

	if (!(self.spawnflags & 1) && (self.monsterinfo.idle) && (level.framenum > self.monsterinfo.idle_framenum))
	{
		if (self.monsterinfo.idle_framenum)
		{
			self.monsterinfo.idle(self);
			self.monsterinfo.idle_framenum = level.framenum + (int)random(15f * BASE_FRAMERATE, 30f * BASE_FRAMERATE);
		}
		else
			self.monsterinfo.idle_framenum = level.framenum + (int)random(15f * BASE_FRAMERATE);
	}
}


/*
=============
ai_walk

The monster is walking it's beat
=============
*/
void(entity self, float dist) ai_walk =
{
	M_MoveToGoal(self, dist);

	// check for noticing a player
	if (FindTarget(self))
		return;

	if ((self.monsterinfo.search) && (level.framenum > self.monsterinfo.idle_framenum)) {
		if (self.monsterinfo.idle_framenum) {
			self.monsterinfo.search(self);
			self.monsterinfo.idle_framenum = level.framenum + (int)random(15f * BASE_FRAMERATE, 30f * BASE_FRAMERATE);
		} else {
			self.monsterinfo.idle_framenum = level.framenum + (int)random(15f * BASE_FRAMERATE);
		}
	}
}


/*
=============
ai_charge

Turns towards target and advances
Use this call with a distnace of 0 to replace ai_face
==============
*/
void(entity self, float dist) ai_charge =
{
	vector	v;
	
#ifdef GROUND_ZERO
	float	ofs;

	// PMM - made AI_MANUAL_STEERING affect things differently here .. they turn, but
	// don't set the ideal_yaw

	// This is put in there so monsters won't move towards the origin after killing
	// a tesla. This could be problematic, so keep an eye on it.
	if(!self.enemy || !self.enemy.inuse)
		return;

	// save blindfire target
	if (visible(self, self.enemy))
		self.monsterinfo.blind_fire_target = self.enemy.s.origin;

	if (!(self.monsterinfo.aiflags & AI_MANUAL_STEERING))
	{
#endif
		v = self.enemy.s.origin - self.s.origin;
		self.ideal_yaw = vectoyaw(v);
#ifdef GROUND_ZERO
	}
#endif

	M_ChangeYaw(self);

	if (dist)
	{
#ifdef GROUND_ZERO
		if (self.monsterinfo.aiflags & AI_CHARGING)
		{
			M_MoveToGoal (self, dist);
			return;
		}
		// circle strafe support
		if (self.monsterinfo.attack_state == AS_SLIDING)
		{
			// if we're fighting a tesla, NEVER circle strafe
			if ((self.enemy) && (self.enemy.classname) && (self.enemy.classname == "tesla"))
				ofs = 0;
			else if (self.monsterinfo.lefty)
				ofs = 90f;
			else
				ofs = -90f;
			
			if (M_walkmove (self, self.ideal_yaw + ofs, dist))
				return;
				
			self.monsterinfo.lefty = !self.monsterinfo.lefty;
			M_walkmove (self, self.ideal_yaw - ofs, dist);
		}
		else
#endif
			M_walkmove(self, self.s.angles[YAW], dist);
	}
}


/*
=============
ai_turn

don't move, but turn towards ideal_yaw
Distance is for slight position adjustments needed by the animations
=============
*/
void(entity self, float dist) ai_turn =
{
	if (dist)
		M_walkmove(self, self.s.angles[YAW], dist);

	if (FindTarget(self))
		return;

#ifdef GROUND_ZERO
	if (!(self.monsterinfo.aiflags & AI_MANUAL_STEERING))
#endif
		M_ChangeYaw(self);
}


/*

.enemy
Will be world if not currently angry at anyone.

.movetarget
The next path spot to walk toward.  If .enemy, ignore .movetarget.
When an enemy is killed, the monster will try to return to it's path.

.hunt_time
Set to time + something when the player is in sight, but movement straight for
him is blocked.  This causes the monster to use wall following code for
movement direction instead of sighting on the player.

.ideal_yaw
A yaw angle of the intended direction, which will be turned towards at up
to 45 deg / state.  If the enemy is in view and hunt_time is not active,
this will be the exact line towards the enemy.

.pausetime
A monster will leave it's stand state and head towards it's .movetarget when
time > .pausetime.

walkmove(angle, speed) primitive is all or nothing
*/

const float MELEE_DISTANCE	= 80f;

/*
=============
range

returns the range catagorization of an entity reletive to self
0   melee range, will become hostile even if back is turned
1   visibility and infront, or visibility and show hostile
2   infront and show hostile
3   only triggered by damage
=============
*/
range_t(entity self, entity other) range =
{
	vector	v;
	float	len;

	v = self.s.origin - other.s.origin;
	len = VectorLength(v);
	if (len < MELEE_DISTANCE)
		return RANGE_MELEE;
	if (len < 500)
		return RANGE_NEAR;
	if (len < 1000)
		return RANGE_MID;
	return RANGE_FAR;
}

//============================================================================
inline void(entity self, float time) AttackFinished =
{
	self.monsterinfo.attack_finished = level.framenum + (int)(time * BASE_FRAMERATE);
}

void(entity self) HuntTarget =
{
	vector	vec;
	
	self.goalentity = self.enemy;
	if (self.monsterinfo.aiflags & AI_STAND_GROUND)
		self.monsterinfo.stand(self);
	else
		self.monsterinfo.run(self);
	vec = self.enemy.s.origin - self.s.origin;
	self.ideal_yaw = vectoyaw(vec);
	// wait a while before first attack
	if (!(self.monsterinfo.aiflags & AI_STAND_GROUND))
		AttackFinished(self, 1);
}

void(entity self) FoundTarget =
{
	// let other monsters see this monster for a while
	if (self.enemy.is_client)
	{
#ifdef GROUND_ZERO
		if (self.enemy.flags & FL_DISGUISED)
			self.enemy.flags &= ~FL_DISGUISED;
#endif
		
		level.sight_entity = self;
		level.sight_entity_framenum = level.framenum;
		level.sight_entity.light_level = 128;
	}

	self.show_hostile = level.framenum + 1 * BASE_FRAMERATE;   // wake up other monsters

	self.monsterinfo.last_sighting = self.enemy.s.origin;
	self.monsterinfo.trail_framenum = level.framenum;
	
#ifdef GROUND_ZERO
	self.monsterinfo.blind_fire_target = self.enemy.s.origin;
	self.monsterinfo.blind_fire_framedelay = 0;
#endif

	if (!self.combattarget)
	{
		HuntTarget(self);
		return;
	}

	self.goalentity = self.movetarget = G_PickTarget(self.combattarget);
	if (!self.movetarget)
	{
		self.goalentity = self.movetarget = self.enemy;
		HuntTarget(self);
		gi.dprintf("%s at %s, combattarget %s not found\n", self.classname, vtos(self.s.origin), self.combattarget);
		return;
	}

	// clear out our combattarget, these are a one shot deal
	self.combattarget = 0;
	self.monsterinfo.aiflags |= AI_COMBAT_POINT;

	// clear the targetname, that point is ours!
	self.movetarget.targetname = 0;
	self.monsterinfo.pause_framenum = 0;

	// run for it
	self.monsterinfo.run(self);
}


/*
===========
FindTarget

Self is currently not attacking anything, so try to find a target

Returns TRUE if an enemy was sighted

When a player fires a missile, the point of impact becomes a fakeplayer so
that monsters that see the impact will respond as if they had seen the
player.

To avoid spending too much time, only a single client (or fakeclient) is
checked each frame.  This means multi player games will have slightly
slower noticing monsters.
============
*/
bool(entity self) FindTarget =
{
	entity	cl;
	bool	heardit;
	int	r;

	if (self.monsterinfo.aiflags & AI_GOOD_GUY) {
		if (self.goalentity && self.goalentity.inuse && self.goalentity.classname) {
			if (self.goalentity.classname == "target_actor")
				return false;
		}

		//FIXME look for monsters?
		return false;
	}

	// if we're going to a combat point, just proceed
	if (self.monsterinfo.aiflags & AI_COMBAT_POINT)
		return false;

// if the first spawnflag bit is set, the monster will only wake up on
// really seeing the player, not another monster getting angry or hearing
// something

// revised behavior so they will wake up if they "see" a player make a noise
// but not weapon impact/explosion noises

	heardit = false;
	if ((level.sight_entity_framenum >= (level.framenum - 1)) && !(self.spawnflags & 1))
	{
		cl = level.sight_entity;
		if (cl.enemy == self.enemy)
			return false;
	}
#ifdef GROUND_ZERO
	else if (level.disguise_violation_framenum > level.framenum)
		cl = level.disguise_violator;
#endif
	else if (level.sound_entity_framenum >= (level.framenum - 1)) {
		cl = level.sound_entity;
		heardit = true;
	} else if (!(self.enemy) && (level.sound2_entity_framenum >= (level.framenum - 1)) && !(self.spawnflags & 1)) {
		cl = level.sound2_entity;
		heardit = true;
	} else {
		cl = level.sight_client;
		if (!cl)
			return false;   // no clients to get mad at
	}

	// if the entity went away, forget it
	if (!cl.inuse)
		return false;

	if (cl == self.enemy)
		return true;    // JDC false;

#ifdef GROUND_ZERO
	if ((self.monsterinfo.aiflags & AI_HINT_PATH) && coop.intVal)
		heardit = false;
#endif

	if (cl.is_client) {
		if (cl.flags & FL_NOTARGET)
			return false;
	} else if (cl.svflags & SVF_MONSTER) {
		if (!cl.enemy)
			return false;
		if (cl.enemy.flags & FL_NOTARGET)
			return false;
	} else if (heardit) {
		if (cl.owner && cl.owner.flags & FL_NOTARGET)
			return false;
	} else
		return false;

	if (!heardit) {
		r = range(self, cl);

		if (r == RANGE_FAR)
			return false;

// this is where we would check invisibility

		// is client in an spot too dark to be seen?
		if (cl.light_level <= 5)
			return false;

		if (!visible(self, cl)) {
			return false;
		}

		if (r == RANGE_NEAR) {
			if (cl.show_hostile < level.framenum && !infront(self, cl)) {
				return false;
			}
		} else if (r == RANGE_MID) {
			if (!infront(self, cl)) {
				return false;
			}
		}

		self.enemy = cl;

		if (self.enemy.classname != "player_noise") {
			self.monsterinfo.aiflags &= ~AI_SOUND_TARGET;

			if (!self.enemy.is_client) {
				self.enemy = self.enemy.enemy;
				if (!self.enemy.is_client) {
					self.enemy = 0;
					return false;
				}
			}
		}
	} else { // heardit
		vector	temp;

		if (self.spawnflags & 1) {
			if (!visible(self, cl))
				return false;
		} else {
			if (!gi.inPHS(self.s.origin, cl.s.origin))
				return false;
		}

		temp = cl.s.origin - self.s.origin;

		if (VectorLength(temp) > 1000) { // too far to hear
			return false;
		}

		// check area portals - if they are different and not connected then we can't hear it
		if (cl.areanum != self.areanum)
			if (!gi.AreasConnected(self.areanum, cl.areanum))
				return false;

		self.ideal_yaw = vectoyaw(temp);
		
#ifdef GROUND_ZERO
		if (!(self.monsterinfo.aiflags & AI_MANUAL_STEERING))
#endif
			M_ChangeYaw(self);

		// hunt the sound for a bit; hopefully find the real player
		self.monsterinfo.aiflags |= AI_SOUND_TARGET;
		self.enemy = cl;
	}

//
// got one
//
#ifdef GROUND_ZERO
	// PMM - if we got an enemy, we need to bail out of hint paths, so take over here
	if (self.monsterinfo.aiflags & AI_HINT_PATH)
		// this calls foundtarget for us
		hintpath_stop (self);
	else
#endif
		FoundTarget(self);

	if (!(self.monsterinfo.aiflags & AI_SOUND_TARGET) && (self.monsterinfo.sight))
		self.monsterinfo.sight(self, self.enemy);

	return true;
}


//=============================================================================

/*
============
FacingIdeal

============
*/
static bool(entity self) FacingIdeal =
{
	float   delta;

	delta = anglemod(self.s.angles[YAW] - self.ideal_yaw);
	if (delta > 45 && delta < 315)
		return false;
	return true;
}


//=============================================================================

bool(entity self) M_CheckAttack =
{
	vector	spot1, spot2;
	float	chance;
	trace_t	tr;

	if (self.enemy.health > 0) {
		// see if any entities are in the way of the shot
		spot1 = self.s.origin;
		spot1.z += self.viewheight;
		spot2 = self.enemy.s.origin;
		spot2.z += self.enemy.viewheight;

		gi.traceline(&tr, spot1, spot2, self, CONTENTS_SOLID | CONTENTS_MONSTER | CONTENTS_SLIME | CONTENTS_LAVA | CONTENTS_WINDOW);

		// do we have a clear shot?
		if (tr.ent != self.enemy)
		{
#ifdef GROUND_ZERO
			// PGM - we want them to go ahead and shoot at info_notnulls if they can.
			if(self.enemy.solid != SOLID_NOT || tr.fraction < 1.0)
			{
				// PMM - if we can't see our target, and we're not blocked by a monster, go into blind fire if available
				if (!(tr.ent.svflags & SVF_MONSTER) && !visible(self, self.enemy))
				{
					if ((self.monsterinfo.blindfire) && (self.monsterinfo.blind_fire_framedelay <= (20.0 * BASE_FRAMERATE)))
					{
						if (level.framenum < self.monsterinfo.attack_finished)
						{
							return false;
						}
						if (level.framenum < (self.monsterinfo.trail_framenum + self.monsterinfo.blind_fire_framedelay))
						{
							// wait for our time
							return false;
						}
						else
						{
							// make sure we're not going to shoot a monster
							gi.traceline(&tr, spot1, self.monsterinfo.blind_fire_target, self, CONTENTS_MONSTER);
							if (tr.allsolid || tr.startsolid || ((tr.fraction < 1.0) && (tr.ent != self.enemy)))
								return false;

							self.monsterinfo.attack_state = AS_BLIND;
							return true;
						}
					}
				}
				// pmm
#endif
				return false;
#ifdef GROUND_ZERO
			}
#endif
		}
	}

	// melee attack
	if (enemy_range == RANGE_MELEE) {
		// don't always melee in easy mode
		if (skill.intVal == 0 && (Q_rand() & 3))
		{
#ifdef GROUND_ZERO
			self.monsterinfo.attack_state = AS_STRAIGHT;
#endif
			return false;
		}
		if (self.monsterinfo.melee)
			self.monsterinfo.attack_state = AS_MELEE;
		else
			self.monsterinfo.attack_state = AS_MISSILE;
		return true;
	}

// missile attack
	if (!self.monsterinfo.attack)
	{
#ifdef GROUND_ZERO
		self.monsterinfo.attack_state = AS_STRAIGHT;
#endif
		return false;
	}

	if (level.framenum < self.monsterinfo.attack_finished)
		return false;

	if (enemy_range == RANGE_FAR)
		return false;

	if (self.monsterinfo.aiflags & AI_STAND_GROUND) {
		chance = 0.4f;
	} else if (enemy_range == RANGE_MELEE) {
		chance = 0.2f;
	} else if (enemy_range == RANGE_NEAR) {
		chance = 0.1f;
	} else if (enemy_range == RANGE_MID) {
		chance = 0.02f;
	} else {
		return false;
	}

	if (skill.intVal == 0)
		chance *= 0.5f;
	else if (skill.intVal >= 2)
		chance *= 2;

	if (random() < chance || self.enemy.solid == SOLID_NOT)
	{
		self.monsterinfo.attack_state = AS_MISSILE;
		self.monsterinfo.attack_finished = level.framenum + (int)random(2f * BASE_FRAMERATE);
		return true;
	}

	if (self.flags & FL_FLY) {
#ifdef GROUND_ZERO
		// originally, just 0.3
		float strafe_chance;
		
		// if enemy is tesla, never strafe
		if (self.enemy && self.enemy.classname == "tesla")
			strafe_chance = 0;
		else if (self.classname != "monster_daedalus")
			strafe_chance = 0.8;
		else
			strafe_chance = 0.6;


		if (random() < strafe_chance)
#else
		if (random() < 0.3f)
#endif
			self.monsterinfo.attack_state = AS_SLIDING;
		else
			self.monsterinfo.attack_state = AS_STRAIGHT;
	}

#ifdef GROUND_ZERO
	else
	{
		if (random() < 0.4)
			self.monsterinfo.attack_state = AS_SLIDING;
		else
			self.monsterinfo.attack_state = AS_STRAIGHT;
	}
#endif

	return false;
}


/*
=============
ai_run_melee

Turn and close until within an angle to launch a melee attack
=============
*/
static void(entity self) ai_run_melee =
{
	self.ideal_yaw = enemy_yaw;

#ifdef GROUND_ZERO
	if (!(self.monsterinfo.aiflags & AI_MANUAL_STEERING))
#endif
		M_ChangeYaw(self);

	if (FacingIdeal(self)) {
		self.monsterinfo.melee(self);
		self.monsterinfo.attack_state = AS_STRAIGHT;
	}
}


/*
=============
ai_run_missile

Turn in place until within an angle to launch a missile attack
=============
*/
static void(entity self) ai_run_missile =
{
	self.ideal_yaw = enemy_yaw;

#ifdef GROUND_ZERO
	if (!(self.monsterinfo.aiflags & AI_MANUAL_STEERING))
#endif
		M_ChangeYaw(self);

	if (FacingIdeal(self)) {
		self.monsterinfo.attack(self);

#ifdef GROUND_ZERO	
		if (self.monsterinfo.attack_state == AS_MISSILE || self.monsterinfo.attack_state == AS_BLIND)
#endif
			self.monsterinfo.attack_state = AS_STRAIGHT;
	}
}

// temp
#ifdef GROUND_ZERO
const float MAX_SIDESTEP	= 8.0;
#endif

/*
=============
ai_run_slide

Strafe sideways, but stay at aproximately the same range
=============
*/
static void(entity self, float distance) ai_run_slide =
{
	float   ofs;

	self.ideal_yaw = enemy_yaw;

#ifdef GROUND_ZERO
	if (!(self.monsterinfo.aiflags & AI_MANUAL_STEERING))
		M_ChangeYaw(self);

	if (!(self.flags & FL_FLY))
		distance = minf(distance, MAX_SIDESTEP);
#endif

	if (self.monsterinfo.lefty)
		ofs = 90f;
	else
		ofs = -90f;

	if (M_walkmove(self, self.ideal_yaw + ofs, distance))
		return;

#ifdef GROUND_ZERO
	// PMM - if we're dodging, give up on it and go straight
	if (self.monsterinfo.aiflags & AI_DODGING)
	{
		monster_done_dodge (self);
		// by setting as_straight, caller will know to try straight move
		self.monsterinfo.attack_state = AS_STRAIGHT;
		return;
	}
#endif

	self.monsterinfo.lefty = !self.monsterinfo.lefty;

#ifdef GROUND_ZERO
	if (M_walkmove (self, self.ideal_yaw - ofs, distance))
		return;

	// if we're dodging, give up on it and go straight
	if (self.monsterinfo.aiflags & AI_DODGING)
		monster_done_dodge (self);

	// the move failed, so signal the caller (ai_run) to try going straight
	self.monsterinfo.attack_state = AS_STRAIGHT;
#else
	M_walkmove(self, self.ideal_yaw - ofs, distance);
#endif
}


/*
=============
ai_checkattack

Decides if we're going to attack or do something else
used by ai_run and ai_stand
=============
*/
bool(entity self, float dist) ai_checkattack =
{
	vector	temp;
	bool	hesDeadJim;

// this causes monsters to run blindly to the combat point w/o firing
	if (self.goalentity) {
		if (self.monsterinfo.aiflags & AI_COMBAT_POINT)
			return false;

		if (self.monsterinfo.aiflags & AI_SOUND_TARGET) {
			if ((level.framenum - self.enemy.last_sound_framenum) > 5.0f * BASE_FRAMERATE) {
				if (self.goalentity == self.enemy) {
					if (self.movetarget)
						self.goalentity = self.movetarget;
					else
						self.goalentity = null_entity;
				}
				self.monsterinfo.aiflags &= ~AI_SOUND_TARGET;
				if (self.monsterinfo.aiflags & AI_TEMP_STAND_GROUND)
					self.monsterinfo.aiflags &= ~(AI_STAND_GROUND | AI_TEMP_STAND_GROUND);
			} else {
				self.show_hostile = level.framenum + 1 * BASE_FRAMERATE;
				return false;
			}
		}
	}

	enemy_vis = false;

// see if the enemy is dead
	hesDeadJim = false;
	if ((!self.enemy) || (!self.enemy.inuse)) {
		hesDeadJim = true;
	} else if (self.monsterinfo.aiflags & AI_MEDIC) {
		if (!(self.enemy.inuse) || self.enemy.health > 0) {
			hesDeadJim = true;
		}
	} else {
		if (self.monsterinfo.aiflags & AI_BRUTAL) {
			if (self.enemy.health <= -80)
				hesDeadJim = true;
		} else {
			if (self.enemy.health <= 0)
				hesDeadJim = true;
		}
	}

	if (hesDeadJim) {
		self.monsterinfo.aiflags &= ~AI_MEDIC;
		self.enemy = 0;
		// FIXME: look all around for other targets
		if (self.oldenemy && self.oldenemy.health > 0)
		{
			self.enemy = self.oldenemy;
			self.oldenemy = 0;
			HuntTarget(self);
		}
#ifdef GROUND_ZERO
		// multiple teslas make monsters lose track of the player.
		else if (self.monsterinfo.last_player_enemy && self.monsterinfo.last_player_enemy.health > 0)
		{
			self.enemy = self.monsterinfo.last_player_enemy;
			self.oldenemy = 0;
			self.monsterinfo.last_player_enemy = 0;
			HuntTarget (self);
		}
#endif
		else
		{
			if (self.movetarget) {
				self.goalentity = self.movetarget;
				self.monsterinfo.walk(self);
			} else {
				// we need the pausetime otherwise the stand code
				// will just revert to walking with no target and
				// the monsters will wonder around aimlessly trying
				// to hunt the world entity
				self.monsterinfo.pause_framenum = INT_MAX;
				self.monsterinfo.stand(self);
			}
			return true;
		}
	}

	self.show_hostile = level.framenum + 1 * BASE_FRAMERATE;   // wake up other monsters

// check knowledge of enemy
	enemy_vis = visible(self, self.enemy);
	if (enemy_vis) {
		self.monsterinfo.search_framenum = level.framenum + 5 * BASE_FRAMERATE;
		self.monsterinfo.last_sighting = self.enemy.s.origin;

#ifdef GROUND_ZERO
		// PMM
		self.monsterinfo.aiflags &= ~AI_LOST_SIGHT;
		self.monsterinfo.trail_framenum = level.framenum;
		self.monsterinfo.blind_fire_target = self.enemy.s.origin;
		self.monsterinfo.blind_fire_framedelay = 0;
		// pmm
#endif
	}

	enemy_range = range(self, self.enemy);
	temp = self.enemy.s.origin - self.s.origin;
	enemy_yaw = vectoyaw(temp);
	
#ifdef GROUND_ZERO
	// PMM -- reordered so the monster specific checkattack is called before the run_missle/melee/checkvis
	// stuff .. this allows for, among other things, circle strafing and attacking while in ai_run
	bool retval = self.monsterinfo.checkattack (self);
	if (retval)
	{
		// PMM
#endif

		if (self.monsterinfo.attack_state == AS_MISSILE)
		{
			ai_run_missile(self);
			return true;
		}
		if (self.monsterinfo.attack_state == AS_MELEE)
		{
			ai_run_melee(self);
			return true;
		}
#ifdef GROUND_ZERO
		if (self.monsterinfo.attack_state == AS_BLIND)
		{
			ai_run_missile (self);
			return true;
		}
#endif

		// if enemy is not currently visible, we will never attack
		if (!enemy_vis)
			return false;
#ifdef GROUND_ZERO
		// PMM
	}
	return retval;
#else
	return self.monsterinfo.checkattack(self);
#endif
}

// trail.qc
entity(entity self) PlayerTrail_PickFirst;
entity(entity self) PlayerTrail_PickNext;

/*
=============
ai_run

The monster has an enemy it is trying to kill
=============
*/
void(entity self, float dist) ai_run =
{
	vector	v;
	entity	tempgoal;
	entity	save;
	bool	new;
	entity	marker;
	float	d1, d2;
	trace_t	tr;
	vector	v_forward, v_right;
	float	left, center, right;
	vector	left_target, right_target;
#ifdef GROUND_ZERO
	bool	retval;
	bool	alreadyMoved = false;
	bool	gotcha = false;
	entity	realEnemy;
#endif

	// if we're going to a combat point, just proceed
	if (self.monsterinfo.aiflags & AI_COMBAT_POINT)
	{
		M_MoveToGoal(self, dist);
		return;
	}

#ifdef GROUND_ZERO
	if (self.monsterinfo.aiflags & AI_DUCKED)
		self.monsterinfo.aiflags &= ~AI_DUCKED;
	if (self.maxs[2] != self.monsterinfo.base_height)
		monster_duck_up (self);

	// if we're currently looking for a hint path
	if (self.monsterinfo.aiflags & AI_HINT_PATH)
	{
		M_MoveToGoal (self, dist);

		if (!self.inuse)
			return;

		// first off, make sure we're looking for the player, not a noise he made
		if (self.enemy)
		{
			if (self.enemy.inuse)
			{
				if (self.enemy.classname != "player_noise")
					realEnemy = self.enemy;
				else if (self.enemy.owner)
					realEnemy = self.enemy.owner;
				else // uh oh, can't figure out enemy, bail
				{
					self.enemy = 0;
					hintpath_stop (self);
					return;
				}
			}
			else
			{
				self.enemy = 0;
				hintpath_stop (self);
				return;
			}
		}
		else
		{
			hintpath_stop (self);
			return;
		}

		if (coop.intVal)
		{
			// if we're in coop, check my real enemy first .. if I SEE him, set gotcha to true
			if (self.enemy && visible(self, realEnemy))
				gotcha = true;
			else // otherwise, let FindTarget bump us out of hint paths, if appropriate
				FindTarget(self);
		}
		else if (self.enemy && visible(self, realEnemy))
			gotcha = true;
		
		// if we see the player, disconnect from hintpaths and start looking normally.
		if (gotcha)
			hintpath_stop (self);

		return;
	}
#endif

	if (self.monsterinfo.aiflags & AI_SOUND_TARGET)
	{
		if (!self.enemy || VectorLength(self.s.origin - self.enemy.s.origin) < 64)
		{
			self.monsterinfo.aiflags |= (AI_STAND_GROUND | AI_TEMP_STAND_GROUND);
			self.monsterinfo.stand(self);
			return;
		}

		M_MoveToGoal(self, dist);
		
#ifdef GROUND_ZERO
		alreadyMoved = true;

		if (!self.inuse)
			return;			// PGM - g_touchtrigger free problem
#endif

		if (!FindTarget(self))
			return;
	}

#ifdef GROUND_ZERO
	retval = ai_checkattack (self, dist);

	// don't strafe if we can't see our enemy
	if (!enemy_vis && self.monsterinfo.attack_state == AS_SLIDING)
		self.monsterinfo.attack_state = AS_STRAIGHT;
	// unless we're dodging (dodging out of view looks smart)
	if (self.monsterinfo.aiflags & AI_DODGING)
		self.monsterinfo.attack_state = AS_SLIDING;
#else
	if (ai_checkattack(self, dist))
		return;
#endif

	if (self.monsterinfo.attack_state == AS_SLIDING)
	{
#ifdef GROUND_ZERO
		// protect against double moves
		if (!alreadyMoved)
#endif
			ai_run_slide(self, dist);

#ifdef GROUND_ZERO
		// we're using attack_state as the return value out of ai_run_slide to indicate whether or not the
		// move succeeded.  If the move succeeded, and we're still sliding, we're done in here (since we've
		// had our chance to shoot in ai_checkattack, and have moved).
		// if the move failed, our state is as_straight, and it will be taken care of below
		if (!retval && self.monsterinfo.attack_state == AS_SLIDING)
#endif
			return;
	}
#ifdef GROUND_ZERO
	else if (self.monsterinfo.aiflags & AI_CHARGING)
	{
		self.ideal_yaw = enemy_yaw;
		if (!(self.monsterinfo.aiflags & AI_MANUAL_STEERING))
			M_ChangeYaw (self);
	}

	if (retval)
	{
		// PMM - is this useful? Monsters attacking usually call the ai_charge routine..
		// the only monster this affects should be the soldier
		if (dist != 0 && !alreadyMoved && self.monsterinfo.attack_state == AS_STRAIGHT && !(self.monsterinfo.aiflags & AI_STAND_GROUND))
			M_MoveToGoal (self, dist);

		if (self.enemy && self.enemy.inuse && enemy_vis)
		{
			self.monsterinfo.aiflags &= ~AI_LOST_SIGHT;
			self.monsterinfo.last_sighting = self.enemy.s.origin;
			self.monsterinfo.trail_framenum = level.framenum;

			self.monsterinfo.blind_fire_target = self.enemy.s.origin;
			self.monsterinfo.blind_fire_framedelay = 0;
		}
		return;
	}
#endif

	if (self.enemy && self.enemy.inuse && enemy_vis)
	{
#ifdef GROUND_ZERO
		if (!alreadyMoved)
#endif
			M_MoveToGoal(self, dist);
#ifdef GROUND_ZERO
		if (!self.inuse)
			return;
#endif
		self.monsterinfo.aiflags &= ~AI_LOST_SIGHT;
		self.monsterinfo.last_sighting = self.enemy.s.origin;
		self.monsterinfo.trail_framenum = level.framenum;
		
#ifdef GROUND_ZERO
		self.monsterinfo.blind_fire_target = self.enemy.s.origin;
		self.monsterinfo.blind_fire_framedelay = 0;
#endif
		return;
	}

#ifdef GROUND_ZERO
	// if we've been looking (unsuccessfully) for the player for 10 seconds
	// PMM - reduced to 5, makes them much nastier
	if ((self.monsterinfo.trail_framenum + (5 * BASE_FRAMERATE)) <= level.framenum)
	{
		// and we haven't checked for valid hint paths in the last 10 seconds
		if ((self.monsterinfo.last_hint_framenum + (10 * BASE_FRAMERATE)) <= level.framenum)
		{
			// check for hint_paths.
			self.monsterinfo.last_hint_framenum = level.framenum;

			if (monsterlost_checkhint(self))
				return;
		}
	}
#endif

	// coop will change to another enemy if visible
	if (coop.intVal)
	{
		// FIXME: insane guys get mad with this, which causes crashes!
		if (FindTarget(self))
			return;
	}

	if ((self.monsterinfo.search_framenum) && (level.framenum > (self.monsterinfo.search_framenum + 20 * BASE_FRAMERATE)))
	{
#ifdef GROUND_ZERO
		if (!alreadyMoved)
#endif
			M_MoveToGoal(self, dist);
		self.monsterinfo.search_framenum = 0;
		return;
	}

	save = self.goalentity;
	tempgoal = G_Spawn();
	self.goalentity = tempgoal;

	new = false;

	if (!(self.monsterinfo.aiflags & AI_LOST_SIGHT)) {
		// just lost sight of the player, decide where to go first
		self.monsterinfo.aiflags |= (AI_LOST_SIGHT | AI_PURSUIT_LAST_SEEN);
		self.monsterinfo.aiflags &= ~(AI_PURSUE_NEXT | AI_PURSUE_TEMP);
		new = true;
	}

	if (self.monsterinfo.aiflags & AI_PURSUE_NEXT) {
		self.monsterinfo.aiflags &= ~AI_PURSUE_NEXT;

		// give ourself more time since we got this far
		self.monsterinfo.search_framenum = level.framenum + 5 * BASE_FRAMERATE;

		if (self.monsterinfo.aiflags & AI_PURSUE_TEMP) {
			self.monsterinfo.aiflags &= ~AI_PURSUE_TEMP;
			marker = 0;
			self.monsterinfo.last_sighting = self.monsterinfo.saved_goal;
			new = true;
		} else if (self.monsterinfo.aiflags & AI_PURSUIT_LAST_SEEN) {
			self.monsterinfo.aiflags &= ~AI_PURSUIT_LAST_SEEN;
			marker = PlayerTrail_PickFirst(self);
		} else {
			marker = PlayerTrail_PickNext(self);
		}

		if (marker) {
			self.monsterinfo.last_sighting = marker.s.origin;
			self.monsterinfo.trail_framenum = marker.timestamp;
			self.s.angles[YAW] = self.ideal_yaw = marker.s.angles[YAW];

			new = true;
		}
	}

	v = self.s.origin - self.monsterinfo.last_sighting;
	d1 = VectorLength(v);
	if (d1 <= dist) {
		self.monsterinfo.aiflags |= AI_PURSUE_NEXT;
		dist = d1;
	}

	self.goalentity.s.origin = self.monsterinfo.last_sighting;

	if (new) {
		gi.trace(&tr, self.s.origin, self.mins, self.maxs, self.monsterinfo.last_sighting, self, MASK_PLAYERSOLID);
		if (tr.fraction < 1) {
			v = self.goalentity.s.origin - self.s.origin;
			d1 = VectorLength(v);
			center = tr.fraction;
			d2 = d1 * ((center + 1) / 2);
			self.s.angles[YAW] = self.ideal_yaw = vectoyaw(v);
			AngleVectors(self.s.angles, &v_forward, &v_right, 0);

			v = [ d2, -16, 0 ];
			left_target = G_ProjectSource(self.s.origin, v, v_forward, v_right);
			gi.trace(&tr, self.s.origin, self.mins, self.maxs, left_target, self, MASK_PLAYERSOLID);
			left = tr.fraction;

			v = [ d2, 16, 0 ];
			right_target = G_ProjectSource(self.s.origin, v, v_forward, v_right);
			gi.trace(&tr, self.s.origin, self.mins, self.maxs, right_target, self, MASK_PLAYERSOLID);
			right = tr.fraction;

			center = (d1 * center) / d2;
			if (left >= center && left > right)
			{
				if (left < 1)
				{
					v = [ d2 * left * 0.5f, -16, 0 ];
					left_target = G_ProjectSource(self.s.origin, v, v_forward, v_right);
				}
				self.monsterinfo.saved_goal = self.monsterinfo.last_sighting;
				self.monsterinfo.aiflags |= AI_PURSUE_TEMP;
				self.goalentity.s.origin = left_target;
				self.monsterinfo.last_sighting = left_target;
				v = self.goalentity.s.origin - self.s.origin;
				self.s.angles[YAW] = self.ideal_yaw = vectoyaw(v);
			}
			else if (right >= center && right > left)
			{
				if (right < 1)
				{
					v = [ d2 * right * 0.5f, 16, 0 ];
					right_target = G_ProjectSource(self.s.origin, v, v_forward, v_right);
				}
				self.monsterinfo.saved_goal = self.monsterinfo.last_sighting;
				self.monsterinfo.aiflags |= AI_PURSUE_TEMP;
				self.goalentity.s.origin = right_target;
				self.monsterinfo.last_sighting = right_target;
				v = self.goalentity.s.origin - self.s.origin;
				self.s.angles[YAW] = self.ideal_yaw = vectoyaw(v);
			}
		}
	}

	M_MoveToGoal(self, dist);

#ifdef GROUND_ZERO
	if (!self.inuse)
		return;			// PGM - g_touchtrigger free problem
#endif

	G_FreeEdict(tempgoal);

	if (self.inuse)
		self.goalentity = save;
}

#endif