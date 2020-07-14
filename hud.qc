/*
======================================================================

INTERMISSION

======================================================================
*/

// from hud.qc
void(entity ent, entity killer) DeathmatchScoreboardMessage;

void(entity ent) MoveClientToIntermission =
{
	if (deathmatch->intVal || coop->intVal)
		ent->client->showscores = true;
	VectorCopy(level.intermission_origin, ent->s.origin);
	ent->client->ps.pmove.origin[(ARRAY_INDEX_TYPE)0] = COORD2SHORT(level.intermission_origin[(ARRAY_INDEX_TYPE)0]);
	ent->client->ps.pmove.origin[(ARRAY_INDEX_TYPE)1] = COORD2SHORT(level.intermission_origin[(ARRAY_INDEX_TYPE)1]);
	ent->client->ps.pmove.origin[(ARRAY_INDEX_TYPE)2] = COORD2SHORT(level.intermission_origin[(ARRAY_INDEX_TYPE)2]);
	VectorCopy(level.intermission_angle, ent->client->ps.viewangles);
	ent->client->ps.pmove.pm_type = PM_FREEZE;
	ent->client->ps.gunindex = 0;
	ent->client->ps.blend[(ARRAY_INDEX_TYPE)3] = 0;
	ent->client->ps.rdflags &= ~RDF_UNDERWATER;

	// clean up powerup info
	ent->client->quad_framenum = 0;
	ent->client->invincible_framenum = 0;
	ent->client->breather_framenum = 0;
	ent->client->enviro_framenum = 0;
	ent->client->grenade_blew_up = false;
	ent->client->grenade_framenum = 0;

	ent->viewheight = 0;
	ent->s.modelindex = 0;
	ent->s.modelindex2 = 0;
	ent->s.modelindex3 = 0;
	ent->s.modelindex = 0;
	ent->s.effects = 0;
	ent->s.sound = 0;
	ent->solid = SOLID_NOT;

	// add the layout

	if (deathmatch->intVal || coop->intVal) {
		DeathmatchScoreboardMessage(ent, world);
		gi.unicast(ent, true);
	}

}

