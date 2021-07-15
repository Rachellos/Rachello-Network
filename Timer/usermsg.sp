stock void PrintColorChat( int target, const char[] szMsg, any ... )
{
	char szBuffer[256];
	VFormat( szBuffer, sizeof( szBuffer ), szMsg, 3 );
	
	SendColorMessage( target, target, szBuffer );
}

stock void PrintColorChatAll( int author, const char[] szMsg, any ... )
{
	char szBuffer[256];
	VFormat( szBuffer, sizeof( szBuffer ), szMsg, 3 );
	
	for ( int client = 1; client <= MaxClients; client++ )
		if ( IsClientInGame( client ) && ( client == author || !(g_fClientHideFlags[client] & HIDEHUD_CHAT) ) )
		{
			if ( author == 0 )
			{
				SendColorMessage( client, client, szBuffer );
			}
			else
			{
				SendColorMessage( client, author, szBuffer );
			}
		}
}

stock void SendFade( int target, int flags = ( 1 << 0 ), int duration, const int color[4] )
{
	Handle hMsg = StartMessageOne( "Fade", target );
	
	if ( hMsg != null )
	{
		BfWriteShort( hMsg, duration );
		BfWriteShort( hMsg, 0 );
		BfWriteShort( hMsg, flags );
		BfWriteByte( hMsg, color[0] );
		BfWriteByte( hMsg, color[1] );
		BfWriteByte( hMsg, color[2] );
		BfWriteByte( hMsg, color[3] );
		
		EndMessage();
	}
}

stock void SendColorMessage( int target, int author, const char[] szMsg )
{
	Handle hMsg = StartMessageOne( "SayText2", target, USERMSG_BLOCKHOOKS );
	
	if ( hMsg != null )
	{
		BfWriteByte( hMsg, author );
		
		// false for no console print. If false, no chat sound is played.
		BfWriteByte( hMsg, true );
		
		BfWriteString( hMsg, szMsg );

		
		EndMessage();
	}
}

