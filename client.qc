#include "m_player.h"

//
// Gross, ugly, disgustuing hack section
//

// this function is an ugly as hell hack to fix some map flaws
//
// the coop spawn spots on some maps are SNAFU.  There are coop spots
// with the wrong targetname as well as spots with no name at all
//
// we use carnal knowledge of the maps to fix the coop spot targetnames to match
// that of the nearest named single player spot

static void(entity self) SP_FixCoopSpots =
{
	entity	spot;
	vector	d;

	spot = null_entity;

	while (1) {
		spot = G_Find(spot, classname, "info_player_start");
		if (spot == null_entity)
			return;
		if (!spot.targetname)
			continue;
		d = self.s.origin - spot.s.origin;
		if (VectorLength(d) < 384) {
			if ((!self.targetname) || stricmp(self.targetname, spot.targetname) != 0) {
				self.targetname = spot.targetname;
			}
			return;
		}
	}
}

// now if that one wasn't ugly enough for you then try this one on for size
// some maps don't have any coop spots at all, so we need to create them
// where they should have been

static void(entity self) SP_CreateCoopSpots =
{
    entity spot;

    if (level.mapname == "security") {
        spot = G_Spawn();
        spot.classname = "info_player_coop";
        spot.s.origin[0] = 188f - 64f;
        spot.s.origin[1] = -164f;
        spot.s.origin[2] = 80f;
        spot.targetname = "jail3";
        spot.s.angles[1] = 90f;

        spot = G_Spawn();
        spot.classname = "info_player_coop";
        spot.s.origin[0] = 188f + 64f;
        spot.s.origin[1] = -164f;
        spot.s.origin[2] = 80f;
        spot.targetname = "jail3";
        spot.s.angles[1] = 90f;

        spot = G_Spawn();
        spot.classname = "info_player_coop";
        spot.s.origin[0] = 188f + 128f;
        spot.s.origin[1] = -164f;
        spot.s.origin[2] = 80f;
        spot.targetname = "jail3";
        spot.s.angles[1] = 90f;

        return;
    }
}


/*QUAKED info_player_start (1 0 0) (-16 -16 -24) (16 16 32)
The normal starting point for a level.
*/
API_FUNC static void(entity self) SP_info_player_start =
{
    if (!coop.intVal)
        return;
    if (stricmp(level.mapname, "security") == 0) {
        // invoke one of our gross, ugly, disgusting hacks
        self.think = SP_CreateCoopSpots;
        self.nextthink = level.framenum + 1;
    }
}

void(entity) SP_misc_teleporter_dest;

/*QUAKED info_player_deathmatch (1 0 1) (-16 -16 -24) (16 16 32)
potential spawning position for deathmatch games
*/
API_FUNC static void(entity self) SP_info_player_deathmatch =
{
    if (!deathmatch.intVal) {
        G_FreeEdict(self);
        return;
    }
    SP_misc_teleporter_dest(self);
}

/*QUAKED info_player_coop (1 0 1) (-16 -16 -24) (16 16 32)
potential spawning position for coop games
*/
API_FUNC static void(entity self) SP_info_player_coop =
{
    if (!coop.intVal) {
        G_FreeEdict(self);
        return;
    }

    if ((stricmp(level.mapname, "jail2") == 0)   ||
        (stricmp(level.mapname, "jail4") == 0)   ||
        (stricmp(level.mapname, "mine1") == 0)   ||
        (stricmp(level.mapname, "mine2") == 0)   ||
        (stricmp(level.mapname, "mine3") == 0)   ||
        (stricmp(level.mapname, "mine4") == 0)   ||
        (stricmp(level.mapname, "lab") == 0)     ||
        (stricmp(level.mapname, "boss1") == 0)   ||
        (stricmp(level.mapname, "fact3") == 0)   ||
        (stricmp(level.mapname, "biggun") == 0)  ||
        (stricmp(level.mapname, "space") == 0)   ||
        (stricmp(level.mapname, "command") == 0) ||
        (stricmp(level.mapname, "power2") == 0) ||
        (stricmp(level.mapname, "strike") == 0)) {
        // invoke one of our gross, ugly, disgusting hacks
        self.think = SP_FixCoopSpots;
        self.nextthink = level.framenum + 1;
    }
}


/*QUAKED info_player_intermission (1 0 1) (-16 -16 -24) (16 16 32)
The deathmatch intermission point will be at one of these
Use 'angles' instead of 'angle', so you can set pitch or roll as well as yaw.  'pitch yaw roll'
*/
API_FUNC static void() SP_info_player_intermission =
{
}

#ifdef GROUND_ZERO
/*QUAKED info_player_coop_lava (1 0 1) (-16 -16 -24) (16 16 32)
potential spawning position for coop games on rmine2 where lava level
needs to be checked
*/
API_FUNC static void(entity self) SP_info_player_coop_lava =
{
	if (!coop.intVal)
	{
		G_FreeEdict (self);
		return;
	}
}
#endif

//=======================================================================


static void(entity self, entity other, float kick, int damage) player_pain =
{
    // player pain is handled at the end of the frame in P_DamageFeedback
}


static bool(entity ent) IsFemale =
{
	if (!ent.is_client)
		return false;
	
	string info = Info_ValueForKey(ent.client.pers.userinfo, "gender");
	if (strat(info, 0) == 'f' || strat(info, 0) == 'F')
		return true;
	return false;
}

static bool(entity ent) IsNeutral =
{
    if (!ent.is_client)
        return false;

    string info = Info_ValueForKey(ent.client.pers.userinfo, "gender");
    if (strat(info, 0) != 'f' && strat(info, 0) != 'F' && strat(info, 0) != 'm' && strat(info, 0) != 'M')
        return true;
    return false;
}

PROGS_LOCAL means_of_death_t meansOfDeath;

