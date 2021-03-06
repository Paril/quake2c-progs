// entity_state_t.renderfx flags
typedef enumflags : int
{
	RF_MINLIGHT,	// allways have some light (viewmodel)
	RF_VIEWERMODEL,	// don't draw through eyes, only mirrors
	RF_WEAPONMODEL,	// only draw through eyes
	RF_FULLBRIGHT,	// always draw full intensity
	RF_DEPTHHACK,	// for view weapon Z crunching
	RF_TRANSLUCENT,
	RF_FRAMELERP,
	RF_BEAM,
	RF_CUSTOMSKIN,	// skin is an index in image_precache
	RF_GLOW,		// pulse lighting for bonus items
	RF_SHELL_RED,
	RF_SHELL_GREEN,
	RF_SHELL_BLUE,

//ROGUE
	RF_IR_VISIBLE		= 0x00008000,
	RF_SHELL_DOUBLE,
	RF_SHELL_HALF_DAM,
	RF_USE_DISGUISE
//ROGUE
} render_effects_t;

// entity_state_t.event values
// ertity events are for effects that take place reletive
// to an existing entities origin.  Very network efficient.
// All muzzle flashes really should be converted to events...
typedef enum : int
{
	EV_NONE,
	EV_ITEM_RESPAWN,
	EV_FOOTSTEP,
	EV_FALLSHORT,
	EV_FALL,
	EV_FALLFAR,
	EV_PLAYER_TELEPORT,
	EV_OTHER_TELEPORT
} entity_event_t;

struct entity_state_t
{
	int			number;
	vector		origin;
	vector		angles;
	vector		old_origin;
	int			modelindex;
	int			modelindex2;
	int			modelindex3;
	int			modelindex4;
#ifdef KMQUAKE2_EXTENSIONS
	int			modelindex5;
	int			modelindex6;
#endif
	int			frame;
	int			skinnum;
#ifdef KMQUAKE2_EXTENSIONS
	float		alpha;
#endif
	entity_effects_t	effects;
	render_effects_t	renderfx;
	int			solid;
	int			sound;
#ifdef KMQUAKE2_EXTENSIONS
	float		attenuation;
#endif
	entity_event_t	event;
};

const int MAX_ENT_CLUSTERS = 16;

// Best not to touch most of these, as they are mapped into Q2's structures.
.entity_state_t	s;

.bool	inuse;
.int	linkcount;

.int	areanum, areanum2;

// edict.svflags
.enumflags : int
{
	SVF_NOCLIENT,		// don't send entity to clients, even if it has effects
	SVF_DEADMONSTER,	// treat as CONTENTS_DEADMONSTER for collision
	SVF_MONSTER			// treat as CONTENTS_MONSTER for collision

#ifdef GROUND_ZERO
	, SVF_DAMAGEABLE
#endif
}		svflags;

.vector	mins, maxs;
.vector	absmin, absmax, size;

.enum : int
{
    SOLID_NOT,		// no interaction with other objects
    SOLID_TRIGGER,	// only touch when inside, after moving
    SOLID_BBOX,		// touch on edge
    SOLID_BSP		// bsp clip, touch on edge
}					solid;
.content_flags_t	clipmask;
.entity				owner;

// game fields below; feel free to modify!
.enum : int
{
	MOVETYPE_NONE,          // never moves
	MOVETYPE_NOCLIP,        // origin and angles change with no interaction
	MOVETYPE_PUSH,          // no clip to world, push on box contact
	MOVETYPE_STOP,          // no clip to world, stops on box contact

	MOVETYPE_WALK,          // gravity
#ifdef SINGLE_PLAYER
	MOVETYPE_STEP,          // gravity, special edge handling
#endif
	MOVETYPE_FLY,
	MOVETYPE_TOSS,          // gravity
	MOVETYPE_FLYMISSILE,    // extra size to monsters
	MOVETYPE_BOUNCE

#ifdef THE_RECKONING
	, MOVETYPE_WALLBOUNCE
#endif
} 		movetype;

