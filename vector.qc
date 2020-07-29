const vector vec3_origin = '0 0 0';

enum : int { PITCH, YAW, ROLL };

/*inline*/ float VectorLengthSquared(vector v)
{
	return v * v;
}

/*inline*/ float VectorLength(vector v)
{
	return sqrtf(VectorLengthSquared(v));
}

/*inline*/ float VectorNormalize(__inout vector v)
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

vector ClipVelocity (vector in, vector normal, float overbounce)
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

	if (vec.x == 0) {
		yaw = 0;
		if (vec.y > 0)
			yaw = 90f;
		else if (vec.y < 0)
			yaw = -90f;
	} else {
		yaw = RAD2DEG(atan2f(vec.y, vec.x));
		if (yaw < 0)
			yaw += 360f;
	}

	return yaw;
}

/*inline*/ vector(vector v1, vector v2) CrossProduct =
{
	return [	v1[1] * v2[2] - v1[2] * v2[1],
			v1[2] * v2[0] - v1[0] * v2[2],
			v1[0] * v2[1] - v1[1] * v2[0] ];
}

void AddPointToBounds(vector v, __inout vector mins, __inout vector maxs)
{
	mins[0] = minf(mins[0], v[0]);
	maxs[0] = maxf(maxs[0], v[0]);
	mins[1] = minf(mins[1], v[1]);
	maxs[1] = maxf(maxs[1], v[1]);
	mins[2] = minf(mins[2], v[2]);
	maxs[2] = maxf(maxs[2], v[2]);
}

vector(vector p, vector normal) ProjectPointOnPlane =
{
	float d;
	vector n;
	float inv_denom = 1.0f / (normal * normal);

	d = (normal * p) * inv_denom;

	n[0] = normal[0] * inv_denom;
	n[1] = normal[1] * inv_denom;
	n[2] = normal[2] * inv_denom;

	return [ p[0] - d * n[0], p[1] - d * n[1], p[2] - d * n[2] ];
}

/*
** assumes "src" is normalized
*/
vector(vector src) PerpendicularVector =
{
	int	pos;
	int	i;
	float	minelem = 1.0f;
	vector	tempvec;

	/*
	** find the smallest magnitude axially aligned vector
	*/
	for ( pos = 0, i = 0; i < 3; i++ )
	{
		if ( fabsf( src[i] ) < minelem )
		{
			pos = i;
			minelem = fabsf( src[i] );
		}
	}
	tempvec[pos] = 1.0f;

	/*
	** project the point onto the plane defined by src
	*/
	vector dst = ProjectPointOnPlane(tempvec, src);

	/*
	** normalize the result
	*/
	VectorNormalize( dst );
	
	return dst;
}

/*
================
R_ConcatRotations
================
*/
void(vector *in1, vector *in2, vector *out) R_ConcatRotations =
{
	out[0][0] = in1[0][0] * in2[0][0] + in1[0][1] * in2[1][0] +
				in1[0][2] * in2[2][0];
	out[0][1] = in1[0][0] * in2[0][1] + in1[0][1] * in2[1][1] +
				in1[0][2] * in2[2][1];
	out[0][2] = in1[0][0] * in2[0][2] + in1[0][1] * in2[1][2] +
				in1[0][2] * in2[2][2];
	out[1][0] = in1[1][0] * in2[0][0] + in1[1][1] * in2[1][0] +
				in1[1][2] * in2[2][0];
	out[1][1] = in1[1][0] * in2[0][1] + in1[1][1] * in2[1][1] +
				in1[1][2] * in2[2][1];
	out[1][2] = in1[1][0] * in2[0][2] + in1[1][1] * in2[1][2] +
				in1[1][2] * in2[2][2];
	out[2][0] = in1[2][0] * in2[0][0] + in1[2][1] * in2[1][0] +
				in1[2][2] * in2[2][0];
	out[2][1] = in1[2][0] * in2[0][1] + in1[2][1] * in2[1][1] +
				in1[2][2] * in2[2][1];
	out[2][2] = in1[2][0] * in2[0][2] + in1[2][1] * in2[1][2] +
				in1[2][2] * in2[2][2];
}

vector(vector dir, vector point, float degrees) RotatePointAroundVector =
{
	vector	m[3];
	vector	im[3];
	vector	zrot[3];
	vector	tmpmat[3];
	vector	rot[3];
	vector	vr, vup, vf;

	vf[0] = dir[0];
	vf[1] = dir[1];
	vf[2] = dir[2];

	vr = PerpendicularVector(dir);
	vup = CrossProduct(vr, vf);

	m[0][0] = vr[0];
	m[1][0] = vr[1];
	m[2][0] = vr[2];

	m[0][1] = vup[0];
	m[1][1] = vup[1];
	m[2][1] = vup[2];

	m[0][2] = vf[0];
	m[1][2] = vf[1];
	m[2][2] = vf[2];
	
	memcpy(&im[0], &m[0], sizeof(im));

	im[0][1] = m[1][0];
	im[0][2] = m[2][0];
	im[1][0] = m[0][1];
	im[1][2] = m[2][1];
	im[2][0] = m[0][2];
	im[2][1] = m[1][2];

	zrot[0][0] = zrot[1][1] = zrot[2][2] = 1.0f;

	zrot[0][0] = cosf( DEG2RAD( degrees ) );
	zrot[0][1] = sinf( DEG2RAD( degrees ) );
	zrot[1][0] = -sinf( DEG2RAD( degrees ) );
	zrot[1][1] = cosf( DEG2RAD( degrees ) );

	R_ConcatRotations( m, zrot, tmpmat );
	R_ConcatRotations( tmpmat, im, rot );
	
	return [
		rot[0][0] * point[0] + rot[0][1] * point[1] + rot[0][2] * point[2],
		rot[1][0] * point[0] + rot[1][1] * point[1] + rot[1][2] * point[2],
		rot[2][0] * point[0] + rot[2][1] * point[1] + rot[2][2] * point[2]
	];
}