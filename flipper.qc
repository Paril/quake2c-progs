#ifdef SINGLE_PLAYER
#include "m_flipper.h"

static int  sound_chomp;
static int  sound_attack;
static int  sound_pain1;
static int  sound_pain2;
static int  sound_death;
static int  sound_idle;
static int  sound_search;
static int  sound_sight;

static mframe_t flipper_frames_stand [] = {
	{ ai_stand }
};
static var mmove_t flipper_move_stand = { FRAME_flphor01, FRAME_flphor01 };

static void flipper_stand(entity self)
{
	self.monsterinfo.currentmove = &flipper_move_stand;
}

const float FLIPPER_RUN_SPEED	= 24f;

static mframe_t flipper_frames_run [] = {
	{ ai_run, FLIPPER_RUN_SPEED },    // 6
	{ ai_run, FLIPPER_RUN_SPEED },
	{ ai_run, FLIPPER_RUN_SPEED },
	{ ai_run, FLIPPER_RUN_SPEED },
	{ ai_run, FLIPPER_RUN_SPEED },    // 10

	{ ai_run, FLIPPER_RUN_SPEED },
	{ ai_run, FLIPPER_RUN_SPEED },
	{ ai_run, FLIPPER_RUN_SPEED },
	{ ai_run, FLIPPER_RUN_SPEED },
	{ ai_run, FLIPPER_RUN_SPEED },
	{ ai_run, FLIPPER_RUN_SPEED },
	{ ai_run, FLIPPER_RUN_SPEED },
	{ ai_run, FLIPPER_RUN_SPEED },
	{ ai_run, FLIPPER_RUN_SPEED },
	{ ai_run, FLIPPER_RUN_SPEED },    // 20

	{ ai_run, FLIPPER_RUN_SPEED },
	{ ai_run, FLIPPER_RUN_SPEED },
	{ ai_run, FLIPPER_RUN_SPEED },
	{ ai_run, FLIPPER_RUN_SPEED },
	{ ai_run, FLIPPER_RUN_SPEED },
	{ ai_run, FLIPPER_RUN_SPEED },
	{ ai_run, FLIPPER_RUN_SPEED },
	{ ai_run, FLIPPER_RUN_SPEED },
	{ ai_run, FLIPPER_RUN_SPEED }     // 29
};
static var mmove_t flipper_move_run_loop = { FRAME_flpver06, FRAME_flpver29 };

static void flipper_run_loop(entity self)
{
	self.monsterinfo.currentmove = &flipper_move_run_loop;
}

static mframe_t flipper_frames_run_start [] = {
	{ ai_run, 8 },
	{ ai_run, 8 },
	{ ai_run, 8 },
	{ ai_run, 8 },
	{ ai_run, 8 },
	{ ai_run, 8 }
};
static var mmove_t flipper_move_run_start = { FRAME_flpver01, FRAME_flpver06, flipper_run_loop };

static void flipper_run(entity self)
{
	self.monsterinfo.currentmove = &flipper_move_run_start;
}

/* Standard Swimming */
static mframe_t flipper_frames_walk [] = {
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
	{ ai_walk, 4 },
	{ ai_walk, 4 },
	{ ai_walk, 4 },
	{ ai_walk, 4 },
	{ ai_walk, 4 },
	{ ai_walk, 4 },
	{ ai_walk, 4 },
	{ ai_walk, 4 }
};
static var mmove_t flipper_move_walk = { FRAME_flphor01, FRAME_flphor24 };

static void flipper_walk(entity self)
{
	self.monsterinfo.currentmove = &flipper_move_walk;
}

static mframe_t flipper_frames_start_run [] = {
	{ ai_run, 8 },
	{ ai_run, 8 },
	{ ai_run, 8 },
	{ ai_run, 8 },
	{ ai_run, 8, flipper_run }
};
static var mmove_t flipper_move_start_run = { FRAME_flphor01, FRAME_flphor05 };

static void flipper_start_run(entity self)
{
	self.monsterinfo.currentmove = &flipper_move_start_run;
}

static mframe_t flipper_frames_pain2 [] = {
	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move }
};
static var mmove_t flipper_move_pain2 = { FRAME_flppn101, FRAME_flppn105, flipper_run };

static mframe_t flipper_frames_pain1 [] = {
	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move }
};
static var mmove_t flipper_move_pain1 = { FRAME_flppn201, FRAME_flppn205, flipper_run };

static void flipper_bite(entity self)
{
	static const vector  aim = [ MELEE_DISTANCE, 0, 0 ];
	fire_hit(self, aim, 5, 0);
}

static void flipper_preattack(entity self)
{
	gi.sound(self, CHAN_WEAPON, sound_chomp, 1, ATTN_NORM, 0);
}

static mframe_t flipper_frames_attack [] = {
	{ ai_charge, 0,   flipper_preattack },
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
	{ ai_charge, 0,   flipper_bite },
	{ ai_charge },
	{ ai_charge },
	{ ai_charge },
	{ ai_charge },
	{ ai_charge, 0,   flipper_bite },
	{ ai_charge }
};
static var mmove_t flipper_move_attack = { FRAME_flpbit01, FRAME_flpbit20, flipper_run };

