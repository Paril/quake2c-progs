#ifdef SINGLE_PLAYER
/*
=================
check_dodge

This is a support routine used when a client is firing
a non-instant attack weapon.  It checks to see if a
monster's dodge function should be called.
=================
*/
void(entity self, vector start, vector dir, int speed) check_dodge =
{
	vector	end;
	vector	v;
	trace_t	tr;
	float	eta;

	// easy mode only ducks one quarter the time
	if (skill.intVal == 0) {
		if (random() > 0.25f)
			return;
	}
	end = start + (8192 * dir);
	gi.traceline(&tr, start, end, self, MASK_SHOT);
	if ((tr.ent) && (tr.ent.svflags & SVF_MONSTER) && (tr.ent.health > 0) && (tr.ent.monsterinfo.dodge) && infront(tr.ent, self)) {
		v = tr.endpos - start;
		eta = (VectorLength(v) - tr.ent.maxs.x) / speed;
		tr.ent.monsterinfo.dodge(tr.ent, self, eta
#ifdef GROUND_ZERO
			, &tr
#endif
		);
	}
}

/*
=================
fire_hit

Used for all impact (hit/punch/slash) attacks
=================
*/
bool(entity self, vector aim, int damage, int kick) fire_hit =
{
	trace_t	tr;
	vector	forward, right, up;
	vector	v;
	vector	point;
	float	range;
	vector	dir;

	//see if enemy is in range
	dir = self.enemy.s.origin - self.s.origin;
	range = VectorLength(dir);

	if (range > aim.x)
		return false;

	if (aim.y > self.mins.x && aim.y < self.maxs.x)
		// the hit is straight on so back the range up to the edge of their bbox
		range -= self.enemy.maxs.x;
	// this is a side hit so adjust the "right" value out to the edge of their bbox
	else if (aim.y < 0)
		aim.y = self.enemy.mins.x;
	else
		aim.y = self.enemy.maxs.x;

	point = self.s.origin + (range * dir);

	gi.traceline(&tr, self.s.origin, point, self, MASK_SHOT);
	if (tr.fraction < 1)
	{
		if (!tr.ent.takedamage)
			return false;
		// if it will hit any client/monster then hit the one we wanted to hit
		if ((tr.ent.svflags & SVF_MONSTER) || (tr.ent.is_client))
			tr.ent = self.enemy;
	}

	AngleVectors(self.s.angles, &forward, &right, &up);
	point = self.s.origin + (range * forward);
	point = point + (aim.y * right);
	point = point + (aim.z * up);
	dir = point - self.enemy.s.origin;

	// do the damage
	T_Damage(tr.ent, self, self, dir, point, vec3_origin, damage, kick / 2, DAMAGE_NO_KNOCKBACK, MOD_HIT);

	if (!(tr.ent.svflags & SVF_MONSTER) && (!tr.ent.is_client))
		return false;

	// do our special form of knockback here
	v = self.enemy.absmin + (0.5f * self.enemy.size);
	v -= point;
	VectorNormalize(v);
	self.enemy.velocity += (kick * v);
	if (self.enemy.velocity.z > 0)
		self.enemy.groundentity = null_entity;
	return true;
}
#endif

