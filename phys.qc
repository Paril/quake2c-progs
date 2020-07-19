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
static bool(entity ent) SV_TestEntityPosition =
{
	trace_t trace;
	int	mask;

	if (ent->clipmask)
		mask = ent->clipmask;
	else
		mask = MASK_SOLID;
	gi.trace(&trace, ent->s.origin, ent->mins, ent->maxs, ent->s.origin, ent, mask);

	return trace.startsolid;
}


/*
================
SV_CheckVelocity
================
*/
static void(entity ent) SV_CheckVelocity =
{
//
// bound velocity
//
	if (ent->velocity_x > sv_maxvelocity->floatVal)
		ent->velocity_x = sv_maxvelocity->floatVal;
	else if (ent->velocity_x < -sv_maxvelocity->floatVal)
		ent->velocity_x = -sv_maxvelocity->floatVal;
		
	if (ent->velocity_y > sv_maxvelocity->floatVal)
		ent->velocity_y = sv_maxvelocity->floatVal;
	else if (ent->velocity_y < -sv_maxvelocity->floatVal)
		ent->velocity_y = -sv_maxvelocity->floatVal;
		
	if (ent->velocity_z > sv_maxvelocity->floatVal)
		ent->velocity_z = sv_maxvelocity->floatVal;
	else if (ent->velocity_z < -sv_maxvelocity->floatVal)
		ent->velocity_z = -sv_maxvelocity->floatVal;
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
		gi.dprintf("NULL ent->think: %s @ %s", ent.classname, vtos(ent.s.origin));
	else
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
	int	blocked;

	blocked = 0;
	if (normal_z > 0)
		blocked |= 1;       // floor
	if (!normal_z)
		blocked |= 2;       // step

	backoff = (in * normal) * overbounce;

	change = normal_x * backoff;
	out_x = in_x - change;
	if (out_x > -STOP_EPSILON && out_x < STOP_EPSILON)
		out_x = 0;
		
	change = normal_y * backoff;
	out_y = in_y - change;
	if (out_y > -STOP_EPSILON && out_y < STOP_EPSILON)
		out_y = 0;
		
	change = normal_z * backoff;
	out_z = in[2] - change;
	if (out_z > -STOP_EPSILON && out_z < STOP_EPSILON)
		out_z = 0;

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
	vector	dir = vec3_origin;
	float	d;
	int	numplanes;
	vector	planes[MAX_CLIP_PLANES];
	vector	primal_velocity, original_velocity, new_velocity = vec3_origin;
	int	i, j;
	trace_t	trace;
	vector	end;
	float	time_left;
	int	blocked;

	numbumps = 4;

	blocked = 0;
	original_velocity = ent->velocity;
	primal_velocity = ent->velocity;
	numplanes = 0;

	time_left = time;

	ent->groundentity = null_entity;
	for (bumpcount = 0 ; bumpcount < numbumps ; bumpcount++) {
		end = ent.s.origin + time_left * ent->velocity;

		gi.trace(&trace, ent->s.origin, ent->mins, ent->maxs, end, ent, mask);

		if (trace.allsolid) {
			// entity is trapped in another solid
			ent->velocity = vec3_origin;
			return 3;
		}

		if (trace.fraction > 0) {
			// actually covered some distance
			ent->s.origin = trace.endpos;
			original_velocity = ent->velocity;
			numplanes = 0;
		}

		if (trace.fraction == 1)
			break;     // moved the entire distance

		hit = trace.ent;

		if (trace.plane.normal[2] > 0.7f) {
			blocked |= 1;       // floor
			if (hit->solid == SOLID_BSP) {
				ent->groundentity = hit;
				ent->groundentity_linkcount = hit->linkcount;
			}
		}
		if (!trace.plane.normal[2]) {
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
			ent->velocity = vec3_origin;
			return 3;
		}

		planes[numplanes] = trace.plane.normal;
		numplanes++;

//
// modify original_velocity so it parallels all of the clip planes
//
		for (i = 0 ; i < numplanes ; i++) {
			ClipVelocity(original_velocity, planes[i], new_velocity, 1);

			for (j = 0 ; j < numplanes ; j++)
				if (j != i && planes[i] != planes[j]) {
					if (new_velocity * planes[j] < 0)
						break;  // not ok
				}
			if (j == numplanes)
				break;
		}

		if (i != numplanes) {
			// go along this plane
			ent->velocity = new_velocity;
		} else {
			// go along the crease
			if (numplanes != 2) {
//              gi.dprintf ("clip velocity, numplanes == %i\n",numplanes);
				ent->velocity = vec3_origin;
				return 7;
			}
			dir = CrossProduct(planes[0], planes[1]);
			d = dir * ent->velocity;
			ent->velocity = dir * d;
		}

//
// if original velocity is against the original velocity, stop dead
// to avoid tiny occilations in sloping corners
//
		if (ent->velocity * primal_velocity <= 0) {
			ent->velocity = vec3_origin;
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
	ent->velocity_z -= ent->gravity * sv_gravity->floatVal * FRAMETIME;
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

	start = ent->s.origin;
	end = start + push;

retry:
	if (ent->clipmask)
		mask = ent->clipmask;
	else
		mask = MASK_SOLID;

	gi.trace(&trace, start, ent->mins, ent->maxs, end, ent, mask);

	ent->s.origin = trace.endpos;
	gi.linkentity(ent);

	if (trace.fraction != 1.0f)
	{
		SV_Impact(ent, trace);

		// if the pushed entity went away and the pusher is still there
		if (!trace.ent->inuse && ent->inuse) {
			// move the pusher back and try again
			ent->s.origin = start;
			gi.linkentity(ent);
			goto retry;
		}
	}

	if (ent->inuse)
		G_TouchTriggers(ent);
}

static entity	pushed_head;
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
	int		e;
	entity		check;
	bool		block;
	vector		mins, maxs;
	vector		org, org2, move2, forward, right, up;

	// clamp the move to 1/8 units, so the position will
	// be accurate for client side prediction
	float temp = move_x * 8.0f;
	if (temp > 0.0f)
		temp += 0.5f;
	else
		temp -= 0.5f;
	move_x = 0.125f * (int)temp;
	temp = move_y * 8.0f;
	if (temp > 0.0f)
		temp += 0.5f;
	else
		temp -= 0.5f;
	move_y = 0.125f * (int)temp;
	temp = move_z * 8.0f;
	if (temp > 0.0f)
		temp += 0.5f;
	else
		temp -= 0.5f;
	move_z = 0.125f * (int)temp;
	
	// find the bounding box
	mins = pusher.absmin + move;
	maxs = pusher.absmax + move;

// we need this for pushing things later
	org = -amove;
	AngleVectors(org, &forward, &right, &up);

// save the pusher's original position
	pusher.pushed.next = world;
	pusher.pushed.prev = pushed_head;

	if (pushed_head)
		pushed_head.pushed.next = pusher;

	pusher.pushed.origin = pusher->s.origin;
	pusher.pushed.angles = pusher->s.angles;
#if USE_SMOOTH_DELTA_ANGLES
	if (pusher->client)
		pusher.pushed.deltayaw = pusher->client->ps.pmove.delta_angles[YAW];
#endif

	pushed_head = pusher;

// move the pusher to it's final position
	pusher->s.origin += move;
	pusher->s.angles += amove;
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
			if (check->absmin_x >= maxs_x
				|| check->absmin_y >= maxs_y
				|| check->absmin_z >= maxs_z
				|| check->absmax_x <= mins_x
				|| check->absmax_y <= mins_y
				|| check->absmax_z <= mins_z)
				continue;

			// see if the ent's bbox is inside the pusher's final position
			if (!SV_TestEntityPosition(check))
				continue;
		}


		if ((pusher->movetype == MOVETYPE_PUSH) || (check->groundentity == pusher)) {
			// move this entity
			check.pushed.origin = check->s.origin;
			check.pushed.angles = check->s.angles;
#if USE_SMOOTH_DELTA_ANGLES
			if (check->client)
				check.pushed.deltayaw = check->client->ps.pmove.delta_angles[YAW];
#endif
			check.pushed.next = world;
			check.pushed.prev = pushed_head;
			
			if (pushed_head)
				pushed_head.pushed.next = check;
			
			pushed_head = check;

			// try moving the contacted entity
			check->s.origin += move;
#if USE_SMOOTH_DELTA_ANGLES
			if (check->client) {
				// FIXME: doesn't rotate monsters?
				// FIXME: skuller: needs client side interpolation
				check->client->ps.pmove.delta_angles[YAW] += ANGLE2SHORT(amove[YAW]);
			}
#endif

			// figure movement due to the pusher's amove
			org = check->s.origin - pusher->s.origin;
			org2_x = org * forward;
			org2_y = -(org * right);
			org2_z = org * up;
			move2 = org2 - org;
			check->s.origin += move2;

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
			check->s.origin = check->s.origin - move;
			block = SV_TestEntityPosition(check);
			if (!block) {
				pushed_head = pushed_head.pushed.prev;
				
				if (pushed_head)
					pushed_head.pushed.next = world;
				continue;
			}
		}

		// save off the obstacle so we can call the block function
		obstacle = check;

		// move back any entities we already moved
		// go backwards, so if the same entity was pushed
		// twice, it goes back to the original position
		for (entity p = pushed_head; p; p = p.pushed.prev) {
			p->s.origin = p.pushed.origin;
			p->s.angles = p.pushed.angles;
#if USE_SMOOTH_DELTA_ANGLES
			if (p->client) {
				p->client->ps.pmove.delta_angles[YAW] = p.pushed->deltayaw;
			}
#endif
			gi.linkentity(p);
		}
		return false;
	}

