#include "m_player.h"

PROGS_LOCAL bool	is_quad;
PROGS_LOCAL int	is_silenced;

#ifdef THE_RECKONING
PROGS_LOCAL_STATIC bool	is_quadfire;
PROGS_LOCAL void(entity, bool) weapon_trap_fire;
#endif

PROGS_LOCAL int	damage_multiplier;

// Paril: from GZ, but handy to keep here
PROGS_LOCAL void(entity ent) P_DamageModifier =
{
	is_quad = false;
	damage_multiplier = 1;

	if (ent.client.quad_framenum > level.framenum)
	{
		damage_multiplier *= 4;
		is_quad = true;

#ifdef GROUND_ZERO
		// if we're quad and DF_NO_STACK_DOUBLE is on, return now.
		if (dmflags.intVal & DF_NO_STACK_DOUBLE)
			return;
#endif
	}
	
#ifdef GROUND_ZERO
	if (ent.client.double_framenum > level.framenum)
	{
		if (deathmatch.intVal || damage_multiplier == 1)
		{
			damage_multiplier *= 2;
			is_quad = true;
		}
	}
#endif
}

PROGS_LOCAL void(entity, bool) weapon_grenade_fire;

const vector handedness_scales = '1 -1 0';

PROGS_LOCAL INLINE vector(entity ent, vector point, vector distance, vector forward, vector right) P_ProjectSource =
{
	vector scaled_dist = [ distance[0], distance[1] * handedness_scales[ent.client.pers.hand], distance[2] ];
	return G_ProjectSource(point, scaled_dist, forward, right);
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

	if (type == PNOISE_WEAPON)
	{
		if (who.client.silencer_shots)
		{
			who.client.silencer_shots--;
			return;
		}
	}

	if (deathmatch.intVal)
		return;

	if (who.flags & FL_NOTARGET)
		return;

#ifdef GROUND_ZERO
	if (who.flags & FL_DISGUISED)
	{
		if (type != PNOISE_WEAPON)
			return;

		level.disguise_violator = who;
		level.disguise_violation_framenum = level.framenum + 5;
	}
#endif

	if (!who.mynoise) {
		noise = G_Spawn();
		noise.classname = "player_noise";
		noise.mins = '-8 -8 -8';
		noise.maxs = '8 8 8';
		noise.owner = who;
		noise.svflags = SVF_NOCLIENT;
		who.mynoise = noise;

		noise = G_Spawn();
		noise.classname = "player_noise";
		noise.mins = '-8 -8 -8';
		noise.maxs = '8 8 8';
		noise.owner = who;
		noise.svflags = SVF_NOCLIENT;
		who.mynoise2 = noise;
	}

	if (type == PNOISE_SELF || type == PNOISE_WEAPON) {
		noise = who.mynoise;
		level.sound_entity = noise;
		level.sound_entity_framenum = level.framenum;
	} else { // type == PNOISE_IMPACT
		noise = who.mynoise2;
		level.sound2_entity = noise;
		level.sound2_entity_framenum = level.framenum;
	}

	noise.s.origin = where;
	noise.absmin = where + noise.maxs;
	noise.absmax = where + noise.maxs;
	noise.last_sound_framenum = level.framenum;
	gi.linkentity(noise);
}


API_FUNC static bool(entity ent, entity other) Pickup_Weapon =
{
	int	index = ent.item->id;

	if (((dmflags.intVal & DF_WEAPONS_STAY) || coop.intVal)
		&& other.client.pers.inventory[index]) {
		if (!(ent.spawnflags & (DROPPED_ITEM | DROPPED_PLAYER_ITEM)))
			return false;   // leave the weapon for others to pickup
	}

	other.client.pers.inventory[index]++;

	if (!(ent.spawnflags & DROPPED_ITEM))
	{
		// give them some ammo with it
		if (ent.item->ammo)
		{
			gitem_t *ammo = FindItem(ent.item->ammo);
			Add_Ammo(other, ammo, ammo->quantity);
		}

		if (!(ent.spawnflags & DROPPED_PLAYER_ITEM))
		{
			if (deathmatch.intVal)
			{
				if (dmflags.intVal & DF_WEAPONS_STAY)
					ent.flags |= FL_RESPAWN;
				else
					SetRespawn(ent, 30);
			}
			if (coop.intVal)
				ent.flags |= FL_RESPAWN;
		}
	}

	if (other.client.pers.weapon != ent.item &&
		(other.client.pers.inventory[index] == 1) &&
		(!deathmatch.intVal || other.client.pers.weapon == FindItem("blaster")))
		other.client.newweapon = ent.item;

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

	if (ent.client.grenade_framenum)
	{
		ent.client.grenade_framenum = level.framenum;
		ent.client.weapon_sound = 0;
		weapon_grenade_fire(ent, false);
		ent.client.grenade_framenum = 0;
	}
	
#ifdef THE_RECKONING
	if (ent.client.trap_framenum)
	{
		ent.client.trap_framenum = level.framenum;
		ent.client.weapon_sound = 0;
		weapon_trap_fire(ent, false);
		ent.client.trap_framenum = 0;
	}
#endif

	ent.client.pers.lastweapon = ent.client.pers.weapon;
	ent.client.pers.weapon = ent.client.newweapon;
	ent.client.newweapon = 0;
	ent.client.machinegun_shots = 0;

	// set visible model
	if (ent.s.modelindex == 255)
	{
		if (ent.client.pers.weapon)
			i = (ent.client.pers.weapon->weapmodel & 0xff) << 8;
		else
			i = 0;
		ent.s.skinnum = ent.s.number | i;
	}

	if (ent.client.pers.weapon && ent.client.pers.weapon->ammo)
			ent.client.ammo_index = FindItem(ent.client.pers.weapon->ammo)->id;
	else
		ent.client.ammo_index = 0;

	if (!ent.client.pers.weapon) {
		// dead
		ent.client.ps.gunindex = 0;
		return;
	}

	ent.client.weaponstate = WEAPON_ACTIVATING;
	ent.client.ps.gunframe = 0;
	ent.client.ps.gunindex = gi.modelindex(ent.client.pers.weapon->view_model);

	ent.client.anim_priority = ANIM_PAIN;
	if (ent.client.ps.pmove.pm_flags & PMF_DUCKED) {
		ent.s.frame = FRAME_crpain1;
		ent.client.anim_end = FRAME_crpain4;
	} else {
		ent.s.frame = FRAME_pain301;
		ent.client.anim_end = FRAME_pain304;

	}
}

