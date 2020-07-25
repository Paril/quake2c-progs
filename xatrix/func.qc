#ifdef THE_RECKONING

/*QUAKED rotating_light (0 .5 .8) (-8 -8 -8) (8 8 8) START_OFF ALARM
"health"	if set, the light may be killed.
*/

// RAFAEL 
// note to self
// the lights will take damage from explosions
// this could leave a player in total darkness very bad
 
const int START_OFF	= 1;

static void(entity self) rotating_light_alarm =
{
	if (self.spawnflags & START_OFF)
	{
		self.think = 0;
		self.nextthink = 0;	
	}
	else
	{
		gi.sound (self, CHAN_NO_PHS_ADD+CHAN_VOICE, self.moveinfo.sound_start, 1, ATTN_STATIC, 0);
		self.nextthink = level.framenum + (1 * BASE_FRAMERATE);
	}
}

static void(entity self, entity inflictor, entity attacker, int damage, vector point) rotating_light_killed =
{
	gi.WriteByte (svc_temp_entity);
	gi.WriteByte (TE_WELDING_SPARKS);
	gi.WriteByte (30);
	gi.WritePosition (self.s.origin);
	gi.WriteDir (vec3_origin);
	gi.WriteByte (0xe0 + (Q_rand()&7));
	gi.multicast (self.s.origin, MULTICAST_PVS);

	self.s.effects &= ~EF_SPINNINGLIGHTS;
	self.use = 0;

	self.think = G_FreeEdict;	
	self.nextthink = level.framenum + 1;
}

static void(entity self, entity other, entity cactivator) rotating_light_use =
{
	if (self.spawnflags & START_OFF)
	{
		self.spawnflags &= ~START_OFF;
		self.s.effects |= EF_SPINNINGLIGHTS;

		if (self.spawnflags & 2)
		{
			self.think = rotating_light_alarm;
			self.nextthink = level.framenum + 1;
		}
	}
	else
	{
		self.spawnflags |= START_OFF;
		self.s.effects &= ~EF_SPINNINGLIGHTS;
	}
}

API_FUNC static void(entity self) SP_rotating_light =
{
	self.movetype = MOVETYPE_STOP;
	self.solid = SOLID_BBOX;
	
	self.s.modelindex = gi.modelindex ("models/objects/light/tris.md2");
	
	self.s.frame = 0;
		
	self.use = rotating_light_use;
	
	if (self.spawnflags & START_OFF)
		self.s.effects &= ~EF_SPINNINGLIGHTS;
	else
		self.s.effects |= EF_SPINNINGLIGHTS;

	if (!self.speed)
		self.speed = 32f;
	// this is a real cheap way
	// to set the radius of the light
	// self.s.frame = self.speed;

	if (!self.health)
	{
		self.health = 10;
		self.max_health = self.health;
		self.die = rotating_light_killed;
		self.takedamage = DAMAGE_YES;
	}
	else
	{
		self.max_health = self.health;
		self.die = rotating_light_killed;
		self.takedamage = DAMAGE_YES;
	}
	
	if (self.spawnflags & 2)
	{
		self.moveinfo.sound_start = gi.soundindex ("misc/alarm.wav");	
	}
	
	gi.linkentity (self);
}


/*QUAKED func_object_repair (1 .5 0) (-8 -8 -8) (8 8 8) 
object to be repaired.
The default delay is 1 second
"delay" the delay in seconds for spark to occur
*/

static void(entity ent) object_repair_fx =
{
	ent.nextthink = level.framenum + (int)(ent.delay * BASE_FRAMERATE);

	if (ent.health <= 100)
		ent.health++;
 	else
	{
		gi.WriteByte (svc_temp_entity);
		gi.WriteByte (TE_WELDING_SPARKS);
		gi.WriteByte (10);
		gi.WritePosition (ent.s.origin);
		gi.WriteDir (vec3_origin);
		gi.WriteByte (0xe0 + (Q_rand()&7));
		gi.multicast (ent.s.origin, MULTICAST_PVS);
	}
	
}

static void(entity ent) object_repair_dead =
{
	G_UseTargets (ent, ent);
	ent.nextthink = level.framenum + 1;
	ent.think = object_repair_fx;
}

static void(entity ent) object_repair_sparks =
{
	if (ent.health < 0)
	{
		ent.nextthink = level.framenum + 1;
		ent.think = object_repair_dead;
		return;
	}

	ent.nextthink = level.framenum + (int)(ent.delay * BASE_FRAMERATE);
	
	gi.WriteByte (svc_temp_entity);
	gi.WriteByte (TE_WELDING_SPARKS);
	gi.WriteByte (10);
	gi.WritePosition (ent.s.origin);
	gi.WriteDir (vec3_origin);
	gi.WriteByte (0xe0 + (Q_rand()&7));
	gi.multicast (ent.s.origin, MULTICAST_PVS);
	
}

API_FUNC static void(entity ent) SP_object_repair =
{
	ent.movetype = MOVETYPE_NONE;
	ent.solid = SOLID_BBOX;
	ent.classname = "object_repair";
	ent.mins = '-8 -8 8';
	ent.maxs = '8 8 8';
	ent.think = object_repair_sparks;
	ent.nextthink = level.framenum + (1 * BASE_FRAMERATE);
	ent.health = 100;

	if (!ent.delay)
		ent.delay = 1.0f;
}

#endif