#include "m_player.h"

string(entity ent) ClientTeam =
{
	if (!ent->is_client)
		return "???";

	string team = Info_ValueForKey (ent->client->pers.userinfo, "skin");
	int p = strchr(team, '/');

	if (p == -1)
		return team;

	if (dmflags.intVal & DF_MODELTEAMS)
		return substr(team, 0, p);

	return substr(team, p + 1);
}

bool(entity ent1, entity ent2) OnSameTeam =
{
	if (!(dmflags->intVal & (DF_MODELTEAMS | DF_SKINTEAMS)))
		return false;

	return ClientTeam(ent1) == ClientTeam(ent2);
}

static void(entity ent, int itflags) SelectNextItem =
{
	int		i;
	gitem_id_t	index;

	if (ent.client->chase_target) {
		ChaseNext(ent);
		return;
	}

	// scan  for the next valid one
	for (i=1 ; i<=itemlist.length ; i++)
	{
		index = (ent.client->pers.selected_item + i)%itemlist.length;
		if (!ent.client->pers.inventory[index])
			continue;
		if (!GetItemKeyByIndex(index, use))
			continue;
		if (!(GetItemKeyByIndex(index, flags) & itflags))
			continue;

		ent.client->pers.selected_item = index;
		return;
	}

	ent.client->pers.selected_item = -1;
}

static void(entity ent, int itflags) SelectPrevItem =
{
	int		i;
	gitem_id_t	index;

	if (ent.client->chase_target) {
		ChasePrev(ent);
		return;
	}

	// scan  for the next valid one
	for (i=1 ; i<=itemlist.length ; i++)
	{
		index = (ent.client->pers.selected_item + itemlist.length - i)%itemlist.length;
		if (!ent.client->pers.inventory[index])
			continue;
		if (!GetItemKeyByIndex(index, use))
			continue;
		if (!(GetItemKeyByIndex(index, flags) & itflags))
			continue;

		ent.client->pers.selected_item = index;
		return;
	}

	ent.client->pers.selected_item = -1;
}

void(entity ent) ValidateSelectedItem =
{
	if (ent.client->pers.inventory[ent.client->pers.selected_item])
		return;		// valid

	SelectNextItem (ent, -1);
}


//=================================================================================

