enum MapChange
{
	MapChange_Instant,      /** Change map as soon as the voting results have come in */
	MapChange_RoundEnd,     /** Change map at the end of the round */
	MapChange_MapEnd        /** Change the sm_nextmap cvar */
};

bool g_bLate;

/* ConVars */
ConVar g_cvMapVoteStartTime;
ConVar g_cvMapVoteDuration;
ConVar g_cvMapVoteBlockMapInterval;
ConVar g_cvMapVoteExtendTime;

/* Map arrays */
ArrayList g_aNominateList;
ArrayList g_aOldMaps;

/* Map Data */
int ClientVote[MAXPLAYERS+1] = {-1, ...};
bool Client_in_vote[MAXPLAYERS+1];
int VotersCount;
Menu g_VoteMenu;

Handle h_VoteTimer = null;

float VoteStartTime;

char g_cMapName[PLATFORM_MAX_PATH];

MapChange g_ChangeTime;

bool g_bMapVoteStarted;
bool g_bMapVoteFinished;
bool MenuClosedByServer = false;

bool IsVoteDisplay[MAXPLAYERS+1];

int	g_VotesVe = 0;
int	g_Votes = 0;
int	g_VotersVe=0;
int	g_Voters=0;
int g_VotesNeededVe = 0;

float g_fMapStartTime;

Menu g_hNominateMenu;

/* Player Data */
bool	g_bRockTheVote[MAXPLAYERS + 1];
char g_cNominatedMap[MAXPLAYERS + 1][PLATFORM_MAX_PATH];

bool g_VotedVe[MAXPLAYERS+1] = {false, ...};

public Action Command_Revote(int client, int args)
{
	if (!client)
	{
		return Plugin_Handled;
	}
	if (g_bMapVoteFinished || !g_bMapVoteStarted)
	{
		CPrintToChat(client, CHAT_PREFIX..."No vote ongoing.");
		return Plugin_Handled;
	}
	if (!Client_in_vote[client])
	{
		CPrintToChat(client, CHAT_PREFIX..."You cannot vote.");
		return Plugin_Handled;
	}
	if (IsVoteDisplay[client])
	{
		CPrintToChat(client, CHAT_PREFIX..."Vote menu display already.");
		return Plugin_Handled;
	}
	g_VoteMenu.Display(client, MENU_TIME_FOREVER);
	return Plugin_Handled;
}

public Action Command_VE(int client, int args)
{
	if (!client)
	{
		return Plugin_Handled;
	}
	
	AttemptVE(client);
	
	return Plugin_Handled;
}

void AttemptVE(int client)
{
	int time;
	if (g_iClientIdle[client])
		g_iClientIdle[client] = false;
	
	GetMapTimeLeft(time);
	if (time > 180)
	{

		int iMins = 0;
		time -= 180;
		int iSec = time;
		while ( iSec >= 60 )
		{
			iMins++;
			iSec -= 60;
		}
		
		CPrintToChat(client, CHAT_PREFIX..."You need wait {lightskyblue}%i min %i sec{white} for !ve", iMins, iSec);
		return;
	}
	if (g_bMapVoteStarted)
	{
		CPrintToChat(client, CHAT_PREFIX..."You must wait until the end of voting");
		return;
	}
	VeVotersCount();
	if (g_VotedVe[client])
	{
		CPrintToChat(client, CHAT_PREFIX..."You have already vote to extend. (%i/%i required)", g_VotesVe, g_VotesNeededVe);
		return;
	}	
	
	char name[MAX_NAME_LENGTH];
	GetClientName(client, name, sizeof(name));
	
	g_VotedVe[client] = true;

	VeVotersCount();
	
	CPrintToChatAll(CHAT_PREFIX..."{green}%N {white}wants extend (%i/%i required)", client, g_VotesVe, g_VotesNeededVe);
	
	if (g_VotesVe >= g_VotesNeededVe)
	{
		StartVE();
	}	
}

