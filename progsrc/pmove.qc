/*
Copyright (C) 1997-2001 Id Software, Inc.

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 2
of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  

See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
*/

#ifdef QUAKEC_PMOVE

// all of the locals will be zeroed before each
// pmove, just to make damn sure we don't have
// any differences when running on client or server
static struct
{
	vector	origin;			// full float precision
	vector	velocity;		// full float precision

	vector	forward, right, up;
	float	frametime;


	csurface_t	groundsurface;
	vector		groundnormal;
	int		groundcontents;

	vector		previous_origin;
	bool		ladder;
} pml;

static pmove_t		*pm;

// movement parameters
static const float	pm_stopspeed = 100;
static const float	pm_maxspeed = 300;
static const float	pm_duckspeed = 100;
static const float	pm_accelerate = 10;
static const float	pm_airaccelerate = 0;
static const float	pm_wateraccelerate = 10;
static const float	pm_friction = 6;
static const float	pm_waterfriction = 1;
static const float	pm_waterspeed = 400;

static hashset pm_entity_list;

/*

  walking up a step should kill some velocity

*/

/*
==================
PM_StepSlideMove

Each intersection will try to step over the obstruction instead of
sliding along it.

Returns a new origin, velocity, and contact entity
Does not modify any world state?
==================
*/
static const float MIN_STEP_NORMAL	= 0.7;		// can't step up onto very steep slopes

static void PM_StepSlideMove_ (void)
{
	int			bumpcount, numbumps;
	vector		dir;
	float		d;
	int			numplanes;
	vector		planes[MAX_CLIP_PLANES];
	vector		primal_velocity;
	int			i, j;
	trace_t	trace;
	vector		end;
	float		time_left;
	
	numbumps = 4;
	
	primal_velocity = pml.velocity;
	numplanes = 0;
	
	time_left = pml.frametime;

	for (bumpcount = 0; bumpcount < numbumps; bumpcount++)
	{
		end = pml.origin + (time_left * pml.velocity);

		pm->trace(&trace, pml.origin, pm->mins, pm->maxs, end);

		if (trace.allsolid)
		{
			// entity is trapped in another solid
			pml.velocity[2] = 0;	// don't build up falling damage
			return;
		}

		if (trace.fraction > 0)
		{
			// actually covered some distance
			pml.origin = trace.endpos;
			numplanes = 0;
		}

		if (trace.fraction == 1)
			 break;		// moved the entire distance

		// save entity for contact
		if (trace.ent != null_entity)
			hashset_add(pm_entity_list, TYPE_ENTITY, trace.ent);
		
		time_left -= time_left * trace.fraction;

		// slide along this plane
		if (numplanes >= MAX_CLIP_PLANES)
		{
			// this shouldn't really happen
			pml.velocity = vec3_origin;
			break;
		}

		planes[numplanes] = trace.normal;
		numplanes++;

//
// modify original_velocity so it parallels all of the clip planes
//
		for (i=0 ; i<numplanes ; i++)
		{
			pml.velocity = ClipVelocity (pml.velocity, planes[i], 1.01);
			for (j=0 ; j<numplanes ; j++)
				if (j != i)
				{
					if ((pml.velocity * planes[j]) < 0)
						break;	// not ok
				}
			if (j == numplanes)
				break;
		}
		
		if (i == numplanes)
		{
			// go along the crease
			if (numplanes != 2)
			{
				pml.velocity = vec3_origin;
				break;
			}
			dir = CrossProduct (planes[0], planes[1]);
			d = dir * pml.velocity;
			pml.velocity = dir * d;
		}

		//
		// if velocity is against the original velocity, stop dead
		// to avoid tiny occilations in sloping corners
		//
		if ((pml.velocity * primal_velocity) <= 0)
		{
			pml.velocity = vec3_origin;
			break;
		}
	}

	if (pm->s.pm_time)
		pml.velocity = primal_velocity;
}

