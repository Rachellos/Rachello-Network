public Action Command_ToggleHUD( int client, int args )
{
	if ( client <= 0 ) return Plugin_Handled;
    
    Panel pPanel = new Panel();
	
	pPanel.SetTitle( "<Settings Menu>\n " );

	pPanel.DrawItem( "General" );
	pPanel.DrawItem( "Right HUD" );
	pPanel.DrawItem( "Central HUD" );
	pPanel.DrawItem( "Chat" );

	pPanel.DrawItem( "", ITEMDRAW_SPACER );
	pPanel.DrawItem( "", ITEMDRAW_SPACER );

	pPanel.CurrentKey = 10;
	pPanel.DrawItem("[X]");

	pPanel.Send( client, Handler_Hud, MENU_TIME_FOREVER );
	delete pPanel;
	return Plugin_Handled;
}

public void ShowHideMenuGen(int client)
{

	Menu mMenu = new Menu( Handler_HudGen );
	
	mMenu.SetTitle( "<Settings Menu> :: General\n " );

	mMenu.AddItem( "pr", ( g_fClientHideFlags[client] & HIDEHUD_PRTIME ) 		? "Time Comparison: [Personal Record]" : "Time Comparison: [World Record]" );
	mMenu.AddItem( "vm", ( g_fClientHideFlags[client] & HIDEHUD_VM )				? "Show Weapon: [OFF]" : "Show Weapon: [ON]" );
	
	mMenu.ExitBackButton = true;
	mMenu.Display( client, MENU_TIME_FOREVER );

}

public void ShowHideMenuRHud(int client)
{
	Menu mMenu = new Menu( Handler_HudRHud );
	
	mMenu.SetTitle( "<Settings Menu> :: Right Hud\n " );
	//mMenu.AddItem( "time", ( g_fClientHideFlags[client] & HIDEHUD_TIMER )			? "Central Hud: OFF" : "Central Hud: ON" );
	mMenu.AddItem( "info", ( g_fClientHideFlags[client] & HIDEHUD_SIDEINFO ) 		? "Right Hud: [OFF]" : "Right Hud: [ON]" );
	mMenu.AddItem( "time", ( g_fClientHideFlags[client] & HIDEHUD_TIMEREMAINING ) 		? "Time Remaining: [OFF]" : "Time Remaining: [ON]" );
	mMenu.AddItem( "clas", ( g_fClientHideFlags[client] & HIDEHUD_CLASS ) 		? "Class Name: [OFF]" : "Class Name: [ON]" );
	mMenu.AddItem( "pr", ( g_fClientHideFlags[client] & HIDEHUD_PERSONALREC ) 		? "Personal Record: [OFF]" : "Personal Record: [ON]" );
	mMenu.AddItem( "wr", ( g_fClientHideFlags[client] & HIDEHUD_WORLDREC ) 		? "World Record: [OFF]" : "World Record: [ON]" );
	mMenu.AddItem( "tmps", ( g_fClientHideFlags[client] & HIDEHUD_TEMPUSWR ) 		? "World Record From Tempus: [OFF]" : "World Record From Tempus: [ON]" );
	mMenu.AddItem( "spec", ( g_fClientHideFlags[client] & HIDEHUD_SPECTYPE ) 		? "Spectators: [List]" : "Spectators: [Count]" );
	
	//mMenu.AddItem( "tmpspr", ( g_fClientHideFlags[client] & HIDEHUD_TEMPUSPR ) 		? "Personal Record From Tempus: [OFF]" : "Personal Record From Tempus: [ON]" );
	
	mMenu.ExitBackButton = true;
	mMenu.Display( client, MENU_TIME_FOREVER );

}

