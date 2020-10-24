/*
============
CanDamage

Returns true if the inflictor can directly damage the target.  Used for
explosions and melee attacks.
============
*/
bool(entity targ, entity inflictor) CanDamage =
{
// bmodels need special checking because their origin is 0,0,0
	if (targ.movetype == MOVETYPE_PUSH)
	{
		vector dest = (targ.absmin + targ.absmax) * 0.5f;
		trace_t trace;
		gi.traceline(&trace, inflictor.s.origin, dest, inflictor, MASK_SOLID);

		if (trace.fraction == 1.0f)
			return true;
		if (trace.ent == targ)
			return true;

		return false;
	}

	trace_t trace;
	gi.traceline(&trace, inflictor.s.origin, targ.s.origin, inflictor, MASK_SOLID);
	if (trace.fraction == 1.0f)
		return true;

	vector dest = targ.s.origin;
	dest.x += 15.0f;
	dest.y += 15.0f;
	gi.traceline(&trace, inflictor.s.origin, dest, inflictor, MASK_SOLID);
	if (trace.fraction == 1.0f)
		return true;

	dest = targ.s.origin;
	dest.x += 15.0f;
	dest.y -= 15.0f;
	gi.traceline(&trace, inflictor.s.origin, dest, inflictor, MASK_SOLID);
	if (trace.fraction == 1.0f)
		return true;

	dest = targ.s.origin;
	dest.x -= 15.0f;
	dest.y += 15.0f;
	gi.traceline(&trace, inflictor.s.origin, dest, inflictor, MASK_SOLID);
	if (trace.fraction == 1.0f)
		return true;

	dest = targ.s.origin;
	dest.x -= 15.0f;
	dest.y -= 15.0f;
	gi.traceline(&trace, inflictor.s.origin, dest, inflictor, MASK_SOLID);
	if (trace.fraction == 1.0f)
		return true;

	return false;
}
#ifdef SINGLE_PLAYER

// from monster.qc
void(entity) monster_death_use;
#endif

/*
============
Killed
============
*/
static void(entity targ, entity inflictor, entity attacker, int damage, vector point) Killed =
{
	if (targ.health < -999)
		targ.health = -999;

#if defined(GROUND_ZERO) && defined(SINGLE_PLAYER)
	if (targ.monsterinfo.aiflags & AI_MEDIC)
	{
		if (targ.enemy)  // god, I hope so
			cleanupHealTarget (targ.enemy);

		// clean up self
		targ.monsterinfo.aiflags &= ~AI_MEDIC;
		targ.enemy = attacker;
	}
	else
#endif
		targ.enemy = attacker;

#ifdef SINGLE_PLAYER
	if ((targ.svflags & SVF_MONSTER) && (targ.deadflag != DEAD_DEAD))
	{
#ifdef GROUND_ZERO
		//ROGUE - free up slot for spawned monster if it's spawned
		if (targ.monsterinfo.aiflags & AI_SPAWNED_CARRIER)
		{
			if (targ.monsterinfo.commander && targ.monsterinfo.commander.inuse && targ.monsterinfo.commander.classname == "monster_carrier")
				targ.monsterinfo.commander.monsterinfo.monster_slots++;
		}
		if (targ.monsterinfo.aiflags & AI_SPAWNED_MEDIC_C)
		{
			if (targ.monsterinfo.commander && targ.monsterinfo.commander.inuse && targ.monsterinfo.commander.classname == "monster_medic_commander")
				targ.monsterinfo.commander.monsterinfo.monster_slots++;
		}
		if (targ.monsterinfo.aiflags & AI_SPAWNED_WIDOW)
		{
			// need to check this because we can have variable numbers of coop players
			if (targ.monsterinfo.commander && targ.monsterinfo.commander.inuse && !strncmp(targ.monsterinfo.commander.classname, "monster_widow", 13))
			{
				if (targ.monsterinfo.commander.monsterinfo.monster_used > 0)
					targ.monsterinfo.commander.monsterinfo.monster_used--;
			}
		}
#endif
		
		if (!(targ.monsterinfo.aiflags & AI_GOOD_GUY_MASK))
		{
			level.killed_monsters++;

			if (coop.intVal && attacker.is_client)
				attacker.client.resp.score++;

#ifndef GROUND_ZERO
			// medics won't heal monsters that they kill themselves
			if (attacker.classname == "monster_medic")
				targ.owner = attacker;
#endif
		}
	}
#endif

	// doors, triggers, etc
	if (targ.movetype == MOVETYPE_PUSH || targ.movetype == MOVETYPE_STOP || targ.movetype == MOVETYPE_NONE)
	{
		targ.die(targ, inflictor, attacker, damage, point);
		return;
	}

#ifdef SINGLE_PLAYER
	if ((targ.svflags & SVF_MONSTER) && (targ.deadflag != DEAD_DEAD))
	{
		targ.touch = 0;
		monster_death_use(targ);
	}
#endif

	targ.die(targ, inflictor, attacker, damage, point);
}


