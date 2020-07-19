#include "m_tank.h"

static int  sound_thud;
static int  sound_pain;
static int  sound_idle;
static int  sound_die;
static int  sound_step;
static int  sound_sight;
static int  sound_windup;
static int  sound_strike;

//
// misc
//

static void tank_sight(entity self, entity other)
{
	gi.sound(self, CHAN_VOICE, sound_sight, 1, ATTN_NORM, 0);
}

static void tank_footstep(entity self)
{
	gi.sound(self, CHAN_BODY, sound_step, 1, ATTN_NORM, 0);
}

static void tank_thud(entity self)
{
	gi.sound(self, CHAN_BODY, sound_thud, 1, ATTN_NORM, 0);
}

static void tank_windup(entity self)
{
	gi.sound(self, CHAN_WEAPON, sound_windup, 1, ATTN_NORM, 0);
}

static void tank_idle(entity self)
{
	gi.sound(self, CHAN_VOICE, sound_idle, 1, ATTN_IDLE, 0);
}


//
// stand
//

static mframe_t tank_frames_stand [] = {
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
static var mmove_t tank_move_stand = { FRAME_stand01, FRAME_stand30 };

static void tank_stand(entity self)
{
	self->monsterinfo.currentmove = &tank_move_stand;
}

//
// walk
//

static mframe_t tank_frames_start_walk [] = {
	{ ai_walk },
	{ ai_walk,  6 },
	{ ai_walk,  6 },
	{ ai_walk, 11, tank_footstep }
};
static var mmove_t tank_move_start_walk = { FRAME_walk01, FRAME_walk04 };

static mframe_t tank_frames_walk [] = {
	{ ai_walk, 4 },
	{ ai_walk, 5 },
	{ ai_walk, 3 },
	{ ai_walk, 2 },
	{ ai_walk, 5 },
	{ ai_walk, 5 },
	{ ai_walk, 4 },
	{ ai_walk, 4, tank_footstep },
	{ ai_walk, 3 },
	{ ai_walk, 5 },
	{ ai_walk, 4 },
	{ ai_walk, 5 },
	{ ai_walk, 7 },
	{ ai_walk, 7 },
	{ ai_walk, 6 },
	{ ai_walk, 6, tank_footstep }
};
static var mmove_t tank_move_walk = { FRAME_walk05, FRAME_walk20 };

static mframe_t tank_frames_stop_walk [] = {
	{ ai_walk,  3 },
	{ ai_walk,  3 },
	{ ai_walk,  2 },
	{ ai_walk,  2 },
	{ ai_walk,  4, tank_footstep }
};
static var mmove_t tank_move_stop_walk = { FRAME_walk21, FRAME_walk25, tank_stand };

static void tank_walk(entity self)
{
	self->monsterinfo.currentmove = &tank_move_walk;
}

//
// run
//

static mframe_t tank_frames_start_run [] = {
	{ ai_run },
	{ ai_run,  6 },
	{ ai_run,  6 },
	{ ai_run, 11, tank_footstep }
};
static var mmove_t tank_move_start_run = { FRAME_walk01, FRAME_walk04 };

static mframe_t tank_frames_run [] = {
	{ ai_run, 4 },
	{ ai_run, 5 },
	{ ai_run, 3 },
	{ ai_run, 2 },
	{ ai_run, 5 },
	{ ai_run, 5 },
	{ ai_run, 4 },
	{ ai_run, 4,  tank_footstep },
	{ ai_run, 3 },
	{ ai_run, 5 },
	{ ai_run, 4 },
	{ ai_run, 5 },
	{ ai_run, 7 },
	{ ai_run, 7 },
	{ ai_run, 6 },
	{ ai_run, 6,  tank_footstep }
};
static var mmove_t tank_move_run = { FRAME_walk05, FRAME_walk20 };

static mframe_t tank_frames_stop_run [] = {
	{ ai_run,  3 },
	{ ai_run,  3 },
	{ ai_run,  2 },
	{ ai_run,  2 },
	{ ai_run,  4, tank_footstep }
};
static var mmove_t tank_move_stop_run = { FRAME_walk21, FRAME_walk25, tank_walk };

static void tank_run(entity self)
{
	if (self->enemy && self->enemy->is_client)
		self->monsterinfo.aiflags |= AI_BRUTAL;
	else
		self->monsterinfo.aiflags &= ~AI_BRUTAL;

	if (self->monsterinfo.aiflags & AI_STAND_GROUND) {
		self->monsterinfo.currentmove = &tank_move_stand;
		return;
	}

	if (self->monsterinfo.currentmove == &tank_move_walk ||
		self->monsterinfo.currentmove == &tank_move_start_run) {
		self->monsterinfo.currentmove = &tank_move_run;
	} else {
		self->monsterinfo.currentmove = &tank_move_start_run;
	}
}

//
// pain
//

static mframe_t tank_frames_pain1 [] = {
	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move }
};
static var mmove_t tank_move_pain1 = { FRAME_pain101, FRAME_pain104, tank_run };

