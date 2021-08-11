public Action Command_Admin_AddSkipLevel( int client, int args )
{
	if ( !client ) return Plugin_Handled;
	
	char query[400];
	GetEntPropVector(client, Prop_Send, "m_vecOrigin", g_vecSkipPos );
	GetClientAbsAngles(client, g_vecSkipAngles );
	FormatEx(query, sizeof(query), "REPLACE INTO skip_zones VALUES('%s', '%i', '%.1f', '%.1f', '%.1f', '%.1f', '%.1f', '%.1f')", g_szCurrentMap, g_iClientMode[client], g_vecSkipPos[0], g_vecSkipPos[1], g_vecSkipPos[2], g_vecSkipAngles[0], g_vecSkipAngles[1], g_vecSkipAngles[2]);
	g_hDatabase.Query( Threaded_Empty, query);
	CPrintToChatAll(CHAT_PREFIX... "Skip position {lightskyblue}Added{white}! <{green}%s{white}>", g_szCurrentMap); 
	return Plugin_Handled;
}

public Action Command_Admin_DelSkipLevel( int client, int args )
{
	if ( !client ) return Plugin_Handled;
	
	char query[400];
	GetEntPropVector(client, Prop_Send, "m_vecOrigin", g_vecSkipPos );
	GetClientAbsAngles(client, g_vecSkipAngles );
	FormatEx(query, sizeof(query), "DELETE FROM levels WHERE map = '%s'", g_szCurrentMap);
	g_hDatabase.Query( Threaded_Empty, query);

	for (int i = 0; i < 3; i++)
	{
		g_vecSkipPos[i] = 0.0;
		g_vecSkipAngles[i] = 0.0;
	}

	CPrintToChatAll(CHAT_PREFIX... "Skip position {red}Deleted{white}! <{green}%s{white}>", g_szCurrentMap); 
	return Plugin_Handled;
}

public Action Command_Admin_ZoneMenu( int client, int args )
{
	if ( !client ) return Plugin_Handled;
	
	
	Menu mMenu = new Menu( Handler_ZoneMain );
	mMenu.SetTitle( "Zone Menu%s\n ", ( g_iBuilderZone[client] != ZONE_INVALID ) ? " :: Building mode" : "" );
	
	if ( g_iBuilderZone[client] != ZONE_INVALID )
	{
		char AutoHeight[100];
		FormatEx( AutoHeight, sizeof(AutoHeight), "%s", (IsBuildingOnGround[client]) ? "Auto Height [ON]" : "Auto Height [OFF]" );

		mMenu.AddItem("", "New Zone", ITEMDRAW_DISABLED );
		mMenu.AddItem( "", "Levels", ITEMDRAW_DISABLED );
		mMenu.AddItem( "", AutoHeight );
		mMenu.AddItem( "", "End Zone" );
		mMenu.AddItem( "", "Cancel Zone" );
		
		mMenu.AddItem( "", "Delete Zone\n ", ITEMDRAW_DISABLED );
	}
	else
	{
		menu_page[client] = 0;
		mMenu.AddItem( "", "New Zone" );
		mMenu.AddItem( "", "Levels" );
		mMenu.AddItem( "", "End Zone", ITEMDRAW_DISABLED );
		mMenu.AddItem( "", "Cancel Zone\n ", ITEMDRAW_DISABLED );
	
		
		mMenu.AddItem( "", "Delete Zone\n " );
	}
	
	mMenu.Display( client, MENU_TIME_FOREVER );

	
	return Plugin_Handled;
}

public int Handler_ZoneMain( Menu mMenu, MenuAction action, int client, int index )
{
	if ( action == MenuAction_End ) { delete mMenu; return 0; }
	if ( action != MenuAction_Select ) return 0;
	
	
	// We got an item!
	if ( g_iBuilderZone[client] != ZONE_INVALID )
	{
		switch ( index )
		{
			case 0 : ChooseZoneType(client);
			case 1 : FakeClientCommand( client, "sm_startlevels" );
			case 2 : { 
				IsBuildingOnGround[client] = !IsBuildingOnGround[client];
				FakeClientCommand( client, "sm_zone" );
			}
			case 3 : FakeClientCommand( client, "sm_endzone" );
			case 4 : FakeClientCommand( client, "sm_cancelzone" );

			case 5 : FakeClientCommand( client, "sm_deletezone" );
		}
	}
	else
	{
		switch ( index )
		{
			case 0 : ChooseZoneType(client);
			case 1 : FakeClientCommand( client, "sm_startlevels" );
			case 2 : FakeClientCommand( client, "sm_endzone" );
			case 3 : FakeClientCommand( client, "sm_cancelzone" );

			case 4 : FakeClientCommand( client, "sm_deletezone" );
		}
	}
	
	return 0;
}

public void ChooseZoneType(int client)
{
	Menu mMenu = new Menu(Handler_ChooseZoneType);

	mMenu.SetTitle("Select Zone Type\n ");

	mMenu.AddItem("", "Main");
	mMenu.AddItem("", "Cources");
	mMenu.AddItem("", "Bonuses");
	mMenu.AddItem("", "Checkpoints\n ");
	mMenu.AddItem("", "Course Teleport");
	mMenu.AddItem("", "Block pass");
	mMenu.AddItem("", "Skip level");


	mMenu.ExitBackButton = true;
	mMenu.Display(client, MENU_TIME_FOREVER);
}

public Action Command_Admin_Levels( int client, int args )
{
	if ( !client ) return Plugin_Handled;
	if (!IsPlayerAlive(client)) return Plugin_Handled;
	if ( g_iBuilderZone[client] != ZONE_INVALID )
	{
		PRINTCHAT( client, CHAT_PREFIX..."You've started to build a zone!" );
		return Plugin_Handled;
	}
	
	
	Menu mMenu = new Menu( Handler_LevelCreate );
	mMenu.SetTitle( "Level Creation\n " );
	mMenu.AddItem( "", "Add Level\n ");
	mMenu.AddItem( "", "Change Level\n ");
	mMenu.AddItem( "", "Delete Level\n ");
	mMenu.ExitBackButton = true;
	mMenu.Display(client, MENU_TIME_FOREVER);
	return Plugin_Handled;
}