// edict.flags
.enumflags : int
{
#ifdef SINGLE_PLAYER
	FL_FLY,
	FL_SWIM,		// implied immunity to drowning
#endif
#if defined(SINGLE_PLAYER)
	FL_NOTARGET,
	FL_PARTIALGROUND,
#endif

	FL_IMMUNE_LASER,
	FL_INWATER,
	FL_GODMODE,
	FL_IMMUNE_SLIME,
	FL_IMMUNE_LAVA,
	FL_WATERJUMP,
	FL_TEAMSLAVE,
	FL_NO_KNOCKBACK,
	FL_POWER_ARMOR,

#ifdef GROUND_ZERO
	FL_MECHANICAL,	// entity is mechanical, use sparks not blood
#ifdef SINGLE_PLAYER
	FL_DISGUISED,	// entity is in disguise, monsters will not recognize.
#endif
	FL_NOGIB,		// player has been vaporized by a nuke, drop no gibs
#endif
	
	FL_RESPAWN

#ifdef SINGLE_PLAYER
#ifdef GROUND_ZERO
	, FL_VISIBLE_MASK = FL_NOTARGET | FL_DISGUISED
#else
	, FL_VISIBLE_MASK = FL_NOTARGET
#endif
#endif
}		flags;

.string	model;
.int	freeframenum;

.string	message;
.string	classname;
.int	spawnflags;

.int	timestamp;
.float	angle;
.string	target;
.string	targetname;
.string	killtarget;
.string	team;
.string	pathtarget;
.string	deathtarget;
.string	combattarget;
.entity	target_ent;

.float	speed, accel, decel;
.vector	movedir;
.vector	pos1, pos2;

.vector	velocity;
.vector	avelocity;
.int	mass;
.int	air_finished_framenum;
.float	gravity;

.entity	goalentity;
.entity	movetarget;
.float	yaw_speed;
.float	ideal_yaw;

.int			nextthink;
.void(entity)	prethink;
.void(entity)	think;

.void(entity, entity) blocked;
.void(entity, entity, vector, csurface_t) touch;
.void(entity, entity, entity) use;
.void(entity, entity, float, int) pain;
.void(entity, entity, entity, int, vector) die;

.int	touch_debounce_framenum;
.int	pain_debounce_framenum;
.int	damage_debounce_framenum;
.int	fly_sound_debounce_framenum;
.int	last_move_framenum;

.int	health;
.int	max_health;
.int	gib_health;
.enum : int
{
	DEAD_NO,
	DEAD_DYING,
	DEAD_DEAD,
	DEAD_RESPAWNABLE 
}		deadflag;
.int	show_hostile;

.int	powerarmor_framenum;

.string	map;
.int	viewheight;
.bool	takedamage;
.int	dmg;
.int	radius_dmg;
.float	dmg_radius;
.int	sounds;
.int	count;

.entity	chain;
.entity	enemy;
.entity	oldenemy;
.entity	activator;
.entity	groundentity;
.int	groundentity_linkcount;
.entity	teamchain;
.entity	teammaster;

#if defined(SINGLE_PLAYER)
.entity	mynoise;
.entity mynoise2;
#endif

.int	noise_index;
.int	noise_index2;
.float	volume;
.float	attenuation;

.float	wait;
.float	delay;
.float	rand;

.int	last_sound_framenum;

.content_flags_t	watertype;
.int				waterlevel;

.vector	move_origin;
.vector	move_angles;

.int		light_level;
.int		style;
.gitem_t	*item;

#ifdef GROUND_ZERO
.int	plat2flags;
.vector	offset;
.vector	gravityVector;
.entity	bad_area;
.entity	hint_chain;
.entity	monster_hint_chain;
.entity	target_hint_chain;
.int	hint_chain_id;
.int	lastMoveFrameNum;
#endif

typedef enum : int
{
	STATE_TOP,
	STATE_BOTTOM,
	STATE_UP,
	STATE_DOWN
} move_state_t;

struct moveinfo_t
{
	// fixed data
	vector	start_origin;
	vector	start_angles;
	vector	end_origin;
	vector	end_angles;
	
	int	sound_start;
	int	sound_middle;
	int	sound_end;
	
	float	accel;
	float	speed;
	float	decel;
	float	distance;
	
	float	wait;
	
	// state data
	move_state_t	state;
	vector			dir;
	float			current_speed;
	float			move_speed;
	float			next_speed;
	float			remaining_distance;
	float			decel_distance;
	void(entity)	endfunc;
};

