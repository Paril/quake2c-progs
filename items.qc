// item spawnflags
const int ITEM_TRIGGER_SPAWN	= 0x00000001;
const int ITEM_NO_TOUCH		= 0x00000002;
// 6 bits reserved for editor flags
// 8 bits used as power cube id bits for coop games
const int DROPPED_ITEM		= 0x00010000;
const int DROPPED_PLAYER_ITEM	= 0x00020000;
const int ITEM_TARGETS_USED	= 0x00040000;

// gitem_t->flags
typedef enumflags int
{
	IT_WEAPON,       // use makes active weapon
	IT_AMMO,
	IT_ARMOR,
	IT_STAY_COOP,
	IT_KEY,
	IT_POWERUP
} item_flags_t;

// gitem_t->weapmodel for weapons indicates model index
typedef enum int
{
	WEAP_NONE,
	WEAP_BLASTER,
	WEAP_SHOTGUN,
	WEAP_SUPERSHOTGUN,
	WEAP_MACHINEGUN,
	WEAP_CHAINGUN,
	WEAP_GRENADES,
	WEAP_GRENADELAUNCHER,
	WEAP_ROCKETLAUNCHER,
	WEAP_HYPERBLASTER,
	WEAP_RAILGUN,
	WEAP_BFG
} weap_model_t;

typedef enum int
{
    AMMO_BULLETS,
    AMMO_SHELLS,
    AMMO_ROCKETS,
    AMMO_GRENADES,
    AMMO_CELLS,
    AMMO_SLUGS
} ammo_t;

typedef enum int
{
	ITEM_NONE
} gitem_id_t;

// armor types
typedef enum int
{
	ARMOR_NONE,
	ARMOR_JACKET,
	ARMOR_COMBAT,
	ARMOR_BODY,
	ARMOR_SHARD
} gitem_armor_id_t;

struct gitem_t
{
	string				classname; // spawning name
	bool(entity, entity)		pickup;
	void(entity, gitem_id_t)	use;
	void(entity, gitem_id_t)	drop;
	void(entity)			weaponthink;
	string				pickup_sound;
	string				world_model;
	entity_effects_t		world_model_flags;
	string				view_model;
	
	// client side info
	string	icon;
	string	pickup_name;   // for printing on pickup
	int	count_width;    // number of digits to display by icon
	
	int		quantity;       // for ammo how much, for weapons how much is used per shot
	string		ammo;          // for weapons
	item_flags_t	flags;          // IT_* flags
	
	weap_model_t	weapmodel;      // weapon model index (for weapons)
	
	gitem_armor_id_t	info;
	int			tag;
	
	string	precaches;     // string of all models, sounds, and images this item will use
};

// from pweapon.qc
bool(entity, entity)		Pickup_Weapon;
void(entity, gitem_id_t)	Use_Weapon;
void(entity, gitem_id_t)	Drop_Weapon;

void(entity) Weapon_Blaster;
void(entity) Weapon_Shotgun;
void(entity) Weapon_SuperShotgun;
void(entity) Weapon_Machinegun;
void(entity) Weapon_Chaingun;
void(entity) Weapon_HyperBlaster;
void(entity) Weapon_RocketLauncher;
void(entity) Weapon_Grenade;
void(entity) Weapon_GrenadeLauncher;
void(entity) Weapon_Railgun;
void(entity) Weapon_BFG;

struct gitem_armor_t
{
	int	base_count;
	int	max_count;
	float	normal_protection;
	float	energy_protection;
};

gitem_armor_t armor_infos[] =
{
	{ },
	{ 25,  50, .30, .00 },
	{ 50, 100, .60, .30 },
	{100, 200, .80, .60 },
	{ }
};

#define GetArmorInfoKeyByIndex(index, key) armor_infos[(ARRAY_INDEX_TYPE)index].key

static int  jacket_armor_index;
static int  combat_armor_index;
static int  body_armor_index;
static int  power_screen_index;
static int  power_shield_index;

// special values for health styles
enum int
{
	HEALTH_IGNORE_MAX	= 1,
	HEALTH_TIMED		= 2
};

static int  quad_drop_timeout_hack;

//======================================================================

gitem_t itemlist[MAX_ITEMS];

// from items.qc
static bool(entity, entity)	Pickup_Armor;

static bool(entity, entity)	Pickup_PowerArmor;
static void(entity, gitem_id_t)	Use_PowerArmor;
static void(entity, gitem_id_t)	Drop_PowerArmor;

static bool(entity, entity)	Pickup_Ammo;
static void(entity, gitem_id_t)	Drop_Ammo;

static bool(entity, entity)	Pickup_Powerup;
static void(entity, gitem_id_t)	Drop_General;

static void(entity, gitem_id_t)	Use_Quad;
static void(entity, gitem_id_t)	Use_Invulnerability;
static void(entity, gitem_id_t)	Use_Silencer;
static void(entity, gitem_id_t)	Use_Breather;
static void(entity, gitem_id_t)	Use_Envirosuit;

static bool(entity, entity)	Pickup_AncientHead;
static bool(entity, entity)	Pickup_Adrenaline;
static bool(entity, entity)	Pickup_Bandolier;
static bool(entity, entity)	Pickup_Pack;
static bool(entity, entity)	Pickup_Key;
static bool(entity, entity)	Pickup_Health;

/*
	string				classname; // spawning name
	bool(entity, entity)		pickup;
	void(entity, gitem_id_t)	use;
	void(entity, gitem_id_t)	drop;
	void(entity)			weaponthink;
	string				pickup_sound;
	string				world_model;
	int				world_model_flags;
	string				view_model;
	
	// client side info
	string	icon;
	string	pickup_name;   // for printing on pickup
	int	count_width;    // number of digits to display by icon
	
	int	quantity;       // for ammo how much, for weapons how much is used per shot
	string	ammo;          // for weapons
	int	flags;          // IT_* flags
	
	int	weapmodel;      // weapon model index (for weapons)
	
	gitem_armor_id_t	info;
	int			tag;
	
	string	precaches;     // string of all models, sounds, and images this item will use
*/

