#ifdef CTF

#define CTF_VERSION		"1.52"

static const string CTF_TEAM1_SKIN = "ctf_r";
static const string CTF_TEAM2_SKIN = "ctf_b";

static const int CTF_CAPTURE_BONUS	= 15;	// what you get for capture
static const int CTF_TEAM_BONUS		= 10;	// what your team gets for capture
static const int CTF_RECOVERY_BONUS	= 1;	// what you get for recovery
static const int CTF_FLAG_BONUS		= 0;	// what you get for picking up enemy flag
static const int CTF_FRAG_CARRIER_BONUS	= 2;	// what you get for fragging enemy flag carrier
static const int CTF_FLAG_RETURN_TIME	= 40;	// seconds until auto return

static const int CTF_CARRIER_DANGER_PROTECT_BONUS	= 2;	// bonus for fraggin someone who has recently hurt your flag carrier
static const int CTF_CARRIER_PROTECT_BONUS			= 1;	// bonus for fraggin someone while either you or your target are near your flag carrier
static const int CTF_FLAG_DEFENSE_BONUS				= 1;	// bonus for fraggin someone while either you or your target are near your flag
static const int CTF_RETURN_FLAG_ASSIST_BONUS		= 1;	// awarded for returning a flag that causes a capture to happen almost immediately
static const int CTF_FRAG_CARRIER_ASSIST_BONUS		= 2;	// award for fragging a flag carrier if a capture happens almost immediately

static const int CTF_TARGET_PROTECT_RADIUS			= 400;	// the radius around an object being defended where a target will be worth extra frags
static const int CTF_ATTACKER_PROTECT_RADIUS		= 400;	// the radius around an object being defended where an attacker will get extra frags when making kills

static const int CTF_CARRIER_DANGER_PROTECT_TIMEOUT		= 8;
static const int CTF_FRAG_CARRIER_ASSIST_TIMEOUT		= 10;
static const int CTF_RETURN_FLAG_ASSIST_TIMEOUT			= 10;

static const int CTF_AUTO_FLAG_RETURN_TIMEOUT		= 30;	// number of seconds before dropped flag auto-returns

static const int CTF_TECH_TIMEOUT					= 60;  // seconds before techs spawn again

static struct
{
	int team1, team2;
	int total1, total2; // these are only set when going into intermission!
	int last_flag_capture_framenum;
	int last_capture_team;

	int warnactive;		// true if stat string 30 is active
} ctfgame;

// Index for various CTF pics, this saves us from calling gi.imageindex
// all the time and saves a few CPU cycles since we don't have to do
// a bunch of string compares all the time.
// These are set in CTFPrecache() called from worldspawn
static int imageindex_i_ctf1;
static int imageindex_i_ctf2;
static int imageindex_i_ctf1d;
static int imageindex_i_ctf2d;
static int imageindex_i_ctf1t;
static int imageindex_i_ctf2t;
static int imageindex_i_ctfj;
static int imageindex_sbfctf1;
static int imageindex_sbfctf2;
static int imageindex_ctfsb1;
static int imageindex_ctfsb2;

static cvar_t warn_unbalanced;

const string ctf_statusbar =
"yb	-24 "

// health
"xv	0 "
"hnum "
"xv	50 "
"pic " STAT(STAT_HEALTH_ICON) " "

// ammo
"if " STAT(STAT_AMMO_ICON) " "
"	xv	100 "
"	anum "
"	xv	150 "
"	pic " STAT(STAT_AMMO_ICON) " "
"endif "

// armor
"if " STAT(STAT_ARMOR_ICON) " "
"	xv	200 "
"	rnum "
"	xv	250 "
"	pic " STAT(STAT_ARMOR_ICON) " "
"endif "

// selected item
"if " STAT(STAT_SELECTED_ICON) " "
"	xv	296 "
"	pic " STAT(STAT_SELECTED_ICON) " "
"endif "

"yb	-50 "

// picked up item
"if " STAT(STAT_PICKUP_ICON) " "
"	xv	0 "
"	pic " STAT(STAT_PICKUP_ICON) " "
"	xv	26 "
"	yb	-42 "
"	stat_string " STAT(STAT_PICKUP_STRING) " "
"	yb	-50 "
"endif "

// timer
"if " STAT(STAT_TIMER_ICON) " "
  "xv 246 "
  "num 2 " STAT(STAT_TIMER) " "
  "xv 296 "
  "pic " STAT(STAT_TIMER_ICON) " "
"endif "

//  help / weapon icon 
"if " STAT(STAT_HELPICON) " "
  "xv 148 "
  "pic " STAT(STAT_HELPICON) " "
"endif "

//  frags
"xr	-50 "
"yt 2 "
"num 3 " STAT(STAT_FRAGS) " "

//tech
"yb -129 "
"if " STAT(STAT_CTF_TECH) " "
  "xr -26 "
  "pic " STAT(STAT_CTF_TECH) " "
"endif "

// red team
"yb -102 "
"if " STAT(STAT_CTF_TEAM1_PIC) " "
  "xr -26 "
  "pic " STAT(STAT_CTF_TEAM1_PIC) " "
"endif "
"xr -62 "
"num 2 " STAT(STAT_CTF_TEAM1_CAPS) " "
//joined overlay
"if " STAT(STAT_CTF_JOINED_TEAM1_PIC) " "
  "yb -104 "
  "xr -28 "
  "pic " STAT(STAT_CTF_JOINED_TEAM1_PIC) " "
"endif "

// blue team
"yb -75 "
"if " STAT(STAT_CTF_TEAM2_PIC) " "
  "xr -26 "
  "pic " STAT(STAT_CTF_TEAM2_PIC) " "
"endif "
"xr -62 "
"num 2 " STAT(STAT_CTF_TEAM2_CAPS) " "
"if " STAT(STAT_CTF_JOINED_TEAM2_PIC) " "
  "yb -77 "
  "xr -28 "
  "pic " STAT(STAT_CTF_JOINED_TEAM2_PIC) " "
"endif "

// have flag graph
"if " STAT(STAT_CTF_FLAG_PIC) " "
  "yt 26 "
  "xr -24 "
  "pic " STAT(STAT_CTF_FLAG_PIC) " "
"endif "

// id view state
"if " STAT(STAT_CTF_ID_VIEW) " "
  "xv 112 "
  "yb -58 "
  "stat_string " STAT(STAT_CTF_ID_VIEW) " "
"endif "

"if " STAT(STAT_CTF_ID_VIEW_COLOR) " "
  "xv 96 "
  "yb -58 "
  "pic " STAT(STAT_CTF_ID_VIEW_COLOR) " "
"endif "

"if " STAT(STAT_CTF_TEAMINFO) " "
  "xl 0 "
  "yb -88 "
  "stat_string " STAT(STAT_CTF_TEAMINFO) " "
"endif "
;

static gitem_id_t techids[] = { ITEM_TECH1, ITEM_TECH2, ITEM_TECH3, ITEM_TECH4 };

/*
=================
findradius

Returns entities that have origins within a spherical area

findradius (origin, radius)
=================
*/
static entity(entity from, vector org, float rad) loc_findradius =
{
	if !(from)
		from = itoe(1);
	else
		from = next_ent(from);

	for (; etoi(from) < globals.num_edicts; from = next_ent(from))
	{
		if !(from.inuse)
			continue;
		vector eorg = org - (from.s.origin + (from.mins + from.maxs) * 0.5f);
		if (VectorLength(eorg) > rad)
			continue;
		return from;
	}

	return world;
}

static void(vector *p, vector org, vector mins, vector maxs) loc_buildboxpoints =
{
	p[0] = org + mins;
	p[1] = p[0];
	p[1].x -= mins.x;
	p[2] = p[0];
	p[2].y -= mins.y;
	p[3] = p[0];
	p[3].x -= mins.x;
	p[3].y -= mins.y;
	p[4] = org + maxs;
	p[5] = p[4];
	p[5].x -= maxs.x;
	p[6] = p[0];
	p[6].y -= maxs.y;
	p[7] = p[0];
	p[7].x -= maxs.x;
	p[7].y -= maxs.y;
}

static bool(entity targ, entity inflictor) loc_CanSee =
{
	if (targ.movetype == MOVETYPE_PUSH)
		return false; // bmodels not supported

	vector targpoints[8];
	loc_buildboxpoints(targpoints, targ.s.origin, targ.mins, targ.maxs);
	
	vector viewpoint = inflictor->s.origin;
	viewpoint.z += inflictor->viewheight;

	for (int i = 0; i < 8; i++)
	{
		trace_t tr;
		gi.traceline(&tr, viewpoint, targpoints[i], inflictor, MASK_SOLID);
		if (tr.fraction == 1.0)
			return true;
	}

	return false;
}

/*--------------------------------------------------------------------------*/

// from ctf.qc
void() CTFSetupTechSpawn;

void() CTFSpawn =
{
	memclear(&ctfgame, sizeof(ctfgame));
	CTFSetupTechSpawn();
}

void() CTFInit =
{
	ctf = gi.cvar("ctf", "0", CVAR_SERVERINFO | CVAR_LATCH);
	warn_unbalanced = gi.cvar("warn_unbalanced", "1", 0);
}

/*
 * Precache CTF items
 */
