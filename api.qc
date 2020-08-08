// contains definitions that pertain to the game/server API
const int GAMEC_API_VERSION	= 1;

//
// per-level limits
//
const int MAX_CLIENTS		= 256;	// absolute limit
const int MAX_LIGHTSTYLES	= 256;
#ifdef KMQUAKE2_EXTENSIONS
const int MAX_EDICTS		= 8192;	// must change protocol to increase more
const int MAX_MODELS		= 8192;	// these are sent over the net as bytes
const int MAX_SOUNDS		= 8192;	// so they cannot be blindly increased
const int MAX_IMAGES		= 2048;
#else
const int MAX_EDICTS		= 1024;	// must change protocol to increase more
const int MAX_MODELS		= 256;	// these are sent over the net as bytes
const int MAX_SOUNDS		= 256;	// so they cannot be blindly increased
const int MAX_IMAGES		= 256;
#endif
const int MAX_ITEMS		= 256;
const int MAX_GENERAL		= (MAX_CLIENTS * 2); // general config strings

// game print flags
typedef enum int
{
	PRINT_LOW,		// pickup messages
	PRINT_MEDIUM,	// death messages
	PRINT_HIGH,		// critical messages
	PRINT_CHAT		// chat messages    
} print_level_t;

// destination class for gi.multicast()
typedef enum int
{
	MULTICAST_ALL,
	MULTICAST_PHS,
	MULTICAST_PVS,
	MULTICAST_ALL_R,
	MULTICAST_PHS_R,
	MULTICAST_PVS_R
} multicast_t;

//
// muzzle flashes / player effects
//
typedef enum int
{
	MZ_BLASTER,
	MZ_MACHINEGUN,
	MZ_SHOTGUN,
	MZ_CHAINGUN1,
	MZ_CHAINGUN2,
	MZ_CHAINGUN3,
	MZ_RAILGUN,
	MZ_ROCKET,
	MZ_GRENADE,
	MZ_LOGIN,
	MZ_LOGOUT,
	MZ_RESPAWN,
	MZ_BFG,
	MZ_SSHOTGUN,
	MZ_HYPERBLASTER,
	MZ_ITEMRESPAWN,
// RAFAEL
	MZ_IONRIPPER,
	MZ_BLUEHYPERBLASTER,
	MZ_PHALANX,
// RAFAEL

//ROGUE
	MZ_ETF_RIFLE	= 30,
	MZ_UNUSED,
	MZ_SHOTGUN2,
	MZ_HEATBEAM,
	MZ_BLASTER2,
	MZ_TRACKER,
	MZ_NUKE1,
	MZ_NUKE2,
	MZ_NUKE4,
	MZ_NUKE8,
//ROGUE

	MZ_SILENCED		= 128	// bit flag ORed with one of the above numbers
} muzzleflash_t;