static void(entity self, entity inflictor, entity attacker) ClientObituary =
{
	int	mod;
	string	message;
	string	message2;
	int	ff;

	if (coop.intVal && attacker.is_client)
		meansOfDeath |= MOD_FRIENDLY_FIRE;

	if (deathmatch.intVal || coop.intVal) {
		ff = meansOfDeath & MOD_FRIENDLY_FIRE;
		mod = meansOfDeath & ~MOD_FRIENDLY_FIRE;
		message = 0;
		message2 = 0;

		switch (mod) {
		case MOD_SUICIDE:
			message = "suicides";
			break;
		case MOD_FALLING:
			message = "cratered";
			break;
		case MOD_CRUSH:
			message = "was squished";
			break;
		case MOD_WATER:
			message = "sank like a rock";
			break;
		case MOD_SLIME:
			message = "melted";
			break;
		case MOD_LAVA:
			message = "does a back flip into the lava";
			break;
		case MOD_EXPLOSIVE:
		case MOD_BARREL:
			message = "blew up";
			break;
		case MOD_EXIT:
			message = "found a way out";
			break;
		case MOD_TARGET_LASER:
			message = "saw the light";
			break;
		case MOD_TARGET_BLASTER:
			message = "got blasted";
			break;
		case MOD_BOMB:
		case MOD_SPLASH:
		case MOD_TRIGGER_HURT:
			message = "was in the wrong place";
			break;
#ifdef THE_RECKONING
		// RAFAEL
		case MOD_GEKK:
		case MOD_BRAINTENTACLE:
			message = "... that's gotta hurt!";
			break;
#endif
		}
		if (attacker == self) {
			switch (mod) {
			case MOD_HELD_GRENADE:
				message = "tried to put the pin back in";
				break;
			case MOD_HG_SPLASH:
			case MOD_G_SPLASH:
				if (IsNeutral(self))
					message = "tripped on its own grenade";
				else if (IsFemale(self))
					message = "tripped on her own grenade";
				else
					message = "tripped on his own grenade";
				break;
			case MOD_R_SPLASH:
				if (IsNeutral(self))
					message = "blew itself up";
				else if (IsFemale(self))
					message = "blew herself up";
				else
					message = "blew himself up";
				break;
			case MOD_BFG_BLAST:
				message = "should have used a smaller gun";
				break;
#ifdef THE_RECKONING
			// RAFAEL 03-MAY-98
			case MOD_TRAP:
				if (IsNeutral(self))
					message = "sucked into its own trap";
				else if (IsFemale(self))
					message = "sucked into her own trap";
				else
					message = "sucked into his own trap";
				break;
#endif
			default:
				if (IsNeutral(self))
					message = "killed itself";
				else if (IsFemale(self))
					message = "killed herself";
				else
					message = "killed himself";
				break;
			}
		}
		if (message) {
			gi.bprintf(PRINT_MEDIUM, "%s %s.\n", self.client.pers.netname, message);
			if (deathmatch.intVal)
				self.client.resp.score--;
			self.enemy = world;
			return;
		}

		self.enemy = attacker;
		if (attacker && attacker.is_client) {
			switch (mod) {
			case MOD_BLASTER:
				message = "was blasted by";
				break;
			case MOD_SHOTGUN:
				message = "was gunned down by";
				break;
			case MOD_SSHOTGUN:
				message = "was blown away by";
				message2 = "'s super shotgun";
				break;
			case MOD_MACHINEGUN:
				message = "was machinegunned by";
				break;
			case MOD_CHAINGUN:
				message = "was cut in half by";
				message2 = "'s chaingun";
				break;
			case MOD_GRENADE:
				message = "was popped by";
				message2 = "'s grenade";
				break;
			case MOD_G_SPLASH:
				message = "was shredded by";
				message2 = "'s shrapnel";
				break;
			case MOD_ROCKET:
				message = "ate";
				message2 = "'s rocket";
				break;
			case MOD_R_SPLASH:
				message = "almost dodged";
				message2 = "'s rocket";
				break;
			case MOD_HYPERBLASTER:
				message = "was melted by";
				message2 = "'s hyperblaster";
				break;
			case MOD_RAILGUN:
				message = "was railed by";
				break;
			case MOD_BFG_LASER:
				message = "saw the pretty lights from";
				message2 = "'s BFG";
				break;
			case MOD_BFG_BLAST:
				message = "was disintegrated by";
				message2 = "'s BFG blast";
				break;
			case MOD_BFG_EFFECT:
				message = "couldn't hide from";
				message2 = "'s BFG";
				break;
			case MOD_HANDGRENADE:
				message = "caught";
				message2 = "'s handgrenade";
				break;
			case MOD_HG_SPLASH:
				message = "didn't see";
				message2 = "'s handgrenade";
				break;
			case MOD_HELD_GRENADE:
				message = "feels";
				message2 = "'s pain";
				break;
			case MOD_TELEFRAG:
				message = "tried to invade";
				message2 = "'s personal space";
				break;
#ifdef THE_RECKONING
			case MOD_RIPPER:
				message = "ripped to shreds by";
				message2 = "'s ripper gun";
				break;
			case MOD_PHALANX:
				message = "was evaporated by";
				break;
			case MOD_TRAP:
				message = "caught in";
				message2 = "'s trap";
				break;
#endif
#ifdef GROUND_ZERO

			case MOD_CHAINFIST:
				message = "was shredded by";
				message2 = "'s ripsaw";
				break;
			case MOD_DISINTEGRATOR:
				message = "lost his grip courtesy of";
				message2 = "'s disintegrator";
				break;
			case MOD_ETF_RIFLE:
				message = "was perforated by";
				break;
			case MOD_HEATBEAM:
				message = "was scorched by";
				message2 = "'s plasma beam";
				break;
			case MOD_TESLA:
				message = "was enlightened by";
				message2 = "'s tesla mine";
				break;
			case MOD_PROX:
				message = "got too close to";
				message2 = "'s proximity mine";
				break;
			case MOD_NUKE:
				message = "was nuked by";
				message2 = "'s antimatter bomb";
				break;
			case MOD_TRACKER:
				message = "was annihilated by";
				message2 = "'s disruptor";
				break;
#endif
			}
			if (message) {
				gi.bprintf(PRINT_MEDIUM, "%s %s %s%s\n", self.client.pers.netname, message, attacker.client.pers.netname, message2);
				if (deathmatch.intVal) {
					if (ff)
						attacker.client.resp.score--;
					else
						attacker.client.resp.score++;
				}
				return;
			}
		}
	}

	gi.bprintf(PRINT_MEDIUM, "%s died.\n", self.client.pers.netname);
	if (deathmatch.intVal)
		self.client.resp.score--;
}

static void(entity self) TossClientWeapon =
{
	gitem_id_t	it;
	entity		drop;
	bool		quad;
	float		spread;

	if (!deathmatch.intVal)
		return;

	it = self.client.pers.weapon;
	if (!self.client.pers.inventory[self.client.ammo_index])
		it = 0;
	
	if (it && GetItemKeyByIndex(it, pickup_name) == "Blaster")
		it = 0;

	if (!(dmflags.intVal & DF_QUAD_DROP))
		quad = false;
	else
		quad = (bool)(self.client.quad_framenum > (level.framenum + 10));
		
#ifdef THE_RECKONING
	// RAFAEL
	bool		quadfire;

	if (!(dmflags.intVal & DF_QUADFIRE_DROP))
		quadfire = false;
	else
		quadfire = (self.client.quadfire_framenum > (level.framenum + 10));
#endif

	if (it && quad)
		spread = 22.5f;
#ifdef THE_RECKONING
	else if (it && quadfire)
		spread = 12.5;
#endif
	else
		spread = 0.0f;

	if (it) {
		self.client.v_angle[YAW] -= spread;
		drop = Drop_Item(self, it);
		self.client.v_angle[YAW] += spread;
		drop.spawnflags = DROPPED_PLAYER_ITEM;
	}

	if (quad) {
		self.client.v_angle[YAW] += spread;
		drop = Drop_Item(self, FindItemByClassname("item_quad"));
		self.client.v_angle[YAW] -= spread;
		drop.spawnflags |= DROPPED_PLAYER_ITEM;

		drop.touch = Touch_Item;
		drop.nextthink = self.client.quad_framenum;
		drop.think = G_FreeEdict;
	}
	
#ifdef THE_RECKONING
	// RAFAEL
	if (quadfire)
	{
		self.client.v_angle[YAW] += spread;
		drop = Drop_Item (self, FindItemByClassname ("item_quadfire"));
		self.client.v_angle[YAW] -= spread;
		drop.spawnflags |= DROPPED_PLAYER_ITEM;

		drop.touch = Touch_Item;
		drop.nextthink = self.client.quadfire_framenum;
		drop.think = G_FreeEdict;
	}
#endif
}