void() InitItems =
{
	#define ADD_ITEM(a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r, s) itemlist[(ARRAY_INDEX_TYPE)(id)].classname = a; itemlist[(ARRAY_INDEX_TYPE)(id)].pickup = b; itemlist[(ARRAY_INDEX_TYPE)(id)].use = c; itemlist[(ARRAY_INDEX_TYPE)(id)].drop = d; itemlist[(ARRAY_INDEX_TYPE)(id)].weaponthink = e; itemlist[(ARRAY_INDEX_TYPE)(id)].pickup_sound = f; itemlist[(ARRAY_INDEX_TYPE)(id)].world_model = g; itemlist[(ARRAY_INDEX_TYPE)(id)].world_model_flags = h; itemlist[(ARRAY_INDEX_TYPE)(id)].view_model = i; itemlist[(ARRAY_INDEX_TYPE)(id)].icon = j; itemlist[(ARRAY_INDEX_TYPE)(id)].pickup_name = k; itemlist[(ARRAY_INDEX_TYPE)(id)].count_width = l; itemlist[(ARRAY_INDEX_TYPE)(id)].quantity = m; itemlist[(ARRAY_INDEX_TYPE)(id)].ammo = n; itemlist[(ARRAY_INDEX_TYPE)(id)].flags = o; itemlist[(ARRAY_INDEX_TYPE)(id)].weapmodel = p; itemlist[(ARRAY_INDEX_TYPE)(id)].info = q; itemlist[(ARRAY_INDEX_TYPE)(id)].tag = r; itemlist[(ARRAY_INDEX_TYPE)(id)].precaches = s; id++
	int id = 0;
	
	ADD_ITEM(0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0); // leave index 0 alone

	//
	// ARMOR
	//

	/*QUAKED item_armor_body (.3 .3 1) (-16 -16 -16) (16 16 16)
	*/
	ADD_ITEM(
		"item_armor_body",
		Pickup_Armor,
		0,
		0,
		0,
		"misc/ar1_pkup.wav",
		"models/items/armor/body/tris.md2", EF_ROTATE,
		0,
		/* icon */      "i_bodyarmor",
		/* pickup */    "Body Armor",
		/* width */     3,
		0,
		0,
		IT_ARMOR,
		0,
		ARMOR_BODY,
		ARMOR_BODY,
		/* precache */ ""
	);

	/*QUAKED item_armor_combat (.3 .3 1) (-16 -16 -16) (16 16 16)
	*/
	ADD_ITEM(
		"item_armor_combat",
		Pickup_Armor,
		0,
		0,
		0,
		"misc/ar1_pkup.wav",
		"models/items/armor/combat/tris.md2", EF_ROTATE,
		0,
		/* icon */      "i_combatarmor",
		/* pickup */    "Combat Armor",
		/* width */     3,
		0,
		0,
		IT_ARMOR,
		0,
		ARMOR_COMBAT,
		ARMOR_COMBAT,
		/* precache */ ""
	);

	/*QUAKED item_armor_jacket (.3 .3 1) (-16 -16 -16) (16 16 16)
	*/
	ADD_ITEM(
		"item_armor_jacket",
		Pickup_Armor,
		0,
		0,
		0,
		"misc/ar1_pkup.wav",
		"models/items/armor/jacket/tris.md2", EF_ROTATE,
		0,
		/* icon */      "i_jacketarmor",
		/* pickup */    "Jacket Armor",
		/* width */     3,
		0,
		0,
		IT_ARMOR,
		0,
		ARMOR_JACKET,
		ARMOR_JACKET,
		/* precache */ ""
	);

	/*QUAKED item_armor_shard (.3 .3 1) (-16 -16 -16) (16 16 16)
	*/
	ADD_ITEM(
		"item_armor_shard",
		Pickup_Armor,
		0,
		0,
		0,
		"misc/ar2_pkup.wav",
		"models/items/armor/shard/tris.md2", EF_ROTATE,
		0,
		/* icon */      "i_jacketarmor",
		/* pickup */    "Armor Shard",
		/* width */     3,
		0,
		0,
		IT_ARMOR,
		0,
		0,
		ARMOR_SHARD,
		/* precache */ ""
	);


	/*QUAKED item_power_screen (.3 .3 1) (-16 -16 -16) (16 16 16)
	*/
	ADD_ITEM(
		"item_power_screen",
		Pickup_PowerArmor,
		Use_PowerArmor,
		Drop_PowerArmor,
		0,
		"misc/ar3_pkup.wav",
		"models/items/armor/screen/tris.md2", EF_ROTATE,
		0,
		/* icon */      "i_powerscreen",
		/* pickup */    "Power Screen",
		/* width */     0,
		60,
		0,
		IT_ARMOR,
		0,
		0,
		0,
		/* precache */ ""
	);

	/*QUAKED item_power_shield (.3 .3 1) (-16 -16 -16) (16 16 16)
	*/
	ADD_ITEM(
		"item_power_shield",
		Pickup_PowerArmor,
		Use_PowerArmor,
		Drop_PowerArmor,
		0,
		"misc/ar3_pkup.wav",
		"models/items/armor/shield/tris.md2", EF_ROTATE,
		0,
		/* icon */      "i_powershield",
		/* pickup */    "Power Shield",
		/* width */     0,
		60,
		0,
		IT_ARMOR,
		0,
		0,
		0,
		/* precache */ "misc/power2.wav misc/power1.wav"
	);


	//
	// WEAPONS
	//

	/* weapon_blaster (.3 .3 1) (-16 -16 -16) (16 16 16)
	always owned, never in the world
	*/
	ADD_ITEM(
		"weapon_blaster",
		0,
		Use_Weapon,
		0,
		Weapon_Blaster,
		"misc/w_pkup.wav",
		0, 0,
		"models/weapons/v_blast/tris.md2",
		/* icon */      "w_blaster",
		/* pickup */    "Blaster",
		0,
		0,
		0,
		IT_WEAPON | IT_STAY_COOP,
		WEAP_BLASTER,
		0,
		0,
		/* precache */ "weapons/blastf1a.wav misc/lasfly.wav"
	);

	/*QUAKED weapon_shotgun (.3 .3 1) (-16 -16 -16) (16 16 16)
	*/
	ADD_ITEM(
		"weapon_shotgun",
		Pickup_Weapon,
		Use_Weapon,
		Drop_Weapon,
		Weapon_Shotgun,
		"misc/w_pkup.wav",
		"models/weapons/g_shotg/tris.md2", EF_ROTATE,
		"models/weapons/v_shotg/tris.md2",
		/* icon */      "w_shotgun",
		/* pickup */    "Shotgun",
		0,
		1,
		"Shells",
		IT_WEAPON | IT_STAY_COOP,
		WEAP_SHOTGUN,
		0,
		0,
		/* precache */ "weapons/shotgf1b.wav weapons/shotgr1b.wav"
	);

	/*QUAKED weapon_supershotgun (.3 .3 1) (-16 -16 -16) (16 16 16)
	*/
	ADD_ITEM(
		"weapon_supershotgun",
		Pickup_Weapon,
		Use_Weapon,
		Drop_Weapon,
		Weapon_SuperShotgun,
		"misc/w_pkup.wav",
		"models/weapons/g_shotg2/tris.md2", EF_ROTATE,
		"models/weapons/v_shotg2/tris.md2",
		/* icon */      "w_sshotgun",
		/* pickup */    "Super Shotgun",
		0,
		2,
		"Shells",
		IT_WEAPON | IT_STAY_COOP,
		WEAP_SUPERSHOTGUN,
		0,
		0,
		/* precache */ "weapons/sshotf1b.wav"
	);

	/*QUAKED weapon_machinegun (.3 .3 1) (-16 -16 -16) (16 16 16)
	*/
	ADD_ITEM(
		"weapon_machinegun",
		Pickup_Weapon,
		Use_Weapon,
		Drop_Weapon,
		Weapon_Machinegun,
		"misc/w_pkup.wav",
		"models/weapons/g_machn/tris.md2", EF_ROTATE,
		"models/weapons/v_machn/tris.md2",
		/* icon */      "w_machinegun",
		/* pickup */    "Machinegun",
		0,
		1,
		"Bullets",
		IT_WEAPON | IT_STAY_COOP,
		WEAP_MACHINEGUN,
		0,
		0,
		/* precache */ "weapons/machgf1b.wav weapons/machgf2b.wav weapons/machgf3b.wav weapons/machgf4b.wav weapons/machgf5b.wav"
	);

	/*QUAKED weapon_chaingun (.3 .3 1) (-16 -16 -16) (16 16 16)
	*/
	ADD_ITEM(
		"weapon_chaingun",
		Pickup_Weapon,
		Use_Weapon,
		Drop_Weapon,
		Weapon_Chaingun,
		"misc/w_pkup.wav",
		"models/weapons/g_chain/tris.md2", EF_ROTATE,
		"models/weapons/v_chain/tris.md2",
		/* icon */      "w_chaingun",
		/* pickup */    "Chaingun",
		0,
		1,
		"Bullets",
		IT_WEAPON | IT_STAY_COOP,
		WEAP_CHAINGUN,
		0,
		0,
		/* precache */ "weapons/chngnu1a.wav weapons/chngnl1a.wav weapons/machgf3b.wav` weapons/chngnd1a.wav"
	);

	/*QUAKED ammo_grenades (.3 .3 1) (-16 -16 -16) (16 16 16)
	*/
	ADD_ITEM(
		"ammo_grenades",
		Pickup_Ammo,
		Use_Weapon,
		Drop_Ammo,
		Weapon_Grenade,
		"misc/am_pkup.wav",
		"models/items/ammo/grenades/medium/tris.md2", 0,
		"models/weapons/v_handgr/tris.md2",
		/* icon */      "a_grenades",
		/* pickup */    "Grenades",
		/* width */     3,
		5,
		"grenades",
		IT_AMMO | IT_WEAPON,
		WEAP_GRENADES,
		0,
		AMMO_GRENADES,
		/* precache */ "weapons/hgrent1a.wav weapons/hgrena1b.wav weapons/hgrenc1b.wav weapons/hgrenb1a.wav weapons/hgrenb2a.wav "
	);

	/*QUAKED weapon_grenadelauncher (.3 .3 1) (-16 -16 -16) (16 16 16)
	*/
	ADD_ITEM(
		"weapon_grenadelauncher",
		Pickup_Weapon,
		Use_Weapon,
		Drop_Weapon,
		Weapon_GrenadeLauncher,
		"misc/w_pkup.wav",
		"models/weapons/g_launch/tris.md2", EF_ROTATE,
		"models/weapons/v_launch/tris.md2",
		/* icon */      "w_glauncher",
		/* pickup */    "Grenade Launcher",
		0,
		1,
		"Grenades",
		IT_WEAPON | IT_STAY_COOP,
		WEAP_GRENADELAUNCHER,
		0,
		0,
		/* precache */ "models/objects/grenade/tris.md2 weapons/grenlf1a.wav weapons/grenlr1b.wav weapons/grenlb1b.wav"
	);

	/*QUAKED weapon_rocketlauncher (.3 .3 1) (-16 -16 -16) (16 16 16)
	*/
	ADD_ITEM(
		"weapon_rocketlauncher",
		Pickup_Weapon,
		Use_Weapon,
		Drop_Weapon,
		Weapon_RocketLauncher,
		"misc/w_pkup.wav",
		"models/weapons/g_rocket/tris.md2", EF_ROTATE,
		"models/weapons/v_rocket/tris.md2",
		/* icon */      "w_rlauncher",
		/* pickup */    "Rocket Launcher",
		0,
		1,
		"Rockets",
		IT_WEAPON | IT_STAY_COOP,
		WEAP_ROCKETLAUNCHER,
		0,
		0,
		/* precache */ "models/objects/rocket/tris.md2 weapons/rockfly.wav weapons/rocklf1a.wav weapons/rocklr1b.wav models/objects/debris2/tris.md2"
	);

	/*QUAKED weapon_hyperblaster (.3 .3 1) (-16 -16 -16) (16 16 16)
	*/
	ADD_ITEM(
		"weapon_hyperblaster",
		Pickup_Weapon,
		Use_Weapon,
		Drop_Weapon,
		Weapon_HyperBlaster,
		"misc/w_pkup.wav",
		"models/weapons/g_hyperb/tris.md2", EF_ROTATE,
		"models/weapons/v_hyperb/tris.md2",
		/* icon */      "w_hyperblaster",
		/* pickup */    "HyperBlaster",
		0,
		1,
		"Cells",
		IT_WEAPON | IT_STAY_COOP,
		WEAP_HYPERBLASTER,
		0,
		0,
		/* precache */ "weapons/hyprbu1a.wav weapons/hyprbl1a.wav weapons/hyprbf1a.wav weapons/hyprbd1a.wav misc/lasfly.wav"
	);

	/*QUAKED weapon_railgun (.3 .3 1) (-16 -16 -16) (16 16 16)
	*/
	ADD_ITEM(
		"weapon_railgun",
		Pickup_Weapon,
		Use_Weapon,
		Drop_Weapon,
		Weapon_Railgun,
		"misc/w_pkup.wav",
		"models/weapons/g_rail/tris.md2", EF_ROTATE,
		"models/weapons/v_rail/tris.md2",
		/* icon */      "w_railgun",
		/* pickup */    "Railgun",
		0,
		1,
		"Slugs",
		IT_WEAPON | IT_STAY_COOP,
		WEAP_RAILGUN,
		0,
		0,
		/* precache */ "weapons/rg_hum.wav"
	);

	/*QUAKED weapon_bfg (.3 .3 1) (-16 -16 -16) (16 16 16)
	*/
	ADD_ITEM(
		"weapon_bfg",
		Pickup_Weapon,
		Use_Weapon,
		Drop_Weapon,
		Weapon_BFG,
		"misc/w_pkup.wav",
		"models/weapons/g_bfg/tris.md2", EF_ROTATE,
		"models/weapons/v_bfg/tris.md2",
		/* icon */      "w_bfg",
		/* pickup */    "BFG10K",
		0,
		50,
		"Cells",
		IT_WEAPON | IT_STAY_COOP,
		WEAP_BFG,
		0,
		0,
		/* precache */ "sprites/s_bfg1.sp2 sprites/s_bfg2.sp2 sprites/s_bfg3.sp2 weapons/bfg__f1y.wav weapons/bfg__l1a.wav weapons/bfg__x1b.wav weapons/bfg_hum.wav"
	);

	//
	// AMMO ITEMS
	//

	/*QUAKED ammo_shells (.3 .3 1) (-16 -16 -16) (16 16 16)
	*/
	ADD_ITEM(
		"ammo_shells",
		Pickup_Ammo,
		0,
		Drop_Ammo,
		0,
		"misc/am_pkup.wav",
		"models/items/ammo/shells/medium/tris.md2", 0,
		0,
		/* icon */      "a_shells",
		/* pickup */    "Shells",
		/* width */     3,
		10,
		0,
		IT_AMMO,
		0,
		0,
		AMMO_SHELLS,
		/* precache */ ""
	);

	/*QUAKED ammo_bullets (.3 .3 1) (-16 -16 -16) (16 16 16)
	*/
	ADD_ITEM(
		"ammo_bullets",
		Pickup_Ammo,
		0,
		Drop_Ammo,
		0,
		"misc/am_pkup.wav",
		"models/items/ammo/bullets/medium/tris.md2", 0,
		0,
		/* icon */      "a_bullets",
		/* pickup */    "Bullets",
		/* width */     3,
		50,
		0,
		IT_AMMO,
		0,
		0,
		AMMO_BULLETS,
		/* precache */ ""
	);

	/*QUAKED ammo_cells (.3 .3 1) (-16 -16 -16) (16 16 16)
	*/
	ADD_ITEM(
		"ammo_cells",
		Pickup_Ammo,
		0,
		Drop_Ammo,
		0,
		"misc/am_pkup.wav",
		"models/items/ammo/cells/medium/tris.md2", 0,
		0,
		/* icon */      "a_cells",
		/* pickup */    "Cells",
		/* width */     3,
		50,
		0,
		IT_AMMO,
		0,
		0,
		AMMO_CELLS,
		/* precache */ ""
	);

	/*QUAKED ammo_rockets (.3 .3 1) (-16 -16 -16) (16 16 16)
	*/
	ADD_ITEM(
		"ammo_rockets",
		Pickup_Ammo,
		0,
		Drop_Ammo,
		0,
		"misc/am_pkup.wav",
		"models/items/ammo/rockets/medium/tris.md2", 0,
		0,
		/* icon */      "a_rockets",
		/* pickup */    "Rockets",
		/* width */     3,
		5,
		0,
		IT_AMMO,
		0,
		0,
		AMMO_ROCKETS,
		/* precache */ ""
	);

	/*QUAKED ammo_slugs (.3 .3 1) (-16 -16 -16) (16 16 16)
	*/
	ADD_ITEM(
		"ammo_slugs",
		Pickup_Ammo,
		0,
		Drop_Ammo,
		0,
		"misc/am_pkup.wav",
		"models/items/ammo/slugs/medium/tris.md2", 0,
		0,
		/* icon */      "a_slugs",
		/* pickup */    "Slugs",
		/* width */     3,
		10,
		0,
		IT_AMMO,
		0,
		0,
		AMMO_SLUGS,
		/* precache */ ""
	);


	//
	// POWERUP ITEMS
	//
	/*QUAKED item_quad (.3 .3 1) (-16 -16 -16) (16 16 16)
	*/
	ADD_ITEM(
		"item_quad",
		Pickup_Powerup,
		Use_Quad,
		Drop_General,
		0,
		"items/pkup.wav",
		"models/items/quaddama/tris.md2", EF_ROTATE,
		0,
		/* icon */      "p_quad",
		/* pickup */    "Quad Damage",
		/* width */     2,
		60,
		0,
		IT_POWERUP,
		0,
		0,
		0,
		/* precache */ "items/damage.wav items/damage2.wav items/damage3.wav"
	);

	/*QUAKED item_invulnerability (.3 .3 1) (-16 -16 -16) (16 16 16)
	*/
	ADD_ITEM(
		"item_invulnerability",
		Pickup_Powerup,
		Use_Invulnerability,
		Drop_General,
		0,
		"items/pkup.wav",
		"models/items/invulner/tris.md2", EF_ROTATE,
		0,
		/* icon */      "p_invulnerability",
		/* pickup */    "Invulnerability",
		/* width */     2,
		300,
		0,
		IT_POWERUP,
		0,
		0,
		0,
		/* precache */ "items/protect.wav items/protect2.wav items/protect4.wav"
	);

	/*QUAKED item_silencer (.3 .3 1) (-16 -16 -16) (16 16 16)
	*/
	ADD_ITEM(
		"item_silencer",
		Pickup_Powerup,
		Use_Silencer,
		Drop_General,
		0,
		"items/pkup.wav",
		"models/items/silencer/tris.md2", EF_ROTATE,
		0,
		/* icon */      "p_silencer",
		/* pickup */    "Silencer",
		/* width */     2,
		60,
		0,
		IT_POWERUP,
		0,
		0,
		0,
		/* precache */ ""
	);

	/*QUAKED item_breather (.3 .3 1) (-16 -16 -16) (16 16 16)
	*/
	ADD_ITEM(
		"item_breather",
		Pickup_Powerup,
		Use_Breather,
		Drop_General,
		0,
		"items/pkup.wav",
		"models/items/breather/tris.md2", EF_ROTATE,
		0,
		/* icon */      "p_rebreather",
		/* pickup */    "Rebreather",
		/* width */     2,
		60,
		0,
		IT_STAY_COOP | IT_POWERUP,
		0,
		0,
		0,
		/* precache */ "items/airout.wav"
	);

	/*QUAKED item_enviro (.3 .3 1) (-16 -16 -16) (16 16 16)
	*/
	ADD_ITEM(
		"item_enviro",
		Pickup_Powerup,
		Use_Envirosuit,
		Drop_General,
		0,
		"items/pkup.wav",
		"models/items/enviro/tris.md2", EF_ROTATE,
		0,
		/* icon */      "p_envirosuit",
		/* pickup */    "Environment Suit",
		/* width */     2,
		60,
		0,
		IT_STAY_COOP | IT_POWERUP,
		0,
		0,
		0,
		/* precache */ "items/airout.wav"
	);

	/*QUAKED item_ancient_head (.3 .3 1) (-16 -16 -16) (16 16 16)
	Special item that gives +2 to maximum health
	*/
	ADD_ITEM(
		"item_ancient_head",
		Pickup_AncientHead,
		0,
		0,
		0,
		"items/pkup.wav",
		"models/items/c_head/tris.md2", EF_ROTATE,
		0,
		/* icon */      "i_fixme",
		/* pickup */    "Ancient Head",
		/* width */     2,
		60,
		0,
		0,
		0,
		0,
		0,
		/* precache */ ""
	);

	/*QUAKED item_adrenaline (.3 .3 1) (-16 -16 -16) (16 16 16)
	gives +1 to maximum health
	*/
	ADD_ITEM(
		"item_adrenaline",
		Pickup_Adrenaline,
		0,
		0,
		0,
		"items/pkup.wav",
		"models/items/adrenal/tris.md2", EF_ROTATE,
		0,
		/* icon */      "p_adrenaline",
		/* pickup */    "Adrenaline",
		/* width */     2,
		60,
		0,
		0,
		0,
		0,
		0,
		/* precache */ ""
	);

	/*QUAKED item_bandolier (.3 .3 1) (-16 -16 -16) (16 16 16)
	*/
	ADD_ITEM(
		"item_bandolier",
		Pickup_Bandolier,
		0,
		0,
		0,
		"items/pkup.wav",
		"models/items/band/tris.md2", EF_ROTATE,
		0,
		/* icon */      "p_bandolier",
		/* pickup */    "Bandolier",
		/* width */     2,
		60,
		0,
		0,
		0,
		0,
		0,
		/* precache */ ""
	);

	/*QUAKED item_pack (.3 .3 1) (-16 -16 -16) (16 16 16)
	*/
	ADD_ITEM(
		"item_pack",
		Pickup_Pack,
		0,
		0,
		0,
		"items/pkup.wav",
		"models/items/pack/tris.md2", EF_ROTATE,
		0,
		/* icon */      "i_pack",
		/* pickup */    "Ammo Pack",
		/* width */     2,
		180,
		0,
		0,
		0,
		0,
		0,
		/* precache */ ""
	);

	//
	// KEYS
	//
	/*QUAKED key_data_cd (0 .5 .8) (-16 -16 -16) (16 16 16)
	key for computer centers
	*/
	ADD_ITEM(
		"key_data_cd",
		Pickup_Key,
		0,
		Drop_General,
		0,
		"items/pkup.wav",
		"models/items/keys/data_cd/tris.md2", EF_ROTATE,
		0,
		"k_datacd",
		"Data CD",
		2,
		0,
		0,
		IT_STAY_COOP | IT_KEY,
		0,
		0,
		0,
		/* precache */ ""
	);

	/*QUAKED key_power_cube (0 .5 .8) (-16 -16 -16) (16 16 16) TRIGGER_SPAWN NO_TOUCH
	warehouse circuits
	*/
	ADD_ITEM(
		"key_power_cube",
		Pickup_Key,
		0,
		Drop_General,
		0,
		"items/pkup.wav",
		"models/items/keys/power/tris.md2", EF_ROTATE,
		0,
		"k_powercube",
		"Power Cube",
		2,
		0,
		0,
		IT_STAY_COOP | IT_KEY,
		0,
		0,
		0,
		/* precache */ ""
	);

	/*QUAKED key_pyramid (0 .5 .8) (-16 -16 -16) (16 16 16)
	key for the entrance of jail3
	*/
	ADD_ITEM(
		"key_pyramid",
		Pickup_Key,
		0,
		Drop_General,
		0,
		"items/pkup.wav",
		"models/items/keys/pyramid/tris.md2", EF_ROTATE,
		0,
		"k_pyramid",
		"Pyramid Key",
		2,
		0,
		0,
		IT_STAY_COOP | IT_KEY,
		0,
		0,
		0,
		/* precache */ ""
	);

	/*QUAKED key_data_spinner (0 .5 .8) (-16 -16 -16) (16 16 16)
	key for the city computer
	*/
	ADD_ITEM(
		"key_data_spinner",
		Pickup_Key,
		0,
		Drop_General,
		0,
		"items/pkup.wav",
		"models/items/keys/spinner/tris.md2", EF_ROTATE,
		0,
		"k_dataspin",
		"Data Spinner",
		2,
		0,
		0,
		IT_STAY_COOP | IT_KEY,
		0,
		0,
		0,
		/* precache */ ""
	);

	/*QUAKED key_pass (0 .5 .8) (-16 -16 -16) (16 16 16)
	security pass for the security level
	*/
	ADD_ITEM(
		"key_pass",
		Pickup_Key,
		0,
		Drop_General,
		0,
		"items/pkup.wav",
		"models/items/keys/pass/tris.md2", EF_ROTATE,
		0,
		"k_security",
		"Security Pass",
		2,
		0,
		0,
		IT_STAY_COOP | IT_KEY,
		0,
		0,
		0,
		/* precache */ ""
	);

	/*QUAKED key_blue_key (0 .5 .8) (-16 -16 -16) (16 16 16)
	normal door key - blue
	*/
	ADD_ITEM(
		"key_blue_key",
		Pickup_Key,
		0,
		Drop_General,
		0,
		"items/pkup.wav",
		"models/items/keys/key/tris.md2", EF_ROTATE,
		0,
		"k_bluekey",
		"Blue Key",
		2,
		0,
		0,
		IT_STAY_COOP | IT_KEY,
		0,
		0,
		0,
		/* precache */ ""
	);

	/*QUAKED key_red_key (0 .5 .8) (-16 -16 -16) (16 16 16)
	normal door key - red
	*/
	ADD_ITEM(
		"key_red_key",
		Pickup_Key,
		0,
		Drop_General,
		0,
		"items/pkup.wav",
		"models/items/keys/red_key/tris.md2", EF_ROTATE,
		0,
		"k_redkey",
		"Red Key",
		2,
		0,
		0,
		IT_STAY_COOP | IT_KEY,
		0,
		0,
		0,
		/* precache */ ""
	);

	/*QUAKED key_commander_head (0 .5 .8) (-16 -16 -16) (16 16 16)
	tank commander's head
	*/
	ADD_ITEM(
		"key_commander_head",
		Pickup_Key,
		0,
		Drop_General,
		0,
		"items/pkup.wav",
		"models/monsters/commandr/head/tris.md2", EF_GIB,
		0,
		/* icon */      "k_comhead",
		/* pickup */    "Commander's Head",
		/* width */     2,
		0,
		0,
		IT_STAY_COOP | IT_KEY,
		0,
		0,
		0,
		/* precache */ ""
	);

	/*QUAKED key_airstrike_target (0 .5 .8) (-16 -16 -16) (16 16 16)
	tank commander's head
	*/
	ADD_ITEM(
		"key_airstrike_target",
		Pickup_Key,
		0,
		Drop_General,
		0,
		"items/pkup.wav",
		"models/items/keys/target/tris.md2", EF_ROTATE,
		0,
		/* icon */      "i_airstrike",
		/* pickup */    "Airstrike Marker",
		/* width */     2,
		0,
		0,
		IT_STAY_COOP | IT_KEY,
		0,
		0,
		0,
		/* precache */ ""
	);

	ADD_ITEM(
		0,
		Pickup_Health,
		0,
		0,
		0,
		"items/pkup.wav",
		0, 0,
		0,
		/* icon */      "i_health",
		/* pickup */    "Health",
		/* width */     3,
		0,
		0,
		0,
		0,
		0,
		0,
		/* precache */ "items/s_health.wav items/n_health.wav items/l_health.wav items/m_health.wav"
	);
	
	game.num_items = id;
};

