// not strictly math, but...
typedef enum int
{
	false,
	true
} bool;

float(float) fabsf = #0:fabsf;
float(float) sqrtf = #0:sqrtf;
float(float) sinf = #0:sinf;
float(float) cosf = #0:cosf;
float(float, float) atan2f = #0:atan2f;
float(float) floorf = #0:floorf;
float(float) ceilf = #0:ceilf;
float(float) roundf = #0:roundf;
float(float) tanf = #0:tanf;
float(float) atanf = #0:atanf;
float(float) asinf = #0:asinf;
bool(float) isnan = #0:isnan;

const float M_PI = 3.14159265358979323846f;

int() Q_rand = #0:Q_rand;
int(int) Q_rand_uniform = #0:Q_rand_uniform;

/*inline*/ float crandom()
{
	return random(-1f, 1f);
}

/*inline*/ vector crandomv()
{
	return randomv('-1 -1 -1', '1 1 1');
}

/*inline*/ float(float a) DEG2RAD =
{
	return a * (M_PI / 180);
}

/*inline*/ float(float a) RAD2DEG =
{
	return a * (180 / M_PI);
}

const int INT_MAX = 2147483647;

/*inline*/ float(float a) anglemod =
{
    return (360.0f / 65536) * ((int)(a * (65536 / 360.0f)) & 65535);
}

/*inline*/ float minf(float a, float b)
{
	if (a < b)
		return a;
	return b;
}

/*inline*/ float maxf(float a, float b)
{
	if (a > b)
		return a;
	return b;
}

/*inline*/ int mini(int a, int b)
{
	if (a < b)
		return a;
	return b;
}

/*inline*/ int maxi(int a, int b)
{
	if (a > b)
		return a;
	return b;
}