/*
==================
LookAtKiller
==================
*/
void(entity self, entity inflictor, entity attacker) LookAtKiller =
{
	vector	dir;

	if (attacker && attacker != world && attacker != self) {
		dir = attacker.s.origin - self.s.origin;
	} else if (inflictor && inflictor != world && inflictor != self) {
		dir = inflictor.s.origin - self.s.origin;
	} else {
		self.client.killer_yaw = self.s.angles[YAW];
		return;
	}

	self.client.killer_yaw = vectoyaw(dir);
}

// from hud.qc
void(entity) Cmd_Help_f;

// from misc.qc
void(entity, string, int, int) ThrowGib;
void(entity, int) ThrowClientHead;

/*
==================
player_die
==================
*/
void(entity self, entity inflictor, entity attacker, int damage, vector point) player_die =
{
	self.avelocity = vec3_origin;

	self.takedamage = DAMAGE_YES;
	self.movetype = MOVETYPE_TOSS;

	self.s.modelindex2 = 0;    // remove linked weapon model

	self.s.angles[PITCH] = 0;
	self.s.angles[ROLL] = 0;

	self.s.sound = 0;
	self.client.weapon_sound = 0;

	self.maxs.z = -8f;

	self.svflags |= SVF_DEADMONSTER;

	if (!self.deadflag) {
		self.client.respawn_framenum = (int)(level.framenum + 1.0f * BASE_FRAMERATE);
		LookAtKiller(self, inflictor, attacker);
		self.client.ps.pmove.pm_type = PM_DEAD;
		ClientObituary(self, inflictor, attacker);
		TossClientWeapon(self);
		if (deathmatch.intVal)
			Cmd_Help_f(self);       // show scores

		// clear inventory
		// this is kind of ugly, but it's how we want to handle keys in coop
		for (int n = 0; n < itemlist.length; n++) {
			if (coop.intVal && itemlist[n].flags & IT_KEY)
				self.client.resp.coop_respawn.inventory[n] = self.client.pers.inventory[n];
			self.client.pers.inventory[n] = 0;
		}
	}

	// remove powerups
	self.client.quad_framenum = 0;
	self.client.invincible_framenum = 0;
	self.client.breather_framenum = 0;
	self.client.enviro_framenum = 0;
#ifdef THE_RECKONING
	self.client.quadfire_framenum = 0;
#endif
	self.flags &= ~FL_POWER_ARMOR;
	
#ifdef GROUND_ZERO
	self.client.double_framenum = 0;
	// if we've been killed by the tracker, GIB!
	if((meansOfDeath & ~MOD_FRIENDLY_FIRE) == MOD_TRACKER)
	{
		self.health = -100;
		damage = 400;
	}
	
	// if we got obliterated by the nuke, don't gib
	if ((self.health < -80) && (meansOfDeath == MOD_NUKE))
		self.flags |= FL_NOGIB;
#endif

	if (self.health < -40)
	{
#ifdef GROUND_ZERO
		if (!(self.flags & FL_NOGIB))
		{
#endif
			// gib
			gi.sound(self, CHAN_BODY, gi.soundindex("misc/udeath.wav"), 1, ATTN_NORM, 0);
			for (int n = 0; n < 4; n++)
				ThrowGib(self, "models/objects/gibs/sm_meat/tris.md2", damage, GIB_ORGANIC);
#ifdef GROUND_ZERO
		}
		self.flags &= ~FL_NOGIB;
#endif

		ThrowClientHead(self, damage);

		self.takedamage = DAMAGE_NO;
	}
	else
	{
		// normal death
		if (!self.deadflag) {
			static int i;

			i = (i + 1) % 3;
			// start a death animation
			self.client.anim_priority = ANIM_DEATH;
			if (self.client.ps.pmove.pm_flags & PMF_DUCKED) {
				self.s.frame = FRAME_crdeath1 - 1;
				self.client.anim_end = FRAME_crdeath5;
			} else switch (i) {
				case 0:
					self.s.frame = FRAME_death101 - 1;
					self.client.anim_end = FRAME_death106;
					break;
				case 1:
					self.s.frame = FRAME_death201 - 1;
					self.client.anim_end = FRAME_death206;
					break;
				case 2:
					self.s.frame = FRAME_death301 - 1;
					self.client.anim_end = FRAME_death308;
					break;
				}
			gi.sound(self, CHAN_VOICE, gi.soundindex(va("*death%i.wav", (Q_rand() % 4) + 1)), 1, ATTN_NORM, 0);
		}
	}

	self.deadflag = DEAD_DEAD;

	gi.linkentity(self);
}

//=======================================================================

/*
==============
InitClientPersistant

This is only called when the game first initializes in single player,
but is called after each death and level change in deathmatch
==============
*/
static void(entity ent) InitClientPersistant =
{
	memclear(&ent.client.pers, sizeof(ent.client.pers));
	
	gitem_id_t it = FindItem("Blaster");
	ent.client.pers.selected_item = ITEM_INDEX(it);
	ent.client.pers.inventory[ent.client.pers.selected_item] = 1;
	
	ent.client.pers.weapon = it;
	
	ent.client.pers.health         = 100;
	ent.client.pers.max_health     = 100;
	
	ent.client.pers.max_bullets    = 200;
	ent.client.pers.max_shells     = 100;
	ent.client.pers.max_rockets    = 50;
	ent.client.pers.max_grenades   = 50;
	ent.client.pers.max_cells      = 200;
	ent.client.pers.max_slugs      = 50;
	
#ifdef THE_RECKONING
	ent.client.pers.max_magslug	= 50;
	ent.client.pers.max_trap	= 5;
#endif

#ifdef GROUND_ZERO
	// FIXME - give these real numbers....
	ent.client.pers.max_prox		= 50;
	ent.client.pers.max_tesla		= 50;
	ent.client.pers.max_flechettes = 200;
	ent.client.pers.max_rounds     = 100;
#endif
	
	ent.client.pers.connected = true;
}

static void(entity ent) InitClientResp =
{
	memclear(&ent.client.resp, sizeof(client_respawn_t));
	ent.client.resp.enterframe = level.framenum;
	memcpy(&ent.client.resp.coop_respawn, &ent.client.pers, sizeof(client_persistant_t));
}

