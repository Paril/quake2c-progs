#include "m_player.h"

// view pitching times
const float DAMAGE_TIME	= 0.5f;
const float FALL_TIME	= 0.3f;

PROGS_LOCAL static entity current_player;
PROGS_LOCAL static vector forward, right, up;
PROGS_LOCAL static float xyspeed, bobmove, bobfracsin;
PROGS_LOCAL static int bobcycle;

/*
=============
P_WorldEffects
=============
*/
static void(void) P_WorldEffects =
{
	bool        breather;
	bool        envirosuit;
	int         current_waterlevel, old_waterlevel;

	if (current_player.movetype == MOVETYPE_NOCLIP) {
		current_player.air_finished_framenum = level.framenum + 12 * BASE_FRAMERATE; // don't need air
		return;
	}

	current_waterlevel = current_player.waterlevel;
	old_waterlevel = current_player.client.old_waterlevel;
	current_player.client.old_waterlevel = current_waterlevel;

	breather = (bool)(current_player.client.breather_framenum > level.framenum);
	envirosuit = (bool)(current_player.client.enviro_framenum > level.framenum);

	//
	// if just entered a water volume, play a sound
	//
	if (!old_waterlevel && current_waterlevel) {
		PlayerNoise(current_player, current_player.s.origin, PNOISE_SELF);
		if (current_player.watertype & CONTENTS_LAVA)
			gi.sound(current_player, CHAN_BODY, gi.soundindex("player/lava_in.wav"), 1, ATTN_NORM, 0);
		else if (current_player.watertype & CONTENTS_SLIME)
			gi.sound(current_player, CHAN_BODY, gi.soundindex("player/watr_in.wav"), 1, ATTN_NORM, 0);
		else if (current_player.watertype & CONTENTS_WATER)
			gi.sound(current_player, CHAN_BODY, gi.soundindex("player/watr_in.wav"), 1, ATTN_NORM, 0);
		current_player.flags |= FL_INWATER;

		// clear damage_debounce, so the pain sound will play immediately
		current_player.damage_debounce_framenum = level.framenum - 1 * BASE_FRAMERATE;
	}

	//
	// if just completely exited a water volume, play a sound
	//
	if (old_waterlevel && !current_waterlevel) {
		PlayerNoise(current_player, current_player.s.origin, PNOISE_SELF);
		gi.sound(current_player, CHAN_BODY, gi.soundindex("player/watr_out.wav"), 1, ATTN_NORM, 0);
		current_player.flags &= ~FL_INWATER;
	}

	//
	// check for head just going under water
	//
	if (old_waterlevel != 3 && current_waterlevel == 3) {
		gi.sound(current_player, CHAN_BODY, gi.soundindex("player/watr_un.wav"), 1, ATTN_NORM, 0);
	}

	//
	// check for head just coming out of water
	//
	if (old_waterlevel == 3 && current_waterlevel != 3) {
		if (current_player.air_finished_framenum < level.framenum) {
			// gasp for air
			gi.sound(current_player, CHAN_VOICE, gi.soundindex("player/gasp1.wav"), 1, ATTN_NORM, 0);
			PlayerNoise(current_player, current_player.s.origin, PNOISE_SELF);
		} else  if (current_player.air_finished_framenum < level.framenum + 11 * BASE_FRAMERATE) {
			// just break surface
			gi.sound(current_player, CHAN_VOICE, gi.soundindex("player/gasp2.wav"), 1, ATTN_NORM, 0);
		}
	}

	//
	// check for drowning
	//
	if (current_waterlevel == 3) {
		// breather or envirosuit give air
		if (breather || envirosuit) {
			current_player.air_finished_framenum = level.framenum + 10 * BASE_FRAMERATE;

			if (((int)(current_player.client.breather_framenum - level.framenum) % 25) == 0) {
				if (!current_player.client.breather_sound)
					gi.sound(current_player, CHAN_AUTO, gi.soundindex("player/u_breath1.wav"), 1, ATTN_NORM, 0);
				else
					gi.sound(current_player, CHAN_AUTO, gi.soundindex("player/u_breath2.wav"), 1, ATTN_NORM, 0);
				current_player.client.breather_sound ^= 1;
				PlayerNoise(current_player, current_player->s.origin, PNOISE_SELF);
			}
		}

		// if out of air, start drowning
		if (current_player.air_finished_framenum < level.framenum) {
			// drown!
			if (current_player.client->next_drown_framenum < level.framenum
				&& current_player.health > 0) {
				current_player.client.next_drown_framenum = level.framenum + 1 * BASE_FRAMERATE;

				// take more damage the longer underwater
				current_player.dmg += 2;
				if (current_player.dmg > 15)
					current_player.dmg = 15;

				// play a gurp sound instead of a normal pain sound
				if (current_player.health <= current_player.dmg)
					gi.sound(current_player, CHAN_VOICE, gi.soundindex("player/drown1.wav"), 1, ATTN_NORM, 0);
				else if (Q_rand() & 1)
					gi.sound(current_player, CHAN_VOICE, gi.soundindex("*gurp1.wav"), 1, ATTN_NORM, 0);
				else
					gi.sound(current_player, CHAN_VOICE, gi.soundindex("*gurp2.wav"), 1, ATTN_NORM, 0);

				current_player.pain_debounce_framenum = level.framenum;

				T_Damage(current_player, world, world, vec3_origin, current_player.s.origin, vec3_origin, current_player.dmg, 0, DAMAGE_NO_ARMOR, MOD_WATER);
			}
		}
	} else {
		current_player.air_finished_framenum = level.framenum + 12 * BASE_FRAMERATE;
		current_player.dmg = 2;
	}

	//
	// check for sizzle damage
	//
	if (current_waterlevel && (current_player.watertype & (CONTENTS_LAVA | CONTENTS_SLIME))) {
		if (current_player.watertype & CONTENTS_LAVA) {
			if (current_player.health > 0
				&& current_player.pain_debounce_framenum <= level.framenum
				&& current_player.client.invincible_framenum < level.framenum) {
				if (Q_rand() & 1)
					gi.sound(current_player, CHAN_VOICE, gi.soundindex("player/burn1.wav"), 1, ATTN_NORM, 0);
				else
					gi.sound(current_player, CHAN_VOICE, gi.soundindex("player/burn2.wav"), 1, ATTN_NORM, 0);
				current_player.pain_debounce_framenum = level.framenum + 1 * BASE_FRAMERATE;
			}

			if (envirosuit) // take 1/3 damage with envirosuit
				T_Damage(current_player, world, world, vec3_origin, current_player.s.origin, vec3_origin, 1 * current_waterlevel, 0, 0, MOD_LAVA);
			else
				T_Damage(current_player, world, world, vec3_origin, current_player.s.origin, vec3_origin, 3 * current_waterlevel, 0, 0, MOD_LAVA);
		}

		if (current_player->watertype & CONTENTS_SLIME) {
			if (!envirosuit) {
				// no damage from slime with envirosuit
				T_Damage(current_player, world, world, vec3_origin, current_player->s.origin, vec3_origin, 1 * current_waterlevel, 0, 0, MOD_SLIME);
			}
		}
	}
}
/*
===============
SV_CalcRoll

===============
*/
static float(vector angles, vector velocity) SV_CalcRoll =
{
	float   sign;
	float   side;
	float   value;

	side = velocity * right;
	sign = side < 0f ? -1f : 1f;
	side = fabsf(side);

	value = sv_rollangle.floatVal;

	if (side < sv_rollspeed.floatVal)
		side = side * value / sv_rollspeed.floatVal;
	else
		side = value;

	return side * sign;

}