void StartVE()
{
	int time;
	GetMapTimeLimit(time);
	ServerCommand("mp_timelimit %i", time + 30 );
	CPrintToChatAll(CHAT_PREFIX..."{lightskyblue}mp_timelimit {white}changed to {green}%i.0", time + 30);
	CPrintToChatAll(CHAT_PREFIX..."Map has been {lightskyblue}extended");
	ResetVE();
	return;
}

void ResetVE()
{
	g_VotesVe = 0;
			
	for (int i=1; i<=MaxClients; i++)
	{
		g_VotedVe[i] = false;
	}
}

public void VeVotersCount()
{
	g_VotesVe = 0;
	g_Votes = 0;
	g_VotersVe=0;
	g_Voters=0;
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && IsClientConnected(i) && !IsFakeClient(i) && !g_iClientIdle[i])
		{
			g_VotersVe++;
			g_VotesNeededVe = RoundToCeil(g_VotersVe * 0.60);

			if (g_VotedVe[i])
				g_VotesVe++;
		}

	}
}

public Action OnRoundStartPost( Event event, const char[] name, bool dontBroadcast )
{
	// disable rtv if delay time is > 0
	g_fMapStartTime = GetGameTime();
	
	g_bMapVoteFinished = false;
	g_bMapVoteStarted = false;
	
	g_aNominateList.Clear();
	for( int i = 1; i <= MaxClients; i++ )
	{
		g_cNominatedMap[i][0] = '\0';
	}
	ClearRTV();
}

public Action Timer_OnSecond( Handle timer )
{
	if( g_aMapList.Length && !g_bMapVoteStarted && !g_bMapVoteFinished )
	{
		CheckTimeLeft();
	}
}

void CheckTimeLeft()
{
	int timeleft;
	if( GetMapTimeLeft( timeleft ) && timeleft > 0 )
	{
		int startTime = RoundFloat( g_cvMapVoteStartTime.FloatValue * 60.0 );
		
		if( timeleft - startTime <= 0 )
		{
			InitiateMapVote( MapChange_MapEnd );
		}
	}
}

public void OnClientSayCommand_Post( int client, const char[] command, const char[] sArgs )
{
	if( StrEqual( sArgs, "rtv", false ) || StrEqual( sArgs, "rockthevote", false ) )
	{
		ReplySource old = SetCmdReplySource(SM_REPLY_TO_CHAT);
		
		Command_RockTheVote( client, 0 );
		
		SetCmdReplySource(old);
	}
	else if( StrEqual( sArgs, "ve", false ) )
	{
		ReplySource old = SetCmdReplySource(SM_REPLY_TO_CHAT);
		
		Command_VE( client, 0 );
		
		SetCmdReplySource(old);
	}
}

