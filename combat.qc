/*
============
CanDamage

Returns true if the inflictor can directly damage the target.  Used for
explosions and melee attacks.
============
*/
bool(entity targ, entity inflictor) CanDamage =
{
	vector	dest;
	trace_t trace;

// bmodels need special checking because their origin is 0,0,0
	if (targ->movetype == MOVETYPE_PUSH) {
		dest = targ->absmin + targ->absmax;
		VectorScale(dest, 0.5f, dest);
		gi.trace(&trace, inflictor->s.origin, vec3_origin, vec3_origin, dest, inflictor, MASK_SOLID);
		if (trace.fraction == 1.0f)
			return true;
		if (trace.ent == targ)
			return true;
		return false;
	}

	gi.trace(&trace, inflictor->s.origin, vec3_origin, vec3_origin, targ->s.origin, inflictor, MASK_SOLID);
	if (trace.fraction == 1.0f)
		return true;

	VectorCopy(targ->s.origin, dest);
	dest_x += 15.0f;
	dest_y += 15.0f;
	gi.trace(&trace, inflictor->s.origin, vec3_origin, vec3_origin, dest, inflictor, MASK_SOLID);
	if (trace.fraction == 1.0f)
		return true;

	VectorCopy(targ->s.origin, dest);
	dest_x += 15.0f;
	dest_y -= 15.0f;
	gi.trace(&trace, inflictor->s.origin, vec3_origin, vec3_origin, dest, inflictor, MASK_SOLID);
	if (trace.fraction == 1.0f)
		return true;

	VectorCopy(targ->s.origin, dest);
	dest_x -= 15.0f;
	dest_y += 15.0f;
	gi.trace(&trace, inflictor->s.origin, vec3_origin, vec3_origin, dest, inflictor, MASK_SOLID);
	if (trace.fraction == 1.0f)
		return true;

	VectorCopy(targ->s.origin, dest);
	dest_x -= 15.0f;
	dest_y -= 15.0f;
	gi.trace(&trace, inflictor->s.origin, vec3_origin, vec3_origin, dest, inflictor, MASK_SOLID);
	if (trace.fraction == 1.0f)
		return true;


	return false;
}

// from monster.qc
void(entity) monster_death_use;

/*
============
Killed
============
*/
static void(entity targ, entity inflictor, entity attacker, int damage, vector point) Killed =
{
	if (targ->health < -999)
		targ->health = -999;

	targ->enemy = attacker;

	if ((targ->svflags & SVF_MONSTER) && (targ->deadflag != DEAD_DEAD)) {
		if (!(targ->monsterinfo.aiflags & AI_GOOD_GUY)) {
			level.killed_monsters++;
			if (coop->intVal && attacker->is_client)
				attacker->client->resp.score++;
			// medics won't heal monsters that they kill themselves
			if (attacker->classname == "monster_medic")
				targ->owner = attacker;
		}
	}

	if (targ->movetype == MOVETYPE_PUSH || targ->movetype == MOVETYPE_STOP || targ->movetype == MOVETYPE_NONE) {
		// doors, triggers, etc
		targ->die(targ, inflictor, attacker, damage, point);
		return;
	}

	if ((targ->svflags & SVF_MONSTER) && (targ->deadflag != DEAD_DEAD)) {
		targ->touch = 0;
		monster_death_use(targ);
	}

	targ->die(targ, inflictor, attacker, damage, point);
}


/*
================
SpawnDamage
================
*/
static void(int type, vector origin, vector normal, int damage) SpawnDamage =
{
	if (damage > 255)
		damage = 255;
	gi.WriteByte(svc_temp_entity);
	gi.WriteByte(type);
	gi.WritePosition(origin);
	gi.WriteDir(normal);
	gi.multicast(origin, MULTICAST_PVS);
}

