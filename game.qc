// game.serverflags values
typedef enumflags : int
{
	SFL_CROSS_TRIGGER_1,
	SFL_CROSS_TRIGGER_2,
	SFL_CROSS_TRIGGER_3,
	SFL_CROSS_TRIGGER_4,
	SFL_CROSS_TRIGGER_5,
	SFL_CROSS_TRIGGER_6,
	SFL_CROSS_TRIGGER_7,
	SFL_CROSS_TRIGGER_8
} server_flags_t;

const server_flags_t SFL_CROSS_TRIGGER_MASK	= 0x000000ff;

API_FUNC struct game_locals_t
{
#ifdef SINGLE_PLAYER
	string	helpmessage1;
	string	helpmessage2;
	int		helpchanged;	// flash F1 icon if non 0, play sound; increment only if 1, 2, or 3
	
	// cross level triggers
	server_flags_t	serverflags;
	
	bool	autosaved;
#endif
	
	// can't store spawnpoint in level, because
	// it would get overwritten by the savegame restore
	string	spawnpoint;	// needed for coop respawns
	
	// store latched cvars here that we want to get at often
	int	maxclients;
	int	maxentities;
} game;

#define itoe(num) ((entity)(variant)(num))
#define etoi(e) (e.s.number)

#define next_ent(e) itoe(e.s.number + 1)

bool(string, string, string) struct_key_parse = #0;
void(entity, string, string) entity_key_parse = #0;

// dmflags.value flags
enumflags : int
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
	DF_FIXED_FOV,		// unused in Quake2C; this is outdated and unnecessary

// RAFAEL
	DF_QUADFIRE_DROP,
// RAFAEL

//ROGUE
	DF_NO_MINES,
	DF_NO_STACK_DOUBLE,
	DF_NO_NUKES,
	DF_NO_SPHERES
//ROGUE

#ifdef CTF
	, DF_CTF_FORCEJOIN,
	DF_ARMOR_PROTECT,
	DF_CTF_NO_TECH
#endif
};

// damage flags
typedef enumflags : int
{
	DAMAGE_RADIUS,		// damage was indirect
	DAMAGE_NO_ARMOR,	// armour does not protect from this damage
	DAMAGE_ENERGY,		// damage is from an energy based weapon
	DAMAGE_NO_KNOCKBACK,	// do not affect velocity, just view angles
	DAMAGE_BULLET,		// damage is from a bullet (used for ricochets)
	DAMAGE_NO_PROTECTION	// armor, shields, invulnerability, and godmode have no effect
	
#ifdef GROUND_ZERO
	, DAMAGE_DESTROY_ARMOR,	// damage is done to armor and health.
	DAMAGE_NO_REG_ARMOR,	// damage skips regular armor
	DAMAGE_NO_POWER_ARMOR	// damage skips power armor
#endif
} damage_flags_t;

// means of death
typedef enum : int
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
	
#ifdef THE_RECKONING
	MOD_RIPPER,
	MOD_PHALANX,
	MOD_BRAINTENTACLE,
	MOD_BLASTOFF,
	MOD_GEKK,
	MOD_TRAP,
#endif

#ifdef GROUND_ZERO
	MOD_CHAINFIST,
	MOD_DISINTEGRATOR,
	MOD_ETF_RIFLE,
	MOD_BLASTER2,
	MOD_HEATBEAM,
	MOD_TESLA,
	MOD_PROX,
	MOD_NUKE,
	MOD_TRACKER,
#endif

#ifdef GRAPPLE
	MOD_GRAPPLE,
#endif

	// bitflag
	MOD_FRIENDLY_FIRE	= 0x8000000
} means_of_death_t;

// gib types
typedef enum : int
{
	GIB_ORGANIC,
	GIB_METALLIC
} gib_type_t;

// weapon parameters
const int DEFAULT_BULLET_HSPREAD			= 300;
const int DEFAULT_BULLET_VSPREAD			= 500;
const int DEFAULT_SHOTGUN_HSPREAD			= 1000;
const int DEFAULT_SHOTGUN_VSPREAD			= 500;
const int DEFAULT_SHOTGUN_COUNT				= 12;
const int DEFAULT_SSHOTGUN_COUNT			= 20;