/*


pushmove objects do not obey gravity, and do not interact with each other or trigger fields, but block normal movement and push normal objects when they move.

onground is set for toss objects when they come to a complete rest.  it is set for steping or walking objects

doors, plats, etc are SOLID_BSP, and MOVETYPE_PUSH
bonus items are SOLID_TRIGGER touch, and MOVETYPE_TOSS
corpses are SOLID_NOT and MOVETYPE_TOSS
crates are SOLID_BBOX and MOVETYPE_TOSS
walking monsters are SOLID_SLIDEBOX and MOVETYPE_STEP
flying/floating monsters are SOLID_SLIDEBOX and MOVETYPE_FLY

solid_edge items only clip against bsp models.

*/


/*
============
SV_TestEntityPosition

============
*/
static entity(entity ent) SV_TestEntityPosition =
{
	trace_t trace;
	int	mask;

	if (ent->clipmask)
		mask = ent->clipmask;
	else
		mask = MASK_SOLID;
	trace_and_result(trace, ent->s.origin, ent->mins, ent->maxs, ent->s.origin, ent, mask);

	if (trace.startsolid)
		return world;

	return null_entity;
}


/*
================
SV_CheckVelocity
================
*/
static void(entity ent) SV_CheckVelocity =
{
	/*int     i;

//
// bound velocity
//
	for (i = 0 ; i < 3 ; i++) {
		if (ent->velocity[i] > sv_maxvelocity->value)
			ent->velocity[i] = sv_maxvelocity->value;
		else if (ent->velocity[i] < -sv_maxvelocity->value)
			ent->velocity[i] = -sv_maxvelocity->value;
	}*/
	if (ent->velocity[(ARRAY_INDEX_TYPE)0] > sv_maxvelocity->floatVal)
		ent->velocity[(ARRAY_INDEX_TYPE)0] = sv_maxvelocity->floatVal;
	else if (ent->velocity[(ARRAY_INDEX_TYPE)0] < -sv_maxvelocity->floatVal)
		ent->velocity[(ARRAY_INDEX_TYPE)0] = -sv_maxvelocity->floatVal;
		
	if (ent->velocity[(ARRAY_INDEX_TYPE)1] > sv_maxvelocity->floatVal)
		ent->velocity[(ARRAY_INDEX_TYPE)1] = sv_maxvelocity->floatVal;
	else if (ent->velocity[(ARRAY_INDEX_TYPE)1] < -sv_maxvelocity->floatVal)
		ent->velocity[(ARRAY_INDEX_TYPE)1] = -sv_maxvelocity->floatVal;
		
	if (ent->velocity[(ARRAY_INDEX_TYPE)2] > sv_maxvelocity->floatVal)
		ent->velocity[(ARRAY_INDEX_TYPE)2] = sv_maxvelocity->floatVal;
	else if (ent->velocity[(ARRAY_INDEX_TYPE)2] < -sv_maxvelocity->floatVal)
		ent->velocity[(ARRAY_INDEX_TYPE)2] = -sv_maxvelocity->floatVal;
}

/*
=============
SV_RunThink

Runs thinking code for this frame if necessary
=============
*/
static bool(entity ent) SV_RunThink =
{
	int	thinktime;

	thinktime = ent->nextthink;
	if (thinktime <= 0)
		return true;
	if (thinktime > level.framenum)
		return true;

	ent->nextthink = 0;
	if (!ent->think)
		gi.error("NULL ent->think");
	ent->think(ent);

	return false;
}

/*
==================
SV_Impact

Two entities have touched, so run their touch functions
==================
*/
static void(entity e1, trace_t trace) SV_Impact =
{
	entity	e2;

	e2 = trace->ent;

	if (e1->touch && e1->solid != SOLID_NOT)
		e1->touch(e1, e2, trace->plane, trace->surface);

	if (e2->touch && e2->solid != SOLID_NOT)
		e2->touch(e2, e1, null_plane, null_surface);
}


