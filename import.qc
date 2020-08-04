accessor cvar_t : int;
accessor entity_set_t : int;

PROGS_LOCAL var struct {
	// QC-specific imports
	void(int)	SetNumEdicts;
	void(entity)	ClearEntity;

	// Quake II game imports
	void(print_level_t, string fmt, ...) bprintf;
	void(string fmt, ...) dprintf;
	void(entity, print_level_t, string fmt, ...) cprintf;
	void(entity, string fmt, ...) centerprintf;
	void(entity, sound_channel_t channel, int soundindex, float volume, sound_attn_t attenuation, float timeofs) sound;
	void(vector, entity, sound_channel_t channel, int soundindex, float volume, sound_attn_t attenuation, float timeofs) positioned_sound;
	
	void(int, string) configstring;
	
	void(string fmt, ...) error;
	
	int(string) modelindex;
	int(string) soundindex;
	int(string) imageindex;
	
	void(entity, string) setmodel;
	
	void(trace_t *tr, vector start, vector mins, vector maxs, vector end, entity passent, int contentmask) trace;
	
	int(vector) pointcontents;
	bool(vector, vector) inPVS;
	bool(vector, vector) inPHS;
	void(int, bool) SetAreaPortalState;
	bool(int, int) AreasConnected;
	
	void(entity) linkentity;
	void(entity) unlinkentity;
	void(entity_set_t set, vector mins, vector maxs, int maxcount, box_edicts_area_t areatype) BoxEdicts;
	void(pmove_t *) Pmove;
	
	void(vector, multicast_t) multicast;
	void(entity, bool reliable) unicast;
	void(int) WriteChar;
	void(int) WriteByte;
	void(int) WriteShort;
	void(int) WriteLong;
	void(float) WriteFloat;
	void(string) WriteString;
	void(vector p) WritePosition;
	void(vector p) WriteDir;
	void(float) WriteAngle;
	
	cvar_t(string name, string value, cvar_flags_t flags) cvar;
	cvar_t(string name, string value) cvar_set;
	cvar_t(string name, string value) cvar_forceset;
	
	int()		argc;
	string(int)	argv;
	string()	args;
	
	void(string)	AddCommandString;
	
	void(float, int color)	DebugGraph;
} gi = {	
	#0:SetNumEdicts,
	#0:ClearEntity,

	#0:bprintf,
	#0:dprintf,
	#0:cprintf,
	#0:centerprintf,
	#0:sound,
	#0:positioned_sound,
	
	#0:configstring,
	
	#0:error,
	
	#0:modelindex,
	#0:soundindex,
	#0:imageindex,
	
	#0:setmodel,
	
	#0:trace,
	#0:pointcontents,
	#0:inPVS,
	#0:inPHS,
	#0:SetAreaPortalState,
	#0:AreasConnected,
	
	#0:linkentity,
	#0:unlinkentity,
	#0:BoxEdicts,
	#0:Pmove,
	
	#0:multicast,
	#0:unicast,
	#0:WriteChar,
	#0:WriteByte,
	#0:WriteShort,
	#0:WriteLong,
	#0:WriteFloat,
	#0:WriteString,
	#0:WritePosition,
	#0:WriteDir,
	#0:WriteAngle,
	
	#0:cvar,
	#0:cvar_set,
	#0:cvar_forceset,
	
	#0:argc,
	#0:argv,
	#0:args,
	
	#0:AddCommandString,
	
	#0:DebugGraph
};