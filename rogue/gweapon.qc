#ifdef GROUND_ZERO

/*
========================
fire_flechette
========================
*/
static void(entity self, entity other, cplane_t plane, csurface_t surf) flechette_touch =
{
	vector		dir;

	if (other == self.owner)
		return;

	if (surf && (surf.flags & SURF_SKY))
	{
		G_FreeEdict (self);
		return;
	}

	if (self.is_client)
		PlayerNoise(self.owner, self.s.origin, PNOISE_IMPACT);

	if (other.takedamage)
	{
		T_Damage (other, self, self.owner, self.velocity, self.s.origin, plane.normal,
			self.dmg, self.dmg_radius, DAMAGE_NO_REG_ARMOR, MOD_ETF_RIFLE);
	}
	else
	{
		if (!plane.normal)
			dir = vec3_origin;
		else
			dir = (plane.normal * 256);
		gi.WriteByte (svc_temp_entity);
		gi.WriteByte (TE_FLECHETTE);
		gi.WritePosition (self.s.origin);
		gi.WriteDir (dir);
		gi.multicast (self.s.origin, MULTICAST_PVS);
	}

	G_FreeEdict (self);
}

void(entity self, vector start, vector dir, int damage, int speed, int kick) fire_flechette =
{
	entity flechette;

	VectorNormalize (dir);

	flechette = G_Spawn();
	flechette.s.origin = flechette.s.old_origin = start;
	flechette.s.angles = vectoangles (dir);

	flechette.velocity = dir * speed;
	flechette.movetype = MOVETYPE_FLYMISSILE;
	flechette.clipmask = MASK_SHOT;
	flechette.solid = SOLID_BBOX;
	flechette.s.renderfx = RF_FULLBRIGHT;
	
	flechette.s.modelindex = gi.modelindex ("models/proj/flechette/tris.md2");

	flechette.owner = self;
	flechette.touch = flechette_touch;
	flechette.nextthink = level.framenum + ((8000 / speed) * BASE_FRAMERATE);
	flechette.think = G_FreeEdict;
	flechette.dmg = damage;
	flechette.dmg_radius = (float)kick;

	gi.linkentity (flechette);
	
	if (self.is_client)
		check_dodge (self, flechette.s.origin, dir, speed);
}

// **************************
// PROX
// **************************
const float PROX_TIME_TO_LIVE	= 45f;		// 45, 30, 15, 10
const float PROX_TIME_DELAY	= 0.5;
const float PROX_BOUND_SIZE	= 96f;
const float PROX_DAMAGE_RADIUS	= 192f;
const int PROX_HEALTH		= 20;
const int PROX_DAMAGE		= 90;

//===============
//===============
static void(entity ent) Prox_Explode =
{
	vector	origin;
	entity	cowner;

	//PMM - changed teammaster to "mover" .. owner of the field is the prox
	if(ent.teamchain && ent.teamchain.owner == ent)
		G_FreeEdict(ent.teamchain);

	cowner = ent;
	if(ent.teammaster)
	{
		cowner = ent.teammaster;
		PlayerNoise(cowner, ent.s.origin, PNOISE_IMPACT);
	}

	// play quad sound if appopriate
	if (ent.dmg > PROX_DAMAGE)
		gi.sound(ent, CHAN_ITEM, gi.soundindex("items/damage3.wav"), 1, ATTN_NORM, 0);

	ent.takedamage = DAMAGE_NO;
	T_RadiusDamage(ent, cowner, ent.dmg, ent, PROX_DAMAGE_RADIUS, MOD_PROX);

	origin = ent.s.origin + (ent.velocity * -0.02);
	gi.WriteByte (svc_temp_entity);
	if (ent.groundentity)
		gi.WriteByte (TE_GRENADE_EXPLOSION);
	else
		gi.WriteByte (TE_ROCKET_EXPLOSION);
	gi.WritePosition (origin);
	gi.multicast (ent.s.origin, MULTICAST_PVS);

	G_FreeEdict (ent);
}

//===============
//===============
static void(entity self, entity inflictor, entity cattacker, int damage, vector point) prox_die =
{
	// if set off by another prox, delay a little (chained explosions)
	self.takedamage = DAMAGE_NO;

	if (inflictor.classname != "prox")
		Prox_Explode(self);
	else
	{
		self.think = Prox_Explode;
		self.nextthink = level.framenum + 1;
	}
}

//===============
//===============
static void(entity ent, entity other, cplane_t plane, csurface_t surf) Prox_Field_Touch =
{
	entity	prox;

	if (!(other.svflags & SVF_MONSTER) && !other.is_client)
		return;

	// trigger the prox mine if it's still there, and still mine.
	prox = ent.owner;

	if (other == prox) // don't set self off
		return;

	if (prox.think == Prox_Explode) // we're set to blow!
		return;

	if(prox.teamchain == ent)
	{
		gi.sound (ent, CHAN_VOICE, gi.soundindex ("weapons/proxwarn.wav"), 1, ATTN_NORM, 0);
		prox.think = Prox_Explode;
		prox.nextthink = level.framenum + (int)(PROX_TIME_DELAY * BASE_FRAMERATE);
		return;
	}

	ent.solid = SOLID_NOT;
	G_FreeEdict(ent);
}

//===============
//===============
static void(entity ent) prox_seek =
{
	if(level.framenum > ent.wait)
		Prox_Explode(ent);
	else
	{
		ent.s.frame++;
		if(ent.s.frame > 13)
			ent.s.frame = 9;
		ent.think = prox_seek;
		ent.nextthink = level.framenum + 1;
	}
}

