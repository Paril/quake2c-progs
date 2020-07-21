//
// monster weapons
//

//FIXME mosnters should call these with a totally accurate direction
// and we can mess it up based on skill.  Spread should be for normal
// and we can tighten or loosen based on skill.  We could muck with
// the damages too, but I'm not sure that's such a good idea.
void(entity self, vector start, vector dir, int damage, int kick, int hspread, int vspread, int flashtype) monster_fire_bullet =
{
	fire_bullet(self, start, dir, damage, kick, hspread, vspread, MOD_UNKNOWN);

	gi.WriteByte(svc_muzzleflash2);
	gi.WriteShort(self.s.number);
	gi.WriteByte(flashtype);
	gi.multicast(start, MULTICAST_PVS);
}

void(entity self, vector start, vector aimdir, int damage, int kick, int hspread, int vspread, int count, int flashtype) monster_fire_shotgun =
{
	fire_shotgun(self, start, aimdir, damage, kick, hspread, vspread, count, MOD_UNKNOWN);

	gi.WriteByte(svc_muzzleflash2);
	gi.WriteShort(self.s.number);
	gi.WriteByte(flashtype);
	gi.multicast(start, MULTICAST_PVS);
}

void(entity self, vector start, vector dir, int damage, int speed, int flashtype, int effect) monster_fire_blaster =
{
	fire_blaster(self, start, dir, damage, speed, effect, false);

	gi.WriteByte(svc_muzzleflash2);
	gi.WriteShort(self.s.number);
	gi.WriteByte(flashtype);
	gi.multicast(start, MULTICAST_PVS);
}

void(entity self, vector start, vector aimdir, int damage, int speed, int flashtype) monster_fire_grenade =
{
	fire_grenade(self, start, aimdir, damage, speed, 2.5f, damage + 40);

	gi.WriteByte(svc_muzzleflash2);
	gi.WriteShort(self.s.number);
	gi.WriteByte(flashtype);
	gi.multicast(start, MULTICAST_PVS);
}

void(entity self, vector start, vector dir, int damage, int speed, int flashtype) monster_fire_rocket =
{
	fire_rocket(self, start, dir, damage, speed, damage + 20, damage);

	gi.WriteByte(svc_muzzleflash2);
	gi.WriteShort(self.s.number);
	gi.WriteByte(flashtype);
	gi.multicast(start, MULTICAST_PVS);
}

void(entity self, vector start, vector aimdir, int damage, int kick, int flashtype) monster_fire_railgun =
{
	fire_rail(self, start, aimdir, damage, kick);

	gi.WriteByte(svc_muzzleflash2);
	gi.WriteShort(self.s.number);
	gi.WriteByte(flashtype);
	gi.multicast(start, MULTICAST_PVS);
}

void(entity self, vector start, vector aimdir, int damage, int speed, int kick, float damage_radius, int flashtype) monster_fire_bfg =
{
	fire_bfg(self, start, aimdir, damage, speed, damage_radius);

	gi.WriteByte(svc_muzzleflash2);
	gi.WriteShort(self.s.number);
	gi.WriteByte(flashtype);
	gi.multicast(start, MULTICAST_PVS);
}



//
// Monster utility functions
//

void(entity self) M_FliesOff =
{
	self->s.effects &= ~EF_FLIES;
	self->s.sound = 0;
}

void(entity self) M_FliesOn =
{
	if (self->waterlevel)
		return;
	self->s.effects |= EF_FLIES;
	self->s.sound = gi.soundindex("infantry/inflies1.wav");
	self->think = M_FliesOff;
	self->nextthink = level.framenum + 60 * BASE_FRAMERATE;
}

void(entity self) M_FlyCheck =
{
	if (self->waterlevel)
		return;

	if (random() > 0.5f)
		return;

	self->think = M_FliesOn;
	self->nextthink = level.framenum + (int)random(5f * BASE_FRAMERATE, 15f * BASE_FRAMERATE);
}

void(entity self, float time) AttackFinished =
{
	self->monsterinfo.attack_finished = level.framenum + (int)(time * BASE_FRAMERATE);
}


