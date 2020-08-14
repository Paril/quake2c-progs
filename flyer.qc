#include "m_flyer.h"

static int  sound_sight;
static int  sound_idle;
static int  sound_pain1;
static int  sound_pain2;
static int  sound_slash;
static int  sound_sproing;
static int  sound_die;

static void(entity self, entity other) flyer_sight =
{
	gi.sound(self, CHAN_VOICE, sound_sight, 1, ATTN_NORM, 0);
}

static void(entity self) flyer_idle =
{
	gi.sound(self, CHAN_VOICE, sound_idle, 1, ATTN_IDLE, 0);
}

static void(entity self) flyer_pop_blades =
{
	gi.sound(self, CHAN_VOICE, sound_sproing, 1, ATTN_NORM, 0);
}

static mframe_t flyer_frames_stand [] = {
	{ ai_stand },
	{ ai_stand },
	{ ai_stand },
	{ ai_stand },
	{ ai_stand },
	{ ai_stand },
	{ ai_stand },
	{ ai_stand },
	{ ai_stand },
	{ ai_stand },
	{ ai_stand },
	{ ai_stand },
	{ ai_stand },
	{ ai_stand },
	{ ai_stand },
	{ ai_stand },
	{ ai_stand },
	{ ai_stand },
	{ ai_stand },
	{ ai_stand },
	{ ai_stand },
	{ ai_stand },
	{ ai_stand },
	{ ai_stand },
	{ ai_stand },
	{ ai_stand },
	{ ai_stand },
	{ ai_stand },
	{ ai_stand },
	{ ai_stand },
	{ ai_stand },
	{ ai_stand },
	{ ai_stand },
	{ ai_stand },
	{ ai_stand },
	{ ai_stand },
	{ ai_stand },
	{ ai_stand },
	{ ai_stand },
	{ ai_stand },
	{ ai_stand },
	{ ai_stand },
	{ ai_stand },
	{ ai_stand },
	{ ai_stand }
};
static var mmove_t flyer_move_stand = { FRAME_stand01, FRAME_stand45 };

static mframe_t flyer_frames_walk [] = {
	{ ai_walk, 5 },
	{ ai_walk, 5 },
	{ ai_walk, 5 },
	{ ai_walk, 5 },
	{ ai_walk, 5 },
	{ ai_walk, 5 },
	{ ai_walk, 5 },
	{ ai_walk, 5 },
	{ ai_walk, 5 },
	{ ai_walk, 5 },
	{ ai_walk, 5 },
	{ ai_walk, 5 },
	{ ai_walk, 5 },
	{ ai_walk, 5 },
	{ ai_walk, 5 },
	{ ai_walk, 5 },
	{ ai_walk, 5 },
	{ ai_walk, 5 },
	{ ai_walk, 5 },
	{ ai_walk, 5 },
	{ ai_walk, 5 },
	{ ai_walk, 5 },
	{ ai_walk, 5 },
	{ ai_walk, 5 },
	{ ai_walk, 5 },
	{ ai_walk, 5 },
	{ ai_walk, 5 },
	{ ai_walk, 5 },
	{ ai_walk, 5 },
	{ ai_walk, 5 },
	{ ai_walk, 5 },
	{ ai_walk, 5 },
	{ ai_walk, 5 },
	{ ai_walk, 5 },
	{ ai_walk, 5 },
	{ ai_walk, 5 },
	{ ai_walk, 5 },
	{ ai_walk, 5 },
	{ ai_walk, 5 },
	{ ai_walk, 5 },
	{ ai_walk, 5 },
	{ ai_walk, 5 },
	{ ai_walk, 5 },
	{ ai_walk, 5 },
	{ ai_walk, 5 }
};
static var mmove_t flyer_move_walk = { FRAME_stand01, FRAME_stand45 };

