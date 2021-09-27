#include <morecolors>
public Action Event_SetTransmit_Client( int ent, int client )
{
	if ( ent < 1 || ent > MaxClients || client == ent ) return Plugin_Continue;
	
	
	if ( !IsPlayerAlive( client ) && GetEntPropEnt( client, Prop_Send, "m_hObserverTarget" ) == ent )
	{
		return Plugin_Continue;
	}
	
	
	if ( IsFakeClient( ent ) )
	{
		return ( g_fClientHideFlags[client] & HIDEHUD_BOTS ) ? Plugin_Handled : Plugin_Continue;
	}
	
	return ( g_fClientHideFlags[client] & HIDEHUD_PLAYERS ) ? Plugin_Handled : Plugin_Continue;
}

// Tell the client to respawn!
public Action Event_ClientDeath( Handle hEvent, const char[] szEvent, bool bDontBroadcast )
{
	int client;

	if ( !(client = GetClientOfUserId( GetEventInt( hEvent, "userid" ) )) ) return;

	g_iClientState[client] = STATE_INVALID;			
	g_iClientRun[client] = RUN_INVALID;
	//PRINTCHAT( client, CHAT_PREFIX..."Type "...CLR_TEAM..."!r"...CLR_TEXT..." to spawn." );
}

// Hide bot name changes.
// First byte is always the author and in name changes they are the 'changeer'.
// Since we only want to block bot name changes, we can just block all of their messages.

public void SayText2(int client, int author, const char[] message)
{
	Handle hBuffer = StartMessageOne("SayText2", client);
	BfWriteByte(hBuffer, author);
	BfWriteByte(hBuffer, true);
	BfWriteString(hBuffer, "");
	EndMessage();
}

public void Event_WeaponDropPost( int client, int weapon )
{
		
}

public Action Event_ClientSpawn( Handle hEvent, const char[] szEvent, bool bDontBroadcast )
{
	int client = GetClientOfUserId( GetEventInt( hEvent, "userid" ) );
	
	
	if ( client < 1 || client > MaxClients || GetClientTeam( client ) < 2 || !IsPlayerAlive( client ) ) return;
	
	if (g_bClientPractising[client])
		g_bClientPractising[client] = false;
	
	isHudDrawing[client] = false;
	TimeToDrawHud[client] = GetEngineTime();
	LastHudDrawing[client] = GetEngineTime();

	if (TF2_GetPlayerClass(client) == TFClass_Soldier)
	{
		SetPlayerStyle(client, STYLE_SOLLY );
	}		
	if (TF2_GetPlayerClass(client) == TFClass_DemoMan)
	{
		SetPlayerStyle(client, STYLE_DEMOMAN );
	}
	
	// 2 = Disable player collisions.
	// 1 = Same + no trigger collision.
	SetEntProp( client, Prop_Send, "m_CollisionGroup", IsFakeClient( client ) ? 1 : 2 );
	
	if(!IsFakeClient(client)) g_iClientMode[client] = getClass(client);
}

public void BlockBounces(int client)
{	
	QueryClientConVar(client, "cl_pitchdown", BlockPitchDown, client);
	QueryClientConVar(client, "cl_pitchup", BlockPitchUp, client);	
}

public void BlockPitchDown(QueryCookie cookie, int client, ConVarQueryResult result, char[] cvarName, char[] cvarValue)
{
    if(!StrEqual(cvarValue, "89"))
    {
        KickClient(client, "The use of cl_pitchdown on this server is disabled. Please disable it before re-connecting to the server");
    }
}
public void BlockPitchUp(QueryCookie cookie, int client, ConVarQueryResult result, char[] cvarName, char[] cvarValue)
{
    if(!StrEqual(cvarValue, "89"))
    {
        KickClient(client, "The use of cl_pitchup on this server is disabled. Please disable it before re-connecting to the server");
    }
}

public Action Event_OnTakeDamage_Client( int victim, int &attacker, int &inflictor, float &flDamage, int &fDamage )
{
	
	
	return Plugin_Continue;
}

