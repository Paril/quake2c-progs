/*
======================================================================

INTERMISSION

======================================================================
*/

// from hud.qc
void(entity ent, entity killer) DeathmatchScoreboardMessage;

void(entity ent) MoveClientToIntermission =
{
#ifdef SINGLE_PLAYER
	if (deathmatch.intVal || coop.intVal)
#endif
		ent.client.showscores = true;
	ent.s.origin = level.intermission_origin;
	ent.client.ps.pmove.origin = level.intermission_origin;
	ent.client.ps.viewangles = level.intermission_angle;
	ent.client.ps.pmove.pm_type = PM_FREEZE;
	ent.client.ps.gunindex = 0;
	ent.client.ps.blend[3] = 0;
	ent.client.ps.rdflags &= ~RDF_UNDERWATER;

	// clean up powerup info
	ent.client.quad_framenum = 0;
	ent.client.invincible_framenum = 0;
	ent.client.breather_framenum = 0;
	ent.client.enviro_framenum = 0;
	ent.client.grenade_blew_up = false;
	ent.client.grenade_framenum = 0;

#ifdef THE_RECKONING
	ent.client.quadfire_framenum = 0;
	ent.client.trap_blew_up = false;
	ent.client.trap_framenum = 0;
#endif

#ifdef GROUND_ZERO
	ent.client.ps.rdflags &= ~RDF_IRGOGGLES;		// PGM
	ent.client.ir_framenum = 0;					// PGM
	ent.client.nuke_framenum = 0;					// PMM
	ent.client.double_framenum = 0;				// PMM
#endif

	ent.viewheight = 0;
	ent.s.modelindex = 0;
	ent.s.modelindex2 = 0;
	ent.s.modelindex3 = 0;
	ent.s.modelindex = 0;
	ent.s.effects = 0;
	ent.s.sound = 0;
	ent.solid = SOLID_NOT;

	gi.linkentity(ent);

	// add the layout
#ifdef SINGLE_PLAYER
	if (deathmatch.intVal || coop.intVal)
	{
#endif
		DeathmatchScoreboardMessage(ent, world);
		gi.unicast(ent, true);
#ifdef SINGLE_PLAYER
	}
#endif
}

void(entity targ) BeginIntermission =
{
	entity	ent, cl;

	if (level.intermission_framenum)
		return;     // already activated

#ifdef CTF
	if (ctf.intVal)
		CTFCalcScores();
#endif

#ifdef SINGLE_PLAYER
	game.autosaved = false;
#endif

	// respawn any dead clients
	for (int i = 0 ; i < game.maxclients ; i++)
	{
		cl = itoe(1 + i);
		if (!cl.inuse)
			continue;
		if (cl.health <= 0)
			respawn(cl);
	}

	level.intermission_framenum = level.framenum;
	level.changemap = targ.map;

#ifdef SINGLE_PLAYER
	if (strstr(level.changemap, "*") != -1)
	{
		if (coop.intVal)
		{
			for (int i = 0 ; i < game.maxclients ; i++)
			{
				cl = itoe(1 + i);
				if (!cl.inuse)
					continue;
					
				gitem_t *it = itemlist;
				// strip players of all keys between units
				for (int n = 0; n < itemlist.length; n++, it++)
					if (it->flags & IT_KEY)
						cl.client.pers.inventory[n] = 0;
			}
		}
	}
	else
	{
		if (!deathmatch.intVal)
		{
			level.exitintermission = 1;     // go immediately to the next level
			return;
		}
	}
#endif

	level.exitintermission = 0;

	// find an intermission spot
	ent = G_Find(world, classname, "info_player_intermission");
	if !(ent)
	{
		// the map creator forgot to put in an intermission point...
		ent = G_Find(world, classname, "info_player_start");
		if !(ent)
			ent = G_Find(world, classname, "info_player_deathmatch");
	}
	else
	{
		// chose one of four spots
		int i = Q_rand() & 3;
		while (i--)
		{
			ent = G_Find(ent, classname, "info_player_intermission");
			if !(ent)   // wrap around the list
				ent = G_Find(ent, classname, "info_player_intermission");
		}
	}

	level.intermission_origin = ent.s.origin;
	level.intermission_angle = ent.s.angles;

	// move all clients to the intermission point
	for (int i = 0; i < game.maxclients; i++)
	{
		cl = itoe(1 + i);
		if (!cl.inuse)
			continue;
		MoveClientToIntermission(cl);
	}
}