stock void ShowKeyHintText( int client, int target )
{
	if ( TF2_GetPlayerClass(client) != TFClass_DemoMan && TF2_GetPlayerClass(client) != TFClass_Soldier && GetClientTeam( client ) != TFTeam_Spectator ) return;
	/*static clients[2];
	
	clients[0] = client;
	Handle hMsg = StartMessageEx( g_UsrMsg_HudMsg, clients, 1 );*/
	char szSpectators[100] = "";
	char szName[15] = "";
	int Spec_Count = 0;
	for (int i = 1; i < MaxClients; i++){
		if (!IsClientInGame(i) || !IsClientObserver(i))
				continue;
				
		int iSpecMode = GetEntProp(i, Prop_Send, "m_iObserverMode");
			
			// The client isn't spectating any one person, so ignore them.
		if (iSpecMode != 4 && iSpecMode != 5)
				continue;
			
			// Find out who the client is spectating.
		int iTarget = GetEntPropEnt(i, Prop_Send, "m_hObserverTarget");
			
			// Are they spectating our player?
		if (iTarget == target)
		{
			Spec_Count++;
			GetClientName(i, szName, sizeof(szName));
			if (Spec_Count <= 5)
				Format(szSpectators, sizeof(szSpectators), "%s\n%s", szSpectators, szName);
			else
				Format(szSpectators, sizeof(szSpectators), "%s\n(+%i)", szSpectators, Spec_Count - 5);
		}
	}
	
	Handle hMsg = StartMessageOne( "KeyHintText", client );
	
	if ( hMsg != null )
	{
		static char szTime[TIME_SIZE_DEF];
		static char szBestTime[TIME_SIZE_DEF];
		static char szText[200];
		static bool bDesi;
		static char wr[32];
		static char szInterval[TIME_SIZE_DEF];
		static char szTxt[TIME_SIZE_DEF];
		static char tempuswr[TIME_SIZE_DEF], tempuspr[TIME_SIZE_DEF];
		static int run;
		static int style;
		static int mode;
		run = g_iClientRun[target];
		style = g_iClientStyle[target];
		mode = g_iClientMode[target];
		FormatSeconds( g_TempusWrTime[run][mode], tempuswr, FORMAT_3DECI );
		FormatSeconds( g_TempusPrTime[target][run][mode], tempuspr, FORMAT_3DECI );
		float interval;
		interval = g_flClientBestTime[target][run][mode] - g_flMapBestTime[run][style][mode];
		static int time;
		GetMapTimeLeft(time);
		char times[100];
		char tempus_info[100], tempus_info_pr[100];
		FormatEx(tempus_info, sizeof(tempus_info), " \nTempus WR:\n%s (%s)\n", 
			(g_TempusWrTime[run][mode] == TIME_INVALID) ? "None" : tempuswr,
			(g_TempusWrTime[run][mode] == TIME_INVALID) ? "" : sz_TempusWrName[run][mode]);

		FormatEx(tempus_info_pr, sizeof(tempus_info_pr), "\nTempus PR:\n%s\n", 
			(g_TempusPrTime[target][run][mode] == TIME_INVALID) ? "None" : tempuspr);

		if ( time > 60 )
		{
			int tims = time / 60;
			FormatEx(times, sizeof(times), "%i minutes remaining", tims);
		}
		else if (time >= 30)
		{
			FormatEx(times, sizeof(times), "> 30 sec remaining");
		}
		else if (time < 30 && time > 10)
		{
			FormatEx(times, sizeof(times), "< 30 sec remaining");
		}
		else if(time < 10 && time > 0)
		{
			FormatEx(times, sizeof(times), "%i sec remaining", time);
		}
		else if (time <= 0)
		{
			FormatEx(times, sizeof(times), "Map ending...");
		}
		if ( !IsFakeClient( target ) || IsFakeClient( target ) )
		{

		  if ( g_flClientBestTime[target][run][mode] != TIME_INVALID )
			{
				FormatSeconds( g_flClientBestTime[target][run][mode], szTime, FORMAT_3DECI );
			}
			else
			{
				FormatEx( szTime, sizeof( szTime ), "None" );
			}
			
			if ( g_flMapBestTime[run][style][mode] != TIME_INVALID )
			{
				FormatEx( wr, sizeof( wr ), "(%s)", szWrName[run][mode] );
				FormatSeconds( g_flMapBestTime[run][style][mode], szBestTime, FORMAT_3DECI );
			
			}
			else
			{
				FormatEx( wr, sizeof( wr ), "" );
				FormatEx( szBestTime, sizeof( szBestTime ), "None" );
				
			}

			if ( g_flClientBestTime[target][run][mode] <= g_flMapBestTime[run][style][mode] || g_flClientBestTime[target][run][mode] <= TIME_INVALID)
			{
				FormatEx( szTxt, sizeof( szTxt ), "");
			}
			else if ( g_flClientBestTime[target][run][mode] > g_flMapBestTime[run][style][mode] || g_flClientBestTime[target][run][mode] > TIME_INVALID)
			{
				FormatSeconds( interval, szInterval, FORMAT_3DECI );
				FormatEx( szTxt, sizeof( szTxt ), "(+%s)", szInterval );
			}
	
			
			static char szStylePostFix[STYLEPOSTFIX_LENGTH];
			GetStylePostfix( g_iClientMode[target], szStylePostFix );
			
			FormatEx( szText, sizeof( szText ), "%s\n\n::%s%s::\n\nPersonal Record:\n%s %s\n\nWorld Record:\n%s %s\n%s",
					times,
					g_szStyleName[NAME_LONG][style],
					szStylePostFix,
					szTime,
					szTxt,
					szBestTime,
					wr,
					(!(g_fClientHideFlags[client] & HIDEHUD_TEMPUSWR)) ? tempus_info : ""/*,
					(!(g_fClientHideFlags[client] & HIDEHUD_TEMPUSPR)) ? tempus_info_pr : ""*/
					);

			if ( g_bClientPractising[target] || run == RUN_SETSTART )
			{
					FormatEx( szText, sizeof( szText ), "%s\n\n", times);
			}
	
		}
		
		if (!(g_fClientHideFlags[client] & HIDEHUD_SPECTYPE))
			Format(szText, sizeof(szText), "%s\nSpectators: %i", szText, Spec_Count);
		else
			Format(szText, sizeof(szText), "%s\nSpectator list:%s", szText, szSpectators);
		
		BfWriteByte( hMsg, 1 );
		BfWriteString( hMsg, szText );
		
		EndMessage();
	}
}