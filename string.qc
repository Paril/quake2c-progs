const int MAX_TOKEN_CHARS	= 1024;	// max length of an individual token
const int MAX_QPATH		= 64;	// max length of a quake game pathname

string(int) itos = #0:itos;
int(string) stoi = #0:stoi;
string(float) ftos = #0:ftos;
float(string) stof = #0:stof;

int(string, string) stricmp = #0:stricmp;
int(string, string, int) strncmp = #0:strncmp;
string(string, __inout int) strtok = #0:strtok;
int(string) strlen = #0:strlen;
int(string, int) strat = #0:strat;
string(string, ...) va = #0:va;
bool(string, string) strstr = #0:strstr;
int(string, int) strchr = #0:strchr;

#define strempty(s) (s == "")

string null_string = "";

typedef enum : string {
	null_dynstring = ""
} dynstring;

void(dynstring) dynstring_acquire = #0:dynstring_acquire;
void(dynstring) dynstring_release = #0:dynstring_release;
dynstring(string) dynstring_create = #0:dynstring_create;
dynstring(int) dynstring_alloc = #0:dynstring_alloc;
void(dynstring, string) dynstring_append = #0:dynstring_append;
string(string, int start, optional int length) substr = #0:substr;

#define dynstring_str(s) (string)(__variant)(s)
#define string_dynstring(s) (dynstring)(__variant)(s)

// FIXME: inline breaks this one
dynstring(dynstring s) dynstring_copy =
{
	dynstring_acquire(s);
	return s;
};

string(vector v) vtos =
{
	return va("%f %f %f", v[(ARRAY_INDEX_TYPE)0], v[(ARRAY_INDEX_TYPE)1], v[(ARRAY_INDEX_TYPE)2]);
}