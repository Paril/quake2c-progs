#ifdef SINGLE_PLAYER

/*
==============================================================================

PLAYER TRAIL

==============================================================================

This is a circular list containing the a list of points of where
the player has been recently.  It is used by monsters for pursuit.

.origin     the spot
.owner      forward link
.aiment     backward link
*/
const int TRAIL_LENGTH	= 8;

PROGS_LOCAL static entity	trail[TRAIL_LENGTH];
PROGS_LOCAL static int		trail_head;
PROGS_LOCAL static var bool	trail_active = false;

#define NEXT(n)     (((n) + 1) & (TRAIL_LENGTH - 1))
#define PREV(n)     (((n) - 1) & (TRAIL_LENGTH - 1))

void() PlayerTrail_Init =
{
	int     n;

	if (deathmatch.intVal)
		return;

	for (n = 0; n < TRAIL_LENGTH; n++)
	{
		trail[n] = G_Spawn();
		trail[n].classname = "player_trail";
	}

	trail_head = 0;
	trail_active = true;
}


void(vector spot) PlayerTrail_Add =
{
	vector	temp;

	if (!trail_active)
		return;

	trail[trail_head].s.origin = spot;
	trail[trail_head].timestamp = level.framenum;

	temp = spot - trail[PREV(trail_head)].s.origin;
	trail[trail_head].s.angles[YAW] = vectoyaw(temp);

	trail_head = NEXT(trail_head);
}


void(vector spot) PlayerTrail_New =
{
	if (!trail_active)
		return;

	PlayerTrail_Init();
	PlayerTrail_Add(spot);
}


entity(entity self) PlayerTrail_PickFirst =
{
	int	marker;
	int	n;

	if (!trail_active)
		return world;

	for (marker = trail_head, n = TRAIL_LENGTH; n; n--)
	{
		if (trail[marker].timestamp <= self.monsterinfo.trail_framenum)
			marker = NEXT(marker);
		else
			break;
	}

	if (visible(self, trail[marker]))
		return trail[marker];

	if (visible(self, trail[PREV(marker)]))
		return trail[PREV(marker)];

	return trail[marker];
}

entity(entity self) PlayerTrail_PickNext =
{
	int	marker;
	int	n;

	if (!trail_active)
		return world;

	for (marker = trail_head, n = TRAIL_LENGTH; n; n--) {
		if (trail[marker].timestamp <= self.monsterinfo.trail_framenum)
			marker = NEXT(marker);
		else
			break;
	}

	return trail[marker];
}

entity() PlayerTrail_LastSpot =
{
	return trail[PREV(trail_head)];
}

#endif