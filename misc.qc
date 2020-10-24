/*QUAKED func_group (0 0 0) ?
Used to group brushes together just for editor convenience.
*/

//=====================================================

static void(entity ent, entity other, entity activator) Use_Areaportal =
{
	ent.count ^= 1;        // toggle state
	gi.SetAreaPortalState(ent.style, ent.count);
}

/*QUAKED func_areaportal (0 0 0) ?

This is a non-visible object that divides the world into
areas that are seperated when this portal is not activated.
Usually enclosed in the middle of a door.
*/
API_FUNC static void(entity ent) SP_func_areaportal =
{
	ent.use = Use_Areaportal;
	ent.count = 0;     // always start closed;
}

//=====================================================


/*
=================
Misc functions
=================
*/
PROGS_LOCAL INLINE vector(int damage) VelocityForDamage =
{
	return randomv('-100 -100 200', '100 100 300') * ((damage < 50) ? 0.7f : 1.2f);
}

PROGS_LOCAL void(entity ent) ClipGibVelocity =
{
	if (ent.velocity.x < -300)
		ent.velocity.x = -300f;
	else if (ent.velocity.x > 300)
		ent.velocity.x = 300f;
	if (ent.velocity.y < -300)
		ent.velocity.y = -300f;
	else if (ent.velocity.y > 300)
		ent.velocity.y = 300f;
	if (ent.velocity.z < 200)
		ent.velocity.z = 200f; // always some upwards
	else if (ent.velocity.z > 500)
		ent.velocity.z = 500f;
}


/*
=================
gibs
=================
*/
static void(entity self) gib_think =
{
	self.s.frame++;
	self.nextthink = level.framenum + 1;

	if (self.s.frame == 10) {
		self.think = G_FreeEdict;
		self.nextthink = level.framenum + (int)(random(8f, 18f) * BASE_FRAMERATE);
	}
}

void(entity self, entity other, vector normal, csurface_t surf) gib_touch =
{
	vector	normal_angles, right;

	if (self.groundentity == null_entity)
		return;

	self.touch = 0;

	if (normal) {
		gi.sound(self, CHAN_VOICE, gi.soundindex("misc/fhit3.wav"), 1, ATTN_NORM, 0);

		normal_angles = vectoangles(normal);
		AngleVectors(normal_angles, 0, &right, 0);
		self.s.angles = vectoangles(right);

		if (self.s.modelindex == sm_meat_index) {
			self.s.frame++;
			self.think = gib_think;
			self.nextthink = level.framenum + 1;
		}
	}
}

void(entity self, entity inflictor, entity attacker, int damage, vector point) gib_die =
{
	G_FreeEdict(self);
}

void(entity self, string gibname, int damage, gib_type_t type) ThrowGib =
{
	entity gib = G_Spawn();

	vector sz = self.size * 0.5f;
	vector origin = self.absmin + sz;
	gib.s.origin = origin + randomv(-sz, sz);

	gi.setmodel(gib, gibname);
	gib.solid = SOLID_NOT;
	gib.s.effects |= EF_GIB;
	gib.flags |= FL_NO_KNOCKBACK;
	gib.takedamage = true;
	gib.die = gib_die;

	float vscale;

	if (type == GIB_ORGANIC)
	{
		gib.movetype = MOVETYPE_TOSS;
		gib.touch = gib_touch;
		vscale = 0.5f;
	}
	else
	{
		gib.movetype = MOVETYPE_BOUNCE;
		vscale = 1.0f;
	}

	gib.velocity = self.velocity + (vscale * VelocityForDamage(damage));
	ClipGibVelocity(gib);
	gib.avelocity = randomv('600 600 600');

	gib.think = G_FreeEdict;
	gib.nextthink = level.framenum + (int)(random(10f, 20f) * BASE_FRAMERATE);

	gi.linkentity(gib);
}

void(entity self, string gibname, int damage, gib_type_t type) ThrowHead =
{
	self.s.skinnum = 0;
	self.s.frame = 0;
	self.mins = vec3_origin;
	self.maxs = vec3_origin;

	self.s.modelindex2 = 0;
	gi.setmodel(self, gibname);
	self.solid = SOLID_NOT;
	self.s.effects |= EF_GIB;
	self.s.effects &= ~EF_FLIES;
	self.s.sound = 0;
	self.flags |= FL_NO_KNOCKBACK;
	self.svflags &= ~SVF_MONSTER;
	self.takedamage = true;
	self.die = gib_die;

	float vscale;

	if (type == GIB_ORGANIC)
	{
		self.movetype = MOVETYPE_TOSS;
		self.touch = gib_touch;
		vscale = 0.5f;
	}
	else
	{
		self.movetype = MOVETYPE_BOUNCE;
		vscale = 1.0f;
	}

	self.velocity += (vscale * VelocityForDamage(damage));
	ClipGibVelocity(self);

	self.avelocity[YAW] = random(-600f, 600f);

	self.think = G_FreeEdict;
	self.nextthink = level.framenum + (int)(random(10f, 20f) * BASE_FRAMERATE);

	gi.linkentity(self);
}


void(entity self, int damage) ThrowClientHead =
{
	string	gibname;

	if (Q_rand() & 1)
	{
		gibname = "models/objects/gibs/head2/tris.md2";
		self.s.skinnum = 1;        // second skin is player
	}
	else
	{
		gibname = "models/objects/gibs/skull/tris.md2";
		self.s.skinnum = 0;
	}

	self.s.origin[2] += 32;
	self.s.frame = 0;
	gi.setmodel(self, gibname);
	self.mins = '-16 -16 0';
	self.maxs = '16 16 16';

	self.takedamage = false;
	self.solid = SOLID_NOT;
	self.s.effects = EF_GIB;
	self.s.sound = 0;
	self.flags |= FL_NO_KNOCKBACK;

	self.movetype = MOVETYPE_BOUNCE;
	self.velocity += VelocityForDamage(damage);

	if (self.is_client)
	{ // bodies in the queue don't have a client anymore
		self.client.anim_priority = ANIM_DEATH;
		self.client.anim_end = self.s.frame;
	}
	else
	{
		self.think = 0;
		self.nextthink = 0;
	}

	gi.linkentity(self);
}

/*
=================
debris
=================
*/
static void(entity self, entity inflictor, entity attacker, int damage, vector point) debris_die =
{
	G_FreeEdict(self);
}

