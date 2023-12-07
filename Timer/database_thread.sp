// Query handles are closed automatically.
public void Threaded_PrintRecordsPoints( Database hOwner, DBResultSet hQuery, const char[] szError, ArrayList hData )
{
	int client;
	if ( (client = GetClientOfUserId( hData.Get( 0, 0 ) )) )
	{
		if ( hQuery == null )
		{
			DB_LogError( "An error occured when trying to print points to client." );
			
			delete hData;
			return;
		}
		
		Menu mMenu;
		static char	szName[MAX_NAME_LENGTH];
		int item;
		int num;
		char szId[32];
		char szUid[32];
		int top = hData.Get( 0, 1 );
		mMenu = new Menu( Handler_Points );
		int iRows = hQuery.RowCount;
		if ( iRows )
		{
			int			overall;
			
			char szItem[64];
			int uid;
			
			while ( hQuery.FetchRow() )
			{
				hQuery.FetchString( 1, szName, sizeof( szName ) );
				overall = hQuery.FetchInt( 2 );
				uid = hQuery.FetchInt( 0 );
				IntToString( uid, szUid, sizeof( szUid ) );
				FormatEx( szItem, sizeof( szItem ), "[#%i] %s :: %i [pts] ",num + 1, szName, overall );
				mMenu.AddItem( szUid, szItem );
				num++;
				if (top == 0)
				{
				mMenu.SetTitle( "<Top Players by overall points Menu>\n " );
				}
				if (top == 1)
				{
				mMenu.SetTitle( "<Top Players by demoman points Menu>\n " );
				}
				if (top == 2)
				{
				mMenu.SetTitle( "<Top Players by soldier Points Menu>\n " );
				}

			}
		}

		mMenu.ExitBackButton = (GetLastPrevMenuIndex(client) != -1) ? true : false;
		SetNewPrevMenu(client,mMenu);
		mMenu.Display( client, MENU_TIME_FOREVER );
	}
	delete hQuery;
	delete hData;
}

public int Handler_Points( Menu mMenu, MenuAction action, int client, int index )
{
	if ( action == MenuAction_End ) {  return 0; }

	if (action == MenuAction_Cancel) 
	{
		if(index == MenuCancel_ExitBack) 
		{
			RemoveLastPrevMenu(client);
			CallPrevMenu(client);
		    return 0;
		}
	}
	if ( action != MenuAction_Select ) return 0;
	char szId[32];
	char szQuery[192];
	if (action == MenuAction_Select)
	{
		GetMenuItem( mMenu, index, szId, sizeof( szId ) );
		int args;
		int id;
		StringToIntEx(szId, id);
		DB_Profile( client, args, 0, "name", id );
	}
	return 0;
}

public void Threaded_printsteam( Database hOwner, DBResultSet hQuery, const char[] szError, int client )
{
	if ( !(client = GetClientOfUserId( client )) ) return;
	
	if ( hQuery == null )
	{
		DB_LogError( "Couldn't retrieve player data!" );
		
		return;
	}

	if ( hQuery.RowCount )
	{
		hQuery.FetchRow();
		char steam[120];
		hQuery.FetchString( 0, steam, sizeof( steam ) );
		
		CPrintToChat(client, CHAT_PREFIX..."{lightskyblue}http://steamcommunity.com/profiles/%s", steam);
		DB_Profile( client, 0, 0, DBS_Name[client], db_id[client] );
	}
	delete hQuery;
}	

public void Threaded_AdminManagement( Database hOwner, DBResultSet hQuery, const char[] szError, int client )
{
	if ( !(client = GetClientOfUserId( client )) ) return;
	
	if ( hQuery == null )
	{
		DB_LogError( "Couldn't retrieve player data!" );
		
		return;
	}

	if ( hQuery.RowCount )
	{
		hQuery.FetchRow();
		char szQuery[192], name[32];

		int isadmin = hQuery.FetchInt( 0 );
		hQuery.FetchString(1, name, sizeof(name));
		
		FormatEx( szQuery, sizeof( szQuery ), "UPDATE plydata SET isadmin = %i WHERE uid = %i",
		isadmin ? 0 : 1,
		db_id[client] );

		g_hDatabase.Query( Threaded_Empty, szQuery );
		
		CPrintToChat(client, CHAT_PREFIX..."Player {lightskyblue}%s {white}%s.", name, isadmin ? "not an Admin anymore!" : "became an Admin!");

		for (int i = 1; i <= MaxClients; i++)
		{
			if (g_iClientId[i] == db_id[client])
			{
				if (!isadmin)
				{
					CPrintToChat(i, CHAT_PREFIX..."You have become an {lightskyblue}Admin!");
					SetUserFlagBits(i, ADMFLAG_ROOT);
				}
				else
				{
					CPrintToChat(i, CHAT_PREFIX..."You are no longer an {red}Admin!");
					SetUserFlagBits(i, 0);
				}
				break;
			}
		}

		FormatEx( szQuery, sizeof( szQuery ), "SELECT country, lastseen, firstseen, uid, name, CURRENT_TIMESTAMP, total_hours, isadmin FROM "...TABLE_PLYDATA..." WHERE uid = %i", db_id[client] );
		g_hDatabase.Query( Threaded_ProfileInfo, szQuery, GetClientUserId( client ), DBPrio_Normal );
	}
	delete hQuery;
}	

public void Threaded_ProfileInfo( Database hOwner, DBResultSet hQuery, const char[] szError, int client )
{
	if ( !(client = GetClientOfUserId( client )) ) return;
	
	if ( hQuery == null )
	{
		DB_LogError( "Couldn't retrieve player data!" );
		
		return;
	}

	Menu mMenu;
	mMenu = new Menu( Handler_ProfileInfo );
	char link[120];
	char country[99];
	int id;
	int isAdmin;
	char last[100];
	char first[100];
	char item[192];
	char name[40];
	char cur_date[100];
	float total_hours;

	if ( hQuery.RowCount )
	{
		hQuery.FetchRow();
		hQuery.FetchString( 0, country, sizeof( country ) );
		hQuery.FetchString( 1, last, sizeof( last ) );
		hQuery.FetchString( 2, first, sizeof( first ) );
		id = hQuery.FetchInt( 3 );
		hQuery.FetchString( 4, name, sizeof( name ) );
		hQuery.FetchString( 5, cur_date, sizeof( cur_date ) );
		total_hours = hQuery.FetchFloat( 6 ) / 60 / 60;

		isAdmin = hQuery.FetchInt( 7 );

		char time_ago_last[40], time_ago_first[40]; 
		FormatTimeDuration(time_ago_last, sizeof(time_ago_last), DateTimeToTimestamp(cur_date) - DateTimeToTimestamp(last));

		if (!hQuery.IsFieldNull(2))
			FormatTimeDuration(time_ago_first, sizeof(time_ago_first), DateTimeToTimestamp(cur_date) - DateTimeToTimestamp(first));

		FormatEx( item, sizeof( item ), "Details:\n Country: %s \n User id: %i \n Last seen: %s \n First seen: %s \n Total online hours: %.1f \n %s", country, id, time_ago_last, time_ago_first, total_hours, isAdmin ? "Thats Admin!\n " : "");
		mMenu.AddItem("", item );
		mMenu.AddItem("", "Get Steam Profile Link\n ");
		if (GetUserFlagBits(client) & ADMFLAG_ROOT)
		{
			mMenu.AddItem("", "Wipe player stats\n ");

			if (id != g_iClientId[client])
			{
				if (!isAdmin)
				{
					mMenu.AddItem("", "Make player an Admin\n ");
				}
				else
				{
					mMenu.AddItem("", "Revoke Admin\n ");
				}
			}
		}
		mMenu.ExitBackButton = true;
	}
	mMenu.SetTitle("<User Details>\nPlayer: %s\n ", name );
	mMenu.Display( client, MENU_TIME_FOREVER );
	RemoveLastPrevMenu(client);

	delete hQuery;
}	

