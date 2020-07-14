#include "m_player.h"

static bool	is_quad;
static int	is_silenced;

static void(entity, bool) weapon_grenade_fire;

static void(entity ent, vector point, vector distance, vector forward, vector right, __out vector result) P_ProjectSource =
{
	vector _distance;

	VectorCopy(distance, _distance);
	if (ent.client->pers.hand == LEFT_HANDED)
		_distance_y *= -1f;
	else if (ent.client->pers.hand == CENTER_HANDED)
		_distance_y = 0;
	G_ProjectSource(point, _distance, forward, right, result);
}


/*
===============
PlayerNoise

Each player can have two noise objects associated with it:
a personal noise (jumping, pain, weapon firing), and a weapon
target noise (bullet wall impacts)

Monsters that don't directly see the player can move
to a noise in hopes of seeing the player from there.
===============
*/
void(entity who, vector where, player_noise_t type) PlayerNoise =
{
	entity	noise;

	if (type == PNOISE_WEAPON) {
		if (who->client->silencer_shots) {
			who->client->silencer_shots--;
			return;
		}
	}

	if (deathmatch->intVal)
		return;

	if (who->flags & FL_NOTARGET)
		return;


	if (!who->mynoise) {
		noise = G_Spawn();
		noise->classname = "player_noise";
		VectorSet(noise->mins, -8, -8, -8);
		VectorSet(noise->maxs, 8, 8, 8);
		noise->owner = who;
		noise->svflags = SVF_NOCLIENT;
		who->mynoise = noise;

		noise = G_Spawn();
		noise->classname = "player_noise";
		VectorSet(noise->mins, -8, -8, -8);
		VectorSet(noise->maxs, 8, 8, 8);
		noise->owner = who;
		noise->svflags = SVF_NOCLIENT;
		who->mynoise2 = noise;
	}

	if (type == PNOISE_SELF || type == PNOISE_WEAPON) {
		noise = who->mynoise;
		level.sound_entity = noise;
		level.sound_entity_framenum = level.framenum;
	} else { // type == PNOISE_IMPACT
		noise = who->mynoise2;
		level.sound2_entity = noise;
		level.sound2_entity_framenum = level.framenum;
	}

	VectorCopy(where, noise->s.origin);
	VectorSubtract(where, noise->maxs, noise->absmin);
	VectorAdd(where, noise->maxs, noise->absmax);
	noise->last_sound_framenum = level.framenum;
	gi.linkentity(noise);
}


bool(entity ent, entity other) Pickup_Weapon =
{
	int		index;
	gitem_id_t	ammo;

	index = ITEM_INDEX(ent->item);

	// TODO
	/*if ((dmflags->intVal & DF_WEAPONS_STAY) || coop->intVal)
		&& other->client->pers.inventory[index]) {
		if (!(ent->spawnflags & (DROPPED_ITEM | DROPPED_PLAYER_ITEM)))
			return false;   // leave the weapon for others to pickup
	}

	other->client->pers.inventory[index]++;*/

	if (!(ent->spawnflags & DROPPED_ITEM)) {
		// give them some ammo with it
		ammo = FindItem(GetItemKeyByIndex(ent->item, ammo));
		if (dmflags->intVal & DF_INFINITE_AMMO)
			Add_Ammo(other, ammo, 1000);
		else
			Add_Ammo(other, ammo, GetItemKeyByIndex(ammo, quantity));

		if (!(ent->spawnflags & DROPPED_PLAYER_ITEM)) {
			if (deathmatch->intVal) {
				if (dmflags->intVal & DF_WEAPONS_STAY)
					ent->flags |= FL_RESPAWN;
				else
					SetRespawn(ent, 30);
			}
			if (coop->intVal)
				ent->flags |= FL_RESPAWN;
		}
	}

	// TODO
	/*if (other->client->pers.weapon != ent->item &&
		(other->client->pers.inventory[index] == 1) &&
		(!deathmatch->value || other->client->pers.weapon == FindItem("blaster")))
		other->client->newweapon = ent->item;*/

	return true;
}


/*
===============
ChangeWeapon

The old weapon has been dropped all the way, so make the new one
current
===============
*/
void(entity ent) ChangeWeapon =
{
	int i;

	if (ent->client->grenade_framenum) {
		ent->client->grenade_framenum = level.framenum;
		ent->client->weapon_sound = 0;
		weapon_grenade_fire(ent, false);
		ent->client->grenade_framenum = 0;
	}

	ent->client->pers.lastweapon = ent->client->pers.weapon;
	ent->client->pers.weapon = ent->client->newweapon;
	ent->client->newweapon = 0;
	ent->client->machinegun_shots = 0;

	// set visible model
	if (ent->s.modelindex == 255) {
		if (ent->client->pers.weapon)
			i = LShiftInt(GetItemKeyByIndex(ent->client->pers.weapon, weapmodel) & 0xff, 8);
		else
			i = 0;
		ent->s.skinnum = ent.s.number | i;
	}

	if (ent->client->pers.weapon && GetItemKeyByIndex(ent->client->pers.weapon, ammo))
			ent->client->ammo_index = ITEM_INDEX(FindItem(GetItemKeyByIndex(ent->client->pers.weapon, ammo)));
	else
		ent->client->ammo_index = 0;

	if (!ent->client->pers.weapon) {
		// dead
		ent->client->ps.gunindex = 0;
		return;
	}

	ent->client->weaponstate = WEAPON_ACTIVATING;
	ent->client->ps.gunframe = 0;
	ent->client->ps.gunindex = gi.modelindex(GetItemKeyByIndex(ent->client->pers.weapon, view_model));

	ent->client->anim_priority = ANIM_PAIN;
	if (ent->client->ps.pmove.pm_flags & PMF_DUCKED) {
		ent->s.frame = FRAME_crpain1;
		ent->client->anim_end = FRAME_crpain4;
	} else {
		ent->s.frame = FRAME_pain301;
		ent->client->anim_end = FRAME_pain304;

	}
}

