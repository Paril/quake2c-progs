void() InitItems =
{
	gitem_t *it = itemlist;
	
	for (int i = 0; i < itemlist.length; i++, it++)
	{
		if (it->pickup_str)
			it->pickup = (pickup_func)func_get(it->pickup_str);
		if (it->use_str)
			it->use = (use_func)func_get(it->use_str);
		if (it->drop_str)
			it->drop = (drop_func)func_get(it->drop_str);
		if (it->weaponthink_str)
			it->weaponthink = (weaponthink_func)func_get(it->weaponthink_str);
	}
};

// item spawnflags
const int ITEM_TRIGGER_SPAWN	= 0x00000001;
const int ITEM_NO_TOUCH		= 0x00000002;
// 6 bits reserved for editor flags
// 8 bits used as power cube id bits for coop games
const int DROPPED_ITEM		= 0x00010000;
const int DROPPED_PLAYER_ITEM	= 0x00020000;
const int ITEM_TARGETS_USED	= 0x00040000;

static int  jacket_armor_index;
static int  combat_armor_index;
static int  body_armor_index;
static int  power_screen_index;
static int  power_shield_index;

// special values for health styles
enum int
{
	HEALTH_IGNORE_MAX	= 1,
	HEALTH_TIMED		= 2
};

static int  quad_drop_timeout_hack;

//======================================================================

/*
===============
GetItemByIndex
===============
*/
#define GetItemKeyByIndex(index, key) (itemlist[index].key)

#define ITEM_INDEX(item) item
	
#define GetItemByIndex(index) index

/*
===============
FindItemByClassname

===============
*/
gitem_id_t(string cclassname) FindItemByClassname =
{
	int     i;
	for (i = 0 ; i < itemlist.length; i++) {
		if (!GetItemKeyByIndex(i, classname))
			continue;
		if (!stricmp(GetItemKeyByIndex(i, classname), cclassname))
			return i;
	}

	return 0;
}

/*
===============
FindItem

===============
*/
gitem_id_t(string pickup_name) FindItem =
{
	int     i;
	for (i = 0 ; i < itemlist.length; i++) {
		if (!GetItemKeyByIndex(i, pickup_name))
			continue;
		if (!stricmp(GetItemKeyByIndex(i, pickup_name), pickup_name))
			return i;
	}

	return 0;
}

//======================================================================

static void(entity ent) DoRespawn =
{
	if (ent->team)
	{
		entity	master;
		int	count;
		int	choice;

		master = ent->teammaster;

		for (count = 0, ent = master; ent; ent = ent->chain, count++)
			;

		choice = Q_rand_uniform(count);

		for (count = 0, ent = master; count < choice; ent = ent->chain, count++)
			;
	}

	ent->svflags &= ~SVF_NOCLIENT;
	ent->solid = SOLID_TRIGGER;
	gi.linkentity(ent);

	// send an effect
	ent->s.event = EV_ITEM_RESPAWN;
}

void(entity ent, int delay) SetRespawn =
{
	ent->flags |= FL_RESPAWN;
	ent->svflags |= SVF_NOCLIENT;
	ent->solid = SOLID_NOT;
	ent->nextthink = level.framenum + delay * BASE_FRAMERATE;
	ent->think = DoRespawn;
	gi.linkentity(ent);
}


//======================================================================
// from items.qc
API_FUNC static void(entity ent, gitem_id_t item) Use_Quad;

API_FUNC static bool(entity ent, entity other) Pickup_Powerup =
{
	int     quantity;

	quantity = other->client->pers.inventory[ITEM_INDEX(ent->item)];
	if ((skill->intVal == 1 && quantity >= 2) || (skill->intVal >= 2 && quantity >= 1))
		return false;

	if ((coop->intVal) && (GetItemKeyByIndex(ent->item, flags) & IT_STAY_COOP) && (quantity > 0))
		return false;

	other->client->pers.inventory[ITEM_INDEX(ent->item)]++;

	if (deathmatch->intVal) {
		if (!(ent->spawnflags & DROPPED_ITEM))
			SetRespawn(ent, GetItemKeyByIndex(ent->item, quantity));
		if ((dmflags->intVal & DF_INSTANT_ITEMS) || ((GetItemKeyByIndex(ent->item, use) == Use_Quad) && (ent->spawnflags & DROPPED_PLAYER_ITEM)))
		{
			if ((GetItemKeyByIndex(ent->item, use) == Use_Quad) && (ent->spawnflags & DROPPED_PLAYER_ITEM))
				quad_drop_timeout_hack = ent->nextthink - level.framenum;
			GetItemKeyByIndex(ent->item, use)(other, ent->item);
		}
	}

	return true;
}

// from items.qc
entity(entity, gitem_id_t) Drop_Item;