public void ShowHideMenuCHud(int client)
{
	Menu mMenu = new Menu( Handler_HudCHud );
	
	mMenu.SetTitle( "<Settings Menu> :: Central Hud\n " );

	mMenu.AddItem( "hud", ( g_fClientHideFlags[client] & HIDEHUD_TIMER )			? "Central Hud: [OFF]" : "Central Hud: [ON]" );
	mMenu.AddItem( "time", ( g_fClientHideFlags[client] & HIDEHUD_TIMER )			? "Central Hud: [OFF]" : "Central Hud: [ON]" );
	mMenu.AddItem( "speed", ( g_fClientHideFlags[client] & HIDEHUD_SPEED )		? "Speedometer: [ON]" : "Speedometer: [OFF]" );
	
	mMenu.ExitBackButton = true;
	mMenu.Display( client, MENU_TIME_FOREVER );

}

public void ShowHideMenuChat(int client)
{
	Menu mMenu = new Menu( Handler_HudChat );

	mMenu.SetTitle( "<Settings Menu> :: Chat\n " );

	char chat_rank[60];
	if (g_fClientHideFlags[client] & HIDEHUD_CHATRANKSOLLY)
	{
		FormatEx(chat_rank, sizeof(chat_rank), "Your rank in chat: [Soldier]");
	}
	else if (g_fClientHideFlags[client] & HIDEHUD_CHATRANKDEMO)
	{
		FormatEx(chat_rank, sizeof(chat_rank), "Your rank in chat: [Demoman]");
	}
	else
	{
		g_fClientHideFlags[client] |= HIDEHUD_CHATRANKAUTO;
		FormatEx(chat_rank, sizeof(chat_rank), "Your rank in chat: [Automatically]");
	}
	mMenu.AddItem( "chat", ( g_fClientHideFlags[client] & HIDEHUD_CHAT ) 			? "Show Messages by players: [OFF]" : "Show Messages by players: [ON]" );
	mMenu.AddItem( "rank", chat_rank );
	mMenu.AddItem( "zmsg", ( g_fClientHideFlags[client] & HIDEHUD_ZONEMSG )		? "Completion Messages: [OFF]" : "Completion Massages: [ON]" );
	mMenu.AddItem( "ad", ( g_fClientHideFlags[client] & HIDEHUD_CHAT_AD )		? "Ad in the chat: [OFF]" : "Ad in the chat: [ON]" );
	
	mMenu.ExitBackButton = true;
	mMenu.Display( client, MENU_TIME_FOREVER );

}

public int Handler_Hud( Menu mMenu, MenuAction action, int client, int item )
{
	char szQuery[192];
	char szSteam[100];

	if ( action == MenuAction_End)
	{
		PrintToChat(client, CHAT_PREFIX..."Saving settings...");
		GetClientSteam(client, szSteam, sizeof(szSteam)	);
		FormatEx( szQuery, sizeof( szQuery ), "UPDATE "...TABLE_PLYDATA..." SET hideflags = %i WHERE steamid = '%s'",
		g_fClientHideFlags[client],
		szSteam);
		g_hDatabase.Query( Threaded_Empty, szQuery );
		PrintToChat(client, CHAT_PREFIX..."Settings have been saved");
		delete mMenu;
		return 0;
	}
	if ( action == MenuAction_Cancel )
	{
		PrintToChat(client, CHAT_PREFIX..."Saving settings...");
		GetClientSteam(client, szSteam, sizeof(szSteam)	);
		FormatEx( szQuery, sizeof( szQuery ), "UPDATE "...TABLE_PLYDATA..." SET hideflags = %i WHERE steamid = '%s'",
		g_fClientHideFlags[client],
		szSteam);
		g_hDatabase.Query( Threaded_Empty, szQuery );
		PrintToChat(client, CHAT_PREFIX..."Settings have been saved");
	}
	if ( action != MenuAction_Select ) return 0;

	if ( action == MenuAction_Select )
	{
		if ( item == 1 )
		{
			ShowHideMenuGen(client);
		}
		else if ( item == 2 )
		{
			ShowHideMenuRHud(client);
		}
		else if ( item == 3 )
		{
			ShowHideMenuCHud(client);
		}
		else if ( item == 4 )
		{
			ShowHideMenuChat(client);
		}
		else if ( item == 10 )
		{
			PrintToChat(client, CHAT_PREFIX..."Saving settings...");
			GetClientSteam(client, szSteam, sizeof(szSteam)	);
			FormatEx( szQuery, sizeof( szQuery ), "UPDATE "...TABLE_PLYDATA..." SET hideflags = %i WHERE steamid = '%s'",
			g_fClientHideFlags[client],
			szSteam);
			g_hDatabase.Query( Threaded_Empty, szQuery );
			PrintToChat(client, CHAT_PREFIX..."Settings have been saved");
		}
	}
	return 0;
}

