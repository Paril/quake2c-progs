#include "m_supertank.h"

bool visible(entity self, entity other);

static int  sound_pain1;
static int  sound_pain2;
static int  sound_pain3;
static int  sound_death;
static int  sound_search1;
static int  sound_search2;

static int tread_sound;

static void TreadSound(entity self)
{
	gi.sound(self, CHAN_VOICE, tread_sound, 1, ATTN_NORM, 0);
}

static void supertank_search(entity self)
{
	if (random() < 0.5f)
		gi.sound(self, CHAN_VOICE, sound_search1, 1, ATTN_NORM, 0);
	else
		gi.sound(self, CHAN_VOICE, sound_search2, 1, ATTN_NORM, 0);
}

//
// stand
//

static mframe_t supertank_frames_stand [] = {
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
static var mmove_t supertank_move_stand = { FRAME_stand_1, FRAME_stand_60 };

static void supertank_stand(entity self)
{
	self->monsterinfo.currentmove = &supertank_move_stand;
}

static mframe_t supertank_frames_run [] = {
	{ ai_run, 12, TreadSound },
	{ ai_run, 12 },
	{ ai_run, 12 },
	{ ai_run, 12 },
	{ ai_run, 12 },
	{ ai_run, 12 },
	{ ai_run, 12 },
	{ ai_run, 12 },
	{ ai_run, 12 },
	{ ai_run, 12 },
	{ ai_run, 12 },
	{ ai_run, 12 },
	{ ai_run, 12 },
	{ ai_run, 12 },
	{ ai_run, 12 },
	{ ai_run, 12 },
	{ ai_run, 12 },
	{ ai_run, 12 }
};
static var mmove_t supertank_move_run = { FRAME_forwrd_1, FRAME_forwrd_18 };

//
// walk
//
static mframe_t supertank_frames_forward [] = {
	{ ai_walk, 4, TreadSound },
	{ ai_walk, 4 },
	{ ai_walk, 4 },
	{ ai_walk, 4 },
	{ ai_walk, 4 },
	{ ai_walk, 4 },
	{ ai_walk, 4 },
	{ ai_walk, 4 },
	{ ai_walk, 4 },
	{ ai_walk, 4 },
	{ ai_walk, 4 },
	{ ai_walk, 4 },
	{ ai_walk, 4 },
	{ ai_walk, 4 },
	{ ai_walk, 4 },
	{ ai_walk, 4 },
	{ ai_walk, 4 },
	{ ai_walk, 4 }
};
static var mmove_t supertank_move_forward = { FRAME_forwrd_1, FRAME_forwrd_18 };

static void supertank_forward(entity self)
{
	self->monsterinfo.currentmove = &supertank_move_forward;
}

static void supertank_walk(entity self)
{
	self->monsterinfo.currentmove = &supertank_move_forward;
}

static void supertank_run(entity self)
{
	if (self->monsterinfo.aiflags & AI_STAND_GROUND)
		self->monsterinfo.currentmove = &supertank_move_stand;
	else
		self->monsterinfo.currentmove = &supertank_move_run;
}

static mframe_t supertank_frames_pain3 [] = {
	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move }
};
static var mmove_t supertank_move_pain3 = { FRAME_pain3_9, FRAME_pain3_12, supertank_run };

static mframe_t supertank_frames_pain2 [] = {
	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move }
};
static var mmove_t supertank_move_pain2 = { FRAME_pain2_5, FRAME_pain2_8, supertank_run };

static mframe_t supertank_frames_pain1 [] = {
	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move }
};
static var mmove_t supertank_move_pain1 = { FRAME_pain1_1, FRAME_pain1_4, supertank_run };

static void supertank_dead(entity self)
{
	self->mins = '-60 -60 0';
	self->maxs = '60 60 72';
	self->movetype = MOVETYPE_TOSS;
	self->svflags |= SVF_DEADMONSTER;
	self->nextthink = 0;
	gi.linkentity(self);
}

//
// death
//
void BossExplode(entity self)
{
	vector  org;
	int     n;

	self->think = BossExplode;
	VectorCopy(self->s.origin, org);
	org[2] += 24 + (Q_rand() & 15);
	switch (self->count++) {
	case 0:
		org[0] -= 24;
		org[1] -= 24;
		break;
	case 1:
		org[0] += 24;
		org[1] += 24;
		break;
	case 2:
		org[0] += 24;
		org[1] -= 24;
		break;
	case 3:
		org[0] -= 24;
		org[1] += 24;
		break;
	case 4:
		org[0] -= 48;
		org[1] -= 48;
		break;
	case 5:
		org[0] += 48;
		org[1] += 48;
		break;
	case 6:
		org[0] -= 48;
		org[1] += 48;
		break;
	case 7:
		org[0] += 48;
		org[1] -= 48;
		break;
	case 8:
		self->s.sound = 0;
		for (n = 0; n < 4; n++)
			ThrowGib(self, "models/objects/gibs/sm_meat/tris.md2", 500, GIB_ORGANIC);
		for (n = 0; n < 8; n++)
			ThrowGib(self, "models/objects/gibs/sm_metal/tris.md2", 500, GIB_METALLIC);
		ThrowGib(self, "models/objects/gibs/chest/tris.md2", 500, GIB_ORGANIC);
		ThrowHead(self, "models/objects/gibs/gear/tris.md2", 500, GIB_METALLIC);
		self->deadflag = DEAD_DEAD;
		return;
	}

	gi.WriteByte(svc_temp_entity);
	gi.WriteByte(TE_EXPLOSION1);
	gi.WritePosition(org);
	gi.multicast(self->s.origin, MULTICAST_PVS);

	self->nextthink = level.framenum + 1;
}