/*
==================
PM_StepSlideMove

==================
*/
static void PM_StepSlideMove (void)
{
	vector		start_o, start_v;
	vector		down_o, down_v;
	trace_t		trace;
	float		down_dist, up_dist;
	vector		up, down;

	start_o = pml.origin;
	start_v = pml.velocity;

	PM_StepSlideMove_ ();

	down_o = pml.origin;
	down_v = pml.velocity;

	up = start_o;
	up[2] += STEPSIZE;

	pm->trace (&trace, up, pm->mins, pm->maxs, up);
	if (trace.allsolid)
		return;		// can't step up

	// try sliding above
	pml.origin = up;
	pml.velocity = start_v;

	PM_StepSlideMove_ ();

	// push down the final amount
	down = pml.origin;
	down[2] -= STEPSIZE;
	pm->trace (&trace, pml.origin, pm->mins, pm->maxs, down);
	if (!trace.allsolid)
		pml.origin = trace.endpos;

	up = pml.origin;

	// decide which one went farther
	down_dist = (down_o[0] - start_o[0])*(down_o[0] - start_o[0])
		+ (down_o[1] - start_o[1])*(down_o[1] - start_o[1]);
	up_dist = (up[0] - start_o[0])*(up[0] - start_o[0])
		+ (up[1] - start_o[1])*(up[1] - start_o[1]);

	if (down_dist > up_dist || trace.normal[2] < MIN_STEP_NORMAL)
	{
		pml.origin = down_o;
		pml.velocity = down_v;
		return;
	}
	//!! Special case
	// if we were walking along a plane, then we need to copy the Z over
	pml.velocity[2] = down_v[2];
}


/*
==================
PM_Friction

Handles both ground friction and water friction
==================
*/
static void PM_Friction (void)
{
	float	speed, newspeed, control;
	float	friction;
	float	drop;

	speed = VectorLength(pml.velocity);
	if (speed < 1)
	{
		pml.velocity[0] = pml.velocity[1] = 0;
		return;
	}

	drop = 0;

// apply ground friction
	if ((pm->groundentity != null_entity && pml.groundsurface != null_surface && !(pml.groundsurface.flags & SURF_SLICK)) || pml.ladder )
	{
		friction = pm_friction;
		control = speed < pm_stopspeed ? pm_stopspeed : speed;
		drop += control*friction*pml.frametime;
	}

// apply water friction
	if (pm->waterlevel && !pml.ladder)
		drop += speed*pm_waterfriction*pm->waterlevel*pml.frametime;

// scale the velocity
	newspeed = speed - drop;
	if (newspeed < 0)
	{
		newspeed = 0;
	}
	newspeed /= speed;

	pml.velocity *= newspeed;
}


/*
==============
PM_Accelerate

Handles user intended acceleration
==============
*/
static void PM_Accelerate (vector wishdir, float wishspeed, float accel)
{
	float		addspeed, accelspeed, currentspeed;

	currentspeed = pml.velocity * wishdir;
	addspeed = wishspeed - currentspeed;
	if (addspeed <= 0)
		return;
	accelspeed = accel*pml.frametime*wishspeed;
	if (accelspeed > addspeed)
		accelspeed = addspeed;

	pml.velocity += accelspeed * wishdir;	
}

static void PM_AirAccelerate (vector wishdir, float wishspeed, float accel)
{
	float		addspeed, accelspeed, currentspeed, wishspd = wishspeed;
		
	if (wishspd > 30)
		wishspd = 30f;
	currentspeed = pml.velocity * wishdir;
	addspeed = wishspd - currentspeed;
	if (addspeed <= 0)
		return;
	accelspeed = accel * wishspeed * pml.frametime;
	if (accelspeed > addspeed)
		accelspeed = addspeed;

	pml.velocity += accelspeed * wishdir;	
}

