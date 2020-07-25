void(entity ent) ChaseNext;

void(entity ent) UpdateChaseCam =
{
	vector	o, ownerv, goal;
	entity	targ;
	vector	forward, right;
	trace_t	trace;
	vector	angles;

	// is our chase target gone?
	if (!ent.client.chase_target.inuse
		|| ent.client.chase_target.client.resp.spectator) {
		entity old = ent.client.chase_target;
		ChaseNext(ent);
		if (ent.client.chase_target == old) {
			ent.client.chase_target = world;
			ent.client.ps.pmove.pm_flags &= ~PMF_NO_PREDICTION;
			return;
		}
	}

	targ = ent.client.chase_target;

	ownerv = targ.s.origin;

	ownerv.z += targ.viewheight;

	angles = targ.client.v_angle;
	if (angles[PITCH] > 56)
		angles[PITCH] = 56f;
	AngleVectors(angles, &forward, &right, 0);
	VectorNormalize(forward);
	o = ownerv + (-30 * forward);

	if (o.z < targ.s.origin[2] + 20f)
		o.z = targ.s.origin[2] + 20f;

	// jump animation lifts
	if (targ.groundentity == null_entity)
		o.z += 16;

	gi.trace(&trace, ownerv, vec3_origin, vec3_origin, o, targ, MASK_SOLID);

	goal = trace.endpos;

	goal = goal + (2 * forward);

	// pad for floors and ceilings
	o = goal;
	o.z += 6;
	gi.trace(&trace, goal, vec3_origin, vec3_origin, o, targ, MASK_SOLID);
	if (trace.fraction < 1) {
		goal = trace.endpos;
		goal.z -= 6;
	}

	o = goal;
	o.z -= 6;
	gi.trace(&trace, goal, vec3_origin, vec3_origin, o, targ, MASK_SOLID);
	if (trace.fraction < 1) {
		goal = trace.endpos;
		goal.z += 6;
	}

	if (targ.deadflag)
		ent.client.ps.pmove.pm_type = PM_DEAD;
	else
		ent.client.ps.pmove.pm_type = PM_FREEZE;

	ent.s.origin = goal;
	ent.client.ps.pmove.delta_angles[0] = ANGLE2SHORT(targ.client.v_angle[0] - ent.client.resp.cmd_angles[0]);
	ent.client.ps.pmove.delta_angles[1] = ANGLE2SHORT(targ.client.v_angle[1] - ent.client.resp.cmd_angles[1]);
	ent.client.ps.pmove.delta_angles[2] = ANGLE2SHORT(targ.client.v_angle[2] - ent.client.resp.cmd_angles[2]);

	if (targ.deadflag) {
		ent.client.ps.viewangles[ROLL] = 40f;
		ent.client.ps.viewangles[PITCH] = -15f;
		ent.client.ps.viewangles[YAW] = targ.client.killer_yaw;
	} else {
		ent.client.ps.viewangles = targ.client.v_angle;
		ent.client.v_angle = targ.client.v_angle;
	}

	ent.viewheight = 0;
	ent.client.ps.pmove.pm_flags |= PMF_NO_PREDICTION;
	gi.linkentity(ent);
}

void(entity ent) ChaseNext =
{
	int i;
	entity e;

	if (!ent.client.chase_target)
		return;

	i = ent.client.chase_target.s.number;
	do {
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
	int i;
	entity e;

	if (!ent.client.chase_target)
		return;

	i = ent.client.chase_target.s.number;
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
	int i;
	entity other;

	for (i = 1; i <= game.maxclients; i++) {
		other = itoe(i);
		if (other.inuse && !other.client.resp.spectator) {
			ent.client.chase_target = other;
			ent.client.update_chase = true;
			UpdateChaseCam(ent);
			return;
		}
	}
	gi.centerprintf(ent, "No other players to chase.");
}
