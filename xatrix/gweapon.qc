#ifdef THE_RECKONING

static void(entity self) ionripper_sparks =
{
	gi.WriteByte (svc_temp_entity);
	gi.WriteByte (TE_WELDING_SPARKS);
	gi.WriteByte (0);
	gi.WritePosition (self.s.origin);
	gi.WriteDir (vec3_origin);
	gi.WriteByte (0xe4 + (Q_rand() & 3));
	gi.multicast (self.s.origin, MULTICAST_PVS);

	G_FreeEdict (self);
}

static void(entity self, entity other, vector normal, csurface_t surf) ionripper_touch =
{
	if (other == self.owner)
		return;

	if (surf && (surf.flags & SURF_SKY))
	{
		G_FreeEdict (self);
		return;
	}

	if (self.owner.is_client)
		PlayerNoise (self.owner, self.s.origin, PNOISE_IMPACT);

	if (other.takedamage)
	{
		T_Damage (other, self, self.owner, self.velocity, self.s.origin, normal, self.dmg, 1, DAMAGE_ENERGY, MOD_RIPPER);
		G_FreeEdict (self);
	}
}

PROGS_LOCAL void(entity self, vector start, vector dir, int damage, int speed, entity_effects_t effect) fire_ionripper =
{
	VectorNormalize (dir);

	entity ion = G_Spawn ();
	ion.s.origin = ion.s.old_origin = start;
	ion.s.angles = vectoangles (dir);
	ion.velocity = dir * speed;

	ion.movetype = MOVETYPE_WALLBOUNCE;
	ion.clipmask = MASK_SHOT;
	ion.solid = SOLID_BBOX;
	ion.s.effects |= effect;

	ion.s.renderfx |= RF_FULLBRIGHT;

	ion.s.modelindex = gi.modelindex ("models/objects/boomrang/tris.md2");
	ion.s.sound = gi.soundindex ("misc/lasfly.wav");
	ion.owner = self;
	ion.touch = ionripper_touch;
	ion.nextthink = level.framenum + 3 * BASE_FRAMERATE;
	ion.think = ionripper_sparks;
	ion.dmg = damage;
	ion.dmg_radius = 100f;
	gi.linkentity (ion);

	if (self.is_client)
		check_dodge (self, ion.s.origin, dir, speed);

	trace_t tr;
	gi.traceline(&tr, self.s.origin, ion.s.origin, ion, MASK_SHOT);
	if (tr.fraction < 1.0)
	{
		ion.s.origin += dir * -10;
		ion.touch (ion, tr.ent, vec3_origin, null_surface);
	}
}

static void(entity self) heat_think =
{
	float	oldlen = 0;
	entity	target = world;
	entity	aquire = world;

	// acquire new target
	while ((target = findradius (target, self.s.origin, 1024)))
	{
		if (self.owner == target)
			continue;
		if ((target.svflags & SVF_MONSTER) || !target.is_client)
			continue;
		if (target.health <= 0)
			continue;
		if (!visible (self, target))
			continue;
		if (!infront (self, target))
			continue;

		vector vec = self.s.origin - target.s.origin;
		float len = VectorLength (vec);

		if (!aquire || len < oldlen)
		{
			aquire = target;
			self.target_ent = aquire;
			oldlen = len;
		}
	}

	if (aquire)
	{
		vector oldang = self.s.angles;
		vector vec = aquire.s.origin - self.s.origin;
		
		self.s.angles = vectoangles (vec);
		
		VectorNormalize (vec);
		self.movedir = vec;
		self.velocity = vec * 500;
	}

	self.nextthink = level.framenum + 1;
}

inline void(entity self, vector start, vector dir, int damage, int speed, float damage_radius, int radius_damage) fire_heat =
{
	entity heat = fire_rocket(self, start, dir, damage, speed, damage_radius, radius_damage);
	heat.nextthink = level.framenum + 1;
	heat.think = heat_think;
}

