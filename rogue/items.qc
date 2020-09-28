#ifdef GROUND_ZERO

API_FUNC bool(entity ent, entity other) Pickup_Nuke =
{
	gitem_t	*citem = ent.item;
	int		quantity = other.client.pers.inventory[citem->id];

	if (quantity >= 1)
		return false;

#ifdef SINGLE_PLAYER
	if (coop.intVal && (citem->flags & IT_STAY_COOP) && quantity > 0)
		return false;
#endif

	other.client.pers.inventory[citem->id]++;

#ifdef SINGLE_PLAYER
	if (deathmatch.intVal && !(ent.spawnflags & DROPPED_ITEM))
#else
	if !(ent.spawnflags & DROPPED_ITEM)
#endif
		SetRespawn (ent, citem->quantity);

	return true;
}


API_FUNC void(entity ent, gitem_t *it) Use_IR =
{
	ent.client.pers.inventory[it->id]--;
	ValidateSelectedItem (ent);

	if (ent.client.ir_framenum > level.framenum)
		ent.client.ir_framenum += 600;
	else
		ent.client.ir_framenum = level.framenum + 600;

	gi.sound(ent, CHAN_ITEM, gi.soundindex("misc/ir_start.wav"), 1, ATTN_NORM, 0);
}

API_FUNC void(entity ent, gitem_t *it) Use_Double =
{
	ent.client.pers.inventory[it->id]--;
	ValidateSelectedItem (ent);

	if (ent.client.double_framenum > level.framenum)
		ent.client.double_framenum += 300;
	else
		ent.client.double_framenum = level.framenum + 300;

	gi.sound(ent, CHAN_ITEM, gi.soundindex("misc/ddamage1.wav"), 1, ATTN_NORM, 0);
}

void(entity self, vector start, vector aimdir, int speed) fire_nuke;

API_FUNC void(entity ent, gitem_t *it) Use_Nuke =
{
	ent.client.pers.inventory[it->id]--;
	ValidateSelectedItem (ent);

	vector	forward;
	AngleVectors (ent.client.v_angle, &forward, 0, 0);

	fire_nuke (ent, ent.s.origin, forward, 100f);
}


//=================
// Item_TriggeredSpawn - create the item marked for spawn creation
//=================
static void(entity self, entity other, entity cactivator) Item_TriggeredSpawn =
{
	self.svflags &= ~SVF_NOCLIENT;
	self.use = 0;
	if (self.classname != "key_power_cube")	// leave them be on key_power_cube..
		self.spawnflags = 0;
	droptofloor (self);
}

//=================
// SetTriggeredSpawn - set up an item to spawn in later.
//=================
void(entity ent) SetTriggeredSpawn =
{
	// don't do anything on key_power_cubes.
	if (ent.classname == "key_power_cube")
		return;

	ent.think = 0;
	ent.nextthink = 0;
	ent.use = Item_TriggeredSpawn;
	ent.svflags |= SVF_NOCLIENT;
	ent.solid = SOLID_NOT;
}

#endif