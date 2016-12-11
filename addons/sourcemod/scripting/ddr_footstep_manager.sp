#pragma semicolon 1

#include <sourcemod>

#pragma newdecls required

public Plugin myinfo = 
{
	name = "Dance Dance Revolution - Footstep Manager",
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
	
	CreateTimer(5.0, Timer_Footsteps, _, TIMER_REPEAT);
}

public Action Timer_Footsteps(Handle timer, any data)
{
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && !IsFakeClient(i))
		{
			SendConVarValue(i, FindConVar("sv_footsteps"), "0");
		}
	}
	return Plugin_Continue;
}