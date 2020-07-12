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
string(string, int start, optional int length) substr = #0:substr;
string(string...) strconcat = #0:strconcat;

#define strempty(s) (s == "")

string null_string = "";

string(vector v) vtos =
{
	return va("%f %f %f", v[(ARRAY_INDEX_TYPE)0], v[(ARRAY_INDEX_TYPE)1], v[(ARRAY_INDEX_TYPE)2]);
}