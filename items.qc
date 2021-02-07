void() InitItems =
{
	gitem_t *it = itemlist;

	for (int i = 0; i < itemlist.length; i++, it++)
	{
		if (it->pickup_str)
			if (!(it->pickup = (pickup_func)func_get(it->pickup_str)))
				gi.dprintf("missing pickup func %s\n", it->pickup_str);
		if (it->use_str)
			if (!(it->use = (use_func)func_get(it->use_str)))
				gi.dprintf("missing use func %s\n", it->use_str);
		if (it->drop_str)
			if (!(it->drop = (drop_func)func_get(it->drop_str)))
				gi.dprintf("missing drop func %s\n", it->drop_str);
		if (it->weaponthink_str)
			if (!(it->weaponthink = (weaponthink_func)func_get(it->weaponthink_str)))
				gi.dprintf("missing weaponthink func %s\n", it->weaponthink_str);

		if (it->info_id)
			it->info = &armor_infos[it->info_id];

		it->id = i;
	}
};

// item spawnflags
const int ITEM_TRIGGER_SPAWN	= 0x00000001;
const int ITEM_NO_TOUCH			= 0x00000002;
// 6 bits reserved for editor flags
// 8 bits used as power cube id bits for coop games
const int DROPPED_ITEM			= 0x00010000;
const int DROPPED_PLAYER_ITEM	= 0x00020000;
const int ITEM_TARGETS_USED		= 0x00040000;

// special values for health styles
enum : int
{
	HEALTH_IGNORE_MAX	= 1,
	HEALTH_TIMED		= 2
};

PROGS_LOCAL_STATIC int quad_drop_timeout_hack;

#ifdef THE_RECKONING
// RAFAEL
PROGS_LOCAL int	quad_fire_drop_timeout_hack;
#endif

//======================================================================

/*
===============
GetItemByIndex
===============
*/	
inline gitem_t *GetItemByIndex(int index)
{
	return &itemlist[index];
}

/*
===============
FindItemByClassname

===============
*/
gitem_t *(string cclassname) FindItemByClassname =
{
	gitem_t *it = itemlist;
	
	for (int i = 0; i < itemlist.length; i++, it++)
		if (striequals(it->classname, cclassname))
			return it;

	return 0;
}

/*
===============
FindItem

===============
*/
gitem_t *(string pickup_name) FindItem =
{
	gitem_t *it = itemlist;
	
	for (int i = 0; i < itemlist.length; i++, it++)
		if (striequals(it->pickup_name, pickup_name))
			return it;

	return 0;
}

//======================================================================

void(entity ent) DoRespawn =
{
	if (ent.team)
	{
		entity master = ent.teammaster;

#ifdef CTF
//in ctf, when we are weapons stay, only the master of a team of weapons
//is spawned
		if (ctf.intVal &&
			(dmflags.intVal & DF_WEAPONS_STAY) &&
			master.item && (master.item->flags & IT_WEAPON))
			ent = master;
		else
		{
#endif	
			int	count;

			for (count = 0, ent = master; ent; ent = ent.chain, count++) ;

			int choice = Q_rand_uniform(count);

			for (count = 0, ent = master; count < choice; ent = ent.chain, count++) ;
#ifdef CTF
		}
#endif
	}

	ent.svflags &= ~SVF_NOCLIENT;
	ent.solid = SOLID_TRIGGER;
	gi.linkentity(ent);

	// send an effect
	ent.s.event = EV_ITEM_RESPAWN;
}

inline void(entity ent, int delay) SetRespawn =
{
	ent.flags |= FL_RESPAWN;
	ent.svflags |= SVF_NOCLIENT;
	ent.solid = SOLID_NOT;
	ent.nextthink = level.framenum + delay * BASE_FRAMERATE;
	ent.think = DoRespawn;
	gi.linkentity(ent);
}


//======================================================================
// from items.qc
API_FUNC static void(entity ent, gitem_t *it) Use_Quad;

#ifdef THE_RECKONING
API_FUNC void(entity ent, gitem_t *it) Use_QuadFire;
#endif

