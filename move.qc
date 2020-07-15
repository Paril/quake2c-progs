const int STEPSIZE	= 18;

/*
=============
M_CheckBottom

Returns false if any part of the bottom of the entity is off an edge that
is not a staircase.

=============
*/
static int c_yes, c_no;

bool(entity ent) M_CheckBottom =
{
	vector	cmins, cmaxs, start, stop;
	trace_t	trace;
	int	x, y;
	float	mid, bottom;

	VectorAdd(ent->s.origin, ent->mins, cmins);
	VectorAdd(ent->s.origin, ent->maxs, cmaxs);

// if all of the points under the corners are solid world, don't bother
// with the tougher checks
// the corners must be within 16 of the midpoint
	start_z = cmins_z - 1;
	for (x = 0 ; x <= 1 ; x++)
		for (y = 0 ; y <= 1 ; y++) {
			start_x = x ? cmaxs_x : cmins_x;
			start_y = y ? cmaxs_y : cmins_y;
			if (gi.pointcontents(start) != CONTENTS_SOLID)
				goto realcheck;
		}

	c_yes++;
	return true;        // we got out easy

realcheck:
	c_no++;
//
// check it for real...
//
	start_z = cmins_z;

// the midpoint must be within 16 of the bottom
	start_x = stop_x = (cmins_x + cmaxs_x) * 0.5f;
	start_y = stop_y = (cmins_y + cmaxs_y) * 0.5f;
	stop_z = start_z - 2 * STEPSIZE;
	trace_and_result(trace, start, vec3_origin, vec3_origin, stop, ent, MASK_MONSTERSOLID);

	if (trace.fraction == 1.0f)
		return false;
	mid = bottom = trace.endpos[(ARRAY_INDEX_TYPE)2];

// the corners must be within 16 of the midpoint
	for (x = 0 ; x <= 1 ; x++)
		for (y = 0 ; y <= 1 ; y++) {
			start_x = stop_x = x ? cmaxs_x : cmins_x;
			start_y = stop_y = y ? cmaxs_y : cmins_y;

			trace_and_result(trace, start, vec3_origin, vec3_origin, stop, ent, MASK_MONSTERSOLID);

			if (trace.fraction != 1.0f && trace.endpos[(ARRAY_INDEX_TYPE)2] > bottom)
				bottom = trace.endpos[(ARRAY_INDEX_TYPE)2];
			if (trace.fraction == 1.0f || mid - trace.endpos[(ARRAY_INDEX_TYPE)2] > STEPSIZE)
				return false;
		}

	c_yes++;
	return true;
}