/*
==================
DeathmatchScoreboardMessage

==================
*/
void(entity ent, entity killer) DeathmatchScoreboardMessage =
{
#ifdef CTF
	if (ctf.intVal)
	{
		CTFScoreboardMessage(ent, killer);
		return;
	}
#endif

	string	entry;
	string	str = "";
	int	stringlength;
	int	i, j, k;
	int	sorted[MAX_CLIENTS] = { 0 };
	int	sortedscores[MAX_CLIENTS] = { 0 };
	int	score, total;
	int	x, y;
	entity	cl_ent;
	string	tag;

	// sort the clients by score
	total = 0;
	for (i = 0 ; i < game.maxclients ; i++) {
		cl_ent = itoe(1 + i);
		if (!cl_ent.inuse || cl_ent.client.resp.spectator)
			continue;
		score = cl_ent.client.resp.score;
		for (j = 0 ; j < total ; j++) {
			if (score > sortedscores[j])
				break;
		}
		for (k = total ; k > j ; k--) {
			sorted[k] = sorted[(k - 1)];
			sortedscores[k] = sortedscores[(k - 1)];
		}
		sorted[j] = i;
		sortedscores[j] = score;
		total++;
	}

	// print level name and exit rules
	stringlength = 0;

	// add the clients in sorted order
	if (total > 12)
		total = 12;

	for (i = 0 ; i < total ; i++) {
		cl_ent = itoe(1 + sorted[i]);

		if (i >= 6)
			x = 160;
		else
			x = 0;
		y = 32 + 32 * (i % 6);

		// add a dogtag
		if (cl_ent == ent)
			tag = "tag1";
		else if (cl_ent == killer)
			tag = "tag2";
		else
			tag = 0;
		if (tag) {
			entry = va("xv %i yv %i picn %s ", x + 32, y, tag);
			j = strlen(entry);
			if (stringlength + j > 1024)
				break;
			str = strconcat(str, entry);
			stringlength += j;
		}

		// send the layout
		entry = va("client %i %i %i %i %i %i ", x, y, sorted[i], cl_ent.client.resp.score, cl_ent.client.ping, ((level.framenum - cl_ent.client.resp.enterframe) / 600));
		j = strlen(entry);
		if (stringlength + j > 1024)
			break;
		str = strconcat(str, entry);
		stringlength += j;
	}

	gi.WriteByte(svc_layout);
	gi.WriteString(str);
}


/*
==================
DeathmatchScoreboard

Draw instead of help message.
Note that it isn't that hard to overflow the MESSAGE_LIMIT!
==================
*/
static void(entity ent) DeathmatchScoreboard =
{
	DeathmatchScoreboardMessage(ent, ent.enemy);
	gi.unicast(ent, true);
}


/*
==================
Cmd_Score_f

Display the scoreboard
==================
*/
void(entity ent) Cmd_Score_f =
{
	ent.client.showinventory = false;

#ifdef PMENU
	if (ent.client.menu.open)
		PMenu_Close(ent);
#endif

#ifdef SINGLE_PLAYER
	ent.client.showhelp = false;

	if (!deathmatch.intVal && !coop.intVal)
		return;
#endif

	if (ent.client.showscores)
	{
		ent.client.showscores = false;
		return;
	}

	ent.client.showscores = true;
	DeathmatchScoreboard(ent);
}

#ifdef SINGLE_PLAYER
/*
==================
HelpComputer

Draw help computer.
==================
*/
static void(entity ent) HelpComputer =
{
	string	str;
	string	sk;

	if (skill.intVal == 0)
		sk = "easy";
	else if (skill.intVal == 1)
		sk = "medium";
	else if (skill.intVal == 2)
		sk = "hard";
	else
		sk = "hard+";

	// send the layout
	str = va(	"xv 32 yv 8 picn help "             // background
			"xv 202 yv 12 string2 \"%s\" "      // skill
			"xv 0 yv 24 cstring2 \"%s\" "       // level name
			"xv 0 yv 54 cstring2 \"%s\" "       // help 1
			"xv 0 yv 110 cstring2 \"%s\" ",     // help 2
			sk,
			level.level_name,
			game.helpmessage1,
			game.helpmessage2);
	
	str = va(	"%sxv 50 yv 164 string2 \" kills     goals    secrets\" "
			"xv 50 yv 172 string2 \"%3i/%3i     %i/%i       %i/%i\" ",
			str,
			level.killed_monsters, level.total_monsters,
			level.found_goals, level.total_goals,
			level.found_secrets, level.total_secrets);

	gi.WriteByte(svc_layout);
	gi.WriteString(str);
	gi.unicast(ent, true);
}
#endif