static mframe_t tank_frames_pain2 [] = {
	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move }
};
static var mmove_t tank_move_pain2 = { FRAME_pain201, FRAME_pain205, tank_run };

static mframe_t tank_frames_pain3 [] = {
	{ ai_move, -7 },
	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move, 2 },
	{ ai_move },
	{ ai_move },
	{ ai_move, 3 },
	{ ai_move },
	{ ai_move, 2 },
	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move, 0,  tank_footstep }
};
static var mmove_t tank_move_pain3 = { FRAME_pain301, FRAME_pain316, tank_run };

static void tank_pain(entity self, entity other, float kick, int damage)
{
	if (self->health < (self->max_health / 2))
		self->s.skinnum |= 1;

	if (damage <= 10)
		return;

	if (level.framenum < self->pain_debounce_framenum)
		return;

	if (damage <= 30)
		if (random() > 0.2f)
			return;

	// If hard or nightmare, don't go into pain while attacking
	if (skill->intVal >= 2) {
		if ((self->s.frame >= FRAME_attak301) && (self->s.frame <= FRAME_attak330))
			return;
		if ((self->s.frame >= FRAME_attak101) && (self->s.frame <= FRAME_attak116))
			return;
	}

	self->pain_debounce_framenum = level.framenum + 3 * BASE_FRAMERATE;
	gi.sound(self, CHAN_VOICE, sound_pain, 1, ATTN_NORM, 0);

	if (skill->intVal == 3)
		return;     // no pain anims in nightmare

	if (damage <= 30)
		self->monsterinfo.currentmove = &tank_move_pain1;
	else if (damage <= 60)
		self->monsterinfo.currentmove = &tank_move_pain2;
	else
		self->monsterinfo.currentmove = &tank_move_pain3;
}


//
// attacks
//

static void TankBlaster(entity self)
{
	vector  forward, right;
	vector  start;
	vector  end;
	vector  dir;
	int     flash_number;

	if (self->s.frame == FRAME_attak110)
		flash_number = MZ2_TANK_BLASTER_1;
	else if (self->s.frame == FRAME_attak113)
		flash_number = MZ2_TANK_BLASTER_2;
	else // (self->s.frame == FRAME_attak116)
		flash_number = MZ2_TANK_BLASTER_3;

	AngleVectors(self->s.angles, &forward, &right, 0);
	G_ProjectSource(self->s.origin, monster_flash_offset[flash_number], forward, right, start);

	end = self->enemy->s.origin;
	end_z += self->enemy->viewheight;
	dir = end - start;

	monster_fire_blaster(self, start, dir, 30, 800, flash_number, EF_BLASTER);
}

static void TankStrike(entity self)
{
	gi.sound(self, CHAN_WEAPON, sound_strike, 1, ATTN_NORM, 0);
}

static void TankRocket(entity self)
{
	vector  forward, right;
	vector  start;
	vector  dir;
	vector  vec;
	int     flash_number;

	if (self->s.frame == FRAME_attak324)
		flash_number = MZ2_TANK_ROCKET_1;
	else if (self->s.frame == FRAME_attak327)
		flash_number = MZ2_TANK_ROCKET_2;
	else // (self->s.frame == FRAME_attak330)
		flash_number = MZ2_TANK_ROCKET_3;

	AngleVectors(self->s.angles, &forward, &right, 0);
	G_ProjectSource(self->s.origin, monster_flash_offset[flash_number], forward, right, start);

	vec = self->enemy->s.origin;
	vec_z += self->enemy->viewheight;
	dir = vec - start;
	VectorNormalize(dir);

	monster_fire_rocket(self, start, dir, 50, 550, flash_number);
}

