/*
CREATE TABLE IF NOT EXISTS tempbounds (map VARCHAR(32), zone INT, id INT, min0 REAL, min1 REAL, min2 REAL, max0 REAL, max1 REAL, max2 REAL, flags INT, PRIMARY KEY(map, zone, id))

INSERT INTO mapbounds (map, zone, id, min0, min1, min2, max0, max1, max2) SELECT 'bhop_name', zone, id, min0, min1, min2, max0, max1, max2 FROM bhop_name
INSERT INTO maprecs (map, steamid, run, style, name, time, jumps, strafes) SELECT 'bhop_name', steamid, run, style, name, time, jumps, strafes FROM rec_bhop_name
*/
#define DB_NAME				 "opentimer"
#define TABLE_PLYDATA		 "plydata"
#define TABLE_MAPINFO		 "map_info"
#define TABLE_RECORDS		 "maprecs"
#define TABLE_ZONES			 "mapbounds"
#define TABLE_CP			 "mapcps"
#define TABLE_CP_RECORDS	 "mapcprecs" // Save record checkpoint times only.
#define TABLE_PLYCHEAT		 "plycheatdata"

Database g_hDatabase;

// Includes all the threaded SQL callbacks.


stock bool GetClientSteam( int client, char[] szSteam, int len )
{
	if ( !GetClientAuthId( client, AuthId_Steam3, szSteam, len ) )
	{
		LogError( CONSOLE_PREFIX..."Couldn't retrieve player's \"%N\" Steam Id!", client );
		return false;
	}
	
	return true;
}

stock void DB_LogError( const char[] szMsg, int client = 0, const char[] szClientMsg = "" )
{
	char szError[100];
	SQL_GetError( g_hDatabase, szError, sizeof( szError ) );
	LogError( CONSOLE_PREFIX..."Error: %s (%s)", szError, szMsg );
	
	if ( client && IsClientInGame( client ) )
	{
		if ( szClientMsg[0] != '\0' )
		{
			PRINTCHAT( client, CHAT_PREFIX..."%s", szClientMsg );
		}
		else
		{
			PRINTCHAT( client, CHAT_PREFIX..."Sorry, something went wrong." );
		}
	}
}


// Initialize soundsounds so important. I'm so cool.
// Create connection with database!
stock void DB_InitializeDatabase()
{
	char szError[100];
	
	if (!SQL_CheckConfig("Timer"))
    {
        SetFailState("Секция \"Timer\" не найдена в databases.cfg");
        return;
    }

    g_hDatabase = SQL_Connect("Timer", true, szError, 100);

    // тип соединения (mysql или sqlite)

	g_hDatabase.SetCharset("utf8");
	
	if ( g_hDatabase == null )
		SetFailState( CONSOLE_PREFIX..."Unable to establish connection to the database! Error: %s", szError );
	
	
	PrintToServer( CONSOLE_PREFIX..."Established connection with database!" );
	
	
	// NOTE: Primary key cannot be 'INT'.
	/*
	g_hDatabase.Query( Threaded_Empty,
		"CREATE TABLE IF NOT EXISTS plydata (
		  uid int(11) NOT NULL,
		  steamid varchar(64) NOT NULL,
		  name varchar(32) NOT NULL DEFAULT 'N/A',
		  hideflags int(11) NOT NULL DEFAULT '0',
		  prefstyle int(11) NOT NULL DEFAULT '0',
		  prefmode int(11) NOT NULL DEFAULT '0',
		  finishes int(11) NOT NULL DEFAULT '0',
		  records int(11) NOT NULL DEFAULT '0',
		  overall double NOT NULL DEFAULT '0',
		  solly double NOT NULL DEFAULT '0',
		  demo double NOT NULL DEFAULT '0',
		  lastseen varchar(30) DEFAULT NULL,
		  firstseen varchar(30) DEFAULT NULL,
		  country varchar(99) NOT NULL DEFAULT 'None',
		  link varchar(130) NOT NULL DEFAULT 'None',
		  srank int(11) DEFAULT '0',
		  drank int(11) DEFAULT '0',
		  orank int(11) DEFAULT '0',
		  ip varchar(30) DEFAULT NULL
		)");
	
	g_hDatabase.Query( Threaded_Empty,
		"CREATE TABLE IF NOT EXISTS `map_info` (
		  `map_name` varchar(32) NOT NULL DEFAULT 'gay',
		  `run` int(11) NOT NULL,
		  `stier` int(11) NOT NULL,
		  `dtier` int(11) NOT NULL,
		  `solly` int(11) NOT NULL,
		  `demo` int(11) NOT NULL
		)");
	
	g_hDatabase.Query( Threaded_Empty,
		"CREATE TABLE IF NOT EXISTS `mapbounds` (
		  `map` varchar(32) NOT NULL,
		  `zone` int(11) NOT NULL,
		  `id` int(11) NOT NULL DEFAULT '0',
		  `min0` double NOT NULL,
		  `min1` double NOT NULL,
		  `min2` double NOT NULL,
		  `max0` double NOT NULL,
		  `max1` double NOT NULL,
		  `max2` double NOT NULL,
		  `flags` int(11) NOT NULL DEFAULT '0'
		)");
	
	g_hDatabase.Query( Threaded_Empty,
		"CREATE TABLE IF NOT EXISTS `maprecs` (
		`recordid` int(11) NOT NULL,
		`map` varchar(40) NOT NULL,
		`uid` int(11) DEFAULT NULL,
		`run` int(11) DEFAULT NULL,
		`style` int(11) DEFAULT NULL,
		`mode` int(11) DEFAULT NULL,
		`time` double DEFAULT NULL,
		`pts` double DEFAULT NULL,
		`date` varchar(30) DEFAULT NULL,
		`rank` int(11) DEFAULT NULL,
		`allranks` int(11) DEFAULT NULL,
		`demourl` char(255) DEFAULT NULL,
		`start_tick` int(11) DEFAULT NULL,
		`end_tick` int(11) DEFAULT NULL
		)");
	
	g_hDatabase.Query( Threaded_Empty,
		"CREATE TABLE IF NOT EXISTS `mapcps` (
		  `map` varchar(32) NOT NULL,
		  `id` int(11) NOT NULL,
		  `run` int(11) NOT NULL,
		  `min0` double NOT NULL,
		  `min1` double NOT NULL,
		  `min2` double NOT NULL,
		  `max0` double NOT NULL,
		  `max1` double NOT NULL,
		  `max2` double NOT NULL
		)" );
	
	g_hDatabase.Query( Threaded_Empty,
		"CREATE TABLE IF NOT EXISTS `mapcprecs` (
		  `map` varchar(32) NOT NULL,
		  `id` int(11) NOT NULL,
		  `run` int(11) NOT NULL,
		  `style` int(11) NOT NULL,
		  `mode` int(11) NOT NULL,
		  `uid` int(11) NOT NULL,
		  `time` double NOT NULL
		)");

	g_hDatabase.Query( Threaded_Empty, 
		"CREATE TABLE IF NOT EXISTS `startpos` (
		  `map` varchar(50) NOT NULL,
		  `run` int(11) NOT NULL,
		  `pos0` double NOT NULL,
		  `pos1` double NOT NULL,
		  `pos2` double NOT NULL,
		  `ang0` double NOT NULL,
		  `ang1` double NOT NULL,
		  `ang2` double NOT NULL
		)");
		*/
}

