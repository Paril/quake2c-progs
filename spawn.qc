struct spawn_field_t
{
	string		key;
	string		field;
	bool		ignore;
};

API_FUNC static spawn_field_t spawn_fields[] =
{
	{ "classname" },
	{ "model" },
	{ "spawnflags" },
	{ "speed" },
	{ "accel" },
	{ "decel" },
	{ "target" },
	{ "targetname" },
	{ "pathtarget" },
	{ "deathtarget" },
	{ "killtarget" },
	{ "combattarget" },
	{ "message" },
	{ "team" },
	{ "wait" },
	{ "delay" },
	{ "random", "rand" },
	{ "move_origin" },
	{ "move_angles" },
	{ "style" },
	{ "count" },
	{ "health" },
	{ "sounds" },
	{ "dmg" },
	{ "mass" },
	{ "volume" },
	{ "attenuation" },
	{ "map" },
	{ "origin", "s.origin" },
	{ "angles", "s.angles" },
	
	{ "light", "", true },
};

API_FUNC static void(entity ent) SP_func_group = 
{
	G_FreeEdict(ent);
}

static bool(string key, string value, entity ent) ED_ParseField =
{
	for (int i = 0; i < spawn_fields.length; i++)
	{
		if (stricmp(spawn_fields[i].key, key))
			continue;
		
		if (!spawn_fields[i].ignore)
			entity_key_parse(ent, spawn_fields[i].field ?: spawn_fields[i].key, value);

		return true;
	}
	
	return false;
};

static bool(string key, string value) ED_ParseSpawnTemp =
{
	return struct_key_parse("st", key, value);
};

static INLINE void() ClearSpawnTemp =
{
	memclear(&st, sizeof(st));
}

static void(string entities, __inout int entities_offset, entity ent) ED_ParseEdict =
{
	bool init = false;
	
	// go through all the dictionary pairs
	while (true)
	{
		// parse key
		string key = strtok(entities, entities_offset);
		
		if (key == "}")
			break;
		else if (strempty(key))
			gi.error(__FUNC__": EOF without closing brace");

		init = true;
		
		// keynames with a leading underscore are used for utility comments,
		// and are immediately discarded by quake
		if (strat(key, 0) == '_')
		{
			strtok(entities, entities_offset);
			continue;
		}

		string value = strtok(entities, entities_offset);
		
		if (!ED_ParseField(key, value, ent) && !ED_ParseSpawnTemp(key, value))
			gi.dprintf(__FUNC__": %s is not a field\n", key);
	}
	
	// QC-specific hack to support .angle
	if (st.angle)
		ent.s.angles[YAW] = st.angle;
	
	if (!init)
		G_FreeEdict(ent);
};

// these are only used by the spawn function
const int SPAWNFLAG_NOT_EASY		= 0x00000100;
const int SPAWNFLAG_NOT_MEDIUM		= 0x00000200;
const int SPAWNFLAG_NOT_HARD		= 0x00000400;
const int SPAWNFLAG_NOT_DEATHMATCH	= 0x00000800;
const int SPAWNFLAG_NOT_COOP		= 0x00001000;

// from client.qc
void() SaveClientData;

/*
===============
ED_CallSpawn

Finds the spawn function for the entity and calls it
===============
*/
bool(entity ent) ED_CallSpawn =
{
	if (!ent.classname) {
		gi.dprintf("ED_CallSpawn: NULL classname\n");
		G_FreeEdict(ent);
		return false;
	}
	
#ifdef GROUND_ZERO
	ent.gravityVector = '0 0 -1';

	if (ent.classname == "weapon_nailgun")
		ent.classname = GetItemKeyByIndex(FindItem("ETF Rifle"), classname);
	if (ent.classname == "ammo_nails")
		ent.classname = GetItemKeyByIndex(FindItem("Flechettes"), classname);
	if (ent.classname == "weapon_heatbeam")
		ent.classname = GetItemKeyByIndex(FindItem("Plasma Beam"), classname);
#endif
	
	// check item spawn functions
	gitem_id_t itemid = FindItemByClassname(ent.classname);
	
	if (itemid)
	{
		SpawnItem(ent, itemid);
		return true;
	}

	void(entity) spawnfunc = func_get(va("SP_%s", ent.classname));
	
	if (spawnfunc)
	{
		spawnfunc(ent);
		return true;
	}


	gi.dprintf("%s doesn't have a spawn function\n", ent.classname);
	G_FreeEdict(ent);
	return false;
}