void(entity targ) BeginIntermission =
{
	int	i, n;
	entity	ent, cl;

	if (level.intermission_framenum)
		return;     // already activated

	game.autosaved = false;

	// respawn any dead clients
	for (i = 0 ; i < game.maxclients ; i++) {
		cl = itoe(1 + i);
		if (!cl->inuse)
			continue;
		if (cl->health <= 0)
			respawn(cl);
	}

	level.intermission_framenum = level.framenum;
	level.changemap = targ->map;

	if (strstr(level.changemap, "*") != -1) {
		if (coop->intVal) {
			for (i = 0 ; i < game.maxclients ; i++) {
				cl = itoe(1 + i);
				if (!cl->inuse)
					continue;
				// strip players of all keys between units
				//TODO
				/*for (n = 0; n < MAX_ITEMS; n++) {
					if (itemlist[n].flags & IT_KEY)
						client->client->pers.inventory[n] = 0;
				}*/
			}
		}
	} else {
		if (!deathmatch->intVal) {
			level.exitintermission = 1;     // go immediately to the next level
			return;
		}
	}

	level.exitintermission = 0;

	// find an intermission spot
	ent = G_Find(null_entity, classname, "info_player_intermission");
	if (ent == null_entity) {
		// the map creator forgot to put in an intermission point...
		ent = G_Find(null_entity, classname, "info_player_start");
		if (ent == null_entity)
			ent = G_Find(null_entity, classname, "info_player_deathmatch");
	} else {
		// chose one of four spots
		i = Q_rand() & 3;
		while (i--) {
			ent = G_Find(ent, classname, "info_player_intermission");
			if (ent == null_entity)   // wrap around the list
				ent = G_Find(ent, classname, "info_player_intermission");
		}
	}

	VectorCopy(ent->s.origin, level.intermission_origin);
	VectorCopy(ent->s.angles, level.intermission_angle);

	// move all clients to the intermission point
	for (i = 0 ; i < game.maxclients ; i++) {
		cl = itoe(1 + i);
		if (!cl->inuse)
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
	string	entry;
	string	str;
	int	stringlength;
	int	i, j, k;
	int	sorted[MAX_CLIENTS];
	int	sortedscores[MAX_CLIENTS];
	int	score, total;
	int	x, y;
	entity	cl_ent;
	string	tag;

	// sort the clients by score
	total = 0;
	for (i = 0 ; i < game.maxclients ; i++) {
		cl_ent = itoe(1 + i);
		if (!cl_ent->inuse || cl_ent.client.resp.spectator)
			continue;
		score = cl_ent.client.resp.score;
		for (j = 0 ; j < total ; j++) {
			if (score > sortedscores[(ARRAY_INDEX_TYPE)j])
				break;
		}
		for (k = total ; k > j ; k--) {
			sorted[(ARRAY_INDEX_TYPE)k] = sorted[(ARRAY_INDEX_TYPE)(k - 1)];
			sortedscores[(ARRAY_INDEX_TYPE)k] = sortedscores[(ARRAY_INDEX_TYPE)(k - 1)];
		}
		sorted[(ARRAY_INDEX_TYPE)j] = i;
		sortedscores[(ARRAY_INDEX_TYPE)j] = score;
		total++;
	}

	// print level name and exit rules
	stringlength = 0;

	// add the clients in sorted order
	if (total > 12)
		total = 12;

	for (i = 0 ; i < total ; i++) {
		cl_ent = itoe(1 + sorted[(ARRAY_INDEX_TYPE)i]);

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
		entry = va("client %i %i %i %i %i %i ", x, y, sorted[(ARRAY_INDEX_TYPE)i], cl_ent.client->resp.score, cl_ent.client->ping, ((level.framenum - cl_ent.client->resp.enterframe) / 600));
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
Note that it isn't that hard to overflow the 1400 byte message limit!
==================
*/
static void(entity ent) DeathmatchScoreboard =
{
	DeathmatchScoreboardMessage(ent, ent->enemy);
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
	ent->client->showinventory = false;
	ent->client->showhelp = false;

	if (!deathmatch->intVal && !coop->intVal)
		return;

	if (ent->client->showscores) {
		ent->client->showscores = false;
		return;
	}

	ent->client->showscores = true;
	DeathmatchScoreboard(ent);
}


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

	if (skill->intVal == 0)
		sk = "easy";
	else if (skill->intVal == 1)
		sk = "medium";
	else if (skill->intVal == 2)
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
	
	str = va(	"xv 50 yv 164 string2 \" kills     goals    secrets\" "
			"xv 50 yv 172 string2 \"%3i/%3i     %i/%i       %i/%i\" ",
			str,
			level.killed_monsters, level.total_monsters,
			level.found_goals, level.total_goals,
			level.found_secrets, level.total_secrets);

	gi.WriteByte(svc_layout);
	gi.WriteString(str);
	gi.unicast(ent, true);
}


/*
==================
Cmd_Help_f

Display the current help message
==================
*/
void(entity ent) Cmd_Help_f =
{
	// this is for backwards compatability
	if (deathmatch->intVal) {
		Cmd_Score_f(ent);
		return;
	}

	ent->client->showinventory = false;
	ent->client->showscores = false;

	if (ent->client->showhelp && (ent->client->pers.game_helpchanged == game.helpchanged)) {
		ent->client->showhelp = false;
		return;
	}

	ent->client->showhelp = true;
	ent->client->pers.helpchanged = 0;
	HelpComputer(ent);
}


//=======================================================================

/*
===============
G_SetStats
===============
*/
void(entity ent) G_SetStats =
{
	gitem_id_t	it;
	int	index, cells;
	int	power_armor_type;

	//
	// health
	//
	ent->client->ps.stats[(ARRAY_INDEX_TYPE)STAT_HEALTH_ICON] = level.pic_health;
	ent->client->ps.stats[STAT_HEALTH] = ent->health;

	//
	// ammo
	//
	if (!ent->client->ammo_index /* || !ent->client->pers.inventory[ent->client->ammo_index] */) {
		ent->client->ps.stats[STAT_AMMO_ICON] = 0;
		ent->client->ps.stats[STAT_AMMO] = 0;
	} else {
		//TODO
		//item = &itemlist[ent->client->ammo_index];
		/*ent->client->ps.stats[STAT_AMMO_ICON] = gi.imageindex(item->icon);
		ent->client->ps.stats[STAT_AMMO] = ent->client->pers.inventory[ent->client->ammo_index];*/
	}

	//TODO
	//
	// armor
	//
	/*power_armor_type = PowerArmorType(ent);
	if (power_armor_type) {
		cells = ent->client->pers.inventory[ITEM_INDEX(FindItem("cells"))];
		if (cells == 0) {
			// ran out of cells for power armor
			ent->flags &= ~FL_POWER_ARMOR;
			gi.sound(ent, CHAN_ITEM, gi.soundindex("misc/power2.wav"), 1, ATTN_NORM, 0);
			power_armor_type = 0;;
		}
	}*/

	index = ArmorIndex(ent);
	if (power_armor_type && (!index || (level.framenum & 8))) {
		// flash between power armor and other armor icon
		ent->client->ps.stats[STAT_ARMOR_ICON] = gi.imageindex("i_powershield");
		ent->client->ps.stats[STAT_ARMOR] = cells;
	} else if (index) {
		it = GetItemByIndex(index);
		ent->client->ps.stats[STAT_ARMOR_ICON] = gi.imageindex(GetItemKeyByIndex(it, icon));
		// TODO
		//ent->client->ps.stats[STAT_ARMOR] = ent->client->pers.inventory[index];
	} else {
		ent->client->ps.stats[STAT_ARMOR_ICON] = 0;
		ent->client->ps.stats[STAT_ARMOR] = 0;
	}

	//
	// pickup message
	//
	if (level.framenum > ent->client->pickup_msg_framenum) {
		ent->client->ps.stats[STAT_PICKUP_ICON] = 0;
		ent->client->ps.stats[STAT_PICKUP_STRING] = 0;
	}

	//
	// timers
	//
	if (ent->client->quad_framenum > level.framenum) {
		ent->client->ps.stats[STAT_TIMER_ICON] = gi.imageindex("p_quad");
		ent->client->ps.stats[STAT_TIMER] = (ent->client->quad_framenum - level.framenum) / 10;
	} else if (ent->client->invincible_framenum > level.framenum) {
		ent->client->ps.stats[STAT_TIMER_ICON] = gi.imageindex("p_invulnerability");
		ent->client->ps.stats[STAT_TIMER] = (ent->client->invincible_framenum - level.framenum) / 10;
	} else if (ent->client->enviro_framenum > level.framenum) {
		ent->client->ps.stats[STAT_TIMER_ICON] = gi.imageindex("p_envirosuit");
		ent->client->ps.stats[STAT_TIMER] = (ent->client->enviro_framenum - level.framenum) / 10;
	} else if (ent->client->breather_framenum > level.framenum) {
		ent->client->ps.stats[STAT_TIMER_ICON] = gi.imageindex("p_rebreather");
		ent->client->ps.stats[STAT_TIMER] = (ent->client->breather_framenum - level.framenum) / 10;
	} else {
		ent->client->ps.stats[STAT_TIMER_ICON] = 0;
		ent->client->ps.stats[STAT_TIMER] = 0;
	}

	//
	// selected item
	//
	if (ent->client->pers.selected_item == -1)
		ent->client->ps.stats[STAT_SELECTED_ICON] = 0;
	else
		ent->client->ps.stats[STAT_SELECTED_ICON] = gi.imageindex(GetItemKeyByIndex(ent->client->pers.selected_item, icon));

	ent->client->ps.stats[STAT_SELECTED_ITEM] = ent->client->pers.selected_item;

	//
	// layouts
	//
	ent->client->ps.stats[STAT_LAYOUTS] = 0;

	if (deathmatch->intVal) {
		if (ent->client->pers.health <= 0 || level.intermission_framenum
			|| ent->client->showscores)
			ent->client->ps.stats[STAT_LAYOUTS] |= 1;
		if (ent->client->showinventory && ent->client->pers.health > 0)
			ent->client->ps.stats[STAT_LAYOUTS] |= 2;
	} else {
		if (ent->client->showscores || ent->client->showhelp)
			ent->client->ps.stats[STAT_LAYOUTS] |= 1;
		if (ent->client->showinventory && ent->client->pers.health > 0)
			ent->client->ps.stats[STAT_LAYOUTS] |= 2;
	}

	//
	// frags
	//
	ent->client->ps.stats[STAT_FRAGS] = ent->client->resp.score;

	//
	// help icon / current weapon if not shown
	//
	if (ent->client->pers.helpchanged && (level.framenum & 8))
		ent->client->ps.stats[STAT_HELPICON] = gi.imageindex("i_help");
	else if ((ent->client->pers.hand == CENTER_HANDED || ent->client->ps.fov > 91)
			 && ent->client->pers.weapon)
		ent->client->ps.stats[STAT_HELPICON] = gi.imageindex(GetItemKeyByIndex(ent->client->pers.weapon, icon));
	else
		ent->client->ps.stats[STAT_HELPICON] = 0;

	ent->client->ps.stats[STAT_SPECTATOR] = 0;
}

void(entity) G_SetSpectatorStats;

/*
===============
G_CheckChaseStats
===============
*/
void(entity ent) G_CheckChaseStats =
{
	int i;

	for (i = 1; i <= game.maxclients; i++) {
		entity cl = itoe(i);
		if (!cl.inuse || cl.client.chase_target != ent)
			continue;
		// FIXME: sizeof
		memcpy(&cl.client->ps.stats[(ARRAY_INDEX_TYPE)0], &ent->client->ps.stats[(ARRAY_INDEX_TYPE)0], sizeof(int) * MAX_STATS);
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
	if (!ent.client->chase_target)
		G_SetStats(ent);

	ent.client->ps.stats[STAT_SPECTATOR] = 1;

	// layouts are independant in spectator
	ent.client->ps.stats[STAT_LAYOUTS] = 0;
	if (ent.client->pers.health <= 0 || level.intermission_framenum || ent.client->showscores)
		ent.client->ps.stats[STAT_LAYOUTS] |= 1;
	if (ent.client->showinventory && ent.client->pers.health > 0)
		ent.client->ps.stats[STAT_LAYOUTS] |= 2;

	if (ent.client->chase_target && ent.client->chase_target->inuse)
		ent.client->ps.stats[STAT_CHASE] = CS_PLAYERSKINS + (ent.client->chase_target.s.number - 1);
	else
		ent.client->ps.stats[STAT_CHASE] = 0;
}
