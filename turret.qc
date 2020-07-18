static void AnglesNormalize(__inout vector vec)
{
	while (vec[0] > 360)
		vec[0] -= 360;
	while (vec[0] < 0)
		vec[0] += 360;
	while (vec[1] > 360)
		vec[1] -= 360;
	while (vec[1] < 0)
		vec[1] += 360;
}

static float SnapToEights(float x)
{
	x *= 8.0f;
	if (x > 0.0f)
		x += 0.5f;
	else
		x -= 0.5f;
	return 0.125f * (int)x;
}


static void turret_blocked(entity self, entity other)
{
	entity attacker;

	if (other->takedamage) {
		if (self->teammaster->owner)
			attacker = self->teammaster->owner;
		else
			attacker = self->teammaster;
		T_Damage(other, self, attacker, vec3_origin, other->s.origin, vec3_origin, self->teammaster->dmg, 10, 0, MOD_CRUSH);
	}
}

/*QUAKED turret_breach (0 0 0) ?
This portion of the turret can change both pitch and yaw.
The model  should be made with a flat pitch.
It (and the associated base) need to be oriented towards 0.
Use "angle" to set the starting angle.

"speed"     default 50
"dmg"       default 10
"angle"     point this forward
"target"    point this at an info_notnull at the muzzle tip
"minpitch"  min acceptable pitch angle : default -30
"maxpitch"  max acceptable pitch angle : default 30
"minyaw"    min acceptable yaw angle   : default 0
"maxyaw"    max acceptable yaw angle   : default 360
*/

static void turret_breach_fire(entity self)
{
	vector  f, r, u;
	vector  start;
	int     damage;
	int     speed;

	AngleVectors(self->s.angles, &f, &r, &u);
	VectorMA(self->s.origin, self->move_origin[0], f, start);
	VectorMA(start, self->move_origin[1], r, start);
	VectorMA(start, self->move_origin[2], u, start);

	damage = (int)random(100f, 150f);
	speed = 550 + 50 * skill->intVal;
	fire_rocket(self->teammaster->owner, start, f, damage, speed, 150, damage);
	gi.positioned_sound(start, self, CHAN_WEAPON, gi.soundindex("weapons/rocklf1a.wav"), 1, ATTN_NORM, 0);
}

static void turret_breach_think(entity self)
{
	entity ent;
	vector  current_angles;
	vector  delta;

	VectorCopy(self->s.angles, current_angles);
	AnglesNormalize(current_angles);

	AnglesNormalize(self->move_angles);
	if (self->move_angles[PITCH] > 180)
		self->move_angles[PITCH] -= 360;

	// clamp angles to mins & maxs
	if (self->move_angles[PITCH] > self->pos1[PITCH])
		self->move_angles[PITCH] = self->pos1[PITCH];
	else if (self->move_angles[PITCH] < self->pos2[PITCH])
		self->move_angles[PITCH] = self->pos2[PITCH];

	if ((self->move_angles[YAW] < self->pos1[YAW]) || (self->move_angles[YAW] > self->pos2[YAW])) {
		float   dmin, dmax;

		dmin = fabsf(self->pos1[YAW] - self->move_angles[YAW]);
		if (dmin < -180)
			dmin += 360;
		else if (dmin > 180)
			dmin -= 360;
		dmax = fabsf(self->pos2[YAW] - self->move_angles[YAW]);
		if (dmax < -180)
			dmax += 360;
		else if (dmax > 180)
			dmax -= 360;
		if (fabsf(dmin) < fabsf(dmax))
			self->move_angles[YAW] = self->pos1[YAW];
		else
			self->move_angles[YAW] = self->pos2[YAW];
	}

	VectorSubtract(self->move_angles, current_angles, delta);
	if (delta[0] < -180)
		delta[0] += 360;
	else if (delta[0] > 180)
		delta[0] -= 360;
	if (delta[1] < -180)
		delta[1] += 360;
	else if (delta[1] > 180)
		delta[1] -= 360;
	delta[2] = 0;

	if (delta[0] > self->speed * FRAMETIME)
		delta[0] = self->speed * FRAMETIME;
	if (delta[0] < -1 * self->speed * FRAMETIME)
		delta[0] = -1 * self->speed * FRAMETIME;
	if (delta[1] > self->speed * FRAMETIME)
		delta[1] = self->speed * FRAMETIME;
	if (delta[1] < -1 * self->speed * FRAMETIME)
		delta[1] = -1 * self->speed * FRAMETIME;

	VectorScale(delta, 1.0f / FRAMETIME, self->avelocity);

	self->nextthink = level.framenum + 1;

	for (ent = self->teammaster; ent; ent = ent->teamchain)
		ent->avelocity[1] = self->avelocity[1];

	// if we have adriver, adjust his velocities
	if (self->owner) {
		float   angle;
		float   target_zf;
		float   diff;
		vector  target;
		vector  dir;

		// angular is easy, just copy ours
		self->owner->avelocity[0] = self->avelocity[0];
		self->owner->avelocity[1] = self->avelocity[1];

		// x & y
		angle = self->s.angles[1] + self->owner->move_origin[1];
		angle = DEG2RAD(angle);
		target[0] = SnapToEights(self->s.origin[0] + cosf(angle) * self->owner->move_origin[0]);
		target[1] = SnapToEights(self->s.origin[1] + sinf(angle) * self->owner->move_origin[0]);
		target[2] = self->owner->s.origin[2];

		VectorSubtract(target, self->owner->s.origin, dir);
		self->owner->velocity[0] = dir[0] * 1.0f / FRAMETIME;
		self->owner->velocity[1] = dir[1] * 1.0f / FRAMETIME;

		// z
		angle = DEG2RAD(self->s.angles[PITCH]);
		target_zf = SnapToEights(self->s.origin[2] + self->owner->move_origin[0] * tanf(angle) + self->owner->move_origin[2]);

		diff = target_zf - self->owner->s.origin[2];
		self->owner->velocity[2] = diff * 1.0f / FRAMETIME;

		if (self->spawnflags & 65536) {
			turret_breach_fire(self);
			self->spawnflags &= ~65536;
		}
	}
}

