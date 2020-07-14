void(entity self) InitTrigger =
{
	if (!VectorEmpty(self->s.angles))
		G_SetMovedir(self->s.angles, self->movedir);

	self->solid = SOLID_TRIGGER;
	self->movetype = MOVETYPE_NONE;
	gi.setmodel(self, self->model);
	self->svflags = SVF_NOCLIENT;
}


// the wait time has passed, so set back up for another activation
static void(entity ent) multi_wait =
{
	ent->nextthink = 0;
}


// the trigger was just activated
// ent->activator should be set to the activator so it can be held through a delay
// so wait for the delay time before firing
static void(entity ent) multi_trigger =
{
	if (ent->nextthink)
		return;     // already been triggered

	G_UseTargets(ent, ent->activator);

	if (ent->wait > 0) {
		ent->think = multi_wait;
		ent->nextthink = level.framenum + (int)(ent->wait * BASE_FRAMERATE);
	} else {
		// we can't just remove (self) here, because this is a touch function
		// called while looping through area links...
		ent->touch = 0;
		ent->nextthink = level.framenum + 1;
		ent->think = G_FreeEdict;
	}
}

static void(entity ent, entity other, entity cactivator) Use_Multi =
{
	ent->activator = cactivator;
	multi_trigger(ent);
}

static void(entity self, entity other, cplane_t plane, csurface_t surf) Touch_Multi =
{
	if (other->is_client) {
		if (self->spawnflags & 2)
			return;
	} else if (other->svflags & SVF_MONSTER) {
		if (!(self->spawnflags & 1))
			return;
	} else
		return;

	if (!VectorEmpty(self->movedir)) {
		vector	forward;

		AngleVectors(other->s.angles, forward, unref_vec, unref_vec);
		if (DotProduct(forward, self->movedir) < 0)
			return;
	}

	self->activator = other;
	multi_trigger(self);
}

/*QUAKED trigger_multiple (.5 .5 .5) ? MONSTER NOT_PLAYER TRIGGERED
Variable sized repeatable trigger.  Must be targeted at one or more entities.
If "delay" is set, the trigger waits some time after activating before firing.
"wait" : Seconds between triggerings. (.2 default)
sounds
1)  secret
2)  beep beep
3)  large switch
4)
set "message" to text string
*/
static void(entity self, entity other, entity cactivator) trigger_enable =
{
	self->solid = SOLID_TRIGGER;
	self->use = Use_Multi;
	gi.linkentity(self);
}

__used static void(entity ent) SP_trigger_multiple =
{
	if (ent->sounds == 1)
		ent->noise_index = gi.soundindex("misc/secret.wav");
	else if (ent->sounds == 2)
		ent->noise_index = gi.soundindex("misc/talk.wav");
	else if (ent->sounds == 3)
		ent->noise_index = gi.soundindex("misc/trigger1.wav");

	if (!ent->wait)
		ent->wait = 0.2f;
	ent->touch = Touch_Multi;
	ent->movetype = MOVETYPE_NONE;
	ent->svflags |= SVF_NOCLIENT;


	if (ent->spawnflags & 4) {
		ent->solid = SOLID_NOT;
		ent->use = trigger_enable;
	} else {
		ent->solid = SOLID_TRIGGER;
		ent->use = Use_Multi;
	}

	if (!VectorEmpty(ent->s.angles))
		G_SetMovedir(ent->s.angles, ent->movedir);

	gi.setmodel(ent, ent->model);
	gi.linkentity(ent);
}


/*QUAKED trigger_once (.5 .5 .5) ? x x TRIGGERED
Triggers once, then removes itself.
You must set the key "target" to the name of another object in the level that has a matching "targetname".

If TRIGGERED, this trigger must be triggered before it is live.

sounds
 1) secret
 2) beep beep
 3) large switch
 4)

"message"   string to be displayed when triggered
*/

__used static void(entity ent) SP_trigger_once =
{
	// make old maps work because I messed up on flag assignments here
	// triggered was on bit 1 when it should have been on bit 4
	if (ent->spawnflags & 1) {
		vector	v;

		VectorMA(ent->mins, 0.5f, ent->size, v);
		ent->spawnflags &= ~1;
		ent->spawnflags |= 4;
		gi.dprintf("fixed TRIGGERED flag on %s at %s\n", ent->classname, vtos(v));
	}

	ent->wait = -1f;
	SP_trigger_multiple(ent);
}

/*QUAKED trigger_relay (.5 .5 .5) (-8 -8 -8) (8 8 8)
This fixed size trigger cannot be touched, it can only be fired by other events.
*/
static void(entity self, entity other, entity cactivator) trigger_relay_use =
{
	G_UseTargets(self, cactivator);
}

__used static void(entity self) SP_trigger_relay =
{
	self->use = trigger_relay_use;
}


/*
==============================================================================

trigger_key

==============================================================================
*/

