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

	static char szTime[TIME_SIZE_DEF],
					szBestTime[TIME_SIZE_DEF],
					szText[200],
					szInterval[TIME_SIZE_DEF],
					szTxt[TIME_SIZE_DEF],
					tempuswr[TIME_SIZE_DEF],
					szSpectators[200] = "",
					szSpecCount[10],
					WorldRecord[100];

	int Spec_Count = 0;
	for (int i = 1; i < MaxClients; i++)
	{
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
			if (Spec_Count <= 5)
				FormatEx(szSpectators, sizeof(szSpectators), "%s\n%N", szSpectators, i);
		}
	}
	
	Handle hMsg = StartMessageOne( "KeyHintText", client );
	
	if ( hMsg != null )
	{
		int run = g_iClientRun[target];
		int style = g_iClientStyle[target];
		int mode = g_iClientMode[target];
		int timeleft;
		GetMapTimeLeft(timeleft);

		char remaining[100],
				tempus_info[100];
				//tempus_info_pr[100];

		FormatSeconds( g_TempusWrTime[run][mode], tempuswr, FORMAT_3DECI );
		//FormatSeconds( g_TempusPrTime[target][run][mode], tempuspr, FORMAT_3DECI );
		
		FormatEx(tempus_info, sizeof(tempus_info), " \nTempus WR:\n%s (%s)\n", 
			(g_TempusWrTime[run][mode] == TIME_INVALID) ? "None" : tempuswr,
			(g_TempusWrTime[run][mode] == TIME_INVALID) ? "" : sz_TempusWrName[run][mode]);

		/*FormatEx(tempus_info_pr, sizeof(tempus_info_pr), "\nTempus PR:\n%s\n", 
			(g_TempusPrTime[target][run][mode] == TIME_INVALID) ? "None" : tempuspr);*/

		if ( timeleft > 60 )
		{
			int mins = timeleft / 60;
			FormatEx(remaining, sizeof(remaining), "%i minutes remaining", mins);
		}
		else if (timeleft >= 30)
		{
			FormatEx(remaining, sizeof(remaining), "> 30 sec remaining");
		}
		else if (timeleft < 30 && timeleft > 10)
		{
			FormatEx(remaining, sizeof(remaining), "< 30 sec remaining");
		}
		else if(timeleft < 10 && timeleft > 0)
		{
			FormatEx(remaining, sizeof(remaining), "%i sec remaining", timeleft);
		}
		else if (timeleft <= 0)
		{
			FormatEx(remaining, sizeof(remaining), "Map ending...");
		}

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
			FormatSeconds( g_flMapBestTime[run][style][mode], szBestTime, FORMAT_3DECI );
			FormatEx( WorldRecord, sizeof( WorldRecord ), "%s (%s)", szBestTime, szWrName[run][mode] );
		}
		else
		{
			FormatEx( WorldRecord, sizeof( WorldRecord ), "None" );
		}

		if ( g_flClientBestTime[target][run][mode] <= g_flMapBestTime[run][style][mode] || g_flClientBestTime[target][run][mode] <= TIME_INVALID)
		{
			FormatEx( szTxt, sizeof( szTxt ), "");
		}
		else if ( g_flClientBestTime[target][run][mode] > g_flMapBestTime[run][style][mode])
		{
			float interval = g_flClientBestTime[target][run][mode] - g_flMapBestTime[run][style][mode];
			
			FormatSeconds( interval, szInterval, FORMAT_3DECI );
			FormatEx( szTxt, sizeof( szTxt ), "(+%s)", szInterval );
		}

		if ( !g_bClientPractising[target] || run != RUN_SETSTART )
		{
			static char szStylePostFix[STYLEPOSTFIX_LENGTH];
			GetStylePostfix( g_iClientMode[target], szStylePostFix );
			
			FormatEx( szText, sizeof( szText ), "%s\n\n::%s%s::\n\nPersonal Record:\n%s %s\n\nWorld Record:\n%s\n%s",
					remaining,
					g_szStyleName[NAME_LONG][style], szStylePostFix,
					szTime,
					szTxt,
					WorldRecord,
					(!(g_fClientHideFlags[client] & HIDEHUD_TEMPUSWR)) ? tempus_info : ""/*,
					(!(g_fClientHideFlags[client] & HIDEHUD_TEMPUSPR)) ? tempus_info_pr : ""*/
					);
		}
		else
		{
			FormatEx( szText, sizeof( szText ), "%s\n\n", remaining);
		}
		
		FormatEx(szSpecCount, sizeof(szSpecCount), "(+%i)", Spec_Count-5);

		if (!(g_fClientHideFlags[client] & HIDEHUD_SPECTYPE))
			Format(szText, sizeof(szText), "%s\nSpectators: %i", szText, Spec_Count);
		else
			Format(szText, sizeof(szText), "%s\nSpectator list:%s\n%s", szText, szSpectators, ((Spec_Count-5) > 0) ? szSpecCount : "");
		
		BfWriteByte( hMsg, 1 );
		BfWriteString( hMsg, szText );
		
		EndMessage();
	}
}