public int Handler_ProfileInfo( Menu mMenu, MenuAction action, int client, int index )
{
	if ( action == MenuAction_End ) { delete mMenu; return 0; }
	if (action == MenuAction_Cancel)
	{
	    if (index == MenuCancel_ExitBack)
		{
		   	DB_Profile( client, 0, 0, DBS_Name[client], db_id[client]);
			return 0;
	    }
	}
	if ( action != MenuAction_Select ) return 0;
	if ( action == MenuAction_Select )
	{
		if ( index == 1 )
		{
			char szQuery[192];
			FormatEx( szQuery, sizeof( szQuery ), "SELECT link FROM "...TABLE_PLYDATA..." WHERE uid = %i", db_id[client] );
			g_hDatabase.Query( Threaded_printsteam, szQuery, GetClientUserId( client ), DBPrio_Normal );
		}
		
		if (GetUserFlagBits(client) & ADMFLAG_ROOT)
		{
			if ( index == 2 )
			{
				WipePlayer( client, db_id[client], DBS_Name[client] );
			}
			if (index == 3)
			{
				char szQuery[192];
				FormatEx( szQuery, sizeof( szQuery ), "SELECT isadmin, name FROM "...TABLE_PLYDATA..." WHERE uid = %i", db_id[client] );
				g_hDatabase.Query( Threaded_AdminManagement, szQuery, GetClientUserId( client ), DBPrio_Normal );
			}
		}
	}
}

public void Threaded_PrintRecords( Database hOwner, DBResultSet hQuery, const char[] szError, ArrayList hData )
{
	int client;
	if ( (client = GetClientOfUserId( hData.Get( 0, 0 ) )) )
	{
		if ( hQuery == null )
		{
			DB_LogError( "An error occured when trying to print times to client." );
			
			delete hData;
			return;
		}
		
		int run = hData.Get( 0, 1 );
		RunPagep[client] = run;
		int imode = hData.Get( 0, 2 );
		
		Menu mMenu;
		mMenu = new Menu( Handler_top );
		
		int num = 0;
		int count = 0;
		char szItem[64];
		
		if ( hQuery.RowCount )
		{
			int			style;
			int			mode;
			int record;
			static char	szName[MAX_NAME_LENGTH];
			char szRecord[32];
			static char	szFormTime[TIME_SIZE_DEF];
			char		szStyleFix[STYLEPOSTFIX_LENGTH];
			char map[MAX_NAME_LENGTH];
			char szInterval[TIME_SIZE_DEF];
			float Inteval;
			
			while ( hQuery.FetchRow() )
			{
				count++;
				style = hQuery.FetchInt( 2 );
				mode = hQuery.FetchInt( 3 );
				FormatSeconds( hQuery.FetchFloat(  4 ), szFormTime );
				
				hQuery.FetchString( 5, szName, sizeof( szName ) );
				record = hQuery.FetchInt( 0);
				
				hQuery.FetchString( 1, map, sizeof( map ) );
				hQuery.FetchString( 1, db_map[client], sizeof( db_map ) );

				Inteval = hQuery.FetchFloat( 4 ) - db_time[client] + 0.0001;
				FormatSeconds( Inteval, szInterval, FORMAT_3DECI );
				GetStylePostfix( mode, szStyleFix, true );
				// XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX - XX:XX:XX [XXXX XXXXXX]
				if (count != 6)
				{
					FormatEx( szItem, sizeof( szItem ), "[#%i] %s +%s :: %s", num + 1, szFormTime, szInterval, szName );
					IntToString( record, szRecord, sizeof( szRecord ) );
					mMenu.AddItem( szRecord, szItem );
				}

				if (count == 6)
				{
					
					FormatEx( szItem, sizeof( szItem ), "[#%i] %s +%s :: %s\n ", num + 1, szFormTime, szInterval, szName );
					IntToString( record, szRecord, sizeof( szRecord ) );
					mMenu.AddItem( szRecord, szItem );

					if (imode == MODE_SOLDIER)
					{
						RunClass[client] = MODE_SOLDIER;
						mMenu.AddItem("a", "[Soldier]", ITEMDRAW_CONTROL);
					}
					else
					{
						RunClass[client] = MODE_DEMOMAN;
						mMenu.AddItem("s", "[Demoman]", ITEMDRAW_CONTROL);
					}
					count = 0;
				}
				num++;
			}
			if (0 < count < 6)
			{
				for (int i = 1; i <= (6 - count); i++)
				{
					mMenu.AddItem("","", ITEMDRAW_SPACER);
				}
				

				if (imode == MODE_SOLDIER)
				{
					RunClass[client] = MODE_SOLDIER;
					mMenu.AddItem("a", "[Soldier]", ITEMDRAW_CONTROL);
				}
				else
				{
					RunClass[client] = MODE_DEMOMAN;
					mMenu.AddItem("s", "[Demoman]", ITEMDRAW_CONTROL);
				}	
			}

				if (imode == MODE_SOLDIER)
				{
					mMenu.SetTitle( "<Top Times Menu :: Soldier\n<%s/%s>\n ", map, g_szRunName[NAME_LONG][run] );
				}
				else
				{
					mMenu.SetTitle( "<Top Times Menu :: Demoman\n<%s/%s>\n ", map, g_szRunName[NAME_LONG][run] );
				}
		}
		else
		{	
			mMenu.AddItem( "", "No Records D:", ITEMDRAW_DISABLED );

			for (int i = 1; i < 6; i++)
				{
					mMenu.AddItem("","", ITEMDRAW_SPACER);
				}

			if (imode == MODE_SOLDIER)	
			{
				RunClass[client] = MODE_SOLDIER;
				mMenu.SetTitle( "<Top Times Menu :: Soldier\n<%s/%s>\n ", db_map[client], g_szRunName[NAME_LONG][run] );
				mMenu.AddItem("a", "[Soldier]");
			}
			else
			{
				RunClass[client] = MODE_DEMOMAN;
				mMenu.SetTitle( "<Top Times Menu :: Demoman\n<%s/%s>\n ", db_map[client], g_szRunName[NAME_LONG][run] );
				mMenu.AddItem("s", "[Demoman]");
			}
		}
		mMenu.ExitBackButton = true;
		SetNewPrevMenu(client, mMenu);
		mMenu.DisplayAt( client, menu_page[client], MENU_TIME_FOREVER );
		
	}
	delete hQuery;
	delete hData;
}

public int Handler_top( Menu mMenu, MenuAction action, int client, int item )
{
	if ( action == MenuAction_End ) { return 0; }
	if (action == MenuAction_Cancel)
	{
		if (item == MenuCancel_ExitBack)
		{
			ShowMapTop(client, db_map[client], last_usage_run_type[client]);
			return 0;
		}
	}
	if ( action != MenuAction_Select ) return 0;

	if ( action == MenuAction_Select )
	{
		char szItem[32];
		GetMenuItem( mMenu, item, szItem, sizeof( szItem ) );
		if ( StrEqual( szItem, "a" ) )
		{
			RemoveLastPrevMenu(client);
			DB_PrintRecords0( client, RunPagep[client], MODE_DEMOMAN );
			return;
		}
		if ( StrEqual( szItem, "s" ) )
		{
			RemoveLastPrevMenu(client);
			DB_PrintRecords0( client, RunPagep[client], MODE_SOLDIER );
			return;
		}

		menu_page[client] = GetMenuSelectionPosition();
		char szId[32];
		GetMenuItem( mMenu, item, szId, sizeof( szId ) );
		int id;
		StringToIntEx(szId, id);
		DB_RecordInfo(client, id);
	}
}

public void Threaded_Admin_Records_DeleteMenu( Database hOwner, DBResultSet hQuery, const char[] szError, ArrayList hData )
{
	int client;
	if ( (client = GetClientOfUserId( hData.Get( 0, 0 ) )) )
	{
		if ( hQuery == null )
		{
			DB_LogError( "An error occured when trying to print records to an admin." );
			
			delete hData;
			return;
		}
		
		
		int		run = hData.Get( 0, 1 );
		int		style;
		int		mode;
		int		id;
		char	szName[MAX_NAME_LENGTH];
		char	szFormTime[TIME_SIZE_DEF];
		char	szStyleFix[STYLEPOSTFIX_LENGTH];
		char	szItem[64];
		char	szId[32];
		char 	map[50];
		
		
		Menu mMenu = new Menu( Handler_RecordDelete );
		mMenu.SetTitle( "Record Deletion (%s)\n ", g_szRunName[NAME_LONG][run] );
		
		
		
		if ( hQuery.RowCount )
		{
			int laststyle = STYLE_INVALID;
			int lastmode = MODE_INVALID;
			
			while ( hQuery.FetchRow() )
			{
				style = hQuery.FetchInt( 0 );
				mode = hQuery.FetchInt( 1 );
				id = hQuery.FetchInt( 2 );
				FormatSeconds( hQuery.FetchFloat(  3 ), szFormTime );
				hQuery.FetchString( 4, szName, sizeof( szName ) );
				hQuery.FetchString( 5, map, sizeof( map ) );
				
				FormatEx( szId, sizeof( szId ), "%i_%i_%i_%s", run, mode, id, map ); // Used to identify records.
				
				GetStylePostfix( mode, szStyleFix, true );
				FormatEx( szItem, sizeof( szItem ), "%s - %s [%s%s]", szName, szFormTime, g_szStyleName[NAME_SHORT][style], szStyleFix );
				
				mMenu.AddItem( szId, szItem );
				
				laststyle = style;
				lastmode = mode;
			}
		}
		else
		{
			FormatEx( szItem, sizeof( szItem ), "No one has beaten %s yet... :(", g_szRunName[NAME_LONG][run] );
			mMenu.AddItem( "", szItem, ITEMDRAW_DISABLED );
		}
		
		mMenu.Display( client, MENU_TIME_FOREVER );

	}
	delete hQuery;
	delete hData;
}