/*
=============
PM_AddCurrents
=============
*/
static void PM_AddCurrents (inout vector wishvel)
{
	vector	v;
	float	s;

	//
	// account for ladders
	//

	if (pml.ladder && fabs(pml.velocity[2]) <= 200)
	{
		if ((pm->viewangles[PITCH] <= -15) && (pm->cmd.forwardmove > 0))
			wishvel[2] = 200f;
		else if ((pm->viewangles[PITCH] >= 15) && (pm->cmd.forwardmove > 0))
			wishvel[2] = -200f;
		else if (pm->cmd.upmove > 0)
			wishvel[2] = 200f;
		else if (pm->cmd.upmove < 0)
			wishvel[2] = -200f;
		else
			wishvel[2] = 0;

		// limit horizontal speed when on a ladder
		if (wishvel[0] < -25)
			wishvel[0] = -25f;
		else if (wishvel[0] > 25)
			wishvel[0] = 25f;

		if (wishvel[1] < -25)
			wishvel[1] = -25f;
		else if (wishvel[1] > 25)
			wishvel[1] = 25f;
	}

	//
	// add water currents
	//

	if (pm->watertype & MASK_CURRENT)
	{
		v = vec3_origin;

		if (pm->watertype & CONTENTS_CURRENT_0)
			v[0] += 1;
		if (pm->watertype & CONTENTS_CURRENT_90)
			v[1] += 1;
		if (pm->watertype & CONTENTS_CURRENT_180)
			v[0] -= 1;
		if (pm->watertype & CONTENTS_CURRENT_270)
			v[1] -= 1;
		if (pm->watertype & CONTENTS_CURRENT_UP)
			v[2] += 1;
		if (pm->watertype & CONTENTS_CURRENT_DOWN)
			v[2] -= 1;

		s = pm_waterspeed;
		if (pm->waterlevel == 1 && pm->groundentity != null_entity)
			s *= 0.5f;

		wishvel += s * v;
	}

	//
	// add conveyor belt velocities
	//

	if (pm->groundentity != null_entity)
	{
		v = vec3_origin;

		if (pml.groundcontents & CONTENTS_CURRENT_0)
			v[0] += 1;
		if (pml.groundcontents & CONTENTS_CURRENT_90)
			v[1] += 1;
		if (pml.groundcontents & CONTENTS_CURRENT_180)
			v[0] -= 1;
		if (pml.groundcontents & CONTENTS_CURRENT_270)
			v[1] -= 1;
		if (pml.groundcontents & CONTENTS_CURRENT_UP)
			v[2] += 1;
		if (pml.groundcontents & CONTENTS_CURRENT_DOWN)
			v[2] -= 1;

		wishvel += 100 * v;
	}
}


/*
===================
PM_WaterMove

===================
*/
static void PM_WaterMove (void)
{
	vector	wishvel;
	float	wishspeed;
	vector	wishdir;

//
// user intentions
//
	wishvel = pml.forward * pm->cmd.forwardmove + pml.right * pm->cmd.sidemove;

	if (!pm->cmd.forwardmove && !pm->cmd.sidemove && !pm->cmd.upmove)
		wishvel[2] -= 60;		// drift towards bottom
	else
		wishvel[2] += pm->cmd.upmove;

	PM_AddCurrents (wishvel);

	wishdir = wishvel;
	wishspeed = VectorNormalize(wishdir);

	if (wishspeed > pm_maxspeed)
	{
		wishvel *= pm_maxspeed / wishspeed;
		wishspeed = pm_maxspeed;
	}
	wishspeed *= 0.5;

	PM_Accelerate (wishdir, wishspeed, pm_wateraccelerate);

	PM_StepSlideMove ();
}