.moveinfo_t		moveinfo;

#ifdef SINGLE_PLAYER
struct mframe_t
{
	void(entity, float)	aifunc;
	float				dist;
	void(entity)		thinkfunc;
};

struct mmove_t
{
	int				firstframe;
	int				lastframe;
	void(entity)	endfunc;
	mframe_t		*frame;
};

//monster ai flags
typedef enumflags : int
{
	AI_STAND_GROUND,
	AI_TEMP_STAND_GROUND,
	AI_SOUND_TARGET,
	AI_LOST_SIGHT,
	AI_PURSUIT_LAST_SEEN,
	AI_PURSUE_NEXT,
	AI_PURSUE_TEMP,
	AI_HOLD_FRAME,
	AI_GOOD_GUY,
	AI_BRUTAL,
	AI_NOSTEP,
	AI_DUCKED,
	AI_COMBAT_POINT,
	AI_MEDIC,
	AI_RESURRECTING
	
#ifdef GROUND_ZERO
	, AI_WALK_WALLS,
	AI_MANUAL_STEERING,
	AI_TARGET_ANGER,
	AI_DODGING,
	AI_CHARGING,
	AI_HINT_PATH,
	AI_IGNORE_SHOTS,
	AI_DO_NOT_COUNT,	// set for healed monsters
	AI_SPAWNED_CARRIER,	//
	AI_SPAWNED_MEDIC_C,	// both do_not_count and spawned are set for spawned monsters
	AI_SPAWNED_WIDOW,	//
	AI_BLOCKED,			// used by blocked_checkattack: set to say I'm attacking while blocked (prevents run-attacks)

	AI_GOOD_GUY_MASK = AI_GOOD_GUY | AI_DO_NOT_COUNT,
	AI_SPAWNED_MASK = AI_SPAWNED_CARRIER | AI_SPAWNED_MEDIC_C | AI_SPAWNED_WIDOW	// mask to catch all three flavors of spawned
#else
	, AI_GOOD_GUY_MASK = AI_GOOD_GUY
#endif
} ai_flags_t;

//monster attack state
typedef enum : int
{
	AS_STRAIGHT = 1,
	AS_SLIDING,
	AS_MELEE,
	AS_MISSILE

#ifdef GROUND_ZERO
	, AS_BLIND	// PMM - used by boss code to do nasty things even if it can't see you
#endif
} ai_attack_state_t;

#ifdef GROUND_ZERO
typedef void(entity, entity, float, trace_t *) mdodgefunc;
#else
typedef void(entity, entity, float) mdodgefunc;
#endif

struct monsterinfo_t
{
	mmove_t     *currentmove;
	ai_flags_t  aiflags;
	int         nextframe;
	float       scale;
	
	void(entity)			stand;
	void(entity)			idle;
	void(entity)			search;
	void(entity)			walk;
	void(entity)			run;
	mdodgefunc				dodge;
	void(entity)			attack;
	void(entity)			melee;
	void(entity, entity)	sight;
	bool(entity)			checkattack;
	
	int	pause_framenum;
	int	attack_finished;
	
	vector				saved_goal;
	int					search_framenum;
	int					trail_framenum;
	vector				last_sighting;
	ai_attack_state_t	attack_state;
	bool				lefty;
	int					idle_framenum;
	int					linkcount;
	
	int	power_armor_type;
	int	power_armor_power;
	
#ifdef GROUND_ZERO
	bool(entity self, float dist)	blocked;
	int		last_hint_framenum;		// last time the monster checked for hintpaths.
	entity	goal_hint;			// which hint_path we're trying to get to
	int		medicTries;
	entity	badMedic1, badMedic2;	// these medics have declared this monster "unhealable"
	entity	healer;	// this is who is healing this monster
	void(entity self, float eta)	duck;
	void(entity self)				unduck;
	void(entity self)				sidestep;
	float	base_height;
	int		next_duck_framenum;
	int		duck_wait_framenum;
	entity	last_player_enemy;
	// blindfire stuff .. the boolean says whether the monster will do it, and blind_fire_time is the timing
	// (set in the monster) of the next shot
	bool	blindfire;		// will the monster blindfire?
	int		blind_fire_framedelay;
	vector	blind_fire_target;
	// used by the spawners to not spawn too much and keep track of #s of monsters spawned
	int		monster_slots;
	int		monster_used;
	entity	commander;
	// powerup timers, used by widow, our friend
	int	quad_framenum;
	int	invincible_framenum;
	int	double_framenum;
#endif
};