public Action Event_RoundRestart( Handle hEvent, const char[] szEvent, bool bDontBroadcast )
{
	RequestFrame( Event_RoundRestart_Delay );
}

public void Event_RoundRestart_Delay( any data )
{
	CheckZones();
}

public void CPrintToChatClientAndSpec(int client, const char[] text, any...)
{
	char szBuffer[256];
	VFormat( szBuffer, sizeof( szBuffer ), text, 3 );

	for (int i = 1; i <= MaxClients; i++)
		if ( ( (IsClientInGame(i) && !IsPlayerAlive(i) ) || i == client) && !(g_fClientHideFlags[i] & HIDEHUD_CHAT))
			if (GetEntPropEnt(i, Prop_Send, "m_hObserverTarget") == client || i == client)
			{
				CPrintToChat( i, szBuffer );
			}
}

public void Event_Touch_Zone( int trigger, int client )
{
	if ( client < 1 || client > MaxClients || !IsClientInGame(client) || !IsClientConnected(client) ) return;

	int	iData[ZONE_SIZE];
	g_hZones.GetArray( GetTriggerIndex( trigger ), iData, view_as<int>( ZoneData ) );
	int zone = iData[ZONE_TYPE];

	int id = iData[ZONE_ID];
	int run = zone/2;

	bool IsStartZone = (zone % 2 == 0 );
	if ( IsStartZone )
	{
		if (EnteredZone[client] == zone && g_iClientState[client] == STATE_START) return;

		if ( (!RunIsCourse(run) || run == RUN_COURSE1))
		{
			IsMapMode[client] = true;
			DisplayCpTime[client] = false;
			g_iClientRun[client] = run;
		}
		else
		{
			if ( (g_iClientState[client] == STATE_END && g_iClientRun[client] == run - 1) || g_iClientRun[client] >= run || !IsMapMode[client] )
			{
				g_iClientRun[client] = run;
			}
			else
			{
				if (g_iClientRun[client] != RUN_MAIN && !g_bClientPractising[client] )
				{
					EmitSoundToClient( client, g_szSoundsMissCp[0] );

					CPrintToChatClientAndSpec(client, "{red}ERROR {white}| Your run has been closed. You missed:");

					for (int i = (( run - ( run - g_iClientRun[client] ) ) * 2)+1; i < run*2; i++)
						CPrintToChatClientAndSpec(client, "{red}ERROR {white}| {orange}%s",
							g_szZoneNames[i]);
				}
				IsMapMode[client] = false;
				DisplayCpTime[client] = false;
				g_iClientRun[client] = run;
			}
		}
		ChangeClientState( client, STATE_START );
	}
	else
	{
		if ( g_flClientStartTime[client] == TIME_INVALID ) return;
		if ( GetEntityMoveType( client ) == MOVETYPE_NOCLIP ) return;
		if ( g_iClientRun[client] != run ) return;
		if ( g_bClientPractising[client] ) return;
		if (g_iClientState[client] == STATE_END) return;
		
		ChangeClientState( client, STATE_END );

		if (!RunIsCourse(run))
		{
			g_flClientFinishTime[client] = GetEngineTime() - g_flClientStartTime[client];
			g_flTicks_End[client] = GetGameTickCount() - STVTickStart;

			DB_SaveClientRecord( client, g_flClientFinishTime[client] );
		}
		else
		{
			g_flTicks_Cource_End[client] = GetGameTickCount() - STVTickStart;
			flNewTimeCourse[client] = GetEngineTime() - g_flClientCourseStartTime[client];
			g_flClientFinishTime[client] = flNewTimeCourse[client];
			DB_SaveClientRecord( client, flNewTimeCourse[client] );

			if ( IsMapMode[client] && ( run == RUN_COURSE10 || !g_bIsLoaded[run+1] ) )
			{
				g_flClientFinishTime[client] = GetEngineTime() - g_flClientStartTime[client];
				g_flTicks_End[client] = GetGameTickCount() - STVTickStart;

				g_iClientRun[client] = RUN_MAIN;

				DB_SaveClientRecord( client, g_flClientFinishTime[client] );
			}
		}
	}
	g_iClientRun[client] = run;
	EnteredZone[client] = zone;
}

