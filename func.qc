/*
=========================================================

  PLATS

  movement options:

  linear
  smooth start, hard stop
  smooth start, smooth stop

  start
  end
  acceleration
  speed
  deceleration
  begin sound
  end sound
  target fired when reaching end
  wait at end

  object characteristics that use move segments
  ---------------------------------------------
  movetype_push, or movetype_stop
  action when touched
  action when blocked
  action when used
	disabled?
  auto trigger spawning


=========================================================
*/

const int PLAT_LOW_TRIGGER	= 1;

const int DOOR_START_OPEN	= 1;
const int DOOR_REVERSE		= 2;
const int DOOR_CRUSHER		= 4;
const int DOOR_NOMONSTER	= 8;
const int DOOR_TOGGLE		= 32;
const int DOOR_X_AXIS		= 64;
const int DOOR_Y_AXIS		= 128;


//
// Support routines for movement (changes in origin using velocity)
//

static void(entity ent) Move_Done =
{
	VectorClear(ent->velocity);
	ent->moveinfo.endfunc(ent);
}

static void(entity ent) Move_Final =
{
	if (ent->moveinfo.remaining_distance == 0) {
		Move_Done(ent);
		return;
	}

	VectorScale(ent->moveinfo.dir, ent->moveinfo.remaining_distance / FRAMETIME, ent->velocity);

	ent->think = Move_Done;
	ent->nextthink = level.framenum + 1;
}

static void(entity ent) Move_Begin =
{
	float   frames;

	if ((ent->moveinfo.speed * FRAMETIME) >= ent->moveinfo.remaining_distance) {
		Move_Final(ent);
		return;
	}
	VectorScale(ent->moveinfo.dir, ent->moveinfo.speed, ent->velocity);
	frames = floorf((ent->moveinfo.remaining_distance / ent->moveinfo.speed) / FRAMETIME);
	ent->moveinfo.remaining_distance -= frames * ent->moveinfo.speed * FRAMETIME;
	ent->nextthink = level.framenum + (int)frames;
	ent->think = Move_Final;
}

// from func.qc
static void(entity ent) Think_AccelMove;

static void(entity ent, vector dest, void(entity) func) Move_Calc =
{
	VectorClear(ent->velocity);
	VectorSubtract(dest, ent->s.origin, ent->moveinfo.dir);
	ent->moveinfo.remaining_distance = VectorNormalize(ent->moveinfo.dir);
	ent->moveinfo.endfunc = func;

	if (ent->moveinfo.speed == ent->moveinfo.accel && ent->moveinfo.speed == ent->moveinfo.decel) {
		if (level.current_entity == ((ent->flags & FL_TEAMSLAVE) ? ent->teammaster : ent)) {
			Move_Begin(ent);
		} else {
			ent->nextthink = level.framenum + 1;
			ent->think = Move_Begin;
		}
	} else {
		// accelerative
		ent->moveinfo.current_speed = 0;
		ent->think = Think_AccelMove;
		ent->nextthink = level.framenum + 1;
	}
}


//
// Support routines for angular movement (changes in angle using avelocity)
//

static void(entity ent) AngleMove_Done =
{
	VectorClear(ent->avelocity);
	ent->moveinfo.endfunc(ent);
}

static void(entity ent) AngleMove_Final =
{
	vector	move;

	if (ent->moveinfo.state == STATE_UP)
		VectorSubtract(ent->moveinfo.end_angles, ent->s.angles, move);
	else
		VectorSubtract(ent->moveinfo.start_angles, ent->s.angles, move);

	if (VectorEmpty(move)) {
		AngleMove_Done(ent);
		return;
	}

	VectorScale(move, 1.0f / FRAMETIME, ent->avelocity);

	ent->think = AngleMove_Done;
	ent->nextthink = level.framenum + 1;
}

static void(entity ent) AngleMove_Begin =
{
	vector	destdelta;
	float	len;
	float	traveltime;
	float	frames;

	// set destdelta to the vector needed to move
	if (ent->moveinfo.state == STATE_UP)
		VectorSubtract(ent->moveinfo.end_angles, ent->s.angles, destdelta);
	else
		VectorSubtract(ent->moveinfo.start_angles, ent->s.angles, destdelta);

	// calculate length of vector
	len = VectorLength(destdelta);

	// divide by speed to get time to reach dest
	traveltime = len / ent->moveinfo.speed;

	if (traveltime < FRAMETIME) {
		AngleMove_Final(ent);
		return;
	}

	frames = floorf(traveltime / FRAMETIME);

	// scale the destdelta vector by the time spent traveling to get velocity
	VectorScale(destdelta, 1.0f / traveltime, ent->avelocity);

	// set nextthink to trigger a think when dest is reached
	ent->nextthink = level.framenum + (int)frames;
	ent->think = AngleMove_Final;
}

static void(entity ent, void(entity) func) AngleMove_Calc =
{
	VectorClear(ent->avelocity);
	ent->moveinfo.endfunc = func;
	if (level.current_entity == ((ent->flags & FL_TEAMSLAVE) ? ent->teammaster : ent)) {
		AngleMove_Begin(ent);
	} else {
		ent->nextthink = level.framenum + 1;
		ent->think = AngleMove_Begin;
	}
}


/*
==============
Think_AccelMove

The team has completed a frame of movement, so
change the speed for the next frame
==============
*/
#define AccelerationDistance(target, rate)  (target * ((target / rate) + 1) / 2)

static void(entity ent) plat_CalcAcceleratedMove =
{
	float	accel_dist;
	float	decel_dist;

	ent.moveinfo->move_speed = ent.moveinfo->speed;

	if (ent.moveinfo->remaining_distance < ent.moveinfo->accel) {
		ent.moveinfo->current_speed = ent.moveinfo->remaining_distance;
		return;
	}

	accel_dist = AccelerationDistance(ent.moveinfo->speed, ent.moveinfo->accel);
	decel_dist = AccelerationDistance(ent.moveinfo->speed, ent.moveinfo->decel);

	if ((ent.moveinfo->remaining_distance - accel_dist - decel_dist) < 0) {
		float   f;

		f = (ent.moveinfo->accel + ent.moveinfo->decel) / (ent.moveinfo->accel * ent.moveinfo->decel);
		ent.moveinfo->move_speed = (-2 + sqrtf(4 - 4 * f * (-2 * ent.moveinfo->remaining_distance))) / (2 * f);
		decel_dist = AccelerationDistance(ent.moveinfo->move_speed, ent.moveinfo->decel);
	}

	ent.moveinfo->decel_distance = decel_dist;
}