// from cmds.qc
void(entity) ValidateSelectedItem;

static void(entity ent, gitem_id_t item) Drop_General =
{
	Drop_Item(ent, item);
	ent->client->pers.inventory[ITEM_INDEX(item)]--;
	ValidateSelectedItem(ent);
}


//======================================================================

static bool(entity ent, entity other) Pickup_Adrenaline
{
	if (!deathmatch->intVal)
		other->max_health += 1;

	if (other->health < other->max_health)
		other->health = other->max_health;

	if (!(ent->spawnflags & DROPPED_ITEM) && (deathmatch->intVal))
		SetRespawn(ent, GetItemKeyByIndex(ent->item, quantity));

	return true;
}

API_FUNC static bool(entity ent, entity other) Pickup_AncientHead =
{
	other->max_health += 2;

	if (!(ent->spawnflags & DROPPED_ITEM) && (deathmatch->intVal))
		SetRespawn(ent, GetItemKeyByIndex(ent->item, quantity));

	return true;
}

API_FUNC static bool(entity ent, entity other) Pickup_Bandolier =
{
	gitem_id_t	itemid;
	int		index;

	if (other->client->pers.max_bullets < 250)
		other->client->pers.max_bullets = 250;
	if (other->client->pers.max_shells < 150)
		other->client->pers.max_shells = 150;
	if (other->client->pers.max_cells < 250)
		other->client->pers.max_cells = 250;
	if (other->client->pers.max_slugs < 75)
		other->client->pers.max_slugs = 75;

	itemid = FindItem("Bullets");
	if (itemid) {
		index = ITEM_INDEX(itemid);
		other->client->pers.inventory[index] += GetItemKeyByIndex(itemid, quantity);
		if (other->client->pers.inventory[index] > other->client->pers.max_bullets)
			other->client->pers.inventory[index] = other->client->pers.max_bullets;
	}

	itemid = FindItem("Shells");
	if (itemid) {
		index = ITEM_INDEX(itemid);
		other->client->pers.inventory[index] += GetItemKeyByIndex(itemid, quantity);
		if (other->client->pers.inventory[index] > other->client->pers.max_shells)
			other->client->pers.inventory[index] = other->client->pers.max_shells;
	}

	if (!(ent->spawnflags & DROPPED_ITEM) && (deathmatch->intVal))
		SetRespawn(ent, GetItemKeyByIndex(ent->item, quantity));

	return true;
}

API_FUNC static bool(entity ent, entity other) Pickup_Pack =
{
	gitem_id_t	itemid;
	int		index;

	if (other->client->pers.max_bullets < 300)
		other->client->pers.max_bullets = 300;
	if (other->client->pers.max_shells < 200)
		other->client->pers.max_shells = 200;
	if (other->client->pers.max_rockets < 100)
		other->client->pers.max_rockets = 100;
	if (other->client->pers.max_grenades < 100)
		other->client->pers.max_grenades = 100;
	if (other->client->pers.max_cells < 300)
		other->client->pers.max_cells = 300;
	if (other->client->pers.max_slugs < 100)
		other->client->pers.max_slugs = 100;

	itemid = FindItem("Bullets");
	if (itemid) {
		index = ITEM_INDEX(itemid);
		other->client->pers.inventory[index] += GetItemKeyByIndex(itemid, quantity);
		if (other->client->pers.inventory[index] > other->client->pers.max_bullets)
			other->client->pers.inventory[index] = other->client->pers.max_bullets;
	}

	itemid = FindItem("Shells");
	if (itemid) {
		index = ITEM_INDEX(itemid);
		other->client->pers.inventory[index] += GetItemKeyByIndex(itemid, quantity);
		if (other->client->pers.inventory[index] > other->client->pers.max_shells)
			other->client->pers.inventory[index] = other->client->pers.max_shells;
	}

	itemid = FindItem("Cells");
	if (itemid) {
		index = ITEM_INDEX(itemid);
		other->client->pers.inventory[index] += GetItemKeyByIndex(itemid, quantity);
		if (other->client->pers.inventory[index] > other->client->pers.max_cells)
			other->client->pers.inventory[index] = other->client->pers.max_cells;
	}

	itemid = FindItem("Grenades");
	if (itemid) {
		index = ITEM_INDEX(itemid);
		other->client->pers.inventory[index] += GetItemKeyByIndex(itemid, quantity);
		if (other->client->pers.inventory[index] > other->client->pers.max_grenades)
			other->client->pers.inventory[index] = other->client->pers.max_grenades;
	}

	itemid = FindItem("Rockets");
	if (itemid) {
		index = ITEM_INDEX(itemid);
		other->client->pers.inventory[index] += GetItemKeyByIndex(itemid, quantity);
		if (other->client->pers.inventory[index] > other->client->pers.max_rockets)
			other->client->pers.inventory[index] = other->client->pers.max_rockets;
	}

	itemid = FindItem("Slugs");
	if (itemid) {
		index = ITEM_INDEX(itemid);
		other->client->pers.inventory[index] += GetItemKeyByIndex(itemid, quantity);
		if (other->client->pers.inventory[index] > other->client->pers.max_slugs)
			other->client->pers.inventory[index] = other->client->pers.max_slugs;
	}

	if (!(ent->spawnflags & DROPPED_ITEM) && (deathmatch->intVal))
		SetRespawn(ent, GetItemKeyByIndex(ent->item, quantity));

	return true;
}