void(entity ent) M_CheckGround =
{
	vector	point;
	trace_t	trace;

	if (ent->flags & (FL_SWIM | FL_FLY))
		return;

	if (ent->velocity_z > 100) {
		ent->groundentity = null_entity;
		return;
	}

// if the hull point one-quarter unit down is solid the entity is on ground
	point_x = ent->s.origin[0];
	point_y = ent->s.origin[1];
	point_z = ent->s.origin[2] - 0.25f;

	gi.trace(&trace, ent->s.origin, ent->mins, ent->maxs, point, ent, MASK_MONSTERSOLID);

	// check steepness
	if (trace.plane.normal[2] < 0.7f && !trace.startsolid) {
		ent->groundentity = null_entity;
		return;
	}

	if (!trace.startsolid && !trace.allsolid) {
		ent->s.origin = trace.endpos;
		ent->groundentity = trace.ent;
		ent->groundentity_linkcount = trace.ent->linkcount;
		ent->velocity_z = 0;
	}
}


static void(entity ent) M_CatagorizePosition =
{
	vector	point;
	int	cont;

//
// get waterlevel
//
	point_x = ent->s.origin[0];
	point_y = ent->s.origin[1];
	point_z = ent->s.origin[2] + ent->mins_z + 1;
	cont = gi.pointcontents(point);

	if (!(cont & MASK_WATER)) {
		ent->waterlevel = 0;
		ent->watertype = 0;
		return;
	}

	ent->watertype = cont;
	ent->waterlevel = 1;
	point_z += 26;
	cont = gi.pointcontents(point);
	if (!(cont & MASK_WATER))
		return;

	ent->waterlevel = 2;
	point_z += 22;
	cont = gi.pointcontents(point);
	if (cont & MASK_WATER)
		ent->waterlevel = 3;
}

static void(entity ent) M_WorldEffects =
{
	int     dmg;

	if (ent->health > 0) {
		if (!(ent->flags & FL_SWIM)) {
			if (ent->waterlevel < 3) {
				ent->air_finished_framenum = level.framenum + 12 * BASE_FRAMERATE;
			} else if (ent->air_finished_framenum < level.framenum) {
				// drown!
				if (ent->pain_debounce_framenum < level.framenum) {
					dmg = 2 + 2 * ((level.framenum - ent->air_finished_framenum) / BASE_FRAMERATE);
					if (dmg > 15)
						dmg = 15;
					T_Damage(ent, world, world, vec3_origin, ent->s.origin, vec3_origin, dmg, 0, DAMAGE_NO_ARMOR, MOD_WATER);
					ent->pain_debounce_framenum = level.framenum + 1 * BASE_FRAMERATE;
				}
			}
		} else {
			if (ent->waterlevel > 0) {
				ent->air_finished_framenum = level.framenum + 9 * BASE_FRAMERATE;
			} else if (ent->air_finished_framenum < level.framenum) {
				// suffocate!
				if (ent->pain_debounce_framenum < level.framenum) {
					dmg = 2 + 2 * ((level.framenum - ent->air_finished_framenum) / BASE_FRAMERATE);
					if (dmg > 15)
						dmg = 15;
					T_Damage(ent, world, world, vec3_origin, ent->s.origin, vec3_origin, dmg, 0, DAMAGE_NO_ARMOR, MOD_WATER);
					ent->pain_debounce_framenum = level.framenum + 1 * BASE_FRAMERATE;
				}
			}
		}
	}

	if (ent->waterlevel == 0) {
		if (ent->flags & FL_INWATER) {
			gi.sound(ent, CHAN_BODY, gi.soundindex("player/watr_out.wav"), 1, ATTN_NORM, 0);
			ent->flags &= ~FL_INWATER;
		}
		return;
	}

	if ((ent->watertype & CONTENTS_LAVA) && !(ent->flags & FL_IMMUNE_LAVA)) {
		if (ent->damage_debounce_framenum < level.framenum) {
			ent->damage_debounce_framenum = level.framenum + (int)(0.2f * BASE_FRAMERATE);
			T_Damage(ent, world, world, vec3_origin, ent->s.origin, vec3_origin, 10 * ent->waterlevel, 0, 0, MOD_LAVA);
		}
	}
	if ((ent->watertype & CONTENTS_SLIME) && !(ent->flags & FL_IMMUNE_SLIME)) {
		if (ent->damage_debounce_framenum < level.framenum) {
			ent->damage_debounce_framenum = level.framenum + 1 * BASE_FRAMERATE;
			T_Damage(ent, world, world, vec3_origin, ent->s.origin, vec3_origin, 4 * ent->waterlevel, 0, 0, MOD_SLIME);
		}
	}

	if (!(ent->flags & FL_INWATER)) {
		if (!(ent->svflags & SVF_DEADMONSTER)) {
			if (ent->watertype & CONTENTS_LAVA)
				if (random() <= 0.5f)
					gi.sound(ent, CHAN_BODY, gi.soundindex("player/lava1.wav"), 1, ATTN_NORM, 0);
				else
					gi.sound(ent, CHAN_BODY, gi.soundindex("player/lava2.wav"), 1, ATTN_NORM, 0);
			else if (ent->watertype & CONTENTS_SLIME)
				gi.sound(ent, CHAN_BODY, gi.soundindex("player/watr_in.wav"), 1, ATTN_NORM, 0);
			else if (ent->watertype & CONTENTS_WATER)
				gi.sound(ent, CHAN_BODY, gi.soundindex("player/watr_in.wav"), 1, ATTN_NORM, 0);
		}

		ent->flags |= FL_INWATER;
		ent->damage_debounce_framenum = 0;
	}
}

