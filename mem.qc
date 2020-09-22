void(variant*, int, int) memset = #0;
void(variant*, variant*, int) memcpy = #0;
void(variant*, variant*, int) memmove = #0;
int(variant*, variant*, int) memcmp = #0;

inline void memclear(variant* ptr, int size)
{
	memset(ptr, 0, size);
}