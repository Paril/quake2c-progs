#ifdef GROUND_ZERO

/*inline*/ float(entity self, entity other) realrange =
{
	return VectorLength(self.s.origin - other.s.origin);
}

//===============================
// BLOCKED Logic
//===============================

bool parasite_drain_attack_ok(vector start, vector end);

// blocked_checkshot
//	shotchance: 0-1, chance they'll take the shot if it's clear.
bool(entity self, float shotChance) blocked_checkshot =
{
	bool	playerVisible;

	if (!self.enemy)
		return false;

	// blocked checkshot is only against players. this will
	// filter out player sounds and other shit they should
	// not be firing at.
	if(!(self.enemy.is_client))
		return false;

	if (random() < shotChance)
		return false;

	// PMM - special handling for the parasite
	if (self.classname == "monster_parasite")
	{
		vector	f, r, offset, start, end;
		trace_t	tr;
		AngleVectors (self.s.angles, &f, &r, 0);
		offset = '24 0 6';
		start = G_ProjectSource (self.s.origin, offset, f, r);

		end = self.enemy.s.origin;
		if (!parasite_drain_attack_ok(start, end))
		{
			end[2] = self.enemy.s.origin[2] + self.enemy.maxs[2] - 8;
			if (!parasite_drain_attack_ok(start, end))
			{
				end[2] = self.enemy.s.origin[2] + self.enemy.mins[2] + 8;
				if (!parasite_drain_attack_ok(start, end))
					return false;
			}
		}
		end = self.enemy.s.origin;

		gi.trace (&tr, start, vec3_origin, vec3_origin, end, self, MASK_SHOT);

		if (tr.ent != self.enemy)
		{
			self.monsterinfo.aiflags |= AI_BLOCKED;
			
			if (self.monsterinfo.attack)
				self.monsterinfo.attack(self);
			
			self.monsterinfo.aiflags &= ~AI_BLOCKED;
			return true;
		}
	}

	playerVisible = visible (self, self.enemy);

	// always shoot at teslas
	if (playerVisible)
	{
		if (self.enemy.classname == "tesla")
		{
			// turn on AI_BLOCKED to let the monster know the attack is being called
			// by the blocked functions...
			self.monsterinfo.aiflags |= AI_BLOCKED;
			
			if (self.monsterinfo.attack)
				self.monsterinfo.attack(self);
			
			self.monsterinfo.aiflags &= ~AI_BLOCKED;
			return true;
		}
	}

	return false;
}

// blocked_checkplat
//	dist: how far they are trying to walk.
bool(entity self, float dist) blocked_checkplat =
{
	int		playerPosition;
	trace_t		trace;
	vector		pt1, pt2;
	vector		forward;
	entity		plat;

	if (!self.enemy)
		return false;

	// check player's relative altitude
	if(self.enemy.absmin[2] >= self.absmax[2])
		playerPosition = 1;
	else if(self.enemy.absmax[2] <= self.absmin[2])
		playerPosition = -1;
	else
		playerPosition = 0;

	// if we're close to the same position, don't bother trying plats.
	if (playerPosition == 0)
		return false;

	plat = world;

	// see if we're already standing on a plat.
	if (self.groundentity != null_entity && self.groundentity != world)
		if(!strncmp(self.groundentity.classname, "func_plat", 8))
			plat = self.groundentity;

	// if we're not, check to see if we'll step onto one with this move
	if (!plat)
	{
		AngleVectors (self.s.angles, &forward, 0, 0);
		pt1 = self.s.origin + (forward * dist);
		pt2 = pt1;
		pt2[2] -= 384;

		gi.trace(&trace, pt1, vec3_origin, vec3_origin, pt2, self, MASK_MONSTERSOLID);

		if(trace.fraction < 1 && !trace.allsolid && !trace.startsolid)
			if(!strncmp(trace.ent.classname, "func_plat", 8))
				plat = trace.ent;
	}

	// if we've found a plat, trigger it.
	if (plat && plat.use)
	{
		if (playerPosition == 1)
		{
			if((self.groundentity == plat && plat.moveinfo.state == STATE_BOTTOM) ||
				(self.groundentity != plat && plat.moveinfo.state == STATE_TOP))
			{
				plat.use (plat, self, self);
				return true;			
			}
		}
		else if(playerPosition == -1)
		{
			if((self.groundentity == plat && plat.moveinfo.state == STATE_TOP) ||
				(self.groundentity != plat && plat.moveinfo.state == STATE_BOTTOM))
			{
				plat.use (plat, self, self);
				return true;
			}
		}
	}

	return false;
}

