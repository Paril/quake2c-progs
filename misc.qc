/*QUAKED func_group (0 0 0) ?
Used to group brushes together just for editor convenience.
*/

//=====================================================

static void(entity ent, entity other, entity activator) Use_Areaportal =
{
	ent->count = BitxorInt(ent->count, 1);        // toggle state
	gi.SetAreaPortalState(ent->style, ent->count);
}

/*QUAKED func_areaportal (0 0 0) ?

This is a non-visible object that divides the world into
areas that are seperated when this portal is not activated.
Usually enclosed in the middle of a door.
*/
__used static void(entity ent) SP_func_areaportal =
{
	ent->use = Use_Areaportal;
	ent->count = 0;     // always start closed;
}

//=====================================================


/*
=================
Misc functions
=================
*/
static void(int damage, __out vector v) VelocityForDamage =
{
	v[(ARRAY_INDEX_TYPE)0] = 100.0f * crand();
	v[(ARRAY_INDEX_TYPE)1] = 100.0f * crand();
	v[(ARRAY_INDEX_TYPE)2] = 200.0f + 100.0f * frand();

	if (damage < 50)
		VectorScale(v, 0.7f, v);
	else
		VectorScale(v, 1.2f, v);
}

static void(entity ent) ClipGibVelocity =
{
	if (ent->velocity[(ARRAY_INDEX_TYPE)0] < -300)
		ent->velocity[(ARRAY_INDEX_TYPE)0] = -300f;
	else if (ent->velocity[(ARRAY_INDEX_TYPE)0] > 300)
		ent->velocity[(ARRAY_INDEX_TYPE)0] = 300f;
	if (ent->velocity[(ARRAY_INDEX_TYPE)1] < -300)
		ent->velocity[(ARRAY_INDEX_TYPE)1] = -300f;
	else if (ent->velocity[(ARRAY_INDEX_TYPE)1] > 300)
		ent->velocity[(ARRAY_INDEX_TYPE)1] = 300f;
	if (ent->velocity[(ARRAY_INDEX_TYPE)2] < 200)
		ent->velocity[(ARRAY_INDEX_TYPE)2] = 200f; // always some upwards
	else if (ent->velocity[(ARRAY_INDEX_TYPE)2] > 500)
		ent->velocity[(ARRAY_INDEX_TYPE)2] = 500f;
}


/*
=================
gibs
=================
*/
static void(entity self) gib_think =
{
	self->s.frame++;
	self->nextthink = level.framenum + 1;

	if (self->s.frame == 10) {
		self->think = G_FreeEdict;
		self->nextthink = level.framenum + (int)((8 + frand() * 10) * BASE_FRAMERATE);
	}
}

static void(entity self, entity other, cplane_t plane, csurface_t surf) gib_touch =
{
	vector	normal_angles, right;

	if (self->groundentity == null_entity)
		return;

	self->touch = 0;

	if (plane.normal) {
		gi.sound(self, CHAN_VOICE, gi.soundindex("misc/fhit3.wav"), 1, ATTN_NORM, 0);

		vectoangles(plane->normal, normal_angles);
		AngleVectors(normal_angles, unref_vec, right, unref_vec);
		vectoangles(right, self->s.angles);

		if (self->s.modelindex == sm_meat_index) {
			self->s.frame++;
			self->think = gib_think;
			self->nextthink = level.framenum + 1;
		}
	}
}

void(entity self, entity inflictor, entity attacker, int damage, vector point) gib_die =
{
	G_FreeEdict(self);
}

