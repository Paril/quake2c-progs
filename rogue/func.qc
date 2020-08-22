#ifdef GROUND_ZERO

/*
=============================================================================

SECRET DOORS

=============================================================================
*/

enumflags : int
{
	SEC_OPEN_ONCE,          // stays open
	SEC_1ST_LEFT,          // 1st move is left of arrow
	SEC_1ST_DOWN,          // 1st move is down from arrow
	SEC_NO_SHOOT,          // only opened by trigger
	SEC_YES_SHOOT,		   // shootable even if targeted
	SEC_MOVE_RIGHT,
	SEC_MOVE_FORWARD
};

static void(entity self) fd_secret_move1;

static void(entity self, entity other, entity cactivator) fd_secret_use =
{
	entity	ent;

	if (self.flags & FL_TEAMSLAVE)
		return;

	// trigger all paired doors
	for (ent = self ; ent ; ent = ent.teamchain)
		Move_Calc(ent, ent.moveinfo.start_origin, fd_secret_move1);

}

static void(entity self, entity inflictor, entity attacker, int damage, vector point) fd_secret_killed =
{
	self.health = self.max_health;
	self.takedamage = false;

	if ((self.flags & FL_TEAMSLAVE) && self.teammaster && self.teammaster.takedamage != false)
		fd_secret_killed (self.teammaster, inflictor, attacker, damage, point);
	else
		fd_secret_use (self, inflictor, attacker);
}

static void(entity self) fd_secret_move2;

// Wait after first movement...
static void(entity self) fd_secret_move1 =
{
	self.nextthink = level.framenum + (int)(1.0 * BASE_FRAMERATE);
	self.think = fd_secret_move2;
}

static void(entity self) fd_secret_move3;

// Start moving sideways w/sound...
static void(entity self) fd_secret_move2 =
{
	Move_Calc(self, self.moveinfo.end_origin, fd_secret_move3);
}

static void(entity self) fd_secret_move4;

// Wait here until time to go back...
static void(entity self) fd_secret_move3 =
{
	if (!(self.spawnflags & SEC_OPEN_ONCE))
	{
		self.nextthink = level.framenum + (int)(self.wait * BASE_FRAMERATE);
		self.think = fd_secret_move4;
	}
}

static void(entity self) fd_secret_move5;

// Move backward...
static void(entity self) fd_secret_move4 =
{
	Move_Calc(self, self.moveinfo.start_origin, fd_secret_move5);          
}

static void(entity self) fd_secret_move6;

// Wait 1 second...
static void(entity self) fd_secret_move5 =
{
	self.nextthink = level.framenum + (int)(1.0 * BASE_FRAMERATE);
	self.think = fd_secret_move6;
}

static void(entity self) fd_secret_done;

static void(entity self) fd_secret_move6 =
{
	Move_Calc(self, self.move_origin, fd_secret_done);
}

static void(entity self) fd_secret_done =
{
	if (!self.targetname || self.spawnflags & SEC_YES_SHOOT)
	{
		self.health = 1;
		self.takedamage = true;
		self.die = fd_secret_killed;   
	}
}

static void(entity self, entity other) secret_blocked =
{
	if (!(self.flags & FL_TEAMSLAVE))
		T_Damage (other, self, self, vec3_origin, other.s.origin, vec3_origin, self.dmg, 0, 0, MOD_CRUSH);
}

/*
================
secret_touch

Prints messages
================
*/
static void(entity self, entity other, vector plane, csurface_t surf) secret_touch =
{
	if (other.health <= 0)
		return;

	if (!(other.is_client))
		return;

	if (self.monsterinfo.attack_finished > level.framenum)
		return;

	self.monsterinfo.attack_finished = level.framenum + (int)(2 * BASE_FRAMERATE);
	
	if (self.message)
		gi.centerprintf (other, self.message);
}


