// the "list" is a tightly packed list of variants. Every item is
// at most 12 bytes, and passed around by value.
accessor list : int;

list(optional int reserve) list_alloc = #0;
void(list, variant, int index) list_insert = #0;
void(list, variant) list_push = #0;
void(list, variant) list_unshift = #0;
void(list, int, optional out variant) list_delete = #0;
void(list, optional out variant) list_pop = #0;
void(list, optional out variant) list_shift = #0;
static int(list) list_get_length = #0;
void(list) list_clear = #0;
static variant(list, int index) list_at = #0
static void(list, int index, variant value) list_set = #0

accessor list : int
{
	get int length = list_get_length;
	
	inline get variant[int index] =
	{
		return list_at(this, index);
	};
	inline set variant[int index] =
	{
		list_set(this, index, value);
	};
};