/*
=================
fire_lead

This is an internal support routine used for bullet/pellet based weapons.
=================
*/
static void(entity self, vector start, vector aimdir, int damage, int kick, int te_impact, int hspread, int vspread, means_of_death_t mod) fire_lead =
{
	trace_t	tr;
	vector	dir;
	vector	forward, right, up;
	vector	end;
	float	r;
	float	u;
	vector	water_start = vec3_origin;
	bool	water = false;
	int	content_mask = MASK_SHOT | MASK_WATER;
	
	gi.traceline(&tr, self.s.origin, start, self, MASK_SHOT);
	if (!(tr.fraction < 1.0f))
	{
		dir = vectoangles(aimdir);

		AngleVectors(dir, &forward, &right, &up);

		r = crandom() * hspread;
		u = crandom() * vspread;
		end = start + (8192 * forward);
		end += (r * right);
		end += (u * up);

		if (gi.pointcontents(start) & MASK_WATER)
		{
			water = true;
			water_start = start;
			content_mask &= ~MASK_WATER;
		}

		gi.traceline(&tr, start, end, self, content_mask);

		// see if we hit water
		if (tr.contents & MASK_WATER)
		{
			int     color;

			water = true;
			water_start = tr.endpos;

			if (start != tr.endpos)
			{
				if (tr.contents & CONTENTS_WATER)
				{
					if (tr.surface.name == "*brwater")
						color = SPLASH_BROWN_WATER;
					else
						color = SPLASH_BLUE_WATER;
				}
				else if (tr.contents & CONTENTS_SLIME)
					color = SPLASH_SLIME;
				else if (tr.contents & CONTENTS_LAVA)
					color = SPLASH_LAVA;
				else
					color = SPLASH_UNKNOWN;

				if (color != SPLASH_UNKNOWN)
				{
					gi.WriteByte(svc_temp_entity);
					gi.WriteByte(TE_SPLASH);
					gi.WriteByte(8);
					gi.WritePosition(tr.endpos);
					gi.WriteDir(tr.normal);
					gi.WriteByte(color);
					gi.multicast(tr.endpos, MULTICAST_PVS);
				}

				// change bullet's course when it enters water
				dir = end - start;
				dir = vectoangles(dir);
				AngleVectors(dir, &forward, &right, &up);
				r = crandom() * hspread * 2;
				u = crandom() * vspread * 2;
				end = water_start + (8192 * forward);
				end += (r * right);
				end += (u * up);
			}

			// re-trace ignoring water this time
			gi.traceline(&tr, water_start, end, self, MASK_SHOT);
		}
	}

	// send gun puff / flash
	if (!(tr.surface && (tr.surface.flags & SURF_SKY)))
	{
		if (tr.fraction < 1.0f)
		{
			if (tr.ent.takedamage)
				T_Damage(tr.ent, self, self, aimdir, tr.endpos, tr.normal, damage, kick, DAMAGE_BULLET, mod);
			else if (strncmp(tr.surface.name, "sky", 3) != 0)
			{
				gi.WriteByte(svc_temp_entity);
				gi.WriteByte(te_impact);
				gi.WritePosition(tr.endpos);
				gi.WriteDir(tr.normal);
				gi.multicast(tr.endpos, MULTICAST_PVS);

#if defined(SINGLE_PLAYER)
				if (self.is_client)
					PlayerNoise(self, tr.endpos, PNOISE_IMPACT);
#endif
			}
		}
	}

	// if went through water, determine where the end and make a bubble trail
	if (water)
	{
		vector	pos;

		dir = tr.endpos - water_start;
		VectorNormalize(dir);
		pos = tr.endpos + (-2 * dir);
		if (gi.pointcontents(pos) & MASK_WATER)
			tr.endpos = pos;
		else
			gi.traceline(&tr, pos, water_start, tr.ent, MASK_WATER);

		pos = water_start + tr.endpos;
		pos *= 0.5f;

		gi.WriteByte(svc_temp_entity);
		gi.WriteByte(TE_BUBBLETRAIL);
		gi.WritePosition(water_start);
		gi.WritePosition(tr.endpos);
		gi.multicast(pos, MULTICAST_PVS);
	}
}


/*
=================
fire_bullet

Fires a single round.  Used for machinegun and chaingun.  Would be fine for
pistols, rifles, etc....
=================
*/
void(entity self, vector start, vector aimdir, int damage, int kick, int hspread, int vspread, means_of_death_t mod) fire_bullet =
{
	fire_lead(self, start, aimdir, damage, kick, TE_GUNSHOT, hspread, vspread, mod);
}


/*
=================
fire_shotgun

Shoots shotgun pellets.  Used by shotgun and super shotgun.
=================
*/
void(entity self, vector start, vector aimdir, int damage, int kick, int hspread, int vspread, int count, means_of_death_t mod) fire_shotgun =
{
	for (int i = 0; i < count; i++)
		fire_lead(self, start, aimdir, damage, kick, TE_SHOTGUN, hspread, vspread, mod);
}