/*QUAKED func_door_secret2 (0 .5 .8) ? open_once 1st_left 1st_down no_shoot always_shoot slide_right slide_forward
Basic secret door. Slides back, then to the left. Angle determines direction.

FLAGS:
open_once = not implemented yet
1st_left = 1st move is left/right of arrow
1st_down = 1st move is forwards/backwards
no_shoot = not implemented yet
always_shoot = even if targeted, keep shootable
reverse_left = the sideways move will be to right of arrow
reverse_back = the to/fro move will be forward

VALUES:
wait = # of seconds before coming back (5 default)
dmg  = damage to inflict when blocked (2 default)

*/

API_FUNC static void(entity ent) SP_func_door_secret2 =
{
	vector	forward,right,up;
	float	lrSize = 0, fbSize = 0;

	ent.moveinfo.sound_start = gi.soundindex  ("doors/dr1_strt.wav");
	ent.moveinfo.sound_middle = gi.soundindex  ("doors/dr1_mid.wav");
	ent.moveinfo.sound_end = gi.soundindex  ("doors/dr1_end.wav");

	if (!ent.dmg)
		ent.dmg = 2;
		
	AngleVectors(ent.s.angles, &forward, &right, &up);
	ent.move_origin = ent.s.origin;
	ent.move_angles = ent.s.angles;

	G_SetMovedir (ent.s.angles, ent.movedir);
	ent.movetype = MOVETYPE_PUSH;
	ent.solid = SOLID_BSP;
	gi.setmodel (ent, ent.model);

	if(ent.move_angles[1] == 0 || ent.move_angles[1] == 180)
	{
		lrSize = ent.size[1];
		fbSize = ent.size[0];
	}		
	else if(ent.move_angles[1] == 90 || ent.move_angles[1] == 270)
	{
		lrSize = ent.size[0];
		fbSize = ent.size[1];
	}
	else
	{
		gi.dprintf("Secret door not at 0,90,180,270!\n");
	}

	if (ent.spawnflags & SEC_MOVE_FORWARD)
		forward *= fbSize;
	else
		forward *= -fbSize;

	if(ent.spawnflags & SEC_MOVE_RIGHT)
		right *= lrSize;
	else
		right *= -lrSize;

	if(ent.spawnflags & SEC_1ST_DOWN)
	{
		ent.moveinfo.start_origin = ent.s.origin + forward;
		ent.moveinfo.end_origin = ent.moveinfo.start_origin + right;
	}
	else
	{
		ent.moveinfo.start_origin = ent.s.origin + right;
		ent.moveinfo.end_origin = ent.moveinfo.start_origin + forward;
	}

	ent.touch = secret_touch;
	ent.blocked = secret_blocked;
	ent.use = fd_secret_use;
	ent.moveinfo.speed = 50f;
	ent.moveinfo.accel = 50f;
	ent.moveinfo.decel = 50f;

	if (!ent.targetname || ent.spawnflags & SEC_YES_SHOOT)
	{
		ent.health = 1;
		ent.max_health = ent.health;
		ent.takedamage = true;
		ent.die = fd_secret_killed;
	}
	if (!ent.wait)
		ent.wait = 5f;          // 5 seconds before closing

	gi.linkentity(ent);
}

// ==================================================

enumflags : int
{
	FWALL_START_ON
};

static void(entity self) force_wall_think =
{
	if(!self.wait)
	{
		gi.WriteByte (svc_temp_entity);
		gi.WriteByte (TE_FORCEWALL);
		gi.WritePosition (self.pos1);
		gi.WritePosition (self.pos2);
		gi.WriteByte  (self.style);
		gi.multicast (self.offset, MULTICAST_PVS);
	}

	self.think = force_wall_think;
	self.nextthink = level.framenum + 1;
}