/*
===================
PM_AirMove

===================
*/
static void PM_AirMove (void)
{
	int			i;
	vector		wishvel;
	int		fmove, smove;
	vector		wishdir;
	float		wishspeed;
	float		maxspeed;

	fmove = pm->cmd.forwardmove;
	smove = pm->cmd.sidemove;

	for (i = 0; i < 2; i++)
		wishvel[i] = pml.forward[i]*fmove + pml.right[i]*smove;
	wishvel[2] = 0;

	PM_AddCurrents (wishvel);

	wishdir = wishvel;
	wishspeed = VectorNormalize(wishdir);

//
// clamp to server defined max speed
//
	maxspeed = (pm->s.pm_flags & PMF_DUCKED) ? pm_duckspeed : pm_maxspeed;

	if (wishspeed > maxspeed)
	{
		wishvel *= maxspeed / wishspeed;
		wishspeed = maxspeed;
	}
	
	if (pml.ladder)
	{
		PM_Accelerate (wishdir, wishspeed, pm_accelerate);
		if (!wishvel[2])
		{
			if (pml.velocity[2] > 0)
			{
				pml.velocity[2] -= pm->s.gravity * pml.frametime;
				if (pml.velocity[2] < 0)
					pml.velocity[2]  = 0;
			}
			else
			{
				pml.velocity[2] += pm->s.gravity * pml.frametime;
				if (pml.velocity[2] > 0)
					pml.velocity[2]  = 0;
			}
		}
		PM_StepSlideMove ();
	}
	else if (pm->groundentity != null_entity)
	{	// walking on ground
		pml.velocity[2] = 0; //!!! this is before the accel
		PM_Accelerate (wishdir, wishspeed, pm_accelerate);

		if(pm->s.gravity > 0)
			pml.velocity[2] = 0;
		else
			pml.velocity[2] -= pm->s.gravity * pml.frametime;

		if (!pml.velocity[0] && !pml.velocity[1])
			return;
		PM_StepSlideMove ();
	}
	else
	{	// not on ground, so little effect on velocity
		if (pm_airaccelerate)
			PM_AirAccelerate (wishdir, wishspeed, pm_accelerate);
		else
			PM_Accelerate (wishdir, wishspeed, 1);
		// add gravity
		pml.velocity[2] -= pm->s.gravity * pml.frametime;
		PM_StepSlideMove ();
	}
}



/*
=============
PM_CatagorizePosition
=============
*/
static void PM_CatagorizePosition (void)
{
	vector		point;
	int			cont;
	trace_t		trace;
	int			sample1;
	int			sample2;

// if the player hull point one unit down is solid, the player
// is on ground

// see if standing on something solid	
	point[0] = pml.origin[0];
	point[1] = pml.origin[1];
	point[2] = pml.origin[2] - 0.25;
	if (pml.velocity[2] > 180) //!!ZOID changed from 100 to 180 (ramp accel)
	{
		pm->s.pm_flags &= ~PMF_ON_GROUND;
		pm->groundentity = null_entity;
	}
	else
	{
		pm->trace (&trace, pml.origin, pm->mins, pm->maxs, point);
		pml.groundnormal = trace.normal;
		pml.groundsurface = trace.surface;
		pml.groundcontents = trace.contents;

		if (trace.ent == null_entity || (trace.normal[2] < 0.7 && !trace.startsolid))
		{
			pm->groundentity = null_entity;
			pm->s.pm_flags &= ~PMF_ON_GROUND;
		}
		else
		{
			pm->groundentity = trace.ent;

			// hitting solid ground will end a waterjump
			if (pm->s.pm_flags & PMF_TIME_WATERJUMP)
			{
				pm->s.pm_flags &= ~(PMF_TIME_WATERJUMP | PMF_TIME_LAND | PMF_TIME_TELEPORT);
				pm->s.pm_time = 0;
			}

			if (! (pm->s.pm_flags & PMF_ON_GROUND) )
			{	// just hit the ground
				pm->s.pm_flags |= PMF_ON_GROUND;
				// don't do landing time if we were just going down a slope
				if (pml.velocity[2] < -200)
				{
					pm->s.pm_flags |= PMF_TIME_LAND;
					// don't allow another jump for a little while
					if (pml.velocity[2] < -400)
						pm->s.pm_time = 25;	
					else
						pm->s.pm_time = 18;
				}
			}
		}

		if (trace.ent != null_entity)
			hashset_add(pm_entity_list, TYPE_ENTITY, trace.ent);
	}

//
// get waterlevel, accounting for ducking
//
	pm->waterlevel = 0;
	pm->watertype = 0;

	sample2 = (int)(pm->viewheight - pm->mins[2]);
	sample1 = sample2 / 2;

	point[2] = pml.origin[2] + pm->mins[2] + 1;	
	cont = pm->pointcontents (point);

	if (cont & MASK_WATER)
	{
		pm->watertype = cont;
		pm->waterlevel = 1;
		point[2] = pml.origin[2] + pm->mins[2] + sample1;
		cont = pm->pointcontents (point);
		if (cont & MASK_WATER)
		{
			pm->waterlevel = 2;
			point[2] = pml.origin[2] + pm->mins[2] + sample2;
			cont = pm->pointcontents (point);
			if (cont & MASK_WATER)
				pm->waterlevel = 3;
		}
	}

}