/*
==================
SaveClientData

Some information that should be persistant, like health,
is still stored in the edict structure, so it needs to
be mirrored out to the client structure before all the
edicts are wiped.
==================
*/
void() SaveClientData =
{
	for (int i = 0; i < game.maxclients; i++)
	{
		entity ent = itoe(1 + i);
		if (!ent.inuse)
			continue;

		ent.client.pers.health = ent.health;
		ent.client.pers.max_health = ent.max_health;
		ent.client.pers.savedFlags = (ent.flags & (FL_GODMODE | FL_NOTARGET | FL_POWER_ARMOR));
		if (coop.intVal)
			ent.client.pers.score = ent.client.resp.score;
	}
}

static void(entity ent) FetchClientEntData =
{
	ent.health = ent.client.pers.health;
	ent.max_health = ent.client.pers.max_health;
	ent.flags |= ent.client.pers.savedFlags;
	if (coop.intVal)
		ent.client.resp.score = ent.client.pers.score;
}

/*
=======================================================================

  SelectSpawnPoint

=======================================================================
*/

/*
================
PlayersRangeFromSpot

Returns the distance to the nearest player from the given spot
================
*/
static float(entity spot) PlayersRangeFromSpot =
{
	entity	player;
	float	bestplayerdistance;
	vector	v;
	int	n;
	float	playerdistance;

	bestplayerdistance = 9999999f;

	for (n = 1; n <= game.maxclients; n++)
	{
		player = itoe(n);

		if (!player.inuse)
			continue;

		if (player.health <= 0)
			continue;

		v = spot.s.origin - player.s.origin;
		playerdistance = VectorLength(v);

		if (playerdistance < bestplayerdistance)
			bestplayerdistance = playerdistance;
	}

	return bestplayerdistance;
}

/*
================
SelectRandomDeathmatchSpawnPoint

go to a random point, but NOT the two points closest
to other players
================
*/
static entity() SelectRandomDeathmatchSpawnPoint =
{
	entity	spot, spot1, spot2;
	int	count = 0;
	int	selection;
	float	range, range1, range2;

	spot = null_entity;
	range1 = range2 = 99999f;
	spot1 = spot2 = null_entity;

	while ((spot = G_Find(spot, classname, "info_player_deathmatch")) != null_entity) {
		count++;
		range = PlayersRangeFromSpot(spot);
		if (range < range1) {
			range1 = range;
			spot1 = spot;
		} else if (range < range2) {
			range2 = range;
			spot2 = spot;
		}
	}

	if (!count)
		return null_entity;

	if (count <= 2) {
		spot1 = spot2 = null_entity;
	} else
		count -= 2;

	selection = Q_rand_uniform(count);

	spot = null_entity;
	do {
		spot = G_Find(spot, classname, "info_player_deathmatch");
		if (spot == spot1 || spot == spot2)
			selection++;
	} while (selection--);

	return spot;
}

/*
================
SelectFarthestDeathmatchSpawnPoint

================
*/
static entity() SelectFarthestDeathmatchSpawnPoint =
{
	entity	bestspot;
	float	bestdistance, bestplayerdistance;
	entity	spot;

	spot = null_entity;
	bestspot = null_entity;
	bestdistance = 0;
	
	while ((spot = G_Find(spot, classname, "info_player_deathmatch")) != null_entity) {
		bestplayerdistance = PlayersRangeFromSpot(spot);

		if (bestplayerdistance > bestdistance) {
			bestspot = spot;
			bestdistance = bestplayerdistance;
		}
	}

	if (bestspot) {
		return bestspot;
	}

	// if there is a player just spawned on each and every start spot
	// we have no choice to turn one into a telefrag meltdown
	spot = G_Find(null_entity, classname, "info_player_deathmatch");

	return spot;
}

static entity() SelectDeathmatchSpawnPoint =
{
	if (dmflags.intVal & DF_SPAWN_FARTHEST)
		return SelectFarthestDeathmatchSpawnPoint();
	else
		return SelectRandomDeathmatchSpawnPoint();
}

#ifdef GROUND_ZERO
static entity(entity ent) SelectLavaCoopSpawnPoint =
{
	int	index;
	entity	spot = null_entity;
	float	lavatop;
	entity	lava;
	entity	pointWithLeastLava;
	float	lowest;
	entity	spawnPoints[64] = { 0 };
	vector	center;
	int	numPoints;
	entity	highestlava;

	lavatop = -99999f;
	highestlava = null_entity;

	// first, find the highest lava
	// remember that some will stop moving when they've filled their
	// areas...
	lava = null_entity;
	while (1)
	{
		lava = G_Find (lava, classname, "func_door");
		if(lava == null_entity)
			break;
		
		center = (lava.absmax + lava.absmin) * 0.5f;

		if(lava.spawnflags & 2 && (gi.pointcontents(center) & MASK_WATER))
		{
			if (lava.absmax[2] > lavatop)
			{
				lavatop = lava.absmax[2];
				highestlava = lava;
			}
		}
	}

	// if we didn't find ANY lava, then return NULL
	if (highestlava == null_entity)
		return null_entity;

	// find the top of the lava and include a small margin of error (plus bbox size)
	lavatop = highestlava.absmax[2] + 64;

	// find all the lava spawn points and store them in spawnPoints[]
	spot = null_entity;
	numPoints = 0;
	while((spot = G_Find (spot, classname, "info_player_coop_lava")) != null_entity)
	{
		if(numPoints == 64)
			break;

		spawnPoints[numPoints++] = spot;
	}

	if(numPoints < 1)
		return null_entity;

	// walk up the sorted list and return the lowest, open, non-lava spawn point
	spot = null_entity;
	lowest = 999999f;
	pointWithLeastLava = null_entity;
	for (index = 0; index < numPoints; index++)
	{
		if(spawnPoints[index].s.origin[2] < lavatop)
			continue;

		if(PlayersRangeFromSpot(spawnPoints[index]) > 32)
		{
			if(spawnPoints[index].s.origin[2] < lowest)
			{
				// save the last point
				pointWithLeastLava = spawnPoints[index];
				lowest = spawnPoints[index].s.origin[2];
			}
		}
	}

	// FIXME - better solution????
	// well, we may telefrag someone, but oh well...
	if(pointWithLeastLava != null_entity)
		return pointWithLeastLava;

	return null_entity;
}
#endif

static entity(entity ent) SelectCoopSpawnPoint =
{
#ifdef GROUND_ZERO
	// rogue hack, but not too gross...
	if (!stricmp(level.mapname, "rmine2p") || !stricmp(level.mapname, "rmine2"))
		return SelectLavaCoopSpawnPoint (ent);
#endif

	int	index;
	entity	spot = null_entity;
	string	target;

	index = ent.s.number - 1;
	
	// player 0 starts in normal player spawn point
	if (!index)
		return null_entity;

	spot = null_entity;

	// assume there are four coop spots at each spawnpoint
	while (1) {
		spot = G_Find(spot, classname, "info_player_coop");
		if (spot == null_entity)
			return null_entity;    // we didn't have enough...

		target = spot.targetname;

		if (stricmp(game.spawnpoint, target) == 0) {
			// this is a coop spawn point for one of the clients here
			index--;
			if (!index)
				return spot;        // this is it
		}
	}


	return spot;
}


