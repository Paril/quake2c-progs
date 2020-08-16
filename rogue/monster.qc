#ifdef GROUND_ZERO

void(entity self, vector start, vector dir, int damage, int speed, int flashtype, int effect) monster_fire_blaster2 =
{
	fire_blaster2 (self, start, dir, damage, speed, effect, false);

	gi.WriteByte (svc_muzzleflash2);
	gi.WriteShort (self.s.number);
	gi.WriteByte (flashtype);
	gi.multicast (start, MULTICAST_PVS);
}

void(entity self, vector start, vector dir, int damage, int speed, entity enemy, int flashtype) monster_fire_tracker =
{
	fire_tracker (self, start, dir, damage, speed, enemy);

	gi.WriteByte (svc_muzzleflash2);
	gi.WriteShort (self.s.number);
	gi.WriteByte (flashtype);
	gi.multicast (start, MULTICAST_PVS);
}

void(entity self, vector start, vector dir, vector offset, int damage, int kick, int flashtype) monster_fire_heatbeam =
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
inline entity CreateMonster(vector origin, vector angles, string cclassname)
{
	entity newEnt = G_Spawn();

	newEnt.s.origin = origin;
	newEnt.s.angles = angles;
	newEnt.classname = cclassname;
	newEnt.monsterinfo.aiflags |= AI_DO_NOT_COUNT;
	
	newEnt.gravityVector = '0 0 -1';
	ED_CallSpawn(newEnt);
	newEnt.s.renderfx |= RF_IR_VISIBLE;

	return newEnt;
}

static inline void DetermineBBox (string cclassname, vector *cmins, vector *cmaxs)
{
	entity newEnt = G_Spawn();

	newEnt.s.origin = newEnt.s.angles = vec3_origin;
	newEnt.classname = cclassname;
	newEnt.monsterinfo.aiflags |= AI_DO_NOT_COUNT;
	
	ED_CallSpawn(newEnt);
	
	*cmins = newEnt.mins;
	*cmaxs = newEnt.maxs;

	G_FreeEdict (newEnt);
}


//
// CheckSpawnPoint
//
// PMM - checks volume to make sure we can spawn a monster there (is it solid?)
//
// This is all fliers should need
bool CheckSpawnPoint (vector origin, vector mins, vector maxs)
{
	trace_t	tr;

	if (!mins || !maxs)
		return false;

	gi.trace (&tr, origin, mins, maxs, origin, 0, MASK_MONSTERSOLID);

	if (tr.startsolid || tr.allsolid)
		return false;

	if (tr.ent != world)
		return false;

	return true;
}