//======================================================================

/*
===============
GetItemByIndex
===============
*/
#define GetItemKeyByIndex(index, key) (itemlist[(ARRAY_INDEX_TYPE)index].key)

#define ITEM_INDEX(item) item
	
#define GetItemByIndex(index) index

/*
===============
FindItemByClassname

===============
*/
gitem_id_t(string cclassname) FindItemByClassname =
{
	int     i;
	for (i = 0 ; i < game.num_items; i++) {
		if (!GetItemKeyByIndex(i, classname))
			continue;
		if (!stricmp(GetItemKeyByIndex(i, classname), cclassname))
			return i;
	}

	return 0;
}

/*
===============
FindItem

===============
*/
gitem_id_t(string pickup_name) FindItem =
{
	int     i;
	for (i = 0 ; i < game.num_items; i++) {
		if (!GetItemKeyByIndex(i, pickup_name))
			continue;
		if (!stricmp(GetItemKeyByIndex(i, pickup_name), pickup_name))
			return i;
	}

	return 0;
}

//======================================================================

static void(entity ent) DoRespawn =
{
	if (ent->team)
	{
		entity	master;
		int	count;
		int	choice;

		master = ent->teammaster;

		for (count = 0, ent = master; ent; ent = ent->chain, count++)
			;

		choice = Q_rand_uniform(count);

		for (count = 0, ent = master; count < choice; ent = ent->chain, count++)
			;
	}

	ent->svflags &= ~SVF_NOCLIENT;
	ent->solid = SOLID_TRIGGER;
	gi.linkentity(ent);

	// send an effect
	ent->s.event = EV_ITEM_RESPAWN;
}