inline void() CTFPrecache =
{
	imageindex_i_ctf1 =   gi.imageindex("i_ctf1"); 
	imageindex_i_ctf2 =   gi.imageindex("i_ctf2"); 
	imageindex_i_ctf1d =  gi.imageindex("i_ctf1d");
	imageindex_i_ctf2d =  gi.imageindex("i_ctf2d");
	imageindex_i_ctf1t =  gi.imageindex("i_ctf1t");
	imageindex_i_ctf2t =  gi.imageindex("i_ctf2t");
	imageindex_i_ctfj =   gi.imageindex("i_ctfj"); 
	imageindex_sbfctf1 =  gi.imageindex("sbfctf1");
	imageindex_sbfctf2 =  gi.imageindex("sbfctf2");
	imageindex_ctfsb1 =   gi.imageindex("ctfsb1");
	imageindex_ctfsb2 =   gi.imageindex("ctfsb2");
}

/*--------------------------------------------------------------------------*/

INLINE string(ctfteam_t team) CTFTeamName =
{
	switch (team)
	{
	case CTF_TEAM1:
		return "RED";
	case CTF_TEAM2:
		return "BLUE";
	}
	return "UNKNOWN";
}

INLINE int(ctfteam_t team) CTFOtherTeam =
{
	switch (team)
	{
	case CTF_TEAM1:
		return CTF_TEAM2;
	case CTF_TEAM2:
		return CTF_TEAM1;
	}
	return -1; // invalid value
}

inline string(ctfteam_t team) CTFOtherTeamName =
{
	return CTFTeamName(CTFOtherTeam(team));
}

void(entity ent, string st) CTFAssignSkin
{
	int playernum = ent.s.number - 1;
	int p = strchr(st, '/');
	string model;

	if (p != -1)
		model = substr(st, 0, p + 1);
	else
		model = "male/";

	string skin = 0;

	switch (ent.client.resp.ctf_team)
	{
	case CTF_TEAM1:
		skin = strconcat(ent.client.pers.netname, "\\", model, CTF_TEAM1_SKIN);
		break;
	case CTF_TEAM2:
		skin = strconcat(ent.client.pers.netname, "\\", model, CTF_TEAM2_SKIN);
		break;
	default:
		skin = strconcat(ent.client.pers.netname, "\\", st);
		break;
	}

	gi.configstring (CS_PLAYERSKINS+playernum, skin);
}

void(entity who) CTFAssignTeam =
{
	who.client.resp.ctf_state = 0;

	if !(dmflags.intVal & DF_CTF_FORCEJOIN)
	{
		who.client.resp.ctf_team = CTF_NOTEAM;
		return;
	}

	int team1count = 0, team2count = 0;

	for (int i = 1; i <= game.maxclients; i++)
	{
		entity player = itoe(i);

		if (!player.inuse || player == who)
			continue;

		switch (player.client.resp.ctf_team)
		{
		case CTF_TEAM1:
			team1count++;
			break;
		case CTF_TEAM2:
			team2count++;
			break;
		}
	}

	if (team1count < team2count)
		who.client.resp.ctf_team = CTF_TEAM1;
	else if (team2count < team1count)
		who.client.resp.ctf_team = CTF_TEAM2;
	else if (Q_rand() & 1)
		who.client.resp.ctf_team = CTF_TEAM1;
	else
		who.client.resp.ctf_team = CTF_TEAM2;
}

// from client.qc
entity()		SelectRandomDeathmatchSpawnPoint;
entity()		SelectFarthestDeathmatchSpawnPoint;
float(entity)	PlayersRangeFromSpot;

/*
================
SelectCTFSpawnPoint

go to a ctf point, but NOT the two points closest
to other players
================
*/
entity(entity ent) SelectCTFSpawnPoint =
{
	if (ent.client.resp.ctf_state)
		if (dmflags.intVal & DF_SPAWN_FARTHEST)
			return SelectFarthestDeathmatchSpawnPoint ();
		else
			return SelectRandomDeathmatchSpawnPoint ();

	ent.client.resp.ctf_state++;

	string	cname = 0;
	switch (ent.client.resp.ctf_team)
	{
	case CTF_TEAM1:
		cname = "info_player_team1";
		break;
	case CTF_TEAM2:
		cname = "info_player_team2";
		break;
	default:
		return SelectRandomDeathmatchSpawnPoint();
	}

	entity spot = 0;
	float range1 = 99999, range2 = 99999;
	entity spot1 = 0, spot2 = 0;
	int count = 0;

	while ((spot = G_Find (spot, classname, cname)))
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
		return SelectRandomDeathmatchSpawnPoint();

	if (count <= 2)
		spot1 = spot2 = 0;
	else
		count -= 2;

	int selection = Q_rand_uniform(count);

	spot = 0;
	do
	{
		spot = G_Find (spot, classname, cname);
		if (spot == spot1 || spot == spot2)
			selection++;
	} while(selection--);

	return spot;
}

/*------------------------------------------------------------------------*/
/*
CTFFragBonuses

Calculate the bonuses for flag defense, flag carrier defense, etc.
Note that bonuses are not cumaltive.  You get one, they are in importance
order.
*/
void(entity targ, entity inflictor, entity attacker) CTFFragBonuses =
{
	// no bonus for fragging yourself
	if (!targ.is_client || !attacker.is_client || targ == attacker)
		return;

	ctfteam_t otherteam = CTFOtherTeam(targ.client.resp.ctf_team);
	if (otherteam < 0)
		return; // whoever died isn't on a team

	// same team, if the flag at base, check to he has the enemy flag
	gitem_id_t flag_item, enemy_flag_item;
	if (targ.client.resp.ctf_team == CTF_TEAM1)
	{
		flag_item = ITEM_FLAG1;
		enemy_flag_item = ITEM_FLAG2;
	}
	else
	{
		flag_item = ITEM_FLAG2;
		enemy_flag_item = ITEM_FLAG1;
	}

	// did the attacker frag the flag carrier?
	if (targ.client.pers.inventory[enemy_flag_item])
	{
		attacker.client.resp.ctf_lastfraggedcarrierframe = level.framenum;
		attacker.client.resp.score += CTF_FRAG_CARRIER_BONUS;
		gi.cprintf(attacker, PRINT_MEDIUM, "BONUS: %d points for fragging enemy flag carrier.\n",
			CTF_FRAG_CARRIER_BONUS);

		// the target had the flag, clear the hurt carrier
		// field on the other team
		for (int i = 1; i <= game.maxclients; i++)
		{
			entity ent = itoe(i);
			if (ent.inuse && ent.client.resp.ctf_team == otherteam)
				ent.client.resp.ctf_lasthurtcarrierframe = 0;
		}
		return;
	}

	if (targ.client.resp.ctf_lasthurtcarrierframe &&
		(level.framenum - targ.client.resp.ctf_lasthurtcarrierframe) < (CTF_CARRIER_DANGER_PROTECT_TIMEOUT * BASE_FRAMERATE) &&
		!attacker.client.pers.inventory[flag_item])
	{
		// attacker is on the same team as the flag carrier and
		// fragged a guy who hurt our flag carrier
		attacker.client.resp.score += CTF_CARRIER_DANGER_PROTECT_BONUS;
		gi.bprintf(PRINT_MEDIUM, "%s defends %s's flag carrier against an agressive enemy\n",
			attacker.client.pers.netname, 
			CTFTeamName(attacker.client.resp.ctf_team));
		return;
	}

	// flag and flag carrier area defense bonuses
	// we have to find the flag and carrier entities
	// find the flag
	string c = 0;
	switch (attacker.client.resp.ctf_team)
	{
	case CTF_TEAM1:
		c = "item_flag_team1";
		break;
	case CTF_TEAM2:
		c = "item_flag_team2";
		break;
	default:
		return;
	}

	entity flag = world;
	while ((flag = G_Find (flag, classname, c)))
		if !(flag->spawnflags & DROPPED_ITEM)
			break;

	if !(flag)
		return; // can't find attacker's flag

	// find attacker's team's flag carrier
	entity carrier = world;
	for (int i = 1; i <= game.maxclients; i++)
	{
		carrier = itoe(i);
		if (carrier.inuse && 
			carrier.client.pers.inventory[flag_item])
			break;
		carrier = world;
	}

	// ok we have the attackers flag and a pointer to the carrier

	// check to see if we are defending the base's flag
	vector v1 = targ.s.origin - flag.s.origin;
	vector v2 = attacker->s.origin - flag->s.origin;

	if ((VectorLength(v1) < CTF_TARGET_PROTECT_RADIUS ||
		VectorLength(v2) < CTF_TARGET_PROTECT_RADIUS ||
		loc_CanSee(flag, targ) || loc_CanSee(flag, attacker)) &&
		attacker.client.resp.ctf_team != targ.client.resp.ctf_team)
	{
		// we defended the base flag
		attacker.client.resp.score += CTF_FLAG_DEFENSE_BONUS;
		if (flag.solid == SOLID_NOT)
			gi.bprintf(PRINT_MEDIUM, "%s defends the %s base.\n",
				attacker.client.pers.netname, 
				CTFTeamName(attacker.client.resp.ctf_team));
		else
			gi.bprintf(PRINT_MEDIUM, "%s defends the %s flag.\n",
				attacker.client.pers.netname, 
				CTFTeamName(attacker.client.resp.ctf_team));
		return;
	}

	if (carrier && carrier != attacker)
	{
		v1 = targ->s.origin - carrier->s.origin;
		v2 = attacker->s.origin - carrier->s.origin;

		if (VectorLength(v1) < CTF_ATTACKER_PROTECT_RADIUS ||
			VectorLength(v2) < CTF_ATTACKER_PROTECT_RADIUS ||
			loc_CanSee(carrier, targ) || loc_CanSee(carrier, attacker))
		{
			attacker.client.resp.score += CTF_CARRIER_PROTECT_BONUS;
			gi.bprintf(PRINT_MEDIUM, "%s defends the %s's flag carrier.\n",
				attacker.client.pers.netname, 
				CTFTeamName(attacker.client.resp.ctf_team));
			return;
		}
	}
}

