// Location of NPCs
float g_fNpcDj[3], g_fNpcBar[3], g_fNpcDealer[3], g_fNpcShop[3], g_fNpcGames[3];

// Enitys of NPCs
int g_iNpcDj, g_iNpcBar, g_iNpcDealer, g_iNpcShop, g_iNpcGames;

public Action Timer_CheckNPCs(Handle Timer, any data)
{
	CheckNPCRange();
	return Plugin_Continue;
}

void HookNPCs()
{
	HookEvent("player_spawn", Event_OnPlayerSpawn, EventHookMode_Post);
	HookEvent("player_death", Event_PlayerDeath);
}

void PreCacheNPCModels()
{
	PrecacheModel(NPC_MODEL_SHOP);
	// Downloader_AddFileToDownloadsTable(NPC_MODEL_SHOP);
	
	PrecacheModel(NPC_MODEL_BAR);
	// Downloader_AddFileToDownloadsTable(NPC_MODEL_BAR);
	
	PrecacheModel(NPC_MODEL_DJ);
	// Downloader_AddFileToDownloadsTable(NPC_MODEL_DJ);
	
	PrecacheModel(NPC_MODEL_DEALER);
	// Downloader_AddFileToDownloadsTable(NPC_MODEL_DEALER);
	
	PrecacheModel(NPC_MODEL_GAMES);
	// Downloader_AddFileToDownloadsTable(NPC_MODEL_GAMES);
}

void InitNPCs()
{
	int entindex = -1;
	char stringname[20];
	
	while ((entindex = FindEntityByClassname(entindex, "info_teleport_destination")) != -1)
	{
		GetEntPropString(entindex, Prop_Data, "m_iName", stringname, sizeof(stringname));

		if (StrEqual(stringname, "npc_dj"))
		{
			GetEntPropVector(entindex, Prop_Send, "m_vecOrigin", g_fNpcDj);
			AcceptEntityInput(entindex, "Kill");
			g_iNpcDj = SpawnNPC("NPC_DJ", NPC_MODEL_DJ, "Wave", g_fNpcDj);
		}
		else if (StrEqual(stringname, "npc_bar"))
		{
			GetEntPropVector(entindex, Prop_Send, "m_vecOrigin", g_fNpcBar);
			AcceptEntityInput(entindex, "Kill");
			g_iNpcBar = SpawnNPC("NPC_BAR", NPC_MODEL_BAR, "LineIdle03", g_fNpcBar);
		}
		else if (StrEqual(stringname, "npc_dealer"))
		{
			GetEntPropVector(entindex, Prop_Send, "m_vecOrigin", g_fNpcDealer);
			AcceptEntityInput(entindex, "Kill");
			g_iNpcDealer = SpawnNPC("NPC_DEALER", NPC_MODEL_DEALER, "Walk", g_fNpcDealer);
		}
		else if (StrEqual(stringname, "npc_shop"))
		{
			GetEntPropVector(entindex, Prop_Send, "m_vecOrigin", g_fNpcShop);
			AcceptEntityInput(entindex, "Kill");
			g_iNpcShop = SpawnNPC("NPC_SHOP", NPC_MODEL_SHOP, "LineIdle01", g_fNpcShop);
		}
		else if (StrEqual(stringname, "npc_games"))
		{
			GetEntPropVector(entindex, Prop_Send, "m_vecOrigin", g_fNpcGames);
			AcceptEntityInput(entindex, "Kill");
			g_iNpcGames = SpawnNPC("NPC_GAMES", NPC_MODEL_GAMES, "LineIdle01", g_fNpcGames);
		}
	}
}

int SpawnNPC(char name[64], char model[512], char defAni[64], float pos[3], float angle[3] = NULL_VECTOR)
{
	int entity = CreateEntityByName("prop_dynamic");
	
	DispatchKeyValue(entity, "targetname", name);
	DispatchKeyValue(entity, "model", model);
	DispatchKeyValue(entity, "DefaultAnim", defAni);
	DispatchKeyValue(entity, "solid", "2"); //Use bounding box
	
	DispatchSpawn(entity);
	
	TeleportEntity(entity, pos, angle, NULL_VECTOR);
	
	return entity;
}