/*
=================
NoAmmoWeaponChange
=================
*/
static void(entity ent) NoAmmoWeaponChange =
{
	// TODO
	/*if (ent->client->pers.inventory[ITEM_INDEX(FindItem("slugs"))]
		&&  ent->client->pers.inventory[ITEM_INDEX(FindItem("railgun"))]) {
		ent->client->newweapon = FindItem("railgun");
		return;
	}
	if (ent->client->pers.inventory[ITEM_INDEX(FindItem("cells"))]
		&&  ent->client->pers.inventory[ITEM_INDEX(FindItem("hyperblaster"))]) {
		ent->client->newweapon = FindItem("hyperblaster");
		return;
	}
	if (ent->client->pers.inventory[ITEM_INDEX(FindItem("bullets"))]
		&&  ent->client->pers.inventory[ITEM_INDEX(FindItem("chaingun"))]) {
		ent->client->newweapon = FindItem("chaingun");
		return;
	}
	if (ent->client->pers.inventory[ITEM_INDEX(FindItem("bullets"))]
		&&  ent->client->pers.inventory[ITEM_INDEX(FindItem("machinegun"))]) {
		ent->client->newweapon = FindItem("machinegun");
		return;
	}
	if (ent->client->pers.inventory[ITEM_INDEX(FindItem("shells"))] > 1
		&&  ent->client->pers.inventory[ITEM_INDEX(FindItem("super shotgun"))]) {
		ent->client->newweapon = FindItem("super shotgun");
		return;
	}
	if (ent->client->pers.inventory[ITEM_INDEX(FindItem("shells"))]
		&&  ent->client->pers.inventory[ITEM_INDEX(FindItem("shotgun"))]) {
		ent->client->newweapon = FindItem("shotgun");
		return;
	}*/
	ent->client->newweapon = FindItem("blaster");
}

/*
=================
Think_Weapon

Called by ClientBeginServerFrame and ClientThink
=================
*/
void(entity ent) Think_Weapon =
{
	// if just died, put the weapon away
	if (ent->health < 1) {
		ent->client->newweapon = 0;
		ChangeWeapon(ent);
	}

	// call active weapon think routine
	if (ent->client->pers.weapon && GetItemKeyByIndex(ent->client->pers.weapon, weaponthink)) {
		is_quad = (bool)(ent->client->quad_framenum > level.framenum);
		if (ent->client->silencer_shots)
			is_silenced = MZ_SILENCED;
		else
			is_silenced = 0;
		GetItemKeyByIndex(ent->client->pers.weapon, weaponthink)(ent);
	}
}


/*
================
Use_Weapon

Make the weapon ready if there is ammo
================
*/
void(entity ent, gitem_id_t it) Use_Weapon =
{
	int		ammo_index;
	gitem_id_t	ammo_item;

	// see if we're already using it
	if (it == ent->client->pers.weapon)
		return;

	if (GetItemKeyByIndex(it, ammo) && !g_select_empty->intVal && !(GetItemKeyByIndex(it, flags) & IT_AMMO)) {
		ammo_item = FindItem(GetItemKeyByIndex(it, ammo));
		ammo_index = ITEM_INDEX(ammo_item);

		// TODO
		/*if (!ent->client->pers.inventory[ammo_index]) {
			gi.cprintf(ent, PRINT_HIGH, "No %s for %s.\n", ammo_item->pickup_name, it->pickup_name);
			return;
		}

		if (ent->client->pers.inventory[ammo_index] < item->quantity) {
			gi.cprintf(ent, PRINT_HIGH, "Not enough %s for %s.\n", ammo_item->pickup_name, it->pickup_name);
			return;
		}*/
	}

	// change to this weapon when down
	ent->client->newweapon = it;
}



/*
================
Drop_Weapon
================
*/
void(entity ent, gitem_id_t it) Drop_Weapon =
{
	int     index;

	if (dmflags->intVal & DF_WEAPONS_STAY)
		return;

	index = ITEM_INDEX(it);
	// see if we're already using it
	// TODO
	/*if (((it == ent->client->pers.weapon) || (it == ent->client->newweapon)) && (ent->client->pers.inventory[index] == 1)) {
		gi.cprintf(ent, PRINT_HIGH, "Can't drop current weapon\n");
		return;
	}*/

	Drop_Item(ent, it);
	
	// TODO
	//ent->client->pers.inventory[index]--;
}


/*
================
Weapon_Generic

A generic function to handle the basics of weapon thinking
================
*/
#define FRAME_FIRE_FIRST        (FRAME_ACTIVATE_LAST + 1)
#define FRAME_IDLE_FIRST        (FRAME_FIRE_LAST + 1)
#define FRAME_DEACTIVATE_FIRST  (FRAME_IDLE_LAST + 1)