static void(entity self, entity other, entity cactivator) force_wall_use =
{
	if(!self.wait)
	{
		self.wait = 1f;
		self.think = 0;
		self.nextthink = 0;
		self.solid = SOLID_NOT;
		gi.linkentity(self);
	}
	else
	{
		self.wait = 0;
		self.think = force_wall_think;
		self.nextthink = level.framenum + 1;
		self.solid = SOLID_BSP;
		KillBox(self);		// Is this appropriate?
		gi.linkentity (self);
	}
}

/*QUAKED func_force_wall (1 0 1) ? start_on
A vertical particle force wall. Turns on and solid when triggered.
If someone is in the force wall when it turns on, they're telefragged.

start_on - forcewall begins activated. triggering will turn it off.
style - color of particles to use.
	208: green, 240: red, 241: blue, 224: orange
*/
API_FUNC static void(entity ent) SP_func_force_wall =
{
	gi.setmodel (ent, ent.model);

	ent.offset[0] = (ent.absmax[0] + ent.absmin[0]) / 2;
	ent.offset[1] = (ent.absmax[1] + ent.absmin[1]) / 2;
	ent.offset[2] = (ent.absmax[2] + ent.absmin[2]) / 2;

	ent.pos1[2] = ent.absmax[2];
	ent.pos2[2] = ent.absmax[2];
	if(ent.size[0] > ent.size[1])
	{
		ent.pos1[0] = ent.absmin[0];
		ent.pos2[0] = ent.absmax[0];
		ent.pos1[1] = ent.offset[1];
		ent.pos2[1] = ent.offset[1];
	}
	else
	{
		ent.pos1[0] = ent.offset[0];
		ent.pos2[0] = ent.offset[0];
		ent.pos1[1] = ent.absmin[1];
		ent.pos2[1] = ent.absmax[1];
	}
	
	if(!ent.style)
		ent.style = 208;

	ent.movetype = MOVETYPE_NONE;
	ent.wait = 1f;

	if(ent.spawnflags & FWALL_START_ON)
	{
		ent.solid = SOLID_BSP;
		ent.think = force_wall_think;
		ent.nextthink = level.framenum + 1;
	}
	else
		ent.solid = SOLID_NOT;

	ent.use = force_wall_use;

	ent.svflags = SVF_NOCLIENT;
	
	gi.linkentity(ent);
}

enumflags : int
{
	PLAT2_TOGGLE	= 2,
	PLAT2_TOP,
	PLAT2_TRIGGER_TOP,
	PLAT2_TRIGGER_BOTTOM,
	PLAT2_BOX_LIFT
};

// ==========================================
// PLAT 2
// ==========================================
enumflags : int
{
	PLAT2_CALLED,
	PLAT2_MOVING,
	PLAT2_WAITING
};

static void(entity ent) plat2_go_down;
static void(entity ent) plat2_go_up;

void(entity ent) plat2_spawn_danger_area =
{
	vector cmins, cmaxs;

	cmins = ent.mins;
	cmaxs = ent.maxs;
	cmaxs[2] = ent.mins[2] + 64f;

	SpawnBadArea(cmins, cmaxs, 0, ent);
}

void(entity ent) plat2_kill_danger_area =
{
	entity t = world;

	while ((t = G_Find (t, classname, "bad_area")))
		if (t.owner == ent)
			G_FreeEdict(t);
}