/*
=================
fire_blaster

Fires a single blaster bolt.  Used by the blaster and hyper blaster.
=================
*/
static void(entity self, entity other, vector normal, csurface_t surf) blaster_touch =
{
	int     mod;

	if (other == self.owner)
		return;

	if (surf && (surf.flags & SURF_SKY))
	{
		G_FreeEdict(self);
		return;
	}
#if defined(SINGLE_PLAYER)

	if (self.owner.is_client)
		PlayerNoise(self.owner, self.s.origin, PNOISE_IMPACT);
#endif

	if (other.takedamage)
	{
		if (self.spawnflags & 1)
			mod = MOD_HYPERBLASTER;
		else
			mod = MOD_BLASTER;
		T_Damage(other, self, self.owner, self.velocity, self.s.origin, normal, self.dmg, 1, DAMAGE_ENERGY, mod);
	}
	else
	{
		gi.WriteByte(svc_temp_entity);
#ifdef THE_RECKONING
		if (self.s.effects & EF_BLUEHYPERBLASTER)	// Knightmare- this was checking bit TE_BLUEHYPERBLASTER
			gi.WriteByte (TE_FLECHETTE);			// Knightmare- TE_BLUEHYPERBLASTER is broken (parse error) in most Q2 engines
		else
#endif
			gi.WriteByte(TE_BLASTER);
		gi.WritePosition(self.s.origin);
		gi.WriteDir(normal);
		gi.multicast(self.s.origin, MULTICAST_PVS);
	}

	G_FreeEdict(self);
}

void(entity self, vector start, vector dir, int damage, int speed, int effect, bool hyper) fire_blaster =
{
	entity	bolt;
	trace_t	tr;

	VectorNormalize(dir);

	bolt = G_Spawn();
	bolt.svflags = SVF_DEADMONSTER;
	// yes, I know it looks weird that projectiles are deadmonsters
	// what this means is that when prediction is used against the object
	// (blaster/hyperblaster shots), the player won't be solid clipped against
	// the object.  Right now trying to run into a firing hyperblaster
	// is very jerky since you are predicted 'against' the shots.
	bolt.s.origin = start;
	bolt.s.old_origin = start;
	bolt.s.angles = vectoangles(dir);
	bolt.velocity = dir * speed;
	bolt.movetype = MOVETYPE_FLYMISSILE;
	bolt.clipmask = MASK_SHOT;
	bolt.solid = SOLID_BBOX;
	bolt.s.effects |= effect;
	bolt.mins = vec3_origin;
	bolt.maxs = vec3_origin;
#ifdef THE_RECKONING
	if (effect & EF_BLUEHYPERBLASTER)
		bolt.s.modelindex = gi.modelindex("models/objects/blaser/tris.md2");
	else
#endif
		bolt.s.modelindex = gi.modelindex("models/objects/laser/tris.md2");
	bolt.s.sound = gi.soundindex("misc/lasfly.wav");
	bolt.owner = self;
	bolt.touch = blaster_touch;
	bolt.nextthink = level.framenum + 2 * BASE_FRAMERATE;
	bolt.think = G_FreeEdict;
	bolt.dmg = damage;
	bolt.classname = "bolt";
	if (hyper)
		bolt.spawnflags = 1;
	gi.linkentity(bolt);

#ifdef SINGLE_PLAYER
	if (self.is_client)
		check_dodge(self, bolt.s.origin, dir, speed);
#endif

	gi.traceline(&tr, self.s.origin, bolt.s.origin, bolt, MASK_SHOT);
	
	if (tr.fraction < 1.0f)
	{
		bolt.s.origin += (-10 * dir);
		bolt.touch(bolt, tr.ent, vec3_origin, null_surface);
	}
}


/*
=================
fire_grenade
=================
*/
void(entity ent) Grenade_Explode =
{
	vector	origin;
	int	mod;
#if defined(SINGLE_PLAYER)

	if (ent.owner.is_client)
		PlayerNoise(ent.owner, ent.s.origin, PNOISE_IMPACT);
#endif

	//FIXME: if we are onground then raise our Z just a bit since we are a point?
	if (ent.enemy)
	{
		float	points;
		vector	v;
		vector dir;

		v = ent.enemy.mins + ent.enemy.maxs;
		v = ent.enemy.s.origin + (0.5f * v);
		v = ent.s.origin - v;
		points = ent.dmg - 0.5f * VectorLength(v);
		dir = ent.enemy.s.origin - ent.s.origin;
		if (ent.spawnflags & 1)
			mod = MOD_HANDGRENADE;
		else
			mod = MOD_GRENADE;
		T_Damage(ent.enemy, ent, ent.owner, dir, ent.s.origin, vec3_origin, (int)points, (int)points, DAMAGE_RADIUS, mod);
	}

	if (ent.spawnflags & 2)
		mod = MOD_HELD_GRENADE;
	else if (ent.spawnflags & 1)
		mod = MOD_HG_SPLASH;
	else
		mod = MOD_G_SPLASH;
	T_RadiusDamage(ent, ent.owner, ent.dmg, ent.enemy, ent.dmg_radius, mod);

	origin = ent.s.origin + (-0.02f * ent.velocity);
	gi.WriteByte(svc_temp_entity);
	if (ent.waterlevel)
	{
		if (ent.groundentity != null_entity)
			gi.WriteByte(TE_GRENADE_EXPLOSION_WATER);
		else
			gi.WriteByte(TE_ROCKET_EXPLOSION_WATER);
	}
	else
	{
		if (ent.groundentity != null_entity)
			gi.WriteByte(TE_GRENADE_EXPLOSION);
		else
			gi.WriteByte(TE_ROCKET_EXPLOSION);
	}
	gi.WritePosition(origin);
	gi.multicast(ent.s.origin, MULTICAST_PHS);

	G_FreeEdict(ent);
}