public int Handler_ChooseZoneType( Menu mMenu, MenuAction action, int client, int item )
{
	if ( action == MenuAction_End ) { delete mMenu; return 0; }
	if (!IsPlayerAlive(client)) { return 0; }
	if (action == MenuAction_Cancel)
	{
	    if (item == MenuCancel_ExitBack)
		{  
			FakeClientCommand( client, "sm_zone" );
		 	return 0; 
		}
	}
	
	if ( action != MenuAction_Select ) return 0;

	CreateZone(client, item);

	return 0;
}

public void CreateZone(int client, int type)
{
	if ( !client ) return;
	
	if ( g_iBuilderZone[client] != ZONE_INVALID )
	{
		PRINTCHAT( client, CHAT_PREFIX..."You've already started to build a zone!" );
		return;
	}

	char szTypeZone[40];
	ZoneType[client] = type;

	switch (type)
	{
		case 0: strcopy(szTypeZone, sizeof(szTypeZone), "Main");
		case 1: strcopy(szTypeZone, sizeof(szTypeZone), "Courses");
		case 2: strcopy(szTypeZone, sizeof(szTypeZone), "Bonuses");
		case 3: strcopy(szTypeZone, sizeof(szTypeZone), "Checkpoints");
		case 4: strcopy(szTypeZone, sizeof(szTypeZone), "Course Teleport");
		case 5: strcopy(szTypeZone, sizeof(szTypeZone), "Block pass");
		case 6: strcopy(szTypeZone, sizeof(szTypeZone), "Skip level");
		
	}

	Menu mMenu = new Menu( Handler_ZoneCreate );
	mMenu.SetTitle( "Zone Creation\nType: %s\n ", szTypeZone );
	char item[50];
	
	if (type == 0)
	{
		for ( int i = ZONE_START; i <= ZONE_END; i++ )
		{
			char szMain[10];
			IntToString(i, szMain, sizeof(szMain));
			if (g_bZoneExists[i][0])
			{
				FormatEx(item, sizeof(item), "%s (Add one more)", g_szZoneNames[i]);	
			}
			else 
			{
				FormatEx(item, sizeof(item), "%s", g_szZoneNames[i]);
			}
			mMenu.AddItem( szMain, item);
		}
	}
	else if (type == 1)
	{
		for ( int i = ZONE_COURSE_1_START; i <= ZONE_COURSE_10_END; i++ )
		{
			char szCource[10];
			IntToString(i, szCource, sizeof(szCource));
			if (g_bZoneExists[i][0])
			{
				FormatEx(item, sizeof(item), "%s (Add one more)", g_szZoneNames[i]);
			}
			else 
			{
				FormatEx(item, sizeof(item), "%s", g_szZoneNames[i]);
			}
			mMenu.AddItem( szCource, item);
		}
	}
	else if (type == 2)
	{
		for ( int i = ZONE_BONUS_1_START; i <= ZONE_BONUS_10_END; i++ )
		{
			char szBonus[10];
			IntToString(i, szBonus, sizeof(szBonus));
			if (g_bZoneExists[i][0])
			{
				FormatEx(item, sizeof(item), "%s (Add one more)", g_szZoneNames[i]);
			}
			else 
			{
				FormatEx(item, sizeof(item), "%s", g_szZoneNames[i]);
			}
			mMenu.AddItem( szBonus, item);
		}
	}
	else if (type == 3)
	{
		char szCP[10];
		IntToString(ZONE_CP, szCP, sizeof(szCP));
		mMenu.AddItem( szCP, "Add Checkpoint");
	}
	else if (type == 4)
	{
		char szTele[10];
		IntToString(ZONE_COURCE, szTele, sizeof(szTele));
		mMenu.AddItem( szTele, "Add Teleport to next course");
	}
	else if (type == 5)
	{
		char szBlock[10];
		IntToString(ZONE_BLOCKS, szBlock, sizeof(szBlock));
		mMenu.AddItem( szBlock, "Add Block zone");
	}
	else if (type == 6)
	{
		char szTele[10];
		IntToString(ZONE_SKIP, szTele, sizeof(szTele));
		mMenu.AddItem( szTele, "Add Skip level");
	}
	
	mMenu.ExitBackButton = true;
	mMenu.DisplayAt( client, menu_page[client], MENU_TIME_FOREVER );
	
	return;
}

public int Handler_ZoneCreate( Menu mMenu, MenuAction action, int client, int item )
{
	if ( action == MenuAction_End ) { delete mMenu; return 0; }
	if (action == MenuAction_Cancel)
	{
	    if (item == MenuCancel_ExitBack)
		{  
			g_bStartBuilding[client] = false;
			ChooseZoneType(client);
		 	return 0;
		}
	}
	
	if ( action != MenuAction_Select ) return 0;
	char szZone[10];
	GetMenuItem( mMenu, item, szZone, sizeof( szZone ) );
	int zone = StringToInt(szZone);
	
	if ( zone < 0 || zone >= NUM_ZONES_W_CP ) return 0;
	
	// Doublecheck just in case...
	if ( zone < NUM_REALZONES && g_bZoneBeingBuilt[zone] ) return 0;

	ZoneIndex[client] = 0;
	for (int i=0; i<20; i++)
	{
		if (zone < NUM_REALZONES)
		{
			if (g_bZoneExists[zone][i])
				ZoneIndex[client] = i+1;
			else
				break;	
		}
	}
	menu_page[client] = GetMenuSelectionPosition();
	ZoningMethod(client, zone, 1);
	
	return 0;
}

