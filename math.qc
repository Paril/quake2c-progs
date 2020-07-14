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

const float M_PI = 3.14159265358979323846f;

int() Q_rand = #0:Q_rand;
int(int) Q_rand_uniform = #0:Q_rand_uniform;
float() frand = #0:frand;
float() crand = #0:crand;

// not strictly math, but...
typedef enum int
{
	false,
	true
} bool;

// TODO: inline
#define ANGLE2SHORT(x)  ((int)((x)*65536/360) & 65535)
#define SHORT2ANGLE(x)  ((x)*(360.0f/65536))

#define COORD2SHORT(x)  ((int)((x)*8.0f))
#define SHORT2COORD(x)  ((x)*(1.0f/8))

const ARRAY_INDEX_TYPE PITCH	= (ARRAY_INDEX_TYPE)0;
const ARRAY_INDEX_TYPE YAW	= (ARRAY_INDEX_TYPE)1;
const ARRAY_INDEX_TYPE ROLL	= (ARRAY_INDEX_TYPE)2;

const int INT_MAX = 2147483647;

float vectoyaw(vector vec)
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