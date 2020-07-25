#ifdef THE_RECKONING

static void(entity self) ionripper_sparks =
{
	gi.WriteByte (svc_temp_entity);
	gi.WriteByte (TE_WELDING_SPARKS);
	gi.WriteByte (0);
	gi.WritePosition (self.s.origin);
	gi.WriteDir (vec3_origin);
	gi.WriteByte (0xe4 + (Q_rand()&3));
	gi.multicast (self.s.origin, MULTICAST_PVS);

	G_FreeEdict (self);
}

static void(entity self, entity other, cplane_t plane, csurface_t surf) ionripper_touch =
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
		T_Damage (other, self, self.owner, self.velocity, self.s.origin, plane.normal, self.dmg, 1, DAMAGE_ENERGY, MOD_RIPPER);
		G_FreeEdict (self);
	}
}

PROGS_LOCAL void(entity self, vector start, vector dir, int damage, int speed, entity_effects_t effect) fire_ionripper =
{
	entity ion;
	trace_t tr;

	VectorNormalize (dir);

	ion = G_Spawn ();
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

	gi.trace (&tr, self.s.origin, vec3_origin, vec3_origin, ion.s.origin, ion, MASK_SHOT);
	if (tr.fraction < 1.0)
	{
		ion.s.origin += dir * -10;
		ion.touch (ion, tr.ent, null_plane, null_surface);
	}

}

static void(entity self) heat_think =
{
	entity	target = null_entity;
	entity	aquire = null_entity;
	vector	vec = vec3_origin;
	vector	oldang;
	float	len;
	float	oldlen = 0;

	// acquire new target
	while (( target = findradius (target, self.s.origin, 1024)) != null_entity)
	{
		if (self.owner == target)
			continue;
		if ((target.svflags & SVF_MONSTER) || !target.is_client)
			continue;
		if (target.health <= 0)
			continue;
		if (!visible (self, target))
			continue;
		
		// if we need to reduce the tracking cone
		/*
		{
			vec3_t	vec;
			float	dot;
			vec3_t	forward;
	
			AngleVectors (self.s.angles, forward, NULL, NULL);
			VectorSubtract (target.s.origin, self.s.origin, vec);
			VectorNormalize (vec);
			dot = DotProduct (vec, forward);
	
			if (dot > 0.6)
				continue;
		}
		*/

		if (!infront (self, target))
			continue;

		vec = self.s.origin - target.s.origin;
		len = VectorLength (vec);

		if (aquire == null_entity || len < oldlen)
		{
			aquire = target;
			self.target_ent = aquire;
			oldlen = len;
		}
	}

	if (aquire != null_entity)
	{
		oldang = self.s.angles;
		vec = aquire.s.origin - self.s.origin;
		
		self.s.angles = vectoangles (vec);
		
		VectorNormalize (vec);
		self.movedir = vec;
		self.velocity = vec * 500;
	}

	self.nextthink = level.framenum + 1;
}

void(entity self, vector start, vector dir, int damage, int speed, float damage_radius, int radius_damage) fire_heat =
{
	entity heat = fire_rocket(self, start, dir, damage, speed, damage_radius, radius_damage);
	
	heat.nextthink = level.framenum + 1;
	heat.think = heat_think;
}

static void(entity ent, entity other, cplane_t plane, csurface_t surf) plasma_touch =
{
	vector	origin;

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
	origin = ent.s.origin + (ent.velocity * -0.02);

	if (other.takedamage)
		T_Damage (other, ent, ent.owner, ent.velocity, ent.s.origin, plane.normal, ent.dmg, 0, 0, MOD_PHALANX);
	
	T_RadiusDamage(ent, ent.owner, ent.radius_dmg, other, ent.dmg_radius, MOD_PHALANX);

	gi.WriteByte (svc_temp_entity);
	gi.WriteByte (TE_PLASMA_EXPLOSION);
	gi.WritePosition (origin);
	gi.multicast (ent.s.origin, MULTICAST_PVS);
	
	G_FreeEdict (ent);
}

