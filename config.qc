/*@@ { "macro": "SINGLE_PLAYER", "desc": "Enable single-player support. This includes monsters, save/load, and any code related to making AI/single player work properly." } @@*/
#define SINGLE_PLAYER

/*@@ { "macro": "CTF", "desc": "Enable CTF support. This includes the techs/flags, the \"ctf\" cvar, and other gamemode-specific changes to make CTF work.", "requires": [ "PMENU", "GRAPPLE" ] } @@*/
#define CTF

/*@@ { "macro": "HOOK_CODE", "desc": "Enables the underlying code for a grappling hook." } @@*/
#define HOOK_CODE

/*@@ { "macro": "GRAPPLE", "desc": "Enables the CTF Grapple weapon.", "depends": [ "HOOK_CODE" ] } @@*/
#define GRAPPLE

/*@@ { "macro": "OFFHAND_HOOK", "desc": "Enables off-hand hook commands.", "depends": [ "HOOK_CODE" ] } @@*/
#define OFFHAND_HOOK

/*@@ { "macro": "HOOK_STANDARD_ASSETS", "desc": "The CTF assets for the hook are a bit buggy (especially the sounds); this will replace them with vanilla assets.", "depends": [ "HOOK_CODE" ] } @@*/
#define HOOK_STANDARD_ASSETS

/*@@ { "macro": "PMENU", "desc": "Enable PMenu support. This is solely a developer feature, allowing you to make simple interactive menus (like the ones used in CTF)." } @@*/
#define PMENU

/*@@ { "macro": "GROUND_ZERO", "desc": "Ground Zero support. This includes all of the Ground Zero entities/weapons, AI improvements, etc. This also includes the g_legacy_trains cvar, which is required to make old maps with teamed trains work." } @@*/
#define GROUND_ZERO

/*@@ { "macro": "THE_RECKONING", "desc": "The Reckoning support. This includes all of The Reckoning entities/weapons." } @@*/
#define THE_RECKONING

/*@@ { "macro": "KMQUAKE2_SUPPORT", "desc": "Optional KMQuake2 features. This gives you access to file loading APIs, which are polyfilled for non-KMQuake2 engines." } @@*/
#define KMQUAKE2_SUPPORT

/*@@ { "macro": "KMQUAKE2_EXTENSIONS", "desc": "KMQuake2-specific features. This gives you access to certain additions that KMQuake2 adds, such as extra modelindex slots or gunindexes. These features will not work on non-KMQuake2 engines, but your mod will still function." } @@*/
#define KMQUAKE2_EXTENSIONS

/*@@ { "macro": "QUAKEC_PMOVE", "desc": "QuakeC PMove. By default, Quake2C uses the PMove export from the engine; if you wish to create a custom player movement system, you can use Y here and edit pmove.qc. Please note that QuakeC PMove may cause significant performance degradation with lots of players." } @@*/
//#define QUAKEC_PMOVE

#ifndef DEBUG
// Uncomment to do a debug build, if you're using the GUI
#define DEBUG
#endif
