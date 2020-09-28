#if defined(GROUND_ZERO) && defined(SINGLE_PLAYER)

inline void(entity self, vector start, vector dir, int damage, int speed, int flashtype, int effect) monster_fire_blaster2 =
{
	fire_blaster2 (self, start, dir, damage, speed, effect, false);

	gi.WriteByte (svc_muzzleflash2);
	gi.WriteShort (self.s.number);
	gi.WriteByte (flashtype);
	gi.multicast (start, MULTICAST_PVS);
}

inline void(entity self, vector start, vector dir, int damage, int speed, entity enemy, int flashtype) monster_fire_tracker =
{
	fire_tracker (self, start, dir, damage, speed, enemy);

	gi.WriteByte (svc_muzzleflash2);
	gi.WriteShort (self.s.number);
	gi.WriteByte (flashtype);
	gi.multicast (start, MULTICAST_PVS);
}

inline void(entity self, vector start, vector dir, vector offset, int damage, int kick, int flashtype) monster_fire_heatbeam =
{
	fire_heatbeam (self, start, dir, offset, damage, kick, true);

	gi.WriteByte (svc_muzzleflash2);
	gi.WriteShort (self.s.number);
	gi.WriteByte (flashtype);
	gi.multicast (start, MULTICAST_PVS);
}

//
//ROGUE
//

//
// Monster spawning code
//
// Used by the carrier, the medic_commander, and the black widow
//
// The sequence to create a flying monster is:
//
//  FindSpawnPoint - tries to find suitable spot to spawn the monster in
//  CreateFlyMonster  - this verifies the point as good and creates the monster

// To create a ground walking monster:
//
//  FindSpawnPoint - same thing
//  CreateGroundMonster - this checks the volume and makes sure the floor under the volume is suitable
//

//
// CreateMonster
//
inline entity(vector origin, vector angles, string cclassname) CreateMonster =
{
	entity new_ent = G_Spawn();

	new_ent.s.origin = origin;
	new_ent.s.angles = angles;
	new_ent.classname = cclassname;
	new_ent.monsterinfo.aiflags |= AI_DO_NOT_COUNT;

	ED_CallSpawn(new_ent);

	new_ent.s.renderfx |= RF_IR_VISIBLE;

	return new_ent;
}

//
// CheckSpawnPoint
//
// PMM - checks volume to make sure we can spawn a monster there (is it solid?)
//
// This is all fliers should need
bool(vector origin, vector mins, vector maxs) CheckSpawnPoint =
{
	if (!mins || !maxs)
		return false;

	trace_t	tr;
	gi.trace (&tr, origin, mins, maxs, origin, 0, MASK_MONSTERSOLID);

	if (tr.startsolid || tr.allsolid)
		return false;

	if (tr.ent != world)
		return false;

	return true;
}

