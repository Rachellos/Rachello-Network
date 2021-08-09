/*bool g_MapVoteCompleted;
bool g_HasVoteStarted;
bool client_voted[MAXPLAYERS+1][7];

int clients_in_vote = 0;

Handle g_VoteMenuTimer = null;
ArrayList nominated;

public void OnMapTimeLeftChanged()
{
	SetupTimeleftTimer();
}

void SetupTimeleftTimer()
{
	int time;
	char query[200];

	if (GetMapTimeLeft(time) && time > 0)
	{
		int startTime = 120;
		if (time - startTime < 0 && !g_MapVoteCompleted && !g_HasVoteStarted)
		{
			g_hMaps.Clear();
			g_hDatabase.Format(query, sizeof(query), "SELECT map_name, stier, dtier FROM map_info WHERE run = 0 ORDER BY RAND() limit 6");
			g_hDatabase.Query(MapArrayCallback, query);
		}
		else
		{
			if (g_VoteTimer != null)
			{
				KillTimer(g_VoteTimer);
				g_VoteTimer = null;
			}	

			g_VoteTimer = CreateTimer(float(time - startTime), Timer_StartMapVote, _, TIMER_FLAG_NO_MAPCHANGE);
		}		
	}
}

public Action Timer_StartMapVote(Handle timer, any data)
{
	g_VoteTimer = null;
	g_HasVoteStarted = true;
	g_hMaps.Clear();
	char query[200];

	g_hDatabase.Format(query, sizeof(query), "SELECT map_name, stier, dtier FROM map_info WHERE run = 0 ORDER BY RAND() limit 6");
	g_hDatabase.Query(MapArrayCallback, query);

	return Plugin_Stop;
}

public void MapArrayCallback( Database hOwner, DBResultSet hQuery, const char[] szError, any data )
{
	if ( hQuery == null )
	{
		PrintToServer("Couldn't get maps data." );
		return;
	}

	char map[PLATFORM_MAX_PATH];
	int index, count=0;
	int stier;
	int dtier;

	ArrayList nominated;
	GetNominatedMapList(nominated);

	if (nominated != INVALID_HANDLE)
		for (int i = 0; i < nominated.Length; i++)
		{
			stier = 3;
			dtier = 3;
			nominated.GetString(i, map, sizeof(map));

			index = g_hMaps.PushString(map);
		
			g_hMaps.Set(index, stier, view_as<int>(STIER));
			g_hMaps.Set(index, dtier, view_as<int>(DTIER));
			count++;
		}

	PrintToChatAll("%i", count);
	while (hQuery.FetchRow() && count <= 6)
	{
		count++;
		stier = hQuery.FetchInt(0);
		dtier = hQuery.FetchInt(1);
		hQuery.FetchString( 2, map, sizeof(map));

		index = g_hMaps.PushString(map);
		
		g_hMaps.Set(index, stier, view_as<int>(STIER));
		g_hMaps.Set(index, dtier, view_as<int>(DTIER));
	}

	StartVote();

	nominated.Clear();
	delete hQuery;
}

void StartVote()
{
	clients_in_vote=0;
    for (int i=1; i <= MaxClients; i++)
    {
        if (IsClientInGame(i) && IsClientConnected(i) && !g_iClientIdle[i])
        {
            clients_in_vote++;
            StartVoteToClient(i);
        }
    }
    return;
}

void StartVoteToClient(int client)
{
    Menu mMenu = new Menu(Vote_Callback);

	int stier, dtier;
	char map[100], display[100];
	char szVotes[10];
	int votes;

	mMenu.SetTitle("Vote Map\n ");

	for (int i = 0; i < g_hMaps.Length; i++)
	{
		g_hMaps.GetString(i, map, sizeof(map));
		PrintToChatAll(map);
		stier = g_hMaps.Get(i, view_as<int>(STIER));
		dtier = g_hMaps.Get(i, view_as<int>(DTIER));

		for (int c; c <= MaxClients; c++ )
		{
			if (client_voted[c][i])
				votes++;
		}
		if (votes > 0)
			FormatEx(szVotes, sizeof(szVotes), " (%i)", votes);

		GetMapDisplayName(map, map, sizeof(map));
		FormatEx(display, sizeof(display), "S%i|D%i %s %s", stier, dtier, map, szVotes);
		mMenu.AddItem(map, display);

		FormatEx(szVotes, sizeof(szVotes), "");
		votes = 0;
	}

	for (int c; c <= MaxClients; c++ )
	{
		if (client_voted[c][6])
			votes++;
	}
	if (votes > 0)
		FormatEx(szVotes, sizeof(szVotes), " (%i)", votes);

	FormatEx(display, sizeof(display), "Don't Change%s", szVotes);

	mMenu.AddItem("extend", display);
	mMenu.Display(client, 20);
}

public int Vote_Callback( Menu mMenu, MenuAction action, int client, int index )
{
	if ( action == MenuAction_End ) {
		delete mMenu; return 0; 
	}
	if ( action != MenuAction_Select )
	{
		return 0;
	}

	if ( action == MenuAction_Select )
	{
		int votes=0;

		for (int i; i < 7; i++)
		{
			client_voted[client][i] = false;
		}

		client_voted[client][index] = true;
		for (int j; j < 7; j++)
			for (int i; i <= MaxClients; i++)
			{
				if (client_voted[i][j])
					votes++;
			}

		if (votes >= clients_in_vote)
		{
			PrintToChatAll("VOTE ENDED");

			for (int j; j < 7; j++)
				for (int i; i <= MaxClients; i++)
					client_voted[i][j] = false;

			g_HasVoteStarted = false;
			g_MapVoteCompleted = true;
		}
		else
		{
			StartVote();
		}
	}
}*/