.monsterinfo_t	monsterinfo;

#ifdef GROUND_ZERO
// this determines how long to wait after a duck to duck again.  this needs to be longer than
// the time after the monster_duck_up in all of the animation sequences
const float DUCK_INTERVAL	= 0.5;

// this is for the count of monsters
inline int(entity self) SELF_SLOTS_LEFT =
{
	return (self.monsterinfo.monster_slots - self.monsterinfo.monster_used);
};
#endif

#ifdef THE_RECKONING
.int	orders;
#endif
#endif
	
// player_state_t.refdef flags
typedef enumflags : int
{
	RDF_UNDERWATER,	// warp the screen as apropriate
	RDF_NOWORLDMODEL,	// used for player configuration screen

//ROGUE
	RDF_IRGOGGLES,
	RDF_UVGOGGLES
//ROGUE
} refdef_flags_t;

// For engine compatibility, these 18 IDs should remain the same
// and keep their described usage.
// These are macros so they can be embedded in the static statusbar strings.
#define STAT_HEALTH_ICON	0
#define STAT_HEALTH			1
#define STAT_AMMO_ICON		2
#define STAT_AMMO			3
#define STAT_ARMOR_ICON		4
#define STAT_ARMOR			5
#define STAT_SELECTED_ICON	6
#define STAT_PICKUP_ICON	7
#define STAT_PICKUP_STRING	8
#define STAT_TIMER_ICON		9
#define STAT_TIMER			10
#define STAT_HELPICON		11
#define STAT_SELECTED_ITEM	12
#define STAT_LAYOUTS		13
#define STAT_FRAGS			14
#define STAT_FLASHES		15 // cleared each frame, 1 = health, 2 = armor
#define STAT_CHASE			16
#define STAT_SPECTATOR		17
// Bits from here to (MAX_STATS - 1) are free for mods
#ifdef CTF
#define STAT_CTF_TEAM1_PIC			18
#define STAT_CTF_TEAM1_CAPS			19
#define STAT_CTF_TEAM2_PIC			20
#define STAT_CTF_TEAM2_CAPS			21
#define STAT_CTF_FLAG_PIC			22
#define STAT_CTF_JOINED_TEAM1_PIC	23
#define STAT_CTF_JOINED_TEAM2_PIC	24
#define STAT_CTF_TEAM1_HEADER		25
#define STAT_CTF_TEAM2_HEADER		26
#define STAT_CTF_TECH				27
#define STAT_CTF_ID_VIEW			28
#define STAT_CTF_ID_VIEW_COLOR		29
#define STAT_CTF_TEAMINFO			30
#endif

// TODO: this is because of a bug in stringification in fteqcc.
// eventually this will not need to be here.
#define STAT_HEALTH_ICON_str	"0"
#define STAT_HEALTH_str			"1"
#define STAT_AMMO_ICON_str		"2"
#define STAT_AMMO_str			"3"
#define STAT_ARMOR_ICON_str		"4"
#define STAT_ARMOR_str			"5"
#define STAT_SELECTED_ICON_str	"6"
#define STAT_PICKUP_ICON_str	"7"
#define STAT_PICKUP_STRING_str	"8"
#define STAT_TIMER_ICON_str		"9"
#define STAT_TIMER_str			"10"
#define STAT_HELPICON_str		"11"
#define STAT_SELECTED_ITEM_str	"12"
#define STAT_LAYOUTS_str		"13"
#define STAT_FRAGS_str			"14"
#define STAT_FLASHES_str		"15" // cleared each frame, 1 = health, 2 = armor
#define STAT_CHASE_str			"16"
#define STAT_SPECTATOR_str		"17"
// Bits from here to (MAX_STATS - 1) are free for mods
#ifdef CTF
#define STAT_CTF_TEAM1_PIC_str			"18"
#define STAT_CTF_TEAM1_CAPS_str			"19"
#define STAT_CTF_TEAM2_PIC_str			"20"
#define STAT_CTF_TEAM2_CAPS_str			"21"
#define STAT_CTF_FLAG_PIC_str			"22"
#define STAT_CTF_JOINED_TEAM1_PIC_str	"23"
#define STAT_CTF_JOINED_TEAM2_PIC_str	"24"
#define STAT_CTF_TEAM1_HEADER_str		"25"
#define STAT_CTF_TEAM2_HEADER_str		"26"
#define STAT_CTF_TECH_str				"27"
#define STAT_CTF_ID_VIEW_str			"28"
#define STAT_CTF_ID_VIEW_COLOR_str		"29"
#define STAT_CTF_TEAMINFO_str			"30"
#endif