//
// CheckGroundSpawnPoint
//
// PMM - used for walking monsters
//  checks:
//		1)	is there a ground within the specified height of the origin?
//		2)	is the ground non-water?
//		3)	is the ground flat enough to walk on?
//
bool(vector origin, vector ent_mins, vector ent_maxs, float height, float gravity) CheckGroundSpawnPoint =
{
	if (!CheckSpawnPoint (origin, ent_mins, ent_maxs))
		return false;

	vector stop = origin;
	stop[2] = origin[2] + ent_mins[2] - height;

	trace_t tr;
	gi.trace (&tr, origin, ent_mins, ent_maxs, stop, 0, MASK_MONSTERSOLID | MASK_WATER);

	// it's not going to be all solid or start solid, since that's checked above
	if ((tr.fraction < 1) && (tr.contents & MASK_MONSTERSOLID))
	{
		// we found a non-water surface down there somewhere.  now we need to check to make sure it's not too sloped
		//
		// algorithm straight out of m_move.c:M_CheckBottom()
		//

		// first, do the midpoint trace
		vector mins = tr.endpos + ent_mins;
		vector maxs = tr.endpos + ent_maxs;

		// first, do the easy flat check
		vector start;

		if (gravity > 0)
			start[2] = maxs[2] + 1;
		else
			start[2] = mins[2] - 1;

		for (int x = 0; x <= 1; x++)
			for (int y = 0; y <= 1; y++)
			{
				start[0] = x ? maxs[0] : mins[0];
				start[1] = y ? maxs[1] : mins[1];
				if (gi.pointcontents (start) != CONTENTS_SOLID)
					goto realcheck;
			}

		// if it passed all four above checks, we're done
		return true;

realcheck:
		// check it for real
		start[0] = stop[0] = (mins[0] + maxs[0])*0.5;
		start[1] = stop[1] = (mins[1] + maxs[1])*0.5;
		start[2] = mins[2];

		gi.traceline(&tr, start, stop, 0, MASK_MONSTERSOLID);

		if (tr.fraction == 1.0)
			return false;

		float mid, bottom;

		if (gravity < 0)
		{
			start[2] = mins[2];
			stop[2] = start[2] - STEPSIZE - STEPSIZE;
			mid = bottom = tr.endpos[2] + ent_mins[2];
		}
		else
		{
			start[2] = maxs[2];
			stop[2] = start[2] + STEPSIZE + STEPSIZE;
			mid = bottom = tr.endpos[2] - ent_maxs[2];
		}

		for (int x = 0; x <= 1; x++)
			for (int y = 0; y <= 1; y++)
			{
				start[0] = stop[0] = x ? maxs[0] : mins[0];
				start[1] = stop[1] = y ? maxs[1] : mins[1];

				gi.traceline(&tr, start, stop, 0, MASK_MONSTERSOLID);

				if(gravity > 0)
				{
					if (tr.fraction != 1.0 && tr.endpos[2] < bottom)
						bottom = tr.endpos[2];
					if (tr.fraction == 1.0 || tr.endpos[2] - mid > STEPSIZE)
						return false;
				}
				else
				{
					if (tr.fraction != 1.0 && tr.endpos[2] > bottom)
						bottom = tr.endpos[2];
					if (tr.fraction == 1.0 || mid - tr.endpos[2] > STEPSIZE)
						return false;
				}
			}

		return true; // we can land on it, it's ok
	}

	// otherwise, it's either water (bad) or not there (too far)
	// if we're here, it's bad below
	return false;
}

// This is just a wrapper for CreateMonster that looks down height # of CMUs and sees if there
// are bad things down there or not
//
// this is from m_move.c
entity(vector origin, vector angles, vector mins, vector maxs, string classname, int height) CreateGroundMonster =
{
	// check the ground to make sure it's there, it's relatively flat, and it's not toxic
	if (!CheckGroundSpawnPoint(origin, mins, maxs, height, -1))
		return 0;

	return CreateMonster (origin, angles, classname);
}

// FindSpawnPoint
// PMM - this is used by the medic commander (possibly by the carrier) to find a good spawn point
// if the startpoint is bad, try above the startpoint for a bit
bool(vector startpoint, vector mins, vector maxs, vector *spawnpoint, float max_move_up) FindSpawnPoint =
{
	trace_t tr;
	gi.trace (&tr, startpoint, mins, maxs, startpoint, 0, MASK_MONSTERSOLID|CONTENTS_PLAYERCLIP);

	if ((tr.startsolid || tr.allsolid) || (tr.ent != world))
	{
		vector top = startpoint;
		top[2] += max_move_up;

		gi.trace (&tr, top, mins, maxs, startpoint, 0, MASK_MONSTERSOLID);
		if (tr.startsolid || tr.allsolid)
			return false;

		*spawnpoint = tr.endpos;
		return true;
	}
	
	*spawnpoint = startpoint;
	return true;
}

// ****************************
// SPAWNGROW stuff
// ****************************
const float SPAWNGROW_LIFESPAN		= 0.3;

static void(entity self) spawngrow_think =
{
	self.s.angles = randomv('360 360 360');

	if ((level.framenum < self.wait) && (self.s.frame < 2))
		self.s.frame++;
	if (level.framenum >= self.wait)
	{
		if (self.s.effects & EF_SPHERETRANS)
		{
			G_FreeEdict (self);
			return;
		}
		else if (self.s.frame > 0)
			self.s.frame--;
		else
		{
			G_FreeEdict (self);
			return;
		}
	}

	self.nextthink += 1;
}

