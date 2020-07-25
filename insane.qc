#include "m_insane.h"


static int  sound_fist;
static int  sound_shake;
static int  sound_moan;
static int  sound_scream[8];

static void insane_fist(entity self)
{
	gi.sound(self, CHAN_VOICE, sound_fist, 1, ATTN_IDLE, 0);
}

static void insane_shake(entity self)
{
	gi.sound(self, CHAN_VOICE, sound_shake, 1, ATTN_IDLE, 0);
}

static void insane_moan(entity self)
{
	gi.sound(self, CHAN_VOICE, sound_moan, 1, ATTN_IDLE, 0);
}

static void insane_scream(entity self)
{
	gi.sound(self, CHAN_VOICE, sound_scream[Q_rand() % 8], 1, ATTN_IDLE, 0);
}

static mframe_t insane_frames_uptodown [] = {
	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move,    0,  insane_moan },
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

	{ ai_move,    2.7 },
	{ ai_move,    4.1 },
	{ ai_move,    6 },
	{ ai_move,    7.6 },
	{ ai_move,    3.6 },
	{ ai_move },
	{ ai_move },
	{ ai_move,    0,  insane_fist },
	{ ai_move },
	{ ai_move },

	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move,    0,  insane_fist },
	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move }
};
static var mmove_t insane_move_uptodown = { FRAME_stand1, FRAME_stand40 };

mframe_t insane_frames_downtoup [] = {
	{ ai_move,    -0.7 },           // 41
	{ ai_move,    -1.2 },           // 42
	{ ai_move,    -1.5 },       // 43
	{ ai_move,    -4.5 },       // 44
	{ ai_move,    -3.5 },           // 45
	{ ai_move,    -0.2 },           // 46
	{ ai_move },           // 47
	{ ai_move,    -1.3 },           // 48
	{ ai_move,    -3 },               // 49
	{ ai_move,    -2 },           // 50
	{ ai_move },               // 51
	{ ai_move },               // 52
	{ ai_move },               // 53
	{ ai_move,    -3.3 },           // 54
	{ ai_move,    -1.6 },           // 55
	{ ai_move,    -0.3 },           // 56
	{ ai_move },               // 57
	{ ai_move },               // 58
	{ ai_move }                // 59
};
static var mmove_t insane_move_downtoup = { FRAME_stand41, FRAME_stand59 };

static mframe_t insane_frames_jumpdown [] = {
	{ ai_move,    0.2 },
	{ ai_move,    11.5 },
	{ ai_move,    5.1 },
	{ ai_move,    7.1 },
	{ ai_move }
};
static var mmove_t insane_move_jumpdown = { FRAME_stand96, FRAME_stand100 };

static void insane_checkdown(entity self)
{
//  if ( (self.s.frame == FRAME_stand94) || (self.s.frame == FRAME_stand65) )
	if (self.spawnflags & 32)              // Always stand
		return;
	if (random() < 0.3f) {
		if (random() < 0.5f)
			self.monsterinfo.currentmove = &insane_move_uptodown;
		else
			self.monsterinfo.currentmove = &insane_move_jumpdown;
	}
}

static mframe_t insane_frames_stand_normal [] = {
	{ ai_stand },
	{ ai_stand },
	{ ai_stand },
	{ ai_stand },
	{ ai_stand },
	{ ai_stand, 0, insane_checkdown }
};
static var mmove_t insane_move_stand_normal = { FRAME_stand60, FRAME_stand65 };

static mframe_t insane_frames_stand_insane [] = {
	{ ai_stand,   0,  insane_shake },
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
	{ ai_stand,   0,  insane_checkdown }
};
static var mmove_t insane_move_stand_insane = { FRAME_stand65, FRAME_stand94 };

static void insane_checkup(entity self)
{
	// If Hold_Ground and Crawl are set
	if ((self.spawnflags & 4) && (self.spawnflags & 16))
		return;
	if (random() < 0.5f)
		self.monsterinfo.currentmove = &insane_move_downtoup;
}

static mframe_t insane_frames_down [] = {
	{ ai_move },       // 100
	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move },       // 110
	{ ai_move,    -1.7 },
	{ ai_move,    -1.6 },
	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move,    0,      insane_fist },
	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move },       // 120
	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move },       // 130
	{ ai_move },
	{ ai_move },
	{ ai_move,    0,      insane_moan },
	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move },       // 140
	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move },       // 150
	{ ai_move,    0.5 },
	{ ai_move },
	{ ai_move,    -0.2,       insane_scream },
	{ ai_move,    0 },
	{ ai_move,    0.2 },
	{ ai_move,    0.4 },
	{ ai_move,    0.6 },
	{ ai_move,    0.8 },
	{ ai_move,    0.7 },
	{ ai_move,    0,      insane_checkup }      // 160
};
static var mmove_t insane_move_down = { FRAME_stand100, FRAME_stand160 };