static void(entity ent) plat_Accelerate =
{
	// are we decelerating?
	if (ent.moveinfo->remaining_distance <= ent.moveinfo->decel_distance) {
		if (ent.moveinfo->remaining_distance < ent.moveinfo->decel_distance) {
			if (ent.moveinfo->next_speed) {
				ent.moveinfo->current_speed = ent.moveinfo->next_speed;
				ent.moveinfo->next_speed = 0;
				return;
			}
			if (ent.moveinfo->current_speed > ent.moveinfo->decel)
				ent.moveinfo->current_speed -= ent.moveinfo->decel;
		}
		return;
	}

	// are we at full speed and need to start decelerating during this move?
	if (ent.moveinfo->current_speed == ent.moveinfo->move_speed)
		if ((ent.moveinfo->remaining_distance - ent.moveinfo->current_speed) < ent.moveinfo->decel_distance) {
			float	p1_distance;
			float	p2_distance;
			float	distance;

			p1_distance = ent.moveinfo->remaining_distance - ent.moveinfo->decel_distance;
			p2_distance = ent.moveinfo->move_speed * (1.0f - (p1_distance / ent.moveinfo->move_speed));
			distance = p1_distance + p2_distance;
			ent.moveinfo->current_speed = ent.moveinfo->move_speed;
			ent.moveinfo->next_speed = ent.moveinfo->move_speed - ent.moveinfo->decel * (p2_distance / distance);
			return;
		}

	// are we accelerating?
	if (ent.moveinfo->current_speed < ent.moveinfo->speed) {
		float	old_speed;
		float	p1_distance;
		float	p1_speed;
		float	p2_distance;
		float	distance;

		old_speed = ent.moveinfo->current_speed;

		// figure simple acceleration up to move_speed
		ent.moveinfo->current_speed += ent.moveinfo->accel;
		if (ent.moveinfo->current_speed > ent.moveinfo->speed)
			ent.moveinfo->current_speed = ent.moveinfo->speed;

		// are we accelerating throughout this entire move?
		if ((ent.moveinfo->remaining_distance - ent.moveinfo->current_speed) >= ent.moveinfo->decel_distance)
			return;

		// during this move we will accelrate from current_speed to move_speed
		// and cross over the decel_distance; figure the average speed for the
		// entire move
		p1_distance = ent.moveinfo->remaining_distance - ent.moveinfo->decel_distance;
		p1_speed = (old_speed + ent.moveinfo->move_speed) / 2.0f;
		p2_distance = ent.moveinfo->move_speed * (1.0f - (p1_distance / p1_speed));
		distance = p1_distance + p2_distance;
		ent.moveinfo->current_speed = (p1_speed * (p1_distance / distance)) + (ent.moveinfo->move_speed * (p2_distance / distance));
		ent.moveinfo->next_speed = ent.moveinfo->move_speed - ent.moveinfo->decel * (p2_distance / distance);
		return;
	}

	// we are at constant velocity (move_speed)
	return;
}

static void(entity ent) Think_AccelMove =
{
	ent->moveinfo.remaining_distance -= ent->moveinfo.current_speed;

	if (ent->moveinfo.current_speed == 0)       // starting or blocked
		plat_CalcAcceleratedMove(ent);

	plat_Accelerate(ent);

	// will the entire move complete on next frame?
	if (ent->moveinfo.remaining_distance <= ent->moveinfo.current_speed) {
		Move_Final(ent);
		return;
	}

	VectorScale(ent->moveinfo.dir, ent->moveinfo.current_speed * 10, ent->velocity);
	ent->nextthink = level.framenum + 1;
	ent->think = Think_AccelMove;
}


static void(entity ent) plat_go_down;

static void(entity ent) plat_hit_top =
{
	if (!(ent->flags & FL_TEAMSLAVE)) {
		if (ent->moveinfo.sound_end)
			gi.sound(ent, CHAN_NO_PHS_ADD + CHAN_VOICE, ent->moveinfo.sound_end, 1, ATTN_STATIC, 0);
		ent->s.sound = 0;
	}
	ent->moveinfo.state = STATE_TOP;

	ent->think = plat_go_down;
	ent->nextthink = level.framenum + 3 * BASE_FRAMERATE;
}

static void(entity ent) plat_hit_bottom =
{
	if (!(ent->flags & FL_TEAMSLAVE)) {
		if (ent->moveinfo.sound_end)
			gi.sound(ent, CHAN_NO_PHS_ADD + CHAN_VOICE, ent->moveinfo.sound_end, 1, ATTN_STATIC, 0);
		ent->s.sound = 0;
	}
	ent->moveinfo.state = STATE_BOTTOM;
}

static void(entity ent) plat_go_down =
{
	if (!(ent->flags & FL_TEAMSLAVE)) {
		if (ent->moveinfo.sound_start)
			gi.sound(ent, CHAN_NO_PHS_ADD + CHAN_VOICE, ent->moveinfo.sound_start, 1, ATTN_STATIC, 0);
		ent->s.sound = ent->moveinfo.sound_middle;
	}
	ent->moveinfo.state = STATE_DOWN;
	Move_Calc(ent, ent->moveinfo.end_origin, plat_hit_bottom);
}

static void(entity ent) plat_go_up =
{
	if (!(ent->flags & FL_TEAMSLAVE)) {
		if (ent->moveinfo.sound_start)
			gi.sound(ent, CHAN_NO_PHS_ADD + CHAN_VOICE, ent->moveinfo.sound_start, 1, ATTN_STATIC, 0);
		ent->s.sound = ent->moveinfo.sound_middle;
	}
	ent->moveinfo.state = STATE_UP;
	Move_Calc(ent, ent->moveinfo.start_origin, plat_hit_top);
}

static void(entity self, entity other) plat_blocked =
{
	if (!(other->svflags & SVF_MONSTER) && (!other->is_client)) {
		// give it a chance to go away on it's own terms (like gibs)
		T_Damage(other, self, self, vec3_origin, other->s.origin, vec3_origin, 100000, 1, 0, MOD_CRUSH);
		// if it's still there, nuke it
		if (other)
			BecomeExplosion1(other);
		return;
	}

	T_Damage(other, self, self, vec3_origin, other->s.origin, vec3_origin, self->dmg, 1, 0, MOD_CRUSH);

	if (self->moveinfo.state == STATE_UP)
		plat_go_down(self);
	else if (self->moveinfo.state == STATE_DOWN)
		plat_go_up(self);
}


static void(entity ent, entity other, entity cactivator) Use_Plat =
{
	if (ent->think)
		return;     // already down
	plat_go_down(ent);
}


static void(entity ent, entity other, cplane_t plane, csurface_t surf) Touch_Plat_Center =
{
	if (!other->is_client)
		return;

	if (other->health <= 0)
		return;

	ent = ent->enemy;   // now point at the plat, not the trigger
	if (ent->moveinfo.state == STATE_BOTTOM)
		plat_go_up(ent);
	else if (ent->moveinfo.state == STATE_TOP)
		ent->nextthink = level.framenum + 1 * BASE_FRAMERATE;   // the player is still on the plat, so delay going down
}

static void(entity ent) plat_spawn_inside_trigger =
{
	entity	trigger;
	vector	tmin, tmax;

//
// middle trigger
//
	trigger = G_Spawn();
	trigger->touch = Touch_Plat_Center;
	trigger->movetype = MOVETYPE_NONE;
	trigger->solid = SOLID_TRIGGER;
	trigger->enemy = ent;

	tmin_x = ent->mins_x + 25;
	tmin_y = ent->mins_y + 25;
	tmin_z = ent->mins_z;

	tmax_x = ent->maxs_x - 25;
	tmax_y = ent->maxs_y - 25;
	tmax_z = ent->maxs_z + 8;

	tmin_z = tmax_z - (ent->pos1_z - ent->pos2_z + st.lip);

	if (ent->spawnflags & PLAT_LOW_TRIGGER)
		tmax_z = tmin_z + 8;

	if (tmax_x - tmin_x <= 0) {
		tmin_x = (ent->mins_x + ent->maxs_x) * 0.5f;
		tmax_x = tmin_x + 1;
	}
	if (tmax_y - tmin_y <= 0) {
		tmin_y = (ent->mins_y + ent->maxs_y) * 0.5f;
		tmax_y = tmin_y + 1;
	}

	VectorCopy(tmin, trigger->mins);
	VectorCopy(tmax, trigger->maxs);

	gi.linkentity(trigger);
}


