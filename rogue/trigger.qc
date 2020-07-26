#ifdef GROUND_ZERO

enumflags : int 
{
	TELEPORT_PLAYER_ONLY,
	TELEPORT_SILENT,
	TELEPORT_CTF_ONLY,
	TELEPORT_START_ON
};

/*QUAKED info_teleport_destination (.5 .5 .5) (-16 -16 -24) (16 16 32)
Destination marker for a teleporter.
*/
API_FUNC static void(entity self) SP_info_teleport_destination =
{
}

/*QUAKED trigger_teleport (.5 .5 .5) ? player_only silent ctf_only start_on
Any object touching this will be transported to the corresponding 
info_teleport_destination entity. You must set the "target" field, 
and create an object with a "targetname" field that matches.

If the trigger_teleport has a targetname, it will only teleport 
entities when it has been fired.

player_only: only players are teleported
silent: <not used right now>
ctf_only: <not used right now>
start_on: when trigger has targetname, start active, deactivate when used.
*/
static void(entity self, entity other, cplane_t plane, csurface_t surf) trigger_teleport_touch =
{
	entity	dest;

	if(/*(self.spawnflags & TELEPORT_PLAYER_ONLY) &&*/ !(other.is_client))
		return;

	if(self.delay)
		return;

	dest = G_Find (null_entity, targetname, self.target);
	if(dest == null_entity)
	{
		gi.dprintf("Teleport Destination not found!\n");
		return;
	}

	gi.WriteByte (svc_temp_entity);
	gi.WriteByte (TE_TELEPORT_EFFECT);
	gi.WritePosition (other.s.origin);
	gi.multicast (other.s.origin, MULTICAST_PVS);

	// unlink to make sure it can't possibly interfere with KillBox
	gi.unlinkentity (other);

	other.s.origin = dest.s.origin;
	other.s.old_origin = dest.s.origin;
	other.s.origin[2] += 10;

	// clear the velocity and hold them in place briefly
	other.velocity = vec3_origin;
	if(other.is_client)
	{
		other.client.ps.pmove.pm_time = 160>>3;		// hold time
		other.client.ps.pmove.pm_flags |= PMF_TIME_TELEPORT;

		// draw the teleport splash at source and on the player
		other.s.event = EV_PLAYER_TELEPORT;

		// set angles
		other.client.ps.pmove.delta_angles = dest.s.angles - other.client.resp.cmd_angles;

		other.client.ps.viewangles = vec3_origin;
		other.client.v_angle = vec3_origin;
	}


	other.s.angles = vec3_origin;

	// kill anything at the destination
	KillBox (other);

	gi.linkentity (other);
}

static void(entity self, entity other, entity cactivator) trigger_teleport_use =
{
	if(self.delay)
		self.delay = 0;
	else
		self.delay = 1f;
}

API_FUNC static void(entity self) SP_trigger_teleport =
{
	if (!self.wait)
		self.wait = 0.2;

	self.delay = 0;
		
	if (self.targetname)
	{
		self.use = trigger_teleport_use;
		if(!(self.spawnflags & TELEPORT_START_ON))
			self.delay = 1f;
	}

	self.touch = trigger_teleport_touch;

	self.solid = SOLID_TRIGGER;
	self.movetype = MOVETYPE_NONE;
//	self.flags |= FL_NOCLIENT;

	if (self.s.angles != vec3_origin)
		G_SetMovedir (self.s.angles, self.movedir);

	gi.setmodel (self, self.model);
	gi.linkentity (self);
}

// ***************************
// TRIGGER_DISGUISE
// ***************************

/*QUAKED trigger_disguise (.5 .5 .5) ? TOGGLE START_ON REMOVE
Anything passing through this trigger when it is active will
be marked as disguised.

TOGGLE - field is turned off and on when used.
START_ON - field is active when spawned.
REMOVE - field removes the disguise
*/

static void(entity self, entity other, cplane_t plane, csurface_t surf) trigger_disguise_touch =
{
	if (other.is_client)
	{
		if(self.spawnflags & 4)
			other.flags &= ~FL_DISGUISED;
		else
			other.flags |= FL_DISGUISED;
	}
}

static void(entity self, entity other, entity cactivator) trigger_disguise_use =
{
	if(self.solid == SOLID_NOT)
		self.solid = SOLID_TRIGGER;
	else
		self.solid = SOLID_NOT;

	gi.linkentity(self);
}

API_FUNC static void(entity self) SP_trigger_disguise =
{
	if(self.spawnflags & 2)
		self.solid = SOLID_TRIGGER;
	else
		self.solid = SOLID_NOT;

	self.touch = trigger_disguise_touch;
	self.use = trigger_disguise_use;
	self.movetype = MOVETYPE_NONE;
	self.svflags = SVF_NOCLIENT;

	gi.setmodel (self, self.model);
	gi.linkentity(self);

}

#endif