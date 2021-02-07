#ifdef GROUND_ZERO

static INLINE vector(entity ent, vector point, vector distance, vector forward, vector right, vector up) P_ProjectSource2 =
{
	vector scaled_dist = [ distance[0], distance[1] * handedness_scales[ent.client.pers.hand], distance[2] ];
	return G_ProjectSource2(point, scaled_dist, forward, right, up);
}

static void(entity ent, int FRAME_FIRE_LAST, int FRAME_IDLE_LAST, int FRAME_THROW_SOUND, int FRAME_THROW_HOLD, int FRAME_THROW_FIRE, bool(int) is_pause_frame, void(entity, bool) fire) Throw_Generic =
{
	if ((ent.client.newweapon) && (ent.client.weaponstate == WEAPON_READY))
	{
		ChangeWeapon (ent);
		return;
	}

	if (ent.client.weaponstate == WEAPON_ACTIVATING)
	{
		ent.client.weaponstate = WEAPON_READY;
		ent.client.ps.gunframe = FRAME_IDLE_FIRST;
		return;
	}

	if (ent.client.weaponstate == WEAPON_READY)
	{
		if ((ent.client.latched_buttons | ent.client.buttons) & BUTTON_ATTACK)
		{
			ent.client.latched_buttons &= ~BUTTON_ATTACK;

			if (ent.client.pers.inventory[ent.client.ammo_index])
			{
				ent.client.ps.gunframe = 1;
				ent.client.weaponstate = WEAPON_FIRING;
				ent.client.grenade_framenum = 0;
				return;
			}
			else if (level.framenum >= ent.pain_debounce_framenum)
			{
				gi.sound(ent, CHAN_VOICE, gi.soundindex("weapons/noammo.wav"), 1, ATTN_NORM, 0);
				ent.pain_debounce_framenum = level.framenum + (1 * BASE_FRAMERATE);
			}

			NoAmmoWeaponChange (ent);
			return;
		}

		if (ent.client.ps.gunframe == FRAME_IDLE_LAST)
		{
			ent.client.ps.gunframe = FRAME_IDLE_FIRST;
			return;
		}

		if (is_pause_frame(ent.client.ps.gunframe) && (Q_rand() & 15))
			return;

		ent.client.ps.gunframe++;
		return;
	}

	if (ent.client.weaponstate == WEAPON_FIRING)
	{
		if (ent.client.ps.gunframe == FRAME_THROW_SOUND)
			gi.sound(ent, CHAN_WEAPON, gi.soundindex("weapons/hgrena1b.wav"), 1, ATTN_NORM, 0);

		if (ent.client.ps.gunframe == FRAME_THROW_HOLD)
		{
			if (!ent.client.grenade_framenum)
				ent.client.grenade_framenum = level.framenum + (int)((GRENADE_TIMER + 0.2) * BASE_FRAMERATE);

			if (ent.client.buttons & BUTTON_ATTACK)
				return;

			if (ent.client.grenade_blew_up)
			{
				if (level.framenum >= ent.client.grenade_framenum)
				{
					ent.client.ps.gunframe = FRAME_FIRE_LAST;
					ent.client.grenade_blew_up = false;
				}
				else
					return;
			}
		}

		if (ent.client.ps.gunframe == FRAME_THROW_FIRE)
		{
			ent.client.weapon_sound = 0;
			fire (ent, true);
		}

		if ((ent.client.ps.gunframe == FRAME_FIRE_LAST) && (level.framenum < ent.client.grenade_framenum))
			return;

		ent.client.ps.gunframe++;

		if (ent.client.ps.gunframe == FRAME_IDLE_FIRST)
		{
			ent.client.grenade_framenum = 0;
			ent.client.weaponstate = WEAPON_READY;
		}
	}
}