public int Handler_HudRHud( Menu mMenu, MenuAction action, int client, int item )
{
	
	if ( action == MenuAction_End)
	{
		char szQuery[192];
		char szSteam[100];
		PrintToChat(client, CHAT_PREFIX..."Saving settings...");
		GetClientSteam(client, szSteam, sizeof(szSteam)	);
		FormatEx( szQuery, sizeof( szQuery ), "UPDATE "...TABLE_PLYDATA..." SET hideflags = %i WHERE steamid = '%s'",
		g_fClientHideFlags[client],
		szSteam);
		g_hDatabase.Query( Threaded_Empty, szQuery, client, DBPrio_High );
		PrintToChat(client, CHAT_PREFIX..."Settings have been saved");
		delete mMenu;
		return 0;
	}
	if ( action == MenuAction_Cancel )
	{
		if (item == MenuCancel_ExitBack)
		{
			ClientCommand(client, "sm_settings");
			return 0;
		}
		
		char szQuery[192];
		char szSteam[100];
		PrintToChat(client, CHAT_PREFIX..."Saving settings...");
		GetClientSteam(client, szSteam, sizeof(szSteam)	);
		FormatEx( szQuery, sizeof( szQuery ), "UPDATE "...TABLE_PLYDATA..." SET hideflags = %i WHERE steamid = '%s'",
		g_fClientHideFlags[client],
		szSteam);
		g_hDatabase.Query( Threaded_Empty, szQuery, client, DBPrio_High );
		PrintToChat(client, CHAT_PREFIX..."Settings have been saved");
		return 0;
	}

	if (action == MenuAction_Select)
	{
		char szItem[10];
		GetMenuItem( mMenu, item, szItem, sizeof( szItem ) );
		
		if ( StrEqual( szItem, "info" ) )
		{
			if ( g_fClientHideFlags[client] & HIDEHUD_SIDEINFO )
			{
				g_fClientHideFlags[client] &= ~HIDEHUD_SIDEINFO;
			}
			else
			{
				g_fClientHideFlags[client] |= HIDEHUD_SIDEINFO;
			}
		}
		else if ( StrEqual( szItem, "time" ) )
		{
			if ( g_fClientHideFlags[client] & HIDEHUD_SPECTYPE )
			{
				g_fClientHideFlags[client] &= ~HIDEHUD_SPECTYPE;
			}
			else
			{
				g_fClientHideFlags[client] |= HIDEHUD_SPECTYPE;
			}
		}
		else if ( StrEqual( szItem, "spec" ) )
		{
			if ( g_fClientHideFlags[client] & HIDEHUD_SPECTYPE )
			{
				g_fClientHideFlags[client] &= ~HIDEHUD_SPECTYPE;
			}
			else
			{
				g_fClientHideFlags[client] |= HIDEHUD_SPECTYPE;
			}
		}
		else if ( StrEqual( szItem, "tmps" ) )
		{
			if ( g_fClientHideFlags[client] & HIDEHUD_TEMPUSWR )
			{
				g_fClientHideFlags[client] &= ~HIDEHUD_TEMPUSWR;
			}
			else
			{
				g_fClientHideFlags[client] |= HIDEHUD_TEMPUSWR;
			}
		}
		else if ( StrEqual( szItem, "tmpspr" ) )
		{
			if ( g_fClientHideFlags[client] & HIDEHUD_TEMPUSPR )
			{
				g_fClientHideFlags[client] &= ~HIDEHUD_TEMPUSPR;
			}
			else
			{
				g_fClientHideFlags[client] |= HIDEHUD_TEMPUSPR;
			}
		}
		ShowHideMenuRHud(client);
	}
	return 0;
}