//===============
//===============
static void(entity ent) prox_open =
{
	entity	search = null_entity;

	if(ent.s.frame == 9)	// end of opening animation
	{
		// set the owner to NULL so the owner can shoot it, etc.  needs to be done here so the owner
		// doesn't get stuck on it while it's opening if fired at point blank wall
		ent.s.sound = 0;
		ent.owner = 0;

		if(ent.teamchain)
			ent.teamchain.touch = Prox_Field_Touch;

		while ((search = findradius(search, ent.s.origin, PROX_DAMAGE_RADIUS + 10)) != null_entity)
		{
			if (!search.classname)			// tag token and other weird shit
				continue;

			// if it's a monster or player with health > 0
			// or it's a player start point
			// and we can see it
			// blow up
			if (
				(
					(((search.svflags & SVF_MONSTER) || (search.is_client)) && (search.health > 0))	|| 
					(
						(deathmatch.intVal) && 
						(
						(search.classname == "info_player_deathmatch") ||
						(search.classname == "info_player_start") ||
						(search.classname == "info_player_coop") ||
						(search.classname == "misc_teleporter_dest")
						)
					)
				)
				&& (visible (search, ent))
			   )
			{
				gi.sound (ent, CHAN_VOICE, gi.soundindex ("weapons/proxwarn.wav"), 1, ATTN_NORM, 0);
				Prox_Explode (ent);
				return;
			}
		}

		/*if (strong_mines && (strong_mines.value))
			ent.wait = level.time + PROX_TIME_TO_LIVE;
		else*/
		{
			int multiplier = ent.dmg / PROX_DAMAGE;
			ent.wait = level.framenum + ((PROX_TIME_TO_LIVE / multiplier) * BASE_FRAMERATE);
		}

		ent.think = prox_seek;
		ent.nextthink = level.framenum + 2;
	}
	else
	{
		if (ent.s.frame == 0)
			gi.sound (ent, CHAN_VOICE, gi.soundindex ("weapons/proxopen.wav"), 1, ATTN_NORM, 0);
		//ent.s.sound = gi.soundindex ("weapons/proxopen.wav");
		ent.s.frame++;
		ent.think = prox_open;
		ent.nextthink = level.framenum + 1;	
	}
}

//===============
//===============
static void(entity ent, entity other, cplane_t plane, csurface_t surf) prox_land =
{
	entity	field;
	vector	dir;
	vector	forward, right, up;
	int	makeslave = 0;
	int	cmovetype = MOVETYPE_NONE;
	int	stick_ok = 0;
	vector	land_point;

	if (surf && (surf.flags & SURF_SKY))
	{
		G_FreeEdict(ent);
		return;
	}

	if (plane.normal)
	{
		land_point = ent.s.origin + (plane.normal * -10.0);

		if (gi.pointcontents (land_point) & (CONTENTS_SLIME|CONTENTS_LAVA))
		{
			Prox_Explode (ent);
			return;
		}
	}

	if ((other.svflags & SVF_MONSTER) || other.is_client || (other.svflags & SVF_DAMAGEABLE))
	{
		if(other != ent.teammaster)
			Prox_Explode(ent);

		return;
	}
	else if (other != world)
	{
		//Here we need to check to see if we can stop on this entity.
		//Note that plane can be NULL
		if (!plane.normal) // this happens if you hit a point object, maybe other cases
		{
			Prox_Explode(ent);
			return;
		}

		if ((other.movetype == MOVETYPE_PUSH) && (plane.normal[2] > 0.7))
			stick_ok = 1;
		else
			stick_ok = 0;
		
		vector out = ClipVelocity(ent.velocity, plane.normal, 1.5);

		if (out[2] > 60)
			return;

		cmovetype = MOVETYPE_BOUNCE;

		// if we're here, we're going to stop on an entity
		if (stick_ok)
		// it's a happy entity
			ent.velocity = ent.avelocity = vec3_origin;
		else // no-stick.  teflon time
		{
			if (plane.normal[2] > 0.7)
			{
				Prox_Explode(ent);
				return;
			}
			return;
		}
	}
	else if (other.s.modelindex != 1)
		return;

	dir = vectoangles (plane.normal);
	AngleVectors (dir, &forward, &right, &up);

	if (gi.pointcontents (ent.s.origin) & (CONTENTS_LAVA|CONTENTS_SLIME))
	{
		Prox_Explode (ent);
		return;
	}

	field = G_Spawn();

	field.s.origin = ent.s.origin;
	field.mins = [ -PROX_BOUND_SIZE, -PROX_BOUND_SIZE, -PROX_BOUND_SIZE ];
	field.maxs = [ PROX_BOUND_SIZE, PROX_BOUND_SIZE, PROX_BOUND_SIZE ];
	field.movetype = MOVETYPE_NONE;
	field.solid = SOLID_TRIGGER;
	field.owner = ent;
	field.classname = "prox_field";
	field.teammaster = ent;
	gi.linkentity (field);

	ent.velocity = ent.avelocity = vec3_origin;
	// rotate to vertical
	dir[PITCH] = dir[PITCH] + 90;
	ent.s.angles = dir;
	ent.takedamage = DAMAGE_AIM;
	ent.movetype = cmovetype;		// either bounce or none, depending on whether we stuck to something
	ent.die = prox_die;
	ent.teamchain = field;
	ent.health = PROX_HEALTH;
	ent.nextthink = level.framenum + 1;
	ent.think = prox_open;
	ent.touch = 0;
	ent.solid = SOLID_BBOX;

	gi.linkentity(ent);
}

//===============
//===============
void(entity self, vector start, vector aimdir, int damage_multiplier, int speed) fire_prox =
{
	entity	prox;
	vector	dir;
	vector	forward, right, up;

	dir = vectoangles(aimdir);
	AngleVectors (dir, &forward, &right, &up);

	prox = G_Spawn();
	prox.s.origin = start;
	prox.velocity = aimdir * speed;
	prox.velocity += random(190f, 210f) * up;
	prox.velocity += random(-10f, 10f) * right;
	prox.s.angles = dir;
	prox.s.angles[PITCH]-=90;
	prox.movetype = MOVETYPE_BOUNCE;
	prox.solid = SOLID_BBOX; 
	prox.s.effects |= EF_GRENADE;
	prox.clipmask = MASK_SHOT|CONTENTS_LAVA|CONTENTS_SLIME;
	prox.s.renderfx |= RF_IR_VISIBLE;
	//FIXME - this needs to be bigger.  Has other effects, though.  Maybe have to change origin to compensate
	// so it sinks in correctly.  Also in lavacheck, might have to up the distance
	prox.mins = '-6 -6 -6';
	prox.maxs = '6 6 6';
	prox.s.modelindex = gi.modelindex ("models/weapons/g_prox/tris.md2");
	prox.owner = self;
	prox.teammaster = self;
	prox.touch = prox_land;
	prox.think = Prox_Explode;
	prox.dmg = PROX_DAMAGE * damage_multiplier;
	prox.classname = "prox";
	prox.svflags |= SVF_DAMAGEABLE;
	prox.flags |= FL_MECHANICAL;
	prox.nextthink = level.framenum + (int)((PROX_TIME_TO_LIVE / damage_multiplier) * BASE_FRAMERATE);

	gi.linkentity (prox);
}

// *************************
// MELEE WEAPONS
// *************************

