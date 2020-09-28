#ifdef SINGLE_PLAYER
#include "m_boss32.h"

static int  sound_pain4;
static int  sound_pain5;
static int  sound_pain6;
static int  sound_death;
static int  sound_step_left;
static int  sound_step_right;
static int  sound_attack_bfg;
static int  sound_brainsplorch;
static int  sound_prerailgun;
static int  sound_popup;
static int  sound_taunt1;
static int  sound_taunt2;
static int  sound_taunt3;
static int  sound_hit;

static void makron_taunt(entity self)
{
	float r;

	r = random();
	if (r <= 0.3f)
		gi.sound(self, CHAN_AUTO, sound_taunt1, 1, ATTN_NONE, 0);
	else if (r <= 0.6f)
		gi.sound(self, CHAN_AUTO, sound_taunt2, 1, ATTN_NONE, 0);
	else
		gi.sound(self, CHAN_AUTO, sound_taunt3, 1, ATTN_NONE, 0);
}

//
// stand
//

static mframe_t makron_frames_stand [] = {
	{ ai_stand },
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
	{ ai_stand },
	{ ai_stand },
	{ ai_stand },
	{ ai_stand },
	{ ai_stand },
	{ ai_stand },
	{ ai_stand },      // 40
	{ ai_stand },
	{ ai_stand },
	{ ai_stand },
	{ ai_stand },
	{ ai_stand },
	{ ai_stand },
	{ ai_stand },
	{ ai_stand },
	{ ai_stand },
	{ ai_stand },      // 50
	{ ai_stand },
	{ ai_stand },
	{ ai_stand },
	{ ai_stand },
	{ ai_stand },
	{ ai_stand },
	{ ai_stand },
	{ ai_stand },
	{ ai_stand },
	{ ai_stand }       // 60
};
static var mmove_t makron_move_stand = { FRAME_stand201, FRAME_stand260 };

static void makron_stand(entity self)
{
	self.monsterinfo.currentmove = &makron_move_stand;
}

static void makron_step_left(entity self)
{
	gi.sound(self, CHAN_BODY, sound_step_left, 1, ATTN_NORM, 0);
}

static void makron_step_right(entity self)
{
	gi.sound(self, CHAN_BODY, sound_step_right, 1, ATTN_NORM, 0);
}

static mframe_t makron_frames_run [] = {
	{ ai_run, 3,  makron_step_left },
	{ ai_run, 12 },
	{ ai_run, 8 },
	{ ai_run, 8 },
	{ ai_run, 8,  makron_step_right },
	{ ai_run, 6 },
	{ ai_run, 12 },
	{ ai_run, 9 },
	{ ai_run, 6 },
	{ ai_run, 12 }
};
static var mmove_t makron_move_run = { FRAME_walk204, FRAME_walk213 };

static void makron_hit(entity self)
{
	gi.sound(self, CHAN_AUTO, sound_hit, 1, ATTN_NONE, 0);
}

static void makron_popup(entity self)
{
	gi.sound(self, CHAN_BODY, sound_popup, 1, ATTN_NONE, 0);
}

void makron_brainsplorch(entity self)
{
	gi.sound(self, CHAN_VOICE, sound_brainsplorch, 1, ATTN_NORM, 0);
}

static void makron_prerailgun(entity self)
{
	gi.sound(self, CHAN_WEAPON, sound_prerailgun, 1, ATTN_NORM, 0);
}


static mframe_t makron_frames_walk [] = {
	{ ai_walk, 3, makron_step_left },
	{ ai_walk, 12 },
	{ ai_walk, 8 },
	{ ai_walk, 8 },
	{ ai_walk, 8, makron_step_right },
	{ ai_walk, 6 },
	{ ai_walk, 12 },
	{ ai_walk, 9 },
	{ ai_walk, 6 },
	{ ai_walk, 12 }
};
static var mmove_t makron_move_walk = { FRAME_walk204, FRAME_walk213 };

static void makron_walk(entity self)
{
	self.monsterinfo.currentmove = &makron_move_walk;
}

static void makron_run(entity self)
{
	if (self.monsterinfo.aiflags & AI_STAND_GROUND)
		self.monsterinfo.currentmove = &makron_move_stand;
	else
		self.monsterinfo.currentmove = &makron_move_run;
}

static mframe_t makron_frames_pain6 [] = {
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
	{ ai_move,    0,  makron_popup },
	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move },       // 20
	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move,    0,  makron_taunt },
	{ ai_move },
	{ ai_move },
	{ ai_move }
};
static var mmove_t makron_move_pain6 = { FRAME_pain601, FRAME_pain627, makron_run };

