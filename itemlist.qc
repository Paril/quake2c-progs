// gitem_t.flags
typedef enumflags : int
{
	IT_WEAPON,       // use makes active weapon
	IT_AMMO,
	IT_ARMOR,
	IT_STAY_COOP,
	IT_KEY,
	IT_POWERUP
	
#ifdef GROUND_ZERO
	, IT_MELEE
#endif
} item_flags_t;

// gitem_t.weapmodel for weapons indicates model index
typedef enum : int
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
	
#ifdef THE_RECKONING
	, WEAP_PHALANX,
	WEAP_BOOMER
#endif

#ifdef GROUND_ZERO
	, WEAP_DISRUPTOR,
	WEAP_ETFRIFLE,
	WEAP_PLASMA,
	WEAP_PROXLAUNCH,
	WEAP_CHAINFIST
#endif
} weap_model_t;

typedef enum : int
{
	AMMO_BULLETS,
	AMMO_SHELLS,
	AMMO_ROCKETS,
	AMMO_GRENADES,
	AMMO_CELLS,
	AMMO_SLUGS,

#ifdef THE_RECKONING
	AMMO_MAGSLUG,
	AMMO_TRAP,
#endif

#ifdef GROUND_ZERO
	AMMO_FLECHETTES,
	AMMO_TESLA,
	AMMO_PROX,
	AMMO_DISRUPTOR,
#endif

	AMMO_TOTAL
} ammo_t;

enum gitem_id_t : int
{
	ITEM_NONE
};

// armor types
typedef enum : int
{
	ARMOR_NONE,
	ARMOR_JACKET,
	ARMOR_COMBAT,
	ARMOR_BODY,
	ARMOR_SHARD
} gitem_armor_id_t;

struct gitem_t;

typedef bool(entity, entity)	pickup_func;
typedef void(entity, gitem_t *)	use_func;
typedef use_func				drop_func;
typedef void(entity)			weaponthink_func;

PROGS_LOCAL const struct gitem_armor_t
{
	int		base_count;
	int		max_count;
	float	normal_protection;
	float	energy_protection;
} armor_infos[] =
{
	{ },
	{ 25,  50, .30, .00 },
	{ 50, 100, .60, .30 },
	{100, 200, .80, .60 },
	{ }
};

struct gitem_t
{
	string				classname; // spawning name
	string				pickup_str;
	string				use_str;
	string				drop_str;
	string				weaponthink_str;
	string				pickup_sound;
	string				world_model;
	entity_effects_t	world_model_flags;
	string				view_model;
	
	// client side info
	string	icon;
	string	pickup_name;   // for printing on pickup
	int		count_width;    // number of digits to display by icon
	
	int				quantity;       // for ammo how much, for weapons how much is used per shot
	string			ammo;          // for weapons
	item_flags_t	flags;          // IT_* flags
	
	weap_model_t	weapmodel;      // weapon model index (for weapons)
	
	gitem_armor_id_t	info_id;
	int					tag;
	
	string	precaches;     // string of all models, sounds, and images this item will use

	// set at load time
	pickup_func			pickup;
	use_func			use;
	drop_func			drop;
	weaponthink_func	weaponthink;

	gitem_armor_t	*info;
	int				id;
};

//======================================================================

PROGS_LOCAL var gitem_t itemlist[] =
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

#ifdef GROUND_ZERO
	/*QUAKED weapon_chainfist (.3 .3 1) (-16 -16 -16) (16 16 16) TRIGGER_SPAWN
	*/
	{
		"weapon_chainfist",									// classname
		"Pickup_Weapon",										// pickup function
		"Use_Weapon",											// use function
		"Drop_Weapon",										// drop function
		"Weapon_ChainFist",									// weapon think function
		"misc/w_pkup.wav",									// pick up sound
		"models/weapons/g_chainf/tris.md2", EF_ROTATE,		// world model, world model flags
		"models/weapons/v_chainf/tris.md2",					// view model
		"w_chainfist",										// icon
		"Chainfist",										// name printed when picked up 
		0,													// number of digits for statusbar
		0,													// amount used / contained
		0,												// ammo type used 
		IT_WEAPON | IT_MELEE,								// inventory flags
		WEAP_CHAINFIST,										// visible weapon
		0,												// info (void *)
		1,													// tag
		"weapons/sawidle.wav weapons/sawhit.wav",			// precaches
	},