/*
==================
ClipVelocity

Slide off of the impacting object
returns the blocked flags (1 = floor, 2 = step / wall)
==================
*/
const float STOP_EPSILON = 0.1f;

static int(vector in, vector normal, __out vector out, float overbounce) ClipVelocity =
{
	float	backoff;
	float	change;
	int	i, blocked;

	blocked = 0;
	if (normal[(ARRAY_INDEX_TYPE)2] > 0)
		blocked |= 1;       // floor
	if (!normal[(ARRAY_INDEX_TYPE)2])
		blocked |= 2;       // step

	backoff = DotProduct(in, normal) * overbounce;

	/*for (i = 0 ; i < 3 ; i++) {
		change = normal[i] * backoff;
		out[i] = in[i] - change;
		if (out[i] > -STOP_EPSILON && out[i] < STOP_EPSILON)
			out[i] = 0;
	}*/
	change = normal[(ARRAY_INDEX_TYPE)0] * backoff;
	out[(ARRAY_INDEX_TYPE)0] = in[(ARRAY_INDEX_TYPE)0] - change;
	if (out[(ARRAY_INDEX_TYPE)0] > -STOP_EPSILON && out[(ARRAY_INDEX_TYPE)0] < STOP_EPSILON)
		out[(ARRAY_INDEX_TYPE)0] = 0;
		
	change = normal[(ARRAY_INDEX_TYPE)1] * backoff;
	out[(ARRAY_INDEX_TYPE)1] = in[(ARRAY_INDEX_TYPE)1] - change;
	if (out[(ARRAY_INDEX_TYPE)1] > -STOP_EPSILON && out[(ARRAY_INDEX_TYPE)1] < STOP_EPSILON)
		out[(ARRAY_INDEX_TYPE)1] = 0;
		
	change = normal[(ARRAY_INDEX_TYPE)2] * backoff;
	out[(ARRAY_INDEX_TYPE)2] = in[(ARRAY_INDEX_TYPE)2] - change;
	if (out[(ARRAY_INDEX_TYPE)2] > -STOP_EPSILON && out[(ARRAY_INDEX_TYPE)2] < STOP_EPSILON)
		out[(ARRAY_INDEX_TYPE)2] = 0;

	return blocked;
}


/*
============
SV_FlyMove

The basic solid body movement clip that slides along multiple planes
Returns the clipflags if the velocity was modified (hit something solid)
1 = floor
2 = wall / step
4 = dead stop
============
*/
const int MAX_CLIP_PLANES = 5;