/*
==================
Cmd_Give_f

Give items to a client
==================
*/
static void(entity ent) Cmd_Give_f =
{
	string		name;
	gitem_id_t	it;
	int		index;
	int		i;
	bool		give_all;
	entity		it_ent;

	if (deathmatch->intVal && !sv_cheats->intVal)
	{
		gi.cprintf (ent, PRINT_HIGH, "You must run the server with '+set cheats 1' to enable this command.\n");
		return;
	}

	name = gi.args();

	if (stricmp(name, "all") == 0)
		give_all = true;
	else
		give_all = false;

	if (give_all || stricmp(gi.argv(1), "health") == 0)
	{
		if (gi.argc() == 3)
			ent->health = stoi(gi.argv(2));
		else
			ent->health = ent->max_health;
		if (!give_all)
			return;
	}

	if (give_all || stricmp(name, "weapons") == 0)
	{
		for (i = 0; i < itemlist.length; i++)
		{
			it = i;
			if (!GetItemKeyByIndex(it, pickup))
				continue;
			if (!(GetItemKeyByIndex(it, flags) & IT_WEAPON))
				continue;
			ent->client->pers.inventory[i] += 1;
		}
		if (!give_all)
			return;
	}

	if (give_all || stricmp(name, "ammo") == 0)
	{
		for (i=0 ; i< itemlist.length; i++)
		{
			it = i;
			if (!GetItemKeyByIndex(it, pickup))
				continue;
			if (!(GetItemKeyByIndex(it, flags) & IT_AMMO))
				continue;
			Add_Ammo (ent, it, 1000);
		}
		if (!give_all)
			return;
	}

	if (give_all || stricmp(name, "armor") == 0)
	{
		gitem_armor_id_t	info;

		it = FindItem("Jacket Armor");
		ent->client->pers.inventory[ITEM_INDEX(it)] = 0;

		it = FindItem("Combat Armor");
		ent->client->pers.inventory[ITEM_INDEX(it)] = 0;

		it = FindItem("Body Armor");
		info = GetItemKeyByIndex(it, info);
		ent->client->pers.inventory[ITEM_INDEX(it)] = GetArmorInfoKeyByIndex(info, max_count);

		if (!give_all)
			return;
	}

	if (give_all || stricmp(name, "Power Shield") == 0)
	{
		it = FindItem("Power Shield");
		it_ent = G_Spawn();
		it_ent->classname = GetItemKeyByIndex(it, classname);
		SpawnItem (it_ent, it);
		Touch_Item (it_ent, ent, null_plane, null_surface);
		if (it_ent->inuse)
			G_FreeEdict(it_ent);

		if (!give_all)
			return;
	}

	if (give_all)
	{
		for (i=0 ; i<itemlist.length ; i++)
		{
			it = i;
			if (!GetItemKeyByIndex(it, pickup))
				continue;
			if (GetItemKeyByIndex(it, flags) & (IT_ARMOR|IT_WEAPON|IT_AMMO))
				continue;
			ent->client->pers.inventory[i] = 1;
		}
		return;
	}

	it = FindItem (name);
	if (!it)
	{
		name = gi.argv(1);
		it = FindItem (name);
		if (!it)
		{
			gi.cprintf (ent, PRINT_HIGH, "unknown item\n");
			return;
		}
	}

	if (!GetItemKeyByIndex(it, pickup))
	{
		gi.cprintf (ent, PRINT_HIGH, "non-pickup item\n");
		return;
	}

	index = ITEM_INDEX(it);

	if (GetItemKeyByIndex(it, flags) & IT_AMMO)
	{
		if (gi.argc() == 3)
			ent->client->pers.inventory[index] = stoi(gi.argv(2));
		else
			ent->client->pers.inventory[index] += GetItemKeyByIndex(it, quantity);
	}
	else
	{
		it_ent = G_Spawn();
		it_ent->classname = GetItemKeyByIndex(it, classname);
		SpawnItem (it_ent, it);
		Touch_Item (it_ent, ent, null_plane, null_surface);
		if (it_ent->inuse)
			G_FreeEdict(it_ent);
	}
}


/*
==================
Cmd_God_f

Sets client to godmode

argv(0) god
==================
*/
static void(entity ent) Cmd_God_f =
{
	string	msg;

	if (deathmatch->intVal && !sv_cheats->intVal)
	{
		gi.cprintf (ent, PRINT_HIGH, "You must run the server with '+set cheats 1' to enable this command.\n");
		return;
	}

	ent->flags ^= FL_GODMODE;
	if (!(ent->flags & FL_GODMODE) )
		msg = "godmode OFF\n";
	else
		msg = "godmode ON\n";

	gi.cprintf (ent, PRINT_HIGH, msg);
}


/*
==================
Cmd_Notarget_f

Sets client to notarget

argv(0) notarget
==================
*/
static void(entity ent) Cmd_Notarget_f =
{
	string	msg;

	if (deathmatch->intVal && !sv_cheats->intVal)
	{
		gi.cprintf (ent, PRINT_HIGH, "You must run the server with '+set cheats 1' to enable this command.\n");
		return;
	}

	ent->flags ^= FL_NOTARGET;
	if (!(ent->flags & FL_NOTARGET) )
		msg = "notarget OFF\n";
	else
		msg = "notarget ON\n";

	gi.cprintf (ent, PRINT_HIGH, msg);
}


/*
==================
Cmd_Noclip_f

argv(0) noclip
==================
*/
static void(entity ent) Cmd_Noclip_f =
{
	string	msg;

	if (deathmatch->intVal && !sv_cheats->intVal)
	{
		gi.cprintf (ent, PRINT_HIGH, "You must run the server with '+set cheats 1' to enable this command.\n");
		return;
	}

	if (ent->movetype == MOVETYPE_NOCLIP)
	{
		ent->movetype = MOVETYPE_WALK;
		msg = "noclip OFF\n";
	}
	else
	{
		ent->movetype = MOVETYPE_NOCLIP;
		msg = "noclip ON\n";
	}

	gi.cprintf (ent, PRINT_HIGH, msg);
}


