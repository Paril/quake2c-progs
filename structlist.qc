// the "structlist" is a tightly packed array of structure data. Every item
// must have the same size, and the structure uses pointers to communicate
// data back and forth. As a result, this is efficient for larger structures, but
// not for smaller ones. For structures that are 12 bytes or less, you can use
// the regular list type, which will be more efficient/safer. Note that since
// this structure deals with pointers, growing the list will effectively invalidate any
// pointers that were previously returned from the list. Storing these pointers
// is only safe if the list's size remains at or below its maximum reserve size.
accessor structlist : int;

structlist(int item_size, optional int reserve) structlist_alloc = #0;
void(structlist, variant*, int index) structlist_insert = #0;
void(structlist, variant*) structlist_push = #0;
void(structlist, variant*) structlist_unshift = #0;
void(structlist, int, optional variant*) structlist_delete = #0;
void(structlist, optional variant*) structlist_pop = #0;
void(structlist, optional variant*) structlist_shift = #0;
static int(structlist) structlist_get_length = #0;
void(structlist) structlist_clear = #0;
static variant*(structlist, int index) structlist_at = #0
static void(structlist, int index, variant *) structlist_value_at = #0
void(structlist, int) structlist_resize = #0;

accessor structlist : int
{
	get int length = structlist_get_length;
	
	inline get variant*[int index] =
	{
		return structlist_at(this, index);
	};
};
