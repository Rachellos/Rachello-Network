
public Action Timer_Connected( Handle hTimer, int client )
{
    if ( !(client = GetClientOfUserId( client )) ) return Plugin_Handled;
   
   
    CPrintToChat( client,  CHAT_PREFIX..."Welcome to the \x0750DCFFRachello Network {white}!");

    char i_SteamID[50];
	GetClientAuthId(client, AuthId_Steam3, i_SteamID, sizeof(i_SteamID));

	if (StrEqual(i_SteamID, "[U:1:1230320973]"))
    	CPrintToChat( client,  CHAT_PREFIX..."Боши ты заебал бегать, чего очкуешь то? бан на темпусе словил и кукухой ебнулся?");
   
    if ( !g_bIsLoaded[RUN_MAIN] && !g_bIsLoaded[RUN_COURSE1])
    {
        PRINTCHAT( client, CHAT_PREFIX..."No records are available for this map!" );
    }
   
    return Plugin_Handled;
}

public Action Timer_regencheck( Handle hTimer )
{
    int iclient;
    int iWeapon = -1;
    int ammo;
	for ( iclient = 1; iclient <= MaxClients; iclient++ )
    {
		if (IsClientConnected(iclient) && IsClientInGame(iclient) && IsPlayerAlive(iclient))
		{
            BlockBounces(iclient);
            if ( (szClass[g_iClientRun[iclient]][g_iClientMode[iclient]] <= 0 && !RegenOn[iclient]) || RegenOn[iclient])
            {
                    TF2_RegeneratePlayer(iclient);
            }     
        }     
	}
    return Plugin_Continue;	
}

public Action Timer_Ad( Handle hTimer )
{
	char ad[8][300] = 
    {
    	"Use \x0750DCFF/settings {white}to customise your HUD, chat and more!",
    	"Welcome to the \x0750DCFFRachello Jump Network{white}!",
    	"Join us on Discord at {lightskyblue}discord.gg/8khRBCEu5C",
    	"Does your game freeze sometimes when another player joins? Try setting \x0750DCFFcl_allowdownload 0 {white}to disable downloading player sprays.",
    	"Type \x0750DCFF/p {white}to view your stats!",
    	"Type \x0750DCFF/top {white}for the best times.",
    	"Need an admin? Use \x0750DCFF!calladmin {white}for any urgent issues and we'll get back to you when possible.",
    	"Don't know where to go, or how to do a jump? Try \x0750DCFF/svid {white}and \x0750DCFF/dvid {white}to watch a showcase (not available for all maps).",
    };

    int arr_len = 8;

    static int msg;
    if (msg >= arr_len) msg = 0;

    for ( int iclient = 1; iclient <= MaxClients; iclient++ )
    {
        if (IsClientConnected(iclient) && IsClientInGame(iclient) && (!(g_fClientHideFlags[iclient] & HIDEHUD_CHAT) || !(g_fClientHideFlags[iclient] & HIDEHUD_CHAT_AD)))
        {
            CPrintToChat(iclient, CHAT_PREFIX_TIP..."%s", ad[msg]);
        }
    }
    msg++;
    return Plugin_Continue; 
}

public Action Timer_EmptyQuery( Handle hTimer, int data )
{
	g_hDatabase.Query(Threaded_Empty, "Select uid from plydata limit 1");
	return Plugin_Continue;
}