public Action NPC_Touch(int npc, int client)
{
	if (!Client_IsValid(client, true) || !IsPlayerAlive(client))
		return;
	
	if (npc == g_iTriggerBar)
		NPCTouchBar(client);
	else if (npc == g_iTriggerDJ)
		NPCTouchDj(client);
	else if (npc == g_iTriggerShop) {}
		// NPCTouchShop(client);
	else if (npc == g_iTriggerDealer)
		NPCTouchDealer(client);
	else if (npc == g_iTriggerGames)
		NPCTouchGames(client);
}

/* void NPCTouchShop(int client)
{
	
} */

void NPCTouchBar(int client)
{
	if(GetEngineVersion() != Engine_CSGO)
	{
		Menu menu = new Menu(NPCBar_MenuHandler);
		
		SetMenuTitle(menu, "%T", "DDR_NPC_Bar_Title", client);
		
		char sBuffer1[64], sBuffer2[64], sBuffer3[64], sBuffer4[64];
		
		Format(sBuffer1, sizeof(sBuffer1), "%T", "DDR_NPC_Bar_Drink1", client);
		Format(sBuffer2, sizeof(sBuffer2), "%T", "DDR_NPC_Bar_Drink2", client);
		Format(sBuffer3, sizeof(sBuffer3), "%T", "DDR_NPC_Bar_Drink3", client);
		Format(sBuffer4, sizeof(sBuffer4), "%T", "DDR_NPC_Bar_Drink4", client);
		
		AddMenuItem(menu, "water", sBuffer1);
		AddMenuItem(menu, "lemonade", sBuffer2);
		AddMenuItem(menu, "beer", sBuffer3);
		AddMenuItem(menu, "vodka", sBuffer4);
		
		SetMenuExitButton(menu, true);
		
		DisplayMenu(menu, client, MENU_TIME_FOREVER);
	}
}

public int NPCBar_MenuHandler(Menu menu, MenuAction action, int client, int param)
{
	if (action == MenuAction_Select)
	{
		char sParam[16];
		GetMenuItem(menu, param, sParam, sizeof(sParam));
		
		if (StrEqual(sParam, "water"))
		{
			CPrintToChat(client, "%T", "DDR_NPC_Bar_Drink1_Result", client);
			ClientCommand(client, "r_screenoverlay 0");
		}
		else if (StrEqual(sParam, "lemonade"))
		{
			CPrintToChat(client, "%T", "DDR_NPC_Bar_Drink2_Result", client);
			ClientCommand(client, "r_screenoverlay effects/com_shield002a.vmt");
		}
		else if (StrEqual(sParam, "beer"))
		{
			CPrintToChat(client, "%T", "DDR_NPC_Bar_Drink3_Result", client);
			ClientCommand(client, "r_screenoverlay effects/tp_eyefx/tp_eyefx.vmt");
		}
		else if (StrEqual(sParam, "vodka"))
		{
			CPrintToChat(client, "%T", "DDR_NPC_Bar_Drink4_Result", client);
			ClientCommand(client, "r_screenoverlay effects/tp_refract.vmt");
		}
	}
	else if (action == MenuAction_End)
		if(menu != null)
			delete menu;
}

void NPCTouchDealer(int client)
{
	if(GetEngineVersion() != Engine_CSGO)
	{
		Menu menu = new Menu(NPCDealer_MenuHandler);
		
		SetMenuTitle(menu, "%T", "DDR_NPC_Dealer_Title", client);
		
		char sBuffer1[64], sBuffer2[64];
		
		Format(sBuffer1, sizeof(sBuffer1), "%T", "DDR_NPC_Dealer_Drug1", client);
		Format(sBuffer2, sizeof(sBuffer2), "%T", "DDR_NPC_Dealer_Drug2", client);
		
		AddMenuItem(menu, "weed", sBuffer1);
		AddMenuItem(menu, "lsd", sBuffer2);
		
		SetMenuExitButton(menu, true);
		
		DisplayMenu(menu, client, MENU_TIME_FOREVER);
	}
}