void(entity self, vector start, vector aim, int reach, int damage, int kick, bool quiet, int mod) fire_player_melee =
{
	vector	forward, right, up;
	vector	v;
	vector	point;
	trace_t	tr;

	v = vectoangles (aim);
	AngleVectors (v, &forward, &right, &up);
	VectorNormalize (forward);
	point = start + (reach * forward);

	//see if the hit connects
	gi.trace(&tr, start, vec3_origin, vec3_origin, point, self, MASK_SHOT);
	if(tr.fraction ==  1.0)
	{
		if(!quiet)
			gi.sound (self, CHAN_WEAPON, gi.soundindex ("weapons/swish.wav"), 1, ATTN_NORM, 0);
		return;
	}

	if(tr.ent.takedamage == DAMAGE_YES || tr.ent.takedamage == DAMAGE_AIM)
	{
		// pull the player forward if you do damage
		self.velocity += forward * 75;
		self.velocity += up * 75;

		// do the damage
		// FIXME - make the damage appear at right spot and direction
		if(mod == MOD_CHAINFIST)
			T_Damage (tr.ent, self, self, vec3_origin, tr.ent.s.origin, vec3_origin, damage, kick/2, DAMAGE_DESTROY_ARMOR | DAMAGE_NO_KNOCKBACK, mod);
		else
			T_Damage (tr.ent, self, self, vec3_origin, tr.ent.s.origin, vec3_origin, damage, kick/2, DAMAGE_NO_KNOCKBACK, mod);

		if(!quiet)
			gi.sound (self, CHAN_WEAPON, gi.soundindex ("weapons/meatht.wav"), 1, ATTN_NORM, 0);
	}
	else
	{
		if(!quiet)
			gi.sound (self, CHAN_WEAPON, gi.soundindex ("weapons/tink1.wav"), 1, ATTN_NORM, 0);

		point = tr.plane.normal * 256;
		gi.WriteByte (svc_temp_entity);
		gi.WriteByte (TE_GUNSHOT);
		gi.WritePosition (tr.endpos);
		gi.WriteDir (point);
		gi.multicast (tr.endpos, MULTICAST_PVS);
	}
}

// *************************
// NUKE 
// *************************

const float NUKE_DELAY		= 4f;
const float NUKE_TIME_TO_LIVE	= 6f;
const float NUKE_RADIUS		= 512f;
const int NUKE_DAMAGE		= 400;
const float NUKE_QUAKE_TIME	= 3f;
const float NUKE_QUAKE_STRENGTH	= 100f;

static void(entity self) Nuke_Quake =
{
	int	i;
	entity	e;

	if (self.last_move_framenum < level.framenum)
	{
		gi.positioned_sound (self.s.origin, self, CHAN_AUTO, self.noise_index, 0.75f, ATTN_NONE, 0);
		self.last_move_framenum = level.framenum + (int)(0.5 * BASE_FRAMERATE);
	}

	for (i=1; i < globals.num_edicts; i++)
	{
		e = itoe(i);

		if (!e.inuse)
			continue;
		if (!e.is_client)
			continue;
		if (e.groundentity == null_entity)
			continue;

		e.groundentity = null_entity;
		e.velocity[0] += random(-150f, 150f);
		e.velocity[1] += random(-150f, 150f);
		e.velocity[2] = self.speed * (100.0f / e.mass);
	}

	if (level.framenum < self.timestamp)
		self.nextthink = level.framenum + 1;
	else
		G_FreeEdict (self);
}

/*
============
T_RadiusNukeDamage

Like T_RadiusDamage, but ignores walls (skips CanDamage check, among others)
// up to KILLZONE radius, do 10,000 points
// after that, do damage linearly out to KILLZONE2 radius
============
*/
static void(entity inflictor, entity attacker, float damage, entity ignore, float radius, int mod) T_RadiusNukeDamage =
{
	float	points;
	entity	ent = null_entity;
	vector	v;
	vector	dir;
	float	len;
	float	killzone, killzone2;
	trace_t	tr;
	float	dist;

	killzone = radius;
	killzone2 = radius*2.0;

	while ((ent = findradius(ent, inflictor.s.origin, killzone2)) != null_entity)
	{
// ignore nobody
		if (ent == ignore)
			continue;
		if (!ent.takedamage)
			continue;
		if (!ent.inuse)
			continue;
		if (!(ent.is_client || (ent.svflags & SVF_MONSTER) || (ent.svflags & SVF_DAMAGEABLE)))
			continue;

		v = ent.mins + ent.maxs;
		v = ent.s.origin + (v * 0.5);
		v = inflictor.s.origin - v;
		len = VectorLength(v);
		if (len <= killzone)
		{
			if (ent.is_client)
				ent.flags |= FL_NOGIB;
			points = 10000f;
		}
		else if (len <= killzone2)
			points = (damage/killzone)*(killzone2 - len);
		else
			points = 0;

		if (points > 0)
		{
			if (ent.is_client)
				ent.client.nuke_framenum = level.framenum + 20;
			dir = ent.s.origin - inflictor.s.origin;
			T_Damage (ent, inflictor, attacker, dir, inflictor.s.origin, vec3_origin, (int)points, (int)points, DAMAGE_RADIUS, mod);
		}
	}
	ent = itoe(1); // skip the worldspawn
	// cycle through players
	while (ent != null_entity)
	{
		if ((ent.is_client) && (ent.client.nuke_framenum != level.framenum+20) && (ent.inuse))
		{
			gi.trace (&tr, inflictor.s.origin, vec3_origin, vec3_origin, ent.s.origin, inflictor, MASK_SOLID);
			if (tr.fraction == 1.0)
				ent.client.nuke_framenum = level.framenum + 20;
			else
			{
				dist = realrange (ent, inflictor);
				if (dist < 2048)
					ent.client.nuke_framenum = max(ent.client.nuke_framenum, level.framenum + 15);
				else
					ent.client.nuke_framenum = max(ent.client.nuke_framenum, level.framenum + 10);
			}
			ent = next_ent(ent);
		}
		else
			ent = null_entity;
	}
}