void(vector startpos, int size) SpawnGrow_Spawn =
{
	entity ent = G_Spawn();
	ent.s.origin = startpos;
	ent.s.angles = randomv('360 360 360');	
	ent.solid = SOLID_NOT;
	ent.s.renderfx = RF_IR_VISIBLE;
	ent.movetype = MOVETYPE_NONE;
	ent.classname = "spawngro";

	float lifespan = SPAWNGROW_LIFESPAN;

	if (size <= 1)
		ent.s.modelindex = gi.modelindex("models/items/spawngro2/tris.md2");
	else if (size == 2)
	{
		ent.s.modelindex = gi.modelindex("models/items/spawngro3/tris.md2");
		lifespan = 2f;
	}
	else
		ent.s.modelindex = gi.modelindex("models/items/spawngro/tris.md2");

	ent.think = spawngrow_think;

	ent.wait = level.framenum + (lifespan * BASE_FRAMERATE);
	ent.nextthink = level.framenum + 1;
	if (size != 2)
		ent.s.effects |= EF_SPHERETRANS;
	gi.linkentity (ent);
}


// ****************************
// WidowLeg stuff
// ****************************

static inline vector(int damage) WidowVelocityForDamage =
{
	return [ damage * crandom(), damage * crandom(), damage * crandom() + 200.0 ];
}

static void(entity self, entity other, vector plane, csurface_t surf) widow_gib_touch =
{
	self.solid = SOLID_NOT;
	self.touch = 0;
	self.s.angles[PITCH] = 0;
	self.s.angles[ROLL] = 0;
	self.avelocity = vec3_origin;

	if (self.plat2flags)
		gi.sound (self, CHAN_VOICE, self.plat2flags, 1, ATTN_NORM, 0);
}

// from misc.qc
void(entity self, entity inflictor, entity attacker, int damage, vector point) gib_die;
void(entity self, entity other, vector plane, csurface_t surf) gib_touch;
PROGS_LOCAL void(entity ent) ClipGibVelocity;

void(entity self, string gibname, int damage, int type, vector startpos, bool sized, int hitsound, bool fade) ThrowWidowGibReal =
{
	if (!gibname)
		return;

	entity gib = G_Spawn();

	if (startpos)
		gib.s.origin = startpos;
	else
	{
		vector csize = self.size * 0.5;
		vector origin = self.absmin + csize;
		gib.s.origin = origin + randomv(-csize, csize);
	}

	gib.solid = SOLID_NOT;
	gib.s.effects |= EF_GIB;
	gib.flags |= FL_NO_KNOCKBACK;
	gib.takedamage = true;
	gib.die = gib_die;
	gib.s.renderfx |= RF_IR_VISIBLE;
	gib.think = G_FreeEdict;

	if (fade)
	{
		// sized gibs last longer
		if (sized)
			gib.nextthink = level.framenum + (int)(random(20f, 35f) * BASE_FRAMERATE);
		else
			gib.nextthink = level.framenum + (int)(random(5f, 15f) * BASE_FRAMERATE);
	}
	else
	{
		// sized gibs last longer
		if (sized)
			gib.nextthink = level.framenum + (int)(random(60f, 75f) * BASE_FRAMERATE);
		else
			gib.nextthink = level.framenum + (int)(random(25f, 35f) * BASE_FRAMERATE);
	}

	float vscale;

	if (type == GIB_ORGANIC)
	{
		gib.movetype = MOVETYPE_TOSS;
		gib.touch = gib_touch;
		vscale = 0.5;
	}
	else
	{
		gib.movetype = MOVETYPE_BOUNCE;
		vscale = 1.0;
	}

	vector vd = WidowVelocityForDamage (damage);
	gib.velocity = self.velocity + (vscale * vd);
	ClipGibVelocity (gib);

	gi.setmodel (gib, gibname);

	if (sized)
	{
		gib.plat2flags = hitsound;
		gib.solid = SOLID_BBOX;
		gib.avelocity = randomv([ 400f, 400f, 200f ]);
		if (gib.velocity[2] < 0)
			gib.velocity[2] *= -1;
		gib.velocity[0] *= 2;
		gib.velocity[1] *= 2;
		ClipGibVelocity (gib);
		gib.velocity[2] = maxf(random(350f, 450f), gib.velocity[2]);
		gib.gravity = 0.25;
		gib.touch = widow_gib_touch;
		gib.owner = self;

		if (gib.s.modelindex == gi.modelindex ("models/monsters/blackwidow2/gib2/tris.md2"))
		{
			gib.mins = '-10 -10 0';
			gib.maxs = '10 10 10';
		}
		else
		{
			gib.mins = '-5 -5 0';
			gib.maxs = '5 5 5';
		}
	}
	else
	{
		gib.velocity[0] *= 2;
		gib.velocity[1] *= 2;
		gib.avelocity = randomv([ 600f, 600f, 600f ]);
	}

	gi.linkentity(gib);
}

