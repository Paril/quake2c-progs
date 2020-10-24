const int MAX_QPATH		= 64;	// max length of a quake game pathname

// this is a special boolean that an engine must support
// that changes how string functions/opcodes work.
// this changes:
// == and != become case-insensitive if false
// strcmp will call stricmp internally if false
// strncmp will call strnicmp internally if false
API_FUNC var bool strcasesensitive = true;

inline int(string str, int offset) strat =
{
	return str[offset];
}

int(string) stoi = #0;
float(string) stof = #0;
int(string, string) strcmp = #0;
int(string, string, int) strncmp = #0;
int(string) strlen = #0;
string(string, ...) va = #0;
int(string, string) strstr = #0;
int(string, int) strchr = #0;
string(string, int start, optional int length) substr = #0;
string(string...) strconcat = #0;
int(int) chrlwr = #0;
int(int) chrupr = #0;
string(string) strlwr = #0;
string(string) strupr = #0;

INLINE bool(string a, string b) stricmp =
{
	strcasesensitive = false;
	bool result = strcmp(a, b);
	strcasesensitive = true;
	return result;
}

INLINE bool(string a, string b, int len) strnicmp =
{
	strcasesensitive = false;
	bool result = strncmp(a, b, len);
	strcasesensitive = true;
	return result;
}

INLINE bool(string a, string b) striequals =
{
	strcasesensitive = false;
	bool result = (a == b) != 0;
	strcasesensitive = true;
	return result;
}

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
	return va("%f %f %f", v[0], v[1], v[2]);
};

/*
==============
strtok

Parse a token out of a string.
Handles C and C++ comments.
==============
*/
API_FUNC string(string data, inout int start) strtok =
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