static void(entity ent) Nuke_Explode =
{
	if (ent.teammaster.is_client)
		PlayerNoise(ent.teammaster, ent.s.origin, PNOISE_IMPACT);

	T_RadiusNukeDamage(ent, ent.teammaster, ent.dmg, ent, ent.dmg_radius, MOD_NUKE);

	if (ent.dmg > NUKE_DAMAGE)
		gi.sound(ent, CHAN_ITEM, gi.soundindex("items/damage3.wav"), 1, ATTN_NORM, 0);

	gi.sound (ent, CHAN_NO_PHS_ADD+CHAN_VOICE, gi.soundindex ("weapons/grenlx1a.wav"), 1, ATTN_NONE, 0);

	gi.WriteByte (svc_temp_entity);
	gi.WriteByte (TE_EXPLOSION1_BIG);
	gi.WritePosition (ent.s.origin);
	gi.multicast (ent.s.origin, MULTICAST_PVS);

	gi.WriteByte (svc_temp_entity);
	gi.WriteByte (TE_NUKEBLAST);
	gi.WritePosition (ent.s.origin);
	gi.multicast (ent.s.origin, MULTICAST_ALL);

	// become a quake
	ent.svflags |= SVF_NOCLIENT;
	ent.noise_index = gi.soundindex ("world/rumble.wav");
	ent.think = Nuke_Quake;
	ent.speed = NUKE_QUAKE_STRENGTH;
	ent.timestamp = level.framenum + (int)(NUKE_QUAKE_TIME * BASE_FRAMERATE);
	ent.nextthink = level.framenum + 1;
	ent.last_move_framenum = 0;
}

static void(entity self, entity inflictor, entity attacker, int damage, vector point) nuke_die =
{
	self.takedamage = DAMAGE_NO;
	if (attacker && attacker.classname == "nuke")
	{
		G_FreeEdict (self);	
		return;
	}
	Nuke_Explode(self);
}

static void(entity ent) Nuke_Think =
{
	const float default_atten = 1.8;
	float attenuation = default_atten;
	int	damage_multiplier, muzzleflash = MZ_NUKE1;

	damage_multiplier = ent.dmg / NUKE_DAMAGE;
	switch (damage_multiplier)
	{
	case 1:
		attenuation = default_atten/1.4;
		muzzleflash = MZ_NUKE1;
		break;
	case 2:
		attenuation = default_atten/2.0;
		muzzleflash = MZ_NUKE2;
		break;
	case 4:
		attenuation = default_atten/3.0;
		muzzleflash = MZ_NUKE4;
		break;
	case 8:
		attenuation = default_atten/5.0;
		muzzleflash = MZ_NUKE8;
		break;
	}

	if(ent.wait < level.framenum)
		Nuke_Explode(ent);
	else if (level.framenum >= (ent.wait - (int)(NUKE_TIME_TO_LIVE * BASE_FRAMERATE)))
	{
		ent.s.frame++;
//		if ((g_showlogic) && (g_showlogic.value))
//			gi.dprintf ("nuke frame %d\n", ent.s.frame);
		if(ent.s.frame > 11)
			ent.s.frame = 6;

		if (gi.pointcontents (ent.s.origin) & (CONTENTS_SLIME|CONTENTS_LAVA))
		{
			Nuke_Explode (ent);
			return;
		}

		ent.think = Nuke_Think;
		ent.nextthink = level.framenum + 1;
		ent.health = 1;
		ent.owner = 0;

		gi.WriteByte (svc_muzzleflash);
		gi.WriteShort (ent.s.number);
		gi.WriteByte (muzzleflash);
		gi.multicast (ent.s.origin, MULTICAST_PVS);

		if (ent.timestamp <= level.framenum)
		{

			if ((ent.wait - level.framenum) <= (NUKE_TIME_TO_LIVE/2.0))
			{
				gi.sound (ent, CHAN_NO_PHS_ADD+CHAN_VOICE, gi.soundindex ("weapons/nukewarn2.wav"), 1, attenuation, 0);
				ent.timestamp = level.framenum + (int)(0.3 * BASE_FRAMERATE);
			}
			else
			{
				gi.sound (ent, CHAN_NO_PHS_ADD+CHAN_VOICE, gi.soundindex ("weapons/nukewarn2.wav"), 1, attenuation, 0);
				ent.timestamp = level.framenum + (int)(0.5 * BASE_FRAMERATE);
			}
		}
	}
	else
	{
		if (ent.timestamp <= level.framenum)
		{
			gi.sound (ent, CHAN_NO_PHS_ADD+CHAN_VOICE, gi.soundindex ("weapons/nukewarn2.wav"), 1, attenuation, 0);
			ent.timestamp = level.framenum + (1 * BASE_FRAMERATE);
		}
		ent.nextthink = level.framenum + 1;
	}
}

static void(entity ent, entity other, cplane_t plane, csurface_t surf) nuke_bounce =
{
	if (random() > 0.5)
		gi.sound (ent, CHAN_VOICE, gi.soundindex ("weapons/hgrenb1a.wav"), 1, ATTN_NORM, 0);
	else
		gi.sound (ent, CHAN_VOICE, gi.soundindex ("weapons/hgrenb2a.wav"), 1, ATTN_NORM, 0);
}

PROGS_LOCAL void(entity ent) P_DamageModifier;
PROGS_LOCAL int	damage_multiplier;

void(entity self, vector start, vector aimdir, int speed) fire_nuke =
{
	entity	nuke;
	vector	dir;
	vector	forward, right, up;

	P_DamageModifier (self);

	dir = vectoangles (aimdir);
	AngleVectors (dir, &forward, &right, &up);

	nuke = G_Spawn();
	nuke.s.origin = start;
	nuke.velocity = aimdir * speed;
	nuke.velocity += random(190f, 210f) * up;
	nuke.velocity += random(-10f, 10f) * right;
	nuke.movetype = MOVETYPE_BOUNCE;
	nuke.clipmask = MASK_SHOT;
	nuke.solid = SOLID_BBOX;
	nuke.s.effects |= EF_GRENADE;
	nuke.s.renderfx |= RF_IR_VISIBLE;
	nuke.mins = '-8 -8 0';
	nuke.maxs = '8 8 16';
	nuke.s.modelindex = gi.modelindex ("models/weapons/g_nuke/tris.md2");
	nuke.owner = self;
	nuke.teammaster = self;
	nuke.nextthink = level.framenum + 1;
	nuke.wait = level.framenum + ((NUKE_DELAY + NUKE_TIME_TO_LIVE) * BASE_FRAMERATE);
	nuke.think = Nuke_Think;
	nuke.touch = nuke_bounce;

	nuke.health = 10000;
	nuke.takedamage = DAMAGE_YES;
	nuke.svflags |= SVF_DAMAGEABLE;
	nuke.dmg = NUKE_DAMAGE * damage_multiplier;
	if (damage_multiplier == 1)
		nuke.dmg_radius = NUKE_RADIUS;
	else
		nuke.dmg_radius = NUKE_RADIUS + NUKE_RADIUS * (0.25 * (float)damage_multiplier);
	// this yields 1.0, 1.5, 2.0, 3.0 times radius
	
	nuke.classname = "nuke";
	nuke.die = nuke_die;

	gi.linkentity (nuke);
}

