#include "m_soldier.h"


static int  sound_idle;
static int  sound_sight1;
static int  sound_sight2;
static int  sound_pain_light;
static int  sound_pain;
static int  sound_pain_ss;
static int  sound_death_light;
static int  sound_death;
static int  sound_death_ss;
static int  sound_cock;


static void(entity self) soldier_idle =
{
	if (frand() > 0.8f)
		gi.sound(self, CHAN_VOICE, sound_idle, 1, ATTN_IDLE, 0);
}

static void(entity self) soldier_cock =
{
	if (self->s.frame == FRAME_stand322)
		gi.sound(self, CHAN_WEAPON, sound_cock, 1, ATTN_IDLE, 0);
	else
		gi.sound(self, CHAN_WEAPON, sound_cock, 1, ATTN_NORM, 0);
}


// STAND
static mframe_t soldier_frames_stand1 [] = {
	{ ai_stand, 0, soldier_idle },
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
static var mmove_t soldier_move_stand1 = { FRAME_stand101, FRAME_stand130 };

static mframe_t soldier_frames_stand3 [] = {
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
	{ ai_stand, 0, soldier_cock },
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
static var mmove_t soldier_move_stand3 = { FRAME_stand301, FRAME_stand339 };

static void(entity self) soldier_stand =
{
	if ((self->monsterinfo.currentmove == &soldier_move_stand3) || (frand() < 0.8f))
		self->monsterinfo.currentmove = &soldier_move_stand1;
	else
		self->monsterinfo.currentmove = &soldier_move_stand3;
}


//
// WALK
//

static void(entity self) soldier_walk1_random =
{
	if (frand() > 0.1f)
		self->monsterinfo.nextframe = FRAME_walk101;
}

static mframe_t soldier_frames_walk1 [] = {
	{ ai_walk, 3 },
	{ ai_walk, 6 },
	{ ai_walk, 2 },
	{ ai_walk, 2 },
	{ ai_walk, 2 },
	{ ai_walk, 1 },
	{ ai_walk, 6 },
	{ ai_walk, 5 },
	{ ai_walk, 3 },
	{ ai_walk, -1, soldier_walk1_random },
	{ ai_walk },
	{ ai_walk },
	{ ai_walk },
	{ ai_walk },
	{ ai_walk },
	{ ai_walk },
	{ ai_walk },
	{ ai_walk },
	{ ai_walk },
	{ ai_walk },
	{ ai_walk },
	{ ai_walk },
	{ ai_walk },
	{ ai_walk },
	{ ai_walk },
	{ ai_walk },
	{ ai_walk },
	{ ai_walk },
	{ ai_walk },
	{ ai_walk },
	{ ai_walk },
	{ ai_walk },
	{ ai_walk }
};
static var mmove_t soldier_move_walk1 = { FRAME_walk101, FRAME_walk133 };

static mframe_t soldier_frames_walk2 [] = {
	{ ai_walk, 4 },
	{ ai_walk, 4 },
	{ ai_walk, 9 },
	{ ai_walk, 8 },
	{ ai_walk, 5 },
	{ ai_walk, 1 },
	{ ai_walk, 3 },
	{ ai_walk, 7 },
	{ ai_walk, 6 },
	{ ai_walk, 7 }
};
static var mmove_t soldier_move_walk2 = { FRAME_walk209, FRAME_walk218 };

static void(entity self) soldier_walk =
{
	if (frand() < 0.5f)
		self->monsterinfo.currentmove = &soldier_move_walk1;
	else
		self->monsterinfo.currentmove = &soldier_move_walk2;
}


//
// RUN
//

static mframe_t soldier_frames_start_run [] = {
	{ ai_run, 7 },
	{ ai_run, 5 }
};
static var mmove_t soldier_move_start_run = { FRAME_run01, FRAME_run02 };

static mframe_t soldier_frames_run [] = {
	{ ai_run, 10 },
	{ ai_run, 11 },
	{ ai_run, 11 },
	{ ai_run, 16 },
	{ ai_run, 10 },
	{ ai_run, 15 }
};
static var mmove_t soldier_move_run = { FRAME_run03, FRAME_run08 };

static void(entity self) soldier_run =
{
	if (self->monsterinfo.aiflags & AI_STAND_GROUND) {
		self->monsterinfo.currentmove = &soldier_move_stand1;
		return;
	}

	if (self->monsterinfo.currentmove == &soldier_move_walk1 ||
		self->monsterinfo.currentmove == &soldier_move_walk2 ||
		self->monsterinfo.currentmove == &soldier_move_start_run) {
		self->monsterinfo.currentmove = &soldier_move_run;
	} else {
		self->monsterinfo.currentmove = &soldier_move_start_run;
	}
}


//
// PAIN
//

static mframe_t soldier_frames_pain1 [] = {
	{ ai_move, -3 },
	{ ai_move, 4 },
	{ ai_move, 1 },
	{ ai_move, 1 },
	{ ai_move }
};
static var mmove_t soldier_move_pain1 = { FRAME_pain101, FRAME_pain105, soldier_run };

static mframe_t soldier_frames_pain2 [] = {
	{ ai_move, -13 },
	{ ai_move, -1 },
	{ ai_move, 2 },
	{ ai_move, 4 },
	{ ai_move, 2 },
	{ ai_move, 3 },
	{ ai_move, 2 }
};
static var mmove_t soldier_move_pain2 = { FRAME_pain201, FRAME_pain207, soldier_run };

static mframe_t soldier_frames_pain3 [] = {
	{ ai_move, -8 },
	{ ai_move, 10 },
	{ ai_move, -4 },
	{ ai_move, -1 },
	{ ai_move, -3 },
	{ ai_move },
	{ ai_move, 3 },
	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move, 1 },
	{ ai_move },
	{ ai_move, 1 },
	{ ai_move, 2 },
	{ ai_move, 4 },
	{ ai_move, 3 },
	{ ai_move, 2 }
};
static var mmove_t soldier_move_pain3 = { FRAME_pain301, FRAME_pain318, soldier_run };

static mframe_t soldier_frames_pain4 [] = {
	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move, -10 },
	{ ai_move, -6 },
	{ ai_move, 8 },
	{ ai_move, 4 },
	{ ai_move, 1 },
	{ ai_move },
	{ ai_move, 2 },
	{ ai_move, 5 },
	{ ai_move, 2 },
	{ ai_move, -1 },
	{ ai_move, -1 },
	{ ai_move, 3 },
	{ ai_move, 2 },
	{ ai_move }
};
static var mmove_t soldier_move_pain4 = { FRAME_pain401, FRAME_pain417, soldier_run };