void InitiateMapVote( MapChange when )
{
	g_ChangeTime = when;
	g_bMapVoteStarted = true;
	
	// create menu
	g_VoteMenu = new Menu( Handler_MapVoteMenu, MENU_ACTIONS_ALL );
	g_VoteMenu.Pagination = MENU_NO_PAGINATION;
	g_VoteMenu.SetTitle( "Vote for next map\n \n" );
	
	int mapsToAdd = 5;

	bool b_skip = false;

	char map[PLATFORM_MAX_PATH];
	char mapToSkipTemp[PLATFORM_MAX_PATH];
	char mapdisplay[PLATFORM_MAX_PATH + 32];
	
	int nominateMapsToAdd = ( mapsToAdd > g_aNominateList.Length ) ? g_aNominateList.Length : mapsToAdd;
	for( int i = 0; i < nominateMapsToAdd; i++ )
	{
		g_aNominateList.GetString( i, map, sizeof(map) );
		
		int stier = 1, dtier = 1;
		int idx = g_aMapList.FindString( map );
		if( idx != -1 )
		{
			stier = g_aMapTiersSolly.Get( idx );
			dtier = g_aMapTiersDemo.Get( idx );
		}
		
		if (stier != -1 || dtier != -1)
			Format( mapdisplay, sizeof(mapdisplay), "S%i|D%i %s ", stier, dtier, map );
		else
			Format( mapdisplay, sizeof(mapdisplay), "Sx|Dx %s ", map );
		
		g_VoteMenu.AddItem( map, mapdisplay );
		
		mapsToAdd--;
	}
	
	for( int i = 0; i < mapsToAdd; i++ )
	{
		int rand = GetRandomInt( 0, g_aMapList.Length - 1 );
		g_aMapList.GetString( rand, map, sizeof(map) );

		if( StrEqual( map, g_cMapName ) )
		{
			// don't add current map to vote
			i--;
			continue;
		}
		
		int idx = g_aOldMaps.FindString( map );
		if( idx != -1 )
		{
			// map already played recently, get another map
			i--;
			continue;
		}

		b_skip = false;

		if ( g_aNominateList.Length > 0 )
		{
			for( int i2 = 0; i2 < nominateMapsToAdd; i2++ )
			{
				g_aNominateList.GetString( i2, mapToSkipTemp, sizeof(mapToSkipTemp) );

				if ( StrEqual(map, mapToSkipTemp) )
				{
					b_skip = true;
				}
			}
		}
		if ( b_skip )
		{
			i--;
			continue;
		}
		
		int stier = g_aMapTiersSolly.Get( rand );
		int dtier = g_aMapTiersDemo.Get( rand );

		if (stier != -1 || dtier != -1)
			Format( mapdisplay, sizeof(mapdisplay), "S%i|D%i %s ", stier, dtier, map );
		else
			Format( mapdisplay, sizeof(mapdisplay), "Sx|Dx %s ", map );
		
		g_VoteMenu.AddItem( map, mapdisplay );
	}
	
	if( when == MapChange_MapEnd )
	{
		g_VoteMenu.AddItem( "extend", "Extend Map" );
	}
	else if( when == MapChange_Instant )
	{
		g_VoteMenu.AddItem( "dontchange", "Don't Change" );
	}
	
	g_VoteMenu.ExitButton = true;
	CPrintToChatAll(CHAT_PREFIX..."Voting for next map has started.");
	for (int i = 1; i <= MaxClients; i++) {
		ClientVote[i] = -1;
		Client_in_vote[i] = false;

		if (!IsClientInGame(i) || IsFakeClient(i) || g_iClientIdle[i])
		{
			continue;
		}
		VotersCount++;
		Client_in_vote[i] = true;
		
		if (IsAutoExtendEnabled(i) && when == MapChange_MapEnd)
		{
			CPrintToChat(i, CHAT_PREFIX..."({lightskyblue}!runmode{white}) You automatically voted for {lightskyblue}Extend Map{white}. {lightskyblue}!revote{white} if you change your mind.");
			ClientVote[i] = 5;
		}
	}

	for (int i = 1; i <= MaxClients; i++)
		if (Client_in_vote[i] && ClientVote[i] != 5)
			g_VoteMenu.Display(i, MENU_TIME_FOREVER);

	h_VoteTimer = CreateTimer( 30.0, Timer_EndOfVoting, g_VoteMenu, TIMER_FLAG_NO_MAPCHANGE );

	int votes;
	for ( int i = 1; i <= MaxClients; i++ )
	{
		if ( Client_in_vote[i] && ClientVote[i] != -1 )
			votes++;
	}

	if (when == MapChange_MapEnd)
		if (votes == VotersCount)
			FinishMapVote(g_VoteMenu, false);
}

public Action Timer_EndOfVoting(Handle timer, any menu)
{	
	int votes;

	for ( int i = 1; i <= MaxClients; i++ )
	{
		if ( Client_in_vote[i] && ClientVote[i] != -1 )
			votes++;
	}
	FinishMapVote(menu, true);
	return Plugin_Handled;
}