/*
==================
Cmd_Use_f

Use an inventory item
==================
*/
static void(entity ent) Cmd_Use_f =
{
	int		index;
	gitem_id_t	it;
	string		s;

	s = gi.args();
	it = FindItem (s);
	if (!it)
	{
		gi.cprintf (ent, PRINT_HIGH, "unknown item: %s\n", s);
		return;
	}
	if (!GetItemKeyByIndex(it, use))
	{
		gi.cprintf (ent, PRINT_HIGH, "Item is not usable.\n");
		return;
	}
	index = ITEM_INDEX(it);
	if (!ent->client->pers.inventory[index])
	{
		gi.cprintf (ent, PRINT_HIGH, "Out of item: %s\n", s);
		return;
	}

	GetItemKeyByIndex(it, use) (ent, it);
}


/*
==================
Cmd_Drop_f

Drop an inventory item
==================
*/
static void(entity ent) Cmd_Drop_f =
{
	int		index;
	gitem_id_t	it;
	string		s;

	s = gi.args();
	it = FindItem (s);
	if (!it)
	{
		gi.cprintf (ent, PRINT_HIGH, "unknown item: %s\n", s);
		return;
	}
	if (!GetItemKeyByIndex(it, drop))
	{
		gi.cprintf (ent, PRINT_HIGH, "Item is not dropable.\n");
		return;
	}
	index = ITEM_INDEX(it);
	if (!ent->client->pers.inventory[index])
	{
		gi.cprintf (ent, PRINT_HIGH, "Out of item: %s\n", s);
		return;
	}

	GetItemKeyByIndex(it, drop) (ent, it);
}


/*
=================
Cmd_Inven_f
=================
*/
static void(entity ent) Cmd_Inven_f =
{
	int		i;

	ent.client->showscores = false;
	ent.client->showhelp = false;

	if (ent.client->showinventory)
	{
		ent.client->showinventory = false;
		return;
	}

	ent.client->showinventory = true;

	gi.WriteByte (svc_inventory);
	for (i=0 ; i<MAX_ITEMS ; i++)
	{
		if (i < itemlist.length)
			gi.WriteShort (ent.client->pers.inventory[i]);
		else
			gi.WriteShort(0);
	}
	gi.unicast (ent, true);
}

/*
=================
Cmd_InvUse_f
=================
*/
static void(entity ent) Cmd_InvUse_f =
{
	gitem_id_t	it;

	ValidateSelectedItem (ent);

	if (ent->client->pers.selected_item == -1)
	{
		gi.cprintf (ent, PRINT_HIGH, "No item to use.\n");
		return;
	}

	it = ent->client->pers.selected_item;
	if (!GetItemKeyByIndex(it, use))
	{
		gi.cprintf (ent, PRINT_HIGH, "Item is not usable.\n");
		return;
	}
	GetItemKeyByIndex(it, use) (ent, it);
}

/*
=================
Cmd_WeapPrev_f
=================
*/
static void(entity ent) Cmd_WeapPrev_f =
{
	int		i, index;
	gitem_id_t	it;
	int		selected_weapon;

	if (!ent.client->pers.weapon)
		return;

	selected_weapon = ITEM_INDEX(ent.client->pers.weapon);

	// scan  for the next valid one
	for (i=1 ; i<=itemlist.length ; i++)
	{
		index = (selected_weapon + i)%itemlist.length;
		if (!ent.client->pers.inventory[index])
			continue;
		it = index;
		if (!GetItemKeyByIndex(it, use))
			continue;
		if (!(GetItemKeyByIndex(it, flags) & IT_WEAPON))
			continue;
		GetItemKeyByIndex(it, use) (ent, it);
		if (ent.client->pers.weapon == it)
			return;	// successful
	}
}

/*
=================
Cmd_WeapNext_f
=================
*/
static void(entity ent) Cmd_WeapNext_f =
{
	int		i, index;
	gitem_id_t	it;
	int		selected_weapon;

	if (!ent.client->pers.weapon)
		return;

	selected_weapon = ITEM_INDEX(ent.client->pers.weapon);

	// scan  for the next valid one
	for (i=1 ; i<=itemlist.length ; i++)
	{
		index = (selected_weapon + itemlist.length - i)%itemlist.length;
		if (!ent.client->pers.inventory[index])
			continue;
		it = index;
		if (!GetItemKeyByIndex(it, use))
			continue;
		if (!(GetItemKeyByIndex(it, flags) & IT_WEAPON))
			continue;
		GetItemKeyByIndex(it, use) (ent, it);
		if (ent.client->pers.weapon == it)
			return;	// successful
	}
}

