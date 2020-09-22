// The "hashset" type is a strong hash set of values. It can store any type of "type".
// If strings are stored, a ref to them is kept, so this can not be used as a weak set.
// Their absolute positions are kept track of, so iteration is constant time, but
// removals may shift the whole index table which might mess up iteration.
// Note that hashset_at does not do type checking! If the hashset only has one type being stored,
// you can safely leave out the type argument, otherwise be sure to do type checking.

enum class set_handle : int { NULL_SET };
accessor hashset : set_handle;

hashset(optional int reserve) hashset_alloc = #0;
bool(hashset, type_t, variant value) hashset_add = #0;
bool(hashset, type_t, variant value) hashset_remove = #0;
bool(hashset, type_t, variant value) hashset_contains = #0
static int(hashset) hashset_get_length = #0;
void(hashset) hashset_clear = #0;
variant(hashset, int index, optional out type_t) hashset_at = #0

accessor hashset : set_handle
{
	get int length = hashset_get_length;
	
	inline get variant[int index] =
	{
		return hashset_at(this, index);
	};
};