bool(entity self) face_wall;

// blocked_checkjump
//	dist: how far they are trying to walk.
//  maxDown/maxUp: how far they'll ok a jump for. set to 0 to disable that direction.
bool(entity self, float dist, float maxDown, float maxUp) blocked_checkjump =
{
	int		playerPosition;
	trace_t		trace;
	vector		pt1, pt2;
	vector		forward, up;

	if(!self.enemy)
		return false;

	AngleVectors (self.s.angles, &forward, 0, &up);

	if(self.enemy.absmin[2] > (self.absmin[2] + 16))
		playerPosition = 1;
	else if(self.enemy.absmin[2] < (self.absmin[2] - 16))
		playerPosition = -1;
	else
		playerPosition = 0;

	if(playerPosition == -1 && maxDown)
	{
		// check to make sure we can even get to the spot we're going to "fall" from
		pt1 = self.s.origin + (forward * 48);
		gi.trace(&trace, self.s.origin, self.mins, self.maxs, pt1, self, MASK_MONSTERSOLID);

		if(trace.fraction < 1)
			return false;

		pt2 = pt1;
		pt2[2] = self.mins[2] - maxDown - 1;

		gi.trace(&trace, pt1, vec3_origin, vec3_origin, pt2, self, MASK_MONSTERSOLID | MASK_WATER);

		if(trace.fraction < 1 && !trace.allsolid && !trace.startsolid)
		{
			if((self.absmin[2] - trace.endpos[2]) >= 24 && trace.contents & MASK_SOLID)
			{
				if ((self.enemy.absmin[2] - trace.endpos[2]) > 32)
					return false;

				if(trace.plane.normal[2] < 0.9)
					return false;

				return true;
			}
		}
	}
	else if (playerPosition == 1 && maxUp)
	{
		pt1 = self.s.origin + (forward * 48);
		pt2 = pt1;
		pt1[2] = self.absmax[2] + maxUp;

		gi.trace(&trace, pt1, vec3_origin, vec3_origin, pt2, self, MASK_MONSTERSOLID | MASK_WATER);

		if(trace.fraction < 1 && !trace.allsolid && !trace.startsolid)
		{
			if((trace.endpos[2] - self.absmin[2]) <= maxUp && trace.contents & MASK_SOLID)
			{
				face_wall(self);
				return true;
			}
		}
	}

	return false;
}

// *************************
// HINT PATHS
// *************************

const int HINT_ENDPOINT		= 0x0001;
const int MAX_HINT_CHAINS	= 100;

static int	hint_paths_present;
static entity	hint_path_start[MAX_HINT_CHAINS];
static int	num_hint_paths;

// =============
// hintpath_other_end - given one endpoint of a hintpath, returns the other end.
// =============
static entity(entity ent) hintpath_other_end =
{
	entity	e;
	entity	last;
	.string	field;

	if(ent.target)		// starting point
	{
		last = world;
		field = targetname;
		e = G_Find(null_entity, field, ent.target);
		while (e != null_entity)
		{
			last = e;
			if(!e.target)
				break;
			e = G_Find(null_entity, field, e.target);
		}
	}
	else				// end point
	{
		last = world;
		field = target;
		e = G_Find(null_entity, field, ent.targetname);
		while(e != null_entity)
		{
			last = e;
			if(!e.targetname)
				break;
			e = G_Find(null_entity, field, e.targetname);
		}
	}

	if (!(last.spawnflags & HINT_ENDPOINT))
		return world;

	return last;
}

// =============
// hintpath_go - starts a monster (self) moving towards the hintpath (point)
//		disables all contrary AI flags.
// =============
void(entity self, entity point) hintpath_go =
{
	vector	dir;
	vector	angles;

	dir = point.s.origin - self.s.origin;
	angles = vectoangles(dir);

	self.ideal_yaw = angles[YAW];
	self.goalentity = self.movetarget = point;
	self.monsterinfo.pause_framenum = 0;
	self.monsterinfo.aiflags |= AI_HINT_PATH;
	self.monsterinfo.aiflags &= ~(AI_SOUND_TARGET | AI_PURSUIT_LAST_SEEN | AI_PURSUE_NEXT | AI_PURSUE_TEMP);
	// run for it
	self.monsterinfo.search_framenum = level.framenum;
	self.monsterinfo.run (self);
}

void(entity self) HuntTarget;

bool(entity self) has_valid_enemy =
{
	return self.enemy && self.enemy.inuse && self.enemy.health;
}