static void(entity ent, int FRAME_ACTIVATE_LAST, int FRAME_FIRE_LAST, int FRAME_IDLE_LAST, int FRAME_DEACTIVATE_LAST, bool(int) is_pause_frame, bool(int) is_fire_frame, void(entity) fire) Weapon_Generic =
{
	int     n;

	if (ent->deadflag || ent->s.modelindex != 255) { // VWep animations screw up corpses
		return;
	}

	if (ent->client->weaponstate == WEAPON_DROPPING) {
		if (ent->client->ps.gunframe == FRAME_DEACTIVATE_LAST) {
			ChangeWeapon(ent);
			return;
		} else if ((FRAME_DEACTIVATE_LAST - ent->client->ps.gunframe) == 4) {
			ent->client->anim_priority = ANIM_REVERSE;
			if (ent->client->ps.pmove.pm_flags & PMF_DUCKED) {
				ent->s.frame = FRAME_crpain4 + 1;
				ent->client->anim_end = FRAME_crpain1;
			} else {
				ent->s.frame = FRAME_pain304 + 1;
				ent->client->anim_end = FRAME_pain301;

			}
		}

		ent->client->ps.gunframe++;
		return;
	}

	if (ent->client->weaponstate == WEAPON_ACTIVATING) {
		if (ent->client->ps.gunframe == FRAME_ACTIVATE_LAST) {
			ent->client->weaponstate = WEAPON_READY;
			ent->client->ps.gunframe = FRAME_IDLE_FIRST;
			return;
		}

		ent->client->ps.gunframe++;
		return;
	}

	if ((ent->client->newweapon) && (ent->client->weaponstate != WEAPON_FIRING)) {
		ent->client->weaponstate = WEAPON_DROPPING;
		ent->client->ps.gunframe = FRAME_DEACTIVATE_FIRST;

		if ((FRAME_DEACTIVATE_LAST - FRAME_DEACTIVATE_FIRST) < 4) {
			ent->client->anim_priority = ANIM_REVERSE;
			if (ent->client->ps.pmove.pm_flags & PMF_DUCKED) {
				ent->s.frame = FRAME_crpain4 + 1;
				ent->client->anim_end = FRAME_crpain1;
			} else {
				ent->s.frame = FRAME_pain304 + 1;
				ent->client->anim_end = FRAME_pain301;

			}
		}
		return;
	}

	if (ent->client->weaponstate == WEAPON_READY) {
		if (((ent->client->latched_buttons | ent->client->buttons) & BUTTON_ATTACK)) {
			ent->client->latched_buttons &= ~BUTTON_ATTACK;
			// TODO
			if ((!ent->client->ammo_index) || true /*||
				(ent->client->pers.inventory[ent->client->ammo_index] >= ent->client->pers.weapon->quantity)*/) {
				ent->client->ps.gunframe = FRAME_FIRE_FIRST;
				ent->client->weaponstate = WEAPON_FIRING;

				// start the animation
				ent->client->anim_priority = ANIM_ATTACK;
				if (ent->client->ps.pmove.pm_flags & PMF_DUCKED) {
					ent->s.frame = FRAME_crattak1 - 1;
					ent->client->anim_end = FRAME_crattak9;
				} else {
					ent->s.frame = FRAME_attack1 - 1;
					ent->client->anim_end = FRAME_attack8;
				}
			} else {
				if (level.framenum >= ent->pain_debounce_framenum) {
					gi.sound(ent, CHAN_VOICE, gi.soundindex("weapons/noammo.wav"), 1, ATTN_NORM, 0);
					ent->pain_debounce_framenum = level.framenum + 1 * BASE_FRAMERATE;
				}
				NoAmmoWeaponChange(ent);
			}
		} else {
			if (ent->client->ps.gunframe == FRAME_IDLE_LAST) {
				ent->client->ps.gunframe = FRAME_IDLE_FIRST;
				return;
			}

			if (is_pause_frame) {
				if (is_pause_frame(ent.client.ps.gunframe) && (Q_rand() & 15))
					return;
			}

			ent->client->ps.gunframe++;
			return;
		}
	}

	if (ent->client->weaponstate == WEAPON_FIRING) {
		if (is_fire_frame(ent->client->ps.gunframe)) {
			if (ent->client->quad_framenum > level.framenum)
				gi.sound(ent, CHAN_ITEM, gi.soundindex("items/damage3.wav"), 1, ATTN_NORM, 0);

			fire(ent);
		}
		else
			ent->client->ps.gunframe++;

		if (ent->client->ps.gunframe == FRAME_IDLE_FIRST + 1)
			ent->client->weaponstate = WEAPON_READY;
	}
}


/*
======================================================================

GRENADE

======================================================================
*/

const float GRENADE_TIMER	= 3.0f;
const int GRENADE_MINSPEED	= 400;
const int GRENADE_MAXSPEED	= 800;

void(entity ent, bool held) weapon_grenade_fire =
{
	vector	offset;
	vector	forward, right;
	vector	start;
	int     damage = 125;
	float   timer;
	int     speed;
	float   radius;

	radius = damage + 40f;
	if (is_quad)
		damage *= 4;

	VectorSet(offset, 8, 8, ent->viewheight - 8);
	AngleVectors(ent->client->v_angle, forward, right, unref_vec);
	P_ProjectSource(ent, ent->s.origin, offset, forward, right, start);

	timer = (ent->client->grenade_framenum - level.framenum) * FRAMETIME;
	speed = (int)(GRENADE_MINSPEED + (GRENADE_TIMER - timer) * ((GRENADE_MAXSPEED - GRENADE_MINSPEED) / GRENADE_TIMER));
	fire_grenade2(ent, start, forward, damage, speed, timer, radius, held);

	// TODO
	//if (!dmflags->intVal & DF_INFINITE_AMMO)
	//	ent->client->pers.inventory[ent->client->ammo_index]--;

	ent->client->grenade_framenum = (int)(level.framenum + 1.0f * BASE_FRAMERATE);

	if (ent->deadflag || ent->s.modelindex != 255) { // VWep animations screw up corpses
		return;
	}

	if (ent->health <= 0)
		return;

	if (ent->client->ps.pmove.pm_flags & PMF_DUCKED) {
		ent->client->anim_priority = ANIM_ATTACK;
		ent->s.frame = FRAME_crattak1 - 1;
		ent->client->anim_end = FRAME_crattak3;
	} else {
		ent->client->anim_priority = ANIM_REVERSE;
		ent->s.frame = FRAME_wave08;
		ent->client->anim_end = FRAME_wave01;
	}
}