public void ZoningMethod(int client, int zone, int type)
{
	char method[60];
	char method2[60];
	char szType[10];

	Menu mMenu = new Menu( Handler_ZoneMethod );
	mMenu.SetTitle( "Select the Zoning Method\nZone: %s\n ", g_szZoneNames[zone] );

	switch (type)
	{
		case 1:
		{
		 	FormatEx(method, sizeof(method), "Eye position");
		 	FormatEx(method2, sizeof(method2), "Player origin position");
		 	FormatEx(szType, sizeof(szType), "-1_%i", zone);
		 	mMenu.AddItem(szType, "Start Build (Select Method)\n ", ITEMDRAW_DISABLED);

		}
		case 2:
		{
			g_bStartBuilding[client] = true;
		 	FormatEx(method, sizeof(method), "Eye position [✔]");
		 	FormatEx(method2, sizeof(method2), "Player origin position");
		 	FormatEx(szType, sizeof(szType), "1_%i", zone);
		 	mMenu.AddItem(szType, "Start Build (Eye)\n " );
		 	g_ZoneMethod[client] = 0;
			TimerEye[client] = CreateTimer( ZONE_BUILD_INTERVAL, Timer_DrawBuildZoneStartEye, client, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE );
		}
		case 3:
		{
			g_bStartBuilding[client] = true;
			FormatEx(szType, sizeof(szType), "2_%i", zone);
		 	FormatEx(method, sizeof(method), "Eye position");
		 	FormatEx(method2, sizeof(method2), "Player origin position [✔]");
		 	mMenu.AddItem(szType, "Start Build (Origin)\n ");
		 	g_ZoneMethod[client] = 1;
		 	
			TimerEye[client] = CreateTimer( ZONE_BUILD_INTERVAL, Timer_DrawBuildZoneStartOrigin, client, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE );
		}
	}
	mMenu.AddItem("", method);
	mMenu.AddItem("", method2);

	mMenu.ExitBackButton = true;
	mMenu.Display( client, MENU_TIME_FOREVER );

}

public int Handler_ZoneMethod( Menu mMenu, MenuAction action, int client, int method )
{
	if (client <= 0) return 0;
	
	if ( action == MenuAction_End && action != MenuAction_Select) 
	{ 
		g_bStartBuilding[client] = false;
		if (TimerEye[client] != null)
		{
			KillTimer(TimerEye[client]);
			TimerEye[client] = null;
		}
		delete mMenu;
		return 0; 
	}
	if (action == MenuAction_Cancel)
	{
	    if (method == MenuCancel_ExitBack)
		{  
			g_bStartBuilding[client] = false;
			CreateZone(client, ZoneType[client]);
			if (TimerEye[client] != null)
			{
				KillTimer(TimerEye[client]);
				TimerEye[client] = null;
			}
			return 0; 
		}
		if (TimerEye[client] != null)
		{
			KillTimer(TimerEye[client]);
			TimerEye[client] = null;
		}
		g_bStartBuilding[client] = false;
		
		return 0; 
	}
	
	if ( action != MenuAction_Select ) {
		g_bStartBuilding[client] = false;
		if (TimerEye[client] != null)
		{
			KillTimer(TimerEye[client]);
			TimerEye[client] = null;
		}
		return 0; 
	}
	
	char szItem[10];
	GetMenuItem( mMenu, 0, szItem, sizeof( szItem ) );

	char szInfo[2][6];
  	if ( !ExplodeString( szItem, "_", szInfo, sizeof( szInfo ), sizeof( szInfo[] ) ) )
  		return 0;
  		
  	int zone = StringToInt(szInfo[1]);
	
	if ( zone < 0 || zone >= NUM_ZONES_W_CP ) { g_bStartBuilding[client] = false; return 0; }
	
	// Doublecheck just in case...
	if ( zone < NUM_REALZONES && g_bZoneBeingBuilt[zone] ) { g_bStartBuilding[client] = false; return 0; }

	switch (method)
	{
		case 0:
		{
			if (TimerEye[client] != null)
			{
				KillTimer(TimerEye[client]);
				TimerEye[client] = null;
			}

			if (StrEqual(szInfo[0], "1") )
			{
				StartToBuild( client, zone, true );
				FakeClientCommand( client, "sm_zone" );
			}
			else if (StrEqual(szInfo[0], "2") )
			{
				StartToBuild( client, zone, false );
				FakeClientCommand( client, "sm_zone" );
			}
		}
		case 1:
		{
			g_bStartBuilding[client] = false;
			if (TimerEye[client] != null)
			{
				KillTimer(TimerEye[client]);
				TimerEye[client] = null;
			}

			ZoningMethod(client, zone, 2);
		}
		case 2:
		{
			g_bStartBuilding[client] = false;
			if (TimerEye[client] != null)
			{
				KillTimer(TimerEye[client]);
				TimerEye[client] = null;
			}

			ZoningMethod(client, zone, 3);
		}
	}
	return 0;
}

public int Handler_LevelCreate( Menu mMenu, MenuAction action, int client, int item )
{
	if ( action == MenuAction_End ) { delete mMenu; return 0; }
	if (!IsPlayerAlive(client)) { return 0; }
	if (action == MenuAction_Cancel)
	{
	    if (item == MenuCancel_ExitBack)
		{  
			FakeClientCommand( client, "sm_zone" );
		 	return 0; 
		}
	}
	
	if ( action != MenuAction_Select ) return 0;
	if (item == 0)
	{
		int levels_count = 0;
		bool isMissing = false;
			
		for (int i = 0; i < 199; i++)
		{
			if (g_fClientLevelPos[i][0] != 0.0 || g_fClientLevelPos[i][1] != 0.0 || g_fClientLevelPos[i][2] != 0.0)
			{
				levels_count++;
			}

			if ((g_fClientLevelPos[i][0] == 0.0 && g_fClientLevelPos[i][1] == 0.0 && g_fClientLevelPos[i][2] == 0.0) && (g_fClientLevelPos[i+1][0] != 0.0 || g_fClientLevelPos[i+1][1] != 0.0 || g_fClientLevelPos[i+1][2] != 0.0))
				isMissing = true;
		}

		if (isMissing)
		{
			CPrintToChat(client, "{red}ERROR{white} | Missing levels found, you must add them before you add a new level!");
			menu_page[client] = 0;
			MissLevels(client);
			return 0;
		}

		char query[200];
		GetEntPropVector(client, Prop_Send, "m_vecOrigin", g_fClientLevelPos[levels_count] );
		GetClientAbsAngles(client, g_fClientLevelAng[levels_count] );

		g_hDatabase.Format(query, sizeof(query), "INSERT INTO levels VALUES( %i, '%s', %.1f, %.1f, %.1f, %.1f, %.1f, %.1f )", levels_count, g_szCurrentMap, g_fClientLevelPos[levels_count][0], g_fClientLevelPos[levels_count][1], g_fClientLevelPos[levels_count][2], g_fClientLevelAng[levels_count][0], g_fClientLevelAng[levels_count][1], g_fClientLevelAng[levels_count][2]);
		g_hDatabase.Query(Threaded_Empty, query);

		CPrintToChat(client, CHAT_PREFIX..."Level \x0750DCFF%i {white}has been created!", levels_count+1);
		FakeClientCommand( client, "sm_startlevels" );
	}
	else if (item == 1)
	{
		menu_page[client] = 0;
		ChangeLevels(client);
	}
	else if (item == 2)
	{
		menu_page[client] = 0;
		DeleteLevels(client);
	}
	return 0;
}