static void(entity self, entity other, float kick, int damage) soldier_pain =
{
	float	r;
	int	n;

	if (self->health < (self->max_health / 2))
		self->s.skinnum |= 1;

	if (level.framenum < self->pain_debounce_framenum) {
		if ((self->velocity_z > 100) && ((self->monsterinfo.currentmove == &soldier_move_pain1) || (self->monsterinfo.currentmove == &soldier_move_pain2) || (self->monsterinfo.currentmove == &soldier_move_pain3)))
			self->monsterinfo.currentmove = &soldier_move_pain4;
		return;
	}

	self->pain_debounce_framenum = level.framenum + 3 * BASE_FRAMERATE;

	n = self->s.skinnum | 1;
	if (n == 1)
		gi.sound(self, CHAN_VOICE, sound_pain_light, 1, ATTN_NORM, 0);
	else if (n == 3)
		gi.sound(self, CHAN_VOICE, sound_pain, 1, ATTN_NORM, 0);
	else
		gi.sound(self, CHAN_VOICE, sound_pain_ss, 1, ATTN_NORM, 0);

	if (self->velocity_z > 100) {
		self->monsterinfo.currentmove = &soldier_move_pain4;
		return;
	}

	if (skill->intVal == 3)
		return;     // no pain anims in nightmare

	r = frand();

	if (r < 0.33f)
		self->monsterinfo.currentmove = &soldier_move_pain1;
	else if (r < 0.66f)
		self->monsterinfo.currentmove = &soldier_move_pain2;
	else
		self->monsterinfo.currentmove = &soldier_move_pain3;
}


