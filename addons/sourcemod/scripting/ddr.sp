#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <cstrike>
#include <SteamWorks>

#include <smlib>
#include <multicolors>
#include <emitsoundany>
#include <smartdm>
#include <ddr>

#undef REQUIRE_PLUGIN
#tryinclude <xenforo_api>
#tryinclude <CustomPlayerSkins>

#pragma newdecls required

#include "ddr/settings.sp"
#include "ddr/globals.sp"
#include "ddr/stocks.sp"
#include "ddr/npcs.sp"
#include "ddr/sql.sp"
#include "ddr/commands.sp"

public Plugin myinfo = 
{
	name = "Dance Dance Revolution", 
	author = "Steven, Zipcore, Bara", 
	description = "Dance Dance Revolution for CS:GO", 
	version = "1.0.<ID>-beta", 
	url = "fotg.net"
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	__pl_xenforo_api_SetNTVOptional();
	__pl_CustomPlayerSkins_SetNTVOptional();
	
	CreateNative("DDR_IsClientInGame", Native_IsClientInGame);
	CreateNative("DDR_GetClientLevel", Native_GetClientLevel);
	
	g_hClientEnterSong = CreateGlobalForward("DDR_ClientEnterSong", ET_Ignore, Param_Cell);
	g_hClientLeftSong = CreateGlobalForward("DDR_ClientLeftSong", ET_Ignore, Param_Cell);
	g_hOnSongStart = CreateGlobalForward("DDR_OnSongStart", ET_Hook, Param_Cell, Param_Cell, Param_String);
	g_hOnSongEnd = CreateGlobalForward("DDR_OnSongEnd", ET_Ignore, Param_Cell, Param_String);
	
	RegPluginLibrary("ddr");
	
	return APLRes_Success;
}

public void OnPluginStart()
{
	if (GetExtensionFileStatus("accelerator.ext") != 1)
		SetFailState("Please use \"Dance Dance Revolution\" only with accelerator!");
		
	if(GetEngineVersion() != Engine_CSGO)
		SetFailState("Only CS:GO supported!");
	
	LoadTranslations("ddr.phrases");
	
	Experience_Generate();
	
	SQL_TConnect(Connect_DataBase, "ddr");
	
	LoadDifficulties();
	
	if (ArrayWaitListSongIDClientID != null)
		ArrayWaitListSongIDClientID.Clear();
	
	if (ArrayWaitListSongID != null)
		ArrayWaitListSongID.Clear();
	
	if (ArrayWaitListDifficulty != null)
		ArrayWaitListDifficulty.Clear();
	
	ArrayWaitListSongIDClientID = new ArrayList();
	ArrayWaitListSongID = new ArrayList();
	ArrayWaitListDifficulty = new ArrayList();
	status = STATUS_NO_WAITLIST;
	
	ResetAll();

	HookEvent("round_start", Event_RoundStart);
	HookEvent("player_team", Event_PlayerTeamPre, EventHookMode_Pre);
	HookEvent("player_team", Event_PlayerTeamPost, EventHookMode_Post);
	HookEvent("player_disconnect", Event_PlayerDisconnect, EventHookMode_Pre);
	HookEvent("player_connect", Event_PlayerConnect, EventHookMode_Pre);
	HookEvent("player_death", Event_PlayerDeathPre, EventHookMode_Pre);
	HookEvent("player_spawn", Event_PlayerSpawn);
	
	RegAdminCmd("sm_ddr", cmd_song, ADMFLAG_GENERIC);
	
	char sBuffer[32];
	
	for (int j; j < sizeof(g_sStopCMD); j++)
	{
		Format(sBuffer, sizeof(sBuffer), "sm_%s", g_sStopCMD[j]);
		RegConsoleCmd(sBuffer, cmd_stop);
	}
	
	for (int j; j < sizeof(g_sRankCMD); j++)
	{
		Format(sBuffer, sizeof(sBuffer), "sm_%s", g_sRankCMD[j]);
		RegConsoleCmd(sBuffer, cmd_rank);
	}
	
	for (int j; j < sizeof(g_sLevelCMD); j++)
	{
		Format(sBuffer, sizeof(sBuffer), "sm_%s", g_sLevelCMD[j]);
		RegConsoleCmd(sBuffer, cmd_level);
	}
	
	for (int j; j < sizeof(g_sResetCMD); j++)
	{
		Format(sBuffer, sizeof(sBuffer), "sm_%s", g_sResetCMD[j]);
		RegAdminCmd(sBuffer, cmd_reset, ADMFLAG_GENERIC);
	}
	
	RegConsoleCmd("sm_solo", cmd_solo);
	RegConsoleCmd("sm_team1", cmd_team1);
	RegConsoleCmd("sm_t1", cmd_team1);
	RegConsoleCmd("sm_team2", cmd_team2);
	RegConsoleCmd("sm_t2", cmd_team2);
	RegConsoleCmd("sm_lobby", cmd_lobby);
	
	// commands
	RegConsoleCmd("sm_respawn", cmd_respawn);
	
	RegAdminCmd("sm_rr", cmd_rr, ADMFLAG_GENERIC); // round restart
	RegAdminCmd("sm_mr", cmd_mr, ADMFLAG_GENERIC); // map restart
	RegAdminCmd("sm_start", cmd_start, ADMFLAG_GENERIC); // faster song start
	
	RegConsoleCmd("jointeam", ForceTeam);
	
	AddCommandListener(Command_Say, "say");
	AddCommandListener(Command_Say, "say_team");
	
	g_hTimerCheckMode = CreateTimer(1.0, CheckGame_Status, _, TIMER_REPEAT);
	StartGlowTimer();
	
	//NPCs
	HookNPCs();
	
	SetDescription();
	
	m_flNextPrimaryAttack = FindSendPropInfo("CBaseCombatWeapon", "m_flNextPrimaryAttack");
	m_flNextSecondaryAttack = FindSendPropInfo("CBaseCombatWeapon", "m_flNextSecondaryAttack");
	
	g_cImmunityAlpha = FindConVar("sv_disable_immunity_alpha");
	if(g_cImmunityAlpha != null)
	{
		g_cImmunityAlpha.SetBool(true);
		g_cImmunityAlpha.AddChangeHook(ConVar_OnImmunityAlphaChanged);
	}
}

public void ConVar_OnImmunityAlphaChanged(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	if(!cvar.BoolValue)
		cvar.SetBool(true);
}

public void OnAllPluginsLoaded()
{
	if(LibraryExists("xenforo_api"))
		g_bXenForo = true;
	
	if(LibraryExists("CustomPlayerSkins"))
		g_bCPS = true;
}

public void OnLibraryAdded(const char[] library)
{
	if(StrEqual(library, "xenforo_api", false))
		g_bXenForo = true;
	
	if(StrEqual(library, "CustomPlayerSkins", false))
		g_bCPS = true;
}

public void OnLibraryRemoved(const char[] library)
{
	if(StrEqual(library, "xenforo_api", false))
		g_bXenForo = false;
	
	if(StrEqual(library, "CustomPlayerSkins", false))
		g_bCPS = false;
}

void StartGlowTimer()
{
	CreateTimer(1.0, Timer_Glow, _, TIMER_REPEAT);
}

public Action Timer_Glow(Handle timer)
{
	if(g_bCPS)
		LoopClients(client)
			if (IsClientInGame(client) && IsPlayerAlive(client))
				SetupGlowSkin(client);
	
	return Plugin_Continue;
}

void SetupGlowSkin(int client)
{
	if(!g_bCPS)
		return;
	
	char sModel[PLATFORM_MAX_PATH];
	GetClientModel(client, sModel, sizeof(sModel));
	int iSkin = CPS_SetSkin(client, sModel, CPS_RENDER);
	
	if(iSkin == -1)
		return;
		
	if (SDKHookEx(iSkin, SDKHook_SetTransmit, OnSetTransmit_GlowSkin))
		SetupGlow(iSkin);
}

void SetupGlow(int iSkin)
{
	int iOffset;
	
	if (!iOffset && (iOffset = GetEntSendPropOffs(iSkin, "m_clrGlow")) == -1)
		return;
	
	SetEntProp(iSkin, Prop_Send, "m_bShouldGlow", false, true);
	SetEntProp(iSkin, Prop_Send, "m_nGlowStyle", 0);
	SetEntPropFloat(iSkin, Prop_Send, "m_flGlowMaxDist", 10000000.0);
	
	SetEntData(iSkin, iOffset, 0, _, true);
	SetEntData(iSkin, iOffset + 1, 0, _, true);
	SetEntData(iSkin, iOffset + 2, 0, _, true);
	SetEntData(iSkin, iOffset + 3, 0, _, true);
}

public Action OnSetTransmit_GlowSkin(int iSkin, int client)
{
	return Plugin_Handled;
}

public Action Timer_AutoRespawn(Handle timer)
{
	LoopClients(j)
		if (IsClientInGame(j) && GetClientTeam(j) > CS_TEAM_SPECTATOR && !IsPlayerAlive(j))
			CS_RespawnPlayer(j);
}

public Action CheckGame_Status(Handle timer)
{
	int where[MAXPLAYERS + 1];
	char sWhere[MAXPLAYERS + 1][256];
	
	int iSize = ArrayWaitListSongIDClientID.Length;
	
	// Testrun
	if (status == STATUS_IN_GAME)
	{
		if (g_bTestingSong)
		{
			// Better multi language support
			LoopClients(j)
				if (IsClientInGame(j) && IsPlayerAlive(j) && !IsFakeClient(j))
					PrintHintText(j, "%T", "DDR_Admin_Testing", j);
		}
		return;
	}
	
	// Recording
	if (g_bIsInRecord)
	{
		// Better multi language support
		LoopClients(j)
		{
			if (IsClientInGame(j) && IsPlayerAlive(j) && !IsFakeClient(j))
				PrintHintText(j, "%T", "DDR_Admin_Recording", j);
		}
		return;
	}
	
	// Reset team counts
	g_iTeam1 = 0;
	g_iTeam2 = 0;
	g_iSolo = 0;
	
	// Get player location and count teams
	LoopClients(j)
	{
		if (IsClientInGame(j) && IsPlayerAlive(j) && !IsFakeClient(j))
		{
			if (g_bVip[j] && g_PlayerDatas[j][LEVEL] < ZONE_VIP_LEVEL && !CheckCommandAccess(j, "sm_ddr", ADMFLAG_GENERIC, false))
			{
				CPrintToChat(j, "%T", "DDR_Zone_NotAllowed", j, g_sLogo[j], ZONE_VIP_LEVEL);
				
				g_bVip[j] = false;
				
				// Fix Glitch and we troll players ;)
				ForcePlayerSuicide(j);
			}
			
			where[j] = WhereIsPlayer(j);
			if (where[j] == TEAMS_TEAM1)
			{
				Format(sWhere[j], sizeof(sWhere[]), "%T", "DDR_Team1", j);
				g_iTeam1++;
			}
			else if (where[j] == TEAMS_TEAM2)
			{
				Format(sWhere[j], sizeof(sWhere[]), "%T", "DDR_Team2", j);
				g_iTeam2++;
			}
			else if (where[j] == TEAMS_SOLO)
			{
				Format(sWhere[j], sizeof(sWhere[]), "%T", "DDR_Solo", j);
				g_iSolo++;
			}
			else
			{
				Format(sWhere[j], sizeof(sWhere[]), "%T", "DDR_Not_Chosen", j);
			}
			
			// set mvp
			if (g_PlayerDatas[j][LEVEL] > 0)
				CS_SetMVPCount(j, g_PlayerDatas[j][LEVEL]);
		}
	}
	
	// Wait list empty
	if (status == STATUS_NO_WAITLIST && iSize == 0)
	{
		LoopClients(j)
			if (IsClientInGame(j) && IsPlayerAlive(j) && !IsFakeClient(j))
				PrintHintText(j, "%T", "DDR_Empty_WaitList", j, sWhere[j]);
	}
	
	// Set next song
	else if (status == STATUS_NO_WAITLIST && iSize > 0 && !g_bSongSelected)
	{
		g_iComingSongId = ArrayWaitListSongID.Get(0);
		g_iComingSongDifficulty = ArrayWaitListDifficulty.Get(0);
		g_iNextClient = ArrayWaitListSongIDClientID.Get(0);
		
		ArrayWaitListSongIDClientID.Erase(0);
		ArrayWaitListSongID.Erase(0);
		ArrayWaitListDifficulty.Erase(0);
		
		ArrayMusicName.GetString(g_iComingSongId, g_sNextMusic, sizeof(g_sNextMusic));
		LoopClients(j)
		{
			if (IsClientInGame(j) && IsPlayerAlive(j) && !IsFakeClient(j))
			{
				CPrintToChat(j, "%T", "DDR_Next_Song_Name", j, g_sLogo[j], g_sNextMusic, g_iDifficulty[g_iComingSongDifficulty][color], g_iDifficulty[g_iComingSongDifficulty][upperName]);
				CPrintToChat(j, "%T", "DDR_Next_Song_Chosen_By", j, g_sLogo[j], g_iNextClient);
			}
		}
		
		status = STATUS_GAME_COUNTDOWN;
		g_iCountdown = GAME_COUNTDOWN;
		
		g_bIsGameTeam = false;
		g_bSongSelected = true;
	}
	
	// Countdown
	else if (status == STATUS_GAME_COUNTDOWN && g_iCountdown >= 0)
	{
		g_iCountdown--;
		
		LoopClients(j)
		{
			if (IsClientInGame(j) && IsPlayerAlive(j) && !IsFakeClient(j))
			{
				PrintHintText(j, "%T", "DDR_TeamCount_Platform", j, g_iTeam1, g_iTeam2, sWhere[j]);
				
				if (g_iCountdown == 25)
					CPrintToChat(j, "%T", "DDR_Song_Countdown_10", j, g_sLogo[j], g_sNextMusic, g_iDifficulty[g_iComingSongDifficulty][color], g_iDifficulty[g_iComingSongDifficulty][upperName], g_iCountdown);
				else if (g_iCountdown == 20)
					CPrintToChat(j, "%T", "DDR_Song_Countdown_10", j, g_sLogo[j], g_sNextMusic, g_iDifficulty[g_iComingSongDifficulty][color], g_iDifficulty[g_iComingSongDifficulty][upperName], g_iCountdown);
				else if (g_iCountdown == 15)
					CPrintToChat(j, "%T", "DDR_Song_Countdown_10", j, g_sLogo[j], g_sNextMusic, g_iDifficulty[g_iComingSongDifficulty][color], g_iDifficulty[g_iComingSongDifficulty][upperName], g_iCountdown);
				else if (g_iCountdown == 10)
					CPrintToChat(j, "%T", "DDR_Song_Countdown_10", j, g_sLogo[j], g_sNextMusic, g_iDifficulty[g_iComingSongDifficulty][color], g_iDifficulty[g_iComingSongDifficulty][upperName], g_iCountdown);
			}
		}
		
		// Play countdown sounds
		if (g_iCountdown <= 5 && g_iCountdown >= 1)
		{
			char sSoundPath[PLATFORM_MAX_PATH + 1];
			Format(sSoundPath, sizeof(sSoundPath), "%s/%d.mp3", PATH_SOUND_EVENTS, g_iCountdown);
			
			LoopClients(j)
			{
				if (IsClientInGame(j) && !IsFakeClient(j))
				{
					// Play sound
					float fVolume = DDR_VOLUME_COUNTDOWN;
					EmitSoundToClientAny(j, sSoundPath, _, _, _, _, fVolume);
					
					// Chat
					char sBuffer[12];
					Format(sBuffer, sizeof(sBuffer), "%T", "DDR_Seconds", j);
					CPrintToChat(j, "%T", "DDR_Song_Countdown_5", 
						j, 
						g_sLogo[j], 
						g_sNextMusic, 
						g_iDifficulty[g_iComingSongDifficulty][color], 
						g_iDifficulty[g_iComingSongDifficulty][upperName], 
						g_iCountdown, 
						(g_iCountdown > 1 ? sBuffer:"")
						);
				}
			}
		}
		
		//Check teams
		if (g_iTeam1 >= 2 || g_iTeam2 >= 2)
		{
			if (g_iTeam1 == g_iTeam2)
			{
				if (!g_bIsGameTeam)
				{
					// Better multi language support
					LoopClients(j)
						if (IsClientInGame(j) && IsPlayerAlive(j) && !IsFakeClient(j))
							CPrintToChat(j, "%T", "DDR_Team_Balanced", j, g_sLogo[j]);
				}
				g_bIsGameTeam = true;
			}
			else
			{
				if (g_bIsGameTeam)
				{
					// Better multi language support
					LoopClients(j)
						if (IsClientInGame(j) && IsPlayerAlive(j) && !IsFakeClient(j))
							CPrintToChat(j, "%T", "DDR_Team_Not_Balanced", j, g_sLogo[j]);
				}
				g_bIsGameTeam = false;
			}
		}
		else
		{
			if (g_bIsGameTeam)
			{
				// Better multi language support
				LoopClients(j)
					if (IsClientInGame(j) && IsPlayerAlive(j) && !IsFakeClient(j))
						CPrintToChat(j, "%T", "DDR_Team_Not_Balanced", j, g_sLogo[j]);
			}
			g_bIsGameTeam = false;
		}
		
		// Setup game
		if (g_iCountdown == 0)
		{
			g_bTestingSong = false;
			
			Action res = Plugin_Continue;
			Call_StartForward(g_hOnSongStart);
			Call_PushCell(g_iComingSongId);
			Call_PushCell(g_iComingSongDifficulty);
			Call_PushString(g_sNextMusic);
			Call_Finish(res);
			
			if(res > Plugin_Changed)
				return;
			
			// Play ready sound
			LoopClients(j)
			{
				if (IsClientInGame(j) && !IsFakeClient(j))
				{
					// Prepare INSANE
					if (g_iComingSongDifficulty == DIFFICULTY_INSANE)
					{
						char sBuffer[PLATFORM_MAX_PATH + 1];
						Format(sBuffer, sizeof(sBuffer), "%s/insane.mp3", PATH_SOUND_EVENTS);
						
						float fVolume = DDR_VOLUME_INSANE;
						EmitSoundToClientAny(j, sBuffer, _, _, _, _, fVolume);
						
						// ClientCommand(j, "playgamesound \"%s/insane.mp3\"", PATH_SOUND_EVENTS);
					}
					else
					{
						char sBuffer[PLATFORM_MAX_PATH + 1];
						Format(sBuffer, sizeof(sBuffer), "%s/ready.mp3", PATH_SOUND_EVENTS);
						
						float fVolume = DDR_VOLUME_READY;
						EmitSoundToClientAny(j, sBuffer, _, _, _, _, fVolume);
						
						// ClientCommand(j, "playgamesound \"%s/ready.mp3\"", PATH_SOUND_EVENTS);
					}
				}
			}
			
			// Setup Game
			if (g_bIsGameTeam)
			{
				if (g_hArrayTeam_1 == null)
					g_hArrayTeam_1 = new ArrayList(1);
				else
					g_hArrayTeam_1.Clear();
				
				if (g_hArrayTeam_2 == null)
					g_hArrayTeam_2 = new ArrayList(1);
				else
					g_hArrayTeam_2.Clear();
				
				if (g_hArrayTeam_Solo == null)
					g_hArrayTeam_Solo = new ArrayList(1);
				else
					g_hArrayTeam_Solo.Clear();
				
				// Add player to game
				LoopClients(j)
				{
					if (IsClientInGame(j) && IsPlayerAlive(j))
					{
						if (where[j] == TEAMS_TEAM1)
							g_hArrayTeam_1.Push(j);
						else if (where[j] == TEAMS_TEAM2)
							g_hArrayTeam_2.Push(j);
						else if (where[j] == TEAMS_SOLO)
							g_hArrayTeam_Solo.Push(j);
					}
				}
				
				// Teams unbalanced
				if (g_iTeam1 > 0 && g_iTeam2 > 0 && g_hArrayTeam_1.Length != g_hArrayTeam_2.Length)
				{
					LoopClients(j)
					{
						if (IsClientInGame(j) && IsPlayerAlive(j) && !IsFakeClient(j))
							CPrintToChat(j, "%T", "DDR_Team_Not_Balanced_After_Start", j, g_sLogo[j]);
					}
					g_bIsGameTeam = false;
				}
				// We got balanced teams
				else
				{
					char s_team1[512], s_team2[512], s_solo[512];
					
					for (int j = 0; j < g_hArrayTeam_1.Length; j++)
						Format(s_team1, sizeof(s_team1), "%s %N", s_team1, g_hArrayTeam_1.Get(j));
					
					for (int j = 0; j < g_hArrayTeam_2.Length; j++)
						Format(s_team2, sizeof(s_team2), "%s %N", s_team2, g_hArrayTeam_2.Get(j));
					
					for (int j = 0; j < g_hArrayTeam_Solo.Length; j++)
						Format(s_solo, sizeof(s_solo), "%s %N", s_solo, g_hArrayTeam_Solo.Get(j));
					
					LoopClients(j)
					{
						if (IsClientInGame(j) && IsPlayerAlive(j) && !IsFakeClient(j))
						{
							CPrintToChat(j, "%T", "DDR_Team1_Players", j, g_sLogo[j], s_team1);
							CPrintToChat(j, "%T", "DDR_Team2_Players", j, g_sLogo[j], s_team2);
							if (g_iSolo > 0)
								CPrintToChat(j, "%T", "DDR_Solo_Players", j, g_sLogo[j], s_solo);
						}
					}
				}
			}
			
			g_iCountdown = -1;
			PlayMusic(g_iNextClient, g_iComingSongId, g_iComingSongDifficulty);
		}
	}
	
	for (int i = GetMaxClients(); i < GetMaxEntities(); i++)
	{
		if (IsValidEdict(i) && IsValidEntity(i))
		{
			char entity[64];
			GetEntityClassname(i, entity, sizeof(entity));
			
			if (!StrEqual(entity, "weapon_smokegrenade", false))
				if ((StrContains(entity, "weapon_", false) != -1 || StrContains(entity, "item_", false) != -1) && GetEntDataEnt2(i, FindSendPropInfo("CBaseCombatWeapon", "m_hOwnerEntity")) == -1)
					RemoveEdict(i);
		}
	}
	
	if (g_bIsInGame)
	{
		int count = 0;
		LoopClients(i)
			if (IsClientInGame(i) && !IsFakeClient(i) && IsPlayerAlive(i) && g_iPlayers[i][LIFE] > 0 && g_iPlayers[i][INGAME])
				count++;
		
		if (count == 0)
		{
			for (int z = 0; z < MAX_SEQUENCE_LINES; z++)
			{
				TrashTimer(g_hSequenceTimer[z]);
				LoopClients(x)
					g_bHUDArrowCanView[x][z] = false;
			}
			g_hSequenceTimer[0] = CreateTimer(3.0, Timer_EndMusic, 0);
		}
	}
}

