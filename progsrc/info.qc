inline bool(int c) isprint =
{
	return c >= 0x20 && c <= 0x7E;
};

const int MAX_INFO_KEY		= 64;
const int MAX_INFO_VALUE	= 64;
const int MAX_INFO_STRING	= 512;
/*
===============
Info_ValueForKey

Searches the string for the given
key and returns the associated value, or an empty string.
===============
*/
string(string s, string key) Info_ValueForKey =
{
	string key_string = va("\\%s\\", key);
	int key_start = strstr(s, key_string);
	
	if (key_start == -1)
		return "";

	int value_start = key_start + strlen(key_string), value_end = value_start + 1;
	
	while (true)
	{
		int c = strat(s, value_end);
		
		if (c == '\\' || !c)
			break;
		
		value_end++;
	}

	return substr(s, value_start, value_end - value_start);
};

/*
==================
Info_RemoveKey
==================
*/
string(string s, string key) Info_RemoveKey =
{
	string result = s;
	string key_string = va("\\%s\\", key);
	
	int key_start;
	while ((key_start = strstr(result, key_string)) != -1)
	{
		int value_end = key_start + strlen(key_string) + 1;
		
		while (true)
		{
			int c = strat(result, value_end);
			
			if (c == '\\' || !c)
				break;
			
			value_end++;
		}
		
		string left = "", right = "";
		
		if (key_start != 0)
			left = substr(result, 0, key_start);
		if (value_end != strlen(result))
			right = substr(result, value_end, strlen(result) - value_end);
		
		result = strconcat(left, right);
	}
	
	return result;
}

/*
==================
Info_Validate

Some characters are illegal in info strings because they
can mess up the server's parsing.
Also checks the length of keys/values and the whole string.
==================
*/
bool(string s) Info_Validate =
{
	int total = 0, offset = 0;

	while (1)
	{
		//
		// validate key
		//
		if (strat(s, offset) == '\\')
		{
			if (++total == MAX_INFO_STRING)
				return false;   // oversize infostring

			offset++;
		}
		if (!strat(s, offset))
			return false;   // missing key

		int len = 0;
		while (strat(s, offset) != '\\')
		{
			int c = strat(s, offset++);
			if (c & 128 || !isprint(c) || c == '\"' || c == ';')
				return false;   // illegal characters
			else if (++len == MAX_INFO_KEY)
				return false;   // oversize key
			else if (++total == MAX_INFO_STRING)
				return false;   // oversize infostring
			else if (!strat(s, offset))
				return false;   // missing value
		}

		//
		// validate value
		//
		offset++;
		if (++total == MAX_INFO_STRING)
			return false;   // oversize infostring
		if (!strat(s, offset))
			return false;   // missing value

		len = 0;
		while (strat(s, offset) != '\\')
		{
			int c = strat(s, offset++);
			if (c & 128 || !isprint(c) || c == '\"' || c == ';')
				return false;   // illegal characters
			else if (++len == MAX_INFO_VALUE)
				return false;   // oversize value
			else if (++total == MAX_INFO_STRING)
				return false;   // oversize infostring
			else if (!strat(s, offset))
				return true;    // end of string
		}
	}
	
	return true;
}

/*
============
Info_SubValidate
============
*/
static int(string s) Info_SubValidate =
{
	int len = 0, offset = 0;

	while (strat(s, offset))
	{
		int c = strat(s, offset++);
		if (c & 128 || !isprint(c) || c == '\\' || c == '\"' || c == ';')
			return INT_MAX;  // illegal characters
		else if (++len == MAX_QPATH)
			return MAX_QPATH;  // oversize value
	}

	return len;
}

/*
==================
Info_SetValueForKey
==================
*/
bool(inout string s, string key, string value) Info_SetValueForKey =
{
	// validate key
	int kl = Info_SubValidate(key);
	if (kl >= MAX_QPATH)
		return false;

	// validate value
	int vl = Info_SubValidate(value);
	if (vl >= MAX_QPATH)
		return false;

	s = Info_RemoveKey(s, key);
	if (!vl)
		return true;

	int l = strlen(s);
	if (l + kl + vl + 2 >= MAX_INFO_STRING)
		return false;
	
	s = strconcat(s, "\\", key, "\\", value);
	return true;
}