// from items.qc
int(entity ent) PowerArmorType;

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

	if (dflags & DAMAGE_NO_ARMOR)
		return 0;

	index = 0;  // shut up qcc

	if (ent.is_client) {
		power_armor_type = PowerArmorType(ent);
		if (power_armor_type != POWER_ARMOR_NONE) {
			index = ITEM_INDEX(FindItem("Cells"));
			power = ent.client->pers.inventory[index];
		}
	} else if (ent->svflags & SVF_MONSTER) {
		power_armor_type = ent->monsterinfo.power_armor_type;
		power = ent->monsterinfo.power_armor_power;
	} else
		return 0;

	if (power_armor_type == POWER_ARMOR_NONE)
		return 0;
	if (!power)
		return 0;

	if (power_armor_type == POWER_ARMOR_SCREEN) {
		vector	vec;
		float	dot;
		vector	forward;

		// only works if damage point is in front
		AngleVectors(ent->s.angles, &forward, 0, 0);
		VectorSubtract(point, ent->s.origin, vec);
		VectorNormalize(vec);
		dot = vec * forward;
		if (dot <= 0.3f)
			return 0;

		damagePerCell = 1;
		pa_te_type = TE_SCREEN_SPARKS;
		damage = damage / 3;
	} else {
		damagePerCell = 2;
		pa_te_type = TE_SHIELD_SPARKS;
		damage = (2 * damage) / 3;
	}

	save = power * damagePerCell;
	if (!save)
		return 0;
	if (save > damage)
		save = damage;

	SpawnDamage(pa_te_type, point, normal, save);
	ent->powerarmor_framenum = (int)(level.framenum + 0.2f * BASE_FRAMERATE);

	power_used = save / damagePerCell;

	if (ent.is_client)
		ent.client->pers.inventory[index] -= power_used;
	else
		ent->monsterinfo.power_armor_power -= power_used;
	return save;
}

static int(entity ent, vector point, vector normal, int damage, int te_sparks, damage_flags_t dflags) CheckArmor =
{
	int	save;
	int	index;
	gitem_id_t	armor;

	if (!damage)
		return 0;

	if (!ent.is_client)
		return 0;

	if (dflags & DAMAGE_NO_ARMOR)
		return 0;

	index = ArmorIndex(ent);
	if (!index)
		return 0;

	armor = GetItemByIndex(index);

	if (dflags & DAMAGE_ENERGY)
		save = (int)ceilf(GetArmorInfoKeyByIndex(GetItemKeyByIndex(armor, info), energy_protection) * damage);
	else
		save = (int)ceilf(GetArmorInfoKeyByIndex(GetItemKeyByIndex(armor, info), normal_protection) * damage);

	if (save >= ent.client->pers.inventory[index])
		save = ent.client->pers.inventory[index];

	if (!save)
		return 0;

	ent.client->pers.inventory[index] -= save;
	SpawnDamage(te_sparks, point, normal, save);

	return save;
}

void(entity self) FoundTarget;