// Main component of the HUD timer.
public void OnGameFrame()
{
    int client
        , target
        , prefix
        , run
        , mode;

    float flCurTime, TimeSplit;

    char hintOutput[256]
        , speed[32]
        , CpSplit[100]
        , szCurTime[TIME_SIZE_DEF]
        , szTimeSplit[TIME_SIZE_DEF];

    for ( client = 1; client <= MaxClients; client++ )
    {
        if ( !IsClientInGame( client ) || !IsClientConnected(client) || IsFakeClient( client ) || IsClientSourceTV( client )) continue;

        target = client;

        //Handle userMessage = StartMessageOne("HintText", client);

        // Dead? Find the player we're spectating.
        if ( GetClientTeam( client ) == TFTeam_Spectator)
        {
            target = GetClientSpecTarget( client );

            // Invalid spec target?
            // -1 = No spec target.
            // No target? No HUD.

            if ( target < 1 || target > MaxClients || !IsPlayerAlive( target ) )
            {
                continue;
            }
            int iSpecMode = GetEntProp(client, Prop_Send, "m_iObserverMode");
			
			// The client isn't spectating any one person, so ignore them.
		    if (iSpecMode != 4 && iSpecMode != 5)
				continue;
        }

        
		if ( TF2_GetPlayerClass(target) != TFClass_DemoMan && TF2_GetPlayerClass(target) != TFClass_Soldier && GetClientTeam( target ) != TFTeam_Spectator ) { isHudDrawing[target] = false; TimeToDrawHud[target] = TIME_INVALID; continue; }
        
        if ( !(g_fClientHideFlags[client] & HIDEHUD_SIDEINFO) )
        {
            ShowKeyHintText( client, target );
        }

        if ( g_fClientHideFlags[client] & HIDEHUD_CENTRAL_HUD) { isHudDrawing[client] = false; TimeToDrawHud[client] = TIME_INVALID; continue; }
        
        run = g_iClientRun[target];
        mode = g_iClientMode[target];
        
        if (g_iClientRun[target] == RUN_INVALID || g_iClientState[target] == STATE_INVALID || g_iClientRun[target] == RUN_SETSTART ) {isHudDrawing[client] = false; TimeToDrawHud[client] = TIME_INVALID; continue;}

        if (DisplayCpTime[target])
            FormatEx(CpSplit, sizeof(CpSplit), "(%s %c%s)\n", g_fClientHideFlags[target] & HIDEHUD_PRTIME ? "PR" : "WR", CpPlusSplit[target], CpTimeSplit[target]);

        if ( szClass[g_iClientRun[target]][g_iClientMode[target]] <= 0 || RegenOn[target])
        {
            FormatEx(szAmmo[target], sizeof(szAmmo), "+regen");
        }
        else
        {
            FormatEx(szAmmo[target], sizeof(szAmmo), "");
        }

        if ( g_fClientHideFlags[client] & HIDEHUD_SPEED )
            FormatEx(speed, sizeof( speed ), "\n(%.0f u/s)\n ", GetEntitySpeed(target));

        if ( RunIsBonus(g_iClientRun[target]) )
                FormatEx( szTimerMode[target], sizeof(szTimerMode), "Bonus");

        else if ( g_iClientRun[target] == RUN_MAIN || RunIsCourse(g_iClientRun[target]))
            FormatEx( szTimerMode[target], sizeof(szTimerMode), "%s", (IsMapMode[target]) ?
                ((RunIsCourse(g_iClientRun[target])) ? "Map" : "Linear") : "Course" );     

        if ( g_iClientRun[target] == RUN_SETSTART )
        {
            continue;
        }
        else if (g_iClientState[target] == STATE_END)
        {
            if ( RUN_COURSE1 <= run < RUN_COURSE10 && g_bIsLoaded[run + 1] && IsMapMode[target])
                flCurTime = GetEngineTime() - g_flClientStartTime[target];
            else
                flCurTime = g_flClientFinishTime[target];

            FormatSeconds( flCurTime, szCurTime );

            float OldTime;

            if ( g_fClientHideFlags[client] & HIDEHUD_PRTIME )
                OldTime = szOldTimePts[target][run][mode];
            else
                OldTime = szOldTimeWr;

            if ( RUN_COURSE1 <= run < RUN_COURSE10 )
            {
                TimeSplit = (flNewTimeCourse[target] < OldTime) ? OldTime - flNewTimeCourse[target] : flNewTimeCourse[target] - OldTime;
                prefix = (flNewTimeCourse[target] < OldTime) ? '-' : '+';
            }
            else
            {
                TimeSplit = (g_flClientFinishTime[target] < OldTime) ? OldTime - g_flClientFinishTime[target] : g_flClientFinishTime[target] - OldTime;
                prefix = (g_flClientFinishTime[target] < OldTime) ? '-' : '+';       
            }

            FormatSeconds( TimeSplit, szTimeSplit );
            if ( !(g_fClientHideFlags[client] & HIDEHUD_TIMER) )
            {
                FormatSeconds( flCurTime, szCurTime );
                StrCat(szCurTime, sizeof(szCurTime), "\n");
            }
            Format(hintOutput, 256, "%s(%s %c%s)\n \n[%s End]\n %s\n%s mode %s", szCurTime, (g_fClientHideFlags[client] & HIDEHUD_PRTIME) ? "PR" : "WR", prefix, szTimeSplit, g_szRunName[NAME_LONG][run], speed, szTimerMode[target], szAmmo[target] );
        }     
        else if ( g_iClientState[target] == STATE_START )
        {
            flCurTime = GetEngineTime() - g_flClientStartTime[target];
            if ( !(g_fClientHideFlags[client] & HIDEHUD_TIMER) )
            {
                FormatSeconds( flCurTime, szCurTime );
            }
            Format(hintOutput, 256, "%s\n \n[%s Start]\n %s\n%s mode %s", IsMapMode[target] ? ( (RunIsCourse(g_iClientRun[target]) && g_iClientRun[target] != RUN_COURSE1) ? szCurTime : g_szCurrentMap ) : g_szCurrentMap, g_szRunName[NAME_LONG][ g_iClientRun[target] ], speed, szTimerMode[target], szAmmo[target] );
        }
        else
        {
            flCurTime = GetEngineTime() - g_flClientStartTime[target];
        
            static float flBestTime;
            flBestTime = g_flMapBestTime[ g_iClientRun[target] ][ g_iClientStyle[target] ][ g_iClientMode[target] ];

            if ( !(g_fClientHideFlags[client] & HIDEHUD_TIMER) )
            {
                FormatSeconds( flCurTime, szCurTime );
                StrCat(szCurTime, sizeof(szCurTime), "\n");
            }
        
            Format(hintOutput, 256, " %s%s \n[%s]\n %s\n%s mode %s",
                szCurTime,
                CpSplit,
                g_szRunName[NAME_LONG][ g_iClientRun[target] ],
                speed,
                szTimerMode[target],
                szAmmo[target]
                );
        }
        if(g_bClientPractising[target])
        {
            Format(hintOutput, 256, "Timer Disabled Mode %s", szAmmo[target] );
        }

        //PrintHintText( client, hintOutput);
        //PrintHintText( client, "");
        if (!isHudDrawing[client] && (GetEngineTime() - LastHudDrawing[client]) > 0.5)
        {
            isHudDrawing[client] = true;
            PrintHintText( client, hintOutput);
            TimeToDrawHud[client] = GetEngineTime() + 0.6;
            LastHudDrawing[client] = GetEngineTime();
        }
        else if ( isHudDrawing[client] && (GetEngineTime() - TimeToDrawHud[client]) > 0.0 )
        {
            LastHudDrawing[client] = GetEngineTime();
            PrintHintText( client, hintOutput);
        }
    }
}

public Action Timer_EndMap( Handle hTimer )
{
    int time;
	GetMapTimeLeft(time);
    char map[32];
    if (time == 120)
        CPrintToChatAll("{lightskyblue}[2 minutes remaining]");
    else if (time == 60)
        CPrintToChatAll("{lightskyblue}[1 minute remaining]");
    else if (time == 30)
        CPrintToChatAll("{lightskyblue}[30 seconds remaining]");
    else if (time == 20)
        CPrintToChatAll("{lightskyblue}[20 seconds remaining]"); 
    else if (time == 10)
        CPrintToChatAll("{lightskyblue}[10 seconds remaining]");
    else if (time == 5)
        CPrintToChatAll("{lightskyblue}[5 seconds remaining]");   
    else if (time == 0)
    {
        GetNextMap(map, sizeof(map));
        CPrintToChatAll(CHAT_PREFIX..."Chenge map to {lightskyblue}%s", map);
    }
    else if (time == -3)
    {
        GetNextMap(map, sizeof(map));
        ServerCommand("changelevel %s", map);
    }
}
 
