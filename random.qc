int() Q_rand = #0;
int(int) Q_rand_uniform = #0;

inline float() crandom =
{
	return random(-1f, 1f);
}

inline vector() crandomv =
{
	return randomv('-1 -1 -1', '1 1 1');
}

inline float(float a) DEG2RAD =
{
	return a * (M_PI / 180);
}

inline float(float a) RAD2DEG =
{
	return a * (180 / M_PI);
}