/*
=================
Cmd_WeapLast_f
=================
*/
static void(entity ent) Cmd_WeapLast_f =
{
	int		index;
	gitem_id_t	it;

	if (!ent.client->pers.weapon || !ent.client->pers.lastweapon)
		return;

	index = ITEM_INDEX(ent.client->pers.lastweapon);
	if (!ent.client->pers.inventory[index])
		return;
	it = index;
	if (!GetItemKeyByIndex(it, use))
		return;
	if (!(GetItemKeyByIndex(it, flags) & IT_WEAPON))
		return;
	GetItemKeyByIndex(it, use) (ent, it);
}

/*
=================
Cmd_InvDrop_f
=================
*/
static void(entity ent) Cmd_InvDrop_f =
{
	gitem_id_t	it;

	ValidateSelectedItem (ent);

	if (ent->client->pers.selected_item == -1)
	{
		gi.cprintf (ent, PRINT_HIGH, "No item to drop.\n");
		return;
	}

	it = ent->client->pers.selected_item;
	if (!GetItemKeyByIndex(it, drop))
	{
		gi.cprintf (ent, PRINT_HIGH, "Item is not dropable.\n");
		return;
	}
	GetItemKeyByIndex(it, drop) (ent, it);
}

/*
=================
Cmd_Kill_f
=================
*/
static void(entity ent) Cmd_Kill_f =
{
	if ((level.framenum - ent->client->respawn_framenum) < 5 * BASE_FRAMERATE)
		return;
	ent->flags &= ~FL_GODMODE;
	ent->health = 0;
	meansOfDeath = MOD_SUICIDE;
	player_die (ent, ent, ent, 100000, vec3_origin);
}

/*
=================
Cmd_PutAway_f
=================
*/
static void(entity ent) Cmd_PutAway_f =
{
	ent->client->showscores = false;
	ent->client->showhelp = false;
	ent->client->showinventory = false;
}

// TODO
/*
int PlayerSort (void const *a, void const *b)
{
	int		anum, bnum;

	anum = *(int *)a;
	bnum = *(int *)b;

	anum = game.clients[anum].ps.stats[STAT_FRAGS];
	bnum = game.clients[bnum].ps.stats[STAT_FRAGS];

	if (anum < bnum)
		return -1;
	if (anum > bnum)
		return 1;
	return 0;
}*/

/*
=================
Cmd_Players_f
=================
*/
static void (entity ent) Cmd_Players_f =
{
	// TODO
/*	int		i;
	int		count;
	char	small[64];
	char	large[1280];
	int		index[256];

	count = 0;
	for (i = 0 ; i < maxclients->value ; i++)
		if (game.clients[i].pers.connected)
		{
			index[count] = i;
			count++;
		}

	// sort by frags
	qsort (index, count, sizeof(index[0]), PlayerSort);

	// print information
	large[0] = 0;

	for (i = 0 ; i < count ; i++)
	{
		Com_sprintf (small, sizeof(small), "%3i %s\n",
			game.clients[index[i]].ps.stats[STAT_FRAGS],
			game.clients[index[i]].pers.netname);
		if (strlen (small) + strlen(large) > sizeof(large) - 100 )
		{	// can't print all of them in one packet
			strcat (large, "...\n");
			break;
		}
		strcat (large, small);
	}

	gi.cprintf (ent, PRINT_HIGH, "%s\n%i players\n", large, count);*/
}