/*
=============
PM_CheckJump
=============
*/
static void PM_CheckJump (void)
{
	if (pm->s.pm_flags & PMF_TIME_LAND)
	{	// hasn't been long enough since landing to jump again
		return;
	}

	if (pm->cmd.upmove < 10)
	{	// not holding jump
		pm->s.pm_flags &= ~PMF_JUMP_HELD;
		return;
	}

	// must wait for jump to be released
	if (pm->s.pm_flags & PMF_JUMP_HELD)
		return;

	if (pm->s.pm_type == PM_DEAD)
		return;

	if (pm->waterlevel >= 2)
	{	// swimming, not jumping
		pm->groundentity = null_entity;

		if (pml.velocity[2] <= -300)
			return;

		if (pm->watertype == CONTENTS_WATER)
			pml.velocity[2] = 100f;
		else if (pm->watertype == CONTENTS_SLIME)
			pml.velocity[2] = 80f;
		else
			pml.velocity[2] = 50f;
		return;
	}

	if (pm->groundentity == null_entity)
		return;		// in air, so no effect

	pm->s.pm_flags |= PMF_JUMP_HELD;

	pm->groundentity = null_entity;
	pml.velocity[2] += 270;
	if (pml.velocity[2] < 270)
		pml.velocity[2] = 270f;
}


/*
=============
PM_CheckSpecialMovement
=============
*/
static void PM_CheckSpecialMovement (void)
{
	vector	spot;
	int		cont;
	vector	flatforward;
	trace_t	trace;

	if (pm->s.pm_time)
		return;

	pml.ladder = false;

	// check for ladder
	flatforward[0] = pml.forward[0];
	flatforward[1] = pml.forward[1];
	flatforward[2] = 0;
	VectorNormalize (flatforward);

	spot = pml.origin + (1 * flatforward);
	pm->trace (&trace, pml.origin, pm->mins, pm->maxs, spot);
	if (trace.fraction < 1 && (trace.contents & CONTENTS_LADDER))
		pml.ladder = true;

	// check for water jump
	if (pm->waterlevel != 2)
		return;

	spot = pml.origin + (30 * flatforward);
	spot[2] += 4;
	cont = pm->pointcontents (spot);
	if (!(cont & CONTENTS_SOLID))
		return;

	spot[2] += 16;
	cont = pm->pointcontents (spot);
	if (cont)
		return;
	// jump out of water
	pml.velocity = flatforward * 50;
	pml.velocity[2] = 350f;

	pm->s.pm_flags |= PMF_TIME_WATERJUMP;
	pm->s.pm_time = 255;
}