static void(entity ent, entity other, vector plane, csurface_t surf) Grenade_Touch =
{
	if (other == ent.owner)
		return;

	if (surf && (surf.flags & SURF_SKY))
	{
		G_FreeEdict(ent);
		return;
	}

	if (!other.takedamage)
	{
		if (ent.spawnflags & 1)
		{
			if (random() > 0.5f)
				gi.sound(ent, CHAN_VOICE, gi.soundindex("weapons/hgrenb1a.wav"), 1, ATTN_NORM, 0);
			else
				gi.sound(ent, CHAN_VOICE, gi.soundindex("weapons/hgrenb2a.wav"), 1, ATTN_NORM, 0);
		}
		else
			gi.sound(ent, CHAN_VOICE, gi.soundindex("weapons/grenlb1b.wav"), 1, ATTN_NORM, 0);

		return;
	}

	ent.enemy = other;
	Grenade_Explode(ent);
}

void(entity self, vector start, vector aimdir, int damage, int speed, float timer, float damage_radius) fire_grenade =
{
	entity	grenade;
	vector	dir;
	vector	forward, right, up;
	float   scale;

	dir = vectoangles(aimdir);
	AngleVectors(dir, &forward, &right, &up);

	grenade = G_Spawn();
	grenade.s.origin = start;
	grenade.velocity = aimdir * speed;
	scale = random(190f, 210f);
	grenade.velocity += (scale * up);
	scale = random(-10f, 10f);
	grenade.velocity += (scale * right);
	grenade.avelocity = '300 300 300';
	grenade.movetype = MOVETYPE_BOUNCE;
	grenade.clipmask = MASK_SHOT;
	grenade.solid = SOLID_BBOX;
	grenade.s.effects |= EF_GRENADE;
	grenade.mins = vec3_origin;
	grenade.maxs = vec3_origin;
	grenade.s.modelindex = gi.modelindex("models/objects/grenade/tris.md2");
	grenade.owner = self;
	grenade.touch = Grenade_Touch;
	grenade.nextthink = level.framenum + (int)(timer * BASE_FRAMERATE);
	grenade.think = Grenade_Explode;
	grenade.dmg = damage;
	grenade.dmg_radius = damage_radius;
	grenade.classname = "grenade";

	gi.linkentity(grenade);
}

void(entity self, vector start, vector aimdir, int damage, int speed, float timer, float damage_radius, bool held) fire_grenade2 =
{
	entity	grenade;
	vector	dir;
	vector	forward, right, up;
	float   scale;

	dir = vectoangles(aimdir);
	AngleVectors(dir, &forward, &right, &up);

	grenade = G_Spawn();
	grenade.s.origin = start;
	grenade.velocity = aimdir * speed;
	scale = random(190f, 210f);
	grenade.velocity += (scale * up);
	scale = random(-10f, 10f);
	grenade.velocity += (scale * right);
	grenade.avelocity = '300 300 300';
	grenade.movetype = MOVETYPE_BOUNCE;
	grenade.clipmask = MASK_SHOT;
	grenade.solid = SOLID_BBOX;
	grenade.s.effects |= EF_GRENADE;
	grenade.mins = vec3_origin;
	grenade.maxs = vec3_origin;
	grenade.s.modelindex = gi.modelindex("models/objects/grenade2/tris.md2");
	grenade.owner = self;
	grenade.touch = Grenade_Touch;
	grenade.nextthink = level.framenum + (int)(timer * BASE_FRAMERATE);
	grenade.think = Grenade_Explode;
	grenade.dmg = damage;
	grenade.dmg_radius = damage_radius;
	grenade.classname = "hgrenade";
	if (held)
		grenade.spawnflags = 3;
	else
		grenade.spawnflags = 1;
	grenade.s.sound = gi.soundindex("weapons/hgrenc1b.wav");

	if (timer <= 0.0f)
		Grenade_Explode(grenade);
	else
	{
		gi.sound(self, CHAN_WEAPON, gi.soundindex("weapons/hgrent1a.wav"), 1, ATTN_NORM, 0);
		gi.linkentity(grenade);
	}
}