/*
=================
Cmd_Wave_f
=================
*/
static void(entity ent) Cmd_Wave_f =
{
	int		i;

	i = stoi (gi.argv(1));

	// can't wave when ducked
	if (ent->client->ps.pmove.pm_flags & PMF_DUCKED)
		return;

	if (ent->client->anim_priority > ANIM_WAVE)
		return;

	ent->client->anim_priority = ANIM_WAVE;

	switch (i)
	{
	case 0:
		gi.cprintf (ent, PRINT_HIGH, "flipoff\n");
		ent->s.frame = FRAME_flip01-1;
		ent->client->anim_end = FRAME_flip12;
		break;
	case 1:
		gi.cprintf (ent, PRINT_HIGH, "salute\n");
		ent->s.frame = FRAME_salute01-1;
		ent->client->anim_end = FRAME_salute11;
		break;
	case 2:
		gi.cprintf (ent, PRINT_HIGH, "taunt\n");
		ent->s.frame = FRAME_taunt01-1;
		ent->client->anim_end = FRAME_taunt17;
		break;
	case 3:
		gi.cprintf (ent, PRINT_HIGH, "wave\n");
		ent->s.frame = FRAME_wave01-1;
		ent->client->anim_end = FRAME_wave11;
		break;
	case 4:
	default:
		gi.cprintf (ent, PRINT_HIGH, "point\n");
		ent->s.frame = FRAME_point01-1;
		ent->client->anim_end = FRAME_point12;
		break;
	}
}

/*
==================
Cmd_Say_f
==================
*/
static void(entity ent, bool team, bool arg0) Cmd_Say_f =
{
	int	i, j;
	entity	other;
	string	p;
	string	text;

	if (gi.argc () < 2 && !arg0)
		return;

	if (!(dmflags->intVal & (DF_MODELTEAMS | DF_SKINTEAMS)))
		team = false;

	if (team)
		text = va("(%s): ", ent->client->pers.netname);
	else
		text = va("%s: ", ent->client->pers.netname);

	if (arg0)
		text = va("%s%s %s", text, gi.argv(0), gi.args());
	else
	{
		p = gi.args();

		if (strat(p, 0) == '"')
			p = substr(p, 1, strlen(p) - 2);

		text = va("%s%s", text, p);
	}

	// don't let text be too long for malicious reasons
	if (strlen(text) > 150)
		text = va("%.150s", text);

	text = va("%s\n", text);

	if (flood_msgs->intVal)
	{
		if (level.time < ent.client->flood_locktill)
		{
			gi.cprintf(ent, PRINT_HIGH, "You can't talk for %d more seconds\n", (int)(ent.client->flood_locktill - level.time));
			return;
		}
		i = ent.client->flood_whenhead - flood_msgs->intVal + 1;
		if (i < 0)
			i = client.flood_when.length + i;
            
		if (ent.client->flood_when[i] && level.time - ent.client->flood_when[i] < flood_persecond->intVal)
		{
			ent.client->flood_locktill = level.time + flood_waitdelay->intVal;
			gi.cprintf(ent, PRINT_CHAT, "Flood protection:  You can't talk for %d seconds.\n", (int)flood_waitdelay->intVal);
			return;
		}

		ent.client->flood_whenhead = (ent.client->flood_whenhead + 1) % client.flood_when.length;
		ent.client->flood_when[ent.client->flood_whenhead] = level.time;
	}

	if (dedicated->intVal)
		gi.cprintf(world, PRINT_CHAT, "%s", text);

	for (j = 1; j <= game.maxclients; j++)
	{
		other = itoe(j);
		if (!other->inuse)
			continue;
		if (!other->is_client)
			continue;
		if (team)
		{
			if (!OnSameTeam(ent, other))
				continue;
		}
		gi.cprintf(other, PRINT_CHAT, "%s", text);
	}
}

static void(entity ent) Cmd_PlayerList_f =
{
	// TODO
	/*int i;
	char st[80];
	char text[1400];
	edict_t *e2;

	// connect time, ping, score, name
	*text = 0;
	for (i = 0, e2 = g_edicts + 1; i < maxclients->value; i++, e2++) {
		if (!e2->inuse)
			continue;

		sprintf(st, "%02d:%02d %4d %3d %s%s\n",
			(level.framenum - e2->client->resp.enterframe) / 600,
			((level.framenum - e2->client->resp.enterframe) % 600)/10,
			e2->client->ping,
			e2->client->resp.score,
			e2->client->pers.netname,
			e2->client->resp.spectator ? " (spectator)" : "");
		if (strlen(text) + strlen(st) > sizeof(text) - 50) {
			sprintf(text+strlen(text), "And more...\n");
			gi.cprintf(ent, PRINT_HIGH, "%s", text);
			return;
		}
		strcat(text, st);
	}
	gi.cprintf(ent, PRINT_HIGH, "%s", text);*/
}