//
// monster muzzle flashes
//
typedef enum int
{
	MZ2_TANK_BLASTER_1	= 1,
	MZ2_TANK_BLASTER_2,
	MZ2_TANK_BLASTER_3,
	MZ2_TANK_MACHINEGUN_1,
	MZ2_TANK_MACHINEGUN_2,
	MZ2_TANK_MACHINEGUN_3,
	MZ2_TANK_MACHINEGUN_4,
	MZ2_TANK_MACHINEGUN_5,
	MZ2_TANK_MACHINEGUN_6,
	MZ2_TANK_MACHINEGUN_7,
	MZ2_TANK_MACHINEGUN_8,
	MZ2_TANK_MACHINEGUN_9,
	MZ2_TANK_MACHINEGUN_10,
	MZ2_TANK_MACHINEGUN_11,
	MZ2_TANK_MACHINEGUN_12,
	MZ2_TANK_MACHINEGUN_13,
	MZ2_TANK_MACHINEGUN_14,
	MZ2_TANK_MACHINEGUN_15,
	MZ2_TANK_MACHINEGUN_16,
	MZ2_TANK_MACHINEGUN_17,
	MZ2_TANK_MACHINEGUN_18,
	MZ2_TANK_MACHINEGUN_19,
	MZ2_TANK_ROCKET_1,
	MZ2_TANK_ROCKET_2,
	MZ2_TANK_ROCKET_3,

	MZ2_INFANTRY_MACHINEGUN_1,
	MZ2_INFANTRY_MACHINEGUN_2,
	MZ2_INFANTRY_MACHINEGUN_3,
	MZ2_INFANTRY_MACHINEGUN_4,
	MZ2_INFANTRY_MACHINEGUN_5,
	MZ2_INFANTRY_MACHINEGUN_6,
	MZ2_INFANTRY_MACHINEGUN_7,
	MZ2_INFANTRY_MACHINEGUN_8,
	MZ2_INFANTRY_MACHINEGUN_9,
	MZ2_INFANTRY_MACHINEGUN_10,
	MZ2_INFANTRY_MACHINEGUN_11,
	MZ2_INFANTRY_MACHINEGUN_12,
	MZ2_INFANTRY_MACHINEGUN_13,
	
	MZ2_SOLDIER_BLASTER_1,
	MZ2_SOLDIER_BLASTER_2,
	MZ2_SOLDIER_SHOTGUN_1,
	MZ2_SOLDIER_SHOTGUN_2,
	MZ2_SOLDIER_MACHINEGUN_1,
	MZ2_SOLDIER_MACHINEGUN_2,
	
	MZ2_GUNNER_MACHINEGUN_1,
	MZ2_GUNNER_MACHINEGUN_2,
	MZ2_GUNNER_MACHINEGUN_3,
	MZ2_GUNNER_MACHINEGUN_4,
	MZ2_GUNNER_MACHINEGUN_5,
	MZ2_GUNNER_MACHINEGUN_6,
	MZ2_GUNNER_MACHINEGUN_7,
	MZ2_GUNNER_MACHINEGUN_8,
	MZ2_GUNNER_GRENADE_1,
	MZ2_GUNNER_GRENADE_2,
	MZ2_GUNNER_GRENADE_3,
	MZ2_GUNNER_GRENADE_4,

	MZ2_CHICK_ROCKET_1,
	
	MZ2_FLYER_BLASTER_1,
	MZ2_FLYER_BLASTER_2,
	
	MZ2_MEDIC_BLASTER_1,
	
	MZ2_GLADIATOR_RAILGUN_1,
	
	MZ2_HOVER_BLASTER_1,
	
	MZ2_ACTOR_MACHINEGUN_1,
	
	MZ2_SUPERTANK_MACHINEGUN_1,
	MZ2_SUPERTANK_MACHINEGUN_2,
	MZ2_SUPERTANK_MACHINEGUN_3,
	MZ2_SUPERTANK_MACHINEGUN_4,
	MZ2_SUPERTANK_MACHINEGUN_5,
	MZ2_SUPERTANK_MACHINEGUN_6,
	MZ2_SUPERTANK_ROCKET_1,
	MZ2_SUPERTANK_ROCKET_2,
	MZ2_SUPERTANK_ROCKET_3,
	
	MZ2_BOSS2_MACHINEGUN_L1,
	MZ2_BOSS2_MACHINEGUN_L2,
	MZ2_BOSS2_MACHINEGUN_L3,
	MZ2_BOSS2_MACHINEGUN_L4,
	MZ2_BOSS2_MACHINEGUN_L5,
	MZ2_BOSS2_ROCKET_1,
	MZ2_BOSS2_ROCKET_2,
	MZ2_BOSS2_ROCKET_3,
	MZ2_BOSS2_ROCKET_4,
	
	MZ2_FLOAT_BLASTER_1,

	MZ2_SOLDIER_BLASTER_3,
	MZ2_SOLDIER_SHOTGUN_3,
	MZ2_SOLDIER_MACHINEGUN_3,
	MZ2_SOLDIER_BLASTER_4,
	MZ2_SOLDIER_SHOTGUN_4,
	MZ2_SOLDIER_MACHINEGUN_4,
	MZ2_SOLDIER_BLASTER_5,
	MZ2_SOLDIER_SHOTGUN_5,
	MZ2_SOLDIER_MACHINEGUN_5,
	MZ2_SOLDIER_BLASTER_6,
	MZ2_SOLDIER_SHOTGUN_6,
	MZ2_SOLDIER_MACHINEGUN_6,
	MZ2_SOLDIER_BLASTER_7,
	MZ2_SOLDIER_SHOTGUN_7,
	MZ2_SOLDIER_MACHINEGUN_7,
	MZ2_SOLDIER_BLASTER_8,
	MZ2_SOLDIER_SHOTGUN_8,
	MZ2_SOLDIER_MACHINEGUN_8,

// Xian
	MZ2_MAKRON_BFG,
	MZ2_MAKRON_BLASTER_1,
	MZ2_MAKRON_BLASTER_2,
	MZ2_MAKRON_BLASTER_3,
	MZ2_MAKRON_BLASTER_4,
	MZ2_MAKRON_BLASTER_5,
	MZ2_MAKRON_BLASTER_6,
	MZ2_MAKRON_BLASTER_7,
	MZ2_MAKRON_BLASTER_8,
	MZ2_MAKRON_BLASTER_9,
	MZ2_MAKRON_BLASTER_10,
	MZ2_MAKRON_BLASTER_11,
	MZ2_MAKRON_BLASTER_12,
	MZ2_MAKRON_BLASTER_13,
	MZ2_MAKRON_BLASTER_14,
	MZ2_MAKRON_BLASTER_15,
	MZ2_MAKRON_BLASTER_16,
	MZ2_MAKRON_BLASTER_17,
	MZ2_MAKRON_RAILGUN_1,
	MZ2_JORG_MACHINEGUN_L1,
	MZ2_JORG_MACHINEGUN_L2,
	MZ2_JORG_MACHINEGUN_L3,
	MZ2_JORG_MACHINEGUN_L4,
	MZ2_JORG_MACHINEGUN_L5,
	MZ2_JORG_MACHINEGUN_L6,
	MZ2_JORG_MACHINEGUN_R1,
	MZ2_JORG_MACHINEGUN_R2,
	MZ2_JORG_MACHINEGUN_R3,
	MZ2_JORG_MACHINEGUN_R4,
	MZ2_JORG_MACHINEGUN_R5,
	MZ2_JORG_MACHINEGUN_R6,
	MZ2_JORG_BFG_1,
	MZ2_BOSS2_MACHINEGUN_R1,
	MZ2_BOSS2_MACHINEGUN_R2,
	MZ2_BOSS2_MACHINEGUN_R3,
	MZ2_BOSS2_MACHINEGUN_R4,
	MZ2_BOSS2_MACHINEGUN_R5,
// Xian

//ROGUE
	MZ2_CARRIER_MACHINEGUN_L1,
	MZ2_CARRIER_MACHINEGUN_R1,
	MZ2_CARRIER_GRENADE,
	MZ2_TURRET_MACHINEGUN,
	MZ2_TURRET_ROCKET,
	MZ2_TURRET_BLASTER,
	MZ2_STALKER_BLASTER,
	MZ2_DAEDALUS_BLASTER,
	MZ2_MEDIC_BLASTER_2,
	MZ2_CARRIER_RAILGUN,
	MZ2_WIDOW_DISRUPTOR,
	MZ2_WIDOW_BLASTER,
	MZ2_WIDOW_RAIL,
	MZ2_WIDOW_PLASMABEAM,			// PMM - not used
	MZ2_CARRIER_MACHINEGUN_L2,
	MZ2_CARRIER_MACHINEGUN_R2,
	MZ2_WIDOW_RAIL_LEFT,
	MZ2_WIDOW_RAIL_RIGHT,
	MZ2_WIDOW_BLASTER_SWEEP1,
	MZ2_WIDOW_BLASTER_SWEEP2,
	MZ2_WIDOW_BLASTER_SWEEP3,
	MZ2_WIDOW_BLASTER_SWEEP4,
	MZ2_WIDOW_BLASTER_SWEEP5,
	MZ2_WIDOW_BLASTER_SWEEP6,
	MZ2_WIDOW_BLASTER_SWEEP7,
	MZ2_WIDOW_BLASTER_SWEEP8,
	MZ2_WIDOW_BLASTER_SWEEP9,
	MZ2_WIDOW_BLASTER_100,
	MZ2_WIDOW_BLASTER_90,
	MZ2_WIDOW_BLASTER_80,
	MZ2_WIDOW_BLASTER_70,
	MZ2_WIDOW_BLASTER_60,
	MZ2_WIDOW_BLASTER_50,
	MZ2_WIDOW_BLASTER_40,
	MZ2_WIDOW_BLASTER_30,
	MZ2_WIDOW_BLASTER_20,
	MZ2_WIDOW_BLASTER_10,
	MZ2_WIDOW_BLASTER_0,
	MZ2_WIDOW_BLASTER_10L,
	MZ2_WIDOW_BLASTER_20L,
	MZ2_WIDOW_BLASTER_30L,
	MZ2_WIDOW_BLASTER_40L,
	MZ2_WIDOW_BLASTER_50L,
	MZ2_WIDOW_BLASTER_60L,
	MZ2_WIDOW_BLASTER_70L,
	MZ2_WIDOW_RUN_1,
	MZ2_WIDOW_RUN_2,
	MZ2_WIDOW_RUN_3,
	MZ2_WIDOW_RUN_4,
	MZ2_WIDOW_RUN_5,
	MZ2_WIDOW_RUN_6,
	MZ2_WIDOW_RUN_7,
	MZ2_WIDOW_RUN_8,
	MZ2_CARRIER_ROCKET_1,
	MZ2_CARRIER_ROCKET_2,
	MZ2_CARRIER_ROCKET_3,
	MZ2_CARRIER_ROCKET_4,
	MZ2_WIDOW2_BEAMER_1,
	MZ2_WIDOW2_BEAMER_2,
	MZ2_WIDOW2_BEAMER_3,
	MZ2_WIDOW2_BEAMER_4,
	MZ2_WIDOW2_BEAMER_5,
	MZ2_WIDOW2_BEAM_SWEEP_1,
	MZ2_WIDOW2_BEAM_SWEEP_2,
	MZ2_WIDOW2_BEAM_SWEEP_3,
	MZ2_WIDOW2_BEAM_SWEEP_4,
	MZ2_WIDOW2_BEAM_SWEEP_5,
	MZ2_WIDOW2_BEAM_SWEEP_6,
	MZ2_WIDOW2_BEAM_SWEEP_7,
	MZ2_WIDOW2_BEAM_SWEEP_8,
	MZ2_WIDOW2_BEAM_SWEEP_9,
	MZ2_WIDOW2_BEAM_SWEEP_10,
	MZ2_WIDOW2_BEAM_SWEEP_11
// ROGUE
} monster_muzzleflash_t;