API_FUNC static bool(entity ent, entity other) Pickup_Powerup =
{
	int	quantity = other.client.pers.inventory[ent.item->id];

#ifdef SINGLE_PLAYER
	if ((skill.intVal == 1 && quantity >= 2) || (skill.intVal >= 2 && quantity >= 1))
		return false;

	if (coop.intVal && (ent.item->flags & IT_STAY_COOP) && quantity > 0)
		return false;
#endif

	other.client.pers.inventory[ent.item->id]++;

#ifdef SINGLE_PLAYER
	if (deathmatch.intVal)
	{
#endif
		if (!(ent.spawnflags & DROPPED_ITEM))
			SetRespawn(ent, ent.item->quantity);

		if ((dmflags.intVal & DF_INSTANT_ITEMS) || ((ent.item->use == Use_Quad
#ifdef THE_RECKONING
			|| ent.item->use == Use_QuadFire
#endif
			) && (ent.spawnflags & DROPPED_PLAYER_ITEM)))
		{
			if (ent.spawnflags & DROPPED_PLAYER_ITEM)
			{
				if (ent.item->use == Use_Quad)
					quad_drop_timeout_hack = ent.nextthink - level.framenum;
#ifdef THE_RECKONING
				else if (ent.item->use == Use_QuadFire)
					quad_drop_timeout_hack = ent.nextthink - level.framenum;
#endif
			}

			if (ent.item->use)
				ent.item->use(other, ent.item);
		}
#ifdef SINGLE_PLAYER
	}
#endif

	return true;
}

// from items.qc
entity(entity, gitem_t *) Drop_Item;

// from cmds.qc
void(entity) ValidateSelectedItem;

static inline void(entity ent, gitem_t *it) Drop_General =
{
	Drop_Item(ent, it);
	ent.client.pers.inventory[it->id]--;
	ValidateSelectedItem(ent);
}

//======================================================================

static bool(entity ent, entity other) Pickup_Adrenaline
{
#ifdef SINGLE_PLAYER
	if (!deathmatch.intVal)
		other.max_health += 1;

#endif
	if (other.health < other.max_health)
		other.health = other.max_health;

#ifdef SINGLE_PLAYER
	if (!(ent.spawnflags & DROPPED_ITEM) && deathmatch.intVal)
#else
	if !(ent.spawnflags & DROPPED_ITEM)
#endif
		SetRespawn(ent, ent.item->quantity);

	return true;
}

API_FUNC static bool(entity ent, entity other) Pickup_AncientHead =
{
	other.max_health += 2;

#ifdef SINGLE_PLAYER
	if (!(ent.spawnflags & DROPPED_ITEM) && deathmatch.intVal)
#else
	if !(ent.spawnflags & DROPPED_ITEM)
#endif
		SetRespawn(ent, ent.item->quantity);

	return true;
}

static inline void(entity other, ammo_t ammo_id, int new_max) AdjustAmmoMax =
{
	other.client.pers.max_ammo[ammo_id] = maxi(other.client.pers.max_ammo[ammo_id], new_max);
}

static inline void(entity other, gitem_id_t index) AddAndCapAmmo =
{
	gitem_t *ammo = GetItemByIndex(index);
	other.client.pers.inventory[index] = mini(other.client.pers.inventory[index] + ammo->quantity, other.client.pers.max_ammo[ammo->tag]);
}

API_FUNC static bool(entity ent, entity other) Pickup_Bandolier =
{
	AdjustAmmoMax(other, AMMO_BULLETS, 250);
	AdjustAmmoMax(other, AMMO_SHELLS, 150);
	AdjustAmmoMax(other, AMMO_CELLS, 250);
	AdjustAmmoMax(other, AMMO_SLUGS, 75);
#ifdef THE_RECKONING
	AdjustAmmoMax(other, AMMO_MAGSLUG, 75);
#endif
#ifdef GROUND_ZERO
	AdjustAmmoMax(other, AMMO_FLECHETTES, 250);
	AdjustAmmoMax(other, AMMO_DISRUPTOR, 150);
#endif

	AddAndCapAmmo(other, ITEM_BULLETS);
	AddAndCapAmmo(other, ITEM_SHELLS);

#ifdef SINGLE_PLAYER
	if (!(ent.spawnflags & DROPPED_ITEM) && deathmatch.intVal)
#else
	if !(ent.spawnflags & DROPPED_ITEM)
#endif
		SetRespawn(ent, ent.item->quantity);

	return true;
}

API_FUNC static bool(entity ent, entity other) Pickup_Pack =
{
	AdjustAmmoMax(other, AMMO_BULLETS, 300);
	AdjustAmmoMax(other, AMMO_SHELLS, 200);
	AdjustAmmoMax(other, AMMO_ROCKETS, 100);
	AdjustAmmoMax(other, AMMO_GRENADES, 100);
	AdjustAmmoMax(other, AMMO_CELLS, 300);
	AdjustAmmoMax(other, AMMO_SLUGS, 100);
#ifdef THE_RECKONING
	AdjustAmmoMax(other, AMMO_MAGSLUG, 100);
#endif
#ifdef GROUND_ZERO
	AdjustAmmoMax(other, AMMO_FLECHETTES, 300);
	AdjustAmmoMax(other, AMMO_DISRUPTOR, 200);
#endif

	AddAndCapAmmo(other, ITEM_BULLETS);
	AddAndCapAmmo(other, ITEM_SHELLS);
	AddAndCapAmmo(other, ITEM_CELLS);
	AddAndCapAmmo(other, ITEM_GRENADES);
	AddAndCapAmmo(other, ITEM_ROCKETS);
	AddAndCapAmmo(other, ITEM_SLUGS);
#ifdef THE_RECKONING
	AddAndCapAmmo(other, ITEM_MAG_SLUG);
#endif
#ifdef GROUND_ZERO
	AddAndCapAmmo(other, ITEM_FLECHETTES);
	AddAndCapAmmo(other, ITEM_ROUNDS);
#endif

#ifdef SINGLE_PLAYER
	if (!(ent.spawnflags & DROPPED_ITEM) && deathmatch.intVal)
#else
	if !(ent.spawnflags & DROPPED_ITEM)
#endif
		SetRespawn(ent, ent.item->quantity);

	return true;
}