static void(entity ent, entity other, vector normal, csurface_t surf) plasma_touch =
{
	if (other == ent.owner)
		return;

	if (surf && (surf.flags & SURF_SKY))
	{
		G_FreeEdict (ent);
		return;
	}

	if (ent.owner.is_client)
		PlayerNoise(ent.owner, ent.s.origin, PNOISE_IMPACT);

	// calculate position for the explosion entity
	vector origin = ent.s.origin + (ent.velocity * -0.02);

	if (other.takedamage)
		T_Damage (other, ent, ent.owner, ent.velocity, ent.s.origin, normal, ent.dmg, 0, 0, MOD_PHALANX);
	
	T_RadiusDamage(ent, ent.owner, ent.radius_dmg, other, ent.dmg_radius, MOD_PHALANX);

	gi.WriteByte (svc_temp_entity);
	gi.WriteByte (TE_PLASMA_EXPLOSION);
	gi.WritePosition (origin);
	gi.multicast (ent.s.origin, MULTICAST_PVS);
	
	G_FreeEdict (ent);
}

void(entity self, vector start, vector dir, int damage, int speed, float damage_radius, int radius_damage) fire_plasma =
{
	entity plasma = G_Spawn();
	plasma.s.origin = start;
	plasma.movedir = dir;
	plasma.s.angles = vectoangles (dir);
	plasma.velocity = dir * speed;
	plasma.movetype = MOVETYPE_FLYMISSILE;
	plasma.clipmask = MASK_SHOT;
	plasma.solid = SOLID_BBOX;
	
	plasma.owner = self;
	plasma.touch = plasma_touch;
	plasma.nextthink = level.framenum + BASE_FRAMERATE * 8000 / speed;
	plasma.think = G_FreeEdict;
	plasma.dmg = damage;
	plasma.radius_dmg = radius_damage;
	plasma.dmg_radius = damage_radius;
	plasma.s.sound = gi.soundindex ("weapons/rockfly.wav");
	
	plasma.s.modelindex = gi.modelindex ("sprites/s_photon.sp2");
	plasma.s.effects |= EF_PLASMA | EF_ANIM_ALLFAST;
	
	if (self.is_client)
		check_dodge (self, plasma.s.origin, dir, speed);

	gi.linkentity (plasma);
}

// from xatrix/item.qc
API_FUNC void(entity self) SP_item_foodcube;

static void(entity ent) Trap_Gib_Think =
{
	if (ent.owner.s.frame != 5)
	{
		G_FreeEdict(ent);
		return;
	}

	vector forward;
	AngleVectors (ent.s.angles, &forward, 0, 0);

	float angle = DEG2RAD(ent.dmg_radius + ent.owner.delay) * 4.f;
	ent.s.origin = ([ -cos(angle), sin(angle), 0 ] * (ent.owner.wait * 0.5f)) + ent.owner.s.origin + forward;
	ent.s.origin[2] = ent.owner.s.origin[2] + ent.owner.wait;

	gi.linkentity (ent);

	ent.nextthink = level.framenum + 1;
};