/*
=============
SV_movestep

Called by monster program code.
The move will be adjusted for slopes and stairs, but if the move isn't
possible, no move is done, false is returned, and
pr_global_struct->trace_normal is set to the normal of the blocking wall
=============
*/
//FIXME since we need to test end position contents here, can we avoid doing
//it again later in catagorize position?
bool(entity ent, vector move, bool relink) SV_movestep =
{
	float	dz;
	vector	oldorg, neworg, end;
	trace_t	trace;
	int	i;
	float	stepsize;
	vector	test;
	int	contents;

// try the move
	VectorCopy(ent->s.origin, oldorg);
	VectorAdd(ent->s.origin, move, neworg);

// flying monsters don't step up
	if (ent->flags & (FL_SWIM | FL_FLY)) {
		// try one move with vertical motion, then one without
		for (i = 0 ; i < 2 ; i++) {
			VectorAdd(ent->s.origin, move, neworg);
			if (i == 0 && ent->enemy) {
				if (!ent->goalentity)
					ent->goalentity = ent->enemy;
				dz = ent->s.origin[(ARRAY_INDEX_TYPE)2] - ent->goalentity->s.origin[(ARRAY_INDEX_TYPE)2];
				if (ent->goalentity->is_client) {
					if (dz > 40)
						neworg_z -= 8;
					if (!((ent->flags & FL_SWIM) && (ent->waterlevel < 2)))
						if (dz < 30)
							neworg_z += 8;
				} else {
					if (dz > 8)
						neworg_z -= 8;
					else if (dz > 0)
						neworg_z -= dz;
					else if (dz < -8)
						neworg_z += 8;
					else
						neworg_z += dz;
				}
			}
			trace_and_result(trace, ent->s.origin, ent->mins, ent->maxs, neworg, ent, MASK_MONSTERSOLID);

			// fly monsters don't enter water voluntarily
			if (ent->flags & FL_FLY) {
				if (!ent->waterlevel) {
					test_x = trace.endpos[(ARRAY_INDEX_TYPE)0];
					test_y = trace.endpos[(ARRAY_INDEX_TYPE)1];
					test_z = trace.endpos[(ARRAY_INDEX_TYPE)2] + ent->mins_z + 1;
					contents = gi.pointcontents(test);
					if (contents & MASK_WATER)
						return false;
				}
			}

			// swim monsters don't exit water voluntarily
			if (ent->flags & FL_SWIM) {
				if (ent->waterlevel < 2) {
					test_x = trace.endpos[(ARRAY_INDEX_TYPE)0];
					test_y = trace.endpos[(ARRAY_INDEX_TYPE)1];
					test_z = trace.endpos[(ARRAY_INDEX_TYPE)2] + ent->mins_z + 1;
					contents = gi.pointcontents(test);
					if (!(contents & MASK_WATER))
						return false;
				}
			}

			if (trace.fraction == 1) {
				VectorCopy(trace.endpos, ent->s.origin);
				if (relink) {
					gi.linkentity(ent);
					G_TouchTriggers(ent);
				}
				return true;
			}

			if (!ent->enemy)
				break;
		}

		return false;
	}

// push down from a step height above the wished position
	if (!(ent->monsterinfo.aiflags & AI_NOSTEP))
		stepsize = (float)STEPSIZE;
	else
		stepsize = 1f;

	neworg_z += stepsize;
	VectorCopy(neworg, end);
	end_z -= stepsize * 2;

	trace_and_result(trace, neworg, ent->mins, ent->maxs, end, ent, MASK_MONSTERSOLID);

	if (trace.allsolid)
		return false;

	if (trace.startsolid) {
		neworg_z -= stepsize;
		trace_and_result(trace, neworg, ent->mins, ent->maxs, end, ent, MASK_MONSTERSOLID);
		if (trace.allsolid || trace.startsolid)
			return false;
	}


	// don't go in to water
	if (ent->waterlevel == 0) {
		test_x = trace.endpos[(ARRAY_INDEX_TYPE)0];
		test_y = trace.endpos[(ARRAY_INDEX_TYPE)1];
		test_z = trace.endpos[(ARRAY_INDEX_TYPE)2] + ent->mins_z + 1;
		contents = gi.pointcontents(test);

		if (contents & MASK_WATER)
			return false;
	}

	if (trace.fraction == 1) {
		// if monster had the ground pulled out, go ahead and fall
		if (ent->flags & FL_PARTIALGROUND) {
			VectorAdd(ent->s.origin, move, ent->s.origin);
			if (relink) {
				gi.linkentity(ent);
				G_TouchTriggers(ent);
			}
			ent->groundentity = null_entity;
			return true;
		}

		return false;       // walked off an edge
	}

// check point traces down for dangling corners
	VectorCopy(trace.endpos, ent->s.origin);

	if (!M_CheckBottom(ent)) {
		if (ent->flags & FL_PARTIALGROUND) {
			// entity had floor mostly pulled out from underneath it
			// and is trying to correct
			if (relink) {
				gi.linkentity(ent);
				G_TouchTriggers(ent);
			}
			return true;
		}
		VectorCopy(oldorg, ent->s.origin);
		return false;
	}

	if (ent->flags & FL_PARTIALGROUND) {
		ent->flags &= ~FL_PARTIALGROUND;
	}
	ent->groundentity = trace.ent;
	ent->groundentity_linkcount = trace.ent->linkcount;

// the move is ok
	if (relink) {
		gi.linkentity(ent);
		G_TouchTriggers(ent);
	}
	return true;
}


//============================================================================

/*
===============
M_ChangeYaw

===============
*/
void(entity ent) M_ChangeYaw =
{
	float	ideal;
	float	current;
	float	move;
	float	speed;

	current = anglemod(ent->s.angles[YAW]);
	ideal = ent->ideal_yaw;

	if (current == ideal)
		return;

	move = ideal - current;
	speed = ent->yaw_speed;
	if (ideal > current) {
		if (move >= 180)
			move = move - 360;
	} else {
		if (move <= -180)
			move = move + 360;
	}
	if (move > 0) {
		if (move > speed)
			move = speed;
	} else {
		if (move < -speed)
			move = -speed;
	}

	ent->s.angles[YAW] = anglemod(current + move);
}


/*
======================
SV_StepDirection

Turns to the movement direction, and walks the current distance if
facing it.

======================
*/
static bool(entity ent, float yaw, float dist) SV_StepDirection =
{
	vector	move, oldorigin;
	float	delta;

	ent->ideal_yaw = yaw;
	M_ChangeYaw(ent);

	yaw = DEG2RAD(yaw);
	move_x = cosf(yaw) * dist;
	move_y = sinf(yaw) * dist;
	move_z = 0;

	VectorCopy(ent->s.origin, oldorigin);
	if (SV_movestep(ent, move, false)) {
		delta = ent->s.angles[YAW] - ent->ideal_yaw;
		if (delta > 45 && delta < 315) {
			// not turned far enough, so don't take the step
			VectorCopy(oldorigin, ent->s.origin);
		}
		gi.linkentity(ent);
		G_TouchTriggers(ent);
		return true;
	}
	gi.linkentity(ent);
	G_TouchTriggers(ent);
	return false;
}

