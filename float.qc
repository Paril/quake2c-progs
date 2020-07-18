#include "m_float.h"


static int  sound_attack2;
static int  sound_attack3;
static int  sound_death1;
static int  sound_idle;
static int  sound_pain1;
static int  sound_pain2;
static int  sound_sight;

static void floater_sight(entity self, entity other)
{
	gi.sound(self, CHAN_VOICE, sound_sight, 1, ATTN_NORM, 0);
}

static void floater_idle(entity self)
{
	gi.sound(self, CHAN_VOICE, sound_idle, 1, ATTN_IDLE, 0);
}

static void floater_fire_blaster(entity self)
{
	vector  start;
	vector  forward, right;
	vector  end;
	vector  dir;
	int     effect;

	if ((self->s.frame == FRAME_attak104) || (self->s.frame == FRAME_attak107))
		effect = EF_HYPERBLASTER;
	else
		effect = 0;
	AngleVectors(self->s.angles, forward, right, unref_vec);
	G_ProjectSource(self->s.origin, monster_flash_offset[MZ2_FLOAT_BLASTER_1], forward, right, start);

	VectorCopy(self->enemy->s.origin, end);
	end_z += self->enemy->viewheight;
	VectorSubtract(end, start, dir);

	monster_fire_blaster(self, start, dir, 1, 1000, MZ2_FLOAT_BLASTER_1, effect);
}