static mframe_t supertank_frames_death1 [] = {
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
static var mmove_t supertank_move_death = { FRAME_death_1, FRAME_death_24, supertank_dead };

static void supertankRocket(entity self)
{
	vector  forward, right;
	vector  start;
	vector  dir;
	vector  vec;
	int     flash_number;

	if (self->s.frame == FRAME_attak2_8)
		flash_number = MZ2_SUPERTANK_ROCKET_1;
	else if (self->s.frame == FRAME_attak2_11)
		flash_number = MZ2_SUPERTANK_ROCKET_2;
	else // (self->s.frame == FRAME_attak2_14)
		flash_number = MZ2_SUPERTANK_ROCKET_3;

	AngleVectors(self->s.angles, &forward, &right, 0);
	G_ProjectSource(self->s.origin, monster_flash_offset[flash_number], forward, right, start);

	VectorCopy(self->enemy->s.origin, vec);
	vec[2] += self->enemy->viewheight;
	VectorSubtract(vec, start, dir);
	VectorNormalize(dir);

	monster_fire_rocket(self, start, dir, 50, 500, flash_number);
}

static mframe_t supertank_frames_attack2[] = {
	{ ai_charge },
	{ ai_charge },
	{ ai_charge },
	{ ai_charge },
	{ ai_charge },
	{ ai_charge },
	{ ai_charge },
	{ ai_charge,  0,  supertankRocket },
	{ ai_move },
	{ ai_move },
	{ ai_move,    0,  supertankRocket },
	{ ai_move },
	{ ai_move },
	{ ai_move,    0,  supertankRocket },
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
static var mmove_t supertank_move_attack2 = { FRAME_attak2_1, FRAME_attak2_27, supertank_run };

void supertankMachineGun(entity self)
{
	vector  dir;
	vector  vec;
	vector  start;
	vector  forward, right;
	int     flash_number;

	flash_number = MZ2_SUPERTANK_MACHINEGUN_1 + (self->s.frame - FRAME_attak1_1);

	//FIXME!!!
	dir[0] = 0;
	dir[1] = self->s.angles[1];
	dir[2] = 0;

	AngleVectors(dir, &forward, &right, 0);
	G_ProjectSource(self->s.origin, monster_flash_offset[flash_number], forward, right, start);

	if (self->enemy) {
		VectorCopy(self->enemy->s.origin, vec);
		VectorMA(vec, 0, self->enemy->velocity, vec);
		vec[2] += self->enemy->viewheight;
		VectorSubtract(vec, start, forward);
		VectorNormalize(forward);
	}

	monster_fire_bullet(self, start, forward, 6, 4, DEFAULT_BULLET_HSPREAD, DEFAULT_BULLET_VSPREAD, flash_number);
}

static mframe_t supertank_frames_attack1[] = {
	{ ai_charge,  0,  supertankMachineGun },
	{ ai_charge,  0,  supertankMachineGun },
	{ ai_charge,  0,  supertankMachineGun },
	{ ai_charge,  0,  supertankMachineGun },
	{ ai_charge,  0,  supertankMachineGun },
	{ ai_charge,  0,  supertankMachineGun },

};
static var mmove_t supertank_move_attack1 = { FRAME_attak1_1, FRAME_attak1_6 };

static mframe_t supertank_frames_end_attack1[] = {
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
static var mmove_t supertank_move_end_attack1 = { FRAME_attak1_7, FRAME_attak1_20, supertank_run };

static void supertank_reattack1(entity self)
{
	if (visible(self, self->enemy))
		if (random() < 0.9f)
			self->monsterinfo.currentmove = &supertank_move_attack1;
		else
			self->monsterinfo.currentmove = &supertank_move_end_attack1;
	else
		self->monsterinfo.currentmove = &supertank_move_end_attack1;
}

static void supertank_pain(entity self, entity other, float kick, int damage)
{

	if (self->health < (self->max_health / 2))
		self->s.skinnum = 1;

	if (level.framenum < self->pain_debounce_framenum)
		return;

	// Lessen the chance of him going into his pain frames
	if (damage <= 25)
		if (random() < 0.2f)
			return;

	// Don't go into pain if he's firing his rockets
	if (skill->intVal >= 2)
		if ((self->s.frame >= FRAME_attak2_1) && (self->s.frame <= FRAME_attak2_14))
			return;

	self->pain_debounce_framenum = level.framenum + 3 * BASE_FRAMERATE;

	if (skill->intVal == 3)
		return;     // no pain anims in nightmare

	if (damage <= 10) {
		gi.sound(self, CHAN_VOICE, sound_pain1, 1, ATTN_NORM, 0);
		self->monsterinfo.currentmove = &supertank_move_pain1;
	} else if (damage <= 25) {
		gi.sound(self, CHAN_VOICE, sound_pain3, 1, ATTN_NORM, 0);
		self->monsterinfo.currentmove = &supertank_move_pain2;
	} else {
		gi.sound(self, CHAN_VOICE, sound_pain2, 1, ATTN_NORM, 0);
		self->monsterinfo.currentmove = &supertank_move_pain3;
	}
}

static void supertank_attack(entity self)
{
	vector  vec;
	float   range;
	//float r;

	VectorSubtract(self->enemy->s.origin, self->s.origin, vec);
	range = VectorLength(vec);

	//r = random();

	// Attack 1 == Chaingun
	// Attack 2 == Rocket Launcher

	if (range <= 160) {
		self->monsterinfo.currentmove = &supertank_move_attack1;
	} else {
		// fire rockets more often at distance
		if (random() < 0.3f)
			self->monsterinfo.currentmove = &supertank_move_attack1;
		else
			self->monsterinfo.currentmove = &supertank_move_attack2;
	}
}


static void supertank_die(entity self, entity inflictor, entity attacker, int damage, vector point)
{
	gi.sound(self, CHAN_VOICE, sound_death, 1, ATTN_NORM, 0);
	self->deadflag = DEAD_DEAD;
	self->takedamage = DAMAGE_NO;
	self->count = 0;
	self->monsterinfo.currentmove = &supertank_move_death;
}

//
// monster_supertank
//

/*QUAKED monster_supertank (1 .5 0) (-64 -64 0) (64 64 72) Ambush Trigger_Spawn Sight
*/
API_FUNC static void SP_monster_supertank(entity self)
{
	if (deathmatch->intVal) {
		G_FreeEdict(self);
		return;
	}
	
	if (!supertank_move_stand.frame)
	{
		supertank_move_stand.frame = &supertank_frames_stand;
		supertank_move_run.frame = &supertank_frames_run;
		supertank_move_forward.frame = &supertank_frames_forward;
		supertank_move_pain1.frame = &supertank_frames_pain1;
		supertank_move_pain2.frame = &supertank_frames_pain2;
		supertank_move_pain3.frame = &supertank_frames_pain3;
		supertank_move_death.frame = &supertank_frames_death1;
		supertank_move_attack2.frame = &supertank_frames_attack2;
		supertank_move_attack1.frame = &supertank_frames_attack1;
		supertank_move_attack1.endfunc = supertank_reattack1;
		supertank_move_end_attack1.frame = &supertank_frames_end_attack1;
	}

	sound_pain1 = gi.soundindex("bosstank/btkpain1.wav");
	sound_pain2 = gi.soundindex("bosstank/btkpain2.wav");
	sound_pain3 = gi.soundindex("bosstank/btkpain3.wav");
	sound_death = gi.soundindex("bosstank/btkdeth1.wav");
	sound_search1 = gi.soundindex("bosstank/btkunqv1.wav");
	sound_search2 = gi.soundindex("bosstank/btkunqv2.wav");

//  self->s.sound = gi.soundindex ("bosstank/btkengn1.wav");
	tread_sound = gi.soundindex("bosstank/btkengn1.wav");

	self->movetype = MOVETYPE_STEP;
	self->solid = SOLID_BBOX;
	self->s.modelindex = gi.modelindex("models/monsters/boss1/tris.md2");
	self->mins = '-64 -64 0';
	self->maxs = '64 64 112';

	self->health = 1500;
	self->gib_health = -500;
	self->mass = 800;

	self->pain = supertank_pain;
	self->die = supertank_die;
	self->monsterinfo.stand = supertank_stand;
	self->monsterinfo.walk = supertank_walk;
	self->monsterinfo.run = supertank_run;
	self->monsterinfo.dodge = 0;
	self->monsterinfo.attack = supertank_attack;
	self->monsterinfo.search = supertank_search;
	self->monsterinfo.melee = 0;
	self->monsterinfo.sight = 0;

	gi.linkentity(self);

	self->monsterinfo.currentmove = &supertank_move_stand;
	self->monsterinfo.scale = MODEL_SCALE;

	walkmonster_start(self);
}
