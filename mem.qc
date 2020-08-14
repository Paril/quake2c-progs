void(__variant*, int, int) memset = #0;
void(__variant*, __variant*, int) memcpy = #0;
void(__variant*, __variant*, int) memmove = #0;
int(__variant*, __variant*, int) memcmp = #0;

inline void memclear(__variant* ptr, int size)
{
	memset(ptr, 0, size);
}