static void turret_breach_finish_init(entity self)
{
	// get and save info for muzzle location
	if (!self->target) {
		gi.dprintf("%s at %s needs a target\n", self->classname, vtos(self->s.origin));
	} else {
		self->target_ent = G_PickTarget(self->target);
		VectorSubtract(self->target_ent->s.origin, self->s.origin, self->move_origin);
		G_FreeEdict(self->target_ent);
	}

	self->teammaster->dmg = self->dmg;
	self->think = turret_breach_think;
	self->think(self);
}

static void SP_turret_breach(entity self)
{
	self->solid = SOLID_BSP;
	self->movetype = MOVETYPE_PUSH;
	gi.setmodel(self, self->model);

	if (!self->speed)
		self->speed = 50f;
	if (!self->dmg)
		self->dmg = 10;

	if (!st.minpitch)
		st.minpitch = -30f;
	if (!st.maxpitch)
		st.maxpitch = 30f;
	if (!st.maxyaw)
		st.maxyaw = 360f;

	self->pos1[PITCH] = -1 * st.minpitch;
	self->pos1[YAW]   = st.minyaw;
	self->pos2[PITCH] = -1 * st.maxpitch;
	self->pos2[YAW]   = st.maxyaw;

	self->ideal_yaw = self->s.angles[YAW];
	self->move_angles[YAW] = self->ideal_yaw;

	self->blocked = turret_blocked;

	self->think = turret_breach_finish_init;
	self->nextthink = level.framenum + 1;
	gi.linkentity(self);
}


/*QUAKED turret_base (0 0 0) ?
This portion of the turret changes yaw only.
MUST be teamed with a turret_breach.
*/

API_FUNC static void SP_turret_base(entity self)
{
	self->solid = SOLID_BSP;
	self->movetype = MOVETYPE_PUSH;
	gi.setmodel(self, self->model);
	self->blocked = turret_blocked;
	gi.linkentity(self);
}


/*QUAKED turret_driver (1 .5 0) (-16 -16 -24) (16 16 32)
Must NOT be on the team with the rest of the turret parts.
Instead it must target the turret_breach.
*/
static void turret_driver_die(entity self, entity inflictor, entity attacker, int damage, vector point)
{
	entity ent;

	// level the gun
	self->target_ent->move_angles[0] = 0;

	// remove the driver from the end of them team chain
	for (ent = self->target_ent->teammaster; ent->teamchain != self; ent = ent->teamchain)
		;
	ent->teamchain = world;
	self->teammaster = world;
	self->flags &= ~FL_TEAMSLAVE;

	self->target_ent->owner = world;
	self->target_ent->teammaster->owner = world;

	infantry_die(self, inflictor, attacker, damage, point);
	
	self->s.renderfx |= RF_FRAMELERP;
}