//
// ATTACK
//

static int blaster_flash [] = {MZ2_SOLDIER_BLASTER_1, MZ2_SOLDIER_BLASTER_2, MZ2_SOLDIER_BLASTER_3, MZ2_SOLDIER_BLASTER_4, MZ2_SOLDIER_BLASTER_5, MZ2_SOLDIER_BLASTER_6, MZ2_SOLDIER_BLASTER_7, MZ2_SOLDIER_BLASTER_8};
static int shotgun_flash [] = {MZ2_SOLDIER_SHOTGUN_1, MZ2_SOLDIER_SHOTGUN_2, MZ2_SOLDIER_SHOTGUN_3, MZ2_SOLDIER_SHOTGUN_4, MZ2_SOLDIER_SHOTGUN_5, MZ2_SOLDIER_SHOTGUN_6, MZ2_SOLDIER_SHOTGUN_7, MZ2_SOLDIER_SHOTGUN_8};
static int machinegun_flash [] = {MZ2_SOLDIER_MACHINEGUN_1, MZ2_SOLDIER_MACHINEGUN_2, MZ2_SOLDIER_MACHINEGUN_3, MZ2_SOLDIER_MACHINEGUN_4, MZ2_SOLDIER_MACHINEGUN_5, MZ2_SOLDIER_MACHINEGUN_6, MZ2_SOLDIER_MACHINEGUN_7, MZ2_SOLDIER_MACHINEGUN_8};

static void(entity self, int flash_number) soldier_fire =
{
	vector	start;
	vector	forward, right, up;
	vector	aim;
	vector	dir;
	vector	end;
	float	r, u;
	int	flash_index;

	if (self->s.skinnum < 2)
		flash_index = blaster_flash[flash_number];
	else if (self->s.skinnum < 4)
		flash_index = shotgun_flash[flash_number];
	else
		flash_index = machinegun_flash[flash_number];

	AngleVectors(self->s.angles, forward, right, unref_vec);
	G_ProjectSource(self->s.origin, monster_flash_offset[flash_index], forward, right, start);

	if (flash_number == 5 || flash_number == 6) {
		VectorCopy(forward, aim);
	} else {
		VectorCopy(self->enemy->s.origin, end);
		end_z += self->enemy->viewheight;
		VectorSubtract(end, start, aim);
		vectoangles(aim, dir);
		AngleVectors(dir, forward, right, up);

		r = crand() * 1000;
		u = crand() * 500;
		VectorMA(start, 8192, forward, end);
		VectorMA(end, r, right, end);
		VectorMA(end, u, up, end);

		VectorSubtract(end, start, aim);
		VectorNormalize(aim);
	}

	if (self->s.skinnum <= 1) {
		monster_fire_blaster(self, start, aim, 5, 600, flash_index, EF_BLASTER);
	} else if (self->s.skinnum <= 3) {
		monster_fire_shotgun(self, start, aim, 2, 1, DEFAULT_SHOTGUN_HSPREAD, DEFAULT_SHOTGUN_VSPREAD, DEFAULT_SHOTGUN_COUNT, flash_index);
	} else {
		if (!(self->monsterinfo.aiflags & AI_HOLD_FRAME))
			self->monsterinfo.pause_framenum = level.framenum + (3 + Q_rand() % 8);

		monster_fire_bullet(self, start, aim, 2, 4, DEFAULT_BULLET_HSPREAD, DEFAULT_BULLET_VSPREAD, flash_index);

		if (level.framenum >= self->monsterinfo.pause_framenum)
			self->monsterinfo.aiflags &= ~AI_HOLD_FRAME;
		else
			self->monsterinfo.aiflags |= AI_HOLD_FRAME;
	}
}