/*
=================
NoAmmoWeaponChange
=================
*/
PROGS_LOCAL void(entity ent) NoAmmoWeaponChange =
{
	if (ent.client.pers.inventory[FindItem("slugs")->id]
		&& ent.client.pers.inventory[FindItem("railgun")->id]) {
		ent.client.newweapon = FindItem("railgun");
		return;
	}
	
#ifdef THE_RECKONING
	if (ent.client.pers.inventory[FindItem("mag slug")->id]
		&& ent.client.pers.inventory[FindItem("phalanx")->id])
	{
		ent.client.newweapon = FindItem("phalanx");
		return;
	}
	if ( ent.client.pers.inventory[FindItem("cells")->id]
		&& ent.client.pers.inventory[FindItem("ionripper")->id])
	{
		ent.client.newweapon = FindItem("ionripper");
		return;
	}
#endif

#ifdef GROUND_ZERO
	if ((ent.client.pers.inventory[FindItem("cells")->id] >= 2)
		&& ent.client.pers.inventory[FindItem("Plasma Beam")->id])
	{
		ent.client.newweapon = FindItem ("Plasma Beam");
		return;
	}

	if (ent.client.pers.inventory[FindItem("flechettes")->id]
		&&  ent.client.pers.inventory[FindItem("etf rifle")->id])
	{
		ent.client.newweapon = FindItem ("etf rifle");
		return;
	}
#endif
	
	if (ent.client.pers.inventory[FindItem("cells")->id]
		&& ent.client.pers.inventory[FindItem("hyperblaster")->id]) {
		ent.client.newweapon = FindItem("hyperblaster");
		return;
	}
	
	if (ent.client.pers.inventory[FindItem("bullets")->id]
		&& ent.client.pers.inventory[FindItem("chaingun")->id]) {
		ent.client.newweapon = FindItem("chaingun");
		return;
	}
	if (ent.client.pers.inventory[FindItem("bullets")->id]
		&& ent.client.pers.inventory[FindItem("machinegun")->id]) {
		ent.client.newweapon = FindItem("machinegun");
		return;
	}
	if (ent.client.pers.inventory[FindItem("shells")->id] > 1
		&& ent.client.pers.inventory[FindItem("super shotgun")->id]) {
		ent.client.newweapon = FindItem("super shotgun");
		return;
	}
	if (ent.client.pers.inventory[FindItem("shells")->id]
		&& ent.client.pers.inventory[FindItem("shotgun")->id]) {
		ent.client.newweapon = FindItem("shotgun");
		return;
	}
	ent.client.newweapon = FindItem("blaster");
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
	if (ent.health < 1) {
		ent.client.newweapon = 0;
		ChangeWeapon(ent);
	}

	// call active weapon think routine
	if (ent.client.pers.weapon && ent.client.pers.weapon->weaponthink)
	{
		P_DamageModifier(ent);
#ifdef THE_RECKONING
		is_quadfire = (ent.client.quadfire_framenum > level.framenum);
#endif
		if (ent.client.silencer_shots)
			is_silenced = MZ_SILENCED;
		else
			is_silenced = 0;
		ent.client.pers.weapon->weaponthink(ent);
	}
}


/*
================
Use_Weapon

Make the weapon ready if there is ammo
================
*/
typedef enum : int
{
	USEWEAP_OK,
	USEWEAP_NO_AMMO,
	USEWEAP_NOT_ENOUGH_AMMO,
	USEWEAP_IS_ACTIVE,
	USEWEAP_OUT_OF_ITEM
} useweap_t;

static useweap_t(entity ent, gitem_t *it) CanUseWeapon =
{
	if (it == ent.client.pers.weapon)
		return USEWEAP_IS_ACTIVE;

	if (!ent.client.pers.inventory[it->id])
		return USEWEAP_OUT_OF_ITEM;
	
	if (it->ammo && !g_select_empty.intVal && !(it->flags & IT_AMMO))
	{
		gitem_t *ammo_item = FindItem(it->ammo);
		gitem_id_t ammo_index = ammo_item->id;

		if (!ent.client.pers.inventory[ammo_index])
			return USEWEAP_NO_AMMO;

		if (ent.client.pers.inventory[ammo_index] < it->quantity)
			return USEWEAP_NOT_ENOUGH_AMMO;
	}

	return USEWEAP_OK;
};

#ifdef THE_RECKONING
static const string rail_chain[] = { "Railgun", "Phalanx" };
#endif

#ifdef GROUND_ZERO
static const string grenadelauncher_chain[] = { "Grenade Launcher", "Prox Launcher" };
static const string machinegun_chain[] = { "Machinegun", "ETF Rifle" };
static const string blaster_chain[] = { "Blaster", "Chainfist" };
static const string bfg_chain[] = { "BFG10k", "Disruptor" };
#endif

#if (defined(GROUND_ZERO) && defined(THE_RECKONING))
static const string grenade_chain[] = { "Grenades", "Trap", "Tesla"};
static const string hyperblaster_chain[] = { "HyperBlaster", "Ionripper", "Plasma Beam" };
#elif defined(GROUND_ZERO)
static const string grenade_chain[] = { "Grenades", "Tesla"};
static const string hyperblaster_chain[] = { "HyperBlaster", "Plasma Beam" };
#elif defined(THE_RECKONING)
static const string grenade_chain[] = { "Grenades", "Trap" };
static const string hyperblaster_chain[] = { "HyperBlaster", "Ionripper" };
#endif

static bool(entity ent, gitem_t *it, out string *chain, out int chain_length) GetChain =
{
	chain = 0;

#if defined(GROUND_ZERO) || defined(THE_RECKONING)
	if (it->pickup_name == "HyperBlaster")
	{
		chain = hyperblaster_chain;
		chain_length = hyperblaster_chain.length;
	}
	else if (it->pickup_name == "Grenades")
	{
		chain = grenade_chain;
		chain_length = grenade_chain.length;
	}
#endif
#if defined(GROUND_ZERO)
	else if (it->pickup_name == "Grenade Launcher")
	{
		chain = grenadelauncher_chain;
		chain_length = grenadelauncher_chain.length;
	}
	else if (it->pickup_name == "Machinegun")
	{
		chain = machinegun_chain;
		chain_length = machinegun_chain.length;
	}
	else if (it->pickup_name == "Blaster")
	{
		chain = blaster_chain;
		chain_length = blaster_chain.length;
	}
	else if (it->pickup_name == "BFG10k")
	{
		chain = bfg_chain;
		chain_length = bfg_chain.length;
	}
#endif
#if defined(THE_RECKONING)
	else if (it->pickup_name == "Railgun")
	{
		chain = rail_chain;
		chain_length = rail_chain.length;
	}
#endif

	return !!chain;
};

