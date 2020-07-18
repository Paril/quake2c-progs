#include "m_boss2.h"

static int  sound_pain1;
static int  sound_pain2;
static int  sound_pain3;
static int  sound_death;
static int  sound_search1;

static void boss2_search(entity self)
{
	if (random() < 0.5f)
		gi.sound(self, CHAN_VOICE, sound_search1, 1, ATTN_NONE, 0);
}

static void Boss2Rocket(entity self)
{
	vector  forward, right;
	vector  start;
	vector  dir;
	vector  vec;

	AngleVectors(self->s.angles, &forward, &right, 0);

//1
	G_ProjectSource(self->s.origin, monster_flash_offset[MZ2_BOSS2_ROCKET_1], forward, right, start);
	VectorCopy(self->enemy->s.origin, vec);
	vec[2] += self->enemy->viewheight;
	VectorSubtract(vec, start, dir);
	VectorNormalize(dir);
	monster_fire_rocket(self, start, dir, 50, 500, MZ2_BOSS2_ROCKET_1);

//2
	G_ProjectSource(self->s.origin, monster_flash_offset[MZ2_BOSS2_ROCKET_2], forward, right, start);
	VectorCopy(self->enemy->s.origin, vec);
	vec[2] += self->enemy->viewheight;
	VectorSubtract(vec, start, dir);
	VectorNormalize(dir);
	monster_fire_rocket(self, start, dir, 50, 500, MZ2_BOSS2_ROCKET_2);

//3
	G_ProjectSource(self->s.origin, monster_flash_offset[MZ2_BOSS2_ROCKET_3], forward, right, start);
	VectorCopy(self->enemy->s.origin, vec);
	vec[2] += self->enemy->viewheight;
	VectorSubtract(vec, start, dir);
	VectorNormalize(dir);
	monster_fire_rocket(self, start, dir, 50, 500, MZ2_BOSS2_ROCKET_3);

//4
	G_ProjectSource(self->s.origin, monster_flash_offset[MZ2_BOSS2_ROCKET_4], forward, right, start);
	VectorCopy(self->enemy->s.origin, vec);
	vec[2] += self->enemy->viewheight;
	VectorSubtract(vec, start, dir);
	VectorNormalize(dir);
	monster_fire_rocket(self, start, dir, 50, 500, MZ2_BOSS2_ROCKET_4);
}

static void boss2_firebullet_right(entity self)
{
	vector  forward, right, target;
	vector  start;

	AngleVectors(self->s.angles, &forward, &right, 0);
	G_ProjectSource(self->s.origin, monster_flash_offset[MZ2_BOSS2_MACHINEGUN_R1], forward, right, start);

	VectorMA(self->enemy->s.origin, -0.2f, self->enemy->velocity, target);
	target[2] += self->enemy->viewheight;
	VectorSubtract(target, start, forward);
	VectorNormalize(forward);

	monster_fire_bullet(self, start, forward, 6, 4, DEFAULT_BULLET_HSPREAD, DEFAULT_BULLET_VSPREAD, MZ2_BOSS2_MACHINEGUN_R1);
}

static void boss2_firebullet_left(entity self)
{
	vector  forward, right, target;
	vector  start;

	AngleVectors(self->s.angles, &forward, &right, 0);
	G_ProjectSource(self->s.origin, monster_flash_offset[MZ2_BOSS2_MACHINEGUN_L1], forward, right, start);

	VectorMA(self->enemy->s.origin, -0.2f, self->enemy->velocity, target);

	target[2] += self->enemy->viewheight;
	VectorSubtract(target, start, forward);
	VectorNormalize(forward);

	monster_fire_bullet(self, start, forward, 6, 4, DEFAULT_BULLET_HSPREAD, DEFAULT_BULLET_VSPREAD, MZ2_BOSS2_MACHINEGUN_L1);
}

static void Boss2MachineGun(entity self)
{
	boss2_firebullet_left(self);
	boss2_firebullet_right(self);
}


