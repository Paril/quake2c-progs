#ifdef THE_RECKONING

/*QUAKED target_mal_laser (1 0 0) (-4 -4 -4) (4 4 4) START_ON RED GREEN BLUE YELLOW ORANGE FAT
Mal's laser
*/
static void(entity self) target_mal_laser_on =
{
	if (!self.activator)
		self.activator = self;
	self.spawnflags |= 0x80000001;
	self.svflags &= ~SVF_NOCLIENT;
	self.nextthink = level.framenum + (int)((self.wait + self.delay) * BASE_FRAMERATE);
}

static void(entity self) target_mal_laser_off =
{
	self.spawnflags &= ~1;
	self.svflags |= SVF_NOCLIENT;
	self.nextthink = 0;
}

static void(entity self, entity other, entity cactivator) target_mal_laser_use =
{
	self.activator = cactivator;
	if (self.spawnflags & 1)
		target_mal_laser_off (self);
	else
		target_mal_laser_on (self);
}

static void(entity self) mal_laser_think =
{
	target_laser_think (self);
	self.nextthink = level.framenum + (int)((self.wait + 0.1) * BASE_FRAMERATE);
	self.spawnflags |= 0x80000000;
}

API_FUNC static void(entity self) SP_target_mal_laser =
{
	self.movetype = MOVETYPE_NONE;
	self.solid = SOLID_NOT;
	self.s.renderfx |= RF_BEAM|RF_TRANSLUCENT;
	self.s.modelindex = 1;			// must be non-zero

	// set the beam diameter
	if (self.spawnflags & 64)
		self.s.frame = 16;
	else
		self.s.frame = 4;

	// set the color
	if (self.spawnflags & 2)
		self.s.skinnum = 0xf2f2f0f0;
	else if (self.spawnflags & 4)
		self.s.skinnum = 0xd0d1d2d3;
	else if (self.spawnflags & 8)
		self.s.skinnum = 0xf3f3f1f1;
	else if (self.spawnflags & 16)
		self.s.skinnum = 0xdcdddedf;
	else if (self.spawnflags & 32)
		self.s.skinnum = 0xe0e1e2e3;

	G_SetMovedir (self.s.angles, self.movedir);
	
	if (!self.delay)
		self.delay = 0.1;

	if (!self.wait)
		self.wait = 0.1;

	if (!self.dmg)
		self.dmg = 5;

	self.mins = '-8 -8 -8';
	self.maxs = '8 8 8';
	
	self.nextthink = level.framenum + (int)(self.delay * BASE_FRAMERATE);
	self.think = mal_laser_think;

	self.use = target_mal_laser_use;

	gi.linkentity (self);

	if (self.spawnflags & 1)
		target_mal_laser_on (self);
	else
		target_mal_laser_off (self);
}

#endif