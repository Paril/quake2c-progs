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
#pragma warning disable F312 /*numerical overflow - not applicable to Quake2C*/

#pragma target quake2c

#pragma opcode disable BOUNDCHECK

#pragma optimise 3

// this is just because kce is not allowed midcompile yet
#pragma flag enable kce
#define out __out
#define used __used
#define inout __inout
#define int __int

#pragma opcode disable STORE_I64

#pragma flag enable lo
#pragma flag enable nullemptystr
#pragma flag enable subscope
#pragma flag enable fastarrays
#pragma flag enable assumeint
#pragma flag enable verbose
#pragma flag enable typeexplicit
#pragma flag enable iffloat
#pragma flag enable ifvector
#pragma flag enable vectorlogic

#ifdef DEBUG
#pragma optimize no-constant_names_strings
#pragma optimize no-constant_names
#pragma optimize no-locals
#pragma optimize no-function_names
#pragma optimize no-filenames
#pragma optimize no-return_only
#pragma optimize no-compound_jumps
#pragma optimize no-strip_functions
#pragma optimize no-locals_overlapping
#pragma optimize no-vectorcalls
#pragma optimize no-class_fields
#pragma optimize no-strip_unused_fields

#pragma flag disable boundchecks
#endif

#define INLINE /*inline*/

// not strictly math, but...
typedef enum : int
{
	false,
	true
} bool;

accessor handle : int;

const handle null_handle = (handle)0;

inline bool(variant p) handle_empty =
{
	return !(handle)p;
};

void(handle) handle_free = #0;

int(int, int) ModInt = #0;

variant(string) func_get = #0;

typedef int(variant *a, variant *b, optional variant *ctx) qsort_comparator;

void(variant* elements, int num, int size_of_element, qsort_comparator compar, optional variant *ctx) qsort = #0;

// function is visible to func_get and to the game code
#define API_FUNC used

#define PROGS_LOCAL nosave
#define PROGS_LOCAL_STATIC static PROGS_LOCAL