// =============
// hintpath_stop - bails a monster out of following hint paths
// =============
void(entity self) hintpath_stop =
{
	self.goalentity = 0;
	self.movetarget = 0;
	self.monsterinfo.last_hint_framenum = level.framenum;
	self.monsterinfo.goal_hint = 0;
	self.monsterinfo.aiflags &= ~AI_HINT_PATH;
	if (has_valid_enemy(self))
	{
		// if we can see our target, go nuts
		if (visible(self, self.enemy))
		{
			FoundTarget (self);
			return;
		}
		// otherwise, keep chasing
		HuntTarget (self);
		return;
	}
	// if our enemy is no longer valid, forget about our enemy and go into stand
	self.enemy = 0;
	// we need the pausetime otherwise the stand code
	// will just revert to walking with no target and
	// the monsters will wonder around aimlessly trying
	// to hunt the world entity
	self.monsterinfo.pause_framenum = INT_MAX;
	self.monsterinfo.stand (self);
}

// =============
// monsterlost_checkhint - the monster (self) will check around for valid hintpaths.
//		a valid hintpath is one where the two endpoints can see both the monster
//		and the monster's enemy. if only one person is visible from the endpoints,
//		it will not go for it.
// =============
bool(entity self) monsterlost_checkhint =
{
	entity		e, monster_pathchain, target_pathchain, checkpoint = 0;
	entity		closest;
	float		closest_range = 1000000;
	entity		start, destination;
	.string		field;
	int		count1=0, count2=0, count3=0, count4=0, count5=0;
	float		r;
	int		i;
	bool		hint_path_represented[MAX_HINT_CHAINS] = { 0 };

	// if there are no hint paths on this map, exit immediately.
	if(!hint_paths_present)
		return false;

	if(!self.enemy)
		return false;

	if (self.monsterinfo.aiflags & AI_STAND_GROUND)
		return false;
	
	if (self.classname == "monster_turret")
		return false;

	monster_pathchain = 0;

	field = classname;

	// find all the hint_paths.
	// FIXME - can we not do this every time?
	for (i=0; i < num_hint_paths; i++)
	{
		e = hint_path_start[i];
		while(e)
		{
			count1++;
			if (e.monster_hint_chain)
				e.monster_hint_chain = 0;

			if (monster_pathchain)
			{
				checkpoint.monster_hint_chain = e;
				checkpoint = e;
			}
			else
			{
				monster_pathchain = e;
				checkpoint = e;
			}

			e = e.hint_chain;
		}
	}
	
	// filter them by distance and visibility to the monster
	e = monster_pathchain;
	checkpoint = 0;
	while (e)
	{
		r = realrange (self, e);

		if (r > 512)
		{
			count2++;
			if (checkpoint)
			{
				checkpoint.monster_hint_chain = e.monster_hint_chain;
				e.monster_hint_chain = 0;
				e = checkpoint.monster_hint_chain;
				continue;
			}
			else
			{
				// use checkpoint as temp pointer
				checkpoint = e;
				e = e.monster_hint_chain;
				checkpoint.monster_hint_chain = 0;
				// and clear it again
				checkpoint = 0;
				// since we have yet to find a valid one (or else checkpoint would be set) move the
				// start of monster_pathchain
				monster_pathchain = e;
				continue;
			}
		}
		if (!visible(self, e))
		{
			count4++;
			if (checkpoint)
			{
				checkpoint.monster_hint_chain = e.monster_hint_chain;
				e.monster_hint_chain = 0;
				e = checkpoint.monster_hint_chain;
				continue;
			}
			else
			{
				// use checkpoint as temp pointer
				checkpoint = e;
				e = e.monster_hint_chain;
				checkpoint.monster_hint_chain = 0;
				// and clear it again
				checkpoint = 0;
				// since we have yet to find a valid one (or else checkpoint would be set) move the
				// start of monster_pathchain
				monster_pathchain = e;
				continue;
			}
		}

		count5++;
		checkpoint = e;
		e = e.monster_hint_chain;
	}

	// at this point, we have a list of all of the eligible hint nodes for the monster
	// we now take them, figure out what hint chains they're on, and traverse down those chains,
	// seeing whether any can see the player
	//
	// first, we figure out which hint chains we have represented in monster_pathchain
	if (count5 == 0)
		return false;

	for (i=0; i < num_hint_paths; i++)
		hint_path_represented[i] = false;

	e = monster_pathchain;
	checkpoint = 0;
	while (e)
	{
		if ((e.hint_chain_id < 0) || (e.hint_chain_id > num_hint_paths))
			return false;

		hint_path_represented[e.hint_chain_id] = true;
		e = e.monster_hint_chain;
	}

	count1 = 0;
	count2 = 0;
	count3 = 0;
	count4 = 0;
	count5 = 0;

	// now, build the target_pathchain which contains all of the hint_path nodes we need to check for
	// validity (within range, visibility)
	target_pathchain = 0;
	checkpoint = 0;
	for (i=0; i < num_hint_paths; i++)
	{
		// if this hint chain is represented in the monster_hint_chain, add all of it's nodes to the target_pathchain
		// for validity checking
		if (hint_path_represented[i])
		{
			e = hint_path_start[i];
			while (e)
			{
				if (target_pathchain)
				{
					checkpoint.target_hint_chain = e;
					checkpoint = e;
				}
				else
				{
					target_pathchain = e;
					checkpoint = e;
				}
				e = e.hint_chain;
			}
		}
	}

	// target_pathchain is a list of all of the hint_path nodes we need to check for validity relative to the target
	e = target_pathchain;
	checkpoint = 0;
	while (e)
	{
		r = realrange (self.enemy, e);

		if (r > 512)
		{
			count2++;

			if (checkpoint)
			{
				checkpoint.target_hint_chain = e.target_hint_chain;
				e.target_hint_chain = 0;
				e = checkpoint.target_hint_chain;
				continue;
			}
			else
			{
				// use checkpoint as temp pointer
				checkpoint = e;
				e = e.target_hint_chain;
				checkpoint.target_hint_chain = 0;
				// and clear it again
				checkpoint = 0;
				target_pathchain = e;
				continue;
			}
		}
		if (!visible(self.enemy, e))
		{
			count4++;

			if (checkpoint)
			{
				checkpoint.target_hint_chain = e.target_hint_chain;
				e.target_hint_chain = 0;
				e = checkpoint.target_hint_chain;
				continue;
			}
			else
			{
				// use checkpoint as temp pointer
				checkpoint = e;
				e = e.target_hint_chain;
				checkpoint.target_hint_chain = 0;
				// and clear it again
				checkpoint = 0;
				target_pathchain = e;
				continue;
			}
		}

		count5++;
		checkpoint = e;
		e = e.target_hint_chain;
	}
	
	// at this point we should have:
	// monster_pathchain - a list of "monster valid" hint_path nodes linked together by monster_hint_chain
	// target_pathcain - a list of "target valid" hint_path nodes linked together by target_hint_chain.  these
	//                   are filtered such that only nodes which are on the same chain as "monster valid" nodes
	//
	// Now, we figure out which "monster valid" node we want to use
	// 
	// To do this, we first off make sure we have some target nodes.  If we don't, there are no valid hint_path nodes
	// for us to take
	//
	// If we have some, we filter all of our "monster valid" nodes by which ones have "target valid" nodes on them
	//
	// Once this filter is finished, we select the closest "monster valid" node, and go to it.

	if (count5 == 0)
		return false;

	// reuse the hint_chain_represented array, this time to see which chains are represented by the target
	for (i=0; i < num_hint_paths; i++)
		hint_path_represented[i] = false;

	e = target_pathchain;
	checkpoint = 0;
	while (e)
	{
		if ((e.hint_chain_id < 0) || (e.hint_chain_id > num_hint_paths))
			return false;

		hint_path_represented[e.hint_chain_id] = true;
		e = e.target_hint_chain;
	}
	
	// traverse the monster_pathchain - if the hint_node isn't represented in the "target valid" chain list, 
	// remove it
	// if it is on the list, check it for range from the monster.  If the range is the closest, keep it
	//
	closest = 0;
	e = monster_pathchain;
	while (e)
	{
		if (!(hint_path_represented[e.hint_chain_id]))
		{
			checkpoint = e.monster_hint_chain;
			e.monster_hint_chain = 0;
			e = checkpoint;
			continue;
		}
		r = realrange(self, e);
		if (r < closest_range)
			closest = e;
		e = e.monster_hint_chain;
	}

	if (!closest)
		return false;

	start = closest;
	// now we know which one is the closest to the monster .. this is the one the monster will go to
	// we need to finally determine what the DESTINATION node is for the monster .. walk down the hint_chain,
	// and find the closest one to the player

	closest = 0;
	closest_range = 10000000f;
	e = target_pathchain;
	while (e)
	{
		if (start.hint_chain_id == e.hint_chain_id)
		{
			r = realrange(self, e);
			if (r < closest_range)
				closest = e;
		}
		e = e.target_hint_chain;
	}

	if (!closest)
		return false;
	
	destination = closest;

	self.monsterinfo.goal_hint = destination;
	hintpath_go(self, start);
	return true;
}

