#ifdef GROUND_ZERO

static void(entity self, entity other, entity cactivator) misc_nuke_core_use =
{
	self.svflags ^= SVF_NOCLIENT;
}

/*QUAKED misc_nuke_core (1 0 0) (-16 -16 -16) (16 16 16)
toggles visible/not visible. starts visible.
*/
API_FUNC static void(entity ent) SP_misc_nuke_core =
{
	gi.setmodel (ent, "models/objects/core/tris.md2");
	gi.linkentity (ent);

	ent.use = misc_nuke_core_use;
}

#endif