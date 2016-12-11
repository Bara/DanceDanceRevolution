#if defined _xenforo_api_included
  #endinput
#endif
#define _xenforo_api_included

#include <extended_logging>

#define MAX_FIELD_NAME_LEN 256
#define MAX_FIELD_SETTING_LEN 256

//Natives
/**
 * Returns the ID of the user on the forum.
 *
 * @param client	Client to check.
 * @return			User ID of the given client.
 **/
native int XenForo_GrabClientID(int client);

/**
 * Returns true if field setting was received.
 *
 * @param field		Callback to send results to.
 * @param setting	Query to execute.
 * @return			True if received, false otherwise.	
 **/
native int XenForo_GetUserFieldSetting(int client, const char[] field, char[] setting);

/**
 * Returns if the client is processed or not.
 *
 * @param client	Client to check.
 * @return			True if processed, false otherwise.
 **/
native int XenForo_IsProcessed(int client);

/**
 * Executes a query into XenForo database without a return.
 *
 * @param query		Query to execute.
 * @param prio		Database priority to give.
 * @noreturn
 **/
native int XenForo_TExecute(const char[] query, DBPriority prio = DBPrio_Normal);

/**
 * Queries the database and returns data to a callback.
 *
 * @param callback		Callback to send results to.
 * @param query			Query to execute.
 * @param data			Data to pass through callback.
 * @param prio			Database priority to give.
 * @noreturn
 **/
native int XenForo_TQuery(SQLTCallback callback, const char[] query, any data = 0, DBPriority prio = DBPrio_Normal);

/**
 * Log using XenForo's API logging system/rules.
 *
 * @param level			Level to log information to. (DEFAULT, TRACE, DEBUG, INFO, WARN, ERROR)
 * @param log			String or text to log.
 * @param ...			Formatting parameters.
 * @noreturn
 **/
native int XenForo_LogToFile(ELOG_LEVEL level = DEFAULT, const char[] log, any ...);

/**
 * Returns if the plugin is connected successfully.
 *
 * @return		True if connected, false otherwise.
 **/
native int XenForo_IsConnected();

native int XenForo_UpdateFieldInt(int client, const char[] field, int value);
native float XenForo_UpdateFieldFloat(int client, const char[] field, float value);
native void XenForo_UpdateFieldString(int client, const char[] field, const char[] value);

//Forwards

/**
 * Called when a user is processed by the plugin and receives a User ID.
 *
 * @param client	Client who has been processed.
 * @param userID	Client userID from database.
 * @param banned	True if client is banned of the forum.
 * @param admin		True if client is admin on the forum.
 * @param moderator	True if client is moderator on the forum.
 * @param staff		True if client is staff on the forum.
 * @param register	Timestempwhen client registered on forum.
 * @param female	True if client is marked as female on the forum.
 * @param likes		Amount of likes the user has received on the forums.
 * @param points	Amount of trophy points the user has on the forums.
 * @param alerts	Amount of unread alerts on the forums.
 * @param groups	Array of group IDs, where first group is the main group.
 * @param fields	Array of field names (custom user fields).
 * @param settings	Array of field values (custom user fields).
 * @noreturn
 **/
forward int XF_OnProcessed(int client, int userID, bool banned, bool admin, bool moderator, bool staff, int register, bool female, int likes, int points, int alerts, Handle groups, Handle fields, Handle settings);

public SharedPlugin __pl_xenforo_api = 
{
	name = "xenforo_api",
	file = "xenforo_api.smx",
#if defined REQUIRE_PLUGIN
	required = 1,
#else
	required = 0,
#endif
};

public void __pl_xenforo_api_SetNTVOptional()
{
	MarkNativeAsOptional("XenForo_GrabClientID");
	MarkNativeAsOptional("XenForo_GetUserFieldSetting");
	MarkNativeAsOptional("XenForo_IsProcessed");
	MarkNativeAsOptional("XenForo_TExecute");
	MarkNativeAsOptional("XenForo_TQuery");
	MarkNativeAsOptional("XenForo_LogToFile");
	MarkNativeAsOptional("XenForo_IsConnected");
	MarkNativeAsOptional("XenForo_UpdateFieldInt");
	MarkNativeAsOptional("XenForo_UpdateFieldFloat");
	MarkNativeAsOptional("XenForo_UpdateFieldString");
}