//
// Path code
//

// =============
// hint_path_touch - someone's touched the hint_path
// =============
static void(entity self, entity other, cplane_t plane, csurface_t surf) hint_path_touch =
{
	entity	e, goal, next = 0;
	bool	goalFound = false;

	// make sure we're the target of it's obsession
	if(other.movetarget == self)
	{
		goal = other.monsterinfo.goal_hint;
		
		// if the monster is where he wants to be
		if (goal == self)
		{
			hintpath_stop (other);
			return;
		}
		else
		{
			// if we aren't, figure out which way we want to go
			e = hint_path_start[self.hint_chain_id];
			while (e)
			{
				// if we get up to ourselves on the hint chain, we're going down it
				if (e == self)
				{
					next = e.hint_chain;
					break;
				}
				if (e == goal)
					goalFound = true;
				// if we get to where the next link on the chain is this hint_path and have found the goal on the way
				// we're going upstream, so remember who the previous link is
				if ((e.hint_chain == self) && goalFound)
				{
					next = e;
					break;
				}
				e = e.hint_chain;
			}
		}

		// if we couldn't find it, have the monster go back to normal hunting.
		if(!next)
		{
			hintpath_stop(other);
			return;
		}

		hintpath_go(other, next);

		// have the monster freeze if the hint path we just touched has a wait time
		// on it, for example, when riding a plat.
		if(self.wait)
			other.nextthink = level.framenum + (int)(self.wait * BASE_FRAMERATE);
	}
}