static int(entity ent, float time, int mask) SV_FlyMove =
{
	entity	hit;
	int	bumpcount, numbumps;
	vector	dir;
	float	d;
	int	numplanes;
	vector	planes[MAX_CLIP_PLANES];
	vector	primal_velocity, original_velocity, new_velocity;
	int	i, j;
	trace_t	trace;
	vector	end;
	float	time_left;
	int	blocked;

	numbumps = 4;

	blocked = 0;
	VectorCopy(ent->velocity, original_velocity);
	VectorCopy(ent->velocity, primal_velocity);
	numplanes = 0;

	time_left = time;

	ent->groundentity = null_entity;
	for (bumpcount = 0 ; bumpcount < numbumps ; bumpcount++) {
		end = ent.s.origin + time_left * ent->velocity;

		trace_and_result(trace, ent->s.origin, ent->mins, ent->maxs, end, ent, mask);

		if (trace.allsolid) {
			// entity is trapped in another solid
			VectorClear(ent->velocity);
			return 3;
		}

		if (trace.fraction > 0) {
			// actually covered some distance
			VectorCopy(trace.endpos, ent->s.origin);
			VectorCopy(ent->velocity, original_velocity);
			numplanes = 0;
		}

		if (trace.fraction == 1)
			break;     // moved the entire distance

		hit = trace.ent;

		if (trace.plane.normal[(ARRAY_INDEX_TYPE)2] > 0.7f) {
			blocked |= 1;       // floor
			if (hit->solid == SOLID_BSP) {
				ent->groundentity = hit;
				ent->groundentity_linkcount = hit->linkcount;
			}
		}
		if (!trace.plane.normal[(ARRAY_INDEX_TYPE)2]) {
			blocked |= 2;       // step
		}

//
// run the impact function
//
		SV_Impact(ent, trace);

		if (!ent->inuse)
			break;      // removed by the impact function


		time_left -= time_left * trace.fraction;

		// cliped to another plane
		if (numplanes >= MAX_CLIP_PLANES) {
			// this shouldn't really happen
			VectorClear(ent->velocity);
			return 3;
		}

		VectorCopy(trace.plane.normal, planes[(ARRAY_INDEX_TYPE)numplanes]);
		numplanes++;

//
// modify original_velocity so it parallels all of the clip planes
//
		for (i = 0 ; i < numplanes ; i++) {
			ClipVelocity(original_velocity, planes[(ARRAY_INDEX_TYPE)i], new_velocity, 1);

			for (j = 0 ; j < numplanes ; j++)
				if ((j != i) && !VectorCompare(planes[(ARRAY_INDEX_TYPE)i], planes[(ARRAY_INDEX_TYPE)j])) {
					if (DotProduct(new_velocity, planes[(ARRAY_INDEX_TYPE)j]) < 0)
						break;  // not ok
				}
			if (j == numplanes)
				break;
		}

		if (i != numplanes) {
			// go along this plane
			VectorCopy(new_velocity, ent->velocity);
		} else {
			// go along the crease
			if (numplanes != 2) {
//              gi.dprintf ("clip velocity, numplanes == %i\n",numplanes);
				VectorClear(ent->velocity);
				return 7;
			}
			CrossProduct(planes[(ARRAY_INDEX_TYPE)0], planes[(ARRAY_INDEX_TYPE)1], dir);
			d = DotProduct(dir, ent->velocity);
			VectorScale(dir, d, ent->velocity);
		}

//
// if original velocity is against the original velocity, stop dead
// to avoid tiny occilations in sloping corners
//
		if (DotProduct(ent->velocity, primal_velocity) <= 0) {
			VectorClear(ent->velocity);
			return blocked;
		}
	}

	return blocked;
}


/*
============
SV_AddGravity

============
*/
static void(entity ent) SV_AddGravity =
{
	ent->velocity[(ARRAY_INDEX_TYPE)2] -= ent->gravity * sv_gravity->floatVal * FRAMETIME;
}

/*
===============================================================================

PUSHMOVE

===============================================================================
*/

/*
============
SV_PushEntity

Does not change the entities velocity at all
============
*/
static void(entity ent, vector push, __out trace_t trace) SV_PushEntity =
{
	vector	start;
	vector	end;
	int	mask;

	VectorCopy(ent->s.origin, start);
	VectorAdd(start, push, end);

retry:
	if (ent->clipmask)
		mask = ent->clipmask;
	else
		mask = MASK_SOLID;

	trace_and_result(trace, start, ent->mins, ent->maxs, end, ent, mask);

	VectorCopy(trace.endpos, ent->s.origin);
	gi.linkentity(ent);

	if (trace.fraction != 1.0f)
	{
		SV_Impact(ent, trace);

		// if the pushed entity went away and the pusher is still there
		if (!trace.ent->inuse && ent->inuse) {
			// move the pusher back and try again
			VectorCopy(start, ent->s.origin);
			gi.linkentity(ent);
			goto retry;
		}
	}

	if (ent->inuse)
		G_TouchTriggers(ent);
}


typedef struct {
	entity	ent;
	vector	origin;
	vector	angles;
#if USE_SMOOTH_DELTA_ANGLES
	int     deltayaw;
#endif
} pushed_t;

static pushed_t	pushed[MAX_EDICTS];
static int	pushed_p;
static entity	obstacle;

