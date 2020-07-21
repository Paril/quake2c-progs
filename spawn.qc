struct spawn_field_t
{
	string		key;
	int		field;
};

API_FUNC static spawn_field_t spawn_fields[] =
{
	{ "classname", (int)(__variant)classname },
	{ "model", (int)(__variant)model },
	{ "spawnflags", (int)(__variant)spawnflags },
	{ "speed", (int)(__variant)speed },
	{ "accel", (int)(__variant)accel },
	{ "decel", (int)(__variant)decel },
	{ "target", (int)(__variant)target },
	{ "targetname", (int)(__variant)targetname },
	{ "pathtarget", (int)(__variant)pathtarget },
	{ "deathtarget", (int)(__variant)deathtarget },
	{ "killtarget", (int)(__variant)killtarget },
	{ "combattarget", (int)(__variant)combattarget },
	{ "message", (int)(__variant)message },
	{ "team", (int)(__variant)team },
	{ "wait", (int)(__variant)wait },
	{ "delay", (int)(__variant)delay },
	{ "random", (int)(__variant)rand },
	{ "move_origin", (int)(__variant)move_origin },
	{ "move_angles", (int)(__variant)move_angles },
	{ "style", (int)(__variant)style },
	{ "count", (int)(__variant)count },
	{ "health", (int)(__variant)health },
	{ "sounds", (int)(__variant)sounds },
	{ "light", (int)(__variant)-1 },
	{ "dmg", (int)(__variant)dmg },
	{ "mass", (int)(__variant)mass },
	{ "volume", (int)(__variant)volume },
	{ "attenuation", (int)(__variant)attenuation },
	{ "map", (int)(__variant)map },
	{ "origin", (int)(__variant)s.origin },
	{ "angles", (int)(__variant)s.angles }
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
		
		if (spawn_fields[i].field != -1)
			entity_key_parse(ent, (.__variant)(__variant)spawn_fields[i].field, value);

		return true;
	}
	
	return false;
};

static bool(string key, string value) ED_ParseSpawnTemp =
{
	return struct_key_parse("st", key, value);
};

static inline void() ClearSpawnTemp =
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
	if (!ent->classname) {
		gi.dprintf("ED_CallSpawn: NULL classname\n");
		G_FreeEdict(ent);
		return false;
	}
	
	// check item spawn functions
	gitem_id_t itemid = FindItemByClassname(ent->classname);
	
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


	gi.dprintf("%s doesn't have a spawn function\n", ent->classname);
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
		 
		if (!e->inuse)
			continue;
		if (!e->team)
			continue;
		if (e->flags & FL_TEAMSLAVE)
			continue;
		chain = e;
		e->teammaster = e;
		c++;
		c2++;
		for (j = i + 1; j < globals.num_edicts ; j++)
		{
			e2 = itoe(j);

			if (!e2->inuse)
				continue;
			if (!e2->team)
				continue;
			if (e2->flags & FL_TEAMSLAVE)
				continue;
			if (e->team == e2->team) {
				c2++;
				chain->teamchain = e2;
				e2->teammaster = e;
				chain = e2;
				e2->flags |= FL_TEAMSLAVE;
			}
		}
	}

	gi.dprintf("%i teams with %i entities\n", c, c2);
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
			ent->spawnflags &= ~SPAWNFLAG_NOT_HARD;
			
		// remove things (except the world) from different skill levels or deathmatch
		if (ent != world)
		{
			if (deathmatch.intVal)
			{
				if (ent->spawnflags & SPAWNFLAG_NOT_DEATHMATCH)
				{
					G_FreeEdict(ent);
					inhibit++;
					continue;
				}
			}
			else
			{
				if ( /* ((coop->value) && (ent->spawnflags & SPAWNFLAG_NOT_COOP)) || */
					((skill_level == 0) && (ent->spawnflags & SPAWNFLAG_NOT_EASY)) ||
					((skill_level == 1) && (ent->spawnflags & SPAWNFLAG_NOT_MEDIUM)) ||
					(((skill_level == 2) || (skill_level == 3)) && (ent->spawnflags & SPAWNFLAG_NOT_HARD)))
				{
					G_FreeEdict(ent);
					inhibit++;
					continue;
				}
			}

			ent->spawnflags &= ~(SPAWNFLAG_NOT_EASY | SPAWNFLAG_NOT_MEDIUM | SPAWNFLAG_NOT_HARD | SPAWNFLAG_NOT_COOP | SPAWNFLAG_NOT_DEATHMATCH);
		}

		if (!ED_CallSpawn(ent))
			inhibit++;
	
		ClearSpawnTemp();
	}
	
	ClearSpawnTemp();

	gi.dprintf("%i entities inhibited\n", inhibit);

	G_FindTeams();

	PlayerTrail_Init();
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
	ent->movetype = MOVETYPE_PUSH;
	ent->solid = SOLID_BSP;
	ent->inuse = true;          // since the world doesn't use G_Spawn()
	ent->s.modelindex = 1;      // world model is always index 1

	//---------------

	// reserve some spots for dead player bodies for coop / deathmatch
	InitBodyQue();

	// set configstrings for items
	SetItemNames();

	if (st.nextmap)
		level.nextmap = st.nextmap;

	// make some data visible to the server

	if (ent->message) {
		gi.configstring(CS_NAME, ent->message);
		level.level_name = ent->message;
	} else
		level.level_name = level.mapname;

	if (st.sky)
		gi.configstring(CS_SKY, st.sky);
	else
		gi.configstring(CS_SKY, "unit1_");

	gi.configstring(CS_SKYROTATE, va("%f", st.skyrotate));

	gi.configstring(CS_SKYAXIS, va("%f %f %f", st.skyaxis[0], st.skyaxis[1], st.skyaxis[2]));

	gi.configstring(CS_CDTRACK, va("%i", ent->sounds));

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
