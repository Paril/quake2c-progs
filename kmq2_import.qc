#ifdef KMQUAKE2_SUPPORT
// KMQ2 DLL imports.
// Note that these may be emulated by non-KMQ2 engines.
accessor file_list_t : handle;

static entity(file_list_t, int)	file_list_get = #0;
static int(file_list_t)			file_list_length = #0;

accessor file_list_t : handle
{
	get entity[int] = file_list_get;
	get int length = file_list_length;
};

accessor file_handle_t : handle;

typedef enum : int
{
	FS_READ,
	FS_WRITE,
	FS_APPEND
} fs_mode_t;

PROGS_LOCAL var struct {
	int(string name, out string buffer)	LoadFile;
	
	file_list_t(string path, optional string extension = "")	GetFileList;
	
	int(string name, out file_handle_t f, fs_mode_t mode)					OpenFile;
	int(string zipName, string name, out file_handle_t f, fs_mode_t mode)	OpenCompressedFile;
	
	int(variant *buffer, int size, file_handle_t f)	FRead;
	int(variant *buffer, int size, file_handle_t f)	FWrite;
	
	int(out string buffer, int size, file_handle_t f)	FReadString;
	int(string buffer, int size, file_handle_t f)		FWriteString;
	
	string()	GameDir;
	string()	SaveGameDir;
	
	void(string)	CreatePath;
} kmgi = {
	#0:LoadFile,

	#0:GetFileList,

	#0:OpenFile,
	#0:OpenCompressedFile,

	#0:FRead,
	#0:FWrite,
	
	#0:FReadString,
	#0:FWriteString,

	#0:GameDir,
	#0:SaveGameDir,

	#0:CreatePath
};
#endif