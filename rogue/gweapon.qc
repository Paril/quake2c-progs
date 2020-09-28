#ifdef GROUND_ZERO

/*
========================
fire_flechette
========================
*/
static void(entity self, entity other, vector normal, csurface_t surf) flechette_touch =
{
	if (other == self.owner)
		return;

	if (surf && (surf.flags & SURF_SKY))
	{
		G_FreeEdict (self);
		return;
	}
#ifdef SINGLE_PLAYER

	if (self.is_client)
		PlayerNoise(self.owner, self.s.origin, PNOISE_IMPACT);
#endif

	if (other.takedamage)
	{
		T_Damage (other, self, self.owner, self.velocity, self.s.origin, normal,
			self.dmg, self.dmg_radius, DAMAGE_NO_REG_ARMOR, MOD_ETF_RIFLE);
	}
	else
	{
		gi.WriteByte (svc_temp_entity);
		gi.WriteByte (TE_FLECHETTE);
		gi.WritePosition (self.s.origin);
		gi.WriteDir (normal * 256);
		gi.multicast (self.s.origin, MULTICAST_PVS);
	}

	G_FreeEdict (self);
}

void(entity self, vector start, vector dir, int damage, int speed, int kick) fire_flechette =
{
	VectorNormalize (dir);

	entity flechette = G_Spawn();
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
	
#ifdef SINGLE_PLAYER
	if (self.is_client)
		check_dodge (self, flechette.s.origin, dir, speed);
#endif
}

// **************************
// PROX
// **************************
const float PROX_TIME_TO_LIVE	= 45f;		// 45, 30, 15, 10
const float PROX_TIME_DELAY		= 0.5;
const float PROX_BOUND_SIZE		= 96f;
const float PROX_DAMAGE_RADIUS	= 192f;
const int PROX_HEALTH			= 20;
const int PROX_DAMAGE			= 90;