//======================================================================

API_FUNC static void(entity ent, gitem_t *it) Use_Quad =
{
	ent.client.pers.inventory[it->id]--;
	ValidateSelectedItem(ent);

	int     timeout;

	if (quad_drop_timeout_hack)
	{
		timeout = quad_drop_timeout_hack;
		quad_drop_timeout_hack = 0;
	}
	else
		timeout = 300;

	if (ent.client.quad_framenum > level.framenum)
		ent.client.quad_framenum += timeout;
	else
		ent.client.quad_framenum = level.framenum + timeout;

	gi.sound(ent, CHAN_ITEM, gi.soundindex("items/damage.wav"), 1, ATTN_NORM, 0);
}

//======================================================================

API_FUNC static void(entity ent, gitem_t *it) Use_Breather =
{
	ent.client.pers.inventory[it->id]--;
	ValidateSelectedItem(ent);

	if (ent.client.breather_framenum > level.framenum)
		ent.client.breather_framenum += 300;
	else
		ent.client.breather_framenum = level.framenum + 300;
}

//======================================================================

API_FUNC static void(entity ent, gitem_t *it) Use_Envirosuit =
{
	ent.client.pers.inventory[it->id]--;
	ValidateSelectedItem(ent);

	if (ent.client.enviro_framenum > level.framenum)
		ent.client.enviro_framenum += 300;
	else
		ent.client.enviro_framenum = level.framenum + 300;
}

//======================================================================

API_FUNC static void(entity ent, gitem_t *it) Use_Invulnerability =
{
	ent.client.pers.inventory[it->id]--;
	ValidateSelectedItem(ent);

	if (ent.client.invincible_framenum > level.framenum)
		ent.client.invincible_framenum += 300;
	else
		ent.client.invincible_framenum = level.framenum + 300;

	gi.sound(ent, CHAN_ITEM, gi.soundindex("items/protect.wav"), 1, ATTN_NORM, 0);
}

//======================================================================

API_FUNC static void(entity ent, gitem_t *it) Use_Silencer =
{
	ent.client.pers.inventory[it->id]--;
	ValidateSelectedItem(ent);
	ent.client.silencer_shots += 30;
}

//======================================================================

#ifdef SINGLE_PLAYER
API_FUNC static bool(entity ent, entity other) Pickup_Key =
{
	if (coop.intVal)
	{
		if (ent.classname == "key_power_cube")
		{
			int cube_flag = (ent.spawnflags & 0x0000ff00) >> 8;

			if (other.client.pers.power_cubes & cube_flag)
				return false;

			other.client.pers.inventory[ent.item->id]++;
			other.client.pers.power_cubes |= cube_flag;
		}
		else
		{
			if (other.client.pers.inventory[ent.item->id])
				return false;

			other.client.pers.inventory[ent.item->id] = 1;
		}

		return true;
	}
	other.client.pers.inventory[ent.item->id]++;
	return true;
}
#endif

//======================================================================

bool(entity ent, gitem_t *it, int count) Add_Ammo =
{
	if (!ent.is_client)
		return false;

	int max = ent.client.pers.max_ammo[it->tag];
	int index = it->id;

	if (ent.client.pers.inventory[index] == max)
		return false;

	ent.client.pers.inventory[index] += count;

	if (ent.client.pers.inventory[index] > max)
		ent.client.pers.inventory[index] = max;

	return true;
}

