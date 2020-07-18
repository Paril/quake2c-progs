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

typedef bool(entity, entity)		pickup_func;
typedef void(entity, gitem_id_t)	use_func;
typedef use_func			drop_func;
typedef void(entity)			weaponthink_func;

struct gitem_t
{
	string			classname; // spawning name
	string			pickup_str;
	string			use_str;
	string			drop_str;
	string			weaponthink_str;
	string			pickup_sound;
	string			world_model;
	entity_effects_t	world_model_flags;
	string			view_model;
	
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

	// set at load time
	pickup_func		pickup;
	use_func		use;
	drop_func		drop;
	weaponthink_func	weaponthink;
};

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

#define GetArmorInfoKeyByIndex(index, key) armor_infos[index].key

//======================================================================

var gitem_t itemlist[] =
{
	// leave index 0 alone
	{ },

	//
	// ARMOR
	//

	/*QUAKED item_armor_body (.3 .3 1) (-16 -16 -16) (16 16 16)
	*/
	{
		"item_armor_body",
		"Pickup_Armor",
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
	},

	/*QUAKED item_armor_combat (.3 .3 1) (-16 -16 -16) (16 16 16)
	*/
	{
		"item_armor_combat",
		"Pickup_Armor",
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
	},

	/*QUAKED item_armor_jacket (.3 .3 1) (-16 -16 -16) (16 16 16)
	*/
	{
		"item_armor_jacket",
		"Pickup_Armor",
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
	},

	/*QUAKED item_armor_shard (.3 .3 1) (-16 -16 -16) (16 16 16)
	*/
	{
		"item_armor_shard",
		"Pickup_Armor",
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
	},


	/*QUAKED item_power_screen (.3 .3 1) (-16 -16 -16) (16 16 16)
	*/
	{
		"item_power_screen",
		"Pickup_PowerArmor",
		"Use_PowerArmor",
		"Drop_PowerArmor",
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
	},

	/*QUAKED item_power_shield (.3 .3 1) (-16 -16 -16) (16 16 16)
	*/
	{
		"item_power_shield",
		"Pickup_PowerArmor",
		"Use_PowerArmor",
		"Drop_PowerArmor",
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
	},


	//
	// WEAPONS
	//

	/* weapon_blaster (.3 .3 1) (-16 -16 -16) (16 16 16)
	always owned, never in the world
	*/
	{
		"weapon_blaster",
		0,
		"Use_Weapon",
		0,
		"Weapon_Blaster",
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
		/* precache */ "weapons/blastf1a.wav misc/lasfly.wav models/objects/laser/tris.md2"
	},

	/*QUAKED weapon_shotgun (.3 .3 1) (-16 -16 -16) (16 16 16)
	*/
	{
		"weapon_shotgun",
		"Pickup_Weapon",
		"Use_Weapon",
		"Drop_Weapon",
		"Weapon_Shotgun",
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
	},

	/*QUAKED weapon_supershotgun (.3 .3 1) (-16 -16 -16) (16 16 16)
	*/
	{
		"weapon_supershotgun",
		"Pickup_Weapon",
		"Use_Weapon",
		"Drop_Weapon",
		"Weapon_SuperShotgun",
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
	},

	/*QUAKED weapon_machinegun (.3 .3 1) (-16 -16 -16) (16 16 16)
	*/
	{
		"weapon_machinegun",
		"Pickup_Weapon",
		"Use_Weapon",
		"Drop_Weapon",
		"Weapon_Machinegun",
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
	},

	/*QUAKED weapon_chaingun (.3 .3 1) (-16 -16 -16) (16 16 16)
	*/
	{
		"weapon_chaingun",
		"Pickup_Weapon",
		"Use_Weapon",
		"Drop_Weapon",
		"Weapon_Chaingun",
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
	},

	/*QUAKED ammo_grenades (.3 .3 1) (-16 -16 -16) (16 16 16)
	*/
	{
		"ammo_grenades",
		"Pickup_Ammo",
		"Use_Weapon",
		"Drop_Ammo",
		"Weapon_Grenade",
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
	},

	/*QUAKED weapon_grenadelauncher (.3 .3 1) (-16 -16 -16) (16 16 16)
	*/
	{
		"weapon_grenadelauncher",
		"Pickup_Weapon",
		"Use_Weapon",
		"Drop_Weapon",
		"Weapon_GrenadeLauncher",
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
	},

	/*QUAKED weapon_rocketlauncher (.3 .3 1) (-16 -16 -16) (16 16 16)
	*/
	{
		"weapon_rocketlauncher",
		"Pickup_Weapon",
		"Use_Weapon",
		"Drop_Weapon",
		"Weapon_RocketLauncher",
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
	},

	/*QUAKED weapon_hyperblaster (.3 .3 1) (-16 -16 -16) (16 16 16)
	*/
	{
		"weapon_hyperblaster",
		"Pickup_Weapon",
		"Use_Weapon",
		"Drop_Weapon",
		"Weapon_HyperBlaster",
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
	},

	/*QUAKED weapon_railgun (.3 .3 1) (-16 -16 -16) (16 16 16)
	*/
	{
		"weapon_railgun",
		"Pickup_Weapon",
		"Use_Weapon",
		"Drop_Weapon",
		"Weapon_Railgun",
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
	},

	/*QUAKED weapon_bfg (.3 .3 1) (-16 -16 -16) (16 16 16)
	*/
	{
		"weapon_bfg",
		"Pickup_Weapon",
		"Use_Weapon",
		"Drop_Weapon",
		"Weapon_BFG",
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
	},

	//
	// AMMO ITEMS
	//

	/*QUAKED ammo_shells (.3 .3 1) (-16 -16 -16) (16 16 16)
	*/
	{
		"ammo_shells",
		"Pickup_Ammo",
		0,
		"Drop_Ammo",
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
	},

	/*QUAKED ammo_bullets (.3 .3 1) (-16 -16 -16) (16 16 16)
	*/
	{
		"ammo_bullets",
		"Pickup_Ammo",
		0,
		"Drop_Ammo",
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
	},

	/*QUAKED ammo_cells (.3 .3 1) (-16 -16 -16) (16 16 16)
	*/
	{
		"ammo_cells",
		"Pickup_Ammo",
		0,
		"Drop_Ammo",
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
	},

	/*QUAKED ammo_rockets (.3 .3 1) (-16 -16 -16) (16 16 16)
	*/
	{
		"ammo_rockets",
		"Pickup_Ammo",
		0,
		"Drop_Ammo",
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
	},

	/*QUAKED ammo_slugs (.3 .3 1) (-16 -16 -16) (16 16 16)
	*/
	{
		"ammo_slugs",
		"Pickup_Ammo",
		0,
		"Drop_Ammo",
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
	},


	//
	// POWERUP ITEMS
	//
	/*QUAKED item_quad (.3 .3 1) (-16 -16 -16) (16 16 16)
	*/
	{
		"item_quad",
		"Pickup_Powerup",
		"Use_Quad",
		"Drop_General",
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
	},

	/*QUAKED item_invulnerability (.3 .3 1) (-16 -16 -16) (16 16 16)
	*/
	{
		"item_invulnerability",
		"Pickup_Powerup",
		"Use_Invulnerability",
		"Drop_General",
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
	},

	/*QUAKED item_silencer (.3 .3 1) (-16 -16 -16) (16 16 16)
	*/
	{
		"item_silencer",
		"Pickup_Powerup",
		"Use_Silencer",
		"Drop_General",
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
	},

	/*QUAKED item_breather (.3 .3 1) (-16 -16 -16) (16 16 16)
	*/
	{
		"item_breather",
		"Pickup_Powerup",
		"Use_Breather",
		"Drop_General",
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
	},

	/*QUAKED item_enviro (.3 .3 1) (-16 -16 -16) (16 16 16)
	*/
	{
		"item_enviro",
		"Pickup_Powerup",
		"Use_Envirosuit",
		"Drop_General",
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
	},

	/*QUAKED item_ancient_head (.3 .3 1) (-16 -16 -16) (16 16 16)
	Special item that gives +2 to maximum health
	*/
	{
		"item_ancient_head",
		"Pickup_AncientHead",
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
	},

	/*QUAKED item_adrenaline (.3 .3 1) (-16 -16 -16) (16 16 16)
	gives +1 to maximum health
	*/
	{
		"item_adrenaline",
		"Pickup_Adrenaline",
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
	},

	/*QUAKED item_bandolier (.3 .3 1) (-16 -16 -16) (16 16 16)
	*/
	{
		"item_bandolier",
		"Pickup_Bandolier",
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
	},

	/*QUAKED item_pack (.3 .3 1) (-16 -16 -16) (16 16 16)
	*/
	{
		"item_pack",
		"Pickup_Pack",
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
	},

	//
	// KEYS
	//
	/*QUAKED key_data_cd (0 .5 .8) (-16 -16 -16) (16 16 16)
	key for computer centers
	*/
	{
		"key_data_cd",
		"Pickup_Key",
		0,
		"Drop_General",
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
	},

	/*QUAKED key_power_cube (0 .5 .8) (-16 -16 -16) (16 16 16) TRIGGER_SPAWN NO_TOUCH
	warehouse circuits
	*/
	{
		"key_power_cube",
		"Pickup_Key",
		0,
		"Drop_General",
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
	},

	/*QUAKED key_pyramid (0 .5 .8) (-16 -16 -16) (16 16 16)
	key for the entrance of jail3
	*/
	{
		"key_pyramid",
		"Pickup_Key",
		0,
		"Drop_General",
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
	},

	/*QUAKED key_data_spinner (0 .5 .8) (-16 -16 -16) (16 16 16)
	key for the city computer
	*/
	{
		"key_data_spinner",
		"Pickup_Key",
		0,
		"Drop_General",
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
	},

	/*QUAKED key_pass (0 .5 .8) (-16 -16 -16) (16 16 16)
	security pass for the security level
	*/
	{
		"key_pass",
		"Pickup_Key",
		0,
		"Drop_General",
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
	},

	/*QUAKED key_blue_key (0 .5 .8) (-16 -16 -16) (16 16 16)
	normal door key - blue
	*/
	{
		"key_blue_key",
		"Pickup_Key",
		0,
		"Drop_General",
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
	},

	/*QUAKED key_red_key (0 .5 .8) (-16 -16 -16) (16 16 16)
	normal door key - red
	*/
	{
		"key_red_key",
		"Pickup_Key",
		0,
		"Drop_General",
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
	},

	/*QUAKED key_commander_head (0 .5 .8) (-16 -16 -16) (16 16 16)
	tank commander's head
	*/
	{
		"key_commander_head",
		"Pickup_Key",
		0,
		"Drop_General",
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
	},

	/*QUAKED key_airstrike_target (0 .5 .8) (-16 -16 -16) (16 16 16)
	tank commander's head
	*/
	{
		"key_airstrike_target",
		"Pickup_Key",
		0,
		"Drop_General",
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
	},

	{
		0,
		"Pickup_Health",
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
	}
};