/*
===========
SelectSpawnPoint

Chooses a player start, deathmatch start, coop start, etc
============
*/
static void(entity ent, __out vector origin, __out vector angles) SelectSpawnPoint =
{
	entity spot = null_entity;

	if (deathmatch.intVal)
		spot = SelectDeathmatchSpawnPoint();
	else if (coop.intVal)
		spot = SelectCoopSpawnPoint(ent);

	// find a single player start spot
	if (spot == null_entity)
	{
		while ((spot = G_Find(spot, classname, "info_player_start")) != null_entity)
		{
			if (!game.spawnpoint && !spot.targetname)
				break;

			if (!game.spawnpoint || !spot.targetname)
				continue;

			if (stricmp(game.spawnpoint, spot.targetname) == 0)
				break;
		}

		if (spot == null_entity)
		{
			if (!game.spawnpoint)
			{
				// there wasn't a spawnpoint without a target, so use any
				spot = G_Find(spot, classname, "info_player_start");
			}
			if (spot == null_entity)
			{
				gi.dprintf("Couldn't find spawn point %s", game.spawnpoint);
				return;
			}
		}
	}

	origin = spot.s.origin;
	origin[2] += 9f;
	angles = spot.s.angles;
}

void InitBodyQue(void)
{
	int     i;
	
	level.body_que = 0;
	for (i = 0; i < BODY_QUEUE_SIZE ; i++) {
		entity ent = G_Spawn();
		ent.classname = "bodyque";
	}
}

static void(entity self, entity inflictor, entity attacker, int damage, vector point) body_die =
{
	int n;
	
	if (self.health < -40) {
		gi.sound(self, CHAN_BODY, gi.soundindex("misc/udeath.wav"), 1, ATTN_NORM, 0);
		for (n = 0; n < 4; n++)
			ThrowGib(self, "models/objects/gibs/sm_meat/tris.md2", damage, GIB_ORGANIC);
		self.s.origin[2] -= 48f;
		ThrowClientHead(self, damage);
		self.takedamage = DAMAGE_NO;
	}
}

static void(entity ent) CopyToBodyQue =
{
	gi.unlinkentity(ent);
	
	// grab a body que and cycle to the next one
	entity body = itoe(game.maxclients + level.body_que + 1);
	level.body_que = (level.body_que + 1) % BODY_QUEUE_SIZE;
	
	// send an effect on the removed body
	if (body.s.modelindex) {
		gi.WriteByte(svc_temp_entity);
		gi.WriteByte(TE_BLOOD);
		gi.WritePosition(body.s.origin);
		gi.WriteDir(vec3_origin);
		gi.multicast(body.s.origin, MULTICAST_PVS);
	}
	
	gi.unlinkentity(body);
	int num = body.s.number;
	memcpy(&body.s, &ent.s, sizeof(ent.s));
	body.s.number = num;
	body.s.event = EV_OTHER_TELEPORT;
	
	body.svflags = ent.svflags;
	body.mins = ent.mins;
	body.maxs = ent.maxs;
	body.absmin = ent.absmin;
	body.absmax = ent.absmax;
	body.size = ent.size;
	body.velocity = ent.velocity;
	body.avelocity = ent.avelocity;
	body.solid = ent.solid;
	body.clipmask = ent.clipmask;
	body.owner = ent.owner;
	body.movetype = ent.movetype;
	body.groundentity = ent.groundentity;
	
	body.die = body_die;
	body.takedamage = DAMAGE_YES;
	
	gi.linkentity(body);
}

// from player.qc
void(entity self) PutClientInServer;

void(entity self) respawn =
{
	if (deathmatch.intVal || coop.intVal) {
		// spectator's don't leave bodies
		if (self.movetype != MOVETYPE_NOCLIP)
			CopyToBodyQue(self);
		self.svflags &= ~SVF_NOCLIENT;
		PutClientInServer(self);

		// add a teleportation effect
		self.s.event = EV_PLAYER_TELEPORT;

		// hold in place briefly
		self.client.ps.pmove.pm_flags = PMF_TIME_TELEPORT;
		self.client.ps.pmove.pm_time = 14;

		self.client.respawn_framenum = level.framenum;

		return;
	}

	// restart the entire server
	gi.AddCommandString("pushmenu loadgame\n");
}

/*
 * only called when pers.spectator changes
 * note that resp.spectator should be the opposite of pers.spectator here
 */
static void(entity ent) spectator_respawn =
{
	int i, numspec;

	// if the user wants to become a spectator, make sure he doesn't
	// exceed max_spectators

	if (ent.client.pers.spectator) {
		string value = Info_ValueForKey(ent.client.pers.userinfo, "spectator");
		if (spectator_password.str &&
			spectator_password.str != "none" &&
			spectator_password.str != value)
		{
			gi.cprintf(ent, PRINT_HIGH, "Spectator password incorrect.\n");
			ent.client.pers.spectator = false;
			gi.WriteByte(svc_stufftext);
			gi.WriteString("spectator 0\n");
			gi.unicast(ent, true);
			return;
		}

		// count spectators
		for (i = 1, numspec = 0; i <= game.maxclients; i++)
			if (itoe(i).inuse && itoe(i).client.pers.spectator)
				numspec++;

		if (numspec >= maxspectators.intVal) {
			gi.cprintf(ent, PRINT_HIGH, "Server spectator limit is full.");
			ent.client.pers.spectator = false;
			// reset his spectator var
			gi.WriteByte(svc_stufftext);
			gi.WriteString("spectator 0\n");
			gi.unicast(ent, true);
			return;
		}
	} else {
		// he was a spectator and wants to join the game
		// he must have the right password
		string value = Info_ValueForKey(ent.client.pers.userinfo, "password");
		if (password.str &&
			password.str != "none" &&
			password.str != value)
		{
			gi.cprintf(ent, PRINT_HIGH, "Password incorrect.\n");
			ent.client.pers.spectator = true;
			gi.WriteByte(svc_stufftext);
			gi.WriteString("spectator 1\n");
			gi.unicast(ent, true);
			return;
		}
	}

	// clear client on respawn
	ent.client.resp.score = ent.client.pers.score = 0;

	ent.svflags &= ~SVF_NOCLIENT;
	PutClientInServer(ent);

	// add a teleportation effect
	if (!ent.client.pers.spectator)  {
		// send effect
		gi.WriteByte(svc_muzzleflash);
		gi.WriteShort(ent.s.number);
		gi.WriteByte(MZ_LOGIN);
		gi.multicast(ent.s.origin, MULTICAST_PVS);

		// hold in place briefly
		ent.client.ps.pmove.pm_flags = PMF_TIME_TELEPORT;
		ent.client.ps.pmove.pm_time = 14;
	}

	ent.client.respawn_framenum = level.framenum;

	if (ent.client.pers.spectator)
		gi.bprintf(PRINT_HIGH, "%s has moved to the sidelines\n", ent.client.pers.netname);
	else
		gi.bprintf(PRINT_HIGH, "%s joined the game\n", ent.client.pers.netname);
}