//======================================================================

API_FUNC static void(entity ent, gitem_id_t item) Use_Quad =
{
	int     timeout;

	ent->client->pers.inventory[ITEM_INDEX(item)]--;
	ValidateSelectedItem(ent);

	if (quad_drop_timeout_hack) {
		timeout = quad_drop_timeout_hack;
		quad_drop_timeout_hack = 0;
	} else {
		timeout = 300;
	}

	if (ent->client->quad_framenum > level.framenum)
		ent->client->quad_framenum += timeout;
	else
		ent->client->quad_framenum = level.framenum + timeout;

	gi.sound(ent, CHAN_ITEM, gi.soundindex("items/damage.wav"), 1, ATTN_NORM, 0);
}

//======================================================================

API_FUNC static void(entity ent, gitem_id_t item) Use_Breather =
{
	ent->client->pers.inventory[ITEM_INDEX(item)]--;
	ValidateSelectedItem(ent);

	if (ent->client->breather_framenum > level.framenum)
		ent->client->breather_framenum += 300;
	else
		ent->client->breather_framenum = level.framenum + 300;
}

//======================================================================

API_FUNC static void(entity ent, gitem_id_t item) Use_Envirosuit =
{
	ent->client->pers.inventory[ITEM_INDEX(item)]--;
	ValidateSelectedItem(ent);

	if (ent->client->enviro_framenum > level.framenum)
		ent->client->enviro_framenum += 300;
	else
		ent->client->enviro_framenum = level.framenum + 300;
}

//======================================================================

API_FUNC static void(entity ent, gitem_id_t item) Use_Invulnerability =
{
	ent->client->pers.inventory[ITEM_INDEX(item)]--;
	ValidateSelectedItem(ent);

	if (ent->client->invincible_framenum > level.framenum)
		ent->client->invincible_framenum += 300;
	else
		ent->client->invincible_framenum = level.framenum + 300;

	gi.sound(ent, CHAN_ITEM, gi.soundindex("items/protect.wav"), 1, ATTN_NORM, 0);
}

//======================================================================

API_FUNC static void(entity ent, gitem_id_t item) Use_Silencer =
{
	ent->client->pers.inventory[ITEM_INDEX(item)]--;
	ValidateSelectedItem(ent);
	ent->client->silencer_shots += 30;
}

//======================================================================

API_FUNC static bool(entity ent, entity other) Pickup_Key =
{
	if (coop->intVal) {
		if (ent->classname == "key_power_cube") {
			if (other->client->pers.power_cubes & ((ent->spawnflags & 0x0000ff00) >> 8))
				return false;
			other->client->pers.inventory[ITEM_INDEX(ent->item)]++;
			other->client->pers.power_cubes |= ((ent->spawnflags & 0x0000ff00) >> 8);
		} else {
			if (other->client->pers.inventory[ITEM_INDEX(ent->item)])
				return false;
			other->client->pers.inventory[ITEM_INDEX(ent->item)] = 1;
		}
		return true;
	}
	other->client->pers.inventory[ITEM_INDEX(ent->item)]++;
	return true;
}

//======================================================================

bool(entity ent, gitem_id_t itemid, int count) Add_Ammo =
{
	int         index;
	int         max;

	if (!ent->is_client)
		return false;
	
	int	tag = GetItemKeyByIndex(itemid, tag);

	if (tag == AMMO_BULLETS)
		max = ent->client->pers.max_bullets;
	else if (tag == AMMO_SHELLS)
		max = ent->client->pers.max_shells;
	else if (tag == AMMO_ROCKETS)
		max = ent->client->pers.max_rockets;
	else if (tag == AMMO_GRENADES)
		max = ent->client->pers.max_grenades;
	else if (tag == AMMO_CELLS)
		max = ent->client->pers.max_cells;
	else if (tag == AMMO_SLUGS)
		max = ent->client->pers.max_slugs;
	else
		return false;

	index = ITEM_INDEX(itemid);

	if (ent->client->pers.inventory[index] == max)
		return false;

	ent->client->pers.inventory[index] += count;

	if (ent->client->pers.inventory[index] > max)
		ent->client->pers.inventory[index] = max;

	return true;
}