/*QUAKED trigger_key (.5 .5 .5) (-8 -8 -8) (8 8 8)
A relay trigger that only fires it's targets if player has the proper key.
Use "item" to specify the required key, for example "key_data_cd"
*/
static void(entity self, entity other, entity cactivator) trigger_key_use =
{
	int	index;

	if (!self->item)
		return;
	if (!cactivator->is_client)
		return;

	index = ITEM_INDEX(self->item);
	// TODO
	/*if (!cactivator->client->pers.inventory[index]) {
		if (level.framenum < self->touch_debounce_framenum)
			return;
		self->touch_debounce_framenum = level.framenum + 5.0f * BASE_FRAMERATE;
		gi.centerprintf(cactivator, "You need the %s", self->item->pickup_name);
		gi.sound(cactivator, CHAN_AUTO, gi.soundindex("misc/keytry.wav"), 1, ATTN_NORM, 0);
		return;
	}*/

	gi.sound(cactivator, CHAN_AUTO, gi.soundindex("misc/keyuse.wav"), 1, ATTN_NORM, 0);
	if (coop->intVal) {
		int     player;
		entity	ent;

		if (GetItemKeyByIndex(self->item, classname) == "key_power_cube") {
			int cube;

			for (cube = 0; cube < 8; cube++)
				if (cactivator->client->pers.power_cubes & LShiftInt(1, cube))
					break;
			for (player = 1; player <= game.maxclients; player++) {
				ent = itoe(player);
				if (!ent->inuse)
					continue;
				if (!ent->is_client)
					continue;
				if (ent->client->pers.power_cubes & LShiftInt(1, cube)) {
					// TODO
					//ent->client->pers.inventory[index]--;
					ent->client->pers.power_cubes &= ~LShiftInt(1, cube);
				}
			}
		} else {
			for (player = 1; player <= game.maxclients; player++) {
				ent = itoe(player);
				if (!ent->inuse)
					continue;
				if (!ent->is_client)
					continue;
				// TODO
				//ent->client->pers.inventory[index] = 0;
			}
		}
	} else {
		// TODO
		//activator->client->pers.inventory[index]--;
	}

	G_UseTargets(self, cactivator);

	self->use = 0;
}

__used static void(entity self) SP_trigger_key =
{
	if (!st.item) {
		gi.dprintf("no key item for trigger_key at %s\n", vtos(self->s.origin));
		return;
	}
	self->item = FindItemByClassname(st.item);

	if (!self->item) {
		gi.dprintf("item %s not found for trigger_key at %s\n", st.item, vtos(self->s.origin));
		return;
	}

	if (!self->target) {
		gi.dprintf("%s at %s has no target\n", self->classname, vtos(self->s.origin));
		return;
	}

	gi.soundindex("misc/keytry.wav");
	gi.soundindex("misc/keyuse.wav");

	self->use = trigger_key_use;
}


/*
==============================================================================

trigger_counter

==============================================================================
*/

/*QUAKED trigger_counter (.5 .5 .5) ? nomessage
Acts as an intermediary for an action that takes multiple inputs.

If nomessage is not set, t will print "1 more.. " etc when triggered and "sequence complete" when finished.

After the counter has been triggered "count" times (default 2), it will fire all of it's targets and remove itself.
*/

static void(entity self, entity other, entity cactivator) trigger_counter_use =
{
	if (self->count == 0)
		return;

	self->count--;

	if (self->count) {
		if (!(self->spawnflags & 1)) {
			gi.centerprintf(cactivator, "%i more to go...", self->count);
			gi.sound(cactivator, CHAN_AUTO, gi.soundindex("misc/talk1.wav"), 1, ATTN_NORM, 0);
		}
		return;
	}

	if (!(self->spawnflags & 1)) {
		gi.centerprintf(cactivator, "Sequence completed!");
		gi.sound(cactivator, CHAN_AUTO, gi.soundindex("misc/talk1.wav"), 1, ATTN_NORM, 0);
	}
	self->activator = cactivator;
	multi_trigger(self);
}

__used static void(entity self) SP_trigger_counter =
{
	self->wait = -1f;
	if (!self->count)
		self->count = 2;

	self->use = trigger_counter_use;
}


/*
==============================================================================

trigger_always

==============================================================================
*/

/*QUAKED trigger_always (.5 .5 .5) (-8 -8 -8) (8 8 8)
This trigger will always fire.  It is activated by the world.
*/
__used static void(entity ent) SP_trigger_always
{
	// we must have some delay to make sure our use targets are present
	if (ent->delay < 0.2f)
		ent->delay = 0.2f;
	G_UseTargets(ent, ent);
}


/*
==============================================================================

trigger_push

==============================================================================
*/

#define PUSH_ONCE       1

static int windsound;

static void(entity self, entity other, cplane_t plane, csurface_t surf) trigger_push_touch =
{
	if (other->classname == "grenade") {
		VectorScale(self->movedir, self->speed * 10, other->velocity);
	} else if (other->health > 0) {
		VectorScale(self->movedir, self->speed * 10, other->velocity);

		if (other->is_client) {
			// don't take falling damage immediately from this
			VectorCopy(other->velocity, other->client->oldvelocity);
			if (other->fly_sound_debounce_framenum < level.framenum) {
				other->fly_sound_debounce_framenum = level.framenum + (int)(1.5f * BASE_FRAMERATE);
				gi.sound(other, CHAN_AUTO, windsound, 1, ATTN_NORM, 0);
			}
		}
	}
	if (self->spawnflags & PUSH_ONCE)
		G_FreeEdict(self);
}