/*
=================
P_FallingDamage
=================
*/
static void(entity ent) P_FallingDamage =
{
	float	delta;
	int	damage;
	vector	dir;

	if (ent.s.modelindex != 255)
		return;     // not in the player model

	if (ent.movetype == MOVETYPE_NOCLIP)
		return;

	if ((ent.client.oldvelocity[2] < 0f) && (ent.velocity[2] > ent.client.oldvelocity[2]) && (ent.groundentity == null_entity)) {
		delta = ent.client.oldvelocity[2];
	} else {
		if (ent.groundentity == null_entity)
			return;
		delta = ent.velocity_z - ent.client.oldvelocity[2];
	}
	delta = delta * delta * 0.0001f;

	// never take falling damage if completely underwater
	if (ent.waterlevel == 3)
		return;
	if (ent.waterlevel == 2)
		delta *= 0.25f;
	if (ent.waterlevel == 1)
		delta *= 0.5f;

	if (delta < 1)
		return;

	if (delta < 15) {
		ent.s.event = EV_FOOTSTEP;
		return;
	}

	ent.client.fall_value = delta * 0.5f;
	if (ent.client.fall_value > 40)
		ent.client.fall_value = 40f;
	ent.client.fall_time = level.time + FALL_TIME;

	if (delta > 30) {
		if (ent.health > 0) {
			if (delta >= 55)
				ent.s.event = EV_FALLFAR;
			else
				ent.s.event = EV_FALL;
		}
		ent.pain_debounce_framenum = level.framenum;   // no normal pain sound
		damage = (int)((delta - 30) / 2);
		if (damage < 1)
			damage = 1;
		dir = '0 0 1';

		if (!deathmatch.intVal || !(dmflags.intVal & DF_NO_FALLING))
			T_Damage(ent, world, world, dir, ent->s.origin, vec3_origin, damage, 0, 0, MOD_FALLING);
	} else {
		ent.s.event = EV_FALLSHORT;
		return;
	}
}