/*QUAKED hint_path (.5 .3 0) (-8 -8 -8) (8 8 8) END
Target: next hint path

END - set this flag on the endpoints of each hintpath.

"wait" - set this if you want the monster to freeze when they touch this hintpath
*/
API_FUNC static void(entity self) SP_hint_path =
{
	if (deathmatch.intVal)
	{
		G_FreeEdict(self);
		return;
	}

	if (!self.targetname && !self.target)
	{
		gi.dprintf ("unlinked hint_path at %s\n", vtos(self.s.origin));
		G_FreeEdict (self);
		return;
	}

	self.solid = SOLID_TRIGGER;
	self.touch = hint_path_touch;
	self.mins = '-8 -8 -8';
	self.maxs = '8 8 8';
	self.svflags |= SVF_NOCLIENT;
	gi.linkentity (self);
}

// ============
// InitHintPaths - Called by InitGame (g_save) to enable quick exits if valid
// ============
void() InitHintPaths =
{
	entity	e, current;
	.string	field;
	int	i, count2;
	bool	errors = false;

	hint_paths_present = 0;
	
	// check all the hint_paths.
	field = classname;
	e = G_Find(null_entity, field, "hint_path");
	if (e != null_entity)
		hint_paths_present = 1;
	else
		return;

	memclear (hint_path_start, MAX_HINT_CHAINS*sizeof(entity));
	num_hint_paths = 0;
	while(e != null_entity)
	{
		if(e.spawnflags & HINT_ENDPOINT)
		{
			if (e.target) // start point
			{
				if (e.targetname) // this is a bad end, ignore it
				{
					gi.dprintf ("Hint path at %s marked as endpoint with both target (%s) and targetname (%s)\n",
						vtos (e.s.origin), e.target, e.targetname);
					errors = true;
				}
				else
				{
					if (num_hint_paths >= MAX_HINT_CHAINS)
						break;

					hint_path_start[num_hint_paths++] = e;
				}
			}
		}
		e = G_Find(e, field, "hint_path");
	}

	field = targetname;
	for (i=0; i< num_hint_paths; i++)
	{
		count2 = 1;
		current = hint_path_start[i];
		current.hint_chain_id = i;

		e = G_Find(null_entity, field, current.target);
		if (G_Find(e, field, current.target) != null_entity)
		{
			gi.dprintf ("\nForked hint path at %s detected for chain %d, target %s\n", 
				vtos (current.s.origin), num_hint_paths, current.target);
			hint_path_start[i].hint_chain = 0;
			count2 = 0;
			errors = true;
			continue;
		}
		while (e)
		{
			if (e.hint_chain)
			{
				gi.dprintf ("\nCircular hint path at %s detected for chain %d, targetname %s\n", 
					vtos (e.s.origin), num_hint_paths, e.targetname);
				hint_path_start[i].hint_chain = 0;
				count2 = 0;
				errors = true;
				break;
			}
			count2++;
			current.hint_chain = e;
			current = e;
			current.hint_chain_id = i;

			if (!current.target)
				break;
			e = G_Find(null_entity, field, current.target);
			if (G_Find(e, field, current.target) != null_entity)
			{
				gi.dprintf ("\nForked hint path at %s detected for chain %d, target %s\n", 
					vtos (current.s.origin), num_hint_paths, current.target);
				hint_path_start[i].hint_chain = 0;
				count2 = 0;
				break;
			}
		}
	}
}