static mframe_t floater_frames_stand1 [] = {
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
static var mmove_t floater_move_stand1 = { FRAME_stand101, FRAME_stand152 };

static mframe_t floater_frames_stand2 [] = {
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
static var mmove_t floater_move_stand2 = { FRAME_stand201, FRAME_stand252 };

static void floater_stand(entity self)
{
	if (frand() <= 0.5f)
		self->monsterinfo.currentmove = &floater_move_stand1;
	else
		self->monsterinfo.currentmove = &floater_move_stand2;
}

static mframe_t floater_frames_run [] = {
	{ ai_run, 13 },
	{ ai_run, 13 },
	{ ai_run, 13 },
	{ ai_run, 13 },
	{ ai_run, 13 },
	{ ai_run, 13 },
	{ ai_run, 13 },
	{ ai_run, 13 },
	{ ai_run, 13 },
	{ ai_run, 13 },
	{ ai_run, 13 },
	{ ai_run, 13 },
	{ ai_run, 13 },
	{ ai_run, 13 },
	{ ai_run, 13 },
	{ ai_run, 13 },
	{ ai_run, 13 },
	{ ai_run, 13 },
	{ ai_run, 13 },
	{ ai_run, 13 },
	{ ai_run, 13 },
	{ ai_run, 13 },
	{ ai_run, 13 },
	{ ai_run, 13 },
	{ ai_run, 13 },
	{ ai_run, 13 },
	{ ai_run, 13 },
	{ ai_run, 13 },
	{ ai_run, 13 },
	{ ai_run, 13 },
	{ ai_run, 13 },
	{ ai_run, 13 },
	{ ai_run, 13 },
	{ ai_run, 13 },
	{ ai_run, 13 },
	{ ai_run, 13 },
	{ ai_run, 13 },
	{ ai_run, 13 },
	{ ai_run, 13 },
	{ ai_run, 13 },
	{ ai_run, 13 },
	{ ai_run, 13 },
	{ ai_run, 13 },
	{ ai_run, 13 },
	{ ai_run, 13 },
	{ ai_run, 13 },
	{ ai_run, 13 },
	{ ai_run, 13 },
	{ ai_run, 13 },
	{ ai_run, 13 },
	{ ai_run, 13 },
	{ ai_run, 13 }
};
static var mmove_t floater_move_run = { FRAME_stand101, FRAME_stand152 };

static void floater_run(entity self)
{
	if (self->monsterinfo.aiflags & AI_STAND_GROUND)
		self->monsterinfo.currentmove = &floater_move_stand1;
	else
		self->monsterinfo.currentmove = &floater_move_run;
}

static mframe_t floater_frames_attack1 [] = {
	{ ai_charge },           // Blaster attack
	{ ai_charge },
	{ ai_charge },
	{ ai_charge,  0,  floater_fire_blaster },           // BOOM (0, -25.8, 32.5)    -- LOOP Starts
	{ ai_charge,  0,  floater_fire_blaster },
	{ ai_charge,  0,  floater_fire_blaster },
	{ ai_charge,  0,  floater_fire_blaster },
	{ ai_charge,  0,  floater_fire_blaster },
	{ ai_charge,  0,  floater_fire_blaster },
	{ ai_charge,  0,  floater_fire_blaster },
	{ ai_charge },
	{ ai_charge },
	{ ai_charge },
	{ ai_charge }            //                          -- LOOP Ends
};
static var mmove_t floater_move_attack1 = { FRAME_attak101, FRAME_attak114, floater_run };

static void floater_wham(entity self)
{
	static vector  aim = {MELEE_DISTANCE, 0, 0};
	gi.sound(self, CHAN_WEAPON, sound_attack3, 1, ATTN_NORM, 0);
	fire_hit(self, aim, 5 + Q_rand() % 6, -50);
}

static mframe_t floater_frames_attack2 [] = {
	{ ai_charge },           // Claws
	{ ai_charge },
	{ ai_charge },
	{ ai_charge },
	{ ai_charge },
	{ ai_charge },
	{ ai_charge },
	{ ai_charge },
	{ ai_charge },
	{ ai_charge },
	{ ai_charge },
	{ ai_charge,  0,  floater_wham },           // WHAM (0, -45, 29.6)      -- LOOP Starts
	{ ai_charge },
	{ ai_charge },
	{ ai_charge },
	{ ai_charge },
	{ ai_charge },
	{ ai_charge },
	{ ai_charge },           //                          -- LOOP Ends
	{ ai_charge },
	{ ai_charge },
	{ ai_charge },
	{ ai_charge },
	{ ai_charge },
	{ ai_charge }
};
static var mmove_t floater_move_attack2 = {FRAME_attak201, FRAME_attak225, floater_run};

static void floater_zap(entity self)
{
	vector  forward, right;
	vector  origin;
	vector  dir;
	vector  offset;

	VectorSubtract(self->enemy->s.origin, self->s.origin, dir);

	AngleVectors(self->s.angles, forward, right, unref_vec);
	//FIXME use a flash and replace these two lines with the commented one
	VectorSet(offset, 18.5f, -0.9f, 10);
	G_ProjectSource(self->s.origin, offset, forward, right, origin);
//  G_ProjectSource (self->s.origin, monster_flash_offset[flash_number], forward, right, origin);

	gi.sound(self, CHAN_WEAPON, sound_attack2, 1, ATTN_NORM, 0);

	//FIXME use the flash, Luke
	gi.WriteByte(svc_temp_entity);
	gi.WriteByte(TE_SPLASH);
	gi.WriteByte(32);
	gi.WritePosition(origin);
	gi.WriteDir(dir);
	gi.WriteByte(1);    //sparks
	gi.multicast(origin, MULTICAST_PVS);

	T_Damage(self->enemy, self, self, dir, self->enemy->s.origin, vec3_origin, 5 + Q_rand() % 6, -10, DAMAGE_ENERGY, MOD_UNKNOWN);
}

static mframe_t floater_frames_attack3 [] = {
	{ ai_charge },
	{ ai_charge },
	{ ai_charge },
	{ ai_charge },
	{ ai_charge },
	{ ai_charge },
	{ ai_charge },
	{ ai_charge },
	{ ai_charge, 0, floater_zap },        //                              -- LOOP Starts
	{ ai_charge },
	{ ai_charge },
	{ ai_charge },
	{ ai_charge },
	{ ai_charge },
	{ ai_charge },
	{ ai_charge },
	{ ai_charge },
	{ ai_charge },
	{ ai_charge },
	{ ai_charge },
	{ ai_charge },
	{ ai_charge },
	{ ai_charge },
	{ ai_charge },
	{ ai_charge },
	{ ai_charge },
	{ ai_charge },
	{ ai_charge },
	{ ai_charge },       //                              -- LOOP Ends
	{ ai_charge },
	{ ai_charge },
	{ ai_charge },
	{ ai_charge },
	{ ai_charge }
};
static var mmove_t floater_move_attack3 = { FRAME_attak301, FRAME_attak334, floater_run };

static mframe_t floater_frames_pain1 [] = {
	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move }
};
static var mmove_t floater_move_pain1 = { FRAME_pain101, FRAME_pain107, floater_run };

static mframe_t floater_frames_pain2 [] = {
	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move }
};
static var mmove_t floater_move_pain2 = { FRAME_pain201, FRAME_pain208, floater_run };