static void TankMachineGun(entity self)
{
	vector  dir;
	vector  vec;
	vector  start;
	vector  forward, right;
	int     flash_number;

	flash_number = MZ2_TANK_MACHINEGUN_1 + (self->s.frame - FRAME_attak406);

	AngleVectors(self->s.angles, &forward, &right, 0);
	G_ProjectSource(self->s.origin, monster_flash_offset[flash_number], forward, right, start);

	if (self->enemy) {
		vec = self->enemy->s.origin;
		vec_z += self->enemy->viewheight;
		vec = vec - start;
		vec = vectoangles(vec);
		dir_x = vec_x;
	} else {
		dir_x = 0;
	}
	if (self->s.frame <= FRAME_attak415)
		dir_y = self->s.angles[1] - 8 * (self->s.frame - FRAME_attak411);
	else
		dir_y = self->s.angles[1] + 8 * (self->s.frame - FRAME_attak419);
	dir_z = 0;

	AngleVectors(dir, &forward, 0, 0);

	monster_fire_bullet(self, start, forward, 20, 4, DEFAULT_BULLET_HSPREAD, DEFAULT_BULLET_VSPREAD, flash_number);
}

static mframe_t tank_frames_attack_blast [] = {
	{ ai_charge },
	{ ai_charge },
	{ ai_charge },
	{ ai_charge },
	{ ai_charge, -1 },
	{ ai_charge, -2 },
	{ ai_charge, -1 },
	{ ai_charge, -1 },
	{ ai_charge },
	{ ai_charge, 0,   TankBlaster },    // 10
	{ ai_charge },
	{ ai_charge },
	{ ai_charge, 0,   TankBlaster },
	{ ai_charge },
	{ ai_charge },
	{ ai_charge, 0,   TankBlaster }     // 16
};
static var mmove_t tank_move_attack_blast = { FRAME_attak101, FRAME_attak116 };

static mframe_t tank_frames_reattack_blast [] = {
	{ ai_charge },
	{ ai_charge },
	{ ai_charge, 0,   TankBlaster },
	{ ai_charge },
	{ ai_charge },
	{ ai_charge, 0,   TankBlaster }     // 16
};
static var mmove_t tank_move_reattack_blast = { FRAME_attak111, FRAME_attak116 };

static mframe_t tank_frames_attack_post_blast [] = {
	{ ai_move },           // 17
	{ ai_move },
	{ ai_move, 2 },
	{ ai_move, 3 },
	{ ai_move, 2 },
	{ ai_move, -2,    tank_footstep }   // 22
};
static var mmove_t tank_move_attack_post_blast = { FRAME_attak117, FRAME_attak122, tank_run };

static void tank_reattack_blaster(entity self)
{
	if (skill->intVal >= 2)
		if (visible(self, self->enemy))
			if (self->enemy->health > 0)
				if (random() <= 0.6f) {
					self->monsterinfo.currentmove = &tank_move_reattack_blast;
					return;
				}
	self->monsterinfo.currentmove = &tank_move_attack_post_blast;
}


static void tank_poststrike(entity self)
{
	self->enemy = world;
	tank_run(self);
}

static mframe_t tank_frames_attack_strike [] = {
	{ ai_move, 3 },
	{ ai_move, 2 },
	{ ai_move, 2 },
	{ ai_move, 1 },
	{ ai_move, 6 },
	{ ai_move, 7 },
	{ ai_move, 9,   tank_footstep },
	{ ai_move, 2 },
	{ ai_move, 1 },
	{ ai_move, 2 },
	{ ai_move, 2,   tank_footstep },
	{ ai_move, 2 },
	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move, -2 },
	{ ai_move, -2 },
	{ ai_move, 0,   tank_windup },
	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move, 0,   TankStrike },
	{ ai_move },
	{ ai_move, -1 },
	{ ai_move, -1 },
	{ ai_move, -1 },
	{ ai_move, -1 },
	{ ai_move, -1 },
	{ ai_move, -3 },
	{ ai_move, -10 },
	{ ai_move, -10 },
	{ ai_move, -2 },
	{ ai_move, -3 },
	{ ai_move, -2,  tank_footstep }
};
static var mmove_t tank_move_attack_strike = { FRAME_attak201, FRAME_attak238, tank_poststrike };

