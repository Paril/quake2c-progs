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

// FIXME: time.qc?
struct time_t
{
	int tm_sec;   // seconds after the minute - [0, 60] including leap second
	int tm_min;   // minutes after the hour - [0, 59]
	int tm_hour;  // hours since midnight - [0, 23]
	int tm_mday;  // day of the month - [1, 31]
	int tm_mon;   // months since January - [0, 11]
	int tm_year;  // years since 1900
	int tm_wday;  // days since Sunday - [0, 6]
	int tm_yday;  // days since January 1 - [0, 365]
	int tm_isdst; // daylight savings time flag
};

void(__out time_t tm) localtime = #0:localtime;