API_FUNC static void(entity ent, gitem_t *it) Use_Weapon =
{
	string	*chain;
	int	chain_length;

	// we have a weapon chain; find our current position in this chain
	if (GetChain(ent, it, chain, chain_length))
	{
		int chain_start = 0;

		for (string *c = chain; c < chain + chain_length; c++)
		{
			gitem_t *cit = FindItem(*c);
			
			if (!cit)
			{
				gi.dprintf("Bad chain specified: %s", *c);
				continue;
			}

			if (ent.client.pers.weapon == cit || ent.client.newweapon == cit)
			{
				chain_start = (c - chain) + 1;
				break;
			}
		}

		// find the next weapon we can equip that doesn't return false
		for (int cid = 0; cid < chain_length; cid++)
		{
			gitem_t *cit = FindItem(chain[(chain_start + cid) % chain_length]);
			
			// got it!
			if (CanUseWeapon(ent, cit) == USEWEAP_OK)
			{
				ent.client.newweapon = cit;
				return;
			}
		}

		// fall back to default warning message
	}
	
	useweap_t result = CanUseWeapon(ent, it);
	gitem_t *ammo_item = it->ammo ? FindItem(it->ammo) : 0;

	switch (result)
	{
	case USEWEAP_IS_ACTIVE:
		return;
	case USEWEAP_NO_AMMO:
		gi.cprintf(ent, PRINT_HIGH, "No %s for %s.\n", ammo_item->pickup_name, it->pickup_name);
		return;
	case USEWEAP_NOT_ENOUGH_AMMO:
		gi.cprintf(ent, PRINT_HIGH, "No %s for %s.\n", ammo_item->pickup_name, it->pickup_name);
		return;
	}

	// change to this weapon when down
	ent.client.newweapon = it;
}