/*
================
SpawnDamage
================
*/
static inline void(int type, vector origin, vector normal) SpawnDamage =
{
	gi.WriteByte(svc_temp_entity);
	gi.WriteByte(type);
	gi.WritePosition(origin);
	gi.WriteDir(normal);
	gi.multicast(origin, MULTICAST_PVS);
}

/*
============
T_Damage

targ        entity that is being damaged
inflictor   entity that is causing the damage
attacker    entity that caused the inflictor to damage targ
	example: targ=monster, inflictor=rocket, attacker=player

dir         direction of the attack
point       point at which the damage is being inflicted
normal      normal vector from that point
damage      amount of damage being inflicted
knockback   force to be applied against targ as a result of the damage

dflags      these flags are used to control how T_Damage works
	DAMAGE_RADIUS           damage was indirect (from a nearby explosion)
	DAMAGE_NO_ARMOR         armor does not protect from this damage
	DAMAGE_ENERGY           damage is from an energy based weapon
	DAMAGE_NO_KNOCKBACK     do not affect velocity, just view angles
	DAMAGE_BULLET           damage is from a bullet (used for ricochets)
	DAMAGE_NO_PROTECTION    kills godmode, armor, everything
============
*/
static int(entity ent, vector point, vector normal, int damage, damage_flags_t dflags) CheckPowerArmor =
{
	int	save;
	power_armor_type_t	power_armor_type;
	int	index;
	int	damagePerCell;
	int	pa_te_type;
	int	power = 0;
	int	power_used;

	if (!damage)
		return 0;

	if (dflags & (DAMAGE_NO_ARMOR
#ifdef GROUND_ZERO
		| DAMAGE_NO_POWER_ARMOR
#endif
		))
		return 0;

	index = 0;  // shut up qcc

	if (ent.is_client)
	{
		power_armor_type = PowerArmorType(ent);
		if (power_armor_type != POWER_ARMOR_NONE)
		{
			index = FindItem("Cells")->id;
			power = ent.client.pers.inventory[index];
		}
	}
#ifdef SINGLE_PLAYER
	else if (ent.svflags & SVF_MONSTER)
	{
		power_armor_type = ent.monsterinfo.power_armor_type;
		power = ent.monsterinfo.power_armor_power;
	}
#endif
	else
		return 0;

	if (!power || power_armor_type == POWER_ARMOR_NONE)
		return 0;

	if (power_armor_type == POWER_ARMOR_SCREEN)
	{
		vector	vec;
		float	dot;
		vector	forward;

		// only works if damage point is in front
		AngleVectors(ent.s.angles, &forward, 0, 0);
		vec = point - ent.s.origin;
		VectorNormalize(vec);
		dot = vec * forward;
		if (dot <= 0.3f)
			return 0;

		damagePerCell = 1;
		pa_te_type = TE_SCREEN_SPARKS;
		damage = damage / 3;
	}
	else
	{
		damagePerCell = 2;
		pa_te_type = TE_SHIELD_SPARKS;
		damage = (2 * damage) / 3;
	}

#ifdef GROUND_ZERO
	if (dflags & DAMAGE_NO_REG_ARMOR)
		save = (power * damagePerCell) / 2;
	else
#endif
		save = power * damagePerCell;

	if (!save)
		return 0;
	if (save > damage)
		save = damage;

	SpawnDamage(pa_te_type, point, normal);
	ent.powerarmor_framenum = (int)(level.framenum + 0.2f * BASE_FRAMERATE);

#ifdef GROUND_ZERO
	if (dflags & DAMAGE_NO_REG_ARMOR)
		power_used = (save / damagePerCell) * 2;
	else
#endif
		power_used = save / damagePerCell;

#ifdef SINGLE_PLAYER
	if (ent.is_client)
#endif
		ent.client.pers.inventory[index] -= power_used;
#ifdef SINGLE_PLAYER
	else
		ent.monsterinfo.power_armor_power -= power_used;
#endif
	return save;
}

