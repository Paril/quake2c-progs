#ifdef THE_RECKONING
// RAFAEL
/*
	RipperGun
*/

PROGS_LOCAL_STATIC void(entity ent) weapon_ionripper_fire =
{
	vector	start;
	vector	forward, right;
	vector	offset;
	vector	tempang;
	int	damage;
	int	kick;

	if (deathmatch.intVal)
	{
		// tone down for deathmatch
		damage = 30;
		kick = 40;
	}
	else
	{
		damage = 50;
		kick = 60;
	}
	
	if (is_quad)
	{
		damage *= damage_multiplier;
		kick *= damage_multiplier;
	}

	tempang = ent.client.v_angle;
	tempang[YAW] += crandom();

	AngleVectors (tempang, &forward, &right, 0);
	
	ent.client.kick_origin = forward * -3;
	ent.client.kick_angles[0] = -3f;

	offset = [ 16, 7, ent.viewheight - 8 ];

	start = P_ProjectSource (ent, ent.s.origin, offset, forward, right);

	fire_ionripper (ent, start, forward, damage, 500, EF_IONRIPPER);

	// send muzzle flash
	gi.WriteByte (svc_muzzleflash);
	gi.WriteShort (ent.s.number);
	gi.WriteByte (MZ_IONRIPPER | is_silenced);
	gi.multicast (ent.s.origin, MULTICAST_PVS);

	ent.client.ps.gunframe++;
	PlayerNoise (ent, start, PNOISE_WEAPON);

	if (!(dmflags.intVal & DF_INFINITE_AMMO))
		ent.client.pers.inventory[ent.client.ammo_index] -= GetItemKeyByIndex(ent.client.pers.weapon, quantity);
	
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
	vector	start;
	vector	forward, right, up;
	vector	offset;
	vector	v;
	int	kick = 12;
	int	damage;
	float	damage_radius;
	int	radius_damage;

	damage = 70 + (int)(random(10.0));
	radius_damage = 120;
	damage_radius = 120f;
	
	if (is_quad)
	{
		damage *= damage_multiplier;
		radius_damage *= damage_multiplier;
	}

	AngleVectors (ent.client.v_angle, &forward, &right, 0);

	ent.client.kick_origin = forward * -2;
	ent.client.kick_angles[0] = -2f;

	offset = [ 0, 8, ent.viewheight - 8 ];
	start = P_ProjectSource (ent, ent.s.origin, offset, forward, right);

	if (ent.client.ps.gunframe == 8)
	{
		v[PITCH] = ent.client.v_angle[PITCH];
		v[YAW]   = ent.client.v_angle[YAW] - 1.5;
		v[ROLL]  = ent.client.v_angle[ROLL];
		AngleVectors (v, &forward, &right, &up);
		
		radius_damage = 30;
		damage_radius = 120f;
	
		fire_plasma (ent, start, forward, damage, 725, damage_radius, radius_damage);

		if (!(dmflags.intVal & DF_INFINITE_AMMO))
			ent.client.pers.inventory[ent.client.ammo_index]--;
	}
	else
	{
		v[PITCH] = ent.client.v_angle[PITCH];
		v[YAW]   = ent.client.v_angle[YAW] + 1.5;
		v[ROLL]  = ent.client.v_angle[ROLL];
		AngleVectors (v, &forward, &right, &up);
		fire_plasma (ent, start, forward, damage, 725, damage_radius, radius_damage);

		// send muzzle flash
		gi.WriteByte (svc_muzzleflash);
		gi.WriteShort (ent.s.number);
		gi.WriteByte (MZ_PHALANX | is_silenced);
		gi.multicast (ent.s.origin, MULTICAST_PVS);
		
		PlayerNoise(ent, start, PNOISE_WEAPON);
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
	vector	offset;
	vector	forward, right;
	vector	start;
	int	damage = 125;
	float	timer;
	int	speed;
	float	radius;

	radius = damage + 40f;
	if (is_quad)
		damage *= damage_multiplier;

	offset = [ 8, 8, ent.viewheight - 8 ];
	AngleVectors (ent.client.v_angle, &forward, &right, 0);
	start = P_ProjectSource (ent, ent.s.origin, offset, forward, right);

	timer = (ent.client.trap_framenum - level.framenum) * FRAMETIME;
	speed = (int)(TRAP_MINSPEED + (TRAP_TIMER - timer) * ((TRAP_MAXSPEED - TRAP_MINSPEED) / TRAP_TIMER));
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
		if ( ((ent.client.latched_buttons|ent.client.buttons) & BUTTON_ATTACK) )
		{
			ent.client.latched_buttons &= ~BUTTON_ATTACK;
			if (ent.client.pers.inventory[ent.client.ammo_index])
			{
				ent.client.ps.gunframe = 1;
				ent.client.weaponstate = WEAPON_FIRING;
				ent.client.trap_framenum = 0;
			}
			else
			{
				if (level.framenum >= ent.pain_debounce_framenum)
				{
					gi.sound(ent, CHAN_VOICE, gi.soundindex("weapons/noammo.wav"), 1, ATTN_NORM, 0);
					ent.pain_debounce_framenum = level.framenum + 1 * BASE_FRAMERATE;
				}
				NoAmmoWeaponChange (ent);
			}
			return;
		}

		if ((ent.client.ps.gunframe == 29) || (ent.client.ps.gunframe == 34) || (ent.client.ps.gunframe == 39) || (ent.client.ps.gunframe == 48))
		{
			if (Q_rand()&15)
				return;
		}

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
				weapon_trap_fire (ent, true);
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