public void ChangeLevels(int client)
{
	Menu mMenu = new Menu(Handler_ChangeLevel);
	mMenu.SetTitle("Change Levels\n ");

	char lvl[10];
	char szLvl[50];
	int count = 0;

	for (int i = 0; i < 200; i++)
	{
		if (g_fClientLevelPos[i][0] != 0.0 || g_fClientLevelPos[i][1] != 0.0 || g_fClientLevelPos[i][2] != 0.0)
		{
			IntToString(i, lvl, sizeof(lvl));
			FormatEx(szLvl, sizeof(szLvl), "Change level %i", i+1);
			mMenu.AddItem(lvl, szLvl);
			count++;
		}
	}

	if (count == 0)
	{
		mMenu.AddItem("", "No Levels", ITEMDRAW_DISABLED);
	}

	mMenu.ExitBackButton = true;
	mMenu.DisplayAt(client, menu_page[client], MENU_TIME_FOREVER);
}

public int Handler_ChangeLevel( Menu mMenu, MenuAction action, int client, int item )
{
	if ( action == MenuAction_End ) { delete mMenu; return 0; }
	if (!IsPlayerAlive(client)) { return 0; }
	if (action == MenuAction_Cancel)
	{
	    if (item == MenuCancel_ExitBack)
		{  
			FakeClientCommand( client, "sm_startlevels" );
		 	return 0; 
		}
	}

	if (action == MenuAction_Select)
	{
		char szItem[20];
		int lvl;
		GetMenuItem( mMenu, item, szItem, sizeof( szItem ) );
		StringToIntEx(szItem, lvl);
		menu_page[client] = GetMenuSelectionPosition();

		char query[200];
		GetEntPropVector(client, Prop_Send, "m_vecOrigin", g_fClientLevelPos[lvl] );
		GetClientAbsAngles(client, g_fClientLevelAng[lvl] );

		g_hDatabase.Format(query, sizeof(query), "Update levels SET pos0 = %.1f, pos1 = %.1f, pos2 = %.1f, ang0 = %.1f, ang1 = %.1f, ang2 = %.1f WHERE level = %i AND map = '%s'", g_fClientLevelPos[lvl][0], g_fClientLevelPos[lvl][1], g_fClientLevelPos[lvl][2], g_fClientLevelAng[lvl][0], g_fClientLevelAng[lvl][1], g_fClientLevelAng[lvl][2], lvl, g_szCurrentMap);
		g_hDatabase.Query(Threaded_Empty, query);

		CPrintToChat(client, CHAT_PREFIX..."Level \x0750DCFF%i {white}has been updated!", lvl+1);

		ChangeLevels(client);
		return 0;
	}
}

public void MissLevels(int client)
{
	Menu mMenu = new Menu(Handler_MissLevel);
	mMenu.SetTitle("Added Missed Levels\n ");

	char lvl[10];
	char szLvl[50];
	int MissCount;

	for (int i = 0; i < 199; i++)
	{
		for (int a = i+1; a < 198; a++)
		{
			if ((g_fClientLevelPos[i][0] == 0.0 && g_fClientLevelPos[i][1] == 0.0 && g_fClientLevelPos[i][2] == 0.0) && (g_fClientLevelPos[a][0] != 0.0 || g_fClientLevelPos[a][1] != 0.0 || g_fClientLevelPos[a][2] != 0.0))
			{
				IntToString(i, lvl, sizeof(lvl));
				FormatEx(szLvl, sizeof(szLvl), "Add level %i", i+1);
				mMenu.AddItem(lvl, szLvl);
				MissCount++;
				break;
			}
		}
	}

	if (MissCount == 0)
	{
		CPrintToChat(client, "\x04Successful{white} | Done, the levels are correct");
		FakeClientCommand( client, "sm_startlevels" );
		return;
	}

	mMenu.ExitBackButton = true;
	mMenu.DisplayAt(client, menu_page[client], MENU_TIME_FOREVER);
}

public int Handler_MissLevel( Menu mMenu, MenuAction action, int client, int item )
{
	if ( action == MenuAction_End ) { delete mMenu; return 0; }
	if (!IsPlayerAlive(client)) { return 0; }
	if (action == MenuAction_Cancel)
	{
	    if (item == MenuCancel_ExitBack)
		{  
			FakeClientCommand( client, "sm_startlevels" );
		 	return 0; 
		}
	}

	if (action == MenuAction_Select)
	{
		char szItem[20];
		int lvl;
		GetMenuItem( mMenu, item, szItem, sizeof( szItem ) );
		StringToIntEx(szItem, lvl);
		menu_page[client] = GetMenuSelectionPosition();

		char query[200];
		GetEntPropVector(client, Prop_Send, "m_vecOrigin", g_fClientLevelPos[lvl] );
		GetClientAbsAngles(client, g_fClientLevelAng[lvl] );

		g_hDatabase.Format(query, sizeof(query), "INSERT INTO levels VALUES( %i, '%s', %.1f, %.1f, %.1f, %.1f, %.1f, %.1f )", lvl, g_szCurrentMap, g_fClientLevelPos[lvl][0], g_fClientLevelPos[lvl][1], g_fClientLevelPos[lvl][2], g_fClientLevelAng[lvl][0], g_fClientLevelAng[lvl][1], g_fClientLevelAng[lvl][2]);
		g_hDatabase.Query(Threaded_Empty, query);

		CPrintToChat(client, CHAT_PREFIX..."Level \x0750DCFF%i {white}has been created!", lvl+1);

		MissLevels(client);
		return 0;
	}
}