// Get map zones, mimics and vote-able maps
stock void DB_InitializeMap()
{
	// ZONES
	char szQuery[192];
	g_hDatabase.Format( szQuery, sizeof( szQuery ), "SELECT zone, min0, min1, min2, max0, max1, max2, id, number FROM "...TABLE_ZONES..." WHERE map = '%s'", g_szCurrentMap );
	
	g_hDatabase.Query( Threaded_Init_Zones, szQuery );
}

// Print server times to client. This can be done to console or to a menu.
// Client can also request individual modes.
stock void DB_PrintRecords0( int client, int iRun = RUN_MAIN, int iMode = MODE_SOLDIER)
{
	Panel hPanel = new Panel();
	hPanel.DrawText( "..." );
	
	hPanel.Send( client, Handler_Empty, MENU_TIME_FOREVER );
	static char szQuery[512];

	Format( szQuery, sizeof( szQuery ),  "SELECT map, time FROM "...TABLE_RECORDS..." WHERE map = '%s' AND run = %i AND mode = %i ORDER BY time ASC", db_map[client], iRun, iMode );		
	
	int iData[3];
	iData[0] = GetClientUserId( client );
	iData[1] = iRun;
	iData[2] = iMode;
	
	ArrayList hData = new ArrayList( sizeof( iData ) );
	hData.PushArray( iData, sizeof( iData ) );
	
	g_hDatabase.Query( DB_PrintRecords, szQuery, hData, DBPrio_Normal );
	delete hPanel;
	
}

public void DB_PrintRecords( Database hOwner, DBResultSet hQuery, const char[] szError, ArrayList hData )
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
		Panel hPanel = new Panel();
		hPanel.DrawText( "..." );
		
		hPanel.Send( client, Handler_Empty, MENU_TIME_FOREVER );
		static char szQuery[512];
		int iRun = hData.Get( 0, 1 );
		int iMode = hData.Get( 0, 2 );
		if ( hQuery.RowCount )
		{
			hQuery.FetchRow();
			hQuery.FetchString( 0, db_map[client], sizeof( db_map ) );
			db_time[client] = hQuery.FetchFloat( 1);
		}
		Format( szQuery, sizeof( szQuery ),  "SELECT recordid, map, style, mode, time, name  FROM "...TABLE_RECORDS..." NATURAL JOIN "...TABLE_PLYDATA..." WHERE map = '%s' AND run = %i AND mode = %i ORDER BY time ASC LIMIT 100", db_map[client], iRun, iMode );
		
		int iData[3];
		iData[0] = GetClientUserId( client );
		iData[1] = iRun;
		iData[2] = iMode;

		delete hPanel;
		ArrayList hData = new ArrayList( sizeof( iData ) );
		hData.PushArray( iData, sizeof( iData ) );
		
		g_hDatabase.Query( Threaded_PrintRecords, szQuery, hData, DBPrio_Normal );	
	}
}

stock void DB_PrintPoints( int client, int args, int top )
{
	static char szQuery[512];

	static char szTop[32];
	if (top == 0)
	{
		Format( szTop, sizeof( szTop ), "");
	}
	if (top == 1)
	{
		Format( szTop, sizeof( szTop ), "AND mode = 3");
	}
	if (top == 2)
	{
		Format( szTop, sizeof( szTop ), "AND mode = 1");
	}
	
	Format( szQuery, sizeof( szQuery ),  "SELECT uid, name, (select sum(pts) from maprecs where uid = plydata.uid %s) FROM "...TABLE_PLYDATA..." ORDER BY (select sum(pts) from maprecs where uid = plydata.uid %s) DESC LIMIT 100", szTop, szTop);
	
	int iData[3];
	iData[0] = GetClientUserId( client );
	iData[1] = top;
	
	ArrayList hData = new ArrayList( sizeof( iData ) );
	hData.PushArray( iData, sizeof( iData ) );
	
	
	g_hDatabase.Query(Threaded_PrintRecordsPoints, szQuery, hData, DBPrio_Normal );
}

stock void DB_Profile( int client, int args, int how, char[] Name, int id, int mode = MODE_SOLDIER )
{
	static char szQuery[4000];

	Panel hPanel = new Panel();
	hPanel.DrawText( "..." );
	
	hPanel.Send( client, Handler_Empty, 5 );

	Transaction profile = new Transaction();

	g_hDatabase.Format( szQuery, sizeof( szQuery ),  "(SELECT SUM(pts) FROM maprecs WHERE uid = (@dbuid)), \
		(SELECT SUM(pts) FROM maprecs WHERE uid = (@dbuid) and mode = %i), \
		(SELECT SUM(pts) FROM maprecs WHERE uid = (@dbuid) AND `rank` = 1 and mode = %i), \
		(SELECT SUM(pts) FROM maprecs WHERE uid = (@dbuid) AND `rank` > 1 AND `rank` < 11 and mode = %i), \
		(SELECT COUNT(overall) FROM plydata WHERE overall > 0.1), \
		(SELECT COUNT(%s) FROM plydata WHERE %s > 0.1), \
		(SELECT COUNT(map) FROM maprecs WHERE uid = (@dbuid) AND mode = %i and run = 0), \
		(SELECT COUNT(map) FROM mapbounds WHERE (zone = 0 or zone = 2) and number = 0 and (select %s from map_info where map_name = mapbounds.map and run = 0) > 0)", mode, mode, mode, (mode == MODE_SOLDIER) ? "solly" : "demo", (mode == MODE_SOLDIER) ? "solly" : "demo", mode, (mode == MODE_SOLDIER) ? "stier" : "dtier" );

	if ( how == 1 )
	{
		g_hDatabase.Format( szQuery, sizeof( szQuery ),  "SELECT name, uid, orank, %s, online, (SELECT @dbuid := uid), %s, (SELECT %i limit 1) FROM plydata WHERE name LIKE '%s%%'", (mode == MODE_SOLDIER) ? "srank" : "drank", szQuery, mode, Name );
	}
	else
	{
		g_hDatabase.Format( szQuery, sizeof( szQuery ),  "SELECT name, uid, orank, %s, online, (SELECT @dbuid := uid), %s, (SELECT %i limit 1) FROM plydata WHERE uid = %i", (mode == MODE_SOLDIER) ? "srank" : "drank", szQuery, mode, id );
	}

	profile.AddQuery(szQuery);
	SQL_ExecuteTransaction(g_hDatabase, profile, OnProfileTxnSuccess, OnProfileTxnError, client);
	delete hPanel;
}

