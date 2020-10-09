#include "m_player.h"

#ifdef SINGLE_PLAYER
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
	entity spot = world;

	while ((spot = G_Find(spot, classname, "info_player_start")))
	{
		if (!spot.targetname)
			continue;
		vector d = self.s.origin - spot.s.origin;
		if (VectorLength(d) < 384)
		{
			if (!striequals(self.targetname, spot.targetname))
				self.targetname = spot.targetname;
			return;
		}
	}
}

// now if that one wasn't ugly enough for you then try this one on for size
// some maps don't have any coop spots at all, so we need to create them
// where they should have been

static void(entity self) SP_CreateCoopSpots =
{
	if (level.mapname == "security")
	{
		entity spot = G_Spawn();
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
	}
}

#endif
/*QUAKED info_player_start (1 0 0) (-16 -16 -24) (16 16 32)
The normal starting point for a level.
*/
API_FUNC static void(entity self) SP_info_player_start =
{
#ifdef SINGLE_PLAYER
	if (!coop.intVal)
		return;

	if (level.mapname == "security")
	{
		// invoke one of our gross, ugly, disgusting hacks
		self.think = SP_CreateCoopSpots;
		self.nextthink = level.framenum + 1;
	}
#endif
}

void(entity) SP_misc_teleporter_dest;

/*QUAKED info_player_deathmatch (1 0 1) (-16 -16 -24) (16 16 32)
potential spawning position for deathmatch games
*/
API_FUNC static void(entity self) SP_info_player_deathmatch =
{
#ifdef SINGLE_PLAYER
	if (!deathmatch.intVal)
	{
		G_FreeEdict(self);
		return;
	}

#endif
	SP_misc_teleporter_dest(self);
}

#ifdef SINGLE_PLAYER
/*QUAKED info_player_coop (1 0 1) (-16 -16 -24) (16 16 32)
potential spawning position for coop games
*/
API_FUNC static void(entity self) SP_info_player_coop =
{
	if (!coop.intVal)
	{
		G_FreeEdict(self);
		return;
	}

	if (level.mapname == "jail2"   ||
		level.mapname == "jail4"   ||
		level.mapname == "mine1"   ||
		level.mapname == "mine2"   ||
		level.mapname == "mine3"   ||
		level.mapname == "mine4"   ||
		level.mapname == "lab"     ||
		level.mapname == "boss1"   ||
		level.mapname == "fact3"   ||
		level.mapname == "biggun"  ||
		level.mapname == "space"   ||
		level.mapname == "command" ||
		level.mapname == "power2"  ||
		level.mapname == "strike")
	{
		// invoke one of our gross, ugly, disgusting hacks
		self.think = SP_FixCoopSpots;
		self.nextthink = level.framenum + 1;
	}
}

#endif
/*QUAKED info_player_intermission (1 0 1) (-16 -16 -24) (16 16 32)
The deathmatch intermission point will be at one of these
Use 'angles' instead of 'angle', so you can set pitch or roll as well as yaw.  'pitch yaw roll'
*/
API_FUNC static void() SP_info_player_intermission =
{
}

#if defined(GROUND_ZERO) && defined(SINGLE_PLAYER)
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

typedef enum : int
{
	GENDER_MALE,
	GENDER_FEMALE,
	GENDER_NEUTRAL
} gender_t;

static gender_t(entity ent) GetGender =
{
	if (!ent.is_client)
		return GENDER_MALE;
	
	string info = Info_ValueForKey(ent.client.pers.userinfo, "gender");

	if (strat(info, 0) == 'f' || strat(info, 0) == 'F')
		return GENDER_FEMALE;
	else if (strat(info, 0) != 'm' && strat(info, 0) != 'm')
		return GENDER_NEUTRAL;

	return GENDER_MALE;
}

// from cmds.qc
bool(entity, entity) OnSameTeam;

PROGS_LOCAL means_of_death_t meansOfDeath;