public void Threaded_Admin_CPRecords_DeleteMenu( Database hOwner, DBResultSet hQuery, const char[] szError, ArrayList hData )
{
	int client;
	if ( (client = GetClientOfUserId( hData.Get( 0, 0 ) )) )
	{
		if ( hQuery == null )
		{
			DB_LogError( "An error occured when trying to print checkpoint records to an admin." );
			
			delete hData;
			return;
		}
		
		
		int	run = hData.Get( 0, 1 );
		int	style;
		int	mode;
		int			id;
		float		flTime;
		char		szFormTime[TIME_SIZE_DEF];
		char		szStyleFix[STYLEPOSTFIX_LENGTH];
		char		szItem[64];
		char		szId[32];
		
		
		Menu mMenu = new Menu( Handler_RecordDelete );
		mMenu.SetTitle( "Checkpoint Record Deletion (%s)\n ", g_szRunName[NAME_LONG][run] );
		
		if ( hQuery.RowCount )
		{
			while ( hQuery.FetchRow() )
			{
				flTime = hQuery.FetchFloat(  3 );
				
				if ( flTime <= TIME_INVALID ) continue;
				
				
				id = hQuery.FetchInt( 0 );
				style = hQuery.FetchInt( 1 );
				mode = hQuery.FetchInt( 2 );
				FormatSeconds( flTime, szFormTime );
				
				FormatEx( szId, sizeof( szId ), "1_%i_%i_%i_%i", run, style, mode, id ); // Used to identify records.
				
				GetStylePostfix( mode, szStyleFix, true );
				FormatEx( szItem, sizeof( szItem ), "#%i - %s [%s%s]", id + 1, szFormTime, g_szStyleName[NAME_SHORT][style], szStyleFix );
				
				mMenu.AddItem( szId, szItem );
			}
		}
		else
		{
			FormatEx( szItem, sizeof( szItem ), "No checkpoint records found!" );
			mMenu.AddItem( "", szItem, ITEMDRAW_DISABLED );
		}
		
		mMenu.Display( client, MENU_TIME_FOREVER );

	}
	delete hQuery;
	delete hData;
}

public void Threaded_RetrieveClientData( Database hOwner, DBResultSet hQuery, const char[] szError, int client )
{
	if ( !(client = GetClientOfUserId( client )) ) return;
	
	if ( hQuery == null )
	{
		DB_LogError( "Couldn't retrieve player data!" );
		
		return;
	}
	
	char szSteam[MAX_ID_LENGTH];
	
	if ( !GetClientSteam( client, szSteam, sizeof( szSteam ) ) ) return;
	char szName[32];
	char szQuery[500];

	GetClientName(client, szName, sizeof( szName ) );

	if ( !SQL_EscapeString( g_hDatabase, szName, szName, sizeof( szName ) ) )
		strcopy( szName, sizeof( szName ), "Player" );

	int num;
	if ( !(num = hQuery.RowCount) )
	{
		FormatEx( szQuery, sizeof( szQuery ), "INSERT INTO "...TABLE_PLYDATA..." (name, steamid) VALUES ('%s', '%s')", szName, szSteam );
		
		g_hDatabase.Query( Threaded_NewID, szQuery, GetClientUserId( client ), DBPrio_Normal );
		
		return;
	}
	
	
	if ( num > 1 )
	{
		// Should never happen.
		CPrintToChatAll( CHAT_PREFIX..."Found multiple records with the same Steam Id!!" );
	}
	
	if ( hQuery.RowCount )
	{
		hQuery.FetchRow();
		g_iClientId[client] = hQuery.FetchInt( 0 );
		
		
		g_fClientHideFlags[client] = hQuery.FetchInt( 1 );
		
		// If spectating.
		if ( g_fClientHideFlags[client] & HIDEHUD_VM )
			SetEntProp( client, Prop_Send, "m_bDrawViewmodel", 0 );
		
		g_iClientPoints[client] = hQuery.FetchFloat(  2 );
		g_iClientPointsSolly[client] = hQuery.FetchFloat(  3 );
		g_iClientPointsDemo[client] = hQuery.FetchFloat(  4 );
		ranksolly[client] = (g_iClientPointsSolly[client] > 0.0) ? hQuery.FetchInt( 5 ) : 0;
		rankdemo[client] = (g_iClientPointsDemo[client] > 0.0) ? hQuery.FetchInt( 6 ) : 0;
		int isAdmin = hQuery.FetchInt( 7 );

		if (isAdmin)
			SetUserFlagBits(client, ADMFLAG_ROOT);
	}
	
	// Then we get the times.
	if ( g_iClientId[client] )
	{
		FormatEx( szQuery, sizeof( szQuery ), "SELECT run, mode, time, recordid FROM "...TABLE_RECORDS..." WHERE map = '%s' AND uid = %i ORDER BY run", g_szCurrentMap, g_iClientId[client] );
		g_hDatabase.Query( Threaded_RetrieveClientTimes, szQuery, GetClientUserId( client ), DBPrio_Normal );
	}
	delete hQuery;
}

public void Threaded_Completions( Database hOwner, DBResultSet hQuery, const char[] szError, int client )
{
	if ( !(client = GetClientOfUserId( client )) ) return;
	
	if ( hQuery == null )
	{
		DB_LogError( "Couldn't retrieve player completions!" );
		
		return;
	}
	
	Menu mMenu = new Menu( Handler_Completions );
	char szId[64];
	char szItem[64];
	char map[64];
	char item[60];
	int record;
	int num;
	int style;
	int count = 0;	
	if ( hQuery.RowCount )
	{
		while ( hQuery.FetchRow() )
		{
			hQuery.FetchString( 0, map, sizeof( map ) );
			
			if (FindMap(map, map, sizeof(map)) == FindMap_NotFound) continue;

			count++;
			num++;
			record = hQuery.FetchInt(1);
			style = hQuery.FetchInt(2);

			IntToString(record, szId, sizeof(szId));
			if (count != 6)
			{
				FormatEx( szItem, sizeof( szItem ), "%s", map );
				mMenu.AddItem( szId, szItem );
			}
			else
			{
				FormatEx( szItem, sizeof( szItem ), "%s\n ", map );
				mMenu.AddItem( szId, szItem );

				mMenu.AddItem("c", (db_style[client] == 0) ? "[Soldier]" : "[Demoman]");
				
				count = 0;
			}
		}
		if (0 < count < 6)
		{
			for (int i = 1; i <= (6 - count); i++)
			{
				mMenu.AddItem("","", ITEMDRAW_SPACER);
			}
				
			mMenu.AddItem("c", (db_style[client] == 0) ? "[Soldier]" : "[Demoman]");
		}
	}
	else
	{
		mMenu.AddItem( "", "Not found competions :(\n \n \n \n \n ", ITEMDRAW_DISABLED );
		for (int i = 1; i < 6; i++)
		{
			mMenu.AddItem("","", ITEMDRAW_SPACER);
		}

		mMenu.AddItem("c", (db_style[client] == 0) ? "[Soldier]" : "[Demoman]");
	}

	mMenu.ExitBackButton = true;
	mMenu.SetTitle( "<Completions menu :: %s>\nPlayer: %s :: (%i total)\n ", g_szStyleName[NAME_LONG][style], DBS_Name[client], num );	
	SetNewPrevMenu(client, mMenu);
	mMenu.Display( client, MENU_TIME_FOREVER );

}		