/*
============
SV_Push

Objects need to be moved back on a failed push,
otherwise riders would continue to slide.
============
*/
static bool(entity pusher, vector move, vector amove) SV_Push =
{
	int		i, e;
	entity		check, block;
	vector		mins, maxs;
	vector		org, org2, move2, forward, right, up;

	// clamp the move to 1/8 units, so the position will
	// be accurate for client side prediction
	for (i = 0 ; i < 3 ; i++) {
		float   temp;
		temp = move[(ARRAY_INDEX_TYPE)i] * 8.0f;
		if (temp > 0.0f)
			temp += 0.5f;
		else
			temp -= 0.5f;
		move[(ARRAY_INDEX_TYPE)i] = 0.125f * (int)temp;
	}

	// find the bounding box
	mins = pusher.absmin + move;
	maxs = pusher.absmax + move;

// we need this for pushing things later
	VectorNegate(amove, org);
	AngleVectors(org, forward, right, up);

// save the pusher's original position
	pushed[(ARRAY_INDEX_TYPE)pushed_p]->ent = pusher;
	VectorCopy(pusher->s.origin, pushed[(ARRAY_INDEX_TYPE)pushed_p]->origin);
	VectorCopy(pusher->s.angles, pushed[(ARRAY_INDEX_TYPE)pushed_p]->angles);
#if USE_SMOOTH_DELTA_ANGLES
	if (pusher->client)
		pushed[(ARRAY_INDEX_TYPE)pushed_p]->deltayaw = pusher->client->ps.pmove.delta_angles[YAW];
#endif
	pushed_p++;

// move the pusher to it's final position
	VectorAdd(pusher->s.origin, move, pusher->s.origin);
	VectorAdd(pusher->s.angles, amove, pusher->s.angles);
	gi.linkentity(pusher);

// see if any solid entities are inside the final position
	for (e = 1; e < globals.num_edicts; e++)
	{
		check = itoe(e);
		if (!check->inuse)
			continue;
		if (check->movetype == MOVETYPE_PUSH
			|| check->movetype == MOVETYPE_STOP
			|| check->movetype == MOVETYPE_NONE
			|| check->movetype == MOVETYPE_NOCLIP)
			continue;

		if (!check->area.prev)
			continue;       // not linked in anywhere

		// if the entity is standing on the pusher, it will definitely be moved
		if (check->groundentity != pusher) {
			// see if the ent needs to be tested
			if (check->absmin[(ARRAY_INDEX_TYPE)0] >= maxs[(ARRAY_INDEX_TYPE)0]
				|| check->absmin[(ARRAY_INDEX_TYPE)1] >= maxs[(ARRAY_INDEX_TYPE)1]
				|| check->absmin[(ARRAY_INDEX_TYPE)2] >= maxs[(ARRAY_INDEX_TYPE)2]
				|| check->absmax[(ARRAY_INDEX_TYPE)0] <= mins[(ARRAY_INDEX_TYPE)0]
				|| check->absmax[(ARRAY_INDEX_TYPE)1] <= mins[(ARRAY_INDEX_TYPE)1]
				|| check->absmax[(ARRAY_INDEX_TYPE)2] <= mins[(ARRAY_INDEX_TYPE)2])
				continue;

			// see if the ent's bbox is inside the pusher's final position
			if (!SV_TestEntityPosition(check))
				continue;
		}

		if ((pusher->movetype == MOVETYPE_PUSH) || (check->groundentity == pusher)) {
			// move this entity
			pushed[(ARRAY_INDEX_TYPE)pushed_p]->ent = check;
			VectorCopy(check->s.origin, pushed[(ARRAY_INDEX_TYPE)pushed_p]->origin);
			VectorCopy(check->s.angles, pushed[(ARRAY_INDEX_TYPE)pushed_p]->angles);
#if USE_SMOOTH_DELTA_ANGLES
			if (check->client)
				pushed[(ARRAY_INDEX_TYPE)pushed_p]->deltayaw = check->client->ps.pmove.delta_angles[YAW];
#endif
			pushed_p++;

			// try moving the contacted entity
			VectorAdd(check->s.origin, move, check->s.origin);
#if USE_SMOOTH_DELTA_ANGLES
			if (check->client) {
				// FIXME: doesn't rotate monsters?
				// FIXME: skuller: needs client side interpolation
				check->client->ps.pmove.delta_angles[YAW] += ANGLE2SHORT(amove[YAW]);
			}
#endif

			// figure movement due to the pusher's amove
			VectorSubtract(check->s.origin, pusher->s.origin, org);
			org2[(ARRAY_INDEX_TYPE)0] = DotProduct(org, forward);
			org2[(ARRAY_INDEX_TYPE)1] = -DotProduct(org, right);
			org2[(ARRAY_INDEX_TYPE)2] = DotProduct(org, up);
			VectorSubtract(org2, org, move2);
			VectorAdd(check->s.origin, move2, check->s.origin);

			// may have pushed them off an edge
			if (check->groundentity != pusher)
				check->groundentity = null_entity;

			block = SV_TestEntityPosition(check);
			if (!block) {
				// pushed ok
				gi.linkentity(check);
				// impact?
				continue;
			}

			// if it is ok to leave in the old position, do it
			// this is only relevent for riding entities, not pushed
			// FIXME: this doesn't acount for rotation
			VectorSubtract(check->s.origin, move, check->s.origin);
			block = SV_TestEntityPosition(check);
			if (!block) {
				pushed_p--;
				continue;
			}
		}

		// save off the obstacle so we can call the block function
		obstacle = check;

		// move back any entities we already moved
		// go backwards, so if the same entity was pushed
		// twice, it goes back to the original position
		for (int p = pushed_p - 1 ; p >= 0 ; p--) {
			VectorCopy(pushed[(ARRAY_INDEX_TYPE)p]->origin, pushed[(ARRAY_INDEX_TYPE)p]->ent->s.origin);
			VectorCopy(pushed[(ARRAY_INDEX_TYPE)p]->angles, pushed[(ARRAY_INDEX_TYPE)p]->ent->s.angles);
#if USE_SMOOTH_DELTA_ANGLES
			if (pushed[(ARRAY_INDEX_TYPE)p]->ent->client) {
				pushed[(ARRAY_INDEX_TYPE)p]->ent->client->ps.pmove.delta_angles[YAW] = pushed[(ARRAY_INDEX_TYPE)p]->deltayaw;
			}
#endif
			gi.linkentity(pushed[(ARRAY_INDEX_TYPE)p]->ent);
		}
		return false;
	}

//FIXME: is there a better way to handle this?
	// see if anything we moved has touched a trigger
	for (int p = pushed_p - 1 ; p >= 0 ; p--)
		G_TouchTriggers(pushed[(ARRAY_INDEX_TYPE)p]->ent);

	return true;
}