//FIXME: is there a better way to handle this?
	// see if anything we moved has touched a trigger
	for (entity p = pushed_head; p; p = p.pushed.prev)
		G_TouchTriggers(p);

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
	pushed_head = world;
	for (part = ent ; part ; part = part->teamchain) {
		if (part->velocity || part->avelocity) {
			// object is moving
			move = part->velocity * FRAMETIME;
			amove = part->avelocity * FRAMETIME;

			if (!SV_Push(part, move, amove))
				break;  // move was blocked
		}
	}

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

	ent->s.angles += (FRAMETIME * ent->avelocity);
	ent->s.origin += (FRAMETIME * ent->velocity);

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

	if (ent->velocity_z > 0)
		ent->groundentity = null_entity;

// check for the groundentity going away
	if (ent->groundentity != null_entity)
		if (!ent->groundentity->inuse)
			ent->groundentity = null_entity;

// if onground, return without moving
	if (ent->groundentity != null_entity)
		return;

	old_origin = ent->s.origin;

	SV_CheckVelocity(ent);

// add gravity
	if (ent->movetype != MOVETYPE_FLY
		&& ent->movetype != MOVETYPE_FLYMISSILE)
		SV_AddGravity(ent);

// move angles
	ent->s.angles += (FRAMETIME * ent->avelocity);