const vector power_color = '0.0 1.0 0.0';
const vector acolor = '1.0 1.0 1.0';
const vector bcolor = '1.0 0.0 0.0';

/*
===============
P_DamageFeedback

Handles color blends and view kicks
===============
*/
static void(entity player) P_DamageFeedback =
{
	float   side;
	float   realcount, dcount, kick;
	vector  v;
	int     r, l;

	// flash the backgrounds behind the status numbers
	player.client.ps.stats[STAT_FLASHES] = 0;
	if (player.client.damage_blood)
		player.client.ps.stats[STAT_FLASHES] |= 1;
	if (player.client.damage_armor && !(player.flags & FL_GODMODE) && (player.client.invincible_framenum <= level.framenum))
		player.client.ps.stats[STAT_FLASHES] |= 2;

	// total points of damage shot at the player this frame
	dcount = (float)(player.client.damage_blood + player.client.damage_armor + player.client.damage_parmor);
	if (dcount == 0)
		return;     // didn't take any damage

	// start a pain animation if still in the player model
	if (player.client.anim_priority < ANIM_PAIN && player.s.modelindex == 255) {
		static int      i;

		player.client.anim_priority = ANIM_PAIN;
		if (player.client.ps.pmove.pm_flags & PMF_DUCKED) {
			player.s.frame = FRAME_crpain1 - 1;
			player.client.anim_end = FRAME_crpain4;
		} else {
			i = (i + 1) % 3;
			switch (i) {
			case 0:
				player.s.frame = FRAME_pain101 - 1;
				player.client.anim_end = FRAME_pain104;
				break;
			case 1:
				player.s.frame = FRAME_pain201 - 1;
				player.client.anim_end = FRAME_pain204;
				break;
			case 2:
				player.s.frame = FRAME_pain301 - 1;
				player.client.anim_end = FRAME_pain304;
				break;
			}
		}
	}

	realcount = dcount;
	if (dcount < 10)
		dcount = 10f; // always make a visible effect

	// play an apropriate pain sound
	if ((level.framenum > player.pain_debounce_framenum) && !(player.flags & FL_GODMODE) && (player.client.invincible_framenum <= level.framenum)) {
		r = 1 + (Q_rand() & 1);
		player.pain_debounce_framenum = (int)(level.framenum + 0.7f * BASE_FRAMERATE);
		if (player.health < 25)
			l = 25;
		else if (player.health < 50)
			l = 50;
		else if (player.health < 75)
			l = 75;
		else
			l = 100;
		gi.sound(player, CHAN_VOICE, gi.soundindex(va("*pain%i_%i.wav", l, r)), 1, ATTN_NORM, 0);
	}

	// the total alpha of the blend is always proportional to count
	if (player.client.damage_alpha < 0)
		player.client.damage_alpha = 0;
	player.client.damage_alpha += dcount * 0.01f;
	if (player.client.damage_alpha < 0.2f)
		player.client.damage_alpha = 0.2f;
	if (player.client.damage_alpha > 0.6f)
		player.client.damage_alpha = 0.6f;    // don't go too saturated

	// the color of the blend will vary based on how much was absorbed
	// by different armors
	v = vec3_origin;
	if (player.client.damage_parmor)
		v += ((float)player.client.damage_parmor / realcount * power_color);
	if (player.client.damage_armor)
		v += ((float)player.client.damage_armor / realcount *  acolor);
	if (player.client.damage_blood)
		v += ((float)player.client.damage_blood / realcount *  bcolor);
	player.client.damage_blend = v;


	//
	// calculate view angle kicks
	//
	kick = fabsf(player.client.damage_knockback);
	if (kick && player.health > 0) { // kick of 0 means no view adjust at all
		kick = kick * 100 / player.health;

		if (kick < dcount * 0.5f)
			kick = dcount * 0.5f;
		if (kick > 50)
			kick = 50f;

		v = player.client.damage_from - player.s.origin;
		VectorNormalize(v);

		side = v * right;
		player.client.v_dmg_roll = kick * side * 0.3f;

		side = -(v * forward);
		player.client.v_dmg_pitch = kick * side * 0.3f;

		player.client.v_dmg_time = level.time + DAMAGE_TIME;
	}

	//
	// clear totals
	//
	player.client.damage_blood = 0;
	player.client.damage_armor = 0;
	player.client.damage_parmor = 0;
	player.client.damage_knockback = 0;
}