/*
================
SV_Physics_Pusher

Bmodel objects don't interact with each other, but
push all box objects
================
*/
static void(entity ent) SV_Physics_Pusher =
{
	vector	move, amove;
	entity	part, mv;

	// if not a team captain, so movement will be handled elsewhere
	if (ent->flags & FL_TEAMSLAVE)
		return;

	// make sure all team slaves can move before commiting
	// any moves or calling any think functions
	// if the move is blocked, all moved objects will be backed out
//retry:
	pushed_p = 0;
	for (part = ent ; part ; part = part->teamchain) {
		if (!VectorEmpty(part->velocity) || !VectorEmpty(part->avelocity)) {
			// object is moving
			VectorScale(part->velocity, FRAMETIME, move);
			VectorScale(part->avelocity, FRAMETIME, amove);

			if (!SV_Push(part, move, amove))
				break;  // move was blocked
		}
	}
	if (pushed_p >= MAX_EDICTS)
		gi.error("pushed_p > &pushed[MAX_EDICTS], memory corrupted");

	if (part) {
		// the move failed, bump all nextthink times and back out moves
		for (mv = ent ; mv ; mv = mv->teamchain) {
			if (mv->nextthink > 0)
				mv->nextthink++;
		}

		// if the pusher has a "blocked" function, call it
		// otherwise, just stay in place until the obstacle is gone
		if (part->blocked)
			part->blocked(part, obstacle);
#if 0
		// if the pushed entity went away and the pusher is still there
		if (!obstacle->inuse && part->inuse)
			goto retry;
#endif
	} else {
		// the move succeeded, so call all think functions
		for (part = ent ; part ; part = part->teamchain) {
			SV_RunThink(part);
		}
	}
}