public void OnProfileTxnSuccess(Database g_hDatabase, any client, int numQueries, DBResultSet[] results, any[] queryData)
{
	if (client <= 0) return;

	if ( results[0] == DBVal_Error || results[0] == DBVal_Null || results[0] == DBVal_TypeMismatch || results[0] == null ) 
	{
		char error[200];

		if (SQL_GetError(g_hDatabase, error, sizeof(error)))
		{
			DB_LogError( error );
		}

		return;
	}

	float overall_pts,
		class_pts,
		wr_points,
		tt_points,
		completions_procent;

	int overall_rank,
		class,
		class_rank,
		overall_ranks,
		class_ranks,
		completed_maps,
		maps_count,
		prefix = '%',
		IsOnline = 0;

	char szItem[64],
		szItem2[64],
		szItem3[64],
		szItem4[64],
		szItem5[64],
		szItem6[64],
		szItem7[64],
		szItem8[64],
		szTxt1[32],
		szTxt2[32],
		szTxt3[32],
		title[100];

	if (results[0].FetchRow())
	{
		Menu mMenu;
		mMenu = new Menu(Handler_Prifile);

		results[0].FetchString( 0, DBS_Name[client], sizeof( DBS_Name ) );
		db_id[client] = results[0].FetchInt( 1 );
		overall_rank = results[0].FetchInt( 2 );
		class_rank = results[0].FetchInt( 3 );
		IsOnline = results[0].FetchInt( 4 );
		overall_pts = results[0].FetchFloat( 6 );
		class_pts = results[0].FetchFloat( 7 );
		wr_points = results[0].FetchFloat( 8 );
		tt_points = results[0].FetchFloat( 9 );
		overall_ranks = results[0].FetchInt( 10 );
		class_ranks = results[0].FetchInt( 11 );
		completed_maps = results[0].FetchInt( 12 );
		maps_count = results[0].FetchInt( 13 );
		class = results[0].FetchInt( 14 );

		profile_mode[client] = class;

		completions_procent = (float(completed_maps) / float(maps_count)) * 100.0;

		if ( overall_pts <= 0.0 )
		{
			FormatEx(szTxt3, sizeof( szTxt3 ), "[Overall N/A]\n ");
		}
		else
		{
			FormatEx(szTxt3, sizeof( szTxt3 ), "%i/%i [%.0f pts]\n ", overall_rank, overall_ranks, overall_pts);
		}
		
		if ( class_pts <= 0.0 )
		{
			FormatEx(szTxt1, sizeof( szTxt1 ), "[%s N/A]\n ", g_szModeName[NAME_LONG][class]);
		}
		else
		{
			FormatEx(szTxt1, sizeof( szTxt1 ), "%i/%i [%.0f pts]\n ", class_rank, class_ranks, class_pts);
		}

		FormatEx( szItem, sizeof( szItem ), "Overall rank: %s", szTxt3 );
		mMenu.AddItem( "", szItem );

		FormatEx( szItem3, sizeof( szItem3 ), "%s rank: %s", g_szModeName[NAME_LONG][class], szTxt1 );
		mMenu.AddItem( "", szItem3 );

		FormatEx(szItem6, sizeof(szItem6), "Records [%.0f pts]\n ", wr_points);
		mMenu.AddItem( "", szItem6 );

		FormatEx(szItem7, sizeof(szItem7), "Top Times [%.0f pts]\n ", tt_points);
		mMenu.AddItem( "", szItem7 );

		FormatEx( szItem8, sizeof( szItem8 ), "Completions (%.1f%c ) [%i/%i]\n ", completions_procent, prefix, completed_maps, maps_count );
		mMenu.AddItem( "", szItem8 );

		FormatEx( szItem5, sizeof( szItem5 ), "Details\n \n    ");
		mMenu.AddItem( "", szItem5 );

		FormatEx( szItem4, sizeof( szItem4 ), "[%s]\n \n ", g_szModeName[NAME_LONG][class]);
		mMenu.AddItem( "", szItem4 );

		mMenu.ExitBackButton = (GetLastPrevMenuIndex(client) != -1) ? true : false;

		if (IsOnline==1)
			FormatEx( title, sizeof( title ), "<Profile Menu :: %s>\nPlayer: %s\nOnline now\n ", g_szModeName[NAME_LONG][class], DBS_Name[client] );
		else
			FormatEx( title, sizeof( title ), "<Profile Menu :: %s>\nPlayer: %s\n ", g_szModeName[NAME_LONG][class], DBS_Name[client] );		

		mMenu.SetTitle( title );
		SetNewPrevMenu(client,mMenu);
		mMenu.Display( client, MENU_TIME_FOREVER );
	}
	else
	{
		CPrintToChat(client, CHAT_PREFIX..."Player not found");
	}
	return;
}

public int Handler_Prifile( Menu mMenu, MenuAction action, int client, int item )
{
	if ( action == MenuAction_End ) { return 0; }
	if (action == MenuAction_Cancel) 
	{
		if(item == MenuCancel_ExitBack) 
		{
			RemoveLastPrevMenu(client);
			CallPrevMenu(client);
		    return 0;
		}
	}
	if ( action != MenuAction_Select ) { return 0; }
	int args;
	if (item == 0)
	{
		DB_PrintPoints( client, args, 0 );
	}
	if (item == 1)
	{
		DB_PrintPoints( client, args, (profile_mode[client] == MODE_SOLDIER) ? 2 : 1 );
	}
	if (item == 2)
	{
		DB_RecTimes(client, (profile_mode[client] == MODE_SOLDIER) ? STYLE_SOLLY : STYLE_DEMOMAN);
	}
	if (item == 3)
	{
		DB_TopTimes(client, (profile_mode[client] == MODE_SOLDIER) ? STYLE_SOLLY : STYLE_DEMOMAN);
	}
	if (item == 4)
	{
		DB_Completions(client, db_id[client], 0);
	}
	if ( item == 5 )
	{
		char szQuery[192];
		FormatEx( szQuery, sizeof( szQuery ), "SELECT country, lastseen, firstseen, uid, name, CURRENT_TIMESTAMP FROM "...TABLE_PLYDATA..." WHERE uid = %i", db_id[client] );
		g_hDatabase.Query( Threaded_ProfileInfo, szQuery, GetClientUserId( client ), DBPrio_Normal );
	}
	if ( item == 6 )
	{
		RemoveLastPrevMenu(client);
		DB_Profile( client, 0, 0, "", db_id[client], (profile_mode[client] == MODE_SOLDIER) ? MODE_DEMOMAN : MODE_SOLDIER );
	}
	return 0;
}

public void OnProfileTxnError(Database g_hDatabase, any client, int numQueries, const char[] error, int failIndex, any[] queryData)
{
	if (client > 0)
	{
		CPrintToChat(client, CHAT_PREFIX..."Player not found");
	}
	if (!StrEqual(error, ""))
	{
		PrintToServer(error);
	}
	return;
}
stock void DB_RecordInfo( int client, int id )
{
	Panel hPanel = new Panel();
	hPanel.DrawText( "..." );
	
	static char szQuery[512];
	hPanel.Send( client, Handler_Empty, MENU_TIME_FOREVER );
	FormatEx( szQuery, sizeof( szQuery ),  "SELECT uid, map, run, style, mode, time, pts, date, name, recordid, `rank`, (select `rank` from maprecs where map = record.map and run = record.run and mode = record.mode order by `rank` desc limit 1), server_id FROM "...TABLE_RECORDS..." as record NATURAL JOIN "...TABLE_PLYDATA..." WHERE recordid = %i", id );	
	
	g_hDatabase.Query( Threaded_RecordInfo, szQuery, client, DBPrio_Normal );
	delete hPanel;
}