/*
===============
SV_CalcViewOffset

Auto pitching on slopes?

  fall from 128: 400 = 160000
  fall from 256: 580 = 336400
  fall from 384: 720 = 518400
  fall from 512: 800 = 640000
  fall from 640: 960 =

  damage = deltavelocity*deltavelocity  * 0.0001

===============
*/
static void(entity ent) SV_CalcViewOffset =
{
	float	bob;
	float	ratio;
	float	delta;
	vector	v;

//===================================

	// if dead, fix the angle and don't add any kick
	if (ent->deadflag) {
		ent.client.ps.kick_angles = vec3_origin;

		ent.client.ps.viewangles[ROLL] = 40f;
		ent.client.ps.viewangles[PITCH] = -15f;
		ent.client.ps.viewangles[YAW] = ent.client.killer_yaw;
	} else {
		// add angles based on weapon kick

		ent.client.ps.kick_angles = ent.client.kick_angles;

		// add angles based on damage kick

		ratio = (ent.client.v_dmg_time - level.time) / DAMAGE_TIME;
		if (ratio < 0) {
			ratio = 0;
			ent.client.v_dmg_pitch = 0;
			ent.client.v_dmg_roll = 0;
		}
		ent.client.ps.kick_angles[PITCH] += ratio * ent.client.v_dmg_pitch;
		ent.client.ps.kick_angles[ROLL] += ratio * ent.client.v_dmg_roll;

		// add pitch based on fall kick

		ratio = (ent.client.fall_time - level.time) / FALL_TIME;
		if (ratio < 0)
			ratio = 0;
		ent.client.ps.kick_angles[PITCH] += ratio * ent.client.fall_value;

		// add angles based on velocity

		delta = ent.velocity * forward;
		ent.client.ps.kick_angles[PITCH] += delta * run_pitch.floatVal;

		delta = ent.velocity * right;
		ent.client.ps.kick_angles[ROLL] += delta * run_roll.floatVal;

		// add angles based on bob

		delta = bobfracsin * bob_pitch.floatVal * xyspeed;
		if (ent.client.ps.pmove.pm_flags & PMF_DUCKED)
			delta *= 6;     // crouching
		ent.client.ps.kick_angles[PITCH] += delta;
		delta = bobfracsin * bob_roll.floatVal * xyspeed;
		if (ent->client->ps.pmove.pm_flags & PMF_DUCKED)
			delta *= 6;     // crouching
		if (bobcycle & 1)
			delta = -delta;
		ent.client.ps.kick_angles[ROLL] += delta;
	}

//===================================

	// base origin

	v = vec3_origin;

	// add view height

	v_z += ent.viewheight;

	// add fall height

	ratio = (ent.client.fall_time - level.time) / FALL_TIME;
	if (ratio < 0)
		ratio = 0;
	v_z -= ratio * ent.client.fall_value * 0.4f;

	// add bob height

	bob = bobfracsin * xyspeed * bob_up.floatVal;
	if (bob > 6)
		bob = 6f;

	v_z += bob;

	// add kick offset
	v += ent.client.kick_origin;

	// absolutely bound offsets
	// so the view can never be outside the player box
	if (v_x < -14)
		v_x = -14f;
	else if (v_x > 14)
		v_x = 14f;
	if (v_y < -14)
		v_y = -14f;
	else if (v_y > 14)
		v_y = 14f;
	if (v_z < -22)
		v_z = -22f;
	else if (v_z > 30)
		v_z = 30f;

	ent.client.ps.viewoffset = v;
}