static void(entity ent, bool held) weapon_tesla_fire =
{
	int	damage = 125;

	if (is_quad)
		damage *= damage_multiplier;		// PGM

	vector forward, right, up;
	AngleVectors (ent.client.v_angle, &forward, &right, &up);

	vector offset = [ 0, -4, ent.viewheight - 22 ];
	vector start = P_ProjectSource2 (ent, ent.s.origin, offset, forward, right, up);

	float timer = (ent.client.grenade_framenum - level.framenum) * FRAMETIME;
	int speed = (int)(GRENADE_MINSPEED + (GRENADE_TIMER - timer) * ((GRENADE_MAXSPEED - GRENADE_MINSPEED) / GRENADE_TIMER));
	if (speed > GRENADE_MAXSPEED)
		speed = GRENADE_MAXSPEED;

	fire_tesla (ent, start, forward, damage_multiplier, speed);

	if (!(dmflags.intVal & DF_INFINITE_AMMO))
		ent.client.pers.inventory[ent.client.ammo_index]--;

	ent.client.grenade_framenum = level.framenum + (1 * BASE_FRAMERATE);

	if (ent.deadflag || ent.s.modelindex != 255) // VWep animations screw up corpses
		return;

	if (ent.health <= 0)
		return;

	if (ent.client.ps.pmove.pm_flags & PMF_DUCKED)
	{
		ent.client.anim_priority = ANIM_ATTACK;
		ent.s.frame = FRAME_crattak1-1;
		ent.client.anim_end = FRAME_crattak3;
	}
	else
	{
		ent.client.anim_priority = ANIM_REVERSE;
		ent.s.frame = FRAME_wave08;
		ent.client.anim_end = FRAME_wave01;
	}
}

API_FUNC void(entity ent) Weapon_Tesla =
{
	PROGS_LOCAL_STATIC int(int frame) is_pause_frame =
	{
		return frame == 21;
	}

	if ((ent.client.ps.gunframe > 1) && (ent.client.ps.gunframe < 9))
		ent.client.ps.gunindex = gi.modelindex  ("models/weapons/v_tesla2/tris.md2");
	else
		ent.client.ps.gunindex = gi.modelindex  ("models/weapons/v_tesla/tris.md2");

	Throw_Generic (ent, 8, 32, 99, 1, 2, is_pause_frame, weapon_tesla_fire);
}

//
// CHAINFIST
//
static const int CHAINFIST_REACH = 64;

static void(entity ent) weapon_chainfist_fire =
{
#ifdef SINGLE_PLAYER
	int	damage;

	if !(deathmatch.intVal)
		damage = 15;
	else
		damage = 30;
#else
	int damage = 30;
#endif

	if (is_quad)
		damage *= damage_multiplier;

	vector forward, right, up;
	AngleVectors (ent.client.v_angle, &forward, &right, &up);

	// kick back
	ent.client.kick_origin = forward * -2;
	ent.client.kick_angles[0] = -1f;

	// set start point
	vector offset = [ 0, 8, ent.viewheight - 4 ];
	vector start = P_ProjectSource (ent, ent.s.origin, offset, forward, right);

	fire_player_melee (ent, start, forward, CHAINFIST_REACH, damage, 100, MOD_CHAINFIST);
#if defined(SINGLE_PLAYER)

	PlayerNoise(ent, start, PNOISE_WEAPON);
#endif

	ent.client.ps.gunframe++;
	if (!(dmflags.intVal & DF_INFINITE_AMMO))
		ent.client.pers.inventory[ent.client.ammo_index] -= ent.client.pers.weapon->quantity;
}

// this spits out some smoke from the motor. it's a two-stroke, you know.
static void(entity ent) chainfist_smoke =
{
	vector forward, right, up;
	AngleVectors(ent.client.v_angle, &forward, &right, &up);

	vector offset = [ 8, 8, ent.viewheight - 4 ];
	vector v = P_ProjectSource (ent, ent.s.origin, offset, forward, right);

	gi.WriteByte (svc_temp_entity);
	gi.WriteByte (TE_CHAINFIST_SMOKE);
	gi.WritePosition (v);
	gi.unicast (ent, 0);
}