/*
================
G_FindTeams

Chain together all entities with a matching team field.

All but the first will have the FL_TEAMSLAVE flag set.
All but the last will have the teamchain field set to the next one
================
*/
// Paril: it took me a while to sus out what exactly this function was for in
// Ground Zero, but basically it was to fix their mappers' bad teams. Maybe they
// were broken later on or grouped wrong and it caused issues? Anyways,
// basically it re-ordered teams with trains so that a train was always
// at the front and synced up their speeds.
static void G_FixTeams (void)
{
	int c = 0;

	for (int i = 1; i < globals.num_edicts; i++)
	{
		entity e = itoe(i);

		if (!e.teammaster)
			continue;
		
		entity master = e.teammaster;

		// already a train, so don't worry about us
		if (master.classname == "func_train")
			continue;

		entity first_train = world;

		for (entity e2 = master; e2; e2 = e2.teamchain)
		{
			if (e2.classname == "func_train")
			{
				first_train = e2;
				break;
			}
		}

		// no train in this team
		if (!first_train)
			continue;

		c++;
		
		entity prev = world;

		// got one! we have to reposition this train to be the master now.
		// swap all of the masters out, and store the guy before the train
		for (entity e2 = master; e2; e2 = e2.teamchain)
		{
			entity next = e2.teamchain;

			e2.teammaster = first_train;

			// copy over movetype and speed
			e2.movetype = MOVETYPE_PUSH;
			e2.speed = first_train.speed;
			
			// reached the guy before first_train
			if (e2.teamchain == first_train)
				prev = e2;
		}
		
		// shim us in
		if (!prev)
			gi.error("wat");

		// master = old teammaster
		// prev = guy before first_train
		// first_train = first.. train

		prev.teamchain = master;
		entity old_master_next = master.teamchain;
		master.teamchain = first_train.teamchain;
		first_train.teamchain = old_master_next;
		
		// remove our slave flag
		first_train.flags &= ~FL_TEAMSLAVE;
		
		// give the old master the flag
		master.flags |= FL_TEAMSLAVE;
	}

	gi.dprintf ("%i teams repaired\n", c);
}

static void() G_FindTeams =
{
	entity	e, e2, chain;
	int	i, j;
	int	c, c2;

	c = 0;
	c2 = 0;
	for (i = 1; i < globals.num_edicts; i++)
	{
		e = itoe(i);
		 
		if (!e.inuse)
			continue;
		if (!e.team)
			continue;
		if (e.flags & FL_TEAMSLAVE)
			continue;
		chain = e;
		e.teammaster = e;
		e.teamchain = 0;
		c++;
		c2++;
		for (j = i + 1; j < globals.num_edicts ; j++)
		{
			e2 = itoe(j);

			if (!e2.inuse)
				continue;
			if (!e2.team)
				continue;
			if (e2.flags & FL_TEAMSLAVE)
				continue;
			if (e.team == e2.team) {
				c2++;
				chain.teamchain = e2;
				e2.teammaster = e;
				e2.teamchain = 0;
				chain = e2;
				e2.flags |= FL_TEAMSLAVE;
			}
		}
	}

	gi.dprintf("%i teams with %i entities\n", c, c2);
	
	G_FixTeams();
}


/*
==============
SpawnEntities

Creates a server's entity / program execution context by
parsing textual entity definitions out of an ent file.
==============
*/
void PreSpawnEntities()
{
	SaveClientData();
}