#endif

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

#ifdef GROUND_ZERO
	/*QUAKED weapon_etf_rifle (.3 .3 1) (-16 -16 -16) (16 16 16) TRIGGER_SPAWN
	*/
	{
		"weapon_etf_rifle",					// classname
		"Pickup_Weapon",					// pickup function
		"Use_Weapon",						// use function
		"Drop_Weapon",						// drop function
		"Weapon_ETF_Rifle",					// weapon think function
		"misc/w_pkup.wav",					// pick up sound
		"models/weapons/g_etf_rifle/tris.md2", EF_ROTATE,	// world model, world model flags
		"models/weapons/v_etf_rifle/tris.md2",			// view model
		"w_etf_rifle",						// icon
		"ETF Rifle",						// name printed when picked up 
		0,							// number of digits for statusbar
		1,							// amount used / contained
		"Flechettes",						// ammo type used 
		IT_WEAPON,						// inventory flags
		WEAP_ETFRIFLE,						// visible weapon
		0,							// info (void *)
		0,							// tag
		"weapons/nail1.wav models/proj/flechette/tris.md2",	// precaches
	},
#endif
	
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

#ifdef THE_RECKONING
	/*QUAKED ammo_trap (.3 .3 1) (-16 -16 -16) (16 16 16)
	*/
	{
		"ammo_trap",
		"Pickup_Ammo",
		"Use_Weapon",
		"Drop_Ammo",
		"Weapon_Trap",
		"misc/am_pkup.wav",
		"models/weapons/g_trap/tris.md2", EF_ROTATE,
		"models/weapons/v_trap/tris.md2",
/* icon */		"a_trap",
/* pickup */	"Trap",
/* width */		3,
		1,
		"trap",
		IT_AMMO|IT_WEAPON,
		0,
		0,
		AMMO_TRAP,
/* precache */ "weapons/trapcock.wav weapons/traploop.wav weapons/trapsuck.wav weapons/trapdown.wav"
	},
#endif

#ifdef GROUND_ZERO
	/*QUAKED ammo_tesla (.3 .3 1) (-16 -16 -16) (16 16 16) TRIGGER_SPAWN
	*/
	{
		"ammo_tesla",
		"Pickup_Ammo",
		"Use_Weapon",						// PGM
		"Drop_Ammo",
		"Weapon_Tesla",					// PGM
		"misc/am_pkup.wav",
		"models/ammo/am_tesl/tris.md2", 0,
		"models/weapons/v_tesla/tris.md2",
		"a_tesla",
		"Tesla",
		3,
		5,
		"Tesla",												// PGM
		IT_AMMO | IT_WEAPON,						// inventory flags
		0,
		0,										// info (void *)
		AMMO_TESLA,									// tag
		"models/weapons/v_tesla2/tris.md2 weapons/teslaopen.wav weapons/hgrenb1a.wav weapons/hgrenb2a.wav models/weapons/g_tesla/tris.md2"			// precache
	},
#endif

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

#ifdef GROUND_ZERO
	/*QUAKED weapon_proxlauncher (.3 .3 1) (-16 -16 -16) (16 16 16) TRIGGER_SPAWN
	*/
	{
		"weapon_proxlauncher",								// classname
		"Pickup_Weapon",										// pickup
		"Use_Weapon",											// use
		"Drop_Weapon",										// drop
		"Weapon_GrenadeLauncher",								// weapon think
		"misc/w_pkup.wav",									// pick up sound
		"models/weapons/g_plaunch/tris.md2", EF_ROTATE,		// world model, world model flags
		"models/weapons/v_plaunch/tris.md2",				// view model
		"w_proxlaunch",										// icon
		"Prox Launcher",									// name printed when picked up
		0,													// number of digits for statusbar
		1,													// amount used
		"Prox",												// ammo type used
		IT_WEAPON,											// inventory flags
		WEAP_PROXLAUNCH,									// visible weapon
		0,												// info (void *)
		AMMO_PROX,											// tag
		"weapons/grenlf1a.wav weapons/grenlr1b.wav weapons/grenlb1b.wav weapons/proxwarn.wav weapons/proxopen.wav",
	},