/*QUAKED trigger_push (.5 .5 .5) ? PUSH_ONCE
Pushes the player
"speed"     defaults to 1000
*/
__used static void(entity self) SP_trigger_push =
{
	InitTrigger(self);
	windsound = gi.soundindex("misc/windfly.wav");
	self->touch = trigger_push_touch;
	if (!self->speed)
		self->speed = 1000f;
	gi.linkentity(self);
}


/*
==============================================================================

trigger_hurt

==============================================================================
*/

/*QUAKED trigger_hurt (.5 .5 .5) ? START_OFF TOGGLE SILENT NO_PROTECTION SLOW
Any entity that touches this will be hurt.

It does dmg points of damage each server frame

SILENT          supresses playing the sound
SLOW            changes the damage rate to once per second
NO_PROTECTION   *nothing* stops the damage

"dmg"           default 5 (whole numbers only)

*/
static void(entity self, entity other, entity cactivator) hurt_use =
{
	if (self->solid == SOLID_NOT)
		self->solid = SOLID_TRIGGER;
	else
		self->solid = SOLID_NOT;
	gi.linkentity(self);

	if (!(self->spawnflags & 2))
		self->use = 0;
}


static void(entity self, entity other, cplane_t plane, csurface_t surf) hurt_touch =
{
	int     dflags;

	if (!other->takedamage)
		return;

	if (self->timestamp > level.framenum)
		return;

	if (self->spawnflags & 16)
		self->timestamp = level.framenum + 1 * BASE_FRAMERATE;
	else
		self->timestamp = level.framenum + 1;

	if (!(self->spawnflags & 4)) {
		if ((level.framenum % 10) == 0)
			gi.sound(other, CHAN_AUTO, self->noise_index, 1, ATTN_NORM, 0);
	}

	if (self->spawnflags & 8)
		dflags = DAMAGE_NO_PROTECTION;
	else
		dflags = 0;
	T_Damage(other, self, self, vec3_origin, other->s.origin, vec3_origin, self->dmg, self->dmg, dflags, MOD_TRIGGER_HURT);
}

__used static void(entity self) SP_trigger_hurt =
{
	InitTrigger(self);

	self->noise_index = gi.soundindex("world/electro.wav");
	self->touch = hurt_touch;

	if (!self->dmg)
		self->dmg = 5;

	if (self->spawnflags & 1)
		self->solid = SOLID_NOT;
	else
		self->solid = SOLID_TRIGGER;

	if (self->spawnflags & 2)
		self->use = hurt_use;

	gi.linkentity(self);
}


/*
==============================================================================

trigger_gravity

==============================================================================
*/

/*QUAKED trigger_gravity (.5 .5 .5) ?
Changes the touching entites gravity to
the value of "gravity".  1.0 is standard
gravity for the level.
*/

static void(entity self, entity other, cplane_t plane, csurface_t surf) trigger_gravity_touch =
{
	other->gravity = self->gravity;
}

__used static void(entity self) SP_trigger_gravity =
{
	if (!st.gravity) {
		gi.dprintf("trigger_gravity without gravity set at %s\n", vtos(self->s.origin));
		G_FreeEdict(self);
		return;
	}

	InitTrigger(self);
	self->gravity = (float)stoi(st.gravity);
	self->touch = trigger_gravity_touch;
}


/*
==============================================================================

trigger_monsterjump

==============================================================================
*/

/*QUAKED trigger_monsterjump (.5 .5 .5) ?
Walking monsters that touch this will jump in the direction of the trigger's angle
"speed" default to 200, the speed thrown forward
"height" default to 200, the speed thrown upwards
*/

static void(entity self, entity other, cplane_t plane, csurface_t surf) trigger_monsterjump_touch =
{
	if (other->flags & (FL_FLY | FL_SWIM))
		return;
	if (other->svflags & SVF_DEADMONSTER)
		return;
	if (!(other->svflags & SVF_MONSTER))
		return;

// set XY even if not on ground, so the jump will clear lips
	other->velocity_x = self->movedir_x * self->speed;
	other->velocity_y = self->movedir_y * self->speed;

	if (other->groundentity == null_entity)
		return;

	other->groundentity = null_entity;
	other->velocity_z = self->movedir_z;
}

__used static void(entity self) SP_trigger_monsterjump =
{
	if (!self->speed)
		self->speed = 200f;
	if (!st.height)
		st.height = 200;
	if (self->s.angles[YAW] == 0)
		self->s.angles[YAW] = 360f;
	InitTrigger(self);
	self->touch = trigger_monsterjump_touch;
	self->movedir_z = (float)st.height;
}