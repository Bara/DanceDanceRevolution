public void Connect_DataBase(Handle owner, Handle hndl, const char[] error, any data)
{
	if (hndl == null)
	{
		SetFailState("[DDR] Database failure: %s", error);
		return;
	}
	else
	{
		
		g_hDatabase = hndl;
		PrintToServer("[DDR] Database connected");
		
		char sBuffer[512];
		Format(sBuffer, sizeof(sBuffer), "SET NAMES \"UTF8\"");
		SQLQuery(sBuffer);
		
		CreateDatabasePlayerDatas();
		CreateDatabaseRank();
		DataBase_GetDataFromAllPlayer();
	}
}

void Show_Top30FC(int client)
{
	if (IsClientInGame(client) && !IsFakeClient(client))
	{
		if (g_hDatabase != null)
		{
			char Query[256];
			Format(Query, sizeof(Query), "SELECT nickname, music_name, difficulty, combo FROM ddr_rank WHERE (miss+bad) = 0  AND (perfect+cool) > 200 ORDER BY score DESC LIMIT 50");
			SQL_TQuery(g_hDatabase, Callback_Top30FC, Query, client);
		}
	}
}

public void Callback_Top30FC(Handle owner, Handle hndl, const char[] error, any client)
{
	if (IsClientInGame(client))
	{
		int result = 0;
		Menu menu = new Menu(MenuInGame);
		if (hndl != null)
		{
			char sTop30[256], titre[126];
			while (SQL_FetchRow(hndl))
			{
				result++;
				SQL_FetchString(hndl, 0, sTop30, sizeof(sTop30));
				SQL_FetchString(hndl, 1, titre, sizeof(titre));
				
				Format(sTop30, sizeof(sTop30), "%T", "DDR_Top30_FC", client, result, sTop30, titre, g_iDifficulty[SQL_FetchInt(hndl, 2)][upperName], SQL_FetchInt(hndl, 3));
				// PrintToServer(sTop30);
				AddMenuItem(menu, "0", sTop30, ITEMDRAW_DISABLED);
			}
			
			SetMenuExitButton(menu, true);
			DisplayMenu(menu, client, MENU_TIME_FOREVER);
			
			delete hndl;
		}
		if (result == 0)
		{
			CPrintToChat(client, "%T", "DDR_Nothing_Found", client, g_sLogo[client]);
			delete menu;
		}
	}
}

void Show_Top30(int client)
{
	if (IsClientInGame(client) && !IsFakeClient(client))
	{
		if (g_hDatabase != null)
		{
			char Query[256];
			Format(Query, sizeof(Query), "SELECT nickname,score, MAX(score) AS score_max FROM ddr_rank GROUP BY communityid ORDER BY score_max DESC LIMIT 50");
			SQL_TQuery(g_hDatabase, Callback_Top30, Query, client);
			
		}
	}
}

public void Callback_Top30(Handle owner, Handle hndl, const char[] error, any client)
{
	if (IsClientInGame(client))
	{
		int result = 0;
		Menu menu = new Menu(MenuInGame);
		if (hndl != null)
		{
			char sCBTop30[256];
			while (SQL_FetchRow(hndl))
			{
				result++;
				SQL_FetchString(hndl, 0, sCBTop30, sizeof(sCBTop30));
				Format(sCBTop30, sizeof(sCBTop30), "%T", "DDR_Top30_Player", client, result, sCBTop30, SQL_FetchInt(hndl, 2));
				// PrintToServer(sCBTop30);
				AddMenuItem(menu, "0", sCBTop30, ITEMDRAW_DISABLED);
			}
			
			SetMenuExitButton(menu, true);
			DisplayMenu(menu, client, MENU_TIME_FOREVER);
			
			delete hndl;
		}
		if (result == 0)
		{
			CPrintToChat(client, "%T", "DDR_Nothing_Found", client, g_sLogo[client]);
			delete menu;
		}
	}
}


void Show_Top50(int client)
{
	if (IsClientInGame(client) && !IsFakeClient(client))
	{
		if (g_hDatabase != null)
		{
			char Query[256];
			Format(Query, sizeof(Query), "SELECT nickname,score FROM ddr_rank ORDER BY score DESC LIMIT 50");
			SQL_TQuery(g_hDatabase, Callback_Top50, Query, client);
		}
	}
}