public int Handler_HudCHud( Menu mMenu, MenuAction action, int client, int item )
{
	if ( action == MenuAction_End)
	{
	 	
		char szQuery[192];
		char szSteam[100];
		CPrintToChat(client, CHAT_PREFIX..."Saving settings...");
		GetClientSteam(client, szSteam, sizeof(szSteam)	);
		FormatEx( szQuery, sizeof( szQuery ), "UPDATE "...TABLE_PLYDATA..." SET hideflags = %i WHERE steamid = '%s'",
		g_fClientHideFlags[client],
		szSteam);
		g_hDatabase.Query( Threaded_Empty, szQuery, client, DBPrio_High );
		CPrintToChat(client, CHAT_PREFIX..."Settings have been saved");
		delete mMenu;
		return 0;
	}
	if ( action == MenuAction_Cancel )
	{
		if (item == MenuCancel_ExitBack)
		{
			ClientCommand(client, "sm_settings");
			return 0;
		}
		
		char szQuery[192];
		char szSteam[100];
		CPrintToChat(client, CHAT_PREFIX..."Saving settings...");
		GetClientSteam(client, szSteam, sizeof(szSteam)	);
		FormatEx( szQuery, sizeof( szQuery ), "UPDATE "...TABLE_PLYDATA..." SET hideflags = %i WHERE steamid = '%s'",
		g_fClientHideFlags[client],
		szSteam);
		g_hDatabase.Query( Threaded_Empty, szQuery, client, DBPrio_High );
		CPrintToChat(client, CHAT_PREFIX..."Settings have been saved");
		return 0;
	}
	if (action != MenuAction_Select) return 0;

	if (action == MenuAction_Select)
	{
		char szItem[6];
		GetMenuItem( mMenu, item, szItem, sizeof( szItem ) );
		
		if ( StrEqual( szItem, "hud" ) )
		{
			if ( g_fClientHideFlags[client] & HIDEHUD_TIMER )
			{
				g_fClientHideFlags[client] &= ~HIDEHUD_TIMER;
			}
			else
			{
				g_fClientHideFlags[client] |= HIDEHUD_TIMER;
			}
		}
		else if ( StrEqual( szItem, "speed" ) )
		{
			if ( g_fClientHideFlags[client] & HIDEHUD_SPEED )
			{
				g_fClientHideFlags[client] &= ~HIDEHUD_SPEED;
			}
			else
			{
				g_fClientHideFlags[client] |= HIDEHUD_SPEED;
			}
		}
		ShowHideMenuCHud(client);
	}
	return 0;
}
public int Handler_HudGen( Menu mMenu, MenuAction action, int client, int item )
{
	if ( action == MenuAction_End && action != MenuAction_Select)
	{
	 	
		char szQuery[192];
		char szSteam[100];
		CPrintToChat(client, CHAT_PREFIX..."Saving settings...");
		GetClientSteam(client, szSteam, sizeof(szSteam)	);
		FormatEx( szQuery, sizeof( szQuery ), "UPDATE "...TABLE_PLYDATA..." SET hideflags = %i WHERE steamid = '%s'",
		g_fClientHideFlags[client],
		szSteam);
		g_hDatabase.Query( Threaded_Empty, szQuery );
		CPrintToChat(client, CHAT_PREFIX..."Settings have been saved");
		delete mMenu;
		return 0;
	}
	if ( action == MenuAction_Cancel )
	{
		if (item == MenuCancel_ExitBack)
		{
			ClientCommand(client, "sm_settings");
			return 0;
		}
		
		char szQuery[192];
		char szSteam[100];
		CPrintToChat(client, CHAT_PREFIX..."Saving settings...");
		GetClientSteam(client, szSteam, sizeof(szSteam)	);
		FormatEx( szQuery, sizeof( szQuery ), "UPDATE "...TABLE_PLYDATA..." SET hideflags = %i WHERE steamid = '%s'",
		g_fClientHideFlags[client],
		szSteam);
		g_hDatabase.Query( Threaded_Empty, szQuery );
		CPrintToChat(client, CHAT_PREFIX..."Settings have been saved");
		return 0;
	}

	char szItem[6];
	GetMenuItem( mMenu, item, szItem, sizeof( szItem ) );
	
	if ( StrEqual( szItem, "vm" ) )
	{
		if ( g_fClientHideFlags[client] & HIDEHUD_VM )
		{
			g_fClientHideFlags[client] &= ~HIDEHUD_VM;
			
			SetEntProp( client, Prop_Send, "m_bDrawViewmodel", 1 );
			
		}
		else
		{
			g_fClientHideFlags[client] |= HIDEHUD_VM;
			
			SetEntProp( client, Prop_Send, "m_bDrawViewmodel", 0 );
			
		}
	}
	else if ( StrEqual( szItem, "pr" ) )
	{
		if ( g_fClientHideFlags[client] & HIDEHUD_PRTIME )
		{
			g_fClientHideFlags[client] &= ~HIDEHUD_PRTIME;
		}
		else
		{
			g_fClientHideFlags[client] |= HIDEHUD_PRTIME;
			
		}
	}
	
	ShowHideMenuGen(client);

}