void(entity targ, entity attacker) CTFCheckHurtCarrier =
{
	if (!targ.is_client || !attacker.is_client)
		return;

	gitem_id_t flag_item;

	if (targ.client.resp.ctf_team == CTF_TEAM1)
		flag_item = ITEM_FLAG2;
	else
		flag_item = ITEM_FLAG1;

	if (targ.client.pers.inventory[flag_item] &&
		targ.client.resp.ctf_team != attacker.client.resp.ctf_team)
		attacker.client.resp.ctf_lasthurtcarrierframe = level.framenum;
}


/*------------------------------------------------------------------------*/

void(ctfteam_t ctf_team) CTFResetFlag =
{
	string c = 0;
	switch (ctf_team)
	{
	case CTF_TEAM1:
		c = "item_flag_team1";
		break;
	case CTF_TEAM2:
		c = "item_flag_team2";
		break;
	default:
		return;
	}

	entity ent = world;
	while ((ent = G_Find (ent, classname, c)))
	{
		if (ent.spawnflags & DROPPED_ITEM)
			G_FreeEdict(ent);
		else
		{
			ent.svflags &= ~SVF_NOCLIENT;
			ent.solid = SOLID_TRIGGER;
			gi.linkentity(ent);
			ent.s.event = EV_ITEM_RESPAWN;
		}
	}
}

void() CTFResetFlags =
{
	CTFResetFlag(CTF_TEAM1);
	CTFResetFlag(CTF_TEAM2);
}

bool(entity ent, entity other) CTFPickup_Flag =
{
	ctfteam_t ctf_team;

	// figure out what team this flag is
	if (ent->classname == "item_flag_team1")
		ctf_team = CTF_TEAM1;
	else if (ent->classname == "item_flag_team2")
		ctf_team = CTF_TEAM2;
	else
	{
		gi.cprintf(ent, PRINT_HIGH, "Don't know what team the flag is on.\n");
		return false;
	}

	gitem_id_t flag_item, enemy_flag_item;

	// same team, if the flag at base, check to he has the enemy flag
	if (ctf_team == CTF_TEAM1)
	{
		flag_item = ITEM_FLAG1;
		enemy_flag_item = ITEM_FLAG2;
	}
	else
	{
		flag_item = ITEM_FLAG2;
		enemy_flag_item = ITEM_FLAG1;
	}

	if (ctf_team == other.client.resp.ctf_team)
	{
		if !(ent.spawnflags & DROPPED_ITEM)
		{
			// the flag is at home base.  if the player has the enemy
			// flag, he's just won!
			if (other.client.pers.inventory[enemy_flag_item])
			{
				gi.bprintf(PRINT_HIGH, "%s captured the %s flag!\n",
						other.client.pers.netname, CTFOtherTeamName(ctf_team));
				other.client.pers.inventory[enemy_flag_item] = 0;

				ctfgame.last_flag_capture_framenum = level.framenum;
				ctfgame.last_capture_team = ctf_team;

				if (ctf_team == CTF_TEAM1)
					ctfgame.team1++;
				else
					ctfgame.team2++;

				gi.sound(ent, CHAN_RELIABLE+CHAN_NO_PHS_ADD+CHAN_VOICE, gi.soundindex("ctf/flagcap.wav"), 1, ATTN_NONE, 0);

				// other gets another 10 frag bonus
				other.client.resp.score += CTF_CAPTURE_BONUS;

				// Ok, let's do the player loop, hand out the bonuses
				for (int i = 1; i <= game.maxclients; i++)
				{
					entity player = itoe(i);

					if (!player.inuse)
						continue;

					if (player.client.resp.ctf_team != other.client.resp.ctf_team)
						player.client.resp.ctf_lasthurtcarrierframe = -5 * BASE_FRAMERATE;
					else if (player.client.resp.ctf_team == other.client.resp.ctf_team)
					{
						if (player != other)
							player.client.resp.score += CTF_TEAM_BONUS;

						// award extra points for capture assists
						if (player.client.resp.ctf_lastreturnedflagframe + (CTF_RETURN_FLAG_ASSIST_TIMEOUT * BASE_FRAMERATE) > level.framenum)
						{
							gi.bprintf(PRINT_HIGH, "%s gets an assist for returning the flag!\n", player.client.pers.netname);
							player.client.resp.score += CTF_RETURN_FLAG_ASSIST_BONUS;
						}

						if (player.client.resp.ctf_lastfraggedcarrierframe + (CTF_FRAG_CARRIER_ASSIST_TIMEOUT * BASE_FRAMERATE) > level.framenum)
						{
							gi.bprintf(PRINT_HIGH, "%s gets an assist for fragging the flag carrier!\n", player.client.pers.netname);
							player.client.resp.score += CTF_FRAG_CARRIER_ASSIST_BONUS;
						}
					}
				}

				CTFResetFlags();
				return false;
			}
			return false; // its at home base already
		}
		// hey, its not home.  return it by teleporting it back
		gi.bprintf(PRINT_HIGH, "%s returned the %s flag!\n", 
			other.client.pers.netname, CTFTeamName(ctf_team));
		other.client.resp.score += CTF_RECOVERY_BONUS;
		other.client.resp.ctf_lastreturnedflagframe = level.framenum;
		gi.sound (ent, CHAN_RELIABLE+CHAN_NO_PHS_ADD+CHAN_VOICE, gi.soundindex("ctf/flagret.wav"), 1, ATTN_NONE, 0);
		//CTFResetFlag will remove this entity!  We must return false
		CTFResetFlag(ctf_team);
		return false;
	}

	// hey, its not our flag, pick it up
	gi.bprintf(PRINT_HIGH, "%s got the %s flag!\n",
		other.client.pers.netname, CTFTeamName(ctf_team));
	other.client.resp.score += CTF_FLAG_BONUS;

	other.client.pers.inventory[flag_item] = 1;
	other.client.resp.ctf_flagsinceframe = level.framenum;

	// pick up the flag
	// if it's not a dropped flag, we just make is disappear
	// if it's dropped, it will be removed by the pickup caller
	if !(ent.spawnflags & DROPPED_ITEM)
	{
		ent.flags |= FL_RESPAWN;
		ent.svflags |= SVF_NOCLIENT;
		ent.solid = SOLID_NOT;
	}
	return true;
}

static void(entity ent, entity other, vector plane, csurface_t surf) CTFDropFlagTouch =
{
	//owner (who dropped us) can't touch for two secs
	if (other == ent.owner && ent.nextthink - level.framenum > (CTF_AUTO_FLAG_RETURN_TIMEOUT - 2) * BASE_FRAMERATE)
		return;

	Touch_Item (ent, other, plane, surf);
}

static void(entity ent) CTFDropFlagThink =
{
	// auto return the flag
	// reset flag will remove ourselves
	ctfteam_t team;

	if (ent.classname == "item_flag_team1")
		team = CTF_TEAM1;
	else if (ent.classname == "item_flag_team2")
		team = CTF_TEAM2;
	else
		return;

	CTFResetFlag(team);
	gi.bprintf(PRINT_HIGH, "The %s flag has returned!\n",
		CTFTeamName(team));
}

// Called from PlayerDie, to drop the flag from a dying player
void(entity self) CTFDeadDropFlag =
{
	entity dropped = world;

	if (self.client.pers.inventory[ITEM_FLAG1])
	{
		dropped = Drop_Item(self, GetItemByIndex(ITEM_FLAG1));
		self.client.pers.inventory[ITEM_FLAG1] = 0;
		gi.bprintf(PRINT_HIGH, "%s lost the %s flag!\n",
			self.client.pers.netname, CTFTeamName(CTF_TEAM1));
	}
	else if (self.client.pers.inventory[ITEM_FLAG2])
	{
		dropped = Drop_Item(self, GetItemByIndex(ITEM_FLAG2));
		self.client.pers.inventory[ITEM_FLAG2] = 0;
		gi.bprintf(PRINT_HIGH, "%s lost the %s flag!\n",
			self.client.pers.netname, CTFTeamName(CTF_TEAM2));
	}

	if (dropped)
	{
		dropped.think = CTFDropFlagThink;
		dropped.nextthink = level.framenum + (CTF_AUTO_FLAG_RETURN_TIMEOUT * BASE_FRAMERATE);
		dropped.touch = CTFDropFlagTouch;
	}
}

bool(entity ent, gitem_t *it) CTFDrop_Flag =
{
	if (Q_rand() & 1) 
		gi.cprintf(ent, PRINT_HIGH, "Only lusers drop flags.\n");
	else
		gi.cprintf(ent, PRINT_HIGH, "Winners don't drop flags.\n");
	return false;
}

static void(entity ent) CTFFlagThink =
{
	if (ent.solid != SOLID_NOT)
		ent.s.frame = 173 + (((ent.s.frame - 173) + 1) % 16);
	ent.nextthink = level.framenum + 1;
}