API_FUNC static bool(entity ent, entity other) Pickup_Ammo =
{
	int	oldcount = 0;
	int	ammocount = 0;
	bool	weapon = (GetItemKeyByIndex(ent->item, flags) & IT_WEAPON);
	if ((weapon) && (dmflags->intVal & DF_INFINITE_AMMO))
		ammocount = 1000;
	else if (ent->count)
		ammocount = ent->count;
	else
		ammocount = GetItemKeyByIndex(ent->item, quantity);

	oldcount = other->client->pers.inventory[ITEM_INDEX(ent->item)];

	if (!Add_Ammo(other, ent->item, ammocount))
		return false;

	if (weapon && !oldcount) {
		if (other->client->pers.weapon != ent->item && (!deathmatch->intVal || other->client->pers.weapon == FindItem("blaster")))
			other->client->newweapon = ent->item;
	}

	if (!(ent->spawnflags & (DROPPED_ITEM | DROPPED_PLAYER_ITEM)) && (deathmatch->intVal))
		SetRespawn(ent, 30);
	return true;
}

static void(entity ent, gitem_id_t itemid) Drop_Ammo =
{
	entity	dropped;
	int	index;

	index = ITEM_INDEX(itemid);
	dropped = Drop_Item(ent, itemid);

	if (ent->client->pers.inventory[index] >= GetItemKeyByIndex(itemid, quantity))
		dropped->count = GetItemKeyByIndex(itemid, quantity);
	else
		dropped->count = ent->client->pers.inventory[index];

	if (ent->client->pers.weapon &&
		GetItemKeyByIndex(ent->client->pers.weapon, tag) == AMMO_GRENADES &&
		GetItemKeyByIndex(itemid, tag) == AMMO_GRENADES &&
		ent->client->pers.inventory[index] - dropped.count <= 0) {
		gi.cprintf(ent, PRINT_HIGH, "Can't drop current weapon\n");
		G_FreeEdict(dropped);
		return;
	}

	ent->client->pers.inventory[index] -= dropped.count;
	ValidateSelectedItem(ent);
}


//======================================================================

static void(entity self) MegaHealth_think =
{
	if (self->owner->health > self->owner->max_health) {
		self->nextthink = level.framenum + 1 * BASE_FRAMERATE;
		self->owner->health -= 1;
		return;
	}

	if (!(self->spawnflags & DROPPED_ITEM) && (deathmatch->intVal))
		SetRespawn(self, 20);
	else
		G_FreeEdict(self);
}

API_FUNC static bool(entity ent, entity other) Pickup_Health =
{
	if (!(ent->style & HEALTH_IGNORE_MAX))
		if (other->health >= other->max_health)
			return false;

	other->health += ent->count;

	if (!(ent->style & HEALTH_IGNORE_MAX)) {
		if (other->health > other->max_health)
			other->health = other->max_health;
	}

	if (ent->style & HEALTH_TIMED) {
		ent->think = MegaHealth_think;
		ent->nextthink = level.framenum + 5 * BASE_FRAMERATE;
		ent->owner = other;
		ent->flags |= FL_RESPAWN;
		ent->svflags |= SVF_NOCLIENT;
		ent->solid = SOLID_NOT;
	} else {
		if (!(ent->spawnflags & DROPPED_ITEM) && (deathmatch->intVal))
			SetRespawn(ent, 30);
	}

	return true;
}

//======================================================================

int(entity ent) ArmorIndex =
{
	if (!ent->is_client)
		return 0;

	if (ent->client->pers.inventory[jacket_armor_index] > 0)
		return jacket_armor_index;

	if (ent->client->pers.inventory[combat_armor_index] > 0)
		return combat_armor_index;

	if (ent->client->pers.inventory[body_armor_index] > 0)
		return body_armor_index;

	return 0;
}