enum { POINT_BOTTOM, POINT_TOP, NUM_POINTS };
 
public Action Timer_DrawZoneBeams( int client, int args )
{  
    if (!IsClientInGame(client) || !IsPlayerAlive(client)) return Plugin_Handled;

    int len = ( g_hBeams == null ) ? 0 : g_hBeams.Length;
    int zone;
    int iCpData[CP_SIZE];
    int iZData[ZONE_SIZE];
    int indexes=0;
    int Cp_Id;
    bool isinside=false;

	for (int f=0; f < NUM_REALZONES; f++)
    {
        for (int c=0; c < 20;c++)
        {
            if (IsInsideBoundsPlayer( client, g_vecZoneMins[f][c], g_vecZoneMaxs[f][c] ))
            {
                isinside = true;
                zone = f;
                break;
            }
        }
    }

    for ( int i = 0; i < g_hZones.Length; i++ )
    {
        for (int index=0; index < 20; index++)
        {
            if (g_hZones.Get( i, view_as<int>( ZONE_ID ) ) == index )
            {
                g_hZones.GetArray( i, iZData, view_as<int>( ZoneData ) );
                
                float vecMins[3];
                float vecMaxs[3];

                ArrayCopy( iZData[ZONE_MINS], vecMins, 3 );
                ArrayCopy( iZData[ZONE_MAXS], vecMaxs, 3 );
                
                if (IsInsideBoundsPlayer( client, vecMins, vecMaxs ))
                {
                    isinside = true;
                    zone = iZData[ZONE_TYPE];
                    break;
                }
            }
        }
    }

    for ( int i = 0; i < g_hCPs.Length; i++ )
    {
        if (g_hCPs.GetArray( i, iCpData, view_as<int>( CPData ) ) )
        {
            float vecMins[3];
            float vecMaxs[3];

            ArrayCopy( iCpData[CP_MINS], vecMins, 3 );
            ArrayCopy( iCpData[CP_MAXS], vecMaxs, 3 );
            
            if (IsInsideBoundsPlayer( client, vecMins, vecMaxs ))
            {
                isinside = true;
                zone = ZONE_CP;
                Cp_Id = iCpData[CP_ID];
                break;
            }
        }
    }
     
    if (zone != ZONE_CP && zone < NUM_REALZONES)
    {           
        for (int c=0; c<20; c++)
        {
             if (g_bZoneExists[zone][c])
                indexes++;
        }
    }     

    if (!isinside) return Plugin_Handled;

    if (GetClientTeam(client) > 1)	
    {  
        for ( int z=0; z<20; z++ )
        {
            int iData[BEAM_SIZE];
            bool found = false;
            for (int i=0; i < len; i++)
            {
                if (zone != ZONE_CP)
                {
                    if (g_hBeams.Get(i, view_as<int>( BEAM_TYPE ) ) == zone && g_hBeams.Get(i, view_as<int>( BEAM_ID ) ) == z)
                    {
                        g_hBeams.GetArray( i, iData, view_as<int>( BeamData ) );
                        found = true;
                    }
                }
                else
                {
                    if (g_hBeams.Get(i, view_as<int>( BEAM_TYPE ) ) == zone && g_hBeams.Get(i, view_as<int>( BEAM_ID ) ) == Cp_Id)
                    {
                        g_hBeams.GetArray( i, iData, view_as<int>( BeamData ) );
                        found = true;
                    }
                }
            }

            if (!found) continue;
            
            zone = iData[BEAM_TYPE];

            if (!isinside) continue;        
            
            float vecZonePoints_Bottom[5][3];
            float vecZonePoints_Top[5][3];
            
            // We'll have to use the zone mins to check if they are close enough.
            ArrayCopy( iData[BEAM_POS_BOTTOM1], vecZonePoints_Bottom[0], 3 );
            ArrayCopy( iData[BEAM_POS_TOP3], vecZonePoints_Top[2], 3 );
            
            
            
            // Bottom
            ArrayCopy( iData[BEAM_POS_BOTTOM1], vecZonePoints_Bottom[0], 3 );
            ArrayCopy( iData[BEAM_POS_BOTTOM2], vecZonePoints_Bottom[1], 3 );
            ArrayCopy( iData[BEAM_POS_BOTTOM3], vecZonePoints_Bottom[2], 3 );
            ArrayCopy( iData[BEAM_POS_BOTTOM4], vecZonePoints_Bottom[3], 3 );
            
            // Top
            ArrayCopy( iData[BEAM_POS_TOP1], vecZonePoints_Top[0], 3 );
            ArrayCopy( iData[BEAM_POS_TOP2], vecZonePoints_Top[1], 3 );
            ArrayCopy( iData[BEAM_POS_TOP3], vecZonePoints_Top[2], 3 );
            ArrayCopy( iData[BEAM_POS_TOP4], vecZonePoints_Top[3], 3 );
            
            #define ZONE_BEAM_ALIVE         10.0
            // Bottom
            for (int i = 0; i < 4; i++)
            {
                TE_SetupBeamPoints( vecZonePoints_Bottom[i], vecZonePoints_Bottom[(i == 3) ? 0 : i+1], g_iBeam, 0, 0, 0, ZONE_BEAM_ALIVE, ZONE_WIDTH, ZONE_WIDTH, 0, 0.0, clrBeam[GREEN_ZONE], 0 );
                TE_SendToClient(client);
            }
            // Top
            for (int i = 0; i < 4; i++)
            {
                TE_SetupBeamPoints( vecZonePoints_Top[i], vecZonePoints_Top[(i == 3) ? 0 : i+1], g_iBeam, 0, 0, 0, ZONE_BEAM_ALIVE, ZONE_WIDTH, ZONE_WIDTH, 0, 0.0, clrBeam[GREEN_ZONE], 0 );
                TE_SendToClient(client);
            }
            // From bottom to top.
            for (int i = 0; i < 4; i++)
            {
                TE_SetupBeamPoints( vecZonePoints_Bottom[i], vecZonePoints_Top[i], g_iBeam, 0, 0, 0, ZONE_BEAM_ALIVE, ZONE_WIDTH, ZONE_WIDTH, 0, 0.0, clrBeam[GREEN_ZONE], 0 );
                TE_SendToClient(client);
            }
        }

        if (zone != ZONE_CP)
        {
            CPrintToChat(client, CHAT_PREFIX..."Drawing \x0750DCFF%i {white}trigger(s) for \x0750DCFF%s!", (indexes > 0) ? indexes : 1, g_szZoneNames[zone]);    
        }
        else
        {
            CPrintToChat(client, CHAT_PREFIX..."Drawing \x0750DCFF1 {white}trigger(s) for \x0750DCFFCheckpoint %i!", Cp_Id+1);     
        }
    }
    return Plugin_Continue;
}