void(entity ent) CTFFlagSetup =
{
	ent.mins = [ -15, -15, -15 ];
	ent.maxs = [ 15, 15, 15 ];

	if (ent.model)
		gi.setmodel (ent, ent.model);
	else
		gi.setmodel (ent, ent.item->world_model);

	ent.solid = SOLID_TRIGGER;
	ent.movetype = MOVETYPE_TOSS;  
	ent.touch = Touch_Item;

	vector dest = ent.s.origin;
	dest[2] += -128;

	trace_t tr;
	gi.trace(&tr, ent.s.origin, ent.mins, ent.maxs, dest, ent, MASK_SOLID);

	if (tr.startsolid)
	{
		gi.dprintf ("CTFFlagSetup: %s startsolid at %s\n", ent.classname, vtos(ent.s.origin));
		G_FreeEdict (ent);
		return;
	}

	ent.s.origin = tr.endpos;

	gi.linkentity (ent);

	ent.nextthink = level.framenum + 1;
	ent.think = CTFFlagThink;
}

void(entity player) CTFEffects =
{
	player.s.effects &= ~(EF_FLAG1 | EF_FLAG2);
	
	if (player.health > 0)
	{
		if (player.client.pers.inventory[ITEM_FLAG1])
			player.s.effects |= EF_FLAG1;
		if (player.client.pers.inventory[ITEM_FLAG2])
			player.s.effects |= EF_FLAG2;
	}

	if (player.client.pers.inventory[ITEM_FLAG1])
		player.s.modelindex3 = gi.modelindex("players/male/flag1.md2");
	else if (player.client.pers.inventory[ITEM_FLAG2])
		player.s.modelindex3 = gi.modelindex("players/male/flag2.md2");
	else
		player.s.modelindex3 = 0;
}

// called when we enter the intermission
void() CTFCalcScores =
{
	ctfgame.total1 = ctfgame.total2 = 0;

	for (int i = 1; i <= game.maxclients; i++)
	{
		entity player = itoe(i);

		if !(player.inuse)
			continue;

		if (player.client.resp.ctf_team == CTF_TEAM1)
			ctfgame.total1 += player.client.resp.score;
		else if (player.client.resp.ctf_team == CTF_TEAM2)
			ctfgame.total2 += player.client.resp.score;
	}
}

void(entity ent) CTFID_f =
{
	if (ent.client.resp.id_state)
		gi.cprintf(ent, PRINT_HIGH, "Disabling player identication display.\n");
	else
		gi.cprintf(ent, PRINT_HIGH, "Activating player identication display.\n");

	ent.client.resp.id_state = !ent.client.resp.id_state;
}

static void(entity ent) CTFSetIDView =
{
	// only check every few frames
	if (level.framenum - ent.client.resp.lastidframe < (0.25 * BASE_FRAMERATE))
		return;
	ent.client.resp.lastidframe = level.framenum;

	ent.client.ps.stats[STAT_CTF_ID_VIEW] = 0;
	ent.client.ps.stats[STAT_CTF_ID_VIEW_COLOR] = 0;

	vector forward;
	AngleVectors(ent.client.v_angle, &forward, 0, 0);
	vector end = ent.s.origin + (forward * 1024);
	trace_t	tr;
	gi.traceline(&tr, ent.s.origin, end, ent, MASK_SOLID);
	if (tr.fraction < 1 && tr.ent && tr.ent.is_client)
	{
		ent.client.ps.stats[STAT_CTF_ID_VIEW] = CS_GENERAL + (tr.ent.s.number - 1);
		if (tr.ent.client.resp.ctf_team == CTF_TEAM1)
			ent.client.ps.stats[STAT_CTF_ID_VIEW_COLOR] = imageindex_sbfctf1;
		else if (tr.ent.client.resp.ctf_team == CTF_TEAM2)
			ent.client.ps.stats[STAT_CTF_ID_VIEW_COLOR] = imageindex_sbfctf2;
		return;
	}

	entity best = 0;
	float bd = 0;

	for (int i = 1; i <= game.maxclients; i++)
	{
		entity who = itoe(i);
		if (!who.inuse || who.solid == SOLID_NOT)
			continue;
		vector dir = who.s.origin - ent.s.origin;
		VectorNormalize(dir);
		float d = forward * dir;
		if (d > bd && loc_CanSee(ent, who))
		{
			bd = d;
			best = who;
		}
	}

	if (bd > 0.90)
	{
		ent.client.ps.stats[STAT_CTF_ID_VIEW] = CS_GENERAL + (best.s.number - 1);
		if (best.client.resp.ctf_team == CTF_TEAM1)
			ent.client.ps.stats[STAT_CTF_ID_VIEW_COLOR] = imageindex_sbfctf1;
		else if (best.client.resp.ctf_team == CTF_TEAM2)
			ent.client.ps.stats[STAT_CTF_ID_VIEW_COLOR] = imageindex_sbfctf2;
	}
}

void(entity ent) SetCTFStats =
{
	if (ctfgame.warnactive)
		ent.client.ps.stats[STAT_CTF_TEAMINFO] = CONFIG_CTF_TEAMINFO;
	else
		ent.client.ps.stats[STAT_CTF_TEAMINFO] = 0;

	// logo headers for the frag display
	ent.client.ps.stats[STAT_CTF_TEAM1_HEADER] = imageindex_ctfsb1;
	ent.client.ps.stats[STAT_CTF_TEAM2_HEADER] = imageindex_ctfsb2;

	// if during intermission, we must blink the team header of the winning team
	if (level.intermission_framenum && (level.framenum & 8)) // blink 1/8th second
	{
		// note that ctfgame.total[12] is set when we go to intermission
		if (ctfgame.team1 > ctfgame.team2)
			ent.client.ps.stats[STAT_CTF_TEAM1_HEADER] = 0;
		else if (ctfgame.team2 > ctfgame.team1)
			ent.client.ps.stats[STAT_CTF_TEAM2_HEADER] = 0;
		else if (ctfgame.total1 > ctfgame.total2) // frag tie breaker
			ent.client.ps.stats[STAT_CTF_TEAM1_HEADER] = 0;
		else if (ctfgame.total2 > ctfgame.total1) 
			ent.client.ps.stats[STAT_CTF_TEAM2_HEADER] = 0;
		else
		{ // tie game!
			ent.client.ps.stats[STAT_CTF_TEAM1_HEADER] = 0;
			ent.client.ps.stats[STAT_CTF_TEAM2_HEADER] = 0;
		}
	}

	// tech icon
	int i = 0;
	ent.client.ps.stats[STAT_CTF_TECH] = 0;

	while (i < techids.length)
	{
		gitem_t *tech = GetItemByIndex(techids[i]);
		if (tech && ent.client.pers.inventory[tech.id])
		{
			ent.client.ps.stats[STAT_CTF_TECH] = gi.imageindex(tech->icon);
			break;
		}
		i++;
	}

	// figure out what icon to display for team logos
	// three states:
	//   flag at base
	//   flag taken
	//   flag dropped
	int p1 = imageindex_i_ctf1;
	entity e = G_Find(world, classname, "item_flag_team1");
	if (e)
	{
		if (e.solid == SOLID_NOT)
		{
			// not at base
			// check if on player
			p1 = imageindex_i_ctf1d; // default to dropped
			for (int i = 1; i <= game.maxclients; i++)
			{
				entity e = itoe(i);
				if (e.inuse && e.client.pers.inventory[ITEM_FLAG1])
				{
					// enemy has it
					p1 = imageindex_i_ctf1t;
					break;
				}
			}
		}
		else if (e.spawnflags & DROPPED_ITEM)
			p1 = imageindex_i_ctf1d; // must be dropped
	}
	int p2 = imageindex_i_ctf2;
	e = G_Find(world, classname, "item_flag_team2");
	if (e)
	{
		if (e.solid == SOLID_NOT)
		{
			// not at base
			// check if on player
			p2 = imageindex_i_ctf2d; // default to dropped
			for (int i = 1; i <= game.maxclients; i++)
			{
				entity e = itoe(i);
				if (e.inuse && e.client.pers.inventory[ITEM_FLAG2])
				{
					// enemy has it
					p2 = imageindex_i_ctf2t;
					break;
				}
			}
		}
		else if (e->spawnflags & DROPPED_ITEM)
			p2 = imageindex_i_ctf2d; // must be dropped
	}

	ent.client.ps.stats[STAT_CTF_TEAM1_PIC] = p1;
	ent.client.ps.stats[STAT_CTF_TEAM2_PIC] = p2;

	if (ctfgame.last_flag_capture_framenum && level.framenum - ctfgame.last_flag_capture_framenum < (5 * BASE_FRAMERATE))
	{
		if (ctfgame.last_capture_team == CTF_TEAM1)
			if (level.framenum & 8)
				ent.client.ps.stats[STAT_CTF_TEAM1_PIC] = p1;
			else
				ent.client.ps.stats[STAT_CTF_TEAM1_PIC] = 0;
		else
			if (level.framenum & 8)
				ent.client.ps.stats[STAT_CTF_TEAM2_PIC] = p2;
			else
				ent.client.ps.stats[STAT_CTF_TEAM2_PIC] = 0;
	}

	ent.client.ps.stats[STAT_CTF_TEAM1_CAPS] = ctfgame.team1;
	ent.client.ps.stats[STAT_CTF_TEAM2_CAPS] = ctfgame.team2;

	ent.client.ps.stats[STAT_CTF_FLAG_PIC] = 0;
	if (ent.client.resp.ctf_team == CTF_TEAM1 &&
		ent.client.pers.inventory[ITEM_FLAG2] &&
		(level.framenum & 8))
		ent.client.ps.stats[STAT_CTF_FLAG_PIC] = imageindex_i_ctf2;
	else if (ent.client.resp.ctf_team == CTF_TEAM2 &&
		ent.client.pers.inventory[ITEM_FLAG1] &&
		(level.framenum & 8))
		ent.client.ps.stats[STAT_CTF_FLAG_PIC] = imageindex_i_ctf1;

	ent.client.ps.stats[STAT_CTF_JOINED_TEAM1_PIC] = 0;
	ent.client.ps.stats[STAT_CTF_JOINED_TEAM2_PIC] = 0;
	if (ent.client.resp.ctf_team == CTF_TEAM1)
		ent.client.ps.stats[STAT_CTF_JOINED_TEAM1_PIC] = imageindex_i_ctfj;
	else if (ent.client.resp.ctf_team == CTF_TEAM2)
		ent.client.ps.stats[STAT_CTF_JOINED_TEAM2_PIC] = imageindex_i_ctfj;

	if (ent.client.resp.id_state)
		CTFSetIDView(ent);
	else
	{
		ent.client.ps.stats[STAT_CTF_ID_VIEW] = 0;
		ent.client.ps.stats[STAT_CTF_ID_VIEW_COLOR] = 0;
	}
}

