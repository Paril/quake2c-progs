#if defined(THE_RECKONING) && defined(SINGLE_PLAYER)

inline void(entity self, vector start, vector dir, int damage, int speed, int flashtype, int effect) monster_fire_blueblaster =
{
	fire_blaster (self, start, dir, damage, speed, effect, false);

	gi.WriteByte (svc_muzzleflash2);
	gi.WriteShort (self.s.number);
	gi.WriteByte (MZ_BLUEHYPERBLASTER);
	gi.multicast (start, MULTICAST_PVS);
}	

inline void(entity self, vector start, vector dir, int damage, int speed, int flashtype, int effect) monster_fire_ionripper =
{
	fire_ionripper (self, start, dir, damage, speed, effect);

	gi.WriteByte (svc_muzzleflash2);
	gi.WriteShort (self.s.number);
	gi.WriteByte (flashtype);
	gi.multicast (start, MULTICAST_PVS);
}

inline void(entity self, vector start, vector dir, int damage, int speed, int flashtype) monster_fire_heat =
{
	fire_heat (self, start, dir, damage, speed, damage, damage);

	gi.WriteByte (svc_muzzleflash2);
	gi.WriteShort (self.s.number);
	gi.WriteByte (flashtype);
	gi.multicast (start, MULTICAST_PVS);
}

void(entity self) dabeam_hit =
{
	int count = (self.spawnflags & 0x80000000) ? 8 : 4;
	entity ignore = self;
	vector start = self.s.origin;
	vector end = start + (self.movedir * 2048);
	trace_t	tr;
	
	do
	{
		gi.traceline(&tr, start, end, ignore, CONTENTS_SOLID|CONTENTS_MONSTER|CONTENTS_DEADMONSTER);

		if (!tr.ent)
			break;

		// hurt it if we can
		if ((tr.ent.takedamage) && !(tr.ent.flags & FL_IMMUNE_LASER) && (tr.ent != self.owner))
			T_Damage (tr.ent, self, self.owner, self.movedir, tr.endpos, vec3_origin, self.dmg, skill.intVal, DAMAGE_ENERGY, MOD_TARGET_LASER);

		if (self.dmg < 0) // healer ray
			// when player is at 100 health
			// just undo health fix
			// keeping fx
			if (tr.ent.is_client && tr.ent.health > 100)
				tr.ent.health += self.dmg; 
		
		// if we hit something that's not a monster or player or is immune to lasers, we're done
		if (!(tr.ent.svflags & SVF_MONSTER) && (!tr.ent.is_client))
		{
			if (self.spawnflags & 0x80000000)
			{
				self.spawnflags &= ~0x80000000;
				gi.WriteByte (svc_temp_entity);
				gi.WriteByte (TE_LASER_SPARKS);
				gi.WriteByte (10);
				gi.WritePosition (tr.endpos);
				gi.WriteDir (tr.normal);
				gi.WriteByte (self.s.skinnum);
				gi.multicast (tr.endpos, MULTICAST_PVS);
			}
			break;
		}

		ignore = tr.ent;
		start = tr.endpos;
	} while (1);

	self.s.old_origin = tr.endpos;
	self.nextthink = level.framenum + 1;
	self.think = G_FreeEdict;
  
}

// RAFAEL
void(entity self) monster_dabeam =
{
	self.movetype = MOVETYPE_NONE;
	self.solid = SOLID_NOT;
	self.s.renderfx |= RF_BEAM|RF_TRANSLUCENT;
	self.s.modelindex = 1;
		
	self.s.frame = 2;
	
	if (self.owner.monsterinfo.aiflags & AI_MEDIC)
		self.s.skinnum = 0xf3f3f1f1;
	else
		self.s.skinnum = 0xf2f2f0f0;

	if (self.enemy)
	{
		vector last_movedir = self.movedir;
		vector point = self.enemy.absmin + (self.enemy.size * 0.5);

		if (self.owner.monsterinfo.aiflags & AI_MEDIC)
			point[0] += sin(level.time) * 8;

		self.movedir = point - self.s.origin;
		VectorNormalize (self.movedir);

		if (self.movedir != last_movedir)
			self.spawnflags |= 0x80000000;
	}
	else
		G_SetMovedir (self.s.angles, self.movedir);

	self.think = dabeam_hit;
	self.nextthink = level.framenum + 1;
	self.mins = '-8 -8 -8';
	self.maxs = '8 8 8';
	gi.linkentity (self);
 
	self.spawnflags |= 0x80000001;
	self.svflags &= ~SVF_NOCLIENT;
}

#endif