/*QUAKED func_plat (0 .5 .8) ? PLAT_LOW_TRIGGER
speed   default 150

Plats are always drawn in the extended position, so they will light correctly.

If the plat is the target of another trigger or button, it will start out disabled in the extended position until it is trigger, when it will lower and become a normal plat.

"speed" overrides default 200.
"accel" overrides default 500
"lip"   overrides default 8 pixel lip

If the "height" key is set, that will determine the amount the plat moves, instead of being implicitly determoveinfoned by the model's height.

Set "sounds" to one of the following:
1) base fast
2) chain slow
*/
API_FUNC static void(entity ent) SP_func_plat =
{
	VectorClear(ent->s.angles);
	ent->solid = SOLID_BSP;
	ent->movetype = MOVETYPE_PUSH;

	gi.setmodel(ent, ent->model);

	ent->blocked = plat_blocked;

	if (!ent->speed)
		ent->speed = 20f;
	else
		ent->speed *= 0.1f;

	if (!ent->accel)
		ent->accel = 5f;
	else
		ent->accel *= 0.1f;

	if (!ent->decel)
		ent->decel = 5f;
	else
		ent->decel *= 0.1f;

	if (!ent->dmg)
		ent->dmg = 2;

	if (!st.lip)
		st.lip = 8;

	// pos1 is the top position, pos2 is the bottom
	VectorCopy(ent->s.origin, ent->pos1);
	VectorCopy(ent->s.origin, ent->pos2);
	if (st.height)
		ent->pos2_z -= st.height;
	else
		ent->pos2_z -= (ent->maxs_z - ent->mins_z) - st.lip;

	ent->use = Use_Plat;

	plat_spawn_inside_trigger(ent);     // the "start moving" trigger

	if (ent->targetname) {
		ent->moveinfo.state = STATE_UP;
	} else {
		VectorCopy(ent->pos2, ent->s.origin);
		gi.linkentity(ent);
		ent->moveinfo.state = STATE_BOTTOM;
	}

	ent->moveinfo.speed = ent->speed;
	ent->moveinfo.accel = ent->accel;
	ent->moveinfo.decel = ent->decel;
	ent->moveinfo.wait = ent->wait;
	VectorCopy(ent->pos1, ent->moveinfo.start_origin);
	VectorCopy(ent->s.angles, ent->moveinfo.start_angles);
	VectorCopy(ent->pos2, ent->moveinfo.end_origin);
	VectorCopy(ent->s.angles, ent->moveinfo.end_angles);

	ent->moveinfo.sound_start = gi.soundindex("plats/pt1_strt.wav");
	ent->moveinfo.sound_middle = gi.soundindex("plats/pt1_mid.wav");
	ent->moveinfo.sound_end = gi.soundindex("plats/pt1_end.wav");
}

//====================================================================

/*QUAKED func_rotating (0 .5 .8) ? START_ON REVERSE X_AXIS Y_AXIS TOUCH_PAIN STOP ANIMATED ANIMATED_FAST
You need to have an origin brush as part of this entity.  The center of that brush will be
the point around which it is rotated. It will rotate around the Z axis by default.  You can
check either the X_AXIS or Y_AXIS box to change that.

"speed" determines how fast it moves; default value is 100.
"dmg"   damage to inflict when blocked (2 default)

REVERSE will cause the it to rotate in the opposite direction.
STOP mean it will stop moving instead of pushing entities
*/

static void(entity self, entity other) rotating_blocked =
{
	T_Damage(other, self, self, vec3_origin, other->s.origin, vec3_origin, self->dmg, 1, 0, MOD_CRUSH);
}

static void(entity self, entity other, cplane_t plane, csurface_t surf) rotating_touch =
{
	if (!VectorEmpty(self->avelocity))
		T_Damage(other, self, self, vec3_origin, other->s.origin, vec3_origin, self->dmg, 1, 0, MOD_CRUSH);
}

static void(entity self, entity other, entity cactivator) rotating_use =
{
	if (!VectorEmpty(self->avelocity)) {
		self->s.sound = 0;
		VectorClear(self->avelocity);
		self->touch = 0;
	} else {
		self->s.sound = self->moveinfo.sound_middle;
		VectorScale(self->movedir, self->speed, self->avelocity);
		if (self->spawnflags & 16)
			self->touch = rotating_touch;
	}
}

API_FUNC static void(entity ent) SP_func_rotating =
{
	ent->solid = SOLID_BSP;
	if (ent->spawnflags & 32)
		ent->movetype = MOVETYPE_STOP;
	else
		ent->movetype = MOVETYPE_PUSH;

	// set the axis of rotation
	VectorClear(ent->movedir);
	if (ent->spawnflags & 4)
		ent->movedir_z = 1.0f;
	else if (ent->spawnflags & 8)
		ent->movedir_x = 1.0f;
	else // Z_AXIS
		ent->movedir_y = 1.0f;

	// check for reverse rotation
	if (ent->spawnflags & 2)
		VectorNegate(ent->movedir, ent->movedir);

	if (!ent->speed)
		ent->speed = 100f;
	if (!ent->dmg)
		ent->dmg = 2;

//  ent->moveinfo.sound_middle = "doors/hydro1.wav";

	ent->use = rotating_use;
	if (ent->dmg)
		ent->blocked = rotating_blocked;

	if (ent->spawnflags & 1)
		ent->use(ent, 0, 0);

	if (ent->spawnflags & 64)
		ent->s.effects |= EF_ANIM_ALL;
	if (ent->spawnflags & 128)
		ent->s.effects |= EF_ANIM_ALLFAST;

	gi.setmodel(ent, ent->model);
	gi.linkentity(ent);
}

/*
======================================================================

BUTTONS

======================================================================
*/

/*QUAKED func_button (0 .5 .8) ?
When a button is touched, it moves some distance in the direction of it's angle, triggers all of it's targets, waits some time, then returns to it's original position where it can be triggered again.

"angle"     determines the opening direction
"target"    all entities with a matching targetname will be used
"speed"     override the default 40 speed
"wait"      override the default 1 second wait (-1 = never return)
"lip"       override the default 4 pixel lip remaining at end of move
"health"    if set, the button must be killed instead of touched
"sounds"
1) silent
2) steam metal
3) wooden clunk
4) metallic click
5) in-out
*/

static void(entity self) button_done =
{
	self->moveinfo.state = STATE_BOTTOM;
	self->s.effects &= ~EF_ANIM23;
	self->s.effects |= EF_ANIM01;
}

static void(entity self) button_return =
{
	self->moveinfo.state = STATE_DOWN;

	Move_Calc(self, self->moveinfo.start_origin, button_done);

	self->s.frame = 0;

	if (self->health)
		self->takedamage = DAMAGE_YES;
}

static void(entity self) button_wait =
{
	self->moveinfo.state = STATE_TOP;
	self->s.effects &= ~EF_ANIM01;
	self->s.effects |= EF_ANIM23;

	G_UseTargets(self, self->activator);
	self->s.frame = 1;
	if (self->moveinfo.wait >= 0) {
		self->nextthink = level.framenum + (int)(self->moveinfo.wait * BASE_FRAMERATE);
		self->think = button_return;
	}
}

static void(entity self) button_fire =
{
	if (self->moveinfo.state == STATE_UP || self->moveinfo.state == STATE_TOP)
		return;

	self->moveinfo.state = STATE_UP;
	if (self->moveinfo.sound_start && !(self->flags & FL_TEAMSLAVE))
		gi.sound(self, CHAN_NO_PHS_ADD + CHAN_VOICE, self->moveinfo.sound_start, 1, ATTN_STATIC, 0);
	Move_Calc(self, self->moveinfo.end_origin, button_wait);
}

static void(entity self, entity other, entity cactivator) button_use =
{
	self->activator = cactivator;
	button_fire(self);
}

static void(entity self, entity other, cplane_t plane, csurface_t surf) button_touch =
{
	if (!other->is_client)
		return;

	if (other->health <= 0)
		return;

	self->activator = other;
	button_fire(self);
}

static void(entity self, entity inflictor, entity attacker, int damage, vector point) button_killed =
{
	self->activator = attacker;
	self->health = self->max_health;
	self->takedamage = DAMAGE_NO;
	button_fire(self);
}