/*
==================
Cmd_Help_f

Display the current help message
==================
*/
void(entity ent) Cmd_Help_f =
{
#ifdef SINGLE_PLAYER
	// this is for backwards compatability
	if (deathmatch.intVal)
	{
		Cmd_Score_f(ent);
		return;
	}

	ent.client.showinventory = false;
	ent.client.showscores = false;

	if (ent.client.showhelp && (ent.client.pers.game_helpchanged == game.helpchanged)) {
		ent.client.showhelp = false;
		return;
	}

	ent.client.showhelp = true;
	ent.client.pers.helpchanged = 0;
	HelpComputer(ent);
#else
	Cmd_Score_f(ent);
#endif
}


//=======================================================================

/*
===============
G_SetStats
===============
*/
void(entity ent) G_SetStats =
{
	gitem_t	*it;

	//
	// health
	//
	ent.client.ps.stats[STAT_HEALTH_ICON] = level.pic_health;
	ent.client.ps.stats[STAT_HEALTH] = ent.health;

	//
	// ammo
	//
	if (!ent.client.ammo_index)
	{
		ent.client.ps.stats[STAT_AMMO_ICON] = 0;
		ent.client.ps.stats[STAT_AMMO] = 0;
	}
	else
	{
		it = GetItemByIndex(ent.client.ammo_index);
		ent.client.ps.stats[STAT_AMMO_ICON] = gi.imageindex(it->icon);
		ent.client.ps.stats[STAT_AMMO] = ent.client.pers.inventory[it->id];
	}

	//
	// armor
	//
	power_armor_type_t power_armor_type = PowerArmorType(ent);
	int cells = 0;
	if (power_armor_type)
	{
		cells = ent.client.pers.inventory[ITEM_CELLS];
		if (cells == 0)
		{
			// ran out of cells for power armor
			ent.flags &= ~FL_POWER_ARMOR;
			gi.sound(ent, CHAN_ITEM, gi.soundindex("misc/power2.wav"), 1, ATTN_NORM, 0);
			power_armor_type = 0;;
		}
	}

	gitem_id_t index = ArmorIndex(ent);
	if (power_armor_type && (!index || (level.framenum & 8)))
	{
		// flash between power armor and other armor icon
		// Knightmare- use correct icon for power screen
		if (power_armor_type == POWER_ARMOR_SHIELD)
			ent.client.ps.stats[STAT_ARMOR_ICON] = gi.imageindex ("i_powershield");
		else	// POWER_ARMOR_SCREEN
			ent.client.ps.stats[STAT_ARMOR_ICON] = gi.imageindex ("i_powerscreen");
		ent.client.ps.stats[STAT_ARMOR] = cells;
	}
	else if (index)
	{
		it = GetItemByIndex(index);
		ent.client.ps.stats[STAT_ARMOR_ICON] = gi.imageindex(it->icon);
		ent.client.ps.stats[STAT_ARMOR] = ent.client.pers.inventory[index];
	}
	else
	{
		ent.client.ps.stats[STAT_ARMOR_ICON] = 0;
		ent.client.ps.stats[STAT_ARMOR] = 0;
	}

	//
	// pickup message
	//
	if (level.framenum > ent.client.pickup_msg_framenum)
	{
		ent.client.ps.stats[STAT_PICKUP_ICON] = 0;
		ent.client.ps.stats[STAT_PICKUP_STRING] = 0;
	}

	//
	// timers
	//
	if (ent.client.quad_framenum > level.framenum)
	{
		ent.client.ps.stats[STAT_TIMER_ICON] = gi.imageindex("p_quad");
		ent.client.ps.stats[STAT_TIMER] = (ent.client.quad_framenum - level.framenum) / 10;
	}
#ifdef THE_RECKONING
	// RAFAEL
	else if (ent.client.quadfire_framenum > level.framenum)
	{
		ent.client.ps.stats[STAT_TIMER_ICON] = gi.imageindex ("p_quadfire");
		ent.client.ps.stats[STAT_TIMER] = (ent.client.quadfire_framenum - level.framenum)/10;
	}
#endif
#ifdef GROUND_ZERO
	else if (ent.client.double_framenum > level.framenum)
	{
		ent.client.ps.stats[STAT_TIMER_ICON] = gi.imageindex ("p_double");
		ent.client.ps.stats[STAT_TIMER] = (ent.client.double_framenum - level.framenum)/10;
	}
#endif
	else if (ent.client.invincible_framenum > level.framenum)
	{
		ent.client.ps.stats[STAT_TIMER_ICON] = gi.imageindex("p_invulnerability");
		ent.client.ps.stats[STAT_TIMER] = (ent.client.invincible_framenum - level.framenum) / 10;
	}
	else if (ent.client.enviro_framenum > level.framenum)
	{
		ent.client.ps.stats[STAT_TIMER_ICON] = gi.imageindex("p_envirosuit");
		ent.client.ps.stats[STAT_TIMER] = (ent.client.enviro_framenum - level.framenum) / 10;
	}
	else if (ent.client.breather_framenum > level.framenum)
	{
		ent.client.ps.stats[STAT_TIMER_ICON] = gi.imageindex("p_rebreather");
		ent.client.ps.stats[STAT_TIMER] = (ent.client.breather_framenum - level.framenum) / 10;
	}
#ifdef GROUND_ZERO
	else if (ent.client.ir_framenum > level.framenum)
	{
		ent.client.ps.stats[STAT_TIMER_ICON] = gi.imageindex ("p_ir");
		ent.client.ps.stats[STAT_TIMER] = (ent.client.ir_framenum - level.framenum)/10;
	}
#endif
	else
	{
		ent.client.ps.stats[STAT_TIMER_ICON] = 0;
		ent.client.ps.stats[STAT_TIMER] = 0;
	}

	//
	// selected item
	//
	if (ent.client.pers.selected_item == -1)
		ent.client.ps.stats[STAT_SELECTED_ICON] = 0;
	else
		ent.client.ps.stats[STAT_SELECTED_ICON] = gi.imageindex(GetItemByIndex(ent.client.pers.selected_item)->icon);

	ent.client.ps.stats[STAT_SELECTED_ITEM] = ent.client.pers.selected_item;

	//
	// layouts
	//
	ent.client.ps.stats[STAT_LAYOUTS] = 0;
#ifdef SINGLE_PLAYER

	if (deathmatch.intVal)
	{
#endif
		if (ent.client.pers.health <= 0 || level.intermission_framenum || ent.client.showscores)
			ent.client.ps.stats[STAT_LAYOUTS] |= 1;
		if (ent.client.showinventory && ent.client.pers.health > 0)
			ent.client.ps.stats[STAT_LAYOUTS] |= 2;
#ifdef SINGLE_PLAYER
	}
	else
	{
		if (ent.client.showscores || ent.client.showhelp)
			ent.client.ps.stats[STAT_LAYOUTS] |= 1;
		if (ent.client.showinventory && ent.client.pers.health > 0)
			ent.client.ps.stats[STAT_LAYOUTS] |= 2;
	}
#endif

	//
	// frags
	//
	ent.client.ps.stats[STAT_FRAGS] = ent.client.resp.score;

	//
	// help icon / current weapon if not shown
	//
#ifdef SINGLE_PLAYER
	if (ent.client.pers.helpchanged && (level.framenum & 8))
		ent.client.ps.stats[STAT_HELPICON] = gi.imageindex("i_help");
	else
#endif
	if ((ent.client.pers.hand == CENTER_HANDED || ent.client.ps.fov > 91) && ent.client.pers.weapon)
		ent.client.ps.stats[STAT_HELPICON] = gi.imageindex(ent.client.pers.weapon->icon);
	else
		ent.client.ps.stats[STAT_HELPICON] = 0;

	ent.client.ps.stats[STAT_SPECTATOR] = 0;

#ifdef CTF
	SetCTFStats(ent);
#endif
}

