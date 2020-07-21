#ifdef THE_RECKONING

// RAFAEL
void(entity self, string gibname, int damage, int type) ThrowGibACID =
{
	entity gib;
	vector vd;
	vector origin;
	vector sz;
	float vscale;

	gib = G_Spawn();

	sz = self->size * 0.5;
	origin = self->absmin + sz;
	gib->s.origin = origin + randomv(-sz, sz);

	gib->s.modelindex = gi.modelindex (gibname);

	gib->clipmask = MASK_SHOT;
	gib->solid = SOLID_BBOX;
 
	gib->s.effects |= EF_GREENGIB;
	// note to self check this
	gib->s.renderfx |= RF_FULLBRIGHT;
	gib->flags |= FL_NO_KNOCKBACK;
	gib->takedamage = DAMAGE_YES;
	gib->die = gib_die;
	gib->dmg = 2;

	if (type == GIB_ORGANIC)
	{
		gib->movetype = MOVETYPE_TOSS;
		vscale = 3.0;
	}
	else
	{
		gib->movetype = MOVETYPE_BOUNCE;
		vscale = 1.0;
	}

	VelocityForDamage (damage, vd);
	gib->velocity = self->velocity + (vd * vscale);
	ClipGibVelocity (gib);
	gib->avelocity = randomv('600 600 600');

	gib->think = G_FreeEdict;
	gib->nextthink = level.framenum + (int)(random(10f, 20f) * BASE_FRAMERATE);

	gi.linkentity (gib);
}

// RAFAEL

void(entity self, string gibname, int damage, int type) ThrowHeadACID =
{
	vector vd;
	float vscale;

	self->s.skinnum = 0;
	self->s.frame = 0;
	self->mins = vec3_origin;
	self->maxs = vec3_origin;

	self->s.modelindex2 = 0;
	gi.setmodel (self, gibname);
 
	self->clipmask = MASK_SHOT;
	self->solid = SOLID_BBOX;
  
	self->s.effects |= EF_GREENGIB;
	self->s.effects &= ~EF_FLIES;
	self->s.effects |= RF_FULLBRIGHT;
	self->s.sound = 0;
	self->flags |= FL_NO_KNOCKBACK;
	self->svflags &= ~SVF_MONSTER;
	self->takedamage = DAMAGE_YES;
	self->die = gib_die;
	self->dmg = 2;

	if (type == GIB_ORGANIC)
	{
		self->movetype = MOVETYPE_TOSS;
		vscale = 0.5;
	}
	else
	{
		self->movetype = MOVETYPE_BOUNCE;
		vscale = 1.0;
	}

	VelocityForDamage (damage, vd);
	self->velocity += vd * vscale;
	ClipGibVelocity (self);

	self->avelocity[YAW] = random(-600f, 600f);

	self->think = G_FreeEdict;
	self->nextthink = level.framenum + (int)(random(10f, 20f) * BASE_FRAMERATE);

	gi.linkentity (self);
}

/*QUAKED misc_crashviper (1 .5 0) (-176 -120 -24) (176 120 72) 
This is a large viper about to crash
*/
API_FUNC static void(entity ent) SP_misc_crashviper =
{
	if (!ent->target)
	{
		gi.dprintf ("misc_viper without a target at %s\n", vtos(ent->absmin));
		G_FreeEdict (ent);
		return;
	}

	if (!ent->speed)
		ent->speed = 300f;

	ent->movetype = MOVETYPE_PUSH;
	ent->solid = SOLID_NOT;
	ent->s.modelindex = gi.modelindex ("models/ships/bigviper/tris.md2");
	ent->mins = '-16 -16 0';
	ent->maxs = '16 16 32';

	ent->think = func_train_find;
	ent->nextthink = level.framenum + 1;
	ent->use = misc_viper_use;
	ent->svflags |= SVF_NOCLIENT;
	ent->moveinfo.accel = ent->moveinfo.decel = ent->moveinfo.speed = ent->speed;

	gi.linkentity (ent);
}