INLINE void(entity self, string gibname, int damage, int type) ThrowWidowGib =
{
	ThrowWidowGibReal(self, gibname, damage, type, 0, false, 0, true);
}

INLINE void(entity self, string gibname, int damage, int type, vector startpos, bool fade) ThrowWidowGibLoc =
{
	ThrowWidowGibReal(self, gibname, damage, type, startpos, false, 0, fade);
}

INLINE void(entity self, string gibname, int damage, int type, vector startpos, int hitsound, bool fade) ThrowWidowGibSized =
{
	ThrowWidowGibReal(self, gibname, damage, type, startpos, true, hitsound, fade);
}

INLINE void(entity self, vector point) ThrowSmallStuff =
{
	ThrowWidowGibLoc(self, "models/objects/gibs/sm_meat/tris.md2", 300, GIB_ORGANIC, point, false);
	ThrowWidowGibLoc(self, "models/objects/gibs/sm_meat/tris.md2", 300, GIB_ORGANIC, point, false);
	ThrowWidowGibLoc(self, "models/objects/gibs/sm_metal/tris.md2", 300, GIB_METALLIC, point, false);
	ThrowWidowGibLoc(self, "models/objects/gibs/sm_metal/tris.md2", 100, GIB_METALLIC, point, false);
}

INLINE void(entity self, vector point) ThrowMoreStuff =
{
	if (coop.intVal)
	{
		ThrowSmallStuff (self, point);
		return;
	}

	ThrowWidowGibLoc(self, "models/objects/gibs/sm_meat/tris.md2", 300, GIB_ORGANIC, point, false);
	ThrowWidowGibLoc(self, "models/objects/gibs/sm_metal/tris.md2", 300, GIB_METALLIC, point, false);
	ThrowWidowGibLoc(self, "models/objects/gibs/sm_metal/tris.md2", 300, GIB_METALLIC, point, false);
	ThrowWidowGibLoc(self, "models/objects/gibs/sm_metal/tris.md2", 100, GIB_METALLIC, point, false);
	ThrowWidowGibLoc(self, "models/objects/gibs/sm_metal/tris.md2", 100, GIB_METALLIC, point, false);
	ThrowWidowGibLoc(self, "models/objects/gibs/sm_metal/tris.md2", 100, GIB_METALLIC, point, false);
}

const int MAX_LEGSFRAME		= 23;
const float LEG_WAIT_TIME	= 1;

static void(entity self) widowlegs_think =
{
	if (self.s.frame == 17)
	{
		vector f, r, u;
		AngleVectors (self.s.angles, &f, &r, &u);

		vector start = G_ProjectSource2 (self.s.origin, '11.77 -7.24 23.31', f, r, u);
		gi.WriteByte (svc_temp_entity);
		gi.WriteByte (TE_EXPLOSION1);
		gi.WritePosition (start);
		gi.multicast (start, MULTICAST_ALL);
		ThrowSmallStuff (self, start);
	}

	if (self.s.frame < MAX_LEGSFRAME)
	{
		self.s.frame++;
		self.nextthink = level.framenum + 1;
		return;
	}
	else if (self.wait == 0)
		self.wait = level.framenum + (LEG_WAIT_TIME * BASE_FRAMERATE);

	if (level.framenum > self.wait)
	{
		vector f, r, u;
		AngleVectors (self.s.angles, &f, &r, &u);

		vector start = G_ProjectSource2 (self.s.origin, '-65.6 -8.44 28.59', f, r, u);
		gi.WriteByte (svc_temp_entity);
		gi.WriteByte (TE_EXPLOSION1);
		gi.WritePosition (start);
		gi.multicast (start, MULTICAST_ALL);
		ThrowSmallStuff (self, start);

		ThrowWidowGibSized (self, "models/monsters/blackwidow/gib1/tris.md2", (int)random(80f, 100f), GIB_METALLIC, start, 0, true);
		ThrowWidowGibSized (self, "models/monsters/blackwidow/gib2/tris.md2", (int)random(80f, 100f), GIB_METALLIC, start, 0, true);

		start = G_ProjectSource2 (self.s.origin, '-1.04 -51.18 7.04', f, r, u);
		gi.WriteByte (svc_temp_entity);
		gi.WriteByte (TE_EXPLOSION1);
		gi.WritePosition (start);
		gi.multicast (start, MULTICAST_ALL);
		ThrowSmallStuff (self, start);

		ThrowWidowGibSized (self, "models/monsters/blackwidow/gib1/tris.md2", (int)random(80f, 100f), GIB_METALLIC, start, 0, true);
		ThrowWidowGibSized (self, "models/monsters/blackwidow/gib2/tris.md2", (int)random(80f, 100f), GIB_METALLIC, start, 0, true);
		ThrowWidowGibSized (self, "models/monsters/blackwidow/gib3/tris.md2", (int)random(80f, 100f), GIB_METALLIC, start, 0, true);

		G_FreeEdict (self);
		return;
	}

	if ((level.framenum > (self.wait - (0.5 * BASE_FRAMERATE))) && (self.count == 0))
	{
		self.count = 1;

		vector f, r, u;
		AngleVectors (self.s.angles, &f, &r, &u);

		vector start = G_ProjectSource2 (self.s.origin, '31 -88.7 10.96', f, r, u);
		gi.WriteByte (svc_temp_entity);
		gi.WriteByte (TE_EXPLOSION1);
		gi.WritePosition (start);
		gi.multicast (start, MULTICAST_ALL);

		start = G_ProjectSource2 (self.s.origin, '-12.67 -4.39 15.68', f, r, u);
		gi.WriteByte (svc_temp_entity);
		gi.WriteByte (TE_EXPLOSION1);
		gi.WritePosition (start);
		gi.multicast (start, MULTICAST_ALL);
	}

	self.nextthink = level.framenum + 1;
}