void(entity self, string modelname, float speed, vector origin) ThrowDebris =
{
	entity chunk;
	vector v;

	chunk = G_Spawn();
	chunk.s.origin = origin;
	gi.setmodel(chunk, modelname);
	v.x = random(-100f, 100f);
	v.y = random(-100f, 100f);
	v.z = random(0f, 200f);
	chunk.velocity = self.velocity + (speed * v);
	chunk.movetype = MOVETYPE_BOUNCE;
	chunk.solid = SOLID_NOT;
	chunk.avelocity = randomv('600 600 600');
	chunk.think = G_FreeEdict;
	chunk.nextthink = level.framenum + (int)(random(5f, 10f) * BASE_FRAMERATE);
	chunk.s.frame = 0;
	chunk.flags = 0;
	chunk.classname = "debris";
	chunk.takedamage = true;
	chunk.die = debris_die;
	gi.linkentity(chunk);
}

/*QUAKED path_corner (.5 .3 0) (-8 -8 -8) (8 8 8) TELEPORT
Target: next path corner
Pathtarget: gets used when an entity that has
	this path_corner targeted touches it
*/

static void(entity self, entity other, vector plane, csurface_t surf) path_corner_touch =
{
	vector	v;
	entity	next;

	if (other.movetarget != self)
		return;

	if (other.enemy)
		return;

	if (self.pathtarget)
	{
		string savetarget = self.target;
		self.target = self.pathtarget;
		G_UseTargets(self, other);
		self.target = savetarget;
	}

	if (self.target)
		next = G_PickTarget(self.target);
	else
		next = world;

	if (next && (next.spawnflags & 1))
	{
		v = next.s.origin;
		v.z += next.mins.z;
		v.z -= other.mins.z;
		other.s.origin = v;
		next = G_PickTarget(next.target);
		other.s.event = EV_OTHER_TELEPORT;
	}

	other.goalentity = other.movetarget = next;

#ifdef SINGLE_PLAYER
	if (self.wait)
	{
		other.monsterinfo.pause_framenum = level.framenum + (int)(self.wait * BASE_FRAMERATE);
		other.monsterinfo.stand(other);
		return;
	}

	if (!other.movetarget)
	{
		other.monsterinfo.pause_framenum = INT_MAX;
		other.monsterinfo.stand(other);
	}
	else
	{
		v = other.goalentity.s.origin - other.s.origin;
		other.ideal_yaw = vectoyaw(v);
	}
#endif
}

API_FUNC static void(entity self) SP_path_corner =
{
	if (!self.targetname)
	{
		gi.dprintf("path_corner with no targetname at %s\n", vtos(self.s.origin));
		G_FreeEdict(self);
		return;
	}

	self.solid = SOLID_TRIGGER;
	self.touch = path_corner_touch;
	self.mins = '-8 -8 -8';
	self.maxs = '8 8 8';
	self.svflags |= SVF_NOCLIENT;
	gi.linkentity(self);
}

#ifdef SINGLE_PLAYER
/*QUAKED point_combat (0.5 0.3 0) (-8 -8 -8) (8 8 8) Hold
Makes this the target of a monster and it will head here
when first activated before going after the activator.  If
hold is selected, it will stay here.
*/
static void(entity self, entity other, vector plane, csurface_t surf) point_combat_touch =
{
	entity cactivator;

	if (other.movetarget != self)
		return;

	if (self.target)
	{
		other.target = self.target;
		other.goalentity = other.movetarget = G_PickTarget(other.target);
		if (!other.goalentity)
		{
			gi.dprintf("%s at %s target %s does not exist\n", self.classname, vtos(self.s.origin), self.target);
			other.movetarget = self;
		}
		self.target = 0;
	}
	else if ((self.spawnflags & 1) && !(other.flags & (FL_SWIM | FL_FLY)))
	{
		other.monsterinfo.pause_framenum = INT_MAX;
		other.monsterinfo.aiflags |= AI_STAND_GROUND;
		other.monsterinfo.stand(other);
	}

	if (other.movetarget == self)
	{
		other.target = 0;
		other.movetarget = world;
		other.goalentity = other.enemy;
		other.monsterinfo.aiflags &= ~AI_COMBAT_POINT;
	}

	if (self.pathtarget)
	{
		string savetarget = self.target;
		self.target = self.pathtarget;
		if (other.enemy && other.enemy.is_client)
			cactivator = other.enemy;
		else if (other.oldenemy && other.oldenemy.is_client)
			cactivator = other.oldenemy;
		else if (other.activator && other.activator.is_client)
			cactivator = other.activator;
		else
			cactivator = other;
		G_UseTargets(self, cactivator);
		self.target = savetarget;
	}
}

API_FUNC static void(entity self) SP_point_combat =
{
	if (deathmatch.intVal)
	{
		G_FreeEdict(self);
		return;
	}
	self.solid = SOLID_TRIGGER;
	self.touch = point_combat_touch;
	self.mins = '-8 -8 -16';
	self.maxs = '8 8 16';
	self.svflags = SVF_NOCLIENT;
	gi.linkentity(self);
}
#endif

/*QUAKED info_null (0 0.5 0) (-4 -4 -4) (4 4 4)
Used as a positional target for spotlights, etc.
*/
API_FUNC void(entity self) SP_info_null =
{
	G_FreeEdict(self);
}

/*QUAKED info_notnull (0 0.5 0) (-4 -4 -4) (4 4 4)
Used as a positional target for lightning.
*/
API_FUNC void(entity self) SP_info_notnull =
{
	self.absmin = self.s.origin;
	self.absmax = self.s.origin;
}

/*QUAKED light (0 1 0) (-8 -8 -8) (8 8 8) START_OFF
Non-displayed light.
Default light value is 300.
Default style is 0.
If targeted, will toggle between on and off.
Default _cone value is 10 (used to set size of light for spotlights)
*/
#ifdef SINGLE_PLAYER

const int START_OFF	= 1;

static void(entity self, entity other, entity cactivator) light_use =
{
	if (self.spawnflags & START_OFF) {
		gi.configstring(CS_LIGHTS + self.style, "m");
		self.spawnflags &= ~START_OFF;
	} else {
		gi.configstring(CS_LIGHTS + self.style, "a");
		self.spawnflags |= START_OFF;
	}
}
#endif

API_FUNC static void(entity self) SP_light =
{
#ifdef SINGLE_PLAYER
	// no targeted lights in deathmatch, because they cause global messages
	if (!self.targetname || deathmatch.intVal)
	{
#endif
		G_FreeEdict(self);
#ifdef SINGLE_PLAYER
		return;
	}

	if (self.style >= 32)
	{
		self.use = light_use;
		if (self.spawnflags & START_OFF)
			gi.configstring(CS_LIGHTS + self.style, "a");
		else
			gi.configstring(CS_LIGHTS + self.style, "m");
	}
#endif
}