// ATTACK1 (blaster/shotgun)

static void(entity self) soldier_fire1 =
{
	soldier_fire(self, 0);
}

static void(entity self) soldier_attack1_refire1 =
{
	if (self->s.skinnum > 1)
		return;

	if (self->enemy->health <= 0)
		return;

	if (((skill->intVal == 3) && (frand() < 0.5f)) || (range(self, self->enemy) == RANGE_MELEE))
		self->monsterinfo.nextframe = FRAME_attak102;
	else
		self->monsterinfo.nextframe = FRAME_attak110;
}

static void(entity self) soldier_attack1_refire2 =
{
	if (self->s.skinnum < 2)
		return;

	if (self->enemy->health <= 0)
		return;

	if (((skill->intVal == 3) && (frand() < 0.5f)) || (range(self, self->enemy) == RANGE_MELEE))
		self->monsterinfo.nextframe = FRAME_attak102;
}

static mframe_t soldier_frames_attack1 [] = {
	{ ai_charge },
	{ ai_charge },
	{ ai_charge, 0,  soldier_fire1 },
	{ ai_charge },
	{ ai_charge },
	{ ai_charge, 0,  soldier_attack1_refire1 },
	{ ai_charge },
	{ ai_charge, 0,  soldier_cock },
	{ ai_charge, 0,  soldier_attack1_refire2 },
	{ ai_charge },
	{ ai_charge },
	{ ai_charge }
};
static var mmove_t soldier_move_attack1 = { FRAME_attak101, FRAME_attak112, soldier_run };

// ATTACK2 (blaster/shotgun)

static void(entity self) soldier_fire2 =
{
	soldier_fire(self, 1);
}

static void(entity self) soldier_attack2_refire1 =
{
	if (self->s.skinnum > 1)
		return;

	if (self->enemy->health <= 0)
		return;

	if (((skill->intVal == 3) && (frand() < 0.5f)) || (range(self, self->enemy) == RANGE_MELEE))
		self->monsterinfo.nextframe = FRAME_attak204;
	else
		self->monsterinfo.nextframe = FRAME_attak216;
}

static void(entity self) soldier_attack2_refire2 =
{
	if (self->s.skinnum < 2)
		return;

	if (self->enemy->health <= 0)
		return;

	if (((skill->intVal == 3) && (frand() < 0.5f)) || (range(self, self->enemy) == RANGE_MELEE))
		self->monsterinfo.nextframe = FRAME_attak204;
}

static mframe_t soldier_frames_attack2 [] = {
	{ ai_charge },
	{ ai_charge },
	{ ai_charge },
	{ ai_charge },
	{ ai_charge, 0, soldier_fire2 },
	{ ai_charge },
	{ ai_charge },
	{ ai_charge, 0, soldier_attack2_refire1 },
	{ ai_charge },
	{ ai_charge },
	{ ai_charge },
	{ ai_charge },
	{ ai_charge, 0, soldier_cock },
	{ ai_charge },
	{ ai_charge, 0, soldier_attack2_refire2 },
	{ ai_charge },
	{ ai_charge },
	{ ai_charge }
};
static var mmove_t soldier_move_attack2 = { FRAME_attak201, FRAME_attak218, soldier_run };

// ATTACK3 (duck and shoot)

static void(entity self) soldier_duck_down =
{
	if (self->monsterinfo.aiflags & AI_DUCKED)
		return;
	self->monsterinfo.aiflags |= AI_DUCKED;
	self->maxs_z -= 32;
	self->takedamage = DAMAGE_YES;
	self->monsterinfo.pause_framenum = level.framenum + 1 * BASE_FRAMERATE;
	gi.linkentity(self);
}

static void(entity self) soldier_duck_up =
{
	self->monsterinfo.aiflags &= ~AI_DUCKED;
	self->maxs_z += 32;
	self->takedamage = DAMAGE_AIM;
	gi.linkentity(self);
}

