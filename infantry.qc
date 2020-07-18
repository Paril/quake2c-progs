#include "m_infantry.h"

static int	sound_pain1;
static int	sound_pain2;
static int	sound_die1;
static int	sound_die2;

static int	sound_gunshot;
static int	sound_weapon_cock;
static int	sound_punch_swing;
static int	sound_punch_hit;
static int	sound_sight;
static int	sound_search;
static int	sound_idle;

static const mframe_t infantry_frames_stand [] = {
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
static var mmove_t infantry_move_stand = { FRAME_stand50, FRAME_stand71 };

void(entity self) infantry_stand =
{
	self->monsterinfo.currentmove = &infantry_move_stand;
}

static const mframe_t infantry_frames_fidget [] = {
	{ ai_stand, 1 },
	{ ai_stand, 0 },
	{ ai_stand, 1 },
	{ ai_stand, 3 },
	{ ai_stand, 6 },
	{ ai_stand, 3 },
	{ ai_stand, 0 },
	{ ai_stand, 0 },
	{ ai_stand, 0 },
	{ ai_stand, 0 },
	{ ai_stand, 1 },
	{ ai_stand, 0 },
	{ ai_stand, 0 },
	{ ai_stand, 0 },
	{ ai_stand, 0 },
	{ ai_stand, 1 },
	{ ai_stand, 0 },
	{ ai_stand, -1 },
	{ ai_stand, 0 },
	{ ai_stand, 0 },
	{ ai_stand, 1 },
	{ ai_stand, 0 },
	{ ai_stand, -2 },
	{ ai_stand, 1 },
	{ ai_stand, 1 },
	{ ai_stand, 1 },
	{ ai_stand, -1 },
	{ ai_stand, 0 },
	{ ai_stand, 0 },
	{ ai_stand, -1 },
	{ ai_stand, 0 },
	{ ai_stand, 0 },
	{ ai_stand, 0 },
	{ ai_stand, 0 },
	{ ai_stand, 0 },
	{ ai_stand, -1 },
	{ ai_stand, 0 },
	{ ai_stand, 0 },
	{ ai_stand, 1 },
	{ ai_stand, 0 },
	{ ai_stand, 0 },
	{ ai_stand, -1 },
	{ ai_stand, -1 },
	{ ai_stand, 0 },
	{ ai_stand, -3 },
	{ ai_stand, -2 },
	{ ai_stand, -3 },
	{ ai_stand, -3 },
	{ ai_stand, -2 }
};
static var mmove_t infantry_move_fidget = { FRAME_stand01, FRAME_stand49, infantry_stand };

static void(entity self) infantry_fidget =
{
	self->monsterinfo.currentmove = &infantry_move_fidget;

	gi.sound(self, CHAN_VOICE, sound_idle, 1, ATTN_IDLE, 0);
}

static const mframe_t infantry_frames_walk [] = {
	{ ai_walk, 5 },
	{ ai_walk, 4 },
	{ ai_walk, 4 },
	{ ai_walk, 5 },
	{ ai_walk, 4 },
	{ ai_walk, 5 },
	{ ai_walk, 6 },
	{ ai_walk, 4 },
	{ ai_walk, 4 },
	{ ai_walk, 4 },
	{ ai_walk, 4 },
	{ ai_walk, 5 }
};
static var mmove_t infantry_move_walk = { FRAME_walk03, FRAME_walk14 };

static void(entity self) infantry_walk =
{
	self->monsterinfo.currentmove = &infantry_move_walk;
}

static const mframe_t infantry_frames_run [] = {
	{ ai_run, 10 },
	{ ai_run, 20 },
	{ ai_run, 5 },
	{ ai_run, 7 },
	{ ai_run, 30 },
	{ ai_run, 35 },
	{ ai_run, 2 },
	{ ai_run, 6 }
};
static var mmove_t infantry_move_run = { FRAME_run01, FRAME_run08 };

static void(entity self) infantry_run =
{
	if (self->monsterinfo.aiflags & AI_STAND_GROUND)
		self->monsterinfo.currentmove = &infantry_move_stand;
	else
		self->monsterinfo.currentmove = &infantry_move_run;
}

static const mframe_t infantry_frames_pain1 [] = {
	{ ai_move, -3 },
	{ ai_move, -2 },
	{ ai_move, -1 },
	{ ai_move, -2 },
	{ ai_move, -1 },
	{ ai_move, 1 },
	{ ai_move, -1 },
	{ ai_move, 1 },
	{ ai_move, 6 },
	{ ai_move, 2 }
};
static var mmove_t infantry_move_pain1 = { FRAME_pain101, FRAME_pain110, infantry_run };

static const mframe_t infantry_frames_pain2 [] = {
	{ ai_move, -3 },
	{ ai_move, -3 },
	{ ai_move, 0 },
	{ ai_move, -1 },
	{ ai_move, -2 },
	{ ai_move, 0 },
	{ ai_move, 0 },
	{ ai_move, 2 },
	{ ai_move, 5 },
	{ ai_move, 2 }
};
static var mmove_t infantry_move_pain2 = { FRAME_pain201, FRAME_pain210, infantry_run };

static void(entity self, entity other, float kick, int damage) infantry_pain =
{
	int     n;

	if (self->health < (self->max_health / 2))
		self->s.skinnum = 1;

	if (level.framenum < self->pain_debounce_framenum)
		return;

	self->pain_debounce_framenum = level.framenum + 3 * BASE_FRAMERATE;

	if (skill->intVal == 3)
		return;     // no pain anims in nightmare

	n = Q_rand() % 2;
	if (n == 0) {
		self->monsterinfo.currentmove = &infantry_move_pain1;
		gi.sound(self, CHAN_VOICE, sound_pain1, 1, ATTN_NORM, 0);
	} else {
		self->monsterinfo.currentmove = &infantry_move_pain2;
		gi.sound(self, CHAN_VOICE, sound_pain2, 1, ATTN_NORM, 0);
	}
}


static const vector aimangles[] = {
	{ 0.0, 5.0, 0.0 },
	{ 10.0, 15.0, 0.0 },
	{ 20.0, 25.0, 0.0 },
	{ 25.0, 35.0, 0.0 },
	{ 30.0, 40.0, 0.0 },
	{ 30.0, 45.0, 0.0 },
	{ 25.0, 50.0, 0.0 },
	{ 20.0, 40.0, 0.0 },
	{ 15.0, 35.0, 0.0 },
	{ 40.0, 35.0, 0.0 },
	{ 70.0, 35.0, 0.0 },
	{ 90.0, 35.0, 0.0 }
};

static void(entity self) InfantryMachineGun =
{
	vector	start = vec3_origin, target;
	vector	forward, right;
	vector	vec;
	int     flash_number;

	if (self->s.frame == FRAME_attak111) {
		flash_number = MZ2_INFANTRY_MACHINEGUN_1;
		
		AngleVectors(self->s.angles, forward, right, unref_vec);
		G_ProjectSource(self->s.origin, monster_flash_offset[MZ2_INFANTRY_MACHINEGUN_1], forward, right, start);

		if (self->enemy) {
			VectorMA(self->enemy->s.origin, -0.2f, self->enemy->velocity, target);
			target_z += self->enemy->viewheight;
			VectorSubtract(target, start, forward);
			VectorNormalize(forward);
		} else {
			AngleVectors(self->s.angles, forward, right, unref_vec);
		}
	} else {
		flash_number = MZ2_INFANTRY_MACHINEGUN_2 + (self->s.frame - FRAME_death211);

		AngleVectors(self->s.angles, forward, right, unref_vec);
		G_ProjectSource(self->s.origin, monster_flash_offset[flash_number], forward, right, start);

		VectorSubtract(self->s.angles, aimangles[(flash_number - MZ2_INFANTRY_MACHINEGUN_2)], vec);
		AngleVectors(vec, forward, unref_vec, unref_vec);
	}

	monster_fire_bullet(self, start, forward, 3, 4, DEFAULT_BULLET_HSPREAD, DEFAULT_BULLET_VSPREAD, flash_number);
}

static void(entity self, entity other) infantry_sight =
{
	gi.sound(self, CHAN_BODY, sound_sight, 1, ATTN_NORM, 0);
}

static void(entity self) infantry_dead =
{
	VectorSet(self->mins, -16, -16, -24);
	VectorSet(self->maxs, 16, 16, -8);
	self->movetype = MOVETYPE_TOSS;
	self->svflags |= SVF_DEADMONSTER;
	gi.linkentity(self);

	M_FlyCheck(self);
}

static const mframe_t infantry_frames_death1 [] = {
	{ ai_move, -4 },
	{ ai_move, 0, },
	{ ai_move, 0, },
	{ ai_move, -1 },
	{ ai_move, -4 },
	{ ai_move, 0 },
	{ ai_move, 0 },
	{ ai_move, 0 },
	{ ai_move, -1 },
	{ ai_move, 3 },
	{ ai_move, 1 },
	{ ai_move, 1 },
	{ ai_move, -2 },
	{ ai_move, 2 },
	{ ai_move, 2 },
	{ ai_move, 9 },
	{ ai_move, 9 },
	{ ai_move, 5 },
	{ ai_move, -3 },
	{ ai_move, -3 }
};
static var mmove_t infantry_move_death1 = { FRAME_death101, FRAME_death120, infantry_dead };

// Off with his head
static const mframe_t infantry_frames_death2 [] = {
	{ ai_move, 0 },
	{ ai_move, 1 },
	{ ai_move, 5 },
	{ ai_move, -1 },
	{ ai_move, 0 },
	{ ai_move, 1 },
	{ ai_move, 1 },
	{ ai_move, 4 },
	{ ai_move, 3 },
	{ ai_move, 0 },
	{ ai_move, -2,  InfantryMachineGun },
	{ ai_move, -2,  InfantryMachineGun },
	{ ai_move, -3,  InfantryMachineGun },
	{ ai_move, -1,  InfantryMachineGun },
	{ ai_move, -2,  InfantryMachineGun },
	{ ai_move, 0,   InfantryMachineGun },
	{ ai_move, 2,   InfantryMachineGun },
	{ ai_move, 2,   InfantryMachineGun },
	{ ai_move, 3,   InfantryMachineGun },
	{ ai_move, -10, InfantryMachineGun },
	{ ai_move, -7,  InfantryMachineGun },
	{ ai_move, -8,  InfantryMachineGun },
	{ ai_move, -6 },
	{ ai_move, 4 },
	{ ai_move, 0 }
};
static var mmove_t infantry_move_death2 = { FRAME_death201, FRAME_death225, infantry_dead };

static const mframe_t infantry_frames_death3 [] = {
	{ ai_move, 0 },
	{ ai_move, 0 },
	{ ai_move, 0 },
	{ ai_move, -6 },
	{ ai_move, -11 },
	{ ai_move, -3 },
	{ ai_move, -11 },
	{ ai_move, 0 },
	{ ai_move, 0 }
};
static var mmove_t infantry_move_death3 = { FRAME_death301, FRAME_death309, infantry_dead };

void(entity self, entity inflictor, entity attacker, int damage, vector point) infantry_die =
{
	int     n;

// check for gib
	if (self->health <= self->gib_health) {
		gi.sound(self, CHAN_VOICE, gi.soundindex("misc/udeath.wav"), 1, ATTN_NORM, 0);
		for (n = 0; n < 2; n++)
			ThrowGib(self, "models/objects/gibs/bone/tris.md2", damage, GIB_ORGANIC);
		for (n = 0; n < 4; n++)
			ThrowGib(self, "models/objects/gibs/sm_meat/tris.md2", damage, GIB_ORGANIC);
		ThrowHead(self, "models/objects/gibs/head2/tris.md2", damage, GIB_ORGANIC);
		self->deadflag = DEAD_DEAD;
		return;
	}

	if (self->deadflag == DEAD_DEAD)
		return;

// regular death
	self->deadflag = DEAD_DEAD;
	self->takedamage = DAMAGE_YES;

	n = Q_rand() % 3;
	if (n == 0) {
		self->monsterinfo.currentmove = &infantry_move_death1;
		gi.sound(self, CHAN_VOICE, sound_die2, 1, ATTN_NORM, 0);
	} else if (n == 1) {
		self->monsterinfo.currentmove = &infantry_move_death2;
		gi.sound(self, CHAN_VOICE, sound_die1, 1, ATTN_NORM, 0);
	} else {
		self->monsterinfo.currentmove = &infantry_move_death3;
		gi.sound(self, CHAN_VOICE, sound_die2, 1, ATTN_NORM, 0);
	}
}


static void(entity self) infantry_duck_down =
{
	if (self->monsterinfo.aiflags & AI_DUCKED)
		return;
	self->monsterinfo.aiflags |= AI_DUCKED;
	self->maxs_z -= 32;
	self->takedamage = DAMAGE_YES;
	self->monsterinfo.pause_framenum = level.framenum + 1 * BASE_FRAMERATE;
	gi.linkentity(self);
}

static void(entity self) infantry_duck_hold =
{
	if (level.framenum >= self->monsterinfo.pause_framenum)
		self->monsterinfo.aiflags &= ~AI_HOLD_FRAME;
	else
		self->monsterinfo.aiflags |= AI_HOLD_FRAME;
}

static void(entity self) infantry_duck_up =
{
	self->monsterinfo.aiflags &= ~AI_DUCKED;
	self->maxs_z += 32;
	self->takedamage = DAMAGE_AIM;
	gi.linkentity(self);
}

static mframe_t infantry_frames_duck [] = {
	{ ai_move, -2, infantry_duck_down },
	{ ai_move, -5, infantry_duck_hold },
	{ ai_move, 3 },
	{ ai_move, 4, infantry_duck_up },
	{ ai_move, 0 }
};
static var mmove_t infantry_move_duck = { FRAME_duck01, FRAME_duck05, infantry_run };

static void(entity self, entity attacker, float eta) infantry_dodge =
{
	if (random() > 0.25f)
		return;

	if (!self->enemy)
		self->enemy = attacker;

	self->monsterinfo.currentmove = &infantry_move_duck;
}


static void(entity self) infantry_cock_gun =
{
	int     n;

	gi.sound(self, CHAN_WEAPON, sound_weapon_cock, 1, ATTN_NORM, 0);
	n = (Q_rand() & 15) + 3 + 7;
	self->monsterinfo.pause_framenum = level.framenum + n;
}

static void(entity self) infantry_fire =
{
	InfantryMachineGun(self);

	if (level.framenum >= self->monsterinfo.pause_framenum)
		self->monsterinfo.aiflags &= ~AI_HOLD_FRAME;
	else
		self->monsterinfo.aiflags |= AI_HOLD_FRAME;
}

static mframe_t infantry_frames_attack1 [] = {
	{ ai_charge, 4 },
	{ ai_charge, -1 },
	{ ai_charge, -1 },
	{ ai_charge, 0,  infantry_cock_gun },
	{ ai_charge, -1 },
	{ ai_charge, 1 },
	{ ai_charge, 1 },
	{ ai_charge, 2 },
	{ ai_charge, -2 },
	{ ai_charge, -3 },
	{ ai_charge, 1,  infantry_fire },
	{ ai_charge, 5 },
	{ ai_charge, -1 },
	{ ai_charge, -2 },
	{ ai_charge, -3 }
};
static var mmove_t infantry_move_attack1 = { FRAME_attak101, FRAME_attak115, infantry_run };


static void(entity self) infantry_swing =
{
	gi.sound(self, CHAN_WEAPON, sound_punch_swing, 1, ATTN_NORM, 0);
}

static void(entity self) infantry_smack =
{
	vector	aim;

	VectorSet(aim, MELEE_DISTANCE, 0, 0);
	if (fire_hit(self, aim, (5 + (Q_rand() % 5)), 50))
		gi.sound(self, CHAN_WEAPON, sound_punch_hit, 1, ATTN_NORM, 0);
}

static mframe_t infantry_frames_attack2 [] = {
	{ ai_charge, 3 },
	{ ai_charge, 6 },
	{ ai_charge, 0, infantry_swing },
	{ ai_charge, 8 },
	{ ai_charge, 5 },
	{ ai_charge, 8, infantry_smack },
	{ ai_charge, 6 },
	{ ai_charge, 3 },
};
static var mmove_t infantry_move_attack2 = { FRAME_attak201, FRAME_attak208, infantry_run };

static void(entity self) infantry_attack =
{
	if (range(self, self->enemy) == RANGE_MELEE)
		self->monsterinfo.currentmove = &infantry_move_attack2;
	else
		self->monsterinfo.currentmove = &infantry_move_attack1;
}


/*QUAKED monster_infantry (1 .5 0) (-16 -16 -24) (16 16 32) Ambush Trigger_Spawn Sight
*/
API_FUNC static void(entity self) SP_monster_infantry =
{
	if (deathmatch->intVal) {
		G_FreeEdict(self);
		return;
	}

	if (!infantry_move_stand->frame)
	{
		infantry_move_stand.frame = &infantry_frames_stand;
		infantry_move_fidget.frame = &infantry_frames_fidget;
		infantry_move_walk.frame = &infantry_frames_walk;
		infantry_move_run.frame = &infantry_frames_run;
		infantry_move_pain1.frame = &infantry_frames_pain1;
		infantry_move_pain2.frame = &infantry_frames_pain2;
		infantry_move_death1.frame = &infantry_frames_death1;
		infantry_move_death2.frame = &infantry_frames_death2;
		infantry_move_death3.frame = &infantry_frames_death3;
		infantry_move_duck.frame = &infantry_frames_duck;
		infantry_move_attack1.frame = &infantry_frames_attack1;
		infantry_move_attack2.frame = &infantry_frames_attack2;
	}

	sound_pain1 = gi.soundindex("infantry/infpain1.wav");
	sound_pain2 = gi.soundindex("infantry/infpain2.wav");
	sound_die1 = gi.soundindex("infantry/infdeth1.wav");
	sound_die2 = gi.soundindex("infantry/infdeth2.wav");

	sound_gunshot = gi.soundindex("infantry/infatck1.wav");
	sound_weapon_cock = gi.soundindex("infantry/infatck3.wav");
	sound_punch_swing = gi.soundindex("infantry/infatck2.wav");
	sound_punch_hit = gi.soundindex("infantry/melee2.wav");

	sound_sight = gi.soundindex("infantry/infsght1.wav");
	sound_search = gi.soundindex("infantry/infsrch1.wav");
	sound_idle = gi.soundindex("infantry/infidle1.wav");


	self->movetype = MOVETYPE_STEP;
	self->solid = SOLID_BBOX;
	self->s.modelindex = gi.modelindex("models/monsters/infantry/tris.md2");
	VectorSet(self->mins, -16, -16, -24);
	VectorSet(self->maxs, 16, 16, 32);

	self->health = 100;
	self->gib_health = -40;
	self->mass = 200;

	self->pain = infantry_pain;
	self->die = infantry_die;

	self->monsterinfo.stand = infantry_stand;
	self->monsterinfo.walk = infantry_walk;
	self->monsterinfo.run = infantry_run;
	self->monsterinfo.dodge = infantry_dodge;
	self->monsterinfo.attack = infantry_attack;
	self->monsterinfo.melee = 0;
	self->monsterinfo.sight = infantry_sight;
	self->monsterinfo.idle = infantry_fidget;

	gi.linkentity(self);

	self->monsterinfo.currentmove = &infantry_move_stand;
	self->monsterinfo.scale = MODEL_SCALE;

	walkmonster_start(self);
}