entity CreateFlyMonster (vector origin, vector angles, vector mins, vector maxs, string classname)
{
	if (!mins || !maxs)
		DetermineBBox (classname, &mins, &maxs);

	if (!CheckSpawnPoint(origin, mins, maxs))
		return 0;

	return CreateMonster(origin, angles, classname);
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
bool CheckGroundSpawnPoint (vector origin, vector entMins, vector entMaxs, float height, float gravity)
{
	trace_t		tr;
	vector		start, stop;
	int		failure = 0;
	vector		mins, maxs;
	int		x, y;	
	float		mid, bottom;

	if (!CheckSpawnPoint (origin, entMins, entMaxs))
		return false;

	stop = origin;
	stop[2] = origin[2] + entMins[2] - height;

	gi.trace (&tr, origin, entMins, entMaxs, stop, 0, MASK_MONSTERSOLID | MASK_WATER);

	// it's not going to be all solid or start solid, since that's checked above
	if ((tr.fraction < 1) && (tr.contents & MASK_MONSTERSOLID))
	{
		// we found a non-water surface down there somewhere.  now we need to check to make sure it's not too sloped
		//
		// algorithm straight out of m_move.c:M_CheckBottom()
		//

		// first, do the midpoint trace

		mins = tr.endpos + entMins;
		maxs = tr.endpos + entMaxs;

		// first, do the easy flat check
		//
		if(gravity > 0)
			start[2] = maxs[2] + 1;
		else
			start[2] = mins[2] - 1;

		for (x=0 ; x<=1 ; x++)
		{
			for (y=0 ; y<=1 ; y++)
			{
				start[0] = x ? maxs[0] : mins[0];
				start[1] = y ? maxs[1] : mins[1];
				if (gi.pointcontents (start) != CONTENTS_SOLID)
					goto realcheck;
			}
		}

		// if it passed all four above checks, we're done
		return true;

realcheck:

		// check it for real

		start[0] = stop[0] = (mins[0] + maxs[0])*0.5;
		start[1] = stop[1] = (mins[1] + maxs[1])*0.5;
		start[2] = mins[2];

		gi.trace (&tr, start, vec3_origin, vec3_origin, stop, 0, MASK_MONSTERSOLID);

		if (tr.fraction == 1.0)
			return false;
		mid = bottom = tr.endpos[2];

		if(gravity < 0)
		{
			start[2] = mins[2];
			stop[2] = start[2] - STEPSIZE - STEPSIZE;
			mid = bottom = tr.endpos[2] + entMins[2];
		}
		else
		{
			start[2] = maxs[2];
			stop[2] = start[2] + STEPSIZE + STEPSIZE;
			mid = bottom = tr.endpos[2] - entMaxs[2];
		}

		for (x=0 ; x<=1 ; x++)
			for (y=0 ; y<=1 ; y++)
			{
				start[0] = stop[0] = x ? maxs[0] : mins[0];
				start[1] = stop[1] = y ? maxs[1] : mins[1];

				gi.trace (&tr, start, vec3_origin, vec3_origin, stop, 0, MASK_MONSTERSOLID);

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

entity CreateGroundMonster (vector origin, vector angles, vector entMins, vector entMaxs, string classname, int height)
{
	vector		mins, maxs;

	// if they don't provide us a bounding box, figure it out
	if (!entMins || !entMaxs)
		DetermineBBox (classname, &mins, &maxs);
	else
	{
		mins = entMins;
		maxs = entMaxs;
	}

	// check the ground to make sure it's there, it's relatively flat, and it's not toxic
	if (!CheckGroundSpawnPoint(origin, mins, maxs, height, -1))
		return 0;

	return CreateMonster (origin, angles, classname);
}

// FindSpawnPoint
// PMM - this is used by the medic commander (possibly by the carrier) to find a good spawn point
// if the startpoint is bad, try above the startpoint for a bit
bool FindSpawnPoint (vector startpoint, vector mins, vector maxs, vector *spawnpoint, float maxMoveUp)
{
	trace_t		tr;
	float		height = maxs[2] - mins[2];
	vector		top;

	gi.trace (&tr, startpoint, mins, maxs, startpoint, 0, MASK_MONSTERSOLID|CONTENTS_PLAYERCLIP);

	if((tr.startsolid || tr.allsolid) || (tr.ent != world))
	{
		top = startpoint;
		top[2] += maxMoveUp;

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

static void spawngrow_think (entity self)
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

void SpawnGrow_Spawn (vector startpos, int size)
{
	entity	ent;
	float	lifespan = SPAWNGROW_LIFESPAN;

	ent = G_Spawn();
	ent.s.origin = startpos;
	ent.s.angles = randomv('360 360 360');	
	ent.solid = SOLID_NOT;
	ent.s.renderfx = RF_IR_VISIBLE;
	ent.movetype = MOVETYPE_NONE;
	ent.classname = "spawngro";

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

static vector WidowVelocityForDamage (int damage)
{
	return [ damage * crandom(), damage * crandom(), damage * crandom() + 200.0 ];
}

static void widow_gib_touch (entity self, entity other, vector plane, csurface_t surf)
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

void ThrowWidowGibReal (entity self, string gibname, int damage, int type, vector startpos, bool sized, int hitsound, bool fade)
{
	entity	gib;
	vector	vd;
	vector	origin;
	vector	csize;
	float	vscale;

	if (!gibname)
		return;

	gib = G_Spawn();

	if (startpos)
		gib.s.origin = startpos;
	else
	{
		csize = self.size * 0.5;
		origin = self.absmin + csize;
		gib.s.origin = origin + randomv(-csize, csize);
	}

	gib.solid = SOLID_NOT;
	gib.s.effects |= EF_GIB;
	gib.flags |= FL_NO_KNOCKBACK;
	gib.takedamage = DAMAGE_YES;
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

	vd = WidowVelocityForDamage (damage);
	gib.velocity = self.velocity + (vscale * vd);
	ClipGibVelocity (gib);

	gi.setmodel (gib, gibname);

	if (sized)
	{
		gib.plat2flags = hitsound;
		gib.solid = SOLID_BBOX;
		gib.avelocity[0] = random(400f);
		gib.avelocity[1] = random(400f);
		gib.avelocity[2] = random(200f);
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
		gib.avelocity[0] = random(600f);
		gib.avelocity[1] = random(600f);
		gib.avelocity[2] = random(600f);
	}

	gi.linkentity (gib);
}

void ThrowWidowGib (entity self, string gibname, int damage, int type)
{
	ThrowWidowGibReal (self, gibname, damage, type, 0, false, 0, true);
}

void ThrowWidowGibLoc (entity self, string gibname, int damage, int type, vector startpos, bool fade)
{
	ThrowWidowGibReal (self, gibname, damage, type, startpos, false, 0, fade);
}

void ThrowWidowGibSized (entity self, string gibname, int damage, int type, vector startpos, int hitsound, bool fade)
{
	ThrowWidowGibReal (self, gibname, damage, type, startpos, true, hitsound, fade);
}

void ThrowSmallStuff (entity self, vector point)
{
	int n;

	for (n= 0; n < 2; n++)
		ThrowWidowGibLoc (self, "models/objects/gibs/sm_meat/tris.md2", 300, GIB_ORGANIC, point, false);
	ThrowWidowGibLoc (self, "models/objects/gibs/sm_metal/tris.md2", 300, GIB_METALLIC, point, false);
	ThrowWidowGibLoc (self, "models/objects/gibs/sm_metal/tris.md2", 100, GIB_METALLIC, point, false);

}

void ThrowMoreStuff (entity self, vector point)
{
	int n;

	if (coop.intVal)
	{
		ThrowSmallStuff (self, point);
		return;
	}

	for (n= 0; n < 1; n++)
		ThrowWidowGibLoc (self, "models/objects/gibs/sm_meat/tris.md2", 300, GIB_ORGANIC, point, false);
	for (n= 0; n < 2; n++)
		ThrowWidowGibLoc (self, "models/objects/gibs/sm_metal/tris.md2", 300, GIB_METALLIC, point, false);
	for (n= 0; n < 3; n++)
		ThrowWidowGibLoc (self, "models/objects/gibs/sm_metal/tris.md2", 100, GIB_METALLIC, point, false);

}

const int MAX_LEGSFRAME	= 23;
const float LEG_WAIT_TIME	= 1;

static void widowlegs_think (entity self)
{
	vector	offset, start;
	vector	f,r,u;

	if (self.s.frame == 17)
	{
		offset = '11.77 -7.24 23.31';
		AngleVectors (self.s.angles, &f, &r, &u);
		start = G_ProjectSource2 (self.s.origin, offset, f, r, u);
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
		AngleVectors (self.s.angles, &f, &r, &u);

		offset = '-65.6 -8.44 28.59';
		start = G_ProjectSource2 (self.s.origin, offset, f, r, u);
		gi.WriteByte (svc_temp_entity);
		gi.WriteByte (TE_EXPLOSION1);
		gi.WritePosition (start);
		gi.multicast (start, MULTICAST_ALL);
		ThrowSmallStuff (self, start);

		ThrowWidowGibSized (self, "models/monsters/blackwidow/gib1/tris.md2", (int)random(80f, 100f), GIB_METALLIC, start, 0, true);
		ThrowWidowGibSized (self, "models/monsters/blackwidow/gib2/tris.md2", (int)random(80f, 100f), GIB_METALLIC, start, 0, true);

		offset = '-1.04 -51.18 7.04';
		start = G_ProjectSource2 (self.s.origin, offset, f, r, u);
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
		AngleVectors (self.s.angles, &f, &r, &u);

		offset = '31 -88.7 10.96';
		start = G_ProjectSource2 (self.s.origin, offset, f, r, u);
		gi.WriteByte (svc_temp_entity);
		gi.WriteByte (TE_EXPLOSION1);
		gi.WritePosition (start);
		gi.multicast (start, MULTICAST_ALL);

		offset = '-12.67 -4.39 15.68';
		start = G_ProjectSource2 (self.s.origin, offset, f, r, u);
		gi.WriteByte (svc_temp_entity);
		gi.WriteByte (TE_EXPLOSION1);
		gi.WritePosition (start);
		gi.multicast (start, MULTICAST_ALL);

		self.nextthink = level.framenum + 1;
		return;
	}
	self.nextthink = level.framenum + 1;
}

void Widowlegs_Spawn (vector startpos, vector cangles)
{
	entity ent;

	ent = G_Spawn();
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

void ThrowArm1 (entity self)
{
	int		n;
	vector	f,r,u, startpoint;
	static const vector	offset1 = '65.76 17.52 7.56';

	AngleVectors (self.s.angles, &f, &r, &u);
	startpoint = G_ProjectSource2 (self.s.origin, offset1, f, r, u);

	gi.WriteByte (svc_temp_entity);
	gi.WriteByte (TE_EXPLOSION1_BIG);
	gi.WritePosition (startpoint);
	gi.multicast (self.s.origin, MULTICAST_ALL);

	for (n= 0; n < 2; n++)
		ThrowWidowGibLoc (self, "models/objects/gibs/sm_metal/tris.md2", 100, GIB_METALLIC, startpoint, false);
}

void ThrowArm2 (entity self)
{
	vector	f,r,u, startpoint;
	static const vector	offset1 = '65.76 17.52 7.56';

	AngleVectors (self.s.angles, &f, &r, &u);
	startpoint = G_ProjectSource2 (self.s.origin, offset1, f, r, u);

	ThrowWidowGibSized (self, "models/monsters/blackwidow2/gib4/tris.md2", 200, GIB_METALLIC, startpoint, 
		gi.soundindex ("misc/fhit3.wav"), false);
	ThrowWidowGibLoc (self, "models/objects/gibs/sm_meat/tris.md2", 300, GIB_ORGANIC, startpoint, false);
}

void WidowExplosion1 (entity self)
{
	int		n;
	vector f,r,u, startpoint;
	static const vector offset = '23.74 -37.67 76.96';

	AngleVectors (self.s.angles, &f, &r, &u);
	startpoint = G_ProjectSource2 (self.s.origin, offset, f, r, u);

	gi.WriteByte (svc_temp_entity);
	gi.WriteByte (TE_EXPLOSION1);
	gi.WritePosition (startpoint);
	gi.multicast (self.s.origin, MULTICAST_ALL);
	
	for (n= 0; n < 1; n++)
		ThrowWidowGibLoc (self, "models/objects/gibs/sm_meat/tris.md2", 300, GIB_ORGANIC, startpoint, false);
	for (n= 0; n < 1; n++)
		ThrowWidowGibLoc (self, "models/objects/gibs/sm_metal/tris.md2", 100, GIB_METALLIC, startpoint, false);
	for (n= 0; n < 2; n++)
		ThrowWidowGibLoc (self, "models/objects/gibs/sm_metal/tris.md2", 300, GIB_METALLIC, startpoint, false);
}

void WidowExplosion2 (entity self)
{
	int		n;
	vector	f,r,u, startpoint;
	static const vector	offset = '-20.49 36.92 73.52';

	AngleVectors (self.s.angles, &f, &r, &u);
	startpoint = G_ProjectSource2 (self.s.origin, offset, f, r, u);

	gi.WriteByte (svc_temp_entity);
	gi.WriteByte (TE_EXPLOSION1);
	gi.WritePosition (startpoint);
	gi.multicast (self.s.origin, MULTICAST_ALL);
	
	for (n= 0; n < 1; n++)
		ThrowWidowGibLoc (self, "models/objects/gibs/sm_meat/tris.md2", 300, GIB_ORGANIC, startpoint, false);
	for (n= 0; n < 1; n++)
		ThrowWidowGibLoc (self, "models/objects/gibs/sm_metal/tris.md2", 100, GIB_METALLIC, startpoint, false);
	for (n= 0; n < 2; n++)
		ThrowWidowGibLoc (self, "models/objects/gibs/sm_metal/tris.md2", 300, GIB_METALLIC, startpoint, false);
}

void WidowExplosion3 (entity self)
{
	int		n;
	vector	f,r,u, startpoint;
	static const vector	offset = '2.11 0.05 92.20';

//	gi.dprintf ("3\n");

	AngleVectors (self.s.angles, &f, &r, &u);
	startpoint = G_ProjectSource2 (self.s.origin, offset, f, r, u);

	gi.WriteByte (svc_temp_entity);
	gi.WriteByte (TE_EXPLOSION1);
	gi.WritePosition (startpoint);
	gi.multicast (self.s.origin, MULTICAST_ALL);
	
	for (n= 0; n < 1; n++)
		ThrowWidowGibLoc (self, "models/objects/gibs/sm_meat/tris.md2", 300, GIB_ORGANIC, startpoint, false);
	for (n= 0; n < 1; n++)
		ThrowWidowGibLoc (self, "models/objects/gibs/sm_metal/tris.md2", 100, GIB_METALLIC, startpoint, false);
	for (n= 0; n < 2; n++)
		ThrowWidowGibLoc (self, "models/objects/gibs/sm_metal/tris.md2", 300, GIB_METALLIC, startpoint, false);
}

void WidowExplosion4 (entity self)
{
	int		n;
	vector	f,r,u, startpoint;
	static const vector offset = '-28.04 -35.57 -77.56';

	AngleVectors (self.s.angles, &f, &r, &u);
	startpoint = G_ProjectSource2 (self.s.origin, offset, f, r, u);

	gi.WriteByte (svc_temp_entity);
	gi.WriteByte (TE_EXPLOSION1);
	gi.WritePosition (startpoint);
	gi.multicast (self.s.origin, MULTICAST_ALL);
	
	for (n= 0; n < 1; n++)
		ThrowWidowGibLoc (self, "models/objects/gibs/sm_meat/tris.md2", 300, GIB_ORGANIC, startpoint, false);
	for (n= 0; n < 1; n++)
		ThrowWidowGibLoc (self, "models/objects/gibs/sm_metal/tris.md2", 100, GIB_METALLIC, startpoint, false);
	for (n= 0; n < 2; n++)
		ThrowWidowGibLoc (self, "models/objects/gibs/sm_metal/tris.md2", 300, GIB_METALLIC, startpoint, false);
}

void WidowExplosion5 (entity self)
{
	int		n;
	vector	f,r,u, startpoint;
	static const vector	offset = '-20.11 -1.11 40.76';

	AngleVectors (self.s.angles, &f, &r, &u);
	startpoint = G_ProjectSource2 (self.s.origin, offset, f, r, u);

	gi.WriteByte (svc_temp_entity);
	gi.WriteByte (TE_EXPLOSION1);
	gi.WritePosition (startpoint);
	gi.multicast (self.s.origin, MULTICAST_ALL);
	
	for (n= 0; n < 1; n++)
		ThrowWidowGibLoc (self, "models/objects/gibs/sm_meat/tris.md2", 300, GIB_ORGANIC, startpoint, false);
	for (n= 0; n < 1; n++)
		ThrowWidowGibLoc (self, "models/objects/gibs/sm_metal/tris.md2", 100, GIB_METALLIC, startpoint, false);
	for (n= 0; n < 2; n++)
		ThrowWidowGibLoc (self, "models/objects/gibs/sm_metal/tris.md2", 300, GIB_METALLIC, startpoint, false);
}

void WidowExplosion6 (entity self)
{
	int		n;
	vector	f,r,u, startpoint;
	static const vector	offset = '-20.11 -1.11 40.76';

	AngleVectors (self.s.angles, &f, &r, &u);
	startpoint = G_ProjectSource2 (self.s.origin, offset, f, r, u);

	gi.WriteByte (svc_temp_entity);
	gi.WriteByte (TE_EXPLOSION1);
	gi.WritePosition (startpoint);
	gi.multicast (self.s.origin, MULTICAST_ALL);
	
	for (n= 0; n < 1; n++)
		ThrowWidowGibLoc (self, "models/objects/gibs/sm_meat/tris.md2", 300, GIB_ORGANIC, startpoint, false);
	for (n= 0; n < 1; n++)
		ThrowWidowGibLoc (self, "models/objects/gibs/sm_metal/tris.md2", 100, GIB_METALLIC, startpoint, false);
	for (n= 0; n < 2; n++)
		ThrowWidowGibLoc (self, "models/objects/gibs/sm_metal/tris.md2", 300, GIB_METALLIC, startpoint, false);
}

void WidowExplosion7 (entity self)
{
	int		n;
	vector	f,r,u, startpoint;
	static const vector	offset = '-20.11 -1.11 40.76';

	AngleVectors (self.s.angles, &f, &r, &u);
	startpoint = G_ProjectSource2 (self.s.origin, offset, f, r, u);

	gi.WriteByte (svc_temp_entity);
	gi.WriteByte (TE_EXPLOSION1);
	gi.WritePosition (startpoint);
	gi.multicast (self.s.origin, MULTICAST_ALL);
	
	for (n= 0; n < 1; n++)
		ThrowWidowGibLoc (self, "models/objects/gibs/sm_meat/tris.md2", 300, GIB_ORGANIC, startpoint, false);
	for (n= 0; n < 1; n++)
		ThrowWidowGibLoc (self, "models/objects/gibs/sm_metal/tris.md2", 100, GIB_METALLIC, startpoint, false);
	for (n= 0; n < 2; n++)
		ThrowWidowGibLoc (self, "models/objects/gibs/sm_metal/tris.md2", 300, GIB_METALLIC, startpoint, false);
}

void WidowExplosionLeg (entity self)
{
	vector	f,r,u, startpoint;
	static const vector	offset1 = '-31.89 -47.86 67.02';
	static const vector	offset2 = '-44.9 -82.14 54.72';

	AngleVectors (self.s.angles, &f, &r, &u);
	startpoint = G_ProjectSource2 (self.s.origin, offset1, f, r, u);

	gi.WriteByte (svc_temp_entity);
	gi.WriteByte (TE_EXPLOSION1_BIG);
	gi.WritePosition (startpoint);
	gi.multicast (self.s.origin, MULTICAST_ALL);

	ThrowWidowGibSized (self, "models/monsters/blackwidow2/gib2/tris.md2", 200, GIB_METALLIC, startpoint, 
		gi.soundindex ("misc/fhit3.wav"), false);
	ThrowWidowGibLoc (self, "models/objects/gibs/sm_meat/tris.md2", 300, GIB_ORGANIC, startpoint, false);
	ThrowWidowGibLoc (self, "models/objects/gibs/sm_metal/tris.md2", 100, GIB_METALLIC, startpoint, false);

	startpoint = G_ProjectSource2 (self.s.origin, offset2, f, r, u);

	gi.WriteByte (svc_temp_entity);
	gi.WriteByte (TE_EXPLOSION1);
	gi.WritePosition (startpoint);
	gi.multicast (self.s.origin, MULTICAST_ALL);

	ThrowWidowGibSized (self, "models/monsters/blackwidow2/gib1/tris.md2", 300, GIB_METALLIC, startpoint,
		gi.soundindex ("misc/fhit3.wav"), false);
	ThrowWidowGibLoc (self, "models/objects/gibs/sm_meat/tris.md2", 300, GIB_ORGANIC, startpoint, false);
	ThrowWidowGibLoc (self, "models/objects/gibs/sm_metal/tris.md2", 100, GIB_METALLIC, startpoint, false);
}

#endif