static int(entity ent, vector point, vector normal, int damage, int te_sparks, damage_flags_t dflags) CheckArmor =
{
	if (!damage)
		return 0;

	if (!ent.is_client)
		return 0;

	if (dflags & (DAMAGE_NO_ARMOR
#ifdef GROUND_ZERO
		| DAMAGE_NO_REG_ARMOR
#endif
		))
		return 0;

	gitem_id_t index = ArmorIndex(ent);
	if (!index)
		return 0;

	gitem_t *armor = GetItemByIndex(index);
	
	int save;

	if (dflags & DAMAGE_ENERGY)
		save = (int)ceil((armor->info)->energy_protection * damage);
	else
		save = (int)ceil((armor->info)->normal_protection * damage);

	if (save >= ent.client.pers.inventory[index])
		save = ent.client.pers.inventory[index];

	if (!save)
		return 0;

	ent.client.pers.inventory[index] -= save;
	SpawnDamage(te_sparks, point, normal);

	return save;
}

#ifdef SINGLE_PLAYER
void(entity self) FoundTarget;

#ifdef GROUND_ZERO
bool(entity self, entity tesla) MarkTeslaArea;
void(entity self, entity tesla) TargetTesla;

static void(entity targ, entity attacker, entity inflictor) M_ReactToDamage =
#else
static void(entity targ, entity attacker) M_ReactToDamage =
#endif
{
	if (!(attacker.is_client) && !(attacker.svflags & SVF_MONSTER))
		return;
		
#ifdef GROUND_ZERO
	// logic for tesla - if you are hit by a tesla, and can't see who you should be mad at (attacker)
	// attack the tesla
	// also, target the tesla if it's a "new" tesla
	if (inflictor && inflictor.classname == "tesla")
	{
		bool new_tesla = MarkTeslaArea(targ, inflictor);
		if (new_tesla)
			TargetTesla (targ, inflictor);
		return;
	}
#endif

	if (attacker == targ || attacker == targ.enemy)
		return;

	// if we are a good guy monster and our attacker is a player
	// or another good guy, do not get mad at them
	if (targ.monsterinfo.aiflags & AI_GOOD_GUY)
	{
		if (attacker.is_client || (attacker.monsterinfo.aiflags & AI_GOOD_GUY))
			return;
	}

#ifdef GROUND_ZERO
	// if we're currently mad at something a target_anger made us mad at, ignore
	// damage
	if (targ.enemy && (targ.monsterinfo.aiflags & AI_TARGET_ANGER))
	{
		float	percentHealth;

		// make sure whatever we were pissed at is still around.
		if(targ.enemy.inuse)
		{
			percentHealth = (float)(targ.health) / (float)(targ.max_health);
			if( targ.enemy.inuse && percentHealth > 0.33)
				return;
		}

		// remove the target anger flag
		targ.monsterinfo.aiflags &= ~AI_TARGET_ANGER;
	}

// if we're healing someone, do like above and try to stay with them
	if (targ.enemy && (targ.monsterinfo.aiflags & AI_MEDIC))
	{
		float	percentHealth;

		percentHealth = (float)(targ.health) / (float)(targ.max_health);
		// ignore it some of the time
		if( targ.enemy.inuse && percentHealth > 0.25)
			return;

		// remove the medic flag
		targ.monsterinfo.aiflags &= ~AI_MEDIC;
		cleanupHealTarget (targ.enemy);
	}
#endif

	// we now know that we are not both good guys

	// if attacker is a client, get mad at them because he's good and we're not
	if (attacker.is_client) {
		targ.monsterinfo.aiflags &= ~AI_SOUND_TARGET;

		// this can only happen in coop (both new and old enemies are clients)
		// only switch if can't see the current enemy
		if (targ.enemy && targ.enemy.is_client) {
			if (visible(targ, targ.enemy)) {
				targ.oldenemy = attacker;
				return;
			}
			targ.oldenemy = targ.enemy;
		}
		targ.enemy = attacker;
		if (!(targ.monsterinfo.aiflags & AI_DUCKED))
			FoundTarget(targ);
		return;
	}

	// it's the same base (walk/swim/fly) type and a different classname and it's not a tank
	// (they spray too much), get mad at them
#ifdef GROUND_ZERO
	if (((targ.flags & (FL_FLY|FL_SWIM)) == (attacker.flags & (FL_FLY|FL_SWIM))) &&
		(targ.classname != attacker.classname) &&
		!(attacker.monsterinfo.aiflags & AI_IGNORE_SHOTS) &&
		!(targ.monsterinfo.aiflags & AI_IGNORE_SHOTS))
#else
	if (((targ.flags & (FL_FLY | FL_SWIM)) == (attacker.flags & (FL_FLY | FL_SWIM))) &&
		(targ.classname != attacker.classname) &&
		(attacker.classname != "monster_tank") &&
		(attacker.classname != "monster_supertank") &&
		(attacker.classname != "monster_makron") &&
		(attacker.classname != "monster_jorg"))
#endif
	{
		if (targ.enemy && targ.enemy.is_client)
			targ.oldenemy = targ.enemy;
		targ.enemy = attacker;
		if (!(targ.monsterinfo.aiflags & AI_DUCKED))
			FoundTarget(targ);
	}
	// if they *meant* to shoot us, then shoot back
	else if (attacker.enemy == targ) {
		if (targ.enemy && targ.enemy.is_client)
			targ.oldenemy = targ.enemy;
		targ.enemy = attacker;
		if (!(targ.monsterinfo.aiflags & AI_DUCKED))
			FoundTarget(targ);
	}
	// otherwise get mad at whoever they are mad at (help our buddy) unless it is us!
	else if (attacker.enemy && attacker.enemy != targ) {
		if (targ.enemy && targ.enemy.is_client)
			targ.oldenemy = targ.enemy;
		targ.enemy = attacker.enemy;
		if (!(targ.monsterinfo.aiflags & AI_DUCKED))
			FoundTarget(targ);
	}
}
#endif