/*
==============
SV_CalcGunOffset
==============
*/
static void(entity ent) SV_CalcGunOffset =
{
	float   delta;

	// gun angles from bobbing
	ent.client.ps.gunangles[ROLL] = xyspeed * bobfracsin * 0.005f;
	ent.client.ps.gunangles[YAW] = xyspeed * bobfracsin * 0.01f;
	if (bobcycle & 1) {
		ent->client->ps.gunangles[ROLL] = -ent->client->ps.gunangles[ROLL];
		ent->client->ps.gunangles[YAW] = -ent->client->ps.gunangles[YAW];
	}

	ent->client->ps.gunangles[PITCH] = xyspeed * bobfracsin * 0.005f;

	// gun angles from delta movement
	#define FIGURE_GUN_ANGLE(i) \
		delta = ent->client->oldviewangles[i] - ent->client->ps.viewangles[i]; \
		if (delta > 180) \
			delta -= 360f; \
		if (delta < -180) \
			delta += 360f; \
		if (delta > 45) \
			delta = 45f; \
		if (delta < -45) \
			delta = -45f; \
		if (i == YAW) \
			ent->client->ps.gunangles[ROLL] += 0.1f * delta; \
		ent->client->ps.gunangles[i] += 0.2f * delta

	FIGURE_GUN_ANGLE(0);
	FIGURE_GUN_ANGLE(1);
	FIGURE_GUN_ANGLE(2);

	// gun height
	ent->client->ps.gunoffset = vec3_origin;
}

/*
=============
SV_AddBlend
=============
*/
static void(vector rgb, float a, float *v_blend) SV_AddBlend =
{
	float   a2, a3;

	if (a <= 0)
		return;
	a2 = v_blend[3] + (1 - v_blend[3]) * a; // new total alpha
	a3 = v_blend[3] / a2;   // fraction of color from old
	
	*((vector *)v_blend) = (*((vector *)v_blend) * a3) + (rgb * (1 - a3));

	v_blend[3] = a2;
}

const vector lava_blend = '1.0 0.3 0.0';
const vector bonus_blend = '0.85 0.7 0.3';
const vector slime_blend = '0.0 0.1 0.05';
const vector water_blend = '0.5 0.3 0.2';
const vector quad_blend = '0 0 1';
const vector invul_blend = '1 1 0';
const vector enviro_blend = '0 1 0';
const vector breather_blend = '0.4 1 0.4';

#ifdef THE_RECKONING
const vector quadfire_blend = '1 0.2 0.5';
#endif