/*QUAKED func_wall (0 .5 .8) ? TRIGGER_SPAWN TOGGLE START_ON ANIMATED ANIMATED_FAST
This is just a solid wall if not inhibited

TRIGGER_SPAWN   the wall will not be present until triggered
				it will then blink in to existance; it will
				kill anything that was in it's way

TOGGLE          only valid for TRIGGER_SPAWN walls
				this allows the wall to be turned on and off

START_ON        only valid for TRIGGER_SPAWN walls
				the wall will initially be present
*/

static void(entity self, entity other, entity cactivator) func_wall_use =
{
	if (self.solid == SOLID_NOT) {
		self.solid = SOLID_BSP;
		self.svflags &= ~SVF_NOCLIENT;
		KillBox(self);
	} else {
		self.solid = SOLID_NOT;
		self.svflags |= SVF_NOCLIENT;
	}
	gi.linkentity(self);

	if (!(self.spawnflags & 2))
		self.use = 0;
}

API_FUNC static void(entity self) SP_func_wall =
{
	self.movetype = MOVETYPE_PUSH;
	gi.setmodel(self, self.model);

	if (self.spawnflags & 8)
		self.s.effects |= EF_ANIM_ALL;
	if (self.spawnflags & 16)
		self.s.effects |= EF_ANIM_ALLFAST;

	// just a wall
	if ((self.spawnflags & 7) == 0) {
		self.solid = SOLID_BSP;
		gi.linkentity(self);
		return;
	}

	// it must be TRIGGER_SPAWN
	if (!(self.spawnflags & 1)) {
//      gi.dprintf("func_wall missing TRIGGER_SPAWN\n");
		self.spawnflags |= 1;
	}

	// yell if the spawnflags are odd
	if (self.spawnflags & 4) {
		if (!(self.spawnflags & 2)) {
			gi.dprintf("func_wall START_ON without TOGGLE\n");
			self.spawnflags |= 2;
		}
	}

	self.use = func_wall_use;
	if (self.spawnflags & 4) {
		self.solid = SOLID_BSP;
	} else {
		self.solid = SOLID_NOT;
		self.svflags |= SVF_NOCLIENT;
	}
	gi.linkentity(self);
}

/*QUAKED func_object (0 .5 .8) ? TRIGGER_SPAWN ANIMATED ANIMATED_FAST
This is solid bmodel that will fall if it's support it removed.
*/

static void(entity self, entity other, vector normal, csurface_t surf) func_object_touch =
{
	// only squash thing we fall on top of
	if (!normal)
		return;
	if (normal[2] < 1.0f)
		return;
	if (other.takedamage == false)
		return;
	T_Damage(other, self, self, vec3_origin, self.s.origin, vec3_origin, self.dmg, 1, 0, MOD_CRUSH);
}

static void(entity self) func_object_release =
{
	self.movetype = MOVETYPE_TOSS;
	self.touch = func_object_touch;
}

static void(entity self, entity other, entity cactivator) func_object_use =
{
	self.solid = SOLID_BSP;
	self.svflags &= ~SVF_NOCLIENT;
	self.use = 0;
	KillBox(self);
	func_object_release(self);
}

API_FUNC static void(entity self) SP_func_object =
{
	gi.setmodel(self, self.model);

	self.mins.x += 1;
	self.mins.y += 1;
	self.mins.z += 1;
	self.maxs.x -= 1;
	self.maxs.y -= 1;
	self.maxs.z -= 1;

	if (!self.dmg)
		self.dmg = 100;

	if (self.spawnflags == 0) {
		self.solid = SOLID_BSP;
		self.movetype = MOVETYPE_PUSH;
		self.think = func_object_release;
		self.nextthink = level.framenum + 2;
	} else {
		self.solid = SOLID_NOT;
		self.movetype = MOVETYPE_PUSH;
		self.use = func_object_use;
		self.svflags |= SVF_NOCLIENT;
	}

	if (self.spawnflags & 2)
		self.s.effects |= EF_ANIM_ALL;
	if (self.spawnflags & 4)
		self.s.effects |= EF_ANIM_ALLFAST;

	self.clipmask = MASK_MONSTERSOLID;

	gi.linkentity(self);
}
#ifdef SINGLE_PLAYER

/*QUAKED func_explosive (0 .5 .8) ? Trigger_Spawn ANIMATED ANIMATED_FAST
Any brush that you want to explode or break apart.  If you want an
ex0plosion, set dmg and it will do a radius explosion of that amount
at the center of the bursh.

If targeted it will not be shootable.

health defaults to 100.

mass defaults to 75.  This determines how much debris is emitted when
it explodes.  You get one large chunk per 100 of mass (up to 8) and
one small chunk per 25 of mass (up to 16).  So 800 gives the most.
*/
static void(entity self, entity inflictor, entity attacker, int damage, vector point) func_explosive_explode =
{
	vector	origin;
	vector	chunkorigin;
	vector	csize;
	int	count;
	int	cmass;

	// bmodel origins are (0 0 0), we need to adjust that here
	csize = self.size * 0.5f;
	origin = self.absmin + csize;
	self.s.origin = origin;

	self.takedamage = false;

	if (self.dmg)
		T_RadiusDamage(self, attacker, self.dmg, 0, self.dmg + 40, MOD_EXPLOSIVE);

	self.velocity = self.s.origin - inflictor.s.origin;
	VectorNormalize(self.velocity);
	self.velocity *= 150;

	// start chunks towards the center
	csize *= 0.5f;

	cmass = self.mass;
	if (!cmass)
		cmass = 75;

	// big chunks
	if (cmass >= 100) {
		count = cmass / 100;
		if (count > 8)
			count = 8;
		while (count--) {
			chunkorigin = origin + randomv(-csize, csize);
			ThrowDebris(self, "models/objects/debris1/tris.md2", 1, chunkorigin);
		}
	}

	// small chunks
	count = cmass / 25;
	if (count > 16)
		count = 16;
	while (count--) {
		chunkorigin = origin + randomv(-csize, csize);
		ThrowDebris(self, "models/objects/debris2/tris.md2", 2, chunkorigin);
	}

#ifdef GROUND_ZERO
	// PMM - if we're part of a train, clean ourselves out of it
	bool done = false;
	entity master;

	if (self.flags & FL_TEAMSLAVE)
	{
		if (self.teammaster)
		{
			master = self.teammaster;
			if(master && master.inuse)		// because mappers (other than jim (usually)) are stupid....
			{
				while (!done)
				{
					if (master.teamchain == self)
					{
						master.teamchain = self.teamchain;
						done = true;
					}
					master = master.teamchain;
				}
			}
		}
	}
#endif

	G_UseTargets(self, attacker);

	if (self.dmg)
		BecomeExplosion1(self);
	else
		G_FreeEdict(self);
}