void(entity ent, int delay) SetRespawn =
{
	ent->flags |= FL_RESPAWN;
	ent->svflags |= SVF_NOCLIENT;
	ent->solid = SOLID_NOT;
	ent->nextthink = level.framenum + delay * BASE_FRAMERATE;
	ent->think = DoRespawn;
	gi.linkentity(ent);
}


//======================================================================

static bool(entity ent, entity other) Pickup_Powerup =
{
	//FIXME
	/*int     quantity;

	quantity = other->client->pers.inventory[ITEM_INDEX(ent->item)];
	if ((skill->value == 1 && quantity >= 2) || (skill->value >= 2 && quantity >= 1))
		return false;

	if ((coop->value) && (ent->item->flags & IT_STAY_COOP) && (quantity > 0))
		return false;

	other->client->pers.inventory[ITEM_INDEX(ent->item)]++;*/

	if (deathmatch->intVal) {
		if (!(ent->spawnflags & DROPPED_ITEM))
			SetRespawn(ent, GetItemKeyByIndex(ent->item, quantity));
		if ((dmflags->intVal & DF_INSTANT_ITEMS) || ((GetItemKeyByIndex(ent->item, use) == Use_Quad) && (ent->spawnflags & DROPPED_PLAYER_ITEM)))
		{
			if ((GetItemKeyByIndex(ent->item, use) == Use_Quad) && (ent->spawnflags & DROPPED_PLAYER_ITEM))
				quad_drop_timeout_hack = ent->nextthink - level.framenum;
			GetItemKeyByIndex(ent->item, use)(other, ent->item);
		}
	}

	return true;
}