API_FUNC static void(entity ent) SP_func_button =
{
	vector	abs_movedir;
	float	dist;

	G_SetMovedir(ent->s.angles, ent->movedir);
	ent->movetype = MOVETYPE_STOP;
	ent->solid = SOLID_BSP;
	gi.setmodel(ent, ent->model);

	if (ent->sounds != 1)
		ent->moveinfo.sound_start = gi.soundindex("switches/butn2.wav");

	if (!ent->speed)
		ent->speed = 40f;
	if (!ent->accel)
		ent->accel = ent->speed;
	if (!ent->decel)
		ent->decel = ent->speed;

	if (!ent->wait)
		ent->wait = 3f;
	if (!st.lip)
		st.lip = 4;

	VectorCopy(ent->s.origin, ent->pos1);
	abs_movedir_x = fabsf(ent->movedir_x);
	abs_movedir_y = fabsf(ent->movedir_y);
	abs_movedir_z = fabsf(ent->movedir_z);
	dist = abs_movedir_x * ent->size_x + abs_movedir_y * ent->size_y + abs_movedir_z * ent->size_z - st.lip;
	VectorMA(ent->pos1, dist, ent->movedir, ent->pos2);

	ent->use = button_use;
	ent->s.effects |= EF_ANIM01;

	if (ent->health) {
		ent->max_health = ent->health;
		ent->die = button_killed;
		ent->takedamage = DAMAGE_YES;
	} else if (! ent->targetname)
		ent->touch = button_touch;

	ent->moveinfo.state = STATE_BOTTOM;

	ent->moveinfo.speed = ent->speed;
	ent->moveinfo.accel = ent->accel;
	ent->moveinfo.decel = ent->decel;
	ent->moveinfo.wait = ent->wait;
	VectorCopy(ent->pos1, ent->moveinfo.start_origin);
	VectorCopy(ent->s.angles, ent->moveinfo.start_angles);
	VectorCopy(ent->pos2, ent->moveinfo.end_origin);
	VectorCopy(ent->s.angles, ent->moveinfo.end_angles);

	gi.linkentity(ent);
}

/*
======================================================================

DOORS

  spawn a trigger surrounding the entire team unless it is
  already targeted by another

======================================================================
*/

/*QUAKED func_door (0 .5 .8) ? START_OPEN x CRUSHER NOMONSTER ANIMATED TOGGLE ANIMATED_FAST
TOGGLE      wait in both the start and end states for a trigger event.
START_OPEN  the door to moves to its destination when spawned, and operate in reverse.  It is used to temporarily or permanently close off an area when triggered (not useful for touch or takedamage doors).
NOMONSTER   monsters will not trigger this door

"message"   is printed when the door is touched if it is a trigger door and it hasn't been fired yet
"angle"     determines the opening direction
"targetname" if set, no touch field will be spawned and a remote button or trigger field activates the door.
"health"    if set, door must be shot open
"speed"     movement speed (100 default)
"wait"      wait before returning (3 default, -1 = never return)
"lip"       lip remaining at end of move (8 default)
"dmg"       damage to inflict when blocked (2 default)
"sounds"
1)  silent
2)  light
3)  medium
4)  heavy
*/

static void(entity self, bool open) door_use_areaportals =
{
	entity t = null_entity;

	if (!self->target)
		return;

	while ((t = G_Find(t, targetname, self->target)) != null_entity) {
		if (stricmp(t->classname, "func_areaportal") == 0) {
			gi.SetAreaPortalState(t->style, open);
		}
	}
}

static void(entity self) door_go_down;

static void(entity self) door_hit_top =
{
	if (!(self->flags & FL_TEAMSLAVE)) {
		if (self->moveinfo.sound_end)
			gi.sound(self, CHAN_NO_PHS_ADD + CHAN_VOICE, self->moveinfo.sound_end, 1, ATTN_STATIC, 0);
		self->s.sound = 0;
	}
	self->moveinfo.state = STATE_TOP;
	if (self->spawnflags & DOOR_TOGGLE)
		return;
	if (self->moveinfo.wait >= 0) {
		self->think = door_go_down;
		self->nextthink = level.framenum + (int)(self->moveinfo.wait * BASE_FRAMERATE);
	}
}

static void(entity self) door_hit_bottom =
{
	if (!(self->flags & FL_TEAMSLAVE)) {
		if (self->moveinfo.sound_end)
			gi.sound(self, CHAN_NO_PHS_ADD + CHAN_VOICE, self->moveinfo.sound_end, 1, ATTN_STATIC, 0);
		self->s.sound = 0;
	}
	self->moveinfo.state = STATE_BOTTOM;
	door_use_areaportals(self, false);
}

static void(entity self) door_go_down =
{
	if (!(self->flags & FL_TEAMSLAVE)) {
		if (self->moveinfo.sound_start)
			gi.sound(self, CHAN_NO_PHS_ADD + CHAN_VOICE, self->moveinfo.sound_start, 1, ATTN_STATIC, 0);
		self->s.sound = self->moveinfo.sound_middle;
	}
	if (self->max_health) {
		self->takedamage = DAMAGE_YES;
		self->health = self->max_health;
	}

	self->moveinfo.state = STATE_DOWN;
	if (self->classname == "func_door")
		Move_Calc(self, self->moveinfo.start_origin, door_hit_bottom);
	else if (self->classname == "func_door_rotating")
		AngleMove_Calc(self, door_hit_bottom);
}

static void(entity self, entity cactivator) door_go_up =
{
	if (self->moveinfo.state == STATE_UP)
		return;     // already going up

	if (self->moveinfo.state == STATE_TOP) {
		// reset top wait time
		if (self->moveinfo.wait >= 0)
			self->nextthink = level.framenum + (int)(self->moveinfo.wait * BASE_FRAMERATE);
		return;
	}

	if (!(self->flags & FL_TEAMSLAVE)) {
		if (self->moveinfo.sound_start)
			gi.sound(self, CHAN_NO_PHS_ADD + CHAN_VOICE, self->moveinfo.sound_start, 1, ATTN_STATIC, 0);
		self->s.sound = self->moveinfo.sound_middle;
	}
	self->moveinfo.state = STATE_UP;
	if (self->classname == "func_door")
		Move_Calc(self, self->moveinfo.end_origin, door_hit_top);
	else if (self->classname == "func_door_rotating")
		AngleMove_Calc(self, door_hit_top);

	G_UseTargets(self, cactivator);
	door_use_areaportals(self, true);
}

static void(entity self, entity other, entity cactivator) door_use =
{
	entity ent;

	if (self->flags & FL_TEAMSLAVE)
		return;

	if (self->spawnflags & DOOR_TOGGLE) {
		if (self->moveinfo.state == STATE_UP || self->moveinfo.state == STATE_TOP) {
			// trigger all paired doors
			for (ent = self ; ent ; ent = ent->teamchain) {
				ent->message = 0;
				ent->touch = 0;
				door_go_down(ent);
			}
			return;
		}
	}

	// trigger all paired doors
	for (ent = self ; ent ; ent = ent->teamchain) {
		ent->message = 0;
		ent->touch = 0;
		door_go_up(ent, cactivator);
	}
}

static void(entity self, entity other, cplane_t plane, csurface_t surf) Touch_DoorTrigger =
{
	if (other->health <= 0)
		return;

	if (!(other->svflags & SVF_MONSTER) && (!other->is_client))
		return;

	if ((self->owner->spawnflags & DOOR_NOMONSTER) && (other->svflags & SVF_MONSTER))
		return;

	if (level.framenum < self->touch_debounce_framenum)
		return;
	self->touch_debounce_framenum = level.framenum + (int)(1.0f * BASE_FRAMERATE);

	door_use(self->owner, other, other);
}

