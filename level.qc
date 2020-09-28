//
// this structure is cleared as each map is entered
// it is read/written to the level.sav file for savegames
//
API_FUNC struct
{
	int		framenum;
	float	time;

	string	level_name;  // the descriptive name (Outer Base, etc)
	string	mapname;     // the server name (base1, etc)
	string	nextmap;     // go here when fraglimit is hit

	// intermission state
	int		intermission_framenum;  // time the intermission was started
	string	changemap;
	int		exitintermission;
	vector	intermission_origin;
	vector	intermission_angle;

	int	pic_health;

#ifdef SINGLE_PLAYER
	entity	sight_client;	// changed once each frame for coop games

	entity	sight_entity;
	int		sight_entity_framenum;
	entity	sound_entity;
	int		sound_entity_framenum;
	entity	sound2_entity;
	int		sound2_entity_framenum;

	int	total_secrets;
	int	found_secrets;

	int	total_goals;
	int	found_goals;

	int	total_monsters;
	int	killed_monsters;

	int	power_cubes;        // ugly necessity for coop

#ifdef GROUND_ZERO
	entity	disguise_violator;
	int		disguise_violation_framenum;
#endif
#endif

	entity	current_entity;	// entity running from G_RunFrame

	int	body_que;           // dead bodies
} level;