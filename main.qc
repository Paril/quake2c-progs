const string GAMEVERSION = "progs";

// extended features
typedef enumflags : int
{
	GMF_CLIENTNUM,
	GMF_PROPERINUSE,
	GMF_MVDSPEC,
	GMF_WANT_ALL_DISCONNECTS,
	
	GMF_ENHANCED_SAVEGAMES		= 0x00000400,
	GMF_VARIABLE_FPS,
	GMF_EXTRA_USERINFO,
	GMF_IPV6_ADDRESS_AWARE
} game_features_t;

// features this game supports
const game_features_t G_FEATURES	= (GMF_PROPERINUSE | GMF_WANT_ALL_DISCONNECTS | GMF_ENHANCED_SAVEGAMES);

/*
============
InitGame

This will be called when the QC is first loaded, which
only happens when a new game is started or a save game
is loaded.
============
*/
static void() InitGame =
{
	gi.dprintf("===== "__FUNC__" =====\n");
	
	//FIXME: sv_ prefix is wrong for these
	sv_rollspeed = gi.cvar("sv_rollspeed", "200", 0);
	
	sv_rollangle = gi.cvar("sv_rollangle", "2", 0);
	sv_maxvelocity = gi.cvar("sv_maxvelocity", "2000", 0);
	sv_gravity = gi.cvar("sv_gravity", "800", 0);
	
	// noset vars
	dedicated = gi.cvar("dedicated", "0", CVAR_NOSET);
	
	// latched vars
	sv_cheats = gi.cvar("cheats", "0", CVAR_SERVERINFO | CVAR_LATCH);
	gi.cvar("gamename", GAMEVERSION, CVAR_SERVERINFO | CVAR_LATCH);
	gi.cvar("gamedate", __DATE__ , CVAR_SERVERINFO | CVAR_LATCH);
	
	cvar_t maxclients = gi.cvar("maxclients", "4", CVAR_SERVERINFO | CVAR_LATCH);
	maxspectators = gi.cvar("maxspectators", "4", CVAR_SERVERINFO);
#ifdef SINGLE_PLAYER
	deathmatch = gi.cvar("deathmatch", "0", CVAR_LATCH);
	coop = gi.cvar("coop", "0", CVAR_LATCH);
	skill = gi.cvar("skill", "1", CVAR_LATCH);
#else
	gi.cvar("deathmatch", "1", CVAR_NOSET);
	gi.cvar_forceset("deathmatch", "1");
	gi.cvar_forceset("coop", "0");
#endif
	maxentities = gi.cvar("maxentities", "1024", CVAR_LATCH);
	
	// change anytime vars
	dmflags = gi.cvar("dmflags", "0", CVAR_SERVERINFO);
	fraglimit = gi.cvar("fraglimit", "0", CVAR_SERVERINFO);
	timelimit = gi.cvar("timelimit", "0", CVAR_SERVERINFO);
#ifdef CTF
	capturelimit = gi.cvar("capturelimit", "0", CVAR_SERVERINFO);
	instantweap = gi.cvar("instantweap", "0", CVAR_SERVERINFO);
#endif
	password = gi.cvar("password", "", CVAR_USERINFO);
	spectator_password = gi.cvar("spectator_password", "", CVAR_USERINFO);
	needpass = gi.cvar("needpass", "0", CVAR_SERVERINFO);
	filterban = gi.cvar("filterban", "1", 0);
	
	g_select_empty = gi.cvar("g_select_empty", "0", CVAR_ARCHIVE);
	
	run_pitch = gi.cvar("run_pitch", "0.002", 0);
	run_roll = gi.cvar("run_roll", "0.005", 0);
	bob_up  = gi.cvar("bob_up", "0.005", 0);
	bob_pitch = gi.cvar("bob_pitch", "0.002", 0);
	bob_roll = gi.cvar("bob_roll", "0.002", 0);
	
	// flood control
	flood_msgs = gi.cvar("flood_msgs", "4", 0);
	flood_persecond = gi.cvar("flood_persecond", "4", 0);
	flood_waitdelay = gi.cvar("flood_waitdelay", "10", 0);
	
	// dm map list
	sv_maplist = gi.cvar("sv_maplist", "", 0);
	
	// obtain server features
	sv_features = gi.cvar("sv_features", "", 0);
	
	// export our own features
	gi.cvar_forceset("g_features", va("%i", G_FEATURES));
	
	game.maxclients = maxclients.intVal;
	game.maxentities = maxentities.intVal;
	
	// sync with Q2
	globals.num_edicts = game.maxclients + 1;
	
	InitItems();

#ifdef CTF
	CTFInit();
#endif
};

static void() ShutdownGame =
{
	gi.dprintf("===== "__FUNC__" =====\n");
};

// from spawn.qc
void() PreSpawnEntities;
void(string mapname, string entities, string spawnpoint) SpawnEntities;
void() PostSpawnEntities;
/*
=================
ClientEndServerFrames
=================
*/
static void() ClientEndServerFrames =
{
    // calc the player views now that all pushing
    // and damage has been added
	for (int i = 0; i < game.maxclients; i++)
	{
		entity ent = itoe(1 + i);
		
		if (!ent.inuse || !ent.is_client)
			continue;
			
		ClientEndServerFrame(ent);
	}
}