// temp entity events
//
// Temp entity events are for things that happen
// at a location seperate from any existing entity.
// Temporary entity messages are explicitly constructed
// and broadcast.
typedef enum int
{
	TE_GUNSHOT,
	TE_BLOOD,
	TE_BLASTER,
	TE_RAILTRAIL,
	TE_SHOTGUN,
	TE_EXPLOSION1,
	TE_EXPLOSION2,
	TE_ROCKET_EXPLOSION,
	TE_GRENADE_EXPLOSION,
	TE_SPARKS,
	TE_SPLASH,
	TE_BUBBLETRAIL,
	TE_SCREEN_SPARKS,
	TE_SHIELD_SPARKS,
	TE_BULLET_SPARKS,
	TE_LASER_SPARKS,
	TE_PARASITE_ATTACK,
	TE_ROCKET_EXPLOSION_WATER,
	TE_GRENADE_EXPLOSION_WATER,
	TE_MEDIC_CABLE_ATTACK,
	TE_BFG_EXPLOSION,
	TE_BFG_BIGEXPLOSION,
	TE_BOSSTPORT,	// used as '22' in a map, so DON'T RENUMBER!!!
	TE_BFG_LASER,
	TE_GRAPPLE_CABLE,
	TE_WELDING_SPARKS,
	TE_GREENBLOOD,
	TE_BLUEHYPERBLASTER,
	TE_PLASMA_EXPLOSION,
	TE_TUNNEL_SPARKS,
//ROGUE
	TE_BLASTER2,
	TE_RAILTRAIL2,
	TE_FLAME,
	TE_LIGHTNING,
	TE_DEBUGTRAIL,
	TE_PLAIN_EXPLOSION,
	TE_FLASHLIGHT,
	TE_FORCEWALL,
	TE_HEATBEAM,
	TE_MONSTER_HEATBEAM,
	TE_STEAM,
	TE_BUBBLETRAIL2,
	TE_MOREBLOOD,
	TE_HEATBEAM_SPARKS,
	TE_HEATBEAM_STEAM,
	TE_CHAINFIST_SMOKE,
	TE_ELECTRIC_SPARKS,
	TE_TRACKER_EXPLOSION,
	TE_TELEPORT_EFFECT,
	TE_DBALL_GOAL,
	TE_WIDOWBEAMOUT,
	TE_NUKEBLAST,
	TE_WIDOWSPLASH,
	TE_EXPLOSION1_BIG,
	TE_EXPLOSION1_NP,
	TE_FLECHETTE,
//ROGUE

	TE_NUM_ENTITIES
} temp_event_t;