//==============================================================

// from player.qc
void(entity ent, string userinfo) ClientUserinfoChanged;

// from pweapon.qc
void(entity) ChangeWeapon;

/*
===========
PutClientInServer

Called when a player connects to a server or respawns in
a deathmatch.
============
*/
static void(entity ent) PutClientInServer =
{
	static const vector player_mins = '-16 -16 -24';
	static const vector player_maxs = ' 16  16  32';
	vector spawn_origin, spawn_angles;
	client_persistant_t saved;
	client_respawn_t    resp;

	// find a spawn point
	// do it before setting health back up, so farthest
	// ranging doesn't count this client
	SelectSpawnPoint(ent, spawn_origin, spawn_angles);

	// deathmatch wipes most client data every spawn
	if (deathmatch.intVal)
	{
		string userinfo = ent.client.pers.userinfo;
		
		memcpy(&resp, &ent.client.resp, sizeof(resp));
		
		InitClientPersistant(ent);
		ClientUserinfoChanged(ent, userinfo);
	}
	else if (coop.intVal)
	{
		string userinfo = ent.client.pers.userinfo;

		memcpy(&resp, &ent.client.resp, sizeof(resp));

		resp.coop_respawn.game_helpchanged = ent.client.pers.game_helpchanged;
		resp.coop_respawn.helpchanged = ent.client.pers.helpchanged;
		memcpy(&ent.client.pers, &resp.coop_respawn, sizeof(resp.coop_respawn));
		ClientUserinfoChanged(ent, userinfo);
		if (resp.score > ent.client.pers.score)
			ent.client.pers.score = resp.score;
	}

	// clear everything but the persistant data
	memcpy(&saved, &ent.client.pers, sizeof(saved));
	memclear(&ent.client, sizeof(ent.client));
	memcpy(&ent.client.pers, &saved, sizeof(saved));
	if (ent.client.pers.health <= 0)
		InitClientPersistant(ent);
	memcpy(&ent.client.resp, &resp, sizeof(resp));

	// copy some data from the client to the entity
	FetchClientEntData(ent);

	// clear entity values
	ent.groundentity = null_entity;
	ent.takedamage = DAMAGE_AIM;
	ent.movetype = MOVETYPE_WALK;
	ent.viewheight = 22;
	ent.inuse = true;
	ent.classname = "player";
	ent.mass = 200;
	ent.solid = SOLID_BBOX;
	ent.deadflag = DEAD_NO;
	ent.air_finished_framenum = level.framenum + 12 * BASE_FRAMERATE;
	ent.clipmask = MASK_PLAYERSOLID;
	ent.model = "players/male/tris.md2";
	ent.pain = player_pain;
	ent.die = player_die;
	ent.waterlevel = 0;
	ent.watertype = 0;
	ent.flags &= ~FL_NO_KNOCKBACK;
	ent.svflags &= ~SVF_DEADMONSTER;

	ent.mins = player_mins;
	ent.maxs = player_maxs;
	ent.velocity = vec3_origin;

	// clear playerstate values
	memclear(&ent.client.ps, sizeof(ent.client.ps));

	ent.client.ps.pmove.origin = spawn_origin;

	if (deathmatch.intVal && (dmflags.intVal & DF_FIXED_FOV))
		ent.client.ps.fov = 90.f;
	else
	{
		ent.client.ps.fov = stof(Info_ValueForKey(ent.client.pers.userinfo, "fov"));
		if (ent.client.ps.fov < 1.f)
			ent.client.ps.fov = 90.f;
		else if (ent.client.ps.fov > 160.f)
			ent.client.ps.fov = 160.f;
	}

	if (ent.client.pers.weapon)
		ent.client.ps.gunindex = gi.modelindex(GetItemKeyByIndex(ent.client.pers.weapon, view_model));
	else
		ent.client.ps.gunindex = 0;

	// clear entity state values
	ent.s.effects = 0;
	ent.s.modelindex = 255;        // will use the skin specified model
	ent.s.modelindex2 = 255;       // custom gun model
	// sknum is player num and weapon number
	// weapon number will be added in changeweapon
	ent.s.skinnum = ent.s.number;

	ent.s.frame = 0;
	ent.s.origin = spawn_origin;
	ent.s.origin += '0 0 1';  // make sure off ground
	ent.s.old_origin = ent.s.origin;

	// set the delta angle
	ent.client.ps.pmove.delta_angles = spawn_angles - ent.client.resp.cmd_angles;

	ent.s.angles[PITCH] = 0;
	ent.s.angles[YAW] = spawn_angles[YAW];
	ent.s.angles[ROLL] = 0;
	ent.client.ps.viewangles = ent.s.angles;
	ent.client.v_angle = ent.s.angles;

	// spawn a spectator
	if (ent.client.pers.spectator)
	{
		ent.client.chase_target = world;

		ent.client.resp.spectator = true;

		ent.movetype = MOVETYPE_NOCLIP;
		ent.solid = SOLID_NOT;
		ent.svflags |= SVF_NOCLIENT;
		ent.client.ps.gunindex = 0;
		gi.linkentity(ent);
		return;
	}
	else
		ent.client.resp.spectator = false;

	if (!KillBox(ent)) {
		// could't spawn in?
	}

	gi.linkentity(ent);

#ifdef GROUND_ZERO
	// my tribute to cash's level-specific hacks. I hope I live
	// up to his trailblazing cheese.
	if(!deathmatch.intVal && level.mapname == "rboss")
	{
		// if you get on to rboss in single player or coop, ensure
		// the player has the nuke key. (not in DM)
		gitem_id_t	it;

		it = FindItem("Antimatter Bomb");
		ent.client.pers.selected_item = ITEM_INDEX(it);
		ent.client.pers.inventory[ent.client.pers.selected_item] = 1;
	}
#endif

	// force the current weapon up
	ent.client.newweapon = ent.client.pers.weapon;
	ChangeWeapon(ent);
};

// from view.qc
void(entity ent) ClientEndServerFrame;

// from hud.qc
void(entity ent) MoveClientToIntermission;

static void(entity ent) ClientBeginDeathmatch =
{
	G_InitEdict(ent);

	InitClientResp(ent);

	// locate ent at a spawn point
	PutClientInServer(ent);

	if (level.intermission_framenum)
	{
		MoveClientToIntermission(ent);
	}
	else
	{
		// send effect
		gi.WriteByte(svc_muzzleflash);
		gi.WriteShort(ent.s.number);
		gi.WriteByte(MZ_LOGIN);
		gi.multicast(ent.s.origin, MULTICAST_PVS);
	}

	gi.bprintf(PRINT_HIGH, "%s entered the game\n", ent.client.pers.netname);

	// make sure all view stuff is valid
	ClientEndServerFrame(ent);
};