#endif

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

#ifdef THE_RECKONING
	/*QUAKED weapon_boomer (.3 .3 1) (-16 -16 -16) (16 16 16)
	*/
	{
		"weapon_boomer",
		"Pickup_Weapon",
		"Use_Weapon",
		"Drop_Weapon",
		"Weapon_Ionripper",
		"misc/w_pkup.wav",
		"models/weapons/g_boom/tris.md2", EF_ROTATE,
		"models/weapons/v_boomer/tris.md2",
/* icon */	"w_ripper",
/* pickup */ "Ionripper",
		0,
		2,
		"Cells",
		IT_WEAPON,
		WEAP_BOOMER,
		0,
		0,
/* precache */ "weapons/rg_hum.wav weapons/rippfire.wav"
	},
#endif

#ifdef GROUND_ZERO
	/*QUAKED weapon_plasmabeam (.3 .3 1) (-16 -16 -16) (16 16 16) TRIGGER_SPAWN
	*/ 
	{
		"weapon_plasmabeam",								// classname
		"Pickup_Weapon",										// pickup function
		"Use_Weapon",											// use function
		"Drop_Weapon",										// drop function
		"Weapon_Heatbeam",									// weapon think function
		"misc/w_pkup.wav",									// pick up sound
		"models/weapons/g_beamer/tris.md2", EF_ROTATE,		// world model, world model flags
		"models/weapons/v_beamer/tris.md2",					// view model
		"w_heatbeam",											// icon
		"Plasma Beam",											// name printed when picked up 
		0,													// number of digits for statusbar
		// FIXME - if this changes, change it in NoAmmoWeaponChange as well
		2,													// amount used / contained
		"Cells",											// ammo type used 
		IT_WEAPON,											// inventory flags
		WEAP_PLASMA,										// visible weapon
		0,												// info (void *)
		0,													// tag
		"models/weapons/v_beamer2/tris.md2 weapons/bfg__l1a.wav",		// precaches
	},
#endif
	
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
	
#ifdef THE_RECKONING
	/*QUAKED weapon_phalanx (.3 .3 1) (-16 -16 -16) (16 16 16)
	*/
	{
		"weapon_phalanx",
		"Pickup_Weapon",
		"Use_Weapon",
		"Drop_Weapon",
		"Weapon_Phalanx",
		"misc/w_pkup.wav",
		"models/weapons/g_shotx/tris.md2", EF_ROTATE,
		"models/weapons/v_shotx/tris.md2",
/* icon */	"w_phallanx",
/* pickup */ "Phalanx",
		0,
		1,
		"Mag Slug",
		IT_WEAPON,
		WEAP_PHALANX,
		0,
		0,
/* precache */ "weapons/plasshot.wav"
	},
#endif

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
		/* precache */ "sprites/s_bfg1.sp2 sprites/s_bfg2.sp2 sprites/s_bfg3.sp2 weapons/bfg__f1y.wav weapons/bfg__l1a.wav weapons/bfg_.x1b.wav weapons/bfg_hum.wav"
	},

#ifdef GROUND_ZERO
	/*QUAKED weapon_disintegrator (.3 .3 1) (-16 -16 -16) (16 16 16) TRIGGER_SPAWN
	*/
	{
		"weapon_disintegrator",								// classname
		"Pickup_Weapon",										// pickup function
		"Use_Weapon",											// use function
		"Drop_Weapon",										// drop function
		"Weapon_Disintegrator",								// weapon think function
		"misc/w_pkup.wav",									// pick up sound
		"models/weapons/g_dist/tris.md2", EF_ROTATE,		// world model, world model flags
		"models/weapons/v_dist/tris.md2",					// view model
		"w_disintegrator",									// icon
		"Disruptor",										// name printed when picked up 
		0,													// number of digits for statusbar
		1,													// amount used / contained
		"Rounds",
		IT_WEAPON,											// inventory flags
		WEAP_DISRUPTOR,										// visible weapon
		0,												// info (void *)
		1,													// tag
		"models/items/spawngro/tris.md2 models/proj/disintegrator/tris.md2 weapons/disrupt.wav weapons/disint2.wav weapons/disrupthit.wav",	// precaches
	},
