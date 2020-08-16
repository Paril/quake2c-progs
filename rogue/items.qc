#ifdef GROUND_ZERO

API_FUNC bool(entity ent, entity other) Pickup_Nuke =
{
	int		quantity;

	quantity = other.client.pers.inventory[ent.item->id];

	if (quantity >= 1)
		return false;

	if (coop.intVal && (ent.item->flags & IT_STAY_COOP) && quantity > 0)
		return false;

	other.client.pers.inventory[ent.item->id]++;

	if (deathmatch.intVal)
	{
		if (!(ent.spawnflags & DROPPED_ITEM))
			SetRespawn (ent, ent.item->quantity);
	}

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
	vector	forward, right, start;
	float	speed;

	ent.client.pers.inventory[it->id]--;
	ValidateSelectedItem (ent);

	AngleVectors (ent.client.v_angle, &forward, &right, 0);

	start = ent.s.origin;
	speed = 100f;
	fire_nuke (ent, start, forward, speed);
}


//=================
// Item_TriggeredSpawn - create the item marked for spawn creation
//=================
void(entity ent) droptofloor;

static void(entity self, entity other, entity cactivator) Item_TriggeredSpawn =
{
	self.svflags &= ~SVF_NOCLIENT;
	self.use = 0;
	if(self.classname != "key_power_cube")	// leave them be on key_power_cube..
		self.spawnflags = 0;
	droptofloor (self);
}

//=================
// SetTriggeredSpawn - set up an item to spawn in later.
//=================
void(entity ent) SetTriggeredSpawn =
{
	// don't do anything on key_power_cubes.
	if(ent.classname == "key_power_cube")
		return;

	ent.think = 0;
	ent.nextthink = 0;
	ent.use = Item_TriggeredSpawn;
	ent.svflags |= SVF_NOCLIENT;
	ent.solid = SOLID_NOT;
}

#endif