API_FUNC bool(entity ent, entity other) Pickup_Ammo =
{
	bool weapon = (ent.item->flags & IT_WEAPON);
	int	ammocount;

	if (weapon && (dmflags.intVal & DF_INFINITE_AMMO))
		ammocount = 1000;
	else if (ent.count)
		ammocount = ent.count;
	else
		ammocount = ent.item->quantity;

	int oldcount = other.client.pers.inventory[ent.item->id];

	if (!Add_Ammo(other, ent.item, ammocount))
		return false;

	if (weapon && !oldcount && other.client.pers.weapon != ent.item &&
#ifdef SINGLE_PLAYER
		(!deathmatch.intVal ||
#endif
		other.client.pers.weapon.id == ITEM_BLASTER)
#ifdef SINGLE_PLAYER
		)
#endif
			other.client.newweapon = ent.item;

#ifdef SINGLE_PLAYER
	if (!(ent.spawnflags & (DROPPED_ITEM | DROPPED_PLAYER_ITEM)) && deathmatch.intVal)
#else
	if !(ent.spawnflags & (DROPPED_ITEM | DROPPED_PLAYER_ITEM))
#endif
		SetRespawn(ent, 30);

	return true;
}

static void(entity ent, gitem_t *it) Drop_Ammo =
{
	int index = it->id;
	entity dropped = Drop_Item(ent, it);

	if (ent.client.pers.inventory[index] >= it->quantity)
		dropped.count = it->quantity;
	else
		dropped.count = ent.client.pers.inventory[index];

	if (ent.client.pers.weapon &&
		ent.client.pers.weapon->tag == AMMO_GRENADES &&
		it->tag == AMMO_GRENADES &&
		ent.client.pers.inventory[index] - dropped.count <= 0)
	{
		gi.cprintf(ent, PRINT_HIGH, "Can't drop current weapon\n");
		G_FreeEdict(dropped);
		return;
	}

	ent.client.pers.inventory[index] -= dropped.count;
	ValidateSelectedItem(ent);
}


//======================================================================

#ifdef CTF
bool(entity) CTFHasRegeneration;
#endif

static void(entity self) MegaHealth_think =
{
	if (self.owner.health > self.owner.max_health
#ifdef CTF
		&& !CTFHasRegeneration(self.owner)
#endif
		)
	{
		self.nextthink = level.framenum + 1 * BASE_FRAMERATE;
		self.owner.health -= 1;
		return;
	}

#ifdef SINGLE_PLAYER
	if (!(self.spawnflags & DROPPED_ITEM) && deathmatch.intVal)
#else
	if !(self.spawnflags & DROPPED_ITEM)
#endif
		SetRespawn(self, 20);
	else
		G_FreeEdict(self);
}

API_FUNC bool(entity ent, entity other) Pickup_Health =
{
	if (!(ent.style & HEALTH_IGNORE_MAX))
		if (other.health >= other.max_health)
			return false;

#ifdef CTF
	if (other.health >= 250 && ent.count > 25)
		return false;
#endif

	other.health += ent.count;

#ifdef CTF
	if (other.health > 250 && ent.count > 25)
		other.health = 250;
#endif

	if (!(ent.style & HEALTH_IGNORE_MAX))
		if (other.health > other.max_health)
			other.health = other.max_health;

	if (ent.style & HEALTH_TIMED
#ifdef CTF
		&& !CTFHasRegeneration(other)
#endif
		)
	{
		ent.think = MegaHealth_think;
		ent.nextthink = level.framenum + 5 * BASE_FRAMERATE;
		ent.owner = other;
		ent.flags |= FL_RESPAWN;
		ent.svflags |= SVF_NOCLIENT;
		ent.solid = SOLID_NOT;
	}
#ifdef SINGLE_PLAYER
	else if (!(ent.spawnflags & DROPPED_ITEM) && deathmatch.intVal)
#else
	else if !(ent.spawnflags & DROPPED_ITEM)
#endif
		SetRespawn(ent, 30);

	return true;
}

//======================================================================

gitem_id_t(entity ent) ArmorIndex =
{
	if (!ent.is_client)
		return ITEM_NONE;

	if (ent.client.pers.inventory[ITEM_ARMOR_JACKET] > 0)
		return ITEM_ARMOR_JACKET;
	else if (ent.client.pers.inventory[ITEM_ARMOR_COMBAT] > 0)
		return ITEM_ARMOR_COMBAT;
	else if (ent.client.pers.inventory[ITEM_ARMOR_BODY] > 0)
		return ITEM_ARMOR_BODY;

	return ITEM_NONE;
}