static void(entity self) soldier_fire3 =
{
	soldier_duck_down(self);
	soldier_fire(self, 2);
}

static void(entity self) soldier_attack3_refire =
{
	if ((level.framenum + (int)(0.4f * BASE_FRAMERATE)) < self->monsterinfo.pause_framenum)
		self->monsterinfo.nextframe = FRAME_attak303;
}

static mframe_t soldier_frames_attack3 [] = {
	{ ai_charge },
	{ ai_charge },
	{ ai_charge, 0, soldier_fire3 },
	{ ai_charge },
	{ ai_charge },
	{ ai_charge, 0, soldier_attack3_refire },
	{ ai_charge, 0, soldier_duck_up },
	{ ai_charge },
	{ ai_charge }
};
static var mmove_t soldier_move_attack3 = { FRAME_attak301, FRAME_attak309, soldier_run };

// ATTACK4 (machinegun)

static void(entity self) soldier_fire4 =
{
	soldier_fire(self, 3);
//
//  if (self->enemy->health <= 0)
//      return;
//
//  if ( ((skill->value == 3) && (random() < 0.5)) || (range(self, self->enemy) == RANGE_MELEE) )
//      self->monsterinfo.nextframe = FRAME_attak402;
}

static mframe_t soldier_frames_attack4 [] = {
	{ ai_charge },
	{ ai_charge },
	{ ai_charge, 0, soldier_fire4 },
	{ ai_charge },
	{ ai_charge },
	{ ai_charge }
};
static var mmove_t soldier_move_attack4 = { FRAME_attak401, FRAME_attak406, soldier_run };


// ATTACK6 (run & shoot)

static void(entity self) soldier_fire8 =
{
	soldier_fire(self, 7);
}

static void(entity self) soldier_attack6_refire =
{
	if (self->enemy->health <= 0)
		return;

	if (range(self, self->enemy) < RANGE_MID)
		return;

	if (skill->intVal == 3)
		self->monsterinfo.nextframe = FRAME_runs03;
}

static mframe_t soldier_frames_attack6 [] = {
	{ ai_charge, 10 },
	{ ai_charge,  4 },
	{ ai_charge, 12 },
	{ ai_charge, 11, soldier_fire8 },
	{ ai_charge, 13 },
	{ ai_charge, 18 },
	{ ai_charge, 15 },
	{ ai_charge, 14 },
	{ ai_charge, 11 },
	{ ai_charge,  8 },
	{ ai_charge, 11 },
	{ ai_charge, 12 },
	{ ai_charge, 12 },
	{ ai_charge, 17, soldier_attack6_refire }
};
static var mmove_t soldier_move_attack6 = { FRAME_runs01, FRAME_runs14, soldier_run };

static void(entity self) soldier_attack =
{
	if (self->s.skinnum < 4) {
		if (frand() < 0.5f)
			self->monsterinfo.currentmove = &soldier_move_attack1;
		else
			self->monsterinfo.currentmove = &soldier_move_attack2;
	} else {
		self->monsterinfo.currentmove = &soldier_move_attack4;
	}
}


//
// SIGHT
//

static void(entity self, entity other) soldier_sight =
{
	if (frand() < 0.5f)
		gi.sound(self, CHAN_VOICE, sound_sight1, 1, ATTN_NORM, 0);
	else
		gi.sound(self, CHAN_VOICE, sound_sight2, 1, ATTN_NORM, 0);

	if ((skill->intVal > 0) && (range(self, self->enemy) >= RANGE_MID)) {
		if (frand() > 0.5f)
			self->monsterinfo.currentmove = &soldier_move_attack6;
	}
}

//
// DUCK
//

static void(entity self) soldier_duck_hold =
{
	if (level.framenum >= self->monsterinfo.pause_framenum)
		self->monsterinfo.aiflags &= ~AI_HOLD_FRAME;
	else
		self->monsterinfo.aiflags |= AI_HOLD_FRAME;
}