static mframe_t flyer_frames_run [] = {
	{ ai_run, 10 },
	{ ai_run, 10 },
	{ ai_run, 10 },
	{ ai_run, 10 },
	{ ai_run, 10 },
	{ ai_run, 10 },
	{ ai_run, 10 },
	{ ai_run, 10 },
	{ ai_run, 10 },
	{ ai_run, 10 },
	{ ai_run, 10 },
	{ ai_run, 10 },
	{ ai_run, 10 },
	{ ai_run, 10 },
	{ ai_run, 10 },
	{ ai_run, 10 },
	{ ai_run, 10 },
	{ ai_run, 10 },
	{ ai_run, 10 },
	{ ai_run, 10 },
	{ ai_run, 10 },
	{ ai_run, 10 },
	{ ai_run, 10 },
	{ ai_run, 10 },
	{ ai_run, 10 },
	{ ai_run, 10 },
	{ ai_run, 10 },
	{ ai_run, 10 },
	{ ai_run, 10 },
	{ ai_run, 10 },
	{ ai_run, 10 },
	{ ai_run, 10 },
	{ ai_run, 10 },
	{ ai_run, 10 },
	{ ai_run, 10 },
	{ ai_run, 10 },
	{ ai_run, 10 },
	{ ai_run, 10 },
	{ ai_run, 10 },
	{ ai_run, 10 },
	{ ai_run, 10 },
	{ ai_run, 10 },
	{ ai_run, 10 },
	{ ai_run, 10 },
	{ ai_run, 10 }
};
static var mmove_t flyer_move_run = { FRAME_stand01, FRAME_stand45 };

#ifdef GROUND_ZERO
var mmove_t flyer_move_kamikaze = { FRAME_rollr02, FRAME_rollr06 };

static void(entity self, entity inflictor, entity attacker, int damage, vector point) flyer_die;

static void flyer_kamikaze_explode (entity self)
{
	vector dir = vec3_origin;

	if (self.monsterinfo.commander && self.monsterinfo.commander.inuse && 
		self.monsterinfo.commander.classname == "monster_carrier")
		self.monsterinfo.commander.monsterinfo.monster_slots++;

	if (self.enemy)
	{
		dir = self.enemy.s.origin - self.s.origin;
		T_Damage (self.enemy, self, self, dir, self.s.origin, vec3_origin, 50, 50, DAMAGE_RADIUS, MOD_UNKNOWN);
	}

	flyer_die (self, 0, 0, 0, dir);
}

static void flyer_kamikaze (entity self)
{
	self.monsterinfo.currentmove = &flyer_move_kamikaze;
}

static void flyer_kamikaze_check (entity self)
{
	float	dist;

	// PMM - this needed because we could have gone away before we get here (blocked code)
	if (!self.inuse)
		return;

	if ((!self.enemy) || (!self.enemy.inuse))
	{
		flyer_kamikaze_explode (self);
		return;
	}

	self.goalentity = self.enemy;

	dist = realrange (self, self.enemy);

	if (dist < 90)
		flyer_kamikaze_explode (self);
}

static mframe_t flyer_frames_kamizake [] =
{
	{ ai_charge, 40,	flyer_kamikaze_check },
	{ ai_charge, 40,	flyer_kamikaze_check },
	{ ai_charge, 40,	flyer_kamikaze_check },
	{ ai_charge, 40,	flyer_kamikaze_check },
	{ ai_charge, 40,	flyer_kamikaze_check }
};
#endif

static void(entity self) flyer_run =
{
#ifdef GROUND_ZERO
	if (self.mass > 50)
		self.monsterinfo.currentmove = &flyer_move_kamikaze;
	else
#endif
	if (self.monsterinfo.aiflags & AI_STAND_GROUND)
		self.monsterinfo.currentmove = &flyer_move_stand;
	else
		self.monsterinfo.currentmove = &flyer_move_run;
}

static void(entity self) flyer_walk =
{
#ifdef GROUND_ZERO

	if (self.mass > 50)
		flyer_run (self);
	else
#endif
		self.monsterinfo.currentmove = &flyer_move_walk;
}

static void(entity self) flyer_stand =
{
#ifdef GROUND_ZERO

	if (self.mass > 50)
		flyer_run (self);
	else
#endif
	self.monsterinfo.currentmove = &flyer_move_stand;
}

static mframe_t flyer_frames_pain3 [] = {
	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move }
};
static var mmove_t flyer_move_pain3 = { FRAME_pain301, FRAME_pain304, flyer_run };

static mframe_t flyer_frames_pain2 [] = {
	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move }
};
static var mmove_t flyer_move_pain2 = { FRAME_pain201, FRAME_pain204, flyer_run };

static mframe_t flyer_frames_pain1 [] = {
	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move }
};
static var mmove_t flyer_move_pain1 = { FRAME_pain101, FRAME_pain109, flyer_run };

