// this struct houses special globals designed to mirror
// the original Q2 code; they aren't synced with Q2
// and must be synced manually via gi
struct
{
	int	num_edicts;
} globals;

const entity world;

// this is a special value that can be used to distinguish the world
// from a literal null entity. The only place this is used in Quake2C
// is for groundentity, which may be null *or* world (or other entity).
const entity null_entity = itoe(-1);

int snd_fry;
int sm_meat_index;

// global cvars
#ifdef SINGLE_PLAYER
cvar_t  deathmatch;
cvar_t  coop;
cvar_t  skill;
#endif
cvar_t	dmflags;
cvar_t	fraglimit;
cvar_t	timelimit;
#ifdef CTF
cvar_t	ctf;
cvar_t	capturelimit;
cvar_t	instantweap;
#endif
cvar_t  password;
cvar_t  spectator_password;
cvar_t  needpass;
cvar_t  maxspectators;
cvar_t  maxentities;
cvar_t  g_select_empty;
cvar_t  dedicated;

cvar_t  filterban;

cvar_t  sv_maxvelocity;
cvar_t  sv_gravity;

cvar_t  sv_rollspeed;
cvar_t  sv_rollangle;

cvar_t  run_pitch;
cvar_t  run_roll;
cvar_t  bob_up;
cvar_t  bob_pitch;
cvar_t  bob_roll;

cvar_t  sv_cheats;

cvar_t  flood_msgs;
cvar_t  flood_persecond;
cvar_t  flood_waitdelay;

cvar_t  sv_maplist;

cvar_t  sv_features;

// spawn_temp_t is only used to hold entity field values that
// can be set from the editor, but aren't actualy present
// in edict_t during gameplay
struct spawn_temp_t
{
	// world vars
	string	sky;
	float	skyrotate;
	vector	skyaxis;
	string	nextmap;
	
	int		lip;
	int		distance;
	int		height;
	string	noise;
	float	pausetime;
	string	item;
	string	gravity;
	
	float	minyaw;
	float	maxyaw;
	float	minpitch;
	float	maxpitch;
	
	float	angle;
} st;