static void(entity self) Think_CalcMoveSpeed =
{
	entity	ent;
	float	min;
	float	time;
	float	newspeed;
	float	ratio;
	float	dist;

	if (self->flags & FL_TEAMSLAVE)
		return;     // only the team master does this

	// find the smallest distance any member of the team will be moving
	min = fabsf(self->moveinfo.distance);
	for (ent = self->teamchain; ent; ent = ent->teamchain) {
		dist = fabsf(ent->moveinfo.distance);
		if (dist < min)
			min = dist;
	}

	time = min / self->moveinfo.speed;

	// adjust speeds so they will all complete at the same time
	for (ent = self; ent; ent = ent->teamchain) {
		newspeed = fabsf(ent->moveinfo.distance) / time;
		ratio = newspeed / ent->moveinfo.speed;
		if (ent->moveinfo.accel == ent->moveinfo.speed)
			ent->moveinfo.accel = newspeed;
		else
			ent->moveinfo.accel *= ratio;
		if (ent->moveinfo.decel == ent->moveinfo.speed)
			ent->moveinfo.decel = newspeed;
		else
			ent->moveinfo.decel *= ratio;
		ent->moveinfo.speed = newspeed;
	}
}

static void(entity ent) Think_SpawnDoorTrigger =
{
	entity	other;
	vector	cmins, cmaxs;

	if (ent->flags & FL_TEAMSLAVE)
		return;     // only the team leader spawns a trigger

	VectorCopy(ent->absmin, cmins);
	VectorCopy(ent->absmax, cmaxs);

	for (other = ent->teamchain ; other ; other = other->teamchain) {
		AddPointToBounds(other->absmin, cmins, cmaxs);
		AddPointToBounds(other->absmax, cmins, cmaxs);
	}

	// expand
	cmins_x -= 60;
	cmins_y -= 60;
	cmaxs_x += 60;
	cmaxs_y += 60;

	other = G_Spawn();
	VectorCopy(cmins, other->mins);
	VectorCopy(cmaxs, other->maxs);
	other->owner = ent;
	other->solid = SOLID_TRIGGER;
	other->movetype = MOVETYPE_NONE;
	other->touch = Touch_DoorTrigger;
	gi.linkentity(other);

	if (ent->spawnflags & DOOR_START_OPEN)
		door_use_areaportals(ent, true);

	Think_CalcMoveSpeed(ent);
}

static void(entity self, entity other) door_blocked =
{
	entity ent;

	if (!(other->svflags & SVF_MONSTER) && (!other->is_client)) {
		// give it a chance to go away on it's own terms (like gibs)
		T_Damage(other, self, self, vec3_origin, other->s.origin, vec3_origin, 100000, 1, 0, MOD_CRUSH);
		// if it's still there, nuke it
		if (other)
			BecomeExplosion1(other);
		return;
	}

	T_Damage(other, self, self, vec3_origin, other->s.origin, vec3_origin, self->dmg, 1, 0, MOD_CRUSH);

	if (self->spawnflags & DOOR_CRUSHER)
		return;


// if a door has a negative wait, it would never come back if blocked,
// so let it just squash the object to death real fast
	if (self->moveinfo.wait >= 0) {
		if (self->moveinfo.state == STATE_DOWN) {
			for (ent = self->teammaster ; ent ; ent = ent->teamchain)
				door_go_up(ent, ent->activator);
		} else {
			for (ent = self->teammaster ; ent ; ent = ent->teamchain)
				door_go_down(ent);
		}
	}
}

static void(entity self, entity inflictor, entity attacker, int damage, vector point) door_killed =
{
	entity ent;

	for (ent = self->teammaster ; ent ; ent = ent->teamchain) {
		ent->health = ent->max_health;
		ent->takedamage = DAMAGE_NO;
	}
	door_use(self->teammaster, attacker, attacker);
}

static void(entity self, entity other, cplane_t plane, csurface_t surf) door_touch =
{
	if (!other->is_client)
		return;

	if (level.framenum < self->touch_debounce_framenum)
		return;
	self->touch_debounce_framenum = level.framenum + (int)(5.0f * BASE_FRAMERATE);

	gi.centerprintf(other, "%s", self->message);
	gi.sound(other, CHAN_AUTO, gi.soundindex("misc/talk1.wav"), 1, ATTN_NORM, 0);
}

API_FUNC static void(entity ent) SP_func_door =
{
	vector	abs_movedir;

	if (ent->sounds != 1) {
		ent->moveinfo.sound_start = gi.soundindex("doors/dr1_strt.wav");
		ent->moveinfo.sound_middle = gi.soundindex("doors/dr1_mid.wav");
		ent->moveinfo.sound_end = gi.soundindex("doors/dr1_end.wav");
	}

	G_SetMovedir(ent->s.angles, ent->movedir);
	ent->movetype = MOVETYPE_PUSH;
	ent->solid = SOLID_BSP;
	gi.setmodel(ent, ent->model);

	ent->blocked = door_blocked;
	ent->use = door_use;

	if (!ent->speed)
		ent->speed = 100f;
	if (deathmatch->intVal)
		ent->speed *= 2;

	if (!ent->accel)
		ent->accel = ent->speed;
	if (!ent->decel)
		ent->decel = ent->speed;

	if (!ent->wait)
		ent->wait = 3f;
	if (!st.lip)
		st.lip = 8;
	if (!ent->dmg)
		ent->dmg = 2;

	// calculate second position
	VectorCopy(ent->s.origin, ent->pos1);
	abs_movedir_x = fabsf(ent->movedir_x);
	abs_movedir_y = fabsf(ent->movedir_y);
	abs_movedir_z = fabsf(ent->movedir_z);
	ent->moveinfo.distance = abs_movedir_x * ent->size_x + abs_movedir_y * ent->size_y + abs_movedir_z * ent->size_z - st.lip;
	VectorMA(ent->pos1, ent->moveinfo.distance, ent->movedir, ent->pos2);

	// if it starts open, switch the positions
	if (ent->spawnflags & DOOR_START_OPEN) {
		VectorCopy(ent->pos2, ent->s.origin);
		VectorCopy(ent->pos1, ent->pos2);
		VectorCopy(ent->s.origin, ent->pos1);
	}

	ent->moveinfo.state = STATE_BOTTOM;

	if (ent->health) {
		ent->takedamage = DAMAGE_YES;
		ent->die = door_killed;
		ent->max_health = ent->health;
	} else if (ent->targetname && ent->message) {
		gi.soundindex("misc/talk.wav");
		ent->touch = door_touch;
	}

	ent->moveinfo.speed = ent->speed;
	ent->moveinfo.accel = ent->accel;
	ent->moveinfo.decel = ent->decel;
	ent->moveinfo.wait = ent->wait;
	VectorCopy(ent->pos1, ent->moveinfo.start_origin);
	VectorCopy(ent->s.angles, ent->moveinfo.start_angles);
	VectorCopy(ent->pos2, ent->moveinfo.end_origin);
	VectorCopy(ent->s.angles, ent->moveinfo.end_angles);

	if (ent->spawnflags & 16)
		ent->s.effects |= EF_ANIM_ALL;
	if (ent->spawnflags & 64)
		ent->s.effects |= EF_ANIM_ALLFAST;

	// to simplify logic elsewhere, make non-teamed doors into a team of one
	if (!ent->team)
		ent->teammaster = ent;

	gi.linkentity(ent);

	ent->nextthink = level.framenum + 1;
	if (ent->health || ent->targetname)
		ent->think = Think_CalcMoveSpeed;
	else
		ent->think = Think_SpawnDoorTrigger;
}


/*QUAKED func_door_rotating (0 .5 .8) ? START_OPEN REVERSE CRUSHER NOMONSTER ANIMATED TOGGLE X_AXIS Y_AXIS
TOGGLE causes the door to wait in both the start and end states for a trigger event.

START_OPEN  the door to moves to its destination when spawned, and operate in reverse.  It is used to temporarily or permanently close off an area when triggered (not useful for touch or takedamage doors).
NOMONSTER   monsters will not trigger this door

You need to have an origin brush as part of this entity.  The center of that brush will be
the point around which it is rotated. It will rotate around the Z axis by default.  You can
check either the X_AXIS or Y_AXIS box to change that.

"distance" is how many degrees the door will be rotated.
"speed" determines how fast the door moves; default value is 100.

REVERSE will cause the door to rotate in the opposite direction.

"message"   is printed when the door is touched if it is a trigger door and it hasn't been fired yet
"angle"     determines the opening direction
"targetname" if set, no touch field will be spawned and a remote button or trigger field activates the door.
"health"    if set, door must be shot open
"speed"     movement speed (100 default)
"wait"      wait before returning (3 default, -1 = never return)
"dmg"       damage to inflict when blocked (2 default)
"sounds"
1)  silent
2)  light
3)  medium
4)  heavy
*/