static mframe_t insane_frames_walk_normal [] = {
	{ ai_walk,    0,      insane_scream },
	{ ai_walk,    2.5 },
	{ ai_walk,    3.5 },
	{ ai_walk,    1.7 },
	{ ai_walk,    2.3 },
	{ ai_walk,    2.4 },
	{ ai_walk,    2.2 },
	{ ai_walk,    4.2 },
	{ ai_walk,    5.6 },
	{ ai_walk,    3.3 },
	{ ai_walk,    2.4 },
	{ ai_walk,    0.9 },
	{ ai_walk }
};
static var mmove_t insane_move_walk_normal = { FRAME_walk27, FRAME_walk39 };
static var mmove_t insane_move_run_normal = { FRAME_walk27, FRAME_walk39 };

static mframe_t insane_frames_walk_insane [] = {
	{ ai_walk,    0,      insane_scream },      // walk 1
	{ ai_walk,    3.4 },       // walk 2
	{ ai_walk,    3.6 },       // 3
	{ ai_walk,    2.9 },       // 4
	{ ai_walk,    2.2 },       // 5
	{ ai_walk,    2.6 },       // 6
	{ ai_walk },       // 7
	{ ai_walk,    0.7 },       // 8
	{ ai_walk,    4.8 },       // 9
	{ ai_walk,    5.3 },       // 10
	{ ai_walk,    1.1 },       // 11
	{ ai_walk,    2 },       // 12
	{ ai_walk,    0.5 },       // 13
	{ ai_walk },       // 14
	{ ai_walk },       // 15
	{ ai_walk,    4.9 },       // 16
	{ ai_walk,    6.7 },       // 17
	{ ai_walk,    3.8 },       // 18
	{ ai_walk,    2 },       // 19
	{ ai_walk,    0.2 },       // 20
	{ ai_walk },       // 21
	{ ai_walk,    3.4 },       // 22
	{ ai_walk,    6.4 },       // 23
	{ ai_walk,    5 },       // 24
	{ ai_walk,    1.8 },       // 25
	{ ai_walk }        // 26
};
static var mmove_t insane_move_walk_insane = { FRAME_walk1, FRAME_walk26 };
static var mmove_t insane_move_run_insane = { FRAME_walk1, FRAME_walk26 };