static void(entity self, entity other, entity cactivator) func_explosive_use =
{
	func_explosive_explode(self, self, other, self.health, vec3_origin);
}

#ifdef GROUND_ZERO
static void(entity self, entity other, entity cactivator) func_explosive_activate =
{
	bool approved = false;

	if (other && other.target)
	{
		if(other.target == self.targetname)
			approved = true;
	}
	if (!approved && cactivator && cactivator.target)
	{
		if(cactivator.target == self.targetname)
			approved = true;
	}

	if (!approved)
		return;

	self.use = func_explosive_use;
	if (!self.health)
		self.health = 100;
	self.die = func_explosive_explode;
	self.takedamage = true;
}
#endif

static void(entity self, entity other, entity cactivator) func_explosive_spawn =
{
	self.solid = SOLID_BSP;
	self.svflags &= ~SVF_NOCLIENT;
	self.use = 0;
	KillBox(self);
	gi.linkentity(self);
}

API_FUNC static void(entity self) SP_func_explosive =
{
	if (deathmatch.intVal)
	{
		// auto-remove for deathmatch
		G_FreeEdict(self);
		return;
	}

	self.movetype = MOVETYPE_PUSH;

	gi.modelindex("models/objects/debris1/tris.md2");
	gi.modelindex("models/objects/debris2/tris.md2");

	gi.setmodel(self, self.model);

	if (self.spawnflags & 1)
	{
		self.svflags |= SVF_NOCLIENT;
		self.solid = SOLID_NOT;
		self.use = func_explosive_spawn;
	}
#ifdef GROUND_ZERO
	else if (self.spawnflags & 8)
	{
		self.solid = SOLID_BSP;
		if(self.targetname)
			self.use = func_explosive_activate;
	}
#endif
	else
	{
		self.solid = SOLID_BSP;
		if (self.targetname)
			self.use = func_explosive_use;
	}

	if (self.spawnflags & 2)
		self.s.effects |= EF_ANIM_ALL;
	if (self.spawnflags & 4)
		self.s.effects |= EF_ANIM_ALLFAST;

	if (self.use != func_explosive_use
#ifdef GROUND_ZERO
		&& self.use != func_explosive_activate
#endif
		) {
		if (!self.health)
			self.health = 100;
		self.die = func_explosive_explode;
		self.takedamage = true;
	}

	gi.linkentity(self);
}

/*QUAKED misc_explobox (0 .5 .8) (-16 -16 0) (16 16 40)
Large exploding box.  You can override its mass (100),
health (80), and dmg (150).
*/
static void(entity self, entity other, vector plane, csurface_t surf) barrel_touch =
{
	float	ratio;
	vector	v;

	if ((other.groundentity == null_entity) || (other.groundentity == self))
		return;

	ratio = (float)other.mass / (float)self.mass;
	v = self.s.origin - other.s.origin;
	M_walkmove(self, vectoyaw(v), 20 * ratio * FRAMETIME);
}

static void(entity self) barrel_explode =
{
	vector	org;
	float   spd;
	vector	save;

	T_RadiusDamage(self, self.activator, self.dmg, 0, self.dmg + 40, MOD_BARREL);

	save = self.s.origin;
	self.s.origin = self.absmin + (0.5f * self.size);

	// a few big chunks
	spd = 1.5f * (float)self.dmg / 200.0f;
	org = self.s.origin + randomv(-self.size, self.size);
	ThrowDebris(self, "models/objects/debris1/tris.md2", spd, org);
	org = self.s.origin + randomv(-self.size, self.size);
	ThrowDebris(self, "models/objects/debris1/tris.md2", spd, org);

	// bottom corners
	spd = 1.75f * (float)self.dmg / 200.0f;
	org = self.absmin;
	ThrowDebris(self, "models/objects/debris3/tris.md2", spd, org);
	org = self.absmin;
	org.x += self.size.x;
	ThrowDebris(self, "models/objects/debris3/tris.md2", spd, org);
	org = self.absmin;
	org.y += self.size.y;
	ThrowDebris(self, "models/objects/debris3/tris.md2", spd, org);
	org = self.absmin;
	org.x += self.size.x;
	org.y += self.size.y;
	ThrowDebris(self, "models/objects/debris3/tris.md2", spd, org);

	// a bunch of little chunks
	spd = 2f * self.dmg / 200f;
	org = self.s.origin + randomv(-self.size, self.size);
	ThrowDebris(self, "models/objects/debris2/tris.md2", spd, org);
	org = self.s.origin + randomv(-self.size, self.size);
	ThrowDebris(self, "models/objects/debris2/tris.md2", spd, org);
	org = self.s.origin + randomv(-self.size, self.size);
	ThrowDebris(self, "models/objects/debris2/tris.md2", spd, org);
	org = self.s.origin + randomv(-self.size, self.size);
	ThrowDebris(self, "models/objects/debris2/tris.md2", spd, org);
	org = self.s.origin + randomv(-self.size, self.size);
	ThrowDebris(self, "models/objects/debris2/tris.md2", spd, org);
	org = self.s.origin + randomv(-self.size, self.size);
	ThrowDebris(self, "models/objects/debris2/tris.md2", spd, org);
	org = self.s.origin + randomv(-self.size, self.size);
	ThrowDebris(self, "models/objects/debris2/tris.md2", spd, org);
	org = self.s.origin + randomv(-self.size, self.size);
	ThrowDebris(self, "models/objects/debris2/tris.md2", spd, org);

	self.s.origin = save;
	if (self.groundentity != null_entity)
		BecomeExplosion2(self);
	else
		BecomeExplosion1(self);
}

static void(entity self, entity inflictor, entity attacker, int damage, vector point) barrel_delay =
{
	self.takedamage = false;
	self.nextthink = level.framenum + 2;
	self.think = barrel_explode;
	self.activator = attacker;
}

#ifdef GROUND_ZERO
static void(entity self) barrel_think =
{
	// the think needs to be first since later stuff may override.
	self.think = barrel_think;
	self.nextthink = level.framenum + 1;

	M_CatagorizePosition (self);
	self.flags |= FL_IMMUNE_SLIME;
	self.air_finished_framenum = level.framenum + (100 * BASE_FRAMERATE);
	M_WorldEffects (self);
}

static void(entity self) barrel_start =
{
	M_droptofloor(self);
	self.think = barrel_think;
	self.nextthink = level.framenum + 1;
}
#endif

