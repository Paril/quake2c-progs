#ifdef GROUND_ZERO

//==========================================================

/*QUAKED target_steam (1 0 0) (-8 -8 -8) (8 8 8)
Creates a steam effect (particles w/ velocity in a line).

  speed = velocity of particles (default 50)
  count = number of particles (default 32)
  sounds = color of particles (default 8 for steam)
     the color range is from this color to this color + 6
  wait = seconds to run before stopping (overrides default
     value derived from func_timer)

  best way to use this is to tie it to a func_timer that "pokes"
  it every second (or however long you set the wait time, above)

  note that the width of the base is proportional to the speed
  good colors to use:
  6-9 - varying whites (darker to brighter)
  224 - sparks
  176 - blue water
  80  - brown water
  208 - slime
  232 - blood
*/

static void(entity self, entity other, entity cactivator) use_target_steam =
{
	static int	nextid;
	vector		point;

	if (nextid > 20000)
		nextid = nextid %20000;

	nextid++;
	
	// automagically set wait from func_timer unless they set it already, or
	// default to 1000 if not called by a func_timer (eek!)
	if (!self.wait)
		if (other)
			self.wait = other.wait * 1000;
		else
			self.wait = 1000f;

	if (self.enemy)
	{
		point = self.enemy.absmin + (self.enemy.size * 0.5);
		self.movedir = point - self.s.origin;
		VectorNormalize (self.movedir);
	}

	point = self.s.origin + (self.movedir * self.plat2flags * 0.5);
	if (self.wait > 100)
	{
		gi.WriteByte (svc_temp_entity);
		gi.WriteByte (TE_STEAM);
		gi.WriteShort (nextid);
		gi.WriteByte (self.count);
		gi.WritePosition (self.s.origin);
		gi.WriteDir (self.movedir);
		gi.WriteByte (self.sounds&0xff);
		gi.WriteShort ( (int)(self.plat2flags) );
		gi.WriteLong ( (int)(self.wait) );
		gi.multicast (self.s.origin, MULTICAST_PVS);
	}
	else
	{
		gi.WriteByte (svc_temp_entity);
		gi.WriteByte (TE_STEAM);
		gi.WriteShort ((int)-1);
		gi.WriteByte (self.count);
		gi.WritePosition (self.s.origin);
		gi.WriteDir (self.movedir);
		gi.WriteByte (self.sounds&0xff);
		gi.WriteShort ( (int)(self.plat2flags) );
		gi.multicast (self.s.origin, MULTICAST_PVS);
	}
}

static void(entity self) target_steam_start =
{
	entity ent;

	self.use = use_target_steam;

	if (self.target)
	{
		ent = G_Find (null_entity, targetname, self.target);
		if (ent == null_entity)
			gi.dprintf ("%s at %s: %s is a bad target\n", self.classname, vtos(self.s.origin), self.target);
		self.enemy = ent;
	}
	else
	{
		G_SetMovedir (self.s.angles, self.movedir);
	}

	if (!self.count)
		self.count = 32;
	if (!self.plat2flags)
		self.plat2flags = 75;
	if (!self.sounds)
		self.sounds = 8;
	if (self.wait)
		self.wait *= 1000;  // we want it in milliseconds, not seconds

	// paranoia is good
	self.sounds &= 0xff;
	self.count &= 0xff;

	self.svflags = SVF_NOCLIENT;

	gi.linkentity (self);
}

static void(entity self) SP_target_steam =
{
	self.plat2flags = (int)self.speed;

	if (self.target)
	{
		self.think = target_steam_start;
		self.nextthink = level.framenum + (1 * BASE_FRAMERATE);
	}
	else
		target_steam_start (self);
}


//==========================================================
// target_anger
//==========================================================

static void(entity self, entity other, entity cactivator) target_anger_use =
{
	entity	ctarget;
	entity	t;

	t = null_entity;
	ctarget = G_Find (t, targetname, self.killtarget);

	if (ctarget != null_entity && self.target)
	{
		// Make whatever a "good guy" so the monster will try to kill it!
		ctarget.monsterinfo.aiflags |= AI_GOOD_GUY;
		ctarget.svflags |= SVF_MONSTER;
		ctarget.health = 300;

		t = null_entity;
		while ((t = G_Find (t, targetname, self.target)) != null_entity)
		{
			if (t == self)
			{
				gi.dprintf ("WARNING: entity used itself.\n");
			}
			else
			{
				if (t.use)
				{
					if (t.health < 0)
						return;

					t.enemy = ctarget;
					t.monsterinfo.aiflags |= AI_TARGET_ANGER;
					FoundTarget (t);
				}
			}
			if (!self.inuse)
			{
				gi.dprintf("entity was removed while using targets\n");
				return;
			}
		}
	}

}