API_FUNC static bool(entity ent, entity other) Pickup_Armor =
{
	int	old_armor_index;
	gitem_armor_id_t	oldinfo;
	gitem_armor_id_t	newinfo;
	int	newcount;
	float	salvage;
	int	salvagecount;

	// get info on new armor
	newinfo = GetItemKeyByIndex(ent->item, info);

	old_armor_index = ArmorIndex(other);

	// handle armor shards specially
	if (GetItemKeyByIndex(ent->item, tag) == ARMOR_SHARD) {
		if (!old_armor_index)
			other->client->pers.inventory[jacket_armor_index] = 2;
		else
			other->client->pers.inventory[old_armor_index] += 2;
	}

	// if player has no armor, just use it
	else if (!old_armor_index) {
		other->client->pers.inventory[ITEM_INDEX(ent->item)] = GetArmorInfoKeyByIndex(newinfo, base_count);
	}

	// use the better armor
	else {
		// get info on old armor
		if (old_armor_index == jacket_armor_index)
			oldinfo = ARMOR_JACKET;
		else if (old_armor_index == combat_armor_index)
			oldinfo = ARMOR_COMBAT;
		else // (old_armor_index == body_armor_index)
			oldinfo = ARMOR_BODY;

		if (GetArmorInfoKeyByIndex(newinfo, normal_protection) > GetArmorInfoKeyByIndex(oldinfo, normal_protection)) {
			// calc new armor values
			salvage = GetArmorInfoKeyByIndex(oldinfo, normal_protection) / GetArmorInfoKeyByIndex(newinfo, normal_protection);
			salvagecount = (int)(salvage * other->client->pers.inventory[old_armor_index]);
			newcount = GetArmorInfoKeyByIndex(newinfo, base_count) + salvagecount;
			if (newcount > GetArmorInfoKeyByIndex(newinfo, max_count))
				newcount = GetArmorInfoKeyByIndex(newinfo, max_count);

			// zero count of old armor so it goes away
			other->client->pers.inventory[old_armor_index] = 0;

			// change armor to new item with computed value
			other->client->pers.inventory[ITEM_INDEX(ent->item)] = newcount;
		} else {
			// calc new armor values
			salvage = GetArmorInfoKeyByIndex(newinfo, normal_protection) / GetArmorInfoKeyByIndex(oldinfo, normal_protection);
			salvagecount = (int)(salvage * GetArmorInfoKeyByIndex(newinfo, base_count));
			newcount = other->client->pers.inventory[old_armor_index] + salvagecount;
			if (newcount > GetArmorInfoKeyByIndex(oldinfo, max_count))
				newcount = GetArmorInfoKeyByIndex(oldinfo, max_count);

			// if we're already maxed out then we don't need the new armor
			if (other->client->pers.inventory[old_armor_index] >= newcount)
				return false;

			// update current armor value
			other->client->pers.inventory[old_armor_index] = newcount;
		}
	}

	if (!(ent->spawnflags & DROPPED_ITEM) && (deathmatch->intVal))
		SetRespawn(ent, 20);

	return true;
}

//======================================================================

power_armor_type_t(entity ent) PowerArmorType =
{
	if (!ent->is_client)
		return POWER_ARMOR_NONE;

	if (!(ent->flags & FL_POWER_ARMOR))
		return POWER_ARMOR_NONE;

	if (ent->client->pers.inventory[power_shield_index] > 0)
		return POWER_ARMOR_SHIELD;

	if (ent->client->pers.inventory[power_screen_index] > 0)
		return POWER_ARMOR_SCREEN;

	return POWER_ARMOR_NONE;
}

API_FUNC static void(entity ent, gitem_id_t itemid) Use_PowerArmor =
{
	int     index;

	if (ent->flags & FL_POWER_ARMOR) {
		ent->flags &= ~FL_POWER_ARMOR;
		gi.sound(ent, CHAN_AUTO, gi.soundindex("misc/power2.wav"), 1, ATTN_NORM, 0);
	} else {
		index = ITEM_INDEX(FindItem("cells"));
		if (!ent->client->pers.inventory[index]) {
			gi.cprintf(ent, PRINT_HIGH, "No cells for power armor.\n");
			return;
		}
		ent->flags |= FL_POWER_ARMOR;
		gi.sound(ent, CHAN_AUTO, gi.soundindex("misc/power1.wav"), 1, ATTN_NORM, 0);
	}
}

API_FUNC static bool(entity ent, entity other) Pickup_PowerArmor =
{
	int	quantity = other->client->pers.inventory[ITEM_INDEX(ent->item)];

	other->client->pers.inventory[ITEM_INDEX(ent->item)]++;

	if (deathmatch->intVal) {
		if (!(ent->spawnflags & DROPPED_ITEM))
			SetRespawn(ent, GetItemKeyByIndex(ent->item, quantity));
		// auto-use for DM only if we didn't already have one
		if (!quantity)
			GetItemKeyByIndex(ent->item, use)(other, ent->item);
	}

	return true;
}

static void(entity ent, gitem_id_t itemid) Drop_PowerArmor =
{
	if ((ent->flags & FL_POWER_ARMOR) && (ent->client->pers.inventory[ITEM_INDEX(itemid)] == 1))
		Use_PowerArmor(ent, itemid);
	Drop_General(ent, itemid);
}

//======================================================================

