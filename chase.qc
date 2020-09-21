void(entity ent) ChaseNext;

void(entity ent) UpdateChaseCam =
{
	// is our chase target gone?
	if (!ent.client.chase_target.inuse || ent.client.chase_target.client.resp.spectator)
	{
		entity old = ent.client.chase_target;
		ChaseNext(ent);

		if (ent.client.chase_target == old)
		{
			ent.client.chase_target = world;
			ent.client.ps.pmove.pm_flags &= ~PMF_NO_PREDICTION;
			return;
		}
	}

	entity targ = ent.client.chase_target;

	vector ownerv = targ.s.origin;
	ownerv.z += targ.viewheight;

	vector angles = targ.client.v_angle;
	if (angles[PITCH] > 56)
		angles[PITCH] = 56f;

	vector forward, right;
	AngleVectors(angles, &forward, &right, 0);
	VectorNormalize(forward);
	vector o = ownerv + (-30 * forward);

	if (o.z < targ.s.origin[2] + 20f)
		o.z = targ.s.origin[2] + 20f;

	// jump animation lifts
	if (targ.groundentity == null_entity)
		o.z += 16;

	trace_t	trace;
	gi.traceline(&trace, ownerv, o, targ, MASK_SOLID);

	vector goal = trace.endpos + (2 * forward);

	// pad for floors and ceilings
	o = goal;
	o.z += 6;
	gi.traceline(&trace, goal, o, targ, MASK_SOLID);
	if (trace.fraction < 1)
	{
		goal = trace.endpos;
		goal.z -= 6;
	}

	o = goal;
	o.z -= 6;
	gi.traceline(&trace, goal, o, targ, MASK_SOLID);
	if (trace.fraction < 1)
	{
		goal = trace.endpos;
		goal.z += 6;
	}

	if (targ.deadflag)
		ent.client.ps.pmove.pm_type = PM_DEAD;
	else
		ent.client.ps.pmove.pm_type = PM_FREEZE;

	ent.s.origin = goal;
	ent.client.ps.pmove.delta_angles = targ.client.v_angle - ent.client.resp.cmd_angles;

	if (targ.deadflag)
	{
		ent.client.ps.viewangles[ROLL] = 40f;
		ent.client.ps.viewangles[PITCH] = -15f;
		ent.client.ps.viewangles[YAW] = targ.client.killer_yaw;
	}
	else
	{
		ent.client.ps.viewangles = targ.client.v_angle;
		ent.client.v_angle = targ.client.v_angle;
	}

	ent.viewheight = 0;
	ent.client.ps.pmove.pm_flags |= PMF_NO_PREDICTION;
	gi.linkentity(ent);
}

void(entity ent) ChaseNext =
{
	if (!ent.client.chase_target)
		return;

	int i = ent.client.chase_target.s.number;
	entity e;
	do
	{
		i++;
		if (i > game.maxclients)
			i = 1;
		e = itoe(i);
		if (!e.inuse)
			continue;
		if (!e.client.resp.spectator)
			break;
	} while (e != ent.client.chase_target);

	ent.client.chase_target = e;
	ent.client.update_chase = true;
}

void(entity ent) ChasePrev =
{
	if (!ent.client.chase_target)
		return;

	int i = ent.client.chase_target.s.number;
	entity e;
	do {
		i--;
		if (i < 1)
			i = game.maxclients;
		e = itoe(i);
		if (!e.inuse)
			continue;
		if (!e.client.resp.spectator)
			break;
	} while (e != ent.client.chase_target);

	ent.client.chase_target = e;
	ent.client.update_chase = true;
}

void(entity ent) GetChaseTarget =
{
	for (int i = 1; i <= game.maxclients; i++)
	{
		entity other = itoe(i);
		
		if (other.inuse && !other.client.resp.spectator)
		{
			ent.client.chase_target = other;
			ent.client.update_chase = true;
			UpdateChaseCam(ent);
			return;
		}
	}
	gi.centerprintf(ent, "No other players to chase.");
}
