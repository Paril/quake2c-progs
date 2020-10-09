const vector MOVEDIR_UP		= [ 0, 0, 1 ];
const vector MOVEDIR_DOWN	= [ 0, 0, -1 ];

/*
=================
G_InitEdict

Marks an entity as active, and sets up some default parameters.
=================
*/
inline void(entity e) G_InitEdict =
{
	e.inuse = true;
	e.classname = "noclass";
	e.gravity = 1.0f;
	e.groundentity = null_entity;
	
#ifdef GROUND_ZERO
	e.gravityVector = MOVEDIR_DOWN;
#endif
};

/*
=================
G_Spawn

Either finds a free edict, or allocates a new one.
Try to avoid reusing an entity that was recently freed, because it
can cause the client to think the entity morphed into something else
instead of being removed and recreated, which can cause interpolated
angles and bad trails.
=================
*/
entity G_Spawn() =
{
	int i;
	
	for (i = game.maxclients + 1; i < globals.num_edicts; i++)
	{
		entity e = itoe(i);

		// the first couple seconds of server time can involve a lot of
		// freeing and allocating, so relax the replacement policy
		if (!e.inuse && (e.freeframenum < (2 * BASE_FRAMERATE) || (level.framenum - e.freeframenum) > (int)(0.5f * BASE_FRAMERATE)))
		{
		    G_InitEdict(e);
		    return e;
		}
	}

	if (i == game.maxentities)
		gi.error(__FUNC__": no free edicts");

	entity e = itoe(i);
	globals.num_edicts++;
	gi.SetNumEdicts(globals.num_edicts);
	G_InitEdict(e);
	return e;
};

const int BODY_QUEUE_SIZE = 8;

/*
=================
G_FreeEdict

Marks the edict as free
=================
*/
void(entity e) G_FreeEdict =
{
	gi.unlinkentity(e);        // unlink from world
	
	if (e.s.number <= (game.maxclients + BODY_QUEUE_SIZE))
		return;

	gi.ClearEntity(e);
	e.classname = "freed";
	e.freeframenum = level.framenum;
};

inline vector G_ProjectSource(vector point, vector distance, vector forward, vector right)
{
	return point + (forward * distance.x) + (right * distance.y) + [ 0, 0, distance.z ];
}

/*
=============
G_Find

Searches all active entities for the next one that holds
the matching string at fieldofs (use the FOFS() macro) in the structure.

Searches beginning at the edict after from, or the beginning (after clients) if
from is world. world will be returned if the end of the list is reached.
=============
*/
entity(entity from, .string fieldofs, string match) G_Find =
{
	strcasesensitive = false;

	if !(from)
		from = itoe(game.maxclients + 1);
	else
		from = next_ent(from);

	for (; etoi(from) < globals.num_edicts; from = next_ent(from))
	{
		if (from.fieldofs != match)
			continue;

		strcasesensitive = true;
		return from;
	}

	strcasesensitive = true;
	return world;
}

/*
=================
findradius

Returns entities that have origins within a spherical area

findradius (origin, radius)
=================
*/
entity(entity from, vector org, float rad) findradius =
{
	if !(from)
		from = itoe(1);
	else
		from = next_ent(from);

	for (; etoi(from) < globals.num_edicts; from = next_ent(from))
	{
		if (!from.inuse)
			continue;
		if (from.solid == SOLID_NOT)
			continue;
		vector eorg = org - (from.s.origin + (from.mins + from.maxs) * 0.5f);
		if (VectorLength(eorg) > rad)
			continue;
		return from;
	}

	return world;
}

/*
=============
G_PickTarget

Searches all active entities for the next one that holds
the matching string at fieldofs (use the FOFS() macro) in the structure.

Searches beginning at the edict after from, or the beginning if world.
world will be returned if the end of the list is reached.
=============
*/
const int MAX_CHOICES	= 8;

