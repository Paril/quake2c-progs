#pragma warning disable Q208 // we're valid darn you >:(
#pragma warning enable F302
#pragma warning disable Q205
#pragma warning disable F322
#pragma warning disable Q207
#pragma warning disable F306
#pragma target fte_9999

#define INLINE /*inline*/

// not strictly math, but...
typedef enum : int
{
	false,
	true
} bool;

typedef enum : vector { null_pointer = [ 0, 0, 0 ] } pointer;

inline bool handle_empty(__variant p)
{
	return (pointer)p == null_pointer;
}

int(int, int) ModInt = #0;

__variant(string) func_get = #0;

// function is visible to func_get and to the game code
#define API_FUNC __used

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