static mframe_t floater_frames_pain3 [] = {
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
static var mmove_t floater_move_pain3 = { FRAME_pain301, FRAME_pain312, floater_run };

static mframe_t floater_frames_walk [] = {
	{ ai_walk, 5 },
	{ ai_walk, 5 },
	{ ai_walk, 5 },
	{ ai_walk, 5 },
	{ ai_walk, 5 },
	{ ai_walk, 5 },
	{ ai_walk, 5 },
	{ ai_walk, 5 },
	{ ai_walk, 5 },
	{ ai_walk, 5 },
	{ ai_walk, 5 },
	{ ai_walk, 5 },
	{ ai_walk, 5 },
	{ ai_walk, 5 },
	{ ai_walk, 5 },
	{ ai_walk, 5 },
	{ ai_walk, 5 },
	{ ai_walk, 5 },
	{ ai_walk, 5 },
	{ ai_walk, 5 },
	{ ai_walk, 5 },
	{ ai_walk, 5 },
	{ ai_walk, 5 },
	{ ai_walk, 5 },
	{ ai_walk, 5 },
	{ ai_walk, 5 },
	{ ai_walk, 5 },
	{ ai_walk, 5 },
	{ ai_walk, 5 },
	{ ai_walk, 5 },
	{ ai_walk, 5 },
	{ ai_walk, 5 },
	{ ai_walk, 5 },
	{ ai_walk, 5 },
	{ ai_walk, 5 },
	{ ai_walk, 5 },
	{ ai_walk, 5 },
	{ ai_walk, 5 },
	{ ai_walk, 5 },
	{ ai_walk, 5 },
	{ ai_walk, 5 },
	{ ai_walk, 5 },
	{ ai_walk, 5 },
	{ ai_walk, 5 },
	{ ai_walk, 5 },
	{ ai_walk, 5 },
	{ ai_walk, 5 },
	{ ai_walk, 5 },
	{ ai_walk, 5 },
	{ ai_walk, 5 },
	{ ai_walk, 5 },
	{ ai_walk, 5 }
};
static var mmove_t floater_move_walk = { FRAME_stand101, FRAME_stand152 };

static void floater_walk(entity self)
{
	self->monsterinfo.currentmove = &floater_move_walk;
}

static void floater_attack(entity self)
{
	self->monsterinfo.currentmove = &floater_move_attack1;
}


static void floater_melee(entity self)
{
	if (frand() < 0.5f)
		self->monsterinfo.currentmove = &floater_move_attack3;
	else
		self->monsterinfo.currentmove = &floater_move_attack2;
}

static void floater_pain(entity self, entity other, float kick, int damage)
{
	int     n;

	if (self->health < (self->max_health / 2))
		self->s.skinnum = 1;

	if (level.framenum < self->pain_debounce_framenum)
		return;

	self->pain_debounce_framenum = level.framenum + 3 * BASE_FRAMERATE;
	if (skill->intVal == 3)
		return;     // no pain anims in nightmare

	n = (Q_rand() + 1) % 3;
	if (n == 0) {
		gi.sound(self, CHAN_VOICE, sound_pain1, 1, ATTN_NORM, 0);
		self->monsterinfo.currentmove = &floater_move_pain1;
	} else {
		gi.sound(self, CHAN_VOICE, sound_pain2, 1, ATTN_NORM, 0);
		self->monsterinfo.currentmove = &floater_move_pain2;
	}
}

static void(entity self, entity inflictor, entity attacker, int damage, vector point) floater_die =
{
	gi.sound(self, CHAN_VOICE, sound_death1, 1, ATTN_NORM, 0);
	BecomeExplosion1(self);
}

/*QUAKED monster_floater (1 .5 0) (-16 -16 -24) (16 16 32) Ambush Trigger_Spawn Sight
*/
API_FUNC static void SP_monster_floater(entity self)
{
	if (deathmatch->intVal) {
		G_FreeEdict(self);
		return;
	}
	
	if (!floater_move_stand1.frame)
	{
		floater_move_stand1.frame = &floater_frames_stand1;
		floater_move_stand2.frame = &floater_frames_stand2;

		floater_move_run.frame = &floater_frames_run;
		floater_move_attack1.frame = &floater_frames_attack1;
		floater_move_attack2.frame = &floater_frames_attack2;
		floater_move_attack3.frame = &floater_frames_attack3;

		floater_move_pain1.frame = &floater_frames_pain1;
		floater_move_pain2.frame = &floater_frames_pain2;
		floater_move_pain3.frame = &floater_frames_pain3;

		floater_move_walk.frame = &floater_frames_walk;
	}

	sound_attack2 = gi.soundindex("floater/fltatck2.wav");
	sound_attack3 = gi.soundindex("floater/fltatck3.wav");
	sound_death1 = gi.soundindex("floater/fltdeth1.wav");
	sound_idle = gi.soundindex("floater/fltidle1.wav");
	sound_pain1 = gi.soundindex("floater/fltpain1.wav");
	sound_pain2 = gi.soundindex("floater/fltpain2.wav");
	sound_sight = gi.soundindex("floater/fltsght1.wav");

	gi.soundindex("floater/fltatck1.wav");

	self->s.sound = gi.soundindex("floater/fltsrch1.wav");

	self->movetype = MOVETYPE_STEP;
	self->solid = SOLID_BBOX;
	self->s.modelindex = gi.modelindex("models/monsters/float/tris.md2");
	VectorSet(self->mins, -24, -24, -24);
	VectorSet(self->maxs, 24, 24, 32);

	self->health = 200;
	self->gib_health = -80;
	self->mass = 300;

	self->pain = floater_pain;
	self->die = floater_die;

	self->monsterinfo.stand = floater_stand;
	self->monsterinfo.walk = floater_walk;
	self->monsterinfo.run = floater_run;
//  self->monsterinfo.dodge = floater_dodge;
	self->monsterinfo.attack = floater_attack;
	self->monsterinfo.melee = floater_melee;
	self->monsterinfo.sight = floater_sight;
	self->monsterinfo.idle = floater_idle;

	gi.linkentity(self);

	if (frand() <= 0.5f)
		self->monsterinfo.currentmove = &floater_move_stand1;
	else
		self->monsterinfo.currentmove = &floater_move_stand2;

	self->monsterinfo.scale = MODEL_SCALE;

	flymonster_start(self);
}
