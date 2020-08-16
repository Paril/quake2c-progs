// A wrapper to math.h

// trig
float(float) cos = #0;
float(float) sin = #0;
float(float) tan = #0;
float(float) acos = #0;
float(float) asin = #0;
float(float) atan = #0;
float(float, float) atan2 = #0;

// hyperbolic
float(float) cosh = #0;
float(float) sinh = #0;
float(float) tanh = #0;
float(float) acosh = #0;
float(float) asinh = #0;
float(float) atanh = #0;

// exp/logarithmic
float(float) exp = #0;
float(float, __out int) frexp = #0;
float(float, int) ldexp = #0;
float(float) log = #0;
float(float) log10 = #0;
float(float, __out int) modf = #0;
float(float) exp2 = #0;
float(float) expm1 = #0;
int(float) ilogb = #0;
float(float) log1p = #0;
float(float) log2 = #0;
float(float) logb = #0;
float(float, int) scalbn = #0;

// pow
float(float, float) pow = #0;
float(float) sqrt = #0;
float(float) cbrt = #0;
float(float, float) hypot = #0;

// error and gamma
float(float) erf = #0;
float(float) erfc = #0;
float(float) tgamma = #0;
float(float) lgamma = #0;

// rounding/remainder
float(float) ceil = #0;
float(float) floor = #0;
float(float, float) fmod = #0;
float(float) trunc = #0;
float(float) round = #0;
int(float) lround = #0;
float(float) rint = #0;
int(float) lrint = #0;
float(float) nearbyint = #0;
float(float, float) remainder = #0;
float(float, float, __out int) remquo = #0;

// floating point
float(float, float) copysign = #0;
float(string) nan = #0;
float(float, float) nextafter = #0;
float(float, float) nexttoward = #0;

// other
float(float) fabs = #0;
int(int) abs = #0;
float(float, float, float) fma = #0;

// classifications
bool(float) isfinite = #0;
bool(float) isinf = #0;
bool(float) isnan = #0;
bool(float) isnormal = #0;
bool(float) signbit = #0;

// constants
const float M_E		= 2.71828182845904523536;
const float M_LOG2E	= 1.44269504088896340736;
const float M_LOG10E	= 0.434294481903251827651;
const float M_LN2	= 0.693147180559945309417;
const float M_LN10	= 2.30258509299404568402;
const float M_PI	= 3.14159265358979323846;
const float M_PI_2	= 1.57079632679489661923;
const float M_PI_4	= 0.785398163397448309616;
const float M_1_PI	= 0.318309886183790671538;
const float M_2_PI	= 0.636619772367581343076;
const float M_2_SQRTPI	= 1.12837916709551257390;
const float M_SQRT2	= 1.41421356237309504880;
const float M_SQRT1_2	= 0.707106781186547524401;

// float constants
// these are set by the QCVM
API_FUNC var float FLT_MAX;
API_FUNC var float FLT_EPSILON;
API_FUNC var float FLT_MIN;

// limits
const int INT_MIN	= -2147483648;
const int INT_MAX	= 2147483647;

// min/max functions

/*INLINE*/ float(float a, float b) minf =
{
	if (a < b)
		return a;
	return b;
}

/*INLINE*/ float(float a, float b) maxf =
{
	if (a > b)
		return a;
	return b;
}

/*INLINE*/ int(int a, int b) mini =
{
	if (a < b)
		return a;
	return b;
}

/*INLINE*/ int(int a, int b) maxi =
{
	if (a > b)
		return a;
	return b;
}

// Quake-specific math functions below

inline float(float a) anglemod =
{
    return (360.0f / 65536) * ((int)(a * (65536 / 360.0f)) & 65535);
}