inline void(vector startpos, vector cangles) Widowlegs_Spawn =
{
	entity ent = G_Spawn();
	ent.s.origin = startpos;
	ent.s.angles = cangles;
	ent.solid = SOLID_NOT;
	ent.s.renderfx = RF_IR_VISIBLE;
	ent.movetype = MOVETYPE_NONE;
	ent.classname = "widowlegs";

	ent.s.modelindex = gi.modelindex("models/monsters/legs/tris.md2");
	ent.think = widowlegs_think;

	ent.nextthink = level.framenum + 1;
	gi.linkentity (ent);
}

INLINE void(entity self) ThrowArm1 =
{
	vector	f, r, u;
	AngleVectors (self.s.angles, &f, &r, &u);

	vector startpoint = G_ProjectSource2 (self.s.origin, '65.76 17.52 7.56', f, r, u);

	gi.WriteByte (svc_temp_entity);
	gi.WriteByte (TE_EXPLOSION1_BIG);
	gi.WritePosition (startpoint);
	gi.multicast (self.s.origin, MULTICAST_ALL);

	ThrowWidowGibLoc (self, "models/objects/gibs/sm_metal/tris.md2", 100, GIB_METALLIC, startpoint, false);
	ThrowWidowGibLoc (self, "models/objects/gibs/sm_metal/tris.md2", 100, GIB_METALLIC, startpoint, false);
}

INLINE void(entity self) ThrowArm2 =
{
	vector f, r, u;
	AngleVectors (self.s.angles, &f, &r, &u);

	vector startpoint = G_ProjectSource2 (self.s.origin, '65.76 17.52 7.56', f, r, u);

	ThrowWidowGibSized (self, "models/monsters/blackwidow2/gib4/tris.md2", 200, GIB_METALLIC, startpoint, gi.soundindex ("misc/fhit3.wav"), false);
	ThrowWidowGibLoc (self, "models/objects/gibs/sm_meat/tris.md2", 300, GIB_ORGANIC, startpoint, false);
}

INLINE void(entity self) WidowExplosion1 =
{
	vector f, r, u;
	AngleVectors (self.s.angles, &f, &r, &u);

	vector startpoint = G_ProjectSource2 (self.s.origin, '23.74 -37.67 76.96', f, r, u);

	gi.WriteByte (svc_temp_entity);
	gi.WriteByte (TE_EXPLOSION1);
	gi.WritePosition (startpoint);
	gi.multicast (self.s.origin, MULTICAST_ALL);

	ThrowWidowGibLoc (self, "models/objects/gibs/sm_meat/tris.md2", 300, GIB_ORGANIC, startpoint, false);
	ThrowWidowGibLoc (self, "models/objects/gibs/sm_metal/tris.md2", 100, GIB_METALLIC, startpoint, false);
	ThrowWidowGibLoc (self, "models/objects/gibs/sm_metal/tris.md2", 300, GIB_METALLIC, startpoint, false);
	ThrowWidowGibLoc (self, "models/objects/gibs/sm_metal/tris.md2", 300, GIB_METALLIC, startpoint, false);
}

