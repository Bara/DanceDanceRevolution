stock void SetClientScore(int client, int score)
{
	CS_SetClientContributionScore(client, score);
}

stock void SetDescription()
{
	SteamWorks_SetGameDescription("♪ ♫ CS:GO - DDR ♫ ♪");
}

stock void OpenHiddenUrl(int client, char[] url)
{
	KeyValues kv = CreateKeyValues("data");
	
	kv.SetString("title", "DDR Music Player");
	kv.SetNum("type", MOTDPANEL_TYPE_URL);
	kv.SetString("msg", url);
	
	ShowVGUIPanel(client, "info", kv, false);
	delete kv;
}

stock void HideHud(int client)
{
	SetEntPropEnt(client, Prop_Send, "m_bSpotted", 0);
	
	SetEntProp(client, Prop_Send, "m_iHideHUD", GetEntProp(client, Prop_Send, "m_iHideHUD") | HIDE_HUD_RADAR | HIDE_HUD_HEALTH_AND_CROSSHAIR);
}

stock void SecondsToTime(float seconds, char[] buffer, int maxlength, int precision)
{
	int t = RoundToFloor(seconds);
	
	int hour, mins;
	
	if (t >= 3600)
	{
		hour = RoundToFloor(t / 3600.0);
		t = t % 3600;
	}
	
	if (t >= 60)
	{
		mins = RoundToFloor(t / 60.0);
		t = t % 60;
	}
	
	Format(buffer, maxlength, "");
	
	if (hour)
		Format(buffer, maxlength, "%s%02d:", buffer, hour);
	
	Format(buffer, maxlength, "%s%02d:", buffer, mins);
	
	if (precision == 1)
		Format(buffer, maxlength, "%s%04.1f", buffer, view_as<float>(t) + seconds - RoundToFloor(seconds));
	else if (precision == 2)
		Format(buffer, maxlength, "%s%05.2f", buffer, view_as<float>(t) + seconds - RoundToFloor(seconds));
	else if (precision == 3)
		Format(buffer, maxlength, "%s%06.3f", buffer, view_as<float>(t) + seconds - RoundToFloor(seconds));
	else
		Format(buffer, maxlength, "%s%02d", buffer, t);
}

stock void StripPlayerWeapons(int client)
{
	int iWeapon = -1;
	for (int i = CS_SLOT_PRIMARY; i <= CS_SLOT_C4; i++)
	{
		while ((iWeapon = GetPlayerWeaponSlot(client, i)) != -1)
		{
			RemovePlayerItem(client, iWeapon);
			RemoveEdict(iWeapon);
		}
	}
}

void FullReset()
{
	g_iTicksCount = 0;
	g_bTestingSong = false;
	g_bAllowStop = false;
	g_bSongSelected = false;
	status = STATUS_NO_WAITLIST;
	
	for (int z = 0; z < MAX_SEQUENCE_LINES; z++)
	{
		TrashTimer(g_hSequenceTimer[z]);
		for (int x = 1; x <= MaxClients; x++)
			g_bHUDArrowCanView[x][z] = false;
	}
	g_hSequenceTimer[0] = CreateTimer(3.0, Timer_EndMusic, 0);
}

void MutePlayers(int client)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i))
		{
			SetListenOverride(client, i, Listen_No);
			SetListenOverride(i, client, Listen_No);
		}
	}
}

void UnMutePlayers(int client)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i))
		{
			SetListenOverride(client, i, Listen_Yes);
			SetListenOverride(i, client, Listen_Yes);
		}
	}
}

stock float GetSequenceTimeLeft()
{
	return (float(g_iTicksCount) / 1000) - (GetGameTime() - g_fPlayStartTime);
}

stock void LoadDifficulties()
{
	char sFile[PLATFORM_MAX_PATH + 1];
	BuildPath(Path_SM, sFile, sizeof(sFile), "%s/difficulties.cfg", PATH_CONFIG);
	
	if(!FileExists(sFile))
	{
		SetFailState("(FileExists) Can't read %s", sFile);
		return;
	}
	
	KeyValues kv = new KeyValues("Difficulties");
	
	if(!kv.ImportFromFile(sFile))
	{
		SetFailState("(ImportFromFile) Can't read %s", sFile);
		delete kv;
		return;
	}
	
	if(!kv.GotoFirstSubKey())
	{
		SetFailState("(ImportFromFile) Can't read %s", sFile);
		delete kv;
		return;
	}

	do
	{
		char sID[4];
		kv.GetSectionName(sID, sizeof(sID));
		int id = StringToInt(sID);
		
		g_iDifficulty[id][dID] = id;
		kv.GetString("upperName", g_iDifficulty[id][upperName], 64);
		kv.GetString("lowerName", g_iDifficulty[id][lowerName], 64);
		kv.GetString("shortName", g_iDifficulty[id][shortName], 3);
		kv.GetString("color", g_iDifficulty[id][color], 32);
		g_iDifficulty[id][arrowSpeed] = kv.GetFloat("arrowSpeed");
		g_iDifficulty[id][multiplicator] = kv.GetFloat("multiplicator");
		g_iDifficulty[id][perfectCombo] = kv.GetFloat("perfectCombo");
		g_iDifficulty[id][perfectComboDiff] = kv.GetFloat("perfectComboDiff");
		
		LogMessage("ID: %d, uName: %s, lName: %s, sName %s, Color: %s, aSpeed: %f, multiplicator: %f, pCombo: %f, pComboDiff: %f",
		g_iDifficulty[id][dID], g_iDifficulty[id][upperName], g_iDifficulty[id][lowerName], g_iDifficulty[id][shortName], g_iDifficulty[id][color], g_iDifficulty[id][arrowSpeed], g_iDifficulty[id][multiplicator], g_iDifficulty[id][perfectCombo], g_iDifficulty[id][perfectComboDiff]);
	} while (kv.GotoNextKey());

	delete kv;
}