/*
================
Drop_Weapon
================
*/
void(entity ent, gitem_t *it) Drop_Weapon =
{
	if (dmflags.intVal & DF_WEAPONS_STAY)
		return;

	int index = it->id;
	// see if we're already using it
	if (((it == ent.client.pers.weapon) || (it == ent.client.newweapon)) && (ent.client.pers.inventory[index] == 1))
	{
		gi.cprintf(ent, PRINT_HIGH, "Can't drop current weapon\n");
		return;
	}

	Drop_Item(ent, it);
	
	ent.client.pers.inventory[index]--;
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

typedef void(entity ent, int FRAME_ACTIVATE_LAST, int FRAME_FIRE_LAST, int FRAME_IDLE_LAST, int FRAME_DEACTIVATE_LAST, bool(int) is_pause_frame, bool(int) is_fire_frame, void(entity) fire) Weapon_Generic_Func;

#ifdef THE_RECKONING
PROGS_LOCAL_STATIC Weapon_Generic_Func Weapon_Generic_ =
#else
PROGS_LOCAL Weapon_Generic_Func Weapon_Generic =
#endif
{
	if (ent.deadflag || ent.s.modelindex != 255) { // VWep animations screw up corpses
		return;
	}

	if (ent.client.weaponstate == WEAPON_DROPPING) {
		if (ent.client.ps.gunframe == FRAME_DEACTIVATE_LAST) {
			ChangeWeapon(ent);
			return;
		} else if ((FRAME_DEACTIVATE_LAST - ent.client.ps.gunframe) == 4) {
			ent.client.anim_priority = ANIM_REVERSE;
			if (ent.client.ps.pmove.pm_flags & PMF_DUCKED) {
				ent.s.frame = FRAME_crpain4 + 1;
				ent.client.anim_end = FRAME_crpain1;
			} else {
				ent.s.frame = FRAME_pain304 + 1;
				ent.client.anim_end = FRAME_pain301;

			}
		}

		ent.client.ps.gunframe++;
		return;
	}

	if (ent.client.weaponstate == WEAPON_ACTIVATING) {
		if (ent.client.ps.gunframe == FRAME_ACTIVATE_LAST) {
			ent.client.weaponstate = WEAPON_READY;
			ent.client.ps.gunframe = FRAME_IDLE_FIRST;
			return;
		}

		ent.client.ps.gunframe++;
		return;
	}

	if ((ent.client.newweapon) && (ent.client.weaponstate != WEAPON_FIRING)) {
		ent.client.weaponstate = WEAPON_DROPPING;
		ent.client.ps.gunframe = FRAME_DEACTIVATE_FIRST;

		if ((FRAME_DEACTIVATE_LAST - FRAME_DEACTIVATE_FIRST) < 4) {
			ent.client.anim_priority = ANIM_REVERSE;
			if (ent.client.ps.pmove.pm_flags & PMF_DUCKED) {
				ent.s.frame = FRAME_crpain4 + 1;
				ent.client.anim_end = FRAME_crpain1;
			} else {
				ent.s.frame = FRAME_pain304 + 1;
				ent.client.anim_end = FRAME_pain301;

			}
		}
		return;
	}

	if (ent.client.weaponstate == WEAPON_READY) {
		if (((ent.client.latched_buttons | ent.client.buttons) & BUTTON_ATTACK)) {
			ent.client.latched_buttons &= ~BUTTON_ATTACK;
			if (!ent.client.ammo_index || 
				(ent.client.pers.inventory[ent.client.ammo_index] >= ent.client.pers.weapon->quantity)) {
				ent.client.ps.gunframe = FRAME_FIRE_FIRST;
				ent.client.weaponstate = WEAPON_FIRING;

				// start the animation
				ent.client.anim_priority = ANIM_ATTACK;
				if (ent.client.ps.pmove.pm_flags & PMF_DUCKED) {
					ent.s.frame = FRAME_crattak1 - 1;
					ent.client.anim_end = FRAME_crattak9;
				} else {
					ent.s.frame = FRAME_attack1 - 1;
					ent.client.anim_end = FRAME_attack8;
				}
			} else {
				if (level.framenum >= ent.pain_debounce_framenum) {
					gi.sound(ent, CHAN_VOICE, gi.soundindex("weapons/noammo.wav"), 1, ATTN_NORM, 0);
					ent.pain_debounce_framenum = level.framenum + 1 * BASE_FRAMERATE;
				}
				NoAmmoWeaponChange(ent);
			}
		} else {
			if (ent.client.ps.gunframe == FRAME_IDLE_LAST) {
				ent.client.ps.gunframe = FRAME_IDLE_FIRST;
				return;
			}

			if (is_pause_frame && is_pause_frame(ent.client.ps.gunframe) && (Q_rand() & 15))
				return;

			ent.client.ps.gunframe++;
			return;
		}
	}

	if (ent.client.weaponstate == WEAPON_FIRING) {
		if (is_fire_frame(ent.client.ps.gunframe)) {
			if (ent.client.quad_framenum > level.framenum)
				gi.sound(ent, CHAN_ITEM, gi.soundindex("items/damage3.wav"), 1, ATTN_NORM, 0);
#ifdef GROUND_ZERO
			else if (ent.client.double_framenum > level.framenum)
				gi.sound(ent, CHAN_ITEM, gi.soundindex("misc/ddamage3.wav"), 1, ATTN_NORM, 0);
#endif

			fire(ent);
		}
		else
			ent.client.ps.gunframe++;

		if (ent.client.ps.gunframe == FRAME_IDLE_FIRST + 1)
			ent.client.weaponstate = WEAPON_READY;
	}
}

#ifdef THE_RECKONING
PROGS_LOCAL Weapon_Generic_Func Weapon_Generic =
{
	Weapon_Generic_(ent, FRAME_ACTIVATE_LAST, FRAME_FIRE_LAST, FRAME_IDLE_LAST, FRAME_DEACTIVATE_LAST, is_pause_frame, is_fire_frame, fire);

	if (is_quadfire)
		Weapon_Generic_(ent, FRAME_ACTIVATE_LAST, FRAME_FIRE_LAST, FRAME_IDLE_LAST, FRAME_DEACTIVATE_LAST, is_pause_frame, is_fire_frame, fire);
};
#endif

/*
======================================================================

GRENADE

======================================================================
*/

const float GRENADE_TIMER	= 3.0f;
const int GRENADE_MINSPEED	= 400;
const int GRENADE_MAXSPEED	= 800;

PROGS_LOCAL void(entity ent, bool held) weapon_grenade_fire =
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
		damage *= damage_multiplier;

	offset = [ 8, 8, ent.viewheight - 8 ];
	AngleVectors(ent.client.v_angle, &forward, &right, 0);
	start = P_ProjectSource(ent, ent.s.origin, offset, forward, right);

	timer = (ent.client.grenade_framenum - level.framenum) * FRAMETIME;
	speed = (int)(GRENADE_MINSPEED + (GRENADE_TIMER - timer) * ((GRENADE_MAXSPEED - GRENADE_MINSPEED) / GRENADE_TIMER));
	fire_grenade2(ent, start, forward, damage, speed, timer, radius, held);

	if (!(dmflags.intVal & DF_INFINITE_AMMO))
		ent.client.pers.inventory[ent.client.ammo_index]--;

	ent.client.grenade_framenum = (int)(level.framenum + 1.0f * BASE_FRAMERATE);

	if (ent.deadflag || ent.s.modelindex != 255) { // VWep animations screw up corpses
		return;
	}

	if (ent.health <= 0)
		return;

	if (ent.client.ps.pmove.pm_flags & PMF_DUCKED) {
		ent.client.anim_priority = ANIM_ATTACK;
		ent.s.frame = FRAME_crattak1 - 1;
		ent.client.anim_end = FRAME_crattak3;
	} else {
		ent.client.anim_priority = ANIM_REVERSE;
		ent.s.frame = FRAME_wave08;
		ent.client.anim_end = FRAME_wave01;
	}
}

void(entity ent) Weapon_Grenade =
{
	if ((ent.client.newweapon) && (ent.client.weaponstate == WEAPON_READY)) {
		ChangeWeapon(ent);
		return;
	}

	if (ent.client.weaponstate == WEAPON_ACTIVATING) {
		ent.client.weaponstate = WEAPON_READY;
		ent.client.ps.gunframe = 16;
		return;
	}

	if (ent.client.weaponstate == WEAPON_READY) {
		if (((ent.client.latched_buttons | ent.client.buttons) & BUTTON_ATTACK)) {
			ent.client.latched_buttons &= ~BUTTON_ATTACK;
			if (ent.client.pers.inventory[ent.client.ammo_index]) {
				ent.client.ps.gunframe = 1;
				ent.client.weaponstate = WEAPON_FIRING;
				ent.client.grenade_framenum = 0;
			} else {
				if (level.framenum >= ent.pain_debounce_framenum) {
					gi.sound(ent, CHAN_VOICE, gi.soundindex("weapons/noammo.wav"), 1, ATTN_NORM, 0);
					ent.pain_debounce_framenum = level.framenum + 1 * BASE_FRAMERATE;
				}
				NoAmmoWeaponChange(ent);
			}
			return;
		}

		if ((ent.client.ps.gunframe == 29) || (ent.client.ps.gunframe == 34) || (ent.client.ps.gunframe == 39) || (ent.client.ps.gunframe == 48)) {
			if (Q_rand() & 15)
				return;
		}

		if (++ent.client.ps.gunframe > 48)
			ent.client.ps.gunframe = 16;
		return;
	}

	if (ent.client.weaponstate == WEAPON_FIRING) {
		if (ent.client.ps.gunframe == 5)
			gi.sound(ent, CHAN_WEAPON, gi.soundindex("weapons/hgrena1b.wav"), 1, ATTN_NORM, 0);

		if (ent.client.ps.gunframe == 11) {
			if (!ent.client.grenade_framenum) {
				ent.client.grenade_framenum = (int)(level.framenum + (GRENADE_TIMER + 0.2f) * BASE_FRAMERATE);
				ent.client.weapon_sound = gi.soundindex("weapons/hgrenc1b.wav");
			}

			// they waited too long, detonate it in their hand
			if (!ent.client.grenade_blew_up && level.framenum >= ent.client.grenade_framenum) {
				ent.client.weapon_sound = 0;
				weapon_grenade_fire(ent, true);
				ent.client.grenade_blew_up = true;
			}

			if (ent.client.buttons & BUTTON_ATTACK)
				return;

			if (ent.client.grenade_blew_up) {
				if (level.framenum >= ent.client.grenade_framenum) {
					ent.client.ps.gunframe = 15;
					ent.client.grenade_blew_up = false;
				} else {
					return;
				}
			}
		}

		if (ent.client.ps.gunframe == 12) {
			ent.client.weapon_sound = 0;
			weapon_grenade_fire(ent, false);
		}

		if ((ent.client.ps.gunframe == 15) && (level.framenum < ent.client.grenade_framenum))
			return;

		ent.client.ps.gunframe++;

		if (ent.client.ps.gunframe == 16) {
			ent.client.grenade_framenum = 0;
			ent.client.weaponstate = WEAPON_READY;
		}
	}
}