// *************************
// TESLA
// *************************

const float TESLA_TIME_TO_LIVE		= 30f;
const float TESLA_DAMAGE_RADIUS		= 128f;
const int TESLA_DAMAGE			= 3;		// 3
const int TESLA_KNOCKBACK		= 8;

const float TESLA_ACTIVATE_TIME		= 3f;

const int TESLA_EXPLOSION_DAMAGE_MULT		= 50;		// this is the amount the damage is multiplied by for underwater explosions
const float TESLA_EXPLOSION_RADIUS		= 200f;

static void(entity self) tesla_remove =
{
	entity	cur, next;

	self.takedamage = DAMAGE_NO;
	if(self.teamchain)
	{
		cur = self.teamchain;
		while(cur)
		{
			next = cur.teamchain;
			G_FreeEdict ( cur );
			cur = next;
		}
	}
	else if (self.air_finished_framenum)
		gi.dprintf ("tesla without a field!\n");

	self.owner = self.teammaster;	// Going away, set the owner correctly.
	// PGM - grenade explode does damage to self.enemy
	self.enemy = 0;

	// play quad sound if quadded and an underwater explosion
	if ((self.dmg_radius) && (self.dmg > (TESLA_DAMAGE*TESLA_EXPLOSION_DAMAGE_MULT)))
		gi.sound(self, CHAN_ITEM, gi.soundindex("items/damage3.wav"), 1, ATTN_NORM, 0);

	Grenade_Explode(self);
}

static void(entity self, entity inflictor, entity attacker, int damage, vector point) tesla_die =
{
	tesla_remove(self);
}

static void(entity self) tesla_blow =
{
	self.dmg *= TESLA_EXPLOSION_DAMAGE_MULT;
	self.dmg_radius = TESLA_EXPLOSION_RADIUS;
	tesla_remove(self);
}

static void(entity self) tesla_think_active =
{
	int	i;
	entity	hit;
	vector	dir, start;
	trace_t	tr;
	
	if(level.framenum > self.air_finished_framenum)
	{
		tesla_remove(self);
		return;
	}

	start = self.s.origin;
	start[2] += 16;

	entity_set_t entities = gi.BoxEdicts(self.teamchain.absmin, self.teamchain.absmax, MAX_EDICTS, AREA_SOLID);
	for(i=0;i<entities.length;i++)
	{
		// if the tesla died while zapping things, stop zapping.
		if(!self.inuse)
			break;

		hit=entities[i];
		if(!hit.inuse)
			continue;
		if(hit == self)
			continue;
		if(hit.health < 1)
			continue;
		// don't hit clients in single-player or coop
		if(hit.is_client)
			if (coop.intVal || !deathmatch.intVal)
				continue;
		if(!(hit.svflags & (SVF_MONSTER | SVF_DAMAGEABLE)) && !hit.is_client)
			continue;
	
		gi.trace(&tr, start, vec3_origin, vec3_origin, hit.s.origin, self, MASK_SHOT);
		if(tr.fraction == 1 || tr.ent == hit)
		{
			dir = hit.s.origin - start;
			
			// PMM - play quad sound if it's above the "normal" damage
			if (self.dmg > TESLA_DAMAGE)
				gi.sound(self, CHAN_ITEM, gi.soundindex("items/damage3.wav"), 1, ATTN_NORM, 0);

			// PGM - don't do knockback to walking monsters
			if((hit.svflags & SVF_MONSTER) && !(hit.flags & (FL_FLY|FL_SWIM)))
				T_Damage (hit, self, self.teammaster, dir, tr.endpos, tr.plane.normal,
					self.dmg, 0, 0, MOD_TESLA);
			else
				T_Damage (hit, self, self.teammaster, dir, tr.endpos, tr.plane.normal,
					self.dmg, TESLA_KNOCKBACK, 0, MOD_TESLA);

			gi.WriteByte (svc_temp_entity);
			gi.WriteByte (TE_LIGHTNING);
			gi.WriteShort (hit.s.number);		// destination entity
			gi.WriteShort (self.s.number);		// source entity
			gi.WritePosition (tr.endpos);
			gi.WritePosition (start);
			gi.multicast (start, MULTICAST_PVS);
		}
	}
	entity_set_free(entities);

	if(self.inuse)
	{
		self.think = tesla_think_active;
		self.nextthink = level.framenum + 1;
	}
}

static void(entity self) tesla_activate =
{
	entity	trigger;
	entity	search;

	if (gi.pointcontents (self.s.origin) & (CONTENTS_SLIME|CONTENTS_LAVA|CONTENTS_WATER))
	{
		tesla_blow (self);
		return;
	}

	// only check for spawn points in deathmatch
	if (deathmatch.intVal)
	{
		search = null_entity;
		while ((search = findradius(search, self.s.origin, 1.5*TESLA_DAMAGE_RADIUS)) != null_entity)
		{
			// if it's a monster or player with health > 0
			// or it's a deathmatch start point
			// and we can see it
			// blow up
			if(search.classname)
			{
				if (   ( (search.classname == "info_player_deathmatch")
					|| (search.classname == "info_player_start")
					|| (search.classname == "info_player_coop")
					|| (search.classname == "misc_teleporter_dest")
					) 
					&& (visible (search, self))
				   )
				{
					tesla_remove (self);
					return;
				}
			}
		}
	}

	trigger = G_Spawn();
	trigger.s.origin = self.s.origin;
	trigger.mins = [ -TESLA_DAMAGE_RADIUS, -TESLA_DAMAGE_RADIUS, self.mins[2] ];
	trigger.maxs = [ TESLA_DAMAGE_RADIUS, TESLA_DAMAGE_RADIUS, TESLA_DAMAGE_RADIUS ];
	trigger.movetype = MOVETYPE_NONE;
	trigger.solid = SOLID_TRIGGER;
	trigger.owner = self;
	trigger.touch = 0;
	trigger.classname = "tesla trigger";
	// doesn't need to be marked as a teamslave since the move code for bounce looks for teamchains
	gi.linkentity (trigger);

	self.s.angles = vec3_origin;
	// clear the owner if in deathmatch
	if (deathmatch.intVal)
		self.owner = 0;
	self.teamchain = trigger;
	self.think = tesla_think_active;
	self.nextthink = level.framenum + 1;
	self.air_finished_framenum = level.framenum + (int)(TESLA_TIME_TO_LIVE * BASE_FRAMERATE);
}