public void FinishMapVote( Menu menu, bool TimeEnd )
{
	if (g_bMapVoteFinished) return;

	int winner_index;
	int item_votes[6];
	int WinnersArr[6];
	bool random = false;
	int num_votes;

	for ( int i = 1; i <= MaxClients; i++ )
	{
		if ( Client_in_vote[i] && ClientVote[i] != -1 )
			num_votes++;
	}

	if (num_votes > 0)
	{
		for ( int i = 1; i <= MaxClients; i++ )
		{
			if ( Client_in_vote[i] && ClientVote[i] != -1 )
				item_votes[ClientVote[i]]++;
		}

		int max = item_votes[0],
			max_index = 0;

		for ( int m; m < 6; m++ )
		{
			if (max < item_votes[m])
			{
				max = item_votes[m];
				max_index = m;
			}
		}

		int countWinners;

		for (int r; r < 6; r++) {
			if (max == item_votes[r]) {
				countWinners++;
				WinnersArr[r] = r;
			}
		}

		if (countWinners > 1)
		{
			int id;
			for (;;)
			{
				id = GetRandomInt(0, 5);
				if (WinnersArr[id] > 0)
				{
					winner_index = id;
					break;
				}
			}
		}
		else
		{
			winner_index = max_index;
		}
	}
	else
	{
		winner_index = GetRandomInt(0, 4); //No choose extend/dont change option
		random = true;
	}

	char map[PLATFORM_MAX_PATH];
	char displayName[PLATFORM_MAX_PATH];
	int c = '%';

	menu.GetItem(winner_index, map, sizeof(map), _, displayName, sizeof(displayName));
	
	if( StrEqual( map, "extend" ) )
	{	
		int time;
		if( GetMapTimeLimit( time ) )
		{
			if( time > 0 )
			{
				ExtendMapTimeLimit( g_cvMapVoteExtendTime.IntValue * 60 );						
			}
		}

		CPrintToChatAll(CHAT_PREFIX..."{lightskyblue}Extend Map {white}won the vote with %i%c (%i/%i)", RoundToFloor(float(item_votes[winner_index])/float(num_votes)*100), c, item_votes[winner_index], num_votes);
		
		// We extended, so we'll have to vote again.
		g_bMapVoteStarted = false;
		
		ClearRTV();
	}
	else if( StrEqual( map, "dontchange" ) )
	{
		g_bMapVoteFinished = false;
		g_bMapVoteStarted = false;
		
		CPrintToChatAll(CHAT_PREFIX..."{lightskyblue}Don't Change {white}won the vote with %i%c (%i/%i)", RoundToFloor(float(item_votes[winner_index])/float(num_votes)*100), c, item_votes[winner_index], num_votes);
		
		ClearRTV();
	}
	else
	{	
		if( g_ChangeTime == MapChange_MapEnd )
		{
			SetNextMap(map);
		}
		else if( g_ChangeTime == MapChange_Instant )
		{
			DataPack data;
			CreateDataTimer(5.0, Timer_ChangeMap, data);
			data.WriteString(map);
		}
		
		g_bMapVoteStarted = false;
		g_bMapVoteFinished = true;
		
		if (random)
			CPrintToChatAll(CHAT_PREFIX..."No one voted. Randomly selected: {lightskyblue}%s", map);
		else
			CPrintToChatAll(CHAT_PREFIX..."{lightskyblue}%s {white}won the vote with %i%c (%i/%i)", map, RoundToFloor(float(item_votes[winner_index])/float(num_votes)*100), c, item_votes[winner_index], num_votes);

		LogAction(-1, -1, "Voting for next map has finished. Nextmap: %s.", map);
	}
	if (!TimeEnd)
	{
		if (h_VoteTimer != null)
		{
			KillTimer(h_VoteTimer);
			h_VoteTimer = null;
		}
	}
	for (int i = 1; i <= MaxClients; i++)
	{
		Client_in_vote[i] = false;
		ClientVote[i] = -1;
	}
	VotersCount = 0;
	MenuClosedByServer = true;
	menu.Cancel();
	MenuClosedByServer = false;
	menu = null;
	delete menu;	
}