static mframe_t makron_frames_pain5 [] = {
	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move }
};
static var mmove_t makron_move_pain5 = { FRAME_pain501, FRAME_pain504, makron_run };

static mframe_t makron_frames_pain4 [] = {
	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move }
};
static var mmove_t makron_move_pain4 = { FRAME_pain401, FRAME_pain404, makron_run };

static void makron_dead(entity self)
{
	self.mins = '-60 -60 0';
	self.maxs = '60 60 72';
	self.movetype = MOVETYPE_TOSS;
	self.svflags |= SVF_DEADMONSTER;
	self.nextthink = 0;
	gi.linkentity(self);
}

static mframe_t makron_frames_death2 [] = {
	{ ai_move,    -15 },
	{ ai_move,    3 },
	{ ai_move,    -12 },
	{ ai_move,    0,  makron_step_left },
	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move },           // 10
	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move,    11 },
	{ ai_move,    12 },
	{ ai_move,    11, makron_step_right },
	{ ai_move },
	{ ai_move },           // 20
	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move },           // 30
	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move,    5 },
	{ ai_move,    7 },
	{ ai_move,    6,  makron_step_left },
	{ ai_move },
	{ ai_move },
	{ ai_move,    -1 },
	{ ai_move,    2 },           // 40
	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move },           // 50
	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move,    -6 },
	{ ai_move,    -4 },
	{ ai_move,    -6, makron_step_right },
	{ ai_move,    -4 },
	{ ai_move,    -4, makron_step_left },
	{ ai_move },
	{ ai_move },           // 60
	{ ai_move },
	{ ai_move },
	{ ai_move,    -2 },
	{ ai_move,    -5 },
	{ ai_move,    -3, makron_step_right },
	{ ai_move,    -8 },
	{ ai_move,    -3, makron_step_left },
	{ ai_move,    -7 },
	{ ai_move,    -4 },
	{ ai_move,    -4, makron_step_right },          // 70
	{ ai_move,    -6 },
	{ ai_move,    -7 },
	{ ai_move,    0,  makron_step_left },
	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move },           // 80
	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move,    -2 },
	{ ai_move },
	{ ai_move },
	{ ai_move,    2 },
	{ ai_move },           // 90
	{ ai_move,    27, makron_hit },
	{ ai_move,    26 },
	{ ai_move,    0,  makron_brainsplorch },
	{ ai_move },
	{ ai_move }            // 95
};
static var mmove_t makron_move_death2 = { FRAME_death201, FRAME_death295, makron_dead };

