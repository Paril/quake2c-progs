const int STEPSIZE	= 18;

#ifdef GROUND_ZERO
entity	new_bad;
#endif

/*
=============
M_CheckBottom

Returns false if any part of the bottom of the entity is off an edge that
is not a staircase.

=============
*/
bool(entity ent) M_CheckBottom =
{
	vector	cmins, cmaxs, start, stop;
	trace_t	trace;
	int	x, y;
	float	mid, bottom;

	cmins = ent.s.origin + ent.mins;
	cmaxs = ent.s.origin + ent.maxs;

// if all of the points under the corners are solid world, don't bother
// with the tougher checks
// the corners must be within 16 of the midpoint
#ifdef GROUND_ZERO
	if(ent.gravityVector[2] > 0)
		start[2] = cmaxs[2] + 1;
	else
#endif
		start[2] = cmins[2] - 1;

	for (x = 0 ; x <= 1 ; x++)
		for (y = 0 ; y <= 1 ; y++) {
			start.x = x ? cmaxs.x : cmins.x;
			start.y = y ? cmaxs.y : cmins.y;
			if (gi.pointcontents(start) != CONTENTS_SOLID)
				goto realcheck;
		}

	return true;        // we got out easy

realcheck:
//
// check it for real...
//

// the midpoint must be within 16 of the bottom
	start.x = stop.x = (cmins.x + cmaxs.x) * 0.5f;
	start.y = stop.y = (cmins.y + cmaxs.y) * 0.5f;

#ifdef GROUND_ZERO
	if (ent.gravityVector[2] > 0)
	{
		start.z = cmaxs.z;
		stop.z = start.z + 2 * STEPSIZE;
	}
	else
	{
#endif
		start.z = cmins.z;
		stop.z = start.z - 2 * STEPSIZE;
#ifdef GROUND_ZERO
	}
#endif
	gi.trace(&trace, start, vec3_origin, vec3_origin, stop, ent, MASK_MONSTERSOLID);

	if (trace.fraction == 1.0f)
		return false;
	mid = bottom = trace.endpos[2];

// the corners must be within 16 of the midpoint
	for (x = 0 ; x <= 1 ; x++)
		for (y = 0 ; y <= 1 ; y++) {
			start.x = stop.x = x ? cmaxs.x : cmins.x;
			start.y = stop.y = y ? cmaxs.y : cmins.y;

			gi.trace(&trace, start, vec3_origin, vec3_origin, stop, ent, MASK_MONSTERSOLID);

#ifdef GROUND_ZERO
			if (ent.gravityVector[2] > 0)
			{
				if (trace.fraction != 1.0 && trace.endpos[2] < bottom)
					bottom = trace.endpos[2];
				if (trace.fraction == 1.0 || trace.endpos[2] - mid > STEPSIZE)
					return false;
			}
			else
			{
#endif
				if (trace.fraction != 1.0f && trace.endpos[2] > bottom)
					bottom = trace.endpos[2];
				if (trace.fraction == 1.0f || mid - trace.endpos[2] > STEPSIZE)
					return false;

#ifdef GROUND_ZERO
			}
#endif
		}

	return true;
}