static mframe_t soldier_frames_duck [] = {
	{ ai_move, 5, soldier_duck_down },
	{ ai_move, -1, soldier_duck_hold },
	{ ai_move, 1 },
	{ ai_move, 0,  soldier_duck_up },
	{ ai_move, 5 }
};
static var mmove_t soldier_move_duck = { FRAME_duck01, FRAME_duck05, soldier_run };

static void(entity self, entity attacker, float eta) soldier_dodge =
{
	float	r;

	r = frand();
	if (r > 0.25f)
		return;

	if (!self->enemy)
		self->enemy = attacker;

	if (skill->intVal == 0) {
		self->monsterinfo.currentmove = &soldier_move_duck;
		return;
	}

	self->monsterinfo.pause_framenum = level.framenum + (int)((eta + 0.3f) * BASE_FRAMERATE);
	r = frand();

	if (skill->intVal == 1) {
		if (r > 0.33f)
			self->monsterinfo.currentmove = &soldier_move_duck;
		else
			self->monsterinfo.currentmove = &soldier_move_attack3;
		return;
	}

	if (skill->intVal >= 2) {
		if (r > 0.66f)
			self->monsterinfo.currentmove = &soldier_move_duck;
		else
			self->monsterinfo.currentmove = &soldier_move_attack3;
		return;
	}

	self->monsterinfo.currentmove = &soldier_move_attack3;
}


//
// DEATH
//

static void(entity self) soldier_fire6 =
{
	soldier_fire(self, 5);
}

static void(entity self) soldier_fire7 =
{
	soldier_fire(self, 6);
}

static void(entity self) soldier_dead =
{
	VectorSet(self->mins, -16, -16, -24);
	VectorSet(self->maxs, 16, 16, -8);
	self->movetype = MOVETYPE_TOSS;
	self->svflags |= SVF_DEADMONSTER;
	self->nextthink = 0;
	gi.linkentity(self);
}

static mframe_t soldier_frames_death1 [] = {
	{ ai_move },
	{ ai_move, -10 },
	{ ai_move, -10 },
	{ ai_move, -10 },
	{ ai_move, -5 },
	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move },

	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move },

	{ ai_move },
	{ ai_move, 0,   soldier_fire6 },
	{ ai_move },
	{ ai_move },
	{ ai_move, 0,   soldier_fire7 },
	{ ai_move },
	{ ai_move },
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
static var mmove_t soldier_move_death1 = { FRAME_death101, FRAME_death136, soldier_dead };

static mframe_t soldier_frames_death2 [] = {
	{ ai_move, -5 },
	{ ai_move, -5 },
	{ ai_move, -5 },
	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move },

	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move },

	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move },
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
static var mmove_t soldier_move_death2 = { FRAME_death201, FRAME_death235, soldier_dead };

static mframe_t soldier_frames_death3 [] = {
	{ ai_move, -5 },
	{ ai_move, -5 },
	{ ai_move, -5 },
	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move },

	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move },

	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move },

	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move },

	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move },
};
static var mmove_t soldier_move_death3 = { FRAME_death301, FRAME_death345, soldier_dead };

static mframe_t soldier_frames_death4 [] = {
	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move },

	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move },

	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move },

	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move },

	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move },
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
static var mmove_t soldier_move_death4 = { FRAME_death401, FRAME_death453, soldier_dead };

static mframe_t soldier_frames_death5 [] = {
	{ ai_move, -5 },
	{ ai_move, -5 },
	{ ai_move, -5 },
	{ ai_move, 0 },
	{ ai_move, 0 },
	{ ai_move, 0 },
	{ ai_move, 0 },
	{ ai_move, 0 },
	{ ai_move, 0 },
	{ ai_move, 0 },

	{ ai_move, 0 },
	{ ai_move, 0 },
	{ ai_move, 0 },
	{ ai_move, 0 },
	{ ai_move, 0 },
	{ ai_move, 0 },
	{ ai_move, 0 },
	{ ai_move, 0 },
	{ ai_move, 0 },
	{ ai_move, 0 },

	{ ai_move, 0 },
	{ ai_move, 0 },
	{ ai_move, 0 },
	{ ai_move, 0 }
};
static var mmove_t soldier_move_death5 = { FRAME_death501, FRAME_death524, soldier_dead };

