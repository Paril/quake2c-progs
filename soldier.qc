#include "m_soldier.h"


PROGS_LOCAL_STATIC int  sound_idle;
PROGS_LOCAL_STATIC int  sound_sight1;
PROGS_LOCAL_STATIC int  sound_sight2;
PROGS_LOCAL_STATIC int  sound_pain_light;
PROGS_LOCAL_STATIC int  sound_pain;
PROGS_LOCAL_STATIC int  sound_pain_ss;
PROGS_LOCAL_STATIC int  sound_death_light;
PROGS_LOCAL_STATIC int  sound_death;
PROGS_LOCAL_STATIC int  sound_death_ss;
PROGS_LOCAL_STATIC int  sound_cock;

#ifdef THE_RECKONING
PROGS_LOCAL_STATIC int	soldierh_modelindex;
#endif

static void(entity self) soldier_idle =
{
	if (random() > 0.8f)
		gi.sound(self, CHAN_VOICE, sound_idle, 1, ATTN_IDLE, 0);
}

static void(entity self) soldier_cock =
{
	if (self.s.frame == FRAME_stand322)
		gi.sound(self, CHAN_WEAPON, sound_cock, 1, ATTN_IDLE, 0);
	else
		gi.sound(self, CHAN_WEAPON, sound_cock, 1, ATTN_NORM, 0);
}