static mframe_t tank_frames_attack_pre_rocket [] = {
	{ ai_charge },
	{ ai_charge },
	{ ai_charge },
	{ ai_charge },
	{ ai_charge },
	{ ai_charge },
	{ ai_charge },
	{ ai_charge },
	{ ai_charge },
	{ ai_charge },            // 10

	{ ai_charge },
	{ ai_charge, 1 },
	{ ai_charge, 2 },
	{ ai_charge, 7 },
	{ ai_charge, 7 },
	{ ai_charge, 7,  tank_footstep },
	{ ai_charge },
	{ ai_charge },
	{ ai_charge },
	{ ai_charge },            // 20

	{ ai_charge, -3 }
};
static var mmove_t tank_move_attack_pre_rocket = { FRAME_attak301, FRAME_attak321 };

static mframe_t tank_frames_attack_fire_rocket [] = {
	{ ai_charge, -3 },            // Loop Start   22
	{ ai_charge },
	{ ai_charge, 0,  TankRocket },      // 24
	{ ai_charge },
	{ ai_charge },
	{ ai_charge, 0,  TankRocket },
	{ ai_charge },
	{ ai_charge },
	{ ai_charge, -1, TankRocket }       // 30   Loop End
};
static var mmove_t tank_move_attack_fire_rocket = { FRAME_attak322, FRAME_attak330 };

static mframe_t tank_frames_attack_post_rocket [] = {
	{ ai_charge },            // 31
	{ ai_charge, -1 },
	{ ai_charge, -1 },
	{ ai_charge },
	{ ai_charge, 2 },
	{ ai_charge, 3 },
	{ ai_charge, 4 },
	{ ai_charge, 2 },
	{ ai_charge },
	{ ai_charge },            // 40

	{ ai_charge },
	{ ai_charge, -9 },
	{ ai_charge, -8 },
	{ ai_charge, -7 },
	{ ai_charge, -1 },
	{ ai_charge, -1, tank_footstep },
	{ ai_charge },
	{ ai_charge },
	{ ai_charge },
	{ ai_charge },            // 50

	{ ai_charge },
	{ ai_charge },
	{ ai_charge }
};
static var mmove_t tank_move_attack_post_rocket = { FRAME_attak331, FRAME_attak353, tank_run };

static mframe_t tank_frames_attack_chain [] = {
	{ ai_charge },
	{ ai_charge },
	{ ai_charge },
	{ ai_charge },
	{ ai_charge },
	{ 0,      0, TankMachineGun },
	{ 0,      0, TankMachineGun },
	{ 0,      0, TankMachineGun },
	{ 0,      0, TankMachineGun },
	{ 0,      0, TankMachineGun },
	{ 0,      0, TankMachineGun },
	{ 0,      0, TankMachineGun },
	{ 0,      0, TankMachineGun },
	{ 0,      0, TankMachineGun },
	{ 0,      0, TankMachineGun },
	{ 0,      0, TankMachineGun },
	{ 0,      0, TankMachineGun },
	{ 0,      0, TankMachineGun },
	{ 0,      0, TankMachineGun },
	{ 0,      0, TankMachineGun },
	{ 0,      0, TankMachineGun },
	{ 0,      0, TankMachineGun },
	{ 0,      0, TankMachineGun },
	{ 0,      0, TankMachineGun },
	{ ai_charge },
	{ ai_charge },
	{ ai_charge },
	{ ai_charge },
	{ ai_charge }
};
static var mmove_t tank_move_attack_chain = { FRAME_attak401, FRAME_attak429, tank_run };

static void tank_refire_rocket(entity self)
{
	// Only on hard or nightmare
	if (skill->intVal >= 2)
		if (self->enemy->health > 0)
			if (visible(self, self->enemy))
				if (random() <= 0.4f) {
					self->monsterinfo.currentmove = &tank_move_attack_fire_rocket;
					return;
				}
	self->monsterinfo.currentmove = &tank_move_attack_post_rocket;
}