public void Callback_Top50(Handle owner, Handle hndl, const char[] error, any client)
{
	if (IsClientInGame(client))
	{
		// PrintToServer("1");
		int result = 0;
		Menu menu = new Menu(MenuInGame);
		if (hndl != null)
		{
			// PrintToServer("2");
			char sCBTop50[256];
			while (SQL_FetchRow(hndl))
			{
				result++;
				SQL_FetchString(hndl, 0, sCBTop50, sizeof(sCBTop50));
				Format(sCBTop50, sizeof(sCBTop50), "%T", "DDR_Top50_Player", client, result, sCBTop50, SQL_FetchInt(hndl, 1));
				PrintToServer(sCBTop50);
				AddMenuItem(menu, "0", sCBTop50, ITEMDRAW_DISABLED);
			}
			
			SetMenuExitButton(menu, true);
			DisplayMenu(menu, client, MENU_TIME_FOREVER);
			
			delete hndl;
		}
		if (result == 0)
		{
			CPrintToChat(client, "%T", "DDR_Nothing_Found", client, g_sLogo[client]);
			delete menu;
		}
	}
}

void Show_Mes50TopScore(int client)
{
	if (IsClientInGame(client) && !IsFakeClient(client))
	{
		if (g_hDatabase != null)
		{
			char Query[256], communityid[32];
			
			GetClientAuthId(client, AuthId_SteamID64, communityid, sizeof(communityid));
			
			Format(Query, sizeof(Query), "SELECT music_name, difficulty, score, combo FROM ddr_rank WHERE communityid='%s' ORDER BY score DESC LIMIT 200", communityid);
			SQL_TQuery(g_hDatabase, Callback_vosmeilleurscores, Query, client);
		}
	}
}

public void Callback_vosmeilleurscores(Handle owner, Handle hndl, const char[] error, any client)
{
	if (IsClientInGame(client))
	{
		int result = 0;
		Menu menu = new Menu(MenuInGame);
		if (hndl != null)
		{
			char sCBvosmeilleurscores[256];
			
			while (SQL_FetchRow(hndl))
			{
				result++;
				SQL_FetchString(hndl, 0, sCBvosmeilleurscores, sizeof(sCBvosmeilleurscores));
				
				
				Format(sCBvosmeilleurscores, sizeof(sCBvosmeilleurscores), "%T", "DDR_Top50_Score", client, SQL_FetchInt(hndl, 2), sCBvosmeilleurscores, g_iDifficulty[SQL_FetchInt(hndl, 1)][upperName], SQL_FetchInt(hndl, 3));
				// PrintToServer(sCBvosmeilleurscores);
				AddMenuItem(menu, "0", sCBvosmeilleurscores, ITEMDRAW_DISABLED);
			}
			
			SetMenuExitButton(menu, true);
			DisplayMenu(menu, client, MENU_TIME_FOREVER);
			
			delete hndl;
		}
		if (result == 0)
		{
			CPrintToChat(client, "%T", "DDR_Nothing_Found", client, g_sLogo[client]);
			
			if (menu != null)
				delete menu;
		}
	}
}

void CreateDatabasePlayerDatas()
{
	if (g_hDatabase == null)
	{
		SetFailState("Error! g_hDatabase is invalid!");
		return;
	}
	
	char sQuery[] = "\
		CREATE TABLE IF NOT EXISTS `ddr_playerdatas` ( \
		  `id` int(11) NOT NULL AUTO_INCREMENT, \
		  `nickname` varchar(64) NOT NULL, \
		  `communityid` varchar(32) NOT NULL, \
		  `exp` int(11) NOT NULL, \
		  `level` int(11) NOT NULL, \
		  `last_seen_date` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP, \
		  `last_seen_ip` varchar(32) NOT NULL, \
		  PRIMARY KEY (`id`) \
		) ENGINE=InnoDB  DEFAULT CHARSET=latin1 AUTO_INCREMENT=1 ;";
	SQLQuery(sQuery);
}

void CreateDatabaseRank()
{
	if (g_hDatabase == null)
	{
		SetFailState("Error! g_hDatabase is invalid!");
		return;
	}
	
	char sQuery[] = "\
		CREATE TABLE IF NOT EXISTS `ddr_rank` ( \
		  `id` int(11) NOT NULL AUTO_INCREMENT, \
		  `music_name` varchar(64) NOT NULL, \
		  `difficulty` int(11) NOT NULL, \
		  `nickname` varchar(64) NOT NULL, \
		  `communityid` varchar(32) NOT NULL, \
		  `timestamp` int(11) NOT NULL, \
		  `score` int(11) NOT NULL, \
		  `perfect` int(11) NOT NULL, \
		  `cool` int(11) NOT NULL, \
		  `bad` int(11) NOT NULL, \
		  `miss` int(11) NOT NULL, \
		  `combo` int(11) NOT NULL, \
		  PRIMARY KEY (`id`) \
		) ENGINE=InnoDB  DEFAULT CHARSET=latin1 AUTO_INCREMENT=1;";
	SQLQuery(sQuery);
}
