#if defined(GROUND_ZERO) && defined(SINGLE_PLAYER)
// invisible turret drivers so we can have unmanned turrets.
// originally designed to shoot at func_trains and such, so they
// fire at the center of the bounding box, rather than the entity's
// origin.
static void(entity self) turret_brain_think =
{
	self.nextthink = level.framenum + 1;

	if (self.enemy)
	{
		if (!self.enemy.inuse)
			self.enemy = 0;
		else if (self.enemy.takedamage && self.enemy.health <= 0)
			self.enemy = 0;
	}

	vector endpos = vec3_origin;

	if (!self.enemy)
	{
		if (!FindTarget (self))
			return;

		self.monsterinfo.trail_framenum = level.framenum;
		self.monsterinfo.aiflags &= ~AI_LOST_SIGHT;
	}
	else
	{
		endpos = (self.enemy.absmax + self.enemy.absmin) * 0.5f;

		trace_t	trace;
		gi.traceline(&trace, self.target_ent.s.origin, endpos, self.target_ent, MASK_SHOT);

		if (trace.fraction == 1 || trace.ent == self.enemy)
		{
			if (self.monsterinfo.aiflags & AI_LOST_SIGHT)
			{
				self.monsterinfo.trail_framenum = level.framenum;
				self.monsterinfo.aiflags &= ~AI_LOST_SIGHT;
			}
		}
		else
		{
			self.monsterinfo.aiflags |= AI_LOST_SIGHT;
			return;
		}
	}

	// let the turret know where we want it to aim
	vector dir = endpos - self.target_ent.s.origin;
	self.target_ent.move_angles = vectoangles(dir);

	// decide if we should shoot
	if (level.framenum < self.monsterinfo.attack_finished)
		return;

	float reaction_time = self.delay;

	if (!reaction_time)
		reaction_time = (float)(3 - skill.intVal) * 1.0;

	if ((level.framenum - self.monsterinfo.trail_framenum) < (reaction_time * BASE_FRAMERATE))
		return;

	self.monsterinfo.attack_finished = level.framenum + (int)((reaction_time + 1.0) * BASE_FRAMERATE);
	//FIXME how do we really want to pass this along?
	self.target_ent.spawnflags |= 65536;
}

// =================
static void(entity self) turret_brain_link =
{
	if (self.killtarget)
		self.enemy = G_PickTarget (self.killtarget);

	self.think = turret_brain_think;
	self.nextthink = level.framenum + 1;

	self.target_ent = G_PickTarget (self.target);
	self.target_ent.owner = self;
	self.target_ent.teammaster.owner = self;
	self.s.angles = self.target_ent.s.angles;

	vector vec = [	self.target_ent.s.origin[0] - self.s.origin[0],
					self.target_ent.s.origin[1] - self.s.origin[1],
					0 ];
	self.move_origin[0] = VectorLength(vec);

	vec = self.s.origin - self.target_ent.s.origin;
	vec = vectoangles(vec);
	AnglesNormalize(vec);

	self.move_origin[1] = vec[1];
	self.move_origin[2] = self.s.origin[2] - self.target_ent.s.origin[2];

	// add the driver to the end of them team chain
	entity ent;
	for (ent = self.target_ent.teammaster; ent.teamchain; ent = ent.teamchain) ;

	ent.teamchain = self;
	self.teammaster = self.target_ent.teammaster;
	self.flags |= FL_TEAMSLAVE;
}

// =================
static void(entity self, entity other, entity cactivator) turret_brain_deactivate =
{
	self.think = 0;
	self.nextthink = 0;
}

// =================
static void(entity self, entity other, entity cactivator) turret_brain_activate =
{
	if (!self.enemy)
		self.enemy = cactivator;

	// wait at least 3 seconds to fire.
	self.monsterinfo.attack_finished = level.framenum + (3 * BASE_FRAMERATE);
	self.use = turret_brain_deactivate;

	self.think = turret_brain_link;
	self.nextthink = level.framenum + 1;
}

/*QUAKED turret_invisible_brain (1 .5 0) (-16 -16 -16) (16 16 16)
Invisible brain to drive the turret.

Does not search for targets. If targeted, can only be turned on once
and then off once. After that they are completely disabled.

"delay" the delay between firing (default ramps for skill level)
"Target" the turret breach
"Killtarget" the item you want it to attack.
Target the brain if you want it activated later, instead of immediately. It will wait 3 seconds
before firing to acquire the target.
*/
API_FUNC static void(entity self) SP_turret_invisible_brain =
{
	if (!self.killtarget)
	{
		gi.dprintf("turret_invisible_brain with no killtarget!\n");
		G_FreeEdict (self);
		return;
	}
	if (!self.target)
	{
		gi.dprintf("turret_invisible_brain with no target!\n");
		G_FreeEdict (self);
		return;
	}

	if (self.targetname)
		self.use = turret_brain_activate;
	else
	{
		self.think = turret_brain_link;
		self.nextthink = level.framenum + 1;
	}

	self.movetype = MOVETYPE_PUSH;
	gi.linkentity (self);
}

#endif