// STAND
static mframe_t soldier_frames_stand1 [] = {
	{ ai_stand, 0, soldier_idle },
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
static var mmove_t soldier_move_stand1 = { FRAME_stand101, FRAME_stand130 };

static mframe_t soldier_frames_stand3 [] = {
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
	{ ai_stand, 0, soldier_cock },
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
static var mmove_t soldier_move_stand3 = { FRAME_stand301, FRAME_stand339 };

static void(entity self) soldier_stand =
{
	if ((self.monsterinfo.currentmove == &soldier_move_stand3) || (random() < 0.8f))
		self.monsterinfo.currentmove = &soldier_move_stand1;
	else
		self.monsterinfo.currentmove = &soldier_move_stand3;
}


//
// WALK
//

static void(entity self) soldier_walk1_random =
{
	if (random() > 0.1f)
		self.monsterinfo.nextframe = FRAME_walk101;
}

static mframe_t soldier_frames_walk1 [] = {
	{ ai_walk, 3 },
	{ ai_walk, 6 },
	{ ai_walk, 2 },
	{ ai_walk, 2 },
	{ ai_walk, 2 },
	{ ai_walk, 1 },
	{ ai_walk, 6 },
	{ ai_walk, 5 },
	{ ai_walk, 3 },
	{ ai_walk, -1, soldier_walk1_random },
	{ ai_walk },
	{ ai_walk },
	{ ai_walk },
	{ ai_walk },
	{ ai_walk },
	{ ai_walk },
	{ ai_walk },
	{ ai_walk },
	{ ai_walk },
	{ ai_walk },
	{ ai_walk },
	{ ai_walk },
	{ ai_walk },
	{ ai_walk },
	{ ai_walk },
	{ ai_walk },
	{ ai_walk },
	{ ai_walk },
	{ ai_walk },
	{ ai_walk },
	{ ai_walk },
	{ ai_walk },
	{ ai_walk }
};
static var mmove_t soldier_move_walk1 = { FRAME_walk101, FRAME_walk133 };

static mframe_t soldier_frames_walk2 [] = {
	{ ai_walk, 4 },
	{ ai_walk, 4 },
	{ ai_walk, 9 },
	{ ai_walk, 8 },
	{ ai_walk, 5 },
	{ ai_walk, 1 },
	{ ai_walk, 3 },
	{ ai_walk, 7 },
	{ ai_walk, 6 },
	{ ai_walk, 7 }
};
static var mmove_t soldier_move_walk2 = { FRAME_walk209, FRAME_walk218 };

static void(entity self) soldier_walk =
{
	if (random() < 0.5f)
		self.monsterinfo.currentmove = &soldier_move_walk1;
	else
		self.monsterinfo.currentmove = &soldier_move_walk2;
}


//
// RUN
//

static mframe_t soldier_frames_start_run [] = {
	{ ai_run, 7 },
	{ ai_run, 5 }
};
static var mmove_t soldier_move_start_run = { FRAME_run01, FRAME_run02 };

#ifdef GROUND_ZERO
static void soldier_start_charge (entity self)
{
	self.monsterinfo.aiflags |= AI_CHARGING;
}

static void soldier_stop_charge (entity self)
{
	self.monsterinfo.aiflags &= ~AI_CHARGING;
}
#endif

static mframe_t soldier_frames_run [] = {
	{ ai_run, 10 },
	{ ai_run, 11
#ifdef GROUND_ZERO
		, monster_done_dodge
#endif
	},
	{ ai_run, 11 },
	{ ai_run, 16 },
	{ ai_run, 10 },
	{ ai_run, 15
#ifdef GROUND_ZERO
		, monster_done_dodge
#endif
	}
};
static var mmove_t soldier_move_run = { FRAME_run03, FRAME_run08 };

static void(entity self) soldier_run =
{
#ifdef GROUND_ZERO
	monster_done_dodge (self);
#endif

	if (self.monsterinfo.aiflags & AI_STAND_GROUND) {
		self.monsterinfo.currentmove = &soldier_move_stand1;
		return;
	}

	if (self.monsterinfo.currentmove == &soldier_move_walk1 ||
		self.monsterinfo.currentmove == &soldier_move_walk2 ||
		self.monsterinfo.currentmove == &soldier_move_start_run) {
		self.monsterinfo.currentmove = &soldier_move_run;
	} else {
		self.monsterinfo.currentmove = &soldier_move_start_run;
	}
}


//
// PAIN
//

static mframe_t soldier_frames_pain1 [] = {
	{ ai_move, -3 },
	{ ai_move, 4 },
	{ ai_move, 1 },
	{ ai_move, 1 },
	{ ai_move }
};
static var mmove_t soldier_move_pain1 = { FRAME_pain101, FRAME_pain105, soldier_run };

static mframe_t soldier_frames_pain2 [] = {
	{ ai_move, -13 },
	{ ai_move, -1 },
	{ ai_move, 2 },
	{ ai_move, 4 },
	{ ai_move, 2 },
	{ ai_move, 3 },
	{ ai_move, 2 }
};
static var mmove_t soldier_move_pain2 = { FRAME_pain201, FRAME_pain207, soldier_run };

static mframe_t soldier_frames_pain3 [] = {
	{ ai_move, -8 },
	{ ai_move, 10 },
	{ ai_move, -4 },
	{ ai_move, -1 },
	{ ai_move, -3 },
	{ ai_move },
	{ ai_move, 3 },
	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move, 1 },
	{ ai_move },
	{ ai_move, 1 },
	{ ai_move, 2 },
	{ ai_move, 4 },
	{ ai_move, 3 },
	{ ai_move, 2 }
};
static var mmove_t soldier_move_pain3 = { FRAME_pain301, FRAME_pain318, soldier_run };

static mframe_t soldier_frames_pain4 [] = {
	{ ai_move },
	{ ai_move },
	{ ai_move },
	{ ai_move, -10 },
	{ ai_move, -6 },
	{ ai_move, 8 },
	{ ai_move, 4 },
	{ ai_move, 1 },
	{ ai_move },
	{ ai_move, 2 },
	{ ai_move, 5 },
	{ ai_move, 2 },
	{ ai_move, -1 },
	{ ai_move, -1 },
	{ ai_move, 3 },
	{ ai_move, 2 },
	{ ai_move }
};
static var mmove_t soldier_move_pain4 = { FRAME_pain401, FRAME_pain417, soldier_run };

static void(entity self, entity other, float kick, int damage) soldier_pain =
{
	float	r;
	int	n;

	if (self.health < (self.max_health / 2))
		self.s.skinnum |= 1;

#ifdef GROUND_ZERO
	monster_done_dodge (self);
	soldier_stop_charge(self);

	// if we're blind firing, this needs to be turned off here
	self.monsterinfo.aiflags &= ~AI_MANUAL_STEERING;
#endif

	if (level.framenum < self.pain_debounce_framenum)
	{
		if ((self.velocity.z > 100) && ((self.monsterinfo.currentmove == &soldier_move_pain1) || (self.monsterinfo.currentmove == &soldier_move_pain2) || (self.monsterinfo.currentmove == &soldier_move_pain3)))
		{
#ifdef GROUND_ZERO
			if (self.monsterinfo.aiflags & AI_DUCKED)
				monster_duck_up(self);
#endif
			self.monsterinfo.currentmove = &soldier_move_pain4;
		}
		return;
	}

	self.pain_debounce_framenum = level.framenum + 3 * BASE_FRAMERATE;

	n = self.s.skinnum | 1;
	if (n == 1)
		gi.sound(self, CHAN_VOICE, sound_pain_light, 1, ATTN_NORM, 0);
	else if (n == 3)
		gi.sound(self, CHAN_VOICE, sound_pain, 1, ATTN_NORM, 0);
	else
		gi.sound(self, CHAN_VOICE, sound_pain_ss, 1, ATTN_NORM, 0);

	if (self.velocity.z > 100)
	{
#ifdef GROUND_ZERO
		if (self.monsterinfo.aiflags & AI_DUCKED)
			monster_duck_up(self);
#endif

		self.monsterinfo.currentmove = &soldier_move_pain4;
		return;
	}

	if (skill.intVal == 3)
		return;     // no pain anims in nightmare

	r = random();

	if (r < 0.33f)
		self.monsterinfo.currentmove = &soldier_move_pain1;
	else if (r < 0.66f)
		self.monsterinfo.currentmove = &soldier_move_pain2;
	else
		self.monsterinfo.currentmove = &soldier_move_pain3;

#ifdef GROUND_ZERO
	if (self.monsterinfo.aiflags & AI_DUCKED)
		monster_duck_up(self);
#endif
}


//
// ATTACK
//

#ifdef THE_RECKONING
PROGS_LOCAL_STATIC void(entity self, int flash_index) soldierh_laserbeam =
{
	vector	forward, right, up;
	vector	tempang, start;
	vector	dir, angles, end;
	vector	tempvec;
	entity	ent;

	// RAFAEL
	// this sound can't be called this frequent
	if (random() > 0.8)
		gi.sound(self, CHAN_AUTO, gi.soundindex("misc/lasfly.wav"), 1, ATTN_STATIC, 0);

	start = self.s.origin;
	end = self.enemy.s.origin;
	dir = end - start;
	angles = vectoangles (dir);
	tempvec = monster_flash_offset[flash_index];
	
	ent = G_Spawn ();
	ent.s.origin = self.s.origin;
	tempang = angles;
	AngleVectors (tempang, &forward, &right, &up);
	ent.s.angles = tempang;
	start = ent.s.origin;

	if (flash_index == 85)
		start += right * (tempvec[0] - 14);
	else 
		start += right * (tempvec[0] + 2);

	start += up * (tempvec[2] + 8);
	start += forward * tempvec[1];
			
	ent.s.origin = start;
	ent.enemy = self.enemy;
	ent.owner = self;
	
	ent.dmg = 1;

	monster_dabeam (ent);
}
#endif

static int blaster_flash [] = {MZ2_SOLDIER_BLASTER_1, MZ2_SOLDIER_BLASTER_2, MZ2_SOLDIER_BLASTER_3, MZ2_SOLDIER_BLASTER_4, MZ2_SOLDIER_BLASTER_5, MZ2_SOLDIER_BLASTER_6, MZ2_SOLDIER_BLASTER_7, MZ2_SOLDIER_BLASTER_8};
static int shotgun_flash [] = {MZ2_SOLDIER_SHOTGUN_1, MZ2_SOLDIER_SHOTGUN_2, MZ2_SOLDIER_SHOTGUN_3, MZ2_SOLDIER_SHOTGUN_4, MZ2_SOLDIER_SHOTGUN_5, MZ2_SOLDIER_SHOTGUN_6, MZ2_SOLDIER_SHOTGUN_7, MZ2_SOLDIER_SHOTGUN_8};
static int machinegun_flash [] = {MZ2_SOLDIER_MACHINEGUN_1, MZ2_SOLDIER_MACHINEGUN_2, MZ2_SOLDIER_MACHINEGUN_3, MZ2_SOLDIER_MACHINEGUN_4, MZ2_SOLDIER_MACHINEGUN_5, MZ2_SOLDIER_MACHINEGUN_6, MZ2_SOLDIER_MACHINEGUN_7, MZ2_SOLDIER_MACHINEGUN_8};

#ifdef GROUND_ZERO
static void(entity self, int in_flash_number) soldier_fire =
#else
static void(entity self, int flash_number) soldier_fire =
#endif
{
	vector	start;
	vector	forward, right, up;
	vector	aim;
	vector	dir;
	vector	end;
	float	r, u;
	int	flash_index;
#ifdef GROUND_ZERO
	int		flash_number;
	vector	aim_norm;
	float	angle;
	trace_t	tr;
	vector aim_good;

	if ((!self.enemy) || (!self.enemy.inuse))
	{
		self.monsterinfo.aiflags &= ~AI_HOLD_FRAME;
		return;
	}

	if (in_flash_number < 0)
		flash_number = -in_flash_number;
	else
		flash_number = in_flash_number;
#endif

	if (self.s.skinnum < 2)
		flash_index = blaster_flash[flash_number];
	else if (self.s.skinnum < 4)
#ifdef THE_RECKONING
		flash_index = (self.s.modelindex == soldierh_modelindex) ? blaster_flash[flash_number] : shotgun_flash[flash_number];
#else
		flash_index = shotgun_flash[flash_number];
#endif
	else
		flash_index = machinegun_flash[flash_number];

	AngleVectors(self.s.angles, &forward, &right, 0);
	start = G_ProjectSource(self.s.origin, monster_flash_offset[flash_index], forward, right);

	if (flash_number == 5 || flash_number == 6)
	{
		aim = forward;
	}
	else
	{
		end = self.enemy.s.origin;
		end.z += self.enemy.viewheight;
		aim = end - start;
		
#ifdef GROUND_ZERO
		aim_good = end;

		if (in_flash_number < 0)
		{
			aim_norm = aim;
			VectorNormalize (aim_norm);
			angle = aim_norm * forward;
			if (angle < 0.9)  // ~25 degree angle
				return;
		}
#endif
		
		dir = vectoangles(aim);
		AngleVectors(dir, &forward, &right, &up);

#ifdef THE_RECKONING
		if (self.s.modelindex == soldierh_modelindex)
		{
			r = random(-100f, 100f);
			u = random(-50f, 50f);
		}
		else
		{
#endif
#ifdef GROUND_ZERO
		if (skill.intVal < 2)
		{
#endif
			r = random(-1000f, 1000f);
			u = random(-500f, 500f);
#ifdef GROUND_ZERO
		}
		else
		{
			r = random(-500f, 500f);
			u = random(-250f, 250f);
		}
#endif
#ifdef THE_RECKONING
		}
#endif
		end = start + (8192 * forward);
		end += (r * right);
		end += (u * up);

		aim = end - start;
		VectorNormalize(aim);
		
#ifdef GROUND_ZERO
		if (!(flash_number == 5 || flash_number == 6))
		{
			gi.trace (&tr, start, vec3_origin, vec3_origin, aim_good, self, MASK_SHOT);
			if ((tr.ent != self.enemy) && (tr.ent != world))
				return;
		}
#endif
	}

	if (self.s.skinnum <= 1) {
#ifdef THE_RECKONING
		if (self.s.modelindex == soldierh_modelindex)
			monster_fire_ionripper (self, start, aim, 5, 600, flash_index, EF_IONRIPPER);
		else
#endif
			monster_fire_blaster(self, start, aim, 5, 600, flash_index, EF_BLASTER);
	} else if (self.s.skinnum <= 3) {
#ifdef THE_RECKONING
		if (self.s.modelindex == soldierh_modelindex)
			monster_fire_blueblaster (self, start, aim, 1, 600, MZ_BLUEHYPERBLASTER, EF_BLUEHYPERBLASTER);
		else
#endif
			monster_fire_shotgun(self, start, aim, 2, 1, DEFAULT_SHOTGUN_HSPREAD, DEFAULT_SHOTGUN_VSPREAD, DEFAULT_SHOTGUN_COUNT, flash_index);
	} else {
		if (!(self.monsterinfo.aiflags & AI_HOLD_FRAME))
#ifdef GROUND_ZERO
			self.wait = (float)
#else
			self.monsterinfo.pause_framenum = 
#endif
				level.framenum + (3 + Q_rand() % 8);

#ifdef THE_RECKONING
		if (self.s.modelindex == soldierh_modelindex)
			soldierh_laserbeam (self, flash_index);
		else
#endif
			monster_fire_bullet(self, start, aim, 2, 4, DEFAULT_BULLET_HSPREAD, DEFAULT_BULLET_VSPREAD, flash_index);

		if (level.framenum >= 
#ifdef GROUND_ZERO
			self.wait
#else
			self.monsterinfo.pause_framenum
#endif
			)
			self.monsterinfo.aiflags &= ~AI_HOLD_FRAME;
		else
			self.monsterinfo.aiflags |= AI_HOLD_FRAME;
	}
}

// ATTACK1 (blaster/shotgun)

#ifdef THE_RECKONING
static void(entity self) soldierh_hyper_refire1 =
{
	if (self.s.modelindex != soldierh_modelindex || self.s.skinnum < 2)
		return;
	else if (self.s.skinnum < 4)
	{
		if (random() < 0.7)
			self.s.frame = FRAME_attak103;
		else
			gi.sound(self, CHAN_AUTO, gi.soundindex("weapons/hyprbd1a.wav"), 1, ATTN_NORM, 0);
	}
}

static void(entity self) soldierh_ripper1 =
{
	if (self.s.modelindex != soldierh_modelindex)
		return;

	if (self.s.skinnum < 2)
		soldier_fire (self, 0);
	else if (self.s.skinnum < 4)
		soldier_fire (self, 0);
}
#endif

static void(entity self) soldier_fire1 =
{
	soldier_fire(self, 0);
}

static void(entity self) soldier_attack1_refire1 =
{
#ifdef GROUND_ZERO
	if (self.monsterinfo.aiflags & AI_MANUAL_STEERING)
	{
		self.monsterinfo.aiflags &= ~AI_MANUAL_STEERING;
		return;
	}
#endif

	if (!self.enemy)
		return;

	if (self.s.skinnum > 1)
		return;

	if (self.enemy.health <= 0)
		return;

	if (((skill.intVal == 3) && (random() < 0.5f)) || (range(self, self.enemy) == RANGE_MELEE))
		self.monsterinfo.nextframe = FRAME_attak102;
	else
		self.monsterinfo.nextframe = FRAME_attak110;
}

static void(entity self) soldier_attack1_refire2 =
{
	if (!self.enemy)
		return;

	if (self.s.skinnum < 2)
		return;

	if (self.enemy.health <= 0)
		return;

	if (((skill.intVal == 3) && (random() < 0.5f)) || (range(self, self.enemy) == RANGE_MELEE))
		self.monsterinfo.nextframe = FRAME_attak102;
}

#ifdef THE_RECKONING
static void(entity self) soldierh_hyper_sound =
{
	if (self.s.modelindex != soldierh_modelindex || self.s.skinnum < 2)
		return;
	else if (self.s.skinnum < 4)
		gi.sound(self, CHAN_AUTO, gi.soundindex("weapons/hyprbl1a.wav"), 1, ATTN_NORM, 0);
}
#endif

static mframe_t soldier_frames_attack1 [] = {
	{ ai_charge },
#ifdef THE_RECKONING
	{ ai_charge, 0,  soldierh_hyper_sound },
	{ ai_charge, 0,  soldier_fire1 },
	{ ai_charge, 0,  soldierh_ripper1 },
	{ ai_charge, 0,  soldierh_ripper1 },
	{ ai_charge, 0,  soldier_attack1_refire1 },
	{ ai_charge, 0,  soldierh_hyper_refire1 },
#else
	{ ai_charge },
	{ ai_charge, 0,  soldier_fire1 },
	{ ai_charge },
	{ ai_charge },
	{ ai_charge, 0,  soldier_attack1_refire1 },
	{ ai_charge },
#endif
	{ ai_charge, 0,  soldier_cock },
	{ ai_charge, 0,  soldier_attack1_refire2 },
	{ ai_charge },
	{ ai_charge },
	{ ai_charge }
};
static var mmove_t soldier_move_attack1 = { FRAME_attak101, FRAME_attak112, soldier_run };

// ATTACK2 (blaster/shotgun)

#ifdef THE_RECKONING
static void(entity self) soldierh_hyper_refire2 =
{
	if (!self.enemy)
		return;

	if (self.s.modelindex != soldierh_modelindex || self.s.skinnum < 2)
		return;
	else if (self.s.skinnum < 4)
	{
		if (random() < 0.7)
			self.s.frame = FRAME_attak205;
		else
			gi.sound(self, CHAN_AUTO, gi.soundindex("weapons/hyprbd1a.wav"), 1, ATTN_NORM, 0);
	}
}

static void(entity self) soldierh_ripper2 =
{
	if (self.s.modelindex != soldierh_modelindex)
		return;

	if (self.s.skinnum < 2)
		soldier_fire (self, 1);
	else if (self.s.skinnum < 4)
		soldier_fire (self, 1);
}
#endif

static void(entity self) soldier_fire2 =
{
	soldier_fire(self, 1);
}

static void(entity self) soldier_attack2_refire1 =
{
	if (!self.enemy)
		return;

	if (self.s.skinnum > 1)
		return;

	if (self.enemy.health <= 0)
		return;

	if (((skill.intVal == 3) && (random() < 0.5f)) || (range(self, self.enemy) == RANGE_MELEE))
		self.monsterinfo.nextframe = FRAME_attak204;
	else
		self.monsterinfo.nextframe = FRAME_attak216;
}

static void(entity self) soldier_attack2_refire2 =
{
	if (!self.enemy)
		return;

	if (self.s.skinnum < 2)
		return;

	if (self.enemy.health <= 0)
		return;

	if (((skill.intVal == 3) && (random() < 0.5f)) || (range(self, self.enemy) == RANGE_MELEE))
		self.monsterinfo.nextframe = FRAME_attak204;
}

static mframe_t soldier_frames_attack2 [] = {
	{ ai_charge },
	{ ai_charge },
	{ ai_charge },
#ifdef THE_RECKONING
	{ ai_charge, 0, soldierh_hyper_sound },
	{ ai_charge, 0, soldier_fire2 },
	{ ai_charge, 0, soldierh_ripper2 },
	{ ai_charge, 0, soldierh_ripper2 },
	{ ai_charge, 0, soldier_attack2_refire1 },
	{ ai_charge, 0, soldierh_hyper_refire2 },
#else
	{ ai_charge },
	{ ai_charge, 0, soldier_fire2 },
	{ ai_charge },
	{ ai_charge },
	{ ai_charge, 0, soldier_attack2_refire1 },
	{ ai_charge },
#endif
	{ ai_charge },
	{ ai_charge },
	{ ai_charge },
	{ ai_charge, 0, soldier_cock },
	{ ai_charge },
	{ ai_charge, 0, soldier_attack2_refire2 },
	{ ai_charge },
	{ ai_charge },
	{ ai_charge }
};
static var mmove_t soldier_move_attack2 = { FRAME_attak201, FRAME_attak218, soldier_run };

// ATTACK3 (duck and shoot)

#ifdef GROUND_ZERO
#define soldier_duck_down monster_duck_down
#define soldier_duck_up monster_duck_up
#define soldier_duck_hold monster_duck_hold
#else
static void(entity self) soldier_duck_down =
{
	if (self.monsterinfo.aiflags & AI_DUCKED)
		return;
	self.monsterinfo.aiflags |= AI_DUCKED;
	self.maxs.z -= 32;
	self.takedamage = DAMAGE_YES;
	self.monsterinfo.pause_framenum = level.framenum + 1 * BASE_FRAMERATE;
	gi.linkentity(self);
}

static void(entity self) soldier_duck_up =
{
	self.monsterinfo.aiflags &= ~AI_DUCKED;
	self.maxs.z += 32;
	self.takedamage = DAMAGE_AIM;
	gi.linkentity(self);
}
#endif

static void(entity self) soldier_fire3 =
{
	soldier_duck_down(self);
	soldier_fire(self, 2);
}

static void(entity self) soldier_attack3_refire =
{
	if ((level.framenum + (int)(0.4f * BASE_FRAMERATE)) <
#ifdef GROUND_ZERO
		self.monsterinfo.duck_wait_framenum
#else
		self.monsterinfo.pause_framenum
#endif
		)
		self.monsterinfo.nextframe = FRAME_attak303;
}

static mframe_t soldier_frames_attack3 [] = {
	{ ai_charge },
	{ ai_charge },
	{ ai_charge, 0, soldier_fire3 },
	{ ai_charge },
	{ ai_charge },
	{ ai_charge, 0, soldier_attack3_refire },
	{ ai_charge, 0, soldier_duck_up },
	{ ai_charge },
	{ ai_charge }
};
static var mmove_t soldier_move_attack3 = { FRAME_attak301, FRAME_attak309, soldier_run };

// ATTACK4 (machinegun)

static void(entity self) soldier_fire4 =
{
	soldier_fire(self, 3);
}

static mframe_t soldier_frames_attack4 [] = {
	{ ai_charge },
	{ ai_charge },
	{ ai_charge, 0, soldier_fire4 },
	{ ai_charge },
	{ ai_charge },
	{ ai_charge }
};
static var mmove_t soldier_move_attack4 = { FRAME_attak401, FRAME_attak406, soldier_run };


// ATTACK6 (run & shoot)

static void(entity self) soldier_fire8 =
{
#ifdef GROUND_ZERO
	soldier_fire(self, -7);
#else
	soldier_fire(self, 7);
#endif
}

static void(entity self) soldier_attack6_refire =
{
#ifdef GROUND_ZERO
	monster_done_dodge (self);
	soldier_stop_charge (self);

	if (!self.enemy)
		return;
#endif

	if (self.enemy.health <= 0)
		return;

	if (range(self, self.enemy) <
#ifdef GROUND_ZERO
		RANGE_NEAR
#else
		RANGE_MID
#endif
		)
		return;

	if (skill.intVal == 3
#ifdef GROUND_ZERO
		 || (random() < (0.25* skill.intVal))
#endif
		)
		self.monsterinfo.nextframe = FRAME_runs03;
}

static mframe_t soldier_frames_attack6 [] =
{
	{ ai_charge, 10
#ifdef GROUND_ZERO
		, soldier_start_charge
#endif
	},
	{ ai_charge,  4 },
	{ ai_charge, 12 },
	{ ai_charge, 11, soldier_fire8 },
	{ ai_charge, 13 },
	{ ai_charge, 18
#ifdef GROUND_ZERO
		, monster_done_dodge
#endif
	},
	{ ai_charge, 15 },
	{ ai_charge, 14 },
	{ ai_charge, 11 },
	{ ai_charge,  8 },
	{ ai_charge, 11 },
	{ ai_charge, 12 },
	{ ai_charge, 12 },
	{ ai_charge, 17, soldier_attack6_refire }
};
static var mmove_t soldier_move_attack6 = { FRAME_runs01, FRAME_runs14, soldier_run };

static void(entity self) soldier_attack =
{
#ifdef GROUND_ZERO
	monster_done_dodge (self);

	// PMM - blindfire!
	if (self.monsterinfo.attack_state == AS_BLIND)
	{
		float chance = 0.1;
		// setup shot probabilities
		if (self.monsterinfo.blind_fire_framedelay < (int)(1.0 * BASE_FRAMERATE))
			chance = 1.0;
		else if (self.monsterinfo.blind_fire_framedelay < (int)(7.5 * BASE_FRAMERATE))
			chance = 0.4;

		float r = random();

		// minimum of 2 seconds, plus 0-3, after the shots are done
		self.monsterinfo.blind_fire_framedelay += (int)(random(4.1f, 7.1f) * BASE_FRAMERATE);

		// don't shoot at the origin
		if (!self.monsterinfo.blind_fire_target)
			return;

		// don't shoot if the dice say not to
		if (r > chance)
			return;

		// turn on manual steering to signal both manual steering and blindfire
		self.monsterinfo.aiflags |= AI_MANUAL_STEERING;
		self.monsterinfo.currentmove = &soldier_move_attack1;
		self.monsterinfo.attack_finished = level.framenum + (int)(random(1.5, 2.5) * BASE_FRAMERATE);
		return;
	}

	float r = random();

	if ((!(self.monsterinfo.aiflags & (AI_BLOCKED|AI_STAND_GROUND))) &&
		(range(self, self.enemy) >= RANGE_NEAR) && 
		(r < (skill.intVal*0.25) && 
		(self.s.skinnum <= 3)))
	{
		self.monsterinfo.currentmove = &soldier_move_attack6;
		return;
	}
#endif

	if (self.s.skinnum < 4)
	{
		if (random() < 0.5f)
			self.monsterinfo.currentmove = &soldier_move_attack1;
		else
			self.monsterinfo.currentmove = &soldier_move_attack2;
	}
	else
	{
		self.monsterinfo.currentmove = &soldier_move_attack4;
	}
}


//
// SIGHT
//

static void(entity self, entity other) soldier_sight =
{
	if (random() < 0.5f)
		gi.sound(self, CHAN_VOICE, sound_sight1, 1, ATTN_NORM, 0);
	else
		gi.sound(self, CHAN_VOICE, sound_sight2, 1, ATTN_NORM, 0);

	if ((skill.intVal > 0) && self.enemy && (range(self, self.enemy) >= RANGE_MID)) {
		if (random() > 0.5f)
#if defined(THE_RECKONING) || defined(GROUND_ZERO)
		{
			if (self.s.skinnum < 4)	
				self.monsterinfo.currentmove = &soldier_move_attack6;
			else
				self.monsterinfo.currentmove = &soldier_move_attack4;
		}
#else
			self.monsterinfo.currentmove = &soldier_move_attack6;
#endif
	}
}

//
// DUCK
//

#ifndef GROUND_ZERO
static void(entity self) soldier_duck_hold =
{
	if (level.framenum >= self.monsterinfo.pause_framenum)
		self.monsterinfo.aiflags &= ~AI_HOLD_FRAME;
	else
		self.monsterinfo.aiflags |= AI_HOLD_FRAME;
}
#endif

static mframe_t soldier_frames_duck [] = {
	{ ai_move, 5, soldier_duck_down },
	{ ai_move, -1, soldier_duck_hold },
	{ ai_move, 1 },
	{ ai_move, 0,  soldier_duck_up },
	{ ai_move, 5 }
};
static var mmove_t soldier_move_duck = { FRAME_duck01, FRAME_duck05, soldier_run };

#ifndef GROUND_ZERO
static void(entity self, entity attacker, float eta) soldier_dodge =
{
	float	r;

	r = random();
	if (r > 0.25f)
		return;

	if (!self.enemy)
		self.enemy = attacker;

	if (skill.intVal == 0) {
		self.monsterinfo.currentmove = &soldier_move_duck;
		return;
	}

	self.monsterinfo.pause_framenum = level.framenum + (int)((eta + 0.3f) * BASE_FRAMERATE);
	r = random();

	if (skill.intVal == 1) {
		if (r > 0.33f)
			self.monsterinfo.currentmove = &soldier_move_duck;
		else
			self.monsterinfo.currentmove = &soldier_move_attack3;
		return;
	}

	if (skill.intVal >= 2) {
		if (r > 0.66f)
			self.monsterinfo.currentmove = &soldier_move_duck;
		else
			self.monsterinfo.currentmove = &soldier_move_attack3;
		return;
	}

	self.monsterinfo.currentmove = &soldier_move_attack3;
}
#endif

//
// DEATH
//

static void(entity self) soldier_fire6 =
{
#ifdef THE_RECKONING
	// no fire laser
	if (self.s.modelindex != soldierh_modelindex || self.s.skinnum < 4)
#endif
		soldier_fire(self, 5);
}

static void(entity self) soldier_fire7 =
{
#ifdef THE_RECKONING
	// no fire laser
	if (self.s.modelindex != soldierh_modelindex || self.s.skinnum < 4)
#endif
		soldier_fire(self, 6);
}

static void(entity self) soldier_dead =
{
	self.mins = '-16 -16 -24';
	self.maxs = '16 16 -8';
	self.movetype = MOVETYPE_TOSS;
	self.svflags |= SVF_DEADMONSTER;
	self.nextthink = 0;
	gi.linkentity(self);
}

static mframe_t soldier_frames_death1 [] = {
	{ ai_move },
	{ ai_move, -10 },
	{ ai_move, -10 },
	{ ai_move, -10 },
	{ ai_move, -5 },
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
	{ ai_move, 0,   soldier_fire6 },
	{ ai_move },
	{ ai_move },
	{ ai_move, 0,   soldier_fire7 },
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
static var mmove_t soldier_move_death1 = { FRAME_death101, FRAME_death136, soldier_dead };

static mframe_t soldier_frames_death2 [] = {
	{ ai_move, -5 },
	{ ai_move, -5 },
	{ ai_move, -5 },
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
static var mmove_t soldier_move_death2 = { FRAME_death201, FRAME_death235, soldier_dead };

static mframe_t soldier_frames_death3 [] = {
	{ ai_move, -5 },
	{ ai_move, -5 },
	{ ai_move, -5 },
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
};
static var mmove_t soldier_move_death3 = { FRAME_death301, FRAME_death345, soldier_dead };

static mframe_t soldier_frames_death4 [] = {
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
static var mmove_t soldier_move_death4 = { FRAME_death401, FRAME_death453, soldier_dead };

static mframe_t soldier_frames_death5 [] = {
	{ ai_move, -5 },
	{ ai_move, -5 },
	{ ai_move, -5 },
	{ ai_move, 0 },
	{ ai_move, 0 },
	{ ai_move, 0 },
	{ ai_move, 0 },
	{ ai_move, 0 },
	{ ai_move, 0 },
	{ ai_move, 0 },

	{ ai_move, 0 },
	{ ai_move, 0 },
	{ ai_move, 0 },
	{ ai_move, 0 },
	{ ai_move, 0 },
	{ ai_move, 0 },
	{ ai_move, 0 },
	{ ai_move, 0 },
	{ ai_move, 0 },
	{ ai_move, 0 },

	{ ai_move, 0 },
	{ ai_move, 0 },
	{ ai_move, 0 },
	{ ai_move, 0 }
};
static var mmove_t soldier_move_death5 = { FRAME_death501, FRAME_death524, soldier_dead };

static mframe_t soldier_frames_death6 [] = {
	{ ai_move, 0 },
	{ ai_move, 0 },
	{ ai_move, 0 },
	{ ai_move, 0 },
	{ ai_move, 0 },
	{ ai_move, 0 },
	{ ai_move, 0 },
	{ ai_move, 0 },
	{ ai_move, 0 },
	{ ai_move, 0 }
};
static var mmove_t soldier_move_death6 = { FRAME_death601, FRAME_death610, soldier_dead };

// from misc.qc
void(entity self, string gibname, int damage, gib_type_t type) ThrowHead;

static void(entity self, entity inflictor, entity attacker, int damage, vector point) soldier_die =
{
	int	n;

// check for gib
	if (self.health <= self.gib_health) {
		gi.sound(self, CHAN_VOICE, gi.soundindex("misc/udeath.wav"), 1, ATTN_NORM, 0);
		for (n = 0; n < 3; n++)
			ThrowGib(self, "models/objects/gibs/sm_meat/tris.md2", damage, GIB_ORGANIC);
		ThrowGib(self, "models/objects/gibs/chest/tris.md2", damage, GIB_ORGANIC);
		ThrowHead(self, "models/objects/gibs/head2/tris.md2", damage, GIB_ORGANIC);
		self.deadflag = DEAD_DEAD;
		return;
	}

	if (self.deadflag == DEAD_DEAD)
		return;

// regular death
	self.deadflag = DEAD_DEAD;
	self.takedamage = DAMAGE_YES;
	self.s.skinnum |= 1;

	if (self.s.skinnum == 1)
		gi.sound(self, CHAN_VOICE, sound_death_light, 1, ATTN_NORM, 0);
	else if (self.s.skinnum == 3)
		gi.sound(self, CHAN_VOICE, sound_death, 1, ATTN_NORM, 0);
	else // (self.s.skinnum == 5)
		gi.sound(self, CHAN_VOICE, sound_death_ss, 1, ATTN_NORM, 0);

	if (fabsf((self.s.origin[2] + self.viewheight) - point[2]) <= 4) {
		// head shot
		self.monsterinfo.currentmove = &soldier_move_death3;
		return;
	}

	n = Q_rand() % 5;
	if (n == 0)
		self.monsterinfo.currentmove = &soldier_move_death1;
	else if (n == 1)
		self.monsterinfo.currentmove = &soldier_move_death2;
	else if (n == 2)
		self.monsterinfo.currentmove = &soldier_move_death4;
	else if (n == 3)
		self.monsterinfo.currentmove = &soldier_move_death5;
	else
		self.monsterinfo.currentmove = &soldier_move_death6;
}

#ifdef GROUND_ZERO
//
// NEW DODGE CODE
//

static void soldier_sidestep (entity self)
{
	if (self.s.skinnum <= 3)
	{
		if (self.monsterinfo.currentmove != &soldier_move_attack6)
			self.monsterinfo.currentmove = &soldier_move_attack6;
	}
	else
	{
		if (self.monsterinfo.currentmove != &soldier_move_start_run)
			self.monsterinfo.currentmove = &soldier_move_start_run;
	}
}

static void soldier_duck (entity self, float eta)
{
	float r;

	// has to be done immediately otherwise he can get stuck
	monster_duck_down(self);

	if (skill.intVal == 0)
	{
		// PMM - stupid dodge
		self.monsterinfo.nextframe = FRAME_duck01;
		self.monsterinfo.currentmove = &soldier_move_duck;
		self.monsterinfo.duck_wait_framenum = level.framenum + (int)((eta + 1) * BASE_FRAMERATE);
		return;
	}

	r = random();

	if (r > (skill.intVal * 0.3))
	{
		self.monsterinfo.nextframe = FRAME_duck01;
		self.monsterinfo.currentmove = &soldier_move_duck;
		self.monsterinfo.duck_wait_framenum = level.framenum + (int)((eta + (0.1 * (3 - skill.intVal))) * BASE_FRAMERATE);
	}
	else
	{
		self.monsterinfo.nextframe = FRAME_attak301;
		self.monsterinfo.currentmove = &soldier_move_attack3;
		self.monsterinfo.duck_wait_framenum = level.framenum + (int)((eta + 1) * BASE_FRAMERATE);
	}
	return;
}

static mframe_t soldier_frames_blind [] =
{
	{ ai_move, 0, soldier_idle },
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
static var mmove_t soldier_move_blind = { FRAME_stand101, FRAME_stand130 };

static void soldier_blind (entity self)
{
	self.monsterinfo.currentmove = &soldier_move_blind;
}

static bool soldier_blocked (entity self, float dist)
{
	// don't do anything if you're dodging
	if ((self.monsterinfo.aiflags & AI_DODGING) || (self.monsterinfo.aiflags & AI_DUCKED))
		return false;

	if(blocked_checkshot (self, 0.25 + (0.05 * skill.intVal)))
		return true;

	if(blocked_checkplat (self, dist))
		return true;

	return false;
}
#endif

//
// SPAWN
//

PROGS_LOCAL_STATIC void(entity self, string model) SP_monster_soldier_x =
{
	if (!soldier_move_stand1.frame)
	{
		soldier_move_stand1.frame = &soldier_frames_stand1;
		soldier_move_stand3.endfunc = soldier_stand;
		soldier_move_stand3.frame = soldier_frames_stand3;
		soldier_move_stand1.endfunc = soldier_stand;
		soldier_move_walk1.frame = &soldier_frames_walk1;
		soldier_move_walk2.frame = &soldier_frames_walk2;
		soldier_move_start_run.frame = &soldier_frames_start_run;
		soldier_move_start_run.endfunc = soldier_run;
		soldier_move_run.frame = &soldier_frames_run;
		soldier_move_pain1.frame = &soldier_frames_pain1;
		soldier_move_pain2.frame = &soldier_frames_pain2;
		soldier_move_pain3.frame = &soldier_frames_pain3;
		soldier_move_pain4.frame = &soldier_frames_pain4;
		soldier_move_attack1.frame = &soldier_frames_attack1;
		soldier_move_attack2.frame = &soldier_frames_attack2;
		soldier_move_attack3.frame = &soldier_frames_attack3;
		soldier_move_attack4.frame = &soldier_frames_attack4;
		soldier_move_attack6.frame = &soldier_frames_attack6;
		soldier_move_duck.frame = &soldier_frames_duck;
		soldier_move_death1.frame = &soldier_frames_death1;
		soldier_move_death2.frame = &soldier_frames_death2;
		soldier_move_death3.frame = &soldier_frames_death3;
		soldier_move_death4.frame = &soldier_frames_death4;
		soldier_move_death5.frame = &soldier_frames_death5;
		soldier_move_death6.frame = &soldier_frames_death6;

#ifdef GROUND_ZERO
		soldier_move_blind.frame = &soldier_frames_blind;
		soldier_move_blind.endfunc = soldier_blind;
#endif
	}

	self.s.modelindex = gi.modelindex(model);
	self.monsterinfo.scale = MODEL_SCALE;
	self.mins = '-16 -16 -24';
	self.maxs = '16 16 32';
	self.movetype = MOVETYPE_STEP;
	self.solid = SOLID_BBOX;

	sound_idle =    gi.soundindex("soldier/solidle1.wav");
	sound_sight1 =  gi.soundindex("soldier/solsght1.wav");
	sound_sight2 =  gi.soundindex("soldier/solsrch1.wav");
	sound_cock =    gi.soundindex("infantry/infatck3.wav");

	self.mass = 100;

	self.pain = soldier_pain;
	self.die = soldier_die;

	self.monsterinfo.stand = soldier_stand;
	self.monsterinfo.walk = soldier_walk;
	self.monsterinfo.run = soldier_run;
	self.monsterinfo.attack = soldier_attack;
	self.monsterinfo.melee = 0;
	self.monsterinfo.sight = soldier_sight;
#ifdef GROUND_ZERO
	self.monsterinfo.dodge = M_MonsterDodge;
	self.monsterinfo.blocked = soldier_blocked;
	self.monsterinfo.duck = soldier_duck;
	self.monsterinfo.unduck = monster_duck_up;
	self.monsterinfo.sidestep = soldier_sidestep;

	if(self.spawnflags & 8)	// blind
		self.monsterinfo.stand = soldier_blind;
#else
	self.monsterinfo.dodge = soldier_dodge;
#endif

	gi.linkentity(self);

	self.monsterinfo.stand(self);

	walkmonster_start(self);
}


/*QUAKED monster_soldier_light (1 .5 0) (-16 -16 -24) (16 16 32) Ambush Trigger_Spawn Sight
*/
API_FUNC static void(entity self) SP_monster_soldier_light =
{
	if (deathmatch.intVal) {
		G_FreeEdict(self);
		return;
	}

	SP_monster_soldier_x(self, "models/monsters/soldier/tris.md2");

	sound_pain_light = gi.soundindex("soldier/solpain2.wav");
	sound_death_light = gi.soundindex("soldier/soldeth2.wav");
	gi.modelindex("models/objects/laser/tris.md2");
	gi.soundindex("misc/lasfly.wav");
	gi.soundindex("soldier/solatck2.wav");

	self.s.skinnum = 0;
	self.health = 20;
	self.gib_health = -30;

#ifdef GROUND_ZERO
	self.monsterinfo.blindfire = true;
#endif
}

/*QUAKED monster_soldier (1 .5 0) (-16 -16 -24) (16 16 32) Ambush Trigger_Spawn Sight
*/
API_FUNC static void(entity self) SP_monster_soldier =
{
	if (deathmatch.intVal) {
		G_FreeEdict(self);
		return;
	}

	SP_monster_soldier_x(self, "models/monsters/soldier/tris.md2");

	sound_pain = gi.soundindex("soldier/solpain1.wav");
	sound_death = gi.soundindex("soldier/soldeth1.wav");
	gi.soundindex("soldier/solatck1.wav");

	self.s.skinnum = 2;
	self.health = 30;
	self.gib_health = -30;
}

/*QUAKED monster_soldier_ss (1 .5 0) (-16 -16 -24) (16 16 32) Ambush Trigger_Spawn Sight
*/
API_FUNC static void(entity self) SP_monster_soldier_ss =
{
	if (deathmatch.intVal) {
		G_FreeEdict(self);
		return;
	}

	SP_monster_soldier_x(self, "models/monsters/soldier/tris.md2");

	sound_pain_ss = gi.soundindex("soldier/solpain3.wav");
	sound_death_ss = gi.soundindex("soldier/soldeth3.wav");
	gi.soundindex("soldier/solatck3.wav");

	self.s.skinnum = 4;
	self.health = 40;
	self.gib_health = -30;
}

#ifdef THE_RECKONING
//
// SPAWN
//

PROGS_LOCAL_STATIC void(entity self) SP_monster_soldier_h =
{
	SP_monster_soldier_x(self, "models/monsters/soldierh/tris.md2");
	soldierh_modelindex = self.s.modelindex;
}


/*QUAKED monster_soldier_ripper (1 .5 0) (-16 -16 -24) (16 16 32) Ambush Trigger_Spawn Sight
*/
API_FUNC static void(entity self) SP_monster_soldier_ripper =
{
	if (deathmatch.intVal)
	{
		G_FreeEdict (self);
		return;
	}

	SP_monster_soldier_h (self);

	sound_pain_light = gi.soundindex ("soldier/solpain2.wav");
	sound_death_light = gi.soundindex ("soldier/soldeth2.wav");
	
	gi.modelindex ("models/objects/boomrang/tris.md2");
	gi.soundindex ("misc/lasfly.wav");
	gi.soundindex ("soldier/solatck2.wav");

	self.s.skinnum = 0;
	self.health = 50;
	self.gib_health = -30;

#ifdef GROUND_ZERO
	self.monsterinfo.blindfire = true;
#endif
}

/*QUAKED monster_soldier_hypergun (1 .5 0) (-16 -16 -24) (16 16 32) Ambush Trigger_Spawn Sight
*/
API_FUNC static void(entity self) SP_monster_soldier_hypergun =
{
	if (deathmatch.intVal)
	{
		G_FreeEdict (self);
		return;
	}

	SP_monster_soldier_h (self);

	gi.modelindex ("models/objects/blaser/tris.md2");
	sound_pain = gi.soundindex ("soldier/solpain1.wav");
	sound_death = gi.soundindex ("soldier/soldeth1.wav");
	gi.soundindex ("soldier/solatck1.wav");

	self.s.skinnum = 2;
	self.health = 60;
	self.gib_health = -30;

#ifdef GROUND_ZERO
	self.monsterinfo.blindfire = true;
#endif
}

/*QUAKED monster_soldier_lasergun (1 .5 0) (-16 -16 -24) (16 16 32) Ambush Trigger_Spawn Sight
*/
API_FUNC static void(entity self) SP_monster_soldier_lasergun =
{
	if (deathmatch.intVal)
	{
		G_FreeEdict (self);
		return;
	}

	SP_monster_soldier_h (self);

	sound_pain_ss = gi.soundindex ("soldier/solpain3.wav");
	sound_death_ss = gi.soundindex ("soldier/soldeth3.wav");
	gi.soundindex ("soldier/solatck3.wav");

	self.s.skinnum = 4;
	self.health = 70;
	self.gib_health = -30;
		
}
#endif