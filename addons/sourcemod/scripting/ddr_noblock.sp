#pragma semicolon 1

#include <sourcemod>

#pragma newdecls required

int g_iCollision;

public Plugin myinfo = 
{
	name = "Dance Dance Revolution - NoBlock", 
	author = "Steven, Zipcore, Bara", 
	description = "Dance Dance Revolution for CS:GO",
	version = "1.0.<ID>-beta", 
	url = "fotg.net"
}

public void OnPluginStart()
{
	if (GetExtensionFileStatus("accelerator.ext") != 1)
	{
		SetFailState("Please use \"Dance Dance Revolution\" only with accelerator!");
	}
	
	HookEvent("player_spawn", Event_PlayerSpawn);
	
	g_iCollision = FindSendPropInfo("CBaseEntity", "m_CollisionGroup");
	if (g_iCollision == -1)
	{
		SetFailState("Fuck off m_CollisionGroup!");
	}
}

public Action Event_PlayerSpawn(Handle event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	SetEntData(client, g_iCollision, 2, 4, true);
}
