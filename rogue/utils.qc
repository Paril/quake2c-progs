#ifdef GROUND_ZERO

inline vector G_ProjectSource2 (vector point, vector distance, vector forward, vector right, vector up)
{
	return point + (forward * distance.x) + (right * distance.y) + (up * distance.z);
}

#endif