INLINE void(entity self) WidowExplosion2 =
{
	vector f, r, u;
	AngleVectors (self.s.angles, &f, &r, &u);

	vector startpoint = G_ProjectSource2 (self.s.origin, '-20.49 36.92 73.52', f, r, u);

	gi.WriteByte (svc_temp_entity);
	gi.WriteByte (TE_EXPLOSION1);
	gi.WritePosition (startpoint);
	gi.multicast (self.s.origin, MULTICAST_ALL);
	
	ThrowWidowGibLoc (self, "models/objects/gibs/sm_meat/tris.md2", 300, GIB_ORGANIC, startpoint, false);
	ThrowWidowGibLoc (self, "models/objects/gibs/sm_metal/tris.md2", 100, GIB_METALLIC, startpoint, false);
	ThrowWidowGibLoc (self, "models/objects/gibs/sm_metal/tris.md2", 300, GIB_METALLIC, startpoint, false);
	ThrowWidowGibLoc (self, "models/objects/gibs/sm_metal/tris.md2", 300, GIB_METALLIC, startpoint, false);
}

INLINE void(entity self) WidowExplosion3 =
{
	vector	f, r, u;
	AngleVectors (self.s.angles, &f, &r, &u);

	vector startpoint = G_ProjectSource2 (self.s.origin, '2.11 0.05 92.20', f, r, u);

	gi.WriteByte (svc_temp_entity);
	gi.WriteByte (TE_EXPLOSION1);
	gi.WritePosition (startpoint);
	gi.multicast (self.s.origin, MULTICAST_ALL);

	ThrowWidowGibLoc (self, "models/objects/gibs/sm_meat/tris.md2", 300, GIB_ORGANIC, startpoint, false);
	ThrowWidowGibLoc (self, "models/objects/gibs/sm_metal/tris.md2", 100, GIB_METALLIC, startpoint, false);
	ThrowWidowGibLoc (self, "models/objects/gibs/sm_metal/tris.md2", 300, GIB_METALLIC, startpoint, false);
	ThrowWidowGibLoc (self, "models/objects/gibs/sm_metal/tris.md2", 300, GIB_METALLIC, startpoint, false);
}

INLINE void(entity self) WidowExplosion4 =
{
	vector	f, r, u;
	AngleVectors (self.s.angles, &f, &r, &u);

	vector startpoint = G_ProjectSource2 (self.s.origin, '-28.04 -35.57 -77.56', f, r, u);

	gi.WriteByte (svc_temp_entity);
	gi.WriteByte (TE_EXPLOSION1);
	gi.WritePosition (startpoint);
	gi.multicast (self.s.origin, MULTICAST_ALL);

	ThrowWidowGibLoc (self, "models/objects/gibs/sm_meat/tris.md2", 300, GIB_ORGANIC, startpoint, false);
	ThrowWidowGibLoc (self, "models/objects/gibs/sm_metal/tris.md2", 100, GIB_METALLIC, startpoint, false);
	ThrowWidowGibLoc (self, "models/objects/gibs/sm_metal/tris.md2", 300, GIB_METALLIC, startpoint, false);
	ThrowWidowGibLoc (self, "models/objects/gibs/sm_metal/tris.md2", 300, GIB_METALLIC, startpoint, false);
}

INLINE void(entity self) WidowExplosion5 =
{
	vector	f, r, u;
	AngleVectors (self.s.angles, &f, &r, &u);

	vector startpoint = G_ProjectSource2 (self.s.origin, '-20.11 -1.11 40.76', f, r, u);

	gi.WriteByte (svc_temp_entity);
	gi.WriteByte (TE_EXPLOSION1);
	gi.WritePosition (startpoint);
	gi.multicast (self.s.origin, MULTICAST_ALL);

	ThrowWidowGibLoc (self, "models/objects/gibs/sm_meat/tris.md2", 300, GIB_ORGANIC, startpoint, false);
	ThrowWidowGibLoc (self, "models/objects/gibs/sm_metal/tris.md2", 100, GIB_METALLIC, startpoint, false);
	ThrowWidowGibLoc (self, "models/objects/gibs/sm_metal/tris.md2", 300, GIB_METALLIC, startpoint, false);
	ThrowWidowGibLoc (self, "models/objects/gibs/sm_metal/tris.md2", 300, GIB_METALLIC, startpoint, false);
}