public Action Timer_DrawZoneBeamsList( int client, int args )
{
    if (!client || !IsPlayerAlive(client)) return Plugin_Handled;

    Menu mMenu = new Menu(Handler_dzlist);
    
    char zoneinfo[10], zonename[50];
    int total = 0;

    int iCpData[CP_SIZE];

    for (int i=0; i < NUM_REALZONES; i++)
    {
        for (int z=0; z < 20;z++)
        {
            if (g_bZoneExists[i][z])
            {
                FormatEx(zoneinfo,sizeof(zoneinfo), "Z%i_%i", i, z);
                if (z > 0)
                {
                    FormatEx(zonename,sizeof(zonename), "%s #%i", g_szZoneNames[i], z+1);
                }
                else
                {
                    FormatEx(zonename,sizeof(zonename), "%s", g_szZoneNames[i]);
                }
                mMenu.AddItem(zoneinfo, zonename);
                total++;
            }
        }
    }

    for ( int i = 0; i < g_hCPs.Length; i++ )
    {
        if (g_hCPs.GetArray( i, iCpData, view_as<int>( CPData ) ) )
        {
            FormatEx(zoneinfo,sizeof(zoneinfo), "C%i_%i", i, iCpData[CP_ID]);
            FormatEx(zonename,sizeof(zonename), "Checkpoint %i", iCpData[CP_ID]+1);
            mMenu.AddItem(zoneinfo, zonename);
            total++;
        }
    }
    mMenu.SetTitle("List Of All Zones (%i Total)\n ", total);
    mMenu.Display(client, MENU_TIME_FOREVER);
}

public int Handler_dzlist( Menu mMenu, MenuAction action, int client, int item )
{
    if (client < 1) return 0;

    if ( action == MenuAction_End ) { delete mMenu; return 0; }
    if ( action == MenuAction_Cancel) return 0;
        
    if ( action != MenuAction_Select ) return 0;
    if ( action == MenuAction_Select )
    {
        char szItem[20];
        GetMenuItem( mMenu, item, szItem, sizeof( szItem ) );

        if (szItem[0] == 'Z')
        {
            ReplaceString(szItem, sizeof(szItem), "Z", "");

            char szInfo[2][10];
            if ( !ExplodeString( szItem, "_", szInfo, sizeof( szInfo ), sizeof( szInfo[] ) ) )
                return 0;
            int zone = StringToInt(szInfo[0]); 
            int index = StringToInt(szInfo[1]);

            DrawZoneListChoose(client, 0, zone, index);   
        }
        else
        {
            ReplaceString(szItem, sizeof(szItem), "C", "");

            char szInfo[2][10];
            if ( !ExplodeString( szItem, "_", szInfo, sizeof( szInfo ), sizeof( szInfo[] ) ) )
                return 0;

            int zone = StringToInt(szItem[0]);
            int index = StringToInt(szItem[1]);

            DrawZoneListChoose(client, ZONE_CP, zone, index);  
        }
    }
    return 0;
}

public void DrawZoneListChoose(int client, int mode, int zone, int index)
{
    Menu mMenu = new Menu(Handler_dzlistChoose);
    char zoneinfo[30], szIndex[20];
    if (mode != ZONE_CP)
    {
        if (index > 0)
            FormatEx(szIndex, sizeof(szIndex), " #%i", index+1);
        else
            FormatEx(szIndex, sizeof(szIndex), "");

        mMenu.SetTitle("Zone: %s%s\n ", g_szZoneNames[zone], szIndex);

        FormatEx(zoneinfo, sizeof(zoneinfo), "Z%i_%i", zone, index);

        mMenu.AddItem(zoneinfo, "Teleport to zone\n ");
        mMenu.AddItem(zoneinfo, "Draw Zone\n ");
    }
    else
    {
        int iCpData[CP_SIZE];
        if (g_hCPs.GetArray( zone, iCpData, view_as<int>( CPData ) ) )
        {
            mMenu.SetTitle("Zone: Checkpoint %i\n ", iCpData[CP_ID]+1);

            FormatEx(zoneinfo, sizeof(zoneinfo), "C%i_%i", zone, iCpData[CP_ID]);

            mMenu.AddItem(zoneinfo, "Teleport to zone\n ");
            mMenu.AddItem(zoneinfo, "Draw Zone\n ");
        }
    }
    mMenu.ExitBackButton = true;
    mMenu.Display(client, MENU_TIME_FOREVER);
}