static mframe_t makron_frames_death3 [] = {
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
static var mmove_t makron_move_death3 = { FRAME_death301, FRAME_death320 };

static mframe_t makron_frames_sight [] = {
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
static var mmove_t makron_move_sight = { FRAME_active01, FRAME_active13, makron_run };

static void makronBFG(entity self)
{
	vector  forward, right;
	vector  start;
	vector  dir;
	vector  vec;

	AngleVectors(self.s.angles, &forward, &right, 0);
	start = G_ProjectSource(self.s.origin, monster_flash_offset[MZ2_MAKRON_BFG], forward, right);

	vec = self.enemy.s.origin;
	vec[2] += self.enemy.viewheight;
	dir = vec - start;
	VectorNormalize(dir);
	gi.sound(self, CHAN_VOICE, sound_attack_bfg, 1, ATTN_NORM, 0);
	monster_fire_bfg(self, start, dir, 50, 300, 100, 300, MZ2_MAKRON_BFG);
}


static mframe_t makron_frames_attack3 [] = {
	{ ai_charge },
	{ ai_charge },
	{ ai_charge },
	{ ai_charge,  0,  makronBFG },      // FIXME: BFG Attack here
	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move }
};
static var mmove_t makron_move_attack3 = { FRAME_attak301, FRAME_attak308, makron_run };

// FIXME: This is all wrong. He's not firing at the proper angles.
static void MakronHyperblaster(entity self)
{
	vector  dir;
	vector  vec;
	vector  start;
	vector  forward, right;
	int     flash_number;

	flash_number = MZ2_MAKRON_BLASTER_1 + (self.s.frame - FRAME_attak405);

	AngleVectors(self.s.angles, &forward, &right, 0);
	start = G_ProjectSource(self.s.origin, monster_flash_offset[flash_number], forward, right);

	if (self.enemy) {
		vec = self.enemy.s.origin;
		vec[2] += self.enemy.viewheight;
		vec -= start;
		vec = vectoangles(vec);
		dir[0] = vec[0];
	} else {
		dir[0] = 0;
	}
	if (self.s.frame <= FRAME_attak413)
		dir[1] = self.s.angles[1] - 10 * (self.s.frame - FRAME_attak413);
	else
		dir[1] = self.s.angles[1] + 10 * (self.s.frame - FRAME_attak421);
	dir[2] = 0;

	AngleVectors(dir, &forward, 0, 0);

	monster_fire_blaster(self, start, forward, 15, 1000, MZ2_MAKRON_BLASTER_1, EF_BLASTER);
}

static mframe_t makron_frames_attack4[] = {
	{ ai_charge },
	{ ai_charge },
	{ ai_charge },
	{ ai_charge },
	{ ai_move,    0,  MakronHyperblaster },     // fire
	{ ai_move,    0,  MakronHyperblaster },     // fire
	{ ai_move,    0,  MakronHyperblaster },     // fire
	{ ai_move,    0,  MakronHyperblaster },     // fire
	{ ai_move,    0,  MakronHyperblaster },     // fire
	{ ai_move,    0,  MakronHyperblaster },     // fire
	{ ai_move,    0,  MakronHyperblaster },     // fire
	{ ai_move,    0,  MakronHyperblaster },     // fire
	{ ai_move,    0,  MakronHyperblaster },     // fire
	{ ai_move,    0,  MakronHyperblaster },     // fire
	{ ai_move,    0,  MakronHyperblaster },     // fire
	{ ai_move,    0,  MakronHyperblaster },     // fire
	{ ai_move,    0,  MakronHyperblaster },     // fire
	{ ai_move,    0,  MakronHyperblaster },     // fire
	{ ai_move,    0,  MakronHyperblaster },     // fire
	{ ai_move,    0,  MakronHyperblaster },     // fire
	{ ai_move,    0,  MakronHyperblaster },     // fire
	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move }
};
static var mmove_t makron_move_attack4 = { FRAME_attak401, FRAME_attak426, makron_run };

static void MakronSaveloc(entity self)
{
	self.pos1 = self.enemy.s.origin;  //save for aiming the shot
	self.pos1[2] += self.enemy.viewheight;
}

static void MakronRailgun(entity self)
{
	vector  start;
	vector  dir;
	vector  forward, right;

	AngleVectors(self.s.angles, &forward, &right, 0);
	start = G_ProjectSource(self.s.origin, monster_flash_offset[MZ2_MAKRON_RAILGUN_1], forward, right);

	// calc direction to where we targted
	dir = self.pos1 - start;
	VectorNormalize(dir);

	monster_fire_railgun(self, start, dir, 50, 100, MZ2_MAKRON_RAILGUN_1);
}

static mframe_t makron_frames_attack5[] = {
	{ ai_charge,  0,  makron_prerailgun },
	{ ai_charge },
	{ ai_charge },
	{ ai_charge },
	{ ai_charge },
	{ ai_charge },
	{ ai_charge },
	{ ai_charge,  0,  MakronSaveloc },
	{ ai_move,    0,  MakronRailgun },      // Fire railgun
	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move }
};
static var mmove_t makron_move_attack5 = { FRAME_attak501, FRAME_attak516, makron_run };

static void makron_pain(entity self, entity other, float kick, int damage)
{

	if (self.health < (self.max_health / 2))
		self.s.skinnum = 1;

	if (level.framenum < self.pain_debounce_framenum)
		return;

	// Lessen the chance of him going into his pain frames
	if (damage <= 25)
		if (random() < 0.2f)
			return;

	self.pain_debounce_framenum = level.framenum + 3 * BASE_FRAMERATE;
	if (skill.intVal == 3)
		return;     // no pain anims in nightmare


	if (damage <= 40) {
		gi.sound(self, CHAN_VOICE, sound_pain4, 1, ATTN_NONE, 0);
		self.monsterinfo.currentmove = &makron_move_pain4;
	} else if (damage <= 110) {
		gi.sound(self, CHAN_VOICE, sound_pain5, 1, ATTN_NONE, 0);
		self.monsterinfo.currentmove = &makron_move_pain5;
	} else {
		if (damage <= 150) {
			if (random() <= 0.45f) {
				gi.sound(self, CHAN_VOICE, sound_pain6, 1, ATTN_NONE, 0);
				self.monsterinfo.currentmove = &makron_move_pain6;
			}
		} else {
			if (random() <= 0.35f) {
				gi.sound(self, CHAN_VOICE, sound_pain6, 1, ATTN_NONE, 0);
				self.monsterinfo.currentmove = &makron_move_pain6;
			}
		}
	}
}