entity G_PickTarget(string stargetname)
{

	if (!stargetname)
	{
		gi.dprintf("G_PickTarget called with NULL targetname\n");
		return world;
	}

	entity	ent = world;
	int		num_choices = 0;
	entity	choice[MAX_CHOICES] = { 0 };

	while ((ent = G_Find(ent, targetname, stargetname)))
	{
		choice[num_choices++] = ent;

		if (num_choices == MAX_CHOICES)
			break;
	}

	if (!num_choices)
	{
		gi.dprintf("G_PickTarget: target %s not found\n", stargetname);
		return world;
	}

	return choice[Q_rand_uniform(num_choices)];
}

// from utils.qc
void(entity ent, entity cactivator) G_UseTargets;

static void(entity ent) Think_Delay
{
	G_UseTargets(ent, ent.activator);
	G_FreeEdict(ent);
}

/*
==============================
G_UseTargets

the global "activator" should be set to the entity that initiated the firing.

If self.delay is set, a DelayedUse entity will be created that will actually
do the SUB_UseTargets after that many seconds have passed.

Centerprints any self.message to the activator.

Search for (string)targetname in all entities that
match (string)self.target and call their .use function

==============================
*/
void(entity ent, entity cactivator) G_UseTargets =
{
//
// check for a delay
//
	if (ent.delay)
	{
		// create a temp object to fire at a later time
		entity t = G_Spawn();
		t.classname = "DelayedUse";
		t.nextthink = level.framenum + (int)(ent.delay * BASE_FRAMERATE);
		t.think = Think_Delay;
		t.activator = cactivator;
		if (!cactivator)
			gi.dprintf("Think_Delay with no activator\n");
		t.message = ent.message;
		t.target = ent.target;
		t.killtarget = ent.killtarget;
		return;
	}

//
// print the message
//
	if ((ent.message) && !(cactivator.svflags & SVF_MONSTER))
	{
		gi.centerprintf(cactivator, "%s", ent.message);
		if (ent.noise_index)
			gi.sound(cactivator, CHAN_AUTO, ent.noise_index, 1, ATTN_NORM, 0);
		else
			gi.sound(cactivator, CHAN_AUTO, gi.soundindex("misc/talk1.wav"), 1, ATTN_NORM, 0);
	}

//
// kill killtargets
//
	if (ent.killtarget)
	{
#ifdef GROUND_ZERO
		bool done = false;
		entity master;
#endif
		entity t = world;

		while ((t = G_Find(t, targetname, ent.killtarget)))
		{
#ifdef GROUND_ZERO
			// PMM - if this entity is part of a train, cleanly remove it
			if ((t.flags & FL_TEAMSLAVE) && t.teammaster)
			{
				master = t.teammaster;
				while (!done)
				{
					if (master.teamchain == t)
					{
						master.teamchain = t.teamchain;
						done = true;
					}
					master = master.teamchain;
				}
			}
#endif

			G_FreeEdict(t);
			if (!ent.inuse)
			{
				gi.dprintf("entity was removed while using killtargets\n");
				return;
			}
		}
	}

//
// fire targets
//
	if (ent.target)
	{
		entity t = world;

		while ((t = G_Find(t, targetname, ent.target)))
		{
			// doors fire area portals in a specific way
			if (striequals(t.classname, "func_areaportal") &&
				(striequals(ent.classname, "func_door") || striequals(ent.classname, "func_door_rotating")))
				continue;

			if (t == ent)
				gi.dprintf("WARNING: Entity used itself.\n");
			else if (t.use)
				t.use(t, ent, cactivator);

			if (!ent.inuse)
			{
				gi.dprintf("entity was removed while using targets\n");
				return;
			}
		}
	}
}

const vector VEC_UP			= [ 0, -1, 0 ];
const vector VEC_DOWN		= [ 0, -2, 0 ];

void(inout vector angles, out vector movedir) G_SetMovedir =
{
	if (angles == VEC_UP)
		movedir = MOVEDIR_UP;
	else if (angles == VEC_DOWN)
		movedir = MOVEDIR_DOWN;
	else
		AngleVectors(angles, &movedir, 0, 0);

	angles = vec3_origin;
}

#ifdef CTF
// from ctf.qc
void() CTFResetFlags;
void(ctfteam_t) CTFResetFlag;
void(entity) CTFRespawnTech;
string(ctfteam_t) CTFTeamName;
#endif

