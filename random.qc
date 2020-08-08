int() Q_rand = #0;
int(int) Q_rand_uniform = #0;

INLINE float crandom()
{
	return random(-1f, 1f);
}

INLINE vector crandomv()
{
	return randomv('-1 -1 -1', '1 1 1');
}

INLINE float(float a) DEG2RAD =
{
	return a * (M_PI / 180);
}

INLINE float(float a) RAD2DEG =
{
	return a * (180 / M_PI);
}