#pragma semicolon 1

#include <sourcemod>

#pragma newdecls required

public Plugin myinfo = 
{
	name = "Dance Dance Revolution - Bhop", 
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
	
	HookEvent("player_jump", Event_PlayerJump);
}

public Action Event_PlayerJump(Handle event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (IsClientInGame(client) && !IsFakeClient(client))
	{
		SetEntPropFloat(client, Prop_Send, "m_flStamina", 0.0);
	}
}

public void OnConfigsExecuted()
{
	ServerCommand("sv_enablebunnyhopping", "1");
	ServerCommand("sv_staminamax", "0");
	ServerCommand("sv_airaccelerate", "2000");
	ServerCommand("sv_staminajumpcost", "0");
	ServerCommand("sv_staminalandcost", "0");
	ServerCommand("sv_accelerate_use_weapon_speed", "0");
	ServerCommand("sv_maxvelocity", "350");
	ServerCommand("sv_staminarecoveryrate", "0");
	ServerCommand("sv_wateraccelerate", "2000");
}

public Action OnPlayerRunCmd(int client, int & buttons, int & impulse, float vel[3], float angles[3], int & weapon)
{
	if (IsClientInGame(client))
	{
		int index = GetEntProp(client, Prop_Data, "m_nWaterLevel");
		int water = EntIndexToEntRef(index);
		if (water != INVALID_ENT_REFERENCE)
		{
			if (IsPlayerAlive(client))
			{
				if (buttons & IN_JUMP)
				{
					if (water <= 1)
					{
						if (!(GetEntityMoveType(client) & MOVETYPE_LADDER))
						{
							SetEntPropFloat(client, Prop_Send, "m_flStamina", 0.0);
							if (!(GetEntityFlags(client) & FL_ONGROUND))
							{
								buttons &= ~IN_JUMP;
							}
						}
					}
				}
			}
		}
	}
	
	return Plugin_Continue;
}