void(entity self, vector start, vector dir, int damage, int speed, float damage_radius, int radius_damage) fire_plasma =
{
	entity plasma;

	plasma = G_Spawn();
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

// from misc.qc
void(entity self) BecomeExplosion1;
// from xatrix/item.qc
API_FUNC void(entity self) SP_item_foodcube;

static void(entity ent) Trap_Think =
{
	entity	target = null_entity;
	entity	best = null_entity;
	vector	vec;
	float	len;
	int	i;
	float	oldlen = 8000;
	vector forward, right, up;
	
	if (ent.timestamp < level.framenum)
	{
		BecomeExplosion1(ent);
		// note to self
		// cause explosion damage???
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
				gi.sound(ent, CHAN_VOICE, gi.soundindex ("weapons/trapdown.wav"), 1, ATTN_IDLE, 0);

			ent.wait -= 2;
			ent.delay += level.time;

			for (i=0; i<3; i++)
			{
				best = G_Spawn();

				if (ent.enemy.classname == "monster_gekk")
				{
					best.s.modelindex = gi.modelindex ("models/objects/gekkgib/torso/tris.md2");	
					best.s.effects |= TE_GREENBLOOD;
				}
				else if (ent.mass > 200)
				{
					best.s.modelindex = gi.modelindex ("models/objects/gibs/chest/tris.md2");	
					best.s.effects |= TE_BLOOD;
				}
				else
				{
					best.s.modelindex = gi.modelindex ("models/objects/gibs/sm_meat/tris.md2");	
					best.s.effects |= TE_BLOOD;
				}

				AngleVectors (ent.s.angles, &forward, &right, &up);
				
				vec = RotatePointAroundVector(up, right, ((360.0/3)* i)+ent.delay);
				vec += vec * (ent.wait * 0.5f);
				vec += ent.s.origin;
				best.s.origin = vec + forward;
  
				best.s.origin[2] = ent.s.origin[2] + ent.wait;
				
				best.s.angles = ent.s.angles;
  
				best.solid = SOLID_NOT;
				best.s.effects |= EF_GIB;
				best.takedamage = DAMAGE_YES;
		
				best.movetype = MOVETYPE_TOSS;
				best.svflags |= SVF_MONSTER;
				best.deadflag = DEAD_DEAD;
		  
				best.mins = best.maxs = vec3_origin;

				best.watertype = gi.pointcontents(best.s.origin);
				if (best.watertype & MASK_WATER)
					best.waterlevel = 1;

				best.nextthink = level.framenum + 1;
				best.think = G_FreeEdict;
				gi.linkentity (best);
			}
				
			if (ent.wait < 19)
				ent.s.frame ++;

			return;
		}
		ent.s.frame ++;
		if (ent.s.frame == 8)
		{
			ent.nextthink = level.framenum + 1 * BASE_FRAMERATE;
			ent.think = G_FreeEdict;

			best = G_Spawn ();
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

	while ((target = findradius(target, ent.s.origin, 256)) != null_entity)
	{
		if (target == ent)
			continue;
		if (!(target.svflags & SVF_MONSTER) && !target.is_client)
			continue;
		// if (target == ent.owner)
		//	continue;
		if (target.health <= 0)
			continue;
		if (!visible (ent, target))
		 	continue;
		if (!best)
		{
			best = target;
			continue;
		}
		vec = ent.s.origin - target.s.origin;
		len = VectorLength (vec);
		if (len < oldlen)
		{
			oldlen = len;
			best = target;
		}
	}

	// pull the enemy in
	if (best)
	{
		vector	forward;

		if (best.groundentity != null_entity)
		{
			best.s.origin[2] += 1;
			best.groundentity = null_entity;
		}
		vec = ent.s.origin - best.s.origin;
		len = VectorLength (vec);
		if (best.is_client)
		{
			VectorNormalize (vec);
			best.velocity += vec * 250;
		}
		else
		{
			best.ideal_yaw = vectoyaw(vec);	
			M_ChangeYaw (best);
			AngleVectors (best.s.angles, &forward, 0, 0);
			best.velocity = forward * 256;
		}

		gi.sound(ent, CHAN_VOICE, gi.soundindex ("weapons/trapsuck.wav"), 1, ATTN_IDLE, 0);
		
		if (len < 32)
		{	
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
				// ok spawn the food cube
				ent.s.frame = 5;	
			}
			else
			{
				BecomeExplosion1(ent);
				// note to self
				// cause explosion damage???
				return;
			}
				
		}
	}

		
}


// RAFAEL
void(entity self, vector start, vector aimdir, int damage, int speed, float timer, float damage_radius, bool held) fire_trap =
{
	entity	trap;
	vector	dir;
	vector	forward, right, up;

	dir = vectoangles (aimdir);
	AngleVectors (dir, &forward, &right, &up);

	trap = G_Spawn();
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
	// RAFAEL 16-APR-98
	trap.s.sound = gi.soundindex ("weapons/traploop.wav");
	// END 16-APR-98
	if (held)
		trap.spawnflags = 3;
	else
		trap.spawnflags = 1;
	
	if (timer <= 0.0)
		Grenade_Explode (trap);
	else
	{
		// gi.sound (self, CHAN_WEAPON, gi.soundindex ("weapons/trapdown.wav"), 1, ATTN_NORM, 0);
		gi.linkentity (trap);
	}
	
	trap.timestamp = level.framenum + 30 * BASE_FRAMERATE;

}

#endif