static void turret_driver_think(entity self)
{
	vector  target;
	vector  dir;
	int     reaction_time;

	self->nextthink = level.framenum + 1;

	if (self->enemy && (!self->enemy->inuse || self->enemy->health <= 0))
		self->enemy = world;

	if (!self->enemy) {
		if (!FindTarget(self))
			return;
		self->monsterinfo.trail_framenum = level.framenum;
		self->monsterinfo.aiflags &= ~AI_LOST_SIGHT;
	} else {
		if (visible(self, self->enemy)) {
			if (self->monsterinfo.aiflags & AI_LOST_SIGHT) {
				self->monsterinfo.trail_framenum = level.framenum;
				self->monsterinfo.aiflags &= ~AI_LOST_SIGHT;
			}
		} else {
			self->monsterinfo.aiflags |= AI_LOST_SIGHT;
			return;
		}
	}

	// let the turret know where we want it to aim
	VectorCopy(self->enemy->s.origin, target);
	target[2] += self->enemy->viewheight;
	VectorSubtract(target, self->target_ent->s.origin, dir);
	self->target_ent->move_angles = vectoangles(dir);

	// decide if we should shoot
	if (level.framenum < self->monsterinfo.attack_finished)
		return;

	reaction_time = (int)((3 - skill->intVal) * 1.0f * BASE_FRAMERATE);
	if ((level.framenum - self->monsterinfo.trail_framenum) < reaction_time)
		return;

	self->monsterinfo.attack_finished = (int)(level.framenum + reaction_time + 1.0f * BASE_FRAMERATE);
	//FIXME how do we really want to pass this along?
	self->target_ent->spawnflags |= 65536;
}

static void turret_driver_link(entity self)
{
	vector  vec;
	entity ent;

	self->think = turret_driver_think;
	self->nextthink = level.framenum + 1;

	self->target_ent = G_PickTarget(self->target);
	self->target_ent->owner = self;
	self->target_ent->teammaster->owner = self;
	VectorCopy(self->target_ent->s.angles, self->s.angles);

	vec[0] = self->target_ent->s.origin[0] - self->s.origin[0];
	vec[1] = self->target_ent->s.origin[1] - self->s.origin[1];
	vec[2] = 0;
	self->move_origin[0] = VectorLength(vec);

	VectorSubtract(self->s.origin, self->target_ent->s.origin, vec);
	vec = vectoangles(vec);
	AnglesNormalize(vec);
	self->move_origin[1] = vec[1];

	self->move_origin[2] = self->s.origin[2] - self->target_ent->s.origin[2];

	// add the driver to the end of them team chain
	for (ent = self->target_ent->teammaster; ent->teamchain; ent = ent->teamchain)
		;
	ent->teamchain = self;
	self->teammaster = self->target_ent->teammaster;
	self->flags |= FL_TEAMSLAVE;
}

API_FUNC static void SP_turret_driver(entity self)
{
	if (deathmatch->intVal) {
		G_FreeEdict(self);
		return;
	}

	self->movetype = MOVETYPE_PUSH;
	self->solid = SOLID_BBOX;
	self->s.modelindex = gi.modelindex("models/monsters/infantry/tris.md2");
	self->mins = '-16 -16 -24';
	self->maxs = '16 16 32';

	self->health = 100;
	self->gib_health = 0;
	self->mass = 200;
	self->viewheight = 24;

	self->die = turret_driver_die;
	self->monsterinfo.stand = infantry_stand;

	self->flags |= FL_NO_KNOCKBACK;

	level.total_monsters++;

	self->svflags |= SVF_MONSTER;
	self->takedamage = DAMAGE_AIM;
	self->use = monster_use;
	self->clipmask = MASK_MONSTERSOLID;
	VectorCopy(self->s.origin, self->s.old_origin);
	self->monsterinfo.aiflags |= AI_STAND_GROUND | AI_DUCKED;

	if (st.item) {
		self->item = FindItemByClassname(st.item);
		if (!self->item)
			gi.dprintf("%s at %s has bad item: %s\n", self->classname, vtos(self->s.origin), st.item);
	}

	self->think = turret_driver_link;
	self->nextthink = level.framenum + 1;

	gi.linkentity(self);
}