public int Handler_HudChat( Menu mMenu, MenuAction action, int client, int item )
{
	if ( action == MenuAction_End)
	{
		char szQuery[192];
		char szSteam[100];
		PrintToChat(client, CHAT_PREFIX..."Saving settings...");
		GetClientSteam(client, szSteam, sizeof(szSteam)	);
		FormatEx( szQuery, sizeof( szQuery ), "UPDATE "...TABLE_PLYDATA..." SET hideflags = %i WHERE steamid = '%s'",
		g_fClientHideFlags[client],
		szSteam);
		g_hDatabase.Query( Threaded_Empty, szQuery);
		PrintToChat(client, CHAT_PREFIX..."Settings have been saved");
		delete mMenu;
		return 0;
	}
	if ( action == MenuAction_Cancel )
	{
		if (item == MenuCancel_ExitBack)
		{
			ClientCommand(client, "sm_settings");
			return 0;
		}
		
		char szQuery[192];
		char szSteam[100];
		PrintToChat(client, CHAT_PREFIX..."Saving settings...");
		GetClientSteam(client, szSteam, sizeof(szSteam)	);
		FormatEx( szQuery, sizeof( szQuery ), "UPDATE "...TABLE_PLYDATA..." SET hideflags = %i WHERE steamid = '%s'",
		g_fClientHideFlags[client],
		szSteam);
		g_hDatabase.Query( Threaded_Empty, szQuery );
		PrintToChat(client, CHAT_PREFIX..."Settings have been saved");
		return 0;
	}

	if (action == MenuAction_Select)
	{
		char szItem[6];
		GetMenuItem( mMenu, item, szItem, sizeof( szItem ) );
		
		if ( StrEqual( szItem, "rank" ) )
		{
			if ( g_fClientHideFlags[client] & HIDEHUD_CHATRANKAUTO )
			{
				g_fClientHideFlags[client] |= HIDEHUD_CHATRANKSOLLY;
				g_fClientHideFlags[client] &= ~ HIDEHUD_CHATRANKAUTO;
				g_fClientHideFlags[client] &= ~ HIDEHUD_CHATRANKDEMO;
			}
			else if ( g_fClientHideFlags[client] & HIDEHUD_CHATRANKSOLLY )
			{
				g_fClientHideFlags[client] &= ~HIDEHUD_CHATRANKAUTO;
				
				g_fClientHideFlags[client] &= ~HIDEHUD_CHATRANKSOLLY;
				
				g_fClientHideFlags[client] |= HIDEHUD_CHATRANKDEMO;
			}
			else if ( g_fClientHideFlags[client] & HIDEHUD_CHATRANKDEMO )
			{
				g_fClientHideFlags[client] |= HIDEHUD_CHATRANKAUTO;
				
				g_fClientHideFlags[client] &= ~HIDEHUD_CHATRANKSOLLY;
				
				g_fClientHideFlags[client] &= ~HIDEHUD_CHATRANKDEMO;
			}
		}
		else if ( StrEqual( szItem, "chat" ) )
		{
			if ( g_fClientHideFlags[client] & HIDEHUD_CHAT )
			{
				g_fClientHideFlags[client] &= ~HIDEHUD_CHAT;
				
			}
			else
			{
				g_fClientHideFlags[client] |= HIDEHUD_CHAT;
				
			}
		}
		else if ( StrEqual( szItem, "zmsg" ) )
		{
			if ( g_fClientHideFlags[client] & HIDEHUD_ZONEMSG )
			{
				g_fClientHideFlags[client] &= ~HIDEHUD_ZONEMSG;
				
			}
			else
			{
				g_fClientHideFlags[client] |= HIDEHUD_ZONEMSG;
			}
		}
		else if ( StrEqual( szItem, "ad" ) )
		{
			if ( g_fClientHideFlags[client] & HIDEHUD_CHAT_AD )
			{
				g_fClientHideFlags[client] &= ~HIDEHUD_CHAT_AD;
				
			}
			else
			{
				g_fClientHideFlags[client] |= HIDEHUD_CHAT_AD;
			}
		}
		
		ShowHideMenuChat(client);
	}
	return 0;
}