/*
===============
Touch_Item
===============
*/
void(entity ent, entity other, cplane_t plane, csurface_t surf) Touch_Item =
{
	bool    taken;

	if (!other->is_client)
		return;
	if (other->health < 1)
		return;     // dead people can't pickup
	if (!GetItemKeyByIndex(ent->item, pickup))
		return;     // not a grabbable item?

	taken = GetItemKeyByIndex(ent->item, pickup)(ent, other);

	if (taken) {
		// flash the screen
		other->client->bonus_alpha = 0.25f;

		// show icon and name on status bar
		other->client->ps.stats[STAT_PICKUP_ICON] = gi.imageindex(GetItemKeyByIndex(ent->item, icon));
		other->client->ps.stats[STAT_PICKUP_STRING] = CS_ITEMS + ITEM_INDEX(ent->item);
		other->client->pickup_msg_framenum = level.framenum + (int)(3.0f * BASE_FRAMERATE);

		// change selected item
		if (GetItemKeyByIndex(ent->item, use))
			other->client->pers.selected_item = other->client->ps.stats[STAT_SELECTED_ITEM] = ITEM_INDEX(ent->item);

		if (GetItemKeyByIndex(ent->item, pickup) == Pickup_Health) {
			if (ent->count == 2)
				gi.sound(other, CHAN_ITEM, gi.soundindex("items/s_health.wav"), 1, ATTN_NORM, 0);
			else if (ent->count == 10)
				gi.sound(other, CHAN_ITEM, gi.soundindex("items/n_health.wav"), 1, ATTN_NORM, 0);
			else if (ent->count == 25)
				gi.sound(other, CHAN_ITEM, gi.soundindex("items/l_health.wav"), 1, ATTN_NORM, 0);
			else // (ent->count == 100)
				gi.sound(other, CHAN_ITEM, gi.soundindex("items/m_health.wav"), 1, ATTN_NORM, 0);
		} else if (GetItemKeyByIndex(ent->item, pickup_sound)) {
			gi.sound(other, CHAN_ITEM, gi.soundindex(GetItemKeyByIndex(ent->item, pickup_sound)), 1, ATTN_NORM, 0);
		}
	}

	if (!(ent->spawnflags & ITEM_TARGETS_USED)) {
		G_UseTargets(ent, other);
		ent->spawnflags |= ITEM_TARGETS_USED;
	}

	if (!taken)
		return;

	if (!((coop->intVal) && (GetItemKeyByIndex(ent->item, flags) & IT_STAY_COOP)) || (ent->spawnflags & (DROPPED_ITEM | DROPPED_PLAYER_ITEM))) {
		if (ent->flags & FL_RESPAWN)
			ent->flags &= ~FL_RESPAWN;
		else
			G_FreeEdict(ent);
	}
}

//======================================================================

static void(entity ent, entity other, cplane_t plane, csurface_t surf) drop_temp_touch =
{
	if (other == ent->owner)
		return;

	Touch_Item(ent, other, plane, surf);
}

static void(entity ent) drop_make_touchable =
{
	ent->touch = Touch_Item;
	if (deathmatch->intVal) {
		ent->nextthink = level.framenum + 29 * BASE_FRAMERATE;
		ent->think = G_FreeEdict;
	}
}

entity(entity ent, gitem_id_t itemid) Drop_Item =
{
	entity	dropped;
	vector	forward, right;
	vector	offset;

	dropped = G_Spawn();

	dropped->classname = GetItemKeyByIndex(itemid, classname);
	dropped->item = itemid;
	dropped->spawnflags = DROPPED_ITEM;
	dropped->s.effects = GetItemKeyByIndex(itemid, world_model_flags);
	dropped->s.renderfx = RF_GLOW;
	VectorSet(dropped->mins, -15, -15, -15);
	VectorSet(dropped->maxs, 15, 15, 15);
	gi.setmodel(dropped, GetItemKeyByIndex(itemid, world_model));
	dropped->solid = SOLID_TRIGGER;
	dropped->movetype = MOVETYPE_TOSS;
	dropped->touch = drop_temp_touch;
	dropped->owner = ent;

	if (ent->is_client) {
		trace_t trace;

		AngleVectors(ent->client->v_angle, forward, right, unref_vec);
		VectorSet(offset, 24, 0, -16);
		G_ProjectSource(ent->s.origin, offset, forward, right, dropped->s.origin);
		gi.trace(&trace, ent->s.origin, dropped->mins, dropped->maxs, dropped->s.origin, ent, CONTENTS_SOLID);
		VectorCopy(trace.endpos, dropped->s.origin);
	} else {
		AngleVectors(ent->s.angles, forward, right, unref_vec);
		VectorCopy(ent->s.origin, dropped->s.origin);
	}

	VectorScale(forward, 100, dropped->velocity);
	dropped->velocity_z = 300f;

	dropped->think = drop_make_touchable;
	dropped->nextthink = level.framenum + 1 * BASE_FRAMERATE;

	gi.linkentity(dropped);

	return dropped;
}