/*
=================
CreateTargetChangeLevel

Returns the created target changelevel
=================
*/
static entity(string new_map) CreateTargetChangeLevel =
{
	entity ent = G_Spawn();
	ent.classname = "target_changelevel";
	level.nextmap = new_map;
	ent.map = level.nextmap;
	return ent;
}

/*
=================
EndDMLevel

The timelimit or fraglimit has been exceeded
=================
*/
void() EndDMLevel =
{
	entity	ent;

	// stay on same level flag
	if (dmflags.intVal & DF_SAME_LEVEL) {
		BeginIntermission(CreateTargetChangeLevel(level.mapname));
		return;
	}

	// see if it's in the map list
	if (sv_maplist.str) {
		string st = sv_maplist.str;
		string f = 0;
		int s_offset = 0;
		string t = strtok(st, s_offset);
		while (t) {
			if (striequals(t, level.mapname))
			{
				// it's in the list, go to the next one
				t = strtok(st, s_offset);
				if (!t)
				{ // end of list, go to first one
					if (!f) // there isn't a first one, same level
						BeginIntermission(CreateTargetChangeLevel(level.mapname));
					else
						BeginIntermission(CreateTargetChangeLevel(f));
				}
				else
					BeginIntermission(CreateTargetChangeLevel(t));

				return;
			}
			if (!f)
				f = t;
			t = strtok(st, s_offset);
		}
	}

	if (level.nextmap) // go to a specific map
		BeginIntermission(CreateTargetChangeLevel(level.nextmap));
	else
	{  // search for a changelevel
		ent = G_Find(world, classname, "target_changelevel");
		if !(ent)
		{
			// the map designer didn't include a changelevel,
			// so create a fake ent that goes back to the same level
			BeginIntermission(CreateTargetChangeLevel(level.mapname));
			return;
		}
		BeginIntermission(ent);
	}
}


/*
=================
CheckNeedPass
=================
*/
static void() CheckNeedPass =
{
	int need;

	// if password or spectator_password has changed, update needpass
	// as needed
	if (password.modified || spectator_password.modified) {
		password.modified = spectator_password.modified = false;

		need = 0;

		if (password.str && !striequals(password.str, "none"))
			need |= 1;
		if (spectator_password.str && !striequals(spectator_password.str, "none"))
			need |= 2;

		gi.cvar_set("needpass", va("%d", need));
	}
}

/*
=================
CheckDMRules
=================
*/
static void() CheckDMRules =
{
	if (level.intermission_framenum)
		return;

#ifdef SINGLE_PLAYER
	if (!deathmatch.intVal)
		return;
#endif

#ifdef CTF
	if (ctf.intVal && CTFCheckRules())
	{
		EndDMLevel ();
		return;
	}
#endif

	if (timelimit.intVal)
	{
		if (level.time >= timelimit.intVal * 60)
		{
			gi.bprintf(PRINT_HIGH, "Timelimit hit.\n");
			EndDMLevel();
			return;
		}
	}

	if (fraglimit.intVal)
	{
		for (int i = 0; i < game.maxclients; i++)
		{
			entity cl = itoe(i + 1);

			if (!cl.inuse)
				continue;

			if (cl.client.resp.score >= fraglimit.intVal)
			{
				gi.bprintf(PRINT_HIGH, "Fraglimit hit.\n");
				EndDMLevel();
				return;
			}
		}
	}
}

/*
=============
ExitLevel
=============
*/
static void(void) ExitLevel =
{
	level.exitintermission = 0;
	level.intermission_framenum = 0;
	
	gi.AddCommandString(va("gamemap \"%s\"\n", level.changemap));
	level.changemap = 0;
	
	ClientEndServerFrames();
	
	// clear some things before going to next level
	for (int i = 0; i < game.maxclients; i++)
	{
		entity ent = itoe(1 + i);
	
		if (!ent.inuse)
			continue;
	
		if (ent.health > ent.max_health)
			ent.health = ent.max_health;
	}
}

// from player.qc
void(entity) ClientBeginServerFrame;
void(entity, usercmd_t) ClientThink;

