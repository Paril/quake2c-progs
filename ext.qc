#pragma warning disable Q208 // we're valid darn you >:(
#pragma warning enable F302
#pragma warning disable Q205
#pragma warning disable F322
#pragma warning disable Q207
#pragma warning disable F306
#pragma target fte_9999

int(int, int) ModInt = #0:ModInt;

__variant(string) func_get = #0:func_get;

// function is visible to func_get and to the game code
#define API_FUNC __used

#define PROGS_LOCAL nosave
#define PROGS_LOCAL_STATIC static PROGS_LOCAL

// define for mission pack support
#define GROUND_ZERO
#define THE_RECKONING

// temp
#ifdef GROUND_ZERO
const float MAX_SIDESTEP	= 8.0;
#endif