static void(entity ent) tesla_think =
{
	if (gi.pointcontents (ent.s.origin) & (CONTENTS_SLIME|CONTENTS_LAVA))
	{
		tesla_remove (ent);
		return;
	}
	
	ent.s.angles = vec3_origin;

	if(!(ent.s.frame))
		gi.sound (ent, CHAN_VOICE, gi.soundindex ("weapons/teslaopen.wav"), 1, ATTN_NORM, 0); 

	ent.s.frame++;
	if(ent.s.frame > 14)
	{
		ent.s.frame = 14;
		ent.think = tesla_activate;
		ent.nextthink = level.framenum + 1;
	}
	else
	{
		if(ent.s.frame > 9)
		{
			if(ent.s.frame == 10)
			{
				if (ent.owner && ent.owner.is_client)
				{
					PlayerNoise(ent.owner, ent.s.origin, PNOISE_WEAPON);		// PGM
				}
				ent.s.skinnum = 1;
			}
			else if(ent.s.frame == 12)
				ent.s.skinnum = 2;
			else if(ent.s.frame == 14)
				ent.s.skinnum = 3;
		}
		ent.think = tesla_think;
		ent.nextthink = level.framenum + 1;
	}
}

static void(entity ent, entity other, cplane_t plane, csurface_t surf) tesla_lava =
{
	vector	land_point;

	if (plane.normal)
	{
		land_point = ent.s.origin + (plane.normal * -20.0f);
		if (gi.pointcontents (land_point) & (CONTENTS_SLIME|CONTENTS_LAVA))
		{
			tesla_blow (ent);
			return;
		}
	}
	if (random() > 0.5)
		gi.sound (ent, CHAN_VOICE, gi.soundindex ("weapons/hgrenb1a.wav"), 1, ATTN_NORM, 0);
	else
		gi.sound (ent, CHAN_VOICE, gi.soundindex ("weapons/hgrenb2a.wav"), 1, ATTN_NORM, 0);
}

void(entity self, vector start, vector aimdir, int damage_multiplier, int speed) fire_tesla =
{
	entity tesla;
	vector dir;
	vector forward, right, up;

	dir = vectoangles (aimdir);
	AngleVectors (dir, &forward, &right, &up);

	tesla = G_Spawn();
	tesla.s.origin = start;
	tesla.velocity = aimdir * speed;
	tesla.velocity += random(190f, 210f) * up;
	tesla.velocity += random(-10.f, 10.f) * right;
	tesla.movetype = MOVETYPE_BOUNCE;
	tesla.solid = SOLID_BBOX;
	tesla.s.effects |= EF_GRENADE;
	tesla.s.renderfx |= RF_IR_VISIBLE;
	tesla.mins = '-12 -12 0';
	tesla.maxs = '12 12 20';
	tesla.s.modelindex = gi.modelindex ("models/weapons/g_tesla/tris.md2");
	
	tesla.owner = self;		// PGM - we don't want it owned by self YET.
	tesla.teammaster = self;

	tesla.wait = (float)(level.framenum + (int)(TESLA_TIME_TO_LIVE * BASE_FRAMERATE));
	tesla.think = tesla_think;
	tesla.nextthink = level.framenum + (int)(TESLA_ACTIVATE_TIME * BASE_FRAMERATE);

	// blow up on contact with lava & slime code
	tesla.touch = tesla_lava;

	if(deathmatch.intVal)
		// PMM - lowered from 50 - 7/29/1998
		tesla.health = 20;
	else
		tesla.health = 30;		// FIXME - change depending on skill?

	tesla.takedamage = DAMAGE_YES;
	tesla.die = tesla_die;
	tesla.dmg = TESLA_DAMAGE*damage_multiplier;
//	tesla.dmg = 0;
	tesla.classname = "tesla";
	tesla.svflags |= SVF_DAMAGEABLE;
	tesla.clipmask = MASK_SHOT|CONTENTS_SLIME|CONTENTS_LAVA;
	tesla.flags |= FL_MECHANICAL;

	gi.linkentity (tesla);
}

// *************************
//  HEATBEAM
// *************************

static void(entity self, vector start, vector aimdir, vector offset, int damage, int kick, int te_beam, int te_impact, int mod) fire_beams =
{
	trace_t		tr;
	vector		dir;
	vector		forward, right, up;
	vector		end;
	vector		water_start = vec3_origin, endpoint;
	bool		water = false, underwater = false;
	int			content_mask = MASK_SHOT | MASK_WATER;
	vector		beam_endpt;

	dir = vectoangles (aimdir);
	AngleVectors (dir, &forward, &right, &up);

	end = start + (forward * 8192);

	if (gi.pointcontents (start) & MASK_WATER)
	{
		underwater = true;
		water_start = start;
		content_mask &= ~MASK_WATER;
	}

	gi.trace (&tr, start, vec3_origin, vec3_origin, end, self, content_mask);

	// see if we hit water
	if (tr.contents & MASK_WATER)
	{
		water = true;
		water_start = tr.endpos;

		if (start != tr.endpos)
		{
			gi.WriteByte (svc_temp_entity);
			gi.WriteByte (TE_HEATBEAM_SPARKS);
			gi.WritePosition (water_start);
			gi.WriteDir (tr.plane.normal);
			gi.multicast (tr.endpos, MULTICAST_PVS);
		}
		// re-trace ignoring water this time
		gi.trace (&tr, water_start, vec3_origin, vec3_origin, end, self, MASK_SHOT);
	}
	endpoint = tr.endpos;

	// halve the damage if target underwater
	if (water)
		damage /= 2;

	// send gun puff / flash
	if (!((tr.surface) && (tr.surface.flags & SURF_SKY)))
	{
		if (tr.fraction < 1.0)
		{
			if (tr.ent.takedamage)
			{
				T_Damage (tr.ent, self, self, aimdir, tr.endpos, tr.plane.normal, damage, kick, DAMAGE_ENERGY, mod);
			}
			else
			{
				if ((!water) && (strncmp (tr.surface.name, "sky", 3)))
				{
					// This is the truncated steam entry - uses 1+1+2 extra bytes of data
					gi.WriteByte (svc_temp_entity);
					gi.WriteByte (TE_HEATBEAM_STEAM);
					gi.WritePosition (tr.endpos);
					gi.WriteDir (tr.plane.normal);
					gi.multicast (tr.endpos, MULTICAST_PVS);

					if (self.is_client)
						PlayerNoise(self, tr.endpos, PNOISE_IMPACT);
				}
			}
		}
	}

	// if went through water, determine where the end and make a bubble trail
	if ((water) || (underwater))
	{
		vector	pos;

		dir = tr.endpos - water_start;
		VectorNormalize (dir);
		pos = tr.endpos + (dir * -2);
		if (gi.pointcontents (pos) & MASK_WATER)
			tr.endpos = pos;
		else
			gi.trace (&tr, pos, vec3_origin, vec3_origin, water_start, tr.ent, MASK_WATER);

		pos = water_start + tr.endpos;
		pos *= 0.5f;

		gi.WriteByte (svc_temp_entity);
		gi.WriteByte (TE_BUBBLETRAIL2);
//		gi.WriteByte (8);
		gi.WritePosition (water_start);
		gi.WritePosition (tr.endpos);
		gi.multicast (pos, MULTICAST_PVS);
	}

	if ((!underwater) && (!water))
	{
		beam_endpt = tr.endpos;
	}
	else
	{
		beam_endpt = endpoint;
	}
	
	gi.WriteByte (svc_temp_entity);
	gi.WriteByte (te_beam);
	gi.WriteShort (self.s.number);
	gi.WritePosition (start);
	gi.WritePosition (beam_endpt);
	gi.multicast (self.s.origin, MULTICAST_ALL);
}


