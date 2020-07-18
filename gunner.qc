#include "m_gunner.h"

static int  sound_pain;
static int  sound_pain2;
static int  sound_death;
static int  sound_idle;
static int  sound_open;
static int  sound_search;
static int  sound_sight;

static void(entity self) gunner_idlesound =
{
	gi.sound(self, CHAN_VOICE, sound_idle, 1, ATTN_IDLE, 0);
}

static void(entity self, entity other) gunner_sight =
{
	gi.sound(self, CHAN_VOICE, sound_sight, 1, ATTN_NORM, 0);
}

static void(entity self) gunner_search =
{
	gi.sound(self, CHAN_VOICE, sound_search, 1, ATTN_NORM, 0);
}

static mframe_t gunner_frames_fidget [] = {
	{ ai_stand },
	{ ai_stand },
	{ ai_stand },
	{ ai_stand },
	{ ai_stand },
	{ ai_stand },
	{ ai_stand },
	{ ai_stand, 0, gunner_idlesound },
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
static var mmove_t gunner_move_fidget = { FRAME_stand31, FRAME_stand70 };

static void(entity self) gunner_fidget =
{
	if (self->monsterinfo.aiflags & AI_STAND_GROUND)
		return;
	if (random() <= 0.05f)
		self->monsterinfo.currentmove = &gunner_move_fidget;
}

static mframe_t gunner_frames_stand [] = {
	{ ai_stand },
	{ ai_stand },
	{ ai_stand },
	{ ai_stand },
	{ ai_stand },
	{ ai_stand },
	{ ai_stand },
	{ ai_stand },
	{ ai_stand },
	{ ai_stand, 0, gunner_fidget },

	{ ai_stand },
	{ ai_stand },
	{ ai_stand },
	{ ai_stand },
	{ ai_stand },
	{ ai_stand },
	{ ai_stand },
	{ ai_stand },
	{ ai_stand },
	{ ai_stand, 0, gunner_fidget },

	{ ai_stand },
	{ ai_stand },
	{ ai_stand },
	{ ai_stand },
	{ ai_stand },
	{ ai_stand },
	{ ai_stand },
	{ ai_stand },
	{ ai_stand },
	{ ai_stand, 0, gunner_fidget }
};
static var mmove_t gunner_move_stand = { FRAME_stand01, FRAME_stand30 };

static void(entity self) gunner_stand =
{
	self->monsterinfo.currentmove = &gunner_move_stand;
}

static mframe_t gunner_frames_walk [] = {
	{ ai_walk },
	{ ai_walk, 3 },
	{ ai_walk, 4 },
	{ ai_walk, 5 },
	{ ai_walk, 7 },
	{ ai_walk, 2 },
	{ ai_walk, 6 },
	{ ai_walk, 4 },
	{ ai_walk, 2 },
	{ ai_walk, 7 },
	{ ai_walk, 5 },
	{ ai_walk, 7 },
	{ ai_walk, 4 }
};
static var mmove_t gunner_move_walk = { FRAME_walk07, FRAME_walk19 };

static void(entity self) gunner_walk =
{
	self->monsterinfo.currentmove = &gunner_move_walk;
}

static mframe_t gunner_frames_run [] = {
	{ ai_run, 26 },
	{ ai_run, 9 },
	{ ai_run, 9 },
	{ ai_run, 9 },
	{ ai_run, 15 },
	{ ai_run, 10 },
	{ ai_run, 13 },
	{ ai_run, 6 }
};
static var mmove_t gunner_move_run = { FRAME_run01, FRAME_run08 };

static void(entity self) gunner_run =
{
	if (self->monsterinfo.aiflags & AI_STAND_GROUND)
		self->monsterinfo.currentmove = &gunner_move_stand;
	else
		self->monsterinfo.currentmove = &gunner_move_run;
}

static mframe_t gunner_frames_pain3 [] = {
	{ ai_move, -3 },
	{ ai_move, 1 },
	{ ai_move, 1 },
	{ ai_move },
	{ ai_move, 1 }
};
static var mmove_t gunner_move_pain3 = { FRAME_pain301, FRAME_pain305, gunner_run };

static mframe_t gunner_frames_pain2 [] = {
	{ ai_move, -2 },
	{ ai_move, 11 },
	{ ai_move, 6 },
	{ ai_move, 2 },
	{ ai_move, -1 },
	{ ai_move, -7 },
	{ ai_move, -2 },
	{ ai_move, -7 }
};
static var mmove_t gunner_move_pain2 = { FRAME_pain201, FRAME_pain208, gunner_run };

static mframe_t gunner_frames_pain1 [] = {
	{ ai_move, 2 },
	{ ai_move },
	{ ai_move, -5 },
	{ ai_move, 3 },
	{ ai_move, -1 },
	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move, 1 },
	{ ai_move, 1 },
	{ ai_move, 2 },
	{ ai_move, 1 },
	{ ai_move },
	{ ai_move, -2 },
	{ ai_move, -2 },
	{ ai_move },
	{ ai_move }
};
static var mmove_t gunner_move_pain1 = { FRAME_pain101, FRAME_pain118, gunner_run };