public void DeleteLevels(int client)
{
	Menu mMenu = new Menu(Handler_DelLevels);

	mMenu.SetTitle("Delete Level\n ");
	static char item[10], szItem[30];
	bool find = false;
	for (int i=0; i < 200; i++)
	{
		if (g_fClientLevelPos[i][0] != 0.0 || g_fClientLevelPos[i][1] != 0.0 || g_fClientLevelPos[i][2] != 0.0)
		{
			IntToString(i, item, sizeof(item));
			FormatEx(szItem, sizeof(szItem), "Level %i", i+1);
			mMenu.AddItem(item, szItem);
			find = true;
		}
	}

	if (!find)
	{
		mMenu.AddItem("", "No levels", ITEMDRAW_DISABLED);
	}	
	mMenu.ExitBackButton=true;
	mMenu.DisplayAt(client, menu_page[client], MENU_TIME_FOREVER);
}

public int Handler_DelLevels( Menu mMenu, MenuAction action, int client, int item )
{
	if ( action == MenuAction_End ) { delete mMenu; return 0; }
	if (!IsPlayerAlive(client)) { return 0; }
	if (action == MenuAction_Cancel)
	{
	    if (item == MenuCancel_ExitBack)
		{  
			FakeClientCommand( client, "sm_startlevels" );
		 	return 0; 
		}
	}
	
	if ( action != MenuAction_Select ) return 0;

	char szItem[20];
	int lvl;
	GetMenuItem( mMenu, item, szItem, sizeof( szItem ) );
	StringToIntEx(szItem, lvl);
	char query[200];

	g_hDatabase.Format(query, sizeof(query), "DELETE FROM levels WHERE map = '%s' and level = %i", g_szCurrentMap, lvl);
	g_hDatabase.Query(Threaded_Empty, query);

	CPrintToChat(client, CHAT_PREFIX..."Level \x0750DCFF%i {white}has been Deleted!", lvl+1);
	for (int i = 0; i<3; i++)
	{
		g_fClientLevelAng[lvl][i] = 0.0;
		g_fClientLevelPos[lvl][i] = 0.0;
	}
	menu_page[client] = GetMenuSelectionPosition();
	DeleteLevels(client);
	return 0;
}

public Action Command_Admin_ZoneEdit( int client, int args )
{
	if ( !client ) return Plugin_Handled;
	
	if ( g_iBuilderZone[client] != ZONE_INVALID )
	{
		PRINTCHAT( client, CHAT_PREFIX..."You are still making a zone!" );
		return Plugin_Handled;
	}
	
	int len = g_hZones.Length;
	if ( !len )
	{
		PRINTCHAT( client, CHAT_PREFIX..."There are no zones to change!" );
		
		FakeClientCommand( client, "sm_zone" );
		
		return Plugin_Handled;
	}
	
	
	Menu mMenu = new Menu( Handler_ZoneEdit );
	mMenu.SetTitle( "Choose Zone\n " );
	
	char szItem[24];
	int num;
	
	for ( int i = 0; i < len; i++ )
	{
		num = view_as<int>( g_hZones.Get( i, view_as<int>( ZONE_ID ) ) ) + 1;
		
		if ( g_hZones.Get( i, view_as<int>( ZONE_TYPE ) ) == ZONE_COURCE )
		{
			FormatEx( szItem, sizeof( szItem ), "Cource teleport #%i", num );
		}
		else
		{
			FormatEx( szItem, sizeof( szItem ), "Block #%i", num );
		}
		
		mMenu.AddItem( "", szItem );
	}
	
	AddMenuItem( mMenu, "f", "Find Zone You Are In" );
	
	mMenu.Display( client, MENU_TIME_FOREVER );

	
	return Plugin_Handled;
}

public int Handler_ZoneEdit( Menu mMenu, MenuAction action, int client, int index )
{
	if ( action == MenuAction_End ) { delete mMenu; return 0; }
	if ( action != MenuAction_Select ) return 0;
	
	
	char szItem[2];
	
	if ( !GetMenuItem( mMenu, index, szItem, sizeof( szItem ) ) ) return 0;
	
	
	if ( szItem[0] == 'f' )
	{
		FakeClientCommand( client, "sm_selectcurzone" );
		return 0;
	}
	
	
	if ( index < 0 || index >= g_hZones.Length ) return 0;
	
	
	g_iBuilderZoneIndex[client] = index;
	
	FakeClientCommand( client, "sm_zonepermissions" );
	
	return 0;
}