//===============
//===============
static void(entity ent) Prox_Explode =
{
	//PMM - changed teammaster to "mover" .. owner of the field is the prox
	if (ent.teamchain && ent.teamchain.owner == ent)
		G_FreeEdict(ent.teamchain);

	entity cowner = ent;

	if (ent.teammaster)
#ifdef SINGLE_PLAYER
	{
#endif
		cowner = ent.teammaster;
#ifdef SINGLE_PLAYER
		PlayerNoise(cowner, ent.s.origin, PNOISE_IMPACT);
	}
#endif

	// play quad sound if appopriate
	if (ent.dmg > PROX_DAMAGE)
		gi.sound(ent, CHAN_ITEM, gi.soundindex("items/damage3.wav"), 1, ATTN_NORM, 0);

	ent.takedamage = false;
	T_RadiusDamage(ent, cowner, ent.dmg, ent, PROX_DAMAGE_RADIUS, MOD_PROX);

	vector origin = ent.s.origin + (ent.velocity * -0.02);
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
	self.takedamage = false;

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
static void(entity ent, entity other, vector plane, csurface_t surf) Prox_Field_Touch =
{
	if (!(other.svflags & SVF_MONSTER) && !other.is_client)
		return;

	// trigger the prox mine if it's still there, and still mine.
	entity prox = ent.owner;

	if (other == prox) // don't set self off
		return;

	if (prox.think == Prox_Explode) // we're set to blow!
		return;

	if (prox.teamchain == ent)
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
	if (level.framenum > ent.wait)
		Prox_Explode(ent);
	else
	{
		ent.s.frame++;
		if (ent.s.frame > 13)
			ent.s.frame = 9;
		ent.think = prox_seek;
		ent.nextthink = level.framenum + 1;
	}
}

//===============
//===============
static void(entity ent) prox_open =
{
	if (ent.s.frame == 9)	// end of opening animation
	{
		// set the owner to NULL so the owner can shoot it, etc.  needs to be done here so the owner
		// doesn't get stuck on it while it's opening if fired at point blank wall
		ent.s.sound = 0;
		ent.owner = 0;

		if (ent.teamchain)
			ent.teamchain.touch = Prox_Field_Touch;

		entity search = world;
		while ((search = findradius(search, ent.s.origin, PROX_DAMAGE_RADIUS + 10)))
		{
			if (!search.classname)			// tag token and other weird shit
				continue;

			// if it's a monster or player with health > 0
			// or it's a player start point
			// and we can see it
			// blow up
			if ((((((search.svflags & SVF_MONSTER) || search.is_client) && (search.health > 0)) ||
#ifdef SINGLE_PLAYER
					(deathmatch.intVal &&
#endif
						(search.classname == "info_player_deathmatch" ||
						search.classname == "info_player_start" ||
						search.classname == "info_player_coop" ||
						search.classname == "misc_teleporter_dest")))
#ifdef SINGLE_PLAYER
					)
#endif
				&& visible(search, ent))
			{
				gi.sound (ent, CHAN_VOICE, gi.soundindex ("weapons/proxwarn.wav"), 1, ATTN_NORM, 0);
				Prox_Explode (ent);
				return;
			}
		}

		int multiplier = ent.dmg / PROX_DAMAGE;
		ent.wait = level.framenum + ((PROX_TIME_TO_LIVE / multiplier) * BASE_FRAMERATE);

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
static void(entity ent, entity other, vector normal, csurface_t surf) prox_land =
{
	if (surf && (surf.flags & SURF_SKY))
	{
		G_FreeEdict(ent);
		return;
	}

	if (normal)
	{
		vector land_point = ent.s.origin + (normal * -10.0);

		if (gi.pointcontents (land_point) & (CONTENTS_SLIME|CONTENTS_LAVA))
		{
			Prox_Explode (ent);
			return;
		}
	}

	int	cmovetype = MOVETYPE_NONE;

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
		if (!normal) // this happens if you hit a point object, maybe other cases
		{
			Prox_Explode(ent);
			return;
		}

		vector out = ClipVelocity(ent.velocity, normal, 1.5);

		if (out[2] > 60)
			return;

		cmovetype = MOVETYPE_BOUNCE;

		bool stick_ok = (other.movetype == MOVETYPE_PUSH && normal[2] > 0.7);

		// if we're here, we're going to stop on an entity
		if (stick_ok) // it's a happy entity
			ent.velocity = ent.avelocity = vec3_origin;
		// no-stick.  teflon time
		else if (normal[2] > 0.7)
			Prox_Explode(ent);

		return;
	}
	else if (other.s.modelindex != 1)
		return;

	vector dir = vectoangles (normal);

	if (gi.pointcontents (ent.s.origin) & (CONTENTS_LAVA|CONTENTS_SLIME))
	{
		Prox_Explode (ent);
		return;
	}

	entity field = G_Spawn();
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
	dir[PITCH] += 90;
	ent.s.angles = dir;
	ent.takedamage = true;
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
	vector dir = vectoangles(aimdir);
	vector	right, up;
	AngleVectors (dir, 0, &right, &up);

	entity prox = G_Spawn();
	prox.s.origin = start;
	prox.velocity = aimdir * speed;
	prox.velocity += random(190f, 210f) * up;
	prox.velocity += random(-10f, 10f) * right;
	prox.s.angles = dir;
	prox.s.angles[PITCH] -= 90;
	prox.movetype = MOVETYPE_BOUNCE;
	prox.solid = SOLID_BBOX; 
	prox.s.effects |= EF_GRENADE;
	prox.clipmask = MASK_SHOT|CONTENTS_LAVA|CONTENTS_SLIME;
	prox.s.renderfx |= RF_IR_VISIBLE;
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

void(entity self, vector start, vector aim, int reach, int damage, int kick, int mod) fire_player_melee =
{
	vector v = vectoangles (aim);
	vector forward, right, up;
	AngleVectors (v, &forward, &right, &up);
	VectorNormalize (forward);
	vector point = start + (reach * forward);

	//see if the hit connects
	trace_t	tr;
	gi.traceline(&tr, start, point, self, MASK_SHOT);

	if (tr.fraction == 1.0)
		return;

	if (tr.ent.takedamage == true || tr.ent.takedamage == true)
	{
		// pull the player forward if you do damage
		self.velocity += forward * 75;
		self.velocity += up * 75;

		// do the damage
		if (mod == MOD_CHAINFIST)
			T_Damage (tr.ent, self, self, vec3_origin, tr.ent.s.origin, vec3_origin, damage, kick/2, DAMAGE_DESTROY_ARMOR | DAMAGE_NO_KNOCKBACK, mod);
		else
			T_Damage (tr.ent, self, self, vec3_origin, tr.ent.s.origin, vec3_origin, damage, kick/2, DAMAGE_NO_KNOCKBACK, mod);
	}
	else
	{
		point = tr.normal * 256;
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
	if (self.last_move_framenum < level.framenum)
	{
		gi.positioned_sound (self.s.origin, self, CHAN_AUTO, self.noise_index, 0.75f, ATTN_NONE, 0);
		self.last_move_framenum = level.framenum + (int)(0.5 * BASE_FRAMERATE);
	}

	for (int i = 1; i < globals.num_edicts; i++)
	{
		entity e = itoe(i);

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
	float killzone = radius;
	float killzone2 = radius * 2.0;

	entity ent = world;
	while ((ent = findradius(ent, inflictor.s.origin, killzone2)))
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

		vector v = ent.mins + ent.maxs;
		v = ent.s.origin + (v * 0.5);
		v = inflictor.s.origin - v;

		float len = VectorLength(v);
		float points;
		
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
			vector dir = ent.s.origin - inflictor.s.origin;
			T_Damage (ent, inflictor, attacker, dir, inflictor.s.origin, vec3_origin, (int)points, (int)points, DAMAGE_RADIUS, mod);
		}
	}

	ent = itoe(1); // skip the worldspawn

	// cycle through players
	while (ent)
	{
		if ((ent.is_client) && (ent.client.nuke_framenum != level.framenum+20) && (ent.inuse))
		{
			trace_t tr;
			gi.traceline (&tr, inflictor.s.origin, ent.s.origin, inflictor, MASK_SOLID);

			if (tr.fraction == 1.0)
				ent.client.nuke_framenum = level.framenum + 20;
			else
			{
				float dist = realrange (ent, inflictor);
				if (dist < 2048)
					ent.client.nuke_framenum = maxi(ent.client.nuke_framenum, level.framenum + 15);
				else
					ent.client.nuke_framenum = maxi(ent.client.nuke_framenum, level.framenum + 10);
			}

			ent = next_ent(ent);
		}
		else
			ent = world;
	}
}

static void(entity ent) Nuke_Explode =
{
#ifdef SINGLE_PLAYER
	if (ent.teammaster.is_client)
		PlayerNoise(ent.teammaster, ent.s.origin, PNOISE_IMPACT);

#endif
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
	self.takedamage = false;
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
	int	muzzleflash = MZ_NUKE1;

	int damage_multiplier = ent.dmg / NUKE_DAMAGE;
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

	if (ent.wait < level.framenum)
		Nuke_Explode(ent);
	else if (level.framenum >= (ent.wait - (int)(NUKE_TIME_TO_LIVE * BASE_FRAMERATE)))
	{
		ent.s.frame++;

		if (ent.s.frame > 11)
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
			if ((ent.wait - level.framenum) <= (NUKE_TIME_TO_LIVE / 2.0))
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

static void(entity ent, entity other, vector plane, csurface_t surf) nuke_bounce =
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
	P_DamageModifier (self);

	vector dir = vectoangles (aimdir);
	vector right, up;
	AngleVectors (dir, 0, &right, &up);

	entity nuke = G_Spawn();
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
	nuke.takedamage = true;
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

const float TESLA_TIME_TO_LIVE			= 30f;
const float TESLA_DAMAGE_RADIUS			= 128f;
const int TESLA_DAMAGE					= 3;		// 3
const int TESLA_KNOCKBACK				= 8;
const int TESLA_ACTIVATE_TIME			= 3;
const int TESLA_EXPLOSION_DAMAGE_MULT	= 50;		// this is the amount the damage is multiplied by for underwater explosions
const float TESLA_EXPLOSION_RADIUS		= 200f;

static void(entity self) tesla_remove =
{
	entity	cur, next;

	self.takedamage = false;
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
	if (level.framenum > self.air_finished_framenum)
	{
		tesla_remove(self);
		return;
	}

	vector start = self.s.origin;
	start[2] += 16;

	static hashset entities;
	
	if (handle_empty(entities))
		entities = hashset_alloc(32);

	int num = gi.BoxEdicts(entities, self.teamchain.absmin, self.teamchain.absmax, MAX_EDICTS, AREA_SOLID);

	for (int i = 0; i < num; i++)
	{
		// if the tesla died while zapping things, stop zapping.
		if(!self.inuse)
			break;

		entity hit = entities[i];
		if (!hit.inuse)
			continue;
		if (hit == self)
			continue;
		if (hit.health < 1)
			continue;
#ifdef SINGLE_PLAYER
		// don't hit clients in single-player or coop
		if (hit.is_client)
			if (coop.intVal || !deathmatch.intVal)
				continue;
#endif
		if (!(hit.svflags & (SVF_MONSTER | SVF_DAMAGEABLE)) && !hit.is_client)
			continue;
	
		trace_t tr;
		gi.traceline(&tr, start, hit.s.origin, self, MASK_SHOT);

		if (tr.fraction == 1 || tr.ent == hit)
		{
			vector dir = hit.s.origin - start;
			
			// PMM - play quad sound if it's above the "normal" damage
			if (self.dmg > TESLA_DAMAGE)
				gi.sound(self, CHAN_ITEM, gi.soundindex("items/damage3.wav"), 1, ATTN_NORM, 0);

#ifdef SINGLE_PLAYER
			// PGM - don't do knockback to walking monsters
			if ((hit.svflags & SVF_MONSTER) && !(hit.flags & (FL_FLY|FL_SWIM)))
				T_Damage (hit, self, self.teammaster, dir, tr.endpos, tr.normal,
					self.dmg, 0, 0, MOD_TESLA);
			else
#endif
				T_Damage (hit, self, self.teammaster, dir, tr.endpos, tr.normal,
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

	if(self.inuse)
	{
		self.think = tesla_think_active;
		self.nextthink = level.framenum + 1;
	}
}

static void(entity self) tesla_activate =
{
	if (gi.pointcontents (self.s.origin) & (CONTENTS_SLIME|CONTENTS_LAVA|CONTENTS_WATER))
	{
		tesla_blow (self);
		return;
	}
	
#ifdef SINGLE_PLAYER
	// only check for spawn points in deathmatch
	if (deathmatch.intVal)
	{
#endif
		entity search = world;
		while ((search = findradius(search, self.s.origin, 1.5*TESLA_DAMAGE_RADIUS)))
		{
			// if it's a monster or player with health > 0
			// or it's a deathmatch start point
			// and we can see it
			// blow up
			if (search.classname &&
				(search.classname == "info_player_deathmatch"
				|| search.classname == "info_player_start"
				|| search.classname == "info_player_coop"
				|| search.classname == "misc_teleporter_dest")
				&& visible(search, self))
			{
				tesla_remove (self);
				return;
			}
		}
#ifdef SINGLE_PLAYER
	}
#endif

	entity trigger = G_Spawn();
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
#ifdef SINGLE_PLAYER
	// clear the owner if in deathmatch
	if (deathmatch.intVal)
#endif
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
		return;
	}

	if (ent.s.frame > 9)
	{
		if (ent.s.frame == 10)
#ifdef SINGLE_PLAYER
		{
			if (ent.owner && ent.owner.is_client)
				PlayerNoise(ent.owner, ent.s.origin, PNOISE_WEAPON);		// PGM
#endif
			ent.s.skinnum = 1;
#ifdef SINGLE_PLAYER
		}
#endif
		else if(ent.s.frame == 12)
			ent.s.skinnum = 2;
		else if(ent.s.frame == 14)
			ent.s.skinnum = 3;
	}
	ent.think = tesla_think;
	ent.nextthink = level.framenum + 1;
}

static void(entity ent, entity other, vector normal, csurface_t surf) tesla_lava =
{
	vector	land_point;

	if (normal)
	{
		land_point = ent.s.origin + (normal * -20.0f);
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
	vector dir = vectoangles (aimdir);

	vector right, up;
	AngleVectors (dir, 0, &right, &up);

	entity tesla = G_Spawn();
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
	tesla.nextthink = level.framenum + (TESLA_ACTIVATE_TIME * BASE_FRAMERATE);

	// blow up on contact with lava & slime code
	tesla.touch = tesla_lava;

#ifdef SINGLE_PLAYER
	if !(deathmatch.intVal)
		tesla.health = 30;
	else
#endif
		tesla.health = 20;

	tesla.takedamage = true;
	tesla.die = tesla_die;
	tesla.dmg = TESLA_DAMAGE * damage_multiplier;
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
	vector dir = vectoangles(aimdir), water_start = vec3_origin;

	vector forward;
	AngleVectors (dir, &forward, 0, 0);

	vector end = start + (forward * 8192);
	bool water = false, underwater = false;

	if (gi.pointcontents (start) & MASK_WATER)
	{
		underwater = true;
		water_start = start;
	}

	trace_t	tr;
	gi.traceline (&tr, start, end, self, MASK_SHOT | MASK_WATER);

	// see if we hit water
	if (tr.contents & MASK_WATER)
	{
		water = true;
		vector water_start = tr.endpos;

		if (start != tr.endpos)
		{
			gi.WriteByte (svc_temp_entity);
			gi.WriteByte (TE_HEATBEAM_SPARKS);
			gi.WritePosition (water_start);
			gi.WriteDir (tr.normal);
			gi.multicast (tr.endpos, MULTICAST_PVS);
		}

		// re-trace ignoring water this time
		gi.traceline (&tr, water_start, end, self, MASK_SHOT);
	}

	vector endpoint = tr.endpos;

	// halve the damage if target underwater
	if (water)
		damage /= 2;

	// send gun puff / flash
	if (tr.fraction < 1.0 && !((tr.surface) && (tr.surface.flags & SURF_SKY)))
	{
		if (tr.ent.takedamage)
			T_Damage (tr.ent, self, self, aimdir, tr.endpos, tr.normal, damage, kick, DAMAGE_ENERGY, mod);
		else if (!water && (strncmp (tr.surface.name, "sky", 3)))
		{
			// This is the truncated steam entry - uses 1+1+2 extra bytes of data
			gi.WriteByte (svc_temp_entity);
			gi.WriteByte (TE_HEATBEAM_STEAM);
			gi.WritePosition (tr.endpos);
			gi.WriteDir (tr.normal);
			gi.multicast (tr.endpos, MULTICAST_PVS);
#ifdef SINGLE_PLAYER

			if (self.is_client)
				PlayerNoise(self, tr.endpos, PNOISE_IMPACT);
#endif
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
			gi.traceline(&tr, pos, water_start, tr.ent, MASK_WATER);

		pos = water_start + tr.endpos;
		pos *= 0.5f;

		gi.WriteByte (svc_temp_entity);
		gi.WriteByte (TE_BUBBLETRAIL2);
//		gi.WriteByte (8);
		gi.WritePosition (water_start);
		gi.WritePosition (tr.endpos);
		gi.multicast (pos, MULTICAST_PVS);
	}

	vector beam_endpt;

	if (!underwater && !water)
		beam_endpt = tr.endpos;
	else
		beam_endpt = endpoint;
	
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
static void(entity self, entity other, vector normal, csurface_t surf) blaster2_touch =
{
	if (other == self.owner)
		return;

	if (surf && (surf.flags & SURF_SKY))
	{
		G_FreeEdict (self);
		return;
	}
#ifdef SINGLE_PLAYER

	if (self.owner && self.owner.is_client)
		PlayerNoise(self.owner, self.s.origin, PNOISE_IMPACT);
#endif

	if (other.takedamage)
	{
		means_of_death_t mod = MOD_BLASTER2;

		if (self.owner)
		{
			bool damagestat = self.owner.takedamage;
			self.owner.takedamage = false;
			if (self.dmg >= 5)
				T_RadiusDamage(self, self.owner, self.dmg*3, other, self.dmg_radius, 0);
			T_Damage (other, self, self.owner, self.velocity, self.s.origin, normal, self.dmg, 1, DAMAGE_ENERGY, mod);
			self.owner.takedamage = damagestat;
		}
		else
		{
			if (self.dmg >= 5)
				T_RadiusDamage(self, self.owner, self.dmg*3, other, self.dmg_radius, 0);
			T_Damage (other, self, self.owner, self.velocity, self.s.origin, normal, self.dmg, 1, DAMAGE_ENERGY, mod);
		}
	}
	else
	{
		if (self.dmg >= 5)
			T_RadiusDamage(self, self.owner, self.dmg*3, self.owner, self.dmg_radius, 0);

		gi.WriteByte (svc_temp_entity);
		gi.WriteByte (TE_BLASTER2);
		gi.WritePosition (self.s.origin);
		gi.WriteDir (normal);
		gi.multicast (self.s.origin, MULTICAST_PVS);
	}

	G_FreeEdict (self);
}

void(entity self, vector start, vector dir, int damage, int speed, int effect, bool hyper) fire_blaster2 =
{
	VectorNormalize (dir);

	entity bolt = G_Spawn();
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

#ifdef SINGLE_PLAYER
	if (self.is_client)
		check_dodge (self, bolt.s.origin, dir, speed);
#endif

	trace_t	tr;
	gi.traceline (&tr, self.s.origin, bolt.s.origin, bolt, MASK_SHOT);
	if (tr.fraction < 1.0)
	{
		bolt.s.origin += dir * -10;
		bolt.touch (bolt, tr.ent, vec3_origin, null_surface);
	}
}	

const damage_flags_t TRACKER_DAMAGE_FLAGS = (DAMAGE_NO_POWER_ARMOR | DAMAGE_ENERGY | DAMAGE_NO_KNOCKBACK);
const damage_flags_t TRACKER_IMPACT_FLAGS = (DAMAGE_NO_POWER_ARMOR | DAMAGE_ENERGY);

const float TRACKER_DAMAGE_TIME	= 0.5;		// seconds

static void(entity self) tracker_pain_daemon_think =
{
	if(!self.inuse)
		return;

	if ((level.framenum - self.timestamp) > TRACKER_DAMAGE_TIME * BASE_FRAMERATE)
	{
		if(!self.enemy.is_client)
			self.enemy.s.effects &= ~EF_TRACKERTRAIL;
		G_FreeEdict (self);
		return;
	}

	if (self.enemy.health > 0)
	{
		T_Damage (self.enemy, self, self.owner, vec3_origin, self.enemy.s.origin, MOVEDIR_UP, self.dmg, 0, TRACKER_DAMAGE_FLAGS, MOD_TRACKER);
		
		// if we kill the player, we'll be removed.
		if (!self.inuse)
			return;

		// if we killed a monster, gib them.
		if (self.enemy.health < 1)
		{
			int hurt;
			
			if(self.enemy.gib_health)
				hurt = -self.enemy.gib_health;
			else
				hurt = 500;

			T_Damage (self.enemy, self, self.owner, vec3_origin, self.enemy.s.origin, MOVEDIR_UP, hurt, 0, TRACKER_DAMAGE_FLAGS, MOD_TRACKER);
		}

		if (self.enemy.is_client)
			self.enemy.client.tracker_pain_framenum = level.framenum + 1;
		else
			self.enemy.s.effects |= EF_TRACKERTRAIL;
		
		self.nextthink = level.framenum + 1;
		return;
	}

	if (!self.enemy.is_client)
		self.enemy.s.effects &= ~EF_TRACKERTRAIL;

	G_FreeEdict (self);
}

static inline void(entity cowner, entity cenemy, int damage) tracker_pain_daemon_spawn =
{
	entity daemon = G_Spawn();
	daemon.classname = "pain daemon";
	daemon.think = tracker_pain_daemon_think;
	daemon.nextthink = level.framenum + 1;
	daemon.timestamp = level.framenum;
	daemon.owner = cowner;
	daemon.enemy = cenemy;
	daemon.dmg = damage;
}

static inline void(entity self) tracker_explode =
{
	gi.WriteByte (svc_temp_entity);
	gi.WriteByte (TE_TRACKER_EXPLOSION);
	gi.WritePosition (self.s.origin);
	gi.multicast (self.s.origin, MULTICAST_PVS);

	G_FreeEdict (self);
}

static void(entity self, entity other, vector normal, csurface_t surf) tracker_touch =
{
	if (other == self.owner)
		return;

	if (surf && (surf.flags & SURF_SKY))
	{
		G_FreeEdict (self);
		return;
	}
#ifdef SINGLE_PLAYER

	if (self.is_client)
		PlayerNoise(self.owner, self.s.origin, PNOISE_IMPACT);
#endif

	if (other.takedamage)
	{
		if ((other.svflags & SVF_MONSTER) || other.is_client)
		{
			if (other.health > 0)		// knockback only for living creatures
			{
				// PMM - kickback was times 4 .. reduced to 3
				// now this does no damage, just knockback
				T_Damage (other, self, self.owner, self.velocity, self.s.origin, normal,
							0, (self.dmg*3), TRACKER_IMPACT_FLAGS, MOD_TRACKER);

#ifdef SINGLE_PLAYER
				if (!(other.flags & (FL_FLY|FL_SWIM)))
#endif
					other.velocity[2] += 140;
				
				float damagetime = (self.dmg * FRAMETIME) / TRACKER_DAMAGE_TIME;
				tracker_pain_daemon_spawn (self.owner, other, (int)damagetime);
			}
			else						// lots of damage (almost autogib) for dead bodies
			{
				T_Damage (other, self, self.owner, self.velocity, self.s.origin, normal,
							self.dmg*4, (self.dmg*3), TRACKER_IMPACT_FLAGS, MOD_TRACKER);
			}
		}
		else	// full damage in one shot for inanimate objects
		{
			T_Damage (other, self, self.owner, self.velocity, self.s.origin, normal,
						self.dmg, (self.dmg*3), TRACKER_IMPACT_FLAGS, MOD_TRACKER);
		}
	}

	tracker_explode (self);
}

static void(entity self) tracker_fly =
{
	if ((!self.enemy) || (!self.enemy.inuse) || (self.enemy.health < 1))
	{
		tracker_explode (self);
		return;
	}

	// PMM - try to hunt for center of enemy, if possible and not client
	vector dest;
	if(self.enemy.is_client)
	{
		dest = self.enemy.s.origin;
		dest[2] += self.enemy.viewheight;
	}
	// paranoia
	else if (!self.enemy.absmin || !self.enemy.absmax)
		dest = self.enemy.s.origin;
	else
	{
		dest = self.enemy.absmin * 0.5;
		dest += self.enemy.absmax * 0.5;
	}

	vector dir = dest - self.s.origin;
	VectorNormalize (dir);
	self.s.angles = vectoangles(dir);
	self.velocity = dir * self.speed;

	self.nextthink = level.framenum + 1;
}

void(entity self, vector start, vector dir, int damage, int cspeed, entity cenemy) fire_tracker =
{
	VectorNormalize (dir);

	entity bolt = G_Spawn();
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

	if (cenemy)
	{
		bolt.nextthink = level.framenum + 1;
		bolt.think = tracker_fly;
	}
	else
	{
		bolt.nextthink = level.framenum + (10 * BASE_FRAMERATE);
		bolt.think = G_FreeEdict;
	}

#ifdef SINGLE_PLAYER
	if (self.is_client)
		check_dodge (self, bolt.s.origin, dir, cspeed);
#endif

	trace_t tr;
	gi.traceline(&tr, self.s.origin, bolt.s.origin, bolt, MASK_SHOT);
	if (tr.fraction < 1.0)
	{
		bolt.s.origin += dir * -10;
		bolt.touch (bolt, tr.ent, vec3_origin, null_surface);
	}
}	


#endif