INLINE void(entity self) BecomeExplosion1 =
{
#ifdef CTF
	//flags are important
	if (self.classname == "item_flag_team1")
	{
		CTFResetFlag(CTF_TEAM1); // this will free self!
		gi.bprintf(PRINT_HIGH, "The %s flag has returned!\n", CTFTeamName(CTF_TEAM1));
		return;
	}
	if (self->classname == "item_flag_team2")
	{
		CTFResetFlag(CTF_TEAM2); // this will free self!
		gi.bprintf(PRINT_HIGH, "The %s flag has returned!\n", CTFTeamName(CTF_TEAM1));
		return;
	}

	// techs are important too
	if (self.item && (self.item->flags & IT_TECH))
	{
		CTFRespawnTech(self); // this frees self!
		return;
	}
#endif
	
	gi.WriteByte(svc_temp_entity);
	gi.WriteByte(TE_EXPLOSION1);
	gi.WritePosition(self.s.origin);
	gi.multicast(self.s.origin, MULTICAST_PVS);

	G_FreeEdict(self);
}

inline void(entity self) BecomeExplosion2 =
{
	gi.WriteByte(svc_temp_entity);
	gi.WriteByte(TE_EXPLOSION2);
	gi.WritePosition(self.s.origin);
	gi.multicast(self.s.origin, MULTICAST_PVS);

	G_FreeEdict(self);
}

/*
============
G_TouchTriggers

============
*/
void(entity ent) G_TouchTriggers =
{
	// dead things don't activate triggers!
	if ((ent.is_client || (ent.svflags & SVF_MONSTER)) && (ent.health <= 0))
		return;

	static hashset touches;
	
	if (handle_empty(touches))
		touches = hashset_alloc(32);

	int num = gi.BoxEdicts(touches, ent.absmin, ent.absmax, MAX_EDICTS, AREA_TRIGGERS);

	// be careful, it is possible to have an entity in this
	// list removed before we get to it (killtriggered)
	for (int i = 0; i < num; i++)
	{
		entity hit = touches[i];
		if (!hit.inuse)
			continue;
		if (!hit.touch)
			continue;
		hit.touch(hit, ent, vec3_origin, null_surface);
	}
}

/*
==============================================================================

Kill box

==============================================================================
*/

void(entity targ, entity inflictor, entity attacker, vector dir, vector point, vector normal, int damage, int knockback, damage_flags_t dflags, means_of_death_t mod) T_Damage;

/*
=================
KillBox

Kills all entities that would touch the proposed new positioning
of ent.  Ent should be unlinked before calling this!
=================
*/
bool(entity ent) KillBox =
{
	while (1)
	{
		trace_t	tr;
		gi.trace(&tr, ent.s.origin, ent.mins, ent.maxs, ent.s.origin, world, MASK_PLAYERSOLID);

		if (!tr.ent)
			break;

		// nail it
		T_Damage(tr.ent, ent, ent, vec3_origin, ent.s.origin, vec3_origin, 100000, 0, DAMAGE_NO_PROTECTION, MOD_TELEFRAG);

		// if we didn't kill it, fail
		if (tr.ent.solid)
			return false;
	}

	return true;        // all clear
};

/*
=============
visible

returns 1 if the entity is visible to self, even if not infront ()
=============
*/
bool(entity self, entity other) visible =
{
	vector	spot1;
	vector	spot2;
	trace_t trace;
	
	spot1 = self.s.origin;
	spot1.z += self.viewheight;
	spot2 = other.s.origin;
	spot2.z += other.viewheight;
	gi.traceline(&trace, spot1, spot2, self, MASK_OPAQUE);
	
	if (trace.fraction == 1.0f || trace.ent == other)
		return true;
	return false;
}

/*
=============
infront

returns 1 if the entity is in front (in sight) of self
=============
*/
bool(entity self, entity other) infront =
{
	vector	vec;
	float	dot;
	vector	forward;

	AngleVectors(self.s.angles, &forward, 0, 0);
	vec = other.s.origin - self.s.origin;
	VectorNormalize(vec);
	dot = vec * forward;

	if (dot > 0.3f)
		return true;
	return false;
}

inline float(entity self, entity other) realrange =
{
	return VectorDistance(self.s.origin, other.s.origin);
}