#include "m_berserk.h"

static int sound_pain;
static int sound_die;
static int sound_idle;
static int sound_punch;
static int sound_sight;
static int sound_search;

static void(entity self, entity other) berserk_sight =
{
	gi.sound(self, CHAN_VOICE, sound_sight, 1, ATTN_NORM, 0);
}

static void(entity self) berserk_search =
{
	gi.sound(self, CHAN_VOICE, sound_search, 1, ATTN_NORM, 0);
}

static mframe_t berserk_frames_stand_fidget [] = {
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
static var mmove_t berserk_move_stand_fidget = { FRAME_standb1, FRAME_standb20 };

static void(entity self) berserk_fidget =
{
	if (self->monsterinfo.aiflags & AI_STAND_GROUND)
		return;
	if (random() > 0.15f)
		return;

	self->monsterinfo.currentmove = &berserk_move_stand_fidget;
	gi.sound(self, CHAN_WEAPON, sound_idle, 1, ATTN_IDLE, 0);
}

static mframe_t berserk_frames_stand [] = {
	{ ai_stand, 0, berserk_fidget },
	{ ai_stand },
	{ ai_stand },
	{ ai_stand },
	{ ai_stand }
};
static var mmove_t berserk_move_stand = { FRAME_stand1, FRAME_stand5 };

static void(entity self) berserk_stand =
{
	self->monsterinfo.currentmove = &berserk_move_stand;
}

static mframe_t berserk_frames_walk [] = {
	{ ai_walk, 9.1 },
	{ ai_walk, 6.3 },
	{ ai_walk, 4.9 },
	{ ai_walk, 6.7 },
	{ ai_walk, 6.0 },
	{ ai_walk, 8.2 },
	{ ai_walk, 7.2 },
	{ ai_walk, 6.1 },
	{ ai_walk, 4.9 },
	{ ai_walk, 4.7 },
	{ ai_walk, 4.7 },
	{ ai_walk, 4.8 }
};
static var mmove_t berserk_move_walk = { FRAME_walkc1, FRAME_walkc11 };

static void(entity self) berserk_walk =
{
	self->monsterinfo.currentmove = &berserk_move_walk;
}

static mframe_t berserk_frames_run1 [] = {
	{ ai_run, 21 },
	{ ai_run, 11 },
	{ ai_run, 21 },
	{ ai_run, 25 },
	{ ai_run, 18 },
	{ ai_run, 19 }
};
static var mmove_t berserk_move_run1 = { FRAME_run1, FRAME_run6 };

static void(entity self) berserk_run =
{
	if (self->monsterinfo.aiflags & AI_STAND_GROUND)
		self->monsterinfo.currentmove = &berserk_move_stand;
	else
		self->monsterinfo.currentmove = &berserk_move_run1;
}

static void(entity self) berserk_attack_spike =
{
	static vector  aim = {MELEE_DISTANCE, 0, -24};
	fire_hit(self, aim, (15 + (Q_rand() % 6)), 400);    //  Faster attack -- upwards and backwards
}

static void(entity self) berserk_swing =
{
	gi.sound(self, CHAN_WEAPON, sound_punch, 1, ATTN_NORM, 0);
}

static mframe_t berserk_frames_attack_spike [] = {
	{ ai_charge },
	{ ai_charge },
	{ ai_charge, 0, berserk_swing },
	{ ai_charge, 0, berserk_attack_spike },
	{ ai_charge  },
	{ ai_charge },
	{ ai_charge },
	{ ai_charge }
};
static var mmove_t berserk_move_attack_spike = { FRAME_att_c1, FRAME_att_c8, berserk_run };

static void(entity self) berserk_attack_club =
{
	vector  aim;
	VectorSet(aim, MELEE_DISTANCE, self->mins_x, -4);
	fire_hit(self, aim, (5 + (Q_rand() % 6)), 400);     // Slower attack
}

static mframe_t berserk_frames_attack_club [] = {
	{ ai_charge },
	{ ai_charge },
	{ ai_charge },
	{ ai_charge },
	{ ai_charge, 0, berserk_swing },
	{ ai_charge },
	{ ai_charge },
	{ ai_charge },
	{ ai_charge, 0, berserk_attack_club },
	{ ai_charge },
	{ ai_charge },
	{ ai_charge }
};
static var mmove_t berserk_move_attack_club = { FRAME_att_c9, FRAME_att_c20, berserk_run };

static void(entity self) berserk_melee =
{
	if ((Q_rand() % 2) == 0)
		self->monsterinfo.currentmove = &berserk_move_attack_spike;
	else
		self->monsterinfo.currentmove = &berserk_move_attack_club;
}

static mframe_t berserk_frames_pain1 [] = {
	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move }
};
static var mmove_t berserk_move_pain1 = { FRAME_painc1, FRAME_painc4, berserk_run };