public void Threaded_RecordInfo( Database hOwner, DBResultSet hQuery, const char[] szError, int client )
{
	if ( hQuery == null )
	{
		DB_LogError( "Couldn't retrieve player's ranking!" );
	
		return;
	}

	if ( hQuery.FetchRow() )
	{
		char map[64];
		char name[32];
		int run, style, mode, uid;
		float pts, time;
		char szTime[TIME_SIZE_DEF];
		char date[50];
		char szId[20];
		char szStyleFix[STYLEPOSTFIX_LENGTH];
		char checkpoints[100];
		GetStylePostfix( g_iClientMode[client], szStyleFix, true );
		hQuery.FetchString( 1, map, sizeof(map));
		hQuery.FetchString( 1, db_map[client], sizeof(db_map));
		hQuery.FetchString( 1, profile_map[client], sizeof(profile_map));
		hQuery.FetchString( 8, name, sizeof(name));
		hQuery.FetchString( 8, profile_playername[client], sizeof(profile_playername));
		run = hQuery.FetchInt( 2 );
		RunPagep[client] = hQuery.FetchInt( 2 );
		profile_run[client] = hQuery.FetchInt( 2 );
		style = hQuery.FetchInt( 3 );
		mode = hQuery.FetchInt( 4 );
		RunClass[client] = hQuery.FetchInt( 4 );
		profile_mode[client] = hQuery.FetchInt( 4 );
		time = hQuery.FetchFloat( 5 );
		pts = hQuery.FetchFloat( 6 );
		hQuery.FetchString( 7, date, sizeof(date));
		uid = hQuery.FetchInt( 0 );
		FormatSeconds( time, szTime, FORMAT_3DECI );
		int rank = hQuery.FetchInt(10);
		int allranks = hQuery.FetchInt(11);
		int s_id = hQuery.FetchInt(12);

		FormatEx(checkpoints, sizeof(checkpoints), "Checkpoint Times (%s)", map);
		DemoInfoId[client] = hQuery.FetchInt(9);

		Panel panel = new Panel();
		char buffer[64];
		db_id[client] = uid;

		DrawPanelText(panel,"<Expanded Record Info>\n ");
		Format(buffer,sizeof(buffer),"Player: %s", name);
		DrawPanelText(panel,buffer);
		Format(buffer,sizeof(buffer),"Zone: %s/%s (%s%s)", map, g_szRunName[NAME_LONG][run], g_szStyleName[NAME_LONG][style], szStyleFix);
		DrawPanelText(panel,buffer);
		DrawPanelText(panel," ");
		Format(buffer,sizeof(buffer),"Duration: %s",szTime);
		DrawPanelText(panel,buffer);
		Format(buffer,sizeof(buffer),"Rank: %i/%i", rank, allranks);
		DrawPanelText(panel,buffer);
		Format(buffer,sizeof(buffer),"Points Gained: %.1f", pts);
		DrawPanelText(panel,buffer);
		Format(buffer,sizeof(buffer),"Date: %s (Moscow)", date);
		DrawPanelText(panel,buffer);
		Format(buffer,sizeof(buffer),"Server: %s", server_name[NAME_LONG][s_id] );
		DrawPanelText(panel,buffer);

		DrawPanelText(panel," ");
		DrawPanelItem(panel,"Open Player Menu");
		if (run == 0)
		{
			DrawPanelItem(panel, checkpoints);
		}
		panel.CurrentKey = 3;
		DrawPanelItem(panel, "Find Demo");
		DrawPanelText(panel," ");

		if (GetUserFlagBits(client) & ADMFLAG_ROOT)
		{
			panel.CurrentKey = 4;
			DrawPanelItem(panel, "Remove Record");
			DrawPanelText(panel," ");
		}

		panel.CurrentKey = 8;
		DrawPanelItem(panel,"[<<]");
		DrawPanelText(panel," ");
		panel.CurrentKey = 10;
		DrawPanelItem(panel,"[X]");

		Func = DB_RecordInfo;

		SendPanelToClient(panel, client, record_control, MENU_TIME_FOREVER);
	}
}

public int record_control(Menu mMenu, MenuAction action, int client, int item) {
	if (action == MenuAction_Select) {
		if(item == 1) {
			//Display player info
			DB_Profile( client, 0, 0, "name", db_id[client] );
		}
		if(item == 2) {
			//Display checks info
			CheckpointTimes( client, db_id[client], profile_map[client], profile_mode[client] );
		}
		else if(item == 3) {
			//Back to top times
			DemoInfo(client, DemoInfoId[client] );
		}
		else if(item == 4) {
			Menu mMenu = new Menu( Handler_RunRecordsDelete2_Confirmation );
			mMenu.SetTitle( "Are you sure?\n ");
			mMenu.AddItem( "", "Yes" );
			mMenu.AddItem( "", "No" );
			
			mMenu.ExitButton = false;
			mMenu.Display( client, MENU_TIME_FOREVER );

		}
		else if(item == 8) {
			CallPrevMenu(client);
		}
	}
}

public int Handler_RunRecordsDelete2_Confirmation( Menu mMenu, MenuAction action, int iclient, int index )
{
	if ( action == MenuAction_End ) { delete mMenu; return 0; }
	if ( action != MenuAction_Select ) { return 0; }	
				
	if ( index != 0 ) {DB_RecordInfo(iclient, DemoInfoId[iclient]); return 0; }

	DB_DeleteRecord( iclient, profile_run[iclient], profile_mode[iclient], db_id[iclient], profile_map[iclient] );
}

public void DemoInfo(int client, int id)
{
	Panel hPanel = new Panel();
	hPanel.DrawText( "..." );
	
	static char szQuery[512];
	hPanel.Send( client, Handler_Empty, MENU_TIME_FOREVER );
	Format( szQuery, sizeof( szQuery ),  "SELECT demourl, start_tick, end_tick, server_id, demo_status FROM "...TABLE_RECORDS..." WHERE recordid = %i", id );	
	
	g_hDatabase.Query( Threaded_DemoInfo, szQuery, client, DBPrio_Normal );
	delete hPanel;
}

int server_id_database[MAXPLAYERS+1];