static void makron_sight(entity self, entity other)
{
	self.monsterinfo.currentmove = &makron_move_sight;
}

static void makron_attack(entity self)
{
	float   r;

	r = random();

	if (r <= 0.3f)
		self.monsterinfo.currentmove = &makron_move_attack3;
	else if (r <= 0.6f)
		self.monsterinfo.currentmove = &makron_move_attack4;
	else
		self.monsterinfo.currentmove = &makron_move_attack5;
}

/*
---
Makron Torso. This needs to be spawned in
---
*/

static void makron_torso_think(entity self)
{
	if (++self.s.frame < 365)
		self.nextthink = level.framenum + 1;
	else {
		self.s.frame = 346;
		self.nextthink = level.framenum + 1;
	}
}

static void makron_torso(entity ent)
{
	ent.movetype = MOVETYPE_NONE;
	ent.solid = SOLID_NOT;
	ent.mins = '-8 -8 0';
	ent.maxs = '8 8 8';
	ent.s.frame = 346;
	ent.s.modelindex = gi.modelindex("models/monsters/boss3/rider/tris.md2");
	ent.think = makron_torso_think;
	ent.nextthink = level.framenum + 2;
	ent.s.sound = gi.soundindex("makron/spine.wav");
	gi.linkentity(ent);
}


//
// death
//


static void makron_die(entity self, entity inflictor, entity attacker, int damage, vector point)
{
	entity tempent;

	int     n;

	self.s.sound = 0;
	// check for gib
	if (self.health <= self.gib_health) {
		gi.sound(self, CHAN_VOICE, gi.soundindex("misc/udeath.wav"), 1, ATTN_NORM, 0);
		for (n = 0; n < 1 /*4*/; n++)
			ThrowGib(self, "models/objects/gibs/sm_meat/tris.md2", damage, GIB_ORGANIC);
		for (n = 0; n < 4; n++)
			ThrowGib(self, "models/objects/gibs/sm_metal/tris.md2", damage, GIB_METALLIC);
		ThrowHead(self, "models/objects/gibs/gear/tris.md2", damage, GIB_METALLIC);
		self.deadflag = DEAD_DEAD;
		return;
	}

	if (self.deadflag == DEAD_DEAD)
		return;

// regular death
	gi.sound(self, CHAN_VOICE, sound_death, 1, ATTN_NONE, 0);
	self.deadflag = DEAD_DEAD;
	self.takedamage = true;

	tempent = G_Spawn();
	tempent.s.origin = self.s.origin;
	tempent.s.angles = self.s.angles;
	tempent.s.origin[1] -= 84;
	makron_torso(tempent);

	self.monsterinfo.currentmove = &makron_move_death2;

}

static bool Makron_CheckAttack(entity self)
{
	vector  spot1, spot2;
	vector  temp;
	float   chance;
	trace_t tr;
	int         enemy_range;
	float       enemy_yaw;

	if (self.enemy.health > 0) {
		// see if any entities are in the way of the shot
		spot1 = self.s.origin;
		spot1[2] += self.viewheight;
		spot2 = self.enemy.s.origin;
		spot2[2] += self.enemy.viewheight;

		gi.traceline(&tr, spot1, spot2, self, CONTENTS_SOLID | CONTENTS_MONSTER | CONTENTS_SLIME | CONTENTS_LAVA);

		// do we have a clear shot?
		if (tr.ent != self.enemy)
			return false;
	}

	enemy_range = range(self, self.enemy);
	temp = self.enemy.s.origin - self.s.origin;
	enemy_yaw = vectoyaw(temp);

	self.ideal_yaw = enemy_yaw;

	// melee attack
	if (enemy_range == RANGE_MELEE) {
		if (self.monsterinfo.melee)
			self.monsterinfo.attack_state = AS_MELEE;
		else
			self.monsterinfo.attack_state = AS_MISSILE;
		return true;
	}

// missile attack
	if (!self.monsterinfo.attack)
		return false;

	if (level.framenum < self.monsterinfo.attack_finished)
		return false;

	if (enemy_range == RANGE_FAR)
		return false;

	if (self.monsterinfo.aiflags & AI_STAND_GROUND) {
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
		self.monsterinfo.attack_state = AS_MISSILE;
		self.monsterinfo.attack_finished = level.framenum + (int)random(2f * BASE_FRAMERATE);
		return true;
	}

	if (self.flags & FL_FLY) {
		if (random() < 0.3f)
			self.monsterinfo.attack_state = AS_SLIDING;
		else
			self.monsterinfo.attack_state = AS_STRAIGHT;
	}

	return false;
}