/*
======================================================================

GRENADE LAUNCHER

======================================================================
*/

PROGS_LOCAL_STATIC void(entity ent) weapon_grenadelauncher_fire =
{
	vector	offset;
	vector	forward, right;
	vector	start;
#ifdef GROUND_ZERO
	bool	is_prox = ent.client.pers.weapon->weapmodel == WEAP_PROXLAUNCH;
	int	damage = is_prox ? 90 : 120;
#else
	int	damage = 120;
#endif
	float	radius;

	radius = damage + 40f;
	if (is_quad)
		damage *= damage_multiplier;

	offset = [ 8, 8, ent.viewheight - 8 ];
	AngleVectors(ent.client.v_angle, &forward, &right, 0);
	start = P_ProjectSource(ent, ent.s.origin, offset, forward, right);

	ent.client.kick_origin = forward * -2;
	ent.client.kick_angles[0] = -1f;

#ifdef GROUND_ZERO
	if (is_prox)
		fire_prox (ent, start, forward, damage_multiplier, 600);
	else
#endif
		fire_grenade(ent, start, forward, damage, 600, 2.5f, radius);

	gi.WriteByte(svc_muzzleflash);
	gi.WriteShort(ent.s.number);
	gi.WriteByte(MZ_GRENADE | is_silenced);
	gi.multicast(ent.s.origin, MULTICAST_PVS);

	ent.client.ps.gunframe++;

	PlayerNoise(ent, start, PNOISE_WEAPON);

	if (!(dmflags.intVal & DF_INFINITE_AMMO))
		ent.client.pers.inventory[ent.client.ammo_index]--;
}