API_FUNC void(entity ent, entity other, entity activator) Use_Item =
{
	ent->svflags &= ~SVF_NOCLIENT;
	ent->use = 0;

	if (ent->spawnflags & ITEM_NO_TOUCH) {
		ent->solid = SOLID_BBOX;
		ent->touch = 0;
	} else {
		ent->solid = SOLID_TRIGGER;
		ent->touch = Touch_Item;
	}

	gi.linkentity(ent);
}

//======================================================================

/*
================
droptofloor
================
*/
static void(entity ent) droptofloor = 
{
	trace_t	tr;
	vector	dest;
	vector	v;

	v = '-15 -15 -15';
	VectorCopy(v, ent->mins);
	v = '15 15 15';
	VectorCopy(v, ent->maxs);

	if (ent->model)
		gi.setmodel(ent, ent->model);
	else
		gi.setmodel(ent, GetItemKeyByIndex(ent->item, world_model));
	ent->solid = SOLID_TRIGGER;
	ent->movetype = MOVETYPE_TOSS;
	ent->touch = Touch_Item;

	v = '0 0 -128';
	VectorAdd(ent->s.origin, v, dest);

	gi.trace(&tr, ent->s.origin, ent->mins, ent->maxs, dest, ent, MASK_SOLID);
	if (tr.startsolid) {
		gi.dprintf("droptofloor: %s startsolid at %s\n", ent->classname, vtos(ent->s.origin));
		G_FreeEdict(ent);
		return;
	}

	VectorCopy(tr.endpos, ent->s.origin);

	if (ent->team) {
		ent->flags &= ~FL_TEAMSLAVE;
		ent->chain = ent->teamchain;
		ent->teamchain = world;

		ent->svflags |= SVF_NOCLIENT;
		ent->solid = SOLID_NOT;
		if (ent == ent->teammaster) {
			ent->nextthink = level.framenum + 1;
			ent->think = DoRespawn;
		}
	}

	if (ent->spawnflags & ITEM_NO_TOUCH) {
		ent->solid = SOLID_BBOX;
		ent->touch = 0;
		ent->s.effects &= ~EF_ROTATE;
		ent->s.renderfx &= ~RF_GLOW;
	}

	if (ent->spawnflags & ITEM_TRIGGER_SPAWN) {
		ent->svflags |= SVF_NOCLIENT;
		ent->solid = SOLID_NOT;
		ent->use = Use_Item;
	}

	gi.linkentity(ent);
}


/*
===============
PrecacheItem

Precaches all data needed for a given item.
This will be called for each item spawned in a level,
and for each item in each client's inventory.
===============
*/
void(gitem_id_t it) PrecacheItem =
{
	if (!it)
		return;

	if (GetItemKeyByIndex(it, pickup_sound))
		gi.soundindex(GetItemKeyByIndex(it, pickup_sound));
	if (GetItemKeyByIndex(it, world_model))
		gi.modelindex(GetItemKeyByIndex(it, world_model));
	if (GetItemKeyByIndex(it, view_model))
		gi.modelindex(GetItemKeyByIndex(it, view_model));
	if (GetItemKeyByIndex(it, icon))
		gi.imageindex(GetItemKeyByIndex(it, icon));

	// parse everything for its ammo
	if (GetItemKeyByIndex(it, ammo)) {
		gitem_id_t ammo = FindItem(GetItemKeyByIndex(it, ammo));
		if (ammo != it)
			PrecacheItem(ammo);
	}

	// parse the space seperated precache string for other items
	string s = GetItemKeyByIndex(it, precaches);
	if (!s)
		return;

	int s_pos = 0;

	while (true)
	{
		string v = strtok(s, s_pos);
		
		if (!v)
			break;

		int v_len = strlen(v);

		if (v_len >= MAX_QPATH || v_len < 5)
			gi.error("PrecacheItem: %s has bad precache string", GetItemKeyByIndex(it, classname));
		
		string ext = substr(v, v_len - 3);

		// determine type based on extension
		if (ext == "md2")
			gi.modelindex(v);
		else if (ext == "sp2")
			gi.modelindex(v);
		else if (ext == "wav")
			gi.soundindex(v);
		else if (ext == "pcx")
			gi.imageindex(v);
	}
}