static void flipper_melee(entity self)
{
	self.monsterinfo.currentmove = &flipper_move_attack;
}

static void flipper_pain(entity self, entity other, float kick, int damage)
{
	int     n;

	if (self.health < (self.max_health / 2))
		self.s.skinnum = 1;

	if (level.framenum < self.pain_debounce_framenum)
		return;

	self.pain_debounce_framenum = level.framenum + 3 * BASE_FRAMERATE;

	if (skill.intVal == 3)
		return;     // no pain anims in nightmare

	n = (Q_rand() + 1) % 2;
	if (n == 0) {
		gi.sound(self, CHAN_VOICE, sound_pain1, 1, ATTN_NORM, 0);
		self.monsterinfo.currentmove = &flipper_move_pain1;
	} else {
		gi.sound(self, CHAN_VOICE, sound_pain2, 1, ATTN_NORM, 0);
		self.monsterinfo.currentmove = &flipper_move_pain2;
	}
}

static void flipper_dead(entity self)
{
	self.mins = '-16 -16 -24';
	self.maxs = '16 16 -8';
	self.movetype = MOVETYPE_TOSS;
	self.svflags |= SVF_DEADMONSTER;
	self.nextthink = 0;
	gi.linkentity(self);
}

static mframe_t flipper_frames_death [] = {
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
	{ ai_move },
	{ ai_move },

	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move }
};
static var mmove_t flipper_move_death = { FRAME_flpdth01, FRAME_flpdth56, flipper_dead };

static void flipper_sight(entity self, entity other)
{
	gi.sound(self, CHAN_VOICE, sound_sight, 1, ATTN_NORM, 0);
}

static void flipper_die(entity self, entity inflictor, entity attacker, int damage, vector point)
{
	int     n;

// check for gib
	if (self.health <= self.gib_health) {
		gi.sound(self, CHAN_VOICE, gi.soundindex("misc/udeath.wav"), 1, ATTN_NORM, 0);
		for (n = 0; n < 2; n++)
			ThrowGib(self, "models/objects/gibs/bone/tris.md2", damage, GIB_ORGANIC);
		for (n = 0; n < 2; n++)
			ThrowGib(self, "models/objects/gibs/sm_meat/tris.md2", damage, GIB_ORGANIC);
		ThrowHead(self, "models/objects/gibs/sm_meat/tris.md2", damage, GIB_ORGANIC);
		self.deadflag = DEAD_DEAD;
		return;
	}

	if (self.deadflag == DEAD_DEAD)
		return;

// regular death
	gi.sound(self, CHAN_VOICE, sound_death, 1, ATTN_NORM, 0);
	self.deadflag = DEAD_DEAD;
	self.takedamage = true;
	self.monsterinfo.currentmove = &flipper_move_death;
}

/*QUAKED monster_flipper (1 .5 0) (-16 -16 -24) (16 16 32) Ambush Trigger_Spawn Sight
*/
API_FUNC static void SP_monster_flipper(entity self)
{
	if (deathmatch.intVal) {
		G_FreeEdict(self);
		return;
	}

	if (!flipper_move_stand.frame)
	{
		flipper_move_stand.frame = &flipper_frames_stand;
		flipper_move_run_loop.frame = &flipper_frames_run;
		flipper_move_run_start.frame = &flipper_frames_run_start;
		flipper_move_walk.frame = &flipper_frames_walk;
		flipper_move_start_run.frame = &flipper_frames_start_run;
		flipper_move_pain2.frame = &flipper_frames_pain2;
		flipper_move_pain1.frame = &flipper_frames_pain1;
		flipper_move_attack.frame = &flipper_frames_attack;
		flipper_move_death.frame = &flipper_frames_death;
	}

	sound_pain1     = gi.soundindex("flipper/flppain1.wav");
	sound_pain2     = gi.soundindex("flipper/flppain2.wav");
	sound_death     = gi.soundindex("flipper/flpdeth1.wav");
	sound_chomp     = gi.soundindex("flipper/flpatck1.wav");
	sound_attack    = gi.soundindex("flipper/flpatck2.wav");
	sound_idle      = gi.soundindex("flipper/flpidle1.wav");
	sound_search    = gi.soundindex("flipper/flpsrch1.wav");
	sound_sight     = gi.soundindex("flipper/flpsght1.wav");

	self.movetype = MOVETYPE_STEP;
	self.solid = SOLID_BBOX;
	self.s.modelindex = gi.modelindex("models/monsters/flipper/tris.md2");
	self.mins = '-16 -16 0';
	self.maxs = '16 16 32';

	self.health = 50;
	self.gib_health = -30;
	self.mass = 100;

	self.pain = flipper_pain;
	self.die = flipper_die;

	self.monsterinfo.stand = flipper_stand;
	self.monsterinfo.walk = flipper_walk;
	self.monsterinfo.run = flipper_start_run;
	self.monsterinfo.melee = flipper_melee;
	self.monsterinfo.sight = flipper_sight;

	gi.linkentity(self);

	self.monsterinfo.currentmove = &flipper_move_stand;
	self.monsterinfo.scale = MODEL_SCALE;

	swimmonster_start(self);
}
#endif