/*
=============
SV_CalcBlend
=============
*/
static void(entity ent) SV_CalcBlend =
{
	int	contents;
	vector	vieworg;
	int	remaining;

	ent->client->ps.blend[0] = ent->client->ps.blend[1] = ent->client->ps.blend[2] = ent->client->ps.blend[3] = 0f;

	// add for contents
	vieworg = ent->s.origin + ent->client->ps.viewoffset;
	contents = gi.pointcontents(vieworg);
	if (contents & (CONTENTS_LAVA | CONTENTS_SLIME | CONTENTS_WATER))
		ent->client->ps.rdflags |= RDF_UNDERWATER;
	else
		ent->client->ps.rdflags &= ~RDF_UNDERWATER;

	if (contents & (CONTENTS_SOLID | CONTENTS_LAVA))
		SV_AddBlend(lava_blend, 0.6f, &ent.client.ps.blend[0]);
	else if (contents & CONTENTS_SLIME)
		SV_AddBlend(slime_blend, 0.6f, &ent->client->ps.blend[0]);
	else if (contents & CONTENTS_WATER)
		SV_AddBlend(water_blend, 0.4f, &ent->client->ps.blend[0]);

	// add for powerups
	if (ent->client->quad_framenum > level.framenum) {
		remaining = ent->client->quad_framenum - level.framenum;
		if (remaining == 30)    // beginning to fade
			gi.sound(ent, CHAN_ITEM, gi.soundindex("items/damage2.wav"), 1, ATTN_NORM, 0);
		if (remaining > 30 || (remaining & 4))
			SV_AddBlend(quad_blend, 0.08f, &ent->client->ps.blend[0]);
#ifdef THE_RECKONING
	// RAFAEL
	else if (ent->client->quadfire_framenum > level.framenum)
	{
		remaining = ent->client->quadfire_framenum - level.framenum;
		if (remaining == 30)	// beginning to fade
			gi.sound(ent, CHAN_ITEM, gi.soundindex("items/quadfire2.wav"), 1, ATTN_NORM, 0);
		if (remaining > 30 || (remaining & 4) )
			SV_AddBlend (quadfire_blend, 0.08f, &ent->client->ps.blend[0]);
	}
#endif
	} else if (ent->client->invincible_framenum > level.framenum) {
		remaining = ent->client->invincible_framenum - level.framenum;
		if (remaining == 30)    // beginning to fade
			gi.sound(ent, CHAN_ITEM, gi.soundindex("items/protect2.wav"), 1, ATTN_NORM, 0);
		if (remaining > 30 || (remaining & 4))
			SV_AddBlend(invul_blend, 0.08f, &ent->client->ps.blend[0]);
	} else if (ent->client->enviro_framenum > level.framenum) {
		remaining = ent->client->enviro_framenum - level.framenum;
		if (remaining == 30)    // beginning to fade
			gi.sound(ent, CHAN_ITEM, gi.soundindex("items/airout.wav"), 1, ATTN_NORM, 0);
		if (remaining > 30 || (remaining & 4))
			SV_AddBlend(enviro_blend, 0.08f, &ent->client->ps.blend[0]);
	} else if (ent->client->breather_framenum > level.framenum) {
		remaining = ent->client->breather_framenum - level.framenum;
		if (remaining == 30)    // beginning to fade
			gi.sound(ent, CHAN_ITEM, gi.soundindex("items/airout.wav"), 1, ATTN_NORM, 0);
		if (remaining > 30 || (remaining & 4))
			SV_AddBlend(breather_blend, 0.04f, &ent->client->ps.blend[0]);
	}

	// add for damage
	if (ent->client->damage_alpha > 0)
		SV_AddBlend(ent->client->damage_blend, ent->client->damage_alpha, &ent->client->ps.blend[0]);

	if (ent->client->bonus_alpha > 0)
		SV_AddBlend(bonus_blend, ent->client->bonus_alpha, &ent->client->ps.blend[0]);

	// drop the damage value
	ent->client->damage_alpha -= 0.06f;
	if (ent->client->damage_alpha < 0)
		ent->client->damage_alpha = 0;

	// drop the bonus value
	ent->client->bonus_alpha -= 0.1f;
	if (ent->client->bonus_alpha < 0)
		ent->client->bonus_alpha = 0;
}

/*
===============
G_SetClientEvent
===============
*/
static void(entity ent) G_SetClientEvent =
{
	if (ent.s.event)
		return;

	if (ent.groundentity != null_entity && xyspeed > 225) {
		if ((int)(ent.client.bobtime + bobmove) != bobcycle)
			ent->s.event = EV_FOOTSTEP;
	}
}

/*
===============
G_SetClientEffects
===============
*/
static void(entity ent) G_SetClientEffects =
{
	int     pa_type;
	int     remaining;

	ent->s.effects = 0;
	ent->s.renderfx = 0;

	if (ent->health <= 0 || level.intermission_framenum)
		return;

	if (ent->powerarmor_framenum > level.framenum) {
		pa_type = PowerArmorType(ent);
		if (pa_type == POWER_ARMOR_SCREEN) {
			ent->s.effects |= EF_POWERSCREEN;
		} else if (pa_type == POWER_ARMOR_SHIELD) {
			ent->s.effects |= EF_COLOR_SHELL;
			ent->s.renderfx |= RF_SHELL_GREEN;
		}
	}

	if (ent->client->quad_framenum > level.framenum) {
		remaining = ent->client->quad_framenum - level.framenum;
		if (remaining > 30 || (remaining & 4))
			ent->s.effects |= EF_QUAD;
	}

#ifdef THE_RECKONING
	// RAFAEL
	if (ent->client->quadfire_framenum > level.framenum)
	{
		remaining = ent->client->quadfire_framenum - level.framenum;
		if (remaining > 30 || (remaining & 4) )
			ent->s.effects |= EF_QUAD;
	}
#endif

	if (ent->client->invincible_framenum > level.framenum) {
		remaining = ent->client->invincible_framenum - level.framenum;
		if (remaining > 30 || (remaining & 4))
			ent->s.effects |= EF_PENT;
	}

	// show cheaters!!!
	if (ent->flags & FL_GODMODE) {
		ent->s.effects |= EF_COLOR_SHELL;
		ent->s.renderfx |= (RF_SHELL_RED | RF_SHELL_GREEN | RF_SHELL_BLUE);
	}
}

