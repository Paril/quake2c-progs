#include "m_boss31.h"

void SP_monster_makron(entity self);

static int  sound_pain1;
static int  sound_pain2;
static int  sound_pain3;
static int  sound_idle;
static int  sound_death;
static int  sound_search1;
static int  sound_search2;
static int  sound_search3;
static int  sound_attack1;
static int  sound_attack2;
static int  sound_firegun;
static int  sound_step_left;
static int  sound_step_right;
static int  sound_death_hit;

static void jorg_search(entity self)
{
	float r;

	r = random();

	if (r <= 0.3f)
		gi.sound(self, CHAN_VOICE, sound_search1, 1, ATTN_NORM, 0);
	else if (r <= 0.6f)
		gi.sound(self, CHAN_VOICE, sound_search2, 1, ATTN_NORM, 0);
	else
		gi.sound(self, CHAN_VOICE, sound_search3, 1, ATTN_NORM, 0);
}

//
// stand
//

static void jorg_step_left(entity self)
{
	gi.sound(self, CHAN_BODY, sound_step_left, 1, ATTN_NORM, 0);
}

static void jorg_step_right(entity self)
{
	gi.sound(self, CHAN_BODY, sound_step_right, 1, ATTN_NORM, 0);
}

static void jorg_idle(entity self)
{
	gi.sound(self, CHAN_VOICE, sound_idle, 1, ATTN_NORM, 0);
}

static mframe_t jorg_frames_stand [] = {
	{ ai_stand, 0, jorg_idle },
	{ ai_stand },
	{ ai_stand },
	{ ai_stand },
	{ ai_stand },
	{ ai_stand },
	{ ai_stand },
	{ ai_stand },
	{ ai_stand },
	{ ai_stand },      // 10
	{ ai_stand },
	{ ai_stand },
	{ ai_stand },
	{ ai_stand },
	{ ai_stand },
	{ ai_stand },
	{ ai_stand },
	{ ai_stand },
	{ ai_stand },
	{ ai_stand },      // 20
	{ ai_stand },
	{ ai_stand },
	{ ai_stand },
	{ ai_stand },
	{ ai_stand },
	{ ai_stand },
	{ ai_stand },
	{ ai_stand },
	{ ai_stand },
	{ ai_stand },      // 30
	{ ai_stand },
	{ ai_stand },
	{ ai_stand },
	{ ai_stand, 19 },
	{ ai_stand, 11, jorg_step_left },
	{ ai_stand },
	{ ai_stand },
	{ ai_stand, 6 },
	{ ai_stand, 9, jorg_step_right },
	{ ai_stand },      // 40
	{ ai_stand },
	{ ai_stand },
	{ ai_stand },
	{ ai_stand },
	{ ai_stand },
	{ ai_stand },
	{ ai_stand, -2 },
	{ ai_stand, -17, jorg_step_left },
	{ ai_stand },
	{ ai_stand, -12 },        // 50
	{ ai_stand, -14, jorg_step_right }  // 51
};
static var mmove_t jorg_move_stand = { FRAME_stand01, FRAME_stand51 };

static void jorg_death_hit(entity self)
{
	gi.sound(self, CHAN_BODY, sound_death_hit, 1, ATTN_NORM, 0);
}

static void jorg_stand(entity self)
{
	self->monsterinfo.currentmove = &jorg_move_stand;
}

static mframe_t jorg_frames_run [] = {
	{ ai_run, 17, jorg_step_left },
	{ ai_run },
	{ ai_run },
	{ ai_run },
	{ ai_run, 12 },
	{ ai_run, 8 },
	{ ai_run, 10 },
	{ ai_run, 33, jorg_step_right },
	{ ai_run },
	{ ai_run },
	{ ai_run },
	{ ai_run, 9 },
	{ ai_run, 9 },
	{ ai_run, 9 }
};
static var mmove_t jorg_move_run = { FRAME_walk06, FRAME_walk19 };