// color for TE_SPLASH
typedef enum int
{
	SPLASH_UNKNOWN,
	SPLASH_SPARKS,
	SPLASH_BLUE_WATER,
	SPLASH_BROWN_WATER,
	SPLASH_SLIME,
	SPLASH_LAVA,
	SPLASH_BLOOD
} splash_type_t;

//
// SOUNDS
//

// sound channels
// channel 0 never willingly overrides
// other channels (1-7) allways override a playing sound on that channel
typedef enum int
{
	CHAN_AUTO,
	CHAN_WEAPON,
	CHAN_VOICE,
	CHAN_ITEM,
	CHAN_BODY,
	// 3 unused IDs

// modifier flags
	CHAN_NO_PHS_ADD	= 8,	// send to all clients, not just ones in PHS (ATTN 0 will also do this)
	CHAN_RELIABLE	= 16	// send by reliable message, not datagram
} sound_channel_t;

// sound attenuation values
typedef enum : float
{
	ATTN_NONE,	// full volume the entire level
	ATTN_NORM,
	ATTN_IDLE,
	ATTN_STATIC	// diminish very rapidly with distance
} sound_attn_t;

//
// config strings are a general means of communication from
// the server to all connected clients.
// Each config string can be at most MAX_QPATH characters.
//
typedef enum int
{
	CS_NAME,
	CS_CDTRACK,
	CS_SKY,
	CS_SKYAXIS,	// %f %f %f format
	CS_SKYROTATE,
	CS_STATUSBAR,	// display program string
	
	CS_AIRACCEL		= 29,	// air acceleration control
	CS_MAXCLIENTS,
	CS_MAPCHECKSUM,			// for catching cheater maps
	
	CS_MODELS,
	CS_SOUNDS		= CS_MODELS + MAX_MODELS,
	CS_IMAGES		= CS_SOUNDS + MAX_SOUNDS,
	CS_LIGHTS		= CS_IMAGES + MAX_IMAGES,
	CS_ITEMS		= CS_LIGHTS + MAX_LIGHTSTYLES,
	CS_PLAYERSKINS		= CS_ITEMS + MAX_ITEMS,
	CS_GENERAL		= CS_PLAYERSKINS + MAX_CLIENTS,
	MAX_CONFIGSTRINGS	= CS_GENERAL + MAX_GENERAL
} config_string_t;