static void(entity ent) plat2_hit_top =
{
	if (!(ent.flags & FL_TEAMSLAVE))
	{
		if (ent.moveinfo.sound_end)
			gi.sound (ent, CHAN_NO_PHS_ADD+CHAN_VOICE, ent.moveinfo.sound_end, 1, ATTN_STATIC, 0);
		ent.s.sound = 0;
	}
	ent.moveinfo.state = STATE_TOP;

	if(ent.plat2flags & PLAT2_CALLED)
	{
		ent.plat2flags = PLAT2_WAITING;
		if(!(ent.spawnflags & PLAT2_TOGGLE))
		{
			ent.think = plat2_go_down;
			ent.nextthink = level.framenum + (int)(5.0 * BASE_FRAMERATE);
		}
		if(deathmatch.intVal)
			ent.last_move_framenum = level.framenum - (int)(1.0 * BASE_FRAMERATE);
		else
			ent.last_move_framenum = level.framenum - (int)(2.0 * BASE_FRAMERATE);
	}
	else if(!(ent.spawnflags & PLAT2_TOP) && !(ent.spawnflags & PLAT2_TOGGLE))
	{
		ent.plat2flags = 0;
		ent.think = plat2_go_down;
		ent.nextthink = level.framenum + (int)(2.0 * BASE_FRAMERATE);
		ent.last_move_framenum = level.framenum;
	}
	else
	{
		ent.plat2flags = 0;
		ent.last_move_framenum = level.framenum;
	}

	G_UseTargets (ent, ent);
}

static void(entity ent) plat2_hit_bottom =
{
	if (!(ent.flags & FL_TEAMSLAVE))
	{
		if (ent.moveinfo.sound_end)
			gi.sound (ent, CHAN_NO_PHS_ADD+CHAN_VOICE, ent.moveinfo.sound_end, 1, ATTN_STATIC, 0);
		ent.s.sound = 0;
	}
	ent.moveinfo.state = STATE_BOTTOM;
	
	if(ent.plat2flags & PLAT2_CALLED)
	{
		ent.plat2flags = PLAT2_WAITING;
		if(!(ent.spawnflags & PLAT2_TOGGLE))
		{
			ent.think = plat2_go_up;
			ent.nextthink = level.framenum + (int)(5.0 * BASE_FRAMERATE);
		}
		if(deathmatch.intVal)
			ent.last_move_framenum = level.framenum - (int)(1.0 * BASE_FRAMERATE);
		else
			ent.last_move_framenum = level.framenum - (int)(2.0 * BASE_FRAMERATE);
	}
	else if ((ent.spawnflags & PLAT2_TOP) && !(ent.spawnflags & PLAT2_TOGGLE))
	{
		ent.plat2flags = 0;
		ent.think = plat2_go_up;
		ent.nextthink = level.framenum + (int)(2.0 * BASE_FRAMERATE);
		ent.last_move_framenum = level.framenum;
	}
	else
	{
		ent.plat2flags = 0;
		ent.last_move_framenum = level.framenum;
	}

	plat2_kill_danger_area (ent);
	G_UseTargets (ent, ent);
}

static void(entity ent) plat2_go_down =
{
	if (!(ent.flags & FL_TEAMSLAVE))
	{
		if (ent.moveinfo.sound_start)
			gi.sound (ent, CHAN_NO_PHS_ADD+CHAN_VOICE, ent.moveinfo.sound_start, 1, ATTN_STATIC, 0);
		ent.s.sound = ent.moveinfo.sound_middle;
	}
	ent.moveinfo.state = STATE_DOWN;
	ent.plat2flags |= PLAT2_MOVING;

	Move_Calc (ent, ent.moveinfo.end_origin, plat2_hit_bottom);
}

static void(entity ent) plat2_go_up =
{
	if (!(ent.flags & FL_TEAMSLAVE))
	{
		if (ent.moveinfo.sound_start)
			gi.sound (ent, CHAN_NO_PHS_ADD+CHAN_VOICE, ent.moveinfo.sound_start, 1, ATTN_STATIC, 0);
		ent.s.sound = ent.moveinfo.sound_middle;
	}
	ent.moveinfo.state = STATE_UP;
	ent.plat2flags |= PLAT2_MOVING;

	plat2_spawn_danger_area(ent);

	Move_Calc (ent, ent.moveinfo.start_origin, plat2_hit_top);
}