static void(entity targ, entity attacker) M_ReactToDamage =
{
	if (!(attacker->is_client) && !(attacker->svflags & SVF_MONSTER))
		return;

	if (attacker == targ || attacker == targ->enemy)
		return;

	// if we are a good guy monster and our attacker is a player
	// or another good guy, do not get mad at them
	if (targ->monsterinfo.aiflags & AI_GOOD_GUY) {
		if (attacker->is_client || (attacker->monsterinfo.aiflags & AI_GOOD_GUY))
			return;
	}

	// we now know that we are not both good guys

	// if attacker is a client, get mad at them because he's good and we're not
	if (attacker->is_client) {
		targ->monsterinfo.aiflags &= ~AI_SOUND_TARGET;

		// this can only happen in coop (both new and old enemies are clients)
		// only switch if can't see the current enemy
		if (targ->enemy && targ->enemy->is_client) {
			if (visible(targ, targ->enemy)) {
				targ->oldenemy = attacker;
				return;
			}
			targ->oldenemy = targ->enemy;
		}
		targ->enemy = attacker;
		if (!(targ->monsterinfo.aiflags & AI_DUCKED))
			FoundTarget(targ);
		return;
	}

	// it's the same base (walk/swim/fly) type and a different classname and it's not a tank
	// (they spray too much), get mad at them
	if (((targ->flags & (FL_FLY | FL_SWIM)) == (attacker->flags & (FL_FLY | FL_SWIM))) &&
		(targ->classname != attacker->classname) &&
		(attacker->classname != "monster_tank") &&
		(attacker->classname != "monster_supertank") &&
		(attacker->classname != "monster_makron") &&
		(attacker->classname != "monster_jorg")) {
		if (targ->enemy && targ->enemy->is_client)
			targ->oldenemy = targ->enemy;
		targ->enemy = attacker;
		if (!(targ->monsterinfo.aiflags & AI_DUCKED))
			FoundTarget(targ);
	}
	// if they *meant* to shoot us, then shoot back
	else if (attacker->enemy == targ) {
		if (targ->enemy && targ->enemy->is_client)
			targ->oldenemy = targ->enemy;
		targ->enemy = attacker;
		if (!(targ->monsterinfo.aiflags & AI_DUCKED))
			FoundTarget(targ);
	}
	// otherwise get mad at whoever they are mad at (help our buddy) unless it is us!
	else if (attacker->enemy && attacker->enemy != targ) {
		if (targ->enemy && targ->enemy->is_client)
			targ->oldenemy = targ->enemy;
		targ->enemy = attacker->enemy;
		if (!(targ->monsterinfo.aiflags & AI_DUCKED))
			FoundTarget(targ);
	}
}

static bool(entity target, entity attacker) CheckTeamDamage =
{
	//FIXME make the next line real and uncomment this block
	// if ((ability to damage a teammate == OFF) && (targ's team == attacker's team))
	return false;
}

// from cmds.qc
bool(entity, entity) OnSameTeam;