public int Handler_MapVoteMenu( Menu menu, MenuAction action, int param1, int param2 )
{
	switch( action )
	{
		case MenuAction_End:
		{
			if (param1 == MenuEnd_Cancelled && param2 == MenuCancel_Timeout)
            {
				int votes;
				for ( int i = 1; i <= MaxClients; i++ )
				{
					if ( Client_in_vote[i] && ClientVote[i] != -1 )
						votes++;
				}
				FinishMapVote(menu, false);
            }
		}
		case MenuAction_Cancel:
		{
			if ( (param2 == MenuCancel_Exit || param2 == MenuCancel_Interrupted) && !MenuClosedByServer )
			{
				CPrintToChat(param1, CHAT_PREFIX..."Vote menu hidden ({lightskyblue}!revote {white}to vote again)");
				IsVoteDisplay[param1] = false;
				return 0;
			}
		}
		case MenuAction_Display:
		{
			IsVoteDisplay[param1] = true;
			Panel panel = view_as<Panel>(param2);
			panel.SetTitle( "Vote for next map\n \n" );
		}		
		
		case MenuAction_DisplayItem:
		{	
			char map[PLATFORM_MAX_PATH], buffer[255], changed[50], szVotes[10];
			int votes;
			for ( int i = 1; i <= MaxClients; i++)
			{
				if ( Client_in_vote[i] && ClientVote[i] == param2 )
					votes++;
			}

			if (votes > 0)
				FormatEx(szVotes, sizeof(szVotes), " (%i)", votes);

			if (menu.ItemCount - 1 == param2)
			{
				menu.GetItem(param2, map, sizeof(map));
				if (strcmp(map, "extend", false) == 0)
				{
					Format( buffer, sizeof(buffer), "Extend Map%s", szVotes );
					return RedrawMenuItem(buffer);
				}
				else if (strcmp(map, "dontchange", false) == 0)
				{
					Format( buffer, sizeof(buffer), "Don't Change%s", szVotes );
					return RedrawMenuItem(buffer);					
				}
			}
			else
			{
				menu.GetItem(param2, changed, sizeof(changed));
				int stier = -1, dtier = -1;
				int idx = g_aMapList.FindString( changed );
				if( idx != -1 )
				{
					stier = g_aMapTiersSolly.Get( idx );
					dtier = g_aMapTiersDemo.Get( idx );
				}

				if (stier != -1 || dtier != -1)
					Format(buffer, sizeof(buffer), "S%i|D%i %s%s", stier, dtier, changed, szVotes);
				else
					Format(buffer, sizeof(buffer), "Sx|Dx %s%s", changed, szVotes);

				return RedrawMenuItem(buffer);
			}
		}
		case MenuAction_Select:
		{
			if (ClientVote[param1] == param2)
			{
				if (IsPressSpamming(param1))
				{
					CPrintToChat(param1, CHAT_PREFIX..."Vote menu hidden ({lightskyblue}!revote {white}to vote again)");
					IsVoteDisplay[param1] = false;
					return 0;
				}
			}

			ClientVote[param1] = param2;
			
			MenuClosedByServer = true;
			for (int i = 1; i <= MaxClients; i++)
			{
				if (!IsClientInGame(i) || IsFakeClient(i) || !Client_in_vote[i] || !IsVoteDisplay[param1])
				{
					continue;
				}
				menu.Display(i, MENU_TIME_FOREVER);
			}
			MenuClosedByServer = false;

			int votes;
			for ( int i = 1; i <= MaxClients; i++)
			{
				if ( Client_in_vote[i] && ClientVote[i] >= 0 )
					votes++;
			}

			if (votes == VotersCount)
			{
				FinishMapVote(menu, false);
			}
		}
	}
	return 0;
}

stock bool IsPressSpamming( int client )
{
	if ( g_flClientWarning[client] > GetEngineTime() )
	{
		return true;
	}

	g_flClientWarning[client] = GetEngineTime() + 1.0;

	return false;
}

// extends map while also notifying players and setting plugin data
void ExtendMap( int time = 0 )
{
	if( time == 0 )
	{
		time = RoundFloat( 15 * 60 );
	}

	ExtendMapTimeLimit( time );
	CPrintToChatAll( "The map was extended for {green}%.1f {white}minutes", time / 60.0 );
	
	g_bMapVoteStarted = false;
	g_bMapVoteFinished = false;
}

