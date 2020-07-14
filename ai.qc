/*
=============
visible

returns 1 if the entity is visible to self, even if not infront ()
=============
*/
bool(entity self, entity other) visible =
{
	vector	spot1;
	vector	spot2;
	trace_t trace;
	
	VectorCopy(self->s.origin, spot1);
	spot1_z += self->viewheight;
	VectorCopy(other->s.origin, spot2);
	spot2_z += other->viewheight;
	trace_and_result(trace, spot1, vec3_origin, vec3_origin, spot2, self, MASK_OPAQUE);
	
	if (trace.fraction == 1.0f)
		return true;
	return false;
}