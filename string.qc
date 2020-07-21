const int MAX_TOKEN_CHARS	= 1024;	// max length of an individual token
const int MAX_QPATH		= 64;	// max length of a quake game pathname

//int(string, int) strat = #0:strat;
inline int(string str, int offset) strat =
{
	return (int)(__variant)str[(float)(__variant)offset];
};

int(string) stoi = #0:stoi;
float(string) stof = #0:stof;
int(string, string) stricmp = #0:stricmp;
int(string, string, int) strncmp = #0:strncmp;
int(string) strlen = #0:strlen;
string(string, ...) va = #0:va;
int(string, string) strstr = #0:strstr;
int(string, int) strchr = #0:strchr;
string(string, int start, optional int length) substr = #0:substr;
string(string...) strconcat = #0:strconcat;

#define strempty(s) (!(s))

inline string(int v) itos =
{
	return va("%i", v);
};

inline string(float v) ftos =
{
	return va("%f", v);
};

inline string(vector v) vtos =
{
	return va("%f %f %f", v_x, v_y, v_z);
};

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

/*
==============
strtok

Parse a token out of a string.
Handles C and C++ comments.
==============
*/
string(string data, __inout int start) strtok =
{
	int token_start = start, token_end;

	if (!strat(data, 0))
	{
		start = -1;
		return "";
	}

// skip whitespace
	int c;

skipwhite:
	while ((c = strat(data, token_start)) <= ' ')
	{
		if (c == 0)
		{
			start = -1;
			return "";
		}
		token_start++;
	}

// skip // comments
	if (c == '/' && strat(data, token_start + 1) == '/')
	{
		token_start += 2;

		while ((c = strat(data, token_start)) && c != '\n')
			token_start++;
		
		goto skipwhite;
	}

// skip /* */ comments
	if (c == '/' && strat(data, token_start + 1) == '*')
	{
		token_start += 2;
		while ((c = strat(data, token_start)))
		{
			if (c == '*' && strat(data, token_start + 1) == '/')
			{
				token_start += 2;
				break;
			}
			token_start++;
		}
		goto skipwhite;
	}

	token_end = token_start;

// handle quoted strings specially
	if (c == '\"')
	{
		token_end++;
		while ((c = strat(data, token_end++)) && c != '\"') ;

		if (!strat(data, token_end))
			start = -1;
		else
			start = token_end;

		return substr(data, token_start + 1, token_end - token_start - 2);
	}

// parse a regular word
	do
	{
		token_end++;
		c = strat(data, token_end);
	} while (c > 32);

	if (!strat(data, token_end))
		start = -1;
	else
		start = token_end;

	return substr(data, token_start, token_end - token_start);
};