API_FUNC static void(entity self) SP_misc_explobox =
{
	if (deathmatch.intVal)
	{
		// auto-remove for deathmatch
		G_FreeEdict(self);
		return;
	}

	gi.modelindex("models/objects/debris1/tris.md2");
	gi.modelindex("models/objects/debris2/tris.md2");
	gi.modelindex("models/objects/debris3/tris.md2");

	self.solid = SOLID_BBOX;
	self.movetype = MOVETYPE_STEP;

	self.model = "models/objects/barrels/tris.md2";
	self.s.modelindex = gi.modelindex(self.model);
	self.mins = '-16 -16 0';
	self.maxs = '16 16 40';

	if (!self.mass)
		self.mass = 400;
	if (!self.health)
		self.health = 10;
	if (!self.dmg)
		self.dmg = 150;

	self.die = barrel_delay;
	self.takedamage = true;
	self.monsterinfo.aiflags = AI_NOSTEP;

	self.touch = barrel_touch;

#ifdef GROUND_ZERO
	self.think = barrel_start;
#else
	self.think = M_droptofloor;
#endif
	self.nextthink = level.framenum + 2;

	gi.linkentity(self);
}
#endif

//
// miscellaneous specialty items
//

/*QUAKED misc_blackhole (1 .5 0) (-8 -8 -8) (8 8 8)
*/

static void(entity ent, entity other, entity cactivator) misc_blackhole_use =
{
	G_FreeEdict(ent);
}

static void(entity self) misc_blackhole_think =
{
	if (++self.s.frame < 19)
		self.nextthink = level.framenum + 1;
	else
	{
		self.s.frame = 0;
		self.nextthink = level.framenum + 1;
	}
}

API_FUNC static void(entity ent) SP_misc_blackhole =
{
	ent.movetype = MOVETYPE_NONE;
	ent.solid = SOLID_NOT;
	ent.mins = '-64 -64 0';
	ent.maxs = '64 64 8';
	ent.s.modelindex = gi.modelindex("models/objects/black/tris.md2");
	ent.s.renderfx = RF_TRANSLUCENT;
	ent.use = misc_blackhole_use;
	ent.think = misc_blackhole_think;
	ent.nextthink = level.framenum + 2;
	gi.linkentity(ent);
}

/*QUAKED misc_eastertank (1 .5 0) (-32 -32 -16) (32 32 32)
*/

static void(entity self) misc_eastertank_think =
{
	if (++self.s.frame < 293)
		self.nextthink = level.framenum + 1;
	else
	{
		self.s.frame = 254;
		self.nextthink = level.framenum + 1;
	}
}

API_FUNC static void(entity ent) SP_misc_eastertank =
{
	ent.movetype = MOVETYPE_NONE;
	ent.solid = SOLID_BBOX;
	ent.mins = '-32 -32 -16';
	ent.maxs = '32 32 32';
	ent.s.modelindex = gi.modelindex("models/monsters/tank/tris.md2");
	ent.s.frame = 254;
	ent.think = misc_eastertank_think;
	ent.nextthink = level.framenum + 2;
	gi.linkentity(ent);
}

/*QUAKED misc_easterchick (1 .5 0) (-32 -32 0) (32 32 32)
*/
static void(entity self) misc_easterchick_think =
{
	if (++self.s.frame < 247)
		self.nextthink = level.framenum + 1;
	else
	{
		self.s.frame = 208;
		self.nextthink = level.framenum + 1;
	}
}

API_FUNC static void(entity ent) SP_misc_easterchick =
{
	ent.movetype = MOVETYPE_NONE;
	ent.solid = SOLID_BBOX;
	ent.mins = '-32 -32 0';
	ent.maxs = '32 32 32';
	ent.s.modelindex = gi.modelindex("models/monsters/bitch/tris.md2");
	ent.s.frame = 208;
	ent.think = misc_easterchick_think;
	ent.nextthink = level.framenum + 2;
	gi.linkentity(ent);
}

/*QUAKED misc_easterchick2 (1 .5 0) (-32 -32 0) (32 32 32)
*/
static void(entity self) misc_easterchick2_think =
{
	if (++self.s.frame < 287)
		self.nextthink = level.framenum + 1;
	else
	{
		self.s.frame = 248;
		self.nextthink = level.framenum + 1;
	}
}

API_FUNC static void(entity ent) SP_misc_easterchick2 =
{
	ent.movetype = MOVETYPE_NONE;
	ent.solid = SOLID_BBOX;
	ent.mins = '-32 -32 0';
	ent.maxs = '32 32 32';
	ent.s.modelindex = gi.modelindex("models/monsters/bitch/tris.md2");
	ent.s.frame = 248;
	ent.think = misc_easterchick2_think;
	ent.nextthink = level.framenum + 2;
	gi.linkentity(ent);
}


/*QUAKED monster_commander_body (1 .5 0) (-32 -32 0) (32 32 48)
Not really a monster, this is the Tank Commander's decapitated body.
There should be a item_commander_head that has this as it's target.
*/
static void(entity self) commander_body_think =
{
	if (++self.s.frame < 24)
		self.nextthink = level.framenum + 1;
	else
		self.nextthink = 0;

	if (self.s.frame == 22)
		gi.sound(self, CHAN_BODY, gi.soundindex("tank/thud.wav"), 1, ATTN_NORM, 0);
}

API_FUNC static void(entity self, entity other, entity cactivator) commander_body_use =
{
	self.think = commander_body_think;
	self.nextthink = level.framenum + 1;
	gi.sound(self, CHAN_BODY, gi.soundindex("tank/pain.wav"), 1, ATTN_NORM, 0);
}

static void(entity self) commander_body_drop =
{
	self.movetype = MOVETYPE_TOSS;
	self.s.origin[2] += 2;
}

API_FUNC static void(entity self) SP_monster_commander_body =
{
	self.movetype = MOVETYPE_NONE;
	self.solid = SOLID_BBOX;
	self.model = "models/monsters/commandr/tris.md2";
	self.s.modelindex = gi.modelindex(self.model);
	self.mins = '-32 -32 0';
	self.maxs = '32 32 48';
	self.use = commander_body_use;
	self.takedamage = true;
	self.flags = FL_GODMODE;
	self.s.renderfx |= RF_FRAMELERP;
	gi.linkentity(self);

	gi.soundindex("tank/thud.wav");
	gi.soundindex("tank/pain.wav");

	self.think = commander_body_drop;
	self.nextthink = level.framenum + 5;
}


/*QUAKED misc_banner (1 .5 0) (-4 -4 -4) (4 4 4)
The origin is the bottom of the banner.
The banner is 128 tall.
*/
static void(entity ent) misc_banner_think =
{
	ent.s.frame = (ent.s.frame + 1) % 16;
	ent.nextthink = level.framenum + 1;
}