static mframe_t soldier_frames_death6 [] = {
	{ ai_move, 0 },
	{ ai_move, 0 },
	{ ai_move, 0 },
	{ ai_move, 0 },
	{ ai_move, 0 },
	{ ai_move, 0 },
	{ ai_move, 0 },
	{ ai_move, 0 },
	{ ai_move, 0 },
	{ ai_move, 0 }
};
static var mmove_t soldier_move_death6 = { FRAME_death601, FRAME_death610, soldier_dead };

static void(entity self, entity inflictor, entity attacker, int damage, vector point) soldier_die =
{
	int	n;

// check for gib
	if (self->health <= self->gib_health) {
		gi.sound(self, CHAN_VOICE, gi.soundindex("misc/udeath.wav"), 1, ATTN_NORM, 0);
		for (n = 0; n < 3; n++)
			ThrowGib(self, "models/objects/gibs/sm_meat/tris.md2", damage, GIB_ORGANIC);
		ThrowGib(self, "models/objects/gibs/chest/tris.md2", damage, GIB_ORGANIC);
		ThrowHead(self, "models/objects/gibs/head2/tris.md2", damage, GIB_ORGANIC);
		self->deadflag = DEAD_DEAD;
		return;
	}

	if (self->deadflag == DEAD_DEAD)
		return;

// regular death
	self->deadflag = DEAD_DEAD;
	self->takedamage = DAMAGE_YES;
	self->s.skinnum |= 1;

	if (self->s.skinnum == 1)
		gi.sound(self, CHAN_VOICE, sound_death_light, 1, ATTN_NORM, 0);
	else if (self->s.skinnum == 3)
		gi.sound(self, CHAN_VOICE, sound_death, 1, ATTN_NORM, 0);
	else // (self->s.skinnum == 5)
		gi.sound(self, CHAN_VOICE, sound_death_ss, 1, ATTN_NORM, 0);

	if (fabsf((self->s.origin[2] + self->viewheight) - point[2]) <= 4) {
		// head shot
		self->monsterinfo.currentmove = &soldier_move_death3;
		return;
	}

	n = Q_rand() % 5;
	if (n == 0)
		self->monsterinfo.currentmove = &soldier_move_death1;
	else if (n == 1)
		self->monsterinfo.currentmove = &soldier_move_death2;
	else if (n == 2)
		self->monsterinfo.currentmove = &soldier_move_death4;
	else if (n == 3)
		self->monsterinfo.currentmove = &soldier_move_death5;
	else
		self->monsterinfo.currentmove = &soldier_move_death6;
}


//
// SPAWN
//

