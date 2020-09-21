#include "m_hover.h"

static int  sound_pain1;
static int  sound_pain2;
static int  sound_death1;
static int  sound_death2;
static int  sound_sight;
static int  sound_search1;
static int  sound_search2;

#ifdef GROUND_ZERO
static int	daed_sound_pain1;
static int	daed_sound_pain2;
static int	daed_sound_death1;
static int	daed_sound_death2;
static int	daed_sound_sight;
static int	daed_sound_search1;
static int	daed_sound_search2;
#endif

static void hover_sight(entity self, entity other)
{
#ifdef GROUND_ZERO
	if (self.mass >= 225)
		gi.sound (self, CHAN_VOICE, daed_sound_sight, 1, ATTN_NORM, 0);
	else
#endif
		gi.sound(self, CHAN_VOICE, sound_sight, 1, ATTN_NORM, 0);
}

static void hover_search(entity self)
{
#ifdef GROUND_ZERO
	if (self.mass >= 225)
	{
		if (random() < 0.5f)
			gi.sound(self, CHAN_VOICE, daed_sound_search1, 1, ATTN_NORM, 0);
		else
			gi.sound(self, CHAN_VOICE, daed_sound_search2, 1, ATTN_NORM, 0);
	}
	else
#endif
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
#ifdef GROUND_ZERO
static void hover_attack2(entity self);
#endif

static void hover_reattack(entity self)
{
	if (self.enemy.health > 0)
		if (visible(self, self.enemy))
			if (random() <= 0.6f)
			{
#ifdef GROUND_ZERO
				if (self.monsterinfo.attack_state == AS_STRAIGHT)
				{
#endif
					hover_attack1(self);
					return;
#ifdef GROUND_ZERO
				}
				else if (self.monsterinfo.attack_state == AS_SLIDING)
				{
					hover_attack2(self);
					return;
				}
#endif
			}
	self.monsterinfo.currentmove = &hover_move_end_attack;
}

static void hover_fire_blaster(entity self)
{
	vector  start;
	vector  forward, right;
	vector  end;
	vector  dir;
	int     effect;

	if (self.s.frame == FRAME_attak104)
		effect = EF_HYPERBLASTER;
	else
		effect = 0;

	AngleVectors(self.s.angles, &forward, &right, 0);
	start = G_ProjectSource(self.s.origin, monster_flash_offset[MZ2_HOVER_BLASTER_1], forward, right);

	end = self.enemy.s.origin;
	end[2] += self.enemy.viewheight;
	dir = end - start;

#ifdef GROUND_ZERO
	if (self.mass >= 200)
		monster_fire_blaster2 (self, start, dir, 1, 1000, MZ2_DAEDALUS_BLASTER, EF_BLASTER);
	else
#endif
		monster_fire_blaster(self, start, dir, 1, 1000, MZ2_HOVER_BLASTER_1, effect);
}

#ifdef GROUND_ZERO
static mframe_t hover_frames_start_attack2 [] =
{
	{ ai_charge,	15 },
	{ ai_charge,	15 },
	{ ai_charge,	15 }
};
static var mmove_t hover_move_start_attack2 = { FRAME_attak101, FRAME_attak103 };

static mframe_t hover_frames_attack2 [] =
{
	{ ai_charge,	10,	hover_fire_blaster },
	{ ai_charge,	10,	hover_fire_blaster },
	{ ai_charge,	10,	hover_reattack },
};
static var mmove_t hover_move_attack2 = { FRAME_attak104, FRAME_attak106 };

static mframe_t hover_frames_end_attack2 [] =
{
	{ ai_charge,	15 },
	{ ai_charge,	15 }
};
static var mmove_t hover_move_end_attack2 = { FRAME_attak107, FRAME_attak108 };

static void hover_attack2(entity self)
{
	self.monsterinfo.currentmove = &hover_move_attack2;
}
#endif

static mframe_t hover_frames_attack1 [] = {
	{ ai_charge,  -10,    hover_fire_blaster },
	{ ai_charge,  -10,    hover_fire_blaster },
	{ ai_charge,  0,      hover_reattack },
};
static var mmove_t hover_move_attack1 = {FRAME_attak104, FRAME_attak106 };

static void hover_attack1(entity self)
{
	self.monsterinfo.currentmove = &hover_move_attack1;
}

static void hover_stand(entity self)
{
	self.monsterinfo.currentmove = &hover_move_stand;
}

static void hover_run(entity self)
{
	if (self.monsterinfo.aiflags & AI_STAND_GROUND)
		self.monsterinfo.currentmove = &hover_move_stand;
	else
		self.monsterinfo.currentmove = &hover_move_run;
}

static void hover_walk(entity self)
{
	self.monsterinfo.currentmove = &hover_move_walk;
}

static void hover_start_attack(entity self)
{
	self.monsterinfo.currentmove = &hover_move_start_attack;
}

static void hover_attack(entity self)
{
#ifdef GROUND_ZERO
	float chance = 0;

	if (skill.intVal)
		chance = 1.0 - (0.5 / skill.floatVal);

	if (self.mass > 150)  // the daedalus strafes more
		chance += 0.1;

	if (random() > chance)
	{
		self.monsterinfo.currentmove = &hover_move_attack1;
		self.monsterinfo.attack_state = AS_STRAIGHT;
	}
	else // circle strafe
	{
		if (random () <= 0.5) // switch directions
			self.monsterinfo.lefty = !self.monsterinfo.lefty;
		self.monsterinfo.currentmove = &hover_move_attack2;
		self.monsterinfo.attack_state = AS_SLIDING;
	}
#else
	self.monsterinfo.currentmove = &hover_move_attack1;
#endif
}


static void hover_pain(entity self, entity other, float kick, int damage)
{
	if (self.health < (self.max_health / 2))
		self.s.skinnum |= 1;

	if (level.framenum < self.pain_debounce_framenum)
		return;

	self.pain_debounce_framenum = level.framenum + 3 * BASE_FRAMERATE;

	if (skill.intVal == 3)
		return;     // no pain anims in nightmare

	if (damage <= 25) {
		if (random() < 0.5f)
		{
#ifdef GROUND_ZERO
			if (self.mass >= 225)
				gi.sound(self, CHAN_VOICE, daed_sound_pain1, 1, ATTN_NORM, 0);
			else
#endif
				gi.sound(self, CHAN_VOICE, sound_pain1, 1, ATTN_NORM, 0);
			self.monsterinfo.currentmove = &hover_move_pain3;
		}
		else
		{
#ifdef GROUND_ZERO
			if (self.mass >= 225)
				gi.sound(self, CHAN_VOICE, daed_sound_pain2, 1, ATTN_NORM, 0);
			else
#endif
				gi.sound(self, CHAN_VOICE, sound_pain2, 1, ATTN_NORM, 0);
			self.monsterinfo.currentmove = &hover_move_pain2;
		}
	} else {
#ifdef GROUND_ZERO
		if (random() < (0.45 - (0.1 * skill.floatVal)))
		{
			if (self.mass >= 225)
				gi.sound(self, CHAN_VOICE, daed_sound_pain1, 1, ATTN_NORM, 0);
			else
#endif
				gi.sound(self, CHAN_VOICE, sound_pain1, 1, ATTN_NORM, 0);
			self.monsterinfo.currentmove = &hover_move_pain1;
#ifdef GROUND_ZERO
		}
		else
		{
			// PMM - daedalus sounds
			if (self.mass >= 225)
				gi.sound (self, CHAN_VOICE, daed_sound_pain2, 1, ATTN_NORM, 0);
			else
				gi.sound (self, CHAN_VOICE, sound_pain2, 1, ATTN_NORM, 0);
			self.monsterinfo.currentmove = &hover_move_pain2;
		}
#endif
	}
}

static void hover_deadthink(entity self)
{
	if (self.groundentity == null_entity && level.framenum < self.timestamp) {
		self.nextthink = level.framenum + 1;
		return;
	}
	BecomeExplosion1(self);
}

static void hover_dead(entity self)
{
	self.mins = '-16 -16 -24';
	self.maxs = '16 16 -8';
	self.movetype = MOVETYPE_TOSS;
	self.think = hover_deadthink;
	self.nextthink = level.framenum + 1;
	self.timestamp = level.framenum + 15 * BASE_FRAMERATE;
	gi.linkentity(self);
}

static void hover_die(entity self, entity inflictor, entity attacker, int damage, vector point)
{
#ifdef GROUND_ZERO
	self.s.effects = 0;
	self.monsterinfo.power_armor_type = POWER_ARMOR_NONE;
#endif

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
#ifdef GROUND_ZERO
	if (self.mass > 225)
	{
		if (random() < 0.5)
			gi.sound (self, CHAN_VOICE, daed_sound_death1, 1, ATTN_NORM, 0);
		else
			gi.sound (self, CHAN_VOICE, daed_sound_death2, 1, ATTN_NORM, 0);
	}
	else
	{
#endif
		if (random() < 0.5f)
			gi.sound(self, CHAN_VOICE, sound_death1, 1, ATTN_NORM, 0);
		else
			gi.sound(self, CHAN_VOICE, sound_death2, 1, ATTN_NORM, 0);
#ifdef GROUND_ZERO
	}
#endif

	self.deadflag = DEAD_DEAD;
	self.takedamage = true;
	self.monsterinfo.currentmove = &hover_move_death1;
}

#ifdef GROUND_ZERO
static bool hover_blocked (entity self, float dist)
{
	return blocked_checkshot(self, 0.25 + (0.05 * skill.floatVal));
}
#endif

/*QUAKED monster_hover (1 .5 0) (-16 -16 -24) (16 16 32) Ambush Trigger_Spawn Sight
*/
API_FUNC static void SP_monster_hover(entity self)
{
	if (deathmatch.intVal)
	{
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

#ifdef GROUND_ZERO
		hover_move_start_attack2.frame = &hover_frames_start_attack2;
		hover_move_start_attack2.endfunc = hover_attack;
		hover_move_attack2.frame = &hover_frames_attack2;
		hover_move_end_attack2.frame = &hover_frames_end_attack2;
		hover_move_end_attack2.endfunc = hover_run;
#endif
	}

#ifdef GROUND_ZERO
	self.monsterinfo.blocked = hover_blocked;

	if (self.classname == "monster_daedalus")
	{
		self.health = 450;
		self.mass = 225;
		self.yaw_speed = 25f;

		self.monsterinfo.power_armor_type = POWER_ARMOR_SCREEN;
		self.monsterinfo.power_armor_power = 100;
		
		self.s.sound = gi.soundindex ("daedalus/daedidle1.wav");
		daed_sound_pain1 = gi.soundindex ("daedalus/daedpain1.wav");	
		daed_sound_pain2 = gi.soundindex ("daedalus/daedpain2.wav");	
		daed_sound_death1 = gi.soundindex ("daedalus/daeddeth1.wav");	
		daed_sound_death2 = gi.soundindex ("daedalus/daeddeth2.wav");	
		daed_sound_sight = gi.soundindex ("daedalus/daedsght1.wav");	
		daed_sound_search1 = gi.soundindex ("daedalus/daedsrch1.wav");	
		daed_sound_search2 = gi.soundindex ("daedalus/daedsrch2.wav");	
		gi.soundindex ("tank/tnkatck3.wav");
	}
	else
#endif
	{
		self.s.sound = gi.soundindex("hover/hovidle1.wav");
		sound_pain1 = gi.soundindex("hover/hovpain1.wav");
		sound_pain2 = gi.soundindex("hover/hovpain2.wav");
		sound_death1 = gi.soundindex("hover/hovdeth1.wav");
		sound_death2 = gi.soundindex("hover/hovdeth2.wav");
		sound_sight = gi.soundindex("hover/hovsght1.wav");
		sound_search1 = gi.soundindex("hover/hovsrch1.wav");
		sound_search2 = gi.soundindex("hover/hovsrch2.wav");
		gi.soundindex("hover/hovatck1.wav");
		
		self.health = 240;
		self.mass = 150;
	}

	self.movetype = MOVETYPE_STEP;
	self.solid = SOLID_BBOX;
	self.s.modelindex = gi.modelindex("models/monsters/hover/tris.md2");
	self.mins = '-24 -24 -24';
	self.maxs = '24 24 32';

	self.gib_health = -100;

	self.pain = hover_pain;
	self.die = hover_die;

	self.monsterinfo.stand = hover_stand;
	self.monsterinfo.walk = hover_walk;
	self.monsterinfo.run = hover_run;
//  self.monsterinfo.dodge = hover_dodge;
	self.monsterinfo.attack = hover_start_attack;
	self.monsterinfo.sight = hover_sight;
	self.monsterinfo.search = hover_search;

	gi.linkentity(self);

	self.monsterinfo.currentmove = &hover_move_stand;
	self.monsterinfo.scale = MODEL_SCALE;

	flymonster_start(self);
}

#ifdef GROUND_ZERO
API_FUNC static void SP_monster_daedalus(entity self)
{
	SP_monster_hover(self);
	self.s.skinnum = 2;
}
#endif