void LoadMapList()
{
	g_aMapList.Clear();
	g_aMapTiersSolly.Clear();
	g_aMapTiersDemo.Clear();
	
	char buffer[512];

	Transaction t = new Transaction();

	t.AddQuery("SELECT map_name, stier, dtier FROM `map_info` WHERE run = 0 and (select enabled from maplist where map = map_name) = 1 ORDER BY `map_name`");
	t.AddQuery("SELECT `map` FROM maplist WHERE enabled = 1 ORDER BY `map`");
	g_hDatabase.Execute( t, LoadMapsTiersCallback, _, 0 );
}

public void LoadMapsTiersCallback(Database g_hDatabase, any client, int numQueries, DBResultSet[] results, any[] queryData)
{

	if ( results[1] == DBVal_Error || results[1] == DBVal_Null || results[1] == DBVal_TypeMismatch || results[1] == null ) 
	{
		char error[200];

		if (SQL_GetError(g_hDatabase, error, sizeof(error)))
		{
			DB_LogError( error );
		}

		return;
	}
	
	char map[PLATFORM_MAX_PATH], buff[PLATFORM_MAX_PATH];

	while( results[0].FetchRow() )
	{	
		results[0].FetchString( 0, map, sizeof(map) );
		
		// TODO: can this cause duplicate entries?
		if( GetMapDisplayName(map, buff, sizeof(buff)) )
		{
			g_aMapList.PushString( map );
			g_aMapTiersSolly.Push( results[0].FetchInt( 1 ) );
			g_aMapTiersDemo.Push( results[0].FetchInt( 2 ) );
		}
	}

	while( results[1].FetchRow() )
	{	
		results[1].FetchString( 0, map, sizeof(map) );
		
		// TODO: can this cause duplicate entries?
		if( GetMapDisplayName(map, buff, sizeof(buff)) )
		{
			if (g_aMapList.FindString(map) == -1)
			{
				g_aMapList.PushString( map );
				g_aMapTiersSolly.Push( -1 );
				g_aMapTiersDemo.Push( -1 );
			}
		}
	}

	
	CreateNominateMenu();
}

bool SMC_FindMap( const char[] mapname, char[] output, int maxlen )
{
	int length = g_aMapList.Length;	
	for( int i = 0; i < length; i++ )
	{
		char entry[PLATFORM_MAX_PATH];
		g_aMapList.GetString( i, entry, sizeof(entry) );
		
		if( StrContains( entry, mapname ) != -1 )
		{
			strcopy( output, maxlen, entry );
			return true;
		}
	}
	
	return false;
}

void ClearRTV()
{
	for( int i = 1; i <= MaxClients; i++ )
	{
		g_bRockTheVote[i] = false;
	}
}

/* Timers */
public Action Timer_ChangeMap( Handle timer, DataPack data )
{
	char map[PLATFORM_MAX_PATH];
	data.Reset();
	data.ReadString( map, sizeof(map) );
	
	SetNextMap( map );
	ForceChangeLevel( map, "RTV Mapvote" );
}

/* Commands */
public Action Command_Extend( int client, int args )
{
	int extendtime;
	if( args > 0 )
	{
		char sArg[8];
		GetCmdArg( 1, sArg, sizeof(sArg) );
		extendtime = RoundFloat( StringToFloat( sArg ) * 60 );
	}
	else
	{
		extendtime = RoundFloat( g_cvMapVoteExtendTime.FloatValue * 60.0 );
	}
	
	ExtendMap( extendtime );
	
	return Plugin_Handled;
}

public Action Command_ForceMapVote( int client, int args )
{
	if( g_bMapVoteStarted || g_bMapVoteFinished )
	{
		ReplyToCommand( client, CHAT_PREFIX..."Map vote already %s", ( g_bMapVoteStarted ) ? "initiated" : "finished" );
	}
	else
	{
		InitiateMapVote( MapChange_Instant );
	}
	
	return Plugin_Handled;
}

public Action Command_ReloadMaplist( int client, int args )
{
	LoadMapList();
	
	return Plugin_Handled;
}