void(entity ent) M_droptofloor =
{
	vector	end;
	trace_t	trace;

	ent->s.origin[2] += 1;
	end = ent->s.origin;
	end_z -= 256;

	gi.trace(&trace, ent->s.origin, ent->mins, ent->maxs, end, ent, MASK_MONSTERSOLID);

	if (trace.fraction == 1 || trace.allsolid)
		return;

	ent->s.origin = trace.endpos;

	gi.linkentity(ent);
	M_CheckGround(ent);
	M_CatagorizePosition(ent);
}


static void(entity ent) M_SetEffects =
{
	ent->s.effects &= ~(EF_COLOR_SHELL | EF_POWERSCREEN);
	ent->s.renderfx &= ~(RF_SHELL_RED | RF_SHELL_GREEN | RF_SHELL_BLUE);

	if (ent->monsterinfo.aiflags & AI_RESURRECTING) {
		ent->s.effects |= EF_COLOR_SHELL;
		ent->s.renderfx |= RF_SHELL_RED;
	}

	if (ent->health <= 0)
		return;

	if (ent->powerarmor_framenum > level.framenum) {
		if (ent->monsterinfo.power_armor_type == POWER_ARMOR_SCREEN) {
			ent->s.effects |= EF_POWERSCREEN;
		} else if (ent->monsterinfo.power_armor_type == POWER_ARMOR_SHIELD) {
			ent->s.effects |= EF_COLOR_SHELL;
			ent->s.renderfx |= RF_SHELL_GREEN;
		}
	}
}

static void(entity self) M_MoveFrame =
{
	mmove_t	*move;
	int	index;

	move = self->monsterinfo.currentmove;
	self->nextthink = level.framenum + 1;

	int first = move->firstframe;
	int last = move->lastframe;
	void(entity) endfunc = move->endfunc;

	if ((self->monsterinfo.nextframe) && (self->monsterinfo.nextframe >= first) && (self->monsterinfo.nextframe <= last)) {
		self->s.frame = self->monsterinfo.nextframe;
		self->monsterinfo.nextframe = 0;
	} else {
		if (self->s.frame == last) {
			if (endfunc) {
				endfunc(self);

				// regrab move, endfunc is very likely to change it
				move = self->monsterinfo.currentmove;
				
				first = move->firstframe;
				last = move->lastframe;
				endfunc = move->endfunc;

				// check for death
				if (self->svflags & SVF_DEADMONSTER)
					return;
			}
		}

		if (self->s.frame < first || self->s.frame > last) {
			self->monsterinfo.aiflags &= ~AI_HOLD_FRAME;
			self->s.frame = first;
		} else {
			if (!(self->monsterinfo.aiflags & AI_HOLD_FRAME)) {
				self->s.frame++;
				if (self->s.frame > last)
					self->s.frame = first;
			}
		}
	}

	index = self->s.frame - first;
	
	mframe_t *frame = &move->frame[index];
	
	void(entity, float) aifunc = frame.aifunc;
	float dist = frame.dist;
	void(entity) thinkfunc = frame.thinkfunc;
	
	if (aifunc) {
		if (!(self->monsterinfo.aiflags & AI_HOLD_FRAME))
			aifunc(self, dist * self->monsterinfo.scale);
		else
			aifunc(self, 0);
	}

	if (thinkfunc)
		thinkfunc(self);
}