#endif

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

#ifdef THE_RECKONING
/*QUAKED ammo_magslug (.3 .3 1) (-16 -16 -16) (16 16 16)
*/
	{
		"ammo_magslug",
		"Pickup_Ammo",
		0,
		"Drop_Ammo",
		0,
		"misc/am_pkup.wav",
		"models/objects/ammo/tris.md2", 0,
		0,
/* icon */		"a_mslugs",
/* pickup */	"Mag Slug",
/* width */		3,
		10,
		0,
		IT_AMMO,
		0,
		0,
		AMMO_MAGSLUG,
/* precache */ ""
	},
#endif

#ifdef GROUND_ZERO
	/*QUAKED ammo_flechettes (.3 .3 1) (-16 -16 -16) (16 16 16) TRIGGER_SPAWN
	*/
	{
		"ammo_flechettes",
		"Pickup_Ammo",
		0,
		"Drop_Ammo",
		0,
		"misc/am_pkup.wav",
		"models/ammo/am_flechette/tris.md2", 0,
		0,
		"a_flechettes",
		"Flechettes",
		3,
		50,
		0,
		IT_AMMO,
		0,
		0,
		AMMO_FLECHETTES
	},

	/*QUAKED ammo_prox (.3 .3 1) (-16 -16 -16) (16 16 16) TRIGGER_SPAWN
	*/
	{
		"ammo_prox",										// Classname
		"Pickup_Ammo",										// pickup function
		0,												// use function
		"Drop_Ammo",											// drop function
		0,												// weapon think function
		"misc/am_pkup.wav",									// pickup sound
		"models/ammo/am_prox/tris.md2", 0,					// world model, world model flags
		0,												// view model
		"a_prox",											// icon
		"Prox",												// Name printed when picked up
		3,													// number of digits for status bar
		5,													// amount contained
		0,												// ammo type used
		IT_AMMO,											// inventory flags
		0,													// vwep index
		0,												// info (void *)
		AMMO_PROX,											// tag
		"models/weapons/g_prox/tris.md2 weapons/proxwarn.wav"	// precaches
	},

	/*QUAKED ammo_nuke (.3 .3 1) (-16 -16 -16) (16 16 16) TRIGGER_SPAWN
	*/
	{
		"ammo_nuke",
		"Pickup_Nuke",
		"Use_Nuke",						// PMM
		"Drop_Ammo",
		0,							// PMM
		"misc/am_pkup.wav",
		"models/weapons/g_nuke/tris.md2", EF_ROTATE,
		0,
/* icon */		"p_nuke",
/* pickup */	"A-M Bomb",
/* width */		3,
		300, /* quantity (used for respawn time) */
		"A-M Bomb",
		IT_POWERUP,	
		0,
		0,
		0,
		"weapons/nukewarn2.wav world/rumble.wav"
	},

	/*QUAKED ammo_disruptor (.3 .3 1) (-16 -16 -16) (16 16 16) TRIGGER_SPAWN
	*/
	{
		"ammo_disruptor",
		"Pickup_Ammo",
		0,
		"Drop_Ammo",
		0,
		"misc/am_pkup.wav",
		"models/ammo/am_disr/tris.md2", 0,
		0,
		"a_disruptor",
		"Rounds",		// FIXME 
		3,
		15,
		0,
		IT_AMMO,											// inventory flags
		0,
		0,
		AMMO_DISRUPTOR,
	},