API_FUNC void(entity ent) Weapon_ChainFist =
{
	PROGS_LOCAL_STATIC int(int frame) is_fire_frame =
	{
		return frame == 8 || frame == 9 || frame == 16 || frame == 17 || frame == 18 || frame == 30 || frame == 31;
	}

	if (ent.client.ps.gunframe == 13 || ent.client.ps.gunframe == 23)			// end of attack, go idle
		ent.client.ps.gunframe = 32;
	// holds for idle sequence
	else if (ent.client.ps.gunframe == 42 && (Q_rand() & 7))
	{
		if ((ent.client.pers.hand != CENTER_HANDED) && random() < 0.4)
			chainfist_smoke(ent);
	}
	else if (ent.client.ps.gunframe == 51 && (Q_rand() & 7))
	{
		if ((ent.client.pers.hand != CENTER_HANDED) && random() < 0.4)
			chainfist_smoke(ent);
	}	

	// set the appropriate weapon sound.
	if (ent.client.weaponstate == WEAPON_FIRING)
		ent.client.weapon_sound = gi.soundindex("weapons/sawhit.wav");
	else if (ent.client.weaponstate == WEAPON_DROPPING)
		ent.client.weapon_sound = 0;
	else
		ent.client.weapon_sound = gi.soundindex("weapons/sawidle.wav");

	Weapon_Generic (ent, 4, 32, 57, 60, 0, is_fire_frame, weapon_chainfist_fire);

	int last_sequence = 0;

	if (ent.client.buttons & BUTTON_ATTACK)
	{
		if (ent.client.ps.gunframe == 13 ||
			ent.client.ps.gunframe == 23 ||
			ent.client.ps.gunframe == 32)
		{
			last_sequence = ent.client.ps.gunframe;
			ent.client.ps.gunframe = 6;
		}
	}

	if (ent.client.ps.gunframe == 6)
	{
		float chance = random();

		if (last_sequence == 13)		// if we just did sequence 1, do 2 or 3.
			chance -= 0.34;
		else if (last_sequence == 23)	// if we just did sequence 2, do 1 or 3
			chance += 0.33;
		else if (last_sequence == 32)	// if we just did sequence 3, do 1 or 2
		{
			if (chance >= 0.33)
				chance += 0.34;
		}

		if (chance < 0.33)
			ent.client.ps.gunframe = 14;
		else if (chance < 0.66)
			ent.client.ps.gunframe = 24;
	}
}

//
// Disintegrator
//
static void(entity self) weapon_tracker_fire =
{
#ifdef SINGLE_PLAYER
	int	 damage;

	if !(deathmatch.intVal)
		damage = 45;
	else
		damage = 30;
#else
	int damage = 30;
#endif

	if (is_quad)
		damage *= damage_multiplier;		//pgm

	vector forward, right;
	AngleVectors (self.client.v_angle, &forward, &right, 0);

	vector offset = [ 24, 8, self.viewheight - 8 ];
	vector start = P_ProjectSource (self, self.s.origin, offset, forward, right);
	vector end = start + (forward * 8192);
	entity enemy = 0;

	trace_t tr;
	gi.traceline (&tr, start, end, self, MASK_SHOT);

	if (tr.ent == world)
		gi.trace (&tr, start, '-16 -16 -16', '16 16 16', end, self, MASK_SHOT);

	if (tr.ent != world)
		if (tr.ent.svflags & SVF_MONSTER || tr.ent.is_client || tr.ent.svflags & SVF_DAMAGEABLE)
			if (tr.ent.health > 0)
				enemy = tr.ent;

	self.client.kick_origin = forward * -2;
	self.client.kick_angles[0] = -1f;

	fire_tracker (self, start, forward, damage, 1000, enemy);

	// send muzzle flash
	gi.WriteByte (svc_muzzleflash);
	gi.WriteShort (self.s.number);
	gi.WriteByte (MZ_TRACKER);
	gi.multicast (self.s.origin, MULTICAST_PVS);
#if defined(SINGLE_PLAYER)

	PlayerNoise(self, start, PNOISE_WEAPON);
#endif

	self.client.ps.gunframe++;
	if (!(dmflags.intVal & DF_INFINITE_AMMO))
		self.client.pers.inventory[self.client.ammo_index] -= self.client.pers.weapon->quantity;
}

