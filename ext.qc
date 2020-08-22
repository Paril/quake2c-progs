#pragma warning disable Q208 // we're valid darn you >:(
#pragma warning enable F302 // uninitialised locals
#pragma warning disable Q205
#pragma warning disable F322
#pragma warning disable Q207
#pragma warning disable F306
#pragma warning disable F327 // multiple bits set for enumflag

#pragma warning error Q101 /*too many parms. The vanilla qcc didn't validate properly, hence why fteqcc normally treats it as a warning.*/
#pragma warning error Q105 /*too few parms. The vanilla qcc didn't validate properly, hence why fteqcc normally treats it as a warning.*/
#pragma warning error Q106 /*assignment to constant/lvalue. Define them as var if you want to initialise something.*/
#pragma warning enable F301 /*non-utf-8 strings. Think of the foreigners! Also think of text editors that insist on screwing up your char encodings.*/

#pragma target fte_9999

#define INLINE /*inline*/

// not strictly math, but...
typedef enum : int
{
	false,
	true
} bool;

accessor handle : int;

const handle null_handle = 0;

inline bool(variant p) handle_empty =
{
	return !(handle)p;
}

void(handle) handle_free = #0;

int(int, int) ModInt = #0;

variant(string) func_get = #0;

// function is visible to func_get and to the game code
#define API_FUNC used

#define PROGS_LOCAL nosave
#define PROGS_LOCAL_STATIC static PROGS_LOCAL

// define for mission pack support
#define GROUND_ZERO
#define THE_RECKONING

// if you want to make a mod using *optional* KMQuake2-specific features, enable this.
#define KMQUAKE2_SUPPORT

// if you want to make a mod that uses *non-compatible* KMQuake2-specific features, enable this.
// Note that these features will not work with other engines
#define KMQUAKE2_EXTENSIONS

// if you want to use your own PMove function or you're
// using an engine that needs custom PMove, you can
// uncomment this and edit pmove.qc
//#define QUAKEC_PMOVE