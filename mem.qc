void(variant *ptr, int value, int size) memset = #0;
void(variant *dst, variant *src, int size) memcpy = #0;
void(variant *dst, variant *src, int size) memmove = #0;
int(variant *a, variant *b, int size) memcmp = #0;

inline void memclear(variant *ptr, int size)
{
	memset(ptr, 0, size);
}