API_FUNC void(entity ent) Weapon_Disintegrator =
{
	PROGS_LOCAL_STATIC int(int frame) is_pause_frame =
	{
		return frame == 14 || frame == 19 || frame == 23;
	}

	PROGS_LOCAL_STATIC int(int frame) is_fire_frame =
	{
		return frame == 5;
	}

	Weapon_Generic (ent, 4, 9, 29, 34, is_pause_frame, is_fire_frame, weapon_tracker_fire);
}

/*
======================================================================

ETF RIFLE

======================================================================
*/
static void(entity ent) weapon_etf_rifle_fire =
{
	// PGM - adjusted to use the quantity entry in the weapon structure.
	if(ent.client.pers.inventory[ent.client.ammo_index] < ent.client.pers.weapon->quantity)
	{
		ent.client.kick_origin = ent.client.kick_angles = vec3_origin;
		ent.client.ps.gunframe = 8;

		if (level.framenum >= ent.pain_debounce_framenum)
		{
			gi.sound(ent, CHAN_VOICE, gi.soundindex("weapons/noammo.wav"), 1, ATTN_NORM, 0);
			ent.pain_debounce_framenum = level.framenum + (1 * BASE_FRAMERATE);
		}
		NoAmmoWeaponChange (ent);
		return;
	}

	int	damage = 10;
	int	kick = 3;

	if (is_quad)
	{
		damage *= damage_multiplier;
		kick *= damage_multiplier;
	}

	ent.client.kick_origin = randomv('-0.85 -0.85 -0.85', '0.85 0.85 0.85');
	ent.client.kick_angles = randomv('-0.85 -0.85 -0.85', '0.85 0.85 0.85');

	// get start / end positions
	vector angles = ent.client.v_angle + ent.client.kick_angles;
	vector forward, right, up;
	AngleVectors (ent.client.v_angle, &forward, &right, &up);

	vector offset;
	if (ent.client.ps.gunframe == 6)			// right barrel
		offset = [ 15, 8, -8 ];
	else										// left barrel
		offset = [ 15, 6, -8 ];
	
	vector v = ent.s.origin;
	v[2] += ent.viewheight;
	vector start = P_ProjectSource2 (ent, v, offset, forward, right, up);
	fire_flechette (ent, start, forward, damage, 750, kick);

	// send muzzle flash
	gi.WriteByte (svc_muzzleflash);
	gi.WriteShort (ent.s.number);
	gi.WriteByte (MZ_ETF_RIFLE);
	gi.multicast (ent.s.origin, MULTICAST_PVS);
#if defined(SINGLE_PLAYER)

	PlayerNoise(ent, start, PNOISE_WEAPON);
#endif

	ent.client.ps.gunframe++;
	if (!(dmflags.intVal & DF_INFINITE_AMMO))
		ent.client.pers.inventory[ent.client.ammo_index] -= ent.client.pers.weapon->quantity;

	ent.client.anim_priority = ANIM_ATTACK;
	if (ent.client.ps.pmove.pm_flags & PMF_DUCKED)
	{
		ent.s.frame = FRAME_crattak1 - 1;
		ent.client.anim_end = FRAME_crattak9;
	}
	else
	{
		ent.s.frame = FRAME_attack1 - 1;
		ent.client.anim_end = FRAME_attack8;
	}
}

API_FUNC void(entity ent) Weapon_ETF_Rifle =
{
	PROGS_LOCAL_STATIC int(int frame) is_pause_frame =
	{
		return frame == 18 || frame == 28;
	}

	PROGS_LOCAL_STATIC int(int frame) is_fire_frame =
	{
		return frame == 6 || frame == 7;
	}

	if (ent.client.weaponstate == WEAPON_FIRING)
	{
		if (ent.client.pers.inventory[ent.client.ammo_index] <= 0)
			ent.client.ps.gunframe = 8;
	}

	Weapon_Generic (ent, 4, 7, 37, 41, is_pause_frame, is_fire_frame, weapon_etf_rifle_fire);

	if (ent.client.ps.gunframe == 8 && (ent.client.buttons & BUTTON_ATTACK))
		ent.client.ps.gunframe = 6;
}

