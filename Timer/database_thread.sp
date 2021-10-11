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
	char last[100];
	char first[100];
	char item[192];
	char name[40];
	char cur_date[100];

	if ( hQuery.RowCount )
	{
		hQuery.FetchRow();
		hQuery.FetchString( 0, country, sizeof( country ) );
		hQuery.FetchString( 1, last, sizeof( last ) );
		hQuery.FetchString( 2, first, sizeof( first ) );
		id = hQuery.FetchInt( 3 );
		hQuery.FetchString( 4, name, sizeof( name ) );
		hQuery.FetchString( 5, cur_date, sizeof( cur_date ) );

		char time_ago_last[40], time_ago_first[40]; 
		FormatTimeDuration(time_ago_last, sizeof(time_ago_last), DateTimeToTimestamp(cur_date) - DateTimeToTimestamp(last));

		if (!hQuery.IsFieldNull(2))
			FormatTimeDuration(time_ago_first, sizeof(time_ago_first), DateTimeToTimestamp(cur_date) - DateTimeToTimestamp(first));

		FormatEx( item, sizeof( item ), "Details:\n Country: %s \n User id: %i \n Last seen: %s \n First seen: %s \n ", country, id, time_ago_last, time_ago_first );
		mMenu.AddItem("", item );
		mMenu.AddItem("", "Get Steam Profile Link\n ");
		if (GetUserFlagBits(client) & ADMFLAG_ROOT)
		{
			mMenu.AddItem("", "Wipe player stats");
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
		char szQuery[192];
		FormatEx(szQuery, sizeof( szQuery ), "SELECT run FROM "...TABLE_MAPINFO..." WHERE map_name = '%s'", db_map[client] );
		FakeClientCommand(client, "sm_top %s", db_map[client]);
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
	GetClientName(client, szName, sizeof( szName ) );
	
	char szQuery[500];
	
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
		PrintToChatAll( CHAT_PREFIX..."Found multiple records with the same Steam Id!!" );
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
		ranksolly[client] = hQuery.FetchInt( 5 );
		rankdemo[client] = hQuery.FetchInt( 6 );
		g_hDatabase.Format( szQuery, sizeof( szQuery ), "UPDATE plydata SET overall = (select sum(pts) from maprecs where uid = %i), solly = (select sum(pts) from maprecs where uid = %i and mode = 1), demo = (select sum(pts) from maprecs where uid = %i and mode = 3) WHERE uid = %i", g_iClientId[client], g_iClientId[client], g_iClientId[client], g_iClientId[client] );
		
		SQL_TQuery(g_hDatabase, Threaded_Empty, szQuery, client);
	}
	
	// Then we get the times.
	if ( g_iClientId[client] )
	{
		FormatEx( szQuery, sizeof( szQuery ), "SELECT run, mode, time FROM "...TABLE_RECORDS..." WHERE map = '%s' AND uid = %i ORDER BY run", g_szCurrentMap, g_iClientId[client] );
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
	
	while ( hQuery.FetchRow() )
	{
		run = hQuery.FetchInt( 0 );
		
		mode = hQuery.FetchInt( 1 );
	
		g_flClientBestTime[client][run][mode] = hQuery.FetchFloat( 2 );
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

		if (srank > 0 || drank > 0)
		{
			if (srank > drank > 0)
			{
				CPrintToChatAll("\x0750DCFF%s {orange}(Rank %d Demoman){white} joining from \x0764E664%s", name, drank, Country );
			}
			else if (drank >= srank > 0)
			{
				CPrintToChatAll("\x0750DCFF%s {orange}(Rank %d Soldier){white} joining from \x0764E664%s", name, srank, Country );
			}
			else
			{
				if (srank <= 0)
					CPrintToChatAll("\x0750DCFF%s {orange}(Rank %d Demoman){white} joining from \x0764E664%s", name, drank, Country );
				else
					CPrintToChatAll("\x0750DCFF%s {orange}(Rank %d Soldier){white} joining from \x0764E664%s", name, srank, Country );	
			}
		}
		else
		{
			CPrintToChatAll("\x0750DCFF%s {orange}(Unranked){white} joining from \x0764E664%s", name, Country );
		}
	}
	else
	{
		CPrintToChatAll("\x0750DCFF%s {orange}(Unranked){white} joining from \x0764E664%s", name, Country );
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

		float TTPoints[3][6][10] = 
		{
			//Map
			{	
				{ 20.0, 30.0, 40.0, 50.0, 60.0, 70.0, 80.0, 100.0, 140.0, 200.0 },
				{ 25.0, 37.5, 50.0, 62.5, 75.0, 87.5, 100.0, 125.0, 175.0, 250.0 },
				{ 30.0, 45.0, 60.0, 75.0, 90.0, 105.0, 120.0, 150.0, 210.0, 300.0 },
				{ 35.0, 52.5, 70.0, 87.5, 105.0, 122.5, 140.0, 175.0, 245.0, 350.0 },
				{ 40.0, 60.0, 80.0, 100.0, 120.0, 140.0, 160.0, 200.0, 280.0, 400.0 },
				{ 50.0, 75.0, 100.0, 150.0, 175.0, 200.0, 250.0, 250.0, 350.0, 500.0 }
			},
			//Course
			{	
				{ 10.0, 15.0, 20.0, 25.0, 30.0, 35.0, 40.0, 50.0, 70.0, 100.0 },
				{ 15.0, 22.5, 30.0, 37.0, 45.0, 52.0, 60.0, 75.0, 105.0, 150.0 },
				{ 20.0, 30.0, 40.0, 50.0, 60.0, 70.0, 80.0, 100.0, 140.0, 200.0 },
				{ 25.0, 37.5, 50.0, 62.5, 75.0, 87.5, 100.0, 125.0, 175.0, 250.0 },
				{ 30.0, 45.0, 60.0, 75.0, 90.0, 105.0, 120.0, 150.0, 210.0, 300.0 },
				{ 40.0, 60.0, 80.0, 100.0, 120.0, 140.0, 160.0, 200.0, 280.0, 400.0 }
			},
			//Bonus
			{	
				{ 1.0, 1.5, 2.0, 2.5, 3.0, 3.5, 4.0, 5.0, 7.0, 10.0 },
				{ 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 10.0, 14.0, 20.0 },
				{ 4.0, 6.0, 8.0, 10.0, 12.0, 14.0, 16.0, 20.0, 28.0, 40.0 },
				{ 6.0, 9.0, 12.0, 15.0, 18.0, 21.0, 24.0, 30.0, 42.0, 60.0 },
				{ 8.0, 12.0, 16.0, 20.0, 24.0, 28.0, 32.0, 40.0, 56.0, 80.0 },
				{ 10.0, 15.0, 20.0, 25.0, 30.0, 35.0, 40.0, 50.0, 70.0, 100.0 }
			}
		};

		float points = CompletionPoints[view_as<int>(run_type)][g_Tiers[run][mode]-1], points2 = 0.0;
		
		char db_run[40];
		char szTrans[200];

		Transaction transaction = new Transaction();

		g_hDatabase.Format(db_run, sizeof(db_run), "%s", (RunIsCourse(run)) ? "course" : (RunIsBonus(run)) ? "bonus" : "map");

		if( rank != oldrank )
		{
			if ( rank <= 10)
			{
				points2 = TTPoints[view_as<int>(run_type)][g_Tiers[run][mode]-1][10 - rank]; 
			}
			
			if ( 0 < oldrank <= 10 && oldrank > rank && rank <= 10 )
			{
				points = 0.0;
				points2 = TTPoints[view_as<int>(run_type)][g_Tiers[run][mode]-1][10 - rank] - TTPoints[view_as<int>(run_type)][g_Tiers[run][mode]-1][10 - oldrank];
			}

			if (rank < 11 || szOldTimePts[client][run][mode] <= TIME_INVALID)
			{
				points3 = points + points2;
				CPrintToChat(client, CHAT_PREFIX..."Gained "...CLR_CUSTOM1..."%.1f {white}%s points!", points3, (style == STYLE_DEMOMAN) ? "Demoman" : "Soldier" );
				
				g_hDatabase.Format(szTrans, sizeof(szTrans), "UPDATE "...TABLE_RECORDS..." SET pts = %.1f%s WHERE map = '%s' AND uid = %i AND run = %i AND mode = %i;", points3, (rank == 1) ? ", beaten = 0" : "", g_szCurrentMap, g_iClientId[client], run, mode);
				transaction.AddQuery(szTrans);

				g_hDatabase.Format(szTrans, sizeof(szTrans), "UPDATE "...TABLE_PLYDATA..." SET %s = (SELECT SUM(pts) FROM "...TABLE_RECORDS..." WHERE uid = %i AND mode = %i) WHERE uid = %i;", (mode == MODE_SOLDIER) ? "solly" : "demo", g_iClientId[client], mode, g_iClientId[client]);
				transaction.AddQuery(szTrans);

				g_hDatabase.Format(szTrans, sizeof(szTrans), "UPDATE "...TABLE_PLYDATA..." SET overall = (SELECT SUM(pts) FROM "...TABLE_RECORDS..." WHERE uid = %i) WHERE uid = %i;", g_iClientId[client], g_iClientId[client]);
				transaction.AddQuery(szTrans);
			}

			// "XXX is ranked X/X in [XXXX XXXX]"
			CPrintToChatClientAndSpec( client, CHAT_PREFIX..."Now ranked \x0750DCFF%i/%i"...CLR_TEXT..." on \x0750DCFF%s"...CLR_TEXT..."!", rank, outof, g_szRunName[NAME_LONG][run] );

			if (rank < 11 && rank > 1 && run == RUN_MAIN )
			{
				char	szStyleFix[STYLEPOSTFIX_LENGTH];
				GetStylePostfix( mode, szStyleFix, true );
				CPrintToChatAll(CHAT_PREFIX..."(%s%s) \x0764E664%N {white}finished the map with rank \x0764E664%i/%i{white}!",
				g_szStyleName[NAME_SHORT][style], szStyleFix,
				client,
				rank,
				outof);
			}

			g_hDatabase.Format(szTrans, sizeof(szTrans), "(SELECT @curRank := 0);");
			transaction.AddQuery(szTrans);

			g_hDatabase.Format(szTrans, sizeof(szTrans), "update maprecs SET `rank` = (@curRank := @curRank + 1) WHERE map = '%s' AND run = %i AND mode = %i ORDER BY time ASC;", g_szCurrentMap, run, mode );
			transaction.AddQuery(szTrans);

			g_hDatabase.Format(szTrans, sizeof(szTrans), "(SELECT @curClassRank := 0);");
			transaction.AddQuery(szTrans);

			g_hDatabase.Format(szTrans, sizeof(szTrans), "UPDATE "...TABLE_PLYDATA..." SET %s = (@curClassRank := @curClassRank + 1) where %s > 0.0 ORDER BY %s DESC;", (style == STYLE_SOLLY) ? "srank" : "drank", (style == STYLE_SOLLY) ? "solly" : "demo" , (style == STYLE_SOLLY) ? "solly" : "demo" );
			transaction.AddQuery(szTrans);

			g_hDatabase.Format(szTrans, sizeof(szTrans), "(SELECT @curOverRank := 0);");
			transaction.AddQuery(szTrans);

			g_hDatabase.Format(szTrans, sizeof(szTrans), "UPDATE "...TABLE_PLYDATA..." SET orank = (@curOverRank := @curOverRank + 1) where solly > 0.0 or demo > 0.0 ORDER BY overall DESC;" );
			transaction.AddQuery(szTrans);

			if (rank == 1 && outof > 1)
			{
				g_hDatabase.Format(szTrans, sizeof(szTrans), "UPDATE "...TABLE_RECORDS..." SET beaten = 1 WHERE `rank` = 2 AND map = '%s' AND run = %i AND mode = %i", g_szCurrentMap, run, mode);
				
				transaction.AddQuery(szTrans);
			}

			int cycle = (outof >= 10) ? 10 : outof;
			for (int i = 1; i <= cycle; i++)
			{
				g_hDatabase.Format(szTrans, sizeof(szTrans), "UPDATE "...TABLE_RECORDS..." SET pts = ((SELECT r%i from points where tier = %i and run = '%s') + %.1f) WHERE %i <= %i AND %i <= 10 AND `rank` = %i AND map = '%s' AND run = %i AND mode = %i", i, g_Tiers[run][mode], db_run, points, i, outof, i, i, g_szCurrentMap, run, mode);
				
				transaction.AddQuery(szTrans);
			}

			SQL_ExecuteTransaction(g_hDatabase, transaction, _, OnTxnFail);

			DB_RetrieveClientData( client );
		}
	}
	delete hData;
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
			FormatEx(szCourses, sizeof(szCourses)," {white}| \x0750DCFF%i {white}courses", courses);
		}
		if (bonuses > 0)
		{
			FormatEx(szBonuses, sizeof(szBonuses)," {white}| \x0750DCFF%i {white}bonuses", bonuses);
		}

		FormatEx(szInfo, sizeof(szInfo), ""...CHAT_PREFIX..."\x0750DCFF%s \x07FFFFFFtiers", map);
		FormatEx(szInfo2, sizeof(szInfo2), ""...CHAT_PREFIX..."\x07FFFFFFSolly \x0750DCFFT%i \x07FFFFFF| Demo \x0750DCFFT%i%s%s", stier, dtier, szCourses, szBonuses);

		CPrintToChatAll(szInfo);
		CPrintToChatAll(szInfo2);
	}
	else
	{
		PrintToChatAll(CHAT_PREFIX..."No match found");
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

public void Threaded_OnAddRecordDone( Database hOwner, DBResultSet hQuery, const char[] szError, ArrayList hData )
{
	int client;
	if ( (client = GetClientOfUserId( hData.Get( 0, 0 ) )) )
	{
		if ( !(StrEqual( szError, "")) )
		{
			DB_LogError( "Unable to add record!" );
			
			return;
		}
		else
		{
			int run = hData.Get( 0, 1 );
			int style = hData.Get( 0, 2 );
			int mode = hData.Get( 0, 3 );
			DB_DisplayClientRank( client, run, style, mode );
		}
	}
	delete hData;
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
	char Query[100];
	float vecMaxs[3];
	int zone;
	int iData[ZONE_SIZE];
	int index;
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
	PrintToChatAll(CHAT_PREFIX..."Loaded \x0750DCFF%i zone(s)", zones );
	
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
				FormatEx( szQuery, sizeof( szQuery ), "SELECT uid, run, style, mode, time, name FROM maprecs natural join plydata WHERE map = '%s' and run = %i and mode = %i order by time asc", g_szCurrentMap, i, b );
				
				g_hDatabase.Query( Threaded_Init_Records, szQuery, _, DBPrio_Normal );
			}
		}

		g_hDatabase.Format(szQuery, sizeof(szQuery), "SELECT run, stier, dtier, solly, demo FROM "...TABLE_MAPINFO..." WHERE map_name = '%s'", g_szCurrentMap);
		g_hDatabase.Query( Threaded_Init_Tiers, szQuery, _, DBPrio_High );		
		
		g_hDatabase.Format(szQuery, sizeof(szQuery), "SELECT level, pos0, pos1, pos2, ang0, ang1, ang2 FROM levels WHERE map = '%s'", g_szCurrentMap);
		g_hDatabase.Query( Threaded_Init_Levels, szQuery, _, DBPrio_High );
		
		g_hDatabase.Format( szQuery, sizeof( szQuery ), "SELECT run, id, min0, min1, min2, max0, max1, max2 FROM "...TABLE_CP..." WHERE map = '%s'", g_szCurrentMap );
		// SELECT run, id, min0, min1, min2, max0, max1, max2, rec_time FROM mapcprecs NATURAL JOIN mapcps WHERE map = 'bhop_gottagofast' ORDER BY run, id
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
	g_hDatabase.Format( szQuery, sizeof( szQuery ), "SELECT uid, run, id, mode, time, map FROM mapcprecs WHERE uid = (select maprecs.uid from maprecs where maprecs.map = '%s' and maprecs.run = mapcprecs.run and maprecs.mode = mapcprecs.mode order by maprecs.time ASC limit 1) and map = '%s' group by map, run, mode, id ORDER BY time ASC", g_szCurrentMap, g_szCurrentMap );
	
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
		PRINTCHAT( client, CHAT_PREFIX..."Record was succesfully deleted!" );
	}
}

public void Threaded_DeleteCpRecord( Database hOwner, DBResultSet hQuery, const char[] szError, int client )
{
	if ( hQuery == null )
	{	
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