/*
===============
G_SetClientSound
===============
*/
static void(entity ent) G_SetClientSound =
{
	string	weap;

	if (ent->client->pers.game_helpchanged != game.helpchanged) {
		ent->client->pers.game_helpchanged = game.helpchanged;
		ent->client->pers.helpchanged = 1;
	}

	// help beep (no more than three times)
	if (ent->client->pers.helpchanged && ent->client->pers.helpchanged <= 3 && !(level.framenum & 63)) {
		ent->client->pers.helpchanged++;
		gi.sound(ent, CHAN_VOICE, gi.soundindex("misc/pc_up.wav"), 1, ATTN_STATIC, 0);
	}

	if (ent->client->pers.weapon)
		weap = GetItemKeyByIndex(ent->client->pers.weapon, classname);
	else
		weap = 0;

	if (ent->waterlevel && (ent->watertype & (CONTENTS_LAVA | CONTENTS_SLIME)))
		ent->s.sound = snd_fry;
	else if (weap == "weapon_railgun")
		ent->s.sound = gi.soundindex("weapons/rg_hum.wav");
	else if (weap == "weapon_bfg")
		ent->s.sound = gi.soundindex("weapons/bfg_hum.wav");
#ifdef THE_RECKONING
	// RAFAEL
	else if (weap == "weapon_phalanx")
		ent->s.sound = gi.soundindex("weapons/phaloop.wav");
#endif
	else if (ent->client->weapon_sound)
		ent->s.sound = ent->client->weapon_sound;
	else
		ent->s.sound = 0;
}

/*
===============
G_SetClientFrame
===============
*/
void(entity ent) G_SetClientFrame =
{
	bool        duck, run;

	if (ent->s.modelindex != 255)
		return;     // not in the player model

	if (ent.client->ps.pmove.pm_flags & PMF_DUCKED)
		duck = true;
	else
		duck = false;
	if (xyspeed)
		run = true;
	else
		run = false;

	// check for stand/duck and stop/go transitions
	if (duck != ent.client->anim_duck && ent.client->anim_priority < ANIM_DEATH)
		goto newanim;
	if (run != ent.client->anim_run && ent.client->anim_priority == ANIM_BASIC)
		goto newanim;
	if (ent->groundentity == null_entity && ent.client->anim_priority <= ANIM_WAVE)
		goto newanim;

	if (ent.client->anim_priority == ANIM_REVERSE) {
		if (ent->s.frame > ent.client->anim_end) {
			ent->s.frame--;
			return;
		}
	} else if (ent->s.frame < ent.client->anim_end) {
		// continue an animation
		ent->s.frame++;
		return;
	}

	if (ent.client->anim_priority == ANIM_DEATH)
		return;     // stay there
	if (ent.client->anim_priority == ANIM_JUMP) {
		if (ent->groundentity == null_entity)
			return;     // stay there
		ent->client->anim_priority = ANIM_WAVE;
		ent->s.frame = FRAME_jump3;
		ent->client->anim_end = FRAME_jump6;
		return;
	}

newanim:
	// return to either a running or standing frame
	ent.client->anim_priority = ANIM_BASIC;
	ent.client->anim_duck = duck;
	ent.client->anim_run = run;

	if (ent->groundentity == null_entity) {
		ent.client->anim_priority = ANIM_JUMP;
		if (ent->s.frame != FRAME_jump2)
			ent->s.frame = FRAME_jump1;
		ent.client->anim_end = FRAME_jump2;
	} else if (run) {
		// running
		if (duck) {
			ent->s.frame = FRAME_crwalk1;
			ent.client->anim_end = FRAME_crwalk6;
		} else {
			ent->s.frame = FRAME_run1;
			ent.client->anim_end = FRAME_run6;
		}
	} else {
		// standing
		if (duck) {
			ent->s.frame = FRAME_crstnd01;
			ent.client->anim_end = FRAME_crstnd19;
		} else {
			ent->s.frame = FRAME_stand01;
			ent.client->anim_end = FRAME_stand40;
		}
	}
}

