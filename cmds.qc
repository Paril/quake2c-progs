#include "m_player.h"

string(entity ent) ClientTeam =
{
	if (!ent.is_client)
		return "???";

	string team = Info_ValueForKey (ent.client.pers.userinfo, "skin");
	int p = strchr(team, '/');

	if (p == -1)
		return team;

	if (dmflags.intVal & DF_MODELTEAMS)
		return substr(team, 0, p);

	return substr(team, p + 1);
}

bool(entity ent1, entity ent2) OnSameTeam =
{
	if (ent1 == ent2)
		return false;
	// player-only teams
	else if (ent1.is_client && ent2.is_client)
	{
#ifdef SINGLE_PLAYER
		// coop players always teamed
		if (coop.intVal)
			return true;
		else
#endif
#ifdef CTF
		if (ctf.intVal && ent1.client.resp.ctf_team == ent2.client.resp.ctf_team)
			return true;
		else
#endif
		if (dmflags.intVal & (DF_MODELTEAMS | DF_SKINTEAMS))
			return ClientTeam(ent1) == ClientTeam(ent2);
	}

	return false;
}

static void(entity ent, int itflags) SelectNextItem =
{
#ifdef PMENU
	if (ent.client.menu.open)
	{
		PMenu_Next(ent);
		return;
	}
#endif

	if (ent.client.chase_target)
	{
		ChaseNext(ent);
		return;
	}

	// scan for the next valid one
	for (int i = 1; i <= itemlist.length; i++)
	{
		gitem_id_t index = (ent.client.pers.selected_item + i) % itemlist.length;

		if (!ent.client.pers.inventory[index])
			continue;

		gitem_t *it = GetItemByIndex(index);

		if (!it->use)
			continue;
		if (!(it->flags & itflags))
			continue;

		ent.client.pers.selected_item = index;
		return;
	}

	ent.client.pers.selected_item = -1;
}

static void(entity ent, int itflags) SelectPrevItem =
{
#ifdef PMENU
	if (ent.client.menu.open)
	{
		PMenu_Prev(ent);
		return;
	}
#endif

	if (ent.client.chase_target)
	{
		ChasePrev(ent);
		return;
	}

	// scan for the next valid one
	for (int i = 1; i <= itemlist.length; i++)
	{
		gitem_id_t index = (ent.client.pers.selected_item + itemlist.length - i) % itemlist.length;

		if (!ent.client.pers.inventory[index])
			continue;

		gitem_t *it = GetItemByIndex(index);

		if (!it->use)
			continue;
		if (!(it->flags & itflags))
			continue;

		ent.client.pers.selected_item = index;
		return;
	}

	ent.client.pers.selected_item = -1;
}