/*
=================
fire_heat

Fires a single heat beam.  Zap.
=================
*/
void(entity self, vector start, vector aimdir, vector offset, int damage, int kick, bool monster) fire_heatbeam =
{
	if (monster)
		fire_beams (self, start, aimdir, offset, damage, kick, TE_MONSTER_HEATBEAM, TE_HEATBEAM_SPARKS, MOD_HEATBEAM);
	else
		fire_beams (self, start, aimdir, offset, damage, kick, TE_HEATBEAM, TE_HEATBEAM_SPARKS, MOD_HEATBEAM);
}


// *************************
//	BLASTER 2
// *************************

/*
=================
fire_blaster2

Fires a single green blaster bolt.  Used by monsters, generally.
=================
*/
static void(entity self, entity other, cplane_t plane, csurface_t surf) blaster2_touch =
{
	int		mod;
	int		damagestat;

	if (other == self.owner)
		return;

	if (surf && (surf.flags & SURF_SKY))
	{
		G_FreeEdict (self);
		return;
	}

	if (self.owner && self.owner.is_client)
		PlayerNoise(self.owner, self.s.origin, PNOISE_IMPACT);

	if (other.takedamage)
	{
		mod = MOD_BLASTER2;

		if (self.owner)
		{
			damagestat = self.owner.takedamage;
			self.owner.takedamage = DAMAGE_NO;
			if (self.dmg >= 5)
				T_RadiusDamage(self, self.owner, self.dmg*3, other, self.dmg_radius, 0);
			T_Damage (other, self, self.owner, self.velocity, self.s.origin, plane.normal, self.dmg, 1, DAMAGE_ENERGY, mod);
			self.owner.takedamage = damagestat;
		}
		else
		{
			if (self.dmg >= 5)
				T_RadiusDamage(self, self.owner, self.dmg*3, other, self.dmg_radius, 0);
			T_Damage (other, self, self.owner, self.velocity, self.s.origin, plane.normal, self.dmg, 1, DAMAGE_ENERGY, mod);
		}
	}
	else
	{
		//PMM - yeowch this will get expensive
		if (self.dmg >= 5)
			T_RadiusDamage(self, self.owner, self.dmg*3, self.owner, self.dmg_radius, 0);

		gi.WriteByte (svc_temp_entity);
		gi.WriteByte (TE_BLASTER2);
		gi.WritePosition (self.s.origin);
		gi.WriteDir (plane.normal);
		gi.multicast (self.s.origin, MULTICAST_PVS);
	}

	G_FreeEdict (self);
}

void(entity self, vector start, vector dir, int damage, int speed, int effect, bool hyper) fire_blaster2 =
{
	entity bolt;
	trace_t	tr;

	VectorNormalize (dir);

	bolt = G_Spawn();
	bolt.s.origin = bolt.s.old_origin = start;
	bolt.s.angles = vectoangles (dir);
	bolt.velocity = dir * speed;
	bolt.movetype = MOVETYPE_FLYMISSILE;
	bolt.clipmask = MASK_SHOT;
	bolt.solid = SOLID_BBOX;
	bolt.s.effects |= effect;

	if (effect)
		bolt.s.effects |= EF_TRACKER;
	bolt.dmg_radius = 128f;
	bolt.s.modelindex = gi.modelindex ("models/proj/laser2/tris.md2");
	bolt.touch = blaster2_touch;

	bolt.owner = self;
	bolt.nextthink = level.framenum + 2 * BASE_FRAMERATE;
	bolt.think = G_FreeEdict;
	bolt.dmg = damage;
	bolt.classname = "bolt";
 	gi.linkentity (bolt);

	if (self.is_client)
		check_dodge (self, bolt.s.origin, dir, speed);

	gi.trace (&tr, self.s.origin, vec3_origin, vec3_origin, bolt.s.origin, bolt, MASK_SHOT);
	if (tr.fraction < 1.0)
	{
		bolt.s.origin += dir * -10;
		bolt.touch (bolt, tr.ent, null_plane, null_surface);
	}
}	

const damage_flags_t TRACKER_DAMAGE_FLAGS = (DAMAGE_NO_POWER_ARMOR | DAMAGE_ENERGY | DAMAGE_NO_KNOCKBACK);
const damage_flags_t TRACKER_IMPACT_FLAGS = (DAMAGE_NO_POWER_ARMOR | DAMAGE_ENERGY);

const float TRACKER_DAMAGE_TIME	= 0.5;		// seconds

