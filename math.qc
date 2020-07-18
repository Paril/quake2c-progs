float(float) fabsf = #0:fabsf;
float(float) sqrtf = #0:sqrtf;
float(float) sinf = #0:sinf;
float(float) cosf = #0:cosf;
float(float, float) atan2f = #0:atan2f;
float(float) RAD2DEG = #0:RAD2DEG;
float(float) DEG2RAD = #0:DEG2RAD;
float(float) floorf = #0:floorf;
float(float) ceilf = #0:ceilf;
float(float) roundf = #0:roundf;
float(float) tanf = #0:tanf;

const float M_PI = 3.14159265358979323846f;

int() Q_rand = #0:Q_rand;
int(int) Q_rand_uniform = #0:Q_rand_uniform;
float() frand = #0:frand;
float() crand = #0:crand;

inline float() frand_intrinsic =
{
	float x;
	asm RAND0 x;
	return x;
};

inline float(float y) frand_max_intrinsic =
{
	float x;
	asm RAND1 y, x;
	return x;
};

inline float(float min, float max) frand_minmax_intrinsic =
{
	float x;
	asm RAND2 min, max, x;
	return x;
};

// not strictly math, but...
typedef enum int
{
	false,
	true
} bool;

inline int(float x) ANGLE2SHORT =
{
	return (int)(x * 65536 / 360) & 65535;
}

inline float(int x) SHORT2ANGLE =
{
	return x * (360.0f / 65536);
}

inline int(float x) COORD2SHORT =
{
	return (int)(x * 8.0f);
}

inline float(int x) SHORT2COORD = 
{
	return x * (1.0f / 8);
}

enum int { PITCH, YAW, ROLL };

const int INT_MAX = 2147483647;

float(vector vec) vectoyaw =
{
	float   yaw;

	if (/*vec[YAW] == 0 &&*/ vec_x == 0) {
		yaw = 0;
		if (vec_y > 0)
			yaw = 90f;
		else if (vec_y < 0)
			yaw = -90f;
	} else {
		yaw = (float)(int)RAD2DEG(atan2f(vec_y, vec_x));
		if (yaw < 0)
			yaw += 360f;
	}

	return yaw;
}

inline float(float a) anglemod =
{
    a = (360.0f / 65536) * ((int)(a * (65536 / 360.0f)) & 65535);
    return a;
}