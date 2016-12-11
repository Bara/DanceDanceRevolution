#if defined _ddr_included
 #endinput
#endif
#define _ddr_included

#define LoopClients(%1) for(int %1 = 1; %1 <= MaxClients; %1++) if(IsClientInGame(%1))

native bool DDR_IsClientInGame(int client);
native int DDR_GetClientLevel(int client);

forward void DDR_ClientEnterSong(int client);
forward void DDR_ClientLeftSong(int client);
forward void DDR_OnSongStart(int songid, int difficulty, const char[] name);
forward void DDR_OnSongEnd(int songid, const char[] name);

stock bool IsDDRLoaded()
{
	if(LibraryExists("ddr"))
		return true;
	return false;
}

public SharedPlugin __pl_ddr =
{
	name = "ddr",
	file = "ddr.smx",
#if defined REQUIRE_PLUGIN
	required = 1,
#else
	required = 0,
#endif
};

#if !defined REQUIRE_PLUGIN
public __pl_gang_SetNTVOptional()
{
	MarkNativeAsOptional("DDR_IsClientInGame");
	MarkNativeAsOptional("DDR_GetClientLevel");
}
#endif