static mframe_t insane_frames_stand_pain [] = {
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
static var mmove_t insane_move_stand_pain = { FRAME_st_pain2, FRAME_st_pain12 };

static mframe_t insane_frames_stand_death [] = {
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
static var mmove_t insane_move_stand_death = { FRAME_st_death2, FRAME_st_death18 };

static mframe_t insane_frames_crawl [] = {
	{ ai_walk,    0,      insane_scream },
	{ ai_walk,    1.5 },
	{ ai_walk,    2.1 },
	{ ai_walk,    3.6 },
	{ ai_walk,    2 },
	{ ai_walk,    0.9 },
	{ ai_walk,    3 },
	{ ai_walk,    3.4 },
	{ ai_walk,    2.4 }
};
static var mmove_t insane_move_crawl = { FRAME_crawl1, FRAME_crawl9 };
static var mmove_t insane_move_runcrawl = { FRAME_crawl1, FRAME_crawl9 };

static mframe_t insane_frames_crawl_pain [] = {
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
static var mmove_t insane_move_crawl_pain = { FRAME_cr_pain2, FRAME_cr_pain10 };

static mframe_t insane_frames_crawl_death [] = {
	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move }
};
static var mmove_t insane_move_crawl_death = { FRAME_cr_death10, FRAME_cr_death16 };

static mframe_t insane_frames_cross [] = {
	{ ai_move,    0,      insane_moan },
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
static var mmove_t insane_move_cross = { FRAME_cross1, FRAME_cross15 };

static mframe_t insane_frames_struggle_cross [] = {
	{ ai_move,    0,      insane_scream },
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
static var mmove_t insane_move_struggle_cross = { FRAME_cross16, FRAME_cross30 };

static void insane_cross(entity self)
{
	if (random() < 0.8f)
		self.monsterinfo.currentmove = &insane_move_cross;
	else
		self.monsterinfo.currentmove = &insane_move_struggle_cross;
}

static void insane_walk(entity self)
{
	if (self.spawnflags & 16)              // Hold Ground?
		if (self.s.frame == FRAME_cr_pain10) {
			self.monsterinfo.currentmove = &insane_move_down;
			return;
		}
	if (self.spawnflags & 4)
		self.monsterinfo.currentmove = &insane_move_crawl;
	else if (random() <= 0.5f)
		self.monsterinfo.currentmove = &insane_move_walk_normal;
	else
		self.monsterinfo.currentmove = &insane_move_walk_insane;
}

static void insane_run(entity self)
{
	if (self.spawnflags & 16)              // Hold Ground?
		if (self.s.frame == FRAME_cr_pain10) {
			self.monsterinfo.currentmove = &insane_move_down;
			return;
		}
	if (self.spawnflags & 4)               // Crawling?
		self.monsterinfo.currentmove = &insane_move_runcrawl;
	else if (random() <= 0.5f)              // Else, mix it up
		self.monsterinfo.currentmove = &insane_move_run_normal;
	else
		self.monsterinfo.currentmove = &insane_move_run_insane;
}


static void insane_pain(entity self, entity other, float kick, int damage)
{
	int l, r;

//  if (self.health < (self.max_health / 2))
//      self.s.skinnum = 1;

	if (level.framenum < self.pain_debounce_framenum)
		return;

	self.pain_debounce_framenum = level.framenum + 3 * BASE_FRAMERATE;

	r = 1 + (Q_rand() & 1);
	if (self.health < 25)
		l = 25;
	else if (self.health < 50)
		l = 50;
	else if (self.health < 75)
		l = 75;
	else
		l = 100;
	gi.sound(self, CHAN_VOICE, gi.soundindex(va("player/male/pain%i_%i.wav", l, r)), 1, ATTN_IDLE, 0);

	if (skill.intVal == 3)
		return;     // no pain anims in nightmare

	// Don't go into pain frames if crucified.
	if (self.spawnflags & 8) {
		self.monsterinfo.currentmove = &insane_move_struggle_cross;
		return;
	}

	if (((self.s.frame >= FRAME_crawl1) && (self.s.frame <= FRAME_crawl9)) || ((self.s.frame >= FRAME_stand99) && (self.s.frame <= FRAME_stand160))) {
		self.monsterinfo.currentmove = &insane_move_crawl_pain;
	} else
		self.monsterinfo.currentmove = &insane_move_stand_pain;

}

static void insane_onground(entity self)
{
	self.monsterinfo.currentmove = &insane_move_down;
}

static void insane_stand(entity self)
{
	if (self.spawnflags & 8) {         // If crucified
		self.monsterinfo.currentmove = &insane_move_cross;
		self.monsterinfo.aiflags |= AI_STAND_GROUND;
	}
	// If Hold_Ground and Crawl are set
	else if ((self.spawnflags & 4) && (self.spawnflags & 16))
		self.monsterinfo.currentmove = &insane_move_down;
	else if (random() < 0.5f)
		self.monsterinfo.currentmove = &insane_move_stand_normal;
	else
		self.monsterinfo.currentmove = &insane_move_stand_insane;
}

static void insane_dead(entity self)
{
	if (self.spawnflags & 8) {
		self.flags |= FL_FLY;
	} else {
		self.mins = '-16 -16 -24';
		self.maxs = '16 16 -8';
		self.movetype = MOVETYPE_TOSS;
	}
	self.svflags |= SVF_DEADMONSTER;
	self.nextthink = 0;
	gi.linkentity(self);
}

static void insane_die(entity self, entity inflictor, entity attacker, int damage, vector point)
{
	int     n;

	if (self.health <= self.gib_health) {
		gi.sound(self, CHAN_VOICE, gi.soundindex("misc/udeath.wav"), 1, ATTN_IDLE, 0);
		for (n = 0; n < 2; n++)
			ThrowGib(self, "models/objects/gibs/bone/tris.md2", damage, GIB_ORGANIC);
		for (n = 0; n < 4; n++)
			ThrowGib(self, "models/objects/gibs/sm_meat/tris.md2", damage, GIB_ORGANIC);
		ThrowHead(self, "models/objects/gibs/head2/tris.md2", damage, GIB_ORGANIC);
		self.deadflag = DEAD_DEAD;
		return;
	}

	if (self.deadflag == DEAD_DEAD)
		return;

	gi.sound(self, CHAN_VOICE, gi.soundindex(va("player/male/death%i.wav", (Q_rand() % 4) + 1)), 1, ATTN_IDLE, 0);

	self.deadflag = DEAD_DEAD;
	self.takedamage = DAMAGE_YES;

	if (self.spawnflags & 8) {
		insane_dead(self);
	} else {
		if (((self.s.frame >= FRAME_crawl1) && (self.s.frame <= FRAME_crawl9)) || ((self.s.frame >= FRAME_stand99) && (self.s.frame <= FRAME_stand160)))
			self.monsterinfo.currentmove = &insane_move_crawl_death;
		else
			self.monsterinfo.currentmove = &insane_move_stand_death;
	}
}


/*QUAKED misc_insane (1 .5 0) (-16 -16 -24) (16 16 32) Ambush Trigger_Spawn CRAWL CRUCIFIED STAND_GROUND ALWAYS_STAND
*/
API_FUNC static void SP_misc_insane(entity self)
{
//  static int skin = 0;    //@@

	if (deathmatch.intVal) {
		G_FreeEdict(self);
		return;
	}
	
	if (!insane_move_uptodown.frame)
	{
		insane_move_uptodown.frame = &insane_frames_uptodown;
		insane_move_uptodown.endfunc = insane_onground;

		insane_move_downtoup.frame = &insane_frames_downtoup;
		insane_move_downtoup.endfunc = insane_stand;

		insane_move_stand_normal.frame = &insane_frames_stand_normal;
		insane_move_stand_normal.endfunc = insane_stand;

		insane_move_stand_insane.frame = &insane_frames_stand_insane;
		insane_move_stand_insane.endfunc = insane_stand;

		insane_move_jumpdown.frame = &insane_frames_jumpdown;
		insane_move_jumpdown.endfunc = insane_onground;

		insane_move_down.frame = &insane_frames_down;
		insane_move_down.endfunc = insane_onground;

		insane_move_walk_normal.frame = &insane_frames_walk_normal;
		insane_move_walk_normal.endfunc = insane_walk;
		insane_move_run_normal.frame = &insane_frames_walk_normal;
		insane_move_run_normal.endfunc = insane_run;

		insane_move_walk_insane.frame = &insane_frames_walk_insane;
		insane_move_walk_insane.endfunc = insane_walk;
		insane_move_run_insane.frame = &insane_frames_walk_insane;
		insane_move_run_insane.endfunc = insane_run;

		insane_move_stand_pain.frame = &insane_frames_stand_pain;
		insane_move_stand_pain.endfunc = insane_run;

		insane_move_stand_death.frame = &insane_frames_stand_death;
		insane_move_stand_death.endfunc = insane_dead;

		insane_move_crawl.frame = &insane_frames_crawl;
		insane_move_runcrawl.frame = &insane_frames_crawl;

		insane_move_crawl_pain.frame = &insane_frames_crawl_pain;
		insane_move_crawl_pain.endfunc = insane_run;

		insane_move_crawl_death.frame = &insane_frames_crawl_death;
		insane_move_crawl_death.endfunc = insane_dead;

		insane_move_cross.frame = &insane_frames_cross;
		insane_move_cross.endfunc = insane_cross;

		insane_move_struggle_cross.frame = &insane_frames_struggle_cross;
		insane_move_struggle_cross.endfunc = insane_cross;
	}

	sound_fist = gi.soundindex("insane/insane11.wav");
	sound_shake = gi.soundindex("insane/insane5.wav");
	sound_moan = gi.soundindex("insane/insane7.wav");
	sound_scream[0] = gi.soundindex("insane/insane1.wav");
	sound_scream[1] = gi.soundindex("insane/insane2.wav");
	sound_scream[2] = gi.soundindex("insane/insane3.wav");
	sound_scream[3] = gi.soundindex("insane/insane4.wav");
	sound_scream[4] = gi.soundindex("insane/insane6.wav");
	sound_scream[5] = gi.soundindex("insane/insane8.wav");
	sound_scream[6] = gi.soundindex("insane/insane9.wav");
	sound_scream[7] = gi.soundindex("insane/insane10.wav");

	self.movetype = MOVETYPE_STEP;
	self.solid = SOLID_BBOX;
	self.s.modelindex = gi.modelindex("models/monsters/insane/tris.md2");

	self.mins = '-16 -16 -24';
	self.maxs = '16 16 32';

	self.health = 100;
	self.gib_health = -50;
	self.mass = 300;

	self.pain = insane_pain;
	self.die = insane_die;

	self.monsterinfo.stand = insane_stand;
	self.monsterinfo.walk = insane_walk;
	self.monsterinfo.run = insane_run;
	self.monsterinfo.dodge = 0;
	self.monsterinfo.attack = 0;
	self.monsterinfo.melee = 0;
	self.monsterinfo.sight = 0;
	self.monsterinfo.aiflags |= AI_GOOD_GUY;

//@@
//  self.s.skinnum = skin;
//  skin++;
//  if (skin > 12)
//      skin = 0;

	gi.linkentity(self);

	if (self.spawnflags & 16)              // Stand Ground
		self.monsterinfo.aiflags |= AI_STAND_GROUND;

	self.monsterinfo.currentmove = &insane_move_stand_normal;

	self.monsterinfo.scale = MODEL_SCALE;

	if (self.spawnflags & 8) {                 // Crucified ?
		self.mins = '-16 0 0';
		self.maxs = '16 8 32';
		self.flags |= FL_NO_KNOCKBACK;
		flymonster_start(self);
	} else {
		walkmonster_start(self);
		self.s.skinnum = Q_rand() % 3;
	}
}