API_FUNC static void(entity ent) SP_misc_banner =
{
	ent.movetype = MOVETYPE_NONE;
	ent.solid = SOLID_NOT;
	ent.s.modelindex = gi.modelindex("models/objects/banner/tris.md2");
	ent.s.frame = Q_rand() % 16;
	gi.linkentity(ent);

	ent.think = misc_banner_think;
	ent.nextthink = level.framenum + 1;
}
#ifdef SINGLE_PLAYER

/*QUAKED misc_deadsoldier (1 .5 0) (-16 -16 0) (16 16 16) ON_BACK ON_STOMACH BACK_DECAP FETAL_POS SIT_DECAP IMPALED
This is the dead player model. Comes in 6 exciting different poses!
*/
static void(entity self, entity inflictor, entity attacker, int damage, vector point) misc_deadsoldier_die =
{
	int	n;

#ifdef GROUND_ZERO
	if (self.health > -30)
#else
	if (self.health > -80)
#endif
		return;

	gi.sound(self, CHAN_BODY, gi.soundindex("misc/udeath.wav"), 1, ATTN_NORM, 0);
	for (n = 0; n < 4; n++)
		ThrowGib(self, "models/objects/gibs/sm_meat/tris.md2", damage, GIB_ORGANIC);
	ThrowHead(self, "models/objects/gibs/head2/tris.md2", damage, GIB_ORGANIC);
}

API_FUNC static void(entity ent) SP_misc_deadsoldier =
{
	if (deathmatch.intVal)
	{
		// auto-remove for deathmatch
		G_FreeEdict(ent);
		return;
	}

	ent.movetype = MOVETYPE_NONE;
	ent.solid = SOLID_BBOX;
	ent.s.modelindex = gi.modelindex("models/deadbods/dude/tris.md2");

	// Defaults to frame 0
	if (ent.spawnflags & 2)
		ent.s.frame = 1;
	else if (ent.spawnflags & 4)
		ent.s.frame = 2;
	else if (ent.spawnflags & 8)
		ent.s.frame = 3;
	else if (ent.spawnflags & 16)
		ent.s.frame = 4;
	else if (ent.spawnflags & 32)
		ent.s.frame = 5;
	else
		ent.s.frame = 0;

	ent.mins = '-16 -16 0';
	ent.maxs = '16 16 16';
	ent.deadflag = DEAD_DEAD;
	ent.takedamage = true;
	ent.svflags |= SVF_MONSTER | SVF_DEADMONSTER;
	ent.die = misc_deadsoldier_die;

	gi.linkentity(ent);
}
#endif
/*QUAKED misc_viper (1 .5 0) (-16 -16 0) (16 16 32)
This is the Viper for the flyby bombing.
It is trigger_spawned, so you must have something use it for it to show up.
There must be a path for it to follow once it is activated.

"speed"     How fast the Viper should fly
*/

// from func.qc
void(entity self, entity other, entity cactivator) train_use;
void(entity self) func_train_find;

void(entity self, entity other, entity cactivator) misc_viper_use =
{
	self.svflags &= ~SVF_NOCLIENT;
	self.use = train_use;
	train_use(self, other, cactivator);
}

API_FUNC static void(entity ent) SP_misc_viper =
{
	if (!ent.target) {
		gi.dprintf("misc_viper without a target at %s\n", vtos(ent.absmin));
		G_FreeEdict(ent);
		return;
	}

	if (!ent.speed)
		ent.speed = 300f;

	ent.movetype = MOVETYPE_PUSH;
	ent.solid = SOLID_NOT;
	ent.s.modelindex = gi.modelindex("models/ships/viper/tris.md2");
	ent.mins = '-16 -16 0';
	ent.maxs = '16 16 32';

	ent.think = func_train_find;
	ent.nextthink = level.framenum + 1;
	ent.use = misc_viper_use;
	ent.svflags |= SVF_NOCLIENT;
	ent.moveinfo.accel = ent.moveinfo.decel = ent.moveinfo.speed = ent.speed;

	gi.linkentity(ent);
}

/*QUAKED misc_bigviper (1 .5 0) (-176 -120 -24) (176 120 72)
This is a large stationary viper as seen in Paul's intro
*/
API_FUNC static void(entity ent) SP_misc_bigviper =
{
	ent.movetype = MOVETYPE_NONE;
	ent.solid = SOLID_BBOX;
	ent.mins = '-176 -120 -24';
	ent.maxs = '176 120 72';
	ent.s.modelindex = gi.modelindex("models/ships/bigviper/tris.md2");
	gi.linkentity(ent);
}


/*QUAKED misc_viper_bomb (1 0 0) (-8 -8 -8) (8 8 8)
"dmg"   how much boom should the bomb make?
*/
static void(entity self, entity other, vector plane, csurface_t surf) misc_viper_bomb_touch =
{
	G_UseTargets(self, self.activator);

	self.s.origin[2] = self.absmin.z + 1;
	T_RadiusDamage(self, self, self.dmg, 0, self.dmg + 40, MOD_BOMB);
	BecomeExplosion2(self);
}

static void(entity self) misc_viper_bomb_prethink =
{
	vector	v;
	float	diff;

	self.groundentity = null_entity;

	diff = (self.timestamp - level.framenum) * FRAMETIME;
	if (diff < -1.0f)
		diff = -1.0f;

	v = self.moveinfo.dir * (1.0f + diff);
	v.z = diff;

	diff = self.s.angles[2];
	self.s.angles = vectoangles(v);
	self.s.angles[2] = diff + 10;
}

static void(entity self, entity other, entity cactivator) misc_viper_bomb_use =
{
	entity	viper;

	self.solid = SOLID_BBOX;
	self.svflags &= ~SVF_NOCLIENT;
	self.s.effects |= EF_ROCKET;
	self.use = 0;
	self.movetype = MOVETYPE_TOSS;
	self.prethink = misc_viper_bomb_prethink;
	self.touch = misc_viper_bomb_touch;
	self.activator = cactivator;

	viper = G_Find(world, classname, "misc_viper");
	self.velocity = viper.moveinfo.dir * viper.moveinfo.speed;

	self.timestamp = level.framenum;
	self.moveinfo.dir = viper.moveinfo.dir;
}

API_FUNC static void(entity self) SP_misc_viper_bomb =
{
	self.movetype = MOVETYPE_NONE;
	self.solid = SOLID_NOT;
	self.mins = '-8 -8 -8';
	self.maxs = '8 8 8';

	self.s.modelindex = gi.modelindex("models/objects/bomb/tris.md2");

	if (!self.dmg)
		self.dmg = 1000;

	self.use = misc_viper_bomb_use;
	self.svflags |= SVF_NOCLIENT;

	gi.linkentity(self);
}