static mframe_t boss2_frames_stand [] = {
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
static var mmove_t boss2_move_stand = { FRAME_stand30, FRAME_stand50 };

static mframe_t boss2_frames_fidget [] = {
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
static var mmove_t boss2_move_fidget = { FRAME_stand1, FRAME_stand30 };

static mframe_t boss2_frames_walk [] = {
	{ ai_walk,    8 },
	{ ai_walk,    8 },
	{ ai_walk,    8 },
	{ ai_walk,    8 },
	{ ai_walk,    8 },
	{ ai_walk,    8 },
	{ ai_walk,    8 },
	{ ai_walk,    8 },
	{ ai_walk,    8 },
	{ ai_walk,    8 },
	{ ai_walk,    8 },
	{ ai_walk,    8 },
	{ ai_walk,    8 },
	{ ai_walk,    8 },
	{ ai_walk,    8 },
	{ ai_walk,    8 },
	{ ai_walk,    8 },
	{ ai_walk,    8 },
	{ ai_walk,    8 },
	{ ai_walk,    8 }
};
static var mmove_t boss2_move_walk = { FRAME_walk1, FRAME_walk20 };

static mframe_t boss2_frames_run [] = {
	{ ai_run, 8 },
	{ ai_run, 8 },
	{ ai_run, 8 },
	{ ai_run, 8 },
	{ ai_run, 8 },
	{ ai_run, 8 },
	{ ai_run, 8 },
	{ ai_run, 8 },
	{ ai_run, 8 },
	{ ai_run, 8 },
	{ ai_run, 8 },
	{ ai_run, 8 },
	{ ai_run, 8 },
	{ ai_run, 8 },
	{ ai_run, 8 },
	{ ai_run, 8 },
	{ ai_run, 8 },
	{ ai_run, 8 },
	{ ai_run, 8 },
	{ ai_run, 8 }
};
static var mmove_t boss2_move_run = { FRAME_walk1, FRAME_walk20 };

static mframe_t boss2_frames_attack_post_mg [] = {
	{ ai_charge,  1 },
	{ ai_charge,  1 },
	{ ai_charge,  1 },
	{ ai_charge,  1 }
};
static var mmove_t boss2_move_attack_post_mg = { FRAME_attack16, FRAME_attack19 };

static void boss2_attack_mg(entity self);

static void boss2_reattack_mg(entity self)
{
	if (infront(self, self->enemy))
		if (random() <= 0.7f)
			boss2_attack_mg(self);
		else
			self->monsterinfo.currentmove = &boss2_move_attack_post_mg;
	else
		self->monsterinfo.currentmove = &boss2_move_attack_post_mg;
}

// Loop this
static mframe_t boss2_frames_attack_mg [] = {
	{ ai_charge,  1,  Boss2MachineGun },
	{ ai_charge,  1,  Boss2MachineGun },
	{ ai_charge,  1,  Boss2MachineGun },
	{ ai_charge,  1,  Boss2MachineGun },
	{ ai_charge,  1,  Boss2MachineGun },
	{ ai_charge,  1,  boss2_reattack_mg }
};
static var mmove_t boss2_move_attack_mg = { FRAME_attack10, FRAME_attack15 };

static void boss2_attack_mg(entity self)
{
	self->monsterinfo.currentmove = &boss2_move_attack_mg;
}

static mframe_t boss2_frames_attack_pre_mg [] = {
	{ ai_charge,  1 },
	{ ai_charge,  1 },
	{ ai_charge,  1 },
	{ ai_charge,  1 },
	{ ai_charge,  1 },
	{ ai_charge,  1 },
	{ ai_charge,  1 },
	{ ai_charge,  1 },
	{ ai_charge,  1,  boss2_attack_mg }
};
static var mmove_t boss2_move_attack_pre_mg = { FRAME_attack1, FRAME_attack9 };

static mframe_t boss2_frames_attack_rocket [] = {
	{ ai_charge,  1 },
	{ ai_charge,  1 },
	{ ai_charge,  1 },
	{ ai_charge,  1 },
	{ ai_charge,  1 },
	{ ai_charge,  1 },
	{ ai_charge,  1 },
	{ ai_charge,  1 },
	{ ai_charge,  1 },
	{ ai_charge,  1 },
	{ ai_charge,  1 },
	{ ai_charge,  1 },
	{ ai_move,    -20,    Boss2Rocket },
	{ ai_charge,  1 },
	{ ai_charge,  1 },
	{ ai_charge,  1 },
	{ ai_charge,  1 },
	{ ai_charge,  1 },
	{ ai_charge,  1 },
	{ ai_charge,  1 },
	{ ai_charge,  1 }
};
static var mmove_t boss2_move_attack_rocket = { FRAME_attack20, FRAME_attack40 };

static mframe_t boss2_frames_pain_heavy [] = {
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
static var mmove_t boss2_move_pain_heavy = { FRAME_pain2, FRAME_pain19 };

static mframe_t boss2_frames_pain_light [] = {
	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move }
};
static var mmove_t boss2_move_pain_light = { FRAME_pain20, FRAME_pain23 };

static void boss2_dead(entity self)
{
	self->mins = '-56 -56 0';
	self->maxs = '56 56 80';
	self->movetype = MOVETYPE_TOSS;
	self->svflags |= SVF_DEADMONSTER;
	self->nextthink = 0;
	gi.linkentity(self);
}

static mframe_t boss2_frames_death [] = {
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
	{ ai_move,    0,  BossExplode }
};
static var mmove_t boss2_move_death = { FRAME_death2, FRAME_death50, boss2_dead };

static void boss2_stand(entity self)
{
	self->monsterinfo.currentmove = &boss2_move_stand;
}

static void boss2_run(entity self)
{
	if (self->monsterinfo.aiflags & AI_STAND_GROUND)
		self->monsterinfo.currentmove = &boss2_move_stand;
	else
		self->monsterinfo.currentmove = &boss2_move_run;
}

static void boss2_walk(entity self)
{
	self->monsterinfo.currentmove = &boss2_move_walk;
}

static void boss2_attack(entity self)
{
	vector  vec;
	float   range;

	VectorSubtract(self->enemy->s.origin, self->s.origin, vec);
	range = VectorLength(vec);

	if (range <= 125) {
		self->monsterinfo.currentmove = &boss2_move_attack_pre_mg;
	} else {
		if (random() <= 0.6f)
			self->monsterinfo.currentmove = &boss2_move_attack_pre_mg;
		else
			self->monsterinfo.currentmove = &boss2_move_attack_rocket;
	}
}

static void boss2_pain(entity self, entity other, float kick, int damage)
{
	if (self->health < (self->max_health / 2))
		self->s.skinnum = 1;

	if (level.framenum < self->pain_debounce_framenum)
		return;

	self->pain_debounce_framenum = level.framenum + 3 * BASE_FRAMERATE;
// American wanted these at no attenuation
	if (damage < 10) {
		gi.sound(self, CHAN_VOICE, sound_pain3, 1, ATTN_NONE, 0);
		self->monsterinfo.currentmove = &boss2_move_pain_light;
	} else if (damage < 30) {
		gi.sound(self, CHAN_VOICE, sound_pain1, 1, ATTN_NONE, 0);
		self->monsterinfo.currentmove = &boss2_move_pain_light;
	} else {
		gi.sound(self, CHAN_VOICE, sound_pain2, 1, ATTN_NONE, 0);
		self->monsterinfo.currentmove = &boss2_move_pain_heavy;
	}
}

static void boss2_die(entity self, entity inflictor, entity attacker, int damage, vector point)
{
	gi.sound(self, CHAN_VOICE, sound_death, 1, ATTN_NONE, 0);
	self->deadflag = DEAD_DEAD;
	self->takedamage = DAMAGE_NO;
	self->count = 0;
	self->monsterinfo.currentmove = &boss2_move_death;
}

static bool Boss2_CheckAttack(entity self)
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
		chance = 0.8f;
	} else if (enemy_range == RANGE_MID) {
		chance = 0.8f;
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



/*QUAKED monster_boss2 (1 .5 0) (-56 -56 0) (56 56 80) Ambush Trigger_Spawn Sight
*/
API_FUNC static void SP_monster_boss2(entity self)
{
	if (deathmatch->intVal) {
		G_FreeEdict(self);
		return;
	}
	
	if (!boss2_move_stand.frame)
	{
		boss2_move_stand.frame = &boss2_frames_stand;
		boss2_move_fidget.frame = &boss2_frames_fidget;
		boss2_move_walk.frame = &boss2_frames_walk;
		boss2_move_run.frame = &boss2_frames_run;
		boss2_move_attack_post_mg.frame = &boss2_frames_attack_post_mg;
		boss2_move_attack_post_mg.endfunc = boss2_run;
		boss2_move_attack_mg.frame = &boss2_frames_attack_mg;
		boss2_move_attack_pre_mg.frame = &boss2_frames_attack_pre_mg;
		boss2_move_attack_rocket.frame = &boss2_frames_attack_rocket;
		boss2_move_attack_rocket.endfunc = boss2_run;
		boss2_move_pain_heavy.frame = &boss2_frames_pain_heavy;
		boss2_move_pain_heavy.endfunc = boss2_run;
		boss2_move_pain_light.frame = &boss2_frames_pain_light;
		boss2_move_pain_light.endfunc = boss2_run;
		boss2_move_death.frame = &boss2_frames_death;
	}

	sound_pain1 = gi.soundindex("bosshovr/bhvpain1.wav");
	sound_pain2 = gi.soundindex("bosshovr/bhvpain2.wav");
	sound_pain3 = gi.soundindex("bosshovr/bhvpain3.wav");
	sound_death = gi.soundindex("bosshovr/bhvdeth1.wav");
	sound_search1 = gi.soundindex("bosshovr/bhvunqv1.wav");

	self->s.sound = gi.soundindex("bosshovr/bhvengn1.wav");

	self->movetype = MOVETYPE_STEP;
	self->solid = SOLID_BBOX;
	self->s.modelindex = gi.modelindex("models/monsters/boss2/tris.md2");
	self->mins = '-56 -56 0';
	self->maxs = '56 56 80';

	self->health = 2000;
	self->gib_health = -200;
	self->mass = 1000;

	self->flags |= FL_IMMUNE_LASER;

	self->pain = boss2_pain;
	self->die = boss2_die;

	self->monsterinfo.stand = boss2_stand;
	self->monsterinfo.walk = boss2_walk;
	self->monsterinfo.run = boss2_run;
	self->monsterinfo.attack = boss2_attack;
	self->monsterinfo.search = boss2_search;
	self->monsterinfo.checkattack = Boss2_CheckAttack;
	gi.linkentity(self);

	self->monsterinfo.currentmove = &boss2_move_stand;
	self->monsterinfo.scale = MODEL_SCALE;

	flymonster_start(self);
}