static void(entity self, int flash_number) flyer_fire =
{
	vector  start;
	vector  forward, right;
	vector  end;
	vector  dir;
	int     effect;

#ifdef GROUND_ZERO
	if (!self.enemy || !self.enemy.inuse)
		return;
#endif

	if ((self.s.frame == FRAME_attak204) || (self.s.frame == FRAME_attak207) || (self.s.frame == FRAME_attak210))
		effect = EF_HYPERBLASTER;
	else
		effect = 0;
	AngleVectors(self.s.angles, &forward, &right, 0);
	start = G_ProjectSource(self.s.origin, monster_flash_offset[flash_number], forward, right);

	end = self.enemy.s.origin;
	end.z += self.enemy.viewheight;
	dir = end - start;

	monster_fire_blaster(self, start, dir, 1, 1000, flash_number, effect);
}

static void(entity self) flyer_fireleft =
{
	flyer_fire(self, MZ2_FLYER_BLASTER_1);
}

static void(entity self) flyer_fireright =
{
	flyer_fire(self, MZ2_FLYER_BLASTER_2);
}

static mframe_t flyer_frames_attack2 [] = {
	{ ai_charge },
	{ ai_charge },
	{ ai_charge },
	{ ai_charge, -10, flyer_fireleft },         // left gun
	{ ai_charge, -10, flyer_fireright },        // right gun
	{ ai_charge, -10, flyer_fireleft },         // left gun
	{ ai_charge, -10, flyer_fireright },        // right gun
	{ ai_charge, -10, flyer_fireleft },         // left gun
	{ ai_charge, -10, flyer_fireright },        // right gun
	{ ai_charge, -10, flyer_fireleft },         // left gun
	{ ai_charge, -10, flyer_fireright },        // right gun
	{ ai_charge },
	{ ai_charge },
	{ ai_charge },
	{ ai_charge },
	{ ai_charge },
	{ ai_charge }
};
static var mmove_t flyer_move_attack2 = { FRAME_attak201, FRAME_attak217, flyer_run };

#ifdef GROUND_ZERO
static mframe_t flyer_frames_attack3 [] =
{
		{ ai_charge, 10 },
		{ ai_charge, 10 },
		{ ai_charge, 10 },
		{ ai_charge, 10, flyer_fireleft },			// left gun
		{ ai_charge, 10, flyer_fireright },		// right gun
		{ ai_charge, 10, flyer_fireleft },			// left gun
		{ ai_charge, 10, flyer_fireright },		// right gun
		{ ai_charge, 10, flyer_fireleft },			// left gun
		{ ai_charge, 10, flyer_fireright },		// right gun
		{ ai_charge, 10, flyer_fireleft },			// left gun
		{ ai_charge, 10, flyer_fireright },		// right gun
		{ ai_charge, 10 },
		{ ai_charge, 10 },
		{ ai_charge, 10 },
		{ ai_charge, 10 },
		{ ai_charge, 10 },
		{ ai_charge, 10 }
};
var mmove_t flyer_move_attack3 = { FRAME_attak201, FRAME_attak217, flyer_run };
#endif

static void(entity self) flyer_slash_left =
{
	const vector  aim = [ MELEE_DISTANCE, self.mins.x, 0 ];
	fire_hit(self, aim, 5, 0);
	gi.sound(self, CHAN_WEAPON, sound_slash, 1, ATTN_NORM, 0);
}

static void(entity self) flyer_slash_right =
{
	const vector  aim = [ MELEE_DISTANCE, self.maxs.x, 0 ];
	fire_hit(self, aim, 5, 0);
	gi.sound(self, CHAN_WEAPON, sound_slash, 1, ATTN_NORM, 0);
}

static mframe_t flyer_frames_start_melee [] = {
	{ ai_charge, 0, flyer_pop_blades },
	{ ai_charge },
	{ ai_charge },
	{ ai_charge },
	{ ai_charge },
	{ ai_charge }
};
static var mmove_t flyer_move_start_melee = { FRAME_attak101, FRAME_attak106 };

static mframe_t flyer_frames_end_melee [] = {
	{ ai_charge },
	{ ai_charge },
	{ ai_charge }
};
static var mmove_t flyer_move_end_melee = { FRAME_attak119, FRAME_attak121, flyer_run };