/*
============
SpawnItem

Sets the clipping size and plants the object on the floor.

Items can't be immediately dropped to floor, because they might
be on an entity that hasn't spawned yet.
============
*/
void(entity ent, gitem_id_t it) SpawnItem =
{
	PrecacheItem(it);

	if (ent->spawnflags) {
		if (ent->classname != "key_power_cube") {
			ent->spawnflags = 0;
			gi.dprintf("%s at %s has invalid spawnflags set\n", ent->classname, vtos(ent->s.origin));
		}
	}

	// some items will be prevented in deathmatch
	if (deathmatch->intVal) {
		if (dmflags->intVal & DF_NO_ARMOR) {
			if (GetItemKeyByIndex(it, pickup) == Pickup_Armor || GetItemKeyByIndex(it, pickup) == Pickup_PowerArmor) {
				G_FreeEdict(ent);
				return;
			}
		}
		if (dmflags->intVal & DF_NO_ITEMS) {
			if (GetItemKeyByIndex(it, pickup) == Pickup_Powerup) {
				G_FreeEdict(ent);
				return;
			}
		}
		if (dmflags->intVal & DF_NO_HEALTH) {
			if (GetItemKeyByIndex(it, pickup) == Pickup_Health || GetItemKeyByIndex(it, pickup) == Pickup_Adrenaline || GetItemKeyByIndex(it, pickup) == Pickup_AncientHead) {
				G_FreeEdict(ent);
				return;
			}
		}
		if (dmflags->intVal & DF_INFINITE_AMMO) {
			if ((GetItemKeyByIndex(it, flags) == IT_AMMO) || ent->classname == "weapon_bfg") {
				G_FreeEdict(ent);
				return;
			}
		}
	}

	if (coop->intVal && ent->classname == "key_power_cube") {
		ent->spawnflags |= (1 << (8 + level.power_cubes));
		level.power_cubes++;
	}

	// don't let them drop items that stay in a coop game
	if ((coop->intVal) && (GetItemKeyByIndex(it, flags) & IT_STAY_COOP)) {
		GetItemKeyByIndex(it, drop) = 0;
	}

	ent->item = it;
	ent->nextthink = level.framenum + 2;    // items start after other solids
	ent->think = droptofloor;
	ent->s.effects = GetItemKeyByIndex(it, world_model_flags);
	ent->s.renderfx = RF_GLOW;
	if (ent->model)
		gi.modelindex(ent->model);
}


/*QUAKED item_health (.3 .3 1) (-16 -16 -16) (16 16 16)
*/
API_FUNC static void(entity self) SP_item_health =
{
	if (deathmatch->intVal && (dmflags->intVal & DF_NO_HEALTH)) {
		G_FreeEdict(self);
		return;
	}

	self->model = "models/items/healing/medium/tris.md2";
	self->count = 10;
	SpawnItem(self, FindItem("Health"));
	gi.soundindex("items/n_health.wav");
}

/*QUAKED item_health_small (.3 .3 1) (-16 -16 -16) (16 16 16)
*/
API_FUNC static void(entity self) SP_item_health_small =
{
	if (deathmatch->intVal && (dmflags->intVal & DF_NO_HEALTH)) {
		G_FreeEdict(self);
		return;
	}

	self->model = "models/items/healing/stimpack/tris.md2";
	self->count = 2;
	SpawnItem(self, FindItem("Health"));
	self->style = HEALTH_IGNORE_MAX;
	gi.soundindex("items/s_health.wav");
}

/*QUAKED item_health_large (.3 .3 1) (-16 -16 -16) (16 16 16)
*/
API_FUNC static void(entity self) SP_item_health_large =
{
	if (deathmatch->intVal && (dmflags->intVal & DF_NO_HEALTH)) {
		G_FreeEdict(self);
		return;
	}

	self->model = "models/items/healing/large/tris.md2";
	self->count = 25;
	SpawnItem(self, FindItem("Health"));
	gi.soundindex("items/l_health.wav");
}

/*QUAKED item_health_mega (.3 .3 1) (-16 -16 -16) (16 16 16)
*/
API_FUNC static void(entity self) SP_item_health_mega =
{
	if (deathmatch->intVal && (dmflags->intVal & DF_NO_HEALTH)) {
		G_FreeEdict(self);
		return;
	}

	self->model = "models/items/mega_h/tris.md2";
	self->count = 100;
	SpawnItem(self, FindItem("Health"));
	gi.soundindex("items/m_health.wav");
	self->style = HEALTH_IGNORE_MAX | HEALTH_TIMED;
}


/*
===============
SetItemNames

Called by worldspawn
===============
*/
void() SetItemNames =
{
	int     i;

	for (i = 0 ; i < itemlist.length ; i++) {
		gi.configstring(CS_ITEMS + i, GetItemKeyByIndex(i, pickup_name));
	}

	jacket_armor_index = ITEM_INDEX(FindItem("Jacket Armor"));
	combat_armor_index = ITEM_INDEX(FindItem("Combat Armor"));
	body_armor_index   = ITEM_INDEX(FindItem("Body Armor"));
	power_screen_index = ITEM_INDEX(FindItem("Power Screen"));
	power_shield_index = ITEM_INDEX(FindItem("Power Shield"));
}