public void OnEntityCreated(int entity, const char[] classname)
{
	if (StrEqual(classname, "smokegrenade_projectile"))
		SDKHook(entity, SDKHook_Spawn, OnEntitySpawned);
}

public void OnEntitySpawned(int entity)
{
	CreateTimer(0.0, Timer_RemoveThinkTick, entity, TIMER_FLAG_NO_MAPCHANGE);
}

public Action Timer_RemoveThinkTick(Handle timer, any entity)
{
	SetEntProp(entity, Prop_Data, "m_nNextThinkTick", -1);
	CreateTimer(0.0, Timer_RemoveFlashbang, entity, TIMER_FLAG_NO_MAPCHANGE);
}

public Action Timer_RemoveFlashbang(Handle timer, any entity)
{
	if (IsValidEntity(entity))
		AcceptEntityInput(entity, "Kill");
}

void OpenRank(int client)
{
	Menu menu = new Menu(Client_ListRank);
	
	menu.SetTitle("%T", "DDR_Main_Rank_Menu_Title", client, g_PlayerDatas[client][LEVEL], g_PlayerDatas[client][EXPERIENCE]);
	
	char sBuffer1[64], sBuffer2[64], sBuffer3[64], sBuffer4[64], sBuffer5[64], sBuffer6[64];
	
	Format(sBuffer1, sizeof(sBuffer1), "%T", "DDR_Main_Rank_Menu_Highscore", client);
	Format(sBuffer2, sizeof(sBuffer2), "%T", "DDR_Main_Rank_Menu_Profile", client);
	Format(sBuffer3, sizeof(sBuffer3), "%T", "DDR_Main_Rank_Menu_Online_Profile", client);
	Format(sBuffer4, sizeof(sBuffer4), "%T", "DDR_Main_Rank_Menu_Top50_Players", client);
	Format(sBuffer5, sizeof(sBuffer5), "%T", "DDR_Main_Rank_Menu_Top50_Scores", client);
	Format(sBuffer6, sizeof(sBuffer6), "%T", "DDR_Main_Rank_Menu_Top50_FC", client);
	
	menu.AddItem("2", sBuffer1);
	menu.AddItem("4", sBuffer2);
	menu.AddItem("5", sBuffer3);
	menu.AddItem("0", sBuffer4);
	menu.AddItem("3", sBuffer5);
	menu.AddItem("1", sBuffer6);
	
	SetMenuExitButton(menu, true);
	
	menu.Display(client, MENU_TIME_FOREVER);
}

public int Client_ListRank(Menu menu, MenuAction action, int client, int params)
{
	if (action == MenuAction_Select)
	{
		char sListRank[16];
		menu.GetItem(params, sListRank, sizeof(sListRank));
		int value = StringToInt(sListRank);
		if (value == 0)
			Show_Top30(client);
		else if (value == 1)
			Show_Top30FC(client);
		else if (value == 2)
			Show_Mes50TopScore(client);
		else if (value == 3)
			Show_Top50(client);
		else if (value == 4)
		{
			/*
			char url[256];
			Format(url, sizeof(url), "%s%sjoueurs.php?id=%d", FIX_URL, SITE_URL, g_PlayerDatas[client][DATABASE_ID]);
			DisplayUrlToClient(client, url);
			*/
		}
		else if (value == 5) {  }
		//Show_ClientList(client);
	}
	else if (action == MenuAction_End)
		delete menu;
}

stock void OpenGamesList(int client)
{
	Menu menu = new Menu(Client_GamesList);
	menu.SetTitle("%T", "DDR_Choose_Game", client);
	
	menu.AddItem("game_climb", "Climb");
	menu.AddItem("game_skipping", "Skipping Rope");
	menu.AddItem("game_hdiving", "High Diving"); // lag issue (?)
	menu.AddItem("game_soccer", "Soccer");
	// menu.AddItem("game_4wins", "Connect Four"); // lag issue
	menu.AddItem("game_tictactoe", "Tic Tac Toe");
	
	menu.ExitButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}


public int Client_GamesList(Menu menu, MenuAction action, int client, int params)
{
	if (action == MenuAction_Select)
	{
		char sTeleport[32];
		menu.GetItem(params, sTeleport, sizeof(sTeleport));
		CPrintToChat(client, "%T", "DDR_BackToLobby", client, g_sLogo[client]);
		
		int entindex = -1;
		char stringname[64];
		float fTeleport[3];
		
		while ((entindex = FindEntityByClassname(entindex, "info_teleport_destination")) != -1)
		{
			GetEntPropString(entindex, Prop_Data, "m_iName", stringname, sizeof(stringname));
			
			if (StrEqual(stringname, sTeleport))
				GetEntPropVector(entindex, Prop_Send, "m_vecOrigin", fTeleport);
		}
		
		TeleportEntity(client, fTeleport, NULL_VECTOR, NULL_VECTOR);
	}
	else if (action == MenuAction_End)
		if(menu != null)
			delete menu;
}

stock void OpenSongsList(int client)
{
	Menu menu = new Menu(Client_ListReply);
	
	menu.SetTitle("%T", "DDR_Choose_Song", client);
	
	char title[256], mp3name[256], SequenceFile[256], idx[5];
	
	for (int j = 0; j < ArrayMusicName.Length; j++)
	{
		ArrayMusicName.GetString(j, title, sizeof(title));
		ArrayMusicFile.GetString(j, mp3name, sizeof(mp3name));
		
		bool found = false;
		char sBuffer[256];
		for (int difficulty = 0; difficulty < DIFFICULTY_COUNT; difficulty++)
		{
			BuildPath(Path_SM, SequenceFile, sizeof(SequenceFile), "%s/%s_%s.txt", PATH_SONGS_CONFIG, mp3name, g_iDifficulty[difficulty][lowerName]);
			
			if (FileExists(SequenceFile))
			{
				found = true;
				Format(sBuffer, sizeof(sBuffer), "%s%s", sBuffer, g_iDifficulty[difficulty][shortName]);
			}
			
		}
		
		Format(title, sizeof(title), "%s [ %s]", title, sBuffer);
		
		if (found)
		{
			IntToString(j, idx, sizeof(idx));
			menu.AddItem(idx, title);
		}
		else
			menu.AddItem("", title, ITEMDRAW_DISABLED);
	}
	
	char sBack[64];
	Format(sBack, sizeof(sBack), "%T", "DDR_Back_First_Page", client);
	
	menu.AddItem("space", "", ITEMDRAW_SPACER);
	menu.AddItem("back", sBack);
	
	menu.ExitButton = true;
	
	menu.Display(client, MENU_TIME_FOREVER);
}

public int Client_ListReply(Menu menu, MenuAction action, int client, int params)
{
	if (action == MenuAction_Select)
	{
		char sSong[16];
		menu.GetItem(params, sSong, sizeof(sSong));
		
		if (StrEqual(sSong, "back"))
		{
			OpenSongsList(client);
			if(menu != null)
				delete menu;
			return;
		}
		
		g_iMenuPick[client] = StringToInt(sSong);
		OpenDifficultySelection(client);
	}
}

void OpenDifficultySelection(int client)
{
	int iSong = g_iMenuPick[client];
	
	char sTitle[256], sName[256], mp3name[256], SequenceFile[256];
	ArrayMusicName.GetString(iSong, sName, sizeof(sName));
	Format(sName, sizeof(sName), "%s", sName);
	Format(sTitle, sizeof(sTitle), "%T", "DDR_Choose_Difficulty", client, sName);
	Menu menu = new Menu(Client_DifficulteReply);
	
	menu.SetTitle(sTitle);
	
	ArrayMusicFile.GetString(g_iMenuPick[client], mp3name, sizeof(mp3name));
	
	char sDifficulty[16];
	for (int j = DIFFICULTY_EASY; j < DIFFICULTY_COUNT; j++)
	{
		IntToString(j, sDifficulty, 16);
		BuildPath(Path_SM, SequenceFile, 256, "%s/%s_%s.txt", PATH_SONGS_CONFIG, mp3name, g_iDifficulty[j][lowerName]);
		
		menu.AddItem(sDifficulty, g_iDifficulty[j][upperName], (FileExists(SequenceFile) ? ITEMDRAW_DEFAULT:ITEMDRAW_DISABLED));
		
	}
	
	char sBack[64];
	Format(sBack, sizeof(sBack), "%T", "DDR_Back_First_Page", client);
	
	menu.AddItem("space", "", ITEMDRAW_SPACER);
	menu.AddItem("back", sBack);
	
	menu.ExitButton = true;
	
	menu.Display(client, MENU_TIME_FOREVER);
}

public int Client_DifficulteReply(Menu menu, MenuAction action, int client, int params)
{
	if (action == MenuAction_Select)
	{
		char buffer[32];
		
		menu.GetItem(params, buffer, sizeof(buffer));
		if (StrEqual(buffer, "back"))
		{
			OpenSongsList(client);
			if(menu != null)
				delete menu;
			return;
		}
		else
		{
			int iDifficulty = StringToInt(buffer);
			
			int idx = ArrayWaitListSongIDClientID.FindValue(client);
			if (idx != -1)
			{
				ArrayWaitListSongID.Set(idx, g_iMenuPick[client]);
				ArrayWaitListDifficulty.Set(idx, iDifficulty);
			}
			else
			{
				idx = ArrayWaitListSongIDClientID.Push(client);
				ArrayWaitListSongID.Push(g_iMenuPick[client]);
				ArrayWaitListDifficulty.Push(iDifficulty);
			}
			
			CPrintToChat(client, "%T", "DDR_Add_Waitlist", client, g_sLogo[client], idx + 1, ArrayWaitListSongIDClientID.Length);
			
			if(ArrayMusicName.Length > 1)
			{
				char sTitle[256];
				ArrayMusicName.GetString(g_iMenuPick[client], sTitle, sizeof(sTitle));
				
				LoopClients(x)
					if (IsClientInGame(x))
						CPrintToChat(x, "%T", "DDR_Add_To_Waitlist", x, g_sLogo[x], client, sTitle, g_iDifficulty[iDifficulty][color], g_iDifficulty[iDifficulty][upperName]);
			}
		}
	}
	else if (action == MenuAction_End)
		if(menu != null)
			delete menu;
}