public Action Command_Admin_ZoneDelete( int client, int args )
{
	if ( !client ) return Plugin_Handled;
	
	
	Menu mMenu = new Menu( Handler_ZoneDelete );
	mMenu.SetTitle( "Zone Delete\n " );
	
	
	bool bFound;
	bool bDraw;
	char szItem[32], szZone[10];
	
	for ( int i = 0; i < NUM_ZONES_W_CP; i++ )
	{
		bDraw = true;
		
		if ( i == ZONE_BLOCKS || i == ZONE_CP || i == ZONE_COURCE || i == ZONE_SKIP )
		{
			FormatEx( szItem, sizeof( szItem ), "%s (sub-menu)", g_szZoneNames[i] );
		}
		else
		{
			int count=0;
			for (int b = 1; b < 10; b++)
			{
				if (g_bZoneExists[i][b])
					count++;
			}
			if (count > 0 )
			{
				FormatEx( szItem, sizeof( szItem ), "%s (sub-menu)", g_szZoneNames[i] );
			}
			else
			{
				if (g_bZoneExists[i][0])
				{
					FormatEx( szItem, sizeof( szItem ), "%s", g_szZoneNames[i] );
				}
				else
				{
					FormatEx( szItem, sizeof( szItem ), "%s", g_szZoneNames[i] );
					bDraw = false;
				}		
			}
		}
		
		
		// Whether we draw it as disabled or not.
		if ( i == ZONE_BLOCKS || i == ZONE_COURCE || i == ZONE_SKIP )
		{
			for (int j=0; j < g_hZones.Length; j++)
			{
				if (g_hZones.Get( j, view_as<int>( ZONE_TYPE )) == i)
				{
					bDraw = true;
					break;
				}
				bDraw = false;
			}
		}
		else if ( i == ZONE_CP )
		{
			if ( g_hCPs == null || !g_hCPs.Length )
				bDraw = false;
		}
		
		if ( bDraw )
		{
			bFound = true;
			IntToString(i, szZone, sizeof(szZone));
			mMenu.AddItem( szZone, szItem, 0 );
		}
	}
	
	if ( !bFound )
	{
		PRINTCHAT( client, CHAT_PREFIX..."There are no zones to delete!" );
		
		delete mMenu;
		return Plugin_Handled;
	}

	mMenu.ExitBackButton = true;
	mMenu.DisplayAt( client, menu_page[client], MENU_TIME_FOREVER );
	
	return Plugin_Handled;
}

public void DeleteZoneByIndex(int client, int zone)
{
	if ( !client ) return;
	
	char szItemInt[20];
	char szItem[60];
	Menu mMenu = new Menu( Handler_ZoneDeleteByIndex );
	mMenu.SetTitle( "Zone Delete\nZone: %s\n \n", g_szZoneNames[zone] );

	for (int i=0; i < 20; i++)
	{
		if (g_bZoneExists[zone][i])
		{
			FormatEx(szItem, sizeof(szItem), "Zone #%i", i+1);
			FormatEx(szItemInt, sizeof(szItemInt), "%i_%i", zone, i);
			mMenu.AddItem(szItemInt, szItem);
		}
	}
	mMenu.ExitBackButton = true;
	mMenu.Display( client, MENU_TIME_FOREVER );

}

public int Handler_ZoneDeleteByIndex( Menu mMenu, MenuAction action, int client, int zoneid )
{
	if ( action == MenuAction_End ) { delete mMenu; return 0; }

	if (action == MenuAction_Cancel)
	{
	    if (zoneid == MenuCancel_ExitBack)
		{  
			FakeClientCommand(client, "sm_deletezone");
			return 0;
		}
	}
	if ( action == MenuAction_Select )
	{
		char szItem[12];
		if ( !GetMenuItem( mMenu, zoneid, szItem, sizeof( szItem ) ) ) return 0;
		
		char szInfo[2][6];
		
		if ( !ExplodeString( szItem, "_", szInfo, sizeof( szInfo ), sizeof( szInfo[] ) ) )
			return 0;

		int zone = StringToInt(szInfo[0]);
		int index = StringToInt(szInfo[1]);

		char query[100];
		g_hDatabase.Format(query, sizeof(query), "DELETE FROM mapbounds WHERE map = '%s' AND zone = %i AND number = %i", g_szCurrentMap, zone, index);
		g_hDatabase.Query(Threaded_Empty, query);

		DeleteZoneBeams( zone, 0, index );

		g_bZoneExists[zone][index] = false;

		CPrintToChatAll( CHAT_PREFIX...""...CLR_TEAM..."%s {white}::index {orange}%i{white}::"...CLR_TEXT..." deleted.", g_szZoneNames[zone], index+1 );
		
	}
	return Plugin_Handled;
}

public int Handler_ZoneDelete( Menu mMenu, MenuAction action, int client, int item )
{
	if ( action == MenuAction_End ) { delete mMenu; return 0; }
	
	if (action == MenuAction_Cancel)
	{
	    if (item == MenuCancel_ExitBack)
		{ 
			FakeClientCommand(client, "sm_zone" );
			return 0;
		}
	}

	if ( action == MenuAction_Select )
	{
		char szZone[10];
		int zone;

		GetMenuItem(mMenu, item, szZone, sizeof(szZone));
		zone = StringToInt(szZone);

		if ( zone < 0 || zone >= NUM_ZONES_W_CP ) return 0;
		
		if ( zone == ZONE_BLOCKS || zone == ZONE_COURCE || zone == ZONE_SKIP )
		{
			menu_page[client] = 0;
			FakeClientCommand( client, "sm_deletezone2" );
			return 0;
		}
		
		if ( zone == ZONE_CP )
		{
			menu_page[client] = 0;
			FakeClientCommand( client, "sm_deletecp" );
			return 0;
		}
		
		
		if ( zone < NUM_REALZONES )
		{
			for (int i=1; i < 10; i++)
			{
				if (g_bZoneExists[zone][i])
				{
					DeleteZoneByIndex(client, zone);
					return 0;
				}
			}
			menu_page[client] = GetMenuSelectionPosition();
			g_bZoneExists[zone][0] = false;
			DeleteZoneBeams( zone );
		}
		PrintColorChatAll( client, CHAT_PREFIX...""...CLR_TEAM..."%s"...CLR_TEXT..." deleted!", g_szZoneNames[zone] );
		
		for (int i = 0; i < NUM_RUNS+20; i+=2)
		{
			if ( (zone == i || zone == i+1) && g_bIsLoaded[i/2] )
			{
				g_bIsLoaded[i/2] = false;
				PrintColorChatAll( client, CHAT_PREFIX...""...CLR_TEAM..."%s"...CLR_TEXT..." is no longer available for running!", g_szRunName[NAME_LONG][i/2] );
			}
		}
		
		// Erase them from the database.
		DB_EraseMapZone( zone );
		
		
		FakeClientCommand( client, "sm_deletezone" );
		
		return 0;
	}
}