/*------------------------------------------------------------------------*/

/*QUAKED info_player_team1 (1 0 0) (-16 -16 -24) (16 16 32)
potential team1 spawning position for ctf games
*/
API_FUNC static void(entity self) SP_info_player_team1 =
{
}

/*QUAKED info_player_team2 (0 0 1) (-16 -16 -24) (16 16 32)
potential team2 spawning position for ctf games
*/
API_FUNC static void(entity self) SP_info_player_team2 =
{
}

void(entity ent) CTFTeam_f =
{
	ctfteam_t desired_team;

	string t = strlwr(gi.args());
	if (!t)
	{
		gi.cprintf(ent, PRINT_HIGH, "You are on the %s team.\n",
			CTFTeamName(ent.client.resp.ctf_team));
		return;
	}

	if (t == "red")
		desired_team = CTF_TEAM1;
	else if (t == "blue")
		desired_team = CTF_TEAM2;
	else
	{
		gi.cprintf(ent, PRINT_HIGH, "Unknown team %s.\n", t);
		return;
	}

	if (ent.client.resp.ctf_team == desired_team)
	{
		gi.cprintf(ent, PRINT_HIGH, "You are already on the %s team.\n",
			CTFTeamName(ent.client.resp.ctf_team));
		return;
	}

	ent.svflags = 0;
	ent.flags &= ~FL_GODMODE;
	ent.client.resp.ctf_team = desired_team;
	ent.client.resp.ctf_state = 0;
	CTFAssignSkin(ent, Info_ValueForKey (ent.client.pers.userinfo, "skin"));

	if (ent.solid == SOLID_NOT) // spectator
	{
		PutClientInServer(ent);
		// add a teleportation effect
		ent.s.event = EV_PLAYER_TELEPORT;
		// hold in place briefly
		ent.client.ps.pmove.pm_flags = PMF_TIME_TELEPORT;
		ent.client.ps.pmove.pm_time = 14;
		gi.bprintf(PRINT_HIGH, "%s joined the %s team.\n",
			ent.client.pers.netname, CTFTeamName(desired_team));
		return;
	}

	ent.health = 0;
	player_die (ent, ent, ent, 100000, vec3_origin);
	// don't even bother waiting for death frames
	ent.deadflag = DEAD_DEAD;
	respawn (ent);

	ent.client.resp.score = 0;

	gi.bprintf(PRINT_HIGH, "%s changed to the %s team.\n",
		ent.client.pers.netname, CTFTeamName(desired_team));
}

typedef struct
{
	int	scores[MAX_CLIENTS];
} ctfscores_t;

/*
==================
CTFScoreboardMessage
==================
*/
void(entity ent, entity killer) CTFScoreboardMessage =
{
	string	entry;
	string	str;
	int		len;
	int		i, j, k, n;
	ctfscores_t		sorted[2] = { { }, { } };
	ctfscores_t		sortedscores[2] = { { }, { } };
	int		score, total[2], totalscore[2];
	int		last[2];
	ctfteam_t team = 0;

	// sort the clients by team and score
	total[0] = total[1] = 0;
	last[0] = last[1] = 0;
	totalscore[0] = totalscore[1] = 0;
	for (i = 0; i < game.maxclients; i++)
	{
		entity cl_ent = itoe(1 + i);
		if (!cl_ent.inuse)
			continue;
		if (cl_ent.client.resp.ctf_team == CTF_TEAM1)
			team = 0;
		else if (cl_ent.client.resp.ctf_team == CTF_TEAM2)
			team = 1;
		else
			continue; // unknown team?

		score = cl_ent.client.resp.score;
		for (j=0 ; j<total[team] ; j++)
		{
			if (score > sortedscores[team].scores[j])
				break;
		}
		for (k=total[team] ; k>j ; k--)
		{
			sorted[team].scores[k] = sorted[team].scores[k-1];
			sortedscores[team].scores[k] = sortedscores[team].scores[k-1];
		}
		sorted[team].scores[j] = i;
		sortedscores[team].scores[j] = score;
		totalscore[team] += score;
		total[team]++;
	}

	// print level name and exit rules
	// add the clients in sorted order
	str = 0;
	len = 0;

	// team one
	str = va("if " STAT(STAT_CTF_TEAM1_HEADER) " xv 8 yv 8 pic " STAT(STAT_CTF_TEAM1_HEADER) " endif "
		"xv 40 yv 28 string \"%4d/%-3d\" "
		"xv 98 yv 12 num 2 " STAT(STAT_CTF_TEAM1_CAPS) " "
		"if " STAT(STAT_CTF_TEAM2_HEADER) " xv 168 yv 8 pic " STAT(STAT_CTF_TEAM2_HEADER) " endif "
		"xv 200 yv 28 string \"%4d/%-3d\" "
		"xv 256 yv 12 num 2 " STAT(STAT_CTF_TEAM2_CAPS) " ",
		totalscore[0], total[0],
		totalscore[1], total[1]);
	len = strlen(str);

	for (i=0 ; i<16 ; i++)
	{
		if (i >= total[0] && i >= total[1])
			break; // we're done

		entry = 0;

		// left side
		if (i < total[0])
		{
			entity cl = itoe(sorted[0].scores[i] + 1);

			entry = strconcat(entry, va(
				"ctf 0 %d %d %d %d ",
				42 + i * 8,
				sorted[0].scores[i],
				cl.client.resp.score,
				cl.client.ping > 999 ? 999 : cl.client.ping));

			if (cl.client.pers.inventory[ITEM_FLAG2])
				entry = strconcat(entry, va("xv 56 yv %d picn sbfctf2 ", 42 + i * 8));

			if (MESSAGE_LIMIT - len > strlen(entry))
			{
				str = strconcat(str, entry);
				len = strlen(str);
				last[0] = i;
			}
		}

		// right side
		if (i < total[1])
		{
			entity cl = itoe(sorted[1].scores[i] + 1);

			entry = strconcat(entry, va(
				"ctf 160 %d %d %d %d ",
				42 + i * 8,
				sorted[1].scores[i],
				cl.client.resp.score,
				cl.client.ping > 999 ? 999 : cl.client.ping));

			if (cl.client.pers.inventory[ITEM_FLAG1])
				entry = strconcat(entry, va("xv 216 yv %d picn sbfctf1 ",
					42 + i * 8));

			if (MESSAGE_LIMIT - len > strlen(entry))
			{
				str = strconcat(str, entry);
				len = strlen(str);
				last[1] = i;
			}
		}
	}

	// put in spectators if we have enough room
	if (last[0] > last[1])
		j = last[0];
	else
		j = last[1];
	j = (j + 2) * 8 + 42;

	k = n = 0;
	entry = 0;

	if (MESSAGE_LIMIT - len > 50)
	{
		for (i = 0; i < game.maxclients; i++)
		{
			entity cl_ent = itoe(1 + i);

			if (!cl_ent.inuse ||
				cl_ent.solid != SOLID_NOT ||
				cl_ent.client.resp.ctf_team != CTF_NOTEAM)
				continue;

			if (!k)
			{
				k = 1;
				entry = va("xv 0 yv %d string2 \"Spectators\" ", j);
				str = strconcat(str, entry);
				len = strlen(str);
				j += 8;
			}

			entry = strconcat(entry, va(
				"ctf %d %d %d %d %d ",
				(n & 1) ? 160 : 0, // x
				j, // y
				i, // playernum
				cl_ent.client.resp.score,
				cl_ent.client.ping > 999 ? 999 : cl_ent.client.ping));

			if (MESSAGE_LIMIT - len > strlen(entry))
			{
				str = strconcat(str, entry);
				len = strlen(str);
			}
			
			if (n & 1)
				j += 8;
			n++;
		}
	}

	if (total[0] - last[0] > 1) // couldn't fit everyone
		str = strconcat(str, va("xv 8 yv %d string \"..and %d more\" ",
			42 + (last[0]+1)*8, total[0] - last[0] - 1));
	if (total[1] - last[1] > 1) // couldn't fit everyone
		str = strconcat(str, va("xv 168 yv %d string \"..and %d more\" ",
			42 + (last[1]+1)*8, total[1] - last[1] - 1));

	gi.WriteByte (svc_layout);
	gi.WriteString (str);
}