void(entity ent) ClientBegin =
{
	if (deathmatch.intVal)
	{
		ClientBeginDeathmatch(ent);
		return;
	}

	// if there is already a body waiting for us (a loadgame), just
	// take it, otherwise spawn one from scratch
	if (ent.inuse)
		// the client has cleared the client side viewangles upon
		// connecting to the server, which is different than the
		// state when the game is saved, so we need to compensate
		// with deltaangles
		ent.client.ps.pmove.delta_angles = ent.client.ps.viewangles;
	else
	{
		// a spawn point will completely reinitialize the entity
		// except for the persistant data that was initialized at
		// ClientConnect() time
		G_InitEdict(ent);
		ent.classname = "player";
		InitClientResp(ent);
		PutClientInServer(ent);
	}

	if (level.intermission_framenum)
		MoveClientToIntermission(ent);
	else if (game.maxclients > 1)
	{
		// send effect if in a multiplayer game
		gi.WriteByte(svc_muzzleflash);
		gi.WriteShort(ent.s.number);
		gi.WriteByte(MZ_LOGIN);
		gi.multicast(ent.s.origin, MULTICAST_PVS);

		gi.bprintf(PRINT_HIGH, "%s entered the game\n", ent.client.pers.netname);
	}

	// make sure all view stuff is valid
	ClientEndServerFrame(ent);
};

/*
===========
ClientUserInfoChanged

called whenever the player updates a userinfo variable.

The game can override any of the settings in place
(forcing skins or names, etc) before copying it off.
============
*/
void(entity ent, string userinfo) ClientUserinfoChanged =
{
	// check for malformed or illegal info strings
	if (!Info_Validate(userinfo)) {
		userinfo = "\\name\\badinfo\\skin\\male/grunt";
	}
	
	// set name
	string str = Info_ValueForKey(userinfo, "name");
	ent.client.pers.netname = str;
	
	// set spectator
	str = Info_ValueForKey(userinfo, "spectator");
	
	// spectators are only supported in deathmatch
	if (deathmatch.intVal && !strempty(str) && str != "0")
		ent.client.pers.spectator = true;
	else
		ent.client.pers.spectator = false;
	
	// set skin
	str = Info_ValueForKey(userinfo, "skin");

	// combine name and skin into a configstring
	gi.configstring(CS_PLAYERSKINS + ent.s.number - 1, va("%s\\%s", ent.client.pers.netname, str));
	
	// fov
	if (deathmatch.intVal && (dmflags.intVal & DF_FIXED_FOV))
	{
		ent.client.ps.fov = 90.f;
	}
	else
	{
		ent.client.ps.fov = stof(Info_ValueForKey(userinfo, "fov"));
		if (ent.client.ps.fov < 1.f)
			ent.client.ps.fov = 90.f;
		else if (ent.client.ps.fov > 160.f)
			ent.client.ps.fov = 160.f;
	}
	
	// handedness
	str = Info_ValueForKey(userinfo, "hand");
	if (!strempty(str)) {
		ent.client.pers.hand = stoi(str);
	}
	
	// save off the userinfo in case we want to check something later
	ent.client.pers.userinfo = userinfo;
}

/*
===========
ClientConnect

Called when a player begins connecting to the server.
The game can refuse entrance to a client by returning false.
If the client is allowed, the connection process will continue
and eventually get to ClientBegin()
Changing levels will NOT cause this to be called again, but
loadgames will.
============
*/
bool(entity ent, __inout string userinfo) ClientConnect =
{
	// check to see if they are on the banned IP list
	/*string value = Info_ValueForKey(userinfo, "ip");
	
	if (SV_FilterPacket(value))
	{
		Info_SetValueForKey(userinfo, "rejmsg", "Banned.");
		return false;
	}*/

	// check for a spectator
	string value = Info_ValueForKey(userinfo, "spectator");

	if (deathmatch.intVal && !strempty(value) && value != "0")
	{
		if (!strempty(spectator_password.str) &&
			spectator_password.str != "none" &&
			spectator_password.str != value)
		{
			Info_SetValueForKey(userinfo, "rejmsg", "Spectator password required or incorrect.");
			return false;
		}

		int i, numspec;
		
		// count spectators
		for (i = numspec = 0; i < game.maxclients; i++)
		{
			entity e = itoe(i + 1);
			
			if (e.inuse && e.client.pers.spectator)
				numspec++;
		}

		if (numspec >= maxspectators.intVal)
		{
			Info_SetValueForKey(userinfo, "rejmsg", "Server spectator limit is full.");
			return false;
		}
	}
	else
	{
		// check for a password
		value = Info_ValueForKey(userinfo, "password");
		if (!strempty(password.str) &&
			password.str != "none" &&
			password.str != value)
		{
			Info_SetValueForKey(userinfo, "rejmsg", "Password required or incorrect.");
			return false;
		}
	}

	// they can connect
	// if there is already a body waiting for us (a loadgame), just
	// take it, otherwise spawn one from scratch
	if (ent.inuse == false)
	{
		// clear the respawning variables
		InitClientResp(ent);

		if (!game.autosaved || !ent.client.pers.weapon)
			InitClientPersistant(ent);
	}

	ClientUserinfoChanged(ent, userinfo);

	if (game.maxclients > 1)
		gi.dprintf("%s connected\n", ent.client.pers.netname);

	ent.svflags = 0; // make sure we start with known default
	ent.client.pers.connected = true;

	return true;
};


/*
===========
ClientDisconnect

Called when a player drops from the server.
Will not be called between levels.
============
*/
void(entity ent) ClientDisconnect =
{
	if (!ent.is_client)
		return;
	
	gi.bprintf(PRINT_HIGH, "%s disconnected\n", ent.client.pers.netname);
	
	// send effect
	if (ent.inuse) {
		gi.WriteByte(svc_muzzleflash);
		gi.WriteShort(ent.s.number);
		gi.WriteByte(MZ_LOGOUT);
		gi.multicast(ent.s.origin, MULTICAST_PVS);
	}
	
	gi.unlinkentity(ent);
	ent.s.modelindex = 0;
	ent.s.sound = 0;
	ent.s.event = 0;
	ent.s.effects = 0;
	ent.solid = SOLID_NOT;
	ent.inuse = false;
	ent.classname = "disconnected";
	ent.client.pers.connected = false;
}

PROGS_LOCAL static entity pm_passent;

// pmove doesn't need to know about passent and contentmask
static void(trace_t *tr, vector start, vector mins, vector maxs, vector end) PM_trace =
{
    if (pm_passent.health > 0)
        gi.trace(tr, start, mins, maxs, end, pm_passent, MASK_PLAYERSOLID);
    else
        gi.trace(tr, start, mins, maxs, end, pm_passent, MASK_DEADSOLID);
}

entity() PlayerTrail_LastSpot;
void(vector pos) PlayerTrail_Add;

// from pweapon.qc
// noise types for PlayerNoise
typedef enum int
{
	PNOISE_SELF,
	PNOISE_WEAPON,
	PNOISE_IMPACT
} player_noise_t;