// from misc.qc
void(entity self, string modelname, float speed, vector origin) ThrowDebris;

/*
=================
fire_rocket
=================
*/
static void(entity ent, entity other, vector normal, csurface_t surf) rocket_touch =
{
	vector	origin;

	if (other == ent.owner)
		return;

	if (surf && (surf.flags & SURF_SKY))
	{
		G_FreeEdict(ent);
		return;
	}
#if defined(SINGLE_PLAYER)

	if (ent.owner.is_client)
		PlayerNoise(ent.owner, ent.s.origin, PNOISE_IMPACT);
#endif

	// calculate position for the explosion entity
	origin = ent.s.origin + (-0.02f * ent.velocity);

	if (other.takedamage)
		T_Damage(other, ent, ent.owner, ent.velocity, ent.s.origin, normal, ent.dmg, 0, 0, MOD_ROCKET);
#ifdef SINGLE_PLAYER
	// don't throw any debris in net games
	else if (!deathmatch.intVal && !coop.intVal)
	{
		if ((surf) && !(surf.flags & (SURF_WARP | SURF_TRANS33 | SURF_TRANS66 | SURF_FLOWING)))
		{
			int n = Q_rand() % 5;
			while (n--)
				ThrowDebris(ent, "models/objects/debris2/tris.md2", 2, ent.s.origin);
		}
	}
#endif

	T_RadiusDamage(ent, ent.owner, ent.radius_dmg, other, ent.dmg_radius, MOD_R_SPLASH);

	gi.WriteByte(svc_temp_entity);
	if (ent.waterlevel)
		gi.WriteByte(TE_ROCKET_EXPLOSION_WATER);
	else
		gi.WriteByte(TE_ROCKET_EXPLOSION);
	gi.WritePosition(origin);
	gi.multicast(ent.s.origin, MULTICAST_PHS);

	G_FreeEdict(ent);
}

entity(entity self, vector start, vector dir, int damage, int speed, float damage_radius, int radius_damage) fire_rocket =
{
	entity	rocket;

	rocket = G_Spawn();
	rocket.s.origin = start;
	rocket.movedir = dir;
	rocket.s.angles = vectoangles(dir);
	rocket.velocity = dir * speed;
	rocket.movetype = MOVETYPE_FLYMISSILE;
	rocket.clipmask = MASK_SHOT;
	rocket.solid = SOLID_BBOX;
	rocket.s.effects |= EF_ROCKET;
	rocket.mins = vec3_origin;
	rocket.maxs = vec3_origin;
	rocket.s.modelindex = gi.modelindex("models/objects/rocket/tris.md2");
	rocket.owner = self;
	rocket.touch = rocket_touch;
	rocket.nextthink = level.framenum + BASE_FRAMERATE * 8000 / speed;
	rocket.think = G_FreeEdict;
	rocket.dmg = damage;
	rocket.radius_dmg = radius_damage;
	rocket.dmg_radius = damage_radius;
	rocket.s.sound = gi.soundindex("weapons/rockfly.wav");
	rocket.classname = "rocket";

#ifdef SINGLE_PLAYER
	if (self.is_client)
		check_dodge(self, rocket.s.origin, dir, speed);
#endif

	gi.linkentity(rocket);
	return rocket;
}