// from items.qc
entity(entity, gitem_id_t) Drop_Item;

// from cmds.qc
void(entity) ValidateSelectedItem;

static void(entity ent, gitem_id_t item) Drop_General =
{
	Drop_Item(ent, item);
	//FIXME
	//ent->client->pers.inventory[ITEM_INDEX(item)]--;
	ValidateSelectedItem(ent);
}


//======================================================================

static bool(entity ent, entity other) Pickup_Adrenaline
{
	if (!deathmatch->intVal)
		other->max_health += 1;

	if (other->health < other->max_health)
		other->health = other->max_health;

	if (!(ent->spawnflags & DROPPED_ITEM) && (deathmatch->intVal))
		SetRespawn(ent, GetItemKeyByIndex(ent->item, quantity));

	return true;
}

static bool(entity ent, entity other) Pickup_AncientHead =
{
	other->max_health += 2;

	if (!(ent->spawnflags & DROPPED_ITEM) && (deathmatch->intVal))
		SetRespawn(ent, GetItemKeyByIndex(ent->item, quantity));

	return true;
}

static bool(entity ent, entity other) Pickup_Bandolier =
{
	gitem_id_t	itemid;
	int		index;

	if (other->client->pers.max_bullets < 250)
		other->client->pers.max_bullets = 250;
	if (other->client->pers.max_shells < 150)
		other->client->pers.max_shells = 150;
	if (other->client->pers.max_cells < 250)
		other->client->pers.max_cells = 250;
	if (other->client->pers.max_slugs < 75)
		other->client->pers.max_slugs = 75;

	itemid = FindItem("Bullets");
	if (itemid) {
		index = ITEM_INDEX(itemid);
		// FIXME
		/*other->client->pers.inventory[index] += item->quantity;
		if (other->client->pers.inventory[index] > other->client->pers.max_bullets)
			other->client->pers.inventory[index] = other->client->pers.max_bullets;*/
	}

	itemid = FindItem("Shells");
	if (itemid) {
		index = ITEM_INDEX(itemid);
		// FIXME
		/*other->client->pers.inventory[index] += item->quantity;
		if (other->client->pers.inventory[index] > other->client->pers.max_shells)
			other->client->pers.inventory[index] = other->client->pers.max_shells;*/
	}

	if (!(ent->spawnflags & DROPPED_ITEM) && (deathmatch->intVal))
		SetRespawn(ent, GetItemKeyByIndex(ent->item, quantity));

	return true;
}

static bool(entity ent, entity other) Pickup_Pack =
{
	gitem_id_t	itemid;
	int		index;

	if (other->client->pers.max_bullets < 300)
		other->client->pers.max_bullets = 300;
	if (other->client->pers.max_shells < 200)
		other->client->pers.max_shells = 200;
	if (other->client->pers.max_rockets < 100)
		other->client->pers.max_rockets = 100;
	if (other->client->pers.max_grenades < 100)
		other->client->pers.max_grenades = 100;
	if (other->client->pers.max_cells < 300)
		other->client->pers.max_cells = 300;
	if (other->client->pers.max_slugs < 100)
		other->client->pers.max_slugs = 100;

	itemid = FindItem("Bullets");
	if (itemid) {
		index = ITEM_INDEX(itemid);
		// FIXME
		/*other->client->pers.inventory[index] += item->quantity;
		if (other->client->pers.inventory[index] > other->client->pers.max_bullets)
			other->client->pers.inventory[index] = other->client->pers.max_bullets;*/
	}

	itemid = FindItem("Shells");
	if (itemid) {
		index = ITEM_INDEX(itemid);
		// FIXME
		/*other->client->pers.inventory[index] += item->quantity;
		if (other->client->pers.inventory[index] > other->client->pers.max_shells)
			other->client->pers.inventory[index] = other->client->pers.max_shells;*/
	}

	itemid = FindItem("Cells");
	if (itemid) {
		index = ITEM_INDEX(itemid);
		// FIXME
		/*other->client->pers.inventory[index] += item->quantity;
		if (other->client->pers.inventory[index] > other->client->pers.max_cells)
			other->client->pers.inventory[index] = other->client->pers.max_cells;*/
	}

	itemid = FindItem("Grenades");
	if (itemid) {
		index = ITEM_INDEX(itemid);
		// FIXME
		/*other->client->pers.inventory[index] += item->quantity;
		if (other->client->pers.inventory[index] > other->client->pers.max_grenades)
			other->client->pers.inventory[index] = other->client->pers.max_grenades;*/
	}

	itemid = FindItem("Rockets");
	if (itemid) {
		index = ITEM_INDEX(itemid);
		// FIXME
		/*other->client->pers.inventory[index] += item->quantity;
		if (other->client->pers.inventory[index] > other->client->pers.max_rockets)
			other->client->pers.inventory[index] = other->client->pers.max_rockets;*/
	}

	itemid = FindItem("Slugs");
	if (itemid) {
		index = ITEM_INDEX(itemid);
		// FIXME
		/*other->client->pers.inventory[index] += item->quantity;
		if (other->client->pers.inventory[index] > other->client->pers.max_slugs)
			other->client->pers.inventory[index] = other->client->pers.max_slugs;*/
	}

	if (!(ent->spawnflags & DROPPED_ITEM) && (deathmatch->intVal))
		SetRespawn(ent, GetItemKeyByIndex(ent->item, quantity));

	return true;
}

//======================================================================

static void(entity ent, gitem_id_t item) Use_Quad =
{
	int     timeout;

	// FIXME
	//ent->client->pers.inventory[ITEM_INDEX(item)]--;
	ValidateSelectedItem(ent);

	if (quad_drop_timeout_hack) {
		timeout = quad_drop_timeout_hack;
		quad_drop_timeout_hack = 0;
	} else {
		timeout = 300;
	}

	if (ent->client->quad_framenum > level.framenum)
		ent->client->quad_framenum += timeout;
	else
		ent->client->quad_framenum = level.framenum + timeout;

	gi.sound(ent, CHAN_ITEM, gi.soundindex("items/damage.wav"), 1, ATTN_NORM, 0);
}

//======================================================================

static void(entity ent, gitem_id_t item) Use_Breather =
{
	// FIXME
	//ent->client->pers.inventory[ITEM_INDEX(item)]--;
	ValidateSelectedItem(ent);

	if (ent->client->breather_framenum > level.framenum)
		ent->client->breather_framenum += 300;
	else
		ent->client->breather_framenum = level.framenum + 300;
}

//======================================================================

