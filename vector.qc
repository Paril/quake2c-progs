// a special vector that is used by AngleVectors, to pass 'null' to them basically
vector unref_vec;

const vector vec3_origin = '0 0 0';

// imports
void(vector, __out vector forward, __out vector right, __out vector up) AngleVectors = #0:AngleVectors;
float(__inout vector) VectorNormalize = #0:VectorNormalize;
float(vector) VectorLength = #0:VectorLength;
void(vector vec, __out vector angles) vectoangles = #0:vectoangles;
void(vector a, vector b, __out vector c) CrossProduct = #0:CrossProduct;

// Definitions, to make Q2->QC easier
#define DotProduct(a, b) ((a) * (b))
#define VectorSet(a, x, y, z) { a[(ARRAY_INDEX_TYPE)0] = (float)(x); a[(ARRAY_INDEX_TYPE)1] = (float)(y); a[(ARRAY_INDEX_TYPE)2] = (float)(z); }
#define VectorClear(a) a = vec3_origin
#define VectorMA(a, s, b, c) (c) = (a) + ((b) * (s))
#define VectorCopy(a, b) (b) = (a)
#define VectorSubtract(a, b, c) (c) = (a) - (b)
#define VectorAdd(a, b, c) (c) = (a) + (b)
#define VectorScale(a, b, c) (c) = (a) * (b)
#define VectorCompare(a, b) ((a) == (b))
#define VectorNegate(a, b) (b) = -(a)
#define VectorEmpty(a) (!(a))