stock void ShowResultChat()
{
	int count = 1, client;
	char buffer[256];
	if (g_iLastPlayedId != -1)
		ArrayMusicName.GetString(g_iLastPlayedId, buffer, sizeof(buffer));
	
	int iPlayerCount = 0;
	LoopClients(i)
		if (IsClientInGame(i) && !IsFakeClient(i) && IsPlayerAlive(i) && g_iPlayers[i][LIFE] > 0 && g_iPlayers[i][INGAME])
			iPlayerCount++;
	
	if (iPlayerCount > 0)
	{
		LoopClients(x)
		{
			if (IsClientInGame(x))
			{
				PrintToConsole(x, "______________________________________________________________\n");
				PrintToConsole(x, "%T", "DDR_Console_Title", x);
				PrintToConsole(x, "______________________________________________________________\n");
				PrintToConsole(x, "%T", "DDR_Console_Stats_Title", x);
				PrintToConsole(x, "%T", "DDR_Console_Stats_Song", x, buffer, g_iDifficulty[g_iLastPlayedDifficulty][upperName]);
				PrintToConsole(x, "\n______________________________________________________________\n");
				
				if(g_bIsGameTeam)
				{
					char sBuffer[128];
					
					if (g_iScoreTeam1 == g_iScoreTeam2) // Draw
					{
						CPrintToChat(x, "%T", "DDR_Team_Draw", x, g_sLogo[x]);
						
						if (g_hArrayTeam_1.FindValue(x) != -1)
							Experience_Add(x, g_iScoreTeam1 / 100 * TEAMS_DRAW_EXP_PERCENT);
						else if (g_hArrayTeam_2.FindValue(x) != -1)
							Experience_Add(x, g_iScoreTeam2 / 100 * TEAMS_DRAW_EXP_PERCENT);
						
						Format(sBuffer, sizeof(sBuffer), "%T", "DDR_Console_Team_Draw", x);
					}
					else if (g_iScoreTeam1 > g_iScoreTeam2) // Team 1 win
					{
						CPrintToChat(x, "%T", "DDR_Team1_Win", x, g_sLogo[x]);
						
						if (g_hArrayTeam_1.FindValue(x) != -1)
							Experience_Add(x, g_iScoreTeam1 / 100 * TEAMS_WIN_EXP_PERCENT);
						else if (g_hArrayTeam_2.FindValue(x) != -1)
							Experience_Add(x, g_iScoreTeam2 / 100 * TEAMS_LOSE_EXP_PERCENT);
						
						Format(sBuffer, sizeof(sBuffer), "%T", "DDR_Console_Team1_Win", x);
					}
					else if (g_iScoreTeam2 > g_iScoreTeam1) // Team 2 win
					{
						CPrintToChat(x, "%T", "DDR_Team2_Win", x, g_sLogo[x]);
						
						if (g_hArrayTeam_1.FindValue(x) != -1)
							Experience_Add(x, g_iScoreTeam1 / 100 * TEAMS_LOSE_EXP_PERCENT);
						else if (g_hArrayTeam_2.FindValue(x) != -1)
							Experience_Add(x, g_iScoreTeam2 / 100 * TEAMS_WIN_EXP_PERCENT);
						
						Format(sBuffer, sizeof(sBuffer), "%T", "DDR_Console_Team2_Win", x);
					}
					
					char sTeam1[512], sTeam2[512];
					
					for (int j = 0; j < g_hArrayTeam_1.Length; j++)
						Format(sTeam1, sizeof(sTeam1), "%s %N", sTeam1, g_hArrayTeam_1.Get(j));
					
					for (int j = 0; j < g_hArrayTeam_2.Length; j++)
						Format(sTeam2, sizeof(sTeam2), "%s %N", sTeam2, g_hArrayTeam_2.Get(j));
					
					PrintToConsole(x, "DDR_Console_Team_Title", x);
					PrintToConsole(x, sBuffer, x);
					PrintToConsole(x, "\t%T", "DDR_Team1", x);
					PrintToConsole(x, "%T", "DDR_Console_Team1_Players", x, sTeam1);
					PrintToConsole(x, "%T", "DDR_Console_Team1_Stats", x, g_iScoreTeam1);
					PrintToConsole(x, " ");
					PrintToConsole(x, "\t%T", "DDR_Team2", x);
					PrintToConsole(x, "%T", "DDR_Console_Team2_Players", x, sTeam2);
					PrintToConsole(x, "%T", "DDR_Console_Team2_Stats", x, g_iScoreTeam2);
					PrintToConsole(x, "\n______________________________________________________________\n");
				}
				
				PrintToConsole(x, "%T", "DDR_Console_Player_Title", x);
			}
		}
		
		
		for (int i = 0; i < ArrayPlayerId.Length; i++)
		{
			client = ArrayPlayerId.Get(i);
			
			if (IsClientInGame(client) && g_iPlayers[client][INGAME])
			{
				LoopClients(x)
				{
					if (IsClientInGame(x))
					{
						char sPassed[24], sDead[24];
						
						Format(sPassed, sizeof(sPassed), "%T", "DDR_Passed", x);
						Format(sDead, sizeof(sDead), "%T", "DDR_Dead", x);
						
						PrintToConsole(x, "%T", "DDR_Console_Stats_Players", x, count, client, g_iPlayers[client][PERFECT], g_iPlayers[client][GOOD], g_iPlayers[client][MISS], g_iPlayers[client][BAD], (g_iPlayers[client][LIFE] <= 0 ? 0:g_iPlayers[client][LIFE]), g_iPlayers[client][MAX_COMBO]);
						CPrintToChat(x, "%T", "DDR_Chat_Stats_Players", x, g_sLogo[x], count, client, g_iPlayers[client][TOTAL], (g_iPlayers[client][LIFE] <= 0 ? sDead:sPassed));
					}
				}
				count++;
				
				if (g_hDatabase != null)
				{
					if (g_iPlayers[client][LIFE] > 0)
					{
						Experience_Add(client, g_iPlayers[client][TOTAL]);
						DataBase_UpdatePlayerDatas(client);
						
						char sQuery[650], user[64], communityid[32], sUser[MAX_NAME_LENGTH], sSong[1024];
						
						if(!GetClientAuthId(client, AuthId_SteamID64, communityid, sizeof(communityid)))
							return;
						
						if(!GetClientName(client, user, sizeof(user)))
							return;
						
						
						SQL_EscapeString(g_hDatabase, user, sUser, sizeof(sUser));
						SQL_EscapeString(g_hDatabase, buffer, sSong, sizeof(sSong));
						
						Format(sQuery, sizeof(sQuery), "INSERT INTO `ddr_rank` (`music_name`, `difficulty`, `nickname`, `communityid`, `timestamp`, `score`, `perfect`, `cool`, `bad`, `miss`, `combo`) VALUES ('%s', '%d', '%s', '%s', UNIX_TIMESTAMP(), '%d', '%d', '%d', '%d', '%d', '%d');", 
							sSong, g_iLastPlayedDifficulty, sUser, communityid, g_iPlayers[client][TOTAL], g_iPlayers[client][PERFECT], g_iPlayers[client][GOOD], g_iPlayers[client][BAD], g_iPlayers[client][MISS], g_iPlayers[client][MAX_COMBO]);
						SQLQuery(sQuery);
						
					}
				}
			}
		}
		
		LoopClients(x)
		{
			if (IsClientInGame(x))
			{
				CPrintToChat(x, "%T", "DDR_Look_Console", x);
				PrintToConsole(x, "\n______________________________________________________________");
			}
		}
	}
}

public Action ShowScoreBoard(Handle timer)
{
	if (!g_bIsInGame)
		return Plugin_Continue;
	
	// Reset team scores
	g_iScoreTeam1 = 0;
	g_iScoreTeam2 = 0;
	
	LoopClients(x)
	{
		if (!IsClientInGame(x) || IsFakeClient(x) || !IsPlayerAlive(x))
			continue;
		
		if (g_iPlayers[x][INGAME] || WhereIsPlayer(x) > TEAMS_NONE || g_bSpec[x])
		{
			char sTitle[256], sTimeleft[64];
			float fSec;
			int iPlayers;
			
			ArrayMusicName.GetString(g_iLastPlayedId, sTitle, sizeof(sTitle));
			fSec = GetSequenceTimeLeft();
			SecondsToTime(fSec, sTimeleft, sizeof(sTimeleft), 0);
			
			Format(sTitle, sizeof(sTitle), "%T", "DDR_Rank_Hint_Title", x, sTitle, g_iDifficulty[g_iLastPlayedDifficulty][upperName], sTimeleft);
			
			Panel panel = new Panel();
			panel.SetTitle(sTitle);
			panel.DrawText(" ");
			
			char sTeam1[64], sTeam2[64];
			
			for (int i = 0; i < ArrayPlayerId.Length; i++)
			{
				// Get player and his current score
				int player = ArrayPlayerId.Get(i);
				int score = ArrayPlayerScore.Get(i);
				
				// when we do it now, then we can save more resources.
				if (!IsClientInGame(player) && !g_iPlayers[player][INGAME] && score <= 0)
					continue;
				
				char sPlayer[256];
				if (!g_bIsGameTeam)
					iPlayers++;
				SetClientScore(player, score);
				
				if (g_bIsGameTeam)
				{
					if (g_hArrayTeam_1.FindValue(player) != -1 && g_iPlayers[player][LIFE] > 0)
						g_iScoreTeam1 += score;
					else if (g_hArrayTeam_2.FindValue(player) != -1 && g_iPlayers[player][LIFE] > 0)
						g_iScoreTeam2 += score;
					
					if (g_iScoreTeam1 > g_iScoreTeam2)
					{
						Format(sTeam1, sizeof(sTeam1), "%T", "DDR_Rank_Panel_Team1_Score", x, g_iScoreTeam1);
						Format(sTeam2, sizeof(sTeam2), "%T", "DDR_Rank_Panel_Team2_Score", x, g_iScoreTeam2);
					}
					else if (g_iScoreTeam1 < g_iScoreTeam2)
					{
						Format(sTeam2, sizeof(sTeam2), "%T", "DDR_Rank_Panel_Team2_Score", x, g_iScoreTeam2);
						Format(sTeam1, sizeof(sTeam1), "%T", "DDR_Rank_Panel_Team1_Score", x, g_iScoreTeam1);
					}
				}
				
				if (!g_bIsGameTeam && iPlayers <= RANK_HINT_LIMIT_PLAYERS)
				{
					Format(sPlayer, sizeof(sPlayer), "%T", "DDR_Rank_Hint_Players_Score", x, player, score, g_iPlayers[player][COMBO], g_iPlayers[player][MAX_COMBO], (g_iPlayers[player][LIFE] <= 0 ? 0:g_iPlayers[player][LIFE]));
					panel.DrawText(sPlayer);
				}
			}
			
			if (g_iScoreTeam1 > g_iScoreTeam2)
			{
				panel.DrawText(sTeam1);
				panel.DrawText(sTeam2);
			}
			else if (g_iScoreTeam1 < g_iScoreTeam2)
			{
				panel.DrawText(sTeam2);
				panel.DrawText(sTeam1);
			}
			
			if (g_bIsGameTeam)
			{
				panel.DrawText(" ");
				
				for (int i = 0; i < ArrayPlayerId.Length; i++)
				{
					// Get player and his current score
					int player = ArrayPlayerId.Get(i);
					int score = ArrayPlayerScore.Get(i);
					
					// when we do it now, then we can save more resources.
					if (!IsClientInGame(player) && !g_iPlayers[player][INGAME] && score <= 0)
						continue;
					
					char sPlayer[256];
					iPlayers++;
					SetClientScore(player, score);
					
					if (iPlayers <= RANK_HINT_LIMIT_PLAYERS)
					{
						Format(sPlayer, sizeof(sPlayer), "%T", "DDR_Rank_Hint_Players_Score", x, player, score, g_iPlayers[player][COMBO], g_iPlayers[player][MAX_COMBO], (g_iPlayers[player][LIFE] <= 0 ? 0:g_iPlayers[player][LIFE]));
						panel.DrawText(sPlayer);
					}
				}
			}
			
			panel.Send(x, MenuInGame, 1);
		}
		else
			continue;
	}
	
	return Plugin_Continue;
}

public int MenuInGame(Handle menu, MenuAction action, int client, int params)
{
	if (action == MenuAction_End)
	{
		delete menu;
	}
}

void SQLQuery(const char[] sQuery)
{
	LogMessage("[DDR] (SQLQuery) sQuery: %s", sQuery);
	SQL_TQuery(g_hDatabase, SQL_Callback, sQuery);
}

public void SQL_Callback(Handle owner, Handle hndl, const char[] error, any string)
{
	if (error[0])
	{
		LogError("[DDR] (SQL_Callback) Error with last query! %s", error);
		return;
	}
}

public Action RankThem(Handle timer)
{
	if (ArrayPlayerId == null)
		ArrayPlayerId = new ArrayList(1);
	else
		ArrayPlayerId.Clear();
	
	if (ArrayPlayerScore == null)
		ArrayPlayerScore = new ArrayList(1);
	else
		ArrayPlayerScore.Clear();
	
	LoopClients(i)
	{
		if (IsClientInGame(i) && IsPlayerAlive(i) && g_iPlayers[i][TOTAL] > 0)
		{
			ArrayPlayerId.Push(i);
			ArrayPlayerScore.Push(g_iPlayers[i][TOTAL]);
		}
	}
	
	int iSize2 = ArrayPlayerId.Length;
	
	int i, j;
	for (i = 0; i < iSize2; i++)
	{
		for (j = i; j < iSize2; j++)
		{
			if (ArrayPlayerScore.Get(i) < ArrayPlayerScore.Get(j))
			{
				ArrayPlayerId.SwapAt(i, j);
				ArrayPlayerScore.SwapAt(i, j);
			}
		}
	}
	return Plugin_Continue;
}