static void(entity ent, gitem_id_t item) Use_Envirosuit =
{
	// FIXME
	//ent->client->pers.inventory[ITEM_INDEX(item)]--;
	ValidateSelectedItem(ent);

	if (ent->client->enviro_framenum > level.framenum)
		ent->client->enviro_framenum += 300;
	else
		ent->client->enviro_framenum = level.framenum + 300;
}

//======================================================================

static void(entity ent, gitem_id_t item) Use_Invulnerability =
{
	// FIXME
	//ent->client->pers.inventory[ITEM_INDEX(item)]--;
	ValidateSelectedItem(ent);

	if (ent->client->invincible_framenum > level.framenum)
		ent->client->invincible_framenum += 300;
	else
		ent->client->invincible_framenum = level.framenum + 300;

	gi.sound(ent, CHAN_ITEM, gi.soundindex("items/protect.wav"), 1, ATTN_NORM, 0);
}

//======================================================================

static void(entity ent, gitem_id_t item) Use_Silencer =
{
	// FIXME
	//ent->client->pers.inventory[ITEM_INDEX(item)]--;
	ValidateSelectedItem(ent);
	ent->client->silencer_shots += 30;
}

//======================================================================

static bool(entity ent, entity other) Pickup_Key =
{
	if (coop->intVal) {
		if (ent->classname == "key_power_cube") {
			if (other->client->pers.power_cubes & (RShiftInt((ent->spawnflags & 0x0000ff00), 8)))
				return false;
			// FIXME
			//other->client->pers.inventory[ITEM_INDEX(ent->item)]++;
			other->client->pers.power_cubes |= (RShiftInt((ent->spawnflags & 0x0000ff00), 8));
		} else {
			// FIXME
			/*if (other->client->pers.inventory[ITEM_INDEX(ent->item)])
				return false;
			other->client->pers.inventory[ITEM_INDEX(ent->item)] = 1;*/
		}
		return true;
	}
	// FIXME
	//other->client->pers.inventory[ITEM_INDEX(ent->item)]++;
	return true;
}

//======================================================================

bool(entity ent, gitem_id_t itemid, int count) Add_Ammo =
{
	int         index;
	int         max;

	if (!ent->is_client)
		return false;
	
	int	tag = GetItemKeyByIndex(itemid, tag);

	if (tag == AMMO_BULLETS)
		max = ent->client->pers.max_bullets;
	else if (tag == AMMO_SHELLS)
		max = ent->client->pers.max_shells;
	else if (tag == AMMO_ROCKETS)
		max = ent->client->pers.max_rockets;
	else if (tag == AMMO_GRENADES)
		max = ent->client->pers.max_grenades;
	else if (tag == AMMO_CELLS)
		max = ent->client->pers.max_cells;
	else if (tag == AMMO_SLUGS)
		max = ent->client->pers.max_slugs;
	else
		return false;

	index = ITEM_INDEX(itemid);

	// FIXME
	/*if (ent->client->pers.inventory[index] == max)
		return false;

	ent->client->pers.inventory[index] += count;

	if (ent->client->pers.inventory[index] > max)
		ent->client->pers.inventory[index] = max;*/

	return true;
}

static bool(entity ent, entity other) Pickup_Ammo =
{
	int	oldcount;
	int	ammocount;
	bool	weapon;

	weapon = (GetItemKeyByIndex(ent->item, flags) & IT_WEAPON);
	if ((weapon) && (dmflags->intVal & DF_INFINITE_AMMO))
		ammocount = 1000;
	else if (ent->count)
		ammocount = ent->count;
	else
		ammocount = GetItemKeyByIndex(ent->item, quantity);

	// fixme
	//oldcount = other->client->pers.inventory[ITEM_INDEX(ent->item)];

	if (!Add_Ammo(other, ent->item, ammocount))
		return false;

	if (weapon && !oldcount) {
		if (other->client->pers.weapon != ent->item && (!deathmatch->intVal || other->client->pers.weapon == FindItem("blaster")))
			other->client->newweapon = ent->item;
	}

	if (!(ent->spawnflags & (DROPPED_ITEM | DROPPED_PLAYER_ITEM)) && (deathmatch->intVal))
		SetRespawn(ent, 30);
	return true;
}

static void(entity ent, gitem_id_t itemid) Drop_Ammo =
{
	entity	dropped;
	int	index;

	index = ITEM_INDEX(itemid);
	dropped = Drop_Item(ent, itemid);

	// FIXME
	/*if (ent->client->pers.inventory[index] >= item->quantity)
		dropped->count = item->quantity;
	else
		dropped->count = ent->client->pers.inventory[index];*/

	// FIXME
	/*if (ent->client->pers.weapon &&
		GetItemKeyByIndex(ent->client->pers.weapon, tag) == AMMO_GRENADES &&
		item->tag == AMMO_GRENADES &&
		ent->client->pers.inventory[index] - dropped->count <= 0) {
		gi.cprintf(ent, PRINT_HIGH, "Can't drop current weapon\n");
		G_FreeEdict(dropped);
		return;
	}

	ent->client->pers.inventory[index] -= dropped->count;*/
	ValidateSelectedItem(ent);
}


//======================================================================

static void(entity self) MegaHealth_think =
{
	if (self->owner->health > self->owner->max_health) {
		self->nextthink = level.framenum + 1 * BASE_FRAMERATE;
		self->owner->health -= 1;
		return;
	}

	if (!(self->spawnflags & DROPPED_ITEM) && (deathmatch->intVal))
		SetRespawn(self, 20);
	else
		G_FreeEdict(self);
}

static bool(entity ent, entity other) Pickup_Health =
{
	if (!(ent->style & HEALTH_IGNORE_MAX))
		if (other->health >= other->max_health)
			return false;

	other->health += ent->count;

	if (!(ent->style & HEALTH_IGNORE_MAX)) {
		if (other->health > other->max_health)
			other->health = other->max_health;
	}

	if (ent->style & HEALTH_TIMED) {
		ent->think = MegaHealth_think;
		ent->nextthink = level.framenum + 5 * BASE_FRAMERATE;
		ent->owner = other;
		ent->flags |= FL_RESPAWN;
		ent->svflags |= SVF_NOCLIENT;
		ent->solid = SOLID_NOT;
	} else {
		if (!(ent->spawnflags & DROPPED_ITEM) && (deathmatch->intVal))
			SetRespawn(ent, 30);
	}

	return true;
}

//======================================================================

int(entity ent) ArmorIndex =
{
	if (!ent->is_client)
		return 0;

	// FIXME
	/*if (ent->client->pers.inventory[jacket_armor_index] > 0)
		return jacket_armor_index;

	if (ent->client->pers.inventory[combat_armor_index] > 0)
		return combat_armor_index;

	if (ent->client->pers.inventory[body_armor_index] > 0)
		return body_armor_index;*/

	return 0;
}

static bool(entity ent, entity other) Pickup_Armor =
{
	int	old_armor_index;
	gitem_armor_id_t	oldinfo;
	gitem_armor_id_t	newinfo;
	int	newcount;
	float	salvage;
	int	salvagecount;

	// get info on new armor
	newinfo = GetItemKeyByIndex(ent->item, info);

	old_armor_index = ArmorIndex(other);

	// handle armor shards specially
	if (GetItemKeyByIndex(ent->item, tag) == ARMOR_SHARD) {
		// FIXME
		/*if (!old_armor_index)
			other->client->pers.inventory[jacket_armor_index] = 2;
		else
			other->client->pers.inventory[old_armor_index] += 2;*/
	}

	// if player has no armor, just use it
	else if (!old_armor_index) {
		// FIXME
		//other->client->pers.inventory[ITEM_INDEX(ent->item)] = newinfo->base_count;
	}

	// use the better armor
	else {
		// get info on old armor
		if (old_armor_index == jacket_armor_index)
			oldinfo = ARMOR_JACKET;
		else if (old_armor_index == combat_armor_index)
			oldinfo = ARMOR_COMBAT;
		else // (old_armor_index == body_armor_index)
			oldinfo = ARMOR_BODY;

		if (GetArmorInfoKeyByIndex(newinfo, normal_protection) > GetArmorInfoKeyByIndex(oldinfo, normal_protection)) {
			// calc new armor values
			salvage = GetArmorInfoKeyByIndex(oldinfo, normal_protection) / GetArmorInfoKeyByIndex(newinfo, normal_protection);
			// FIXME
			//salvagecount = salvage * other->client->pers.inventory[old_armor_index];
			newcount = GetArmorInfoKeyByIndex(newinfo, base_count) + salvagecount;
			if (newcount > GetArmorInfoKeyByIndex(newinfo, max_count))
				newcount = GetArmorInfoKeyByIndex(newinfo, max_count);

			// FIXME
			// zero count of old armor so it goes away
			//other->client->pers.inventory[old_armor_index] = 0;

			// change armor to new item with computed value
			//other->client->pers.inventory[ITEM_INDEX(ent->item)] = newcount;
		} else {
			// calc new armor values
			salvage = GetArmorInfoKeyByIndex(newinfo, normal_protection) / GetArmorInfoKeyByIndex(oldinfo, normal_protection);
			salvagecount = (int)(salvage * GetArmorInfoKeyByIndex(newinfo, base_count));
			// FIXME
			//newcount = other->client->pers.inventory[old_armor_index] + salvagecount;
			if (newcount > GetArmorInfoKeyByIndex(oldinfo, max_count))
				newcount = GetArmorInfoKeyByIndex(oldinfo, max_count);

			// FIXME
			// if we're already maxed out then we don't need the new armor
			//if (other->client->pers.inventory[old_armor_index] >= newcount)
			//	return false;

			// update current armor value
			//other->client->pers.inventory[old_armor_index] = newcount;
		}
	}

	if (!(ent->spawnflags & DROPPED_ITEM) && (deathmatch->intVal))
		SetRespawn(ent, 20);

	return true;
}