void(entity ent) Weapon_Grenade =
{
	if ((ent->client->newweapon) && (ent->client->weaponstate == WEAPON_READY)) {
		ChangeWeapon(ent);
		return;
	}

	if (ent->client->weaponstate == WEAPON_ACTIVATING) {
		ent->client->weaponstate = WEAPON_READY;
		ent->client->ps.gunframe = 16;
		return;
	}

	if (ent->client->weaponstate == WEAPON_READY) {
		if (((ent->client->latched_buttons | ent->client->buttons) & BUTTON_ATTACK)) {
			ent->client->latched_buttons &= ~BUTTON_ATTACK;
			// TODO
			/*if (ent->client->pers.inventory[ent->client->ammo_index]) {*/
				ent->client->ps.gunframe = 1;
				ent->client->weaponstate = WEAPON_FIRING;
				ent->client->grenade_framenum = 0;
			/*} else {
				if (level.framenum >= ent->pain_debounce_framenum) {
					gi.sound(ent, CHAN_VOICE, gi.soundindex("weapons/noammo.wav"), 1, ATTN_NORM, 0);
					ent->pain_debounce_framenum = level.framenum + 1 * BASE_FRAMERATE;
				}
				NoAmmoWeaponChange(ent);
			}*/
			return;
		}

		if ((ent->client->ps.gunframe == 29) || (ent->client->ps.gunframe == 34) || (ent->client->ps.gunframe == 39) || (ent->client->ps.gunframe == 48)) {
			if (Q_rand() & 15)
				return;
		}

		if (++ent->client->ps.gunframe > 48)
			ent->client->ps.gunframe = 16;
		return;
	}

	if (ent->client->weaponstate == WEAPON_FIRING) {
		if (ent->client->ps.gunframe == 5)
			gi.sound(ent, CHAN_WEAPON, gi.soundindex("weapons/hgrena1b.wav"), 1, ATTN_NORM, 0);

		if (ent->client->ps.gunframe == 11) {
			if (!ent->client->grenade_framenum) {
				ent->client->grenade_framenum = (int)(level.framenum + (GRENADE_TIMER + 0.2f) * BASE_FRAMERATE);
				ent->client->weapon_sound = gi.soundindex("weapons/hgrenc1b.wav");
			}

			// they waited too long, detonate it in their hand
			if (!ent->client->grenade_blew_up && level.framenum >= ent->client->grenade_framenum) {
				ent->client->weapon_sound = 0;
				weapon_grenade_fire(ent, true);
				ent->client->grenade_blew_up = true;
			}

			if (ent->client->buttons & BUTTON_ATTACK)
				return;

			if (ent->client->grenade_blew_up) {
				if (level.framenum >= ent->client->grenade_framenum) {
					ent->client->ps.gunframe = 15;
					ent->client->grenade_blew_up = false;
				} else {
					return;
				}
			}
		}

		if (ent->client->ps.gunframe == 12) {
			ent->client->weapon_sound = 0;
			weapon_grenade_fire(ent, false);
		}

		if ((ent->client->ps.gunframe == 15) && (level.framenum < ent->client->grenade_framenum))
			return;

		ent->client->ps.gunframe++;

		if (ent->client->ps.gunframe == 16) {
			ent->client->grenade_framenum = 0;
			ent->client->weaponstate = WEAPON_READY;
		}
	}
}

/*
======================================================================

GRENADE LAUNCHER

======================================================================
*/

static void(entity ent) weapon_grenadelauncher_fire =
{
	vector	offset;
	vector	forward, right;
	vector	start;
	int	damage = 120;
	float	radius;

	radius = damage + 40f;
	if (is_quad)
		damage *= 4;

	VectorSet(offset, 8, 8, ent->viewheight - 8);
	AngleVectors(ent->client->v_angle, forward, right, unref_vec);
	P_ProjectSource(ent, ent->s.origin, offset, forward, right, start);

	VectorScale(forward, -2, ent->client->kick_origin);
	ent->client->kick_angles[(ARRAY_INDEX_TYPE)0] = -1f;

	fire_grenade(ent, start, forward, damage, 600, 2.5f, radius);

	gi.WriteByte(svc_muzzleflash);
	gi.WriteShort(ent.s.number);
	gi.WriteByte(MZ_GRENADE | is_silenced);
	gi.multicast(ent->s.origin, MULTICAST_PVS);

	ent->client->ps.gunframe++;

	PlayerNoise(ent, start, PNOISE_WEAPON);

	// TODO
	//if (!((int)dmflags->value & DF_INFINITE_AMMO))
	//	ent->client->pers.inventory[ent->client->ammo_index]--;
}

void(entity ent) Weapon_GrenadeLauncher =
{
	static int(int frame) is_pause_frame =
	{
		return frame == 34 || frame == 51 || frame == 59;
	};

	static int(int frame) is_fire_frame =
	{
		return frame == 6;
	};

	Weapon_Generic(ent, 5, 16, 59, 64, is_pause_frame, is_fire_frame, weapon_grenadelauncher_fire);
}

/*
======================================================================

ROCKET

======================================================================
*/

static void(entity ent) Weapon_RocketLauncher_Fire =
{
	vector	offset, start;
	vector	forward, right;
	int	damage;
	float	damage_radius;
	int	radius_damage;

	damage = 100 + (int)(frand() * 20.0f);
	radius_damage = 120;
	damage_radius = 120f;
	if (is_quad) {
		damage *= 4;
		radius_damage *= 4;
	}

	AngleVectors(ent->client->v_angle, forward, right, unref_vec);

	VectorScale(forward, -2, ent->client->kick_origin);
	ent->client->kick_angles[(ARRAY_INDEX_TYPE)0] = -1f;

	VectorSet(offset, 8, 8, ent->viewheight - 8);
	P_ProjectSource(ent, ent->s.origin, offset, forward, right, start);
	fire_rocket(ent, start, forward, damage, 650, damage_radius, radius_damage);

	// send muzzle flash
	gi.WriteByte(svc_muzzleflash);
	gi.WriteShort(ent.s.number);
	gi.WriteByte(MZ_ROCKET | is_silenced);
	gi.multicast(ent->s.origin, MULTICAST_PVS);

	ent->client->ps.gunframe++;

	PlayerNoise(ent, start, PNOISE_WEAPON);

	// TODO
	//if (!(dmflags->intVal & DF_INFINITE_AMMO))
	//	ent->client->pers.inventory[ent->client->ammo_index]--;
}