// from hud.qc
void(entity ent) Cmd_Score_f;

// spawn.qc
bool(entity ent) ED_CallSpawn;

static void(entity ent) Cmd_Spawn_f =
{
	entity e = G_Spawn();
	e.classname = gi.argv(1);
	
	vector forward;
	AngleVectors(ent.client.v_angle, forward, unref_vec, unref_vec);
	
	e.s.origin = ent.s.origin + (forward * 128);
	
	e.s.angles[YAW] = ent.s.angles[YAW];
	
	ED_CallSpawn(e);
	
	gi.linkentity(e);
};

/*
=================
ClientCommand
=================
*/
void(entity ent) ClientCommand =
{
	string	cmd;

	if (!ent->is_client)
		return;		// not fully in game yet

	cmd = gi.argv(0);

	if (stricmp (cmd, "players") == 0)
	{
		Cmd_Players_f (ent);
		return;
	}
	if (stricmp (cmd, "say") == 0)
	{
		Cmd_Say_f (ent, false, false);
		return;
	}
	if (stricmp (cmd, "say_team") == 0)
	{
		Cmd_Say_f (ent, true, false);
		return;
	}
	if (stricmp (cmd, "score") == 0)
	{
		Cmd_Score_f (ent);
		return;
	}
	if (stricmp (cmd, "help") == 0)
	{
		Cmd_Help_f (ent);
		return;
	}

	if (level.intermission_framenum)
		return;

	if (stricmp (cmd, "spawn") == 0)
		Cmd_Spawn_f (ent);
	else if (stricmp (cmd, "use") == 0)
		Cmd_Use_f (ent);
	else if (stricmp (cmd, "drop") == 0)
		Cmd_Drop_f (ent);
	else if (stricmp (cmd, "give") == 0)
		Cmd_Give_f (ent);
	else if (stricmp (cmd, "god") == 0)
		Cmd_God_f (ent);
	else if (stricmp (cmd, "notarget") == 0)
		Cmd_Notarget_f (ent);
	else if (stricmp (cmd, "noclip") == 0)
		Cmd_Noclip_f (ent);
	else if (stricmp (cmd, "inven") == 0)
		Cmd_Inven_f (ent);
	else if (stricmp (cmd, "invnext") == 0)
		SelectNextItem (ent, -1);
	else if (stricmp (cmd, "invprev") == 0)
		SelectPrevItem (ent, -1);
	else if (stricmp (cmd, "invnextw") == 0)
		SelectNextItem (ent, IT_WEAPON);
	else if (stricmp (cmd, "invprevw") == 0)
		SelectPrevItem (ent, IT_WEAPON);
	else if (stricmp (cmd, "invnextp") == 0)
		SelectNextItem (ent, IT_POWERUP);
	else if (stricmp (cmd, "invprevp") == 0)
		SelectPrevItem (ent, IT_POWERUP);
	else if (stricmp (cmd, "invuse") == 0)
		Cmd_InvUse_f (ent);
	else if (stricmp (cmd, "invdrop") == 0)
		Cmd_InvDrop_f (ent);
	else if (stricmp (cmd, "weapprev") == 0)
		Cmd_WeapPrev_f (ent);
	else if (stricmp (cmd, "weapnext") == 0)
		Cmd_WeapNext_f (ent);
	else if (stricmp (cmd, "weaplast") == 0)
		Cmd_WeapLast_f (ent);
	else if (stricmp (cmd, "kill") == 0)
		Cmd_Kill_f (ent);
	else if (stricmp (cmd, "putaway") == 0)
		Cmd_PutAway_f (ent);
	else if (stricmp (cmd, "wave") == 0)
		Cmd_Wave_f (ent);
	else if (stricmp(cmd, "playerlist") == 0)
		Cmd_PlayerList_f(ent);
	else	// anything that doesn't match a command will be a chat
		Cmd_Say_f (ent, false, true);
}