static void(entity self) monster_think =
{
	M_MoveFrame(self);
	if (self->linkcount != self->monsterinfo.linkcount) {
		self->monsterinfo.linkcount = self->linkcount;
		M_CheckGround(self);
	}
	M_CatagorizePosition(self);
	M_WorldEffects(self);
	M_SetEffects(self);
}


/*
================
monster_use

Using a monster makes it angry at the current activator
================
*/
void(entity self, entity other, entity cactivator) monster_use =
{
	if (self->enemy)
		return;
	if (self->health <= 0)
		return;
	if (cactivator->flags & FL_NOTARGET)
		return;
	if (!(cactivator->is_client) && !(cactivator->monsterinfo.aiflags & AI_GOOD_GUY))
		return;

// delay reaction so if the monster is teleported, its sound is still heard
	self->enemy = cactivator;
	FoundTarget(self);
}


// from monster.qc
static void(entity self) monster_start_go;

static void(entity self) monster_triggered_spawn =
{
	self->s.origin[2] += 1;
	KillBox(self);

	self->solid = SOLID_BBOX;
	self->movetype = MOVETYPE_STEP;
	self->svflags &= ~SVF_NOCLIENT;
	self->air_finished_framenum = level.framenum + 12 * BASE_FRAMERATE;
	gi.linkentity(self);

	monster_start_go(self);

#ifdef THE_RECKONING
	// RAFAEL
	if (self->classname == "monster_fixbot")
	{
		if ((self->spawnflags & 16) || (self->spawnflags & 8) || (self->spawnflags & 4))
		{
			self->enemy = world;
			return;
		}
	}
#endif

	if (self->enemy && !(self->spawnflags & 1) && !(self->enemy->flags & FL_NOTARGET)) {
		FoundTarget(self);
	} else {
		self->enemy = world;
	}
}

static void(entity self, entity other, entity cactivator) monster_triggered_spawn_use =
{
	// we have a one frame delay here so we don't telefrag the guy who activated us
	self->think = monster_triggered_spawn;
	self->nextthink = level.framenum + 1;
	if (cactivator->is_client)
		self->enemy = cactivator;
	self->use = monster_use;
}

static void(entity self) monster_triggered_start =
{
	self->solid = SOLID_NOT;
	self->movetype = MOVETYPE_NONE;
	self->svflags |= SVF_NOCLIENT;
	self->nextthink = 0;
	self->use = monster_triggered_spawn_use;
}


/*
================
monster_death_use

When a monster dies, it fires all of its targets with the current
enemy as activator.
================
*/
void(entity self) monster_death_use =
{
	self->flags &= ~(FL_FLY | FL_SWIM);
	self->monsterinfo.aiflags &= AI_GOOD_GUY;

	if (self->item) {
		Drop_Item(self, self->item);
		self->item = 0;
	}

	if (self->deathtarget)
		self->target = self->deathtarget;

	if (!self->target)
		return;

	G_UseTargets(self, self->enemy);
}

//============================================================================

static bool(entity self) monster_start =
{
	if (deathmatch->intVal) {
		G_FreeEdict(self);
		return false;
	}

	if ((self->spawnflags & 4) && !(self->monsterinfo.aiflags & AI_GOOD_GUY)) {
		self->spawnflags &= ~4;
		self->spawnflags |= 1;
//      gi.dprintf("fixed spawnflags on %s at %s\n", self->classname, vtos(self->s.origin));
	}

	if (!(self->monsterinfo.aiflags & AI_GOOD_GUY))
		level.total_monsters++;

	self->nextthink = level.framenum + 1;
	self->svflags |= SVF_MONSTER;
	self->s.renderfx |= RF_FRAMELERP;
	self->takedamage = DAMAGE_AIM;
	self->air_finished_framenum = level.framenum + 12 * BASE_FRAMERATE;
	self->use = monster_use;
	self->max_health = self->health;
	self->clipmask = MASK_MONSTERSOLID;

	self->s.skinnum = 0;
	self->deadflag = DEAD_NO;
	self->svflags &= ~SVF_DEADMONSTER;

	if (!self->monsterinfo.checkattack)
		self->monsterinfo.checkattack = M_CheckAttack;
	self->s.old_origin = self->s.origin;

	if (st.item) {
		self->item = FindItemByClassname(st.item);
		if (!self->item)
			gi.dprintf("%s at %s has bad item: %s\n", self->classname, vtos(self->s.origin), st.item);
	}

	// randomize what frame they start on
	if (self->monsterinfo.currentmove)
	{
		int first = self->monsterinfo.currentmove->firstframe;
		int last = self->monsterinfo.currentmove->lastframe;

		self->s.frame = first + (Q_rand() % (last - first + 1));
	}

	return true;
}