// RAFAEL
/*QUAKED misc_viper_missile (1 0 0) (-8 -8 -8) (8 8 8)
"dmg"	how much boom should the bomb make? the default value is 250
*/

static void(entity self, entity other, entity cactivator) misc_viper_missile_use =
{
	vector	forward, right, up;
	vector	start, dir;
	vector	vec;
	
	AngleVectors (self->s.angles, &forward, &right, &up);
	
	self->enemy = G_Find (null_entity, targetname, self->target);
	
	vec = self->enemy->s.origin;
	vec[2] += 16;	// Knightmare fixed
	
	start = self->s.origin;
	dir = vec - start;
	VectorNormalize (dir);
	
	monster_fire_rocket (self, start, dir, self->dmg, 500, MZ2_CHICK_ROCKET_1);
	
	self->nextthink = level.framenum + 1;
	self->think = G_FreeEdict;
}

API_FUNC static void(entity self) SP_misc_viper_missile =
{
	self->movetype = MOVETYPE_NONE;
	self->solid = SOLID_NOT;
	self->mins = '-8 -8 -8';
	self->maxs = '8 8 8';

	if (!self->dmg)
		self->dmg = 250;

	self->s.modelindex = gi.modelindex ("models/objects/bomb/tris.md2");

	self->use = misc_viper_missile_use;
	self->svflags |= SVF_NOCLIENT;

	gi.linkentity (self);
}

/*QUAKED misc_transport (1 0 0) (-8 -8 -8) (8 8 8) TRIGGER_SPAWN
Maxx's transport at end of game
*/
API_FUNC static void(entity ent) SP_misc_transport =
{
	if (!ent->target)
	{
		gi.dprintf ("%s without a target at %s\n", ent->classname, vtos(ent->absmin));
		G_FreeEdict (ent);
		return;
	}

	if (!ent->speed)
		ent->speed = 300f;

	ent->movetype = MOVETYPE_PUSH;
	ent->solid = SOLID_NOT;
	ent->s.modelindex = gi.modelindex ("models/objects/ship/tris.md2");

	ent->mins = '-16 -16 0';
	ent->maxs = '16 16 32';

	ent->think = func_train_find;
	ent->nextthink = level.framenum + 1;
	ent->use = misc_strogg_ship_use;
	ent->svflags |= SVF_NOCLIENT;
	ent->moveinfo.accel = ent->moveinfo.decel = ent->moveinfo.speed = ent->speed;

	if (!(ent->spawnflags & 1))
	{
		ent->spawnflags |= 1;
	}
	
	gi.linkentity (ent);
}

/*QUAKED misc_amb4 (1 0 0) (-16 -16 -16) (16 16 16)
Mal's amb4 loop entity
*/
static int amb4sound;

static void(entity ent) amb4_think =
{
	ent->nextthink = level.framenum + (int)(2.7 * BASE_FRAMETIME);
	gi.sound(ent, CHAN_VOICE, amb4sound, 1, ATTN_NONE, 0);
}

API_FUNC static void(entity ent) SP_misc_amb4 =
{
	ent->think = amb4_think;
	ent->nextthink = level.framenum + 1 * BASE_FRAMETIME;
	amb4sound = gi.soundindex ("world/amb4.wav");
	gi.linkentity (ent);
}

/*QUAKED misc_nuke (1 0 0) (-16 -16 -16) (16 16 16)
*/

static void(entity self, entity other, entity cactivator) use_nuke =
{
	int fromn = 0;

	for ( ; fromn < globals.num_edicts; fromn++)
	{
		entity from = itoe(fromn);
		
		if (from == self)
			continue;
		if (from->is_client)
		{
			T_Damage (from, self, self, vec3_origin, from->s.origin, vec3_origin, 100000, 1, 0, MOD_TRAP);
		}
		else if (from->svflags & SVF_MONSTER)
		{
			G_FreeEdict (from);
		}
	}

	self->use = 0;
}

API_FUNC static void(entity ent) SP_misc_nuke =
{
	ent->use = use_nuke;
}

#endif