void(entity, vector, player_noise_t) PlayerNoise;
void(entity) Think_Weapon;

void(entity ent, usercmd_t ucmd) ClientThink =
{
	entity	other;
	int	i;
	pmove_t	pm;

	level.current_entity = ent;

	if (level.intermission_framenum) {
		ent.client.ps.pmove.pm_type = PM_FREEZE;
		// can exit intermission after five seconds
		if (level.framenum > level.intermission_framenum + 5.0f * BASE_FRAMERATE
			&& (ucmd.buttons & BUTTON_ANY))
			level.exitintermission = true;
		return;
	}

	pm_passent = ent;

	if (ent.client.chase_target) {
		ent.client.resp.cmd_angles = ucmd.angles;
	} else {

		// set up for pmove
		if (ent.movetype == MOVETYPE_NOCLIP)
			ent.client.ps.pmove.pm_type = PM_SPECTATOR;
		else if (ent.s.modelindex != 255)
			ent.client.ps.pmove.pm_type = PM_GIB;
		else if (ent.deadflag)
			ent.client.ps.pmove.pm_type = PM_DEAD;
		else
			ent.client.ps.pmove.pm_type = PM_NORMAL;

#ifdef GROUND_ZERO
		ent.client.ps.pmove.gravity = (int)(sv_gravity.intVal * ent.gravity);
#else
		ent.client.ps.pmove.gravity = sv_gravity.intVal;
#endif
		memcpy(&pm.s, &ent.client.ps.pmove, sizeof(pm.s));

		pm.s.origin = ent.s.origin;
		pm.s.velocity = ent.velocity;

		pm.snapinitial = !!memcmp(&ent.client.old_pmove, &pm.s, sizeof(pm.s));

		pm.cmd = ucmd;

		pm.trace = PM_trace;    // adds default parms
		pm.pointcontents = gi.pointcontents;

		// perform a pmove
#ifdef QUAKEC_PMOVE
		Pmove(&pm);
#else
		gi.Pmove(&pm);
#endif

		// save results of pmove
		memcpy(&ent.client.ps.pmove, &pm.s, sizeof(pm.s));
		memcpy(&ent.client.old_pmove, &ent.client.ps.pmove, sizeof(ent.client.old_pmove));

		ent.s.origin = pm.s.origin;
		ent.velocity = pm.s.velocity;

		ent.mins = pm.mins;
		ent.maxs = pm.maxs;

		ent.client.resp.cmd_angles = ucmd.angles;

		if (ent.groundentity != null_entity && pm.groundentity == null_entity && (pm.cmd.upmove >= 10) && (pm.waterlevel == 0)) {
			gi.sound(ent, CHAN_VOICE, gi.soundindex("*jump1.wav"), 1, ATTN_NORM, 0);
			PlayerNoise(ent, ent.s.origin, PNOISE_SELF);
		}

		ent.viewheight = (int)pm.viewheight;
		ent.waterlevel = pm.waterlevel;
		ent.watertype = pm.watertype;
		ent.groundentity = pm.groundentity;
		if (pm.groundentity != null_entity)
			ent.groundentity_linkcount = pm.groundentity.linkcount;

		if (ent.deadflag) {
			ent.client.ps.viewangles[ROLL] = 40f;
			ent.client.ps.viewangles[PITCH] = -15f;
			ent.client.ps.viewangles[YAW] = ent.client.killer_yaw;
		} else {
			ent.client.v_angle = pm.viewangles;
			ent.client.ps.viewangles = pm.viewangles;
		}

		gi.linkentity(ent);

		if (ent.movetype != MOVETYPE_NOCLIP)
			G_TouchTriggers(ent);

#ifdef GROUND_ZERO
		ent.gravity = 1.0;
#endif

		// touch other objects
		for (int i = 0; i < pm.touchents.length; i++)
		{
			entity other = pm.touchents[i];
			if (!other.touch)
				continue;
			other.touch(other, ent, null_plane, null_surface);
		}

	}

	ent.client.oldbuttons = ent.client.buttons;
	ent.client.buttons = ucmd.buttons;
	ent.client.latched_buttons |= ent.client.buttons & ~ent.client.oldbuttons;

	// save light level the player is standing on for
	// monster sighting AI
	ent.light_level = ucmd.lightlevel;

	// fire weapon from final position if needed
	if (ent.client.latched_buttons & BUTTON_ATTACK) {
		if (ent.client.resp.spectator) {

			ent.client.latched_buttons = 0;

			if (ent.client.chase_target) {
				ent.client.chase_target = world;
				ent.client.ps.pmove.pm_flags &= ~PMF_NO_PREDICTION;
			} else
				GetChaseTarget(ent);

		} else if (!ent.client.weapon_thunk) {
			ent.client.weapon_thunk = true;
			Think_Weapon(ent);
		}
	}

	if (ent.client.resp.spectator) {
		if (ucmd.upmove >= 10) {
			if (!(ent.client.ps.pmove.pm_flags & PMF_JUMP_HELD)) {
				ent.client.ps.pmove.pm_flags |= PMF_JUMP_HELD;
				if (ent.client.chase_target)
					ChaseNext(ent);
				else
					GetChaseTarget(ent);
			}
		} else
			ent.client.ps.pmove.pm_flags &= ~PMF_JUMP_HELD;
	}

	// update chase cam if being followed
	for (i = 1; i <= game.maxclients; i++) {
		other = itoe(i);
		if (other.inuse && other.client.chase_target == ent)
			UpdateChaseCam(other);
	}
};

// from ai.qc
bool(entity self, entity other) visible;

/*
==============
ClientBeginServerFrame

This will be called once for each server frame, before running
any other entities in the world.
==============
*/
void(entity ent) ClientBeginServerFrame =
{
	int         buttonMask;

	if (level.intermission_framenum)
		return;

	if (deathmatch.intVal &&
		ent.client.pers.spectator != ent.client.resp.spectator &&
		(level.framenum - ent.client.respawn_framenum) >= 5 * BASE_FRAMERATE) {
		spectator_respawn(ent);
		return;
	}

	// run weapon animations if it hasn't been done by a ucmd_t
	if (!ent.client.weapon_thunk && !ent.client.resp.spectator)
		Think_Weapon(ent);
	else
		ent.client.weapon_thunk = false;

	if (ent.deadflag) {
		// wait for any button just going down
		if (level.framenum > ent.client.respawn_framenum) {
			// in deathmatch, only wait for attack button
			if (deathmatch.intVal)
				buttonMask = BUTTON_ATTACK;
			else
				buttonMask = -1;

			if ((ent.client.latched_buttons & buttonMask) ||
				(deathmatch.intVal && (dmflags.intVal & DF_FORCE_RESPAWN))) {
				respawn(ent);
				ent.client.latched_buttons = 0;
			}
		}
		return;
	}

	// add player trail so monsters can follow
	if (!deathmatch.intVal)
		if (!visible(ent, PlayerTrail_LastSpot()))
			PlayerTrail_Add(ent.s.old_origin);

	ent.client.latched_buttons = 0;
}