/*
===============
PM_FlyMove
===============
*/
static void PM_FlyMove (bool doclip)
{
	float	speed, drop, friction, control, newspeed;
	float	currentspeed, addspeed, accelspeed;
	vector		wishvel;
	int		fmove, smove;
	vector		wishdir;
	float		wishspeed;
	vector		end;
	trace_t	trace;

	pm->viewheight = 22f;

	// friction

	speed = VectorLength (pml.velocity);
	if (speed < 1)
		pml.velocity = vec3_origin;
	else
	{
		drop = 0;

		friction = pm_friction*1.5;	// extra friction
		control = speed < pm_stopspeed ? pm_stopspeed : speed;
		drop += control*friction*pml.frametime;

		// scale the velocity
		newspeed = speed - drop;
		if (newspeed < 0)
			newspeed = 0;
		newspeed /= speed;

		pml.velocity *= newspeed;
	}

	// accelerate
	fmove = pm->cmd.forwardmove;
	smove = pm->cmd.sidemove;
	
	VectorNormalize (pml.forward);
	VectorNormalize (pml.right);

	wishvel = pml.forward*fmove + pml.right*smove;
	wishvel[2] += pm->cmd.upmove;

	wishdir = wishvel;
	wishspeed = VectorNormalize(wishdir);

	//
	// clamp to server defined max speed
	//
	if (wishspeed > pm_maxspeed)
	{
		wishvel *= pm_maxspeed / wishspeed;
		wishspeed = pm_maxspeed;
	}


	currentspeed = pml.velocity * wishdir;
	addspeed = wishspeed - currentspeed;
	if (addspeed <= 0)
		return;
	accelspeed = pm_accelerate*pml.frametime*wishspeed;
	if (accelspeed > addspeed)
		accelspeed = addspeed;
	
	pml.velocity += accelspeed * wishdir;	

	if (doclip)
	{
		end = pml.origin + (pml.frametime * pml.velocity);

		pm->trace (&trace, pml.origin, pm->mins, pm->maxs, end);

		pml.origin = trace.endpos;
	}
	else
		pml.origin += pml.frametime * pml.velocity; // move
}


/*
==============
PM_CheckDuck

Sets mins, maxs, and pm->viewheight
==============
*/
static void PM_CheckDuck (void)
{
	trace_t	trace;

	pm->mins[0] = -16f;
	pm->mins[1] = -16f;

	pm->maxs[0] = 16f;
	pm->maxs[1] = 16f;

	if (pm->s.pm_type == PM_GIB)
	{
		pm->mins[2] = 0;
		pm->maxs[2] = 16f;
		pm->viewheight = 8f;
		return;
	}

	pm->mins[2] = -24f;

	if (pm->s.pm_type == PM_DEAD)
		pm->s.pm_flags |= PMF_DUCKED;
	else if (pm->cmd.upmove < 0 && (pm->s.pm_flags & PMF_ON_GROUND))
		pm->s.pm_flags |= PMF_DUCKED; // duck
	else if (pm->s.pm_flags & PMF_DUCKED)
	{
		// try to stand up
		pm->maxs[2] = 32f;
		pm->trace (&trace, pml.origin, pm->mins, pm->maxs, pml.origin);
		if (!trace.allsolid)
			pm->s.pm_flags &= ~PMF_DUCKED;
	}

	if (pm->s.pm_flags & PMF_DUCKED)
	{
		pm->maxs[2] = 4f;
		pm->viewheight = -2f;
	}
	else
	{
		pm->maxs[2] = 32f;
		pm->viewheight = 22f;
	}
}


/*
==============
PM_DeadMove
==============
*/
static void PM_DeadMove (void)
{
	float	forward;

	if (pm->groundentity == null_entity)
		return;

	// extra friction

	forward = VectorLength (pml.velocity);
	forward -= 20;
	if (forward <= 0)
		pml.velocity = vec3_origin;
	else
	{
		VectorNormalize (pml.velocity);
		pml.velocity *= forward;
	}
}


static bool PM_GoodPosition (void)
{
	trace_t	trace;
	vector	origin, end;

	if (pm->s.pm_type == PM_SPECTATOR)
		return true;

	origin = end = pm->s.origin * 0.125;
	pm->trace (&trace, origin, pm->mins, pm->maxs, end);

	return !trace.allsolid;
}