API_FUNC static void(entity ent) SP_func_door_rotating =
{
	VectorClear(ent->s.angles);

	// set the axis of rotation
	VectorClear(ent->movedir);
	if (ent->spawnflags & DOOR_X_AXIS)
		ent->movedir_z = 1.0f;
	else if (ent->spawnflags & DOOR_Y_AXIS)
		ent->movedir_x = 1.0f;
	else // Z_AXIS
		ent->movedir_y = 1.0f;

	// check for reverse rotation
	if (ent->spawnflags & DOOR_REVERSE)
		VectorNegate(ent->movedir, ent->movedir);

	if (!st.distance) {
		gi.dprintf("%s at %s with no distance set\n", ent->classname, vtos(ent->s.origin));
		st.distance = 90;
	}

	VectorCopy(ent->s.angles, ent->pos1);
	VectorMA(ent->s.angles, st.distance, ent->movedir, ent->pos2);
	ent->moveinfo.distance = (float)st.distance;

	ent->movetype = MOVETYPE_PUSH;
	ent->solid = SOLID_BSP;
	gi.setmodel(ent, ent->model);

	ent->blocked = door_blocked;
	ent->use = door_use;

	if (!ent->speed)
		ent->speed = 100f;
	if (!ent->accel)
		ent->accel = ent->speed;
	if (!ent->decel)
		ent->decel = ent->speed;

	if (!ent->wait)
		ent->wait = 3f;
	if (!ent->dmg)
		ent->dmg = 2;

	if (ent->sounds != 1) {
		ent->moveinfo.sound_start = gi.soundindex("doors/dr1_strt.wav");
		ent->moveinfo.sound_middle = gi.soundindex("doors/dr1_mid.wav");
		ent->moveinfo.sound_end = gi.soundindex("doors/dr1_end.wav");
	}

	// if it starts open, switch the positions
	if (ent->spawnflags & DOOR_START_OPEN) {
		VectorCopy(ent->pos2, ent->s.angles);
		VectorCopy(ent->pos1, ent->pos2);
		VectorCopy(ent->s.angles, ent->pos1);
		VectorNegate(ent->movedir, ent->movedir);
	}

	if (ent->health) {
		ent->takedamage = DAMAGE_YES;
		ent->die = door_killed;
		ent->max_health = ent->health;
	}

	if (ent->targetname && ent->message) {
		gi.soundindex("misc/talk.wav");
		ent->touch = door_touch;
	}

	ent->moveinfo.state = STATE_BOTTOM;
	ent->moveinfo.speed = ent->speed;
	ent->moveinfo.accel = ent->accel;
	ent->moveinfo.decel = ent->decel;
	ent->moveinfo.wait = ent->wait;
	VectorCopy(ent->s.origin, ent->moveinfo.start_origin);
	VectorCopy(ent->pos1, ent->moveinfo.start_angles);
	VectorCopy(ent->s.origin, ent->moveinfo.end_origin);
	VectorCopy(ent->pos2, ent->moveinfo.end_angles);

	if (ent->spawnflags & 16)
		ent->s.effects |= EF_ANIM_ALL;

	// to simplify logic elsewhere, make non-teamed doors into a team of one
	if (!ent->team)
		ent->teammaster = ent;

	gi.linkentity(ent);

	ent->nextthink = level.framenum + 1;
	if (ent->health || ent->targetname)
		ent->think = Think_CalcMoveSpeed;
	else
		ent->think = Think_SpawnDoorTrigger;
}


/*QUAKED func_water (0 .5 .8) ? START_OPEN
func_water is a moveable water brush.  It must be targeted to operate.  Use a non-water texture at your own risk.

START_OPEN causes the water to move to its destination when spawned and operate in reverse.

"angle"     determines the opening direction (up or down only)
"speed"     movement speed (25 default)
"wait"      wait before returning (-1 default, -1 = TOGGLE)
"lip"       lip remaining at end of move (0 default)
"sounds"    (yes, these need to be changed)
0)  no sound
1)  water
2)  lava
*/

API_FUNC static void(entity self) SP_func_water =
{
	vector	abs_movedir;

	G_SetMovedir(self->s.angles, self->movedir);
	self->movetype = MOVETYPE_PUSH;
	self->solid = SOLID_BSP;
	gi.setmodel(self, self->model);

	switch (self->sounds) {
	default:
		break;

	case 1: // water
		self->moveinfo.sound_start = gi.soundindex("world/mov_watr.wav");
		self->moveinfo.sound_end = gi.soundindex("world/stp_watr.wav");
		break;

	case 2: // lava
		self->moveinfo.sound_start = gi.soundindex("world/mov_watr.wav");
		self->moveinfo.sound_end = gi.soundindex("world/stp_watr.wav");
		break;
	}

	// calculate second position
	VectorCopy(self->s.origin, self->pos1);
	abs_movedir_x = fabsf(self->movedir_x);
	abs_movedir_y = fabsf(self->movedir_y);
	abs_movedir_z = fabsf(self->movedir_z);
	self->moveinfo.distance = abs_movedir_x * self->size_x + abs_movedir_y * self->size_y + abs_movedir_z * self->size_z - st.lip;
	VectorMA(self->pos1, self->moveinfo.distance, self->movedir, self->pos2);

	// if it starts open, switch the positions
	if (self->spawnflags & DOOR_START_OPEN) {
		VectorCopy(self->pos2, self->s.origin);
		VectorCopy(self->pos1, self->pos2);
		VectorCopy(self->s.origin, self->pos1);
	}

	VectorCopy(self->pos1, self->moveinfo.start_origin);
	VectorCopy(self->s.angles, self->moveinfo.start_angles);
	VectorCopy(self->pos2, self->moveinfo.end_origin);
	VectorCopy(self->s.angles, self->moveinfo.end_angles);

	self->moveinfo.state = STATE_BOTTOM;

	if (!self->speed)
		self->speed = 25f;
	self->moveinfo.accel = self->moveinfo.decel = self->moveinfo.speed = self->speed;

	if (!self->wait)
		self->wait = -1f;
	self->moveinfo.wait = self->wait;

	self->use = door_use;

	if (self->wait == -1)
		self->spawnflags |= DOOR_TOGGLE;

	self->classname = "func_door";

	gi.linkentity(self);
}


const int TRAIN_START_ON	= 1;
const int TRAIN_TOGGLE		= 2;
const int TRAIN_BLOCK_STOPS	= 4;

/*QUAKED func_train (0 .5 .8) ? START_ON TOGGLE BLOCK_STOPS
Trains are moving platforms that players can ride.
The targets origin specifies the min point of the train at each corner.
The train spawns at the first target it is pointing at.
If the train is the target of a button or trigger, it will not begin moving until activated.
speed   default 100
dmg     default 2
noise   looping sound to play when the train is in motion

*/
static void(entity self) train_next;

static void(entity self, entity other) train_blocked =
{
	if (!(other->svflags & SVF_MONSTER) && (!other->is_client)) {
		// give it a chance to go away on it's own terms (like gibs)
		T_Damage(other, self, self, vec3_origin, other->s.origin, vec3_origin, 100000, 1, 0, MOD_CRUSH);
		// if it's still there, nuke it
		if (other)
			BecomeExplosion1(other);
		return;
	}

	if (level.framenum < self->touch_debounce_framenum)
		return;

	if (!self->dmg)
		return;
	self->touch_debounce_framenum = level.framenum + (int)(0.5f * BASE_FRAMERATE);
	T_Damage(other, self, self, vec3_origin, other->s.origin, vec3_origin, self->dmg, 1, 0, MOD_CRUSH);
}