//
// walk
//

static mframe_t jorg_frames_walk [] = {
	{ ai_walk, 17 },
	{ ai_walk },
	{ ai_walk },
	{ ai_walk },
	{ ai_walk, 12 },
	{ ai_walk, 8 },
	{ ai_walk, 10 },
	{ ai_walk, 33 },
	{ ai_walk },
	{ ai_walk },
	{ ai_walk },
	{ ai_walk, 9 },
	{ ai_walk, 9 },
	{ ai_walk, 9 }
};
static var mmove_t jorg_move_walk = { FRAME_walk06, FRAME_walk19 };

static void jorg_walk(entity self)
{
	self->monsterinfo.currentmove = &jorg_move_walk;
}

static void jorg_run(entity self)
{
	if (self->monsterinfo.aiflags & AI_STAND_GROUND)
		self->monsterinfo.currentmove = &jorg_move_stand;
	else
		self->monsterinfo.currentmove = &jorg_move_run;
}

static mframe_t jorg_frames_pain3 [] = {
	{ ai_move,    -28 },
	{ ai_move,    -6 },
	{ ai_move,    -3, jorg_step_left },
	{ ai_move,    -9 },
	{ ai_move,    0,  jorg_step_right },
	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move,    -7 },
	{ ai_move,    1 },
	{ ai_move,    -11 },
	{ ai_move,    -4 },
	{ ai_move },
	{ ai_move },
	{ ai_move,    10 },
	{ ai_move,    11 },
	{ ai_move },
	{ ai_move,    10 },
	{ ai_move,    3 },
	{ ai_move,    10 },
	{ ai_move,    7,  jorg_step_left },
	{ ai_move,    17 },
	{ ai_move },
	{ ai_move },
	{ ai_move,    0,  jorg_step_right }
};
static var mmove_t jorg_move_pain3 = { FRAME_pain301, FRAME_pain325, jorg_run };

static mframe_t jorg_frames_pain2 [] = {
	{ ai_move },
	{ ai_move },
	{ ai_move }
};
static var mmove_t jorg_move_pain2 = { FRAME_pain201, FRAME_pain203, jorg_run };

static mframe_t jorg_frames_pain1 [] = {
	{ ai_move },
	{ ai_move },
	{ ai_move }
};
static var mmove_t jorg_move_pain1 = { FRAME_pain101, FRAME_pain103, jorg_run };

static mframe_t jorg_frames_death1 [] = {
	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move },       // 10
	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move },       // 20
	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move },       // 30
	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move },       // 40
	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move,    0,  MakronToss },
	{ ai_move,    0,  BossExplode }     // 50
};
static var mmove_t jorg_move_death = { FRAME_death01, FRAME_death50 };

static void jorgBFG(entity self)
{
	vector  forward, right;
	vector  start;
	vector  dir;
	vector  vec;

	AngleVectors(self->s.angles, &forward, &right, 0);
	G_ProjectSource(self->s.origin, monster_flash_offset[MZ2_JORG_BFG_1], forward, right, start);

	VectorCopy(self->enemy->s.origin, vec);
	vec[2] += self->enemy->viewheight;
	VectorSubtract(vec, start, dir);
	VectorNormalize(dir);
	gi.sound(self, CHAN_VOICE, sound_attack2, 1, ATTN_NORM, 0);
	monster_fire_bfg(self, start, dir, 50, 300, 100, 200, MZ2_JORG_BFG_1);
}

static mframe_t jorg_frames_attack2 [] = {
	{ ai_charge },
	{ ai_charge },
	{ ai_charge },
	{ ai_charge },
	{ ai_charge },
	{ ai_charge },
	{ ai_charge,  0,  jorgBFG },
	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move }
};
static var mmove_t jorg_move_attack2 = { FRAME_attak201, FRAME_attak213, jorg_run };