/*
=============
SV_movestep

Called by monster program code.
The move will be adjusted for slopes and stairs, but if the move isn't
possible, no move is done, false is returned, and
pr_global_struct.trace_normal is set to the normal of the blocking wall
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
#ifdef GROUND_ZERO
	entity	current_bad = 0;
	float	minheight;

	// PMM - who cares about bad areas if you're dead?
	if (ent.health > 0)
	{
		current_bad = CheckForBadArea(ent);
		if(current_bad)
		{
			ent.bad_area = current_bad;
			 
			if(ent.enemy && ent.enemy.classname == "tesla")
			{
				// if the tesla is in front of us, back up...
				if (IsBadAhead (ent, current_bad, move))
					move = -move;
			}
		}
		else if(ent.bad_area)
		{
			// if we're no longer in a bad area, get back to business.
			ent.bad_area = 0;
			if(ent.oldenemy)
			{
				ent.enemy = ent.oldenemy;
				ent.goalentity = ent.oldenemy;
				FoundTarget(ent);

				return true;
			}
		}
	}
#endif

// try the move
	oldorg = ent.s.origin;
	neworg = ent.s.origin + move;

// flying monsters don't step up
	if (ent.flags & (FL_SWIM | FL_FLY)) {
		// try one move with vertical motion, then one without
		for (i = 0 ; i < 2 ; i++) {
			neworg = ent.s.origin + move;
			if (i == 0 && ent.enemy) {
				if (!ent.goalentity)
					ent.goalentity = ent.enemy;
				dz = ent.s.origin[2] - ent.goalentity.s.origin[2];
				if (ent.goalentity.is_client)
				{
#ifdef GROUND_ZERO
					// we want the carrier to stay a certain distance off the ground, to help prevent him
					// from shooting his fliers, who spawn in below him
					if (ent.classname == "monster_carrier")
						minheight = 104f;
					else
						minheight = 40f;
					if (dz > minheight)
#else
					if (dz > 40)
#endif
						neworg.z -= 8;
					if (!((ent.flags & FL_SWIM) && ent.waterlevel < 2))
#ifdef GROUND_ZERO
						if (dz < (minheight - 10))
#else
						if (dz < 30)
#endif
							neworg.z += 8;
				} else {
#ifdef THE_RECKONING
					// RAFAEL
					if (ent.classname == "monster_fixbot")
					{
						if (ent.s.frame >= 105 && ent.s.frame <= 120)
						{
							if (dz > 12)
								neworg.z--;
							else if (dz < -12)
								neworg.z++;
						}
						else if (ent.s.frame >= 31 && ent.s.frame <= 88)
						{
							if (dz > 12)
								neworg.z -= 12;
							else if (dz < -12)
								neworg.z += 12;
						}
						else
						{
							if (dz > 12)
								neworg.z -= 8;
							else if (dz < -12)
								neworg.z += 8;
						}
					}
					// RAFAEL ( else )
					else
					{
#endif
						if (dz > 8)
							neworg.z -= 8;
						else if (dz > 0)
							neworg.z -= dz;
						else if (dz < -8)
							neworg.z += 8;
						else
							neworg.z += dz;
#ifdef THE_RECKONING
					}
#endif
				}
			}
			gi.trace(&trace, ent.s.origin, ent.mins, ent.maxs, neworg, ent, MASK_MONSTERSOLID);

			// fly monsters don't enter water voluntarily
			if (ent.flags & FL_FLY) {
				if (!ent.waterlevel) {
					test.x = trace.endpos[0];
					test.y = trace.endpos[1];
					test.z = trace.endpos[2] + ent.mins.z + 1;
					contents = gi.pointcontents(test);
					if (contents & MASK_WATER)
						return false;
				}
			}

			// swim monsters don't exit water voluntarily
			if (ent.flags & FL_SWIM) {
				if (ent.waterlevel < 2) {
					test.x = trace.endpos[0];
					test.y = trace.endpos[1];
					test.z = trace.endpos[2] + ent.mins.z + 1;
					contents = gi.pointcontents(test);
					if (!(contents & MASK_WATER))
						return false;
				}
			}

			if (trace.fraction == 1 && !trace.allsolid && !trace.startsolid)
			{
				ent.s.origin = trace.endpos;
				
#ifdef GROUND_ZERO
				if (!current_bad && CheckForBadArea(ent))
					ent.s.origin = oldorg;
				else
				{
#endif
					if (relink)
					{
						gi.linkentity(ent);
						G_TouchTriggers(ent);
					}
					return true;
#ifdef GROUND_ZERO
				}
#endif
			}

			if (!ent.enemy)
				break;
		}

		return false;
	}

// push down from a step height above the wished position
	if (!(ent.monsterinfo.aiflags & AI_NOSTEP))
		stepsize = (float)STEPSIZE;
	else
		stepsize = 1f;

#ifdef GROUND_ZERO
	// trace from 1 stepsize gravityUp to 2 stepsize gravityDown.
	neworg += ent.gravityVector * (-1 * stepsize);
	end = neworg + (ent.gravityVector * (2 * stepsize));
#else
	neworg.z += stepsize;
	end = neworg;
	end.z -= stepsize * 2;
#endif

	gi.trace(&trace, neworg, ent.mins, ent.maxs, end, ent, MASK_MONSTERSOLID);

	if (trace.allsolid)
		return false;

	if (trace.startsolid)
	{
		neworg.z -= stepsize;
		gi.trace(&trace, neworg, ent.mins, ent.maxs, end, ent, MASK_MONSTERSOLID);
		if (trace.allsolid || trace.startsolid)
			return false;
	}


	// don't go in to water
	if (ent.waterlevel == 0)
	{
		test.x = trace.endpos[0];
		test.y = trace.endpos[1];
#ifdef GROUND_ZERO
		if(ent.gravityVector[2] > 0)
			test[2] = trace.endpos[2] + ent.maxs[2] - 1;	
		else
#endif
			test.z = trace.endpos[2] + ent.mins.z + 1;
		contents = gi.pointcontents(test);

		if (contents & MASK_WATER)
			return false;
	}

	if (trace.fraction == 1) {
		// if monster had the ground pulled out, go ahead and fall
		if (ent.flags & FL_PARTIALGROUND) {
			ent.s.origin += move;
			if (relink) {
				gi.linkentity(ent);
				G_TouchTriggers(ent);
			}
			ent.groundentity = null_entity;
			return true;
		}

		return false;       // walked off an edge
	}

// check point traces down for dangling corners
	ent.s.origin = trace.endpos;
	
#ifdef GROUND_ZERO
	// PMM - don't bother with bad areas if we're dead
	if (ent.health > 0)
	{
		// use AI_BLOCKED to tell the calling layer that we're now mad at a tesla
		new_bad = CheckForBadArea(ent);
		if(!current_bad && new_bad)
		{
			if (new_bad.owner)
			{
				if (new_bad.owner.classname == "tesla")
				{
					if (!ent.enemy || !ent.enemy.inuse)
					{
						TargetTesla (ent, new_bad.owner);
						ent.monsterinfo.aiflags |= AI_BLOCKED;
					}
					else if (ent.enemy.classname != "tesla")
					{
						if (ent.enemy && ent.enemy.is_client)
						{
							if (!visible(ent, ent.enemy))
							{
								TargetTesla (ent, new_bad.owner);
								ent.monsterinfo.aiflags |= AI_BLOCKED;
							}
						}
						else
						{
							TargetTesla (ent, new_bad.owner);
							ent.monsterinfo.aiflags |= AI_BLOCKED;
						}
					}
				}
			}

			ent.s.origin = oldorg;
			return false;
		}
	}
#endif

	if (!M_CheckBottom(ent)) {
		if (ent.flags & FL_PARTIALGROUND) {
			// entity had floor mostly pulled out from underneath it
			// and is trying to correct
			if (relink) {
				gi.linkentity(ent);
				G_TouchTriggers(ent);
			}
			return true;
		}
		ent.s.origin = oldorg;
		return false;
	}

	if (ent.flags & FL_PARTIALGROUND) {
		ent.flags &= ~FL_PARTIALGROUND;
	}
	ent.groundentity = trace.ent;
	ent.groundentity_linkcount = trace.ent.linkcount;

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

	current = anglemod(ent.s.angles[YAW]);
	ideal = ent.ideal_yaw;

	if (current == ideal)
		return;

	move = ideal - current;
	speed = ent.yaw_speed;
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

	ent.s.angles[YAW] = anglemod(current + move);
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
	if(!ent.inuse)
		return true;
	
	vector	move, oldorigin;
	float	delta;

	ent.ideal_yaw = yaw;
	M_ChangeYaw(ent);

	yaw = DEG2RAD(yaw);
	move.x = cosf(yaw) * dist;
	move.y = sinf(yaw) * dist;
	move.z = 0;

	oldorigin = ent.s.origin;
	if (SV_movestep(ent, move, false))
	{
		if(!ent.inuse)
			return true;

#ifdef GROUND_ZERO
		ent.monsterinfo.aiflags &= ~AI_BLOCKED;
#endif
		
		delta = ent.s.angles[YAW] - ent.ideal_yaw;
		
#ifdef GROUND_ZERO
		if (!strncmp(ent.classname, "monster_widow", 13))
#endif
			if (delta > 45 && delta < 315)
			{
				// not turned far enough, so don't take the step
				ent.s.origin = oldorigin;
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
	ent.flags |= FL_PARTIALGROUND;
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

	olddir = anglemod((int)(actor.ideal_yaw / 45) * 45);
	turnaround = anglemod(olddir - 180);

	deltax = enemy.s.origin[0] - actor.s.origin[0];
	deltay = enemy.s.origin[1] - actor.s.origin[1];
	if (deltax > 10)
		d.y = 0;
	else if (deltax < -10)
		d.y = 180f;
	else
		d.y = DI_NODIR;
	if (deltay < -10)
		d.z = 270f;
	else if (deltay > 10)
		d.z = 90f;
	else
		d.z = DI_NODIR;

// try direct route
	if (d[1] != DI_NODIR && d[2] != DI_NODIR) {
		if (d.y == 0)
			tdir = d.z == 90f ? 45f : 315f;
		else
			tdir = d.z == 90f ? 135f : 215f;

		if (tdir != turnaround && SV_StepDirection(actor, tdir, dist))
			return;
	}

// try other directions
	if (((Q_rand() & 3) & 1) || fabsf(deltay) > fabsf(deltax)) {
		tdir = d.y;
		d.y = d.z;
		d.z = tdir;
	}

	if (d.y != DI_NODIR && d.y != turnaround
		&& SV_StepDirection(actor, d.y, dist))
		return;

	if (d.z != DI_NODIR && d.z != turnaround
		&& SV_StepDirection(actor, d.z, dist))
		return;

#ifdef GROUND_ZERO
	if (actor.monsterinfo.blocked && actor.inuse && actor.health > 0 && actor.monsterinfo.blocked(actor, dist))
		return;
#endif

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

	actor.ideal_yaw = olddir;      // can't move

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
	if (goal.absmin.x > ent.absmax.x + dist)
		return false;
	if (goal.absmax.x < ent.absmin.x - dist)
		return false;
	if (goal.absmin.y > ent.absmax.y + dist)
		return false;
	if (goal.absmax.y < ent.absmin.y - dist)
		return false;
	if (goal.absmin.z > ent.absmax.z + dist)
		return false;
	if (goal.absmax.z < ent.absmin.z - dist)
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

	goal = ent.goalentity;

	if (ent.groundentity == null_entity && !(ent.flags & (FL_FLY | FL_SWIM)))
		return;

// if the next step hits the enemy, return immediately
	if (ent.enemy && SV_CloseEnough(ent, ent.enemy, dist))
		return;

// bump around...
	if (
#ifdef GROUND_ZERO
		((Q_rand() & 3) == 1 && !(ent.monsterinfo.aiflags & AI_CHARGING))
#else
		(Q_rand() & 3) == 1
#endif
		|| !SV_StepDirection(ent, ent.ideal_yaw, dist))
	{
#ifdef GROUND_ZERO
		if (ent.monsterinfo.aiflags & AI_BLOCKED)
		{
			ent.monsterinfo.aiflags &= ~AI_BLOCKED;
			return;
		}
#endif
		
		if (ent.inuse)
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

	if (ent.groundentity == null_entity && !(ent.flags & (FL_FLY | FL_SWIM)))
		return false;

	yaw = DEG2RAD(yaw);
	move.x = cosf(yaw) * dist;
	move.y = sinf(yaw) * dist;
	move.z = 0;

#ifdef GROUND_ZERO
	bool retval = SV_movestep(ent, move, true);
	ent.monsterinfo.aiflags &= ~AI_BLOCKED;
	return retval;
#else
	return SV_movestep(ent, move, true);
#endif
}