bool Can_Pickup_Armor(entity ent, entity other, out gitem_id_t armor_index = 0, out int armor_count = 0, out gitem_id_t destroy_armor_index = 0)
{
	gitem_id_t	old_armor_index = ArmorIndex(other);

	// handle armor shards specially
	if (ent.item->tag == ARMOR_SHARD)
	{
		armor_index = old_armor_index ?: ITEM_ARMOR_JACKET;
		armor_count = other.client.pers.inventory[armor_index] + 2;
		destroy_armor_index = 0;
		return true;
	}

	// get info on new armor
	gitem_armor_t *newinfo = ent.item->info;

	// if player has no armor, just use it
	if (!old_armor_index)
	{
		armor_index = ent.item->id;
		armor_count = newinfo->base_count;
		destroy_armor_index = 0;
		return true;
	}

	// use the better armor
	// get info on old armor
	gitem_armor_t *oldinfo = GetItemByIndex(old_armor_index)->info;

	if (newinfo->normal_protection > oldinfo->normal_protection)
	{
		// calc new armor values
		float salvage = oldinfo->normal_protection / newinfo->normal_protection;
		int salvagecount = (int)(salvage * other.client.pers.inventory[old_armor_index]);
		int newcount = mini(newinfo->base_count + salvagecount, newinfo->max_count);

		// zero count of old armor so it goes away
		destroy_armor_index = old_armor_index;

		// change armor to new item with computed value
		armor_index = ent.item->id;
		armor_count = newcount;
	}
	else
	{
		// calc new armor values
		float salvage = newinfo->normal_protection / oldinfo->normal_protection;
		int salvagecount = (int)(salvage * newinfo->base_count);
		int newcount = mini(other.client.pers.inventory[old_armor_index] + salvagecount, oldinfo->max_count);

		destroy_armor_index = 0;

		// if we're already maxed out then we don't need the new armor
		if (other.client.pers.inventory[old_armor_index] >= newcount)
			return false;

		// update current armor value
		armor_index = old_armor_index;
		armor_count = newcount;
	}

	return true;
}

API_FUNC static bool(entity ent, entity other) Pickup_Armor =
{
	gitem_id_t armor_index;
	int armor_count;
	gitem_id_t destroy_armor_index;
	
	if (Can_Pickup_Armor(ent, other, armor_index, armor_count, destroy_armor_index))
	{
		if (destroy_armor_index)
			other.client.pers.inventory[destroy_armor_index] = 0;
		other.client.pers.inventory[armor_index] = armor_count;
	}

#ifdef SINGLE_PLAYER
	if (!(ent.spawnflags & DROPPED_ITEM) && deathmatch.intVal)
#else
	if !(ent.spawnflags & DROPPED_ITEM)
#endif
		SetRespawn(ent, 20);

	return true;
}

//======================================================================

// power armor types
typedef enum : int
{
	POWER_ARMOR_NONE,
	POWER_ARMOR_SCREEN,
	POWER_ARMOR_SHIELD,
} power_armor_type_t;

power_armor_type_t(entity ent) PowerArmorType =
{
	if (ent.is_client && (ent.flags & FL_POWER_ARMOR))
	{
		if (ent.client.pers.inventory[ITEM_POWER_SHIELD] > 0)
			return POWER_ARMOR_SHIELD;
		else if (ent.client.pers.inventory[ITEM_POWER_SCREEN] > 0)
			return POWER_ARMOR_SCREEN;
	}

	return POWER_ARMOR_NONE;
}

API_FUNC static void(entity ent, gitem_t *it) Use_PowerArmor =
{
	if (ent.flags & FL_POWER_ARMOR)
		gi.sound(ent, CHAN_AUTO, gi.soundindex("misc/power2.wav"), 1, ATTN_NORM, 0);
	else
	{
		if (!ent.client.pers.inventory[ITEM_CELLS])
		{
			gi.cprintf(ent, PRINT_HIGH, "No cells for power armor.\n");
			return;
		}
		gi.sound(ent, CHAN_AUTO, gi.soundindex("misc/power1.wav"), 1, ATTN_NORM, 0);
	}

	ent.flags ^= FL_POWER_ARMOR;
}

API_FUNC static bool(entity ent, entity other) Pickup_PowerArmor =
{
	int	quantity = other.client.pers.inventory[ent.item->id];

	other.client.pers.inventory[ent.item->id]++;

#ifdef SINGLE_PLAYER
	if (deathmatch.intVal)
	{
#endif
		if !(ent.spawnflags & DROPPED_ITEM)
			SetRespawn(ent, ent.item->quantity);

		// auto-use for DM only if we didn't already have one
		if (!quantity)
			ent.item->use(other, ent.item);
#ifdef SINGLE_PLAYER
	}
#endif

	return true;
}

static void(entity ent, gitem_t *it) Drop_PowerArmor =
{
	if ((ent.flags & FL_POWER_ARMOR) && (ent.client.pers.inventory[it->id] == 1))
		Use_PowerArmor(ent, it);

	Drop_General(ent, it);
}

//======================================================================

