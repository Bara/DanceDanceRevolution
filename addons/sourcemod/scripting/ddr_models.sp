#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

#pragma newdecls required

#define PLAYER_MODELS_MAX 4

bool bFoundModels = false;
int g_iModelCount = 0; 

public Plugin myinfo = 
{
	name = "Dance Dance Revolution - Models",
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
	
	HookEvent("player_spawn", Event_PlayerSpawn, EventHookMode_PostNoCopy);
}

public void OnMapStart()
{
	PlayerModels_Precache();
}

public Action Event_PlayerSpawn(Handle event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if(IsClientInGame(client) && IsPlayerAlive(client))
		if (bFoundModels)
			SetPlayerModel(client);
}

stock void PlayerModels_Precache()
{
	KeyValues kv = new KeyValues("DDR-Models");
	
	char sConfig[PLATFORM_MAX_PATH + 1];
	BuildPath(Path_SM, sConfig, sizeof(sConfig), "configs/DDR2/models.ini");
	
	PrintToServer("[PLAYER MODELS] Models Config: %s", sConfig);
	
	if (kv.ImportFromFile(sConfig))
	{
		if (!kv.GotoFirstSubKey())
		{
			SetFailState("Can't find a configuration!");
			return;
		}
		
		do
		{
			char sBuffer[64], sMap[64];
			
			kv.GetSectionName(sBuffer, sizeof(sBuffer));
			GetCurrentMap(sMap, sizeof(sMap));
			
			if(StrContains(sMap, sBuffer, false) != -1)
			{
				g_iModelCount = kv.GetNum("Count");
			
				for (int i = 1; i <= g_iModelCount; i++)
				{
					PrintToServer("[PLAYER MODELS] %d of %d", i, g_iModelCount);
					if (g_iModelCount <= PLAYER_MODELS_MAX)
					{
						char sKey[12];
						char sModelDir[PLATFORM_MAX_PATH + 1];
						
						Format(sKey, sizeof(sKey), "Model%d", i);
						kv.GetString(sKey, sModelDir, sizeof(sModelDir));
						
						PrintToServer("[PLAYER MODELS] Key: %s - Dir: %s", sKey, sModelDir);
						
						if (strlen(sModelDir) > 2)
						{
							if (DirExists(sModelDir))
							{
								Handle hModelDir;
								hModelDir = OpenDirectory(sModelDir);
								
								if (hModelDir != null)
								{
									char sModelFile[PLATFORM_MAX_PATH + 1];
									FileType type;
									
									while (ReadDirEntry(hModelDir, sModelFile, sizeof(sModelFile), type))
									{
										if (type == FileType_File)
										{
											Format(sModelFile, sizeof(sModelFile), "%s/%s", sModelDir, sModelFile);
											
											if (StrContains(sModelFile, ".mdl", false) != -1)
												PrecacheModel(sModelFile);
											
											AddFileToDownloadsTable(sModelFile);
											
											PrintToServer(sModelFile);
											
											if (!bFoundModels)
												bFoundModels = true;
										}
									}
								}
								
								delete hModelDir;
							}
						}
						
						Format(sKey, sizeof(sKey), "Material%d", i);
						kv.GetString(sKey, sModelDir, sizeof(sModelDir));
						
						PrintToServer("[PLAYER MODELS] Key: %s - Dir: %s", sKey, sModelDir);
						
						if (strlen(sModelDir) > 2)
						{
							if (DirExists(sModelDir))
							{
								Handle hModelDir;
								hModelDir = OpenDirectory(sModelDir);
								
								if (hModelDir != null)
								{
									char sModelFile[PLATFORM_MAX_PATH + 1];
									FileType type;
									
									while (ReadDirEntry(hModelDir, sModelFile, sizeof(sModelFile), type))
									{
										if (type == FileType_File)
										{
											Format(sModelFile, sizeof(sModelFile), "%s/%s", sModelDir, sModelFile);
											AddFileToDownloadsTable(sModelFile);
											PrintToServer(sModelFile);
										}
									}
								}
								
								delete hModelDir;
							}
						}
					}
				}
			}
		} while (kv.GotoNextKey());
	}
	
	delete kv;
}

void SetPlayerModel(int client)
{
	KeyValues kv = new KeyValues("DDR");
	
	char sConfig[PLATFORM_MAX_PATH + 1];
	BuildPath(Path_SM, sConfig, sizeof(sConfig), "configs/DDR2/models.ini");
	
	if (kv.ImportFromFile(sConfig))
	{
		char sMap[32];
		GetCurrentMap(sMap, sizeof(sMap));
		if(kv.JumpToKey(sMap, false))
		{
			int iModel = GetRandomInt(1, g_iModelCount);
			
			char sKey[12];
			char sModel[PLATFORM_MAX_PATH + 1];
			
			Format(sKey, sizeof(sKey), "Mdl%d", iModel);
			kv.GetString(sKey, sModel, sizeof(sModel));
			
			if (FileExists(sModel))
				SetEntityModel(client, sModel);
		}
	}
}