// *****************************
//	MISCELLANEOUS STUFF
// *****************************

// PMM - inback
// use to see if opponent is behind you (not to side)
// if it looks a lot like infront, well, there's a reason
bool(entity self, entity other) inback =
{
	vector	vec;
	float	dot;
	vector	forward;
	
	AngleVectors (self.s.angles, &forward, 0, 0);
	vec = other.s.origin - self.s.origin;
	VectorNormalize (vec);
	dot = vec * forward;

	return dot < -0.3;
}

// from move.qc
void(entity ent) M_ChangeYaw;

bool(entity self) face_wall =
{
	vector	pt;
	vector	forward;
	vector	ang;
	trace_t	tr;

	AngleVectors (self.s.angles, &forward, 0, 0);
	pt = self.s.origin + (forward * 64);
	gi.trace(&tr, self.s.origin, vec3_origin, vec3_origin, pt, self, MASK_MONSTERSOLID);
	if(tr.fraction < 1 && !tr.allsolid && !tr.startsolid)
	{
		ang = vectoangles(tr.plane.normal);
		self.ideal_yaw = ang[YAW] + 180f;
		if(self.ideal_yaw > 360)
			self.ideal_yaw -= 360;

		M_ChangeYaw(self);
		return true;
	}

	return false;
}

//
// Monster "Bad" Areas
// 
static void(entity self, entity other, cplane_t plane, csurface_t surf) badarea_touch =
{
};

entity(vector cmins, vector cmaxs, int lifespan_frames, entity cowner) SpawnBadArea =
{
	entity	badarea;
	vector	corigin;
	
	corigin = cmins + cmaxs;
	corigin *= 0.5f;

	cmaxs -= corigin;
	cmins -= corigin;

	badarea = G_Spawn();
	badarea.s.origin = corigin;
	badarea.maxs = cmaxs;
	badarea.mins = cmins;
	badarea.movetype = MOVETYPE_NONE;
	badarea.solid = SOLID_TRIGGER;
	badarea.classname = "bad_area";
	badarea.touch = badarea_touch;
	gi.linkentity (badarea);

	if(lifespan_frames)
	{
		badarea.think = G_FreeEdict;
		badarea.nextthink = level.framenum + lifespan_frames;
	}

	if(cowner)
		badarea.owner = cowner;

	return badarea;
}

// CheckForBadArea
//		This is a customized version of G_TouchTriggers that will check
//		for bad area triggers and return them if they're touched.
entity(entity ent) CheckForBadArea =
{
	int		i;
	entity		hit;
	vector		cmins, cmaxs;

	cmins = ent.s.origin + ent.mins;
	cmaxs = ent.s.origin + ent.maxs;

	entity_set_t entities = gi.BoxEdicts (cmins, cmaxs, MAX_EDICTS, AREA_TRIGGERS);

	// be careful, it is possible to have an entity in this
	// list removed before we get to it (killtriggered)
	for (i = 0; i < entities.length; i++)
	{
		hit = entities[i];
		if (!hit.inuse)
			continue;
		if (hit.touch == badarea_touch)
		{
			entity_set_free(entities);
			return hit;
		}
	}
	
	entity_set_free(entities);
	return 0;
}

const float TESLA_DAMAGE_RADIUS		= 128;

bool(entity self, entity tesla) MarkTeslaArea =
{
	vector	cmins, cmaxs;
	entity	e, tail, area;

	if(!tesla || !self)
		return false;

	area = 0;

	// make sure this tesla doesn't have a bad area around it already...
	e = tesla.teamchain;
	tail = tesla;
	while (e)
	{
		tail = tail.teamchain;

		if(e.classname == "bad_area")
			return false;

		e = e.teamchain;
	}

	// see if we can grab the trigger directly
	if(tesla.teamchain && tesla.teamchain.inuse)
	{
		entity trigger = tesla.teamchain;

		cmins = trigger.absmin;
		cmaxs = trigger.absmax;

		if (tesla.air_finished_framenum)
			area = SpawnBadArea (cmins, cmaxs, tesla.air_finished_framenum, tesla);
		else
			area = SpawnBadArea (cmins, cmaxs, tesla.nextthink, tesla);
	}
	// otherwise we just guess at how long it'll last.
	else
	{
	
		cmins = [ -TESLA_DAMAGE_RADIUS, -TESLA_DAMAGE_RADIUS, tesla.mins[2] ];
		cmaxs = [ TESLA_DAMAGE_RADIUS, TESLA_DAMAGE_RADIUS, TESLA_DAMAGE_RADIUS ];

		area = SpawnBadArea(cmins, cmaxs, 30 * BASE_FRAMERATE, tesla);
	}

	if(area)
		tail.teamchain = area;

	return true;
}