/*
===============
Touch_Item
===============
*/
void(entity ent, entity other, vector plane, csurface_t surf) Touch_Item =
{
	if (!other.is_client)
		return;
	if (other.health < 1)
		return;     // dead people can't pickup
	if (!ent.item->pickup)
		return;     // not a grabbable item?

	bool taken = ent.item->pickup(ent, other);

	if (taken)
	{
		// flash the screen
		other.client.bonus_alpha = 0.25f;

		// show icon and name on status bar
		other.client.ps.stats[STAT_PICKUP_ICON] = gi.imageindex(ent.item->icon);
		other.client.ps.stats[STAT_PICKUP_STRING] = CS_ITEMS + ent.item->id;
		other.client.pickup_msg_framenum = level.framenum + (int)(3.0f * BASE_FRAMERATE);

		// change selected item
		if (ent.item->use)
			other.client.pers.selected_item = other.client.ps.stats[STAT_SELECTED_ITEM] = ent.item->id;

		if (ent.item->pickup == Pickup_Health)
		{
			if (ent.count == 2)
				gi.sound(other, CHAN_ITEM, gi.soundindex("items/s_health.wav"), 1, ATTN_NORM, 0);
			else if (ent.count == 10)
				gi.sound(other, CHAN_ITEM, gi.soundindex("items/n_health.wav"), 1, ATTN_NORM, 0);
			else if (ent.count == 25)
				gi.sound(other, CHAN_ITEM, gi.soundindex("items/l_health.wav"), 1, ATTN_NORM, 0);
			else
				gi.sound(other, CHAN_ITEM, gi.soundindex("items/m_health.wav"), 1, ATTN_NORM, 0);
		}
		else if (ent.item->pickup_sound)
			gi.sound(other, CHAN_ITEM, gi.soundindex(ent.item->pickup_sound), 1, ATTN_NORM, 0);
	}

	if (!(ent.spawnflags & ITEM_TARGETS_USED))
	{
		G_UseTargets(ent, other);
		ent.spawnflags |= ITEM_TARGETS_USED;
	}

	if (!taken)
		return;
#ifdef SINGLE_PLAYER
	else if (coop.intVal && (ent.item->flags & IT_STAY_COOP) && !(ent.spawnflags & (DROPPED_ITEM | DROPPED_PLAYER_ITEM)))
		return;
#endif

	if (ent.flags & FL_RESPAWN)
		ent.flags &= ~FL_RESPAWN;
	else
		G_FreeEdict(ent);
}

//======================================================================

static void(entity ent, entity other, vector plane, csurface_t surf) drop_temp_touch =
{
	if (other == ent.owner)
		return;

	Touch_Item(ent, other, plane, surf);
}

static void(entity ent) drop_make_touchable =
{
	ent.touch = Touch_Item;

#ifdef SINGLE_PLAYER
	if (deathmatch.intVal)
	{
#endif
		ent.nextthink = level.framenum + 29 * BASE_FRAMERATE;
		ent.think = G_FreeEdict;
#ifdef SINGLE_PLAYER
	}
#endif
}

entity(entity ent, gitem_t *it) Drop_Item =
{
	entity dropped = G_Spawn();

	dropped.classname = it->classname;
	dropped.item = it;
	dropped.spawnflags = DROPPED_ITEM;
	dropped.s.effects = it->world_model_flags;
	dropped.s.renderfx = RF_GLOW
#ifdef GROUND_ZERO
		| RF_IR_VISIBLE
#endif
		;
	dropped.mins = '-15 -15 -15';
	dropped.maxs = '15 15 15';
	gi.setmodel(dropped, it->world_model);
	dropped.solid = SOLID_TRIGGER;
	dropped.movetype = MOVETYPE_TOSS;
	dropped.touch = drop_temp_touch;
	dropped.owner = ent;

	vector forward;

	if (ent.is_client)
	{
		vector right;
		AngleVectors(ent.client.v_angle, &forward, &right, 0);
		dropped.s.origin = G_ProjectSource(ent.s.origin, '24 0 -16', forward, right);

		trace_t trace;
		gi.trace(&trace, ent.s.origin, dropped.mins, dropped.maxs, dropped.s.origin, ent, CONTENTS_SOLID);
		dropped.s.origin = trace.endpos;
	}
	else
	{
		AngleVectors(ent.s.angles, &forward, 0, 0);
		dropped.s.origin = ent.s.origin;
	}

	dropped.velocity = forward * 100;
	dropped.velocity.z = 300f;

	dropped.think = drop_make_touchable;
	dropped.nextthink = level.framenum + 1 * BASE_FRAMERATE;

	gi.linkentity(dropped);

	return dropped;
}

API_FUNC void(entity ent, entity other, entity activator) Use_Item =
{
	ent.svflags &= ~SVF_NOCLIENT;
	ent.use = 0;

	if (ent.spawnflags & ITEM_NO_TOUCH)
	{
		ent.solid = SOLID_BBOX;
		ent.touch = 0;
	}
	else
	{
		ent.solid = SOLID_TRIGGER;
		ent.touch = Touch_Item;
	}

	gi.linkentity(ent);
}

//======================================================================