public void Threaded_Overall( Database hOwner, DBResultSet hQuery, const char[] szError, int client )
{
	if ( !(client = GetClientOfUserId( client )) ) return;
	
	if ( hQuery == null )
	{
		DB_LogError( "Couldn't retrieve player data!" );
		
		return;
	}
	
	
	if ( hQuery.FetchRow() )
	{
		float pts = hQuery.FetchFloat(  0 );
		CPrintToChatAll(CHAT_PREFIX... "Sum of {green}all points {white}:: {lightskyblue}%.1f", pts);
	}
	
}

public void Threaded_RetrieveClientTimes( Database hOwner, DBResultSet hQuery, const char[] szError, int client )
{
	if ( !(client = GetClientOfUserId( client )) ) return;
	
	if ( hQuery == null )
	{
		DB_LogError( "Couldn't retrieve player records!" );
		
		return;
	}
	
	
	int run;
	int style;
	int mode;

	char query[255];
	
	if (hQuery.RowCount)
	{
		while ( hQuery.FetchRow() )
		{
			run = hQuery.FetchInt( 0 );
			
			mode = hQuery.FetchInt( 1 );
		
			g_flClientBestTime[client][run][mode] = hQuery.FetchFloat( 2 );

			if (run == RUN_MAIN)
				g_iClientMapPR_id[client][mode] = hQuery.FetchInt( 3 );
		}

		g_hDatabase.Format(query, sizeof(query), "SELECT id, run, style, mode, time FROM mapcprecs where ( recordid = %i OR recordid = %i ) and map = '%s'", 
			g_iClientMapPR_id[client][MODE_SOLDIER], 
			g_iClientMapPR_id[client][MODE_DEMOMAN], 
			g_szCurrentMap);

		g_hDatabase.Query( Threaded_Init_CP_PR_Times, query, client, DBPrio_High );
	}
}

public void Threaded_GetRank( Database hOwner, DBResultSet hQuery, const char[] szError, int client )
{
	if ( hQuery == null )
	{
		DB_LogError( "Couldn't retrieve player's Threaded_GetSolly!" );
		
		return;
	}
	char name[32], IP[99], Country[99];
	GetClientName(client, name, sizeof(name));
	GetClientIP(client, IP, sizeof(IP), true);
	if(!GeoipCountry(IP, Country, sizeof(Country)))
	{
		Country = "None";
	}

	if ( hQuery.FetchRow() )
	{
		float solly = hQuery.FetchFloat( 0 );
		float demo = hQuery.FetchFloat( 1 );
		int srank = hQuery.FetchInt( 2 );
		int drank = hQuery.FetchInt( 3 );

		if (solly > 0.0 || demo > 0.0)
		{
			if (drank >= srank && srank > 0 && drank > 0)
			{
				CPrintToChatAll("{lightskyblue}%s {orange}(Rank %d Soldier){white} joining from {green}%s", name, srank, Country );
			}
			else
			{
				CPrintToChatAll("{lightskyblue}%s {orange}(Rank %d Demoman){white} joining from {green}%s", name, drank, Country );
			}
		}
		else
		{
			CPrintToChatAll("{lightskyblue}%s {orange}(Unranked){white} joining from {green}%s", name, Country );
		}
	}
	else
	{
		CPrintToChatAll("{lightskyblue}%s {orange}(Unranked){white} joining from {green}%s", name, Country );
	}
	delete hQuery;
}

public void OnTxnFail( Database g_hDatabase, any data, int numQueries, const char[] error, int failIndex, any[] queryData )
{
	DB_LogError( error[failIndex] );
}

public void OnDisplayRankTxnSuccess( Database g_hDatabase, ArrayList hData, int numQueries, DBResultSet[] hQuery, any[] queryData )
{
	int client;
	if ( (client = GetClientOfUserId( hData.Get( 0, 0 ) )) )
	{
		int outof, rank, oldrank;

		if (hQuery[0].FetchRow())
			outof = hQuery[0].FetchInt( 0 );
		
		if (hQuery[1].FetchRow())
			oldrank = hQuery[1].FetchInt( 0 );
		else
			oldrank = 99999999999;

		if (hQuery[2].FetchRow())
			rank = hQuery[2].FetchInt( 0 ) + 1;
		
		int run = hData.Get( 0, 1 );
		int style = hData.Get( 0, 2 );
		int mode = hData.Get( 0, 3 );

		RunType run_type = (RunIsCourse(run)) ? COURSE_RUN : (RunIsBonus(run)) ? BONUS_RUN : MAP_RUN;

		if (rank <= 0)
			rank = 99999999999;

		if ( 99999999999 > rank > outof )
			outof = rank;

		float CompletionPoints[3][6] = 
		{
			//Map
			{
				10.0,
				20.0,
				30.0,
				50.0,
				100.0,
				200.0
			},
			//Course
			{
				5.0,
				10.0,
				20.0,
				30.0,
				50.0,
				100.0
			},
			//Bonus
			{
				2.0,
				5.0,
				10.0,
				20.0,
				30.0,
				50.0
			}
		};

		float WrPoints[3][6] = 
		{
			//Map
			{	
				200.0,
				250.0,
				300.0,
				350.0,
				400.0,
				500.0
			},
			//Course
			{	
				100.0,
				150.0,
				200.0,
				250.0,
				300.0,
				400.0
			},
			//Bonus
			{	
				10.0,
				20.0,
				40.0,
				60.0,
				80.0,
				100.0
			}
		};

		float multipler[10] = 
		{
			1.0,
			0.7,
			0.5,
			0.4,
			0.35,
			0.3,
			0.25,
			0.2,
			0.15,
			0.1
		};

		float points = CompletionPoints[view_as<int>(run_type)][g_Tiers[run][mode]-1], points2 = 0.0;
		
		char db_run[40];
		char szTrans[400];

		Transaction transaction = new Transaction();

		g_hDatabase.Format(db_run, sizeof(db_run), "%s", (RunIsCourse(run)) ? "course" : (RunIsBonus(run)) ? "bonus" : "map");

		if( rank != oldrank )
		{
			if ( rank <= 10)
			{
				points2 = WrPoints[view_as<int>(run_type)][g_Tiers[run][mode]-1] * multipler[rank - 1]; 
			}
			
			if ( 0 < oldrank <= 10 && oldrank > rank && rank <= 10 )
			{
				points = 0.0;
				points2 = 	(WrPoints[view_as<int>(run_type)][g_Tiers[run][mode]-1] * multipler[rank - 1])
						-
							(WrPoints[view_as<int>(run_type)][g_Tiers[run][mode]-1] * multipler[oldrank - 1]);
			
			}

			if (rank < 11 || szOldTimePts[client][run][mode] <= TIME_INVALID)
			{
				points3 = points + points2;
				CPrintToChat(client, CHAT_PREFIX..."Gained {lightskyblue}%.1f {white}%s points!", points3, (style == STYLE_DEMOMAN) ? "Demoman" : "Soldier" );
				
				g_hDatabase.Format(szTrans, sizeof(szTrans), "UPDATE "...TABLE_RECORDS..." SET pts = pts + %.1f%s WHERE map = '%s' AND uid = %i AND run = %i AND mode = %i;", points3, (rank == 1) ? ", beaten = 0" : "", g_szCurrentMap, g_iClientId[client], run, mode);
				transaction.AddQuery(szTrans);

				g_hDatabase.Format(szTrans, sizeof(szTrans), "(SELECT @curRank := 0);");
				transaction.AddQuery(szTrans);

				g_hDatabase.Format(szTrans, sizeof(szTrans), "update maprecs SET `rank` = (@curRank := @curRank + 1) WHERE map = '%s' AND run = %i AND mode = %i ORDER BY time ASC;", g_szCurrentMap, run, mode );
				transaction.AddQuery(szTrans);

				if (rank <= 10)
				{ 
					g_hDatabase.Format(szTrans, sizeof(szTrans), "UPDATE "...TABLE_RECORDS..." SET pts = \
						((SELECT wr_pts from points where run_type = '%s' and tier = %i) \
						* (SELECT multipler FROM points_multipler where `rank` = maprecs.`rank`) \
						+ (SELECT completion from points where run_type = '%s' and tier = %i) ) \
						WHERE recordid = maprecs.recordid AND map = '%s' AND run = %i AND mode = %i",
						db_run, g_Tiers[run][mode], db_run, g_Tiers[run][mode], g_szCurrentMap, run, mode);
						
					transaction.AddQuery(szTrans);
				}
			}

			CPrintToChatClientAndSpec( client, CHAT_PREFIX..."Now ranked {lightskyblue}%i/%i{white} on {lightskyblue}%s{white}!", rank, outof, g_szRunName[NAME_LONG][run] );

			if ( 1 < rank < 11 && run == RUN_MAIN )
			{
				char	szStyleFix[STYLEPOSTFIX_LENGTH];
				GetStylePostfix( mode, szStyleFix, true );
				CPrintToChatAll(CHAT_PREFIX..."(%s%s) {green}%N {white}finished the map with rank {green}%i/%i{white}!",
				g_szStyleName[NAME_SHORT][style], szStyleFix,
				client,
				rank,
				outof);
			}

			if (rank == 1 && outof > 1)
			{
				g_hDatabase.Format(szTrans, sizeof(szTrans), "UPDATE "...TABLE_RECORDS..." SET beaten = 1 WHERE `rank` = 2 AND map = '%s' AND run = %i AND mode = %i", g_szCurrentMap, run, mode);
				
				transaction.AddQuery(szTrans);
			}

			SQL_ExecuteTransaction(g_hDatabase, transaction, OnMapRecordUpdated, OnTxnFail);

			for ( int i = 1; i <= MaxClients; i++)
			{
				if (IsClientInGame(i) && g_flClientBestTime[i][run][mode] != TIME_INVALID)
				{
					DB_RetrieveClientData( i );
				}
			}
		}
	}
	delete hData;
}