static void(entity self) tracker_pain_daemon_think =
{
	static const vector pain_normal = '0 0 1';
	int hurt;

	if(!self.inuse)
		return;

	if((level.framenum - self.timestamp) > TRACKER_DAMAGE_TIME * BASE_FRAMERATE)
	{
		if(!self.enemy.is_client)
			self.enemy.s.effects &= ~EF_TRACKERTRAIL;
		G_FreeEdict (self);
		return;
	}

	if(self.enemy.health > 0)
	{
		T_Damage (self.enemy, self, self.owner, vec3_origin, self.enemy.s.origin, pain_normal, self.dmg, 0, TRACKER_DAMAGE_FLAGS, MOD_TRACKER);
		
		// if we kill the player, we'll be removed.
		if (!self.inuse)
			return;

		// if we killed a monster, gib them.
		if (self.enemy.health < 1)
		{
			if(self.enemy.gib_health)
				hurt = - self.enemy.gib_health;
			else
				hurt = 500;

//					gi.dprintf("non-player killed. ensuring gib!  %d\n", hurt);
			T_Damage (self.enemy, self, self.owner, vec3_origin, self.enemy.s.origin, pain_normal, hurt, 0, TRACKER_DAMAGE_FLAGS, MOD_TRACKER);
		}

		if(self.enemy.is_client)
			self.enemy.client.tracker_pain_framenum = level.framenum + 1;
		else
			self.enemy.s.effects |= EF_TRACKERTRAIL;
		
		self.nextthink = level.framenum + 1;
		return;
	}

	if(!self.enemy.is_client)
		self.enemy.s.effects &= ~EF_TRACKERTRAIL;
	G_FreeEdict (self);
}

static void(entity cowner, entity cenemy, int damage) tracker_pain_daemon_spawn =
{
	entity daemon;

	if (!cenemy)
		return;

	daemon = G_Spawn();
	daemon.classname = "pain daemon";
	daemon.think = tracker_pain_daemon_think;
	daemon.nextthink = level.framenum + 1;
	daemon.timestamp = level.framenum;
	daemon.owner = cowner;
	daemon.enemy = cenemy;
	daemon.dmg = damage;
}

static void(entity self, cplane_t plane) tracker_explode =
{
	vector	dir = vec3_origin;

	if (plane.normal)
		dir = plane.normal * 256;

	gi.WriteByte (svc_temp_entity);
	gi.WriteByte (TE_TRACKER_EXPLOSION);
	gi.WritePosition (self.s.origin);
	gi.multicast (self.s.origin, MULTICAST_PVS);

	G_FreeEdict (self);
}

static void(entity self, entity other, cplane_t plane, csurface_t surf) tracker_touch =
{
	float	damagetime;

	if (other == self.owner)
		return;

	if (surf && (surf.flags & SURF_SKY))
	{
		G_FreeEdict (self);
		return;
	}

	if (self.is_client)
		PlayerNoise(self.owner, self.s.origin, PNOISE_IMPACT);

	if (other.takedamage)
	{
		if((other.svflags & SVF_MONSTER) || other.is_client)
		{
			if(other.health > 0)		// knockback only for living creatures
			{
				// PMM - kickback was times 4 .. reduced to 3
				// now this does no damage, just knockback
				T_Damage (other, self, self.owner, self.velocity, self.s.origin, plane.normal,
							/* self.dmg */ 0, (self.dmg*3), TRACKER_IMPACT_FLAGS, MOD_TRACKER);
				
				if (!(other.flags & (FL_FLY|FL_SWIM)))
					other.velocity[2] += 140;
				
				damagetime = ((float)self.dmg)*FRAMETIME;
				damagetime = damagetime / TRACKER_DAMAGE_TIME;
//				gi.dprintf ("damage is %f\n", damagetime);

				tracker_pain_daemon_spawn (self.owner, other, (int)damagetime);
			}
			else						// lots of damage (almost autogib) for dead bodies
			{
				T_Damage (other, self, self.owner, self.velocity, self.s.origin, plane.normal,
							self.dmg*4, (self.dmg*3), TRACKER_IMPACT_FLAGS, MOD_TRACKER);
			}
		}
		else	// full damage in one shot for inanimate objects
		{
			T_Damage (other, self, self.owner, self.velocity, self.s.origin, plane.normal,
						self.dmg, (self.dmg*3), TRACKER_IMPACT_FLAGS, MOD_TRACKER);
		}
	}

	tracker_explode (self, plane);
}

static void(entity self) tracker_fly =
{
	vector	dest;
	vector	dir;
	vector	center;

	if ((!self.enemy) || (!self.enemy.inuse) || (self.enemy.health < 1))
	{
		tracker_explode (self, null_plane);
		return;
	}
/*
	VectorCopy (self.enemy.s.origin, dest);
	if(self.enemy.client)
		dest[2] += self.enemy.viewheight;
*/
	// PMM - try to hunt for center of enemy, if possible and not client
	if(self.enemy.is_client)
	{
		dest = self.enemy.s.origin;
		dest[2] += self.enemy.viewheight;
	}
	// paranoia
	else if (!self.enemy.absmin || !self.enemy.absmax)
	{
		dest = self.enemy.s.origin;
	}
	else
	{
		center = self.enemy.absmin * 0.5;
		center += self.enemy.absmax * 0.5;
		dest = center;
	}

	dir = dest - self.s.origin;
	VectorNormalize (dir);
	self.s.angles = vectoangles(dir);
	self.velocity = dir * self.speed;
	self.monsterinfo.saved_goal = dest;

	self.nextthink = level.framenum + 1;
}

void(entity self, vector start, vector dir, int damage, int cspeed, entity cenemy) fire_tracker =
{
	entity bolt;
	trace_t	tr;

	VectorNormalize (dir);

	bolt = G_Spawn();
	bolt.s.origin = bolt.s.old_origin = start;
	bolt.s.angles = vectoangles (dir);
	bolt.velocity = dir * cspeed;
	bolt.movetype = MOVETYPE_FLYMISSILE;
	bolt.clipmask = MASK_SHOT;
	bolt.solid = SOLID_BBOX;
	bolt.speed = (float)cspeed;
	bolt.s.effects = EF_TRACKER;
	bolt.s.sound = gi.soundindex ("weapons/disrupt.wav");
	
	bolt.s.modelindex = gi.modelindex ("models/proj/disintegrator/tris.md2");
	bolt.touch = tracker_touch;
	bolt.enemy = cenemy;
	bolt.owner = self;
	bolt.dmg = damage;
	bolt.classname = "tracker";
	gi.linkentity (bolt);

	if(cenemy)
	{
		bolt.nextthink = level.framenum + 1;
		bolt.think = tracker_fly;
	}
	else
	{
		bolt.nextthink = level.framenum + (10 * BASE_FRAMERATE);
		bolt.think = G_FreeEdict;
	}

	if (self.is_client)
		check_dodge (self, bolt.s.origin, dir, cspeed);

	gi.trace (&tr, self.s.origin, vec3_origin, vec3_origin, bolt.s.origin, bolt, MASK_SHOT);
	if (tr.fraction < 1.0)
	{
		bolt.s.origin += dir * -10;
		bolt.touch (bolt, tr.ent, null_plane, null_surface);
	}
}	


#endif