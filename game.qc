struct game_locals_t
{
	dynstring	helpmessage1;
	dynstring	helpmessage2;
	int		helpchanged;	// flash F1 icon if non 0, play sound
					// and increment only if 1, 2, or 3
	
	// can't store spawnpoint in level, because
	// it would get overwritten by the savegame restore
	dynstring	spawnpoint;	// needed for coop respawns
	
	// store latched cvars here that we want to get at often
	int	maxclients;
	int	maxentities;
	
	// cross level triggers
	int	serverflags;
	
	// items
	int	num_items;
	
	bool	autosaved;
};

game_locals_t game;

entity(int) itoe = #0:itoe;
int(entity) etoi = #0:etoi;

#define next_ent(e) itoe(e.s.number + 1)

bool(string, string, string) struct_key_parse = #0:struct_key_parse;
void(entity, .__variant, string) entity_key_parse = #0:entity_key_parse;

// dmflags->value flags
enumflags
{
	DF_NO_HEALTH,
	DF_NO_ITEMS,
	DF_WEAPONS_STAY,
	DF_NO_FALLING,
	DF_INSTANT_ITEMS,
	DF_SAME_LEVEL,
	DF_SKINTEAMS,
	DF_MODELTEAMS,
	DF_NO_FRIENDLY_FIRE,
	DF_SPAWN_FARTHEST,
	DF_FORCE_RESPAWN,
	DF_NO_ARMOR,
	DF_ALLOW_EXIT,
	DF_INFINITE_AMMO,
	DF_QUAD_DROP,
	DF_FIXED_FOV,

// RAFAEL
	DF_QUADFIRE_DROP,
// RAFAEL

//ROGUE
	DF_NO_MINES,
	DF_NO_STACK_DOUBLE,
	DF_NO_NUKES,
	DF_NO_SPHERES
//ROGUE
} dmflags_t;

// damage flags
typedef enumflags int
{
	DAMAGE_RADIUS,		// damage was indirect
	DAMAGE_NO_ARMOR,	// armour does not protect from this damage
	DAMAGE_ENERGY,		// damage is from an energy based weapon
	DAMAGE_NO_KNOCKBACK,	// do not affect velocity, just view angles
	DAMAGE_BULLET,		// damage is from a bullet (used for ricochets)
	DAMAGE_NO_PROTECTION,	// armor, shields, invulnerability, and godmode have no effect
} damage_flags_t;

// means of death
typedef enum int
{
	MOD_UNKNOWN,
	MOD_BLASTER,
	MOD_SHOTGUN,
	MOD_SSHOTGUN,
	MOD_MACHINEGUN,
	MOD_CHAINGUN,
	MOD_GRENADE,
	MOD_G_SPLASH,
	MOD_ROCKET,
	MOD_R_SPLASH,
	MOD_HYPERBLASTER,
	MOD_RAILGUN,
	MOD_BFG_LASER,
	MOD_BFG_BLAST,
	MOD_BFG_EFFECT,
	MOD_HANDGRENADE,
	MOD_HG_SPLASH,
	MOD_WATER,
	MOD_SLIME,
	MOD_LAVA,
	MOD_CRUSH,
	MOD_TELEFRAG,
	MOD_FALLING,
	MOD_SUICIDE,
	MOD_HELD_GRENADE,
	MOD_EXPLOSIVE,
	MOD_BARREL,
	MOD_BOMB,
	MOD_EXIT,
	MOD_SPLASH,
	MOD_TARGET_LASER,
	MOD_TRIGGER_HURT,
	MOD_HIT,
	MOD_TARGET_BLASTER,
	
	// bitflag
	MOD_FRIENDLY_FIRE	= 0x8000000
} means_of_death_t;

// gib types
typedef enum int
{
	GIB_ORGANIC,
	GIB_METALLIC
} gib_type_t;

// weapon parameters
const int DEFAULT_BULLET_HSPREAD		= 300;
const int DEFAULT_BULLET_VSPREAD		= 500;
const int DEFAULT_SHOTGUN_HSPREAD		= 1000;
const int DEFAULT_SHOTGUN_VSPREAD		= 500;
const int DEFAULT_DEATHMATCH_SHOTGUN_COUNT	= 12;
const int DEFAULT_SHOTGUN_COUNT			= 12;
const int DEFAULT_SSHOTGUN_COUNT		= 20;