// Some mods actually exploit CS_STATUSBAR to take space up to CS_AIRACCEL
int CS_SIZE(config_string_t cs)
{
	if (cs >= CS_STATUSBAR && cs < CS_AIRACCEL)
		return MAX_QPATH * (CS_AIRACCEL - cs);
		
	return MAX_QPATH;
}

/*
==========================================================

CVARS (console variables)

==========================================================
*/

typedef enumflags int
{
	CVAR_NONE	= 0,
	CVAR_ARCHIVE	= 1,	// set to cause it to be saved to vars.rc
	CVAR_USERINFO,		// added to userinfo  when changed
	CVAR_SERVERINFO,	// added to serverinfo when changed
	CVAR_NOSET,		// don't allow change from console at all,
				// but can be set from the command line
	CVAR_LATCH		// save changes until server restart
} cvar_flags_t;

accessor cvar_t : int;

static string(cvar_t)		cvar_get_name = #0;

static string(cvar_t)		cvar_get_string = #0;

static string(cvar_t)		cvar_get_latched_string = #0;

static cvar_flags_t(cvar_t)	cvar_get_flags = #0;

static bool(cvar_t)		cvar_get_modified = #0;
static void(cvar_t, bool)	cvar_set_modified = #0;

static float(cvar_t)		cvar_get_floatVal = #0;