public void OnMapStart()
{
	PrecacheAndAddDL();
	
	ServerCommand("mp_restartgame 1");
	
	CreateTimer(5.0, Timer_AutoRespawn, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
	CreateTimer(1.5, Timer_CheckNPCs, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
}

public void OnConfigsExecuted()
{
	PrecacheAndAddDL();
	
	SetConVarBool(FindConVar("sv_ignoregrenaderadio"), true);
	
	char sBuffer[128];
	ConVar hTags = FindConVar("sv_tags");
	hTags.GetString(sBuffer, sizeof(sBuffer));
	Format(sBuffer, sizeof(sBuffer), "ddr, dance dance revolution, %s", sBuffer);
	
	if(hTags != null)
		hTags.SetString(sBuffer);
	
	SetDescription();
}

public Action EntityScoreTimer(Handle timer, any data)
{
	LoopClients(client)
	{
		if (!IsClientInGame(client))
			continue;
		
		char buffer[6];
		
		IntToString(g_iPlayers[client][TOTAL], buffer, 6);
		int iSize3 = strlen(buffer);
		
		int value = 0;
		for (int i = iSize3 - 1; i >= 0; i--)
		{
			g_iClientScoreEntity[client][value] = StringToInt(buffer[i]);
			buffer[i] = '\0';
			value++;
		}
	}
	return Plugin_Continue;
}

void Do_BotFreeze(int client)
{
	if (g_iViewControlTriggerEntity != -1)
	{
		float ori[3];
		GetEntPropVector(g_iViewControlTriggerEntity, Prop_Send, "m_vecOrigin", ori);
		TeleportEntity(client, ori, NULL_VECTOR, NULL_VECTOR);
		SetEntProp(client, Prop_Data, "m_takedamage", 0, 1);
		Client_RemoveAllWeapons(client);
		SetEntityMoveType(client, MOVETYPE_NONE);
	}
}

public Action FreezeDisBot(Handle timer, any client)
{
	if (IsClientInGame(client) && GetClientTeam(client) > CS_TEAM_SPECTATOR && IsPlayerAlive(client))
	{
		Do_BotFreeze(client);
		fStop(client);
		RenameBot(client);
	}
	return Plugin_Continue;
}

public Action Event_PlayerTeamPre(Handle event, const char[] name, bool dontBroadcast)
{
	return Plugin_Handled;
}

public Action Event_PlayerTeamPost(Handle event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	int team = GetEventInt(event, "team");
	
	if (IsClientInGame(client))
	{
		if (team == CS_TEAM_T)
		{
			LoopClients(i)
			{
				if (IsClientInGame(i))
				{
					if (i == client)
						CPrintToChat(client, "%T", "DDR_T_Join", client, g_sLogo[client]);
					else if (i != client)
						CPrintToChat(i, "%T", "DDR_T_Join_Other", i, g_sLogo[i], client);
				}
			}
		}
	}
}

public Action Event_PlayerConnect(Handle event, const char[] name, bool dontBroadcast)
{
	return Plugin_Handled;
}

public Action Event_PlayerDisconnect(Handle event, const char[] name, bool dontBroadcast)
{
	return Plugin_Handled;
}

public Action Event_PlayerDeathPre(Handle event, const char[] name, bool dontBroadcast)
{
	return Plugin_Handled;
}

public Action Event_PlayerSpawn(Handle event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	RenameBot(client);
	
	if (IsClientInGame(client) && IsFakeClient(client))
	{
		Do_BotFreeze(client);
		fStop(client);
		TrashTimer(g_hBotFreeze);
		g_hBotFreeze = CreateTimer(5.0, FreezeDisBot, client, TIMER_REPEAT);
	}
	
	if (GetClientTeam(client) == CS_TEAM_CT && !IsFakeClient(client) && IsClientInGame(client))
	{
		CS_SwitchTeam(client, CS_TEAM_T);
		CS_UpdateClientModel(client);
		RequestFrame(OnPlayerSpawn, client);
		TeleportEntity(client, g_fTeleLobby, NULL_VECTOR, NULL_VECTOR);
	}
	
	if (GetClientTeam(client) == CS_TEAM_T && IsClientInGame(client))
	{
		RequestFrame(OnPlayerSpawn, client);
		TeleportEntity(client, g_fTeleLobby, NULL_VECTOR, NULL_VECTOR);
		SetClientViewEntity(client, client);
	}
	
	SetClientRender(client, true);
}

public void OnPlayerSpawn(any client)
{
	if (IsClientInGame(client) && IsPlayerAlive(client))
	{
		StripPlayerWeapons(client);
		HideHud(client);
	}
}

void RenameBot(int client)
{
	if (IsClientInGame(client) && IsFakeClient(client) && IsPlayerAlive(client))
		SetClientName(client, "♪ ♫ DJ Unicorn ♫ ♪");
}

void fStop(int client)
{
	if (IsClientInGame(client) && IsPlayerAlive(client))
		SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", 0.0);
}

public void OnPluginEnd()
{
	TrashTimer(g_hTimerCheckMode, true);
	
	if (g_hDatabase != null)
	{
		delete g_hDatabase;
		g_hDatabase = null;
	}
}

public void OnClientConnected(int client)
{
	float curTime = GetGameTime();
	afLastUsed[client] = curTime;
}

public Action ForceTeam(int client, int args)
{
	if (args < 1)
		return Plugin_Handled;
	
	if (IsPlayerAlive(client))
		return Plugin_Handled;
	
	char buffer[256];
	GetCmdArgString(buffer, sizeof(buffer));
	
	int team = StringToInt(buffer);
	
	float curTime = GetGameTime();
	if (curTime - afLastUsed[client] != 0)
	{
		if (team > CS_TEAM_SPECTATOR)
		{
			CS_SwitchTeam(client, CS_TEAM_T);
			CS_RespawnPlayer(client);
		}
		afLastUsed[client] = curTime;
	}
	return Plugin_Handled;
}

public Action Command_Say(int client, const char[] command, int argc)
{
	if (IsChatTrigger())
		return Plugin_Handled;
	return Plugin_Continue;
}

public void delayedrespawn(any client)
{
	if (IsClientInGame(client) && GetClientTeam(client) > CS_TEAM_SPECTATOR && !IsPlayerAlive(client))
		CS_RespawnPlayer(client);
}

public void OnClientPutInServer(int client)
{
	g_iPlayers[client][TOTAL] = 0;
	for (int i = 0; i < 4; i++)
	{
		g_iClientScoreEntity[client][i] = 0;
	}
	
	ClearClientData(client);
	if (IsClientInGame(client))
	{
		Format(g_sLogo[client], sizeof(g_sLogo[]), "%T", "DDR_Chat_Logo", client);
		ClientCommand(client, "jointeam %d", (!IsFakeClient(client) ? 2:3));
		if (IsFakeClient(client))
		{
			CS_SwitchTeam(client, CS_TEAM_CT);
			CS_UpdateClientModel(client);
		}
	}
	
	if (!IsFakeClient(client))
	{
		UpdateNameClient(client);
		
		DataBase_GetDataFromPlayer(client);
	}
}

public void OnClientPostAdminCheck(int client)
{
	QueryClientConVar(client, "cl_downloadfilter", QueryConVar);
	
	// mute new player for ingame players
	LoopClients(i)
		if (IsClientInGame(i) && g_iPlayers[i][INGAME])
			MutePlayers(i);
}

public void QueryConVar(QueryCookie cookie, int client, ConVarQueryResult result, const char[] cvarName, const char[] cvarValue)
{
	if (strcmp(cvarValue, "all", false) == 0)
		return;
	
	KickClient(client, "%T", "DDR_Active_Download_Filter", client, cvarValue);
	
	return;
}

void UpdateNameClient(int client)
{
	if (g_hDatabase != null && !IsFakeClient(client))
	{
		char sQuery[360], buffer[64], communityid[32], sName[MAX_NAME_LENGTH];
		
		if(!GetClientAuthId(client, AuthId_SteamID64, communityid, sizeof(communityid)))
			return;
		
		if(!GetClientName(client, buffer, sizeof(buffer)))
			return;
		
		SQL_EscapeString(g_hDatabase, buffer, sName, sizeof(sName));
		
		Format(sQuery, sizeof(sQuery), "UPDATE  `ddr_rank` SET  `nickname` =  '%s' WHERE  `communityid` ='%s';", sName, communityid);
		SQLQuery(sQuery);
		
		Format(sQuery, sizeof(sQuery), "UPDATE  `ddr_playerdatas` SET  `nickname` =  '%s' WHERE  `communityid` ='%s';", sName, communityid);
		SQLQuery(sQuery);
	}
}

public void OnClientDisconnect(int client)
{
	// Remove clients songs from waitlist
	int idx = ArrayWaitListSongIDClientID.FindValue(client);
	if (idx != -1)
	{
		char sTitle[256];
		ArrayMusicName.GetString(g_iMenuPick[client], sTitle, sizeof(sTitle));
		
		LoopClients(x)
			if (IsClientInGame(x))
				CPrintToChat(x, "%T", "DDR_Remove_From_Waitlist", x, g_sLogo[x], sTitle, g_iDifficulty[g_iLastPlayedDifficulty][color], g_iDifficulty[g_iLastPlayedDifficulty][upperName]);
				
		ArrayWaitListSongIDClientID.Erase(idx);
		ArrayWaitListSongID.Erase(idx);
		ArrayWaitListDifficulty.Erase(idx);
	}
	
	// Clear Player
	ClearClientData(client);
	
	if (g_iPlayers[client][INGAME])
	{
		CheckAliveClient();
	}
	
	DataBase_UpdatePlayerDatas(client);
	
	if (IsClientInGame(client))
		LoopClients(i)
			if (IsClientInGame(i))
				CPrintToChat(i, "%T", "DDR_Player_Leave", i, g_sLogo[i], client);
}

stock void ManageHealth(int client, int health, bool AddLife = true)
{
	if (g_bTestingSong)
		return;
	
	if (AddLife)
	{
		if (g_iPlayers[client][COMBO_REGEN] >= LIFE_WIN_COMBO_AMOUNT)
		{
			g_iPlayers[client][LIFE] += LIFE_WIN_COMBO_LIFE;
			g_iPlayers[client][COMBO_REGEN] = 0;
		}
		
		int newhealth = (g_iPlayers[client][LIFE] + health);
		g_iPlayers[client][LIFE] = (newhealth > LIFE_TOTAL ? LIFE_TOTAL:newhealth);
	}
	else
	{
		g_iPlayers[client][LIFE] -= health;
		
		if (g_iPlayers[client][LIFE] <= 0)
		{
			LoopClients(i)
			{
				if (IsClientInGame(i))
					CPrintToChat(i, "%T", "DDR_Much_Failed", i, g_sLogo[i], client);
			}
			CheckAliveClient();
		}
	}
	
	HUD_UpdateHealthBar(client, client);
}

public Action HUD_Timer_LoadingHealthBar(Handle timer)
{
	if (g_iHUDHealthBarLoading == (LIFE_START/10))
		return Plugin_Stop;
	else
	{
		LoopClients(i)
			g_iHUDHealthBarValue[i]++;
		g_iHUDHealthBarLoading++;
		return Plugin_Continue;
	}
}

stock void HUD_ResetHealthBar(int client)
{
	g_iHUDHealthBarValue[client] = 0;
}

stock void HUD_UpdateHealthBar(int client, int target)
{
	int current = g_iPlayers[target][LIFE];
	
	if (current > 90)
		g_iHUDHealthBarValue[client] = 9;
	else if (current > 80)
		g_iHUDHealthBarValue[client] = 8;
	else if (current > 70)
		g_iHUDHealthBarValue[client] = 7;
	else if (current > 60)
		g_iHUDHealthBarValue[client] = 6;
	else if (current > 50)
		g_iHUDHealthBarValue[client] = 5;
	else if (current > 40)
		g_iHUDHealthBarValue[client] = 4;
	else if (current > 30)
		g_iHUDHealthBarValue[client] = 3;
	else if (current > 20)
		g_iHUDHealthBarValue[client] = 2;
	else if (current > 10)
		g_iHUDHealthBarValue[client] = 1;
	else if (current > 0)
		g_iHUDHealthBarValue[client] = 0;
	else
		g_iHUDHealthBarValue[client] = -1;
}

void OpenDdrAdminMenue(int client)
{
	Menu menu = new Menu(ListeReply);
	
	int iSongs = ArrayMusicName.Length;
	
	menu.SetTitle("%T", "DDR_Admin_Panel_Title", client, iSongs);
	
	char title[256], mp3name[256], SequenceFile[256], iSong[5];
	for (int i = 0; i < iSongs; i++)
	{
		IntToString(i, iSong, sizeof(iSong));
		ArrayMusicName.GetString(i, title, sizeof(title));
		ArrayMusicFile.GetString(i, mp3name, sizeof(mp3name));
		
		bool found = false;
		char sBuffer[256];
		for (int difficulty = DIFFICULTY_EASY; difficulty < DIFFICULTY_COUNT; difficulty++)
		{
			BuildPath(Path_SM, SequenceFile, sizeof(SequenceFile), "%s/%s_%s.txt", PATH_SONGS_CONFIG, mp3name, g_iDifficulty[difficulty][lowerName]);
			
			if (FileExists(SequenceFile))
			{
				found = true;
				Format(sBuffer, sizeof(sBuffer), "%s%s", sBuffer, g_iDifficulty[difficulty][shortName]);
			}
		}
		
		Format(title, sizeof(title), "%s [ %s]", title, sBuffer);
		if (found)
			menu.AddItem(iSong, title);
		else
			menu.AddItem(iSong, title);
	}
	
	menu.AddItem("space", "", ITEMDRAW_SPACER);
	menu.AddItem("back", "Back to first page");
	
	menu.ExitButton = true;
	
	menu.Display(client, MENU_TIME_FOREVER);
}

public int ListeReply(Menu menu, MenuAction action, int client, int params)
{
	if (action == MenuAction_Select)
	{
		char sSong[16];
		menu.GetItem(params, sSong, sizeof(sSong));
		
		if (StrEqual(sSong, "back"))
		{
			OpenDdrAdminMenue(client);
			if(menu != null)
				delete menu;
			return;
		}
		
		int iSong = StringToInt(sSong);
		g_iMenuPick[client] = iSong;
		
		OpenDifficultyMenu(client);
	}
	else if (action == MenuAction_End)
		if(menu != null)
			delete menu;
}

void OpenDifficultyMenu(int client)
{
	int iSong = g_iMenuPick[client];
	
	char title[256], mp3name[256], SequenceFile[256];
	bool available;
	ArrayMusicName.GetString(iSong, title, sizeof(title));
	ArrayMusicFile.GetString(iSong, mp3name, sizeof(mp3name));
	Format(title, sizeof(title), "%s - Choose a difficulty", title);
	Menu menu = new Menu(DifficulteReply);
	
	menu.SetTitle(title);
	
	char sDifficulty[16];
	for (int iDifficulty = DIFFICULTY_EASY; iDifficulty < DIFFICULTY_COUNT; iDifficulty++)
	{
		IntToString(iDifficulty, sDifficulty, 16);
		
		BuildPath(Path_SM, SequenceFile, 256, "%s/%s_%s.txt", PATH_SONGS_CONFIG, mp3name, g_iDifficulty[iDifficulty][lowerName]);
		available = FileExists(SequenceFile);
		
		char itemBuffer[256];
		Format(itemBuffer, sizeof(itemBuffer), "%s%s", g_iDifficulty[iDifficulty][upperName], (available ? "":" (No file)"));
		menu.AddItem(sDifficulty, itemBuffer);
	}
	
	menu.AddItem("space", "", ITEMDRAW_SPACER);
	
	char sBack[64];
	Format(sBack, sizeof(sBack), "%T", "DDR_Song_Selection", client);
	menu.AddItem("back", sBack);
	
	menu.ExitButton = true;
	
	menu.Display(client, MENU_TIME_FOREVER);
}

public int DifficulteReply(Menu menu, MenuAction action, int client, int params)
{
	if (action == MenuAction_Select)
	{
		char buffer[16];
		
		Menu menur = new Menu(ActionDifficulty);
		menu.GetItem(params, buffer, sizeof(buffer));
		
		if (StrEqual(buffer, "back"))
		{
			OpenDdrAdminMenue(client);
			if(menu != null)
				delete menu;
			return;
		}
		
		int value = StringToInt(buffer);
		char title[256], mp3name[256], SequenceFile[256];
		g_iMenuDifficulty[client] = value;
		ArrayMusicFile.GetString(g_iMenuPick[client], mp3name, sizeof(mp3name));
		ArrayMusicName.GetString(g_iMenuPick[client], title, sizeof(title));
		
		BuildPath(Path_SM, SequenceFile, sizeof(SequenceFile), "%s/%s_%s.txt", PATH_SONGS_CONFIG, mp3name, g_iDifficulty[value][lowerName]);
		
		Format(title, sizeof(title), "%s [%s]", title, g_iDifficulty[value][upperName]);
		
		menur.SetTitle(title);
		
		bool bFileExist = FileExists(SequenceFile);
		
		char sBuffer1[64], sBuffer2[64], sBuffer3[64], sBuffer4[64];
		
		Format(sBuffer1, sizeof(sBuffer1), "%T", "DDR_Test_Song", client);
		Format(sBuffer2, sizeof(sBuffer2), "%T", "DDR_Play_Song", client);
		Format(sBuffer3, sizeof(sBuffer3), "%T", "DDR_Record_Song", client);
		Format(sBuffer4, sizeof(sBuffer4), "%T", "DDR_Delete_Song", client);
		
		menur.AddItem("test", sBuffer1, (bFileExist ? ITEMDRAW_DEFAULT:ITEMDRAW_DISABLED));
		menur.AddItem("play", sBuffer2, (bFileExist ? ITEMDRAW_DEFAULT:ITEMDRAW_DISABLED));
		menur.AddItem("record", sBuffer3);
		menur.AddItem("delete", sBuffer4, (bFileExist ? ITEMDRAW_DEFAULT:ITEMDRAW_DISABLED));
		
		menur.AddItem("space", "", ITEMDRAW_SPACER);
		
		char sBack[64];
		Format(sBack, sizeof(sBack), "%T", "DDR_Song_Selection", client);
		menur.AddItem("back", sBack);
		
		menur.ExitButton = true;
		
		menur.Display(client, MENU_TIME_FOREVER);
		
	}
	else if (action == MenuAction_End)
		if(menu != null)
			delete menu;
}

public int ActionDifficulty(Menu menu, MenuAction action, int client, int params)
{
	if (action == MenuAction_Select)
	{
		char buffer[16];
		menu.GetItem(params, buffer, sizeof(buffer));
		
		if (StrEqual(buffer, "back"))
		{
			OpenDdrAdminMenue(client);
			if(menu != null)
				delete menu;
			return;
		}
		
		if (g_bIsInGame || g_bTestingSong || g_bIsInRecord)
		{
			OpenDdrAdminMenue(client);
			if(menu != null)
				delete menu;
			return;
		}
		
		ResetAll();
		
		g_iLastPlayedId = g_iMenuPick[client];
		if (StrEqual(buffer, "record"))
		{
			StartRecordSequence(client, g_iLastPlayedId, g_iMenuDifficulty[client]);
		}
		else if (StrEqual(buffer, "delete"))
		{
			StartRecordSequence(client, g_iLastPlayedId, g_iMenuDifficulty[client], true);
			OpenDifficultyMenu(client);
		}
		else if (StrEqual(buffer, "play"))
		{
			PlayMusic(client, g_iLastPlayedId, g_iMenuDifficulty[client]);
		}
		else if (StrEqual(buffer, "test"))
		{
			g_bTestingSong = true;
			PlayMusic(client, g_iLastPlayedId, g_iMenuDifficulty[client]);
		}
	}
	else if (action == MenuAction_End)
		if(menu != null)
			delete menu;
}

void HUD_BackgroundOff()
{
	char sName[256], sBuffer[256];
	
	if (strlen(g_StringLastTableau)  >= 2)
		Format(sBuffer, sizeof(sBuffer), "tableau_%s_off", g_StringLastTableau);
	
	if (strlen(sBuffer)  >= 2)
	{
		int iEnt;
		
		while ((iEnt = FindEntityByClassname(iEnt, "logic_relay")) != -1)
		{
			GetEntPropString(iEnt, Prop_Data, "m_iName", sName, sizeof(sName));
			
			if (StrEqual(sName, sBuffer))
				AcceptEntityInput(iEnt, "Trigger");
		}
	}
}

void HUD_BackgroundOn(int music_id = -1)
{
	char sName[256], sBuffer[256];
	
	if (music_id != -1)
	{
		ArrayBackgroundCat.GetString(music_id, sBuffer, sizeof(sBuffer));
		if (strlen(sBuffer) >= 2)
		{
			Format(g_StringLastTableau, sizeof(g_StringLastTableau), sBuffer);
			Format(sBuffer, sizeof(sBuffer), "tableau_%s_on", sBuffer);
		}
	}
	
	if (strlen(sBuffer)  >= 2)
	{
		int iEnt;
		
		while ((iEnt = FindEntityByClassname(iEnt, "logic_relay")) != -1)
		{
			GetEntPropString(iEnt, Prop_Data, "m_iName", sName, sizeof(sName));
			
			if (StrEqual(sName, sBuffer))
				AcceptEntityInput(iEnt, "Trigger");
		}
	}
}

void SetLights(bool bStatus = false)
{
	int iEnt;
	char sName[256];
	
	while ((iEnt = FindEntityByClassname(iEnt, "logic_relay")) != -1)
	{
		GetEntPropString(iEnt, Prop_Data, "m_iName", sName, sizeof(sName));
		
		if (bStatus && StrEqual(sName, "lobby_lights_on"))
		{
			AcceptEntityInput(iEnt, "Trigger");
			g_bLights = true;
		}
		else if(!bStatus && StrEqual(sName, "lobby_lights_off"))
		{
			AcceptEntityInput(iEnt, "Trigger");
			g_bLights = false;
		}
	}
}

public Action OnEntityTouch(int entity, int client)
{
	// Player left game
	if (!g_bIsInGame && client < MaxClients && client > 0)
		g_iPlayers[client][INGAME] = false;
}

public Action OnEntityUnTouch(int entity, int client)
{
	// Player entered game
	if (!g_bIsInGame && client < MaxClients && client > 0)
		g_iPlayers[client][INGAME] = true;
}

void PlayMusic(int client, int music_id, int difficulty)
{
	g_fPlayStartTime = GetGameTime();
	
	if (!IsClientInGame(client))
		client = 0;
	
	char buffer[256], music[256], music_name[256];
	g_bIsInGame = true;
	
	ArrayMusicFile.GetString(music_id, buffer, sizeof(buffer));
	ArrayMusicName.GetString(music_id, music_name, sizeof(music_name));
	Format(music, sizeof(music), "%s/%s", PATH_SOUND_SONGS, buffer);
	BuildPath(Path_SM, g_sFileRecord, 256, "configs/%s/%s_%s.txt", PATH_SOUND_SONGS, buffer, g_iDifficulty[difficulty][lowerName]);
	
	if (!FileExists(g_sFileRecord))
		CPrintToChat(client, "%T", "DDR_File_Not_Found", client, g_sLogo[client], music_name, g_iDifficulty[difficulty][color], g_iDifficulty[difficulty][color][upperName]);
	else
	{
		LoopClients(i)
		{
			if (IsClientInGame(i))
				CPrintToChat(i, "%T", "DDR_Play_Music", i, g_sLogo[i], music_name, g_iDifficulty[difficulty][color], g_iDifficulty[difficulty][upperName]);
		}
		
		g_bAllowStop = false;
		CreateTimer(5.0, Timer_SetStop);
		
		HUD_BackgroundOn(music_id);
		// AcceptEntityInput(test_relay, "Trigger");
		status = STATUS_IN_GAME;
		LoopClients(i)
		{
			g_iPlayers[i][TOTAL] = 0;
			g_iPerfect[i] = 0;
			
			#if DEBUG == 1
			if (IsClientInGame(i))
			{
				PrintToChat(i, "Perfect Counter: %d", g_iPerfect[i]);
			}
			#endif
			
			g_iPlayers[i][COMBO_REGEN] = 0;
			g_iPlayers[i][LIFE] = LIFE_START;
			g_iHUDHealthBarValue[i] = -1;
			for (int iz = 0; iz < 5; iz++)
			{
				g_iClientScoreEntity[i][iz] = 0;
			}
		}
		g_iHUDHealthBarLoading = 0;
		CreateTimer(0.2, HUD_Timer_LoadingHealthBar, _, TIMER_REPEAT);
		Run_Sequence(music_id, difficulty);
		g_iLastPlayedId = music_id;
		
		if(!g_bLights)
			SetLights(true);
	}
	
	if (view_control != -1)
	{
		LoopClients(i)
		{
			if (IsClientInGame(i) && IsPlayerAlive(i) && g_iPlayers[i][INGAME])
			{
				Client_RemoveAllWeapons(i);
				SetEntityMoveType(i, MOVETYPE_NONE);
				SetClientRender(i, false);
			}
		}
	}
}

public Action Timer_SetStop(Handle timer)
{
	g_bAllowStop = true;
}

void Do_View_Client(int client, bool ignore = false)
{
	if (IsClientInGame(client) && IsPlayerAlive(client) && !IsFakeClient(client))
	{
		int where = WhereIsPlayer(client);
		if (ignore || where > TEAMS_NONE)
		{
			Client_RemoveAllWeapons(client);
			SetEntityMoveType(client, MOVETYPE_NONE);
			SetClientRender(client, false);
			SetClientViewEntity(client, view_control);
			g_iPlayers[client][INGAME] = true;
			Forward_ClientEnterSong(client);
		}
	}
}

void Stop_View_Client(int client)
{
	if (IsClientInGame(client) && IsPlayerAlive(client) && !IsFakeClient(client))
		RequestFrame(OnStopViewClient, client);
}

public void OnStopViewClient(any client)
{
	TeleportEntity(client, g_fTeleLobby, NULL_VECTOR, NULL_VECTOR);
	StripPlayerWeapons(client);
	SetEntityMoveType(client, MOVETYPE_WALK);
	SetClientRender(client, true);
	SetClientViewEntity(client, client);
	g_iPlayers[client][INGAME] = false;
	Forward_ClientLeftSong(client);
	UnMutePlayers(client); // unmute all players for client
	ShowOverlayToClient(client, "");
	SetClientScore(client, 0);
	
	if (!g_bInEnding)
		CheckAliveClient(true);
}

void StartRecordSequence(int client, int music_id, int difficulty, bool deletefileonly = false)
{
	if (status == STATUS_IN_GAME)
	{
		CPrintToChat(client, "%T", "DDR_Record_Not_Allow", client, g_sLogo[client]);
		return;
	}
	
	char buffer[256], music[256], music_name[256];
	
	ArrayMusicFile.GetString(music_id, buffer, sizeof(buffer));
	ArrayMusicName.GetString(music_id, music_name, sizeof(music_name));
	Format(music, sizeof(music), "%s/%s", PATH_SOUND_SONGS, buffer);
	BuildPath(Path_SM, g_sFileRecord, 256, "%s/%s_%s.txt", PATH_SONGS_CONFIG, buffer, g_iDifficulty[difficulty][lowerName]);
	
	/* Delete sequence */
	//if (FileExists(g_sFileRecord) && DeleteFile(g_sFileRecord) && deletefileonly)
	if (FileExists(g_sFileRecord) && deletefileonly)
	{
		char newpath[256];
		Format(newpath, sizeof(newpath), "%s_%d", g_sFileRecord, GetTime());
		RenameFile(newpath, g_sFileRecord);
		CPrintToChat(client, "%T", "DDR_File_Deleted", client, g_sLogo[client], music_name, g_iDifficulty[difficulty][color], g_iDifficulty[difficulty][color][upperName]);
		return;
	}
	
	g_hFileRecord = OpenFile(g_sFileRecord, "w");
	g_iRecordingClient = client;
	
	g_bIsInRecord = true;
	g_iRecordedNote = 0;
	
	g_iTicks[client] = RoundToFloor(GetGameTime() * 1000);
	
	CPrintToChat(client, "%T", "DDR_Start_Recording", client, g_sLogo[client], music_name, g_iDifficulty[difficulty][color], g_iDifficulty[difficulty][color][upperName]);
	CPrintToChat(client, "%T", "DDR_Start_Recording_Stop", client, g_sLogo[client]);
	
	Do_View_Client(client, true);
	
	PlayAllThis(music);
}

public Action DelayPlayIt(Handle timer, Handle pack)
{
	ResetPack(pack);
	char music[256];
	ReadPackString(pack, music, sizeof(music));
	LoopClients(i)
	{
		if (IsClientInGame(i) && !IsFakeClient(i))
		{
			if (g_iPlayers[i][INGAME])
			{
				Client_RemoveAllWeapons(i);
				MutePlayers(i); // mute all players for i
			}
			
			//TODO
			float fVolume = DDR_VOLUME_MUSIC;
			EmitSoundToAllAny(music, _, SNDCHAN_VOICE, _, _, fVolume, _, g_iBot);
		}
	}
	delete pack;
}

stock void PrecacheSongs()
{
	ArrayMusicName = new ArrayList(64);
	ArrayMusicFile = new ArrayList(64);
	ArrayBackgroundCat = new ArrayList(32);
	
	ArrayMusicName.Clear();
	ArrayMusicFile.Clear();
	ArrayBackgroundCat.Clear();
	
	char file[256], buffer[256], datas[5][256];
	
	BuildPath(Path_SM, file, sizeof(file), "%s/music_name.txt", PATH_CONFIG);
	Handle fileh = OpenFile(file, "r");
	
	if (fileh != null)
	{
		while (ReadFileLine(fileh, buffer, sizeof(buffer)))
		{
			TrimString(buffer);
			ExplodeString(buffer, "//", datas, sizeof(datas), sizeof(buffer));
			
			Format(buffer, sizeof(buffer), "%s/%s", PATH_SOUND_SONGS, datas[0]);
			
			PrecacheSoundAny(buffer);
			Format(buffer, sizeof(buffer), "sound/%s", buffer);
			AddFileToDownloadsTable(buffer);
			
			ArrayMusicName.PushString(datas[1]);
			ArrayMusicFile.PushString(datas[0]);
			ArrayBackgroundCat.PushString(datas[2]);
		}
		
		delete fileh;
	}
}

stock void ClearClientData(int client)
{
	char buffer[256];
	if (g_iLastPlayedId != -1)
	{
		ArrayMusicFile.GetString(g_iLastPlayedId, buffer, sizeof(buffer));
		Format(buffer, sizeof(buffer), "%s/%s", PATH_SOUND_SONGS, buffer);
		
		if (IsClientInGame(client))
			StopSoundAny(client, SNDCHAN_VOICE_BASE, buffer);
	}
	
	for (int x = 0; x < 3; x++)
		g_iHUDComboValues[client][x] = -1;
	
	ArrayEntityInUse[client] = new ArrayList(1);
	ArrayEntityButton[client] = new ArrayList(1);
	
	g_iRecordTicksAntiDoublons[client] = 0;
	ArrayEntityInUse[client].Clear();
	ArrayEntityButton[client].Clear();
	
	g_iPlayers[client][GOOD] = 0;
	g_iPlayers[client][MISS] = 0;
	g_iPlayers[client][COMBO] = 0;
	g_iPlayers[client][BAD] = 0;
	g_iPlayers[client][MAX_COMBO] = 0;
	g_iPlayers[client][TOTAL] = 0;
	g_iPlayers[client][PERFECT] = 0;
	g_iPerfect[client] = 0;
	
	#if DEBUG == 1
	if (IsClientInGame(client))
	{
		PrintToChat(client, "Perfect Counter: %d", g_iPerfect[client]);
	}
	#endif
	
	g_iPlayers[client][LIFE] = 0;
	g_iPlayers[client][INGAME] = false;
	Forward_ClientLeftSong(client);
	TrashTimer(g_hMsg[client]);
	
	g_hMsg[client] = CreateTimer(0.1, CleanOverlay, client);
	
	for (int z = 0; z < MAX_SEQUENCE_LINES; z++)
		g_bHUDArrowCanView[client][z] = false;
	
	if (ArrayPlayerId != null)
	{
		int ar = ArrayPlayerId.FindValue(client);
		if (ar != -1)
		{
			ArrayPlayerId.Erase(ar);
			ArrayPlayerScore.Erase(ar);
		}
	}
}

stock void ResetAll()
{
	g_bIsInGame = false;
	g_iRecordingClient = -1;
	g_bIsInRecord = false;
	
	g_iScoreTeam1 = 0;
	g_iScoreTeam2 = 0;
	g_bIsGameTeam = false;
	
	LoopClients(i)
		ClearClientData(i);
	
	TrashTimer(g_hMissedTimer, true);
	TrashTimer(g_hDelayedSong);
	
	g_iLastPlayedId = -1;
	
	if (ArrayPlayerId != null)
		ArrayPlayerId.Clear();
	
	if (ArrayPlayerScore != null)
		ArrayPlayerScore.Clear();
	
	TrashTimer(g_hRankRefresh, true);
	TrashTimer(g_hHint, true);
	
	if(g_bLights)
		SetLights(false);
}

stock void TrashTimer(Handle & h_timer, bool IsRepeat = false)
{
	if (h_timer != null)
	{
		if (IsRepeat)
			KillTimer(h_timer);
		else
			delete h_timer;
		h_timer = null;
	}
}

public Action Event_RoundStart(Handle event, const char[] name, bool dontBroadcast)
{
	RequestFrame(Delayed_RoundStart, dontBroadcast);
}

void SetClientRender(int client, bool bStatus)
{
	if (IsClientInGame(client) && IsPlayerAlive(client))
	{
		if(bStatus)
		{
			if(!g_bCPS)
				SetEntityRenderMode(client, RENDER_NORMAL); 
			else
			{
				SetEntityRenderMode(client, RENDER_TRANSCOLOR);
				SetEntityRenderColor(client, 255, 255, 255, 255);
			}
		}
		else
		{
			if(!g_bCPS)
				SetEntityRenderMode(client, RENDER_NONE);
			else
			{
				SetEntityRenderMode(client, RENDER_TRANSCOLOR);
				SetEntityRenderColor(client, 0, 0, 0, 0);
			}
		}
	}
}

public void Delayed_RoundStart(any dontBroadcast)
{
	g_bIsInGame = false;
	int entindex = -1;
	char g_sEntityFlech[4][32], g_sScoreFetch[4][32], name[20], modelname[128];
	
	g_fTeleLobby[0] = 0.0;
	g_fTeleLobby[1] = 0.0;
	g_fTeleLobby[2] = 0.0;
	
	while ((entindex = FindEntityByClassname(entindex, "info_teleport_destination")) != -1)
	{
		GetEntPropString(entindex, Prop_Data, "m_iName", name, sizeof(name));
		if (StrEqual(name, "teleport_lobby"))
			GetEntPropVector(entindex, Prop_Send, "m_vecOrigin", g_fTeleLobby);
		else if (StrEqual(name, "teleport_solo"))
			GetEntPropVector(entindex, Prop_Send, "m_vecOrigin", g_fTeleSolo);
		else if (StrEqual(name, "teleport_team1"))
			GetEntPropVector(entindex, Prop_Send, "m_vecOrigin", g_fTeleTeam1);
		else if (StrEqual(name, "teleport_team2"))
			GetEntPropVector(entindex, Prop_Send, "m_vecOrigin", g_fTeleTeam2);
	}
	
	LoopClients(i)
	{
		if (IsClientInGame(i) && !IsFakeClient(i) && IsPlayerAlive(i))
			TeleportEntity(i, g_fTeleLobby, NULL_VECTOR, NULL_VECTOR);
	}
	
	while ((entindex = FindEntityByClassname(entindex, "trigger_multiple")) != -1)
	{
		GetEntPropString(entindex, Prop_Data, "m_iName", name, sizeof(name));
		if (StrEqual("multiple_room_all", name))
		{
			SDKHook(entindex, SDKHook_StartTouchPost, OnEntityTouch);
			SDKHook(entindex, SDKHook_EndTouchPost, OnEntityUnTouch);
			float ori[3];
			GetEntPropVector(entindex, Prop_Send, "m_vecOrigin", ori);
			
			ori[2] -= 50.0;
			TeleportEntity(entindex, ori, NULL_VECTOR, NULL_VECTOR);
			GetEntPropVector(entindex, Prop_Send, "m_vecOrigin", ori);
		}
		
		else if (StrEqual("ddr_viewcontrol_on", name))
		{
			float ori[3];
			GetEntPropVector(entindex, Prop_Send, "m_vecOrigin", ori);
			g_iViewControlTriggerEntity = entindex;
			
			LoopClients(i)
			{
				if (IsClientInGame(i) && IsFakeClient(i))
				{
					g_iBot = i;
					Do_BotFreeze(i);
					break;
				}
			}
		}
		
		else if (StrEqual("ddr_platform_solo", name))
		{
			g_iTriggerSolo = entindex;
			SDKHook(entindex, SDKHook_StartTouch, StartTouchPlatformTrigger);
			SDKHook(entindex, SDKHook_EndTouch, EndTouchPlatformTrigger);
		}
		
		else if (StrEqual("ddr_platform_team1", name))
		{
			g_iTriggerTeam1 = entindex;
			SDKHook(entindex, SDKHook_StartTouch, StartTouchPlatformTrigger);
			SDKHook(entindex, SDKHook_EndTouch, EndTouchPlatformTrigger);
		}
		
		else if (StrEqual("ddr_platform_team2", name))
		{
			g_iTriggerTeam2 = entindex;
			SDKHook(entindex, SDKHook_StartTouch, StartTouchPlatformTrigger);
			SDKHook(entindex, SDKHook_EndTouch, EndTouchPlatformTrigger);
		}
		
		else if (StrEqual("ddr_lobby_spectator", name))
		{
			g_iTriggerSpec = entindex;
			SDKHook(entindex, SDKHook_StartTouch, StartTouchPlatformTrigger);
			SDKHook(entindex, SDKHook_EndTouch, EndTouchPlatformTrigger);
		}
		else if (StrEqual("ddr_vip", name))
		{
			g_iTriggerVip = entindex;
			SDKHook(entindex, SDKHook_StartTouch, StartTouchPlatformTrigger);
			SDKHook(entindex, SDKHook_EndTouch, EndTouchPlatformTrigger);
		}
		else if (StrEqual("bartrigger", name))
		{
			g_iTriggerBar = entindex;
			SDKHook(entindex, SDKHook_StartTouch, NPC_Touch);
		}
		else if (StrEqual("deejaytrigger", name))
		{
			g_iTriggerDJ = entindex;
			SDKHook(entindex, SDKHook_StartTouch, NPC_Touch);
		}
		else if (StrEqual("hattrigger", name))
		{
			g_iTriggerShop = entindex;
			SDKHook(entindex, SDKHook_StartTouch, NPC_Touch);
		}
		else if (StrEqual("drugtrigger", name))
		{
			g_iTriggerDealer = entindex;
			SDKHook(entindex, SDKHook_StartTouch, NPC_Touch);
		}
		else if (StrEqual("trigger_npc_games", name))
		{
			g_iTriggerGames = entindex;
			SDKHook(entindex, SDKHook_StartTouch, NPC_Touch);
		}
	}
	
	while ((entindex = FindEntityByClassname(entindex, "func_tracktrain")) != -1)
	{
		GetEntPropString(entindex, Prop_Data, "m_iName", name, sizeof(name));
		
		ExplodeString(name, "_", g_sEntityFlech, 4, 32);
		
		if (StrEqual(g_sEntityFlech[1], "g"))
		{
			if (StringToInt(g_sEntityFlech[2]) < MAX_ARROWS_PER_TRACK)
			{
				g_iHUDArrowEntitys[ARROW_LEFT][StringToInt(g_sEntityFlech[2])] = entindex;
				SDKHook(entindex, SDKHook_SetTransmit, ShouldHideArrow);
			}
		}
		else if (StrEqual(g_sEntityFlech[1], "d"))
		{
			if (StringToInt(g_sEntityFlech[2]) < MAX_ARROWS_PER_TRACK)
			{
				g_iHUDArrowEntitys[ARROW_RIGHT][StringToInt(g_sEntityFlech[2])] = entindex;
				SDKHook(entindex, SDKHook_SetTransmit, ShouldHideArrow);
			}
		}
		
		else if (StrEqual(g_sEntityFlech[1], "b"))
		{
			if (StringToInt(g_sEntityFlech[2]) < MAX_ARROWS_PER_TRACK)
			{
				g_iHUDArrowEntitys[ARROW_DOWN][StringToInt(g_sEntityFlech[2])] = entindex;
				SDKHook(entindex, SDKHook_SetTransmit, ShouldHideArrow);
			}
			
		}
		else if (StrEqual(g_sEntityFlech[1], "h"))
		{
			if (StringToInt(g_sEntityFlech[2]) < MAX_ARROWS_PER_TRACK)
			{
				g_iHUDArrowEntitys[ARROW_UP][StringToInt(g_sEntityFlech[2])] = entindex;
				SDKHook(entindex, SDKHook_SetTransmit, ShouldHideArrow);
			}
		}
	}
	
	float ori[3];
	while ((entindex = FindEntityByClassname(entindex, "func_button")) != -1)
	{
		GetEntPropString(entindex, Prop_Data, "m_iName", name, sizeof(name));
		
		if (StrContains("rank", name, false))
			SDKHook(entindex, SDKHook_SetTransmit, RankHide);
	}
	while ((entindex = FindEntityByClassname(entindex, "prop_dynamic")) != -1)
	{
		GetEntPropString(entindex, Prop_Data, "m_iName", name, sizeof(name));
		GetEntPropString(entindex, Prop_Data, "m_ModelName", modelname, 128);
		
		ExplodeString(name, "_", g_sScoreFetch, 4, 32);
		
		// HUD Healthbar
		if (StrEqual(g_sScoreFetch[0], "life"))
		{
			g_iHUDHealthBarEntity[StringToInt(g_sScoreFetch[1])] = entindex;
			
			SDKHook(entindex, SDKHook_SetTransmit, ShouldHideDisplay);
		}
		// HUD Score Numbers
		else if (StrEqual(g_sScoreFetch[0], "n"))
		{
			g_EntityScore[StringToInt(g_sScoreFetch[1])][StringToInt(g_sScoreFetch[2])] = entindex;
			SDKHook(entindex, SDKHook_SetTransmit, ShouldHideDisplay);
			SetEntityRenderColor(entindex, 255, 255, 0, 255);
		}
		// HUD Combo Numbers
		else if (StrEqual(g_sScoreFetch[0], "c"))
		{
			g_iHUDComboCounterEntity[StringToInt(g_sScoreFetch[1])][StringToInt(g_sScoreFetch[2])] = entindex;
			SDKHook(entindex, SDKHook_SetTransmit, ShouldHideDisplay);
			SetEntityRenderColor(entindex, 250, 255, 140, 255);
		}
		else
		{
			// HUD Combo Word
			if (StrEqual("models/nsnf/ddr/word_combo.mdl", modelname))
			{
				g_iHUDComboWordEntity = entindex;
				SDKHook(entindex, SDKHook_SetTransmit, ShouldHideDisplay);
				SetEntityRenderColor(entindex, 250, 255, 140, 255);
			}
			// HUD Static Arrows / Get Perfect Height
			else if (StrEqual("models/nsnf/ddr/arrow_ghost.mdl", modelname))
			{
				GetEntPropVector(entindex, Prop_Send, "m_vecOrigin", ori);
				g_iInterfaceHeight = ori[2];
			}
			
			// HUD Ghost Arrow (Shadow Shape)
			if (StrEqual(g_sScoreFetch[0], "g"))
			{
				g_iHUDGhostArrowEntity[StringToInt(g_sScoreFetch[1])] = entindex;
				SDKHook(entindex, SDKHook_SetTransmit, HideButton);
				//SetEntityRenderColor(entindex, 255, 0, 255, 255);
			}
			// HUD Arrow (Active/Orange)
			else if (StrEqual(g_sScoreFetch[0], "ga"))
			{
				g_iHUDGhostArrowActiveEntity[StringToInt(g_sScoreFetch[1])] = entindex;
				SDKHook(entindex, SDKHook_SetTransmit, HideButton);
				//SetEntityRenderColor(entindex, 0, 255, 0, 255);
			}
		}
	}
	
	while ((entindex = FindEntityByClassname(entindex, "prop_dynamic")) != -1)
	{
		GetEntPropString(entindex, Prop_Data, "m_ModelName", name, 128);
		if (StrEqual("models/nsnf/ddr/arrow.mdl", name, false))
		{
			SDKHook(entindex, SDKHook_SetTransmit, ShouldHideArrow);
		}
	}
	
	view_control = -1;
	while ((entindex = FindEntityByClassname(entindex, "point_viewcontrol")) != -1)
	{
		view_control = entindex;
	}
	
	// Init NPCs
	InitNPCs();
}

public Action StartTouchPlatformTrigger(int entity, int client)
{
	if (!Client_IsValid(client, true))
		return;
	
	if (entity == g_iTriggerSolo)
		g_bSolo[client] = true;
	else if (entity == g_iTriggerTeam1)
		g_bTeam1[client] = true;
	else if (entity == g_iTriggerTeam2)
		g_bTeam2[client] = true;
	else if (entity == g_iTriggerSpec)
		g_bSpec[client] = true;
	else if (entity == g_iTriggerVip)
		Zone_CheckPlayer(client, g_iTriggerVip);
}

stock void Zone_CheckPlayer(int client, int zone)
{
	if (!IsPlayerAlive(client))
	{
		SetEntProp(zone, Prop_Send, "m_CollisionGroup", 11);
		return;
	}
	
	g_bVip[client] = true;
	
	if (g_PlayerDatas[client][LEVEL] >= ZONE_VIP_LEVEL || CheckCommandAccess(client, "sm_ddr", ADMFLAG_GENERIC, false))
	{
		SetEntProp(zone, Prop_Send, "m_CollisionGroup", 11);
		return;
	}
	
	if (g_PlayerDatas[client][LEVEL] < ZONE_VIP_LEVEL && !CheckCommandAccess(client, "sm_ddr", ADMFLAG_GENERIC, false))
	{
		CPrintToChat(client, "%T", "DDR_Zone_NotAllowed", client, g_sLogo[client], ZONE_VIP_LEVEL);
		
		if (g_bVip[client])
			g_bVip[client] = false;
		
		// Fix Glitch and we troll players ;)
		ForcePlayerSuicide(client);
	}
}

public Action EndTouchPlatformTrigger(int entity, int client)
{
	if (!Client_IsValid(client, true))
		return;
	
	if (entity == g_iTriggerSolo)
		g_bSolo[client] = false;
	else if (entity == g_iTriggerTeam1)
		g_bTeam1[client] = false;
	else if (entity == g_iTriggerTeam2)
		g_bTeam2[client] = false;
	else if (entity == g_iTriggerSpec)
		g_bSpec[client] = false;
	else if (entity == g_iTriggerVip)
		g_bVip[client] = false;
}

/*
stock void DoSpark(float origins[3])
{
	TeleportEntity(g_iTesla, origins, NULL_VECTOR, NULL_VECTOR);
	AcceptEntityInput(g_iTesla, "DoSpark");
}
*/

void Run_Sequence(int music_id, int difficulty)
{
	char buffer[256], music[256], sequence_file[256];
	
	ArrayMusicFile.GetString(music_id, buffer, sizeof(buffer));
	Format(music, sizeof(music), "%s/%s", PATH_SOUND_SONGS, buffer);
	BuildPath(Path_SM, sequence_file, 256, "%s/%s_%s.txt", PATH_SONGS_CONFIG, buffer, g_iDifficulty[difficulty][lowerName]);
	
	g_iLastPlayedDifficulty = difficulty;
	
	// Clear sequence timers
	for (int i = 0; i < MAX_SEQUENCE_LINES; i++)
	{
		if (g_hSequenceTimer[i] != null)
		{
			KillTimer(g_hSequenceTimer[i]);
			g_hSequenceTimer[i] = null;
		}
	}
	
	// Create sequence timers
	char read_actions[5][20];
	int value = 0;
	Handle fileh = OpenFile(sequence_file, "r");
	
	if (fileh != null)
	{
		int ticks;
		while (ReadFileLine(fileh, buffer, sizeof(buffer)))
		{
			Handle pack = CreateDataPack();
			WritePackCell(pack, value);
			
			float speed = g_iDifficulty[difficulty][arrowSpeed];
			
			WritePackFloat(pack, speed);
			
			float diff = START_SONG_DELAY - (110.0 / speed);
			
			ExplodeString(buffer, ";", read_actions, 5, 20);
			
			if (StringToInt(read_actions[0]) > ticks)
			{
				ticks = StringToInt(read_actions[0]);
				
				// Create timer to create delayed action
				g_hSequenceTimer[value] = CreateTimer((StringToFloat(read_actions[0]) / 1000) + diff, HUD_Timer_LaunchNextArrows, pack);
				
				value++; // Timer instance
				
				for (int i = 1; i <= 4; i++)
				{
					WritePackCell(pack, StringToInt(read_actions[i]));
				}
			}
		}
		
		delete fileh;
		ticks += 5000;
		g_iTicksCount = ticks;
		
		// Create timer to finish sequence
		g_hSequenceTimer[value] = CreateTimer(float(ticks) / 1000, Timer_EndMusic, value);
		
		// Create timer to start sequence
		g_hDelayedSong = CreateTimer(START_SONG_DELAY, DelayedSong, music_id);
		
		// Create timer to check notes which passed the point of no return
		g_hMissedTimer = CreateTimer(0.1, CheckMissedNote, _, TIMER_REPEAT);
		
		if (g_hClientEntityScore == null)
			g_hClientEntityScore = CreateTimer(0.2, EntityScoreTimer, _, TIMER_REPEAT);
	}
	
	g_hRankRefresh = CreateTimer(RANK_REFRESH_RATE, RankThem, _, TIMER_REPEAT);
	
	g_hHint = CreateTimer(RANK_HINT_REFRESH_RATE, ShowScoreBoard, _, TIMER_REPEAT);
	
	if (g_iViewControlTriggerEntity != -1)
	{
		LoopClients(i)
		{
			Do_View_Client(i, false);
		}
	}
	CheckAliveClient(true);
}

void CheckAliveClient(bool first = false)
{
	if (g_bIsInGame)
	{
		int count = 0;
		LoopClients(i)
			if (IsClientInGame(i) && !IsFakeClient(i) && IsPlayerAlive(i) && g_iPlayers[i][LIFE] > 0 && g_iPlayers[i][INGAME])
				count++;
		
		if (count == 0)
		{
			for (int z = 0; z < MAX_SEQUENCE_LINES; z++)
			{
				TrashTimer(g_hSequenceTimer[z]);
				LoopClients(x)
					g_bHUDArrowCanView[x][z] = false;
			}
			g_hSequenceTimer[0] = CreateTimer(3.0, Timer_EndMusic, 0);
			
			if (first)
			{
				LoopClients(i)
					if (IsClientInGame(i))
						CPrintToChat(i, "%T", "DDR_None_Playing", i, g_sLogo[i]);
			}
			else
			{
				LoopClients(i)
					if (IsClientInGame(i))
						CPrintToChat(i, "%T", "DDR_All_Players_Failed", i, g_sLogo[i]);
			}
		}
		else
		{
			if (first)
			{
				LoopClients(i)
					if (IsClientInGame(i))
						CPrintToChat(i, "%T", "DDR_Player_Play_Song", i, g_sLogo[i], count, (count > 1 ? "s":""));
			}
			else
			{
				LoopClients(i)
					// Dirty Workaround
					if (IsClientInGame(i) && !g_bIsGameTeam)
						CPrintToChat(i, "%T", "DDR_Player_Left", i, g_sLogo[i], count, (count > 1 ? "s":""));
			}
		}
	}
}

public Action Timer_EndMusic(Handle timer, any timerid)
{
	g_iTicksCount = 0;
	g_bTestingSong = false;
	g_bAllowStop = false;
	g_bSongSelected = false;
	
	LoopClients(i)
	{
		if (IsClientInGame(i))
		{
			CPrintToChat(i, "%T", "DDR_Song_Ends", i, g_sLogo[i]);
			
			char sPath[256];
			ArrayMusicFile.GetString(g_iLastPlayedId, sPath, sizeof(sPath));
			Format(sPath, sizeof(sPath), "%s/%s", PATH_SOUND_SONGS, sPath);
			
			//TODO
			StopSoundAny(i, SNDCHAN_VOICE, sPath);
		}
	}
	
	ShowResultChat();
	
	status = STATUS_NO_WAITLIST;
	g_hSequenceTimer[timerid] = null;
	
	g_bInEnding = true;
	LoopClients(i)
	{
		if (g_iPlayers[i][INGAME] || WhereIsPlayer(i) > TEAMS_NONE)
		{
			Stop_View_Client(i);
			ClearClientData(i);
		}
	}
	g_bInEnding = false;
	
	HUD_BackgroundOff();
	
	char sBuffer[64];
	ArrayMusicName.GetString(g_iLastPlayedId, sBuffer, sizeof(sBuffer));
	
	Call_StartForward(g_hOnSongEnd);
	Call_PushCell(g_iLastPlayedId);
	Call_PushString(sBuffer);
	Call_Finish();
	
	ResetAll();
	
	return Plugin_Stop;
}

public Action DelayedSong(Handle timer, any music_id)
{
	char buffer[256], music[256];
	
	ArrayMusicFile.GetString(music_id, buffer, sizeof(buffer));
	Format(music, sizeof(music), "%s/%s", PATH_SOUND_SONGS, buffer);
	
	g_hDelayedSong = null;
	PlayAllThis(music);
	
	return Plugin_Stop;
}

stock void PlayAllThis(char[] Sound)
{
	float Origin[3];
	GetEntPropVector(view_control, Prop_Send, "m_vecOrigin", Origin);
	Handle pack = CreateDataPack();
	
	WritePackString(pack, Sound);
	
	LoopClients(i)
	{
		if (IsClientInGame(i) && !IsFakeClient(i) && g_iPlayers[i][INGAME])
		{
			g_iTicks[i] = RoundToFloor(GetGameTime() * 1000);
			g_iRecordTicksAntiDoublons[i] = 0;
			TeleportEntity(i, Origin, NULL_VECTOR, NULL_VECTOR);
		}
	}
	CreateTimer(0.2, DelayPlayIt, pack);
}

int WhereIsPlayer(int client)
{
	if (!IsClientInGame(client) || !IsPlayerAlive(client))
	{
		return TEAMS_NONE;
	}
	
	float v[3];
	GetEntPropVector(client, Prop_Send, "m_vecOrigin", v);
	
	// Hardcoded origins for first map
	if (g_bSolo[client])
		return TEAMS_SOLO;
	
	if (g_bTeam1[client])
		return TEAMS_TEAM1;
	
	if (g_bTeam2[client])
		return TEAMS_TEAM2;
	
	return TEAMS_NONE;
}

public Action HUD_Timer_LaunchNextArrows(Handle timer, Handle pack)
{
	int timer_id, ent;
	float speed;
	
	ResetPack(pack);
	timer_id = ReadPackCell(pack);
	speed = ReadPackFloat(pack);
	
	for (int i = 0; i < 4; i++)
	{
		if (ReadPackCell(pack) != 0)
		{
			// Get next free arrow entity
			if (g_iArrowsInUse[i] >= MAX_ARROWS_PER_TRACK - 1)
				g_iArrowsInUse[i] = 0; // restart all have been unsed
			else
				g_iArrowsInUse[i]++;
			
			ent = g_iHUDArrowEntitys[i][g_iArrowsInUse[i]];
			
			LoopClients(y)
			{
				if (IsClientInGame(y) && IsPlayerAlive(y) && !IsFakeClient(y))
				{
					int idx = ArrayEntityInUse[y].FindValue(ent, 0);
					if (idx != -1)
						MoveOff(y, idx, ent);
				
					ArrayEntityInUse[y].Push(ent);
					ArrayEntityButton[y].Push(i);
					
					g_bHUDArrowCanView[y][ent] = true;
				}
			}
			
			//Start movement
			AcceptEntityInput(ent, "StartForward");
			
			// Set movement speed
			if (g_iLastPlayedDifficulty == DIFFICULTY_CHAOS && speed == g_iDifficulty[DIFFICULTY_CHAOS][arrowSpeed])
				SetVariantFloat(GetRandomFloat(g_iDifficulty[DIFFICULTY_EASY][arrowSpeed], g_iDifficulty[DIFFICULTY_CHAOS][arrowSpeed]));
			else
				SetVariantFloat(speed);
			AcceptEntityInput(ent, "SetSpeedReal");
		}
	}
	g_hSequenceTimer[timer_id] = null;
	
	delete pack;
	return Plugin_Stop;
}

public Action ShouldHideArrow(int ent, int client)
{
	// View Ent Parent
	int parent = Entity_GetParent(ent);
	return ((g_bHUDArrowCanView[client][ent] == true || (parent != -1 && g_bHUDArrowCanView[client][parent] == true)) ? Plugin_Continue:Plugin_Handled);
}

public Action ShouldHideDisplay(int ent, int client)
{
	// Arrows, Life HUD etc
	char g_sEntityFlech[4][32], stringname[20], model[128];
	GetEntPropString(ent, Prop_Data, "m_iName", stringname, sizeof(stringname));
	GetEntPropString(ent, Prop_Data, "m_ModelName", model, 128);
	ExplodeString(stringname, "_", g_sEntityFlech, 4, 32);
	int id_num = StringToInt(g_sEntityFlech[1]);
	
	if (StrEqual(g_sEntityFlech[0], "n"))
	{
		int value_num = StringToInt(g_sEntityFlech[2]);
		return (g_iClientScoreEntity[client][id_num] == value_num ? Plugin_Continue : Plugin_Handled);
	}
	else if (StrEqual(g_sEntityFlech[0], "c"))
	{
		int value_num = StringToInt(g_sEntityFlech[2]);
		return (g_iHUDComboValues[client][id_num] == value_num ? Plugin_Continue : Plugin_Handled);
	}
	else if (StrEqual(g_sEntityFlech[0], "life") && g_iHUDHealthBarValue[client] != -1)
	{
		return (g_iHUDHealthBarValue[client] >= id_num ? Plugin_Continue : Plugin_Handled);
	}
	else if (g_iHUDComboWordEntity == ent && g_bHUDComboWordCanView[client])
		return Plugin_Continue;
	
	return Plugin_Handled;
}

public Action CheckMissedNote(Handle timer)
{
	if (g_bIsInGame)
	{
		int entity;
		float origins[3];
		LoopClients(i)
		{
			if (IsClientInGame(i) && !IsFakeClient(i) && g_iPlayers[i][INGAME])
			{
				for (int idx = 0; idx < ArrayEntityInUse[i].Length; idx++)
				{
					entity = ArrayEntityInUse[i].Get(idx, 0, false);
					GetEntPropVector(entity, Prop_Send, "m_vecOrigin", origins);
					
					// Has entity passed point of no return
					if (origins[2] >= g_iInterfaceHeight + Get_Tolerance_GOOD(i))
					{
						MoveOff(i, idx, entity);
						if (g_iPlayers[i][COMBO] > 50)
						{
							char sBuffer[PLATFORM_MAX_PATH + 1];
							Format(sBuffer, sizeof(sBuffer), "%s/combo_breaker.mp3", PATH_SOUND_EVENTS);
							
							float fVolume = DDR_VOLUME_FAIL;
							EmitSoundToClientAny(i, sBuffer, _, _, _, _, fVolume);
							
							// ClientCommand(i, "playgamesound \"%s/combo_breaker.mp3\"", PATH_SOUND_EVENTS);
						}
						
						if (g_iPlayers[i][LIFE] > 0)
						{
							g_iPlayers[i][MISS]++;
							ManageHealth(i, LIFE_LOSE_MISS, false);
						}
						
						g_iPlayers[i][COMBO_REGEN] = 0;
						g_iPlayers[i][COMBO] = 0;
						Show_Client_Msg(i, EFFECT_MISS, origins);
					}
				}
				
				if (g_iPlayers[i][LIFE] <= 0)
				{
					if (g_iPlayers[i][INGAME] == true)
						PrintCenterText(i, "%T", "DDR_You_Failed", i);
					else PrintCenterText(i, "%T", "DDR_You_Cant_Play", i);
				}
			}
		}
	}
}

public Action RankHide(int ent, int client)
{
	char g_sEntityFlech[4][16], name[20];
	
	GetEntPropString(ent, Prop_Data, "m_iName", name, sizeof(name));
	ExplodeString(name, "_", g_sEntityFlech, 4, 32);
	int id = StringToInt(g_sEntityFlech[1]);
	
	if (ArrayPlayerId != null && (ArrayPlayerId.FindValue(client) + 1) == id)
		return Plugin_Continue;
	
	return Plugin_Handled;
}

public Action HideButton(int ent, int client)
{
	char g_sEntityFlech[4][16], name[20];
	
	GetEntPropString(ent, Prop_Data, "m_iName", name, sizeof(name));
	ExplodeString(name, "_", g_sEntityFlech, 4, 32);
	int id = StringToInt(g_sEntityFlech[1]);
	
	if ((StrEqual(g_sEntityFlech[0], "ga") && g_bHUDGhostArrowCanView[client][id] == true) || (StrEqual(g_sEntityFlech[0], "g") && g_bHUDGhostArrowCanView[client][id] != true))
		return Plugin_Continue;
	
	return Plugin_Handled;
}

void Do_ComboSound(int client, int combo)
{
	int value = -1;
	if (IsClientInGame(client))
	{
		if (combo == COMBO_SUPER)
		{
			value = 0;
			g_iPlayers[client][TOTAL] += POINTS_SUPER;
		}
		else if (combo == COMBO_KILLER)
		{
			value = 1;
			g_iPlayers[client][TOTAL] += POINTS_KILLER;
		}
		else if (combo == COMBO_TRIPLE)
		{
			value = 2;
			g_iPlayers[client][TOTAL] += POINTS_TRIPLE;
		}
		else if (combo == COMBO_MASTER)
		{
			value = 3;
			g_iPlayers[client][TOTAL] += POINTS_MASTER;
		}
		else if (combo == COMBO_ULTRA)
		{
			value = 4;
			g_iPlayers[client][TOTAL] += POINTS_ULTRA;
		}
	}
	
	if (value != -1)
	{
		char buf[256];
		Format(buf, sizeof(buf), "%s/%s.mp3", PATH_SOUND_EVENTS, g_sComboSound[value]);
		
		float fVolume = DDR_VOLUME_COMBO;
		EmitSoundToClientAny(client, buf, _, _, _, _, fVolume);
		
		// ClientCommand(client, "playgamesound \"%s\"", buf);
		
		LoopClients(i)
		{
			if (!IsClientInGame(i))
				continue;
			
			CPrintToChat(i, "%T", "DDR_Combo_Announce", i, g_sLogo[i], client, combo);
		}
	}
}

public Action OnPlayerRunCmd(int client, int & buttons, int & impulse, float vel[3], float angles[3], int & weapon)
{
	// Ignore bots
	if (IsFakeClient(client))
		return;
	
	// Player is not in a game
	if (!g_iPlayers[client][INGAME])
		return;
	
	// Buttons didn't changed
	if (oldButtons[client] == buttons)
		return;
	
	// block mouse1+mouse2
	SetEntDataFloat(weapon, m_flNextPrimaryAttack, GetGameTime() + 2.0);
	SetEntDataFloat(weapon, m_flNextSecondaryAttack, GetGameTime() + 2.0);
	
	// Get average ping
	g_fAvgPing[client] = GetClientAvgLatency(client, NetFlow_Outgoing) * 1024;
	
	int cticks = (RoundToFloor(GetGameTime() * 1000) - g_iTicks[client]);
	
	/*
	if (g_iRecordTicksAntiDoublons[client] + DOUBLE_CLICK_PROTECTION_TICKS > cticks)
		return;
	*/
	
	bool bButtonsPressed[4];
	bool bButtonPressed;
	
	for (int i = 0; i < 4; i++)
	{
		bButtonsPressed[i] = !(oldButtons[client] & d_Buttons[i]) && (buttons & d_Buttons[i]);
		
		if(bButtonsPressed[i])
			bButtonPressed = true;
	}
	
	oldButtons[client] = buttons;
	
	// Show static arrows to client
	if (g_bIsInGame || (g_bIsInRecord && g_iRecordingClient == client))
	{
		for (int i = 0; i < 4; i++)
			g_bHUDGhostArrowCanView[client][i] = bButtonsPressed[i];
	}
	
	// Recording int sequence
	if (g_bIsInRecord && g_iRecordingClient == client && bButtonPressed)
	{
		g_iRecordedNote++;
		g_iRecordTicksAntiDoublons[client] = cticks;
		CPrintToChat(g_iRecordingClient, "%T", "DDR_Recording", g_iRecordingClient, g_iRecordedNote, cticks, (bButtonsPressed[0] ? "←":"  "), (bButtonsPressed[1] ? "↓":" "), (bButtonsPressed[2] ? "↑":" "), (bButtonsPressed[3] ? "→":"  "));
		WriteFileLine(g_hFileRecord, "%d;%d;%d;%d;%d;", cticks, (bButtonsPressed[0] ? 1:0), (bButtonsPressed[1] ? 1:0), (bButtonsPressed[2] ? 1:0), (bButtonsPressed[3] ? 1:0));
	}
	
	if (g_bIsInGame && g_iPlayers[client][INGAME])
	{
		float origins[3];
		
		int entity, button;
		bool IsButtonValidated[4] =  { false, ... };
		
		// Read all entitys, which are currently in use
		for (int idx = 0; idx < ArrayEntityInUse[client].Length; idx++)
		{
			entity = ArrayEntityInUse[client].Get(idx, 0, false);
			button = ArrayEntityButton[client].Get(idx, 0, false);
			
			GetEntPropVector(entity, Prop_Send, "m_vecOrigin", origins);
			origins[2] -= FIX_HEIGHT;
			
			//Entity has already passed point of no return
			if (origins[2] >= g_iInterfaceHeight + Get_Tolerance_GOOD(client))
			{
				MoveOff(client, idx, entity);
				
				if (g_iPlayers[client][COMBO] > 50)
				{
					char sBuffer[PLATFORM_MAX_PATH + 1];
					Format(sBuffer, sizeof(sBuffer), "%s/combo_breaker.mp3", PATH_SOUND_EVENTS);
					
					float fVolume = DDR_VOLUME_FAIL;
					EmitSoundToClientAny(client, sBuffer, _, _, _, _, fVolume);
					
					// ClientCommand(client, "playgamesound \"%s/combo_breaker.mp3\"", PATH_SOUND_EVENTS);
				}
				
				g_iPlayers[client][COMBO_REGEN] = 0;
				g_iPlayers[client][COMBO] = 0;
				
				// ToDo - Reset Prefect Combo
				if (g_iPlayers[client][LIFE] > 0)
				{
					g_iPlayers[client][MISS]++;
					g_iPerfect[client] = 0;
					#if DEBUG == 1
					PrintToChat(client, "Perfect Counter: %d", g_iPerfect[client]);
					#endif
					
					ManageHealth(client, LIFE_LOSE_MISS, false);
				}
				
				Show_Client_Msg(client, EFFECT_MISS, origins);
			}
			else
			{
				// GOOD/PERFECT
				if (!IsButtonValidated[button] && bButtonsPressed[button] && origins[2] >= g_iInterfaceHeight - Get_Tolerance_GOOD(client) && origins[2] <= g_iInterfaceHeight + Get_Tolerance_GOOD(client))
				{
					MoveOff(client, idx, entity);
					bool IsPerfect = (origins[2] >= g_iInterfaceHeight - Get_Tolerance_Perfect(client) && origins[2] <= g_iInterfaceHeight + Get_Tolerance_Perfect(client) ? true:false);
					IsButtonValidated[button] = true;
					
					if (g_iPlayers[client][LIFE] > 0 && !g_bTestingSong)
					{
						g_iPlayers[client][(IsPerfect ? PERFECT:GOOD)]++;
						
						g_iPlayers[client][COMBO]++;
						if (g_iPlayers[client][COMBO] > g_iPlayers[client][MAX_COMBO])
						{
							g_iPlayers[client][MAX_COMBO] = g_iPlayers[client][COMBO];
						}
						g_iPlayers[client][TOTAL] += Get_Points(client, IsPerfect);
						
						g_iPlayers[client][COMBO_REGEN]++;
						
						ManageHealth(client, (IsPerfect ? LIFE_WIN_PERFECT:LIFE_WIN_GOOD));
						
						Do_ComboSound(client, g_iPlayers[client][COMBO]);
						
						if (!IsPerfect)
						{
							g_iPerfect[client] = 0;
							#if DEBUG == 1
							PrintToChat(client, "Perfect Counter: %d", g_iPerfect[client]);
							#endif
						}
						else
						{
							g_iPerfect[client]++;
							
							#if DEBUG == 1
							PrintToChat(client, "Perfect Counter (%d): %d", g_iLastPlayedDifficulty, g_iPerfect[client]);
							#endif
							
							for (int i = 1; i <= PERFECT_MAX_COMBO; i++)
							{
								if (g_iPerfect[client] == (g_iDifficulty[g_iLastPlayedDifficulty][perfectCombo] * i))
								{
									float points = PERFECT_POINTS_BASE;
									points *= g_iDifficulty[g_iLastPlayedDifficulty][perfectComboDiff];
									points *= i;
									float iPoints = AddPerfectComboPoints(client, points);
									#if DEBUG == 1
									PrintToChat(client, "Perfect Counter (%d): %d - Points: %.f - iPoints: %.f", g_iLastPlayedDifficulty, g_iPerfect[client], points, iPoints);
									#endif
									g_iPlayers[client][TOTAL] += RoundToFloor(iPoints);
									CPrintToChat(client, "%T", "DDR_Perfect_Combo", client, g_sLogo[client], RoundToFloor(iPoints));
								}
							}
						}
					}
					
					TrashTimer(g_hClientComboView[client], false);
					g_hClientComboView[client] = CreateTimer(COMBO_VIEWTIME, CleanCombo, client);
					Show_Client_Msg(client, (IsPerfect ? EFFECT_PERFECT:EFFECT_GOOD), origins);
				}
				// BAD
				else if (!IsButtonValidated[button] && bButtonsPressed[button] && origins[2] >= g_iInterfaceHeight - Get_Tolerance_Miss(client))
				{
					IsButtonValidated[button] = true;
					
					if (g_iPlayers[client][COMBO] > COMBO_SUPER)
					{
						float fVolume = DDR_VOLUME_FAIL;
						char sBuffer[PLATFORM_MAX_PATH + 1];
						
						Format(sBuffer, sizeof(sBuffer), "%s/combo_breaker.mp3", PATH_SOUND_EVENTS);
						EmitSoundToClientAny(client, sBuffer, _, _, _, _, fVolume);
						
						// ClientCommand(client, "playgamesound \"%s/combo_breaker.mp3\"", PATH_SOUND_EVENTS);
					}
					
					MoveOff(client, idx, entity);
					g_iPlayers[client][COMBO_REGEN] = 0;
					g_iPlayers[client][COMBO] = 0;
					
					if (g_iPlayers[client][LIFE] > 0)
					{
						g_iPlayers[client][BAD]++;
						
						ManageHealth(client, LIFE_LOSE_BAD, false);
					}
					
					Show_Client_Msg(client, EFFECT_BAD, origins);
				}
			}
		}
	}
}

void Show_Client_Msg(int client, int msg, float origins[3])
{
	if (msg == EFFECT_PERFECT)
	{
		TE_SetupEnergySplash(origins, view_as<float>( { 0.0, 0.0, 0.0 } ), true);
		TE_SendToClient(client);
	}
	else if (msg == EFFECT_GOOD)
	{
		TE_SetupEnergySplash(origins, view_as<float>( { 0.0, 0.0, 0.0 } ), true);
		TE_SendToClient(client);
	}
	else if (msg == EFFECT_BAD)
	{
		TE_SetupBloodSprite(origins, view_as<float>( { 0.0, 0.0, 0.0 } ), { 255, 50, 120, 255 }, 5, g_SmokeSprite, g_SmokeSprite);
		TE_SendToClient(client);
	}
	else if (msg == EFFECT_MISS)
	{
		TE_SetupSmoke(origins, g_SmokeSprite, 2.0, 5);
		TE_SendToClient(client);
	}
	
	if (g_hMsg[client] != null)
		KillTimer(g_hMsg[client]);
	
	char buffer[256];
	Format(buffer, sizeof(buffer), "%s.vmt", g_sOverlay[msg]);
	
	ShowOverlayToClient(client, buffer);
	
	if (g_iPlayers[client][COMBO] > 1)
	{
		int val;
		g_bHUDComboWordCanView[client] = true;
		
		int combo = (g_iPlayers[client][COMBO] > 999 ? 999:g_iPlayers[client][COMBO]);
		IntToString(combo, buffer, 6);
		int iSize1 = strlen(buffer);
		for (int i = 0; i < 3; i++)
		{
			g_iHUDComboValues[client][i] = -1;
		}
		
		for (int i = iSize1 - 1; i >= 0; i--)
		{
			g_iHUDComboValues[client][val] = StringToInt(buffer[i]);
			buffer[i] = '\0';
			val++;
		}
	}
	
	g_hMsg[client] = CreateTimer(OVERLAY_DURATION, CleanOverlay, client);
}

public Action CleanCombo(Handle timer, any client)
{
	g_bHUDComboWordCanView[client] = false;
	for (int i = 0; i < 3; i++)
	{
		g_iHUDComboValues[client][i] = -1;
	}
	
	g_hClientComboView[client] = null;
	return Plugin_Stop;
}

public Action CleanOverlay(Handle timer, any client)
{
	if (IsClientInGame(client))
	{
		if (g_iPlayers[client][INGAME] && g_iPlayers[client][LIFE] <= 0)
		{
			ShowDeadOverlayToClient(client);
		}
		else
		{
			ShowOverlayToClient(client, "");
		}
	}
	
	g_hMsg[client] = null;
	return Plugin_Stop;
}

void ShowOverlayToClient(int client, const char[] overlaypath)
{
	if (g_iPlayers[client][INGAME] && g_iPlayers[client][LIFE] <= 0)
	{
		ShowDeadOverlayToClient(client);
	}
	else
	{
		ClientCommand(client, "r_screenoverlay \"%s\"", overlaypath);
	}
}

void ShowDeadOverlayToClient(int client)
{
	ClientCommand(client, "r_screenoverlay \"%s.vmt\"", g_sOverlay[EFFECT_DEAD]);
}

void MoveOff(int client, int i, int ent)
{
	g_bHUDArrowCanView[client][ent] = false;
	ArrayEntityInUse[client].Erase(i);
	ArrayEntityButton[client].Erase(i);
}

void DataBase_GetDataFromAllPlayer()
{
	LoopClients(i)
	{
		DataBase_GetDataFromPlayer(i);
	}
}

void DataBase_GetDataFromPlayer(int client)
{
	if (IsClientInGame(client) && !IsFakeClient(client))
	{
		if (g_hDatabase != null)
		{
			char sID[32], sQuery[256];
			
			if(!GetClientAuthId(client, AuthId_SteamID64, sID, sizeof(sID)))
				return;
			
			Format(sQuery, sizeof(sQuery), "SELECT id, exp, level FROM `ddr_playerdatas` WHERE `communityid` = '%s' LIMIT 1", sID);
			SQL_TQuery(g_hDatabase, CallBack_PlayerInfos, sQuery, client);
		}
	}
}

public void CallBack_PlayerInfos(Handle owner, Handle hndl, const char[] error, any client)
{
	if (hndl != null)
	{
		if (SQL_FetchRow(hndl))
		{
			Update_Player_Variables(client, SQL_FetchInt(hndl, 0), SQL_FetchInt(hndl, 1), SQL_FetchInt(hndl, 2));
			delete hndl;
		}
		else
		{
			char sIP[32], sEIP[32], sQuery[650], user[MAX_NAME_LENGTH], communityid[32], sName[MAX_NAME_LENGTH];
			
			if(!GetClientAuthId(client, AuthId_SteamID64, communityid, sizeof(communityid)))
				return;
			
			if(!GetClientIP(client, sIP, sizeof(sIP)))
				return;
			
			if(!GetClientName(client, user, sizeof(user)))
				return;
			
			
			SQL_EscapeString(g_hDatabase, user, sName, sizeof(sName));
			SQL_EscapeString(g_hDatabase, sIP, sEIP, sizeof(sEIP));
			
			Format(sQuery, sizeof(sQuery), "INSERT INTO  `ddr_playerdatas` (`nickname` , `communityid` , `last_seen_date` , `last_seen_ip`) VALUES ('%s',  '%s', UNIX_TIMESTAMP(), '%s');", sName, communityid, sEIP);
			SQL_TQuery(g_hDatabase, CallBack_InsertPlayer, sQuery, client);
		}
	}
}

public void CallBack_InsertPlayer(Handle owner, Handle hndl, const char[] error, any client)
{
	if (hndl != null)
	{
		int insert_id = SQL_GetInsertId(hndl);
		Update_Player_Variables(client, insert_id, 0, 0);
	}
	else
	{
		LogError("[SQL] Error with player: %N", client);
	}
	return;
}

void Update_Player_Variables(int client, int database_id, int experience = 0, int level = 0)
{
	if (database_id)
	{
		g_PlayerDatas[client][DATABASE_ID] = database_id;
		
		if (experience >= 0)
		{
			g_PlayerDatas[client][EXPERIENCE] = experience;
			
			if(g_bXenForo)
				if(XenForo_IsProcessed(client))
					XenForo_UpdateFieldInt(client, "ddr_points", g_PlayerDatas[client][EXPERIENCE]);
		}
		if (level >= 0)
		{
			g_PlayerDatas[client][LEVEL] = Experience_ReturnLevel(experience);
			
			if(g_bXenForo)
				if(XenForo_IsProcessed(client))
					XenForo_UpdateFieldInt(client, "ddr_level", g_PlayerDatas[client][LEVEL]);
		}
	}
}

// Generate EXP values for levels
void Experience_Generate()
{
	g_iLevelExpReq[0] = 0;
	int i = 1;
	while (i <= MAX_LEVEL)
	{
		g_iLevelExpReq[i] = RoundToFloor((g_iLevelExpReq[i - 1] + EXP_VALUE) * EXP_SCALE);
		i++;
	}
}

void Experience_Add(int client, int score)
{
	int current_level = g_PlayerDatas[client][LEVEL];
	
	g_PlayerDatas[client][EXPERIENCE] += score / SCORE_POINTS;
	int associated = Experience_ReturnLevel(g_PlayerDatas[client][EXPERIENCE]);
	
	if(g_bXenForo)
		if(XenForo_IsProcessed(client))
			XenForo_UpdateFieldInt(client, "ddr_points", g_PlayerDatas[client][EXPERIENCE]);
	
	#if DEBUG == 1
	PrintToServer("Level : %d - Associated: %d", current_level, associated)
	#endif
	
	if (associated > current_level)
	{
		LoopClients(i)
		{
			if (!IsClientInGame(i))
				continue;
			
			CPrintToChat(i, "%T", "DDR_Rank_Up", i, g_sLogo[i], client, associated);
		}
		
		g_PlayerDatas[client][LEVEL] = associated;
		
		if(g_bXenForo)
			if(XenForo_IsProcessed(client))
				XenForo_UpdateFieldInt(client, "ddr_level", g_PlayerDatas[client][LEVEL]);
		
		char sBuffer[PLATFORM_MAX_PATH + 1];
		Format(sBuffer, sizeof(sBuffer), "%s/lvl_up.mp3", PATH_SOUND_EVENTS);
		
		float fVolume = DDR_VOLUME_LVLUP;
		EmitSoundToClientAny(client, sBuffer, _, _, _, _, fVolume);
		
		// ClientCommand(client, "playgamesound \"%s/lvl_up.mp3\"", PATH_SOUND_EVENTS);
	}
}

int Experience_ReturnLevel(int experience)
{
	for (int Level = 0; Level < MAX_LEVEL; Level++)
	{
		if (experience < g_iLevelExpReq[Level])
			return Level - 1;
		else
			continue;
	}
	
	return MAX_LEVEL;
}

void DataBase_UpdatePlayerDatas(int client)
{
	if (!IsFakeClient(client))
	{
		if (g_hDatabase != null)
		{
			char ip[32], sEIP[32], sQuery[1024], user[64], sName[MAX_NAME_LENGTH];
			
			if(!GetClientIP(client, ip, sizeof(ip)))
				return;
			
			if(!GetClientName(client, user, sizeof(user)))
				return;
			
			SQL_EscapeString(g_hDatabase, user, sName, sizeof(sName));
			SQL_EscapeString(g_hDatabase, ip, sEIP, sizeof(sEIP));
			
			Format(sQuery, sizeof(sQuery), "UPDATE  `ddr_playerdatas` SET `nickname` = '%s', `exp` = '%d', `level` = '%d', `last_seen_date` = UNIX_TIMESTAMP(), `last_seen_ip` = '%s' WHERE `id` = %d;", sName, g_PlayerDatas[client][EXPERIENCE], g_PlayerDatas[client][LEVEL], sEIP, g_PlayerDatas[client][DATABASE_ID]);
			SQLQuery(sQuery);
		}
	}
}

float Get_Tolerance_Perfect(int client)
{
	float ping_tolerance = g_fAvgPing[client] * TOLMUL_PERFECT;
	
	if (ping_tolerance < TOLERANCE_PERFECT_MIN)
		return TOLERANCE_PERFECT_MIN;
	else
		return ping_tolerance;
}

float Get_Tolerance_GOOD(int client)
{
	float ping_tolerance = g_fAvgPing[client] * TOLMUL_GOOD;
	
	if (ping_tolerance < TOLERANCE_GOOD_MIN)
		return TOLERANCE_GOOD_MIN;
	else
		return ping_tolerance;
}

float Get_Tolerance_Miss(int client)
{
	float ping_tolerance = g_fAvgPing[client] * TOLMUL_MISS;
	
	if (ping_tolerance < TOLERANCE_MISS_MIN)
		return TOLERANCE_MISS_MIN;
	else
		return ping_tolerance;
}

int Get_Points(int client, bool perfect)
{
	int points = 0;
	
	if (g_iPlayers[client][COMBO] > COMBO_ULTRA)
	{
		if (perfect)
			points = POINTS_ULTRA_PERFECT;
		else
			points = POINTS_ULTRA_OK;
	}
	else if (g_iPlayers[client][COMBO] > COMBO_MASTER)
	{
		if (perfect)
			points = POINTS_MASTER_PERFECT;
		else
			points = POINTS_MASTER_OK;
	}
	else if (g_iPlayers[client][COMBO] > COMBO_TRIPLE)
	{
		if (perfect)
			points = POINTS_TRIPLE_PERFECT;
		else
			points = POINTS_TRIPLE_OK;
	}
	else if (g_iPlayers[client][COMBO] > COMBO_KILLER)
	{
		if (perfect)
			points = POINTS_KILLER_PERFECT;
		else
			points = POINTS_KILLER_OK;
	}
	else if (g_iPlayers[client][COMBO] > COMBO_SUPER)
	{
		if (perfect)
			points = POINTS_SUPER_PERFECT;
		else
			points = POINTS_SUPER_OK;
	}
	else
	{
		if (perfect)
			points = POINTS_PERFECT;
		else
			points = POINTS_OK;
	}
	
	return RoundToFloor(points * g_iDifficulty[g_iLastPlayedDifficulty][multiplicator]);
}

float AddPerfectComboPoints(int client, float points)
{
	if (g_iPlayers[client][COMBO] > COMBO_ULTRA)
	{
		points *= PERFECT_ULTRA;
		return points;
	}
	else if (g_iPlayers[client][COMBO] > COMBO_MASTER)
	{
		points *= PERFECT_MASTER;
		return points;
	}
	else if (g_iPlayers[client][COMBO] > COMBO_TRIPLE)
	{
		points *= PERFECT_TRIPLE;
		return points;
	}
	else if (g_iPlayers[client][COMBO] > COMBO_KILLER)
	{
		points *= PERFECT_KILLER;
		return points;
	}
	else if (g_iPlayers[client][COMBO] > COMBO_SUPER)
	{
		points *= PERFECT_SUPER;
		return points;
	}
	else
	{
		points *= PERFECT_NO_COMBO;
		return points;
	}
}

void PrecacheAndAddDL()
{
	PrecacheSongs();
	g_SmokeSprite = PrecacheModel("sprites/steam1.vmt");
	
	char sBuffer[80];
	
	for (int i; i < sizeof(g_sSoundsEvents); i++)
	{
		Format(sBuffer, sizeof(sBuffer), "%s/%s.mp3", PATH_SOUND_EVENTS, g_sSoundsEvents[i]);
		PrecacheSoundAny(sBuffer);
		Format(sBuffer, sizeof(sBuffer), "sound/%s", sBuffer);
		AddFileToDownloadsTable(sBuffer);
	}
	
	for (int i = 0; i < sizeof(g_sComboSound); i++)
	{
		Format(sBuffer, sizeof(sBuffer), "%s/%s.mp3", PATH_SOUND_EVENTS, g_sComboSound[i]);
		PrecacheSoundAny(sBuffer);
		Format(sBuffer, sizeof(sBuffer), "sound/%s", sBuffer);
		AddFileToDownloadsTable(sBuffer);
	}
	
	for (int i = 1; i <= 5; i++)
	{
		Format(sBuffer, sizeof(sBuffer), "%s/%d.mp3", PATH_SOUND_EVENTS, i);
		PrecacheSoundAny(sBuffer);
		Format(sBuffer, sizeof(sBuffer), "sound/%s", sBuffer);
		AddFileToDownloadsTable(sBuffer);
	}
	
	// NPCs
	PreCacheNPCModels();
}

public int Native_IsClientInGame(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	return g_iPlayers[client][INGAME];
}

public int Native_GetClientLevel(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	return g_PlayerDatas[client][LEVEL];
}

stock void Forward_ClientEnterSong(int client)
{
	Call_StartForward(g_hClientEnterSong);
	Call_PushCell(client);
	Call_Finish();
}

stock void Forward_ClientLeftSong(int client)
{
	Call_StartForward(g_hClientLeftSong);
	Call_PushCell(client);
	Call_Finish();
}