/*
================
PM_SnapPosition

On exit, the origin will have a value that is pre-quantized to the 0.125
precision of the network channel and in a valid position.
================
*/
static void PM_SnapPosition (void)
{
	int		sign[3] = { 0 };
	int		i, j, bits;
	int	base[3] = { 0 };
	// try all single bits first
	static int jitterbits[8] = {0,4,1,2,3,5,6,7};

	// snap velocity to eigths
	for (i=0 ; i<3 ; i++)
		pm->s.velocity[i] = (float)(int)(pml.velocity[i]*8);

	for (i=0 ; i<3 ; i++)
	{
		if (pml.origin[i] >= 0)
			sign[i] = 1;
		else 
			sign[i] = -1;
		pm->s.origin[i] = (float)(base[i] = (int)(pml.origin[i]*8));
		if (pm->s.origin[i]*0.125 == pml.origin[i])
			sign[i] = 0;
	}

	// try all combinations
	for (j=0 ; j<8 ; j++)
	{
		bits = jitterbits[j];
		pm->s.origin = [ (float)base[0], (float)base[1], (float)base[2] ];
		for (i=0 ; i<3 ; i++)
			if (bits & (1<<i) )
				pm->s.origin[i] += sign[i];

		if (PM_GoodPosition ())
			return;
	}

	// go back to the last position
	pm->s.origin = pml.previous_origin;
}

/*
================
PM_InitialSnapPosition

================
*/
static void PM_InitialSnapPosition(void)
{
	int        x, y, z;
	static int offset[3] = { 0, -1, 1 };
	int base[3] = { (int)pm->s.origin[0], (int)pm->s.origin[1], (int)pm->s.origin[2] };

	for ( z = 0; z < 3; z++ ) {
		pm->s.origin[2] = (float)(base[2] + offset[z]);
		for ( y = 0; y < 3; y++ ) {
			pm->s.origin[1] = (float)(base[1] + offset[y]);
			for ( x = 0; x < 3; x++ ) {
				pm->s.origin[0] = (float)(base[0] + offset[x]);
				if (PM_GoodPosition ()) {
					pml.origin = pm->s.origin * 0.125;
					pml.previous_origin = pm->s.origin;
					return;
				}
			}
		}
	}
}

/*
================
PM_ClampAngles

================
*/

const float coord2short = 8.f;
const float angle2short = (65536.f / 360.f);
const float short2coord = (1.0f / 8);
const float short2angle = (360.0f / 65536);

static void PM_ClampAngles (void)
{
	int	temp;
	int		i;

	if (pm->s.pm_flags & PMF_TIME_TELEPORT)
	{
		pm->viewangles[YAW] = (pm->cmd.angles[YAW] + pm->s.delta_angles[YAW]) * short2angle;
		pm->viewangles[PITCH] = 0;
		pm->viewangles[ROLL] = 0;
	}
	else
	{
		// circularly clamp the angles with deltas
		for (i=0 ; i<3 ; i++)
		{
			temp = (int)(pm->cmd.angles[i] + pm->s.delta_angles[i]);
			pm->viewangles[i] = temp * short2angle;
		}

		// don't let the player look up or down more than 90 degrees
		if (pm->viewangles[PITCH] > 89 && pm->viewangles[PITCH] < 180)
			pm->viewangles[PITCH] = 89f;
		else if (pm->viewangles[PITCH] < 271 && pm->viewangles[PITCH] >= 180)
			pm->viewangles[PITCH] = 271f;
	}
	AngleVectors (pm->viewangles, &pml.forward, &pml.right, &pml.up);
}