// kmquake2 has a higher stat limit
#ifdef KMQUAKE2_EXTENSIONS
const int MAX_STATS	= 256;
#else
const int MAX_STATS = 32;
#endif

// for stringifying stat in static strings
#define STAT(s) s ## _str

struct player_state_t
{
	pmove_state_t	pmove;
	
	vector	viewangles;
	vector	viewoffset;
	vector	kick_angles;
	
	vector	gunangles;
	vector	gunoffset;
	int		gunindex;
	int		gunframe;

#ifdef KMQUAKE2_EXTENSIONS
	int	gunskin;		// for animated weapon skins
	int	gunindex2;		// for a second weapon model (boot)
	int	gunframe2;
	int	gunskin2;

	// server-side speed control!
	int	maxspeed;
	int	duckspeed;
	int	waterspeed;
	int	accel;
	int	stopspeed;
#endif
	
	float	blend[4];
	
	float	fov;
	
	refdef_flags_t	rdflags;
	
	int	stats[MAX_STATS];
};

// handedness values
typedef enum : int
{
	RIGHT_HANDED,
	LEFT_HANDED,
	CENTER_HANDED
} handedness_t;

// client data that stays across multiple level loads
struct client_persistant_t
{
	string			userinfo;
	string			netname;
	handedness_t	hand;
	
	bool	connected;  // a loadgame will leave valid entities that
						// just don't have a connection yet
	
	// values saved and restored from edicts when changing levels
	int	health;
	int	max_health;
	
	int	selected_item;
	int	inventory[itemlist.length];
	
	// ammo capacities
	int max_ammo[AMMO_TOTAL];
	
	gitem_t	*weapon;
	gitem_t	*lastweapon;

	int	score;          // for calculating total unit score in coop games

#ifdef SINGLE_PLAYER
	int	power_cubes;    // used for tracking the cubes in coop games
	int	savedFlags;
	int	game_helpchanged;
	int	helpchanged;
#endif
	
	bool	spectator;      // client is a spectator
};

#ifdef CTF
typedef enum : int
{
	CTF_NOTEAM,
	CTF_TEAM1,
	CTF_TEAM2
} ctfteam_t;
#endif

// client data that stays across deathmatch respawns
struct client_respawn_t
{
#ifdef SINGLE_PLAYER
	client_persistant_t	coop_respawn;   // what to set client.pers to on a respawn
#endif

	int		enterframe;         // level.framenum the client entered the game
	int		score;              // frags, etc
	vector	cmd_angles;         // angles sent over in the last command

	bool	spectator;          // client is a spectator

#ifdef CTF
	ctfteam_t	ctf_team;			// CTF team
	int		ctf_state;
	int		ctf_lasthurtcarrierframe;
	int		ctf_lastreturnedflagframe;
	int		ctf_flagsinceframe;
	int		ctf_lastfraggedcarrierframe;
	bool	id_state;
	int		lastidframe;
#endif
};

typedef enum : int
{
	WEAPON_READY,
	WEAPON_ACTIVATING,
	WEAPON_DROPPING,
	WEAPON_FIRING
} weaponstate_t;

// client_t.anim_priority
typedef enum : int
{
	ANIM_BASIC,		// stand / run
	ANIM_WAVE,
	ANIM_JUMP,
	ANIM_PAIN,
	ANIM_ATTACK,
	ANIM_DEATH,
	ANIM_REVERSE
} anim_priority_t;

