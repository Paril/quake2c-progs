//
// this structure is cleared as each map is entered
// it is read/written to the level.sav file for savegames
//
struct level_locals_t
{
	int	framenum;
	float	time;

	dynstring	level_name;  // the descriptive name (Outer Base, etc)
	dynstring	mapname;     // the server name (base1, etc)
	dynstring	nextmap;     // go here when fraglimit is hit

	// intermission state
	int	intermission_framenum;  // time the intermission was started
	dynstring	changemap;
	int	exitintermission;
	vector	intermission_origin;
	vector	intermission_angle;

	entity	sight_client;  // changed once each frame for coop games

	entity	sight_entity;
	int	sight_entity_framenum;
	entity	sound_entity;
	int	sound_entity_framenum;
	entity	sound2_entity;
	int	sound2_entity_framenum;

	int	pic_health;

	int	total_secrets;
	int	found_secrets;

	int	total_goals;
	int	found_goals;

	int	total_monsters;
	int	killed_monsters;

	entity	current_entity;    // entity running from G_RunFrame
	int	body_que;           // dead bodies

	int	power_cubes;        // ugly necessity for coop
};

level_locals_t level;