static void(entity ent) Heatbeam_Fire =
{
	if (ent.client.pers.inventory[ent.client.ammo_index] < ent.client.pers.weapon->quantity)
	{
		ent.client.ps.gunframe++;
		return;
	}

	int	damage = 15;
#ifdef SINGLE_PLAYER
	int kick;

	if !(deathmatch.intVal)  // really knock 'em around in deathmatch
		kick = 30;
	else
		kick = 75;
#else
	int kick = 75;
#endif

	ent.client.ps.gunframe++;
	ent.client.ps.gunindex = gi.modelindex ("models/weapons/v_beamer2/tris.md2");

	if (is_quad)
	{
		damage *= damage_multiplier;
		kick *= damage_multiplier;
	}

	ent.client.kick_origin = ent.client.kick_angles = vec3_origin;

	// get start / end positions
	vector forward, right, up;
	AngleVectors (ent.client.v_angle, &forward, &right, &up);

// This offset is the "view" offset for the beam start (used by trace)
	
	vector offset = [ 7, 2, ent.viewheight-3 ];
	vector start = P_ProjectSource (ent, ent.s.origin, offset, forward, right);

	fire_heatbeam (ent, start, forward, '2 7 -3', damage, kick, false);

	// send muzzle flash
	gi.WriteByte (svc_muzzleflash);
	gi.WriteShort (ent.s.number);
	gi.WriteByte (MZ_HEATBEAM | is_silenced);
	gi.multicast (ent.s.origin, MULTICAST_PVS);
#if defined(SINGLE_PLAYER)

	PlayerNoise(ent, start, PNOISE_WEAPON);
#endif

	if (!(dmflags.intVal & DF_INFINITE_AMMO))
		ent.client.pers.inventory[ent.client.ammo_index] -= ent.client.pers.weapon->quantity;

	ent.client.anim_priority = ANIM_ATTACK;
	if (ent.client.ps.pmove.pm_flags & PMF_DUCKED)
	{
		ent.s.frame = FRAME_crattak1 - 1;
		ent.client.anim_end = FRAME_crattak9;
	}
	else
	{
		ent.s.frame = FRAME_attack1 - 1;
		ent.client.anim_end = FRAME_attack8;
	}

}

API_FUNC void(entity ent) Weapon_Heatbeam =
{
	PROGS_LOCAL_STATIC int(int frame) is_pause_frame =
	{
		return frame == 35;
	}

	PROGS_LOCAL_STATIC int(int frame) is_fire_frame =
	{
		return frame >= 9 || frame <= 12;
	}

	if (ent.client.weaponstate == WEAPON_FIRING)
	{
		ent.client.weapon_sound = gi.soundindex ("weapons/bfg__l1a.wav");
		if ((ent.client.pers.inventory[ent.client.ammo_index] >= ent.client.pers.weapon->quantity) && (ent.client.buttons & BUTTON_ATTACK))
		{
			if (ent.client.ps.gunframe >= 13)
			{
				ent.client.ps.gunframe = 9;
				ent.client.ps.gunindex = gi.modelindex ("models/weapons/v_beamer2/tris.md2");
			}
			else
				ent.client.ps.gunindex = gi.modelindex ("models/weapons/v_beamer2/tris.md2");
		}
		else
		{
			ent.client.ps.gunframe = 13;
			ent.client.ps.gunindex = gi.modelindex ("models/weapons/v_beamer/tris.md2");
		}
	}
	else
	{
		ent.client.ps.gunindex = gi.modelindex ("models/weapons/v_beamer/tris.md2");
		ent.client.weapon_sound = 0;
	}

	Weapon_Generic (ent, 8, 12, 39, 44, is_pause_frame, is_fire_frame, Heatbeam_Fire);
}

#endif