static void(entity self, entity other, float kick, int damage) gunner_pain =
{
	if (self->health < (self->max_health / 2))
		self->s.skinnum = 1;

	if (level.framenum < self->pain_debounce_framenum)
		return;

	self->pain_debounce_framenum = level.framenum + 3 * BASE_FRAMERATE;

	if (Q_rand() & 1)
		gi.sound(self, CHAN_VOICE, sound_pain, 1, ATTN_NORM, 0);
	else
		gi.sound(self, CHAN_VOICE, sound_pain2, 1, ATTN_NORM, 0);

	if (skill->intVal == 3)
		return;     // no pain anims in nightmare

	if (damage <= 10)
		self->monsterinfo.currentmove = &gunner_move_pain3;
	else if (damage <= 25)
		self->monsterinfo.currentmove = &gunner_move_pain2;
	else
		self->monsterinfo.currentmove = &gunner_move_pain1;
}

static void(entity self) gunner_dead =
{
	VectorSet(self->mins, -16, -16, -24);
	VectorSet(self->maxs, 16, 16, -8);
	self->movetype = MOVETYPE_TOSS;
	self->svflags |= SVF_DEADMONSTER;
	self->nextthink = 0;
	gi.linkentity(self);
}

static mframe_t gunner_frames_death [] = {
	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move, -7 },
	{ ai_move, -3 },
	{ ai_move, -5 },
	{ ai_move, 8 },
	{ ai_move, 6 },
	{ ai_move },
	{ ai_move },
	{ ai_move }
};
static var mmove_t gunner_move_death = { FRAME_death01, FRAME_death11, gunner_dead };

static void(entity self, entity inflictor, entity attacker, int damage, vector point) gunner_die =
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
	gi.sound(self, CHAN_VOICE, sound_death, 1, ATTN_NORM, 0);
	self->deadflag = DEAD_DEAD;
	self->takedamage = DAMAGE_YES;
	self->monsterinfo.currentmove = &gunner_move_death;
}

static void(entity self) GunnerGrenade;

static void(entity self) gunner_duck_down =
{
	if (self->monsterinfo.aiflags & AI_DUCKED)
		return;
	self->monsterinfo.aiflags |= AI_DUCKED;
	if (skill->intVal >= 2) {
		if (random() > 0.5f)
			GunnerGrenade(self);
	}

	self->maxs_z -= 32;
	self->takedamage = DAMAGE_YES;
	self->monsterinfo.pause_framenum = level.framenum + 1 * BASE_FRAMERATE;
	gi.linkentity(self);
}

static void(entity self) gunner_duck_hold =
{
	if (level.framenum >= self->monsterinfo.pause_framenum)
		self->monsterinfo.aiflags &= ~AI_HOLD_FRAME;
	else
		self->monsterinfo.aiflags |= AI_HOLD_FRAME;
}

static void(entity self) gunner_duck_up =
{
	self->monsterinfo.aiflags &= ~AI_DUCKED;
	self->maxs_z += 32;
	self->takedamage = DAMAGE_AIM;
	gi.linkentity(self);
}

static mframe_t gunner_frames_duck [] = {
	{ ai_move, 1,  gunner_duck_down },
	{ ai_move, 1 },
	{ ai_move, 1,  gunner_duck_hold },
	{ ai_move },
	{ ai_move, -1 },
	{ ai_move, -1 },
	{ ai_move, 0,  gunner_duck_up },
	{ ai_move, -1 }
};
static var mmove_t gunner_move_duck = { FRAME_duck01, FRAME_duck08, gunner_run };