static mframe_t jorg_frames_start_attack1 [] = {
	{ ai_charge },
	{ ai_charge },
	{ ai_charge },
	{ ai_charge },
	{ ai_charge },
	{ ai_charge },
	{ ai_charge },
	{ ai_charge }
};
static var mmove_t jorg_move_start_attack1 = { FRAME_attak101, FRAME_attak108 };

static void jorg_firebullet_right(entity self)
{
	vector  forward, right, target;
	vector  start;

	AngleVectors(self->s.angles, &forward, &right, 0);
	G_ProjectSource(self->s.origin, monster_flash_offset[MZ2_JORG_MACHINEGUN_R1], forward, right, start);

	VectorMA(self->enemy->s.origin, -0.2f, self->enemy->velocity, target);
	target[2] += self->enemy->viewheight;
	VectorSubtract(target, start, forward);
	VectorNormalize(forward);

	monster_fire_bullet(self, start, forward, 6, 4, DEFAULT_BULLET_HSPREAD, DEFAULT_BULLET_VSPREAD, MZ2_JORG_MACHINEGUN_R1);
}

static void jorg_firebullet_left(entity self)
{
	vector  forward, right, target;
	vector  start;

	AngleVectors(self->s.angles, &forward, &right, 0);
	G_ProjectSource(self->s.origin, monster_flash_offset[MZ2_JORG_MACHINEGUN_L1], forward, right, start);

	VectorMA(self->enemy->s.origin, -0.2f, self->enemy->velocity, target);
	target[2] += self->enemy->viewheight;
	VectorSubtract(target, start, forward);
	VectorNormalize(forward);

	monster_fire_bullet(self, start, forward, 6, 4, DEFAULT_BULLET_HSPREAD, DEFAULT_BULLET_VSPREAD, MZ2_JORG_MACHINEGUN_L1);
}

static void jorg_firebullet(entity self)
{
	jorg_firebullet_left(self);
	jorg_firebullet_right(self);
}

static mframe_t jorg_frames_attack1[] = {
	{ ai_charge,  0,  jorg_firebullet },
	{ ai_charge,  0,  jorg_firebullet },
	{ ai_charge,  0,  jorg_firebullet },
	{ ai_charge,  0,  jorg_firebullet },
	{ ai_charge,  0,  jorg_firebullet },
	{ ai_charge,  0,  jorg_firebullet }
};
static var mmove_t jorg_move_attack1 = { FRAME_attak109, FRAME_attak114 };

static mframe_t jorg_frames_end_attack1[] = {
	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move }
};
static var mmove_t jorg_move_end_attack1 = { FRAME_attak115, FRAME_attak118, jorg_run };

static void jorg_reattack1(entity self)
{
	if (visible(self, self->enemy))
		if (random() < 0.9f)
			self->monsterinfo.currentmove = &jorg_move_attack1;
		else {
			self->s.sound = 0;
			self->monsterinfo.currentmove = &jorg_move_end_attack1;
		}
	else {
		self->s.sound = 0;
		self->monsterinfo.currentmove = &jorg_move_end_attack1;
	}
}

static void jorg_attack1(entity self)
{
	self->monsterinfo.currentmove = &jorg_move_attack1;
}

