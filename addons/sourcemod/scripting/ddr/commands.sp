public Action cmd_stop(int client, int args)
{
	if (g_bIsInRecord && g_iRecordingClient == client)
	{
		delete g_hFileRecord;
		CPrintToChat(client, "%T", "DDR_Save_Sequence", client, g_sLogo[client], g_sFileRecord);
		ResetAll();
		
		Stop_View_Client(client);
	}
	else if (g_iPlayers[client][INGAME])
	{
		if (g_bAllowStop)
			Stop_View_Client(client);
		else CPrintToChat(client, "%T", "DDR_Please_Wait", client, g_sLogo[client]);
	}
	else CPrintToChat(client, "%T", "DDR_Not_InGame", client, g_sLogo[client]);
}
public Action cmd_song(int client, int args)
{
	OpenDdrAdminMenue(client);
	
	return Plugin_Handled;
}

public Action cmd_solo(int client, int args)
{
	TeleportEntity(client, g_fTeleSolo, NULL_VECTOR, NULL_VECTOR);
	
	return Plugin_Handled;
}

public Action cmd_team1(int client, int args)
{
	TeleportEntity(client, g_fTeleTeam1, NULL_VECTOR, NULL_VECTOR);
	
	return Plugin_Handled;
}

public Action cmd_team2(int client, int args)
{
	TeleportEntity(client, g_fTeleTeam2, NULL_VECTOR, NULL_VECTOR);
	
	return Plugin_Handled;
}

public Action cmd_lobby(int client, int args)
{
	TeleportEntity(client, g_fTeleLobby, NULL_VECTOR, NULL_VECTOR);
	
	return Plugin_Handled;
}

public Action cmd_rank(int client, int args)
{
	OpenRank(client);
	
	return Plugin_Handled;
}

public Action cmd_level(int client, int args)
{
	for (int j = 1; j <= MaxClients; j++)
		if (IsClientInGame(j) && g_PlayerDatas[j][LEVEL] > 0)
			CPrintToChat(j, "%T", "DDR_Command_Level", j, g_sLogo[j], client, g_PlayerDatas[client][LEVEL]);
	
	return Plugin_Handled;
}

public Action cmd_reset(int client, int args)
{
	FullReset();
	for (int j = 1; j <= MaxClients; j++)
		if (IsClientInGame(j))
			CPrintToChat(j, "%T", "DDR_Admin_Reset", j, g_sLogo[j], client);
	
	return Plugin_Handled;
}

public Action cmd_respawn(int client, int args)
{
	if (IsClientInGame(client) && GetClientTeam(client) == CS_TEAM_T)
		CS_RespawnPlayer(client);
	
	return Plugin_Continue;
}

public Action cmd_rr(int client, int args)
{
	if(!g_bDev)
		return Plugin_Handled;
	
	CS_TerminateRound(3.0, CSRoundEnd_Draw);
	
	return Plugin_Handled;
}

public Action cmd_mr(int client, int args)
{
	if(!g_bDev)
		return Plugin_Handled;
	
	char sMap[128];
	GetCurrentMap(sMap, sizeof(sMap));
	ForceChangeLevel(sMap, "Map restart");
	
	return Plugin_Handled;
}

public Action cmd_start(int client, int args)
{
	if (g_iCountdown > 6 && g_iCountdown < 30)
		g_iCountdown = 6;
	
	return Plugin_Handled;
}
