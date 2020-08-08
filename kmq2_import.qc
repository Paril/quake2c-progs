#ifdef KMQUAKE2_SUPPORT
// KMQ2 DLL imports.
// Note that some of these may be emulated by non-KMQ2 engines.
accessor file_list_t : int;

accessor file_handle_t : int;

typedef enum : int
{
	FS_READ,
	FS_WRITE,
	FS_APPEND
} fs_mode_t;

PROGS_LOCAL var struct {
	int(string name, __out string buffer)	LoadFile;
	
	file_list_t(string path, string extension)	GetFileList;
	
	int(string name, __out file_handle_t f, fs_mode_t mode)				OpenFile;
	int(string zipName, string name, __out file_handle_t f, fs_mode_t mode)		OpenCompressedFile;
	void(file_handle_t)								CloseFile;
	
	int(void *buffer, int size, file_handle_t f)	FRead;
	int(void *buffer, int size, file_handle_t f)	FWrite;
	
	string()	FS_GameDir;
	string()	FS_SaveGameDir;
	
	void()	CreatePath;
} kmgi = {
	#0:LoadFile,

	#0:GetFileList,

	#0:OpenFile,
	#0:OpenCompressedFile,
	#0:CloseFile,

	#0:FRead,
	#0:FWrite,

	#0:FS_GameDir,
	#0:FS_SaveGameDir,

	#0:CreatePath
};
#endif