static void jorg_pain(entity self, entity other, float kick, int damage)
{
	if (self->health < (self->max_health / 2))
		self->s.skinnum = 1;

	self->s.sound = 0;

	if (level.framenum < self->pain_debounce_framenum)
		return;

	// Lessen the chance of him going into his pain frames if he takes little damage
	if (damage <= 40)
		if (random() <= 0.6f)
			return;

	/*
	If he's entering his attack1 or using attack1, lessen the chance of him
	going into pain
	*/

	if ((self->s.frame >= FRAME_attak101) && (self->s.frame <= FRAME_attak108))
		if (random() <= 0.005f)
			return;

	if ((self->s.frame >= FRAME_attak109) && (self->s.frame <= FRAME_attak114))
		if (random() <= 0.00005f)
			return;


	if ((self->s.frame >= FRAME_attak201) && (self->s.frame <= FRAME_attak208))
		if (random() <= 0.005f)
			return;


	self->pain_debounce_framenum = level.framenum + 3 * BASE_FRAMERATE;
	if (skill->intVal == 3)
		return;     // no pain anims in nightmare

	if (damage <= 50) {
		gi.sound(self, CHAN_VOICE, sound_pain1, 1, ATTN_NORM, 0);
		self->monsterinfo.currentmove = &jorg_move_pain1;
	} else if (damage <= 100) {
		gi.sound(self, CHAN_VOICE, sound_pain2, 1, ATTN_NORM, 0);
		self->monsterinfo.currentmove = &jorg_move_pain2;
	} else {
		if (random() <= 0.3f) {
			gi.sound(self, CHAN_VOICE, sound_pain3, 1, ATTN_NORM, 0);
			self->monsterinfo.currentmove = &jorg_move_pain3;
		}
	}
}

static void jorg_attack(entity self)
{
	if (random() <= 0.75f) {
		gi.sound(self, CHAN_VOICE, sound_attack1, 1, ATTN_NORM, 0);
		self->s.sound = gi.soundindex("boss3/w_loop.wav");
		self->monsterinfo.currentmove = &jorg_move_start_attack1;
	} else {
		gi.sound(self, CHAN_VOICE, sound_attack2, 1, ATTN_NORM, 0);
		self->monsterinfo.currentmove = &jorg_move_attack2;
	}
}

static void jorg_die(entity self, entity inflictor, entity attacker, int damage, vector point)
{
	gi.sound(self, CHAN_VOICE, sound_death, 1, ATTN_NORM, 0);
	self->deadflag = DEAD_DEAD;
	self->takedamage = DAMAGE_NO;
	self->s.sound = 0;
	self->count = 0;
	self->monsterinfo.currentmove = &jorg_move_death;
}

static bool Jorg_CheckAttack(entity self)
{
	vector  spot1, spot2;
	vector  temp;
	float   chance;
	trace_t tr;
	int         enemy_range;
	float       enemy_yaw;

	if (self->enemy->health > 0) {
		// see if any entities are in the way of the shot
		VectorCopy(self->s.origin, spot1);
		spot1[2] += self->viewheight;
		VectorCopy(self->enemy->s.origin, spot2);
		spot2[2] += self->enemy->viewheight;

		gi.trace(&tr, spot1, vec3_origin, vec3_origin, spot2, self, CONTENTS_SOLID | CONTENTS_MONSTER | CONTENTS_SLIME | CONTENTS_LAVA);

		// do we have a clear shot?
		if (tr.ent != self->enemy)
			return false;
	}

	enemy_range = range(self, self->enemy);
	VectorSubtract(self->enemy->s.origin, self->s.origin, temp);
	enemy_yaw = vectoyaw(temp);

	self->ideal_yaw = enemy_yaw;


	// melee attack
	if (enemy_range == RANGE_MELEE) {
		if (self->monsterinfo.melee)
			self->monsterinfo.attack_state = AS_MELEE;
		else
			self->monsterinfo.attack_state = AS_MISSILE;
		return true;
	}

// missile attack
	if (!self->monsterinfo.attack)
		return false;

	if (level.framenum < self->monsterinfo.attack_finished)
		return false;

	if (enemy_range == RANGE_FAR)
		return false;

	if (self->monsterinfo.aiflags & AI_STAND_GROUND) {
		chance = 0.4f;
	} else if (enemy_range == RANGE_MELEE) {
		chance = 0.8f;
	} else if (enemy_range == RANGE_NEAR) {
		chance = 0.4f;
	} else if (enemy_range == RANGE_MID) {
		chance = 0.2f;
	} else {
		return false;
	}

	if (random() < chance) {
		self->monsterinfo.attack_state = AS_MISSILE;
		self->monsterinfo.attack_finished = level.framenum + (int)random(2f * BASE_FRAMERATE);
		return true;
	}

	if (self->flags & FL_FLY) {
		if (random() < 0.3f)
			self->monsterinfo.attack_state = AS_SLIDING;
		else
			self->monsterinfo.attack_state = AS_STRAIGHT;
	}

	return false;
}