void Update_PlayersRanksAndPoints()
{
	Transaction transaction = new Transaction();

	transaction.AddQuery("UPDATE "...TABLE_PLYDATA..." SET solly = COALESCE((SELECT SUM(pts) FROM "...TABLE_RECORDS..." WHERE uid = plydata.uid AND mode = 1 AND (SELECT enabled FROM maplist where map = maprecs.`map`) = 1), 0.0) WHERE uid = plydata.uid;");
	transaction.AddQuery("UPDATE "...TABLE_PLYDATA..." SET demo = COALESCE((SELECT SUM(pts) FROM "...TABLE_RECORDS..." WHERE uid = plydata.uid AND mode = 3 AND (SELECT enabled FROM maplist where map = maprecs.`map`) = 1), 0.0) WHERE uid = plydata.uid;");

	transaction.AddQuery("UPDATE "...TABLE_PLYDATA..." SET overall = COALESCE((SELECT SUM(pts) FROM "...TABLE_RECORDS..." WHERE uid = plydata.uid AND (SELECT enabled FROM maplist where map = maprecs.`map`) = 1), 0.0) WHERE uid = plydata.uid;");

	transaction.AddQuery("(SELECT @curClassRank := 0);");

	transaction.AddQuery("UPDATE "...TABLE_PLYDATA..." SET srank = (@curClassRank := @curClassRank + 1) where solly > 0.0 ORDER BY solly DESC;");
	transaction.AddQuery("UPDATE "...TABLE_PLYDATA..." SET drank = (@curClassRank := @curClassRank + 1) where demo > 0.0 ORDER BY demo DESC;");

	transaction.AddQuery("(SELECT @curOverRank := 0);");

	transaction.AddQuery("UPDATE "...TABLE_PLYDATA..." SET orank = (@curOverRank := @curOverRank + 1) where solly > 0.0 or demo > 0.0 ORDER BY overall DESC;" );

	g_hDatabase.Execute(transaction, OnPlydataUpdated, _, _, DBPrio_Low);
}

public void OnPlydataUpdated(Database g_hDatabase, any client, int numQueries, DBResultSet[] results, any[] queryData)
{
	if (client <= 0) return;

	if ( results[1] == DBVal_Error || results[1] == DBVal_Null || results[1] == DBVal_TypeMismatch || results[1] == null ) 
	{
		char error[200];

		if (SQL_GetError(g_hDatabase, error, sizeof(error)))
		{
			DB_LogError( error );
		}

		return;
	}

	for ( int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i))
		{
			DB_RetrieveClientData( i );
		}
	}

	PrintToServer("PLYDATA ranks and points updated!");
}

public void OnMapRecordUpdated(Database g_hDatabase, any client, int numQueries, DBResultSet[] results, any[] queryData)
{
	if (client <= 0) return;

	if ( results[1] == DBVal_Error || results[1] == DBVal_Null || results[1] == DBVal_TypeMismatch || results[1] == null ) 
	{
		char error[200];

		if (SQL_GetError(g_hDatabase, error, sizeof(error)))
		{
			DB_LogError( error );
		}

		return;
	}

	Update_PlayersRanksAndPoints();
}

public void GetTiers_CallBack( Database hOwner, DBResultSet results, const char[] szError, any data )
{
	if ( results == null )
	{
		DB_LogError( "Couldn't get map tiers!" );
		
		return;
	}

	char map[100], szCourses[60], szBonuses[60], szInfo[120], szInfo2[160];

	int run, stier, dtier, courses, bonuses;

	if (results.RowCount)
	{
		if (results.FetchRow())
		{
			results.FetchString( 0, map, sizeof(map) );
			run = results.FetchInt( 3 );
			if (run == 0)
			{
				stier = results.FetchInt( 1 );
				dtier = results.FetchInt( 2 );
			}
			else
			{
				stier = -1;
				dtier = -1;
			}
		}

		while (results.FetchRow())
		{
			run = results.FetchInt( 3 );

			if (RUN_COURSE1 <= run <= RUN_COURSE10 )
				courses++;

			else if (RUN_BONUS1 <= run <= RUN_BONUS10)
				bonuses++;
		}

		if (courses > 0)
		{
			FormatEx(szCourses, sizeof(szCourses)," {white}| {lightskyblue}%i {white}courses", courses);
		}
		if (bonuses > 0)
		{
			FormatEx(szBonuses, sizeof(szBonuses)," {white}| {lightskyblue}%i {white}bonuses", bonuses);
		}

		FormatEx(szInfo, sizeof(szInfo), ""...CHAT_PREFIX..."{lightskyblue}%s {white}tiers", map);
		FormatEx(szInfo2, sizeof(szInfo2), ""...CHAT_PREFIX..."{white}Solly {lightskyblue}T%i {white}| Demo {lightskyblue}T%i%s%s", stier, dtier, szCourses, szBonuses);

		CPrintToChatAll(szInfo);
		CPrintToChatAll(szInfo2);
	}
	else
	{
		CPrintToChatAll(CHAT_PREFIX..."No match found");
	}

	delete results;
	return;
}

public void Threaded_NewID( Database hOwner, DBResultSet hQuery, const char[] szError, int client )
{
	if ( hQuery == null )
	{
		DB_LogError( "Couldn't create new player data record!" );
		
		return;
	}
	
	if ( !(client = GetClientOfUserId( client )) ) return;
	
	
	char szSteam[MAX_ID_LENGTH];
	
	GetClientSteam( client, szSteam, sizeof( szSteam ) );
	int args;
	ShowHelp(client, args);
	
	
	static char szQuery[92];
	g_hDatabase.Format( szQuery, sizeof( szQuery ), "SELECT uid FROM "...TABLE_PLYDATA..." WHERE steamid = '%s'", szSteam );
	
	g_hDatabase.Query( Threaded_NewID_Final, szQuery, GetClientUserId( client ), DBPrio_High );
}

public void Threaded_NewID_Final( Database hOwner, DBResultSet hQuery, const char[] szError, int client )
{
	if ( hQuery == null )
	{
		DB_LogError( "Couldn't receive new id for player!" );
		
		return;
	}
	
	if ( !(client = GetClientOfUserId( client )) ) return;
	int args;
	ShowHelp(client, args);
	char szSteam[100];
	GetClientSteam(client, szSteam,sizeof( szSteam) );
	char szQuery[300];
	char sTime[32];
	char szLink[192];
    GetClientAuthId( client, AuthId_SteamID64, szLink, sizeof(szLink) );
	char name[99], IP[99], Country[99];
	GetClientName(client, name, sizeof(name));
	GetClientIP(client, IP, sizeof(IP), true);
	if(!GeoipCountry(IP, Country, sizeof(Country)))
			Country = "None";

	FormatTime(sTime, sizeof(sTime), "%Y-%m-%d %H:%M:%S", GetTime() ); 
	g_hDatabase.Format( szQuery, sizeof( szQuery ), "UPDATE "...TABLE_PLYDATA..." SET lastseen = CURRENT_TIMESTAMP, firstseen = CURRENT_TIMESTAMP, country = '%s', link = '%s', ip = '%s' WHERE steamid = '%s'",
	Country,
	szLink,
	IP,
	szSteam );
	SQL_TQuery(g_hDatabase, Threaded_Empty, szQuery, client);
	
	
	if ( hQuery.RowCount )
	{
		hQuery.FetchRow();
		g_iClientId[client] = hQuery.FetchInt( 0 );
	}
	else
	{
		LogError( CONSOLE_PREFIX..."Couldn't receive new id for player!" );
	}
}