static int(cvar_t)		cvar_get_intVal = #0;

accessor cvar_t : int
{
	get string name = cvar_get_name;
	
	get string str = cvar_get_string;
	
	get string latched_str = cvar_get_latched_string;
	
	get cvar_flags_t flags = cvar_get_flags;
	
	get bool modified = cvar_get_modified;
	set bool modified = cvar_set_modified;
	
	get float floatVal = cvar_get_floatVal;
	
	get int intVal = cvar_get_intVal;
};

/*
==============================================================

COLLISION DETECTION

==============================================================
*/

// lower bits are stronger, and will eat weaker brushes completely
typedef enumflags int
{
	CONTENTS_SOLID,		// an eye is never valid in a solid
	CONTENTS_WINDOW,	// translucent, but not watery
	CONTENTS_AUX,
	CONTENTS_LAVA,
	CONTENTS_SLIME,
	CONTENTS_WATER,
	CONTENTS_MIST,
	LAST_VISIBLE_CONTENTS	= CONTENTS_MIST,

// remaining contents are non-visible, and don't eat brushes

	CONTENTS_AREAPORTAL	= 0x8000,

	CONTENTS_PLAYERCLIP,
	CONTENTS_MONSTERCLIP,

// currents can be added to any other contents, and may be mixed
	CONTENTS_CURRENT_0,
	CONTENTS_CURRENT_90,
	CONTENTS_CURRENT_180,
	CONTENTS_CURRENT_270,
	CONTENTS_CURRENT_UP,
	CONTENTS_CURRENT_DOWN,
	
	CONTENTS_ORIGIN,	// removed before bsping an entity
	
	CONTENTS_MONSTER,	// should never be on a brush, only in game
	CONTENTS_DEADMONSTER,
	CONTENTS_DETAIL,	// brushes to be added after vis leafs
	CONTENTS_TRANSLUCENT,	// auto set if any surface has trans
	CONTENTS_LADDER
} content_flags_t;