public int Handler_dzlistChoose( Menu mMenu, MenuAction action, int client, int item )
{
    if (client < 1) return 0;

    if ( action == MenuAction_End ) { delete mMenu; return 0; }
    if ( action == MenuAction_Cancel)
    {
        if (item == MenuCancel_ExitBack)
        {
            ClientCommand(client, "sm_dzl");
        }
        return 0;
    } 
        
    if ( action != MenuAction_Select ) return 0;
    if ( action == MenuAction_Select )
    {
        char szItem[20];
        GetMenuItem( mMenu, item, szItem, sizeof( szItem ) );

        static int iCpData[CP_SIZE];
        int len = ( g_hBeams == null ) ? 0 : g_hBeams.Length;
        int CPlen = ( g_hCPs == null ) ? 0 : g_hCPs.Length;
        if (szItem[0] == 'Z')
        {
            ReplaceString(szItem, sizeof(szItem), "Z", "");

            char szInfo[2][10];
            if ( !ExplodeString( szItem, "_", szInfo, sizeof( szInfo ), sizeof( szInfo[] ) ) )
                return 0;
            int zone = StringToInt(szInfo[0]); 
            int index = StringToInt(szInfo[1]);

            if (item == 0)
            {
                SetPlayerPractice( client, true );
                int pos[3];
                pos[0] = g_vecZoneMins[zone][index][0] + ( g_vecZoneMaxs[zone][index][0] - g_vecZoneMins[zone][index][0] ) / 2;
                pos[1] = g_vecZoneMins[zone][index][1] + ( g_vecZoneMaxs[zone][index][1] - g_vecZoneMins[zone][index][1] ) / 2;
                pos[2] = (g_vecZoneMins[zone][index][2] + g_vecZoneMaxs[zone][index][2]) / 2;
                TeleportEntity(client, pos, NULL_VECTOR, g_vecNull);
                DrawZoneListChoose(client, 0, zone, index);
            }
            else
            {
                static int iData[BEAM_SIZE];
                for (int i=0; i < len; i++)
                    if (g_hBeams.Get(i, view_as<int>( BEAM_TYPE ) ) == zone && g_hBeams.Get(i, view_as<int>( BEAM_INDEX ) ) == index)
                    {
                        g_hBeams.GetArray( i, iData, view_as<int>( BeamData ) );
                    }

                static float vecZonePoints_Bottom[5][3];
                static float vecZonePoints_Top[5][3];
               
                // We'll have to use the zone mins to check if they are close enough.
                ArrayCopy( iData[BEAM_POS_BOTTOM1], vecZonePoints_Bottom[0], 3 );
                ArrayCopy( iData[BEAM_POS_TOP3], vecZonePoints_Top[2], 3 );
               
               
               
                // Bottom
                ArrayCopy( iData[BEAM_POS_BOTTOM1], vecZonePoints_Bottom[0], 3 );
                ArrayCopy( iData[BEAM_POS_BOTTOM2], vecZonePoints_Bottom[1], 3 );
                ArrayCopy( iData[BEAM_POS_BOTTOM3], vecZonePoints_Bottom[2], 3 );
                ArrayCopy( iData[BEAM_POS_BOTTOM4], vecZonePoints_Bottom[3], 3 );
               
                // Top
                ArrayCopy( iData[BEAM_POS_TOP1], vecZonePoints_Top[0], 3 );
                ArrayCopy( iData[BEAM_POS_TOP2], vecZonePoints_Top[1], 3 );
                ArrayCopy( iData[BEAM_POS_TOP3], vecZonePoints_Top[2], 3 );
                ArrayCopy( iData[BEAM_POS_TOP4], vecZonePoints_Top[3], 3 );

                //vecZonePoints_Top[1][2] += 15.0;
               
                // For people with high ping.
                #define ZONE_BEAM_ALIVE         10.0
                // Bottom
                for (int i = 0; i < 4; i++)
                {
	                TE_SetupBeamPoints( vecZonePoints_Bottom[i], vecZonePoints_Bottom[(i == 3) ? 0 : i+1], g_iBeam, 0, 0, 0, ZONE_BEAM_ALIVE, ZONE_WIDTH, ZONE_WIDTH, 0, 0.0, clrBeam[GREEN_ZONE], 0 );
	                TE_SendToClient(client);
                }
                // Top
                for (int i = 0; i < 4; i++)
                {
                	TE_SetupBeamPoints( vecZonePoints_Top[i], vecZonePoints_Top[(i == 3) ? 0 : i+1], g_iBeam, 0, 0, 0, ZONE_BEAM_ALIVE, ZONE_WIDTH, ZONE_WIDTH, 0, 0.0, clrBeam[GREEN_ZONE], 0 );
                	TE_SendToClient(client);
                }
                // From bottom to top.
                for (int i = 0; i < 4; i++)
                {
                	TE_SetupBeamPoints( vecZonePoints_Bottom[i], vecZonePoints_Top[i], g_iBeam, 0, 0, 0, ZONE_BEAM_ALIVE, ZONE_WIDTH, ZONE_WIDTH, 0, 0.0, clrBeam[GREEN_ZONE], 0 );
                	TE_SendToClient(client);
                }
                DrawZoneListChoose(client, 0, zone, index);
            }   
        }
        else
        {
            ReplaceString(szItem, sizeof(szItem), "C", "");

            char szInfo[2][10];
            if ( !ExplodeString( szItem, "_", szInfo, sizeof( szInfo ), sizeof( szInfo[] ) ) )
                return 0;

            int zone = StringToInt(szItem[0]);

            if (item == 0)
            {
                SetPlayerPractice( client, true );
                int pos[3];
                float vecMins[3];
                float vecMaxs[3], origin[3];
                for (int i=0; i < CPlen; i++)
                    if (g_hCPs.Get(i, view_as<int>( CP_ID ) ) == zone)
                    {
                    	int ent = EntRefToEntIndex( g_hCPs.Get( i, view_as<int>( CP_ENTREF ) ) );
                    	GetEntPropVector(ent, Prop_Send, "m_vecMins", vecMins);
    					GetEntPropVector(ent, Prop_Send, "m_vecMaxs", vecMaxs);
    					GetEntPropVector(ent, Prop_Send, "m_vecOrigin", origin);
                        /*g_hCPs.GetArray( i, iCpData, view_as<int>( CPData ) );
                        ArrayCopy( iCpData[CP_MINS], vecMins, 3 );
                        ArrayCopy( iCpData[CP_MAXS], vecMaxs, 3 );*/
                    }

                pos[0] = (vecMins[0] + vecMaxs[0]) / 2 + origin[0];
                pos[1] = (vecMins[1] + vecMaxs[1]) / 2 + origin[1];
                pos[2] = (vecMins[2] + vecMaxs[2]) / 2 + origin[2];
                TeleportEntity(client, pos, NULL_VECTOR, g_vecNull);
                DrawZoneListChoose(client, ZONE_CP, zone, zone);
            }
            else
            {
                int iData[BEAM_SIZE];

                for (int i=0; i < len; i++)
                    if (g_hBeams.Get(i, view_as<int>( BEAM_TYPE ) ) == ZONE_CP && g_hBeams.Get(i, view_as<int>( BEAM_ID ) ) == zone)
                    {
                        g_hBeams.GetArray( i, iData, view_as<int>( BeamData ) );
                    }


                static float vecZonePoints_Bottom[5][3];
                static float vecZonePoints_Top[5][3];
               
                // We'll have to use the zone mins to check if they are close enough.
                ArrayCopy( iData[BEAM_POS_BOTTOM1], vecZonePoints_Bottom[0], 3 );
                ArrayCopy( iData[BEAM_POS_TOP3], vecZonePoints_Top[2], 3 );
               
               
               
                // Bottom
                ArrayCopy( iData[BEAM_POS_BOTTOM1], vecZonePoints_Bottom[0], 3 );
                ArrayCopy( iData[BEAM_POS_BOTTOM2], vecZonePoints_Bottom[1], 3 );
                ArrayCopy( iData[BEAM_POS_BOTTOM3], vecZonePoints_Bottom[2], 3 );
                ArrayCopy( iData[BEAM_POS_BOTTOM4], vecZonePoints_Bottom[3], 3 );
               
                // Top
                ArrayCopy( iData[BEAM_POS_TOP1], vecZonePoints_Top[0], 3 );
                ArrayCopy( iData[BEAM_POS_TOP2], vecZonePoints_Top[1], 3 );
                ArrayCopy( iData[BEAM_POS_TOP3], vecZonePoints_Top[2], 3 );
                ArrayCopy( iData[BEAM_POS_TOP4], vecZonePoints_Top[3], 3 );
               
                // For people with high ping.
                #define ZONE_BEAM_ALIVE         10.0
                // Bottom
                for (int i = 0; i < 4; i++)
                {
	                TE_SetupBeamPoints( vecZonePoints_Bottom[i], vecZonePoints_Bottom[(i == 3) ? 0 : i+1], g_iBeam, 0, 0, 0, ZONE_BEAM_ALIVE, ZONE_WIDTH, ZONE_WIDTH, 0, 0.0, clrBeam[GREEN_ZONE], 0 );
	                TE_SendToClient(client);
                }
                // Top
                for (int i = 0; i < 4; i++)
                {
                	TE_SetupBeamPoints( vecZonePoints_Top[i], vecZonePoints_Top[(i == 3) ? 0 : i+1], g_iBeam, 0, 0, 0, ZONE_BEAM_ALIVE, ZONE_WIDTH, ZONE_WIDTH, 0, 0.0, clrBeam[GREEN_ZONE], 0 );
                	TE_SendToClient(client);
                }
                // From bottom to top.
                for (int i = 0; i < 4; i++)
                {
                	TE_SetupBeamPoints( vecZonePoints_Bottom[i], vecZonePoints_Top[i], g_iBeam, 0, 0, 0, ZONE_BEAM_ALIVE, ZONE_WIDTH, ZONE_WIDTH, 0, 0.0, clrBeam[GREEN_ZONE], 0 );
                	TE_SendToClient(client);
                }
                DrawZoneListChoose(client, ZONE_CP, zone, zone);
            }   
        }
    }
    return 0;
}