public void OnAddRecordDone(Database g_hDatabase, any client, int numQueries, DBResultSet[] results, any[] queryData)
{
	if (client <= 0) return;

	if ( results[1] == DBVal_Error || results[1] == DBVal_Null || results[1] == DBVal_TypeMismatch || results[1] == null ) 
	{
		char error[200];

		if (SQL_GetError(g_hDatabase, error, sizeof(error)))
		{
			DB_LogError( error );
		}

		return;
	}

	results[1].FetchRow();
	int run = results[1].FetchInt(0);
	int style = results[1].FetchInt(1);
	int mode = results[1].FetchInt(2);

	if (results[2].FetchRow())
	{	
		char szQuery[255];

		g_iClientMapPR_id[client][mode] = results[2].FetchInt(0);

		// Save checkpoint time differences.
		if ( g_hCPs != null && run == RUN_MAIN )
		{
			int len = g_hClientCPData[client].Length;

			for ( int i = 0; i < len; i++ )
			{
				int iData[C_CP_SIZE];
				
				static float flPrevTime;
				
				flPrevTime = g_flClientStartTime[client];
				
				g_hClientCPData[client].GetArray( i, iData, view_as<int>( C_CPData ) );
				
				
				float flRecTime;
				flRecTime = view_as<float>( iData[C_CP_GAMETIME] ) - flPrevTime;
				
				if (f_CpPr[client][mode][i] <= TIME_INVALID)
				{
					FormatEx( szQuery, sizeof( szQuery ), "INSERT INTO mapcprecs VALUES (%i, '%s', %i, %i, %i, %i, %i, %.16f)",
					g_iClientMapPR_id[client][mode],
					g_szCurrentMap,
					iData[C_CP_ID],
					run,
					style,
					mode,
					g_iClientId[client],
					flRecTime );
				}
				else
				{
					FormatEx( szQuery, sizeof( szQuery ), "UPDATE mapcprecs SET time = %.16f WHERE recordid = %i and id = %i", flRecTime, g_iClientMapPR_id[client][mode], iData[C_CP_ID] );
				}

				g_hDatabase.Query(Threaded_Empty, szQuery);

				SetPrCpTime( iData[C_CP_INDEX], mode, flRecTime, client  );
			}
		}
	}
	DB_DisplayClientRank( client, run, style, mode );
	return;
}

public void Threaded_GetMapList( Database hOwner, DBResultSet hQuery, const char[] szError, any data )
{
	if ( hQuery == null )
	{
		DB_LogError( "Unable to retrieve map list!" );
		
		return;
	}
	char map[50];
	if (hQuery.RowCount)
	{
		while (hQuery.FetchRow())
		{
			hQuery.FetchString(0, map, sizeof(map));
			g_aMapListFromDB.PushString(map);
		}
	}

	UpdateMaplistByTempus();
	
	return;
}