static void tank_doattack_rocket(entity self)
{
	self->monsterinfo.currentmove = &tank_move_attack_fire_rocket;
}

static void tank_attack(entity self)
{
	vector  vec;
	float   range;
	float   r;

	if (self->enemy->health < 0) {
		self->monsterinfo.currentmove = &tank_move_attack_strike;
		self->monsterinfo.aiflags &= ~AI_BRUTAL;
		return;
	}

	vec = self->enemy->s.origin - self->s.origin;
	range = VectorLength(vec);

	r = random();

	if (range <= 125) {
		if (r < 0.4f)
			self->monsterinfo.currentmove = &tank_move_attack_chain;
		else
			self->monsterinfo.currentmove = &tank_move_attack_blast;
	} else if (range <= 250) {
		if (r < 0.5f)
			self->monsterinfo.currentmove = &tank_move_attack_chain;
		else
			self->monsterinfo.currentmove = &tank_move_attack_blast;
	} else {
		if (r < 0.33f)
			self->monsterinfo.currentmove = &tank_move_attack_chain;
		else if (r < 0.66f) {
			self->monsterinfo.currentmove = &tank_move_attack_pre_rocket;
			self->pain_debounce_framenum = level.framenum + (int)(5.0f * BASE_FRAMERATE);  // no pain for a while
		} else
			self->monsterinfo.currentmove = &tank_move_attack_blast;
	}
}


//
// death
//

static void tank_dead(entity self)
{
	self->mins = '-16 -16 -16';
	self->maxs = '16 16 -0';
	self->movetype = MOVETYPE_TOSS;
	self->svflags |= SVF_DEADMONSTER;
	self->nextthink = 0;
	gi.linkentity(self);
}

static mframe_t tank_frames_death1 [] = {
	{ ai_move, -7 },
	{ ai_move, -2 },
	{ ai_move, -2 },
	{ ai_move, 1 },
	{ ai_move, 3 },
	{ ai_move, 6 },
	{ ai_move, 1 },
	{ ai_move, 1 },
	{ ai_move, 2 },
	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move, -2 },
	{ ai_move },
	{ ai_move },
	{ ai_move, -3 },
	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move, -4 },
	{ ai_move, -6 },
	{ ai_move, -4 },
	{ ai_move, -5 },
	{ ai_move, -7 },
	{ ai_move, -15, tank_thud },
	{ ai_move, -5 },
	{ ai_move },
	{ ai_move },
	{ ai_move }
};
static var mmove_t tank_move_death = { FRAME_death101, FRAME_death132, tank_dead };

static void tank_die(entity self, entity inflictor, entity attacker, int damage, vector point)
{
	int     n;

// check for gib
	if (self->health <= self->gib_health) {
		gi.sound(self, CHAN_VOICE, gi.soundindex("misc/udeath.wav"), 1, ATTN_NORM, 0);
		for (n = 0; n < 1 /*4*/; n++)
			ThrowGib(self, "models/objects/gibs/sm_meat/tris.md2", damage, GIB_ORGANIC);
		for (n = 0; n < 4; n++)
			ThrowGib(self, "models/objects/gibs/sm_metal/tris.md2", damage, GIB_METALLIC);
		ThrowGib(self, "models/objects/gibs/chest/tris.md2", damage, GIB_ORGANIC);
		ThrowHead(self, "models/objects/gibs/gear/tris.md2", damage, GIB_METALLIC);
		self->deadflag = DEAD_DEAD;
		return;
	}

	if (self->deadflag == DEAD_DEAD)
		return;

// regular death
	gi.sound(self, CHAN_VOICE, sound_die, 1, ATTN_NORM, 0);
	self->deadflag = DEAD_DEAD;
	self->takedamage = DAMAGE_YES;

	self->monsterinfo.currentmove = &tank_move_death;

}


//
// monster_tank
//