static void(entity ent, entity other) plat2_operate =
{
	int	otherState;
	float	pauseTime;
	float	platCenter;
	entity trigger = ent;
	ent = ent.enemy;	// now point at the plat, not the trigger

	if (ent.plat2flags & PLAT2_MOVING)
		return;

	if ((ent.last_move_framenum + (2 * BASE_FRAMERATE)) > level.framenum)
		return;

	platCenter = (trigger.absmin[2] + trigger.absmax[2]) / 2;

	if(ent.moveinfo.state == STATE_TOP)
	{
		otherState = STATE_TOP;
		if(ent.spawnflags & PLAT2_BOX_LIFT)
		{
			if(platCenter > other.s.origin[2])
				otherState = STATE_BOTTOM;
		}
		else
		{
			if(trigger.absmax[2] > other.s.origin[2])
				otherState = STATE_BOTTOM;
		}
	}
	else
	{
		otherState = STATE_BOTTOM;
		if(other.s.origin[2] > platCenter)
			otherState = STATE_TOP;
	}

	ent.plat2flags = PLAT2_MOVING;

	if(deathmatch.intVal)
		pauseTime = 0.3;
	else
		pauseTime = 0.5;

	if(ent.moveinfo.state != otherState)
	{
		ent.plat2flags |= PLAT2_CALLED;
		pauseTime = 0.1;
	}

	ent.last_move_framenum = level.framenum;
	
	if (ent.moveinfo.state == STATE_BOTTOM)
		ent.think = plat2_go_up;
	else
		ent.think = plat2_go_down;

	ent.nextthink = level.framenum + (int)(pauseTime * BASE_FRAMERATE);
}

static void(entity ent, entity other, vector plane, csurface_t surf) Touch_Plat_Center2 =
{
	if (other.health <= 0)
		return;

	// PMM - don't let non-monsters activate plat2s
	if ((!(other.svflags & SVF_MONSTER)) && (!other.is_client))
		return;
	
	plat2_operate(ent, other);
}

static void(entity self, entity other) plat2_blocked =
{
	if (!(other.svflags & SVF_MONSTER) && (!other.is_client))
	{
		// give it a chance to go away on it's own terms (like gibs)
		T_Damage (other, self, self, vec3_origin, other.s.origin, vec3_origin, 100000, 1, 0, MOD_CRUSH);
		// if it's still there, nuke it
		if(other && other.inuse)
			BecomeExplosion1 (other);
		return;
	}

	// gib dead things
	if(other.health < 1)
		T_Damage(other, self, self, vec3_origin, other.s.origin, vec3_origin, 100, 1, 0, MOD_CRUSH);

	T_Damage (other, self, self, vec3_origin, other.s.origin, vec3_origin, self.dmg, 1, 0, MOD_CRUSH);

	if (self.moveinfo.state == STATE_UP)
		plat2_go_down (self);
	else if (self.moveinfo.state == STATE_DOWN)
		plat2_go_up (self);
}

static void(entity ent, entity other, entity cactivator) Use_Plat2  =
{ 
	entity	trigger;
	int	i;

	if(ent.moveinfo.state > STATE_BOTTOM)
		return;
	if((ent.last_move_framenum + (2 * BASE_FRAMERATE)) > level.framenum)
		return;

	for (i = 1; i < globals.num_edicts; i++)
	{
		trigger = itoe(i);
		if (!trigger.inuse)
			continue;
		if (trigger.touch == Touch_Plat_Center2)
		{
			if (trigger.enemy == ent)
			{
				plat2_operate (trigger, cactivator);
				return;
			}
		} 
	}
}

static void(entity ent, entity other, entity cactivator) plat2_activate =
{
	entity trigger;

	ent.use = Use_Plat2;

	trigger = plat_spawn_inside_trigger (ent);	// the "start moving" trigger	

	trigger.maxs[0]+=10;
	trigger.maxs[1]+=10;
	trigger.mins[0]-=10;
	trigger.mins[1]-=10;

	gi.linkentity (trigger);
	
	trigger.touch = Touch_Plat_Center2;		// Override trigger touch function

	plat2_go_down(ent);
}