static void(entity self) monster_start_go =
{
	vector	v;

	if (self->health <= 0)
		return;

	// check for target to combat_point and change to combattarget
	if (self->target) {
		bool	notcombat;
		bool	fixup;
		entity	ctarget;

		ctarget = null_entity;
		notcombat = false;
		fixup = false;
		while ((ctarget = G_Find(ctarget, targetname, self->target)) != null_entity) {
			if (ctarget->classname == "point_combat") {
				self->combattarget = self->target;
				fixup = true;
			} else {
				notcombat = true;
			}
		}
		if (notcombat && self->combattarget)
			gi.dprintf("%s at %s has target with mixed types\n", self->classname, vtos(self->s.origin));
		if (fixup)
			self->target = 0;
	}

	// validate combattarget
	if (self->combattarget) {
		entity	ctarget;

		ctarget = null_entity;
		while ((ctarget = G_Find(ctarget, targetname, self->combattarget)) != null_entity) {
			if (ctarget->classname != "point_combat") {
				gi.dprintf("%s at (%s) has a bad combattarget %s : %s at (%s)\n",
						   self->classname, vtos(self->s.origin),
						   self->combattarget, ctarget->classname, vtos(ctarget->s.origin));
			}
		}
	}

	if (self->target) {
		self->goalentity = self->movetarget = G_PickTarget(self->target);
		if (!self->movetarget) {
			gi.dprintf("%s can't find target %s at %s\n", self->classname, self->target, vtos(self->s.origin));
			self->target = 0;
			self->monsterinfo.pause_framenum = INT_MAX;
			self->monsterinfo.stand(self);
		} else if (self->movetarget->classname == "path_corner") {
			v = self->goalentity->s.origin - self->s.origin;
			self->ideal_yaw = self->s.angles[YAW] = vectoyaw(v);
			self->monsterinfo.walk(self);
			self->target = 0;
		} else {
			self->goalentity = self->movetarget = world;
			self->monsterinfo.pause_framenum = INT_MAX;
			self->monsterinfo.stand(self);
		}
	} else {
		self->monsterinfo.pause_framenum = INT_MAX;
		self->monsterinfo.stand(self);
	}

	self->think = monster_think;
	self->nextthink = level.framenum + 1;
}


static void(entity self) walkmonster_start_go =
{
	if (!(self->spawnflags & 2) && level.time < 1) {
		M_droptofloor(self);

		if (self->groundentity != null_entity)
			if (!M_walkmove(self, 0, 0))
				gi.dprintf("%s in solid at %s\n", self->classname, vtos(self->s.origin));
	}

	if (!self->yaw_speed)
		self->yaw_speed = 20f;
	self->viewheight = 25;

	monster_start_go(self);

	if (self->spawnflags & 2)
		monster_triggered_start(self);
}

void(entity self) walkmonster_start =
{
	self->think = walkmonster_start_go;
	monster_start(self);
}


static void(entity self) flymonster_start_go =
{
	if (!M_walkmove(self, 0, 0))
		gi.dprintf("%s in solid at %s\n", self->classname, vtos(self->s.origin));

	if (!self->yaw_speed)
		self->yaw_speed = 10f;
	self->viewheight = 25;

	monster_start_go(self);

	if (self->spawnflags & 2)
		monster_triggered_start(self);
}


void(entity self) flymonster_start =
{
	self->flags |= FL_FLY;
	self->think = flymonster_start_go;
	monster_start(self);
}


static void(entity self) swimmonster_start_go =
{
	if (!self->yaw_speed)
		self->yaw_speed = 10f;
	self->viewheight = 10;

	monster_start_go(self);

	if (self->spawnflags & 2)
		monster_triggered_start(self);
}

void(entity self) swimmonster_start =
{
	self->flags |= FL_SWIM;
	self->think = swimmonster_start_go;
	monster_start(self);
}