public void Event_EndTouchPost_Zone( int trigger, int client )
{
	if ( client < 1 || client > MaxClients || !IsClientInGame(client) || !IsClientConnected(client) ) return;
	
	int	iData[ZONE_SIZE];
	g_hZones.GetArray( GetTriggerIndex( trigger ), iData, view_as<int>( ZoneData ) );

	int zone = iData[ZONE_TYPE]
	, id = iData[ZONE_ID]
	, run = zone/2;

	bool IsStartZone = (zone % 2 == 0 );

	if ( !IsStartZone) return;

	if ( IsStartZone )
	{
		ChangeClientState( client, STATE_RUNNING );

		if (!RunIsCourse(run) || run == RUN_COURSE1)
		{
			for (int a = 0; a < 100; a++)
			{
				g_iClientCpsEntered[client][a] = false;
			}

			if ( g_hClientCPData[client] != null )
			{
				delete g_hClientCPData[client];
			}

			g_hClientCPData[client] = new ArrayList( view_as<int>( C_CPData ) );
			g_iClientCurCP[client] = -1;
			DisplayCpTime[client] = false;

			g_flClientStartTime[client] = GetEngineTime();
			g_flTicks_Start[client] = GetGameTickCount() - STVTickStart;
			if (run == RUN_COURSE1)
			{
				g_flClientCourseStartTime[client] = GetEngineTime();
				g_flTicks_Cource_Start[client] = GetGameTickCount() - STVTickStart;
			}
		}
		else
		{
			g_flClientCourseStartTime[client] = GetEngineTime();
			g_flTicks_Cource_Start[client] = GetGameTickCount() - STVTickStart;

			if (!IsMapMode[client])
				g_flClientStartTime[client] = GetEngineTime();
		}
	}
	EnteredZone[client] = ZONE_INVALID;
	return;
}

public void Event_StartTouchPost_Block( int trigger, int ent )
{
	if ( ent < 1 || ent > MaxClients ) return;
	
	if ( g_bClientPractising[ent] ) return;
	
	if ( !IsClientInGame( ent ) ) return;
	
	static int zone;
	zone = GetTriggerIndex( trigger );
	EnteredZone[ent] = zone;
	
	PRINTCHAT( ent, CHAT_PREFIX..."You are not allowed to go there!" );
		
	TeleportPlayerToStart( ent );
}

public void Event_StartTouchPost_NextCours( int trigger, int ent )
{
	if ( ent < 1 || ent > MaxClients ) return;
	
	if ( g_bClientPractising[ent] ) return;
	
	if ( !IsClientInGame( ent ) ) return;
	
	static int zone;
	zone = GetTriggerIndex( trigger );
	EnteredZone[ent] = zone;

	if (g_iClientRun[ent]+1 < NUM_RUNS && RUN_COURSE1 < g_iClientRun[ent]+1 <= RUN_COURSE10 && g_bIsLoaded[g_iClientRun[ent]+1])
		TeleportEntity( ent, g_vecSpawnPos[g_iClientRun[ent]+1], g_vecSpawnAngles[g_iClientRun[ent]+1], g_vecNull );
	else
		PrintToChat(ent, CHAT_PREFIX... "You cannot teleport to the next course because it does not exist.");
}

public void Event_StartTouchPost_Skip( int trigger, int ent )
{
	if ( ent < 1 || ent > MaxClients ) return;
	
	if ( g_bClientPractising[ent] ) return;
	
	if ( !IsClientInGame( ent ) ) return;

	if (g_iClientMode[ent] != g_iSkipMode) return;
	
	static int zone;
	zone = GetTriggerIndex( trigger );
	EnteredZone[ent] = zone;
	
	TeleportEntity( ent, g_vecSkipPos, g_vecSkipAngles, g_vecNull );
}

