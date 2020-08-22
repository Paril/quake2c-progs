const vector vec3_origin = '0 0 0';

enum : int { PITCH, YAW, ROLL };

inline float(vector v) VectorLengthSquared =
{
	return v * v;
}

inline float(vector v) VectorLength =
{
	return sqrt(VectorLengthSquared(v));
}

INLINE float(inout vector v) VectorNormalize =
{
	float length = VectorLength(v);
	
	if (length)
		v *= 1.f / length;

	return length;
}

/*
==================
ClipVelocity

Slide off of the impacting object
==================
*/

// This constant is used for how steep a ground plane is for
// bouncing things.
const float STOP_EPSILON = 0.1f;

vector(vector in, vector normal, float overbounce) ClipVelocity =
{
	float backoff = (in * normal) * overbounce;
	vector out = vec3_origin;

	for (int i = 0; i < 3; i++)
	{
		float change = normal[i]*backoff;
		out[i] = in[i] - change;
		if (out[i] > -STOP_EPSILON && out[i] < STOP_EPSILON)
			out[i] = 0;
	}
	
	return out;
}

void(vector angles, vector *forward, vector *right, vector *up) AngleVectors =
{
	float angle = DEG2RAD(angles[YAW]);
	float sy = sin(angle);
	float cy = cos(angle);
	float angle = DEG2RAD(angles[PITCH]);
	float sp = sin(angle);
	float cp = cos(angle);

	if (forward)
		*forward = [ cp * cy, cp * sy, -sp ];

	if (right || up)
	{
		float angle = DEG2RAD(angles[ROLL]);
		float sr = sin(angle);
		float cr = cos(angle);

		if (right)
			*right = [
				(-1 * sr * sp * cy + -1 * cr * -sy),
				(-1 * sr * sp * sy + -1 * cr * cy),
				-1 * sr * cp
			];
		if (up)
			*up = [
				(cr * sp * cy + -sr * -sy),
				(cr * sp * sy + -sr * cy),
				cr * cp
			];
	}
}

vector vectoangles(vector value1)
{
	if (value1[1] == 0 && value1[0] == 0)
	{
		if (value1[2] > 0)
			return [ -90f, 0, 0 ];

		return [ -270f, 0, 0 ];
	}

	float yaw;

	if (value1[0])
	{
		yaw = RAD2DEG(atan2(value1[1], value1[0]));

		if (yaw < 0)
			yaw += 360;
	}
	else if (value1[1] > 0)
		yaw = 90f;
	else
		yaw = 270f;

	const float forward = sqrt(value1[0]*value1[0] + value1[1]*value1[1]);
	float pitch = RAD2DEG(atan2(value1[2], forward));
	if (pitch < 0)
		pitch += 360;

	return [ -pitch, yaw, 0 ];
}

float(vector vec) vectoyaw =
{
	if (vec.x == 0)
	{
		if (vec.y > 0)
			return 90f;
		else if (vec.y < 0)
			return -90f;

		return 0;
	}

	float yaw = RAD2DEG(atan2(vec.y, vec.x));

	if (yaw < 0)
		yaw += 360f;

	return yaw;
}

inline vector(vector v1, vector v2) CrossProduct =
{
	return [v1[1] * v2[2] - v1[2] * v2[1],
			v1[2] * v2[0] - v1[0] * v2[2],
			v1[0] * v2[1] - v1[1] * v2[0]];
}

inline void(vector v, inout vector mins, inout vector maxs) AddPointToBounds =
{
	mins[0] = minf(mins[0], v[0]);
	maxs[0] = maxf(maxs[0], v[0]);
	mins[1] = minf(mins[1], v[1]);
	maxs[1] = maxf(maxs[1], v[1]);
	mins[2] = minf(mins[2], v[2]);
	maxs[2] = maxf(maxs[2], v[2]);
}