float(float) fabsf = #0:fabsf;
float(float) sqrtf = #0:sqrtf;
float(float) sinf = #0:sinf;
float(float) cosf = #0:cosf;
float(float, float) atan2f = #0:atan2f;
float(float) floorf = #0:floorf;
float(float) ceilf = #0:ceilf;
float(float) roundf = #0:roundf;
float(float) tanf = #0:tanf;

const float M_PI = 3.14159265358979323846f;

int() Q_rand = #0:Q_rand;
int(int) Q_rand_uniform = #0:Q_rand_uniform;

#ifndef USE_RAND_INTRINSICS
float() frandom = #0:frandom;
float() crandom = #0:crandom;
vector() frandomv = #0:frandomv;
vector() crandomv = #0:crandomv;

#define random frandom
#define randomv frandomv
#else
inline float crandom()
{
	return random(-1f, 1f);
}

inline vector crandomv()
{
	return randomv('-1 -1 -1', '1 1 1');
}
#endif

// not strictly math, but...
typedef enum int
{
	false,
	true
} bool;

inline int(float x) ANGLE2SHORT =
{
	return (int)(x * (65536f / 360f)) & 65535;
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

inline float(float a) DEG2RAD =
{
	return a * (M_PI / 180);
}

inline float(float a) RAD2DEG =
{
	return a * (180 / M_PI);
}

const int INT_MAX = 2147483647;

inline float(float a) anglemod =
{
    return (360.0f / 65536) * ((int)(a * (65536 / 360.0f)) & 65535);
}