static mframe_t flyer_frames_loop_melee [] = {
	{ ai_charge },     // Loop Start
	{ ai_charge },
	{ ai_charge, 0, flyer_slash_left },     // Left Wing Strike
	{ ai_charge },
	{ ai_charge },
	{ ai_charge },
	{ ai_charge },
	{ ai_charge, 0, flyer_slash_right },    // Right Wing Strike
	{ ai_charge },
	{ ai_charge },
	{ ai_charge },
	{ ai_charge }      // Loop Ends

};
static var mmove_t flyer_move_loop_melee = { FRAME_attak107, FRAME_attak118 };

static void(entity self) flyer_loop_melee =
{
	self.monsterinfo.currentmove = &flyer_move_loop_melee;
}

static void(entity self) flyer_attack =
{
#ifdef GROUND_ZERO
	// 0% chance of circle in easy
	// 50% chance in normal
	// 75% chance in hard
	// 86.67% chance in nightmare

	if (self.mass > 50)
	{
		flyer_run (self);
		return;
	}

	float chance = 0;
	
	if (skill.intVal)
		chance = 1.0 - (0.5 / skill.floatVal);

	if (random() > chance)
	{
		self.monsterinfo.attack_state = AS_STRAIGHT;
#endif
		self.monsterinfo.currentmove = &flyer_move_attack2;
#ifdef GROUND_ZERO
	}
	else // circle strafe
	{
		if (random () <= 0.5) // switch directions
			self.monsterinfo.lefty = 1 - self.monsterinfo.lefty;
		self.monsterinfo.attack_state = AS_SLIDING;
		self.monsterinfo.currentmove = &flyer_move_attack3;
	}
#endif
}

static void(entity self) flyer_melee =
{
#ifdef GROUND_ZERO
	if (self.mass > 50)
		flyer_run (self);
	else
#endif
		self.monsterinfo.currentmove = &flyer_move_start_melee;
}

static void(entity self) flyer_check_melee =
{
	if (range(self, self.enemy) == RANGE_MELEE)
		if (random() <= 0.8f)
			self.monsterinfo.currentmove = &flyer_move_loop_melee;
		else
			self.monsterinfo.currentmove = &flyer_move_end_melee;
	else
		self.monsterinfo.currentmove = &flyer_move_end_melee;
}

static void(entity self, entity other, float kick, int damage) flyer_pain =
{
#ifdef GROUND_ZERO
	// kamikaze's don't feel pain
	if (self.mass != 50)
		return;
#endif

	int     n;

	if (self.health < (self.max_health / 2))
		self.s.skinnum = 1;

	if (level.framenum < self.pain_debounce_framenum)
		return;

	self.pain_debounce_framenum = level.framenum + 3 * BASE_FRAMERATE;
	if (skill.intVal == 3)
		return;     // no pain anims in nightmare

	n = Q_rand() % 3;
	if (n == 0) {
		gi.sound(self, CHAN_VOICE, sound_pain1, 1, ATTN_NORM, 0);
		self.monsterinfo.currentmove = &flyer_move_pain1;
	} else if (n == 1) {
		gi.sound(self, CHAN_VOICE, sound_pain2, 1, ATTN_NORM, 0);
		self.monsterinfo.currentmove = &flyer_move_pain2;
	} else {
		gi.sound(self, CHAN_VOICE, sound_pain1, 1, ATTN_NORM, 0);
		self.monsterinfo.currentmove = &flyer_move_pain3;
	}
}

void(entity self) BecomeExplosion1;

static void(entity self, entity inflictor, entity attacker, int damage, vector point) flyer_die =
{
	gi.sound(self, CHAN_VOICE, sound_die, 1, ATTN_NORM, 0);
	BecomeExplosion1(self);
}