void(entity ent) Weapon_RocketLauncher =
{
	static int(int frame) is_pause_frame =
	{
		return frame == 25 || frame == 33 || frame == 42 || frame == 50;
	};

	static int(int frame) is_fire_frame =
	{
		return frame == 5;
	};

	Weapon_Generic(ent, 4, 12, 50, 54, is_pause_frame, is_fire_frame, Weapon_RocketLauncher_Fire);
}


/*
======================================================================

BLASTER / HYPERBLASTER

======================================================================
*/

static void(entity ent, vector g_offset, int damage, bool hyper, int effect) Blaster_Fire =
{
	vector	forward, right;
	vector	start;
	vector	offset;

	if (is_quad)
		damage *= 4;
	AngleVectors(ent->client->v_angle, forward, right, unref_vec);
	VectorSet(offset, 24, 8, ent->viewheight - 8);
	VectorAdd(offset, g_offset, offset);
	P_ProjectSource(ent, ent->s.origin, offset, forward, right, start);

	VectorScale(forward, -2, ent->client->kick_origin);
	ent->client->kick_angles[(ARRAY_INDEX_TYPE)0] = -1f;

	fire_blaster(ent, start, forward, damage, 1000, effect, hyper);

	// send muzzle flash
	gi.WriteByte(svc_muzzleflash);
	gi.WriteShort(ent.s.number);
	if (hyper)
		gi.WriteByte(MZ_HYPERBLASTER | is_silenced);
	else
		gi.WriteByte(MZ_BLASTER | is_silenced);
	gi.multicast(ent->s.origin, MULTICAST_PVS);

	PlayerNoise(ent, start, PNOISE_WEAPON);
}


static void(entity ent) Weapon_Blaster_Fire =
{
	int     damage;

	if (deathmatch->intVal)
		damage = 15;
	else
		damage = 10;
	Blaster_Fire(ent, vec3_origin, damage, false, EF_BLASTER);
	ent->client->ps.gunframe++;
}

void(entity ent) Weapon_Blaster =
{
	static int(int frame) is_pause_frame =
	{
		return frame == 19 || frame == 32;
	};

	static int(int frame) is_fire_frame =
	{
		return frame == 5;
	};

	Weapon_Generic(ent, 4, 8, 52, 55, is_pause_frame, is_fire_frame, Weapon_Blaster_Fire);
}


static void(entity ent) Weapon_HyperBlaster_Fire =
{
	float	rotation;
	vector	offset;
	int	effect;
	int	damage;

	ent->client->weapon_sound = gi.soundindex("weapons/hyprbl1a.wav");

	if (!(ent->client->buttons & BUTTON_ATTACK)) {
		ent->client->ps.gunframe++;
	} else {
		// TODO
		/*if (! ent->client->pers.inventory[ent->client->ammo_index]) {
			if (level.framenum >= ent->pain_debounce_framenum) {
				gi.sound(ent, CHAN_VOICE, gi.soundindex("weapons/noammo.wav"), 1, ATTN_NORM, 0);
				ent->pain_debounce_framenum = level.framenum + 1 * BASE_FRAMERATE;
			}
			NoAmmoWeaponChange(ent);
		} else {*/
			rotation = (ent->client->ps.gunframe - 5) * (M_PI / 3);
			offset_x = -4f * sinf(rotation);
			offset_y = 0;
			offset_z = 4f * cosf(rotation);

			if ((ent->client->ps.gunframe == 6) || (ent->client->ps.gunframe == 9))
				effect = EF_HYPERBLASTER;
			else
				effect = 0;
			if (deathmatch->intVal)
				damage = 15;
			else
				damage = 20;
			Blaster_Fire(ent, offset, damage, true, effect);
			// TODO
			//if (!((int)dmflags->value & DF_INFINITE_AMMO))
			//	ent->client->pers.inventory[ent->client->ammo_index]--;

			ent->client->anim_priority = ANIM_ATTACK;
			if (ent->client->ps.pmove.pm_flags & PMF_DUCKED) {
				ent->s.frame = FRAME_crattak1 - 1;
				ent->client->anim_end = FRAME_crattak9;
			} else {
				ent->s.frame = FRAME_attack1 - 1;
				ent->client->anim_end = FRAME_attack8;
			}
		/*}*/

		ent->client->ps.gunframe++;
		
		// TODO
		if (ent->client->ps.gunframe == 12/* && ent->client->pers.inventory[ent->client->ammo_index]*/)
			ent->client->ps.gunframe = 6;
	}

	if (ent->client->ps.gunframe == 12) {
		gi.sound(ent, CHAN_AUTO, gi.soundindex("weapons/hyprbd1a.wav"), 1, ATTN_NORM, 0);
		ent->client->weapon_sound = 0;
	}

}

void(entity ent) Weapon_HyperBlaster = 
{
	static int(int frame) is_fire_frame =
	{
		return frame >= 6 && frame <= 11;
	};

	Weapon_Generic(ent, 5, 20, 49, 53, 0, is_fire_frame, Weapon_HyperBlaster_Fire);
}

/*
======================================================================

MACHINEGUN / CHAINGUN

======================================================================
*/

