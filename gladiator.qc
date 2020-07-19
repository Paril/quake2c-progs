#include "m_gladiator.h"

static int  sound_pain1;
static int  sound_pain2;
static int  sound_die;
static int  sound_gun;
static int  sound_cleaver_swing;
static int  sound_cleaver_hit;
static int  sound_cleaver_miss;
static int  sound_idle;
static int  sound_search;
static int  sound_sight;


static void gladiator_idle(entity self)
{
	gi.sound(self, CHAN_VOICE, sound_idle, 1, ATTN_IDLE, 0);
}

static void gladiator_sight(entity self, entity other)
{
	gi.sound(self, CHAN_VOICE, sound_sight, 1, ATTN_NORM, 0);
}

static void gladiator_search(entity self)
{
	gi.sound(self, CHAN_VOICE, sound_search, 1, ATTN_NORM, 0);
}

static void gladiator_cleaver_swing(entity self)
{
	gi.sound(self, CHAN_WEAPON, sound_cleaver_swing, 1, ATTN_NORM, 0);
}

static mframe_t gladiator_frames_stand [] = {
	{ ai_stand },
	{ ai_stand },
	{ ai_stand },
	{ ai_stand },
	{ ai_stand },
	{ ai_stand },
	{ ai_stand }
};
static var mmove_t gladiator_move_stand = { FRAME_stand1, FRAME_stand7 };

static void gladiator_stand(entity self)
{
	self->monsterinfo.currentmove = &gladiator_move_stand;
}

static mframe_t gladiator_frames_walk [] = {
	{ ai_walk, 15 },
	{ ai_walk, 7 },
	{ ai_walk, 6 },
	{ ai_walk, 5 },
	{ ai_walk, 2 },
	{ ai_walk },
	{ ai_walk, 2 },
	{ ai_walk, 8 },
	{ ai_walk, 12 },
	{ ai_walk, 8 },
	{ ai_walk, 5 },
	{ ai_walk, 5 },
	{ ai_walk, 2 },
	{ ai_walk, 2 },
	{ ai_walk, 1 },
	{ ai_walk, 8 }
};
static var mmove_t gladiator_move_walk = { FRAME_walk1, FRAME_walk16 };

static void gladiator_walk(entity self)
{
	self->monsterinfo.currentmove = &gladiator_move_walk;
}


static mframe_t gladiator_frames_run [] = {
	{ ai_run, 23 },
	{ ai_run, 14 },
	{ ai_run, 14 },
	{ ai_run, 21 },
	{ ai_run, 12 },
	{ ai_run, 13 }
};
static var mmove_t gladiator_move_run = { FRAME_run1, FRAME_run6 };

static void gladiator_run(entity self)
{
	if (self->monsterinfo.aiflags & AI_STAND_GROUND)
		self->monsterinfo.currentmove = &gladiator_move_stand;
	else
		self->monsterinfo.currentmove = &gladiator_move_run;
}


static void GaldiatorMelee(entity self)
{
	const vector  aim = [ MELEE_DISTANCE, self->mins_x, -4 ];
	if (fire_hit(self, aim, (20 + (Q_rand() % 5)), 300))
		gi.sound(self, CHAN_AUTO, sound_cleaver_hit, 1, ATTN_NORM, 0);
	else
		gi.sound(self, CHAN_AUTO, sound_cleaver_miss, 1, ATTN_NORM, 0);
}

static mframe_t gladiator_frames_attack_melee [] = {
	{ ai_charge },
	{ ai_charge },
	{ ai_charge },
	{ ai_charge },
	{ ai_charge, 0, gladiator_cleaver_swing },
	{ ai_charge },
	{ ai_charge, 0, GaldiatorMelee },
	{ ai_charge },
	{ ai_charge },
	{ ai_charge },
	{ ai_charge, 0, gladiator_cleaver_swing },
	{ ai_charge },
	{ ai_charge },
	{ ai_charge, 0, GaldiatorMelee },
	{ ai_charge },
	{ ai_charge },
	{ ai_charge }
};
static var mmove_t gladiator_move_attack_melee = { FRAME_melee1, FRAME_melee17, gladiator_run };

static void gladiator_melee(entity self)
{
	self->monsterinfo.currentmove = &gladiator_move_attack_melee;
}

static void GladiatorGun(entity self)
{
	vector  start;
	vector  dir;
	vector  forward, right;

	AngleVectors(self->s.angles, &forward, &right, 0);
	G_ProjectSource(self->s.origin, monster_flash_offset[MZ2_GLADIATOR_RAILGUN_1], forward, right, start);

	// calc direction to where we targted
	dir = self->pos1 - start;
	VectorNormalize(dir);

	monster_fire_railgun(self, start, dir, 50, 100, MZ2_GLADIATOR_RAILGUN_1);
}

static mframe_t gladiator_frames_attack_gun [] = {
	{ ai_charge },
	{ ai_charge },
	{ ai_charge },
	{ ai_charge, 0, GladiatorGun },
	{ ai_charge },
	{ ai_charge },
	{ ai_charge },
	{ ai_charge },
	{ ai_charge }
};
static var mmove_t gladiator_move_attack_gun = { FRAME_attack1, FRAME_attack9, gladiator_run };