//==================================================================

/*
=============
SV_Physics_None

Non moving objects can only think
=============
*/
static void(entity ent) SV_Physics_None =
{
// regular thinking
	SV_RunThink(ent);
}

/*
=============
SV_Physics_Noclip

A moving object that doesn't obey physics
=============
*/
static void(entity ent) SV_Physics_Noclip =
{
// regular thinking
	if (!SV_RunThink(ent))
		return;
	if (!ent->inuse)
		return;

	VectorMA(ent->s.angles, FRAMETIME, ent->avelocity, ent->s.angles);
	VectorMA(ent->s.origin, FRAMETIME, ent->velocity, ent->s.origin);

	gi.linkentity(ent);
}

/*
==============================================================================

TOSS / BOUNCE

==============================================================================
*/

/*
=============
SV_Physics_Toss

Toss, bounce, and fly movement.  When onground, do nothing.
=============
*/
static void(entity ent) SV_Physics_Toss =
{
	trace_t	trace;
	vector	move;
	float	backoff;
	entity	slave;
	int	wasinwater;
	int	isinwater;
	vector	old_origin;

// regular thinking
	SV_RunThink(ent);
	if (!ent->inuse)
		return;

	// if not a team captain, so movement will be handled elsewhere
	if (ent->flags & FL_TEAMSLAVE)
		return;

	if (ent->velocity[(ARRAY_INDEX_TYPE)2] > 0)
		ent->groundentity = null_entity;

// check for the groundentity going away
	if (ent->groundentity != null_entity)
		if (!ent->groundentity->inuse)
			ent->groundentity = null_entity;

// if onground, return without moving
	if (ent->groundentity != null_entity)
		return;

	VectorCopy(ent->s.origin, old_origin);

	SV_CheckVelocity(ent);

// add gravity
	if (ent->movetype != MOVETYPE_FLY
		&& ent->movetype != MOVETYPE_FLYMISSILE)
		SV_AddGravity(ent);

// move angles
	VectorMA(ent->s.angles, FRAMETIME, ent->avelocity, ent->s.angles);

// move origin
	VectorScale(ent->velocity, FRAMETIME, move);
	SV_PushEntity(ent, move, trace);
	if (!ent->inuse)
		return;

	if (trace.fraction < 1) {
		if (ent->movetype == MOVETYPE_BOUNCE)
			backoff = 1.5f;
		else
			backoff = 1f;

		ClipVelocity(ent->velocity, trace.plane.normal, ent->velocity, backoff);

		// stop if on ground
		if (trace.plane.normal[(ARRAY_INDEX_TYPE)2] > 0.7f) {
			if (ent->velocity[(ARRAY_INDEX_TYPE)2] < 60f || ent->movetype != MOVETYPE_BOUNCE) {
				ent->groundentity = trace.ent;
				ent->groundentity_linkcount = trace.ent->linkcount;
				VectorClear(ent->velocity);
				VectorClear(ent->avelocity);
			}
		}
	}

// check for water transition
	wasinwater = (ent->watertype & MASK_WATER);
	ent->watertype = gi.pointcontents(ent->s.origin);
	isinwater = ent->watertype & MASK_WATER;

	if (isinwater)
		ent->waterlevel = 1;
	else
		ent->waterlevel = 0;

	if (!wasinwater && isinwater)
		gi.positioned_sound(old_origin, world, CHAN_AUTO, gi.soundindex("misc/h2ohit1.wav"), 1, 1, 0);
	else if (wasinwater && !isinwater)
		gi.positioned_sound(ent->s.origin, world, CHAN_AUTO, gi.soundindex("misc/h2ohit1.wav"), 1, 1, 0);

// move teamslaves
	for (slave = ent->teamchain; slave; slave = slave->teamchain) {
		VectorCopy(ent->s.origin, slave->s.origin);
		gi.linkentity(slave);
	}
}