static void(entity self) train_wait =
{
	if (self.target_ent.pathtarget) {
		string savetarget;
		entity ent;

		ent = self->target_ent;
		savetarget = ent->target;
		ent->target = ent->pathtarget;
		G_UseTargets(ent, self->activator);
		ent->target = savetarget;

		// make sure we didn't get killed by a killtarget
		if (!self->inuse)
			return;
	}

	if (self->moveinfo.wait) {
		if (self->moveinfo.wait > 0) {
			self->nextthink = level.framenum + (int)(self->moveinfo.wait * BASE_FRAMERATE);
			self->think = train_next;
		} else if (self->spawnflags & TRAIN_TOGGLE) { // && wait < 0
			train_next(self);
			self->spawnflags &= ~TRAIN_START_ON;
			VectorClear(self->velocity);
			self->nextthink = 0;
		}

		if (!(self->flags & FL_TEAMSLAVE)) {
			if (self->moveinfo.sound_end)
				gi.sound(self, CHAN_NO_PHS_ADD + CHAN_VOICE, self->moveinfo.sound_end, 1, ATTN_STATIC, 0);
			self->s.sound = 0;
		}
	} else {
		train_next(self);
	}

}

static void(entity self) train_next =
{
	entity	ent;
	vector	dest;
	bool	first;

	first = true;
again:
	if (!self->target) {
//      gi.dprintf ("train_next: no next target\n");
		return;
	}

	ent = G_PickTarget(self->target);
	if (!ent) {
		gi.dprintf("train_next: bad target %s\n", self->target);
		return;
	}

	self->target = ent->target;

	// check for a teleport path_corner
	if (ent->spawnflags & 1) {
		if (!first) {
			gi.dprintf("connected teleport path_corners, see %s at %s\n", ent->classname, vtos(ent->s.origin));
			return;
		}
		first = false;
		VectorSubtract(ent->s.origin, self->mins, self->s.origin);
		VectorCopy(self->s.origin, self->s.old_origin);
		self->s.event = EV_OTHER_TELEPORT;
		gi.linkentity(self);
		goto again;
	}

	self->moveinfo.wait = ent->wait;
	self->target_ent = ent;

	if (!(self->flags & FL_TEAMSLAVE)) {
		if (self->moveinfo.sound_start)
			gi.sound(self, CHAN_NO_PHS_ADD + CHAN_VOICE, self->moveinfo.sound_start, 1, ATTN_STATIC, 0);
		self->s.sound = self->moveinfo.sound_middle;
	}

	VectorSubtract(ent->s.origin, self->mins, dest);
	self->moveinfo.state = STATE_TOP;
	VectorCopy(self->s.origin, self->moveinfo.start_origin);
	VectorCopy(dest, self->moveinfo.end_origin);
	Move_Calc(self, dest, train_wait);
	self->spawnflags |= TRAIN_START_ON;
}

static void(entity self) train_resume =
{
	entity	ent;
	vector	dest;

	ent = self->target_ent;

	VectorSubtract(ent->s.origin, self->mins, dest);
	self->moveinfo.state = STATE_TOP;
	VectorCopy(self->s.origin, self->moveinfo.start_origin);
	VectorCopy(dest, self->moveinfo.end_origin);
	Move_Calc(self, dest, train_wait);
	self->spawnflags |= TRAIN_START_ON;
}

void(entity self) func_train_find =
{
	entity	ent;

	if (!self->target) {
		gi.dprintf("train_find: no target\n");
		return;
	}
	ent = G_PickTarget(self->target);
	if (!ent) {
		gi.dprintf("train_find: target %s not found\n", self->target);
		return;
	}
	self->target = ent->target;

	VectorSubtract(ent->s.origin, self->mins, self->s.origin);
	gi.linkentity(self);

	// if not triggered, start immediately
	if (!self->targetname)
		self->spawnflags |= TRAIN_START_ON;

	if (self->spawnflags & TRAIN_START_ON) {
		self->nextthink = level.framenum + 1;
		self->think = train_next;
		self->activator = self;
	}
}

void(entity self, entity other, entity cactivator) train_use =
{
	self->activator = cactivator;

	if (self->spawnflags & TRAIN_START_ON) {
		if (!(self->spawnflags & TRAIN_TOGGLE))
			return;
		self->spawnflags &= ~TRAIN_START_ON;
		VectorClear(self->velocity);
		self->nextthink = 0;
	} else {
		if (self->target_ent)
			train_resume(self);
		else
			train_next(self);
	}
}

API_FUNC static void(entity self) SP_func_train =
{
	self->movetype = MOVETYPE_PUSH;

	VectorClear(self->s.angles);
	self->blocked = train_blocked;
	if (self->spawnflags & TRAIN_BLOCK_STOPS)
		self->dmg = 0;
	else {
		if (!self->dmg)
			self->dmg = 100;
	}
	self->solid = SOLID_BSP;
	gi.setmodel(self, self->model);

	if (st.noise)
		self->moveinfo.sound_middle = gi.soundindex(st.noise);

	if (!self->speed)
		self->speed = 100f;

	self->moveinfo.speed = self->speed;
	self->moveinfo.accel = self->moveinfo.decel = self->moveinfo.speed;

	self->use = train_use;

	gi.linkentity(self);

	if (self->target) {
		// start trains on the second frame, to make sure their targets have had
		// a chance to spawn
		self->nextthink = level.framenum + 1;
		self->think = func_train_find;
	} else {
		gi.dprintf("func_train without a target at %s\n", vtos(self->absmin));
	}
}


/*QUAKED trigger_elevator (0.3 0.1 0.6) (-8 -8 -8) (8 8 8)
*/
static void(entity self, entity other, entity cactivator) trigger_elevator_use =
{
	entity	target;

	if (self->movetarget->nextthink) {
//      gi.dprintf("elevator busy\n");
		return;
	}

	if (!other->pathtarget) {
		gi.dprintf("elevator used with no pathtarget\n");
		return;
	}

	target = G_PickTarget(other->pathtarget);
	if (!target) {
		gi.dprintf("elevator used with bad pathtarget: %s\n", other->pathtarget);
		return;
	}

	self->movetarget->target_ent = target;
	train_resume(self->movetarget);
}

static void(entity self) trigger_elevator_init =
{
	if (!self->target) {
		gi.dprintf("trigger_elevator has no target\n");
		return;
	}
	self->movetarget = G_PickTarget(self->target);
	if (!self->movetarget) {
		gi.dprintf("trigger_elevator unable to find target %s\n", self->target);
		return;
	}
	if (self->movetarget->classname != "func_train") {
		gi.dprintf("trigger_elevator target %s is not a train\n", self->target);
		return;
	}

	self->use = trigger_elevator_use;
	self->svflags = SVF_NOCLIENT;

}

API_FUNC static void(entity self) SP_trigger_elevator =
{
	self->think = trigger_elevator_init;
	self->nextthink = level.framenum + 1;
}


/*QUAKED func_timer (0.3 0.1 0.6) (-8 -8 -8) (8 8 8) START_ON
"wait"          base time between triggering all targets, default is 1
"random"        wait variance, default is 0

so, the basic time between firing is a random time between
(wait - random) and (wait + random)

"delay"         delay before first firing when turned on, default is 0

"pausetime"     additional delay used only the very first time
				and only if spawned with START_ON

These can used but not touched.
*/
static void(entity self) func_timer_think =
{
	G_UseTargets(self, self->activator);
	self->nextthink = level.framenum + (int)((self->wait + random(-self->rand, self->rand)) * BASE_FRAMERATE);
}