//
// monster_makron
//

void MakronPrecache(void)
{
	sound_pain4 = gi.soundindex("makron/pain3.wav");
	sound_pain5 = gi.soundindex("makron/pain2.wav");
	sound_pain6 = gi.soundindex("makron/pain1.wav");
	sound_death = gi.soundindex("makron/death.wav");
	sound_step_left = gi.soundindex("makron/step1.wav");
	sound_step_right = gi.soundindex("makron/step2.wav");
	sound_attack_bfg = gi.soundindex("makron/bfg_fire.wav");
	sound_brainsplorch = gi.soundindex("makron/brain1.wav");
	sound_prerailgun = gi.soundindex("makron/rail_up.wav");
	sound_popup = gi.soundindex("makron/popup.wav");
	sound_taunt1 = gi.soundindex("makron/voice4.wav");
	sound_taunt2 = gi.soundindex("makron/voice3.wav");
	sound_taunt3 = gi.soundindex("makron/voice.wav");
	sound_hit = gi.soundindex("makron/bhit.wav");

	gi.modelindex("models/monsters/boss3/rider/tris.md2");
}

/*QUAKED monster_makron (1 .5 0) (-30 -30 0) (30 30 90) Ambush Trigger_Spawn Sight
*/
API_FUNC void SP_monster_makron(entity self)
{
	if (deathmatch.intVal) {
		G_FreeEdict(self);
		return;
	}
	
	if (!makron_move_stand.frame)
	{
		makron_move_stand.frame = &makron_frames_stand;
		makron_move_run.frame = &makron_frames_run;
		makron_move_walk.frame = &makron_frames_run;
		makron_move_pain6.frame = &makron_frames_pain6;
		makron_move_pain5.frame = &makron_frames_pain5;
		makron_move_pain4.frame = &makron_frames_pain4;
		makron_move_death2.frame = &makron_frames_death2;
		makron_move_death3.frame = &makron_frames_death3;
		makron_move_sight.frame = &makron_frames_sight;
		makron_move_attack3.frame = &makron_frames_attack3;
		makron_move_attack4.frame = &makron_frames_attack4;
		makron_move_attack5.frame = &makron_frames_attack5;
	}

	MakronPrecache();

	self.movetype = MOVETYPE_STEP;
	self.solid = SOLID_BBOX;
	self.s.modelindex = gi.modelindex("models/monsters/boss3/rider/tris.md2");
	self.mins = '-30 -30 0';
	self.maxs = '30 30 90';

	self.health = 3000;
	self.gib_health = -2000;
	self.mass = 500;

	self.pain = makron_pain;
	self.die = makron_die;
	self.monsterinfo.stand = makron_stand;
	self.monsterinfo.walk = makron_walk;
	self.monsterinfo.run = makron_run;
	self.monsterinfo.dodge = 0;
	self.monsterinfo.attack = makron_attack;
	self.monsterinfo.melee = 0;
	self.monsterinfo.sight = makron_sight;
	self.monsterinfo.checkattack = Makron_CheckAttack;

	gi.linkentity(self);

	self.monsterinfo.currentmove = &makron_move_sight;
	self.monsterinfo.scale = MODEL_SCALE;

	walkmonster_start(self);

#ifdef GROUND_ZERO
	self.monsterinfo.aiflags |= AI_IGNORE_SHOTS;
#endif
}


/*
=================
MakronSpawn

=================
*/
void MakronSpawn(entity self)
{
	vector	vec;
	entity	player;

	SP_monster_makron(self);

	// jump at player
	player = level.sight_client;
	if (!player)
		return;

	vec = player.s.origin - self.s.origin;
	self.s.angles[YAW] = vectoyaw(vec);
	VectorNormalize(vec);
	self.velocity = vec * 400;
	self.velocity[2] = 200f;
	self.groundentity = null_entity;
}

/*
=================
MakronToss

Jorg is just about dead, so set up to launch Makron out
=================
*/
void MakronToss(entity self)
{
	entity ent;

	ent = G_Spawn();
	ent.nextthink = level.framenum + (int)(0.8f * BASE_FRAMERATE);
	ent.think = MakronSpawn;
	ent.target = self.target;
	ent.s.origin = self.s.origin;
}
#endif