void(entity targ, entity inflictor, entity attacker, vector dir, vector point, vector normal, int damage, int knockback, damage_flags_t dflags, means_of_death_t mod) T_Damage =
{
	int         take;
	int         save;
	int         asave;
	int         psave;
	int         te_sparks;

	if (!targ->takedamage)
		return;

	// easy mode takes half damage
	if (skill->intVal == 0 && deathmatch->intVal == 0 && targ->is_client) {
		damage = (int)(damage * 0.5f);
		if (!damage)
			damage = 1;
	}

	// friendly fire avoidance
	// if enabled you can't hurt teammates (but you can hurt yourself)
	// knockback still occurs
	if ((targ != attacker) && ((deathmatch->intVal && (dmflags->intVal & (DF_MODELTEAMS | DF_SKINTEAMS))) || (coop->intVal && targ->is_client))) {
		if (OnSameTeam(targ, attacker)) {
			if (dmflags->intVal & DF_NO_FRIENDLY_FIRE)
				damage = 0;
			else
				mod |= MOD_FRIENDLY_FIRE;
		}
	}
	meansOfDeath = mod;

	if (dflags & DAMAGE_BULLET)
		te_sparks = TE_BULLET_SPARKS;
	else
		te_sparks = TE_SPARKS;

	VectorNormalize(dir);

// bonus damage for suprising a monster
	if (!(dflags & DAMAGE_RADIUS) && (targ->svflags & SVF_MONSTER) && (attacker->is_client) && (!targ->enemy) && (targ->health > 0))
		damage *= 2;

	if (targ->flags & FL_NO_KNOCKBACK)
		knockback = 0;

// figure momentum add
	if (!(dflags & DAMAGE_NO_KNOCKBACK)) {
		if ((knockback) && (targ->movetype != MOVETYPE_NONE) && (targ->movetype != MOVETYPE_BOUNCE) && (targ->movetype != MOVETYPE_PUSH) && (targ->movetype != MOVETYPE_STOP)) {
			vector	kvel;
			float	calc_mass;

			if (targ->mass < 50)
				calc_mass = 50f;
			else
				calc_mass = (float)targ->mass;

			if (targ->is_client && attacker == targ)
				VectorScale(dir, 1600.0f * (float)knockback / calc_mass, kvel);  // the rocket jump hack...
			else
				VectorScale(dir, 500.0f * (float)knockback / calc_mass, kvel);

			targ->velocity += kvel;
		}
	}

	take = damage;
	save = 0;

	// check for godmode
	if ((targ->flags & FL_GODMODE) && !(dflags & DAMAGE_NO_PROTECTION)) {
		take = 0;
		save = damage;
		SpawnDamage(te_sparks, point, normal, save);
	}

	// check for invincibility
	if ((targ.is_client && targ.client->invincible_framenum > level.framenum) && !(dflags & DAMAGE_NO_PROTECTION)) {
		if (targ->pain_debounce_framenum < level.framenum) {
			gi.sound(targ, CHAN_ITEM, gi.soundindex("items/protect4.wav"), 1, ATTN_NORM, 0);
			targ->pain_debounce_framenum = level.framenum + 2 * BASE_FRAMERATE;
		}
		take = 0;
		save = damage;
	}

	psave = CheckPowerArmor(targ, point, normal, take, dflags);
	take -= psave;

	asave = CheckArmor(targ, point, normal, take, te_sparks, dflags);
	take -= asave;

	//treat cheat/powerup savings the same as armor
	asave += save;

	// team damage avoidance
	if (!(dflags & DAMAGE_NO_PROTECTION) && CheckTeamDamage(targ, attacker))
		return;

// do the damage
	if (take) {
		if ((targ->svflags & SVF_MONSTER) || (targ.is_client))
			SpawnDamage(TE_BLOOD, point, normal, take);
		else
			SpawnDamage(te_sparks, point, normal, take);


		targ->health = targ->health - take;

		if (targ->health <= 0) {
			if ((targ->svflags & SVF_MONSTER) || (targ.is_client))
				targ->flags |= FL_NO_KNOCKBACK;
			Killed(targ, inflictor, attacker, take, point);
			return;
		}
	}

	if (targ->svflags & SVF_MONSTER) {
		M_ReactToDamage(targ, attacker);
		if (!(targ->monsterinfo.aiflags & AI_DUCKED) && (take)) {
			targ->pain(targ, attacker, knockback, take);
			// nightmare mode monsters don't go into pain frames often
			if (skill->intVal == 3)
				targ->pain_debounce_framenum = level.framenum + 5 * BASE_FRAMERATE;
		}
	} else if (targ.is_client) {
		if (!(targ->flags & FL_GODMODE) && (take))
			targ->pain(targ, attacker, knockback, take);
	} else if (take) {
		if (targ->pain)
			targ->pain(targ, attacker, knockback, take);
	}

	// add to the damage inflicted on a player this frame
	// the total will be turned into screen blends and view angle kicks
	// at the end of the frame
	if (targ.is_client) {
		targ.client->damage_parmor += psave;
		targ.client->damage_armor += asave;
		targ.client->damage_blood += take;
		targ.client->damage_knockback += knockback;
		VectorCopy(point, targ.client->damage_from);
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
	entity	ent = null_entity;
	vector	v;
	vector	dir;

	while ((ent = findradius(ent, inflictor->s.origin, radius)) != null_entity) {
		if (ent == ignore)
			continue;
		if (!ent->takedamage)
			continue;

		v = ent->mins + ent->maxs;
		VectorMA(ent->s.origin, 0.5f, v, v);
		VectorSubtract(inflictor->s.origin, v, v);
		points = damage - 0.5f * VectorLength(v);
		if (ent == attacker)
			points = points * 0.5f;
		if (points > 0) {
			if (CanDamage(ent, inflictor)) {
				VectorSubtract(ent->s.origin, inflictor->s.origin, dir);
				T_Damage(ent, inflictor, attacker, dir, inflictor->s.origin, vec3_origin, (int)points, (int)points, DAMAGE_RADIUS, mod);
			}
		}
	}
}