/*QUAKED target_anger (1 0 0) (-8 -8 -8) (8 8 8)
This trigger will cause an entity to be angry at another entity when a player touches it. Target the
entity you want to anger, and killtarget the entity you want it to be angry at.

target - entity to piss off
killtarget - entity to be pissed off at
*/
API_FUNC static void(entity self) SP_target_anger =
{	
	if (!self.target)
	{
		gi.dprintf("target_anger without target!\n");
		G_FreeEdict (self);
		return;
	}
	if (!self.killtarget)
	{
		gi.dprintf("target_anger without killtarget!\n");
		G_FreeEdict (self);
		return;
	}

	self.use = target_anger_use;
	self.svflags = SVF_NOCLIENT;
}

// ***********************************
// target_killplayers
// ***********************************

static void(entity self, entity other, entity cactivator) target_killplayers_use =
{
	int	i;
	entity	ent, player;

	// kill the players
	for (i=0 ; i<game.maxclients ; i++)
	{
		player = itoe(1 + i);
		if (!player.inuse)
			continue;

		// nail it
		T_Damage (player, self, self, vec3_origin, self.s.origin, vec3_origin, 100000, 0, DAMAGE_NO_PROTECTION, MOD_TELEFRAG);
	}

	// kill any visible monsters
	for (i = 0; i < globals.num_edicts; i++)
	{
		ent = itoe(i);
		if (!ent.inuse)
			continue;
		if (ent.health < 1)
			continue;
		if (!ent.takedamage)
			continue;
		
		for (int j = 0; j < game.maxclients; j++)
		{
			player = itoe(j + 1);
			if(!player.inuse)
				continue;
			
			if(visible(player, ent))
			{
				T_Damage (ent, self, self, vec3_origin, ent.s.origin, vec3_origin, 
							ent.health, 0, DAMAGE_NO_PROTECTION, MOD_TELEFRAG);
				break;
			}
		}
	}

}

/*QUAKED target_killplayers (1 0 0) (-8 -8 -8) (8 8 8)
When triggered, this will kill all the players on the map.
*/
API_FUNC static void(entity self) SP_target_killplayers =
{
	self.use = target_killplayers_use;
	self.svflags = SVF_NOCLIENT;
}

/*QUAKED target_blacklight (1 0 1) (-16 -16 -24) (16 16 24) 
Pulsing black light with sphere in the center
*/
static void(entity self) blacklight_think =
{
	self.s.angles = randomv('360 360 360');
	self.nextthink = level.framenum + 1;
}

API_FUNC static void(entity ent) SP_target_blacklight =
{
	if (deathmatch.intVal)
	{	// auto-remove for deathmatch
		G_FreeEdict (ent);
		return;
	}

	ent.s.effects |= (EF_TRACKERTRAIL|EF_TRACKER);
	ent.think = blacklight_think;
	ent.s.modelindex = gi.modelindex ("models/items/spawngro2/tris.md2");
	ent.s.frame = 1;
	ent.nextthink = level.framenum + 1;
	gi.linkentity (ent);
}

/*QUAKED target_orb (1 0 1) (-16 -16 -24) (16 16 24) 
Translucent pulsing orb with speckles
*/
static void(entity self) orb_think =
{
	self.s.angles = randomv('360 360 360');
	self.nextthink = level.framenum + 1;
}

API_FUNC static void(entity ent) SP_target_orb =
{
	if (deathmatch.intVal)
	{	// auto-remove for deathmatch
		G_FreeEdict (ent);
		return;
	}

	ent.think = orb_think;
	ent.nextthink = level.framenum + 1;
	ent.s.modelindex = gi.modelindex ("models/items/spawngro2/tris.md2");
	ent.s.frame = 2;
	ent.s.effects |= EF_SPHERETRANS;
	gi.linkentity (ent);
}

#endif