/*
=================
ClientEndServerFrame

Called for each player at the end of the server frame
and right after spawning
=================
*/
void(entity ent) ClientEndServerFrame =
{
	float   bobtime;

	current_player = ent;

	//
	// If the origin or velocity have changed since ClientThink(),
	// update the pmove values.  This will happen when the client
	// is pushed by a bmodel or kicked by an explosion.
	//
	// If it wasn't updated here, the view position would lag a frame
	// behind the body position when pushed -- "sinking into plats"
	//
	ent.client.ps.pmove.origin[0] = COORD2SHORT(ent.s.origin[0]);
	ent.client.ps.pmove.velocity[0] = COORD2SHORT(ent.velocity[0]);
	ent.client.ps.pmove.origin[1] = COORD2SHORT(ent.s.origin[1]);
	ent.client.ps.pmove.velocity[1] = COORD2SHORT(ent.velocity[1]);
	ent.client.ps.pmove.origin[2] = COORD2SHORT(ent.s.origin[2]);
	ent.client.ps.pmove.velocity[2] = COORD2SHORT(ent.velocity[2]);

	//
	// If the end of unit layout is displayed, don't give
	// the player any normal movement attributes
	//
	if (level.intermission_framenum)
	{
		// FIXME: add view drifting here?
		ent.client.ps.blend[3] = 0f;
		ent.client.ps.fov = 90f;
		G_SetStats(ent);
		return;
	}

	AngleVectors(ent.client.v_angle, &forward, &right, &up);

	// burn from lava, etc
	P_WorldEffects();

	//
	// set model angles from view angles so other things in
	// the world can tell which direction you are looking
	//
	if (ent.client.v_angle[PITCH] > 180)
		ent.s.angles[PITCH] = (-360 + ent.client.v_angle[PITCH]) / 3;
	else
		ent.s.angles[PITCH] = ent.client.v_angle[PITCH] / 3;
	ent->s.angles[YAW] = ent->client->v_angle[YAW];
	ent->s.angles[ROLL] = 0;
	ent->s.angles[ROLL] = SV_CalcRoll(ent.s.angles, ent.velocity) * 4;

	//
	// calculate speed and cycle to be used for
	// all cyclic walking effects
	//
	xyspeed = sqrtf(ent.velocity_x * ent.velocity_x + ent.velocity_y * ent.velocity_y);

	if (xyspeed < 5) {
		bobmove = 0;
		ent.client.bobtime = 0;    // start at beginning of cycle again
	} else if (ent.groundentity != null_entity) {
		// so bobbing only cycles when on ground
		if (xyspeed > 210)
			bobmove = 0.25f;
		else if (xyspeed > 100)
			bobmove = 0.125f;
		else
			bobmove = 0.0625f;
	}

	bobtime = (ent.client.bobtime += bobmove);

	if (ent.client.ps.pmove.pm_flags & PMF_DUCKED)
		bobtime *= 4;

	bobcycle = (int)bobtime;
	bobfracsin = fabsf(sinf(bobtime * M_PI));

	// detect hitting the floor
	P_FallingDamage(ent);

	// apply all the damage taken this frame
	P_DamageFeedback(ent);

	// determine the view offsets
	SV_CalcViewOffset(ent);

	// determine the gun offsets
	SV_CalcGunOffset(ent);

	// determine the full screen color blend
	// must be after viewoffset, so eye contents can be
	// accurately determined
	// FIXME: with client prediction, the contents
	// should be determined by the client
	SV_CalcBlend(ent);

	// chase cam stuff
	if (ent->client->resp.spectator)
		G_SetSpectatorStats(ent);
	else
		G_SetStats(ent);
	G_CheckChaseStats(ent);

	G_SetClientEvent(ent);

	G_SetClientEffects(ent);

	G_SetClientSound(ent);

	G_SetClientFrame(ent);

	ent.client.oldvelocity = ent.velocity;
	ent.client.oldviewangles = ent.client.ps.viewangles;

	// clear weapon kicks
	ent.client.kick_origin = vec3_origin;
	ent.client.kick_angles = vec3_origin;

	// if the scoreboard is up, update it
	if (ent.client.showscores && !(level.framenum & 31)) {
		DeathmatchScoreboardMessage(ent, ent.enemy);
		gi.unicast(ent, false);
	}
}
