#ifdef THE_RECKONING
// RAFAEL
/*
	RipperGun
*/

PROGS_LOCAL_STATIC void(entity ent) weapon_ionripper_fire =
{
#ifdef SINGLE_PLAYER
	int	damage;
	int	kick;

	if !(deathmatch.intVal)
	{
		damage = 50;
		kick = 60;
	}
	else
	{
		// tone down for deathmatch
		damage = 30;
		kick = 40;
	}
#else
	int damage = 30;
	int kick = 40;
#endif
	
	if (is_quad)
	{
		damage *= damage_multiplier;
		kick *= damage_multiplier;
	}

	vector tempang = ent.client.v_angle;
	tempang[YAW] += crandom();

	vector forward, right;
	AngleVectors (tempang, &forward, &right, 0);
	
	ent.client.kick_origin = forward * -3;
	ent.client.kick_angles[0] = -3f;

	vector offset = [ 16, 7, ent.viewheight - 8 ];
	vector start = P_ProjectSource (ent, ent.s.origin, offset, forward, right);

	fire_ionripper (ent, start, forward, damage, 500, EF_IONRIPPER);

	// send muzzle flash
	gi.WriteByte (svc_muzzleflash);
	gi.WriteShort (ent.s.number);
	gi.WriteByte (MZ_IONRIPPER | is_silenced);
	gi.multicast (ent.s.origin, MULTICAST_PVS);

	ent.client.ps.gunframe++;
#ifdef SINGLE_PLAYER
	PlayerNoise (ent, start, PNOISE_WEAPON);
#endif

	if (!(dmflags.intVal & DF_INFINITE_AMMO))
		ent.client.pers.inventory[ent.client.ammo_index] -= ent.client.pers.weapon->quantity;
	
	if (ent.client.pers.inventory[ent.client.ammo_index] < 0)
		ent.client.pers.inventory[ent.client.ammo_index] = 0;
}

void(entity ent) Weapon_Ionripper =
{
	PROGS_LOCAL_STATIC int(int frame) is_pause_frame =
	{
		return frame == 36;
	}
	
	PROGS_LOCAL_STATIC int(int frame) is_fire_frame = 
	{
		return frame == 5;
	}

	Weapon_Generic (ent, 4, 6, 36, 39, is_pause_frame, is_fire_frame, weapon_ionripper_fire);
}

// 
//	Phalanx
//

PROGS_LOCAL_STATIC void(entity ent) weapon_phalanx_fire =
{
	int	kick = 12;
	int damage = 70 + (int)(random(10.0));
	int radius_damage = 120;
	float damage_radius = 120f;
	
	if (is_quad)
	{
		damage *= damage_multiplier;
		radius_damage *= damage_multiplier;
	}

	vector forward, right;
	AngleVectors (ent.client.v_angle, &forward, &right, 0);

	ent.client.kick_origin = forward * -2;
	ent.client.kick_angles[0] = -2f;

	vector offset = [ 0, 8, ent.viewheight - 8 ];
	vector start = P_ProjectSource (ent, ent.s.origin, offset, forward, right);

	if (ent.client.ps.gunframe == 8)
	{
		vector v = [ent.client.v_angle[PITCH],
					ent.client.v_angle[YAW] - 1.5,
					ent.client.v_angle[ROLL]];

		vector up;
		AngleVectors (v, &forward, &right, &up);
		
		radius_damage = 30;
		damage_radius = 120f;
	
		fire_plasma (ent, start, forward, damage, 725, damage_radius, radius_damage);

		if (!(dmflags.intVal & DF_INFINITE_AMMO))
			ent.client.pers.inventory[ent.client.ammo_index]--;
	}
	else
	{
		vector v = [ent.client.v_angle[PITCH],
					ent.client.v_angle[YAW] + 1.5,
					ent.client.v_angle[ROLL]];

		vector up;
		AngleVectors (v, &forward, &right, &up);

		fire_plasma (ent, start, forward, damage, 725, damage_radius, radius_damage);

		// send muzzle flash
		gi.WriteByte (svc_muzzleflash);
		gi.WriteShort (ent.s.number);
		gi.WriteByte (MZ_PHALANX | is_silenced);
		gi.multicast (ent.s.origin, MULTICAST_PVS);
#ifdef SINGLE_PLAYER
		
		PlayerNoise(ent, start, PNOISE_WEAPON);
#endif
	}
	
	ent.client.ps.gunframe++;
	
}

void(entity ent) Weapon_Phalanx =
{
	PROGS_LOCAL_STATIC int(int frame) is_pause_frame =
	{
		return frame == 29 || frame == 42 || frame == 55;
	}
	
	PROGS_LOCAL_STATIC int(int frame) is_fire_frame = 
	{
		return frame == 7 || frame == 8;
	}

	Weapon_Generic (ent, 5, 20, 58, 63, is_pause_frame, is_fire_frame, weapon_phalanx_fire);
}