public void Threaded_DemoInfo( Database hOwner, DBResultSet hQuery, const char[] szError, int client )
{
	if ( hQuery == null )
	{
		DB_LogError( "Couldn't retrieve player's ranking!" );
	
		return;
	}

	// Has anybody even beaten the map in the first place?
	if ( hQuery.FetchRow() )
	{
		hQuery.FetchString( 0, DemoUrlClient[client], sizeof(DemoUrlClient));
		int start = hQuery.FetchInt( 1 );
		int end = hQuery.FetchInt( 2 );
		server_id_database[client] = hQuery.FetchInt( 3 );
		int demo = hQuery.FetchInt( 4 );
		bool not_exist = false;
		Panel panel = new Panel();
		char buffer[64], status[50], path[PLATFORM_MAX_PATH];

		BuildPath(Path_SM, path, sizeof(path), "recordings/bz2/%s", DemoUrlClient[client]);

		if (StrEqual(DemoUrlClient[client], ""))
		{
			not_exist = true;
			FormatEx(status, sizeof(status), "Not exist");
		}
		else
		{
			FormatEx(status, sizeof(status), "%s", g_szDemoStatus[demo]);
		}

		DrawPanelText(panel,"<Demo Info>");

		if (!not_exist)
		{
			Format(buffer,sizeof(buffer),"Demo: %s", DemoUrlClient[client]);
			DrawPanelText(panel,buffer);
		}
		Format(buffer,sizeof(buffer),"Server: %s", server_name[NAME_LONG][server_id_database[client]]);
		DrawPanelText(panel,buffer);
		if (!not_exist)
		{
			Format(buffer,sizeof(buffer),"Start tick: %i", start);
			DrawPanelText(panel,buffer);
			Format(buffer,sizeof(buffer),"End tick: %i", end);
			DrawPanelText(panel,buffer);
		}

		Format(buffer,sizeof(buffer)," (Go to %s for Upload the demo)", server_name[NAME_SHORT][server_id_database[client]]);
		Format(buffer,sizeof(buffer),"Status: %s%s", status, (server_id_database[client] != server_id && !not_exist && (demo == DEMO_READY || demo == DEMO_ERROR)) ? buffer : "" );
		DrawPanelText(panel,buffer);

		DrawPanelText(panel," ");
		if (demo == DEMO_UPLOADED)
		{
			DrawPanelItem(panel,"Print link");
		}
		else if (demo == DEMO_UPLOADING || demo == DEMO_RECORDING)
		{
			panel.CurrentKey = 2;
			DrawPanelItem(panel,"Refresh");
			DrawPanelText(panel," ");
		}
		else if (demo == DEMO_READY && FileExists(path))
		{
			panel.CurrentKey = 3;
			DrawPanelItem(panel,"Upload demo");

			DrawPanelText(panel," ");

			panel.CurrentKey = 5;
			DrawPanelItem(panel,"Delete demo\n ");
		}
		char demosz[150];
		strcopy(demosz, sizeof(demosz), DemoUrlClient[client]);
		ReplaceString(demosz, sizeof(demosz), ".bz2", "");

		if (!StrEqual(currentDemoFilename, demosz) && (demo == DEMO_RECORDING || demo == DEMO_ERROR)  && server_id_database[client] == server_id)
		{
			panel.CurrentKey = 4;
			char way[PLATFORM_MAX_PATH];
			BuildPath(Path_SM, way, sizeof(way), "recordings/%s", demosz);
			if (FileExists(way))
				DrawPanelItem(panel,"Retry Upload");
			else{
				BuildPath(Path_SM, way, sizeof(way), "recordings/bz2/%s.bz2", demosz);
				if (FileExists(way))
				{
					panel.CurrentKey = 6;
					DrawPanelItem(panel,"Retry Upload");
				}
				else
				{
					DrawPanelItem(panel,"Retry Upload (File does not exist)", ITEMDRAW_DISABLED);
				}
			}
				
			DrawPanelText(panel," ");
		}

		panel.CurrentKey = 8;
		DrawPanelItem(panel,"[<<]");
		DrawPanelText(panel," ");
		panel.CurrentKey = 10;
		DrawPanelItem(panel,"[X]");

		SendPanelToClient(panel, client, demo_control, MENU_TIME_FOREVER);
	}
}

public int demo_control(Menu mMenu, MenuAction action, int client, int item) {
	if (action == MenuAction_Select) {
		char query[900];
		if(item == 1) {
			char link[256];
			FormatEx(link, sizeof(link), DemoUrlClient[client]);
			ReplaceString(link, sizeof(link), "\\", "%5c");
			CPrintToChat(client, CHAT_PREFIX..."\n{orange}game339233.ourserver.ru/demos/server_%i/%s", server_id_database[client], link);
			DemoInfo(client, DemoInfoId[client] );
			return 0;
		}
		else if (item == 2)
		{
			DemoInfo(client, DemoInfoId[client] );
			return 0;
		}
		else if (item == 3)
		{
			char path[PLATFORM_MAX_PATH];
			BuildPath(Path_SM, path, sizeof(path), "recordings/bz2/%s", DemoUrlClient[client]);
			CPrintToChat(client, CHAT_PREFIX..."Uploading %s...", DemoUrlClient[client]);
			g_hDatabase.Format(query, sizeof(query), "UPDATE maprecs SET demo_status = %i WHERE demourl = '%s'", DEMO_UPLOADING, DemoUrlClient[client]);
			EasyFTP_UploadFile("demos", path, "/", EasyFTP_CallBack);
		}
		else if (item == 4)
		{
			char demosz[150];
			strcopy(demosz, sizeof(demosz), DemoUrlClient[client]);
			ReplaceString(demosz, sizeof(demosz), ".bz2", "");
			requestedByMenu = true;
			Handle pack = CreateDataPack();
			WritePackString(pack, demosz);
			CreateTimer(0.5, Timer_CompressDemo, pack);
			CPrintToChat(client, CHAT_PREFIX..."Compression %s...", DemoUrlClient[client]);
			g_hDatabase.Format(query, sizeof(query), "UPDATE maprecs SET demo_status = %i WHERE demourl = '%s'", DEMO_UPLOADING, DemoUrlClient[client]);
		}
		else if (item == 5)
		{
			char path[PLATFORM_MAX_PATH];
			BuildPath(Path_SM, path, sizeof(path), "recordings/bz2/%s", DemoUrlClient[client]);
			CPrintToChat(client, CHAT_PREFIX..."Deleting %s...", DemoUrlClient[client]);

			if (DeleteFile(path))
			{
				CPrintToChat(client, CHAT_PREFIX..."\x0750DCFFSuccess. {white}Demo {red}Deleted{white}!");
				g_hDatabase.Format(query, sizeof(query), "UPDATE maprecs SET demo_status = %i WHERE demourl = '%s'", DEMO_DELETED, DemoUrlClient[client]);
			}
			else
			{
				CPrintToChat(client, CHAT_PREFIX..."{red}ERROR. {white}Demo deletion failed");
				DemoInfo(client, DemoInfoId[client] );
				return 0;
			}
		}
		else if (item == 6)
		{
			char path[PLATFORM_MAX_PATH];
			BuildPath(Path_SM, path, sizeof(path), "recordings/bz2/%s", DemoUrlClient[client]);
			CPrintToChat(client, CHAT_PREFIX..."Uploading %s...", DemoUrlClient[client]);
			g_hDatabase.Format(query, sizeof(query), "UPDATE maprecs SET demo_status = %i WHERE demourl = '%s'", DEMO_UPLOADING, DemoUrlClient[client]);
			EasyFTP_UploadFile("demos", path, "/", EasyFTP_CallBack);
		}
		else if(item == 8) {
			Call_StartFunction(INVALID_HANDLE, Func);
		    Call_PushCell(client);
		    Call_PushCell(DemoInfoId[client]);

		    Call_Finish();
			return 0;
		}
		if (item != 10) {
			SQL_TQuery(g_hDatabase, Threaded_Empty, query, client);
			DemoInfo(client, DemoInfoId[client] );
		}
	}
}