/*QUAKED misc_strogg_ship (1 .5 0) (-16 -16 0) (16 16 32)
This is a Storgg ship for the flybys.
It is trigger_spawned, so you must have something use it for it to show up.
There must be a path for it to follow once it is activated.

"speed"     How fast it should fly
*/
void(entity self, entity other, entity cactivator) misc_strogg_ship_use =
{
	self.svflags &= ~SVF_NOCLIENT;
	self.use = train_use;
	train_use(self, other, cactivator);
}

API_FUNC static void(entity ent) SP_misc_strogg_ship =
{
	if (!ent.target) {
		gi.dprintf("%s without a target at %s\n", ent.classname, vtos(ent.absmin));
		G_FreeEdict(ent);
		return;
	}

	if (!ent.speed)
		ent.speed = 300f;

	ent.movetype = MOVETYPE_PUSH;
	ent.solid = SOLID_NOT;
	ent.s.modelindex = gi.modelindex("models/ships/strogg1/tris.md2");
	ent.mins = '-16 -16 0';
	ent.maxs = '16 16 32';

	ent.think = func_train_find;
	ent.nextthink = level.framenum + 1;
	ent.use = misc_strogg_ship_use;
	ent.svflags |= SVF_NOCLIENT;
	ent.moveinfo.accel = ent.moveinfo.decel = ent.moveinfo.speed = ent.speed;

	gi.linkentity(ent);
}


/*QUAKED misc_satellite_dish (1 .5 0) (-64 -64 0) (64 64 128)
*/
static void(entity self) misc_satellite_dish_think =
{
	self.s.frame++;
	if (self.s.frame < 38)
		self.nextthink = level.framenum + 1;
}

static void(entity self, entity other, entity cactivator) misc_satellite_dish_use =
{
	self.s.frame = 0;
	self.think = misc_satellite_dish_think;
	self.nextthink = level.framenum + 1;
}

API_FUNC static void(entity ent) SP_misc_satellite_dish =
{
	ent.movetype = MOVETYPE_NONE;
	ent.solid = SOLID_BBOX;
	ent.mins = '-64 -64 0';
	ent.maxs = '64 64 128';
	ent.s.modelindex = gi.modelindex("models/objects/satellite/tris.md2");
	ent.use = misc_satellite_dish_use;
	gi.linkentity(ent);
}


/*QUAKED light_mine1 (0 1 0) (-2 -2 -12) (2 2 12)
*/
API_FUNC static void(entity ent) SP_light_mine1 =
{
	ent.movetype = MOVETYPE_NONE;
	ent.solid = SOLID_BBOX;
	ent.s.modelindex = gi.modelindex("models/objects/minelite/light1/tris.md2");
	gi.linkentity(ent);
}


/*QUAKED light_mine2 (0 1 0) (-2 -2 -12) (2 2 12)
*/
API_FUNC static void(entity ent) SP_light_mine2 =
{
	ent.movetype = MOVETYPE_NONE;
	ent.solid = SOLID_BBOX;
	ent.s.modelindex = gi.modelindex("models/objects/minelite/light2/tris.md2");
	gi.linkentity(ent);
}


/*QUAKED misc_gib_arm (1 0 0) (-8 -8 -8) (8 8 8)
Intended for use with the target_spawner
*/
API_FUNC static void(entity ent) SP_misc_gib_arm =
{
	gi.setmodel(ent, "models/objects/gibs/arm/tris.md2");
	ent.solid = SOLID_NOT;
	ent.s.effects |= EF_GIB;
	ent.takedamage = true;
	ent.die = gib_die;
	ent.movetype = MOVETYPE_TOSS;
	ent.svflags |= SVF_MONSTER;
	ent.deadflag = DEAD_DEAD;
	ent.avelocity = randomv('200 200 200');
	ent.think = G_FreeEdict;
	ent.nextthink = level.framenum + 30 * BASE_FRAMERATE;
	gi.linkentity(ent);
}

/*QUAKED misc_gib_leg (1 0 0) (-8 -8 -8) (8 8 8)
Intended for use with the target_spawner
*/
API_FUNC static void(entity ent) SP_misc_gib_leg =
{
	gi.setmodel(ent, "models/objects/gibs/leg/tris.md2");
	ent.solid = SOLID_NOT;
	ent.s.effects |= EF_GIB;
	ent.takedamage = true;
	ent.die = gib_die;
	ent.movetype = MOVETYPE_TOSS;
	ent.svflags |= SVF_MONSTER;
	ent.deadflag = DEAD_DEAD;
	ent.avelocity = randomv('200 200 200');
	ent.think = G_FreeEdict;
	ent.nextthink = level.framenum + 30 * BASE_FRAMERATE;
	gi.linkentity(ent);
}

/*QUAKED misc_gib_head (1 0 0) (-8 -8 -8) (8 8 8)
Intended for use with the target_spawner
*/
API_FUNC static void(entity ent) SP_misc_gib_head =
{
	gi.setmodel(ent, "models/objects/gibs/head/tris.md2");
	ent.solid = SOLID_NOT;
	ent.s.effects |= EF_GIB;
	ent.takedamage = true;
	ent.die = gib_die;
	ent.movetype = MOVETYPE_TOSS;
	ent.svflags |= SVF_MONSTER;
	ent.deadflag = DEAD_DEAD;
	ent.avelocity = randomv('200 200 200');
	ent.think = G_FreeEdict;
	ent.nextthink = level.framenum + 30 * BASE_FRAMERATE;
	gi.linkentity(ent);
}

//=====================================================

/*QUAKED target_character (0 0 1) ?
used with target_string (must be on same "team")
"count" is position in the string (starts at 1)
*/

API_FUNC static void(entity self) SP_target_character =
{
	self.movetype = MOVETYPE_PUSH;
	gi.setmodel(self, self.model);
	self.solid = SOLID_BSP;
	self.s.frame = 12;
	gi.linkentity(self);
	return;
}


/*QUAKED target_string (0 0 1) (-8 -8 -8) (8 8 8)
*/

static void(entity self, entity other, entity activator) target_string_use =
{
	entity	e;
	int	n, l;
	int	c;

	l = strlen(self.message);
	for (e = self.teammaster; e; e = e.teamchain) {
		if (!e.count)
			continue;
		n = e.count - 1;
		if (n > l) {
			e.s.frame = 12;
			continue;
		}

		c = strat(self.message, n);
		if (c >= '0' && c <= '9')
			e.s.frame = (int)(c - '0');
		else if (c == '-')
			e.s.frame = 10;
		else if (c == ':')
			e.s.frame = 11;
		else
			e.s.frame = 12;
	}
}