/*
================
Pmove

Can be called by either the server or the client
================
*/
static void Pmove_ (pmove_t *pmove)
{
	if (handle_empty(pm_entity_list))
		pm_entity_list = hashset_alloc(16);
	else
		hashset_clear(pm_entity_list);
	
	pm = pmove;

	// Paril: input adjustments
	for (int i = 0; i < 3; i++)
	{
		pm->s.origin[i] = (float)(int)(pm->s.origin[i] * coord2short);
		pm->s.velocity[i] = (float)(int)(pm->s.velocity[i] * coord2short);
		pm->s.delta_angles[i] = (float)(int)(pm->s.delta_angles[i] * angle2short);
		pm->cmd.angles[i] = (float)(int)(pm->cmd.angles[i] * angle2short);
	}
	
	// clear results
	pm->touchents = pm_entity_list;
	pm->viewangles = vec3_origin;
	pm->viewheight = 0;
	pm->groundentity = null_entity;
	pm->watertype = 0;
	pm->waterlevel = 0;

	// clear all pmove local vars
	memclear (&pml, sizeof(pml));

	// convert origin and velocity to float values
	pml.origin[0] = pm->s.origin[0]*0.125;
	pml.origin[1] = pm->s.origin[1]*0.125;
	pml.origin[2] = pm->s.origin[2]*0.125;

	pml.velocity[0] = pm->s.velocity[0]*0.125;
	pml.velocity[1] = pm->s.velocity[1]*0.125;
	pml.velocity[2] = pm->s.velocity[2]*0.125;

	// save old org in case we get stuck
	pml.previous_origin = pm->s.origin;

	pml.frametime = pm->cmd.msec * 0.001;

	PM_ClampAngles ();

	if (pm->s.pm_type == PM_SPECTATOR)
	{
		PM_FlyMove (false);
		PM_SnapPosition ();
		return;
	}

	if (pm->s.pm_type >= PM_DEAD)
	{
		pm->cmd.forwardmove = 0;
		pm->cmd.sidemove = 0;
		pm->cmd.upmove = 0;
	}

	if (pm->s.pm_type == PM_FREEZE)
		return;		// no movement at all

	// set mins, maxs, and viewheight
	PM_CheckDuck ();

	if (pm->snapinitial)
		PM_InitialSnapPosition ();

	// set groundentity, watertype, and waterlevel
	PM_CatagorizePosition ();

	if (pm->s.pm_type == PM_DEAD)
		PM_DeadMove ();

	PM_CheckSpecialMovement ();

	// drop timing counter
	if (pm->s.pm_time)
	{
		int		msec;

		msec = pm->cmd.msec >> 3;
		if (!msec)
			msec = 1;
		if ( msec >= pm->s.pm_time) 
		{
			pm->s.pm_flags &= ~(PMF_TIME_WATERJUMP | PMF_TIME_LAND | PMF_TIME_TELEPORT);
			pm->s.pm_time = 0;
		}
		else
			pm->s.pm_time -= msec;
	}

	if (pm->s.pm_flags & PMF_TIME_TELEPORT)
	{	// teleport pause stays exactly in place
	}
	else if (pm->s.pm_flags & PMF_TIME_WATERJUMP)
	{	// waterjump has no control, but falls
		pml.velocity[2] -= pm->s.gravity * pml.frametime;
		if (pml.velocity[2] < 0)
		{	// cancel as soon as we are falling down again
			pm->s.pm_flags &= ~(PMF_TIME_WATERJUMP | PMF_TIME_LAND | PMF_TIME_TELEPORT);
			pm->s.pm_time = 0;
		}

		PM_StepSlideMove ();
	}
	else
	{
		PM_CheckJump ();

		PM_Friction ();

		if (pm->waterlevel >= 2)
			PM_WaterMove ();
		else {
			vector	angles;

			angles = pm->viewangles;
			if (angles[PITCH] > 180)
				angles[PITCH] = angles[PITCH] - 360;
			angles[PITCH] /= 3;

			AngleVectors (angles, &pml.forward, &pml.right, &pml.up);

			PM_AirMove ();
		}
	}

	// set groundentity, watertype, and waterlevel for final spot
	PM_CatagorizePosition ();

	PM_SnapPosition ();
}

void Pmove (pmove_t *pmove)
{
	Pmove_(pmove);

	for (int i = 0; i < 3; i++)
	{
		pmove->s.origin[i] = pmove->s.origin[i] * short2coord;
		pmove->s.velocity[i] = pmove->s.velocity[i] * short2coord;
		pmove->s.delta_angles[i] = pmove->s.delta_angles[i] * short2angle;
	}
}

#endif