static void(entity self, entity inflictor, entity attacker) ClientObituary =
{
	if (OnSameTeam(self, attacker))
		meansOfDeath |= MOD_FRIENDLY_FIRE;

	int ff = meansOfDeath & MOD_FRIENDLY_FIRE;
	int mod = meansOfDeath & ~MOD_FRIENDLY_FIRE;
	string message = 0;
	string message2 = 0;
	gender_t gender = GetGender(self);

	static const string their[] = {
		"his",
		"her",
		"their"
	};

	static const string themself[] = {
		"himself",
		"herself",
		"themself"
	};

	switch (mod)
	{
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
	case MOD_GEKK:
	case MOD_BRAINTENTACLE:
		message = "... that's gotta hurt!";
		break;
#endif
	}

	if (attacker == self)
	{
		switch (mod)
		{
		case MOD_HELD_GRENADE:
			message = "tried to put the pin back in";
			break;
		case MOD_HG_SPLASH:
		case MOD_G_SPLASH:
			message = va("tripped on %s own grenade", their[gender]);
			break;
		case MOD_R_SPLASH:
			message = va("blew %s up", themself[gender]);
			break;
		case MOD_BFG_BLAST:
			message = "should have used a smaller gun";
			break;
#ifdef THE_RECKONING
		case MOD_TRAP:
			message = va("was sucked into %s own trap", their[gender]);
			break;
#endif
		default:
			message = va("killed %s", themself[gender]);
			break;
		}
	}

	if (message)
	{
		gi.bprintf(PRINT_MEDIUM, "%s %s.\n", self.client.pers.netname, message);
#ifdef SINGLE_PLAYER
		if (deathmatch.intVal)
#endif
			self.client.resp.score--;
		self.enemy = world;
		return;
	}

	self.enemy = attacker;
	if (attacker && attacker.is_client)
	{
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
			message = "was ripped to shreds by";
			message2 = "'s ripper gun";
			break;
		case MOD_PHALANX:
			message = "was evaporated by";
			break;
		case MOD_TRAP:
			message = "was caught in";
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
#ifdef GRAPPLE
		case MOD_GRAPPLE:
			message = "was caught by";
			message2 = "'s grapple";
			break;
#endif
		}

		if (message)
		{
			gi.bprintf(PRINT_MEDIUM, "%s %s %s%s\n", self.client.pers.netname, message, attacker.client.pers.netname, message2);
#ifdef SINGLE_PLAYER

			if (deathmatch.intVal)
			{
#endif
				if (ff)
					attacker.client.resp.score--;
				else
					attacker.client.resp.score++;
#ifdef SINGLE_PLAYER
			}
#endif
			return;
		}
	}
}

