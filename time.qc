struct time_t
{
	int tm_sec;   // seconds after the minute - [0, 60] including leap second
	int tm_min;   // minutes after the hour - [0, 59]
	int tm_hour;  // hours since midnight - [0, 23]
	int tm_mday;  // day of the month - [1, 31]
	int tm_mon;   // months since January - [0, 11]
	int tm_year;  // years since 1900
	int tm_wday;  // days since Sunday - [0, 6]
	int tm_yday;  // days since January 1 - [0, 365]
	int tm_isdst; // daylight savings time flag
};

void(out time_t tm) localtime = #0;

float() now = #0;

#define TIMER_DEFINE_START float __timer = now()
#define TIMER_FINISHED(name) gi.dprintf("%s: %fs\n", name, now() - __timer)
#define TIMER_RESTART __timer = now()