static void(entity ent) Machinegun_Fire =
{
	int	i;
	vector	start;
	vector	forward, right;
	vector	angles;
	int	damage = 8;
	int	kick = 2;
	vector	offset;

	if (!(ent->client->buttons & BUTTON_ATTACK)) {
		ent->client->machinegun_shots = 0;
		ent->client->ps.gunframe++;
		return;
	}

	if (ent->client->ps.gunframe == 5)
		ent->client->ps.gunframe = 4;
	else
		ent->client->ps.gunframe = 5;

	// TODO
	/*if (ent->client->pers.inventory[ent->client->ammo_index] < 1) {
		ent->client->ps.gunframe = 6;
		if (level.framenum >= ent->pain_debounce_framenum) {
			gi.sound(ent, CHAN_VOICE, gi.soundindex("weapons/noammo.wav"), 1, ATTN_NORM, 0);
			ent->pain_debounce_framenum = level.framenum + 1 * BASE_FRAMERATE;
		}
		NoAmmoWeaponChange(ent);
		return;
	}*/

	if (is_quad) {
		damage *= 4;
		kick *= 4;
	}

	/*for (i = 1 ; i < 3 ; i++) {
		ent->client->kick_origin[i] = crandom() * 0.35f;
		ent->client->kick_angles[i] = crandom() * 0.7f;
	}*/
	ent->client->kick_origin[(ARRAY_INDEX_TYPE)1] = crand() * 0.35f;
	ent->client->kick_angles[(ARRAY_INDEX_TYPE)1] = crand() * 0.7f;
	ent->client->kick_origin[(ARRAY_INDEX_TYPE)2] = crand() * 0.35f;
	ent->client->kick_angles[(ARRAY_INDEX_TYPE)2] = crand() * 0.7f;
	
	ent->client->kick_origin[(ARRAY_INDEX_TYPE)0] = crand() * 0.35f;
	ent->client->kick_angles[(ARRAY_INDEX_TYPE)0] = ent->client->machinegun_shots * -1.5f;

	// raise the gun as it is firing
	if (!deathmatch->intVal) {
		ent->client->machinegun_shots++;
		if (ent->client->machinegun_shots > 9)
			ent->client->machinegun_shots = 9;
	}

	// get start / end positions
	VectorAdd(ent->client->v_angle, ent->client->kick_angles, angles);
	AngleVectors(angles, forward, right, unref_vec);
	VectorSet(offset, 0, 8, ent->viewheight - 8);
	P_ProjectSource(ent, ent->s.origin, offset, forward, right, start);
	
	fire_bullet(ent, start, forward, damage, kick, DEFAULT_BULLET_HSPREAD, DEFAULT_BULLET_VSPREAD, MOD_MACHINEGUN);

	gi.WriteByte(svc_muzzleflash);
	gi.WriteShort(ent.s.number);
	gi.WriteByte(MZ_MACHINEGUN | is_silenced);
	gi.multicast(ent->s.origin, MULTICAST_PVS);

	PlayerNoise(ent, start, PNOISE_WEAPON);

	// TODO
	//if (!((int)dmflags->value & DF_INFINITE_AMMO))
	//	ent->client->pers.inventory[ent->client->ammo_index]--;

	ent->client->anim_priority = ANIM_ATTACK;
	if (ent->client->ps.pmove.pm_flags & PMF_DUCKED) {
		ent->s.frame = FRAME_crattak1 - (int)(frand() + 0.25f);
		ent->client->anim_end = FRAME_crattak9;
	} else {
		ent->s.frame = FRAME_attack1 - (int)(frand() + 0.25f);
		ent->client->anim_end = FRAME_attack8;
	}
}

void(entity ent) Weapon_Machinegun =
{
	static int(int frame) is_pause_frame =
	{
		return frame == 23 || frame == 45;
	};
	
	static int(int frame) is_fire_frame =
	{
		return frame == 4 || frame == 5;
	};

	Weapon_Generic(ent, 3, 5, 45, 49, is_pause_frame, is_fire_frame, Machinegun_Fire);
}