stock void GetMiddleOfABox(float vec1[3], float vec2[3], float buffer[3])
{
    float mid[3];
    MakeVectorFromPoints(vec1, vec2, mid);
    mid[0] = mid[0] / 2.0;
    mid[1] = mid[1] / 2.0;
    mid[2] = mid[2] / 2.0;
    AddVectors(vec1, mid, buffer);
}

public Action Timer_DrawBuildZoneBeamsEye( Handle hTimer, int client )
{
    if ( !IsClientInGame( client ) || !IsPlayerAlive( client ) || g_iBuilderZone[client] == ZONE_INVALID )
    {
        g_bStartBuilding[client] = false;
        g_iBuilderZone[client] = ZONE_INVALID;
       
        return Plugin_Stop;
    }
   
   
    static float vecPos[3];
    static float vecABS[3];
    static float end[3];
    GetClientEyeAngles( client, vecPos );
    GetClientEyePosition( client, vecABS );
    TR_TraceRayFilter(vecABS, vecPos, MASK_SOLID, RayType_Infinite, TraceEntityFilterPlayer, client);
    TR_GetEndPosition(end);

    float flDif = end[2] - g_vecBuilderStart[client][2];
	
	// If player built the mins on the ground and just walks to the other side, we will then automatically make it higher.
	if ( IsBuildingOnGround[client] && ( flDif <= 4.0 && flDif >= -4.0 ) )
		end[2] = g_vecBuilderStart[client][2] + ZONE_DEF_HEIGHT;

   
    static float flPoint4Min[3], flPoint4Max[3];
    static float flPoint3Min[3];
    static float flPoint2Min[3], flPoint2Max[3];
    static float flPoint1Max[3];
   
    flPoint4Min[0] = g_vecBuilderStart[client][0]; flPoint4Min[1] = end[1]; flPoint4Min[2] = g_vecBuilderStart[client][2];
    flPoint4Max[0] = g_vecBuilderStart[client][0]; flPoint4Max[1] = end[1]; flPoint4Max[2] = end[2];
   
    flPoint3Min[0] = end[0]; flPoint3Min[1] = end[1]; flPoint3Min[2] = g_vecBuilderStart[client][2];
   
    flPoint2Min[0] = end[0]; flPoint2Min[1] = g_vecBuilderStart[client][1]; flPoint2Min[2] = g_vecBuilderStart[client][2];
    flPoint2Max[0] = end[0]; flPoint2Max[1] = g_vecBuilderStart[client][1]; flPoint2Max[2] = end[2];
   
    flPoint1Max[0] = g_vecBuilderStart[client][0]; flPoint1Max[1] = g_vecBuilderStart[client][1]; flPoint1Max[2] = end[2];
   
    TE_SetupBeamPoints( g_vecBuilderStart[client], flPoint1Max, g_iBeam, 0, 0, 0, ZONE_BUILD_INTERVAL, ZONE_WIDTH, ZONE_WIDTH, 0, 0.0, clrBeam[DEV_GREEN_ZONE], 0 );
    TE_SendToAll();
   
    TE_SetupBeamPoints( g_vecBuilderStart[client], flPoint4Min, g_iBeam, 0, 0, 0, ZONE_BUILD_INTERVAL, ZONE_WIDTH, ZONE_WIDTH, 0, 0.0, clrBeam[DEV_ZONE_RED], 0 );
    TE_SendToAll();
   
    TE_SetupBeamPoints( g_vecBuilderStart[client], flPoint2Min, g_iBeam, 0, 0, 0, ZONE_BUILD_INTERVAL, ZONE_WIDTH, ZONE_WIDTH, 0, 0.0, clrBeam[DEV_ZONE_WHITE], 0 );
    TE_SendToAll();
   
    TE_SetupBeamPoints( flPoint3Min, end, g_iBeam, 0, 0, 0, ZONE_BUILD_INTERVAL, ZONE_WIDTH, ZONE_WIDTH, 0, 0.0, clrBeam[DEV_ZONE_BLUE], 0 );
    TE_SendToAll();
   
    TE_SetupBeamPoints( flPoint3Min, flPoint4Min, g_iBeam, 0, 0, 0, ZONE_BUILD_INTERVAL, ZONE_WIDTH, ZONE_WIDTH, 0, 0.0, clrBeam[DEV_GREEN_ZONE], 0 );
    TE_SendToAll();
   
    TE_SetupBeamPoints( flPoint3Min, flPoint2Min, g_iBeam, 0, 0, 0, ZONE_BUILD_INTERVAL, ZONE_WIDTH, ZONE_WIDTH, 0, 0.0, clrBeam[DEV_ZONE_RED], 0 );
    TE_SendToAll();
   
    TE_SetupBeamPoints( flPoint2Max, flPoint2Min, g_iBeam, 0, 0, 0, ZONE_BUILD_INTERVAL, ZONE_WIDTH, ZONE_WIDTH, 0, 0.0, clrBeam[DEV_GREEN_ZONE], 0 );
    TE_SendToAll();
   
    TE_SetupBeamPoints( flPoint2Max, flPoint1Max, g_iBeam, 0, 0, 0, ZONE_BUILD_INTERVAL, ZONE_WIDTH, ZONE_WIDTH, 0, 0.0, clrBeam[DEV_ZONE_BLUE], 0 );
    TE_SendToAll();
   
    TE_SetupBeamPoints( flPoint2Max, end, g_iBeam, 0, 0, 0, ZONE_BUILD_INTERVAL, ZONE_WIDTH, ZONE_WIDTH, 0, 0.0, clrBeam[DEV_GREEN_ZONE], 0 );
    TE_SendToAll();
   
    TE_SetupBeamPoints( flPoint4Max, flPoint4Min, g_iBeam, 0, 0, 0, ZONE_BUILD_INTERVAL, ZONE_WIDTH, ZONE_WIDTH, 0, 0.0, clrBeam[DEV_ZONE_RED], 0 );
    TE_SendToAll();
   
    TE_SetupBeamPoints( flPoint4Max, flPoint1Max, g_iBeam, 0, 0, 0, ZONE_BUILD_INTERVAL, ZONE_WIDTH, ZONE_WIDTH, 0, 0.0, clrBeam[DEV_ZONE_WHITE], 0 );
    TE_SendToAll();
   
    TE_SetupBeamPoints( flPoint4Max, end, g_iBeam, 0, 0, 0, ZONE_BUILD_INTERVAL, ZONE_WIDTH, ZONE_WIDTH, 0, 0.0, clrBeam[DEV_ZONE_BLUE], 0 );
    TE_SendToAll();
   
    return Plugin_Continue;
}
 