void(entity ent) Weapon_GrenadeLauncher =
{
	PROGS_LOCAL_STATIC int(int frame) is_pause_frame =
	{
		return frame == 34 || frame == 51 || frame == 59;
	};

	PROGS_LOCAL_STATIC int(int frame) is_fire_frame =
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

PROGS_LOCAL_STATIC void(entity ent) Weapon_RocketLauncher_Fire =
{
	vector	offset, start;
	vector	forward, right;
	int	damage;
	float	damage_radius;
	int	radius_damage;

	damage = (int)random(100f, 120f);
	radius_damage = 120;
	damage_radius = 120f;
	if (is_quad) {
		damage *= damage_multiplier;
		radius_damage *= damage_multiplier;
	}

	AngleVectors(ent.client.v_angle, &forward, &right, 0);

	ent.client.kick_origin = forward * -2;
	ent.client.kick_angles[0] = -1f;

	offset = [ 8, 8, ent.viewheight - 8 ];
	start = P_ProjectSource(ent, ent.s.origin, offset, forward, right);
	fire_rocket(ent, start, forward, damage, 650, damage_radius, radius_damage);

	// send muzzle flash
	gi.WriteByte(svc_muzzleflash);
	gi.WriteShort(ent.s.number);
	gi.WriteByte(MZ_ROCKET | is_silenced);
	gi.multicast(ent.s.origin, MULTICAST_PVS);

	ent.client.ps.gunframe++;

	PlayerNoise(ent, start, PNOISE_WEAPON);

	if (!(dmflags.intVal & DF_INFINITE_AMMO))
		ent.client.pers.inventory[ent.client.ammo_index]--;
}

void(entity ent) Weapon_RocketLauncher =
{
	PROGS_LOCAL_STATIC int(int frame) is_pause_frame =
	{
		return frame == 25 || frame == 33 || frame == 42 || frame == 50;
	};

	PROGS_LOCAL_STATIC int(int frame) is_fire_frame =
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

PROGS_LOCAL_STATIC void(entity ent, vector g_offset, int damage, bool hyper, int effect) Blaster_Fire =
{
	vector	forward, right;
	vector	start;
	vector	offset;

	if (is_quad)
		damage *= damage_multiplier;
	AngleVectors(ent.client.v_angle, &forward, &right, 0);
	offset = [ 24, 8, ent.viewheight - 8 ];
	offset += g_offset;
	start = P_ProjectSource(ent, ent.s.origin, offset, forward, right);

	ent.client.kick_origin = forward * -2;
	ent.client.kick_angles[0] = -1f;

	fire_blaster(ent, start, forward, damage, 1000, effect, hyper);

	// send muzzle flash
	gi.WriteByte(svc_muzzleflash);
	gi.WriteShort(ent.s.number);
	if (hyper)
		gi.WriteByte(MZ_HYPERBLASTER | is_silenced);
	else
		gi.WriteByte(MZ_BLASTER | is_silenced);
	gi.multicast(ent.s.origin, MULTICAST_PVS);

	PlayerNoise(ent, start, PNOISE_WEAPON);
}


PROGS_LOCAL_STATIC void(entity ent) Weapon_Blaster_Fire =
{
	int     damage;

	if (deathmatch.intVal)
		damage = 15;
	else
		damage = 10;
	Blaster_Fire(ent, vec3_origin, damage, false, EF_BLASTER);
	ent.client.ps.gunframe++;
}

void(entity ent) Weapon_Blaster =
{
	PROGS_LOCAL_STATIC int(int frame) is_pause_frame =
	{
		return frame == 19 || frame == 32;
	};

	PROGS_LOCAL_STATIC int(int frame) is_fire_frame =
	{
		return frame == 5;
	};

	Weapon_Generic(ent, 4, 8, 52, 55, is_pause_frame, is_fire_frame, Weapon_Blaster_Fire);
}


PROGS_LOCAL_STATIC void(entity ent) Weapon_HyperBlaster_Fire =
{
	float	rotation;
	vector	offset;
	int	effect;
	int	damage;

	ent.client.weapon_sound = gi.soundindex("weapons/hyprbl1a.wav");

	if (!(ent.client.buttons & BUTTON_ATTACK)) {
		ent.client.ps.gunframe++;
	} else {
		if (! ent.client.pers.inventory[ent.client.ammo_index]) {
			if (level.framenum >= ent.pain_debounce_framenum) {
				gi.sound(ent, CHAN_VOICE, gi.soundindex("weapons/noammo.wav"), 1, ATTN_NORM, 0);
				ent.pain_debounce_framenum = level.framenum + 1 * BASE_FRAMERATE;
			}
			NoAmmoWeaponChange(ent);
		} else {
			rotation = (ent.client.ps.gunframe - 5) * (M_PI / 3);
			offset.x = -4f * sin(rotation);
			offset.y = 0;
			offset.z = 4f * cos(rotation);

			if ((ent.client.ps.gunframe == 6) || (ent.client.ps.gunframe == 9))
				effect = EF_HYPERBLASTER;
			else
				effect = 0;
			if (deathmatch.intVal)
				damage = 15;
			else
				damage = 20;
			Blaster_Fire(ent, offset, damage, true, effect);

			if (!(dmflags.intVal & DF_INFINITE_AMMO))
				ent.client.pers.inventory[ent.client.ammo_index]--;

			ent.client.anim_priority = ANIM_ATTACK;
			if (ent.client.ps.pmove.pm_flags & PMF_DUCKED) {
				ent.s.frame = FRAME_crattak1 - 1;
				ent.client.anim_end = FRAME_crattak9;
			} else {
				ent.s.frame = FRAME_attack1 - 1;
				ent.client.anim_end = FRAME_attack8;
			}
		}

		ent.client.ps.gunframe++;
		
		if (ent.client.ps.gunframe == 12 && ent.client.pers.inventory[ent.client.ammo_index])
			ent.client.ps.gunframe = 6;
	}

	if (ent.client.ps.gunframe == 12) {
		gi.sound(ent, CHAN_AUTO, gi.soundindex("weapons/hyprbd1a.wav"), 1, ATTN_NORM, 0);
		ent.client.weapon_sound = 0;
	}

}

void(entity ent) Weapon_HyperBlaster = 
{
	PROGS_LOCAL_STATIC int(int frame) is_fire_frame =
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

PROGS_LOCAL_STATIC void(entity ent) Machinegun_Fire =
{
	vector	start;
	vector	forward, right;
	vector	angles;
	int	damage = 8;
	int	kick = 2;
	vector	offset;

	if (!(ent.client.buttons & BUTTON_ATTACK)) {
		ent.client.machinegun_shots = 0;
		ent.client.ps.gunframe++;
		return;
	}

	if (ent.client.ps.gunframe == 5)
		ent.client.ps.gunframe = 4;
	else
		ent.client.ps.gunframe = 5;

	if (ent.client.pers.inventory[ent.client.ammo_index] < 1) {
		ent.client.ps.gunframe = 6;
		if (level.framenum >= ent.pain_debounce_framenum) {
			gi.sound(ent, CHAN_VOICE, gi.soundindex("weapons/noammo.wav"), 1, ATTN_NORM, 0);
			ent.pain_debounce_framenum = level.framenum + 1 * BASE_FRAMERATE;
		}
		NoAmmoWeaponChange(ent);
		return;
	}

	if (is_quad) {
		damage *= damage_multiplier;
		kick *= damage_multiplier;
	}

	ent.client.kick_origin[1] = random(-0.35f, 0.35f);
	ent.client.kick_angles[1] = random(-0.7f, 0.7f);
	ent.client.kick_origin[2] = random(-0.35f, 0.35f);
	ent.client.kick_angles[2] = random(-0.7f, 0.7f);
	
	ent.client.kick_origin[0] = random(-0.35f, 0.35f);
	ent.client.kick_angles[0] = ent.client.machinegun_shots * -1.5f;

	// raise the gun as it is firing
	if (!deathmatch.intVal) {
		ent.client.machinegun_shots++;
		if (ent.client.machinegun_shots > 9)
			ent.client.machinegun_shots = 9;
	}

	// get start / end positions
	angles = ent.client.v_angle + ent.client.kick_angles;
	AngleVectors(angles, &forward, &right, 0);
	offset = [ 0, 8, ent.viewheight - 8 ];
	start = P_ProjectSource(ent, ent.s.origin, offset, forward, right);
	
	fire_bullet(ent, start, forward, damage, kick, DEFAULT_BULLET_HSPREAD, DEFAULT_BULLET_VSPREAD, MOD_MACHINEGUN);

	gi.WriteByte(svc_muzzleflash);
	gi.WriteShort(ent.s.number);
	gi.WriteByte(MZ_MACHINEGUN | is_silenced);
	gi.multicast(ent.s.origin, MULTICAST_PVS);

	PlayerNoise(ent, start, PNOISE_WEAPON);

	if (!(dmflags.intVal & DF_INFINITE_AMMO))
		ent.client.pers.inventory[ent.client.ammo_index]--;

	ent.client.anim_priority = ANIM_ATTACK;
	if (ent.client.ps.pmove.pm_flags & PMF_DUCKED) {
		ent.s.frame = FRAME_crattak1 - (int)random(0.25f, 1.25f);
		ent.client.anim_end = FRAME_crattak9;
	} else {
		ent.s.frame = FRAME_attack1 - (int)random(0.25f, 1.25f);
		ent.client.anim_end = FRAME_attack8;
	}
}

void(entity ent) Weapon_Machinegun =
{
	PROGS_LOCAL_STATIC int(int frame) is_pause_frame =
	{
		return frame == 23 || frame == 45;
	};
	
	PROGS_LOCAL_STATIC int(int frame) is_fire_frame =
	{
		return frame == 4 || frame == 5;
	};

	Weapon_Generic(ent, 3, 5, 45, 49, is_pause_frame, is_fire_frame, Machinegun_Fire);
}

PROGS_LOCAL_STATIC void(entity ent) Chaingun_Fire =
{
	int	i;
	int	shots;
	vector	start = vec3_origin;
	vector	forward, right, up;
	float	r, u;
	vector	offset;
	int	damage;
	int	kick = 2;

	if (deathmatch.intVal)
		damage = 6;
	else
		damage = 8;

	if (ent.client.ps.gunframe == 5)
		gi.sound(ent, CHAN_AUTO, gi.soundindex("weapons/chngnu1a.wav"), 1, ATTN_IDLE, 0);

	if ((ent.client.ps.gunframe == 14) && !(ent.client.buttons & BUTTON_ATTACK)) {
		ent.client.ps.gunframe = 32;
		ent.client.weapon_sound = 0;
		return;
	}
	else if ((ent.client.ps.gunframe == 21) && (ent.client.buttons & BUTTON_ATTACK)
			   && ent.client.pers.inventory[ent.client.ammo_index]) {
		ent.client.ps.gunframe = 15;
	} else {
		ent.client.ps.gunframe++;
	}

	if (ent.client.ps.gunframe == 22) {
		ent.client.weapon_sound = 0;
		gi.sound(ent, CHAN_AUTO, gi.soundindex("weapons/chngnd1a.wav"), 1, ATTN_IDLE, 0);
	} else {
		ent.client.weapon_sound = gi.soundindex("weapons/chngnl1a.wav");
	}

	ent.client.anim_priority = ANIM_ATTACK;
	if (ent.client.ps.pmove.pm_flags & PMF_DUCKED) {
		ent.s.frame = FRAME_crattak1 - (ent.client.ps.gunframe & 1);
		ent.client.anim_end = FRAME_crattak9;
	} else {
		ent.s.frame = FRAME_attack1 - (ent.client.ps.gunframe & 1);
		ent.client.anim_end = FRAME_attack8;
	}

	if (ent.client.ps.gunframe <= 9)
		shots = 1;
	else if (ent.client.ps.gunframe <= 14) {
		if (ent.client.buttons & BUTTON_ATTACK)
			shots = 2;
		else
			shots = 1;
	} else
		shots = 3;

	if (ent.client.pers.inventory[ent.client.ammo_index] < shots)
		shots = ent.client.pers.inventory[ent.client.ammo_index];

	if (!shots) {
		if (level.framenum >= ent.pain_debounce_framenum) {
			gi.sound(ent, CHAN_VOICE, gi.soundindex("weapons/noammo.wav"), 1, ATTN_NORM, 0);
			ent.pain_debounce_framenum = level.framenum + 1 * BASE_FRAMERATE;
		}
		NoAmmoWeaponChange(ent);
		return;
	}

	if (is_quad) {
		damage *= damage_multiplier;
		kick *= damage_multiplier;
	}
	
	ent.client.kick_origin = randomv('-0.35 -0.35 -0.35', '0.35 0.35 0.35');
	ent.client.kick_angles = randomv('-0.7 -0.7 -0.7', '0.7 0.7 0.7');

	for (i = 0 ; i < shots ; i++) {
		// get start / end positions
		AngleVectors(ent.client.v_angle, &forward, &right, &up);
		r = random(3f, 11f);
		u = random(-4f, 4f);
		offset = [ 0, r, u + ent.viewheight - 8 ];
		start = P_ProjectSource(ent, ent.s.origin, offset, forward, right);

		fire_bullet(ent, start, forward, damage, kick, DEFAULT_BULLET_HSPREAD, DEFAULT_BULLET_VSPREAD, MOD_CHAINGUN);
	}

	// send muzzle flash
	gi.WriteByte(svc_muzzleflash);
	gi.WriteShort(ent.s.number);
	gi.WriteByte((MZ_CHAINGUN1 + shots - 1) | is_silenced);
	gi.multicast(ent.s.origin, MULTICAST_PVS);

	PlayerNoise(ent, start, PNOISE_WEAPON);

	if (!(dmflags.intVal & DF_INFINITE_AMMO))
		ent.client.pers.inventory[ent.client.ammo_index] -= shots;
}


void(entity ent) Weapon_Chaingun =
{
	PROGS_LOCAL_STATIC int(int frame) is_pause_frame =
	{
		return frame == 38 || frame == 43 || frame == 51 || frame == 61;
	};
	
	PROGS_LOCAL_STATIC int(int frame) is_fire_frame =
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

PROGS_LOCAL_STATIC void(entity ent) weapon_shotgun_fire =
{
	vector	start;
	vector	forward, right;
	vector	offset;
	int	damage = 4;
	int	kick = 8;

	if (ent.client.ps.gunframe == 9) {
		ent.client.ps.gunframe++;
		return;
	}

	AngleVectors(ent.client.v_angle, &forward, &right, 0);

	ent.client.kick_origin = forward * -2;
	ent.client.kick_angles[0] = -2f;

	offset = [ 0, 8,  ent.viewheight - 8 ];
	start = P_ProjectSource(ent, ent.s.origin, offset, forward, right);

	if (is_quad) {
		damage *= damage_multiplier;
		kick *= damage_multiplier;
	}

	if (deathmatch.intVal)
		fire_shotgun(ent, start, forward, damage, kick, 500, 500, DEFAULT_DEATHMATCH_SHOTGUN_COUNT, MOD_SHOTGUN);
	else
		fire_shotgun(ent, start, forward, damage, kick, 500, 500, DEFAULT_SHOTGUN_COUNT, MOD_SHOTGUN);

	// send muzzle flash
	gi.WriteByte(svc_muzzleflash);
	gi.WriteShort(ent.s.number);
	gi.WriteByte(MZ_SHOTGUN | is_silenced);
	gi.multicast(ent.s.origin, MULTICAST_PVS);

	ent.client.ps.gunframe++;
	PlayerNoise(ent, start, PNOISE_WEAPON);

	if (!(dmflags.intVal & DF_INFINITE_AMMO))
		ent.client.pers.inventory[ent.client.ammo_index]--;
}

void(entity ent) Weapon_Shotgun =
{
	PROGS_LOCAL_STATIC int(int frame) is_pause_frame =
	{
		return frame == 22 || frame == 28 || frame == 34 || frame == 0;
	}

	PROGS_LOCAL_STATIC int(int frame) is_fire_frame =
	{
		return frame == 8 || frame == 9;
	}

	Weapon_Generic(ent, 7, 18, 36, 39, is_pause_frame, is_fire_frame, weapon_shotgun_fire);
}

PROGS_LOCAL_STATIC void(entity ent) weapon_supershotgun_fire =
{
	vector	start;
	vector	forward, right;
	vector	offset;
	vector	v;
	int         damage = 6;
	int         kick = 12;

	AngleVectors(ent.client.v_angle, &forward, &right, 0);

	ent.client.kick_origin = forward * -2;
	ent.client.kick_angles[0] = -2f;

	offset = [ 0, 8,  ent.viewheight - 8 ];
	start = P_ProjectSource(ent, ent.s.origin, offset, forward, right);

	if (is_quad) {
		damage *= damage_multiplier;
		kick *= damage_multiplier;
	}

	v[PITCH] = ent.client.v_angle[PITCH];
	v[YAW]   = ent.client.v_angle[YAW] - 5;
	v[ROLL]  = ent.client.v_angle[ROLL];
	AngleVectors(v, &forward, 0, 0);
	fire_shotgun(ent, start, forward, damage, kick, DEFAULT_SHOTGUN_HSPREAD, DEFAULT_SHOTGUN_VSPREAD, DEFAULT_SSHOTGUN_COUNT / 2, MOD_SSHOTGUN);
	v[YAW]   = ent.client.v_angle[YAW] + 5;
	AngleVectors(v, &forward, 0, 0);
	fire_shotgun(ent, start, forward, damage, kick, DEFAULT_SHOTGUN_HSPREAD, DEFAULT_SHOTGUN_VSPREAD, DEFAULT_SSHOTGUN_COUNT / 2, MOD_SSHOTGUN);

	// send muzzle flash
	gi.WriteByte(svc_muzzleflash);
	gi.WriteShort(ent.s.number);
	gi.WriteByte(MZ_SSHOTGUN | is_silenced);
	gi.multicast(ent.s.origin, MULTICAST_PVS);

	ent.client.ps.gunframe++;
	PlayerNoise(ent, start, PNOISE_WEAPON);

	if (!(dmflags.intVal & DF_INFINITE_AMMO))
		ent.client.pers.inventory[ent.client.ammo_index] -= 2;
}

void(entity ent) Weapon_SuperShotgun =
{
	PROGS_LOCAL_STATIC int(int frame) is_pause_frame =
	{
		return frame == 29 || frame == 42 || frame == 57;
	}
	
	PROGS_LOCAL_STATIC int(int frame) is_fire_frame =
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

PROGS_LOCAL_STATIC void(entity ent) weapon_railgun_fire =
{
	vector	start;
	vector	forward, right;
	vector	offset;
	int	damage;
	int	kick;

	if (deathmatch.intVal) {
		// normal damage is too extreme in dm
		damage = 100;
		kick = 200;
	} else {
		damage = 150;
		kick = 250;
	}

	if (is_quad) {
		damage *= damage_multiplier;
		kick *= damage_multiplier;
	}

	AngleVectors(ent.client.v_angle, &forward, &right, 0);

	ent.client.kick_origin = forward * -3;
	ent.client.kick_angles[0] = -3f;

	offset = [ 0, 7,  ent.viewheight - 8 ];
	start = P_ProjectSource(ent, ent.s.origin, offset, forward, right);
	fire_rail(ent, start, forward, damage, kick);

	// send muzzle flash
	gi.WriteByte(svc_muzzleflash);
	gi.WriteShort(ent.s.number);
	gi.WriteByte(MZ_RAILGUN | is_silenced);
	gi.multicast(ent.s.origin, MULTICAST_PVS);

	ent.client.ps.gunframe++;
	PlayerNoise(ent, start, PNOISE_WEAPON);

	if (!(dmflags.intVal & DF_INFINITE_AMMO))
		ent.client.pers.inventory[ent.client.ammo_index]--;
}


void(entity ent) Weapon_Railgun =
{
	PROGS_LOCAL_STATIC int(int frame) is_pause_frame =
	{
		return frame == 56;
	}
	
	PROGS_LOCAL_STATIC int(int frame) is_fire_frame =
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

PROGS_LOCAL_STATIC void(entity ent) weapon_bfg_fire =
{
	vector	offset, start;
	vector	forward, right;
	int	damage;
	float	damage_radius = 1000f;

	if (deathmatch.intVal)
		damage = 200;
	else
		damage = 500;

	AngleVectors(ent.client.v_angle, &forward, &right, 0);

	offset = [ 8, 8, ent.viewheight - 8 ];
	start = P_ProjectSource(ent, ent.s.origin, offset, forward, right);

	if (ent.client.ps.gunframe == 9) {
		// send muzzle flash
		gi.WriteByte(svc_muzzleflash);
		gi.WriteShort(ent.s.number);
		gi.WriteByte(MZ_BFG | is_silenced);
		gi.multicast(ent.s.origin, MULTICAST_PVS);

		ent.client.ps.gunframe++;

		PlayerNoise(ent, start, PNOISE_WEAPON);
		return;
	}

	// cells can go down during windup (from power armor hits), so
	// check again and abort firing if we don't have enough now
	if (ent.client.pers.inventory[ent.client.ammo_index] < 50) {
		ent.client.ps.gunframe++;
		return;
	}

	ent.client.kick_origin = forward * -2;

	// make a big pitch kick with an inverse fall
	ent.client.v_dmg_pitch = -40f;
	ent.client.v_dmg_roll = random(-8f, 8f);
	ent.client.v_dmg_time = level.time + DAMAGE_TIME;

	if (is_quad)
		damage *= damage_multiplier;
	fire_bfg(ent, start, forward, damage, 400, damage_radius);

	ent.client.ps.gunframe++;

	PlayerNoise(ent, start, PNOISE_WEAPON);

	if (!(dmflags.intVal & DF_INFINITE_AMMO))
		ent.client.pers.inventory[ent.client.ammo_index] -= 50;
}

void(entity ent) Weapon_BFG =
{
	PROGS_LOCAL_STATIC int(int frame) is_pause_frame =
	{
		return frame == 39 || frame == 45 || frame == 50 || frame == 55;
	}
	
	PROGS_LOCAL_STATIC int(int frame) is_fire_frame = 
	{
		return frame == 9 || frame == 17;
	}

	Weapon_Generic(ent, 8, 32, 55, 58, is_pause_frame, is_fire_frame, weapon_bfg_fire);
}


//======================================================================