public Action Command_Nominate( int client, int args )
{
	if( args < 1 )
	{
		OpenNominateMenu( client );
		return Plugin_Handled;
	}
	
	char mapname[PLATFORM_MAX_PATH];
	GetCmdArg( 1, mapname, sizeof(mapname) );
	if( SMC_FindMap( mapname, mapname, sizeof(mapname) ) )
	{
		if( StrEqual( mapname, g_cMapName ) )
		{
			ReplyToCommand( client, CHAT_PREFIX..."Can't nominate current map" );
			return Plugin_Handled;
		}
		
		int idx = g_aOldMaps.FindString( mapname );
		if( idx != -1 )
		{
			ReplyToCommand(client, CHAT_PREFIX... "The map you chose was recently played and cannot be nominated");
			return Plugin_Handled;
		}
	
		ReplySource old = SetCmdReplySource( SM_REPLY_TO_CHAT );
		Nominate( client, mapname );
		SetCmdReplySource( old );
	}
	else
	{
		CPrintToChatAll( CHAT_PREFIX..."Could not find map {lightskyblue}%s", mapname );
	}
	
	return Plugin_Handled;
}

public Action Command_UnNominate( int client, int args )
{
	if( g_cNominatedMap[client][0] == '\0' )
	{
		ReplyToCommand( client, CHAT_PREFIX..."You haven't nominated a map" );
		return Plugin_Handled;
	}

	int idx = g_aNominateList.FindString( g_cNominatedMap[client] );
	if( idx != -1 )
	{
		g_aNominateList.Erase( idx );
		g_cNominatedMap[client][0] = '\0';
	}

	ReplyToCommand( client, CHAT_PREFIX..."Successfully removed nomination for {green}%s", g_cNominatedMap[client] );
	
	
	return Plugin_Handled;
}

void CreateNominateMenu()
{
	delete g_hNominateMenu;
	g_hNominateMenu = new Menu( NominateMenuHandler );
	
	g_hNominateMenu.SetTitle( "Nominate Menu\n \n" );
	
	int length = g_aMapList.Length;
	for( int i = 0; i < length; i++ )
	{
		int stier = g_aMapTiersSolly.Get( i );
		int dtier = g_aMapTiersDemo.Get( i );
		
		char mapname[PLATFORM_MAX_PATH];
		g_aMapList.GetString( i, mapname, sizeof(mapname) );
		
		if( StrEqual( mapname, g_cMapName ) )
		{
			continue;
		}
		
		int idx = g_aOldMaps.FindString( mapname );
		if( idx != -1 )
		{
			continue;
		}
		
		char mapdisplay[PLATFORM_MAX_PATH + 32];

		if (stier != -1 || dtier != -1)
			Format( mapdisplay, sizeof(mapdisplay), "S%i|D%i %s ", stier, dtier, mapname);
		else
			Format( mapdisplay, sizeof(mapdisplay), "Sx|Dx %s ", mapname);
		
		g_hNominateMenu.AddItem( mapname, mapdisplay );
	}
}

void OpenNominateMenu( int client )
{
	g_hNominateMenu.Display( client, MENU_TIME_FOREVER );
}

public int NominateMenuHandler( Menu menu, MenuAction action, int param1, int param2 )
{
	if( action == MenuAction_Select )
	{
		char mapname[PLATFORM_MAX_PATH];
		menu.GetItem( param2, mapname, sizeof(mapname) );
		
		Nominate( param1, mapname );
	}
}

void Nominate( int client, const char mapname[PLATFORM_MAX_PATH] )
{
	int idx = g_aNominateList.FindString( mapname );
	if( idx != -1 )
	{
		CReplyToCommand( client, CHAT_PREFIX..."{green}%s {white}has already been nominated", mapname );
		return;
	}
	
	if( g_cNominatedMap[client][0] != '\0' )
	{
		RemoveString( g_aNominateList, g_cNominatedMap[client] );
	}
	
	g_aNominateList.PushString( mapname );
	g_cNominatedMap[client] = mapname;
	
	CPrintToChatAll( CHAT_PREFIX..."{green}%N {white}has nominated {lightskyblue}%s", client, mapname );
}

