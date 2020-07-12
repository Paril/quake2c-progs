void G_ProjectSource(vector point, vector distance, vector forward, vector right, __out vector result)
{
	result = point + (forward * distance[(ARRAY_INDEX_TYPE)0]) + (right * distance[(ARRAY_INDEX_TYPE)1]);
	result[(ARRAY_INDEX_TYPE)2] += distance[(ARRAY_INDEX_TYPE)2];
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
	int	i, num;
	entity	hit;

	// dead things don't activate triggers!
	if ((ent->is_client || (ent->svflags & SVF_MONSTER)) && (ent->health <= 0))
		return;

	box_edicts_t touches = gi.BoxEdicts(ent->absmin, ent->absmax, MAX_EDICTS, AREA_TRIGGERS, num);

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
	
	gi.FreeBoxEdicts(touches);
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
		trace_and_result(tr, ent->s.origin, ent->mins, ent->maxs, ent->s.origin, world, MASK_PLAYERSOLID);

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