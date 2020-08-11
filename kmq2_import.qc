#ifdef KMQUAKE2_SUPPORT
// KMQ2 DLL imports.
// Note that these may be emulated by non-KMQ2 engines.
accessor file_list_t : pointer;

static entity(file_list_t, int)		file_list_get = #0;
static int(file_list_t)			file_list_length = #0;
void(file_list_t)			file_list_free = #0;

accessor file_list_t : pointer
{
	get entity[int] = file_list_get;
	get int length = file_list_length;
};

accessor file_handle_t : pointer;

typedef enum : int
{
	FS_READ,
	FS_WRITE,
	FS_APPEND
} fs_mode_t;

PROGS_LOCAL var struct {
	int(string name, __out string buffer)	LoadFile;
	
	file_list_t(string path, optional string extension = "")	GetFileList;
	
	int(string name, __out file_handle_t f, fs_mode_t mode)				OpenFile;
	int(string zipName, string name, __out file_handle_t f, fs_mode_t mode)		OpenCompressedFile;
	void(file_handle_t)								CloseFile;
	
	int(__variant *buffer, int size, file_handle_t f)	FRead;
	int(__variant *buffer, int size, file_handle_t f)	FWrite;
	
	string()	GameDir;
	string()	SaveGameDir;
	
	void(string)	CreatePath;
} kmgi = {
	#0:LoadFile,

	#0:GetFileList,

	#0:OpenFile,
	#0:OpenCompressedFile,
	#0:CloseFile,

	#0:FRead,
	#0:FWrite,

	#0:GameDir,
	#0:SaveGameDir,

	#0:CreatePath
};
#endif