static void(entity self) TossClientWeapon =
{
#ifdef SINGLE_PLAYER
	if (!deathmatch.intVal)
		return;

#endif
	gitem_t *it = self.client.pers.weapon;

	if (!self.client.pers.inventory[self.client.ammo_index] || it->pickup_name == "Blaster")
		it = 0;

	bool quad = (dmflags.intVal & DF_QUAD_DROP) && (self.client.quad_framenum > (level.framenum + 10));
		
#ifdef THE_RECKONING
	bool quadfire = (dmflags.intVal & DF_QUADFIRE_DROP) && (self.client.quadfire_framenum > (level.framenum + 10));
#endif

	float spread;

	if (it && quad)
		spread = 22.5f;
#ifdef THE_RECKONING
	else if (it && quadfire)
		spread = 12.5;
#endif
	else
		spread = 0.0f;

	if (it)
	{
		self.client.v_angle[YAW] -= spread;
		entity drop = Drop_Item(self, it);
		self.client.v_angle[YAW] += spread;
		drop.spawnflags = DROPPED_PLAYER_ITEM;
	}

	if (quad)
	{
		self.client.v_angle[YAW] += spread;
		entity drop = Drop_Item(self, FindItemByClassname("item_quad"));
		self.client.v_angle[YAW] -= spread;
		drop.spawnflags |= DROPPED_PLAYER_ITEM;

		drop.touch = Touch_Item;
		drop.nextthink = self.client.quad_framenum;
		drop.think = G_FreeEdict;
	}
	
#ifdef THE_RECKONING
	if (quadfire)
	{
		self.client.v_angle[YAW] += spread;
		entity drop = Drop_Item (self, FindItemByClassname ("item_quadfire"));
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
	if (attacker && attacker != self)
		self.client.killer_yaw = vectoyaw(attacker.s.origin - self.s.origin);
	else if (inflictor && inflictor != self)
		self.client.killer_yaw = vectoyaw(inflictor.s.origin - self.s.origin);
	else
		self.client.killer_yaw = self.s.angles[YAW];
}

// from hud.qc
void(entity) Cmd_Help_f;

// from misc.qc
void(entity, string, int, int) ThrowGib;
void(entity, int) ThrowClientHead;

#ifdef GRAPPLE
void(entity) GrapplePlayerReset;
#endif

#ifdef CTF
void(entity, entity, entity) CTFFragBonuses;
void(entity) CTFDeadDropFlag;
void(entity) CTFDeadDropTech;
#endif

/*
==================
player_die
==================
*/
void(entity self, entity inflictor, entity attacker, int damage, vector point) player_die =
{
	self.avelocity = vec3_origin;

	self.takedamage = true;
	self.movetype = MOVETYPE_TOSS;

	self.s.modelindex2 = 0; // remove linked weapon model
#ifdef CTF
	self.s.modelindex3 = 0; // remove linked flag
#endif

	self.s.angles[PITCH] = 0;
	self.s.angles[ROLL] = 0;

	self.s.sound = 0;
	self.client.weapon_sound = 0;

	self.maxs.z = -8f;

	self.svflags |= SVF_DEADMONSTER;

	if (!self.deadflag)
	{
		self.client.respawn_framenum = (int)(level.framenum + 1.0f * BASE_FRAMERATE);
		LookAtKiller(self, inflictor, attacker);
		self.client.ps.pmove.pm_type = PM_DEAD;
		ClientObituary(self, inflictor, attacker);

#ifdef CTF
		// if at start and same team, clear
		if (ctf.intVal && meansOfDeath == MOD_TELEFRAG &&
			self.client.resp.ctf_state < 2 &&
			self.client.resp.ctf_team == attacker.client.resp.ctf_team)
		{
			attacker.client.resp.score--;
			self.client.resp.ctf_state = 0;
		}

		CTFFragBonuses(self, inflictor, attacker);
#endif

		TossClientWeapon(self);

#ifdef GRAPPLE
		GrapplePlayerReset(self);
#endif

#ifdef CTF
		CTFDeadDropFlag(self);
		CTFDeadDropTech(self);
#endif

#ifdef SINGLE_PLAYER
		if (deathmatch.intVal)
#endif
			Cmd_Help_f(self);       // show scores

		// clear inventory
		// this is kind of ugly, but it's how we want to handle keys in coop
		for (int n = 0; n < itemlist.length; n++)
#ifdef SINGLE_PLAYER
		{
			if (coop.intVal && itemlist[n].flags & IT_KEY)
				self.client.resp.coop_respawn.inventory[n] = self.client.pers.inventory[n];
#endif
			self.client.pers.inventory[n] = 0;
#ifdef SINGLE_PLAYER
		}
#endif
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
	if ((meansOfDeath & ~MOD_FRIENDLY_FIRE) == MOD_TRACKER)
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
		// gib
#ifdef GROUND_ZERO
		if (!(self.flags & FL_NOGIB))
		{
#endif
			gi.sound(self, CHAN_BODY, gi.soundindex("misc/udeath.wav"), 1, ATTN_NORM, 0);
			for (int n = 0; n < 4; n++)
				ThrowGib(self, "models/objects/gibs/sm_meat/tris.md2", damage, GIB_ORGANIC);
#ifdef GROUND_ZERO
		}
		self.flags &= ~FL_NOGIB;
#endif

		ThrowClientHead(self, damage);
		self.client.anim_priority = ANIM_DEATH;
		self.client.anim_end = 0;
		self.takedamage = false;
	}
	else if (!self.deadflag) // normal death
	{
		static int i;

		i = (i + 1) % 3;

		// start a death animation
		self.client.anim_priority = ANIM_DEATH;
		if (self.client.ps.pmove.pm_flags & PMF_DUCKED)
		{
			self.s.frame = FRAME_crdeath1 - 1;
			self.client.anim_end = FRAME_crdeath5;
		}
		else switch (i)
		{
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

	self.deadflag = DEAD_DEAD;

	gi.linkentity(self);
}

//=======================================================================

static inline void(entity other, ammo_t ammo_id, int new_max) SetAmmoMax =
{
	other.client.pers.max_ammo[ammo_id] = new_max;
}

#ifdef CTF
void(entity) CTFAssignTeam;
#endif

/*
==============
InitClientPersistant

This is only called when the game first initializes in single player,
but is called after each death and level change in deathmatch
==============
*/
void(entity ent) InitClientPersistant =
{
	memclear(&ent.client.pers, sizeof(ent.client.pers));
	
	gitem_t *it = FindItem("Blaster");
	ent.client.pers.selected_item = it->id;
	ent.client.pers.inventory[ent.client.pers.selected_item] = 1;
	
	ent.client.pers.weapon = ent.client.pers.lastweapon = it;

#ifdef GRAPPLE
	ent.client.pers.inventory[FindItem("Grapple").id] = 1;
#endif
	
	ent.client.pers.health         = 100;
	ent.client.pers.max_health     = 100;

	SetAmmoMax(ent, AMMO_BULLETS, 200);
	SetAmmoMax(ent, AMMO_SHELLS, 100);
	SetAmmoMax(ent, AMMO_ROCKETS, 50);
	SetAmmoMax(ent, AMMO_GRENADES, 50);
	SetAmmoMax(ent, AMMO_CELLS, 200);
	SetAmmoMax(ent, AMMO_SLUGS, 50);
	
#ifdef THE_RECKONING
	SetAmmoMax(ent, AMMO_MAGSLUG, 50);
	SetAmmoMax(ent, AMMO_TRAP, 5);
#endif

#ifdef GROUND_ZERO
	SetAmmoMax(ent, AMMO_PROX, 50);
	SetAmmoMax(ent, AMMO_TESLA, 50);
	SetAmmoMax(ent, AMMO_FLECHETTES, 200);
	SetAmmoMax(ent, AMMO_DISRUPTOR, 100);
#endif
	
	ent.client.pers.connected = true;
}

static void(entity ent) InitClientResp =
{
#ifdef CTF
	ctfteam_t ctf_team = ent.client.resp.ctf_team;
	bool id_state = ent.client.resp.id_state;
#endif

	memclear(&ent.client.resp, sizeof(client_respawn_t));

#ifdef CTF
	ent.client.resp.ctf_team = ctf_team;
	ent.client.resp.id_state = id_state;
#endif

	ent.client.resp.enterframe = level.framenum;
#ifdef SINGLE_PLAYER
	memcpy(&ent.client.resp.coop_respawn, &ent.client.pers, sizeof(client_persistant_t));
#endif

#ifdef CTF
	if (ctf.intVal && ent.client.resp.ctf_team < CTF_TEAM1)
		CTFAssignTeam(ent);
#endif
}

#ifdef SINGLE_PLAYER
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
#endif

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
float(entity spot) PlayersRangeFromSpot =
{
	float bestplayerdistance = 9999999f;

	for (int n = 1; n <= game.maxclients; n++)
	{
		entity player = itoe(n);

		if (!player.inuse)
			continue;

		if (player.health <= 0)
			continue;

		float playerdistance = VectorDistance(spot.s.origin, player.s.origin);

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
entity() SelectRandomDeathmatchSpawnPoint =
{
	int	count = 0;
	entity spot = world, spot1 = world, spot2 = world;
	float range1 = FLT_MAX, range2 = FLT_MAX;

	while ((spot = G_Find(spot, classname, "info_player_deathmatch")))
	{
		count++;
		float range = PlayersRangeFromSpot(spot);
		if (range < range1)
		{
			range1 = range;
			spot1 = spot;
		}
		else if (range < range2)
		{
			range2 = range;
			spot2 = spot;
		}
	}

	if (!count)
		return world;

	if (count <= 2)
		spot1 = spot2 = world;
	else
		count -= 2;

	int selection = Q_rand_uniform(count);

	spot = world;
	do
	{
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
entity() SelectFarthestDeathmatchSpawnPoint =
{
	entity spot = world;
	entity bestspot = world;
	float bestdistance = 0;
	
	while ((spot = G_Find(spot, classname, "info_player_deathmatch")))
	{
		float bestplayerdistance = PlayersRangeFromSpot(spot);

		if (bestplayerdistance > bestdistance)
		{
			bestspot = spot;
			bestdistance = bestplayerdistance;
		}
	}

	if (bestspot)
		return bestspot;

	// if there is a player just spawned on each and every start spot
	// we have no choice to turn one into a telefrag meltdown
	return G_Find(world, classname, "info_player_deathmatch");
}

static entity() SelectDeathmatchSpawnPoint =
{
	if (dmflags.intVal & DF_SPAWN_FARTHEST)
		return SelectFarthestDeathmatchSpawnPoint();
	else
		return SelectRandomDeathmatchSpawnPoint();
}

#ifdef SINGLE_PLAYER
#ifdef GROUND_ZERO
static entity(entity ent) SelectLavaCoopSpawnPoint =
{
	float lavatop = -99999f;
	entity highestlava = world;

	// first, find the highest lava
	// remember that some will stop moving when they've filled their
	// areas...
	entity lava = world;
	while ((lava = G_Find (lava, classname, "func_door")))
	{
		vector center = (lava.absmax + lava.absmin) * 0.5f;

		if (lava.spawnflags & 2 && (gi.pointcontents(center) & MASK_WATER))
		{
			if (lava.absmax[2] > lavatop)
			{
				lavatop = lava.absmax[2];
				highestlava = lava;
			}
		}
	}

	// if we didn't find ANY lava, then return NULL
	if !(highestlava)
		return world;

	// find the top of the lava and include a small margin of error (plus bbox size)
	lavatop = highestlava.absmax[2] + 64;

	// find all the lava spawn points and store them in spawnPoints[]
	entity spot = world;
	int numPoints = 0;
	entity spawnPoints[64] = { 0 };

	while ((spot = G_Find (spot, classname, "info_player_coop_lava")))
	{
		if (numPoints == 64)
			break;

		spawnPoints[numPoints++] = spot;
	}

	if (numPoints < 1)
		return world;

	// walk up the sorted list and return the lowest, open, non-lava spawn point
	spot = world;
	float lowest = 999999f;
	entity pointWithLeastLava = world;

	for (int index = 0; index < numPoints; index++)
	{
		if (spawnPoints[index].s.origin[2] < lavatop)
			continue;

		if (PlayersRangeFromSpot(spawnPoints[index]) > 32)
		{
			if (spawnPoints[index].s.origin[2] < lowest)
			{
				// save the last point
				pointWithLeastLava = spawnPoints[index];
				lowest = spawnPoints[index].s.origin[2];
			}
		}
	}

	// FIXME - better solution????
	// well, we may telefrag someone, but oh well...
	if (pointWithLeastLava)
		return pointWithLeastLava;

	return world;
}
#endif

static entity(entity ent) SelectCoopSpawnPoint =
{
#ifdef GROUND_ZERO
	// rogue hack, but not too gross...
	if (!stricmp(level.mapname, "rmine2p") || !stricmp(level.mapname, "rmine2"))
		return SelectLavaCoopSpawnPoint (ent);
#endif

	int index = ent.s.number - 1;
	
	// player 0 starts in normal player spawn point
	if !(index)
		return world;

	entity spot = world;

	// assume there are four coop spots at each spawnpoint
	while ((spot = G_Find(spot, classname, "info_player_coop")))
	{
		if (stricmp(game.spawnpoint, spot.targetname) == 0)
		{
			// this is a coop spawn point for one of the clients here
			index--;
			if (!index)
				return spot;        // this is it
		}
	}


	return spot;
}
#endif

#ifdef CTF
entity(entity) SelectCTFSpawnPoint;
#endif

/*
===========
SelectSpawnPoint

Chooses a player start, deathmatch start, coop start, etc
============
*/
static void(entity ent, out vector origin, out vector angles) SelectSpawnPoint =
{
#ifdef SINGLE_PLAYER
	entity spot = world;

#ifdef CTF
	if (ctf.intVal)
		spot = SelectCTFSpawnPoint(ent);
	else
#endif
	if (deathmatch.intVal)
		spot = SelectDeathmatchSpawnPoint();
	else if (coop.intVal)
		spot = SelectCoopSpawnPoint(ent);
#else
	entity spot = SelectDeathmatchSpawnPoint();
#endif

	// find a single player start spot
	if (!spot && game.spawnpoint)
		while ((spot = G_Find(spot, classname, "info_player_start")))
			if (stricmp(game.spawnpoint, spot.targetname) == 0)
				break;

	if !(spot)
		// there wasn't a spawnpoint found yet
		spot = G_Find(spot, classname, "info_player_start");

	if !(spot)
	{
		gi.dprintf("Couldn't find spawn point \"%s\"\n", game.spawnpoint);
		return;
	}

	origin = spot.s.origin;
	origin[2] += 9f;
	angles = spot.s.angles;
}

void() InitBodyQue =
{
	level.body_que = 0;

	for (int i = 0; i < BODY_QUEUE_SIZE; i++)
	{
		entity ent = G_Spawn();
		ent.classname = "bodyque";
	}
}

static void(entity self, entity inflictor, entity attacker, int damage, vector point) body_die =
{
	if (self.health < -40)
	{
		gi.sound(self, CHAN_BODY, gi.soundindex("misc/udeath.wav"), 1, ATTN_NORM, 0);
		for (int n = 0; n < 4; n++)
			ThrowGib(self, "models/objects/gibs/sm_meat/tris.md2", damage, GIB_ORGANIC);
		self.s.origin[2] -= 48f;
		ThrowClientHead(self, damage);
		self.takedamage = false;
	}
}

static void(entity ent) CopyToBodyQue =
{
	gi.unlinkentity(ent);
	
	// grab a body que and cycle to the next one
	entity body = itoe(game.maxclients + level.body_que + 1);
	level.body_que = (level.body_que + 1) % BODY_QUEUE_SIZE;
	
	// send an effect on the removed body
	if (body.s.modelindex)
	{
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
	body.takedamage = true;
	
	gi.linkentity(body);
}

// from player.qc
void(entity self) PutClientInServer;

void(entity self) respawn =
{
#ifdef SINGLE_PLAYER
	if (!deathmatch.intVal && !coop.intVal)
	{
		// restart the entire server
		gi.AddCommandString("pushmenu loadgame\n");
		return;
	}

#endif
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
}

/*
 * only called when pers.spectator changes
 * note that resp.spectator should be the opposite of pers.spectator here
 */
static void(entity ent) spectator_respawn =
{
	// if the user wants to become a spectator, make sure he doesn't
	// exceed max_spectators
	if (ent.client.pers.spectator)
	{
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
		int i, numspec;

		for (i = 1, numspec = 0; i <= game.maxclients; i++)
			if (itoe(i).inuse && itoe(i).client.pers.spectator)
				numspec++;

		if (numspec >= maxspectators.intVal)
		{
			gi.cprintf(ent, PRINT_HIGH, "Server spectator limit is full.");
			ent.client.pers.spectator = false;
			// reset his spectator var
			gi.WriteByte(svc_stufftext);
			gi.WriteString("spectator 0\n");
			gi.unicast(ent, true);
			return;
		}
	}
	else
	{
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
	if (!ent.client.pers.spectator)
	{
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

#ifdef CTF
bool(entity) CTFStartClient;
#endif

/*
===========
PutClientInServer

Called when a player connects to a server or respawns in
a deathmatch.
============
*/
void(entity ent) PutClientInServer =
{
	static const vector player_mins = '-16 -16 -24';
	static const vector player_maxs = ' 16  16  32';

	// find a spawn point
	// do it before setting health back up, so farthest
	// ranging doesn't count this client
	vector spawn_origin, spawn_angles;
	SelectSpawnPoint(ent, spawn_origin, spawn_angles);

	// deathmatch wipes most client data every spawn
	client_respawn_t    resp;
#ifdef SINGLE_PLAYER
	if (deathmatch.intVal)
	{
#endif
		string userinfo = ent.client.pers.userinfo;
		
		memcpy(&resp, &ent.client.resp, sizeof(resp));
		
		InitClientPersistant(ent);
		ClientUserinfoChanged(ent, userinfo);
#ifdef SINGLE_PLAYER
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
#endif

	// clear everything but the persistant data
	client_persistant_t saved;
	memcpy(&saved, &ent.client.pers, sizeof(saved));
	memclear(&ent.client, sizeof(ent.client));
	memcpy(&ent.client.pers, &saved, sizeof(saved));
	if (ent.client.pers.health <= 0)
		InitClientPersistant(ent);
	memcpy(&ent.client.resp, &resp, sizeof(resp));

#ifdef SINGLE_PLAYER
	// copy some data from the client to the entity
	FetchClientEntData(ent);
#endif

	// clear entity values
	ent.groundentity = null_entity;
	ent.takedamage = true;
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
	ent.client.ps.pmove.pm_flags &= ~PMF_NO_PREDICTION;

	ent.client.ps.fov = stof(Info_ValueForKey(ent.client.pers.userinfo, "fov"));
	if (ent.client.ps.fov < 1.f)
		ent.client.ps.fov = 90.f;
	else if (ent.client.ps.fov > 160.f)
		ent.client.ps.fov = 160.f;

	if (ent.client.pers.weapon)
		ent.client.ps.gunindex = gi.modelindex(ent.client.pers.weapon->view_model);
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

#ifdef CTF
	if (CTFStartClient(ent))
		return;
#endif

	if (!KillBox(ent)) {
		// could't spawn in?
	}

	gi.linkentity(ent);

#if defined(GROUND_ZERO) && defined(SINGLE_PLAYER)
	// my tribute to cash's level-specific hacks. I hope I live
	// up to his trailblazing cheese.
	if (!deathmatch.intVal && level.mapname == "rboss")
	{
		// if you get on to rboss in single player or coop, ensure
		// the player has the nuke key. (not in DM)
		gitem_t *it = FindItem("Antimatter Bomb");
		ent.client.pers.selected_item = it->id;
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

void(entity ent) ClientBegin =
{
#ifdef SINGLE_PLAYER
	// if there is already a body waiting for us (a loadgame), just
	// take it, otherwise spawn one from scratch
	if (!deathmatch.intVal && ent.inuse)
		// the client has cleared the client side viewangles upon
		// connecting to the server, which is different than the
		// state when the game is saved, so we need to compensate
		// with deltaangles
		ent.client.ps.pmove.delta_angles = ent.client.ps.viewangles;
	else
	{
#endif
		// a spawn point will completely reinitialize the entity
		// except for the persistant data that was initialized at
		// ClientConnect() time
		G_InitEdict(ent);
		InitClientResp(ent);
		PutClientInServer(ent);
#ifdef SINGLE_PLAYER
	}
#endif

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

#ifdef CTF
void(entity, string) CTFAssignSkin;
#endif

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
	if (!Info_Validate(userinfo))
		userinfo = "\\name\\badinfo\\skin\\male/grunt";
	
	// set name
	string str = Info_ValueForKey(userinfo, "name");
	ent.client.pers.netname = str;
	
	// set spectator
	str = Info_ValueForKey(userinfo, "spectator");

	// spectators are only supported in deathmatch
	if (
#ifdef SINGLE_PLAYER
		deathmatch.intVal &&
#endif
		!strempty(str) && str != "0")
		ent.client.pers.spectator = true;
	else
		ent.client.pers.spectator = false;
	
	// set skin
	str = Info_ValueForKey(userinfo, "skin");

	// combine name and skin into a configstring
#ifdef CTF
	// set player name field (used in id_state view)
	gi.configstring (CS_GENERAL + ent.s.number - 1, ent.client.pers.netname);

	if (ctf.intVal)
		CTFAssignSkin(ent, str);
	else
#endif
		gi.configstring(CS_PLAYERSKINS + ent.s.number - 1, va("%s\\%s", ent.client.pers.netname, str));
	
	// fov
	ent.client.ps.fov = stof(Info_ValueForKey(userinfo, "fov"));
	if (ent.client.ps.fov < 1.f)
		ent.client.ps.fov = 90.f;
	else if (ent.client.ps.fov > 160.f)
		ent.client.ps.fov = 160.f;
	
	// handedness
	str = Info_ValueForKey(userinfo, "hand");
	if (!strempty(str))
		ent.client.pers.hand = maxi(RIGHT_HANDED, mini(CENTER_HANDED, stoi(str)));
	
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
bool(entity ent, inout string userinfo) ClientConnect =
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

	if (
#ifdef SINGLE_PLAYER
		deathmatch.intVal &&
#endif
		!strempty(value) && value != "0")
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

#ifdef CTF
	if (ctf.intVal)
	{
		// force team join
		ent.client.resp.ctf_team = -1;
		ent.client.resp.id_state = true;
	}
#endif

#ifdef SINGLE_PLAYER
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
#else
	InitClientResp(ent);
	InitClientPersistant(ent);
#endif

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

#ifdef CTF
	CTFDeadDropFlag(ent);
	CTFDeadDropTech(ent);
#endif
	
	// send effect
	if (ent.inuse)
	{
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

#ifdef SINGLE_PLAYER
entity() PlayerTrail_LastSpot;
void(vector pos) PlayerTrail_Add;

// from pweapon.qc
// noise types for PlayerNoise
typedef enum : int
{
	PNOISE_SELF,
	PNOISE_WEAPON,
	PNOISE_IMPACT
} player_noise_t;

void(entity, vector, player_noise_t) PlayerNoise;
#endif

void(entity) Think_Weapon;

#ifdef CTF
void(entity) CTFApplyRegeneration;
#endif

#ifdef GRAPPLE
void(entity) GrapplePull;
#endif

void(entity ent, usercmd_t ucmd) ClientThink =
{
	level.current_entity = ent;

	if (level.intermission_framenum)
	{
		ent.client.ps.pmove.pm_type = PM_FREEZE;
		// can exit intermission after five seconds
		if (level.framenum > level.intermission_framenum + 5.0f * BASE_FRAMERATE
			&& (ucmd.buttons & BUTTON_ANY))
			level.exitintermission = true;
		return;
	}

	pm_passent = ent;

	if (ent.client.chase_target)
		ent.client.resp.cmd_angles = ucmd.angles;
	else
	{
		pmove_t	pm;

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

		if (ent.groundentity != null_entity && pm.groundentity == null_entity && (pm.cmd.upmove >= 10) && (pm.waterlevel == 0))
#ifdef SINGLE_PLAYER
		{
#endif
			gi.sound(ent, CHAN_VOICE, gi.soundindex("*jump1.wav"), 1, ATTN_NORM, 0);
#ifdef SINGLE_PLAYER
			PlayerNoise(ent, ent.s.origin, PNOISE_SELF);
		}
#endif

		ent.viewheight = (int)pm.viewheight;
		ent.waterlevel = pm.waterlevel;
		ent.watertype = pm.watertype;
		ent.groundentity = pm.groundentity;
		if (pm.groundentity != null_entity)
			ent.groundentity_linkcount = pm.groundentity.linkcount;

		if (ent.deadflag)
		{
			ent.client.ps.viewangles[ROLL] = 40f;
			ent.client.ps.viewangles[PITCH] = -15f;
			ent.client.ps.viewangles[YAW] = ent.client.killer_yaw;
		}
		else
		{
			ent.client.v_angle = pm.viewangles;
			ent.client.ps.viewangles = pm.viewangles;
		}

#ifdef GRAPPLE
		if (ent.client.grapple)
			GrapplePull(ent.client.grapple);
#endif

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
			other.touch(other, ent, vec3_origin, null_surface);
		}
	}

	ent.client.oldbuttons = ent.client.buttons;
	ent.client.buttons = ucmd.buttons;
	ent.client.latched_buttons |= ent.client.buttons & ~ent.client.oldbuttons;

	// save light level the player is standing on for
	// monster sighting AI
	ent.light_level = ucmd.lightlevel;

	// fire weapon from final position if needed
	if ((ent.client.latched_buttons & BUTTON_ATTACK)
#ifdef CTF
		&& ent.movetype != MOVETYPE_NOCLIP
#endif
		)
	{
		if (ent.client.resp.spectator)
		{
			ent.client.latched_buttons = 0;

			if (ent.client.chase_target)
			{
				ent.client.chase_target = world;
				ent.client.ps.pmove.pm_flags &= ~PMF_NO_PREDICTION;
			}
			else
				GetChaseTarget(ent);
		}
		else if (!ent.client.weapon_thunk)
		{
			ent.client.weapon_thunk = true;
			Think_Weapon(ent);
		}
	}

#ifdef CTF
	CTFApplyRegeneration(ent);
#endif

	if (ent.client.resp.spectator)
	{
		if (ucmd.upmove >= 10)
		{
			if (!(ent.client.ps.pmove.pm_flags & PMF_JUMP_HELD))
			{
				ent.client.ps.pmove.pm_flags |= PMF_JUMP_HELD;
				if (ent.client.chase_target)
					ChaseNext(ent);
				else
					GetChaseTarget(ent);
			}
		}
		else
			ent.client.ps.pmove.pm_flags &= ~PMF_JUMP_HELD;
	}

	// update chase cam if being followed
	for (int i = 1; i <= game.maxclients; i++)
	{
		entity other = itoe(i);
		if (other.inuse && other.client.chase_target == ent)
			UpdateChaseCam(other);
	}
};

/*
==============
ClientBeginServerFrame

This will be called once for each server frame, before running
any other entities in the world.
==============
*/
void(entity ent) ClientBeginServerFrame =
{
	if (level.intermission_framenum)
		return;

	if (
#ifdef SINGLE_PLAYER
		deathmatch.intVal &&
#endif
		ent.client.pers.spectator != ent.client.resp.spectator &&
		(level.framenum - ent.client.respawn_framenum) >= 5 * BASE_FRAMERATE)
	{
		spectator_respawn(ent);
		return;
	}

	// run weapon animations if it hasn't been done by a ucmd_t
	if (!ent.client.weapon_thunk && !ent.client.resp.spectator
#ifdef CTF
		&& ent->movetype != MOVETYPE_NOCLIP
#endif
		)
		Think_Weapon(ent);
	else
		ent.client.weapon_thunk = false;

	if (ent.deadflag)
	{
		// wait for any button just going down
		if (level.framenum > ent.client.respawn_framenum)
		{
#ifdef SINGLE_PLAYER
			int buttonMask;

			// in deathmatch, only wait for attack button
			if (deathmatch.intVal)
				buttonMask = BUTTON_ATTACK;
			else
				buttonMask = -1;
#else
			const int buttonMask = BUTTON_ATTACK;

#endif
			if ((ent.client.latched_buttons & buttonMask) || (
#ifdef SINGLE_PLAYER
				deathmatch.intVal && 
#endif
				(dmflags.intVal & DF_FORCE_RESPAWN)))
			{
				respawn(ent);
				ent.client.latched_buttons = 0;
			}
		}

		return;
	}
#ifdef SINGLE_PLAYER

	// add player trail so monsters can follow
	if (!deathmatch.intVal)
		if (!visible(ent, PlayerTrail_LastSpot()))
			PlayerTrail_Add(ent.s.old_origin);
#endif

	ent.client.latched_buttons = 0;
}