/*
===============================================================================

STEPPING MOVEMENT

===============================================================================
*/

/*
=============
SV_Physics_Step

Monsters freefall when they don't have a ground entity, otherwise
all movement is done with discrete steps.

This is also used for objects that have become still on the ground, but
will fall if the floor is pulled out from under them.
FIXME: is this true?
=============
*/

//FIXME: hacked in for E3 demo
const float sv_stopspeed	= 100f;
const float sv_friction		= 6f;
const float sv_waterfriction	= 1f;

static void(entity ent) SV_AddRotationalFriction =
{
	int	n;
	float	adjustment;

	VectorMA(ent->s.angles, FRAMETIME, ent->avelocity, ent->s.angles);
	adjustment = FRAMETIME * sv_stopspeed * sv_friction;
	/*for (n = 0; n < 3; n++) {
		if (ent->avelocity[n] > 0) {
			ent->avelocity[n] -= adjustment;
			if (ent->avelocity[n] < 0)
				ent->avelocity[n] = 0;
		} else {
			ent->avelocity[n] += adjustment;
			if (ent->avelocity[n] > 0)
				ent->avelocity[n] = 0;
		}
	}*/
	if (ent->avelocity[(ARRAY_INDEX_TYPE)0] > 0) {
		ent->avelocity[(ARRAY_INDEX_TYPE)0] -= adjustment;
		if (ent->avelocity[(ARRAY_INDEX_TYPE)0] < 0)
			ent->avelocity[(ARRAY_INDEX_TYPE)0] = 0;
	} else {
		ent->avelocity[(ARRAY_INDEX_TYPE)0] += adjustment;
		if (ent->avelocity[(ARRAY_INDEX_TYPE)0] > 0)
			ent->avelocity[(ARRAY_INDEX_TYPE)0] = 0;
	}
	
	if (ent->avelocity[(ARRAY_INDEX_TYPE)1] > 0) {
		ent->avelocity[(ARRAY_INDEX_TYPE)1] -= adjustment;
		if (ent->avelocity[(ARRAY_INDEX_TYPE)1] < 0)
			ent->avelocity[(ARRAY_INDEX_TYPE)1] = 0;
	} else {
		ent->avelocity[(ARRAY_INDEX_TYPE)1] += adjustment;
		if (ent->avelocity[(ARRAY_INDEX_TYPE)1] > 0)
			ent->avelocity[(ARRAY_INDEX_TYPE)1] = 0;
	}
	
	if (ent->avelocity[(ARRAY_INDEX_TYPE)2] > 0) {
		ent->avelocity[(ARRAY_INDEX_TYPE)2] -= adjustment;
		if (ent->avelocity[(ARRAY_INDEX_TYPE)2] < 0)
			ent->avelocity[(ARRAY_INDEX_TYPE)2] = 0;
	} else {
		ent->avelocity[(ARRAY_INDEX_TYPE)2] += adjustment;
		if (ent->avelocity[(ARRAY_INDEX_TYPE)2] > 0)
			ent->avelocity[(ARRAY_INDEX_TYPE)2] = 0;
	}
}

//TODO
void(entity ent) M_CheckGround = { }
bool(entity ent) M_CheckBottom = { return false; }