/*
=================
fire_rail
=================
*/
void(entity self, vector start, vector aimdir, int damage, int kick) fire_rail =
{
	if (gi.pointcontents (start) & MASK_SOLID)
		return;

	vector	from;
	vector	end;
	trace_t	tr = { 0 };
	entity	ignore;
	int	mask;
	bool	water;

	end = start + (8192 * aimdir);
	from = start;
	ignore = self;
	water = false;
	mask = MASK_SHOT | CONTENTS_SLIME | CONTENTS_LAVA;
	while (ignore)
	{
		gi.traceline(&tr, from, end, ignore, mask);

		if (tr.contents & (CONTENTS_SLIME | CONTENTS_LAVA))
		{
			mask &= ~(CONTENTS_SLIME | CONTENTS_LAVA);
			water = true;
		}
		else
		{
			//ZOID--added so rail goes through SOLID_BBOX entities (gibs, etc)
			if ((tr.ent.svflags & SVF_MONSTER) || (tr.ent.is_client) ||
				(tr.ent.solid == SOLID_BBOX))
				ignore = tr.ent;
			else
				ignore = world;

			if ((tr.ent != self) && (tr.ent.takedamage))
				T_Damage(tr.ent, self, self, aimdir, tr.endpos, tr.normal, damage, kick, 0, MOD_RAILGUN);
		}

		from = tr.endpos;
	}

	// send gun puff / flash
	gi.WriteByte(svc_temp_entity);
	gi.WriteByte(TE_RAILTRAIL);
	gi.WritePosition(start);
	gi.WritePosition(tr.endpos);
	gi.multicast(self.s.origin, MULTICAST_PHS);
	if (water)
	{
		gi.WriteByte(svc_temp_entity);
		gi.WriteByte(TE_RAILTRAIL);
		gi.WritePosition(start);
		gi.WritePosition(tr.endpos);
		gi.multicast(tr.endpos, MULTICAST_PHS);
	}
#if defined(SINGLE_PLAYER)

	if (self.is_client)
		PlayerNoise(self, tr.endpos, PNOISE_IMPACT);
#endif
}


/*
=================
fire_bfg
=================
*/
static void(entity self) bfg_explode =
{
	entity	ent;
	float	points;
	vector	v;
	float	dist;

	if (self.s.frame == 0)
	{
		// the BFG effect
		ent = world;
		while ((ent = findradius(ent, self.s.origin, self.dmg_radius)))
		{
			if (!ent.takedamage)
				continue;
			if (ent == self.owner)
				continue;
			if (!CanDamage(ent, self))
				continue;
			if (!CanDamage(ent, self.owner))
				continue;

			v = ent.mins + ent.maxs;
			v = ent.s.origin + (0.5f * v);
			v = self.s.origin - v;
			dist = VectorLength(v);
			points = self.radius_dmg * (1.0f - sqrt(dist / self.dmg_radius));
			if (ent == self.owner)
				points *= 0.5f;

			gi.WriteByte(svc_temp_entity);
			gi.WriteByte(TE_BFG_EXPLOSION);
			gi.WritePosition(ent.s.origin);
			gi.multicast(ent.s.origin, MULTICAST_PHS);
			T_Damage(ent, self, self.owner, self.velocity, ent.s.origin, vec3_origin, (int)points, 0, DAMAGE_ENERGY, MOD_BFG_EFFECT);
		}
	}

	self.nextthink = level.framenum + 1;
	self.s.frame++;
	if (self.s.frame == 5)
		self.think = G_FreeEdict;
}

static void(entity self, entity other, vector normal, csurface_t surf) bfg_touch =
{
	if (other == self.owner)
		return;

	if (surf && (surf.flags & SURF_SKY))
	{
		G_FreeEdict(self);
		return;
	}
#if defined(SINGLE_PLAYER)

	if (self.owner.is_client)
		PlayerNoise(self.owner, self.s.origin, PNOISE_IMPACT);
#endif

	// core explosion - prevents firing it into the wall/floor
	if (other.takedamage)
		T_Damage(other, self, self.owner, self.velocity, self.s.origin, normal, 200, 0, 0, MOD_BFG_BLAST);
	T_RadiusDamage(self, self.owner, 200, other, 100, MOD_BFG_BLAST);

	gi.sound(self, CHAN_VOICE, gi.soundindex("weapons/bfg_.x1b.wav"), 1, ATTN_NORM, 0);
	self.solid = SOLID_NOT;
	self.touch = 0;
	self.s.origin += ((-1 * FRAMETIME) * self.velocity);
	self.velocity = vec3_origin;
	self.s.modelindex = gi.modelindex("sprites/s_bfg3.sp2");
	self.s.frame = 0;
	self.s.sound = 0;
	self.s.effects &= ~EF_ANIM_ALLFAST;
	self.think = bfg_explode;
	self.nextthink = level.framenum + 1;
	self.enemy = other;

	gi.WriteByte(svc_temp_entity);
	gi.WriteByte(TE_BFG_BIGEXPLOSION);
	gi.WritePosition(self.s.origin);
	gi.multicast(self.s.origin, MULTICAST_PVS);
}