static mframe_t berserk_frames_pain2 [] = {
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
static var mmove_t berserk_move_pain2 = { FRAME_painb1, FRAME_painb20, berserk_run };

static void(entity self, entity other, float kick, int damage) berserk_pain =
{
	if (self->health < (self->max_health / 2))
		self->s.skinnum = 1;

	if (level.framenum < self->pain_debounce_framenum)
		return;

	self->pain_debounce_framenum = level.framenum + 3 * BASE_FRAMERATE;
	gi.sound(self, CHAN_VOICE, sound_pain, 1, ATTN_NORM, 0);

	if (skill->intVal == 3)
		return;     // no pain anims in nightmare

	if ((damage < 20) || (random() < 0.5f))
		self->monsterinfo.currentmove = &berserk_move_pain1;
	else
		self->monsterinfo.currentmove = &berserk_move_pain2;
}

static void(entity self) berserk_dead =
{
	VectorSet(self->mins, -16, -16, -24);
	VectorSet(self->maxs, 16, 16, -8);
	self->movetype = MOVETYPE_TOSS;
	self->svflags |= SVF_DEADMONSTER;
	self->nextthink = 0;
	gi.linkentity(self);
}


static mframe_t berserk_frames_death1 [] = {
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
static var mmove_t berserk_move_death1 = { FRAME_death1, FRAME_death13, berserk_dead };

static mframe_t berserk_frames_death2 [] = {
	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move }
};
static var mmove_t berserk_move_death2 = { FRAME_deathc1, FRAME_deathc8, berserk_dead };

static void(entity self, entity inflictor, entity attacker, int damage, vector point) berserk_die =
{
	int     n;

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

	gi.sound(self, CHAN_VOICE, sound_die, 1, ATTN_NORM, 0);
	self->deadflag = DEAD_DEAD;
	self->takedamage = DAMAGE_YES;

	if (damage >= 50)
		self->monsterinfo.currentmove = &berserk_move_death1;
	else
		self->monsterinfo.currentmove = &berserk_move_death2;
}

/*QUAKED monster_berserk (1 .5 0) (-16 -16 -24) (16 16 32) Ambush Trigger_Spawn Sight
*/
API_FUNC static void(entity self) SP_monster_berserk =
{
	if (deathmatch->intVal) {
		G_FreeEdict(self);
		return;
	}
	
	if (!berserk_move_stand_fidget.frame)
	{
		berserk_move_stand_fidget.frame = &berserk_frames_stand_fidget;
		berserk_move_stand_fidget.endfunc = berserk_stand;
		berserk_move_stand.frame = &berserk_frames_stand;
		berserk_move_walk.frame = &berserk_frames_walk;
		berserk_move_run1.frame = &berserk_frames_run1;
		berserk_move_attack_spike.frame = &berserk_frames_attack_spike;
		berserk_move_attack_club.frame = &berserk_frames_attack_club;
		berserk_move_pain1.frame = &berserk_frames_pain1;
		berserk_move_pain2.frame = &berserk_frames_pain2;
		berserk_move_death1.frame = &berserk_frames_death1;
		berserk_move_death2.frame = &berserk_frames_death2;
	}

	// pre-caches
	sound_pain  = gi.soundindex("berserk/berpain2.wav");
	sound_die   = gi.soundindex("berserk/berdeth2.wav");
	sound_idle  = gi.soundindex("berserk/beridle1.wav");
	sound_punch = gi.soundindex("berserk/attack.wav");
	sound_search = gi.soundindex("berserk/bersrch1.wav");
	sound_sight = gi.soundindex("berserk/sight.wav");

	self->s.modelindex = gi.modelindex("models/monsters/berserk/tris.md2");
	VectorSet(self->mins, -16, -16, -24);
	VectorSet(self->maxs, 16, 16, 32);
	self->movetype = MOVETYPE_STEP;
	self->solid = SOLID_BBOX;

	self->health = 240;
	self->gib_health = -60;
	self->mass = 250;

	self->pain = berserk_pain;
	self->die = berserk_die;

	self->monsterinfo.stand = berserk_stand;
	self->monsterinfo.walk = berserk_walk;
	self->monsterinfo.run = berserk_run;
	self->monsterinfo.dodge = 0;
	self->monsterinfo.attack = 0;
	self->monsterinfo.melee = berserk_melee;
	self->monsterinfo.sight = berserk_sight;
	self->monsterinfo.search = berserk_search;

	self->monsterinfo.currentmove = &berserk_move_stand;
	self->monsterinfo.scale = MODEL_SCALE;

	gi.linkentity(self);

	walkmonster_start(self);
}