static void(entity self, entity attacker, float eta) gunner_dodge =
{
	if (random() > 0.25f)
		return;

	if (!self->enemy)
		self->enemy = attacker;

	self->monsterinfo.currentmove = &gunner_move_duck;
}

static void(entity self) gunner_opengun =
{
	gi.sound(self, CHAN_VOICE, sound_open, 1, ATTN_IDLE, 0);
}

static void(entity self) GunnerFire =
{
	vector	start;
	vector	forward, right;
	vector	target;
	vector	aim;
	int	flash_number;

	flash_number = MZ2_GUNNER_MACHINEGUN_1 + (self->s.frame - FRAME_attak216);

	AngleVectors(self->s.angles, forward, right, unref_vec);
	G_ProjectSource(self->s.origin, monster_flash_offset[flash_number], forward, right, start);

	// project enemy back a bit and target there
	VectorCopy(self->enemy->s.origin, target);
	VectorMA(target, -0.2f, self->enemy->velocity, target);
	target_z += self->enemy->viewheight;

	VectorSubtract(target, start, aim);
	VectorNormalize(aim);
	monster_fire_bullet(self, start, aim, 3, 4, DEFAULT_BULLET_HSPREAD, DEFAULT_BULLET_VSPREAD, flash_number);
}

static void(entity self) GunnerGrenade =
{
	vector	start;
	vector	forward, right;
	vector	aim;
	int	flash_number;

	if (self->s.frame == FRAME_attak105)
		flash_number = MZ2_GUNNER_GRENADE_1;
	else if (self->s.frame == FRAME_attak108)
		flash_number = MZ2_GUNNER_GRENADE_2;
	else if (self->s.frame == FRAME_attak111)
		flash_number = MZ2_GUNNER_GRENADE_3;
	else // (self->s.frame == FRAME_attak114)
		flash_number = MZ2_GUNNER_GRENADE_4;

	AngleVectors(self->s.angles, forward, right, unref_vec);
	G_ProjectSource(self->s.origin, monster_flash_offset[flash_number], forward, right, start);

	//FIXME : do a spread -225 -75 75 225 degrees around forward
	VectorCopy(forward, aim);

	monster_fire_grenade(self, start, aim, 50, 600, flash_number);
}

static mframe_t gunner_frames_attack_chain [] = {
	{ ai_charge, 0, gunner_opengun },
	{ ai_charge },
	{ ai_charge },
	{ ai_charge },
	{ ai_charge },
	{ ai_charge },
	{ ai_charge }
};
static var mmove_t gunner_move_attack_chain = { FRAME_attak209, FRAME_attak215 };

static mframe_t gunner_frames_fire_chain [] = {
	{ ai_charge,   0, GunnerFire },
	{ ai_charge,   0, GunnerFire },
	{ ai_charge,   0, GunnerFire },
	{ ai_charge,   0, GunnerFire },
	{ ai_charge,   0, GunnerFire },
	{ ai_charge,   0, GunnerFire },
	{ ai_charge,   0, GunnerFire },
	{ ai_charge,   0, GunnerFire }
};
static var mmove_t gunner_move_fire_chain = { FRAME_attak216, FRAME_attak223 };

static mframe_t gunner_frames_endfire_chain [] = {
	{ ai_charge },
	{ ai_charge },
	{ ai_charge },
	{ ai_charge },
	{ ai_charge },
	{ ai_charge },
	{ ai_charge }
};
static var mmove_t gunner_move_endfire_chain = { FRAME_attak224, FRAME_attak230, gunner_run };

static mframe_t gunner_frames_attack_grenade [] = {
	{ ai_charge },
	{ ai_charge },
	{ ai_charge },
	{ ai_charge },
	{ ai_charge, 0, GunnerGrenade },
	{ ai_charge },
	{ ai_charge },
	{ ai_charge, 0, GunnerGrenade },
	{ ai_charge },
	{ ai_charge },
	{ ai_charge, 0, GunnerGrenade },
	{ ai_charge },
	{ ai_charge },
	{ ai_charge, 0, GunnerGrenade },
	{ ai_charge },
	{ ai_charge },
	{ ai_charge },
	{ ai_charge },
	{ ai_charge },
	{ ai_charge },
	{ ai_charge }
};
static var mmove_t gunner_move_attack_grenade = { FRAME_attak101, FRAME_attak121, gunner_run };