static void(entity ent) Trap_Think =
{
	if (ent.timestamp < level.framenum)
	{
		BecomeExplosion1(ent);
		return;
	}
	
	ent.nextthink = level.framenum + 1;
	
	if (ent.groundentity == null_entity)
		return;

	// ok lets do the blood effect
	if (ent.s.frame > 4)
	{
		if (ent.s.frame == 5)
		{
			if (ent.wait == 64)
			{
				gi.sound(ent, CHAN_VOICE, gi.soundindex ("weapons/trapdown.wav"), 1, ATTN_IDLE, 0);

				for (int i = 0; i < 3; i++)
				{
					entity best = G_Spawn();

					if (ent.enemy.classname == "monster_gekk")
					{
						best.s.modelindex = gi.modelindex ("models/objects/gekkgib/torso/tris.md2");	
						best.s.effects |= EF_GREENGIB;
					}
					else if (ent.enemy.mass > 200)
					{
						best.s.modelindex = gi.modelindex ("models/objects/gibs/chest/tris.md2");	
						best.s.effects |= EF_GIB;
					}
					else
					{
						best.s.modelindex = gi.modelindex ("models/objects/gibs/sm_meat/tris.md2");	
						best.s.effects |= EF_GIB;
					}
					
					best.dmg_radius = (360.0 / 3) * i;
					best.think = Trap_Gib_Think;
					best.nextthink = level.framenum + 1;
					best.s.angles = ent.s.angles;
					best.solid = SOLID_NOT;
					best.takedamage = true;
					best.movetype = MOVETYPE_NONE;
					best.svflags |= SVF_MONSTER;
					best.deadflag = DEAD_DEAD;
					best.owner = ent;
					best.watertype = gi.pointcontents(best.s.origin);
					if (best.watertype & MASK_WATER)
						best.waterlevel = 1;

					Trap_Gib_Think(best);
				}
			}

			ent.wait -= 2;
			ent.delay += level.time;
				
			if (ent.wait < 19)
				ent.s.frame++;

			return;
		}
		ent.s.frame ++;
		if (ent.s.frame == 8)
		{
			ent.nextthink = level.framenum + 1 * BASE_FRAMERATE;
			ent.think = G_FreeEdict;

			entity best = G_Spawn ();
			SP_item_foodcube (best);
			best.s.origin = ent.s.origin;
			best.s.origin[2] += 16;
			best.velocity.z = 400f;
			best.count = ent.mass;
			gi.linkentity (best);
			return;
		}
		return;
	}
	
	ent.s.effects &= ~EF_TRAP;
	if (ent.s.frame >= 4)
	{
		ent.s.effects |= EF_TRAP;
		ent.mins = ent.maxs = vec3_origin;
	}

	if (ent.s.frame < 4)
		ent.s.frame++;

	entity	target = world, best = world;
	float	oldlen = 8000;
	
	while ((target = findradius(target, ent.s.origin, 256)))
	{
		if (target == ent)
			continue;
		if (!(target.svflags & SVF_MONSTER) && !target.is_client)
			continue;
		if (target.health <= 0)
			continue;
		if (!visible (ent, target))
		 	continue;
		if (!best)
		{
			best = target;
			continue;
		}
		vector vec = ent.s.origin - target.s.origin;
		float len = VectorLength (vec);
		if (len < oldlen)
		{
			oldlen = len;
			best = target;
		}
	}

	// pull the enemy in
	if (!best)
		return;

	if (best.groundentity != null_entity)
	{
		best.s.origin[2] += 1;
		best.groundentity = null_entity;
	}

	vector vec = ent.s.origin - best.s.origin;
	float len = VectorLength (vec);

	if (best.is_client)
	{
		VectorNormalize (vec);
		best.velocity += vec * 250;
	}
	else
	{
		vector forward;
		best.ideal_yaw = vectoyaw(vec);	
		M_ChangeYaw (best);
		AngleVectors (best.s.angles, &forward, 0, 0);
		best.velocity = forward * 256;
	}

	gi.sound(ent, CHAN_VOICE, gi.soundindex ("weapons/trapsuck.wav"), 1, ATTN_IDLE, 0);
	
	if (len >= 32)
		return;

	if (best.mass < 400)
	{
		T_Damage (best, ent, ent.owner, vec3_origin, best.s.origin, vec3_origin, 100000, 1, DAMAGE_NO_PROTECTION, MOD_TRAP);
		ent.enemy = best;
		ent.wait = 64f;
		ent.s.old_origin = ent.s.origin;
		ent.timestamp = level.framenum + 30 * BASE_FRAMERATE;

		if (deathmatch.intVal)
			ent.mass = (int)(best.mass * 0.25f);
		else
			ent.mass = (int)(best.mass * 0.1f);

		ent.s.frame = 5;
		return;
	}

	BecomeExplosion1(ent);
}

// RAFAEL
void(entity self, vector start, vector aimdir, int damage, int speed, float timer, float damage_radius, bool held) fire_trap =
{
	vector dir = vectoangles (aimdir);
	vector right, up;
	AngleVectors (dir, 0, &right, &up);

	entity trap = G_Spawn();
	trap.s.origin = start;
	trap.velocity = aimdir * speed;
	trap.velocity += random(190f, 210f) * up;
	trap.velocity += random(-10f, 10f) * right;
	trap.avelocity = '0 300 0';
	trap.movetype = MOVETYPE_BOUNCE;
	trap.clipmask = MASK_SHOT;
	trap.solid = SOLID_BBOX;
	trap.mins = '4 -4 0';
	trap.maxs = '4 4 8';
	trap.s.modelindex = gi.modelindex ("models/weapons/z_trap/tris.md2");
	trap.owner = self;
	trap.nextthink = level.framenum + 1 * BASE_FRAMERATE;
	trap.think = Trap_Think;
	trap.dmg = damage;
	trap.dmg_radius = damage_radius;
	trap.classname = "htrap";
	trap.s.sound = gi.soundindex ("weapons/traploop.wav");
	if (held)
		trap.spawnflags = 3;
	else
		trap.spawnflags = 1;
	
	if (timer <= 0.0)
		Grenade_Explode (trap);
	else
		gi.linkentity (trap);
	
	trap.timestamp = level.framenum + 30 * BASE_FRAMERATE;

}

#endif