void(entity ent) ValidateSelectedItem =
{
	if !(ent.client.pers.inventory[ent.client.pers.selected_item])
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
	if (
#ifdef SINGLE_PLAYER
		deathmatch.intVal && 
#endif
		!sv_cheats.intVal)
	{
		gi.cprintf (ent, PRINT_HIGH, "You must run the server with '+set cheats 1' to enable this command.\n");
		return;
	}

	string name = gi.args();
	bool give_all = striequals(name, "all");

	if (give_all || striequals(gi.argv(1), "health"))
	{
		if (gi.argc() == 3)
			ent.health = stoi(gi.argv(2));
		else
			ent.health = ent.max_health;
		if (!give_all)
			return;
	}

	bool give_weapons = give_all || striequals(name, "weapons");
	bool give_ammo = give_all || striequals(name, "ammo");

	if (give_weapons || give_ammo)
	{
		gitem_t *it = itemlist;

		for (int i = 0; i < itemlist.length; i++, it++)
		{
			if (!it->pickup)
				continue;
			if (it->flags & IT_AMMO)
			{
				if (give_ammo)
					Add_Ammo (ent, it, 1000);
			}
			else if (it->flags & IT_WEAPON)
			{
				if (give_weapons)
					ent.client.pers.inventory[i] += 1;
			}
			else if !(it->flags & IT_ARMOR)
			{
				if (give_all)
					ent.client.pers.inventory[i] = 1;
			}
		}

		if (!give_all)
			return;
	}

	if (give_all || striequals(name, "armor"))
	{
		gitem_t *it = FindItem("Jacket Armor");
		ent.client.pers.inventory[it->id] = 0;

		it = FindItem("Combat Armor");
		ent.client.pers.inventory[it->id] = 0;

		it = FindItem("Body Armor");
		gitem_armor_t *info = it->info;
		ent.client.pers.inventory[it->id] = info->max_count;

		if (!give_all)
			return;
	}

	if (give_all || striequals(name, "Power Shield"))
	{
		gitem_t *it = FindItem("Power Shield");

		entity it_ent = G_Spawn();
		it_ent.classname = it->classname;

		SpawnItem (it_ent, it);
		Touch_Item (it_ent, ent, vec3_origin, null_surface);

		if (it_ent.inuse)
			G_FreeEdict(it_ent);

		if (!give_all)
			return;
	}
	
	if (give_all)
		return;

	gitem_t *it = FindItem (name);

	if (!it)
	{
		string name = gi.argv(1);
		it = FindItem (name);

		if (!it)
		{
			gi.cprintf (ent, PRINT_HIGH, "unknown item\n");
			return;
		}
	}

	if (!it->pickup)
	{
		gi.cprintf (ent, PRINT_HIGH, "non-pickup item\n");
		return;
	}

	gitem_id_t index = it->id;

	if (it->flags & IT_AMMO)
	{
		if (gi.argc() == 3)
			ent.client.pers.inventory[index] = stoi(gi.argv(2));
		else
			ent.client.pers.inventory[index] += it->quantity;
	}
	else
	{
		entity it_ent = G_Spawn();
		it_ent.classname = it->classname;

		SpawnItem (it_ent, it);
		Touch_Item (it_ent, ent, vec3_origin, null_surface);

		if (it_ent.inuse)
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
	if (
#ifdef SINGLE_PLAYER
		deathmatch.intVal && 
#endif
		!sv_cheats.intVal)
	{
		gi.cprintf (ent, PRINT_HIGH, "You must run the server with '+set cheats 1' to enable this command.\n");
		return;
	}

	ent.flags ^= FL_GODMODE;

	string	msg;

	if (!(ent.flags & FL_GODMODE) )
		msg = "godmode OFF\n";
	else
		msg = "godmode ON\n";

	gi.cprintf (ent, PRINT_HIGH, msg);
}

#ifdef SINGLE_PLAYER
/*
==================
Cmd_Notarget_f

Sets client to notarget

argv(0) notarget
==================
*/
static void(entity ent) Cmd_Notarget_f =
{
	if (deathmatch.intVal && !sv_cheats.intVal)
	{
		gi.cprintf (ent, PRINT_HIGH, "You must run the server with '+set cheats 1' to enable this command.\n");
		return;
	}

	ent.flags ^= FL_NOTARGET;

	string	msg;

	if (!(ent.flags & FL_NOTARGET) )
		msg = "notarget OFF\n";
	else
		msg = "notarget ON\n";

	gi.cprintf (ent, PRINT_HIGH, msg);
}
#endif

/*
==================
Cmd_Noclip_f

argv(0) noclip
==================
*/
static void(entity ent) Cmd_Noclip_f =
{
	if (
#ifdef SINGLE_PLAYER
		deathmatch.intVal && 
#endif
		!sv_cheats.intVal)
	{
		gi.cprintf (ent, PRINT_HIGH, "You must run the server with '+set cheats 1' to enable this command.\n");
		return;
	}

	string	msg;

	if (ent.movetype == MOVETYPE_NOCLIP)
	{
		ent.movetype = MOVETYPE_WALK;
		msg = "noclip OFF\n";
	}
	else
	{
		ent.movetype = MOVETYPE_NOCLIP;
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
	string s = gi.args();
	gitem_t *it = FindItem (s);

	if (!it)
	{
		gi.cprintf (ent, PRINT_HIGH, "unknown item: %s\n", s);
		return;
	}

	gitem_id_t index = it->id;

	if (!ent.client.pers.inventory[index])
		gi.cprintf (ent, PRINT_HIGH, "Out of item: %s\n", s);
	else if (!it->use)
		gi.cprintf (ent, PRINT_HIGH, "Item is not usable.\n");
	else
		it->use(ent, it);
}


/*
==================
Cmd_Drop_f

Drop an inventory item
==================
*/
static void(entity ent) Cmd_Drop_f =
{
	string s = strlwr(gi.args());
	
#ifdef CTF
	gitem_t *it;

	if (s == "tech" && (it = CTFWhat_Tech(ent)))
	{
		it->drop(ent, it);
		return;
	}
#else
	gitem_t *
#endif
	it = FindItem (s);

	if (!it)
	{
		gi.cprintf (ent, PRINT_HIGH, "unknown item: %s\n", s);
		return;
	}

	gitem_id_t index = it->id;

	if (!ent.client.pers.inventory[index])
		gi.cprintf (ent, PRINT_HIGH, "Out of item: %s\n", s);
	else if (!it->drop)
		gi.cprintf (ent, PRINT_HIGH, "Item is not droppable.\n");
	else
		it->drop(ent, it);
}

/*
=================
Cmd_Inven_f
=================
*/
static void(entity ent) Cmd_Inven_f =
{
	ent.client.showscores = false;
#ifdef SINGLE_PLAYER
	ent.client.showhelp = false;
#endif
#ifdef PMENU
	if (ent.client.menu.open)
	{
		PMenu_Close(ent);
		ent.client.update_chase = true;
		return;
	}
#endif

	if (ent.client.showinventory)
	{
		ent.client.showinventory = false;
		return;
	}

#ifdef CTF
	if (ctf.intVal && ent.client.resp.ctf_team == CTF_NOTEAM)
	{
		CTFOpenJoinMenu(ent);
		return;
	}
#endif

	ent.client.showinventory = true;

	gi.WriteByte(svc_inventory);
	for (int i = 0; i < MAX_ITEMS; i++)
	{
		if (i < itemlist.length)
			gi.WriteShort(ent.client.pers.inventory[i]);
		else
			gi.WriteShort(0);
	}
	gi.unicast(ent, true);
}

/*
=================
Cmd_InvUse_f
=================
*/
static void(entity ent) Cmd_InvUse_f =
{
#ifdef PMENU
	if (ent.client.menu.open)
	{
		PMenu_Select(ent);
		return;
	}
#endif
	
	ValidateSelectedItem (ent);

	if (ent.client.pers.selected_item == -1)
	{
		gi.cprintf (ent, PRINT_HIGH, "No item to use.\n");
		return;
	}

	gitem_t *it = GetItemByIndex(ent.client.pers.selected_item);

	if (!it->use)
		gi.cprintf (ent, PRINT_HIGH, "Item is not usable.\n");
	else
		it->use(ent, it);
}

/*
=================
Cmd_WeapPrev_f
=================
*/
static void(entity ent) Cmd_WeapPrev_f =
{
	if (!ent.client.pers.weapon)
		return;

	gitem_id_t selected_weapon = ent.client.pers.weapon->id;

	// scan  for the next valid one
	for (int i = 1; i <= itemlist.length; i++)
	{
		gitem_id_t index = (selected_weapon + itemlist.length - i) % itemlist.length;

		if (!ent.client.pers.inventory[index])
			continue;

		gitem_t *it = GetItemByIndex(index);

		if (!it->use)
			continue;
		if (!(it->flags & IT_WEAPON))
			continue;

		it->use(ent, it);

		if (ent.client.newweapon == it || ent.client.pers.weapon == it)
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
	if (!ent.client.pers.weapon)
		return;

	gitem_id_t selected_weapon = ent.client.pers.weapon->id;

	// scan  for the next valid one
	for (int i = 1; i <= itemlist.length; i++)
	{
		gitem_id_t index = (selected_weapon + i) % itemlist.length;

		if (!ent.client.pers.inventory[index])
			continue;

		gitem_t *it = GetItemByIndex(index);

		if (!it->use)
			continue;
		if (!(it->flags & IT_WEAPON))
			continue;

		it->use(ent, it);

		if (ent.client.newweapon == it || ent.client.pers.weapon == it)
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
	if (!ent.client.pers.weapon || !ent.client.pers.lastweapon)
		return;

	gitem_id_t index = ent.client.pers.lastweapon->id;

	if (!ent.client.pers.inventory[index])
		return;

	gitem_t *it = GetItemByIndex(index);

	if (!it->use)
		return;
	if (!(it->flags & IT_WEAPON))
		return;

	it->use(ent, it);
}

/*
=================
Cmd_InvDrop_f
=================
*/
static void(entity ent) Cmd_InvDrop_f =
{
	ValidateSelectedItem (ent);

	if (ent.client.pers.selected_item == -1)
	{
		gi.cprintf (ent, PRINT_HIGH, "No item to drop.\n");
		return;
	}

	gitem_t *it = GetItemByIndex(ent.client.pers.selected_item);

	if (!it->drop)
		gi.cprintf (ent, PRINT_HIGH, "Item is not dropable.\n");
	else
		it->drop(ent, it);
}

/*
=================
Cmd_Kill_f
=================
*/
static void(entity ent) Cmd_Kill_f =
{
	if (ent->solid == SOLID_NOT)
		return;
	if ((level.framenum - ent.client.respawn_framenum) < 5 * BASE_FRAMERATE)
		return;

	ent.flags &= ~FL_GODMODE;
	ent.health = 0;
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
	ent.client.showscores = false;
#ifdef SINGLE_PLAYER
	ent.client.showhelp = false;
#endif
	ent.client.showinventory = false;

#ifdef PMENU
	if (ent.client.menu.open)
		PMenu_Close(ent);
#endif

	ent.client.update_chase = true;
}

static int(int *a, int *b) PlayerSort =
{
	int anum = itoe((*a) + 1).client.ps.stats[STAT_FRAGS];
	int bnum = itoe((*b) + 1).client.ps.stats[STAT_FRAGS];

	if (anum < bnum)
		return -1;
	if (anum > bnum)
		return 1;
	return 0;
}

/*
=================
Cmd_Players_f
=================
*/
static void (entity ent) Cmd_Players_f =
{
	int count = 0;
	int index[256] = { 0 };

	for (int i = 0 ; i < game.maxclients; i++)
		if (itoe(i + 1).client.pers.connected)
		{
			index[count] = i + 1;
			count++;
		}

	// sort by frags
	qsort(index, count, sizeof(index[0]), PlayerSort);

	// print information
	string large = "";

	for (int i = 0; i < count; i++)
	{
		entity e = itoe(index[i]);
		string small = va("%3i %s\n", e.client.ps.stats[STAT_FRAGS], e.client.pers.netname);

		if (strlen(small) + strlen(large) > 1280 - 100 )
		{
			// can't print all of them in one packet
			large = strconcat(large, "...\n");
			break;
		}

		large = strconcat(large, small);
	}

	gi.cprintf(ent, PRINT_HIGH, "%s\n%i players\n", large, count);
}

/*
=================
Cmd_Wave_f
=================
*/
static void(entity ent) Cmd_Wave_f =
{
	// can't wave when ducked
	if (ent.client.ps.pmove.pm_flags & PMF_DUCKED)
		return;

	if (ent.client.anim_priority > ANIM_WAVE)
		return;

	ent.client.anim_priority = ANIM_WAVE;

	switch (stoi(gi.argv(1)))
	{
	case 0:
		gi.cprintf (ent, PRINT_HIGH, "flipoff\n");
		ent.s.frame = FRAME_flip01-1;
		ent.client.anim_end = FRAME_flip12;
		break;
	case 1:
		gi.cprintf (ent, PRINT_HIGH, "salute\n");
		ent.s.frame = FRAME_salute01-1;
		ent.client.anim_end = FRAME_salute11;
		break;
	case 2:
		gi.cprintf (ent, PRINT_HIGH, "taunt\n");
		ent.s.frame = FRAME_taunt01-1;
		ent.client.anim_end = FRAME_taunt17;
		break;
	case 3:
		gi.cprintf (ent, PRINT_HIGH, "wave\n");
		ent.s.frame = FRAME_wave01-1;
		ent.client.anim_end = FRAME_wave11;
		break;
	case 4:
	default:
		gi.cprintf (ent, PRINT_HIGH, "point\n");
		ent.s.frame = FRAME_point01-1;
		ent.client.anim_end = FRAME_point12;
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
	if (gi.argc() < 2 && !arg0)
		return;

	bool team = (dmflags.intVal & (DF_MODELTEAMS | DF_SKINTEAMS));
	string text;

	if (team)
		text = va("(%s): ", ent.client.pers.netname);
	else
		text = va("%s: ", ent.client.pers.netname);

	if (arg0)
		text = va("%s%s %s", text, gi.argv(0), gi.args());
	else
	{
		string p = gi.args();

		if (strat(p, 0) == '"')
			p = substr(p, 1, strlen(p) - 2);

		text = va("%s%s", text, p);
	}

	// don't let text be too long for malicious reasons
	if (strlen(text) > 150)
		text = va("%.150s", text);

	text = va("%s\n", text);

	if (flood_msgs.intVal)
	{
		if (level.time < ent.client.flood_locktill)
		{
			gi.cprintf(ent, PRINT_HIGH, "You can't talk for %d more seconds\n", (int)(ent.client.flood_locktill - level.time));
			return;
		}

		int i = ent.client.flood_whenhead - flood_msgs.intVal + 1;

		if (i < 0)
			i = client.flood_when.length + i;
            
		if (ent.client.flood_when[i] && level.time - ent.client.flood_when[i] < flood_persecond.intVal)
		{
			ent.client.flood_locktill = level.time + flood_waitdelay.intVal;
			gi.cprintf(ent, PRINT_CHAT, "Flood protection:  You can't talk for %d seconds.\n", (int)flood_waitdelay.intVal);
			return;
		}

		ent.client.flood_whenhead = (ent.client.flood_whenhead + 1) % client.flood_when.length;
		ent.client.flood_when[ent.client.flood_whenhead] = level.time;
	}

	if (dedicated.intVal)
		gi.cprintf(world, PRINT_CHAT, "%s", text);

	for (int i = 1; i <= game.maxclients; i++)
	{
		entity other = itoe(i);
		if (!other.inuse)
			continue;
		if (!other.is_client)
			continue;
		if (team && !OnSameTeam(ent, other))
			continue;

		gi.cprintf(other, PRINT_CHAT, "%s", text);
	}
}

static void(entity ent) Cmd_PlayerList_f =
{
	// connect time, ping, score, name
	string text = "";

	for (int i = 0; i < game.maxclients; i++)
	{
		entity e2 = itoe(i + 1);

		if (!e2.inuse)
			continue;

		string st = va("%02d:%02d %4d %3d %s%s\n",
			(level.framenum - e2.client.resp.enterframe) / 600,
			((level.framenum - e2.client.resp.enterframe) % 600) / 10,
			e2.client.ping,
			e2.client.resp.score,
			e2.client.pers.netname,
			e2.client.resp.spectator ? " (spectator)" : "");

		if (strlen(text) + strlen(st) > MESSAGE_LIMIT - 50)
		{
			text = strconcat(text, "And more...\n");
			break;
		}

		text = strconcat(text, st);
	}

	gi.cprintf(ent, PRINT_HIGH, "%s", text);
}

// from hud.qc
void(entity ent) Cmd_Score_f;

// spawn.qc
bool(entity ent) ED_CallSpawn;

static void(entity ent) Cmd_Spawn_f =
{
	if (
#ifdef SINGLE_PLAYER
		deathmatch.intVal && 
#endif
		!sv_cheats.intVal)
	{
		gi.cprintf (ent, PRINT_HIGH, "You must run the server with '+set cheats 1' to enable this command.\n");
		return;
	}

	entity e = G_Spawn();
	e.classname = gi.argv(1);
	
	vector forward;
	AngleVectors(ent.client.v_angle, &forward, 0, 0);
	
	e.s.origin = ent.s.origin + (forward * 128);
	e.s.angles[YAW] = ent.s.angles[YAW];
	
	ED_CallSpawn(e);
	gi.linkentity(e);
};

#ifdef OFFHAND_HOOK
void(entity) GrappleCmd;
#endif

/*
=================
ClientCommand
=================
*/
void(entity ent) ClientCommand =
{
	string	cmd;

	if (!ent.is_client)
		return;		// not fully in game yet

	cmd = strlwr(gi.argv(0));

	// allowed any time
	if (cmd == "players")
		return Cmd_Players_f (ent);
	else if (cmd == "say")
		Cmd_Say_f (ent, false, false);
	else if (cmd == "say_team")
		Cmd_Say_f (ent, true, false);
	else if (cmd == "score")
		Cmd_Score_f (ent);
	else if (cmd == "help")
		Cmd_Help_f (ent);
	else if (level.intermission_framenum)
		return;

	// in-game commands only
	else if (cmd == "spawn")
		Cmd_Spawn_f (ent);
	else if (cmd == "use")
		Cmd_Use_f (ent);
	else if (cmd == "drop")
		Cmd_Drop_f (ent);
	else if (cmd == "give")
		Cmd_Give_f (ent);
	else if (cmd == "god")
		Cmd_God_f (ent);
#ifdef SINGLE_PLAYER
	else if (cmd == "notarget")
		Cmd_Notarget_f (ent);
#endif
	else if (cmd == "noclip")
		Cmd_Noclip_f (ent);
	else if (cmd == "inven")
		Cmd_Inven_f (ent);
	else if (cmd == "invnext")
		SelectNextItem (ent, -1);
	else if (cmd == "invprev")
		SelectPrevItem (ent, -1);
	else if (cmd == "invnextw")
		SelectNextItem (ent, IT_WEAPON);
	else if (cmd == "invprevw")
		SelectPrevItem (ent, IT_WEAPON);
	else if (cmd == "invnextp")
		SelectNextItem (ent, IT_POWERUP);
	else if (cmd == "invprevp")
		SelectPrevItem (ent, IT_POWERUP);
	else if (cmd == "invuse")
		Cmd_InvUse_f (ent);
	else if (cmd == "invdrop")
		Cmd_InvDrop_f (ent);
	else if (cmd == "weapprev")
		Cmd_WeapPrev_f (ent);
	else if (cmd == "weapnext")
		Cmd_WeapNext_f (ent);
	else if (cmd == "weaplast")
		Cmd_WeapLast_f (ent);
	else if (cmd == "kill")
		Cmd_Kill_f (ent);
	else if (cmd == "putaway")
		Cmd_PutAway_f (ent);
	else if (cmd == "wave")
		Cmd_Wave_f (ent);
	else if (cmd == "playerlist")
		Cmd_PlayerList_f(ent);
#ifdef CTF
	else if (cmd == "team")
		CTFTeam_f (ent);
	else if (cmd == "id")
		CTFID_f (ent);
	else if (cmd == "playerlist")
		CTFPlayerList(ent);
	else if (cmd == "observer")
		CTFObserver(ent);
#endif
#ifdef OFFHAND_HOOK
	else if (cmd == "hook")
		GrappleCmd(ent);
#endif
	else	// anything that doesn't match a command will be a chat
		Cmd_Say_f (ent, false, true);
}