// FIXME should be in enum, but it infinite loop
const content_flags_t MASK_ALL	= -1;
// content masks
const content_flags_t MASK_SOLID	= CONTENTS_SOLID | CONTENTS_WINDOW;
const content_flags_t MASK_PLAYERSOLID	= CONTENTS_SOLID | CONTENTS_PLAYERCLIP | CONTENTS_WINDOW | CONTENTS_MONSTER;
const content_flags_t MASK_DEADSOLID	= CONTENTS_SOLID | CONTENTS_PLAYERCLIP | CONTENTS_WINDOW;
const content_flags_t MASK_MONSTERSOLID	= CONTENTS_SOLID | CONTENTS_MONSTERCLIP | CONTENTS_WINDOW | CONTENTS_MONSTER;
const content_flags_t MASK_WATER	= CONTENTS_WATER | CONTENTS_LAVA | CONTENTS_SLIME;
const content_flags_t MASK_OPAQUE	= CONTENTS_SOLID | CONTENTS_SLIME | CONTENTS_LAVA;
const content_flags_t MASK_SHOT		= CONTENTS_SOLID | CONTENTS_MONSTER | CONTENTS_WINDOW | CONTENTS_DEADMONSTER;
const content_flags_t MASK_CURRENT	= CONTENTS_CURRENT_0 | CONTENTS_CURRENT_90 | CONTENTS_CURRENT_180 | CONTENTS_CURRENT_270 | CONTENTS_CURRENT_UP | CONTENTS_CURRENT_DOWN;

typedef enumflags int
{
	SURF_LIGHT,	// value will hold the light strength
	
	SURF_SLICK,	// effects game physics
	
	SURF_SKY,	// don't draw, but add to skybox
	SURF_WARP,	// turbulent water warp
	SURF_TRANS33,
	SURF_TRANS66,
	SURF_FLOWING,	// scroll towards angle
	SURF_NODRAW,	// don't bother referencing the texture
	
	SURF_ALPHATEST	= 0x02000000	// used by kmquake2
} surface_flags_t;

typedef enum int
{
	AREA_SOLID	= 1,
	AREA_TRIGGERS	= 2
} box_edicts_area_t;

accessor entity_set_t : int;

static entity(entity_set_t, int)		entity_set_get = #0;
static int(entity_set_t)			entity_set_length = #0;
void(entity_set_t, entity)		entity_set_add = #0;
void(entity_set_t, entity)		entity_set_remove = #0;
void(entity_set_t)			entity_set_clear = #0;
void(entity_set_t)			entity_set_free = #0;
entity_set_t(optional int reserve)	entity_set_alloc = #0;

accessor entity_set_t : int
{
	get entity[int] = entity_set_get;
	get int length = entity_set_length;
};

struct cplane_t
{
	vector	normal;
	float	dist;
	int	extra; // FIXME?
};

const cplane_t null_plane;

accessor csurface_t : int;

static string(csurface_t)		csurface_get_name = #0;
static surface_flags_t(csurface_t)	csurface_get_flags = #0;
static int(csurface_t)			csurface_get_value = #0;

accessor csurface_t : int
{
	get string name = csurface_get_name;
	get surface_flags_t flags = csurface_get_flags;
	get int value = csurface_get_value;
};

const csurface_t null_surface = 0;

struct trace_t
{
	int		allsolid;
	int		startsolid;
	float		fraction;
	vector		endpos;
	cplane_t	plane;
	csurface_t	surface;
	content_flags_t	contents;
	entity		ent;
};

//
// button bits
//
typedef enum int
{
	BUTTON_ATTACK		= 1,
	BUTTON_USE			= 2,
	BUTTON_ANY			= 128		// any key whatsoever
} button_bits_t;

// usercmd_t is sent to the server each client frame
struct usercmd_t
{
	int		msec;
	button_bits_t	buttons;
	vector		angles;
	int		forwardmove, sidemove, upmove;
	int		impulse;        // remove?
	int		lightlevel;     // light level the player is standing on
};

// This constant is used in Q2 for movement
const int STEPSIZE = 18;

// The max number of planes to clip moves against
const int MAX_CLIP_PLANES = 5;

// pmove_state_t is the information necessary for client side movement
// prediction
typedef enum int
{
	// can accelerate and turn
	PM_NORMAL,
	PM_SPECTATOR,
	// no acceleration or turning
	PM_DEAD,
	PM_GIB,     // different bounding box
	PM_FREEZE
} pmtype_t;

