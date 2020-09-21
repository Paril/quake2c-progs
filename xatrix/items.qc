#ifdef THE_RECKONING

#ifdef THE_RECKONING
API_FUNC void(entity ent, gitem_t *it) Use_QuadFire =
{
	ent.client.pers.inventory[it->id]--;
	ValidateSelectedItem (ent);

	int timeout;

	if (quad_fire_drop_timeout_hack)
	{
		timeout = quad_fire_drop_timeout_hack;
		quad_fire_drop_timeout_hack = 0;
	}
	else
		timeout = 300;

	if (ent.client.quadfire_framenum > level.framenum)
		ent.client.quadfire_framenum += timeout;
	else
		ent.client.quadfire_framenum = level.framenum + timeout;

	gi.sound(ent, CHAN_ITEM, gi.soundindex("items/quadfire1.wav"), 1, ATTN_NORM, 0);
}
#endif

// RAFAEL
API_FUNC void(entity self) SP_item_foodcube =
{
	if (deathmatch.intVal && (dmflags.intVal & DF_NO_HEALTH))
	{
		G_FreeEdict (self);
		return;
	}

	self.model = "models/objects/trapfx/tris.md2";
	SpawnItem (self, FindItem ("Health"));
	self.spawnflags |= DROPPED_ITEM;
	self.style = HEALTH_IGNORE_MAX;
	gi.soundindex ("items/s_health.wav");
	self.classname = "foodcube";
}

#endif