static void(entity self) SP_monster_soldier_x =
{
	if (!soldier_move_stand1.frame)
	{
		soldier_move_stand1.frame = &soldier_frames_stand1;
		soldier_move_stand3.endfunc = soldier_stand;
		soldier_move_stand3.frame = soldier_frames_stand3;
		soldier_move_stand1.endfunc = soldier_stand;
		soldier_move_walk1.frame = &soldier_frames_walk1;
		soldier_move_walk2.frame = &soldier_frames_walk2;
		soldier_move_start_run.frame = &soldier_frames_start_run;
		soldier_move_start_run.endfunc = soldier_run;
		soldier_move_run.frame = &soldier_frames_run;
		soldier_move_pain1.frame = &soldier_frames_pain1;
		soldier_move_pain2.frame = &soldier_frames_pain2;
		soldier_move_pain3.frame = &soldier_frames_pain3;
		soldier_move_pain4.frame = &soldier_frames_pain4;
		soldier_move_attack1.frame = &soldier_frames_attack1;
		soldier_move_attack2.frame = &soldier_frames_attack2;
		soldier_move_attack3.frame = &soldier_frames_attack3;
		soldier_move_attack4.frame = &soldier_frames_attack4;
		soldier_move_attack6.frame = &soldier_frames_attack6;
		soldier_move_duck.frame = &soldier_frames_duck;
		soldier_move_death1.frame = &soldier_frames_death1;
		soldier_move_death2.frame = &soldier_frames_death2;
		soldier_move_death3.frame = &soldier_frames_death3;
		soldier_move_death4.frame = &soldier_frames_death4;
		soldier_move_death5.frame = &soldier_frames_death5;
		soldier_move_death6.frame = &soldier_frames_death6;
	}

	self->s.modelindex = gi.modelindex("models/monsters/soldier/tris.md2");
	self->monsterinfo.scale = MODEL_SCALE;
	VectorSet(self->mins, -16, -16, -24);
	VectorSet(self->maxs, 16, 16, 32);
	self->movetype = MOVETYPE_STEP;
	self->solid = SOLID_BBOX;

	sound_idle =    gi.soundindex("soldier/solidle1.wav");
	sound_sight1 =  gi.soundindex("soldier/solsght1.wav");
	sound_sight2 =  gi.soundindex("soldier/solsrch1.wav");
	sound_cock =    gi.soundindex("infantry/infatck3.wav");

	self->mass = 100;

	self->pain = soldier_pain;
	self->die = soldier_die;

	self->monsterinfo.stand = soldier_stand;
	self->monsterinfo.walk = soldier_walk;
	self->monsterinfo.run = soldier_run;
	self->monsterinfo.dodge = soldier_dodge;
	self->monsterinfo.attack = soldier_attack;
	self->monsterinfo.melee = 0;
	self->monsterinfo.sight = soldier_sight;

	gi.linkentity(self);

	self->monsterinfo.stand(self);

	walkmonster_start(self);
}


/*QUAKED monster_soldier_light (1 .5 0) (-16 -16 -24) (16 16 32) Ambush Trigger_Spawn Sight
*/
__used static void(entity self) SP_monster_soldier_light =
{
	if (deathmatch->intVal) {
		G_FreeEdict(self);
		return;
	}

	SP_monster_soldier_x(self);

	sound_pain_light = gi.soundindex("soldier/solpain2.wav");
	sound_death_light = gi.soundindex("soldier/soldeth2.wav");
	gi.modelindex("models/objects/laser/tris.md2");
	gi.soundindex("misc/lasfly.wav");
	gi.soundindex("soldier/solatck2.wav");

	self->s.skinnum = 0;
	self->health = 20;
	self->gib_health = -30;
}

/*QUAKED monster_soldier (1 .5 0) (-16 -16 -24) (16 16 32) Ambush Trigger_Spawn Sight
*/
__used static void(entity self) SP_monster_soldier =
{
	if (deathmatch->intVal) {
		G_FreeEdict(self);
		return;
	}

	SP_monster_soldier_x(self);

	sound_pain = gi.soundindex("soldier/solpain1.wav");
	sound_death = gi.soundindex("soldier/soldeth1.wav");
	gi.soundindex("soldier/solatck1.wav");

	self->s.skinnum = 2;
	self->health = 30;
	self->gib_health = -30;
}

/*QUAKED monster_soldier_ss (1 .5 0) (-16 -16 -24) (16 16 32) Ambush Trigger_Spawn Sight
*/
__used static void(entity self) SP_monster_soldier_ss =
{
	if (deathmatch->intVal) {
		G_FreeEdict(self);
		return;
	}

	SP_monster_soldier_x(self);

	sound_pain_ss = gi.soundindex("soldier/solpain3.wav");
	sound_death_ss = gi.soundindex("soldier/soldeth3.wav");
	gi.soundindex("soldier/solatck3.wav");

	self->s.skinnum = 4;
	self->health = 40;
	self->gib_health = -30;
}