public Action Command_RockTheVote( int client, int args )
{
	if (g_iClientIdle[client])
		g_iClientIdle[client] = false;

	if( g_bMapVoteStarted )
	{
		CReplyToCommand( client, CHAT_PREFIX..."Rock The Vote already started." );
	}
	else if( g_bRockTheVote[client] )
	{
		int total = 0;
		int rtvcount = 0;
		for( int i = 1; i <= MaxClients; i++ )
		{
			if( IsClientInGame(i) && IsClientConnected(i) && !IsFakeClient(i) && !g_iClientIdle[i])
			{
				total++;
				if( g_bRockTheVote[i] )
				{
					rtvcount++;
				}
			}
		}

		CPrintToChat(client, CHAT_PREFIX..."You have already voted. (%i/%i required)", rtvcount, total);
	}
	else
	{
		g_bRockTheVote[client] = true;

		int total = 0;
		int rtvcount = 0;
		for( int i = 1; i <= MaxClients; i++ )
		{
			if( IsClientInGame(i) && IsClientConnected(i) && !IsFakeClient(i) && !g_iClientIdle[i])
			{
				total++;
				if( g_bRockTheVote[i] )
				{
					rtvcount++;
				}
			}
		}

		CPrintToChatAll(CHAT_PREFIX..."{green}%N {white}wants rock the vote! (%i/%i required)", client, rtvcount, total );
		CheckRTV();
	}
	
	return Plugin_Handled;
}

void CheckRTV()
{
	int needed = GetRTVVotesNeeded();

	int total = 0;
	int rtvcount = 0;
	for( int i = 1; i <= MaxClients; i++ ) 
	{
		if( IsClientInGame(i) && IsClientConnected(i) && !IsFakeClient(i) && !g_iClientIdle[i])
		{
			total++;
			if( g_bRockTheVote[i] )
			{
				rtvcount++;
			}
		}
	}

	if( needed <= 0 )
	{
		if( g_bMapVoteFinished )
		{
			char map[PLATFORM_MAX_PATH];
			GetNextMap( map, sizeof(map) );
		
			CPrintToChatAll(CHAT_PREFIX..."Changing map to {lightskyblue}%s", map);
			
			ChangeMapDelayed( map );
		}
		else
		{	
			InitiateMapVote( MapChange_Instant );
		}
	}
}

public Action Command_UnRockTheVote( int client, int args )
{
	if( g_bMapVoteStarted || g_bMapVoteFinished )
	{
		ReplyToCommand( client, CHAT_PREFIX..."Map vote already %s", ( g_bMapVoteStarted ) ? "initiated" : "finished" );
	}
	else if( g_bRockTheVote[client] )
	{
		g_bRockTheVote[client] = false;
		
		CPrintToChatAll( CHAT_PREFIX..."{green}%N {white}no longer wants to rock the vote!", client );
	}

	return Plugin_Handled;
}

/* Stocks */

stock void RemoveString( ArrayList array, const char[] target )
{
	int idx = array.FindString( target );
	if( idx != -1 )
	{
		array.Erase( idx );
	}
}

stock void ChangeMapDelayed( const char[] map, float delay = 5.0 )
{
	DataPack data;
	CreateDataTimer( delay, Timer_ChangeMap, data );
	data.WriteString( map );
}

stock int GetRTVVotesNeeded()
{
	int total = 0;
	int rtvcount = 0;
	for( int i = 1; i <= MaxClients; i++ )
	{
		if( IsClientInGame(i) && IsClientConnected(i) && !IsFakeClient(i) && !g_iClientIdle[i])
		{
			total++;
			if( g_bRockTheVote[i] )
			{
				rtvcount++;
			}
		}
	}
	
	int totalNeeded = RoundToCeil( total * (60.0 / 100) );
	
	// always clamp to 1, so if rtvcount is 0 it never initiates RTV
	if( totalNeeded < 1 )
	{
		totalNeeded = 1;
	}
	
	return totalNeeded - rtvcount;
}