static void(entity self) gunner_attack =
{
	if (range(self, self->enemy) == RANGE_MELEE) {
		self->monsterinfo.currentmove = &gunner_move_attack_chain;
	} else {
		if (random() <= 0.5f)
			self->monsterinfo.currentmove = &gunner_move_attack_grenade;
		else
			self->monsterinfo.currentmove = &gunner_move_attack_chain;
	}
}

static void(entity self) gunner_fire_chain =
{
	self->monsterinfo.currentmove = &gunner_move_fire_chain;
}

static void(entity self) gunner_refire_chain =
{
	if (self->enemy->health > 0)
		if (visible(self, self->enemy))
			if (random() <= 0.5f) {
				self->monsterinfo.currentmove = &gunner_move_fire_chain;
				return;
			}
	self->monsterinfo.currentmove = &gunner_move_endfire_chain;
}

/*QUAKED monster_gunner (1 .5 0) (-16 -16 -24) (16 16 32) Ambush Trigger_Spawn Sight
*/
API_FUNC static void(entity self) SP_monster_gunner =
{
	if (deathmatch->intVal) {
		G_FreeEdict(self);
		return;
	}
	
	if (!gunner_move_fidget.frame)
	{
		gunner_move_fidget.frame = &gunner_frames_fidget;
		gunner_move_fidget.endfunc = gunner_stand;

		gunner_move_stand.frame = &gunner_frames_stand;

		gunner_move_walk.frame = &gunner_frames_walk;

		gunner_move_run.frame = &gunner_frames_run;

		gunner_move_pain3.frame = &gunner_frames_pain3;
		gunner_move_pain2.frame = &gunner_frames_pain2;
		gunner_move_pain1.frame = &gunner_frames_pain1;

		gunner_move_death.frame = &gunner_frames_death;

		gunner_move_duck.frame = &gunner_frames_duck;

		gunner_move_attack_chain.frame = &gunner_frames_attack_chain;
		gunner_move_attack_chain.endfunc = gunner_fire_chain;

		gunner_move_fire_chain.frame = &gunner_frames_fire_chain;
		gunner_move_fire_chain.endfunc = gunner_refire_chain;

		gunner_move_endfire_chain.frame = &gunner_frames_endfire_chain;

		gunner_move_attack_grenade.frame = &gunner_frames_attack_grenade;
	}

	sound_death = gi.soundindex("gunner/death1.wav");
	sound_pain = gi.soundindex("gunner/gunpain2.wav");
	sound_pain2 = gi.soundindex("gunner/gunpain1.wav");
	sound_idle = gi.soundindex("gunner/gunidle1.wav");
	sound_open = gi.soundindex("gunner/gunatck1.wav");
	sound_search = gi.soundindex("gunner/gunsrch1.wav");
	sound_sight = gi.soundindex("gunner/sight1.wav");

	gi.soundindex("gunner/gunatck2.wav");
	gi.soundindex("gunner/gunatck3.wav");

	self->movetype = MOVETYPE_STEP;
	self->solid = SOLID_BBOX;
	self->s.modelindex = gi.modelindex("models/monsters/gunner/tris.md2");
	VectorSet(self->mins, -16, -16, -24);
	VectorSet(self->maxs, 16, 16, 32);

	self->health = 175;
	self->gib_health = -70;
	self->mass = 200;

	self->pain = gunner_pain;
	self->die = gunner_die;

	self->monsterinfo.stand = gunner_stand;
	self->monsterinfo.walk = gunner_walk;
	self->monsterinfo.run = gunner_run;
	self->monsterinfo.dodge = gunner_dodge;
	self->monsterinfo.attack = gunner_attack;
	self->monsterinfo.melee = 0;
	self->monsterinfo.sight = gunner_sight;
	self->monsterinfo.search = gunner_search;

	gi.linkentity(self);

	self->monsterinfo.currentmove = &gunner_move_stand;
	self->monsterinfo.scale = MODEL_SCALE;

	walkmonster_start(self);
}
