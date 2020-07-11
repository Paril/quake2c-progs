// this struct houses special globals designed to mirror
// the original Q2 code; they aren't synced with Q2
// and must be synced manually via gi
struct
{
	int	num_edicts;
} globals;

const entity world;
const entity null_entity = (entity)(__variant)1;

int snd_fry;
int sm_meat_index;

// global cvars
cvar_t  deathmatch;
cvar_t  coop;
cvar_t  dmflags;
cvar_t  skill;
cvar_t  fraglimit;
cvar_t  timelimit;
cvar_t  password;
cvar_t  spectator_password;
cvar_t  needpass;
cvar_t  maxclients;
cvar_t  maxspectators;
cvar_t  maxentities;
cvar_t  g_select_empty;
cvar_t  dedicated;

cvar_t  filterban;

cvar_t  sv_maxvelocity;
cvar_t  sv_gravity;

cvar_t  sv_rollspeed;
cvar_t  sv_rollangle;
cvar_t  gun_x;
cvar_t  gun_y;
cvar_t  gun_z;

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