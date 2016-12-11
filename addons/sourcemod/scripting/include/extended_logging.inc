#if defined _extended_log_included
 #endinput
#endif
#define _extended_log_included

#define ExLo_VERSION "2.0.0"

enum ELOG_LEVEL
{
	DEFAULT = 0,
	TRACE,
	DEBUG,
	INFO,
	WARN,
	ERROR
};

char g_sELogLevel[6][32] = {
	"default",
	"trace",
	"debug",
	"info",
	"warn",
	"error"
};

/**
 * Logs a message to any file.
 *
 * @param path			Path to file (default: addons/sourcemod/logs).
 * @param file			File name (default: file).
 * @param date			Date for better overview (default: no date).
 * @param format		String format.
 * @param ...			Format arguments.
 * @noreturn
 * @error				File could not be opened/written.
 */
stock void Log_Default(const char[] path = "", const char[] file = "file", const char[] date = "",  const char[] format, any ...)
{
	char sBuffer[1024];
	VFormat(sBuffer, sizeof(sBuffer), format, 5);
	Log_File(path, file, date, DEFAULT, sBuffer);
}

/**
 * Logs a trace message to any file.
 *
 * @param path			Path to file (default: addons/sourcemod/logs).
 * @param file			File name (default: file).
 * @param date			Date for better overview (default: no date).
 * @param format		String format.
 * @param ...			Format arguments.
 * @noreturn
 * @error				File could not be opened/written.
 */
stock void Log_Trace(const char[] path = "", const char[] file = "file", const char[] date = "",  const char[] format, any ...)
{
	char sBuffer[1024];
	VFormat(sBuffer, sizeof(sBuffer), format, 5);
	Log_File(path, file, date, TRACE, sBuffer);
}

/**
 * Logs a debug message to any file.
 *
 * @param path			Path to file (default: addons/sourcemod/logs).
 * @param file			File name (default: file).
 * @param date			Date for better overview (default: no date).
 * @param format		String format.
 * @param ...			Format arguments.
 * @noreturn
 * @error				File could not be opened/written.
 */
stock void Log_Debug(const char[] path = "", const char[] file = "file", const char[] date = "",  const char[] format, any ...)
{
	char sBuffer[1024];
	VFormat(sBuffer, sizeof(sBuffer), format, 5);
	Log_File(path, file, date, DEBUG, sBuffer);
}

/**
 * Logs a info message to any file.
 *
 * @param path			Path to file (default: addons/sourcemod/logs).
 * @param file			File name (default: file).
 * @param date			Date for better overview (default: no date).
 * @param format		String format.
 * @param ...			Format arguments.
 * @noreturn
 * @error				File could not be opened/written.
 */
stock void Log_Info(const char[] path = "", const char[] file = "file", const char[] date = "",  const char[] format, any ...)
{
	char sBuffer[1024];
	VFormat(sBuffer, sizeof(sBuffer), format, 5);
	Log_File(path, file, date, INFO, sBuffer);
}

/**
 * Logs a warning message to any file.
 *
 * @param path			Path to file (default: addons/sourcemod/logs).
 * @param file			File name (default: file).
 * @param date			Date for better overview (default: no date).
 * @param format		String format.
 * @param ...			Format arguments.
 * @noreturn
 * @error				File could not be opened/written.
 */
stock void Log_Warn(const char[] path = "", const char[] file = "file", const char[] date = "",  const char[] format, any ...)
{
	char sBuffer[1024];
	VFormat(sBuffer, sizeof(sBuffer), format, 5);
	Log_File(path, file, date, WARN, sBuffer);
}

/**
 * Logs a error message to any file.
 *
 * @param path			Path to file (default: addons/sourcemod/logs).
 * @param file			File name (default: file).
 * @param date			Date for better overview (default: no date).
 * @param format		String format.
 * @param ...			Format arguments.
 * @noreturn
 * @error				File could not be opened/written.
 */
stock void Log_Error(const char[] path = "", const char[] file = "file", const char[] date = "",  const char[] format, any ...)
{
	char sBuffer[1024];
	VFormat(sBuffer, sizeof(sBuffer), format, 5);
	Log_File(path, file, date, ERROR, sBuffer);
}

/**
 * Logs a message to any file.
 * Level: 0/6+ - DEFAULT, 1 - TRACE, 2 - DEBUG,
 *        3 - INFO, 4 - WARN, 5 - ERROR
 *
 * @param path			Path to file (default: addons/sourcemod/logs).
 * @param file			File name (default: file).
 * @param date			Date for better overview (default: no date).
 * @param level			Log level (default: INFO).
 * @param format		String format.
 * @param ...			Format arguments.
 * @noreturn
 * @error				File could not be opened/written.
 */
stock void Log_File(const char[] path = "", const char[] file = "file", const char[] date = "", ELOG_LEVEL level = INFO, const char[] format, any ...)
{
	char sPath[PLATFORM_MAX_PATH + 1];
	char sLevelPath[PLATFORM_MAX_PATH + 1];
	char sFile[PLATFORM_MAX_PATH + 1];
	char sBuffer[1024];

	if(StrEqual(path, "", false))
	{
		BuildPath(Path_SM, sPath, sizeof(sPath), "logs");
	}
	else
	{
		BuildPath(Path_SM, sPath, sizeof(sPath), "logs/%s", path);
		
		if(!DirExists(sPath))
		{
			CreateDirectory(sPath, 755);
		}
	}

	if(level < TRACE || level > ERROR)
	{
		Format(sLevelPath, sizeof(sLevelPath), "%s", sPath);
	}
	else
	{
		Format(sLevelPath, sizeof(sLevelPath), "%s/%s", sPath, g_sELogLevel[level]);
	}

	
	if(!DirExists(sLevelPath))
	{
		CreateDirectory(sLevelPath, 755);
	}

	if(StrEqual(date, "", false))
	{
		Format(sFile, sizeof(sFile), "%s/%s.log", sLevelPath, file);
	}
	else
	{
		Format(sFile, sizeof(sFile), "%s/%s_%s.log", sLevelPath, file, date);
	}

	VFormat(sBuffer, sizeof(sBuffer), format, 6);

	LogToFile(sFile, sBuffer);
}