// predictive calculator
// target is who you want to shoot
// start is where the shot comes from
// bolt_speed is how fast the shot is
// eye_height is a boolean to say whether or not to adjust to targets eye_height
// offset is how much time to miss by
// aimdir is the resulting aim direction (pass in NULL if you don't want it)
// aimpoint is the resulting aimpoint (pass in NULL if don't want it)
void(entity target, vector start, float bolt_speed, bool eye_height, float offset, vector *aimdir, vector *aimpoint) PredictAim =
{
	vector	dir, vec;
	float	dist, time;

	if (!target || !target.inuse)
	{
		if (aimdir)
			*aimdir = vec3_origin;
		return;
	}

	dir = target.s.origin - start;
	if (eye_height)
		dir[2] += target.viewheight;

	dist = VectorLength(dir);
	time = dist / bolt_speed;

	vec = target.s.origin + (target.velocity * (time - offset));

	if (eye_height)
		vec[2] += target.viewheight;

	if (aimdir)
	{
		*aimdir = vec - start;
		VectorNormalize (*aimdir);
	}
	
	if (aimpoint)
		*aimpoint = vec;
}


bool(entity self, entity other) below =
{
	vector	vec;
	float	dot;
	static const vector down = '0 0 -1';
	
	vec = other.s.origin - self.s.origin;
	VectorNormalize (vec);
	dot = vec * down;

	return dot > 0.95;  // 18 degree arc below
}

void(entity self) monster_done_dodge =
{
	self.monsterinfo.aiflags &= ~AI_DODGING;
}

//
// New dodge code
//
void(entity self, entity attacker, float eta, trace_t *tr) M_MonsterDodge =
{
	float	r = random();
	float	height;
	bool	ducker = false, dodger = false;

	// this needs to be here since this can be called after the monster has "died"
	if (self.health < 1)
		return;

	if (self.monsterinfo.duck && self.monsterinfo.unduck)
		ducker = true;
	if (self.monsterinfo.sidestep && !(self.monsterinfo.aiflags & AI_STAND_GROUND))
		dodger = true;

	if (!ducker && !dodger)
		return;

	if (!self.enemy)
	{
		self.enemy = attacker;
		FoundTarget (self);
	}

	// PMM - don't bother if it's going to hit anyway; fix for weird in-your-face etas (I was
	// seeing numbers like 13 and 14)
	if (eta < 0.1 || eta > 5)
		return;

	// skill level determination..
	if (r > (0.25 * (skill.intVal + 1)))
		return;

	if (ducker)
	{
		height = self.absmax[2] - 32 - 1;  // the -1 is because the absmax is s.origin + maxs + 1

		// FIXME, make smarter
		// if we only duck, and ducking won't help or we're already ducking, do nothing
		//
		// need to add monsterinfo.abort_duck() and monsterinfo.next_duck_time
		if (!dodger && (tr.endpos[2] <= height || (self.monsterinfo.aiflags & AI_DUCKED)))
			return;
	}
	else
		height = self.absmax[2];

	if (dodger)
	{
		// if we're already dodging, just finish the sequence, i.e. don't do anything else
		if (self.monsterinfo.aiflags & AI_DODGING)
			return;

		// if we're ducking already, or the shot is at our knees
		if (tr.endpos[2] <= height || (self.monsterinfo.aiflags & AI_DUCKED))
		{
			vector right, diff;

			AngleVectors (self.s.angles, 0, &right, 0);
			diff = tr.endpos - self.s.origin;

			if (right * diff < 0)
				self.monsterinfo.lefty = 0;
			else
				self.monsterinfo.lefty = 1;
	
			// if we are currently ducked, unduck

			if (ducker && (self.monsterinfo.aiflags & AI_DUCKED))
				self.monsterinfo.unduck(self);

			self.monsterinfo.aiflags |= AI_DODGING;
			self.monsterinfo.attack_state = AS_SLIDING;

			// call the monster specific code here
			self.monsterinfo.sidestep (self);
			return;
		}
	}

	if (ducker)
	{
		if (self.monsterinfo.next_duck_framenum > level.framenum)
			return;

		monster_done_dodge (self);
		// set this prematurely; it doesn't hurt, and prevents extra iterations
		self.monsterinfo.aiflags |= AI_DUCKED;

		self.monsterinfo.duck (self, eta);
	}
}