public Action Timer_DrawBuildZoneBeamsOrigin( Handle hTimer, int client )
{
    if ( !IsClientInGame( client ) || !IsPlayerAlive( client ) || g_iBuilderZone[client] == ZONE_INVALID )
    {
        g_bStartBuilding[client] = false;
        g_iBuilderZone[client] = ZONE_INVALID;
       
        return Plugin_Stop;
    }
   
   
    static float end[3];
    GetClientAbsOrigin(client, end);
   
	float flDif = end[2] - g_vecBuilderStart[client][2];
	
	// If player built the mins on the ground and just walks to the other side, we will then automatically make it higher.
	if ( IsBuildingOnGround[client] && ( flDif <= 4.0 && flDif >= -4.0 ) )
		end[2] = g_vecBuilderStart[client][2] + ZONE_DEF_HEIGHT;
   
    static float flPoint4Min[3], flPoint4Max[3];
    static float flPoint3Min[3];
    static float flPoint2Min[3], flPoint2Max[3];
    static float flPoint1Max[3];
   
    flPoint4Min[0] = g_vecBuilderStart[client][0]; flPoint4Min[1] = end[1]; flPoint4Min[2] = g_vecBuilderStart[client][2];
    flPoint4Max[0] = g_vecBuilderStart[client][0]; flPoint4Max[1] = end[1]; flPoint4Max[2] = end[2];
   
    flPoint3Min[0] = end[0]; flPoint3Min[1] = end[1]; flPoint3Min[2] = g_vecBuilderStart[client][2];
   
    flPoint2Min[0] = end[0]; flPoint2Min[1] = g_vecBuilderStart[client][1]; flPoint2Min[2] = g_vecBuilderStart[client][2];
    flPoint2Max[0] = end[0]; flPoint2Max[1] = g_vecBuilderStart[client][1]; flPoint2Max[2] = end[2];
   
    flPoint1Max[0] = g_vecBuilderStart[client][0]; flPoint1Max[1] = g_vecBuilderStart[client][1]; flPoint1Max[2] = end[2];
   
    TE_SetupBeamPoints( g_vecBuilderStart[client], flPoint1Max, g_iBeam, 0, 0, 0, ZONE_BUILD_INTERVAL, ZONE_WIDTH, ZONE_WIDTH, 0, 0.0, clrBeam[DEV_GREEN_ZONE], 0 );
    TE_SendToAll();
   
    TE_SetupBeamPoints( g_vecBuilderStart[client], flPoint4Min, g_iBeam, 0, 0, 0, ZONE_BUILD_INTERVAL, ZONE_WIDTH, ZONE_WIDTH, 0, 0.0, clrBeam[DEV_ZONE_RED], 0 );
    TE_SendToAll();
   
    TE_SetupBeamPoints( g_vecBuilderStart[client], flPoint2Min, g_iBeam, 0, 0, 0, ZONE_BUILD_INTERVAL, ZONE_WIDTH, ZONE_WIDTH, 0, 0.0, clrBeam[DEV_ZONE_WHITE], 0 );
    TE_SendToAll();
   
    TE_SetupBeamPoints( flPoint3Min, end, g_iBeam, 0, 0, 0, ZONE_BUILD_INTERVAL, ZONE_WIDTH, ZONE_WIDTH, 0, 0.0, clrBeam[DEV_ZONE_BLUE], 0 );
    TE_SendToAll();
   
    TE_SetupBeamPoints( flPoint3Min, flPoint4Min, g_iBeam, 0, 0, 0, ZONE_BUILD_INTERVAL, ZONE_WIDTH, ZONE_WIDTH, 0, 0.0, clrBeam[DEV_GREEN_ZONE], 0 );
    TE_SendToAll();
   
    TE_SetupBeamPoints( flPoint3Min, flPoint2Min, g_iBeam, 0, 0, 0, ZONE_BUILD_INTERVAL, ZONE_WIDTH, ZONE_WIDTH, 0, 0.0, clrBeam[DEV_ZONE_RED], 0 );
    TE_SendToAll();
   
    TE_SetupBeamPoints( flPoint2Max, flPoint2Min, g_iBeam, 0, 0, 0, ZONE_BUILD_INTERVAL, ZONE_WIDTH, ZONE_WIDTH, 0, 0.0, clrBeam[DEV_GREEN_ZONE], 0 );
    TE_SendToAll();
   
    TE_SetupBeamPoints( flPoint2Max, flPoint1Max, g_iBeam, 0, 0, 0, ZONE_BUILD_INTERVAL, ZONE_WIDTH, ZONE_WIDTH, 0, 0.0, clrBeam[DEV_ZONE_BLUE], 0 );
    TE_SendToAll();
   
    TE_SetupBeamPoints( flPoint2Max, end, g_iBeam, 0, 0, 0, ZONE_BUILD_INTERVAL, ZONE_WIDTH, ZONE_WIDTH, 0, 0.0, clrBeam[DEV_GREEN_ZONE], 0 );
    TE_SendToAll();
   
    TE_SetupBeamPoints( flPoint4Max, flPoint4Min, g_iBeam, 0, 0, 0, ZONE_BUILD_INTERVAL, ZONE_WIDTH, ZONE_WIDTH, 0, 0.0, clrBeam[DEV_ZONE_RED], 0 );
    TE_SendToAll();
   
    TE_SetupBeamPoints( flPoint4Max, flPoint1Max, g_iBeam, 0, 0, 0, ZONE_BUILD_INTERVAL, ZONE_WIDTH, ZONE_WIDTH, 0, 0.0, clrBeam[DEV_ZONE_WHITE], 0 );
    TE_SendToAll();
   
    TE_SetupBeamPoints( flPoint4Max, end, g_iBeam, 0, 0, 0, ZONE_BUILD_INTERVAL, ZONE_WIDTH, ZONE_WIDTH, 0, 0.0, clrBeam[DEV_ZONE_BLUE], 0 );
    TE_SendToAll();
   
    return Plugin_Continue;
}
 