/*------------------------------------------------------------------------*/
/* TECH																	  */
/*------------------------------------------------------------------------*/

void(entity who) CTFHasTech =
{
	if (level.framenum - who.client.ctf_lasttechframenum > (2 * BASE_FRAMERATE))
	{
		gi.centerprintf(who, "You already have a TECH powerup.");
		who.client.ctf_lasttechframenum = level.time;
	}
}

gitem_t *(entity ent) CTFWhat_Tech =
{
	int i = 0;
	while (i < techids.length)
	{
		gitem_t *tech = GetItemByIndex(techids[i]);
		if (tech && ent.client.pers.inventory[tech.id])
			return tech;
		i++;
	}
	return 0;
}

bool(entity ent, entity other) CTFPickup_Tech =
{
	int i = 0;
	while (i < techids.length)
	{
		gitem_t *tech = GetItemByIndex(techids[i]);
		if (tech && other.client.pers.inventory[tech.id])
		{
			CTFHasTech(other);
			return false; // has this one
		}
		i++;
	}
	
	// client only gets one tech
	other.client.pers.inventory[ent.item->id]++;
	other.client.ctf_regenframenum = level.framenum;

	return true;
}

static entity() FindTechSpawn =
{
	entity spot = 0;
	int i = Q_rand() % 16;

	while (i--)
		spot = G_Find (spot, classname, "info_player_deathmatch");
	if (!spot)
		spot = G_Find (spot, classname, "info_player_deathmatch");
	return spot;
}

static void(gitem_t *, entity) SpawnTech;

static void(entity tech) TechThink =
{
	entity spot = FindTechSpawn();

	if (spot)
	{
		SpawnTech(tech.item, spot);
		G_FreeEdict(tech);
	}
	else
	{
		tech.nextthink = level.framenum + (CTF_TECH_TIMEOUT * BASE_FRAMERATE);
		tech.think = TechThink;
	}
}

void(entity ent, gitem_t *item) CTFDrop_Tech =
{
	entity tech = Drop_Item(ent, item);
	tech.nextthink = level.framenum + (CTF_TECH_TIMEOUT * BASE_FRAMERATE);
	tech.think = TechThink;
	ent.client.pers.inventory[item.id] = 0;
}

void(entity ent) CTFDeadDropTech =
{
	int i = 0;
	while (i < techids.length)
	{
		gitem_t *tech = GetItemByIndex(techids[i]);
		if (tech && ent.client.pers.inventory[tech.id])
		{
			entity dropped = Drop_Item(ent, tech);
			// hack the velocity to make it bounce random
			dropped.velocity[0] = random(-300.0, 300.0);
			dropped.velocity[1] = random(-300.0, 300.0);
			dropped.nextthink = level.framenum + (CTF_TECH_TIMEOUT * BASE_FRAMERATE);
			dropped.think = TechThink;
			dropped.owner = 0;
			ent.client.pers.inventory[tech.id] = 0;
		}
		i++;
	}
}

static void(gitem_t *it, entity spot) SpawnTech =
{
	entity ent = G_Spawn();

	ent.classname = it->classname;
	ent.item = it;
	ent.spawnflags = DROPPED_ITEM;
	ent.s.effects = it->world_model_flags;
	ent.s.renderfx = RF_GLOW;
	ent->mins = [ -15, -15, -15 ];
	ent->maxs = [ 15, 15, 15 ];
	gi.setmodel (ent, ent.item->world_model);
	ent.solid = SOLID_TRIGGER;
	ent.movetype = MOVETYPE_TOSS;  
	ent.touch = Touch_Item;
	ent.owner = ent;

	vector angles = [ 0, random(360.0), 0 ];
	vector forward, right;
	AngleVectors (angles, &forward, &right, 0);
	ent.s.origin = spot.s.origin;
	ent.s.origin[2] += 16;
	ent.velocity = forward * 100;
	ent.velocity[2] = 300;

	ent.nextthink = level.framenum + (CTF_TECH_TIMEOUT * BASE_FRAMERATE);
	ent.think = TechThink;

	gi.linkentity (ent);
}

static void(entity ent) SpawnTechs =
{
	int i = 0;
	while (i < techids.length)
	{
		gitem_t *tech = GetItemByIndex(techids[i]);
		entity spot = FindTechSpawn();
		if (tech && spot)
			SpawnTech(tech, spot);
		i++;
	}
	if (ent)
		G_FreeEdict(ent);
}

// frees the passed edict!
void(entity ent) CTFRespawnTech =
{
	entity spot = FindTechSpawn();
	if (spot)
		SpawnTech(ent.item, spot);
	G_FreeEdict(ent);
}

void() CTFSetupTechSpawn =
{
	if (dmflags->intVal & DF_CTF_NO_TECH)
		return;

	entity ent = G_Spawn();
	ent.nextthink = level.framenum + (2 * BASE_FRAMERATE);
	ent.think = SpawnTechs;
}

void() CTFResetTech =
{
	for (int i = 1; i < globals.num_edicts; i++)
	{
		entity ent = itoe(i);

		if (ent.inuse && ent.item && (ent.item->flags & IT_TECH))
			G_FreeEdict(ent);
	}

	SpawnTechs(0);
}

int(entity ent, int dmg) CTFApplyResistance =
{
	float volume = 1.0;

	if (ent.is_client && ent.client.silencer_shots)
		volume = 0.2;

	if (dmg && ent.is_client && ent.client.pers.inventory[ITEM_TECH1])
	{
		// make noise
	   	gi.sound(ent, CHAN_VOICE, gi.soundindex("ctf/tech1.wav"), volume, ATTN_NORM, 0);
		return dmg / 2;
	}
	return dmg;
}

int(entity ent, int dmg) CTFApplyStrength =
{
	if (dmg && ent.is_client && ent.client.pers.inventory[ITEM_TECH2])
		return dmg * 2;
	return dmg;
}

bool(entity ent) CTFApplyStrengthSound =
{
	float volume = 1.0;

	if (ent->is_client && ent.client.silencer_shots)
		volume = 0.2;

	if (ent.is_client && ent.client.pers.inventory[ITEM_TECH2])
	{
		if (ent.client.ctf_techsndframenum < level.framenum)
		{
			ent.client.ctf_techsndframenum = level.framenum + (1 * BASE_FRAMERATE);
			if (ent.client.quad_framenum > level.framenum)
				gi.sound(ent, CHAN_VOICE, gi.soundindex("ctf/tech2x.wav"), volume, ATTN_NORM, 0);
			else
				gi.sound(ent, CHAN_VOICE, gi.soundindex("ctf/tech2.wav"), volume, ATTN_NORM, 0);
		}
		return true;
	}
	return false;
}


inline bool(entity ent) CTFApplyHaste =
{
	return ent.is_client && ent.client.pers.inventory[ITEM_TECH3];
}

void(entity ent) CTFApplyHasteSound =
{
	float volume = 1.0;

	if (ent.is_client && ent.client.silencer_shots)
		volume = 0.2;

	if (ent.is_client &&
		ent.client.pers.inventory[ITEM_TECH3] &&
		ent.client.ctf_techsndframenum < level.framenum)
	{
		ent.client.ctf_techsndframenum = level.framenum + (1 * BASE_FRAMERATE);
		gi.sound(ent, CHAN_VOICE, gi.soundindex("ctf/tech3.wav"), volume, ATTN_NORM, 0);
	}
}

void(entity ent) CTFApplyRegeneration =
{
	bool noise = false;
	float volume = 1.0;

	if (!ent.is_client)
		return;

	if (ent.client.silencer_shots)
		volume = 0.2;

	if (ent.client.pers.inventory[ITEM_TECH4])
	{
		if (ent.client.ctf_regenframenum < level.framenum)
		{
			ent.client.ctf_regenframenum = level.framenum;
			if (ent.health < 150)
			{
				ent.health += 5;
				if (ent.health > 150)
					ent.health = 150;
				ent.client.ctf_regenframenum += (0.5 * BASE_FRAMERATE);
				noise = true;
			}
			gitem_id_t index = ArmorIndex (ent);
			if (index && ent.client.pers.inventory[index] < 150)
			{
				ent.client.pers.inventory[index] += 5;
				if (ent.client.pers.inventory[index] > 150)
					ent.client.pers.inventory[index] = 150;
				ent.client.ctf_regenframenum += (0.5 * BASE_FRAMERATE);
				noise = true;
			}
		}
		if (noise && ent.client.ctf_techsndframenum < level.framenum)
		{
			ent.client.ctf_techsndframenum = level.framenum + (1 * BASE_FRAMERATE);
			gi.sound(ent, CHAN_VOICE, gi.soundindex("ctf/tech4.wav"), volume, ATTN_NORM, 0);
		}
	}
}

inline bool(entity ent) CTFHasRegeneration =
{
	return ent.is_client && ent.client.pers.inventory[ITEM_TECH4];
}


