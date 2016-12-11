#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <cstrike>

#pragma newdecls required

char g_sBlockedCMDs[][] =  { "kill", "explode", "spectate", "jointeam", "joinclass" };
char g_sRadioCMDs[][] =  { "coverme", "takepoint", "holdpos", "regroup", "followme", "takingfire", "go", "fallback", "sticktog", "getinpos", "stormfront", "report", "roger", "enemyspot", "needbackup", "sectorclear", "inposition", "reportingin", "getout", "negative", "enemydown" };

public Plugin myinfo = 
{
	name = "Dance Dance Revolution - Commands",
	author = "Steven, Zipcore, Bara", 
	description = "Dance Dance Revolution for CS:GO", 
	version = "1.0.<ID>-beta", 
	url = "fotg.net"
};

public void OnPluginStart()
{
	if (GetExtensionFileStatus("accelerator.ext") != 1)
	{
		SetFailState("Please use \"Dance Dance Revolution\" only with accelerator!");
	}
	
	for (int j; j < sizeof(g_sBlockedCMDs); j++)
		AddCommandListener(Command_InterceptSuicide, g_sBlockedCMDs[j]);
	
	for (int j; j < sizeof(g_sRadioCMDs); j++)
		AddCommandListener(Command_Radio, g_sRadioCMDs[j]);
}


public Action Command_InterceptSuicide(int client, const char[] command, int args)
{
	if (IsClientInGame(client) && GetClientTeam(client) == CS_TEAM_T)
		return Plugin_Handled;
	return Plugin_Continue;
}

public Action Command_Radio(int client, const char[] command, int args)
{
	return Plugin_Handled;
}