void(entity self, string gibname, int damage, gib_type_t type) ThrowGib =
{
	entity	gib;
	vector	vd;
	vector	origin;
	vector	sz;
	float	vscale;

	gib = G_Spawn();

	VectorScale(self->size, 0.5f, sz);
	VectorAdd(self->absmin, sz, origin);
	gib->s.origin[(ARRAY_INDEX_TYPE)0] = origin[(ARRAY_INDEX_TYPE)0] + crand() * sz[(ARRAY_INDEX_TYPE)0];
	gib->s.origin[(ARRAY_INDEX_TYPE)1] = origin[(ARRAY_INDEX_TYPE)1] + crand() * sz[(ARRAY_INDEX_TYPE)1];
	gib->s.origin[(ARRAY_INDEX_TYPE)2] = origin[(ARRAY_INDEX_TYPE)2] + crand() * sz[(ARRAY_INDEX_TYPE)2];

	gi.setmodel(gib, gibname);
	gib->solid = SOLID_NOT;
	gib->s.effects |= EF_GIB;
	gib->flags |= FL_NO_KNOCKBACK;
	gib->takedamage = DAMAGE_YES;
	gib->die = gib_die;

	if (type == GIB_ORGANIC) {
		gib->movetype = MOVETYPE_TOSS;
		gib->touch = gib_touch;
		vscale = 0.5f;
	} else {
		gib->movetype = MOVETYPE_BOUNCE;
		vscale = 1.0f;
	}

	VelocityForDamage(damage, vd);
	VectorMA(self->velocity, vscale, vd, gib->velocity);
	ClipGibVelocity(gib);
	gib->avelocity[(ARRAY_INDEX_TYPE)0] = frand() * 600;
	gib->avelocity[(ARRAY_INDEX_TYPE)1] = frand() * 600;
	gib->avelocity[(ARRAY_INDEX_TYPE)2] = frand() * 600;

	gib->think = G_FreeEdict;
	gib->nextthink = level.framenum + (int)((10 + frand() * 10) * BASE_FRAMERATE);

	gi.linkentity(gib);
}

void(entity self, string gibname, int damage, gib_type_t type) ThrowHead =
{
	vector	vd;
	float	vscale;

	self->s.skinnum = 0;
	self->s.frame = 0;
	VectorClear(self->mins);
	VectorClear(self->maxs);

	self->s.modelindex2 = 0;
	gi.setmodel(self, gibname);
	self->solid = SOLID_NOT;
	self->s.effects |= EF_GIB;
	self->s.effects &= ~EF_FLIES;
	self->s.sound = 0;
	self->flags |= FL_NO_KNOCKBACK;
	self->svflags &= ~SVF_MONSTER;
	self->takedamage = DAMAGE_YES;
	self->die = gib_die;

	if (type == GIB_ORGANIC) {
		self->movetype = MOVETYPE_TOSS;
		self->touch = gib_touch;
		vscale = 0.5f;
	} else {
		self->movetype = MOVETYPE_BOUNCE;
		vscale = 1.0f;
	}

	VelocityForDamage(damage, vd);
	VectorMA(self->velocity, vscale, vd, self->velocity);
	ClipGibVelocity(self);

	self->avelocity[YAW] = crand() * 600;

	self->think = G_FreeEdict;
	self->nextthink = level.framenum + (int)((10 + frand() * 10) * BASE_FRAMERATE);

	gi.linkentity(self);
}


void(entity self, int damage) ThrowClientHead =
{
	vector	vd;
	string	gibname;

	if (Q_rand() & 1) {
		gibname = "models/objects/gibs/head2/tris.md2";
		self->s.skinnum = 1;        // second skin is player
	} else {
		gibname = "models/objects/gibs/skull/tris.md2";
		self->s.skinnum = 0;
	}

	self->s.origin[(ARRAY_INDEX_TYPE)2] += 32;
	self->s.frame = 0;
	gi.setmodel(self, gibname);
	VectorSet(self->mins, -16, -16, 0);
	VectorSet(self->maxs, 16, 16, 16);

	self->takedamage = DAMAGE_NO;
	self->solid = SOLID_NOT;
	self->s.effects = EF_GIB;
	self->s.sound = 0;
	self->flags |= FL_NO_KNOCKBACK;

	self->movetype = MOVETYPE_BOUNCE;
	VelocityForDamage(damage, vd);
	VectorAdd(self->velocity, vd, self->velocity);

	if (self->is_client) { // bodies in the queue don't have a client anymore
		self->client->anim_priority = ANIM_DEATH;
		self->client->anim_end = self->s.frame;
	} else {
		self->think = 0;
		self->nextthink = 0;
	}

	gi.linkentity(self);
}



/*QUAKED misc_teleporter_dest (1 0 0) (-32 -32 -24) (32 32 -16)
Point teleporters at these.
*/
__used void(entity ent) SP_misc_teleporter_dest =
{
    gi.setmodel(ent, "models/objects/dmspot/tris.md2");
    ent->s.skinnum = 0;
    ent->solid = SOLID_BBOX;
    VectorSet(ent->mins, -32, -32, -24);
    VectorSet(ent->maxs, 32, 32, -16);
    gi.linkentity(ent);
}