static void(entity ent) Chaingun_Fire =
{
	int	i;
	int	shots;
	vector	start;
	vector	forward, right, up;
	float	r, u;
	vector	offset;
	int	damage;
	int	kick = 2;

	if (deathmatch->intVal)
		damage = 6;
	else
		damage = 8;

	if (ent->client->ps.gunframe == 5)
		gi.sound(ent, CHAN_AUTO, gi.soundindex("weapons/chngnu1a.wav"), 1, ATTN_IDLE, 0);

	if ((ent->client->ps.gunframe == 14) && !(ent->client->buttons & BUTTON_ATTACK)) {
		ent->client->ps.gunframe = 32;
		ent->client->weapon_sound = 0;
		return;
	}
	// TODO
	/* else if ((ent->client->ps.gunframe == 21) && (ent->client->buttons & BUTTON_ATTACK)
			   && ent->client->pers.inventory[ent->client->ammo_index]) {
		ent->client->ps.gunframe = 15;
	}*/ else {
		ent->client->ps.gunframe++;
	}

	if (ent->client->ps.gunframe == 22) {
		ent->client->weapon_sound = 0;
		gi.sound(ent, CHAN_AUTO, gi.soundindex("weapons/chngnd1a.wav"), 1, ATTN_IDLE, 0);
	} else {
		ent->client->weapon_sound = gi.soundindex("weapons/chngnl1a.wav");
	}

	ent->client->anim_priority = ANIM_ATTACK;
	if (ent->client->ps.pmove.pm_flags & PMF_DUCKED) {
		ent->s.frame = FRAME_crattak1 - (ent->client->ps.gunframe & 1);
		ent->client->anim_end = FRAME_crattak9;
	} else {
		ent->s.frame = FRAME_attack1 - (ent->client->ps.gunframe & 1);
		ent->client->anim_end = FRAME_attack8;
	}

	if (ent->client->ps.gunframe <= 9)
		shots = 1;
	else if (ent->client->ps.gunframe <= 14) {
		if (ent->client->buttons & BUTTON_ATTACK)
			shots = 2;
		else
			shots = 1;
	} else
		shots = 3;

	// TODO
	//if (ent->client->pers.inventory[ent->client->ammo_index] < shots)
	//	shots = ent->client->pers.inventory[ent->client->ammo_index];

	if (!shots) {
		if (level.framenum >= ent->pain_debounce_framenum) {
			gi.sound(ent, CHAN_VOICE, gi.soundindex("weapons/noammo.wav"), 1, ATTN_NORM, 0);
			ent->pain_debounce_framenum = level.framenum + 1 * BASE_FRAMERATE;
		}
		NoAmmoWeaponChange(ent);
		return;
	}

	if (is_quad) {
		damage *= 4;
		kick *= 4;
	}

	/*for (i = 0 ; i < 3 ; i++) {
		ent->client->kick_origin[i] = crandom() * 0.35f;
		ent->client->kick_angles[i] = crandom() * 0.7f;
	}*/
	ent->client->kick_origin[(ARRAY_INDEX_TYPE)0] = crand() * 0.35f;
	ent->client->kick_angles[(ARRAY_INDEX_TYPE)0] = crand() * 0.7f;
	ent->client->kick_origin[(ARRAY_INDEX_TYPE)1] = crand() * 0.35f;
	ent->client->kick_angles[(ARRAY_INDEX_TYPE)1] = crand() * 0.7f;
	ent->client->kick_origin[(ARRAY_INDEX_TYPE)2] = crand() * 0.35f;
	ent->client->kick_angles[(ARRAY_INDEX_TYPE)2] = crand() * 0.7f;

	for (i = 0 ; i < shots ; i++) {
		// get start / end positions
		AngleVectors(ent->client->v_angle, forward, right, up);
		r = 7 + crand() * 4;
		u = crand() * 4;
		VectorSet(offset, 0, r, u + ent->viewheight - 8);
		P_ProjectSource(ent, ent->s.origin, offset, forward, right, start);

		fire_bullet(ent, start, forward, damage, kick, DEFAULT_BULLET_HSPREAD, DEFAULT_BULLET_VSPREAD, MOD_CHAINGUN);
	}

	// send muzzle flash
	gi.WriteByte(svc_muzzleflash);
	gi.WriteShort(ent.s.number);
	gi.WriteByte((MZ_CHAINGUN1 + shots - 1) | is_silenced);
	gi.multicast(ent->s.origin, MULTICAST_PVS);

	PlayerNoise(ent, start, PNOISE_WEAPON);

	// TODO
	//if (!((int)dmflags->value & DF_INFINITE_AMMO))
	//	ent->client->pers.inventory[ent->client->ammo_index] -= shots;
}


void(entity ent) Weapon_Chaingun =
{
	static int(int frame) is_pause_frame =
	{
		return frame == 38 || frame == 43 || frame == 51 || frame == 61;
	};
	
	static int(int frame) is_fire_frame =
	{
		return frame >= 5 && frame <= 21;
	};
	
	Weapon_Generic(ent, 4, 31, 61, 64, is_pause_frame, is_fire_frame, Chaingun_Fire);
}


/*
======================================================================

SHOTGUN / SUPERSHOTGUN

======================================================================
*/

static void(entity ent) weapon_shotgun_fire =
{
	vector	start;
	vector	forward, right;
	vector	offset;
	int	damage = 4;
	int	kick = 8;

	if (ent->client->ps.gunframe == 9) {
		ent->client->ps.gunframe++;
		return;
	}

	AngleVectors(ent->client->v_angle, forward, right, unref_vec);

	VectorScale(forward, -2, ent->client->kick_origin);
	ent->client->kick_angles[(ARRAY_INDEX_TYPE)0] = -2f;

	VectorSet(offset, 0, 8,  ent->viewheight - 8);
	P_ProjectSource(ent, ent->s.origin, offset, forward, right, start);

	if (is_quad) {
		damage *= 4;
		kick *= 4;
	}

	// TODO
	if (deathmatch->intVal)
		fire_shotgun(ent, start, forward, damage, kick, 500, 500, DEFAULT_DEATHMATCH_SHOTGUN_COUNT, MOD_SHOTGUN);
	else
		fire_shotgun(ent, start, forward, damage, kick, 500, 500, DEFAULT_SHOTGUN_COUNT, MOD_SHOTGUN);

	// send muzzle flash
	gi.WriteByte(svc_muzzleflash);
	gi.WriteShort(ent.s.number);
	gi.WriteByte(MZ_SHOTGUN | is_silenced);
	gi.multicast(ent->s.origin, MULTICAST_PVS);

	ent->client->ps.gunframe++;
	PlayerNoise(ent, start, PNOISE_WEAPON);

	// TODO
	//if (!((int)dmflags->value & DF_INFINITE_AMMO))
	//	ent->client->pers.inventory[ent->client->ammo_index]--;
}

void(entity ent) Weapon_Shotgun =
{
	static int(int frame) is_pause_frame =
	{
		return frame == 22 || frame == 28 || frame == 34 || frame == 0;
	}

	static int(int frame) is_fire_frame =
	{
		return frame == 8 || frame == 9;
	}

	Weapon_Generic(ent, 7, 18, 36, 39, is_pause_frame, is_fire_frame, weapon_shotgun_fire);
}


