void G_ProjectSource(vector point, vector distance, vector forward, vector right, __out vector result)
{
	result = point + (forward * distance_x) + (right * distance_y);
	result_z += distance_z;
}

/*
=============
G_Find

Searches all active entities for the next one that holds
the matching string at fieldofs (use the FOFS() macro) in the structure.

Searches beginning at the edict after from, or the beginning if NULL
NULL will be returned if the end of the list is reached.

=============
*/
entity(entity from, .string fieldofs, string match) G_Find =
{
	string str;

	if (from == null_entity)
		from = world;
	else
		from = next_ent(from);

	for (; etoi(from) < globals.num_edicts; from = next_ent(from))
	{
		if (!from->inuse)
			continue;
		str = from.fieldofs;
		if (!str)
			continue;
		if (!stricmp(str, match))
			return from;
	}

	return null_entity;
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
	vector	eorg;

	if (from == null_entity)
		from = world;
	else
		from = next_ent(from);

	for (; etoi(from) < globals.num_edicts; from = next_ent(from)) {
		if (!from->inuse)
			continue;
		if (from->solid == SOLID_NOT)
			continue;
		eorg = org - (from.s.origin + (from.mins + from.maxs) * 0.5f);
		if (VectorLength(eorg) > rad)
			continue;
		return from;
	}

	return null_entity;
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
	entity	ent = world;
	int	num_choices = 0;
	entity	choice[MAX_CHOICES] = { 0 };

	if (!stargetname) {
		gi.dprintf("G_PickTarget called with NULL targetname\n");
		return world;
	}

	while (1) {
		ent = G_Find(ent, targetname, stargetname);
		if (ent == null_entity)
			break;
		choice[num_choices++] = ent;
		if (num_choices == MAX_CHOICES)
			break;
	}

	if (!num_choices) {
		gi.dprintf("G_PickTarget: target %s not found\n", stargetname);
		return world;
	}

	return choice[Q_rand_uniform(num_choices)];
}

// from utils.qc
void(entity ent, entity cactivator) G_UseTargets;
void G_FreeEdict(entity ent);

static void(entity ent) Think_Delay
{
	G_UseTargets(ent, ent->activator);
	G_FreeEdict(ent);
}

// from utils.qc
entity G_Spawn();

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
	entity	t;

//
// check for a delay
//
	if (ent->delay) {
		// create a temp object to fire at a later time
		t = G_Spawn();
		t->classname = "DelayedUse";
		t->nextthink = level.framenum + (int)(ent->delay * BASE_FRAMERATE);
		t->think = Think_Delay;
		t->activator = cactivator;
		if (!cactivator)
			gi.dprintf("Think_Delay with no activator\n");
		t->message = ent->message;
		t->target = ent->target;
		t->killtarget = ent->killtarget;
		return;
	}


//
// print the message
//
	if ((ent->message) && !(cactivator->svflags & SVF_MONSTER)) {
		gi.centerprintf(cactivator, "%s", ent->message);
		if (ent->noise_index)
			gi.sound(cactivator, CHAN_AUTO, ent->noise_index, 1, ATTN_NORM, 0);
		else
			gi.sound(cactivator, CHAN_AUTO, gi.soundindex("misc/talk1.wav"), 1, ATTN_NORM, 0);
	}

//
// kill killtargets
//
	if (ent->killtarget) {
		t = null_entity;
		while ((t = G_Find(t, targetname, ent->killtarget)) != null_entity) {
			G_FreeEdict(t);
			if (!ent->inuse) {
				gi.dprintf("entity was removed while using killtargets\n");
				return;
			}
		}
	}

//
// fire targets
//
	if (ent->target) {
		t = null_entity;
		while ((t = G_Find(t, targetname, ent->target)) != null_entity) {
			// doors fire area portals in a specific way
			if (!stricmp(t->classname, "func_areaportal") &&
				(!stricmp(ent->classname, "func_door") || !stricmp(ent->classname, "func_door_rotating")))
				continue;

			if (t == ent) {
				gi.dprintf("WARNING: Entity used itself.\n");
			} else {
				if (t->use)
					t->use(t, ent, cactivator);
			}
			if (!ent->inuse) {
				gi.dprintf("entity was removed while using targets\n");
				return;
			}
		}
	}
}

const vector VEC_UP		= [ 0, -1, 0 ];
const vector MOVEDIR_UP		= [ 0, 0, 1 ];
const vector VEC_DOWN		= [ 0, -2, 0 ];
const vector MOVEDIR_DOWN	= [ 0, 0, -1 ];

void(__inout vector angles, __out vector movedir) G_SetMovedir =
{
	if (angles == VEC_UP) {
		movedir = MOVEDIR_UP;
	} else if (angles == VEC_DOWN) {
		movedir = MOVEDIR_DOWN;
	} else {
		AngleVectors(angles, &movedir, 0, 0);
	}

	angles = vec3_origin;
}


/*
=================
G_InitEdict

Marks an entity as active, and sets up some default parameters.
=================
*/
void(entity e) G_InitEdict =
{
	e.inuse = true;
	e.classname = "noclass";
	e.gravity = 1.0f;
	e.groundentity = null_entity;
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
		if (!e.inuse && (e.freetime < 2 || level.time - e.freetime > 0.5f))
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
	e.freetime = level.time;
}

/*
============
G_TouchTriggers

============
*/
void(entity ent) G_TouchTriggers =
{
	int	i;
	entity	hit;

	// dead things don't activate triggers!
	if ((ent->is_client || (ent->svflags & SVF_MONSTER)) && (ent->health <= 0))
		return;

	entity_list_t touches = gi.BoxEdicts(ent->absmin, ent->absmax, MAX_EDICTS, AREA_TRIGGERS);
	int num = touches.length;

	// be careful, it is possible to have an entity in this
	// list removed before we get to it (killtriggered)
	for (i = 0 ; i < num ; i++) {
		hit = touches[i];
		if (!hit->inuse)
			continue;
		if (!hit->touch)
			continue;
		hit->touch(hit, ent, null_plane, null_surface);
	}
	
	entity_list_free(touches);
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
	trace_t     tr;

	while (1) {
		gi.trace(&tr, ent->s.origin, ent->mins, ent->maxs, ent->s.origin, world, MASK_PLAYERSOLID);

		if (!tr.ent)
			break;

		// nail it
		T_Damage(tr.ent, ent, ent, vec3_origin, ent->s.origin, vec3_origin, 100000, 0, DAMAGE_NO_PROTECTION, MOD_TELEFRAG);

		// if we didn't kill it, fail
		if (tr.ent->solid)
			return false;
	}

	return true;        // all clear
};