//======================================================================

power_armor_type_t(entity ent) PowerArmorType =
{
	if (!ent->is_client)
		return POWER_ARMOR_NONE;

	if (!(ent->flags & FL_POWER_ARMOR))
		return POWER_ARMOR_NONE;

	// TODO
	/*if (ent->client->pers.inventory[power_shield_index] > 0)
		return POWER_ARMOR_SHIELD;

	if (ent->client->pers.inventory[power_screen_index] > 0)
		return POWER_ARMOR_SCREEN;*/

	return POWER_ARMOR_NONE;
}

static void(entity ent, gitem_id_t itemid) Use_PowerArmor =
{
	int     index;

	if (ent->flags & FL_POWER_ARMOR) {
		ent->flags &= ~FL_POWER_ARMOR;
		gi.sound(ent, CHAN_AUTO, gi.soundindex("misc/power2.wav"), 1, ATTN_NORM, 0);
	} else {
		index = ITEM_INDEX(FindItem("cells"));
		// FIXME
		/*if (!ent->client->pers.inventory[index]) {
			gi.cprintf(ent, PRINT_HIGH, "No cells for power armor.\n");
			return;
		}*/
		ent->flags |= FL_POWER_ARMOR;
		gi.sound(ent, CHAN_AUTO, gi.soundindex("misc/power1.wav"), 1, ATTN_NORM, 0);
	}
}

static bool(entity ent, entity other) Pickup_PowerArmor =
{
	int     quantity;

	// FIXME
	//quantity = other->client->pers.inventory[ITEM_INDEX(ent->item)];

	//other->client->pers.inventory[ITEM_INDEX(ent->item)]++;

	if (deathmatch->intVal) {
		if (!(ent->spawnflags & DROPPED_ITEM))
			SetRespawn(ent, GetItemKeyByIndex(ent->item, quantity));
		// auto-use for DM only if we didn't already have one
		if (!quantity)
			GetItemKeyByIndex(ent->item, use)(other, ent->item);
	}

	return true;
}

static void(entity ent, gitem_id_t itemid) Drop_PowerArmor =
{
	// FIXME
	//if ((ent->flags & FL_POWER_ARMOR) && (ent->client->pers.inventory[ITEM_INDEX(item)] == 1))
	//	Use_PowerArmor(ent, item);
	Drop_General(ent, itemid);
}

//======================================================================

/*
===============
Touch_Item
===============
*/
void(entity ent, entity other, cplane_t plane, csurface_t surf) Touch_Item =
{
	bool    taken;

	if (!other->is_client)
		return;
	if (other->health < 1)
		return;     // dead people can't pickup
	if (!GetItemKeyByIndex(ent->item, pickup))
		return;     // not a grabbable item?

	taken = GetItemKeyByIndex(ent->item, pickup)(ent, other);

	if (taken) {
		// flash the screen
		other->client->bonus_alpha = 0.25f;

		// show icon and name on status bar
		other->client->ps.stats[STAT_PICKUP_ICON] = gi.imageindex(GetItemKeyByIndex(ent->item, icon));
		other->client->ps.stats[STAT_PICKUP_STRING] = CS_ITEMS + ITEM_INDEX(ent->item);
		other->client->pickup_msg_framenum = level.framenum + (int)(3.0f * BASE_FRAMERATE);

		// change selected item
		if (GetItemKeyByIndex(ent->item, use))
			other->client->pers.selected_item = other->client->ps.stats[STAT_SELECTED_ITEM] = ITEM_INDEX(ent->item);

		if (GetItemKeyByIndex(ent->item, pickup) == Pickup_Health) {
			if (ent->count == 2)
				gi.sound(other, CHAN_ITEM, gi.soundindex("items/s_health.wav"), 1, ATTN_NORM, 0);
			else if (ent->count == 10)
				gi.sound(other, CHAN_ITEM, gi.soundindex("items/n_health.wav"), 1, ATTN_NORM, 0);
			else if (ent->count == 25)
				gi.sound(other, CHAN_ITEM, gi.soundindex("items/l_health.wav"), 1, ATTN_NORM, 0);
			else // (ent->count == 100)
				gi.sound(other, CHAN_ITEM, gi.soundindex("items/m_health.wav"), 1, ATTN_NORM, 0);
		} else if (GetItemKeyByIndex(ent->item, pickup_sound)) {
			gi.sound(other, CHAN_ITEM, gi.soundindex(GetItemKeyByIndex(ent->item, pickup_sound)), 1, ATTN_NORM, 0);
		}
	}

	if (!(ent->spawnflags & ITEM_TARGETS_USED)) {
		G_UseTargets(ent, other);
		ent->spawnflags |= ITEM_TARGETS_USED;
	}

	if (!taken)
		return;

	if (!((coop->intVal) && (GetItemKeyByIndex(ent->item, flags) & IT_STAY_COOP)) || (ent->spawnflags & (DROPPED_ITEM | DROPPED_PLAYER_ITEM))) {
		if (ent->flags & FL_RESPAWN)
			ent->flags &= ~FL_RESPAWN;
		else
			G_FreeEdict(ent);
	}
}

//======================================================================

static void(entity ent, entity other, cplane_t plane, csurface_t surf) drop_temp_touch =
{
	if (other == ent->owner)
		return;

	Touch_Item(ent, other, plane, surf);
}

static void(entity ent) drop_make_touchable =
{
	ent->touch = Touch_Item;
	if (deathmatch->intVal) {
		ent->nextthink = level.framenum + 29 * BASE_FRAMERATE;
		ent->think = G_FreeEdict;
	}
}

entity(entity ent, gitem_id_t itemid) Drop_Item =
{
	entity	dropped;
	vector	forward, right;
	vector	offset;

	dropped = G_Spawn();

	dropped->classname = GetItemKeyByIndex(itemid, classname);
	dropped->item = itemid;
	dropped->spawnflags = DROPPED_ITEM;
	dropped->s.effects = GetItemKeyByIndex(itemid, world_model_flags);
	dropped->s.renderfx = RF_GLOW;
	VectorSet(dropped->mins, -15, -15, -15);
	VectorSet(dropped->maxs, 15, 15, 15);
	gi.setmodel(dropped, GetItemKeyByIndex(itemid, world_model));
	dropped->solid = SOLID_TRIGGER;
	dropped->movetype = MOVETYPE_TOSS;
	dropped->touch = drop_temp_touch;
	dropped->owner = ent;

	if (ent->is_client) {
		trace_t trace;

		AngleVectors(ent->client->v_angle, forward, right, unref_vec);
		VectorSet(offset, 24, 0, -16);
		G_ProjectSource(ent->s.origin, offset, forward, right, dropped->s.origin);
		trace_and_result(trace, ent->s.origin, dropped->mins, dropped->maxs, dropped->s.origin, ent, CONTENTS_SOLID);
		VectorCopy(trace.endpos, dropped->s.origin);
	} else {
		AngleVectors(ent->s.angles, forward, right, unref_vec);
		VectorCopy(ent->s.origin, dropped->s.origin);
	}

	VectorScale(forward, 100, dropped->velocity);
	dropped->velocity_z = 300f;

	dropped->think = drop_make_touchable;
	dropped->nextthink = level.framenum + 1 * BASE_FRAMERATE;

	gi.linkentity(dropped);

	return dropped;
}

void(entity ent, entity other, entity activator) Use_Item =
{
	ent->svflags &= ~SVF_NOCLIENT;
	ent->use = 0;

	if (ent->spawnflags & ITEM_NO_TOUCH) {
		ent->solid = SOLID_BBOX;
		ent->touch = 0;
	} else {
		ent->solid = SOLID_TRIGGER;
		ent->touch = Touch_Item;
	}

	gi.linkentity(ent);
}