INLINE void(entity self) WidowExplosion6 =
{
	vector	f, r, u;
	AngleVectors (self.s.angles, &f, &r, &u);

	vector startpoint = G_ProjectSource2 (self.s.origin, '-20.11 -1.11 40.76', f, r, u);

	gi.WriteByte (svc_temp_entity);
	gi.WriteByte (TE_EXPLOSION1);
	gi.WritePosition (startpoint);
	gi.multicast (self.s.origin, MULTICAST_ALL);

	ThrowWidowGibLoc (self, "models/objects/gibs/sm_meat/tris.md2", 300, GIB_ORGANIC, startpoint, false);
	ThrowWidowGibLoc (self, "models/objects/gibs/sm_metal/tris.md2", 100, GIB_METALLIC, startpoint, false);
	ThrowWidowGibLoc (self, "models/objects/gibs/sm_metal/tris.md2", 300, GIB_METALLIC, startpoint, false);
	ThrowWidowGibLoc (self, "models/objects/gibs/sm_metal/tris.md2", 300, GIB_METALLIC, startpoint, false);
}

INLINE void(entity self) WidowExplosion7 =
{
	vector	f, r, u;
	AngleVectors (self.s.angles, &f, &r, &u);

	vector startpoint = G_ProjectSource2 (self.s.origin, '-20.11 -1.11 40.76', f, r, u);

	gi.WriteByte (svc_temp_entity);
	gi.WriteByte (TE_EXPLOSION1);
	gi.WritePosition (startpoint);
	gi.multicast (self.s.origin, MULTICAST_ALL);
	
	ThrowWidowGibLoc (self, "models/objects/gibs/sm_meat/tris.md2", 300, GIB_ORGANIC, startpoint, false);
	ThrowWidowGibLoc (self, "models/objects/gibs/sm_metal/tris.md2", 100, GIB_METALLIC, startpoint, false);
	ThrowWidowGibLoc (self, "models/objects/gibs/sm_metal/tris.md2", 300, GIB_METALLIC, startpoint, false);
	ThrowWidowGibLoc (self, "models/objects/gibs/sm_metal/tris.md2", 300, GIB_METALLIC, startpoint, false);
}

INLINE void(entity self) WidowExplosionLeg =
{
	vector	f, r, u;
	AngleVectors (self.s.angles, &f, &r, &u);

	vector startpoint = G_ProjectSource2 (self.s.origin, '-31.89 -47.86 67.02', f, r, u);

	gi.WriteByte (svc_temp_entity);
	gi.WriteByte (TE_EXPLOSION1_BIG);
	gi.WritePosition (startpoint);
	gi.multicast (self.s.origin, MULTICAST_ALL);

	ThrowWidowGibSized (self, "models/monsters/blackwidow2/gib2/tris.md2", 200, GIB_METALLIC, startpoint, gi.soundindex ("misc/fhit3.wav"), false);
	ThrowWidowGibLoc (self, "models/objects/gibs/sm_meat/tris.md2", 300, GIB_ORGANIC, startpoint, false);
	ThrowWidowGibLoc (self, "models/objects/gibs/sm_metal/tris.md2", 100, GIB_METALLIC, startpoint, false);

	startpoint = G_ProjectSource2 (self.s.origin, '-44.9 -82.14 54.72', f, r, u);

	gi.WriteByte (svc_temp_entity);
	gi.WriteByte (TE_EXPLOSION1);
	gi.WritePosition (startpoint);
	gi.multicast (self.s.origin, MULTICAST_ALL);

	ThrowWidowGibSized (self, "models/monsters/blackwidow2/gib1/tris.md2", 300, GIB_METALLIC, startpoint, gi.soundindex ("misc/fhit3.wav"), false);
	ThrowWidowGibLoc (self, "models/objects/gibs/sm_meat/tris.md2", 300, GIB_ORGANIC, startpoint, false);
	ThrowWidowGibLoc (self, "models/objects/gibs/sm_metal/tris.md2", 100, GIB_METALLIC, startpoint, false);
}

#endif