public Action Command_Admin_ZoneDelete2( int client, int args )
{
	if ( !client ) return Plugin_Handled;

	Menu mMenu = new Menu( Handler_ZoneDelete_S );
	mMenu.SetTitle( "Zone Delete (Block/Cource teleport)\n " );

	int len = g_hZones.Length;
	if ( !len )
	{
		mMenu.AddItem( "", "no zones to delete!", ITEMDRAW_DISABLED );
		return Plugin_Handled;
	}
	
	char szItem[24];
	char szIndex[10];

	for ( int i = 0; i < len; i++ )
	{
		if (g_hZones.Get( i, view_as<int>( ZONE_TYPE )) < NUM_REALZONES) continue;

		switch (g_hZones.Get( i, view_as<int>( ZONE_TYPE )))
		{
			case ZONE_COURCE : FormatEx( szItem, sizeof( szItem ), "Cource teleport #%i", g_hZones.Get( i, view_as<int>( ZONE_ID ) ) + 1 );
			case ZONE_SKIP : FormatEx( szItem, sizeof( szItem ), "Skip level #%i", g_hZones.Get( i, view_as<int>( ZONE_ID ) ) + 1 );
			case ZONE_BLOCKS : FormatEx( szItem, sizeof( szItem ), "Block #%i", g_hZones.Get( i, view_as<int>( ZONE_ID ) ) + 1 );
		}
		
		IntToString(i, szIndex, sizeof(szIndex));
		mMenu.AddItem( szIndex, szItem );
	}
	
	mMenu.DisplayAt( client, menu_page[client], MENU_TIME_FOREVER );
	
	return Plugin_Handled;
}

public int Handler_ZoneDelete_S( Menu mMenu, MenuAction action, int client, int item )
{
	if ( action == MenuAction_End ) { delete mMenu; return 0; }
	if ( action != MenuAction_Select ) return 0;
	
	char szIndex[10];
	GetMenuItem(mMenu, item, szIndex, sizeof(szIndex));
	int index = StringToInt(szIndex);

	int ent = g_hZones.Get( index, view_as<int>( ZONE_ENT ) );
	int zone = g_hZones.Get( index, view_as<int>( ZONE_TYPE ) );
	
	int id = g_hZones.Get( index, view_as<int>( ZONE_ID ) );
	
	
	g_hZones.Erase( index );
	
	// Erase them from the database.
	DB_EraseMapZone( zone, id );
	
	if ( ent > 0 )
	{
		DeleteZoneBeams( zone, id );
		
		RemoveEdict( ent );
		
		PRINTCHATV( client, CHAT_PREFIX...""...CLR_TEAM..."%s"...CLR_TEXT..." zone deleted.", g_szZoneNames[zone] );
	}
	else
	{
		PRINTCHATV( client, CHAT_PREFIX..."Couldn't remove "...CLR_TEAM..."%s"...CLR_TEXT..." zone entity! Reloading the map will get rid of it.", g_szZoneNames[zone] );
		LogError( CONSOLE_PREFIX..."Attemped to remove %s zone but found invalid entity index (%i)!", g_szZoneNames[zone], ent );
		
		return 0;
	}

	menu_page[client] = GetMenuSelectionPosition();
	FakeClientCommand( client, "sm_deletezone2" );
	
	return 0;
}

public Action Command_Admin_ZoneDelete_CP( int client, int args )
{
	if ( !client ) return Plugin_Handled;
	
	int len = g_hCPs.Length;

	Menu mMenu = new Menu( Handler_ZoneDelete_CP );
	mMenu.SetTitle( "Checkpoint Delete\n " );
	
	if ( !len )
	{
		mMenu.AddItem( "", "No checkpoints", ITEMDRAW_DISABLED );
	}
	
	char szItem[32];
	char szId[5];
	for ( int i = 0; i < len; i++ )
	{
		IntToString(i, szId, sizeof(szId));
		FormatEx( szItem, sizeof( szItem ), "CP #%i",
			g_hCPs.Get( i, view_as<int>( CP_ID ) ) + 1);
			
		mMenu.AddItem( szId, szItem );
	}
	
	mMenu.DisplayAt( client, menu_page[client], MENU_TIME_FOREVER );
	
	return Plugin_Handled;
}

public int Handler_ZoneDelete_CP( Menu mMenu, MenuAction action, int client, int item )
{
	if ( action == MenuAction_End ) { delete mMenu; return 0; }
	if ( action != MenuAction_Select ) return 0;
	
	char szItem[10];
	GetMenuItem( mMenu, item, szItem, sizeof( szItem ) );

	int index = StringToInt(szItem);

	if ( index < 0 || index >= g_hCPs.Length ) return 0;

	int ent = EntRefToEntIndex( g_hCPs.Get( index, view_as<int>( CP_ENTREF ) ) );
	int id = g_hCPs.Get( index, view_as<int>( CP_ID ) );
	
	
	g_hCPs.Erase( index );
	
	// Erase them from the database.
	DB_EraseMapZone( ZONE_CP, id );

	
	if ( ent > 0 )
	{
		DeleteZoneBeams( ZONE_CP, id );
		
		RemoveEdict( ent );
		
		CPrintToChat( client, CHAT_PREFIX..."Checkpoint {lightskyblue}%i {white}deleted.", id + 1 );
	}
	else
	{
		PRINTCHAT( client, CHAT_PREFIX..."Couldn't remove checkpoint entity! Reloading the map will get rid of it." );
		
		LogError( CONSOLE_PREFIX..."Attemped to remove a checkpoint but found invalid entity index (%i)!", ent );
		
		return 0;
	}
	
	menu_page[client] = GetMenuSelectionPosition();
	FakeClientCommand( client, "sm_deletecp" );
	
	return 0;
}