static void(entity ent) SV_Physics_Step =
{
	bool	wasonground;
	bool	hitsound = false;
	float	speed, newspeed, control;
	float	friction;
	entity	cgroundentity;
	int	mask;

	// airborn monsters should always check for ground
	if (ent->groundentity == null_entity)
		M_CheckGround(ent);

	cgroundentity = ent->groundentity;

	SV_CheckVelocity(ent);

	if (cgroundentity != null_entity)
		wasonground = true;
	else
		wasonground = false;

	if (!VectorEmpty(ent->avelocity))
		SV_AddRotationalFriction(ent);

	// add gravity except:
	//   flying monsters
	//   swimming monsters who are in the water
	if (! wasonground)
		if (!(ent->flags & FL_FLY))
			if (!((ent->flags & FL_SWIM) && (ent->waterlevel > 2))) {
				if (ent->velocity[(ARRAY_INDEX_TYPE)2] < sv_gravity->floatVal * -0.1f)
					hitsound = true;
				if (ent->waterlevel == 0)
					SV_AddGravity(ent);
			}

	// friction for flying monsters that have been given vertical velocity
	if ((ent->flags & FL_FLY) && (ent->velocity[(ARRAY_INDEX_TYPE)2] != 0)) {
		speed = fabsf(ent->velocity[(ARRAY_INDEX_TYPE)2]);
		control = speed < sv_stopspeed ? sv_stopspeed : speed;
		friction = sv_friction / 3;
		newspeed = speed - (FRAMETIME * control * friction);
		if (newspeed < 0)
			newspeed = 0;
		newspeed /= speed;
		ent->velocity[(ARRAY_INDEX_TYPE)2] *= newspeed;
	}

	// friction for flying monsters that have been given vertical velocity
	if ((ent->flags & FL_SWIM) && (ent->velocity[(ARRAY_INDEX_TYPE)2] != 0)) {
		speed = fabsf(ent->velocity[(ARRAY_INDEX_TYPE)2]);
		control = speed < sv_stopspeed ? sv_stopspeed : speed;
		newspeed = speed - (FRAMETIME * control * sv_waterfriction * ent->waterlevel);
		if (newspeed < 0)
			newspeed = 0;
		newspeed /= speed;
		ent->velocity[(ARRAY_INDEX_TYPE)2] *= newspeed;
	}

	if (ent.velocity) {
		// apply friction
		// let dead monsters who aren't completely onground slide
		if ((wasonground) || (ent->flags & (FL_SWIM | FL_FLY)))
			if (!(ent->health <= 0 && !M_CheckBottom(ent))) {
				speed = sqrtf(ent.velocity[(ARRAY_INDEX_TYPE)0] * ent.velocity[(ARRAY_INDEX_TYPE)0] + ent.velocity[(ARRAY_INDEX_TYPE)1] * ent.velocity[(ARRAY_INDEX_TYPE)1]);
				if (speed) {
					friction = sv_friction;

					control = speed < sv_stopspeed ? sv_stopspeed : speed;
					newspeed = speed - FRAMETIME * control * friction;

					if (newspeed < 0)
						newspeed = 0;
					newspeed /= speed;

					ent.velocity[(ARRAY_INDEX_TYPE)0] *= newspeed;
					ent.velocity[(ARRAY_INDEX_TYPE)1] *= newspeed;
				}
			}

		if (ent->svflags & SVF_MONSTER)
			mask = MASK_MONSTERSOLID;
		else
			mask = MASK_SOLID;
		SV_FlyMove(ent, FRAMETIME, mask);

		gi.linkentity(ent);
		G_TouchTriggers(ent);
		if (!ent->inuse)
			return;

		if (ent->groundentity)
			if (!wasonground)
				if (hitsound)
					gi.sound(ent, 0, gi.soundindex("world/land.wav"), 1, 1, 0);
	}

// regular thinking
	SV_RunThink(ent);
}

//============================================================================
/*
================
G_RunEntity

================
*/
void(entity ent) G_RunEntity =
{
	if (ent->prethink)
		ent->prethink(ent);

	switch (ent->movetype) {
	case MOVETYPE_PUSH:
	case MOVETYPE_STOP:
		SV_Physics_Pusher(ent);
		break;
	case MOVETYPE_NONE:
		SV_Physics_None(ent);
		break;
	case MOVETYPE_NOCLIP:
		SV_Physics_Noclip(ent);
		break;
	case MOVETYPE_STEP:
		SV_Physics_Step(ent);
		break;
	case MOVETYPE_TOSS:
	case MOVETYPE_BOUNCE:
	case MOVETYPE_FLY:
	case MOVETYPE_FLYMISSILE:
		SV_Physics_Toss(ent);
		break;
	default:
		gi.error("SV_Physics: bad movetype %i", ent->movetype);
	}
}
