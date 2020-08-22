#ifdef GROUND_ZERO

/* clean up heal targets for medic */
void(entity ent) M_SetEffects;

inline void(entity ent) cleanupHealTarget =
{
	ent.monsterinfo.healer = 0;
	ent.takedamage = true;
	ent.monsterinfo.aiflags &= ~AI_RESURRECTING;
	M_SetEffects (ent);
}

#endif