/*QUAKED monster_tank (1 .5 0) (-32 -32 -16) (32 32 72) Ambush Trigger_Spawn Sight
*/
/*QUAKED monster_tank_commander (1 .5 0) (-32 -32 -16) (32 32 72) Ambush Trigger_Spawn Sight
*/
API_FUNC static void SP_monster_tank(entity self)
{
	if (deathmatch->intVal) {
		G_FreeEdict(self);
		return;
	}
	
	if (!tank_move_stand.frame)
	{
		tank_move_stand.frame = &tank_frames_stand;
		tank_move_start_walk.frame = &tank_frames_start_walk;
		tank_move_start_walk.endfunc = tank_walk;
		tank_move_walk.frame = &tank_frames_walk;
		tank_move_stop_walk.frame = &tank_frames_stop_walk;
		tank_move_start_run.frame = &tank_frames_start_run;
		tank_move_start_run.endfunc = tank_run;
		tank_move_run.frame = &tank_frames_run;
		tank_move_stop_run.frame = &tank_frames_stop_run;
		tank_move_pain1.frame = &tank_frames_pain1;
		tank_move_pain2.frame = &tank_frames_pain2;
		tank_move_pain3.frame = &tank_frames_pain3;
		tank_move_attack_blast.frame = &tank_frames_attack_blast;
		tank_move_attack_blast.endfunc = tank_reattack_blaster;
		tank_move_reattack_blast.frame = &tank_frames_reattack_blast;
		tank_move_reattack_blast.endfunc = tank_reattack_blaster;
		tank_move_attack_post_blast.frame = &tank_frames_attack_post_blast;
		tank_move_attack_strike.frame = &tank_frames_attack_strike;
		tank_move_attack_pre_rocket.frame = &tank_frames_attack_pre_rocket;
		tank_move_attack_pre_rocket.endfunc = tank_doattack_rocket;
		tank_move_attack_fire_rocket.frame = &tank_frames_attack_fire_rocket;
		tank_move_attack_fire_rocket.endfunc = tank_refire_rocket;
		tank_move_attack_post_rocket.frame = &tank_frames_attack_post_rocket;
		tank_move_attack_chain.frame = &tank_frames_attack_chain;
		tank_move_death.frame = &tank_frames_death1;
	}

	self->s.modelindex = gi.modelindex("models/monsters/tank/tris.md2");
	self->mins = '-32 -32 -16';
	self->maxs = '32 32 72';
	self->movetype = MOVETYPE_STEP;
	self->solid = SOLID_BBOX;

	sound_pain = gi.soundindex("tank/tnkpain2.wav");
	sound_thud = gi.soundindex("tank/tnkdeth2.wav");
	sound_idle = gi.soundindex("tank/tnkidle1.wav");
	sound_die = gi.soundindex("tank/death.wav");
	sound_step = gi.soundindex("tank/step.wav");
	sound_windup = gi.soundindex("tank/tnkatck4.wav");
	sound_strike = gi.soundindex("tank/tnkatck5.wav");
	sound_sight = gi.soundindex("tank/sight1.wav");

	gi.soundindex("tank/tnkatck1.wav");
	gi.soundindex("tank/tnkatk2a.wav");
	gi.soundindex("tank/tnkatk2b.wav");
	gi.soundindex("tank/tnkatk2c.wav");
	gi.soundindex("tank/tnkatk2d.wav");
	gi.soundindex("tank/tnkatk2e.wav");
	gi.soundindex("tank/tnkatck3.wav");

	if (self->classname == "monster_tank_commander") {
		self->health = 1000;
		self->gib_health = -225;
	} else {
		self->health = 750;
		self->gib_health = -200;
	}

	self->mass = 500;

	self->pain = tank_pain;
	self->die = tank_die;
	self->monsterinfo.stand = tank_stand;
	self->monsterinfo.walk = tank_walk;
	self->monsterinfo.run = tank_run;
	self->monsterinfo.dodge = 0;
	self->monsterinfo.attack = tank_attack;
	self->monsterinfo.melee = 0;
	self->monsterinfo.sight = tank_sight;
	self->monsterinfo.idle = tank_idle;

	gi.linkentity(self);

	self->monsterinfo.currentmove = &tank_move_stand;
	self->monsterinfo.scale = MODEL_SCALE;

	walkmonster_start(self);

	if (self->classname == "monster_tank_commander")
		self->s.skinnum = 2;
}
