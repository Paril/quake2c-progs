const vector vec3_origin = '0 0 0';

enum : int { PITCH, YAW, ROLL };

inline float VectorLengthSquared(vector v)
{
	return v * v;
}

inline float VectorLength(vector v)
{
	return sqrtf(VectorLengthSquared(v));
}

float VectorNormalize(__inout vector v)
{
	float length = VectorLength(v);
	v *= 1.f / length;
	return length;
}

void(vector angles, vector *forward, vector *right, vector *up) AngleVectors =
{
	float	angle;
	float	sp, sy, cp, cy;

	angle = DEG2RAD(angles[YAW]);
	sy = sinf(angle);
	cy = cosf(angle);
	angle = DEG2RAD(angles[PITCH]);
	sp = sinf(angle);
	cp = cosf(angle);

	if (forward)
		*forward = [ cp * cy, cp * sy, -sp ];

	if (right || up)
	{
		angle = DEG2RAD(angles[ROLL]);
		float sr = sinf(angle);
		float cr = cosf(angle);

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
	float	yaw, pitch;
	
	if (value1[1] == 0 && value1[0] == 0)
	{
		yaw = 0;
		if (value1[2] > 0)
			pitch = 90f;
		else
			pitch = 270f;
	}
	else
	{
	// PMM - fixed to correct for pitch of 0
		if (value1[0])
		{
			yaw = RAD2DEG(atan2f(value1[1], value1[0]));

			if (yaw < 0)
				yaw += 360;
		}
		else if (value1[1] > 0)
			yaw = 90f;
		else
			yaw = 270f;

		const float forward = sqrtf(value1[0]*value1[0] + value1[1]*value1[1]);
		pitch = RAD2DEG(atan2f(value1[2], forward));
		if (pitch < 0)
			pitch += 360;
	}

	return [ -pitch, yaw, 0 ];
}

float(vector vec) vectoyaw =
{
	float   yaw;

	if (vec_x == 0) {
		yaw = 0;
		if (vec_y > 0)
			yaw = 90f;
		else if (vec_y < 0)
			yaw = -90f;
	} else {
		yaw = RAD2DEG(atan2f(vec_y, vec_x));
		if (yaw < 0)
			yaw += 360f;
	}

	return yaw;
}

inline vector(vector v1, vector v2) CrossProduct =
{
	return [	v1[1] * v2[2] - v1[2] * v2[1],
			v1[2] * v2[0] - v1[0] * v2[2],
			v1[0] * v2[1] - v1[1] * v2[0] ];
}

float min(float a, float b)
{
	return (a < b) ? a : b;
}

float max(float a, float b)
{
	return (a > b) ? a : b;
}

void AddPointToBounds(vector v, __inout vector mins, __inout vector maxs)
{
	mins[0] = min(mins[0], v[0]);
	maxs[0] = max(maxs[0], v[0]);
	mins[1] = min(mins[1], v[1]);
	maxs[1] = max(maxs[1], v[1]);
	mins[2] = min(mins[2], v[2]);
	maxs[2] = max(maxs[2], v[2]);
}

// Definitions, to make Q2->QC easier
#define VectorMA(a, s, b, c) (c) = (a) + ((b) * (s))
#define VectorCopy(a, b) (b) = (a)
#define VectorSubtract(a, b, c) (c) = (a) - (b)
#define VectorScale(a, b, c) (c) = (a) * (b)