// move origin
	move = ent->velocity * FRAMETIME;
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
		if (trace.plane.normal[2] > 0.7f) {
			if (ent->velocity_z < 60f || ent->movetype != MOVETYPE_BOUNCE) {
				ent->groundentity = trace.ent;
				ent->groundentity_linkcount = trace.ent->linkcount;
				ent->velocity = vec3_origin;
				ent->avelocity = vec3_origin;
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
		slave->s.origin = ent->s.origin;
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
	float	adjustment;

	ent->s.angles += (FRAMETIME * ent->avelocity);
	adjustment = FRAMETIME * sv_stopspeed * sv_friction;

	if (ent->avelocity_x > 0) {
		ent->avelocity_x -= adjustment;
		if (ent->avelocity_x < 0)
			ent->avelocity_x = 0;
	} else {
		ent->avelocity_x += adjustment;
		if (ent->avelocity_x > 0)
			ent->avelocity_x = 0;
	}
	
	if (ent->avelocity_y > 0) {
		ent->avelocity_y -= adjustment;
		if (ent->avelocity_y < 0)
			ent->avelocity_y = 0;
	} else {
		ent->avelocity_y += adjustment;
		if (ent->avelocity_y > 0)
			ent->avelocity_y = 0;
	}
	
	if (ent->avelocity_z > 0) {
		ent->avelocity_z -= adjustment;
		if (ent->avelocity_z < 0)
			ent->avelocity_z = 0;
	} else {
		ent->avelocity_z += adjustment;
		if (ent->avelocity_z > 0)
			ent->avelocity_z = 0;
	}
}

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

	if (ent->avelocity)
		SV_AddRotationalFriction(ent);

	// add gravity except:
	//   flying monsters
	//   swimming monsters who are in the water
	if (! wasonground)
		if (!(ent->flags & FL_FLY))
			if (!((ent->flags & FL_SWIM) && (ent->waterlevel > 2))) {
				if (ent->velocity_z < sv_gravity->floatVal * -0.1f)
					hitsound = true;
				if (ent->waterlevel == 0)
					SV_AddGravity(ent);
			}

	// friction for flying monsters that have been given vertical velocity
	if ((ent->flags & FL_FLY) && (ent->velocity_z != 0)) {
		speed = fabsf(ent->velocity_z);
		control = speed < sv_stopspeed ? sv_stopspeed : speed;
		friction = sv_friction / 3;
		newspeed = speed - (FRAMETIME * control * friction);
		if (newspeed < 0)
			newspeed = 0;
		newspeed /= speed;
		ent->velocity_z *= newspeed;
	}

	// friction for flying monsters that have been given vertical velocity
	if ((ent->flags & FL_SWIM) && (ent->velocity_z != 0)) {
		speed = fabsf(ent->velocity_z);
		control = speed < sv_stopspeed ? sv_stopspeed : speed;
		newspeed = speed - (FRAMETIME * control * sv_waterfriction * ent->waterlevel);
		if (newspeed < 0)
			newspeed = 0;
		newspeed /= speed;
		ent->velocity_z *= newspeed;
	}

	if (ent.velocity) {
		// apply friction
		// let dead monsters who aren't completely onground slide
		if ((wasonground) || (ent->flags & (FL_SWIM | FL_FLY)))
			if (!(ent->health <= 0 && !M_CheckBottom(ent))) {
				speed = sqrtf(ent.velocity_x * ent.velocity_x + ent.velocity_y * ent.velocity_y);
				if (speed) {
					friction = sv_friction;

					control = speed < sv_stopspeed ? sv_stopspeed : speed;
					newspeed = speed - FRAMETIME * control * friction;

					if (newspeed < 0)
						newspeed = 0;
					newspeed /= speed;

					ent.velocity_x *= newspeed;
					ent.velocity_y *= newspeed;
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

		if (ent->groundentity != null_entity)
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