/*-----------------------------------------------------------------------*/
/*QUAKED misc_ctf_banner (1 .5 0) (-4 -64 0) (4 64 248) TEAM2
The origin is the bottom of the banner.
The banner is 248 tall.
*/
static void(entity ent) misc_ctf_banner_think =
{
	ent.s.frame = (ent.s.frame + 1) % 16;
	ent.nextthink = level.framenum + 1;
}

API_FUNC static void(entity ent) SP_misc_ctf_banner =
{
	ent.movetype = MOVETYPE_NONE;
	ent.solid = SOLID_NOT;
	ent.s.modelindex = gi.modelindex ("models/ctf/banner/tris.md2");
	if (ent.spawnflags & 1) // team2
		ent.s.skinnum = 1;

	ent.s.frame = Q_rand() % 16;
	gi.linkentity (ent);

	ent.think = misc_ctf_banner_think;
	ent.nextthink = level.framenum + 1;
}

/*QUAKED misc_ctf_small_banner (1 .5 0) (-4 -32 0) (4 32 124) TEAM2
The origin is the bottom of the banner.
The banner is 124 tall.
*/
API_FUNC static void(entity ent) SP_misc_ctf_small_banner =
{
	ent.movetype = MOVETYPE_NONE;
	ent.solid = SOLID_NOT;
	ent.s.modelindex = gi.modelindex ("models/ctf/banner/small.md2");
	if (ent.spawnflags & 1) // team2
		ent.s.skinnum = 1;

	ent.s.frame = Q_rand() % 16;
	gi.linkentity (ent);

	ent.think = misc_ctf_banner_think;
	ent.nextthink = level.framenum + 1;
}

/*-----------------------------------------------------------------------*/

static INLINE void(pmenu_t *p) SetLevelName =
{
	p->text = strconcat("*", world.message ? world.message : level.mapname);
};

static var pmenu_t creditsmenu[18];

static const int jmenu_level = 2;
static const int jmenu_match = 3;
static const int jmenu_red = 5;
static const int jmenu_blue = 7;
static const int jmenu_chase = 9;
static const int jmenu_reqmatch = 11;

void(entity ent, ctfteam_t desired_team) CTFJoinTeam =
{
	PMenu_Close(ent);

	ent.svflags &= ~SVF_NOCLIENT;
	ent.client.resp.ctf_team = desired_team;
	ent.client.resp.ctf_state = 0;
	CTFAssignSkin(ent, Info_ValueForKey (ent.client.pers.userinfo, "skin"));

	PutClientInServer (ent);
	// add a teleportation effect
	ent.s.event = EV_PLAYER_TELEPORT;
	// hold in place briefly
	ent.client.ps.pmove.pm_flags = PMF_TIME_TELEPORT;
	ent.client.ps.pmove.pm_time = 14;
	gi.bprintf(PRINT_HIGH, "%s joined the %s team.\n",
		ent.client.pers.netname, CTFTeamName(desired_team));
};

void(entity ent) CTFJoinTeam1 =
{
	CTFJoinTeam(ent, CTF_TEAM1);
};

void(entity ent) CTFJoinTeam2 =
{
	CTFJoinTeam(ent, CTF_TEAM2);
};

static var pmenu_t nochasemenu[7];

void(entity ent) CTFChaseCam =
{
	if (ent.client.chase_target)
	{
		ent.client.chase_target = 0;
		ent.client.ps.pmove.pm_flags &= ~PMF_NO_PREDICTION;
		PMenu_Close(ent);
		return;
	}

	for (int i = 1; i <= game.maxclients; i++)
	{
		entity e = itoe(i);
		if (e.inuse && e.solid != SOLID_NOT)
		{
			ent.client.chase_target = e;
			PMenu_Close(ent);
			ent.client.update_chase = true;
			return;
		}
	}

	SetLevelName(nochasemenu + jmenu_level);

	PMenu_Close(ent);
	PMenu_Open(ent, nochasemenu, nochasemenu.length);
}

static var pmenu_t joinmenu[18];

int(entity ent) CTFUpdateJoinMenu =
{
	static string team1players;
	static string team2players;
	int num1, num2, i;

	joinmenu[jmenu_red].text = "Join Red Team";
	joinmenu[jmenu_blue].text = "Join Blue Team";
	joinmenu[jmenu_red].func = CTFJoinTeam1;
	joinmenu[jmenu_blue].func = CTFJoinTeam2;

	if (ent.client.chase_target)
		joinmenu[jmenu_chase].text = "Leave Chase Camera";
	else
		joinmenu[jmenu_chase].text = "Chase Camera";

	SetLevelName(joinmenu + jmenu_level);

	num1 = num2 = 0;
	for (i = 0; i < game.maxclients; i++)
	{
		entity e = itoe(i + 1);
		if (!e.inuse)
			continue;
		if (e.client.resp.ctf_team == CTF_TEAM1)
			num1++;
		else if (e.client.resp.ctf_team == CTF_TEAM2)
			num2++;
	}

	team1players = va("  (%d players)", num1);
	team2players = va("  (%d players)", num2);

	if (joinmenu[jmenu_red].text)
		joinmenu[jmenu_red+1].text = team1players;
	else
		joinmenu[jmenu_red+1].text = 0;

	if (joinmenu[jmenu_blue].text)
		joinmenu[jmenu_blue+1].text = team2players;
	else
		joinmenu[jmenu_blue+1].text = 0;

	joinmenu[jmenu_reqmatch].text = 0;
	joinmenu[jmenu_reqmatch].func = 0;
	
	if (num1 > num2)
		return CTF_TEAM1;
	else if (num2 > num1)
		return CTF_TEAM2;
	return (Q_rand() & 1) ? CTF_TEAM1 : CTF_TEAM2;
};

void(entity ent) CTFOpenJoinMenu =
{
	int team = CTFUpdateJoinMenu(ent);
	if (ent.client.chase_target)
		team = 8;
	else if (team == CTF_TEAM1)
		team = 4;
	else
		team = 6;
	PMenu_Open(ent, joinmenu, joinmenu.length, team);
};

void(entity ent) CTFCredits =
{
	PMenu_Close(ent);
	PMenu_Open(ent, creditsmenu, creditsmenu.length);
};

static var pmenu_t joinmenu[18] = {
	{ "*Quake II",			PMENU_ALIGN_CENTER },
	{ "*ThreeWave Capture the Flag",	PMENU_ALIGN_CENTER },
	{ 0,					PMENU_ALIGN_CENTER },
	{ 0,					PMENU_ALIGN_CENTER },
	{ 0,					PMENU_ALIGN_CENTER },
	{ "Join Red Team",		PMENU_ALIGN_LEFT, CTFJoinTeam1 },
	{ 0,					PMENU_ALIGN_LEFT },
	{ "Join Blue Team",		PMENU_ALIGN_LEFT, CTFJoinTeam2 },
	{ 0,					PMENU_ALIGN_LEFT },
	{ "Chase Camera",		PMENU_ALIGN_LEFT, CTFChaseCam },
	{ "Credits",			PMENU_ALIGN_LEFT, CTFCredits },
	{ 0,					PMENU_ALIGN_LEFT },
	{ 0,					PMENU_ALIGN_LEFT },
	{ "Use [ and ] to move cursor",	PMENU_ALIGN_LEFT },
	{ "ENTER to select",	PMENU_ALIGN_LEFT },
	{ "ESC to Exit Menu",	PMENU_ALIGN_LEFT },
	{ "(TAB to Return)",	PMENU_ALIGN_LEFT },
	{ "v" CTF_VERSION,	PMENU_ALIGN_RIGHT }
};

void(entity ent) CTFReturnToMain =
{
	PMenu_Close(ent);
	CTFOpenJoinMenu(ent);
};

static var pmenu_t nochasemenu[7] = {
	{ "*Quake II",			PMENU_ALIGN_CENTER },
	{ "*ThreeWave Capture the Flag",	PMENU_ALIGN_CENTER },
	{ 0,					PMENU_ALIGN_CENTER },
	{ 0,					PMENU_ALIGN_CENTER },
	{ "No one to chase",	PMENU_ALIGN_LEFT },
	{ 0,					PMENU_ALIGN_CENTER },
	{ "Return to Main Menu", PMENU_ALIGN_LEFT, CTFReturnToMain }
};

static var pmenu_t creditsmenu[18] = {
	{ "*Quake II",						PMENU_ALIGN_CENTER },
	{ "*ThreeWave Capture the Flag",	PMENU_ALIGN_CENTER },
	{ 0,								PMENU_ALIGN_CENTER },
	{ "*Programming",					PMENU_ALIGN_CENTER }, 
	{ "Dave 'Zoid' Kirsch",				PMENU_ALIGN_CENTER },
	{ "*Level Design", 					PMENU_ALIGN_CENTER },
	{ "Christian Antkow",				PMENU_ALIGN_CENTER },
	{ "Tim Willits",					PMENU_ALIGN_CENTER },
	{ "Dave 'Zoid' Kirsch",				PMENU_ALIGN_CENTER },
	{ "*Art",							PMENU_ALIGN_CENTER },
	{ "Adrian Carmack Paul Steed",		PMENU_ALIGN_CENTER },
	{ "Kevin Cloud",					PMENU_ALIGN_CENTER },
	{ "*Sound",							PMENU_ALIGN_CENTER },
	{ "Tom 'Bjorn' Klok",				PMENU_ALIGN_CENTER },
	{ "*Original CTF Art Design",		PMENU_ALIGN_CENTER },
	{ "Brian 'Whaleboy' Cozzens",		PMENU_ALIGN_CENTER },
	{ 0,								PMENU_ALIGN_CENTER },
	{ "Return to Main Menu",			PMENU_ALIGN_LEFT, CTFReturnToMain }
};