stock void DB_Admin_Records_DeleteMenu( int client, int run )
{
	// For deletion menu.
	
	char szQuery[300];
	FormatEx( szQuery, sizeof( szQuery ), "SELECT style, mode, uid, time, name, map FROM "...TABLE_RECORDS..." NATURAL JOIN "...TABLE_PLYDATA..." WHERE map = '%s' AND run = %i ORDER BY date DESC", g_szCurrentMap, run );
	
	int iData[2];
	iData[0] = GetClientUserId( client );
	iData[1] = run;
	
	ArrayList hData = new ArrayList( sizeof( iData ) );
	hData.PushArray( iData, sizeof( iData ) );
	
	g_hDatabase.Query( Threaded_Admin_Records_DeleteMenu, szQuery, hData, DBPrio_Normal );
}

stock void DB_Admin_CPRecords_DeleteMenu( int client, int run )
{
	// For deletion menu.
	
	char szQuery[300];
	FormatEx( szQuery, sizeof( szQuery ), "SELECT id, style, mode, time FROM "...TABLE_CP_RECORDS..." WHERE map = '%s' AND run = %i ORDER BY id AND style ASC", g_szCurrentMap, run );
	
	int iData[2];
	iData[0] = GetClientUserId( client );
	iData[1] = run;
	
	ArrayList hData = new ArrayList( sizeof( iData ) );
	hData.PushArray( iData, sizeof( iData ) );
	
	g_hDatabase.Query( Threaded_Admin_CPRecords_DeleteMenu, szQuery, hData, DBPrio_Normal );
}

stock void DB_DisplayClientRank( int client, int run = RUN_MAIN, int style = STYLE_SOLLY, int mode = MODE_INVALID )
{
	if ( g_flClientBestTime[client][run][mode] <= TIME_INVALID ) return;
	
	Transaction t = new Transaction();

	char szQuery[162];

	g_hDatabase.Format( szQuery, sizeof( szQuery ), "SELECT COUNT(*) FROM "...TABLE_RECORDS..." WHERE map = '%s' AND run = %i AND mode = %i",
		g_szCurrentMap,
		run,
		mode );

	t.AddQuery(szQuery);

	g_hDatabase.Format( szQuery, sizeof( szQuery ), "SELECT `rank` FROM "...TABLE_RECORDS..." WHERE map = '%s' AND run = %i AND mode = %i AND uid = %i",
		g_szCurrentMap,
		run,
		mode,
		g_iClientId[client] );

	t.AddQuery(szQuery);

	g_hDatabase.Format( szQuery, sizeof( szQuery ), "SELECT COUNT(*) FROM "...TABLE_RECORDS..." WHERE map = '%s' AND run = %i AND style = %i AND mode = %i AND time < %f",
		g_szCurrentMap,
		run,
		style,
		mode,
		g_flClientBestTime[client][run][mode] );

	t.AddQuery(szQuery);
	
	
	int iData[4];
	iData[0] = GetClientUserId( client );
	iData[1] = run;
	iData[2] = style;
	iData[3] = mode;
	
	ArrayList hData = new ArrayList( sizeof( iData ) );
	hData.PushArray( iData, sizeof( iData ) );

	SQL_ExecuteTransaction(g_hDatabase, t, OnDisplayRankTxnSuccess, OnTxnFail, hData);
}

stock bool DB_SaveClientRecord( int client, float flNewTime )
{
	if ( !g_iClientId[client] || flNewTime <= TIME_INVALID ) return false;
	if ( TF2_GetPlayerClass(client) != TFClass_DemoMan && TF2_GetPlayerClass(client) != TFClass_Soldier || g_iClientRun[client] == RUN_SETSTART ) return false;
	// We save the record if needed and print a notification to the chat.
	static int run;
	static int style;
	static int mode;
	static float flOldBestTime;
		
	run = g_iClientRun[client];
	style = g_iClientStyle[client];
	mode = getClass(client);

	if (run == RUN_MAIN)
	{
		int lenCp = g_hCPs.Length;
		bool missed = false;
		char miss[100];
		int count = 0;

		for (int i = 0; i < lenCp; i++)
		{
			if (!g_iClientCpsEntered[client][i])
			{
				if (count > 0)
					FormatEx(miss, sizeof(miss), "%s, \x0750DCFF%i{white}", miss, i+1);
				else
					FormatEx(miss, sizeof(miss), "\x0750DCFF%i{white}", i+1);

				missed = true;
				count++;
			}
		}
		for (int i = 0; i < 100; i++)
		{
			g_iClientCpsEntered[client][i] = false;
		}

		if (missed)
		{
			CPrintToChat(client, "{red}ERROR {white}| Missed %s checkpoint!", miss );
			EmitSoundToClient( client, g_szSoundsMissCp[0] );
			return false;
		}
	}
	szOldTimePts[client][run][mode] = g_flClientBestTime[client][run][mode];
	flOldBestTime = g_flClientBestTime[client][run][mode];
	static char szQuery[400];
	// First time beating or better time than last time.
	if ( flOldBestTime <= TIME_INVALID || flNewTime < flOldBestTime )
	{		
		// INSERT INTO maprecs VALUES ('bhop_gottagofast', 2, 0, 0, 1, 1337.000, 444, 333)
		char sTime[100];

        FormatTime(sTime, sizeof(sTime), "%Y-%m-%d %H:%M:%S", GetTime() );

		int iData[4];
		iData[0] = GetClientUserId( client );
		iData[1] = run;
		iData[2] = style;
		iData[3] = mode;
		
		ArrayList hData_ = new ArrayList( sizeof( iData ) );
		hData_.PushArray( iData, sizeof( iData ) );

		// Update their best time.
		if ( szOldTimePts[client][run][mode] <= TIME_INVALID )
		{
			FormatEx( szQuery, sizeof( szQuery ), "INSERT INTO "...TABLE_RECORDS..." ( map, uid, run, style, mode, time, date, demourl, start_tick, end_tick, server_id, demo_status) VALUES ('%s', %i, %i, %i, %i, %.16f, CURRENT_TIMESTAMP, '%s', %i, %i, %i, %i)",
			g_szCurrentMap,
			g_iClientId[client],
			run,
			style,
			mode,
			flNewTime,
			DemoUrl,
			( RunIsCourse(run) ) ? (g_flTicks_Cource_Start[client] - 67) : (g_flTicks_Start[client] - 67),
			( RunIsCourse(run) ) ? (g_flTicks_Cource_End[client] - 67) : (g_flTicks_End[client] - 67),
			server_id,
			DEMO_RECORDING );
			
			g_hDatabase.Query(Threaded_OnAddRecordDone, szQuery, hData_, DBPrio_High );
		}
		else
		{
			FormatEx( szQuery, sizeof( szQuery ), "UPDATE "...TABLE_RECORDS..." SET time = %.16f, date = CURRENT_TIMESTAMP, demourl = '%s', start_tick = %i, end_tick = %i, server_id = %i, demo_status = %i WHERE map = '%s' AND uid = %i AND run = %i AND mode = %i",
			flNewTime,
			DemoUrl,
			( RunIsCourse(run) ) ? (g_flTicks_Cource_Start[client] - 67) : (g_flTicks_Start[client] - 67),
			( RunIsCourse(run) ) ? (g_flTicks_Cource_End[client] - 67) : (g_flTicks_End[client] - 67),
			server_id,
			DEMO_RECORDING,
			g_szCurrentMap,
			g_iClientId[client],
			run,
			mode);
			g_hDatabase.Query(Threaded_OnAddRecordDone, szQuery, hData_, DBPrio_High );
		}
		g_flClientBestTime[client][run][mode] = flNewTime;
		szOldTime[client] = flOldBestTime;
	}
	static float flPrevMapBest;
	flPrevMapBest = g_flMapBestTime[run][style][mode];
	szOldTimeWr = flPrevMapBest;
	
	static char szName[32];
	GetClientName( client, szName, sizeof( szName ) );
	
	// Is best?
	if ( flPrevMapBest <= TIME_INVALID || flNewTime < flPrevMapBest )
	{
		g_flMapBestTime[run][style][mode] = g_flClientBestTime[client][run][mode];
		FormatEx( szWrName[run][mode], sizeof(szWrName), "%s", szName);
	}

	if ( g_hCPs != null && run == RUN_MAIN )
	{
		if ( flOldBestTime <= TIME_INVALID || flNewTime < flOldBestTime )
		{
			// Save checkpoint time differences.
			int len = g_hClientCPData[client].Length;
			
			int prev;

			for ( int i = 0; i < len; i++ )
			{
				prev = i - 1;
				
				static int iData[C_CP_SIZE];
				
				static float flPrevTime;
				if ( prev < 0 )
				{
					flPrevTime = g_flClientStartTime[client];
				}
				else
				{
					g_hClientCPData[client].GetArray( prev, iData, view_as<int>( C_CPData ) );
					flPrevTime = g_flClientStartTime[client];
				}
				
				g_hClientCPData[client].GetArray( i, iData, view_as<int>( C_CPData ) );
				
				
				static float flRecTime;
				flRecTime = view_as<float>( iData[C_CP_GAMETIME] ) - flPrevTime;
				
				FormatEx( szQuery, sizeof( szQuery ), "REPLACE INTO "...TABLE_CP_RECORDS..." VALUES ('%s', %i, %i, %i, %i, %i, %.16f)",
				g_szCurrentMap,
				iData[C_CP_ID],
				run,
				style,
				mode,
				g_iClientId[client],
				flRecTime );
				
				if (flPrevMapBest <= TIME_INVALID || flNewTime < flPrevMapBest)
					SetWrCpTime( iData[C_CP_INDEX], mode, flRecTime );

				SetPrCpTime( iData[C_CP_INDEX], mode, flRecTime, client  );
				
				// Update game too.
				
				SQL_TQuery(g_hDatabase, Threaded_Empty, szQuery, client);
			}
		}
	}	
	
	DoRecordNotification( client, run, style, mode, flNewTime, flOldBestTime, flPrevMapBest );

	return true;
}

