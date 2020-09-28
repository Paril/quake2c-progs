#ifndef PRETTIFIED
/* @SINGLE_PLAYER@ Enable single-player support. This includes monsters, save/load, and any code related to
making AI/single player work properly. */
#define SINGLE_PLAYER

/* @GROUND_ZERO@ Ground Zero support. This includes all of the Ground Zero entities/weapons,
AI improvements, etc. This also includes the g_legacy_trains cvar, which is required to make old maps work. */
#define GROUND_ZERO

/* @THE_RECKONING@ The Reckoning support. This includes all of The Reckoning entities/weapons. */
#define THE_RECKONING

/* @KMQUAKE2_SUPPORT@ Optional KMQuake2 features. This gives you access to file loading APIs,
which are polyfilled for non-KMQuake2 engines. */
#define KMQUAKE2_SUPPORT

/* @KMQUAKE2_EXTENSIONS@ KMQuake2-specific features. This gives you access to certain additions
that KMQuake2 may make. These features will not work on non-KMQuake2 engines, but your mod will still function. */
#define KMQUAKE2_EXTENSIONS

/* @QUAKEC_PMOVE@ QuakeC PMove. By default, Quake2C uses the PMove export from the engine; if you wish to create
a custom player movement system, you can use Y here and edit pmove.qc. Please note that QuakeC PMove
may cause significant performance degradation with lots of players. */
#define QUAKEC_PMOVE
#endif

// Uncomment to do a debug build
//#define DEBUG