/*
======================================================================

TRAP

======================================================================
*/

// Paril: these constants were unused in Xatrix originally
const float TRAP_TIMER	= GRENADE_TIMER;
const int TRAP_MINSPEED	= GRENADE_MINSPEED;
const int TRAP_MAXSPEED	= GRENADE_MAXSPEED;

PROGS_LOCAL void(entity ent, bool held) weapon_trap_fire =
{
	int	damage = 125;
	float radius = damage + 40f;

	if (is_quad)
		damage *= damage_multiplier;

	vector offset = [ 8, 8, ent.viewheight - 8 ];
	vector forward, right;
	AngleVectors (ent.client.v_angle, &forward, &right, 0);
	vector start = P_ProjectSource (ent, ent.s.origin, offset, forward, right);

	float timer = (ent.client.trap_framenum - level.framenum) * FRAMETIME;
	int speed = (int)(TRAP_MINSPEED + (TRAP_TIMER - timer) * ((TRAP_MAXSPEED - TRAP_MINSPEED) / TRAP_TIMER));
	fire_trap (ent, start, forward, damage, speed, timer, radius, held);

	ent.client.pers.inventory[ent.client.ammo_index]--;

	ent.client.trap_framenum = (int)(level.framenum + 1.0f * BASE_FRAMERATE);
}

void(entity ent) Weapon_Trap =
{
	if ((ent.client.newweapon) && (ent.client.weaponstate == WEAPON_READY))
	{
		ChangeWeapon (ent);
		return;
	}

	if (ent.client.weaponstate == WEAPON_ACTIVATING)
	{
		ent.client.weaponstate = WEAPON_READY;
		ent.client.ps.gunframe = 16;
		return;
	}

	if (ent.client.weaponstate == WEAPON_READY)
	{
		if ((ent.client.latched_buttons|ent.client.buttons) & BUTTON_ATTACK)
		{
			ent.client.latched_buttons &= ~BUTTON_ATTACK;

			if (ent.client.pers.inventory[ent.client.ammo_index])
			{
				ent.client.ps.gunframe = 1;
				ent.client.weaponstate = WEAPON_FIRING;
				ent.client.trap_framenum = 0;
				return;
			}

			if (level.framenum >= ent.pain_debounce_framenum)
			{
				gi.sound(ent, CHAN_VOICE, gi.soundindex("weapons/noammo.wav"), 1, ATTN_NORM, 0);
				ent.pain_debounce_framenum = level.framenum + 1 * BASE_FRAMERATE;
			}

			NoAmmoWeaponChange (ent);
			return;
		}

		if ((ent.client.ps.gunframe == 29) || (ent.client.ps.gunframe == 34) || (ent.client.ps.gunframe == 39) || (ent.client.ps.gunframe == 48))
			if (Q_rand() & 15)
				return;

		if (++ent.client.ps.gunframe > 48)
			ent.client.ps.gunframe = 16;
		return;
	}

	if (ent.client.weaponstate == WEAPON_FIRING)
	{
		if (ent.client.ps.gunframe == 5)
			gi.sound(ent, CHAN_WEAPON, gi.soundindex("weapons/trapcock.wav"), 1, ATTN_NORM, 0);

		if (ent.client.ps.gunframe == 11)
		{
			if (!ent.client.trap_framenum)
			{
				ent.client.trap_framenum = (int)(level.framenum + (TRAP_TIMER + 0.2f) * BASE_FRAMERATE);
				ent.client.weapon_sound = gi.soundindex("weapons/traploop.wav");
			}

			// they waited too long, detonate it in their hand
			if (!ent.client.grenade_blew_up && level.framenum >= ent.client.trap_framenum)
			{
				ent.client.weapon_sound = 0;
				weapon_trap_fire(ent, true);
				ent.client.grenade_blew_up = true;
			}

			if (ent.client.buttons & BUTTON_ATTACK)
				return;

			if (ent.client.grenade_blew_up)
			{
				if (level.framenum >= ent.client.grenade_framenum)
				{
					ent.client.ps.gunframe = 15;
					ent.client.grenade_blew_up = false;
				}
				else
					return;
			}
		}

		if (ent.client.ps.gunframe == 12)
		{
			ent.client.weapon_sound = 0;
			weapon_trap_fire (ent, false);
			if (ent.client.pers.inventory[ent.client.ammo_index] == 0)
				NoAmmoWeaponChange (ent);
		}

		if ((ent.client.ps.gunframe == 15) && (level.framenum < ent.client.trap_framenum))
			return;

		ent.client.ps.gunframe++;

		if (ent.client.ps.gunframe == 16)
		{
			ent.client.trap_framenum = 0;
			ent.client.weaponstate = WEAPON_READY;
		}
	}
}

#endif