stock bool DB_SaveClientData( int client )
{
	if ( !g_iClientId[client] ) return false;
	
	static char szSteam[MAX_ID_LENGTH];
	if ( !GetClientSteam( client, szSteam, sizeof( szSteam ) ) ) return false;
	
	static char szName[MAX_NAME_LENGTH];
	GetClientName( client, szName, sizeof( szName ) );
	
	StripQuotes( szName );
	
	if ( !SQL_EscapeString( g_hDatabase, szName, szName, sizeof( szName ) ) )
		strcopy( szName, sizeof( szName ), "Player" );
		
	static char szQuery[192];
	FormatEx( szQuery, sizeof( szQuery ), "UPDATE "...TABLE_PLYDATA..." SET name = '%s' WHERE steamid = '%s'",
		szName,
		szSteam );
	
	SQL_TQuery(g_hDatabase, Threaded_Empty, szQuery, client);
	
	return true;
}

// Get client options and time it took him/her to beat the map in all modes.
stock void DB_RetrieveClientData( int client )
{
	static char szSteam[MAX_ID_LENGTH];
	if ( !GetClientSteam( client, szSteam, sizeof( szSteam ) ) ) return;
	
	
	static char szQuery[192];

	FormatEx( szQuery, sizeof( szQuery ), "SELECT uid, hideflags, overall, solly, demo, srank, drank FROM "...TABLE_PLYDATA..." WHERE steamid = '%s'", szSteam );
	
	g_hDatabase.Query( Threaded_RetrieveClientData, szQuery, GetClientUserId( client ), DBPrio_Normal );
}

/*stock void DB_GetClientId( int client )
{
	static char szSteam[MAX_ID_LENGTH];
	if ( !GetClientSteam( client, szSteam, sizeof( szSteam ) ) ) return;
	
	
	static char szQuery[128];
	FormatEx( szQuery, sizeof( szQuery ), "SELECT uid FROM "...TABLE_PLYDATA..." WHERE steamid = '%s'", szSteam );
	
	g_hDatabase.Query( Threaded_GetClientId, szQuery, GetClientUserId( client ), DBPrio_Normal );
}*/

stock void DB_SaveMapZone( int zone, float vecMins[3], float vecMaxs[3], int id = 0, int run = 0, int client = 0 )
{
	char szQuery[500];
	if ( zone == ZONE_CP )
	{
		g_hDatabase.Format( szQuery, sizeof( szQuery ), "INSERT INTO "...TABLE_CP..." VALUES ('%s', %i,  %i, %.0f, %.0f, %.0f, %.0f, %.0f, %.0f, %i, CURRENT_DATE)",
		g_szCurrentMap, id, 0,
		vecMins[0], vecMins[1], vecMins[2],
		vecMaxs[0], vecMaxs[1], vecMaxs[2], g_iClientId[client]);
	}
	else
	{
		int num;
		if (zone < NUM_REALZONES)
			for (int i = 0; i < 20; i++)
			{
				if (g_bZoneExists[zone][i])
				{
					num++;
				}
			}

			g_hDatabase.Format( szQuery, sizeof( szQuery ), "INSERT INTO "...TABLE_ZONES..." VALUES ('%s', %i, %i, %.0f, %.0f, %.0f, %.0f, %.0f, %.0f, %i, %i, CURRENT_DATE)",
			g_szCurrentMap, zone, id,
			vecMins[0], vecMins[1], vecMins[2],
			vecMaxs[0], vecMaxs[1], vecMaxs[2],
			num, g_iClientId[client] );

		if (zone < NUM_REALZONES)
			g_bZoneExists[zone][num] = true;
	}
	
	SQL_TQuery(g_hDatabase, Threaded_Empty, szQuery, client);
}

stock void DB_EraseMapZone( int zone, int id = 0, int run = 0, int client = 0 )
{
	char szQuery[162];
	if ( zone == ZONE_CP )
	{
		g_hDatabase.Format( szQuery, sizeof( szQuery ), "DELETE FROM "...TABLE_CP..." WHERE map = '%s' AND id = %i", g_szCurrentMap, id );
	}
	else
	{
		g_hDatabase.Format( szQuery, sizeof( szQuery ), "DELETE FROM "...TABLE_ZONES..." WHERE map = '%s' AND zone = %i AND id = %i AND number = 0", g_szCurrentMap, zone, id );
	}
	
	SQL_TQuery(g_hDatabase, Threaded_Empty, szQuery, client);
}