#ifdef PMENU
typedef enum : int
{
	PMENU_ALIGN_LEFT,
	PMENU_ALIGN_CENTER,
	PMENU_ALIGN_RIGHT
} pmenu_align_t;

typedef void(entity) pmenu_select_func;

struct pmenu_t
{
	string				text;
	pmenu_align_t		align;
	pmenu_select_func	func;
};

struct pmenuhnd_t
{
	bool		open;
	pmenu_t		entries[18];
	int			cur;
	int			num;
	void		*arg;
};
#endif

#ifdef HOOK_CODE
typedef enum : int
{
	GRAPPLE_STATE_FLY,
	GRAPPLE_STATE_PULL,
	GRAPPLE_STATE_HANG
} grapplestate_t;
#endif

struct gclient_t
{
	player_state_t	ps;

	int		ping;
	int		clientNum;

	// private to game
	client_persistant_t	pers;
	client_respawn_t	resp;
	pmove_state_t		old_pmove;  // for detecting out-of-pmove changes
	
	bool	showscores;         // set layout stat
	bool	showinventory;      // set layout stat
#ifdef SINGLE_PLAYER
	bool	showhelp;
	bool	showhelpicon;
#endif
	
	int	ammo_index;
	
	button_bits_t	buttons;
	button_bits_t	oldbuttons;
	button_bits_t	latched_buttons;
	
	bool	weapon_thunk;

	gitem_t	*newweapon;
	
	// sum up damage over an entire frame, so
	// shotgun blasts give a single big kick
	int		damage_armor;       // damage absorbed by armor
	int		damage_parmor;      // damage absorbed by power armor
	int		damage_blood;       // damage taken out of health
	int		damage_knockback;   // impact damage
	vector	damage_from;        // origin for vector calculation
	
	float	killer_yaw;         // when dead, look at killer
	
	weaponstate_t	weaponstate;

	vector	kick_angles;    // weapon kicks
	vector	kick_origin;
	float	v_dmg_roll, v_dmg_pitch, v_dmg_time;    // damage kicks
	float	fall_time, fall_value;      // for view drop on fall
	float	bonus_alpha;
	vector	damage_blend;
	float	damage_alpha;
	vector	v_angle;            // aiming direction
	float	bobtime;            // so off-ground doesn't change it
	vector	oldviewangles;
	vector	oldvelocity;
	
	int	next_drown_framenum;
	int	old_waterlevel;
	int	breather_sound;
	
	int	machinegun_shots;   // for weapon raising
	
	// animation vars
	int				anim_end;
	anim_priority_t	anim_priority;
	bool			anim_duck;
	bool			anim_run;
	
	// powerup timers
	int	quad_framenum;
	int	invincible_framenum;
	int	breather_framenum;
	int	enviro_framenum;
	
	bool	grenade_blew_up;
	int		grenade_framenum;

	int	silencer_shots;
	int	weapon_sound;
	
	int	pickup_msg_framenum;
	
	float	flood_locktill;     // locked from talking
	float	flood_when[10];     // when messages were said
	int		flood_whenhead;     // head pointer for when said
	
	int		respawn_framenum;   // can respawn when time > this
	
	entity	chase_target;      // player we are chasing
	bool	update_chase;       // need to update chase info?

#ifdef THE_RECKONING
	int		quadfire_framenum;
	int		trap_framenum;
	bool	trap_blew_up;
#endif

#ifdef GROUND_ZERO
	int		double_framenum;
	int		ir_framenum;
	int		nuke_framenum;
	int		tracker_pain_framenum;
#endif

#ifdef PMENU
	pmenuhnd_t	menu;
#endif

#ifdef HOOK_CODE
	entity			grapple;	// entity of grapple
	grapplestate_t	grapplestate;
	int				grapplereleaseframenum;	// time of grapple release
#endif

#ifdef CTF
	int	ctf_regenframenum;		// regen tech
	int	ctf_techsndframenum;
	int	ctf_lasttechframenum;
#endif
};

.gclient_t	client;
.bool		is_client;	// read-only, set by the engine
.bool		is_linked;	// read-only, set by the engine

// used to store pre-push state
.struct
{
	vector	origin, angles;
#ifdef USE_SMOOTH_DELTA_ANGLES
	float	deltayaw;
#endif
} pushed;