API_FUNC static void(entity self) SP_target_string =
{
	self.use = target_string_use;
}


/*QUAKED func_clock (0 0 1) (-8 -8 -8) (8 8 8) TIMER_UP TIMER_DOWN START_OFF MULTI_USE
target a target_string with this

The default is to be a time of day clock

TIMER_UP and TIMER_DOWN run for "count" seconds and the fire "pathtarget"
If START_OFF, this entity must be used before it starts

"style"     0 "xx"
			1 "xx:xx"
			2 "xx:xx:xx"
*/

static void(entity self) func_clock_reset =
{
	self.activator = world;
	if (self.spawnflags & 1) {
		self.health = 0;
		self.wait = (float)self.count;
	} else if (self.spawnflags & 2) {
		self.health = self.count;
		self.wait = 0;
	}
}

static void(entity self) func_clock_format_countdown =
{
	if (self.style == 0) {
		self.message = va("%2i", self.health);
		return;
	}

	if (self.style == 1) {
		self.message = va("%02i:%02i", self.health / 60, self.health % 60);
		return;
	}

	if (self.style == 2) {
		self.message = va("%02i:%02i:%02i", self.health / 3600, (self.health - (self.health / 3600) * 3600) / 60, self.health % 60);
		return;
	}
}

static void(entity self) func_clock_think =
{
	if !(self.enemy)
	{
		self.enemy = G_Find(world, targetname, self.target);
		if (self.enemy == world)
			return;
	}

	if (self.spawnflags & 1)
	{
		func_clock_format_countdown(self);
		self.health++;
	}
	else if (self.spawnflags & 2)
	{
		func_clock_format_countdown(self);
		self.health--;
	}
	else
	{
		time_t ltime;
		localtime(ltime);
		self.message = va("%02i:%02i:%02i", ltime.tm_hour, ltime.tm_min, ltime.tm_sec);
	}

	self.enemy.message = self.message;
	self.enemy.use(self.enemy, self, self);

	if (((self.spawnflags & 1) && (self.health > self.wait)) ||
		((self.spawnflags & 2) && (self.health < self.wait)))
	{
		if (self.pathtarget)
		{
			string	savetarget;
			string	savemessage;

			savetarget = self.target;
			savemessage = self.message;
			self.target = self.pathtarget;
			self.message = 0;
			G_UseTargets(self, self.activator);
			self.target = savetarget;
			self.message = savemessage;
		}

		if (!(self.spawnflags & 8))
			return;

		func_clock_reset(self);

		if (self.spawnflags & 4)
			return;
	}

	self.nextthink = level.framenum + 1 * BASE_FRAMERATE;
}

static void(entity self, entity other, entity cactivator) func_clock_use =
{
	if (!(self.spawnflags & 8))
		self.use = 0;
	if (self.activator)
		return;
	self.activator = cactivator;
	self.think(self);
}

API_FUNC static void(entity self) SP_func_clock =
{
	if (!self.target) {
		gi.dprintf("%s with no target at %s\n", self.classname, vtos(self.s.origin));
		G_FreeEdict(self);
		return;
	}

	if ((self.spawnflags & 2) && (!self.count)) {
		gi.dprintf("%s with no count at %s\n", self.classname, vtos(self.s.origin));
		G_FreeEdict(self);
		return;
	}

	if ((self.spawnflags & 1) && (!self.count))
		self.count = 60 * 60;

	func_clock_reset(self);

	self.think = func_clock_think;

	if (self.spawnflags & 4)
		self.use = func_clock_use;
	else
		self.nextthink = level.framenum + 1 * BASE_FRAMERATE;
}

//=================================================================================

static void(entity self, entity other, vector plane, csurface_t surf) teleporter_touch =
{
	if (!other.is_client)
		return;

	entity dest = G_Find(world, targetname, self.target);

	if !(dest)
	{
		gi.dprintf("Couldn't find destination\n");
		return;
	}

#ifdef HOOK_CODE
	GrapplePlayerReset(other);
#endif

	// unlink to make sure it can't possibly interfere with KillBox
	gi.unlinkentity(other);

	other.s.origin = dest.s.origin;
	other.s.old_origin = dest.s.origin;
	other.s.origin[2] += 10;

	// clear the velocity and hold them in place briefly
	other.velocity = vec3_origin;
	other.client.ps.pmove.pm_time = 160 >> 3;     // hold time
	other.client.ps.pmove.pm_flags |= PMF_TIME_TELEPORT;

	// draw the teleport splash at source and on the player
	self.owner.s.event = EV_PLAYER_TELEPORT;
	other.s.event = EV_PLAYER_TELEPORT;

	// set angles
	other.client.ps.pmove.delta_angles = dest.s.angles - other.client.resp.cmd_angles;

	other.s.angles = vec3_origin;
	other.client.ps.viewangles = vec3_origin;
	other.client.v_angle = vec3_origin;

	// kill anything at the destination
	KillBox(other);

	gi.linkentity(other);
}

/*QUAKED misc_teleporter (1 0 0) (-32 -32 -24) (32 32 -16)
Stepping onto this disc will teleport players to the targeted misc_teleporter_dest object.
*/
API_FUNC static void(entity ent) SP_misc_teleporter =
{
	entity	trig;

	if (!ent.target) {
		gi.dprintf("teleporter without a target.\n");
		G_FreeEdict(ent);
		return;
	}

	gi.setmodel(ent, "models/objects/dmspot/tris.md2");
	ent.s.skinnum = 1;
	ent.s.effects = EF_TELEPORTER;
	ent.s.sound = gi.soundindex("world/amb10.wav");
	ent.solid = SOLID_BBOX;

	ent.mins = '-32 -32 -24';
	ent.maxs = '32 32 -16';
	gi.linkentity(ent);

	trig = G_Spawn();
	trig.touch = teleporter_touch;
	trig.solid = SOLID_TRIGGER;
	trig.target = ent.target;
	trig.owner = ent;
	trig.s.origin = ent.s.origin;
	trig.mins = '-8 -8 8';
	trig.maxs = '8 8 24';
	gi.linkentity(trig);

}

/*QUAKED misc_teleporter_dest (1 0 0) (-32 -32 -24) (32 32 -16)
Point teleporters at these.
*/
API_FUNC void(entity ent) SP_misc_teleporter_dest =
{
    gi.setmodel(ent, "models/objects/dmspot/tris.md2");
    ent.s.skinnum = 0;
    ent.solid = SOLID_BBOX;
    ent.mins = '-32 -32 -24';
    ent.maxs = '32 32 -16';
    gi.linkentity(ent);
}