void(entity) G_SetSpectatorStats;

/*
===============
G_CheckChaseStats
===============
*/
void(entity ent) G_CheckChaseStats =
{
	for (int i = 1; i <= game.maxclients; i++)
	{
		entity cl = itoe(i);
		if (!cl.inuse || cl.client.chase_target != ent)
			continue;
		// FIXME: sizeof
		memcpy(&cl.client.ps.stats[0], &ent.client.ps.stats[0], sizeof(int) * MAX_STATS);
		G_SetSpectatorStats(cl);
	}
}

/*
===============
G_SetSpectatorStats
===============
*/
void(entity ent) G_SetSpectatorStats =
{
	if (!ent.client.chase_target)
		G_SetStats(ent);

	ent.client.ps.stats[STAT_SPECTATOR] = 1;

	// layouts are independant in spectator
	ent.client.ps.stats[STAT_LAYOUTS] = 0;
	if (ent.client.pers.health <= 0 || level.intermission_framenum || ent.client.showscores)
		ent.client.ps.stats[STAT_LAYOUTS] |= 1;
	if (ent.client.showinventory && ent.client.pers.health > 0)
		ent.client.ps.stats[STAT_LAYOUTS] |= 2;

	if (ent.client.chase_target && ent.client.chase_target.inuse)
		ent.client.ps.stats[STAT_CHASE] = CS_PLAYERSKINS + (ent.client.chase_target.s.number - 1);
	else
		ent.client.ps.stats[STAT_CHASE] = 0;
}