static void gladiator_attack(entity self)
{
	float   range;
	vector  v;

	// a small safe zone
	v = self->s.origin - self->enemy->s.origin;
	range = VectorLength(v);
	if (range <= (MELEE_DISTANCE + 32))
		return;

	// charge up the railgun
	gi.sound(self, CHAN_WEAPON, sound_gun, 1, ATTN_NORM, 0);
	self->pos1 = self->enemy->s.origin;  //save for aiming the shot
	self->pos1[2] += self->enemy->viewheight;
	self->monsterinfo.currentmove = &gladiator_move_attack_gun;
}


static mframe_t gladiator_frames_pain [] = {
	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move }
};
static var mmove_t gladiator_move_pain = { FRAME_pain1, FRAME_pain6, gladiator_run };

static mframe_t gladiator_frames_pain_air [] = {
	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move }
};
static var mmove_t gladiator_move_pain_air = { FRAME_painup1, FRAME_painup7, gladiator_run };

static void gladiator_pain(entity self, entity other, float kick, int damage)
{

	if (self->health < (self->max_health / 2))
		self->s.skinnum = 1;

	if (level.framenum < self->pain_debounce_framenum) {
		if ((self->velocity[2] > 100) && (self->monsterinfo.currentmove == &gladiator_move_pain))
			self->monsterinfo.currentmove = &gladiator_move_pain_air;
		return;
	}

	self->pain_debounce_framenum = level.framenum + 3 * BASE_FRAMERATE;

	if (random() < 0.5f)
		gi.sound(self, CHAN_VOICE, sound_pain1, 1, ATTN_NORM, 0);
	else
		gi.sound(self, CHAN_VOICE, sound_pain2, 1, ATTN_NORM, 0);

	if (skill->intVal == 3)
		return;     // no pain anims in nightmare

	if (self->velocity[2] > 100)
		self->monsterinfo.currentmove = &gladiator_move_pain_air;
	else
		self->monsterinfo.currentmove = &gladiator_move_pain;

}


static void gladiator_dead(entity self)
{
	self->mins = '-16 -16 -24';
	self->maxs = '16 16 -8';
	self->movetype = MOVETYPE_TOSS;
	self->svflags |= SVF_DEADMONSTER;
	self->nextthink = 0;
	gi.linkentity(self);
}

static mframe_t gladiator_frames_death [] = {
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
static var mmove_t gladiator_move_death = { FRAME_death1, FRAME_death22, gladiator_dead };

static void gladiator_die(entity self, entity inflictor, entity attacker, int damage, vector point)
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
	gi.sound(self, CHAN_VOICE, sound_die, 1, ATTN_NORM, 0);
	self->deadflag = DEAD_DEAD;
	self->takedamage = DAMAGE_YES;

	self->monsterinfo.currentmove = &gladiator_move_death;
}


/*QUAKED monster_gladiator (1 .5 0) (-32 -32 -24) (32 32 64) Ambush Trigger_Spawn Sight
*/
API_FUNC static void SP_monster_gladiator(entity self)
{
	if (deathmatch->intVal) {
		G_FreeEdict(self);
		return;
	}

	if (!gladiator_move_stand.frame)
	{
		gladiator_move_stand.frame = &gladiator_frames_stand;
		gladiator_move_walk.frame = &gladiator_frames_walk;
		gladiator_move_run.frame = &gladiator_frames_run;
		gladiator_move_attack_melee.frame = &gladiator_frames_attack_melee;
		gladiator_move_attack_gun.frame = &gladiator_frames_attack_gun;
		gladiator_move_pain.frame = &gladiator_frames_pain;
		gladiator_move_pain_air.frame = &gladiator_frames_pain_air;
		gladiator_move_death.frame = &gladiator_frames_death;
	}

	sound_pain1 = gi.soundindex("gladiator/pain.wav");
	sound_pain2 = gi.soundindex("gladiator/gldpain2.wav");
	sound_die = gi.soundindex("gladiator/glddeth2.wav");
	sound_gun = gi.soundindex("gladiator/railgun.wav");
	sound_cleaver_swing = gi.soundindex("gladiator/melee1.wav");
	sound_cleaver_hit = gi.soundindex("gladiator/melee2.wav");
	sound_cleaver_miss = gi.soundindex("gladiator/melee3.wav");
	sound_idle = gi.soundindex("gladiator/gldidle1.wav");
	sound_search = gi.soundindex("gladiator/gldsrch1.wav");
	sound_sight = gi.soundindex("gladiator/sight.wav");

	self->movetype = MOVETYPE_STEP;
	self->solid = SOLID_BBOX;
	self->s.modelindex = gi.modelindex("models/monsters/gladiatr/tris.md2");
	self->mins = '-32 -32 -24';
	self->maxs = '32 32 64';

	self->health = 400;
	self->gib_health = -175;
	self->mass = 400;

	self->pain = gladiator_pain;
	self->die = gladiator_die;

	self->monsterinfo.stand = gladiator_stand;
	self->monsterinfo.walk = gladiator_walk;
	self->monsterinfo.run = gladiator_run;
	self->monsterinfo.dodge = 0;
	self->monsterinfo.attack = gladiator_attack;
	self->monsterinfo.melee = gladiator_melee;
	self->monsterinfo.sight = gladiator_sight;
	self->monsterinfo.idle = gladiator_idle;
	self->monsterinfo.search = gladiator_search;

	gi.linkentity(self);
	self->monsterinfo.currentmove = &gladiator_move_stand;
	self->monsterinfo.scale = MODEL_SCALE;

	walkmonster_start(self);
}