static void(entity self, entity other, entity cactivator) func_timer_use =
{
	self->activator = cactivator;

	// if on, turn it off
	if (self->nextthink) {
		self->nextthink = 0;
		return;
	}

	// turn it on
	if (self->delay)
		self->nextthink = level.framenum + (int)(self->delay * BASE_FRAMERATE);
	else
		func_timer_think(self);
}

API_FUNC static void(entity self) SP_func_timer =
{
	if (!self->wait)
		self->wait = 1.0f;

	self->use = func_timer_use;
	self->think = func_timer_think;

	if (self->rand >= self->wait) {
		self->rand = self->wait - FRAMETIME;
		gi.dprintf("func_timer at %s has random >= wait\n", vtos(self->s.origin));
	}

	if (self->spawnflags & 1) {
		self->nextthink = level.framenum + (int)((1.0f + st.pausetime + self->delay + self->wait + random(-self->rand, self->rand)) * BASE_FRAMERATE);
		self->activator = self;
	}

	self->svflags = SVF_NOCLIENT;
}


/*QUAKED func_conveyor (0 .5 .8) ? START_ON TOGGLE
Conveyors are stationary brushes that move what's on them.
The brush should be have a surface with at least one current content enabled.
speed   default 100
*/

static void(entity self, entity other, entity cactivator) func_conveyor_use =
{
	if (self->spawnflags & 1) {
		self->speed = 0;
		self->spawnflags &= ~1;
	} else {
		self->speed = (float)self->count;
		self->spawnflags |= 1;
	}

	if (!(self->spawnflags & 2))
		self->count = 0;
}

API_FUNC static void(entity self) SP_func_conveyor =
{
	if (!self->speed)
		self->speed = 100f;

	if (!(self->spawnflags & 1)) {
		self->count = (int)self->speed;
		self->speed = 0;
	}

	self->use = func_conveyor_use;

	gi.setmodel(self, self->model);
	self->solid = SOLID_BSP;
	gi.linkentity(self);
}


/*QUAKED func_door_secret (0 .5 .8) ? always_shoot 1st_left 1st_down
A secret door.  Slide back and then to the side.

open_once       doors never closes
1st_left        1st move is left of arrow
1st_down        1st move is down from arrow
always_shoot    door is shootebale even if targeted

"angle"     determines the direction
"dmg"       damage to inflic when blocked (default 2)
"wait"      how long to hold in the open position (default 5, -1 means hold)
*/

const int SECRET_ALWAYS_SHOOT	= 1;
const int SECRET_1ST_LEFT	= 2;
const int SECRET_1ST_DOWN	= 4;

static void(entity self) door_secret_move1;
static void(entity self) door_secret_move2;
static void(entity self) door_secret_move3;
static void(entity self) door_secret_move4;
static void(entity self) door_secret_move5;
static void(entity self) door_secret_move6;
static void(entity self) door_secret_done;

static void(entity self, entity other, entity cactivator) door_secret_use =
{
	// make sure we're not already moving
	if (!VectorEmpty(self->s.origin))
		return;

	Move_Calc(self, self->pos1, door_secret_move1);
	door_use_areaportals(self, true);
}

static void(entity self) door_secret_move1 = 
{
	self->nextthink = level.framenum + (int)(1.0f * BASE_FRAMERATE);
	self->think = door_secret_move2;
}

static void(entity self) door_secret_move2 =
{
	Move_Calc(self, self->pos2, door_secret_move3);
}

static void(entity self) door_secret_move3 =
{
	if (self->wait == -1)
		return;
	self->nextthink = level.framenum + (int)(self->wait * BASE_FRAMERATE);
	self->think = door_secret_move4;
}

static void(entity self) door_secret_move4 =
{
	Move_Calc(self, self->pos1, door_secret_move5);
}

static void(entity self) door_secret_move5 =
{
	self->nextthink = level.framenum + (int)(1.0f * BASE_FRAMERATE);
	self->think = door_secret_move6;
}

static void(entity self) door_secret_move6 =
{
	Move_Calc(self, vec3_origin, door_secret_done);
}

static void(entity self) door_secret_done =
{
	if (!(self->targetname) || (self->spawnflags & SECRET_ALWAYS_SHOOT)) {
		self->health = 0;
		self->takedamage = DAMAGE_YES;
	}
	door_use_areaportals(self, false);
}

static void(entity self, entity other) door_secret_blocked =
{
	if (!(other->svflags & SVF_MONSTER) && (!other->is_client)) {
		// give it a chance to go away on it's own terms (like gibs)
		T_Damage(other, self, self, vec3_origin, other->s.origin, vec3_origin, 100000, 1, 0, MOD_CRUSH);
		// if it's still there, nuke it
		if (other)
			BecomeExplosion1(other);
		return;
	}

	if (level.framenum < self->touch_debounce_framenum)
		return;
	self->touch_debounce_framenum = level.framenum + (int)(0.5f * BASE_FRAMERATE);

	T_Damage(other, self, self, vec3_origin, other->s.origin, vec3_origin, self->dmg, 1, 0, MOD_CRUSH);
}

static void(entity self, entity inflictor, entity attacker, int damage, vector point) door_secret_die =
{
	self->takedamage = DAMAGE_NO;
	door_secret_use(self, attacker, attacker);
}

API_FUNC static void(entity ent) SP_func_door_secret =
{
	vector	forward, right, up;
	float	side;
	float	width;
	float	length;

	ent->moveinfo.sound_start = gi.soundindex("doors/dr1_strt.wav");
	ent->moveinfo.sound_middle = gi.soundindex("doors/dr1_mid.wav");
	ent->moveinfo.sound_end = gi.soundindex("doors/dr1_end.wav");

	ent->movetype = MOVETYPE_PUSH;
	ent->solid = SOLID_BSP;
	gi.setmodel(ent, ent->model);

	ent->blocked = door_secret_blocked;
	ent->use = door_secret_use;

	if (!(ent->targetname) || (ent->spawnflags & SECRET_ALWAYS_SHOOT)) {
		ent->health = 0;
		ent->takedamage = DAMAGE_YES;
		ent->die = door_secret_die;
	}

	if (!ent->dmg)
		ent->dmg = 2;

	if (!ent->wait)
		ent->wait = 5f;

	ent->moveinfo.accel =
		ent->moveinfo.decel =
			ent->moveinfo.speed = 50f;

	// calculate positions
	AngleVectors(ent->s.angles, forward, right, up);
	VectorClear(ent->s.angles);
	side = 1.0f - (ent->spawnflags & SECRET_1ST_LEFT);
	if (ent->spawnflags & SECRET_1ST_DOWN)
		width = fabsf(DotProduct(up, ent->size));
	else
		width = fabsf(DotProduct(right, ent->size));
	length = fabsf(DotProduct(forward, ent->size));
	if (ent->spawnflags & SECRET_1ST_DOWN)
		VectorMA(ent->s.origin, -1 * width, up, ent->pos1);
	else
		VectorMA(ent->s.origin, side * width, right, ent->pos1);
	VectorMA(ent->pos1, length, forward, ent->pos2);

	if (ent->health) {
		ent->takedamage = DAMAGE_YES;
		ent->die = door_killed;
		ent->max_health = ent->health;
	} else if (ent->targetname && ent->message) {
		gi.soundindex("misc/talk.wav");
		ent->touch = door_touch;
	}

	ent->classname = "func_door";

	gi.linkentity(ent);
}


/*QUAKED func_killbox (1 0 0) ?
Kills everything inside when fired, irrespective of protection.
*/
static void(entity self, entity other, entity activator) use_killbox =
{
	KillBox(self);
}

API_FUNC static void(entity ent) SP_func_killbox =
{
	gi.setmodel(ent, ent->model);
	ent->use = use_killbox;
	ent->svflags = SVF_NOCLIENT;
}