static void(entity ent) weapon_supershotgun_fire =
{
	vector	start;
	vector	forward, right;
	vector	offset;
	vector	v;
	int         damage = 6;
	int         kick = 12;

	AngleVectors(ent->client->v_angle, forward, right, unref_vec);

	VectorScale(forward, -2, ent->client->kick_origin);
	ent->client->kick_angles[(ARRAY_INDEX_TYPE)0] = -2f;

	VectorSet(offset, 0, 8,  ent->viewheight - 8);
	P_ProjectSource(ent, ent->s.origin, offset, forward, right, start);

	if (is_quad) {
		damage *= 4;
		kick *= 4;
	}

	v[PITCH] = ent->client->v_angle[PITCH];
	v[YAW]   = ent->client->v_angle[YAW] - 5;
	v[ROLL]  = ent->client->v_angle[ROLL];
	AngleVectors(v, forward, unref_vec, unref_vec);
	fire_shotgun(ent, start, forward, damage, kick, DEFAULT_SHOTGUN_HSPREAD, DEFAULT_SHOTGUN_VSPREAD, DEFAULT_SSHOTGUN_COUNT / 2, MOD_SSHOTGUN);
	v[YAW]   = ent->client->v_angle[YAW] + 5;
	AngleVectors(v, forward, unref_vec, unref_vec);
	fire_shotgun(ent, start, forward, damage, kick, DEFAULT_SHOTGUN_HSPREAD, DEFAULT_SHOTGUN_VSPREAD, DEFAULT_SSHOTGUN_COUNT / 2, MOD_SSHOTGUN);

	// send muzzle flash
	gi.WriteByte(svc_muzzleflash);
	gi.WriteShort(ent.s.number);
	gi.WriteByte(MZ_SSHOTGUN | is_silenced);
	gi.multicast(ent->s.origin, MULTICAST_PVS);

	ent->client->ps.gunframe++;
	PlayerNoise(ent, start, PNOISE_WEAPON);

	// TODO
	//if (!((int)dmflags->value & DF_INFINITE_AMMO))
	//	ent->client->pers.inventory[ent->client->ammo_index] -= 2;
}

void(entity ent) Weapon_SuperShotgun =
{
	static int(int frame) is_pause_frame =
	{
		return frame == 29 || frame == 42 || frame == 57;
	}
	
	static int(int frame) is_fire_frame =
	{
		return frame == 7;
	}

	Weapon_Generic(ent, 6, 17, 57, 61, is_pause_frame, is_fire_frame, weapon_supershotgun_fire);
}



/*
======================================================================

RAILGUN

======================================================================
*/

static void(entity ent) weapon_railgun_fire =
{
	vector	start;
	vector	forward, right;
	vector	offset;
	int	damage;
	int	kick;

	if (deathmatch->intVal) {
		// normal damage is too extreme in dm
		damage = 100;
		kick = 200;
	} else {
		damage = 150;
		kick = 250;
	}

	if (is_quad) {
		damage *= 4;
		kick *= 4;
	}

	AngleVectors(ent->client->v_angle, forward, right, unref_vec);

	VectorScale(forward, -3, ent->client->kick_origin);
	ent->client->kick_angles[(ARRAY_INDEX_TYPE)0] = -3f;

	VectorSet(offset, 0, 7,  ent->viewheight - 8);
	P_ProjectSource(ent, ent->s.origin, offset, forward, right, start);
	fire_rail(ent, start, forward, damage, kick);

	// send muzzle flash
	gi.WriteByte(svc_muzzleflash);
	gi.WriteShort(ent.s.number);
	gi.WriteByte(MZ_RAILGUN | is_silenced);
	gi.multicast(ent->s.origin, MULTICAST_PVS);

	ent->client->ps.gunframe++;
	PlayerNoise(ent, start, PNOISE_WEAPON);

	// TODO
	//if (!((int)dmflags->value & DF_INFINITE_AMMO))
	//	ent->client->pers.inventory[ent->client->ammo_index]--;
}


void(entity ent) Weapon_Railgun =
{
	static int(int frame) is_pause_frame =
	{
		return frame == 56;
	}
	
	static int(int frame) is_fire_frame =
	{
		return frame == 4;
	}

	Weapon_Generic(ent, 3, 18, 56, 61, is_pause_frame, is_fire_frame, weapon_railgun_fire);
}


/*
======================================================================

BFG10K

======================================================================
*/

static void(entity ent) weapon_bfg_fire =
{
	vector	offset, start;
	vector	forward, right;
	int	damage;
	float	damage_radius = 1000f;

	if (deathmatch->intVal)
		damage = 200;
	else
		damage = 500;

	if (ent->client->ps.gunframe == 9) {
		// send muzzle flash
		gi.WriteByte(svc_muzzleflash);
		gi.WriteShort(ent.s.number);
		gi.WriteByte(MZ_BFG | is_silenced);
		gi.multicast(ent->s.origin, MULTICAST_PVS);

		ent->client->ps.gunframe++;

		PlayerNoise(ent, start, PNOISE_WEAPON);
		return;
	}

	// cells can go down during windup (from power armor hits), so
	// check again and abort firing if we don't have enough now
	// TODO
	/*if (ent->client->pers.inventory[ent->client->ammo_index] < 50) {
		ent->client->ps.gunframe++;
		return;
	}*/

	if (is_quad)
		damage *= 4;

	AngleVectors(ent->client->v_angle, forward, right, unref_vec);

	VectorScale(forward, -2, ent->client->kick_origin);

	// make a big pitch kick with an inverse fall
	ent->client->v_dmg_pitch = -40f;
	ent->client->v_dmg_roll = crand() * 8f;
	ent->client->v_dmg_time = level.time + DAMAGE_TIME;

	VectorSet(offset, 8, 8, ent->viewheight - 8);
	P_ProjectSource(ent, ent->s.origin, offset, forward, right, start);
	fire_bfg(ent, start, forward, damage, 400, damage_radius);

	ent->client->ps.gunframe++;

	PlayerNoise(ent, start, PNOISE_WEAPON);

	// TODO
	//if (!((int)dmflags->value & DF_INFINITE_AMMO))
	//	ent->client->pers.inventory[ent->client->ammo_index] -= 50;
}

void(entity ent) Weapon_BFG =
{
	static int(int frame) is_pause_frame =
	{
		return frame == 39 || frame == 45 || frame == 50 || frame == 55;
	}
	
	static int(int frame) is_fire_frame = 
	{
		return frame == 9 || frame == 17;
	}

	Weapon_Generic(ent, 8, 32, 55, 58, is_pause_frame, is_fire_frame, weapon_bfg_fire);
}


//======================================================================