/*QUAKED func_plat2 (0 .5 .8) ? PLAT_LOW_TRIGGER PLAT2_TOGGLE PLAT2_TOP PLAT2_TRIGGER_TOP PLAT2_TRIGGER_BOTTOM BOX_LIFT
speed	default 150

PLAT_LOW_TRIGGER - creates a short trigger field at the bottom
PLAT2_TOGGLE - plat will not return to default position.
PLAT2_TOP - plat's default position will the the top.
PLAT2_TRIGGER_TOP - plat will trigger it's targets each time it hits top
PLAT2_TRIGGER_BOTTOM - plat will trigger it's targets each time it hits bottom
BOX_LIFT - this indicates that the lift is a box, rather than just a platform

Plats are always drawn in the extended position, so they will light correctly.

If the plat is the target of another trigger or button, it will start out disabled in the extended position until it is trigger, when it will lower and become a normal plat.

"speed"	overrides default 200.
"accel" overrides default 500
"lip"	no default

If the "height" key is set, that will determine the amount the plat moves, instead of being implicitly determoveinfoned by the model's height.

*/
API_FUNC static void(entity ent) SP_func_plat2 =
{
	entity trigger;

	ent.s.angles = vec3_origin;
	ent.solid = SOLID_BSP;
	ent.movetype = MOVETYPE_PUSH;

	gi.setmodel (ent, ent.model);

	ent.blocked = plat2_blocked;

	if (!ent.speed)
		ent.speed = 20f;
	else
		ent.speed *= 0.1;

	if (!ent.accel)
		ent.accel = 5f;
	else
		ent.accel *= 0.1;

	if (!ent.decel)
		ent.decel = 5f;
	else
		ent.decel *= 0.1;

	if (deathmatch.intVal)
	{
		ent.speed *= 2;
		ent.accel *= 2;
		ent.decel *= 2;
	}


	//PMM Added to kill things it's being blocked by 
	if (!ent.dmg)
		ent.dmg = 2;

	// pos1 is the top position, pos2 is the bottom
	ent.pos1 = ent.s.origin;
	ent.pos2 = ent.s.origin;

	if (st.height)
		ent.pos2[2] -= (st.height - st.lip);
	else
		ent.pos2[2] -= (ent.maxs[2] - ent.mins[2]) - st.lip;

	ent.moveinfo.state = STATE_TOP;

	if(ent.targetname)
	{
		ent.use = plat2_activate;
	}
	else
	{
		ent.use = Use_Plat2;

		trigger = plat_spawn_inside_trigger (ent);	// the "start moving" trigger	

		// PGM - debugging??
		trigger.maxs[0]+=10;
		trigger.maxs[1]+=10;
		trigger.mins[0]-=10;
		trigger.mins[1]-=10;

		gi.linkentity (trigger);

		trigger.touch = Touch_Plat_Center2;		// Override trigger touch function

		if(!(ent.spawnflags & PLAT2_TOP))
		{
			ent.s.origin = ent.pos2;
			ent.moveinfo.state = STATE_BOTTOM;
		}	
	}

	gi.linkentity (ent);

	ent.moveinfo.speed = ent.speed;
	ent.moveinfo.accel = ent.accel;
	ent.moveinfo.decel = ent.decel;
	ent.moveinfo.wait = ent.wait;
	ent.moveinfo.start_origin = ent.pos1;
	ent.moveinfo.start_angles = ent.s.angles;
	ent.moveinfo.end_origin = ent.pos2;
	ent.moveinfo.end_angles = ent.s.angles;

	ent.moveinfo.sound_start = gi.soundindex ("plats/pt1_strt.wav");
	ent.moveinfo.sound_middle = gi.soundindex ("plats/pt1_mid.wav");
	ent.moveinfo.sound_end = gi.soundindex ("plats/pt1_end.wav");
}

#endif