void(string mapname, string entities, string spawnpoint) SpawnEntities =
{
	int entities_offset = 0;
	int skill_level = skill.intVal;

	if (skill_level < 0)
		skill_level = 0;
	if (skill_level > 3)
		skill_level = 3;
	if (skill.intVal != skill_level)
		gi.cvar_forceset("skill", itos(skill_level));

	memclear(&level, sizeof(level));
	level.mapname = mapname;
	game.spawnpoint = spawnpoint;
	
	entity ent = world;
	int inhibit = 0;
	
	// parse ents
	while (1)
	{
		string token = strtok(entities, entities_offset);
		
		if (entities_offset < 0)
			break;

		if (token != "{")
			gi.error(__FUNC__": found %s when expecting {", token);
		
		if (ent.inuse)
			ent = G_Spawn();
		else
		{
			G_FreeEdict(ent);
			G_InitEdict(ent);	
		}
		
		ED_ParseEdict(entities, entities_offset, ent);

		// yet another map hack
		if (!stricmp(level.mapname, "command") && !stricmp(ent.classname, "trigger_once") && !stricmp(ent.model, "*27"))
			ent.spawnflags &= ~SPAWNFLAG_NOT_HARD;
			
		// remove things (except the world) from different skill levels or deathmatch
		if (ent != world)
		{
			if (deathmatch.intVal)
			{
				if (ent.spawnflags & SPAWNFLAG_NOT_DEATHMATCH)
				{
					G_FreeEdict(ent);
					inhibit++;
					continue;
				}
			}
			else
			{
#ifdef GROUND_ZERO
				if (coop.intVal && (ent.spawnflags & SPAWNFLAG_NOT_COOP))
				{
					G_FreeEdict (ent);	
					inhibit++;
					continue;
				}
				
				// TODO: there was a block here about (EASY | MED | HARD) meaning that it's coop-only.
				// is this true in only rogue maps?
#endif

				if (	((skill_level == 0) && (ent.spawnflags & SPAWNFLAG_NOT_EASY)) ||
					((skill_level == 1) && (ent.spawnflags & SPAWNFLAG_NOT_MEDIUM)) ||
					(((skill_level == 2) || (skill_level == 3)) && (ent.spawnflags & SPAWNFLAG_NOT_HARD)))
				{
					G_FreeEdict(ent);
					inhibit++;
					continue;
				}
			}

			ent.spawnflags &= ~(SPAWNFLAG_NOT_EASY | SPAWNFLAG_NOT_MEDIUM | SPAWNFLAG_NOT_HARD | SPAWNFLAG_NOT_COOP | SPAWNFLAG_NOT_DEATHMATCH);
		}

		if (!ED_CallSpawn(ent))
			inhibit++;
#ifdef GROUND_ZERO
		else
			ent.s.renderfx |= RF_IR_VISIBLE;
#endif
	
		ClearSpawnTemp();
	}
	
	ClearSpawnTemp();

	gi.dprintf("%i entities inhibited\n", inhibit);

	G_FindTeams();

	PlayerTrail_Init();

#ifdef GROUND_ZERO
	if (!deathmatch.intVal)
		InitHintPaths();
#endif
};

void() PostSpawnEntities =
{
};

//===================================================================

PROGS_LOCAL_STATIC const string single_statusbar =
"yb -24 "

// health
"xv 0 "
"hnum "
"xv 50 "
"pic 0 "

// ammo
"if 2 "
"   xv  100 "
"   anum "
"   xv  150 "
"   pic 2 "
"endif "

// armor
"if 4 "
"   xv  200 "
"   rnum "
"   xv  250 "
"   pic 4 "
"endif "

// selected item
"if 6 "
"   xv  296 "
"   pic 6 "
"endif "

"yb -50 "

// picked up item
"if 7 "
"   xv  0 "
"   pic 7 "
"   xv  26 "
"   yb  -42 "
"   stat_string 8 "
"   yb  -50 "
"endif "

// timer
"if 9 "
"   xv  262 "
"   num 2   10 "
"   xv  296 "
"   pic 9 "
"endif "

//  help / weapon icon
"if 11 "
"   xv  148 "
"   pic 11 "
"endif "
;

PROGS_LOCAL_STATIC const string dm_statusbar =
"yb -24 "

// health
"xv 0 "
"hnum "
"xv 50 "
"pic 0 "

// ammo
"if 2 "
"   xv  100 "
"   anum "
"   xv  150 "
"   pic 2 "
"endif "

// armor
"if 4 "
"   xv  200 "
"   rnum "
"   xv  250 "
"   pic 4 "
"endif "

// selected item
"if 6 "
"   xv  296 "
"   pic 6 "
"endif "

"yb -50 "

// picked up item
"if 7 "
"   xv  0 "
"   pic 7 "
"   xv  26 "
"   yb  -42 "
"   stat_string 8 "
"   yb  -50 "
"endif "

// timer
"if 9 "
"   xv  246 "
"   num 2   10 "
"   xv  296 "
"   pic 9 "
"endif "