void(entity self) monster_duck_down =
{
	self.monsterinfo.aiflags |= AI_DUCKED;
	self.monsterinfo.aiflags &= ~AI_HOLD_FRAME;

	self.maxs[2] = self.monsterinfo.base_height - 32;
	self.takedamage = DAMAGE_YES;
	if (self.monsterinfo.duck_wait_framenum < level.framenum)
		self.monsterinfo.duck_wait_framenum = level.framenum + (1 * BASE_FRAMERATE);
	gi.linkentity (self);
}

void(entity self) monster_duck_hold =
{
	if (level.framenum >= self.monsterinfo.duck_wait_framenum)
		self.monsterinfo.aiflags &= ~AI_HOLD_FRAME;
	else
		self.monsterinfo.aiflags |= AI_HOLD_FRAME;
}

void(entity self) monster_duck_up =
{
	self.monsterinfo.aiflags &= ~AI_DUCKED;
	self.maxs[2] = self.monsterinfo.base_height;
	self.takedamage = DAMAGE_AIM;
	self.monsterinfo.next_duck_framenum = level.framenum + (int)(DUCK_INTERVAL * BASE_FRAMERATE);
	gi.linkentity (self);
}

//=========================

void(entity self, entity tesla) TargetTesla =
{
	if (!self || !tesla)
		return;

	// PMM - medic bails on healing things
	if (self.monsterinfo.aiflags & AI_MEDIC)
	{
		if (self.enemy)
			cleanupHealTarget(self.enemy);
		self.monsterinfo.aiflags &= ~AI_MEDIC;
	}

	// store the player enemy in case we lose track of him.
	if (self.enemy && self.enemy.is_client)
		self.monsterinfo.last_player_enemy = self.enemy;

	if(self.enemy != tesla)
	{
		self.oldenemy = self.enemy;
		self.enemy = tesla;
		if(self.monsterinfo.attack)
		{
			if (self.health <= 0)
				return;

			self.monsterinfo.attack(self);
		}
		else
			FoundTarget(self);
	}
}

// this returns a randomly selected coop player who is visible to self
// returns NULL if bad

entity(entity self) PickCoopTarget =
{
	// no more than 4 players in coop, so..
	entity	targets[4] = { 0 };
	int	num_targets = 0, targetID;
	entity	ent;
	int	player;

	// if we're not in coop, this is a noop
	if (!coop.intVal)
		return world;

	memclear(targets, 4 * sizeof(entity));

	for (player = 1; player <= game.maxclients; player++)
	{
		ent = itoe(player);
		if (!ent.inuse)
			continue;
		if (!ent.is_client)
			continue;
		if (visible(self, ent))
			targets[num_targets++] = ent;
	}

	if (!num_targets)
		return world;

	// get a number from 0 to (num_targets-1)
	targetID = Q_rand() % num_targets;
	
	// just in case we got a 1.0 from random
	if (targetID == num_targets)
		targetID--;

	return targets[targetID];
}

// only meant to be used in coop
int CountPlayers (void)
{
	entity	ent;
	int	count = 0;
	int	player;

	// if we're not in coop, this is a noop
	if (!coop.intVal)
		return 1;

	for (player = 1; player <= game.maxclients; player++)
	{
		ent = itoe(player);
		if (!ent.inuse)
			continue;
		if (!ent.is_client)
			continue;
		count++;
	}

	return count;
}

//*******************
// JUMPING AIDS
//*******************

/*inline*/ void(entity self) monster_jump_start =
{
	self.timestamp = level.framenum;
}

/*inline*/ bool(entity self) monster_jump_finished =
{
	return (level.framenum - self.timestamp) > (3 * BASE_FRAMERATE);
}

// MOVE STUFF

bool(entity self, entity bad, vector move) IsBadAhead =
{
	vector	dir;
	vector	forward;
	float	dp_bad, dp_move;

	dir = bad.s.origin - self.s.origin;
	VectorNormalize (dir);
	AngleVectors (self.s.angles, &forward, 0, 0);
	dp_bad = forward * dir;

	VectorNormalize (move);
	AngleVectors (self.s.angles, &forward, 0, 0);
	dp_move = forward * move;

	if (dp_bad < 0 && dp_move < 0)
		return true;
	if (dp_bad > 0 && dp_move > 0)
		return true;

	return false;
}

#endif