static void(entity self) bfg_think =
{
	entity	ent;
	entity	ignore;
	vector	point;
	vector	dir;
	vector	start;
	vector	end;
	trace_t	tr = { 0 };
#ifdef SINGLE_PLAYER
	int	dmg;

	if !(deathmatch.intVal)
		dmg = 10;
	else
		dmg = 5;
#else
	const int dmg = 5;
#endif

	ent = world;
	while ((ent = findradius(ent, self.s.origin, 256)))
	{
		if (ent == self)
			continue;

		if (ent == self.owner)
			continue;

		if (!ent.takedamage)
			continue;

		if (!(ent.svflags & SVF_MONSTER) && (!ent.is_client) && ent.classname != "misc_explobox"
#ifdef GROUND_ZERO
			&& !(ent.svflags & SVF_DAMAGEABLE)
#endif
			)
			continue;

		if (OnSameTeam(self, ent))
			continue;

		point = ent.absmin + (0.5f * ent.size);

		dir = point - self.s.origin;
		VectorNormalize(dir);

		ignore = self;
		start = self.s.origin;
		end = start + (2048 * dir);
		while (1)
		{
			gi.traceline(&tr, start, end, ignore, CONTENTS_SOLID | CONTENTS_MONSTER | CONTENTS_DEADMONSTER);

			if (!tr.ent)
				break;

			// hurt it if we can
			if ((tr.ent.takedamage) && !(tr.ent.flags & FL_IMMUNE_LASER) && (tr.ent != self.owner))
				T_Damage(tr.ent, self, self.owner, dir, tr.endpos, vec3_origin, dmg, 1, DAMAGE_ENERGY, MOD_BFG_LASER);

			// if we hit something that's not a monster or player we're done
			if (!(tr.ent.svflags & SVF_MONSTER) && (!tr.ent.is_client)
#ifdef GROUND_ZERO
				&& !(tr.ent.svflags & SVF_DAMAGEABLE)
#endif
				)
			{
				gi.WriteByte(svc_temp_entity);
				gi.WriteByte(TE_LASER_SPARKS);
				gi.WriteByte(4);
				gi.WritePosition(tr.endpos);
				gi.WriteDir(tr.normal);
				gi.WriteByte(self.s.skinnum);
				gi.multicast(tr.endpos, MULTICAST_PVS);
				break;
			}

			ignore = tr.ent;
			start = tr.endpos;
		}

		gi.WriteByte(svc_temp_entity);
		gi.WriteByte(TE_BFG_LASER);
		gi.WritePosition(self.s.origin);
		gi.WritePosition(tr.endpos);
		gi.multicast(self.s.origin, MULTICAST_PHS);
	}

	self.nextthink = level.framenum + 1;
}


void(entity self, vector start, vector dir, int damage, int speed, float damage_radius) fire_bfg =
{
	entity	bfg;

	bfg = G_Spawn();
	bfg.s.origin = start;
	bfg.movedir = dir;
	bfg.s.angles = vectoangles(dir);
	bfg.velocity = dir * speed;
	bfg.movetype = MOVETYPE_FLYMISSILE;
	bfg.clipmask = MASK_SHOT;
	bfg.solid = SOLID_BBOX;
	bfg.s.effects |= EF_BFG | EF_ANIM_ALLFAST;
	bfg.mins = vec3_origin;
	bfg.maxs = vec3_origin;
	bfg.s.modelindex = gi.modelindex("sprites/s_bfg1.sp2");
	bfg.owner = self;
	bfg.touch = bfg_touch;
	bfg.nextthink = level.framenum + BASE_FRAMERATE * 8000 / speed;
	bfg.think = G_FreeEdict;
	bfg.radius_dmg = damage;
	bfg.dmg_radius = damage_radius;
	bfg.classname = "bfg blast";
	bfg.s.sound = gi.soundindex("weapons/bfg__l1a.wav");

	bfg.think = bfg_think;
	bfg.nextthink = level.framenum + 1;
	bfg.teammaster = bfg;
	bfg.teamchain = world;

#ifdef SINGLE_PLAYER
	if (self.is_client)
		check_dodge(self, bfg.s.origin, dir, speed);
#endif

	gi.linkentity(bfg);
}