//======================================================================

/*
================
droptofloor
================
*/
static void(entity ent) droptofloor = 
{
	trace_t	tr;
	vector	dest;
	vector	v;

	v = '-15 -15 -15';
	VectorCopy(v, ent->mins);
	v = '15 15 15';
	VectorCopy(v, ent->maxs);

	if (ent->model)
		gi.setmodel(ent, ent->model);
	else
		gi.setmodel(ent, GetItemKeyByIndex(ent->item, world_model));
	ent->solid = SOLID_TRIGGER;
	ent->movetype = MOVETYPE_TOSS;
	ent->touch = Touch_Item;

	v = '0 0 -128';
	VectorAdd(ent->s.origin, v, dest);

	trace_and_result(tr, ent->s.origin, ent->mins, ent->maxs, dest, ent, MASK_SOLID);
	if (tr.startsolid) {
		gi.dprintf("droptofloor: %s startsolid at %s\n", ent->classname, vtos(ent->s.origin));
		G_FreeEdict(ent);
		return;
	}

	VectorCopy(tr.endpos, ent->s.origin);

	if (ent->team) {
		ent->flags &= ~FL_TEAMSLAVE;
		ent->chain = ent->teamchain;
		ent->teamchain = world;

		ent->svflags |= SVF_NOCLIENT;
		ent->solid = SOLID_NOT;
		if (ent == ent->teammaster) {
			ent->nextthink = level.framenum + 1;
			ent->think = DoRespawn;
		}
	}

	if (ent->spawnflags & ITEM_NO_TOUCH) {
		ent->solid = SOLID_BBOX;
		ent->touch = 0;
		ent->s.effects &= ~EF_ROTATE;
		ent->s.renderfx &= ~RF_GLOW;
	}

	if (ent->spawnflags & ITEM_TRIGGER_SPAWN) {
		ent->svflags |= SVF_NOCLIENT;
		ent->solid = SOLID_NOT;
		ent->use = Use_Item;
	}

	gi.linkentity(ent);
}


/*
===============
PrecacheItem

Precaches all data needed for a given item.
This will be called for each item spawned in a level,
and for each item in each client's inventory.
===============
*/
void(gitem_id_t it) PrecacheItem =
{
	// FIXME
	/*char    *s, *start;
	char    data[MAX_QPATH];
	int     len;
	gitem_t *ammo;

	if (!it)
		return;

	if (it->pickup_sound)
		gi.soundindex(it->pickup_sound);
	if (it->world_model)
		gi.modelindex(it->world_model);
	if (it->view_model)
		gi.modelindex(it->view_model);
	if (it->icon)
		gi.imageindex(it->icon);

	// parse everything for its ammo
	if (it->ammo && it->ammo[0]) {
		ammo = FindItem(it->ammo);
		if (ammo != it)
			PrecacheItem(ammo);
	}

	// parse the space seperated precache string for other items
	s = it->precaches;
	if (!s || !s[0])
		return;

	while (*s) {
		start = s;
		while (*s && *s != ' ')
			s++;

		len = s - start;
		if (len >= MAX_QPATH || len < 5)
			gi.error("PrecacheItem: %s has bad precache string", it->classname);
		memcpy(data, start, len);
		data[len] = 0;
		if (*s)
			s++;

		// determine type based on extension
		if (!strcmp(data + len - 3, "md2"))
			gi.modelindex(data);
		else if (!strcmp(data + len - 3, "sp2"))
			gi.modelindex(data);
		else if (!strcmp(data + len - 3, "wav"))
			gi.soundindex(data);
		if (!strcmp(data + len - 3, "pcx"))
			gi.imageindex(data);
	}*/
}

/*
============
SpawnItem

Sets the clipping size and plants the object on the floor.

Items can't be immediately dropped to floor, because they might
be on an entity that hasn't spawned yet.
============
*/
void(entity ent, gitem_id_t it) SpawnItem =
{
	PrecacheItem(it);

	if (ent->spawnflags) {
		if (ent->classname != "key_power_cube") {
			ent->spawnflags = 0;
			gi.dprintf("%s at %s has invalid spawnflags set\n", ent->classname, vtos(ent->s.origin));
		}
	}

	// some items will be prevented in deathmatch
	if (deathmatch->intVal) {
		if (dmflags->intVal & DF_NO_ARMOR) {
			if (GetItemKeyByIndex(it, pickup) == Pickup_Armor || GetItemKeyByIndex(it, pickup) == Pickup_PowerArmor) {
				G_FreeEdict(ent);
				return;
			}
		}
		if (dmflags->intVal & DF_NO_ITEMS) {
			if (GetItemKeyByIndex(it, pickup) == Pickup_Powerup) {
				G_FreeEdict(ent);
				return;
			}
		}
		if (dmflags->intVal & DF_NO_HEALTH) {
			if (GetItemKeyByIndex(it, pickup) == Pickup_Health || GetItemKeyByIndex(it, pickup) == Pickup_Adrenaline || GetItemKeyByIndex(it, pickup) == Pickup_AncientHead) {
				G_FreeEdict(ent);
				return;
			}
		}
		if (dmflags->intVal & DF_INFINITE_AMMO) {
			if ((GetItemKeyByIndex(it, flags) == IT_AMMO) || ent->classname == "weapon_bfg") {
				G_FreeEdict(ent);
				return;
			}
		}
	}

	if (coop->intVal && ent->classname == "key_power_cube") {
		ent->spawnflags |= LShiftInt(1, (8 + level.power_cubes));
		level.power_cubes++;
	}

	// don't let them drop items that stay in a coop game
	if ((coop->intVal) && (GetItemKeyByIndex(it, flags) & IT_STAY_COOP)) {
		GetItemKeyByIndex(it, drop) = 0;
	}

	ent->item = it;
	ent->nextthink = level.framenum + 2;    // items start after other solids
	ent->think = droptofloor;
	ent->s.effects = GetItemKeyByIndex(it, world_model_flags);
	ent->s.renderfx = RF_GLOW;
	if (ent->model)
		gi.modelindex(ent->model);
}


/*QUAKED item_health (.3 .3 1) (-16 -16 -16) (16 16 16)
*/
__used static void(entity self) SP_item_health =
{
	if (deathmatch->intVal && (dmflags->intVal & DF_NO_HEALTH)) {
		G_FreeEdict(self);
		return;
	}

	self->model = "models/items/healing/medium/tris.md2";
	self->count = 10;
	SpawnItem(self, FindItem("Health"));
	gi.soundindex("items/n_health.wav");
}

/*QUAKED item_health_small (.3 .3 1) (-16 -16 -16) (16 16 16)
*/
__used static void(entity self) SP_item_health_small =
{
	if (deathmatch->intVal && (dmflags->intVal & DF_NO_HEALTH)) {
		G_FreeEdict(self);
		return;
	}

	self->model = "models/items/healing/stimpack/tris.md2";
	self->count = 2;
	SpawnItem(self, FindItem("Health"));
	self->style = HEALTH_IGNORE_MAX;
	gi.soundindex("items/s_health.wav");
}

/*QUAKED item_health_large (.3 .3 1) (-16 -16 -16) (16 16 16)
*/
__used static void(entity self) SP_item_health_large =
{
	if (deathmatch->intVal && (dmflags->intVal & DF_NO_HEALTH)) {
		G_FreeEdict(self);
		return;
	}

	self->model = "models/items/healing/large/tris.md2";
	self->count = 25;
	SpawnItem(self, FindItem("Health"));
	gi.soundindex("items/l_health.wav");
}

/*QUAKED item_health_mega (.3 .3 1) (-16 -16 -16) (16 16 16)
*/
__used static void(entity self) SP_item_health_mega =
{
	if (deathmatch->intVal && (dmflags->intVal & DF_NO_HEALTH)) {
		G_FreeEdict(self);
		return;
	}

	self->model = "models/items/mega_h/tris.md2";
	self->count = 100;
	SpawnItem(self, FindItem("Health"));
	gi.soundindex("items/m_health.wav");
	self->style = HEALTH_IGNORE_MAX | HEALTH_TIMED;
}


/*
===============
SetItemNames

Called by worldspawn
===============
*/
void() SetItemNames =
{
	int     i;

	for (i = 0 ; i < game.num_items ; i++) {
		gi.configstring(CS_ITEMS + i, GetItemKeyByIndex(i, pickup_name));
	}

	jacket_armor_index = ITEM_INDEX(FindItem("Jacket Armor"));
	combat_armor_index = ITEM_INDEX(FindItem("Combat Armor"));
	body_armor_index   = ITEM_INDEX(FindItem("Body Armor"));
	power_screen_index = ITEM_INDEX(FindItem("Power Screen"));
	power_shield_index = ITEM_INDEX(FindItem("Power Shield"));
}