/*QUAKED monster_jorg (1 .5 0) (-80 -80 0) (90 90 140) Ambush Trigger_Spawn Sight
*/
API_FUNC static void SP_monster_jorg(entity self)
{
	if (deathmatch->intVal) {
		G_FreeEdict(self);
		return;
	}
	
	if (!jorg_move_stand.frame)
	{
		jorg_move_stand.frame = &jorg_frames_stand;
		jorg_move_run.frame = &jorg_frames_run;
		jorg_move_walk.frame = &jorg_frames_walk;
		jorg_move_pain3.frame = &jorg_frames_pain3;
		jorg_move_pain2.frame = &jorg_frames_pain2;
		jorg_move_pain1.frame = &jorg_frames_pain1;
		jorg_move_death.frame = &jorg_frames_death1;
		jorg_move_attack2.frame = &jorg_frames_attack2;
		jorg_move_start_attack1.frame = &jorg_frames_start_attack1;
		jorg_move_start_attack1.endfunc = jorg_attack1;
		jorg_move_attack1.frame = &jorg_frames_attack1;
		jorg_move_attack1.endfunc = jorg_reattack1;
		jorg_move_end_attack1.frame = &jorg_frames_end_attack1;
	}

	sound_pain1 = gi.soundindex("boss3/bs3pain1.wav");
	sound_pain2 = gi.soundindex("boss3/bs3pain2.wav");
	sound_pain3 = gi.soundindex("boss3/bs3pain3.wav");
	sound_death = gi.soundindex("boss3/bs3deth1.wav");
	sound_attack1 = gi.soundindex("boss3/bs3atck1.wav");
	sound_attack2 = gi.soundindex("boss3/bs3atck2.wav");
	sound_search1 = gi.soundindex("boss3/bs3srch1.wav");
	sound_search2 = gi.soundindex("boss3/bs3srch2.wav");
	sound_search3 = gi.soundindex("boss3/bs3srch3.wav");
	sound_idle = gi.soundindex("boss3/bs3idle1.wav");
	sound_step_left = gi.soundindex("boss3/step1.wav");
	sound_step_right = gi.soundindex("boss3/step2.wav");
	sound_firegun = gi.soundindex("boss3/xfire.wav");
	sound_death_hit = gi.soundindex("boss3/d_hit.wav");

	MakronPrecache();

	self->movetype = MOVETYPE_STEP;
	self->solid = SOLID_BBOX;
	self->s.modelindex = gi.modelindex("models/monsters/boss3/rider/tris.md2");
	self->s.modelindex2 = gi.modelindex("models/monsters/boss3/jorg/tris.md2");
	self->mins = '-80 -80 0';
	self->maxs = '80 80 140';

	self->health = 3000;
	self->gib_health = -2000;
	self->mass = 1000;

	self->pain = jorg_pain;
	self->die = jorg_die;
	self->monsterinfo.stand = jorg_stand;
	self->monsterinfo.walk = jorg_walk;
	self->monsterinfo.run = jorg_run;
	self->monsterinfo.dodge = 0;
	self->monsterinfo.attack = jorg_attack;
	self->monsterinfo.search = jorg_search;
	self->monsterinfo.melee = 0;
	self->monsterinfo.sight = 0;
	self->monsterinfo.checkattack = Jorg_CheckAttack;
	gi.linkentity(self);

	self->monsterinfo.currentmove = &jorg_move_stand;
	self->monsterinfo.scale = MODEL_SCALE;

	walkmonster_start(self);
}