#endif

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

	
#ifdef THE_RECKONING
	/*QUAKED item_quadfire (.3 .3 1) (-16 -16 -16) (16 16 16)
	*/
	{
		"item_quadfire", 
		"Pickup_Powerup",
		"Use_QuadFire",
		"Drop_General",
		0,
		"items/pkup.wav",
		"models/items/quadfire/tris.md2", EF_ROTATE,
		0,
/* icon */		"p_quadfire",

/* pickup */	"DualFire Damage",
/* width */		2,
		60,
		0,
		IT_POWERUP,
		0,
		0,
		0,
/* precache */ "items/quadfire1.wav items/quadfire2.wav items/quadfire3.wav"
	},
#endif

#ifdef GROUND_ZERO
	/*QUAKED item_ir_goggles (.3 .3 1) (-16 -16 -16) (16 16 16) TRIGGER_SPAWN
	gives +1 to maximum health
	*/
	{
		"item_ir_goggles",
		"Pickup_Powerup",
		"Use_IR",
		"Drop_General",
		0,
		"items/pkup.wav",
		"models/items/goggles/tris.md2", EF_ROTATE,
		0,
/* icon */		"p_ir",
/* pickup */	"IR Goggles",
/* width */		2,
		60,
		0,
		IT_POWERUP,
		0,
		0,
		0,
/* precache */ "misc/ir_start.wav"
	},

	/*QUAKED item_double (.3 .3 1) (-16 -16 -16) (16 16 16) TRIGGER_SPAWN
	*/
	{
		"item_double", 
		"Pickup_Powerup",
		"Use_Double",
		"Drop_General",
		0,
		"items/pkup.wav",
		"models/items/ddamage/tris.md2", EF_ROTATE,
		0,
/* icon */		"p_double",
/* pickup */	"Double Damage",
/* width */		2,
		60,
		0,
		IT_POWERUP,
		0,
		0,
		0,
/* precache */ "misc/ddamage1.wav misc/ddamage2.wav misc/ddamage3.wav"
	},
#endif

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

#ifdef THE_RECKONING
	/*QUAKED key_green_key (0 .5 .8) (-16 -16 -16) (16 16 16)
	normal door key - blue
	*/
	{
		"key_green_key",
		"Pickup_Key",
		0,
		"Drop_General",
		0,
		"items/pkup.wav",
		"models/items/keys/green_key/tris.md2", EF_ROTATE,
		0,
		"k_green",
		"Green Key",
		2,
		0,
		0,
		IT_STAY_COOP|IT_KEY,
		0,
		0,
		0,
/* precache */ ""
	},
#endif

#ifdef GROUND_ZERO
	/*QUAKED key_nuke_container (.3 .3 1) (-16 -16 -16) (16 16 16) TRIGGER_SPAWN
	*/
	{
		"key_nuke_container",								// classname
		"Pickup_Key",											// pickup function
		0,												// use function
		"Drop_General",										// drop function
		0,												// weapon think function
		"items/pkup.wav",									// pick up sound
		"models/weapons/g_nuke/tris.md2",					// world model
		EF_ROTATE,											// world model flags
		0,												// view model
		"i_contain",										// icon
		"Antimatter Pod",									// name printed when picked up 
		2,													// number of digits for statusbar
		0,													// respawn time
		0,												// ammo type used 
		IT_STAY_COOP|IT_KEY,								// inventory flags
		0,
		0,												// info (void *)
		0,													// tag
		0,												// precaches
	},

	/*QUAKED key_nuke (.3 .3 1) (-16 -16 -16) (16 16 16) TRIGGER_SPAWN
	*/
	{
		"key_nuke",											// classname
		"Pickup_Key",											// pickup function
		0,												// use function
		"Drop_General",										// drop function
		0,												// weapon think function
		"items/pkup.wav",									// pick up sound
		"models/weapons/g_nuke/tris.md2",					// world model
		EF_ROTATE,											// world model flags
		0,												// view model
		"i_nuke",											// icon
		"Antimatter Bomb",									// name printed when picked up 
		2,													// number of digits for statusbar
		0,													// respawn time
		0,												// ammo type used 
		IT_STAY_COOP|IT_KEY,								// inventory flags
		0,
		0,												// info (void *)
		0,													// tag
		0,												// precaches
	},
#endif

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