#ifdef GROUND_ZERO
// PMM - kamikaze code .. blow up if blocked	
static bool flyer_blocked (entity self, float dist)
{
	vector origin;

	// kamikaze = 100, normal = 50
	if (self.mass == 100)
	{
		flyer_kamikaze_check(self);

		// if the above didn't blow us up (i.e. I got blocked by the player)
		if (self.inuse)
		{
			if (self.monsterinfo.commander && self.monsterinfo.commander.inuse && 
				self.monsterinfo.commander.classname == "monster_carrier")
				self.monsterinfo.commander.monsterinfo.monster_slots++;

			origin = self.s.origin + (-0.02 * self.velocity);
			gi.WriteByte (svc_temp_entity);
			gi.WriteByte (TE_ROCKET_EXPLOSION);
			gi.WritePosition (origin);
			gi.multicast (self.s.origin, MULTICAST_PHS);

			G_FreeEdict (self);
		}
		return true;
	}

	// we're a normal flyer
	if (blocked_checkshot(self, 0.25 + (0.05 * skill.intVal)))
		return true;

	return false;
}
#endif

/*QUAKED monster_flyer (1 .5 0) (-16 -16 -24) (16 16 32) Ambush Trigger_Spawn Sight
*/
API_FUNC static void(entity self) SP_monster_flyer =
{
	if (deathmatch.intVal) {
		G_FreeEdict(self);
		return;
	}

	if (!flyer_move_stand.frame)
	{
		flyer_move_stand.frame = &flyer_frames_stand;
		flyer_move_walk.frame = &flyer_frames_walk;
		flyer_move_run.frame = &flyer_frames_run;

		flyer_move_pain3.frame = &flyer_frames_pain3;
		flyer_move_pain2.frame = &flyer_frames_pain2;
		flyer_move_pain1.frame = &flyer_frames_pain1;

		flyer_move_attack2.frame = &flyer_frames_attack2;

		flyer_move_start_melee.frame = &flyer_frames_start_melee;
		flyer_move_start_melee.endfunc = flyer_loop_melee;

		flyer_move_end_melee.frame = &flyer_frames_end_melee;
		flyer_move_loop_melee.frame = &flyer_frames_loop_melee;
		flyer_move_loop_melee.endfunc = flyer_check_melee;

#ifdef GROUND_ZERO
		flyer_move_kamikaze.frame = &flyer_frames_kamizake;
		flyer_move_kamikaze.endfunc = flyer_kamikaze;
		flyer_move_attack3.frame = &flyer_frames_attack3;
#endif
	}

	// fix a map bug in jail5.bsp
	if (striequals(level.mapname, "jail5") && (self.s.origin[2] == -104)) {
		self.targetname = self.target;
		self.target = 0;
	}

	sound_sight = gi.soundindex("flyer/flysght1.wav");
	sound_idle = gi.soundindex("flyer/flysrch1.wav");
	sound_pain1 = gi.soundindex("flyer/flypain1.wav");
	sound_pain2 = gi.soundindex("flyer/flypain2.wav");
	sound_slash = gi.soundindex("flyer/flyatck2.wav");
	sound_sproing = gi.soundindex("flyer/flyatck1.wav");
	sound_die = gi.soundindex("flyer/flydeth1.wav");

	gi.soundindex("flyer/flyatck3.wav");

	self.s.modelindex = gi.modelindex("models/monsters/flyer/tris.md2");
	self.mins = '-16 -16 -24';
#ifdef GROUND_ZERO
	self.maxs = '16 16 16';
#else
	self.maxs = '16 16 32';
#endif
	self.movetype = MOVETYPE_STEP;
	self.solid = SOLID_BBOX;

	self.s.sound = gi.soundindex("flyer/flyidle1.wav");

	self.health = 50;
	self.mass = 50;

	self.pain = flyer_pain;
	self.die = flyer_die;

	self.monsterinfo.stand = flyer_stand;
	self.monsterinfo.walk = flyer_walk;
	self.monsterinfo.run = flyer_run;
	self.monsterinfo.attack = flyer_attack;
	self.monsterinfo.melee = flyer_melee;
	self.monsterinfo.sight = flyer_sight;
	self.monsterinfo.idle = flyer_idle;

#ifdef GROUND_ZERO
	self.monsterinfo.blocked = flyer_blocked;
#endif

	gi.linkentity(self);

	self.monsterinfo.currentmove = &flyer_move_stand;
	self.monsterinfo.scale = MODEL_SCALE;

	flymonster_start(self);
}

#ifdef GROUND_ZERO
API_FUNC static void SP_monster_kamikaze (entity self)
{
	SP_monster_flyer(self);

	self.s.sound = gi.soundindex ("flyer/flyidle1.wav");
	self.s.effects |= EF_ROCKET;
	self.mass = 100;
}
#endif