public int NPCDealer_MenuHandler(Menu menu, MenuAction action, int client, int param)
{
	if (action == MenuAction_Select)
	{
		char sParam[16];
		GetMenuItem(menu, param, sParam, sizeof(sParam));
		
		if (StrEqual(sParam, "weed"))
		{
			CPrintToChat(client, "%T", "DDR_NPC_Dealer_Drug1_Result", client);
			ClientCommand(client, "r_screenoverlay models/effects/portalfunnel_sheet.vmt");
		}
		else if (StrEqual(sParam, "lsd"))
		{
			CPrintToChat(client, "%T", "DDR_NPC_Dealer_Drug2_Result", client);
			ClientCommand(client, "r_screenoverlay models/props_combine/portalball001_sheet.vmt");
		}
	}
	else if (action == MenuAction_End)
		if(menu != null)
			delete menu;
}

void NPCTouchDj(int client)
{
	OpenSongsList(client);
}

void NPCTouchGames(int client)
{
	OpenGamesList(client);
}

public Action Event_OnPlayerSpawn(Handle event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (!client || !IsClientInGame(client) || GetClientTeam(client) <= 1 || IsFakeClient(client))
		return Plugin_Continue;
	
	return Plugin_Continue;
}

public Action Event_PlayerDeath(Handle event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (GetClientTeam(client) > 1)
		RequestFrame(delayedrespawn, client);
}

void CheckNPCRange()
{
	if (Entity_IsValid(g_iNpcBar))
	{
		for (int j = 1; j <= MaxClients; j++)
		{
			if (!Client_IsValid(j, true))
				continue;
			
			if (!IsClientInGame(j))
				continue;
			
			if (!IsPlayerAlive(j))
				continue;
			
			if (Entity_InRange(g_iNpcBar, j, 128.0))
			{
				NPC_LookAtClient(g_iNpcBar, j);
				break;
			}
		}
	}
	
	if (Entity_IsValid(g_iNpcDealer))
	{
		for (int j = 1; j <= MaxClients; j++)
		{
			if (!Client_IsValid(j, true))
				continue;
			
			if (!IsClientInGame(j))
				continue;
			
			if (!IsPlayerAlive(j))
				continue;
			
			if (Entity_InRange(g_iNpcDealer, j, 128.0))
			{
				NPC_LookAtClient(g_iNpcDealer, j);
				break;
			}
		}
	}
	
	if (Entity_IsValid(g_iNpcDj))
	{
		for (int j = 1; j <= MaxClients; j++)
		{
			if (!Client_IsValid(j, true))
				continue;
			
			if (!IsClientInGame(j))
				continue;
			
			if (!IsPlayerAlive(j))
				continue;
			
			if (Entity_InRange(g_iNpcDj, j, 128.0))
			{
				NPC_LookAtClient(g_iNpcDj, j);
				break;
			}
		}
	}
	
	if (Entity_IsValid(g_iNpcGames))
	{
		for (int j = 1; j <= MaxClients; j++)
		{
			if (!Client_IsValid(j, true))
				continue;
			
			if (!IsClientInGame(j))
				continue;
			
			if (!IsPlayerAlive(j))
				continue;
			
			if (Entity_InRange(g_iNpcGames, j, 128.0))
			{
				NPC_LookAtClient(g_iNpcGames, j);
				break;
			}
		}
	}
	
	if (Entity_IsValid(g_iNpcShop))
	{
		for (int j = 1; j <= MaxClients; j++)
		{
			if (!Client_IsValid(j, true))
				continue;
			
			if (!IsClientInGame(j))
				continue;
			
			if (!IsPlayerAlive(j))
				continue;
			
			if (Entity_InRange(g_iNpcShop, j, 500.0))
			{
				NPC_LookAtClient(g_iNpcShop, j);
				break;
			}
		}
	}
}

void NPC_LookAtClient(int npc, int client)
{
	float angle[3], vec[3], vecClient[3], vecNPC[3];
	
	Entity_GetAbsOrigin(npc, vecNPC);
	GetClientAbsOrigin(client, vecClient);
	
	MakeVectorFromPoints(vecNPC, vecClient, vec);
	
	GetVectorAngles(vec, angle);
	angle[0] = 0.0;
	angle[2] = 0.0;
	
	TeleportEntity(npc, NULL_VECTOR, angle, NULL_VECTOR);
} 