// pmove.pm_flags
typedef enumflags int
{
	PMF_DUCKED,
	PMF_JUMP_HELD,
	PMF_ON_GROUND,
	PMF_TIME_WATERJUMP,	// pm_time is waterjump
	PMF_TIME_LAND,		// pm_time is time before rejump
	PMF_TIME_TELEPORT,	// pm_time is non-moving time
	PMF_NO_PREDICTION,	// temporarily disables prediction (used for grappling hook)
	PMF_TELEPORT_BIT	// used by q2pro
} pmflags_t;

struct pmove_state_t
{
	pmtype_t	pm_type;
	vector		origin;
	vector		velocity;
	int		pm_flags;
	int		pm_time;
	int		gravity;
	vector		delta_angles;
};

struct pmove_t
{
	// inout
	pmove_state_t	s;
	
	// in
	usercmd_t	cmd;
	bool		snapinitial;
	
	// out
	// DO NOT FREE THIS LIST!!!
	entity_set_t	touchents;
	
	vector	viewangles;
	float	viewheight;
	
	vector	mins, maxs;
	
	entity		groundentity;
	content_flags_t	watertype;
	int		waterlevel;
	
	// in (callbacks)
	void(trace_t *tr, vector start, vector mins, vector maxs, vector end) trace;
	content_flags_t(vector)	pointcontents;
};

// default server FPS
const int	BASE_FRAMERATE		= 10;
const int	BASE_FRAMETIME		= 100;
const float	BASE_1_FRAMETIME	= 1.0 / BASE_FRAMERATE;
const float	BASE_FRAMETIME_1000	= BASE_FRAMETIME / 1000.f;

const float	FRAMETIME = BASE_FRAMETIME_1000;

//
// server to client
//
typedef enum int
{
	svc_bad,

	// these ops are known to the game dll
	svc_muzzleflash,
	svc_muzzleflash2,
	svc_temp_entity,
	svc_layout,
	svc_inventory,

	// the rest are private to the client and server
	svc_nop,
	svc_disconnect,
	svc_reconnect,
	svc_sound,			// <see code>
	svc_print,			// [byte] id [string] null terminated string
	svc_stufftext,			// [string] stuffed into client's console buffer, should be \n terminated
	svc_serverdata,			// [long] protocol ...
	svc_configstring,		// [short] [string]
	svc_spawnbaseline,		
	svc_centerprint,		// [string] to put in center of the screen
	svc_download,			// [short] size [size bytes]
	svc_playerinfo,			// variable
	svc_packetentities,		// [...]
	svc_deltapacketentities,	// [...]
	svc_frame
} svc_ops_t;

// entity_state_t.effects
// Effects are things handled on the client side (lights, particles, frame animations)
// that happen constantly on the given entity.
// An entity that has effects will be sent to the client
// even if it has a zero index model.
typedef enumflags int
{
	EF_ROTATE,	// rotate (bonus items)
	EF_GIB,		// leave a trail
	EF_UNUSED,
	EF_BLASTER,	// redlight + trail
	EF_ROCKET,	// redlight + trail
	EF_GRENADE,
	EF_HYPERBLASTER,
	EF_BFG,
	EF_COLOR_SHELL,
	EF_POWERSCREEN,
	EF_ANIM01,		// automatically cycle between frames 0 and 1 at 2 hz
	EF_ANIM23,		// automatically cycle between frames 2 and 3 at 2 hz
	EF_ANIM_ALL,		// automatically cycle through all frames at 2hz
	EF_ANIM_ALLFAST,	// automatically cycle through all frames at 10hz
	EF_FLIES,
	EF_QUAD,
	EF_PENT,
	EF_TELEPORTER,		// particle fountain
	EF_FLAG1,
	EF_FLAG2,
// RAFAEL
	EF_IONRIPPER,
	EF_GREENGIB,
	EF_BLUEHYPERBLASTER,
	EF_SPINNINGLIGHTS,
	EF_PLASMA,
	EF_TRAP,
// RAFAEL

//ROGUE
	EF_TRACKER,
	EF_DOUBLE,
	EF_SPHERETRANS,
	EF_TAGTRAIL,
	EF_HALF_DAMAGE,
//ROGUE

	EF_TRACKERTRAIL
} entity_effects_t;