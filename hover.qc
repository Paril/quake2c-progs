#include "m_hover.h"

static int  sound_pain1;
static int  sound_pain2;
static int  sound_death1;
static int  sound_death2;
static int  sound_sight;
static int  sound_search1;
static int  sound_search2;

static void hover_sight(entity self, entity other)
{
	gi.sound(self, CHAN_VOICE, sound_sight, 1, ATTN_NORM, 0);
}

static void hover_search(entity self)
{
	if (random() < 0.5f)
		gi.sound(self, CHAN_VOICE, sound_search1, 1, ATTN_NORM, 0);
	else
		gi.sound(self, CHAN_VOICE, sound_search2, 1, ATTN_NORM, 0);
}

static mframe_t hover_frames_stand [] = {
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
static var mmove_t hover_move_stand = { FRAME_stand01, FRAME_stand30 };

static mframe_t hover_frames_pain3 [] = {
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
static var mmove_t hover_move_pain3 = { FRAME_pain301, FRAME_pain309 };

static mframe_t hover_frames_pain2 [] = {
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
static var mmove_t hover_move_pain2 = { FRAME_pain201, FRAME_pain212 };

static mframe_t hover_frames_pain1 [] = {
	{ ai_move },
	{ ai_move },
	{ ai_move,    2 },
	{ ai_move,    -8 },
	{ ai_move,    -4 },
	{ ai_move,    -6 },
	{ ai_move,    -4 },
	{ ai_move,    -3 },
	{ ai_move,    1 },
	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move,    3 },
	{ ai_move,    1 },
	{ ai_move },
	{ ai_move,    2 },
	{ ai_move,    3 },
	{ ai_move,    2 },
	{ ai_move,    7 },
	{ ai_move,    1 },
	{ ai_move },
	{ ai_move },
	{ ai_move,    2 },
	{ ai_move },
	{ ai_move },
	{ ai_move,    5 },
	{ ai_move,    3 },
	{ ai_move,    4 }
};
static var mmove_t hover_move_pain1 = { FRAME_pain101, FRAME_pain128 };

static mframe_t hover_frames_walk [] = {
	{ ai_walk,    4 },
	{ ai_walk,    4 },
	{ ai_walk,    4 },
	{ ai_walk,    4 },
	{ ai_walk,    4 },
	{ ai_walk,    4 },
	{ ai_walk,    4 },
	{ ai_walk,    4 },
	{ ai_walk,    4 },
	{ ai_walk,    4 },
	{ ai_walk,    4 },
	{ ai_walk,    4 },
	{ ai_walk,    4 },
	{ ai_walk,    4 },
	{ ai_walk,    4 },
	{ ai_walk,    4 },
	{ ai_walk,    4 },
	{ ai_walk,    4 },
	{ ai_walk,    4 },
	{ ai_walk,    4 },
	{ ai_walk,    4 },
	{ ai_walk,    4 },
	{ ai_walk,    4 },
	{ ai_walk,    4 },
	{ ai_walk,    4 },
	{ ai_walk,    4 },
	{ ai_walk,    4 },
	{ ai_walk,    4 },
	{ ai_walk,    4 },
	{ ai_walk,    4 },
	{ ai_walk,    4 },
	{ ai_walk,    4 },
	{ ai_walk,    4 },
	{ ai_walk,    4 },
	{ ai_walk,    4 }
};
static var mmove_t hover_move_walk = { FRAME_forwrd01, FRAME_forwrd35 };

static mframe_t hover_frames_run [] = {
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
static var mmove_t hover_move_run = { FRAME_forwrd01, FRAME_forwrd35 };

static mframe_t hover_frames_death1 [] = {
	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move,    -10 },
	{ ai_move,    3 },
	{ ai_move,    5 },
	{ ai_move,    4 },
	{ ai_move,    7 }
};
static var mmove_t hover_move_death1 = { FRAME_death101, FRAME_death111 };

static mframe_t hover_frames_start_attack [] = {
	{ ai_charge,  1 },
	{ ai_charge,  1 },
	{ ai_charge,  1 }
};
static var mmove_t hover_move_start_attack = { FRAME_attak101, FRAME_attak103 };

static mframe_t hover_frames_end_attack [] = {
	{ ai_charge,  1 },
	{ ai_charge,  1 }
};
static var mmove_t hover_move_end_attack = { FRAME_attak107, FRAME_attak108 };

static void hover_attack1(entity self);

static void hover_reattack(entity self)
{
	if (self->enemy->health > 0)
		if (visible(self, self->enemy))
			if (random() <= 0.6f) {
				hover_attack1(self);
				return;
			}
	self->monsterinfo.currentmove = &hover_move_end_attack;
}

static void hover_fire_blaster(entity self)
{
	vector  start;
	vector  forward, right;
	vector  end;
	vector  dir;
	int     effect;

	if (self->s.frame == FRAME_attak104)
		effect = EF_HYPERBLASTER;
	else
		effect = 0;

	AngleVectors(self->s.angles, &forward, &right, 0);
	G_ProjectSource(self->s.origin, monster_flash_offset[MZ2_HOVER_BLASTER_1], forward, right, start);

	VectorCopy(self->enemy->s.origin, end);
	end[2] += self->enemy->viewheight;
	VectorSubtract(end, start, dir);

	monster_fire_blaster(self, start, dir, 1, 1000, MZ2_HOVER_BLASTER_1, effect);
}

static mframe_t hover_frames_attack1 [] = {
	{ ai_charge,  -10,    hover_fire_blaster },
	{ ai_charge,  -10,    hover_fire_blaster },
	{ ai_charge,  0,      hover_reattack },
};
static var mmove_t hover_move_attack1 = {FRAME_attak104, FRAME_attak106 };

static void hover_attack1(entity self)
{
	self->monsterinfo.currentmove = &hover_move_attack1;
}

static void hover_stand(entity self)
{
	self->monsterinfo.currentmove = &hover_move_stand;
}

static void hover_run(entity self)
{
	if (self->monsterinfo.aiflags & AI_STAND_GROUND)
		self->monsterinfo.currentmove = &hover_move_stand;
	else
		self->monsterinfo.currentmove = &hover_move_run;
}

static void hover_walk(entity self)
{
	self->monsterinfo.currentmove = &hover_move_walk;
}

static void hover_start_attack(entity self)
{
	self->monsterinfo.currentmove = &hover_move_start_attack;
}

static void hover_attack(entity self)
{
	self->monsterinfo.currentmove = &hover_move_attack1;
}


static void hover_pain(entity self, entity other, float kick, int damage)
{
	if (self->health < (self->max_health / 2))
		self->s.skinnum = 1;

	if (level.framenum < self->pain_debounce_framenum)
		return;

	self->pain_debounce_framenum = level.framenum + 3 * BASE_FRAMERATE;

	if (skill->intVal == 3)
		return;     // no pain anims in nightmare

	if (damage <= 25) {
		if (random() < 0.5f) {
			gi.sound(self, CHAN_VOICE, sound_pain1, 1, ATTN_NORM, 0);
			self->monsterinfo.currentmove = &hover_move_pain3;
		} else {
			gi.sound(self, CHAN_VOICE, sound_pain2, 1, ATTN_NORM, 0);
			self->monsterinfo.currentmove = &hover_move_pain2;
		}
	} else {
		gi.sound(self, CHAN_VOICE, sound_pain1, 1, ATTN_NORM, 0);
		self->monsterinfo.currentmove = &hover_move_pain1;
	}
}

static void hover_deadthink(entity self)
{
	if (self->groundentity == null_entity && level.framenum < self->timestamp) {
		self->nextthink = level.framenum + 1;
		return;
	}
	BecomeExplosion1(self);
}

static void hover_dead(entity self)
{
	self->mins = '-16 -16 -24';
	self->maxs = '16 16 -8';
	self->movetype = MOVETYPE_TOSS;
	self->think = hover_deadthink;
	self->nextthink = level.framenum + 1;
	self->timestamp = level.framenum + 15 * BASE_FRAMERATE;
	gi.linkentity(self);
}

static void hover_die(entity self, entity inflictor, entity attacker, int damage, vector point)
{
	int     n;

// check for gib
	if (self->health <= self->gib_health) {
		gi.sound(self, CHAN_VOICE, gi.soundindex("misc/udeath.wav"), 1, ATTN_NORM, 0);
		for (n = 0; n < 2; n++)
			ThrowGib(self, "models/objects/gibs/bone/tris.md2", damage, GIB_ORGANIC);
		for (n = 0; n < 2; n++)
			ThrowGib(self, "models/objects/gibs/sm_meat/tris.md2", damage, GIB_ORGANIC);
		ThrowHead(self, "models/objects/gibs/sm_meat/tris.md2", damage, GIB_ORGANIC);
		self->deadflag = DEAD_DEAD;
		return;
	}

	if (self->deadflag == DEAD_DEAD)
		return;

// regular death
	if (random() < 0.5f)
		gi.sound(self, CHAN_VOICE, sound_death1, 1, ATTN_NORM, 0);
	else
		gi.sound(self, CHAN_VOICE, sound_death2, 1, ATTN_NORM, 0);
	self->deadflag = DEAD_DEAD;
	self->takedamage = DAMAGE_YES;
	self->monsterinfo.currentmove = &hover_move_death1;
}

/*QUAKED monster_hover (1 .5 0) (-16 -16 -24) (16 16 32) Ambush Trigger_Spawn Sight
*/
API_FUNC static void SP_monster_hover(entity self)
{
	if (deathmatch->intVal) {
		G_FreeEdict(self);
		return;
	}
	
	if (!hover_move_stand.frame)
	{
		hover_move_stand.frame = &hover_frames_stand;
		hover_move_pain3.frame = &hover_frames_pain3;
		hover_move_pain3.endfunc = hover_run;
		hover_move_pain2.frame = &hover_frames_pain2;
		hover_move_pain2.endfunc = hover_run;
		hover_move_pain1.frame = &hover_frames_pain1;
		hover_move_pain1.endfunc = hover_run;
		hover_move_walk.frame = &hover_frames_walk;
		hover_move_run.frame = &hover_frames_run;
		hover_move_death1.frame = &hover_frames_death1;
		hover_move_death1.endfunc = hover_dead;
		hover_move_start_attack.frame = &hover_frames_start_attack;
		hover_move_start_attack.endfunc = hover_attack;
		hover_move_attack1.frame = &hover_frames_attack1;
		hover_move_end_attack.frame = &hover_frames_end_attack;
		hover_move_end_attack.endfunc = hover_run;
	}

	sound_pain1 = gi.soundindex("hover/hovpain1.wav");
	sound_pain2 = gi.soundindex("hover/hovpain2.wav");
	sound_death1 = gi.soundindex("hover/hovdeth1.wav");
	sound_death2 = gi.soundindex("hover/hovdeth2.wav");
	sound_sight = gi.soundindex("hover/hovsght1.wav");
	sound_search1 = gi.soundindex("hover/hovsrch1.wav");
	sound_search2 = gi.soundindex("hover/hovsrch2.wav");

	gi.soundindex("hover/hovatck1.wav");

	self->s.sound = gi.soundindex("hover/hovidle1.wav");

	self->movetype = MOVETYPE_STEP;
	self->solid = SOLID_BBOX;
	self->s.modelindex = gi.modelindex("models/monsters/hover/tris.md2");
	self->mins = '-24 -24 -24';
	self->maxs = '24 24 32';

	self->health = 240;
	self->gib_health = -100;
	self->mass = 150;

	self->pain = hover_pain;
	self->die = hover_die;

	self->monsterinfo.stand = hover_stand;
	self->monsterinfo.walk = hover_walk;
	self->monsterinfo.run = hover_run;
//  self->monsterinfo.dodge = hover_dodge;
	self->monsterinfo.attack = hover_start_attack;
	self->monsterinfo.sight = hover_sight;
	self->monsterinfo.search = hover_search;

	gi.linkentity(self);

	self->monsterinfo.currentmove = &hover_move_stand;
	self->monsterinfo.scale = MODEL_SCALE;

	flymonster_start(self);
}