/*
================
droptofloor
================
*/
void(entity ent) droptofloor = 
{
	ent.mins = '-15 -15 -15';
	ent.maxs = '15 15 15';

	if (ent.model)
		gi.setmodel(ent, ent.model);
	else
		gi.setmodel(ent, ent.item->world_model);
	ent.solid = SOLID_TRIGGER;
	ent.movetype = MOVETYPE_TOSS;
	ent.touch = Touch_Item;

	vector dest = ent.s.origin;
	dest[2] -= 128;

	trace_t tr;
	gi.trace(&tr, ent.s.origin, ent.mins, ent.maxs, dest, ent, MASK_SOLID);
	if (tr.startsolid)
	{
#ifdef THE_RECKONING
		if (ent.classname == "foodcube")
		{
			tr.endpos = ent.s.origin;
			ent.velocity[2] = 0;
		}
		else
		{
#endif
			gi.dprintf("droptofloor: %s startsolid at %s\n", ent.classname, vtos(ent.s.origin));
			G_FreeEdict(ent);
			return;
#ifdef THE_RECKONING
		}
#endif
	}

	ent.s.origin = tr.endpos;

	if (ent.team)
	{
		ent.flags &= ~FL_TEAMSLAVE;
		ent.chain = ent.teamchain;
		ent.teamchain = world;
		ent.svflags |= SVF_NOCLIENT;
		ent.solid = SOLID_NOT;

		if (ent == ent.teammaster)
		{
			ent.nextthink = level.framenum + 1;
			ent.think = DoRespawn;
		}
	}

	if (ent.spawnflags & ITEM_NO_TOUCH)
	{
		ent.solid = SOLID_BBOX;
		ent.touch = 0;
		ent.s.effects &= ~EF_ROTATE;
		ent.s.renderfx &= ~RF_GLOW;
	}

	if (ent.spawnflags & ITEM_TRIGGER_SPAWN)
	{
		ent.svflags |= SVF_NOCLIENT;
		ent.solid = SOLID_NOT;
		ent.use = Use_Item;
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
void(gitem_t *it) PrecacheItem =
{
	if (!it)
		return;

	if (it->pickup_sound)
		gi.soundindex(it->pickup_sound);
	if (it->world_model)
		gi.modelindex(it->world_model);
	if (it->view_model)
		gi.modelindex(it->view_model);
	if (it->icon)
		gi.imageindex(it->icon);

	// parse everything for its ammo
	if (it->ammo && it->ammo != it->id)
		PrecacheItem(GetItemByIndex(it->ammo));

	// parse the space seperated precache string for other items
	string s = it->precaches;
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
		{
			gi.dprintf("PrecacheItem: %s has bad precache string \"%s\"", it->classname, it->precaches);
			break;
		}

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
		else
			gi.dprintf("PrecacheItem: %s has bad precache entry \"%s\"", it->classname, v);
	}
}
#ifdef GROUND_ZERO

void(entity ent) SetTriggeredSpawn;
#endif
#ifdef CTF

void(entity) CTFFlagSetup;
#endif

/*
============
SpawnItem

Sets the clipping size and plants the object on the floor.

Items can't be immediately dropped to floor, because they might
be on an entity that hasn't spawned yet.
============
*/
void(entity ent, gitem_t *it) SpawnItem =
{
	if (ent.spawnflags
#ifdef GROUND_ZERO
		> ITEM_TRIGGER_SPAWN
#endif
#ifdef SINGLE_PLAYER
		&& ent.classname != "key_power_cube"
#endif
		)
	{
		ent.spawnflags = 0;
		gi.dprintf("%s at %s has invalid spawnflags set\n", ent.classname, vtos(ent.s.origin));
	}

#ifdef SINGLE_PLAYER
	// some items will be prevented in deathmatch
	if (deathmatch.intVal)
	{
#endif
		if ((dmflags.intVal & DF_NO_ARMOR) && (it->pickup == Pickup_Armor || it->pickup == Pickup_PowerArmor))
			G_FreeEdict(ent);
		else if ((dmflags.intVal & DF_NO_ITEMS) && it->pickup == Pickup_Powerup)
			G_FreeEdict(ent);
		else if ((dmflags.intVal & DF_NO_HEALTH) && (it->pickup == Pickup_Health || it->pickup == Pickup_Adrenaline || it->pickup == Pickup_AncientHead))
			G_FreeEdict(ent);
		else if ((dmflags.intVal & DF_INFINITE_AMMO) && (it->flags == IT_AMMO || ent.classname == "weapon_bfg"))
			G_FreeEdict(ent);
#ifdef GROUND_ZERO
		else if ((dmflags.intVal & DF_NO_MINES) && (ent.classname == "ammo_prox" || ent.classname == "ammo_tesla"))
			G_FreeEdict (ent);
		else if ((dmflags.intVal & DF_NO_NUKES) && ent.classname == "ammo_nuke")
			G_FreeEdict (ent);
#endif
#ifdef SINGLE_PLAYER
	}
#endif
#ifdef GROUND_ZERO
	else if (ent.classname == "ammo_nuke")
		G_FreeEdict(ent);
#endif

	// freed by the above
	if !(ent.inuse)
		return;

	PrecacheItem(it);

#ifdef SINGLE_PLAYER
	if (coop.intVal && ent.classname == "key_power_cube")
	{
		ent.spawnflags |= (1 << (8 + level.power_cubes));
		level.power_cubes++;
	}

	// don't let them drop items that stay in a coop game
	if (coop.intVal && (it->flags & IT_STAY_COOP))
		it->drop = 0;
#endif

#ifdef CTF
//Don't spawn the flags unless enabled
	if (!ctf.intVal &&
		(ent->classname == "item_flag_team1" ||
		ent->classname == "item_flag_team2"))
	{
		G_FreeEdict(ent);
		return;
	}
#endif

	ent.item = it;
	ent.nextthink = level.framenum + 2;    // items start after other solids
	ent.think = droptofloor;
	ent.s.effects = it->world_model_flags;
	ent.s.renderfx = RF_GLOW;

	if (ent.model)
		gi.modelindex(ent.model);
#ifdef GROUND_ZERO

	if (ent.spawnflags & ITEM_TRIGGER_SPAWN)
		SetTriggeredSpawn (ent);
#endif
#ifdef CTF

	//flags are server animated and have special handling
	if (ent.classname == "item_flag_team1" ||
		ent.classname == "item_flag_team2")
		ent.think = CTFFlagSetup;
#endif
}


/*QUAKED item_health (.3 .3 1) (-16 -16 -16) (16 16 16)
*/
API_FUNC static void(entity self) SP_item_health =
{
#ifdef SINGLE_PLAYER
	if (deathmatch.intVal && (dmflags.intVal & DF_NO_HEALTH))
#else
	if (dmflags.intVal & DF_NO_HEALTH)
#endif
	{
		G_FreeEdict(self);
		return;
	}

	self.model = "models/items/healing/medium/tris.md2";
	self.count = 10;
	SpawnItem(self, GetItemByIndex(ITEM_HEALTH));
	gi.soundindex("items/n_health.wav");
}

/*QUAKED item_health_small (.3 .3 1) (-16 -16 -16) (16 16 16)
*/
API_FUNC static void(entity self) SP_item_health_small =
{
#ifdef SINGLE_PLAYER
	if (deathmatch.intVal && (dmflags.intVal & DF_NO_HEALTH))
#else
	if (dmflags.intVal & DF_NO_HEALTH)
#endif
	{
		G_FreeEdict(self);
		return;
	}

	self.model = "models/items/healing/stimpack/tris.md2";
	self.count = 2;
	SpawnItem(self, GetItemByIndex(ITEM_HEALTH));
	self.style = HEALTH_IGNORE_MAX;
	gi.soundindex("items/s_health.wav");
}

/*QUAKED item_health_large (.3 .3 1) (-16 -16 -16) (16 16 16)
*/
API_FUNC static void(entity self) SP_item_health_large =
{
#ifdef SINGLE_PLAYER
	if (deathmatch.intVal && (dmflags.intVal & DF_NO_HEALTH))
#else
	if (dmflags.intVal & DF_NO_HEALTH)
#endif
	{
		G_FreeEdict(self);
		return;
	}

	self.model = "models/items/healing/large/tris.md2";
	self.count = 25;
	SpawnItem(self, GetItemByIndex(ITEM_HEALTH));
	gi.soundindex("items/l_health.wav");
}

/*QUAKED item_health_mega (.3 .3 1) (-16 -16 -16) (16 16 16)
*/
API_FUNC static void(entity self) SP_item_health_mega =
{
#ifdef SINGLE_PLAYER
	if (deathmatch.intVal && (dmflags.intVal & DF_NO_HEALTH))
#else
	if (dmflags.intVal & DF_NO_HEALTH)
#endif
	{
		G_FreeEdict(self);
		return;
	}

	self.model = "models/items/mega_h/tris.md2";
	self.count = 100;
	SpawnItem(self, GetItemByIndex(ITEM_HEALTH));
	gi.soundindex("items/m_health.wav");
	self.style = HEALTH_IGNORE_MAX | HEALTH_TIMED;
}

/*
===============
SetItemNames

Called by worldspawn
===============
*/
void() SetItemNames =
{
	gitem_t *it = itemlist;

	for (int i = 0; i < itemlist.length; i++, it++)
		gi.configstring(CS_ITEMS + i, it->pickup_name);
}