public void Threaded_CheckPointsDefault( Database hOwner, DBResultSet hQuery, const char[] szError, any data )
{
	if ( hQuery == null )
	{
		DB_LogError( "Unable to retrieve map zones!" );
		
		return;
	}

	if (hQuery.RowCount<1)
	{
		if (data == 1)
		{
			g_hDatabase.Query( Threaded_Empty,
			"REPLACE INTO `points` VALUES\ 
			('map',1,10,200),('map',2,20,250),('map',3,30,300),('map',4,50,350),('map',5,100,400),\
			('map',6,200,500),('course',1,5,100),('course',2,10,150),('course',3,20,200),('course',4,30,250),\
			('course',5,50,300),('course',6,100,400),('bonus',1,2,10),('bonus',2,5,20),\
			('bonus',3,10,40),('bonus',4,20,60),('bonus',5,30,80),('bonus',6,50,100);" );
		}
		if (data == 2)
		{
			g_hDatabase.Query( Threaded_Empty,
			"REPLACE INTO `points_multipler` VALUES (1,1),(2,0.7),(3,0.5),(4,0.4),(5,0.35),(6,0.3),(7,0.25),(8,0.2),(9,0.15),(10,0.1),(11,0);" );
		}
	}
	return;
}

public void Threaded_Init_Zones( Database hOwner, DBResultSet hQuery, const char[] szError, any data )
{
	if ( hQuery == null )
	{
		DB_LogError( "Unable to retrieve map zones!" );
		
		return;
	}
	
	int zones = 0;
	float vecMins[3];
	char Query[100], polygon[1024], error[64];
	float vecMaxs[3];
	int zone;
	int iData[ZONE_SIZE];
	int index;

	bool isErrorPolygon = false;

	Handle hJson;
	while ( hQuery.FetchRow() )
	{
		zone = hQuery.FetchInt( 0 );
		
		vecMins[0] = hQuery.FetchFloat( 1 );
		vecMins[1] = hQuery.FetchFloat( 2 );
		vecMins[2] = hQuery.FetchFloat( 3 );
		
		vecMaxs[0] = hQuery.FetchFloat( 4 );
		vecMaxs[1] = hQuery.FetchFloat( 5 );
		vecMaxs[2] = hQuery.FetchFloat( 6 );
		index = hQuery.FetchInt( 8 );
		
		if ( zone >= NUM_REALZONES )
		{
			iData[ZONE_TYPE] = zone;
			iData[ZONE_ID] = hQuery.FetchInt( 7 );
			
			ArrayCopy( vecMins, iData[ZONE_MINS], 3 );
			ArrayCopy( vecMaxs, iData[ZONE_MAXS], 3 );
			
			g_hZones.PushArray( iData, view_as<int>( ZoneData ) );
		}
		else
		{
			iData[ZONE_TYPE] = zone;
			iData[ZONE_ID] = index;

			
			g_bZoneExists[zone][index] = true;
			
			ArrayCopy( vecMins, iData[ZONE_MINS], 3 );
			ArrayCopy( vecMaxs, iData[ZONE_MAXS], 3 );
			ArrayCopy( vecMins, g_vecZoneMins[zone][index], 3 );
			ArrayCopy( vecMaxs, g_vecZoneMaxs[zone][index], 3 );

			g_hZones.PushArray( iData, view_as<int>( ZoneData ) );
		}
		CreateZoneBeams( zone, vecMins, vecMaxs, iData[ZONE_ID], index );
		zones++;
	}
	CPrintToChatAll(CHAT_PREFIX..."Loaded {lightskyblue}%i zone(s)", zones );
	
	if ( !g_bZoneExists[ZONE_START][0] && !g_bZoneExists[ZONE_END][0] && !g_bZoneExists[ZONE_COURSE_1_START][0] && !g_bZoneExists[ZONE_COURSE_1_END][0] )
	{
		PrintToServer( CONSOLE_PREFIX..."Map is lacking zones..." );
		g_bIsLoaded[RUN_MAIN] = false;
	}
	else g_bIsLoaded[RUN_MAIN] = true;
	
	for (int i = 2; i < NUM_RUNS+20; i+=2)
	{
		g_bIsLoaded[i/2] = ( g_bZoneExists[i][0] && g_bZoneExists[i+1][0] );
	}
	
	
	if ( g_bIsLoaded[RUN_MAIN] || g_bIsLoaded[RUN_COURSE1] )
	{
		SetupZoneSpawns();
		
		char szQuery[256];
		
		for (int i=0; i < NUM_RUNS; i++)
		{
			if (!g_bIsLoaded[i]) continue;
			
			for (int b=1; b < 4; b+=2)
			{
				FormatEx( szQuery, sizeof( szQuery ), "SELECT uid, run, style, mode, time, name, recordid FROM maprecs natural join plydata WHERE map = '%s' and run = %i and mode = %i order by time asc limit 1", g_szCurrentMap, i, b );
				
				g_hDatabase.Query( Threaded_Init_Records, szQuery, _, DBPrio_Normal );
			}
		}

		g_hDatabase.Format(szQuery, sizeof(szQuery), "SELECT run, stier, dtier, solly, demo FROM "...TABLE_MAPINFO..." WHERE map_name = '%s'", g_szCurrentMap);
		g_hDatabase.Query( Threaded_Init_Tiers, szQuery, _, DBPrio_High );		
		
		g_hDatabase.Format(szQuery, sizeof(szQuery), "SELECT level, pos0, pos1, pos2, ang0, ang1, ang2 FROM levels WHERE map = '%s'", g_szCurrentMap);
		g_hDatabase.Query( Threaded_Init_Levels, szQuery, _, DBPrio_High );
		
		g_hDatabase.Format( szQuery, sizeof( szQuery ), "SELECT run, id, min0, min1, min2, max0, max1, max2 FROM "...TABLE_CP..." WHERE map = '%s'", g_szCurrentMap );
		g_hDatabase.Query( Threaded_Init_CPs, szQuery, _, DBPrio_Normal );

		g_hDatabase.Format(szQuery, sizeof(szQuery), "SELECT mode, pos0, pos1, pos2, ang0, ang1, ang2 FROM skip_zones WHERE map = '%s'", g_szCurrentMap);
		g_hDatabase.Query( Threaded_Init_Skip, szQuery, _, DBPrio_High );
	}
	
	CheckZones();
}

public void Threaded_Init_Skip( Database hOwner, DBResultSet hQuery, const char[] szError, any data )
{
	if ( hQuery == null )
	{
		DB_LogError( "Unable to retrieve map records!" );
	}
	if ( hQuery.RowCount )
	{
		if (hQuery.FetchRow())
		{
			g_iSkipMode = hQuery.FetchInt( 0 );
			g_vecSkipPos[0] = hQuery.FetchFloat( 1 );
			g_vecSkipPos[1] = hQuery.FetchFloat( 2 );
			g_vecSkipPos[2] = hQuery.FetchFloat( 3 );
			g_vecSkipAngles[0] = hQuery.FetchFloat( 4 );
			g_vecSkipAngles[1] = hQuery.FetchFloat( 5 );
			g_vecSkipAngles[2] = hQuery.FetchFloat( 6 );
		}
	}
}

public void Threaded_Init_Levels( Database hOwner, DBResultSet hQuery, const char[] szError, any data )
{
	if ( hQuery == null )
	{
		DB_LogError( "Unable to retrieve map records!" );
	}
	if ( hQuery.RowCount )
	{
		int level;

		while ( hQuery.FetchRow() )
		{
			level = hQuery.FetchInt( 0 );
			
			for (int i = 0; i<3; i++)
				g_fClientLevelPos[level][i] = hQuery.FetchFloat( i+1 );

			for (int i = 0; i<3; i++)	
				g_fClientLevelAng[level][i] = hQuery.FetchFloat( i+4 );
		}
	}
}

public void Threaded_Init_Records( Database hOwner, DBResultSet hQuery, const char[] szError, any data )
{
	if ( hQuery == null )
	{
		DB_LogError( "Unable to retrieve map records!" );
	}
	if ( hQuery.RowCount )
	{
	
		int		iRun;
		int		iStyle;
		int		iMode;

		if ( hQuery.FetchRow() )
		{
			iRun = hQuery.FetchInt( 1 );
			
			if ( !g_bIsLoaded[iRun] ) return;
			
			
			iStyle = hQuery.FetchInt( 2 );
			iMode = hQuery.FetchInt( 3 );
			
			g_flMapBestTime[iRun][iStyle][iMode] = hQuery.FetchFloat( 4 );

			hQuery.FetchString( 5, szWrName[iRun][iMode], sizeof(szWrName) );

			if (iRun == RUN_MAIN)
				g_iMapWR_id[iMode] = hQuery.FetchInt( 6 );
		}
	}
}


public void Threaded_Init_Tiers( Database hOwner, DBResultSet hQuery, const char[] szError, any data )
{
	if ( hQuery == null )
	{
		DB_LogError( "Unable to retrieve map tiers!" );
	}
	
	if ( hQuery.RowCount )
	{

		int run;
		
		while( hQuery.FetchRow() )
		{
			run = hQuery.FetchInt( 0 );

			g_Tiers[run][MODE_SOLDIER] = hQuery.FetchInt( 1 );
			g_Tiers[run][MODE_DEMOMAN] = hQuery.FetchInt( 2 );

			szClass[run][MODE_SOLDIER] = hQuery.FetchInt( 3 );
			szClass[run][MODE_DEMOMAN] = hQuery.FetchInt( 4 );
		}
	}

	char szQuery[192];
	g_hDatabase.Format(szQuery, sizeof(szQuery), "SELECT run, pos0, pos1, pos2, ang0, ang1, ang2 FROM startpos WHERE map = '%s'", g_szCurrentMap);
	g_hDatabase.Query( Threaded_Custom_Start, szQuery );
}

public void Threaded_Custom_Start( Database hOwner, DBResultSet hQuery, const char[] szError, any data )
{
	if ( hQuery == null )
	{
		DB_LogError( "Unable to retrieve map Class! 2" );
		
		return;
	}
	
	if ( hQuery.RowCount )
	{

		int run;
		
		while( hQuery.FetchRow() )
		{
			run = hQuery.FetchInt( 0 );

			isSetCustomStart[run] = true;

			g_CustomRespawnPos[run][0] = hQuery.FetchFloat(1);
			g_CustomRespawnPos[run][1] = hQuery.FetchFloat(2);
			g_CustomRespawnPos[run][2] = hQuery.FetchFloat(3);
			g_CustomRespawnAng[run][0] = hQuery.FetchFloat(4);
			g_CustomRespawnAng[run][1] = hQuery.FetchFloat(5);
			g_CustomRespawnAng[run][2] = hQuery.FetchFloat(6);
		}
		SetupZoneSpawns();
	}

}

public void Threaded_Init_CPs( Database hOwner, DBResultSet hQuery, const char[] szError, any data )
{
	if ( hQuery == null )
	{
		DB_LogError( "Unable to retrieve map checkpoints!" );
		
		return;
	}
	
	if ( !hQuery.RowCount ) return;
	
	
	int iData[CP_SIZE];
	float vecMins[3];
	float vecMaxs[3];
	
	while ( hQuery.FetchRow() )
	{
		iData[CP_ID] = hQuery.FetchInt( 1 );
		
		vecMins[0] = hQuery.FetchFloat(  2 );
		vecMins[1] = hQuery.FetchFloat(  3 );
		vecMins[2] = hQuery.FetchFloat(  4 );
		
		vecMaxs[0] = hQuery.FetchFloat(  5 );
		vecMaxs[1] = hQuery.FetchFloat(  6 );
		vecMaxs[2] = hQuery.FetchFloat(  7 );
		
		ArrayCopy( vecMins, iData[CP_MINS], 3 );
		ArrayCopy( vecMaxs, iData[CP_MAXS], 3 );
		
		g_hCPs.PushArray( iData, view_as<int>( CPData ) );
		
		CreateZoneBeams( ZONE_CP, vecMins, vecMaxs, iData[CP_ID] );
	}
	
	// GET CHECKPOINT TIMES
	char szQuery[500];
	g_hDatabase.Format( szQuery, sizeof( szQuery ), "SELECT uid, run, id, mode, time, map FROM mapcprecs WHERE recordid = %i OR recordid = %i", g_iMapWR_id[MODE_SOLDIER], g_iMapWR_id[MODE_DEMOMAN] );
	
	g_hDatabase.Query( Threaded_Init_CP_WR_Times, szQuery, _, DBPrio_High );
}

public void Threaded_Init_CP_WR_Times( Database hOwner, DBResultSet hQuery, const char[] szError, any data )
{

	if ( hQuery == null )
	{
		DB_LogError( szError );
		
		return;
	}
	
	if ( !hQuery.RowCount ) return;

	int id;
	int run;
	int index;
	
	while ( hQuery.FetchRow() )
	{
		run = hQuery.FetchInt( 1 );
		id = hQuery.FetchInt( 2 );
		index = FindCPIndex( run, id );
		
		if ( index != -1 )
		{
			int mode = hQuery.FetchInt( 3 );
			float flTime = hQuery.FetchFloat(  4 );
			
			SetWrCpTime( index, mode, flTime );
		}
	}
}

public void Threaded_Init_CP_PR_Times( Database hOwner, DBResultSet hQuery, const char[] szError, int client )
{
	if ( hQuery == null )
	{
		DB_LogError( szError );
		
		return;
	}
	
	if ( !hQuery.RowCount )
	{
		return;
	}
	
	int id;
	int run;
	int index;
	
	while ( hQuery.FetchRow() )
	{
		run = hQuery.FetchInt( 1 );
		id = hQuery.FetchInt( 0 );
		index = FindCPIndex( run, id );
		
		if ( index != -1 )
		{
			int style = hQuery.FetchInt( 2 );
			int mode = hQuery.FetchInt( 3 );
			float flTime = hQuery.FetchFloat(  4 );
			
			SetPrCpTime( index, mode, flTime, client );
		}
	}
}

public void Threaded_DeleteRecord( Database hOwner, DBResultSet hQuery, const char[] szError, int client )
{
	if ( hQuery == null )
	{
		DB_LogError( "Couldn't delete record.", client, "Couldn't delete record!" );
		
		return;
	}
	
	if ( client && IsClientInGame( client ) )
	{
		CPrintToChat( client, CHAT_PREFIX..."Record was succesfully deleted!" );
	}
}

public void Threaded_DeleteCpRecord( Database hOwner, DBResultSet hQuery, const char[] szError, int client )
{
	if ( hQuery == null )
	{	
		DB_LogError(szError);
		return;
	}
}

// No special callback is needed.
public void Threaded_Empty( Handle hOwner, Handle hQuery, char[] szError, any client )
{
	if ( hQuery == null )
	{
		DB_LogError( szError, client, "Couldn't save data." );
	}
	delete hQuery;
}

public void MapsManagement(int client)
{
	char query[150];

	FormatEx(query, sizeof(query), "SELECT map, enabled FROM maplist ORDER BY `map`");
	g_hDatabase.Query(Threaded_MapsManagement, query, client, DBPrio_High);
}

public void Threaded_MapsManagement( Database hOwner, DBResultSet hQuery, char[] szError, any client )
{
	if ( hQuery == null )
	{
		DB_LogError( szError, client, "Couldn't open map management." );
	}

	if ( !hQuery.RowCount )
	{
		CPrintToChat(client, "{red}ERROR {white}| Map list is empty");
		return;
	}

	char map[50], temp[50];
	int enabled;
	char status[50], display[100];

	int total;

	Menu mMenu = new Menu( Handler_MapsManagemet );

	while (hQuery.FetchRow())
	{
		hQuery.FetchString(0, map, sizeof(map));
		enabled = hQuery.FetchInt(1);

		FormatEx(status, sizeof(status), "%s***%s", enabled ? "enabled" : "disabled", map);

		FormatEx(display, sizeof(display), "[%s] %s %s", enabled ? "ENABLED" : "DISABLED", map, GetMapDisplayName(map, temp, sizeof(temp)) ? "" : "[Download]" );

		mMenu.AddItem(status, display);
		total++;
	}
	mMenu.SetTitle( "Maps Management Menu\n%i Maps Total\n ", total );
	mMenu.DisplayAt(client, menu_page[client], MENU_TIME_FOREVER);

	delete hQuery;
}

public int Handler_MapsManagemet( Menu mMenu, MenuAction action, int client, int item )
{
	if ( action == MenuAction_End ) { delete mMenu; return 0; }
	if ( action == MenuAction_Cancel )
	{
		CPrintToChat(client, CHAT_PREFIX..."{lightskyblue}Updating {white}some data...");
		Update_PlayersRanksAndPoints();
		return 0;
	}
	if (action == MenuAction_Select)
	{
		menu_page[client] = GetMenuSelectionPosition();
		
		char szItem[100], szInfo[2][50];
		mMenu.GetItem(item, szItem, sizeof(szItem));

		ExplodeString( szItem, "***", szInfo, sizeof( szInfo ), sizeof( szInfo[] ) );

		if (StrEqual(szInfo[0], "enabled"))
			DisableMap(client, szInfo[1]);
		else if(StrEqual(szInfo[0], "disabled"))
			EnableMap(client, szInfo[1]);

		MapsManagement(client);
	}
	return 0;
}

void EnableMap(int client, char[] map, bool isAll = false)
{
	char szTemp[50], query[150];

	if (GetMapDisplayName(map, szTemp, sizeof(szTemp)))
	{
		if (!isAll)
		{
			FormatEx(query, sizeof(query), "UPDATE maplist SET enabled = 1 WHERE map = '%s'", map);
			g_hDatabase.Query(Threaded_Empty, query);
		
			CPrintToChatAll(CHAT_PREFIX..."{lightskyblue}%s {white}is now {green}Enabled!", map);
			LoadMapList();
		}
	}
	else
	{
		CPrintToChat(client, CHAT_PREFIX..."{lightskyblue}%s {white}not found, Downloading...", map);

		FormatEx(query, sizeof(query), "UPDATE maplist SET enabled = 1 WHERE map = '%s'", map);
		g_hDatabase.Query(Threaded_Empty, query);
		
		char output[150], link[300];
		FormatEx(link, sizeof(link), "https://static.tempus2.xyz/tempus/server/maps/%s.bsp.bz2", map);
		FormatEx(output, sizeof(output), "addons/sourcemod/data/%s.bsp.bz2", map);

		System2HTTPRequest httpRequest = new System2HTTPRequest(HttpResponseCallback, link);
		httpRequest.SetData(map);
		httpRequest.SetOutputFile(output);
		httpRequest.GET();
	}

	return;
}

public void HttpResponseCallback(bool success, const char[] error, System2HTTPRequest request, System2HTTPResponse response, HTTPRequestMethod method)
{
    char map[50], infile[150], out[150];
	request.GetData(map, sizeof(map));
	if (success) {
		PrintToServer(map);

		FormatEx(infile, sizeof(infile), "addons/sourcemod/data/%s.bsp.bz2", map);
		FormatEx(out, sizeof(out), "addons/sourcemod/data/%s.bsp", map);

		Handle pack = CreateDataPack();
		WritePackString(pack, map);

		BZ2_DecompressFile(infile, out, OnMapDecompressed, pack);
    } else {
		char query[150];
        PrintToAdmins("{red}Failed {white}| Download %s...", map);

		FormatEx(query, sizeof(query), "UPDATE maplist SET enabled = 0 WHERE map = '%s'", map);
		g_hDatabase.Query(Threaded_Empty, query);
    }
}

public OnMapDecompressed(BZ_Error:iError, String:inFile[], String:outFile[], any:pack) 
{
	ResetPack(pack);
	char map[128], query[400], gamedir[400], DecompressedDir[400], mapsDir[400], CommandOutput[100], command[500];

	ReadPackString(pack, map, sizeof(map));
	CloseHandle(pack);
	if(_:iError < 0) {
		char suffix[256];
		Format(suffix, sizeof(suffix), "while decompressing %s", map);
		LogBZ2Error(iError, suffix);

		PrintToAdmins("{red}Failed {white}| decompressing %s.bz2...", map);

		FormatEx(query, sizeof(query), "UPDATE maplist SET enabled = 0 WHERE map = '%s'", map);
		g_hDatabase.Query(Threaded_Empty, query);

		return 0;
	}
	System2_GetGameDir(gamedir, sizeof(gamedir));

	FormatEx(DecompressedDir, sizeof(DecompressedDir), "%s/addons/sourcemod/data/%s.bsp", gamedir, map);
	FormatEx(mapsDir, sizeof(mapsDir), "%s/maps/%s.bsp", gamedir, map);


	if (System2_ExecuteFormatted(CommandOutput, sizeof(CommandOutput), "%s %s %s", System2_GetOS() == OS_WINDOWS ? "move" : "mv", DecompressedDir, mapsDir ))
	{
		char bspFilePath[200];
		BuildPath(Path_SM, bspFilePath, sizeof(bspFilePath), "data/%s.bsp.bz2", map);

		if(FileExists(bspFilePath))
			DeleteFile(bspFilePath);

		CPrintToChatAll(CHAT_PREFIX..."{lightskyblue}%s {white}is now Downloaded and {green}Enabled!", map);
		LoadMapList();
	}
	PrintToServer(CommandOutput);
	return 0;
}

public void DisableMap(int client, char[] map)
{
	char query[150];
	FormatEx(query, sizeof(query), "UPDATE maplist SET enabled = 0 WHERE map = '%s'", map);
	g_hDatabase.Query(Threaded_Empty, query);

	CPrintToChatAll(CHAT_PREFIX..."{lightskyblue}%s {white}is now {red}Disabled{white}!", map);
	LoadMapList();
	return;
}