//  help / weapon icon
"if 11 "
"   xv  148 "
"   pic 11 "
"endif "

//  frags
"xr -50 "
"yt 2 "
"num 3 14 "

// spectator
"if 17 "
"xv 0 "
"yb -58 "
"string2 \"SPECTATOR MODE\" "
"endif "

// chase camera
"if 16 "
"xv 0 "
"yb -68 "
"string \"Chasing\" "
"xv 64 "
"stat_string 16 "
"endif "
;

/*QUAKED worldspawn (0 0 0) ?

Only used for the world.
"sky"   environment map name
"skyaxis"   vector axis for rotating sky
"skyrotate" speed of rotation in degrees/second
"sounds"    music cd track number
"gravity"   800 is default gravity
"message"   text to print at user logon
*/
API_FUNC static void(entity ent) SP_worldspawn =
{
	ent.movetype = MOVETYPE_PUSH;
	ent.solid = SOLID_BSP;
	ent.inuse = true;          // since the world doesn't use G_Spawn()
	ent.s.modelindex = 1;      // world model is always index 1

	//---------------

	// reserve some spots for dead player bodies for coop / deathmatch
	InitBodyQue();

	// set configstrings for items
	SetItemNames();

	if (st.nextmap)
		level.nextmap = st.nextmap;

	// make some data visible to the server

	if (ent.message) {
		gi.configstring(CS_NAME, ent.message);
		level.level_name = ent.message;
	} else
		level.level_name = level.mapname;

	if (st.sky)
		gi.configstring(CS_SKY, st.sky);
	else
		gi.configstring(CS_SKY, "unit1_");

	gi.configstring(CS_SKYROTATE, va("%f", st.skyrotate));

	gi.configstring(CS_SKYAXIS, va("%f %f %f", st.skyaxis[0], st.skyaxis[1], st.skyaxis[2]));

	gi.configstring(CS_CDTRACK, va("%i", ent.sounds));

	gi.configstring(CS_MAXCLIENTS, va("%i", game.maxclients));

	// status bar program
	if (deathmatch.intVal)
		gi.configstring(CS_STATUSBAR, dm_statusbar);
	else
		gi.configstring(CS_STATUSBAR, single_statusbar);

	//---------------


	// help icon for statusbar
	gi.imageindex("i_help");
	level.pic_health = gi.imageindex("i_health");
	gi.imageindex("help");
	gi.imageindex("field_3");

	if (!st.gravity)
		gi.cvar_set("sv_gravity", "800");
	else
		gi.cvar_set("sv_gravity", st.gravity);

	snd_fry = gi.soundindex("player/fry.wav");  // standing in lava / slime

	PrecacheItem(FindItem("Blaster"));

	gi.soundindex("player/lava1.wav");
	gi.soundindex("player/lava2.wav");

	gi.soundindex("misc/pc_up.wav");
	gi.soundindex("misc/talk1.wav");

	gi.soundindex("misc/udeath.wav");

	// gibs
	gi.soundindex("items/respawn1.wav");

	// sexed sounds
	gi.soundindex("*death1.wav");
	gi.soundindex("*death2.wav");
	gi.soundindex("*death3.wav");
	gi.soundindex("*death4.wav");
	gi.soundindex("*fall1.wav");
	gi.soundindex("*fall2.wav");
	gi.soundindex("*gurp1.wav");        // drowning damage
	gi.soundindex("*gurp2.wav");
	gi.soundindex("*jump1.wav");        // player jump
	gi.soundindex("*pain25_1.wav");
	gi.soundindex("*pain25_2.wav");
	gi.soundindex("*pain50_1.wav");
	gi.soundindex("*pain50_2.wav");
	gi.soundindex("*pain75_1.wav");
	gi.soundindex("*pain75_2.wav");
	gi.soundindex("*pain100_1.wav");
	gi.soundindex("*pain100_2.wav");

	// sexed models
	// THIS ORDER MUST MATCH THE DEFINES IN g_local.h
	// you can add more, max 19 (pete change)
	gi.modelindex("#w_blaster.md2");
	gi.modelindex("#w_shotgun.md2");
	gi.modelindex("#w_sshotgun.md2");
	gi.modelindex("#w_machinegun.md2");
	gi.modelindex("#w_chaingun.md2");
	gi.modelindex("#a_grenades.md2");
	gi.modelindex("#w_glauncher.md2");
	gi.modelindex("#w_rlauncher.md2");
	gi.modelindex("#w_hyperblaster.md2");
	gi.modelindex("#w_railgun.md2");
	gi.modelindex("#w_bfg.md2");

#ifdef THE_RECKONING
	gi.modelindex ("#w_phalanx.md2");
	gi.modelindex ("#w_ripper.md2");
#endif

#ifdef GROUND_ZERO
	gi.modelindex ("#w_disrupt.md2");
	gi.modelindex ("#w_etfrifle.md2");
	gi.modelindex ("#w_plasma.md2");
	gi.modelindex ("#w_plauncher.md2");
	gi.modelindex ("#w_chainfist.md2");
#endif

	//-------------------

	gi.soundindex("player/gasp1.wav");      // gasping for air
	gi.soundindex("player/gasp2.wav");      // head breaking surface, not gasping

	gi.soundindex("player/watr_in.wav");    // feet hitting water
	gi.soundindex("player/watr_out.wav");   // feet leaving water

	gi.soundindex("player/watr_un.wav");    // head going underwater

	gi.soundindex("player/u_breath1.wav");
	gi.soundindex("player/u_breath2.wav");

	gi.soundindex("items/pkup.wav");        // bonus item pickup
	gi.soundindex("world/land.wav");        // landing thud
	gi.soundindex("misc/h2ohit1.wav");      // landing splash

	gi.soundindex("items/damage.wav");
#ifdef GROUND_ZERO
	gi.soundindex ("misc/ddamage1.wav");
#endif
	gi.soundindex("items/protect.wav");
	gi.soundindex("items/protect4.wav");
	gi.soundindex("weapons/noammo.wav");

	gi.soundindex("infantry/inflies1.wav");

	sm_meat_index = gi.modelindex("models/objects/gibs/sm_meat/tris.md2");
	gi.modelindex("models/objects/gibs/arm/tris.md2");
	gi.modelindex("models/objects/gibs/bone/tris.md2");
	gi.modelindex("models/objects/gibs/bone2/tris.md2");
	gi.modelindex("models/objects/gibs/chest/tris.md2");
	gi.modelindex("models/objects/gibs/skull/tris.md2");
	gi.modelindex("models/objects/gibs/head2/tris.md2");

//
// Setup light animation tables. 'a' is total darkness, 'z' is doublebright.
//

	// 0 normal
	gi.configstring(CS_LIGHTS + 0, "m");

	// 1 FLICKER (first variety)
	gi.configstring(CS_LIGHTS + 1, "mmnmmommommnonmmonqnmmo");

	// 2 SLOW STRONG PULSE
	gi.configstring(CS_LIGHTS + 2, "abcdefghijklmnopqrstuvwxyzyxwvutsrqponmlkjihgfedcba");

	// 3 CANDLE (first variety)
	gi.configstring(CS_LIGHTS + 3, "mmmmmaaaaammmmmaaaaaabcdefgabcdefg");

	// 4 FAST STROBE
	gi.configstring(CS_LIGHTS + 4, "mamamamamama");

	// 5 GENTLE PULSE 1
	gi.configstring(CS_LIGHTS + 5, "jklmnopqrstuvwxyzyxwvutsrqponmlkj");

	// 6 FLICKER (second variety)
	gi.configstring(CS_LIGHTS + 6, "nmonqnmomnmomomno");

	// 7 CANDLE (second variety)
	gi.configstring(CS_LIGHTS + 7, "mmmaaaabcdefgmmmmaaaammmaamm");

	// 8 CANDLE (third variety)
	gi.configstring(CS_LIGHTS + 8, "mmmaaammmaaammmabcdefaaaammmmabcdefmmmaaaa");

	// 9 SLOW STROBE (fourth variety)
	gi.configstring(CS_LIGHTS + 9, "aaaaaaaazzzzzzzz");

	// 10 FLUORESCENT FLICKER
	gi.configstring(CS_LIGHTS + 10, "mmamammmmammamamaaamammma");

	// 11 SLOW PULSE NOT FADE TO BLACK
	gi.configstring(CS_LIGHTS + 11, "abcdefghijklmnopqrrqponmlkjihgfedcba");

	// styles 32-62 are assigned by the light program for switchable lights

	// 63 testing
	gi.configstring(CS_LIGHTS + 63, "a");
}