bool(entity ent) CTFStartClient =
{
	if (!ctf.intVal || ent.client.resp.ctf_team != CTF_NOTEAM)
		return false;

	if !(dmflags.intVal & DF_CTF_FORCEJOIN)
	{
		// start as 'observer'
		ent.movetype = MOVETYPE_NOCLIP;
		ent.solid = SOLID_NOT;
		ent.svflags |= SVF_NOCLIENT;
		ent.client.resp.ctf_team = CTF_NOTEAM;
		ent.client.ps.gunindex = 0;
		gi.linkentity (ent);

		CTFOpenJoinMenu(ent);
		return true;
	}
	return false;
}

void(entity ent) CTFObserver =
{
	string userinfo;

	// start as 'observer'
#ifdef HOOK_CODE
	GrapplePlayerReset(ent);
#endif
	CTFDeadDropFlag(ent);
	CTFDeadDropTech(ent);

	ent.deadflag = DEAD_NO;
	ent.movetype = MOVETYPE_NOCLIP;
	ent.solid = SOLID_NOT;
	ent.svflags |= SVF_NOCLIENT;
	ent.client.resp.ctf_team = CTF_NOTEAM;
	ent.client.ps.gunindex = 0;
	ent.client.resp.score = 0;
	userinfo = ent.client.pers.userinfo;
	InitClientPersistant(ent);
	ClientUserinfoChanged(ent, userinfo);
	gi.linkentity(ent);
	CTFOpenJoinMenu(ent);
}

void() CTFResetAllPlayers =
{
	for (int i = 1; i <= game.maxclients; i++)
	{
		entity ent = itoe(i);
		if (!ent.inuse)
			continue;

		if (ent.client.menu.open)
			PMenu_Close(ent);

#ifdef HOOK_CODE
		GrapplePlayerReset(ent);
#endif
		CTFDeadDropFlag(ent);
		CTFDeadDropTech(ent);

		ent.client.resp.ctf_team = CTF_NOTEAM;

		ent.svflags = 0;
		ent.flags &= ~FL_GODMODE;
		PutClientInServer(ent);
	}

	// reset the level
	CTFResetTech();
	CTFResetFlags();

	for (int i = 1 + game.maxclients; i < globals.num_edicts; i++)
	{
		entity ent = itoe(i);
		if (ent.inuse)
		{
			if (ent.solid == SOLID_NOT && ent.think == DoRespawn &&
				ent.nextthink >= level.framenum)
			{
				ent.nextthink = 0;
				DoRespawn(ent);
			}
		}
	}
}

// from main.qc
void() EndDMLevel;

void() CTFEndMatch =
{
	gi.bprintf(PRINT_CHAT, "MATCH COMPLETED!\n");

	CTFCalcScores();

	gi.bprintf(PRINT_HIGH, "RED TEAM:  %d captures, %d points\n",
		ctfgame.team1, ctfgame.total1);
	gi.bprintf(PRINT_HIGH, "BLUE TEAM:  %d captures, %d points\n",
		ctfgame.team2, ctfgame.total2);

	if (ctfgame.team1 > ctfgame.team2)
		gi.bprintf(PRINT_CHAT, "RED team won over the BLUE team by %d CAPTURES!\n",
			ctfgame.team1 - ctfgame.team2);
	else if (ctfgame.team2 > ctfgame.team1)
		gi.bprintf(PRINT_CHAT, "BLUE team won over the RED team by %d CAPTURES!\n",
			ctfgame.team2 - ctfgame.team1);
	else if (ctfgame.total1 > ctfgame.total2) // frag tie breaker
		gi.bprintf(PRINT_CHAT, "RED team won over the BLUE team by %d POINTS!\n",
			ctfgame.total1 - ctfgame.total2);
	else if (ctfgame.total2 > ctfgame.total1) 
		gi.bprintf(PRINT_CHAT, "BLUE team won over the RED team by %d POINTS!\n",
			ctfgame.total2 - ctfgame.total1);
	else
		gi.bprintf(PRINT_CHAT, "TIE GAME!\n");

	EndDMLevel();
}

bool() CTFCheckRules =
{
	int team1 = 0, team2 = 0;

	if (warn_unbalanced.intVal)
	{
		// count up the team totals
		for (int i = 1; i <= game.maxclients; i++)
		{
			entity ent = itoe(i);
			if (!ent.inuse)
				continue;
			if (ent.client.resp.ctf_team == CTF_TEAM1)
				team1++;
			else if (ent.client.resp.ctf_team == CTF_TEAM2)
				team2++;
		}

		if (team1 - team2 >= 2 && team2 >= 2)
		{
			if (ctfgame.warnactive != CTF_TEAM1)
			{
				ctfgame.warnactive = CTF_TEAM1;
				gi.configstring (CONFIG_CTF_TEAMINFO, "WARNING: Red has too many players");
			}
		}
		else if (team2 - team1 >= 2 && team1 >= 2)
		{
			if (ctfgame.warnactive != CTF_TEAM2)
			{
				ctfgame.warnactive = CTF_TEAM2;
				gi.configstring (CONFIG_CTF_TEAMINFO, "WARNING: Blue has too many players");
			}
		}
		else
			ctfgame.warnactive = 0;
	}
	else
		ctfgame.warnactive = 0;

	if (capturelimit.intVal && 
		(ctfgame.team1 >= capturelimit.intVal ||
		ctfgame.team2 >= capturelimit.intVal))
	{
		gi.bprintf (PRINT_HIGH, "Capturelimit hit.\n");
		return true;
	}
	return false;
}

/*--------------------------------------------------------------------------
 * just here to help old map conversions
 *--------------------------------------------------------------------------*/

static void(entity self, entity other, vector plane, csurface_t surf) old_teleporter_touch =
{
	entity	dest;
	vector	forward;

	if (!other.is_client)
		return;
	dest = G_Find (0, targetname, self.target);
	if (!dest)
	{
		gi.dprintf ("Couldn't find destination\n");
		return;
	}

#ifdef HOOK_CODE
	GrapplePlayerReset(other);
#endif

	// unlink to make sure it can't possibly interfere with KillBox
	gi.unlinkentity (other);

	other.s.origin = other.s.old_origin = dest.s.origin;

	// clear the velocity and hold them in place briefly
	other.velocity = vec3_origin;
	other.client.ps.pmove.pm_time = 160>>3;		// hold time
	other.client.ps.pmove.pm_flags |= PMF_TIME_TELEPORT;

	// draw the teleport splash at source and on the player
	self.enemy.s.event = EV_PLAYER_TELEPORT;
	other.s.event = EV_PLAYER_TELEPORT;

	// set angles
	other.client.ps.pmove.delta_angles = dest.s.angles - other.client.resp.cmd_angles;

	other.s.angles[PITCH] = 0;
	other.s.angles[YAW] = dest.s.angles[YAW];
	other.s.angles[ROLL] = 0;
	other.client.ps.viewangles = other.client.v_angle = dest.s.angles;

	// give a little forward velocity
	AngleVectors (other.client.v_angle, &forward, 0, 0);
	other.velocity = forward * 200;

	// kill anything at the destination
	if (!KillBox (other))
	{
	}

	gi.linkentity (other);
}

/*QUAKED trigger_teleport (0.5 0.5 0.5) ?
Players touching this will be teleported
*/
static API_FUNC void(entity ent) SP_trigger_teleport =
{
	if (!ent.target)
	{
		gi.dprintf ("teleporter without a target.\n");
		G_FreeEdict(ent);
		return;
	}

	ent.svflags |= SVF_NOCLIENT;
	ent.solid = SOLID_TRIGGER;
	ent.touch = old_teleporter_touch;
	gi.setmodel (ent, ent.model);
	gi.linkentity (ent);

	// noise maker and splash effect dude
	entity se = G_Spawn();
	ent.enemy = se;
	se.s.origin = ent.mins + (ent.maxs - ent.mins) / 2;
	se.s.sound = gi.soundindex ("world/hum1.wav");
	gi.linkentity(se);
}

/*QUAKED info_teleport_destination (0.5 0.5 0.5) (-16 -16 -24) (16 16 32)
Point trigger_teleports at these.
*/
static API_FUNC void(entity ent) SP_info_teleport_destination =
{
	ent.s.origin[2] += 16;
}

/*-----------------------------------------------------------------------*/

void(entity ent) CTFPlayerList =
{
	int i;
	string st;
	string text;
	entity e2;

	// number, name, connect time, ping, score, admin

	text = 0;
	for (i = 1; i <= game.maxclients; i++)
	{
		e2 = itoe(i);
		if (!e2.inuse)
			continue;

		st = strconcat(va("%3d %-16.16s %02d:%02d %4d %3d\n",
			i,
			e2.client.pers.netname,
			(level.framenum - e2.client.resp.enterframe) / 600,
			((level.framenum - e2.client.resp.enterframe) % 600)/10,
			e2.client.ping,
			e2.client.resp.score));

		if (strlen(text) + strlen(st) > MESSAGE_LIMIT - 50)
		{
			text = strconcat(text, "And more...\n");
			break;
		}

		text = strconcat(text, st);
	}
	gi.cprintf(ent, PRINT_HIGH, "%s", text);
}

#endif