public Action Timer_DrawBuildZoneStartEye( Handle hTimer, int client )
{
    if ( !IsClientInGame( client ) || !IsPlayerAlive( client ) || !g_bStartBuilding[client] )
    {
        g_bStartBuilding[client] = false;
        return Plugin_Stop;
    }
	
    static float vecPos[3];
	static float vecEye[3];
	static float end[3];

	GetClientEyePosition(client, vecPos);
	GetClientEyeAngles(client, vecEye);
   	TR_TraceRayFilter(vecPos, vecEye, MASK_SOLID, RayType_Infinite, TraceEntityFilterPlayer, client);
	
	TR_GetEndPosition(end);

    TE_SetupGlowSprite( end, g_iSprite, ZONE_BUILD_INTERVAL, 0.1, 255 );
    TE_SendToClient( client, 0.0 );
    return Plugin_Continue;
}

public Action Timer_DrawBuildZoneStartOrigin( Handle hTimer, int client )
{
    if ( !IsClientInGame( client ) || !IsPlayerAlive( client ) || !g_bStartBuilding[client] )
    {
        g_bStartBuilding[client] = false;
        return Plugin_Stop;
    }
    
    static float vecPos[3];
    GetClientAbsOrigin( client, vecPos );

    TE_SetupGlowSprite( vecPos, g_iSprite, ZONE_BUILD_INTERVAL, 0.1, 255 );
    TE_SendToClient( client, 0.0 );
    return Plugin_Continue;
}

bool TraceEntityFilterPlayer(int entity, int contentsMask)
{
	return entity > MaxClients;
}  

 
#if defined VOTING
    public Action Timer_ChangeMap( Handle hTimer )
    {
        ServerCommand( "changelevel %s", g_szNextMap );
        return Plugin_Handled;
    }

#endif