/*
================
RunFrame

Advances the world by 0.1 seconds
================
*/
static void() RunFrame =
{
	level.framenum++;
	level.time = level.framenum * FRAMETIME;

#ifdef SINGLE_PLAYER
	// choose a client for monsters to target this frame
	AI_SetSightClient();
#endif
	
	// exit intermissions
	if (level.exitintermission)
	{
		ExitLevel();
		return;
	}
	
	//
	// treat each object in turn
	// even the world gets a chance to think
	//
	for (int i = 0 ; i < globals.num_edicts; i++)
	{
		entity ent = itoe(i);

		if (!ent.inuse)
			continue;
		
		level.current_entity = ent;
		
		ent.s.old_origin = ent.s.origin;
		
		// if the ground entity moved, make sure we are still on it
		if ((ent.groundentity != null_entity) && (ent.groundentity.linkcount != ent.groundentity_linkcount))
#ifdef SINGLE_PLAYER
		{
#endif
			ent.groundentity = null_entity;
#ifdef SINGLE_PLAYER
			if (!(ent.flags & (FL_SWIM | FL_FLY)) && (ent.svflags & SVF_MONSTER))
				M_CheckGround(ent);
		}
#endif
	
		if (i > 0 && i <= game.maxclients)
			ClientBeginServerFrame(ent);
	
		G_RunEntity(ent);
	}
	
	// see if it is time to end a deathmatch
	CheckDMRules();
	
	// see if needpass needs updated
	CheckNeedPass();
	
	// build the playerstate_t structures for all players
	ClientEndServerFrames();
}

static void(bool autosave) PreWriteGame =
{
#ifdef SINGLE_PLAYER
	if (!autosave)
		SaveClientData();

	game.autosaved = autosave;
#endif
};

static void(bool autosave) PostWriteGame =
{
#ifdef SINGLE_PLAYER
	game.autosaved = false;
#endif
};

static void() PreReadGame =
{
};

static void() PostReadGame =
{
};

static void() PreWriteLevel =
{
};

static void() PostWriteLevel =
{
};

static void() PreReadLevel = 
{
};

static void(int num_edicts) PostReadLevel = 
{
#ifdef SINGLE_PLAYER
	globals.num_edicts = num_edicts;
	
	// mark all clients as unconnected
	for (int i = 0 ; i < game.maxclients; i++)
	{
		entity ent = itoe(i + 1);
		ent.client.pers.connected = false;
	}

	// do any load time things at this point
	for (int i = 0 ; i < globals.num_edicts; i++)
	{
		entity ent = itoe(i);

		if (!ent.inuse)
			continue;

		// fire any cross-level triggers
		if (ent.classname == "target_crosslevel_target")
			ent.nextthink = level.framenum + (int)(ent.delay * BASE_FRAMERATE);
	}
#endif
};

struct game_export_t {
	int	apiversion;
	int	clientsize;
	
	void()		InitGame;
	void()		ShutdownGame;
	
	void()								PreSpawnEntities;
	void(string mapname, string entities, string spawnpoint)	SpawnEntities;
	void()								PostSpawnEntities;
	
	bool(entity ent, inout string userinfo)	ClientConnect;
	void(entity ent)				ClientBegin;
	void(entity ent, string userinfo)		ClientUserinfoChanged;
	void(entity ent)				ClientDisconnect;
	void(entity ent)				ClientCommand;
	void(entity ent, usercmd_t cmd)			ClientThink;
	
	void()	RunFrame;
	
	void()	ServerCommand;
	
	void(bool autosave)	PreWriteGame;
	void(bool autosave)	PostWriteGame;
	
	void()	PreReadGame;
	void()	PostReadGame;
	
	void()	PreWriteLevel;
	void()	PostWriteLevel;
	
	void()			PreReadLevel;
	void(int num_edicts)	PostReadLevel;
};

// Main entry point; if you need to do any global stuff, this is where
// ya do it.
API_FUNC void(out game_export_t exports) GetGameAPI =
{
	// set up constants for configstrings
	CS_SOUNDS		= CS_MODELS + MAX_MODELS;
	CS_IMAGES		= CS_SOUNDS + MAX_SOUNDS;
	CS_LIGHTS		= CS_IMAGES + MAX_IMAGES;
	CS_ITEMS		= CS_LIGHTS + MAX_LIGHTSTYLES;
	CS_PLAYERSKINS		= CS_ITEMS + MAX_ITEMS;
	CS_GENERAL		= CS_PLAYERSKINS + MAX_CLIENTS;
	MAX_CONFIGSTRINGS	= CS_GENERAL + MAX_GENERAL;
	
	exports.apiversion = GAMEC_API_VERSION;
	exports.clientsize = sizeof(gclient_t);

	exports.InitGame = InitGame;
	exports.ShutdownGame = ShutdownGame;

	exports.PreSpawnEntities = PreSpawnEntities;
	exports.SpawnEntities = SpawnEntities;
	exports.PostSpawnEntities = PostSpawnEntities;

	exports.ClientConnect = ClientConnect;
	exports.ClientBegin = ClientBegin;
	exports.ClientUserinfoChanged = ClientUserinfoChanged;
	exports.ClientDisconnect = ClientDisconnect;
	exports.ClientCommand = ClientCommand;
	exports.ClientThink = ClientThink;

	exports.RunFrame = RunFrame;

	exports.ServerCommand = ServerCommand;
	
	exports.PreWriteGame = PreWriteGame;
	exports.PostWriteGame = PostWriteGame;

	exports.PreReadGame = PreReadGame;
	exports.PostReadGame = PostReadGame;
	
	exports.PreWriteLevel = PreWriteLevel;
	exports.PostWriteLevel = PostWriteLevel;
	
	exports.PreReadLevel = PreReadLevel;
	exports.PostReadLevel = PostReadLevel;
}