/*
======================
SV_FixCheckBottom

======================
*/
static void(entity ent) SV_FixCheckBottom =
{
	ent->flags |= FL_PARTIALGROUND;
}



/*
================
SV_NewChaseDir

================
*/
const float DI_NODIR	= -1;
void(entity actor, entity enemy, float dist) SV_NewChaseDir =
{
	float   deltax, deltay;
	vector	d;
	float   tdir, olddir, turnaround;

	//FIXME: how did we get here with no enemy
	if (!enemy)
		return;

	olddir = anglemod((int)(actor->ideal_yaw / 45) * 45);
	turnaround = anglemod(olddir - 180);

	deltax = enemy->s.origin[(ARRAY_INDEX_TYPE)0] - actor->s.origin[(ARRAY_INDEX_TYPE)0];
	deltay = enemy->s.origin[(ARRAY_INDEX_TYPE)1] - actor->s.origin[(ARRAY_INDEX_TYPE)1];
	if (deltax > 10)
		d_y = 0;
	else if (deltax < -10)
		d_y = 180f;
	else
		d_y = DI_NODIR;
	if (deltay < -10)
		d_z = 270f;
	else if (deltay > 10)
		d_z = 90f;
	else
		d_z = DI_NODIR;

// try direct route
	if (d[(ARRAY_INDEX_TYPE)1] != DI_NODIR && d[(ARRAY_INDEX_TYPE)2] != DI_NODIR) {
		if (d_y == 0)
			tdir = d_z == 90f ? 45f : 315f;
		else
			tdir = d_z == 90f ? 135f : 215f;

		if (tdir != turnaround && SV_StepDirection(actor, tdir, dist))
			return;
	}

// try other directions
	if (((Q_rand() & 3) & 1) || fabsf(deltay) > fabsf(deltax)) {
		tdir = d_y;
		d_y = d_z;
		d_z = tdir;
	}

	if (d_y != DI_NODIR && d_y != turnaround
		&& SV_StepDirection(actor, d_y, dist))
		return;

	if (d_z != DI_NODIR && d_z != turnaround
		&& SV_StepDirection(actor, d_z, dist))
		return;

	/* there is no direct path to the player, so pick another direction */

	if (olddir != DI_NODIR && SV_StepDirection(actor, olddir, dist))
		return;

	if (Q_rand() & 1) { /*randomly determine direction of search*/
		for (tdir = 0 ; tdir <= 315f ; tdir += 45f)
			if (tdir != turnaround && SV_StepDirection(actor, tdir, dist))
				return;
	} else {
		for (tdir = 315f ; tdir >= 0 ; tdir -= 45f)
			if (tdir != turnaround && SV_StepDirection(actor, tdir, dist))
				return;
	}

	if (turnaround != DI_NODIR && SV_StepDirection(actor, turnaround, dist))
		return;

	actor->ideal_yaw = olddir;      // can't move

// if a bridge was pulled out from underneath a monster, it may not have
// a valid standing position at all

	if (!M_CheckBottom(actor))
		SV_FixCheckBottom(actor);
}

/*
======================
SV_CloseEnough

======================
*/
static bool(entity ent, entity goal, float dist) SV_CloseEnough =
{
	/*int     i;

	for (i = 0 ; i < 3 ; i++) {
		if (goal->absmin[i] > ent->absmax[i] + dist)
			return false;
		if (goal->absmax[i] < ent->absmin[i] - dist)
			return false;
	}*/
	if (goal->absmin_x > ent->absmax_x + dist)
		return false;
	if (goal->absmax_x < ent->absmin_x - dist)
		return false;
	if (goal->absmin_y > ent->absmax_y + dist)
		return false;
	if (goal->absmax_y < ent->absmin_y - dist)
		return false;
	if (goal->absmin_z > ent->absmax_z + dist)
		return false;
	if (goal->absmax_z < ent->absmin_z - dist)
		return false;
	return true;
}


/*
======================
M_MoveToGoal
======================
*/
void(entity ent, float dist) M_MoveToGoal =
{
	entity	goal;

	goal = ent->goalentity;

	if (ent->groundentity == null_entity && !(ent->flags & (FL_FLY | FL_SWIM)))
		return;

// if the next step hits the enemy, return immediately
	if (ent->enemy && SV_CloseEnough(ent, ent->enemy, dist))
		return;

// bump around...
	if ((Q_rand() & 3) == 1 || !SV_StepDirection(ent, ent->ideal_yaw, dist)) {
		if (ent->inuse)
			SV_NewChaseDir(ent, goal, dist);
	}
}


/*
===============
M_walkmove
===============
*/
bool(entity ent, float yaw, float dist) M_walkmove =
{
	vector	move;

	if (ent->groundentity == null_entity && !(ent->flags & (FL_FLY | FL_SWIM)))
		return false;

	yaw = DEG2RAD(yaw);
	move_x = cosf(yaw) * dist;
	move_y = sinf(yaw) * dist;
	move_z = 0;

	return SV_movestep(ent, move, true);
}