public Action Command_Admin_RunRecordsDelete( int client, int args )
{
	if ( !client ) return Plugin_Handled;
	
	
	Menu mMenu = new Menu( Handler_RunRecordsDelete );
	mMenu.SetTitle( "Remove Records\n " );
	
	char szItem[32];
	
	mMenu.AddItem( "", "Map (sub-menu)" );
	for ( int i = 1; i < NUM_RUNS; i++ )
	{
		FormatEx( szItem, sizeof( szItem ), "%s (sub-menu)", g_szRunName[NAME_LONG][i] );
		
		mMenu.AddItem( "", szItem, ( g_bIsLoaded[i] ) ? 0 : ITEMDRAW_DISABLED );
	}
	
	mMenu.Display( client, MENU_TIME_FOREVER );

	
	return Plugin_Handled;
}

public int Handler_RunRecordsDelete( Menu mMenu, MenuAction action, int client, int run )
{
	if ( action == MenuAction_End ) { delete mMenu; return 0; }
	if ( action != MenuAction_Select ) return 0;
	
	
	if ( run < 0 || run >= NUM_RUNS ) return 0;
	
	
	Menu mMenu_ = new Menu( Handler_RunRecordsDelete_Type );
	mMenu_.SetTitle( "Remove Records (%s)\n ", g_szRunName[NAME_LONG][run] );
	
	
	char szItem[12];
	FormatEx( szItem, sizeof( szItem ), "%i", run );
	
	AddMenuItem( mMenu_, szItem, "Remove specific record (sub-menu)" );
	AddMenuItem( mMenu_, szItem, "Remove all records" );
	
	mMenu_.Display( client, MENU_TIME_FOREVER );
	
	return 0;
}

public int Handler_RunRecordsDelete_Type( Menu mMenu, MenuAction action, int client, int type )
{
	if ( action == MenuAction_End ) { delete mMenu; return 0; }
	if ( action != MenuAction_Select ) return 0;
	
	
	char szRun[4];
	if ( !GetMenuItem( mMenu, type, szRun, sizeof( szRun ) ) ) return 0;
	
	
	int run = StringToInt( szRun );
	
	if ( type == 0 )
	{
		DB_Admin_Records_DeleteMenu( client, run );
		return 0;
	}
	
	Menu mMenu_ = new Menu( Handler_RunRecordsDelete_Confirmation );
	mMenu_.SetTitle( "Are you sure?\n " );
	
	
	char szItem[64];
	FormatEx( szItem, sizeof( szItem ), "%i_%i", run, type );
	
	mMenu_.AddItem( szItem, "Yes" );
	mMenu_.AddItem( "", "No" );
	
	mMenu_.ExitButton = false;
	mMenu_.Display( client, MENU_TIME_FOREVER );
	
	return 0;
}

public int Handler_RunRecordsDelete_Confirmation( Menu mMenu, MenuAction action, int client, int index )
{
	if ( action == MenuAction_End ) { delete mMenu; return 0; }
	if ( action != MenuAction_Select ) return 0;
	
	
	if ( index != 0 ) return 0;
	
	char szItem[12];
	if ( !GetMenuItem( mMenu, index, szItem, sizeof( szItem ) ) ) return 0;
	
	
	char szInfo[2][6];
	if ( !ExplodeString( szItem, "_", szInfo, sizeof( szInfo ), sizeof( szInfo[] ) ) )
		return 0;
	
	int run = StringToInt( szInfo[0] );
	int type = StringToInt( szInfo[1] );
	
	switch ( type )
	{
		case 1 : // Remove run records
		{
			DB_EraseRunRecords( run );
		}
	}
	
	return 0;
}

public int Handler_RecordDelete( Menu mMenu, MenuAction action, int client, int index )
{
	if ( action == MenuAction_End ) { delete mMenu; return 0; }
	if ( action != MenuAction_Select ) return 0;
	
	
	char szId[70];
	if ( !GetMenuItem( mMenu, index, szId, sizeof( szId ) ) ) return 0;
	
	
	Menu mMenu_ = new Menu( Handler_RecordDelete_Confirmation );
	mMenu_.SetTitle( "Are you sure you want to remove this record?\n " );
	
	mMenu_.AddItem( szId, "Yes" );
	mMenu_.AddItem( "", "No" );
	
	mMenu_.ExitButton = false;
	mMenu_.Display( client, MENU_TIME_FOREVER );
	
	return 0;
}

public int Handler_RecordDelete_Confirmation( Menu mMenu, MenuAction action, int client, int index )
{
	if ( action == MenuAction_End ) { delete mMenu; return 0; }
	if ( action != MenuAction_Select ) return 0;
	
	
	if ( index != 0 ) return 0;
	
	char szId[32];
	if ( !GetMenuItem( mMenu, index, szId, sizeof( szId ) ) ) return 0;
	
	// 0 = type (0 = record, 1 = cp record)
	// 1 = run
	// 2 = style
	// 3 = mode
	// 4 = id (cp id or uid)
	// 5 = is best?
	char szInfo[7][80];
	if ( !ExplodeString( szId, "_", szInfo, sizeof( szInfo ), sizeof( szInfo[] ) ) )
		return 0;
	
	
	int run = StringToInt( szInfo[1] );
	int style = StringToInt( szInfo[2] );
	int mode = StringToInt( szInfo[3] );
	int id = StringToInt( szInfo[4] );
	char map[50];
	FormatEx(map, sizeof(map), szInfo[6]);
	
	if ( StringToInt( szInfo[0] ) == 0 )
	{
		// A record.
		DB_DeleteRecord( client, run, mode, id, map );
		
		if ( StringToInt( szInfo[5] ) )
		{
			// Also reset time in game.
				
			// If that client is in the server right now, reset their PB too.
			for ( int i = 1; i < MaxClients; i++ )
			{
				if ( g_iClientId[i] == id )
				{
					g_flClientBestTime[i][run][mode] = TIME_INVALID;

					if (run == RUN_MAIN)
					{
						bool have_cp_records;
						for (int j = 0; j < g_hCPs.Length; j++)
						{
							SetPrCpTime( j, mode, TIME_INVALID, i );
						}
					}
					break;
				}
			}
		}
	}
	
	return 0;
}