bool(entity targ, entity attacker, int mod = 0) CheckTeamDamage =
{
	return ((dmflags.intVal & DF_NO_FRIENDLY_FIRE)
#ifdef GROUND_ZERO
			&& (mod != MOD_NUKE)
#endif
			);
};

void(entity targ, entity inflictor, entity attacker, vector dir, vector point, vector normal, int damage, int knockback, damage_flags_t dflags, means_of_death_t mod) T_Damage =
{
	int         take;
	int         save;
	int         asave;
	int         psave;
	int         te_sparks;

	if (!targ.takedamage)
		return;
#ifdef SINGLE_PLAYER

	// easy mode takes half damage
	if (!skill.intVal && !deathmatch.intVal && targ.is_client)
	{
		damage = (int)(damage * 0.5f);
		if (!damage)
			damage = 1;
	}
#endif

	// friendly fire avoidance
	// if enabled you can't hurt teammates (but you can hurt yourself)
	// knockback still occurs
	if (OnSameTeam(targ, attacker))
	{
		if (CheckTeamDamage(targ, attacker, mod))
			damage = 0;
		else
			mod |= MOD_FRIENDLY_FIRE;
	}
	meansOfDeath = mod;

	if (dflags & DAMAGE_BULLET)
		te_sparks = TE_BULLET_SPARKS;
	else
		te_sparks = TE_SPARKS;

	VectorNormalize(dir);

// bonus damage for suprising a monster
	if (!(dflags & DAMAGE_RADIUS) && (targ.svflags & SVF_MONSTER) && (attacker.is_client) && (!targ.enemy) && (targ.health > 0))
		damage *= 2;

	if (targ.flags & FL_NO_KNOCKBACK)
		knockback = 0;
// figure momentum add
	else if (knockback && !(dflags & DAMAGE_NO_KNOCKBACK))
	{
		if ((targ.movetype != MOVETYPE_NONE) && (targ.movetype != MOVETYPE_BOUNCE) && (targ.movetype != MOVETYPE_PUSH) && (targ.movetype != MOVETYPE_STOP))
		{
			vector	kvel;
			float	calc_mass;

			if (targ.mass < 50)
				calc_mass = 50f;
			else
				calc_mass = (float)targ.mass;

			if (targ.is_client && attacker == targ)
				kvel = dir * (1600.0f * (float)knockback / calc_mass);  // the rocket jump hack...
			else
				kvel = dir * (500.0f * (float)knockback / calc_mass);

			targ.velocity += kvel;
		}
	}

	take = damage;
	save = 0;

	// check for godmode
	if ((targ.flags & FL_GODMODE) && !(dflags & DAMAGE_NO_PROTECTION))
	{
		take = 0;
		save = damage;
		SpawnDamage(te_sparks, point, normal);
	}

	// check for invincibility
	if (((targ.is_client && targ.client.invincible_framenum > level.framenum) && !(dflags & DAMAGE_NO_PROTECTION))
#if defined(GROUND_ZERO) && defined(SINGLE_PLAYER)
		|| (((targ.svflags & SVF_MONSTER) && targ.monsterinfo.invincible_framenum > level.framenum ) && !(dflags & DAMAGE_NO_PROTECTION))
#endif
		)
	{
		if (targ.pain_debounce_framenum < level.framenum)
		{
			gi.sound(targ, CHAN_ITEM, gi.soundindex("items/protect4.wav"), 1, ATTN_NORM, 0);
			targ.pain_debounce_framenum = level.framenum + 2 * BASE_FRAMERATE;
		}
		take = 0;
		save = damage;
	}

#ifdef CTF
	//team armor protect
	if (ctf.intVal && targ.is_client && attacker.is_client &&
		OnSameTeam(targ, attacker) && (dmflags.intVal & DF_ARMOR_PROTECT))
		psave = asave = 0;
	else
	{
#endif
		psave = CheckPowerArmor(targ, point, normal, take, dflags);
		take -= psave;

		asave = CheckArmor(targ, point, normal, take, te_sparks, dflags);
		take -= asave;
#ifdef CTF
	}
#endif

	//treat cheat/powerup savings the same as armor
	asave += save;

#ifdef GROUND_ZERO
	// this option will do damage both to the armor and person. originally for DPU rounds
	if (dflags & DAMAGE_DESTROY_ARMOR)
	{
		if (!(targ.flags & FL_GODMODE) && !(dflags & DAMAGE_NO_PROTECTION) &&
		   !(is_client && targ.client.invincible_framenum > level.framenum))
			take = damage;
	}
#endif

#ifdef CTF
	take = CTFApplyResistance(targ, take);

	CTFCheckHurtCarrier(targ, attacker);
#endif

// do the damage
	if (take)
	{
		if ((targ.svflags & SVF_MONSTER) || (targ.is_client))
		{
#if defined(THE_RECKONING) && defined(SINGLE_PLAYER)
			if (targ.classname == "monster_gekk")
				SpawnDamage (TE_GREENBLOOD, point, normal);
			else
#endif
#ifdef GROUND_ZERO
			if (targ.flags & FL_MECHANICAL)
				SpawnDamage ( TE_ELECTRIC_SPARKS, point, normal);
			else if (mod == MOD_CHAINFIST)
				SpawnDamage (TE_MOREBLOOD, point, normal);
			else
#endif
				SpawnDamage(TE_BLOOD, point, normal);
		}
		else
			SpawnDamage(te_sparks, point, normal);

		targ.health = targ.health - take;

		if (targ.health <= 0)
		{
			if ((targ.svflags & SVF_MONSTER) || targ.is_client)
				targ.flags |= FL_NO_KNOCKBACK;
			Killed(targ, inflictor, attacker, take, point);
			return;
		}
	}

#ifdef SINGLE_PLAYER
	if (targ.svflags & SVF_MONSTER)
	{
		M_ReactToDamage(targ, attacker
#ifdef GROUND_ZERO
			, inflictor
#endif
			);

		if (!(targ.monsterinfo.aiflags & AI_DUCKED) && take)
		{
			if (targ.pain)
				targ.pain(targ, attacker, knockback, take);

			// nightmare mode monsters don't go into pain frames often
			if (skill.intVal == 3)
				targ.pain_debounce_framenum = level.framenum + 5 * BASE_FRAMERATE;
		}
	}
	else
#endif
	if (targ.is_client)
	{
		if (!(targ.flags & FL_GODMODE) && take)
			targ.pain(targ, attacker, knockback, take);
	}
	else if (take)
	{
		if (targ.pain)
			targ.pain(targ, attacker, knockback, take);
	}

	// add to the damage inflicted on a player this frame
	// the total will be turned into screen blends and view angle kicks
	// at the end of the frame
	if (targ.is_client)
	{
		targ.client.damage_parmor += psave;
		targ.client.damage_armor += asave;
		targ.client.damage_blood += take;
		targ.client.damage_knockback += knockback;
		targ.client.damage_from = point;
	}
}


/*
============
T_RadiusDamage
============
*/
void(entity inflictor, entity attacker, float damage, entity ignore, float radius, means_of_death_t mod) T_RadiusDamage =
{
	float	points;
	entity	ent = world;
	vector	v;
	vector	dir;

	while ((ent = findradius(ent, inflictor.s.origin, radius))) {
		if (ent == ignore)
			continue;
		if (!ent.takedamage)
			continue;

		v = ent.mins + ent.maxs;
		v = ent.s.origin + (0.5f * v);
		v = inflictor.s.origin - v;
		points = damage - 0.5f * VectorLength(v);
		if (ent == attacker)
			points = points * 0.5f;
		if (points > 0) {
			if (CanDamage(ent, inflictor)) {
				dir = ent.s.origin - inflictor.s.origin;
				T_Damage(ent, inflictor, attacker, dir, inflictor.s.origin, vec3_origin, (int)points, (int)points, DAMAGE_RADIUS, mod);
			}
		}
	}
}