public void Event_StartTouchPost_CheckPoint( int trigger, int ent )
{
	if ( ent < 1 || ent > MaxClients ) return;

	EnteredZone[ent] = ZONE_CP;
	
	// I'm not even going to try get practising to work. It'll just be a major headache and nobody will notice it, anyway.
	if ( g_bClientPractising[ent] ) return;
	
	if ( !IsClientInGame( ent ) ) return;
	
	if ( g_hClientCPData[ent] == null ) return;
	
	if ( g_hCPs == null ) return;

	if ( !StrEqual(szTimerMode[ent], "Linear") && !StrEqual(szTimerMode[ent], "Map") )
		return;

	int cp, id;
	cp = GetTriggerIndex( trigger );
	if ( trigger != EntRefToEntIndex( g_hCPs.Get( cp, view_as<int>( CP_ENTREF ) ) ) )
	{
		LogError( CONSOLE_PREFIX..."Invalid checkpoint entity index!" );
		return;
	}
	
	// Player ended up in the wrong run! :(
	
	id = g_hCPs.Get( cp, view_as<int>( CP_ID ) );
	
	// Client attempted to re-enter the cp.
	if ( g_iClientCurCP[ent] >= id ) return;
	
	g_iClientCurCP[ent] = id;

	float 	flBestTime,
	 		flMyTime,
			flLeftSeconds,
			flCurTime,
			flTime;

	char 	CheckpointInfo[100],
			szTime[TIME_SIZE_DEF],
			szTimeForHud[TIME_SIZE_DEF];
	
	int 	index, 
			prefix, 
			iCData[C_CP_SIZE];

	flCurTime = GetEngineTime();
	flTime = flCurTime - g_flClientStartTime[ent];

	flBestTime = (g_fClientHideFlags[ent] & HIDEHUD_PRTIME) ? f_CpPr[ent][g_iClientMode[ent]][id] 
															: f_CpWr[g_iClientMode[ent]][id];
		
	// Determine what is our reference time.
	// If no previous checkpoint is found, it is our starting time.
	
	index = g_hClientCPData[ent].Length - 1;
	
	if ( index >= 0 )
		g_hClientCPData[ent].GetArray( index, iCData, view_as<int>( C_CPData ) );	

	flMyTime = flCurTime - g_flClientStartTime[ent];
	
	if ( flBestTime > flMyTime )
	{
		flLeftSeconds = flBestTime - flMyTime;
		prefix = '-';
	}
	else
	{
		flLeftSeconds = flMyTime - flBestTime;
		prefix = '+';
	}

	if (index < 0 || id == CpBlock[ent])
	{
		CpPlusSplit[ent] = prefix;
		FormatSeconds( flTime, szTime, FORMAT_2DECI );
		FormatSeconds( flLeftSeconds, szCPTime, FORMAT_2DECI );
		FormatSeconds( flLeftSeconds, szTimeForHud, FORMAT_2DECI );

		FormatEx(CpTimeSplit[ent], sizeof(CpTimeSplit), "%s", szTimeForHud);

		CpBlock[ent] = id + 1;
		DisplayCpTime[ent] = true;

		if (flBestTime > TIME_INVALID)
		{
			DisplayCpTime[ent] = true;
			FormatEx(CheckpointInfo, sizeof(CheckpointInfo), " {white}( \x0750DCFF%s %c%s {white})", g_fClientHideFlags[ent] & HIDEHUD_PRTIME ? "PR" : "WR", prefix, szCPTime);
		}
		else
		{
			DisplayCpTime[ent] = false;
			FormatEx(CheckpointInfo, sizeof(CheckpointInfo), "");
		}

		CPrintToChatClientAndSpec( ent, CHAT_PREFIX..."Entered \x0750DCFFCheckpoint %i. {white}Total: \x0764E664%s%s", id + 1, szTime, CheckpointInfo );
	}
	else
	{
		DisplayCpTime[ent] = false;
		CPrintToChatClientAndSpec(ent, CHAT_PREFIX..."Wrong map passing. Run Closed");

		SetPlayerPractice( ent, true );
		return;
	}

	g_iClientCpsEntered[ent][id] = true;

	iCData[C_CP_ID] = id;
	iCData[C_CP_INDEX] = cp;
	iCData[C_CP_GAMETIME] = flCurTime;
	
	g_hClientCPData[ent].PushArray( iCData, view_as<int>( C_CPData ) );
}