public Action Command_Credits( int client, int args )
{
	if ( !client ) return Plugin_Handled;
	
	
	Panel pPanel = new Panel();
	
	pPanel.SetTitle( "Credits:" );
	
	pPanel.DrawItem( "", ITEMDRAW_SPACER );
	pPanel.DrawText( "Rachello - Original author" );
	pPanel.DrawItem( "", ITEMDRAW_SPACER );
	
	pPanel.DrawText( "Thanks to p4tt - For help at the beginning of plugin development." );
	pPanel.DrawItem( "", ITEMDRAW_SPACER );
	
	pPanel.DrawItem( "Exit", ITEMDRAW_CONTROL );
	
	pPanel.Send( client, Handler_Empty, MENU_TIME_FOREVER );
	
	delete pPanel;
	
	return Plugin_Handled;
}

// Used for multiple menus/panels.
public int Handler_Empty( Menu mMenu, MenuAction action, int client, int item )
{
	if ( action == MenuAction_End ) delete mMenu;	
	
	return 0;
}
public int Handler_Completions( Menu mMenu, MenuAction action, int client, int item )
{
	if ( action == MenuAction_End ) { delete mMenu; return 0; }
	if (action == MenuAction_Cancel)
	{
    if (item == MenuCancel_ExitBack)
	{
		int args;
	   	DB_Profile( client, args, 1, DBS_Name[client], 0 ); 
		return 0;
    }
	}
	if ( action != MenuAction_Select ) return 0;
	if ( action == MenuAction_Select )
	{
		char szItem[5];
		int rec;
		GetMenuItem( mMenu, item, szItem, sizeof( szItem ) );
		if ( item == 6 )
		{
			DB_Completions(client, (db_style[client] == STYLE_SOLLY) ? STYLE_DEMOMAN : STYLE_SOLLY);
			return 0;
		}
		StringToIntEx(szItem, rec);
		DB_RecordInfo(client, rec);
	}
	
	return 0;
}