stock void DB_EraseRunRecords( int run, int client = 0 )
{
	char szQuery[128];
	FormatEx( szQuery, sizeof( szQuery ), "DELETE FROM "...TABLE_RECORDS..." WHERE map = '%s' AND run = %i", g_szCurrentMap, run );
	
	SQL_TQuery(g_hDatabase, Threaded_Empty, szQuery, client);
}

stock void DB_EraseRunCPRecords( int run, int client = 0 )
{
	char szQuery[128];
	FormatEx( szQuery, sizeof( szQuery ), "DELETE FROM "...TABLE_CP_RECORDS..." WHERE map = '%s' AND run = %i", g_szCurrentMap, run );
	
	SQL_TQuery(g_hDatabase, Threaded_Empty, szQuery, client);
}

stock void DB_DeleteRecord( int client, int run, int mode, int uid, char[] map )
{
	char szQuery[500], update_records[100];
	FormatEx( szQuery, sizeof( szQuery ), "DELETE FROM "...TABLE_RECORDS..." WHERE map = '%s' AND run = %i AND mode = %i AND uid = %i", map, run, mode, uid );
	
	g_hDatabase.Query( Threaded_DeleteRecord, szQuery, client, DBPrio_Normal );

	FormatEx( szQuery, sizeof( szQuery ), "DELETE FROM "...TABLE_CP_RECORDS..." WHERE map = '%s' AND uid = %i AND run = %i AND mode = %i", map, uid, run, mode );
	
	g_hDatabase.Query( Threaded_DeleteCpRecord, szQuery, client, DBPrio_Normal );

	char szT4[200], szT5[200], szT6[200], szT7[200], szT8[200], szT9[200], szT10[200], szT11[200], szT12[200], szT13[200];

	Transaction t1s = new Transaction();
	g_hDatabase.Format(szT4, sizeof(szT4), "(SELECT @curRank := 0);");
	g_hDatabase.Format(szT5, sizeof(szT5), "update maprecs SET rank = (@curRank := @curRank + 1) WHERE map = '%s' AND run = %i AND mode = %i ORDER BY time ASC;", map, run, mode );
	g_hDatabase.Format(szT12, sizeof(szT12), "update plydata SET %s = (SELECT SUM(pts) from maprecs where uid = plydata.uid and mode = %i) WHERE (SELECT SUM(pts) from maprecs where uid = plydata.uid and mode %i) > 0.0;", (mode == MODE_SOLDIER) ? "solly" : "demo", (mode == MODE_SOLDIER) ? 1 : 3, (mode == MODE_SOLDIER) ? 1 : 3 );
	g_hDatabase.Format(szT13, sizeof(szT13), "update plydata SET overall = (SELECT SUM(pts) from maprecs where uid = plydata.uid) WHERE (SELECT SUM(pts) from maprecs where uid = plydata.uid) > 0.0;" );

	Transaction t2s = new Transaction();
	g_hDatabase.Format(szT6, sizeof(szT6), "(SELECT @curRank := 0);");
	g_hDatabase.Format(szT7, sizeof(szT7), "UPDATE "...TABLE_PLYDATA..." SET %s = (@curRank := @curRank + 1) where (select sum(pts) from maprecs where uid = plydata.uid and mode = %s) > 0.0 ORDER BY (select sum(pts) from maprecs where uid = plydata.uid and mode = %s) DESC;", (mode == MODE_SOLDIER) ? "srank" : "drank", (mode == MODE_SOLDIER) ? "solly" : "demo", (mode == MODE_SOLDIER) ? "1" : "3", (mode == MODE_SOLDIER) ? "1" : "3" );
				
	Transaction t3s = new Transaction();
	g_hDatabase.Format(szT8, sizeof(szT8), "(SELECT @curRank := 0);");
	g_hDatabase.Format(szT9, sizeof(szT9), "UPDATE "...TABLE_PLYDATA..." SET orank = (@curRank := @curRank + 1) where (select sum(pts) from maprecs where uid = plydata.uid) > 0.0 ORDER BY (select sum(pts) from maprecs where uid = plydata.uid) DESC;" );

	t1s.AddQuery(szT4);
	t1s.AddQuery(szT5);
	t1s.AddQuery(szT12);
	t1s.AddQuery(szT13);
	t2s.AddQuery(szT6);
	t2s.AddQuery(szT7);
	t3s.AddQuery(szT8);
	t3s.AddQuery(szT9);

	SQL_ExecuteTransaction(g_hDatabase, t1s);
	SQL_ExecuteTransaction(g_hDatabase, t2s);
	SQL_ExecuteTransaction(g_hDatabase, t3s);

	char socket_key[20];
	GetConVarString(CVAR_MessageKey, socket_key, sizeof(socket_key));
	Format(update_records, sizeof(update_records), "%supdate_records", socket_key);
	if (IRC_Connected)
		SocketSend(ClientSocket, update_records, sizeof(update_records));

	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i))
		{
			if (g_iClientId[i] == uid)
			{
				g_flClientBestTime[client][run][mode] = TIME_INVALID;
				for (int cp = 0; cp < g_hCPs.Length; cp++)
				{
					f_CpPr[client][mode][cp] = TIME_INVALID;
				}
			}
		}
	}
	
	for (int i=0; i < NUM_RUNS; i++)
	{
		if (!g_bIsLoaded[i]) continue;
		
		for (int b=1; b < 4; b+=2)
		{
			FormatEx( szQuery, sizeof( szQuery ), "SELECT uid, run, style, mode, time, name FROM maprecs natural join plydata WHERE map = '%s' and run = %i and mode = %i order by time asc", g_szCurrentMap, i, b );
						
			g_hDatabase.Query( Threaded_Init_Records, szQuery, _, DBPrio_Normal );
		}
	}

	g_hDatabase.Format( szQuery, sizeof( szQuery ), "SELECT uid, run, id, mode, time, map FROM mapcprecs WHERE uid = (select maprecs.uid from maprecs where maprecs.map = '%s' and maprecs.run = mapcprecs.run and maprecs.mode = mapcprecs.mode order by maprecs.time ASC limit 1) and map = '%s' group by map, run, mode, id ORDER BY time ASC", g_szCurrentMap, g_szCurrentMap );
				
	g_hDatabase.Query( Threaded_Init_CP_WR_Times, szQuery, _, DBPrio_High );
}

stock void DB_EraseCPRecord( int client, int run, int style, int mode, int uid )
{
	// Reset instead of delete. Essentially the same.
	char szQuery[162];
	FormatEx( szQuery, sizeof( szQuery ), "DELETE FROM "...TABLE_CP_RECORDS..." WHERE map = '%s' AND uid = %i AND run = %i AND style = %i AND mode = %i", map, uid, run, style, mode );
	
	g_hDatabase.Query( Threaded_DeleteCpRecord, szQuery, client, DBPrio_Normal );
}