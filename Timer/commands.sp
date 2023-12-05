public Action Command_Version( int client, int args )
{
	if ( client )
	{
		CPrintToChatAll( CHAT_PREFIX..."Running version {lightskyblue}"...PLUGIN_VERSION_CORE..." {white}made by {lightskyblue}"...PLUGIN_AUTHOR_CORE..."{white}." );
	}
	else
	{
		PrintToServer( CONSOLE_PREFIX..."Running version "...PLUGIN_VERSION_CORE..." made by "...PLUGIN_AUTHOR_CORE..."." );
	}
	
	return Plugin_Handled;
}

public Action Command_RunMode(int client, int args)
{
	if (!client) return Plugin_Handled;

	if ( g_fClientHideFlags[client] & AUTO_EXTEND_MAP_OPTION )
	{
		g_fClientHideFlags[client] &= ~AUTO_EXTEND_MAP_OPTION;
		CPrintToChat(client, CHAT_PREFIX..."You are no longer in run mode.");
	}
	else
	{
		g_fClientHideFlags[client] |= AUTO_EXTEND_MAP_OPTION;
		CPrintToChat(client, CHAT_PREFIX..."You are now in run mode - you will automatically vote to extend.");
		
	}
	return Plugin_Handled;
}

public Action Command_Help( int client, int args )
{
	if ( !client ) return Plugin_Handled;
    
    ShowHelp(client, args);
    return Plugin_Handled;
}	

public Action Command_Time( int client, int args )
{
	if ( !client ) return Plugin_Handled;
	
	
	if ( IsSpammingCommand( client ) ) return Plugin_Handled;
	
	char szTarget[MAX_NAME_LENGTH];
	GetCmdArgString( szTarget, sizeof( szTarget ) );
	int target = FindTarget( client, szTarget, false, false );
	if ( target > 0 )
	{
	GetTimer(target, args );
	return 0;
	}
	GetTimer( client, args );
	
	return Plugin_Handled;
}

public Action Command_Overall( int client, int args )
{
	if ( !client ) return Plugin_Handled;
	
	
	if ( IsSpammingCommand( client ) ) return Plugin_Handled;
	
	char szQuery[162];

	FormatEx( szQuery, sizeof( szQuery ), "SELECT SUM(pts) FROM "...TABLE_RECORDS..."" );
	g_hDatabase.Query( Threaded_Overall, szQuery, GetClientUserId( client ), DBPrio_Normal );
	
	return Plugin_Handled;
}

public void GetTimer(int client, int args)
{	
	char szStyleFix[STYLEPOSTFIX_LENGTH];
	GetStylePostfix( g_iClientMode[client], szStyleFix, true );
	float time = GetEngineTime() - g_flClientStartTime[client];

	char szTime[TIME_SIZE_DEF];
	FormatSeconds( time, szTime, FORMAT_2DECI );

	if (g_iClientState[client] == STATE_END)
	{
		CPrintToChatAll(CHAT_PREFIX..."(%s%s) {green}%N {white}state on {lightskyblue}%s End",
		g_szStyleName[NAME_SHORT][ g_iClientStyle[client] ], szStyleFix,
		client,
		g_szRunName[NAME_LONG][ g_iClientRun[client] ] );
	}
	else if (g_iClientState[client] == STATE_START)
	{
		CPrintToChatAll(CHAT_PREFIX..."(%s%s) {green}%N {white}state on {lightskyblue}%s Start",
		g_szStyleName[NAME_SHORT][ g_iClientStyle[client] ], szStyleFix,
		client,
		g_szRunName[NAME_LONG][ g_iClientRun[client] ] );
	}
	else if (g_iClientState[client] == STATE_RUNNING && g_iClientState[client] != STATE_SETSTART)
	{
		CPrintToChatAll(CHAT_PREFIX..."(%s%s) {green}%N {white}run {lightskyblue}%s {white}with time: {green}%s",
		g_szStyleName[NAME_SHORT][ g_iClientStyle[client] ], szStyleFix,
		client,
		g_szRunName[NAME_LONG][ g_iClientRun[client] ],
		szTime );
	}
}	

public void BonusMenu(int client)
{	
	Menu mMenu;
	mMenu = new Menu( Handler_BonusMenu );
	int num;
	char szRun[30];
	for (int i = RUN_BONUS1; i <= RUN_BONUS10; i++ )
	{
		if ( g_bIsLoaded[i] )
		{
			IntToString(i, szRun, sizeof(szRun) );
			mMenu.AddItem( szRun, g_szRunName[NAME_LONG][i] );
			num += 1;
		}
	}
	
	if (num == 0)
	{
		mMenu.AddItem( "", "", ITEMDRAW_SPACER );
	}
	mMenu.SetTitle( "<Bonuses menu> (%i total)\n ", num );
	mMenu.Display( client, MENU_TIME_FOREVER );

}

public int Handler_BonusMenu( Menu mMenu, MenuAction action, int client, int item )
{
	if ( action == MenuAction_End ) { delete mMenu; return 0; }
	if ( action != MenuAction_Select ) return 0;
	
	char szItem[30];
	int run;
	GetMenuItem( mMenu, item, szItem, sizeof( szItem ) );

	StringToIntEx(szItem, run);

	if (g_bIsLoaded[run])
	{
		if (TF2_GetPlayerClass(client) == TFClass_DemoMan) {
			SetEntityGravity(client, 1.0);
			SetEntityHealth(client, 175);
	       	DestroyProjectilesDemo(client);
		} 
		else if (TF2_GetPlayerClass(client) == TFClass_Soldier) {
		       DestroyProjectilesSoldier(client);
		}

		TeleportEntity( client, g_vecSpawnPos[run], g_vecSpawnAngles[run], g_vecNull );

		g_fClientRespawnPosition[client][0] = 0.0;
		g_fClientRespawnPosition[client][1] = 0.0;
		g_fClientRespawnPosition[client][2] = 0.0;
			
		g_fClientRespawnAngles[client][0] = 0.0;
		g_fClientRespawnAngles[client][1] = 0.0;
		g_fClientRespawnAngles[client][2] = 0.0;
		TF2_RegeneratePlayer(client);
		BonusMenu(client);
	}
	return;
}

public void CourseMenu(int client)
{	
	Menu mMenu;
	mMenu = new Menu( Handler_CoursesMenu );
	int num;
	char szRun[30];
	for (int i = RUN_COURSE1; i <= RUN_COURSE10; i++ )
	{
		if ( g_bIsLoaded[i] )
		{
			IntToString(i, szRun, sizeof(szRun) );
			mMenu.AddItem( szRun, g_szRunName[NAME_LONG][i] );
			num += 1;
		}
	}
	if (num == 0)
	{
		mMenu.AddItem( "", "", ITEMDRAW_SPACER );
	}
	mMenu.SetTitle( "<Courses menu> (%i total)\n ", num );
	mMenu.Display( client, MENU_TIME_FOREVER );

}

public int Handler_CoursesMenu( Menu mMenu, MenuAction action, int client, int item )
{
	if ( action == MenuAction_End ) { delete mMenu; return 0; }
	if ( action != MenuAction_Select ) return 0;
	char szItem[30];
	int run;
	GetMenuItem( mMenu, item, szItem, sizeof( szItem ) );

	StringToIntEx(szItem, run);

	if (g_bIsLoaded[run])
	{
		if (TF2_GetPlayerClass(client) == TFClass_DemoMan) {
			SetEntityGravity(client, 1.0);
			SetEntityHealth(client, 175);
	       	DestroyProjectilesDemo(client);
		   } else if (TF2_GetPlayerClass(client) == TFClass_Soldier) {
		       DestroyProjectilesSoldier(client);
		       SetEntityGravity(client, 1.0);
		   }

		IsMapMode[client] = false;
		DisplayCpTime[client] = false;
		TeleportEntity( client, g_vecSpawnPos[run], g_vecSpawnAngles[run], g_vecNull );

		g_fClientRespawnPosition[client][0] = 0.0;
		g_fClientRespawnPosition[client][1] = 0.0;
		g_fClientRespawnPosition[client][2] = 0.0;
			
		g_fClientRespawnAngles[client][0] = 0.0;
		g_fClientRespawnAngles[client][1] = 0.0;
		g_fClientRespawnAngles[client][2] = 0.0;
		TF2_RegeneratePlayer(client);
		CourseMenu(client);
	}
	return;
}

public Action Change_zone_pints( int client, int args )
{
    if (!client || !IsPlayerAlive(client)) return Plugin_Handled;

    Menu mMenu = new Menu(Handler_Change_zone_pints);
    
    mMenu.SetTitle("<Change Points of Zones :: Selection\n ");

    char zoneinfo[10], zonename[50];

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
        }
    }
    mMenu.Display(client, MENU_TIME_FOREVER);
}

public int Handler_Change_zone_pints( Menu mMenu, MenuAction action, int client, int item )
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

            ChangeZonePoint(client, 0, zone, index, true);
        }
        else
        {
            ReplaceString(szItem, sizeof(szItem), "C", "");

            char szInfo[2][10];
            if ( !ExplodeString( szItem, "_", szInfo, sizeof( szInfo ), sizeof( szInfo[] ) ) )
                return 0;

            int zone = StringToInt(szItem[0]);
            int index = StringToInt(szItem[1]);

            ChangeZonePoint(client, ZONE_CP, zone, index, true);  
        }
    }
    return 0;
}

public void ChangeZonePoint(int client, int type, int zone, int index, bool teleport)
{
    Menu mMenu = new Menu(Handler_ChangeZonePoint);
    char zoneinfo[30], szIndex[20];
    if (type != ZONE_CP)
    {
        if (index > 0)
            FormatEx(szIndex, sizeof(szIndex), " #%i", index+1);
        else
            FormatEx(szIndex, sizeof(szIndex), "");

        mMenu.SetTitle("<Change Zone Point :: Selection>\nZone: %s%s\n ", g_szZoneNames[zone], szIndex);

        FormatEx(zoneinfo, sizeof(zoneinfo), "Z%i_%i", zone, index);

        g_iBuilderZone[client] = zone;
       	g_iBuilderZoneIndex[client] = index;
        SetPlayerPractice( client, true );
        CreateTimer( ZONE_BUILD_INTERVAL, Timer_DrawChangeZonePointBeamsEye, client, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE );
        
        if (teleport)
        {
	        int pos[3];
	        pos[0] = g_vecZoneMins[zone][index][0] + ( g_vecZoneMaxs[zone][index][0] - g_vecZoneMins[zone][index][0] ) / 2;
	        pos[1] = g_vecZoneMins[zone][index][1] + ( g_vecZoneMaxs[zone][index][1] - g_vecZoneMins[zone][index][1] ) / 2;
	        pos[2] = (g_vecZoneMins[zone][index][2] + g_vecZoneMaxs[zone][index][2]) / 2;
	        TeleportEntity(client, pos, NULL_VECTOR, g_vecNull);
	    }

        mMenu.AddItem(zoneinfo, "Top point 1 (green)\n ");
        mMenu.AddItem(zoneinfo, "Top point 2 (red)\n ");
        mMenu.AddItem(zoneinfo, "Top point 3 (bleu)\n ");
        mMenu.AddItem(zoneinfo, "Top point 4 (purple)\n ");
        mMenu.AddItem(zoneinfo, "Bottom point 1 (green)\n ");
        mMenu.AddItem(zoneinfo, "Bottom point 2 (red)\n ");
        mMenu.AddItem(zoneinfo, "Bottom point 3 (blue)\n ");
        mMenu.AddItem(zoneinfo, "Bottom point 4 (purple)\n ");
    }
    else
    {
		int iCpData[CP_SIZE];
		if (g_hCPs.GetArray( zone, iCpData, view_as<int>( CPData ) ) )
        {
			mMenu.SetTitle("<Change Zone Point :: Selection>\nZone: Checkpoint %i\n ", iCpData[CP_ID]+1);

			
            g_iBuilderZone[client] = ZONE_CP;
       		g_iBuilderZoneIndex[client] = index;

       		SetPlayerPractice( client, true );
			
			if (teleport)
        	{
				int pos[3];
	            float vecMins[3];
	            float vecMaxs[3], origin[3];
	            for (int i=0; i < g_hCPs.Length; i++)
	            	if (g_hCPs.Get(i, view_as<int>( CP_ID ) ) == zone)
	               	{
	                	int ent = EntRefToEntIndex( g_hCPs.Get( i, view_as<int>( CP_ENTREF ) ) );
	                	GetEntPropVector(ent, Prop_Send, "m_vecMins", vecMins);
	    				GetEntPropVector(ent, Prop_Send, "m_vecMaxs", vecMaxs);
	    				GetEntPropVector(ent, Prop_Send, "m_vecOrigin", origin);
	                   	/*
	                  	 g_hCPs.GetArray( i, iCpData, view_as<int>( CPData ) );
	                   	ArrayCopy( iCpData[CP_MINS], vecMins, 3 );
	                   	ArrayCopy( iCpData[CP_MAXS], vecMaxs, 3 );
	                   	*/
	                   	pos[0] = (vecMins[0] + vecMaxs[0]) / 2 + origin[0];
			            pos[1] = (vecMins[1] + vecMaxs[1]) / 2 + origin[1];
			            pos[2] = (vecMins[2] + vecMaxs[2]) / 2 + origin[2];

			            TeleportEntity(client, pos, NULL_VECTOR, g_vecNull);
	               	}
	       	}

            CreateTimer( ZONE_BUILD_INTERVAL, Timer_DrawChangeZonePointBeamsEye, client, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE );
			
			FormatEx(zoneinfo, sizeof(zoneinfo), "C%i_%i", zone, iCpData[CP_ID]);

			mMenu.AddItem(zoneinfo, "Top point 1 (green)\n ");
			mMenu.AddItem(zoneinfo, "Top point 2 (red)\n ");
			mMenu.AddItem(zoneinfo, "Top point 3 (blue)\n ");
			mMenu.AddItem(zoneinfo, "Top point 4 (purple)\n ");
			mMenu.AddItem(zoneinfo, "Bottom point 1 (green)\n ");
			mMenu.AddItem(zoneinfo, "Bottom point 2 (red)\n ");
			mMenu.AddItem(zoneinfo, "Bottom point 3 (blue)\n ");
			mMenu.AddItem(zoneinfo, "Bottom point 4 (purple)\n ");
		}
	}
    mMenu.ExitBackButton = true;
    mMenu.Display(client, MENU_TIME_FOREVER);
}

public int Handler_ChangeZonePoint( Menu mMenu, MenuAction action, int client, int item )
{
    if (client < 1) return 0;

    if ( action == MenuAction_End ) { delete mMenu; return 0; }
    if ( action == MenuAction_Cancel)
    {
        if (item == MenuCancel_ExitBack)
        {
            ClientCommand(client, "sm_changezone");
        }
        return 0;
    } 
        
    if ( action != MenuAction_Select ) return 0;
    if ( action == MenuAction_Select )
    {
        char szItem[20];
        GetMenuItem( mMenu, item, szItem, sizeof( szItem ) );

        static float vecPos[3];
		static float vecABS[3];
		static float end[3];
		GetClientEyeAngles( client, vecPos );
	 	GetClientEyePosition( client, vecABS );
		TR_TraceRayFilter(vecABS, vecPos, MASK_SOLID, RayType_Infinite, TraceEntityFilterPlayer, client);
		TR_GetEndPosition(end);

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
            	int iData[BEAM_SIZE];
                for (int i=0; i < len; i++)
                    if (g_hBeams.Get(i, view_as<int>( BEAM_TYPE ) ) == zone && g_hBeams.Get(i, view_as<int>( BEAM_INDEX ) ) == index)
                    {
                    	g_hBeams.GetArray( i, iData, view_as<int>( BeamData ) );
                    	ArrayCopy(	end, iData[BEAM_POS_TOP1], 3 );
                        g_hBeams.SetArray( i, iData, view_as<int>( BeamData ) );
                    }
                ChangeZonePoint(client, 0, zone, index, false);    
            }
            if (item == 1)
            {
            	int iData[BEAM_SIZE];
                for (int i=0; i < len; i++)
                    if (g_hBeams.Get(i, view_as<int>( BEAM_TYPE ) ) == zone && g_hBeams.Get(i, view_as<int>( BEAM_INDEX ) ) == index)
                    {
                    	g_hBeams.GetArray( i, iData, view_as<int>( BeamData ) );
                    	ArrayCopy(	end, iData[BEAM_POS_TOP2], 3 );
                        g_hBeams.SetArray( i, iData, view_as<int>( BeamData ) );
                    }
                ChangeZonePoint(client, 0, zone, index, false);    
            }
            if (item == 2)
            {
            	int iData[BEAM_SIZE];
                for (int i=0; i < len; i++)
                    if (g_hBeams.Get(i, view_as<int>( BEAM_TYPE ) ) == zone && g_hBeams.Get(i, view_as<int>( BEAM_INDEX ) ) == index)
                    {
                    	g_hBeams.GetArray( i, iData, view_as<int>( BeamData ) );
                    	ArrayCopy(	end, iData[BEAM_POS_TOP3], 3 );
                        g_hBeams.SetArray( i, iData, view_as<int>( BeamData ) );
                    }
                ChangeZonePoint(client, 0, zone, index, false);    
            }
            if (item == 3)
            {
            	int iData[BEAM_SIZE];
                for (int i=0; i < len; i++)
                    if (g_hBeams.Get(i, view_as<int>( BEAM_TYPE ) ) == zone && g_hBeams.Get(i, view_as<int>( BEAM_INDEX ) ) == index)
                    {
                    	g_hBeams.GetArray( i, iData, view_as<int>( BeamData ) );
                    	ArrayCopy(	end, iData[BEAM_POS_TOP4], 3 );
                        g_hBeams.SetArray( i, iData, view_as<int>( BeamData ) );
                    }
                ChangeZonePoint(client, 0, zone, index, false);    
            }
            if (item == 4)
            {
            	int iData[BEAM_SIZE];
                for (int i=0; i < len; i++)
                    if (g_hBeams.Get(i, view_as<int>( BEAM_TYPE ) ) == zone && g_hBeams.Get(i, view_as<int>( BEAM_INDEX ) ) == index)
                    {
                    	g_hBeams.GetArray( i, iData, view_as<int>( BeamData ) );
                    	ArrayCopy(	end, iData[BEAM_POS_BOTTOM1], 3 );
                        g_hBeams.SetArray( i, iData, view_as<int>( BeamData ) );
                    }
                ChangeZonePoint(client, 0, zone, index, false);    
            }
            if (item == 5)
            {
            	int iData[BEAM_SIZE];
                for (int i=0; i < len; i++)
                    if (g_hBeams.Get(i, view_as<int>( BEAM_TYPE ) ) == zone && g_hBeams.Get(i, view_as<int>( BEAM_INDEX ) ) == index)
                    {
                    	g_hBeams.GetArray( i, iData, view_as<int>( BeamData ) );
                    	ArrayCopy(	end, iData[BEAM_POS_BOTTOM2], 3 );
                        g_hBeams.SetArray( i, iData, view_as<int>( BeamData ) );
                    }
                ChangeZonePoint(client, 0, zone, index, false);    
            }
            if (item == 6)
            {
            	int iData[BEAM_SIZE];
                for (int i=0; i < len; i++)
                    if (g_hBeams.Get(i, view_as<int>( BEAM_TYPE ) ) == zone && g_hBeams.Get(i, view_as<int>( BEAM_INDEX ) ) == index)
                    {
                    	g_hBeams.GetArray( i, iData, view_as<int>( BeamData ) );
                    	ArrayCopy(	end, iData[BEAM_POS_BOTTOM3], 3 );
                        g_hBeams.SetArray( i, iData, view_as<int>( BeamData ) );
                    }
                ChangeZonePoint(client, 0, zone, index, false);    
            }
            if (item == 7)
            {
            	int iData[BEAM_SIZE];
                for (int i=0; i < len; i++)
                    if (g_hBeams.Get(i, view_as<int>( BEAM_TYPE ) ) == zone && g_hBeams.Get(i, view_as<int>( BEAM_INDEX ) ) == index)
                    {
                    	g_hBeams.GetArray( i, iData, view_as<int>( BeamData ) );
                    	ArrayCopy(	end, iData[BEAM_POS_BOTTOM4], 3 );
                        g_hBeams.SetArray( i, iData, view_as<int>( BeamData ) );
                    }
                ChangeZonePoint(client, 0, zone, index, false);    
            }

            SetupZoneSpawns();
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

public Action Timer_DrawChangeZonePointBeamsEye( Handle hTimer, int client )
{
    if ( !IsClientInGame( client ) || !IsPlayerAlive( client ) || g_iBuilderZone[client] == ZONE_INVALID )
    {
        g_bStartBuilding[client] = false;
        g_iBuilderZone[client] = ZONE_INVALID;
       	g_iBuilderZoneIndex[client] = -1;
        return Plugin_Stop;
    }
    int len = ( g_hBeams == null ) ? 0 : g_hBeams.Length;
   	static int iData[BEAM_SIZE];
   	static float vecZonePoints_Bottom[5][3];
    static float vecZonePoints_Top[5][3];

    float ZonePointsPlus_y[3] = {0.0, 0.0, 10.0};
    float ZonePointsPlus_x[3] = {0.0, 10.0, 0.0};

   	if (g_iBuilderZone[client] != ZONE_CP)
   	{
	    for (int i=0; i < g_hBeams.Length; i++)
	        if (g_hBeams.Get(i, view_as<int>( BEAM_TYPE ) ) == g_iBuilderZone[client] && g_hBeams.Get(i, view_as<int>( BEAM_INDEX ) ) == g_iBuilderZoneIndex[client])
	        {
	            g_hBeams.GetArray( i, iData, view_as<int>( BeamData ) );
	        }

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
	    #define ZONE_BEAM_ALIVE         0.1
	    // Bottom
	    for (int i = 0; i < 4; i++)
	    {
	     	TE_SetupBeamPoints( vecZonePoints_Bottom[i], vecZonePoints_Bottom[(i == 3) ? 0 : i+1], g_iBeam, 0, 0, 0, ZONE_BEAM_ALIVE, ZONE_WIDTH, ZONE_WIDTH, 0, 0.0, clrBeam[i+1], 0 );
		    TE_SendToAll();
	    }
	   	// Top
	    for (int i = 0; i < 4; i++)
	    {
	    	TE_SetupBeamPoints( vecZonePoints_Top[i], vecZonePoints_Top[(i == 3) ? 0 : i+1], g_iBeam, 0, 0, 0, ZONE_BEAM_ALIVE, ZONE_WIDTH, ZONE_WIDTH, 0, 0.0, clrBeam[i+1], 0 );
	   		TE_SendToAll();
	    }
	    // From bottom to top.
	    for (int i = 0; i < 4; i++)
	    {
	    	TE_SetupBeamPoints( vecZonePoints_Bottom[i], vecZonePoints_Top[i], g_iBeam, 0, 0, 0, ZONE_BEAM_ALIVE, ZONE_WIDTH, ZONE_WIDTH, 0, 0.0, clrBeam[i+1], 0 );
	    	TE_SendToAll();
	    }
	    //DEV POINTS
	    float vecZonePoints_Top_dev_y[2][5][3], vecZonePoints_Top_dev_x[2][5][3], vecZonePoints_Bottom_dev_y[2][5][3], vecZonePoints_Bottom_dev_x[2][5][3];
	    for (int i = 0; i < 5; i++)
	    {
		    ArrayCopy(vecZonePoints_Top[i], vecZonePoints_Top_dev_y[0][i], 3);
		    ArrayCopy(vecZonePoints_Top[i], vecZonePoints_Top_dev_y[1][i], 3);

		    ArrayCopy(vecZonePoints_Top[i], vecZonePoints_Top_dev_x[0][i], 3);
		    ArrayCopy(vecZonePoints_Top[i], vecZonePoints_Top_dev_x[1][i], 3);

	    	ArrayCopy(vecZonePoints_Bottom[i], vecZonePoints_Bottom_dev_y[0][i], 3);
	    	ArrayCopy(vecZonePoints_Bottom[i], vecZonePoints_Bottom_dev_y[1][i], 3);

	    	ArrayCopy(vecZonePoints_Bottom[i], vecZonePoints_Bottom_dev_x[0][i], 3);
	    	ArrayCopy(vecZonePoints_Bottom[i], vecZonePoints_Bottom_dev_x[1][i], 3);
		}

	    for (int i = 0; i < 4; i++)
	    {
	    	vecZonePoints_Top_dev_y[0][i][2] -= 10.0;
	    	vecZonePoints_Top_dev_y[1][i][2] += 10.0;
	    	vecZonePoints_Top_dev_x[0][i][1] -= 10.0;
	    	vecZonePoints_Top_dev_x[1][i][1] += 10.0; 
	    	vecZonePoints_Bottom_dev_y[0][i][2] -= 10.0;
	    	vecZonePoints_Bottom_dev_y[1][i][2] += 10.0;
	    	vecZonePoints_Bottom_dev_x[0][i][1] -= 10.0;
	    	vecZonePoints_Bottom_dev_x[1][i][1] += 10.0;

	    	TE_SetupBeamPoints( vecZonePoints_Top_dev_y[0][i], vecZonePoints_Top_dev_y[1][i], g_iBeam, 0, 0, 0, ZONE_BEAM_ALIVE, ZONE_WIDTH+1.0, ZONE_WIDTH+1.0, 0, 0.0, clrBeam[i == 3 ? DEV_ZONE_PURPLE : i+1], 0 );
	    	TE_SendToAll();
	    	
	    	TE_SetupBeamPoints( vecZonePoints_Top_dev_x[0][i], vecZonePoints_Top_dev_x[1][i], g_iBeam, 0, 0, 0, ZONE_BEAM_ALIVE, ZONE_WIDTH+1.0, ZONE_WIDTH+1.0, 0, 0.0, clrBeam[i == 3 ? DEV_ZONE_PURPLE : i+1], 0 );
	    	TE_SendToAll();
	    	
	    	TE_SetupBeamPoints( vecZonePoints_Bottom_dev_y[0][i], vecZonePoints_Bottom_dev_y[1][i], g_iBeam, 0, 0, 0, ZONE_BEAM_ALIVE, ZONE_WIDTH+1.0, ZONE_WIDTH+1.0, 0, 0.0, clrBeam[i == 3 ? DEV_ZONE_PURPLE : i+1], 0 );
	    	TE_SendToAll();
	    	TE_SetupBeamPoints( vecZonePoints_Bottom_dev_x[0][i], vecZonePoints_Bottom_dev_x[1][i], g_iBeam, 0, 0, 0, ZONE_BEAM_ALIVE, ZONE_WIDTH+1.0, ZONE_WIDTH+1.0, 0, 0.0, clrBeam[i == 3 ? DEV_ZONE_PURPLE : i+1], 0 );
	    	TE_SendToAll();
	    }
	}
	else
	{
        for (int i=0; i < len; i++)
        	if (g_hBeams.Get(i, view_as<int>( BEAM_TYPE ) ) == ZONE_CP && g_hBeams.Get(i, view_as<int>( BEAM_ID ) ) == g_iBuilderZone[client])
            	g_hBeams.GetArray( i, iData, view_as<int>( BeamData ) );

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
	    #define ZONE_BEAM_ALIVE         0.1
	    // Bottom
	    for (int i = 0; i < 4; i++)
	    {
	     	TE_SetupBeamPoints( vecZonePoints_Bottom[i], vecZonePoints_Bottom[(i == 3) ? 0 : i+1], g_iBeam, 0, 0, 0, ZONE_BEAM_ALIVE, ZONE_WIDTH, ZONE_WIDTH, 0, 0.0, clrBeam[i+1], 0 );
		    TE_SendToAll();
	    }
	   	// Top
	    for (int i = 0; i < 4; i++)
	    {
	    	TE_SetupBeamPoints( vecZonePoints_Top[i], vecZonePoints_Top[(i == 3) ? 0 : i+1], g_iBeam, 0, 0, 0, ZONE_BEAM_ALIVE, ZONE_WIDTH, ZONE_WIDTH, 0, 0.0, clrBeam[i+1], 0 );
	   		TE_SendToAll();
	    }
	    // From bottom to top.
	    for (int i = 0; i < 4; i++)
	    {
	    	TE_SetupBeamPoints( vecZonePoints_Bottom[i], vecZonePoints_Top[i], g_iBeam, 0, 0, 0, ZONE_BEAM_ALIVE, ZONE_WIDTH, ZONE_WIDTH, 0, 0.0, clrBeam[i+1], 0 );
	    	TE_SendToAll();
	    }  
	    //DEV POINTS
	    float vecZonePoints_Top_dev_y[2][5][3], vecZonePoints_Top_dev_x[2][5][3], vecZonePoints_Bottom_dev_y[2][5][3], vecZonePoints_Bottom_dev_x[2][5][3];
	    for (int i = 0; i < 5; i++)
	    {
		    ArrayCopy(vecZonePoints_Top[i], vecZonePoints_Top_dev_y[0][i], 3);
		    ArrayCopy(vecZonePoints_Top[i], vecZonePoints_Top_dev_y[1][i], 3);

		    ArrayCopy(vecZonePoints_Top[i], vecZonePoints_Top_dev_x[0][i], 3);
		    ArrayCopy(vecZonePoints_Top[i], vecZonePoints_Top_dev_x[1][i], 3);

	    	ArrayCopy(vecZonePoints_Bottom[i], vecZonePoints_Bottom_dev_y[0][i], 3);
	    	ArrayCopy(vecZonePoints_Bottom[i], vecZonePoints_Bottom_dev_y[1][i], 3);

	    	ArrayCopy(vecZonePoints_Bottom[i], vecZonePoints_Bottom_dev_x[0][i], 3);
	    	ArrayCopy(vecZonePoints_Bottom[i], vecZonePoints_Bottom_dev_x[1][i], 3);
		}

	    for (int i = 0; i < 4; i++)
	    {
	    	vecZonePoints_Top_dev_y[0][i][2] -= 10.0;
	    	vecZonePoints_Top_dev_y[1][i][2] += 10.0;
	    	vecZonePoints_Top_dev_x[0][i][1] -= 10.0;
	    	vecZonePoints_Top_dev_x[1][i][1] += 10.0; 
	    	vecZonePoints_Bottom_dev_y[0][i][2] -= 10.0;
	    	vecZonePoints_Bottom_dev_y[1][i][2] += 10.0;
	    	vecZonePoints_Bottom_dev_x[0][i][1] -= 10.0;
	    	vecZonePoints_Bottom_dev_x[1][i][1] += 10.0;

	    	TE_SetupBeamPoints( vecZonePoints_Top_dev_y[0][i], vecZonePoints_Top_dev_y[1][i], g_iBeam, 0, 0, 0, ZONE_BEAM_ALIVE, ZONE_WIDTH+1.0, ZONE_WIDTH+1.0, 0, 0.0, clrBeam[i == 3 ? DEV_ZONE_PURPLE : i+1], 0 );
	    	TE_SendToAll();
	    	
	    	TE_SetupBeamPoints( vecZonePoints_Top_dev_x[0][i], vecZonePoints_Top_dev_x[1][i], g_iBeam, 0, 0, 0, ZONE_BEAM_ALIVE, ZONE_WIDTH+1.0, ZONE_WIDTH+1.0, 0, 0.0, clrBeam[i == 3 ? DEV_ZONE_PURPLE : i+1], 0 );
	    	TE_SendToAll();
	    	
	    	TE_SetupBeamPoints( vecZonePoints_Bottom_dev_y[0][i], vecZonePoints_Bottom_dev_y[1][i], g_iBeam, 0, 0, 0, ZONE_BEAM_ALIVE, ZONE_WIDTH+1.0, ZONE_WIDTH+1.0, 0, 0.0, clrBeam[i == 3 ? DEV_ZONE_PURPLE : i+1], 0 );
	    	TE_SendToAll();
	    	TE_SetupBeamPoints( vecZonePoints_Bottom_dev_x[0][i], vecZonePoints_Bottom_dev_x[1][i], g_iBeam, 0, 0, 0, ZONE_BEAM_ALIVE, ZONE_WIDTH+1.0, ZONE_WIDTH+1.0, 0, 0.0, clrBeam[i == 3 ? DEV_ZONE_PURPLE : i+1], 0 );
	    	TE_SendToAll();
	    }
	}
   
    return Plugin_Continue;
}

public void ShowHelp(int client, int args)
{	
	Menu mMenu;
	mMenu = new Menu( Handler_Empty );
	mMenu.SetTitle( "<Commands menu>\n " );
	mMenu.AddItem( "", "/timer - Toggle practice mode.", ITEMDRAW_DISABLED );
	mMenu.AddItem( "", "/noclip - Typical noclip.", ITEMDRAW_DISABLED );
	mMenu.AddItem( "", "/restart, /r - Respawn or go back to start if not dead.", ITEMDRAW_DISABLED );
	mMenu.AddItem( "", "/settings - Toggle HUD elements and more.", ITEMDRAW_DISABLED );
	mMenu.AddItem( "", "/stime | /dtime <player|rank> <map> - View soldier|demo info about player run.", ITEMDRAW_DISABLED );	
	mMenu.AddItem( "", "/spec <name> - Spectate a specific player or go to spectate mode.", ITEMDRAW_DISABLED );
	mMenu.AddItem( "", "/p <player> - Stats menu", ITEMDRAW_DISABLED );
	mMenu.AddItem( "", "/b <number> - Go to bonus.", ITEMDRAW_DISABLED );
	mMenu.AddItem( "", "/c <number> - Go to Course.", ITEMDRAW_DISABLED );
	mMenu.AddItem( "", "/s and  /t - Save and teleport to saved point (disable timer for this).", ITEMDRAW_DISABLED );
	mMenu.AddItem( "", "/top <map> - Top times menu.", ITEMDRAW_DISABLED );
	mMenu.AddItem( "", "/m - View map tiers.", ITEMDRAW_DISABLED );	
	mMenu.AddItem( "", "/top - Top times menu.", ITEMDRAW_DISABLED );
	mMenu.AddItem( "", "/set, /setstart - set start position.", ITEMDRAW_DISABLED );
	mMenu.AddItem( "", "/clear, /clearstart - clear setstart position.", ITEMDRAW_DISABLED );
	mMenu.AddItem( "", "/ttop <map> - view tempus top.", ITEMDRAW_DISABLED );
	mMenu.AddItem( "", "/help - This ;)", ITEMDRAW_DISABLED );
	mMenu.AddItem( "", "/version - What version of "...PLUGIN_NAME_CORE..." are we running?", ITEMDRAW_DISABLED );
	mMenu.AddItem( "", "/info - information about plugin", ITEMDRAW_DISABLED );
	
	mMenu.Display( client, MENU_TIME_FOREVER );
}

public Action Command_AllCommands(int client, int args)
{
	if (client <= 0) return Plugin_Handled;

	menu_page[client] = 0;
	AllCommands(client, 0);
}

public void AllCommands(int client, int page)
{
	Menu mMenu = new Menu(Handler_CommandList);
	int count;
	for (int i = 0; i < 81; i++)
	{
		mMenu.AddItem("", command_list[COMMAND][i]);
		count++;
	} 

	mMenu.SetTitle("<Commands list :: %i total>\n ", count);
	mMenu.DisplayAt(client, page, MENU_TIME_FOREVER);
}

public int Handler_CommandList( Menu mMenu, MenuAction action, int client, int item )
{
	if ( action == MenuAction_End ) { delete mMenu; return 0; }
	if ( action != MenuAction_Select ) return 0;
	if (action == MenuAction_Select)
	{
		if (item == 8)
		{
			AllCommands(client, menu_page[client]);
		}
		else
		{
			menu_page[client] = GetMenuSelectionPosition();
			Command_Description(client, item);
		}
	}
	return 0;
}

public void Command_Description(int client, int command_id)
{
	Panel panel = new Panel();

	panel.SetTitle("<Commands list :: Description>\n ");

	panel.DrawText( command_list[COMMAND_DESC][command_id] );
	for (int i; i < 6; i++)
		panel.DrawItem("", ITEMDRAW_SPACER);

	panel.CurrentKey = 8;
	panel.DrawItem("[<<]");

	panel.CurrentKey = 10;
	panel.DrawItem("[<<]");
	
	panel.Send(client, Handler_CommandList, MENU_TIME_FOREVER);
}

public Action Command_Spawn( int client, int args )
{
	if ( !client ) return Plugin_Handled;
	
	TF2_RegeneratePlayer(client);

	g_iClientRun[client] = RUN_SETSTART;
	g_iClientState[client] = STATE_SETSTART;
	RespawnPlayerRun( client );
	
	return Plugin_Handled;
}

public Action Command_ResentRecords_Bonus( int client, int args )
{
	if ( !client ) return Plugin_Handled;
	
	char query[200];
	FormatEx(query, sizeof(query), "SELECT recordid, map, mode, date, run, (select name from plydata where uid = maprecs.uid), CURRENT_TIMESTAMP FROM maprecs where `rank` = 1 and run >= %i and run <= %i order by date desc limit 50", RUN_BONUS1, RUN_BONUS10);
	g_hDatabase.Query(RecentRecords_Bonus_Wr_Callback, query, GetClientUserId( client ));
	
	return Plugin_Handled;
}

public Action Command_ResentRecords_Course( int client, int args )
{
	if ( !client ) return Plugin_Handled;
	
	char query[200];
	FormatEx(query, sizeof(query), "SELECT recordid, map, mode, date, run, (select name from plydata where uid = maprecs.uid), CURRENT_TIMESTAMP FROM maprecs where `rank` = 1 and run >= %i and run <= %i order by date desc limit 50", RUN_COURSE1, RUN_COURSE10);
	g_hDatabase.Query(RecentRecords_Course_Wr_Callback, query, GetClientUserId( client ));
	
	return Plugin_Handled;
}

public Action Command_ResentRecords( int client, int args )
{
	if ( !client ) return Plugin_Handled;
	
	Menu mMenu = new Menu(Recent_records_handler);

	mMenu.SetTitle("<Recent Records :: Selection>\n ");
	mMenu.AddItem("", "Recent Map Records");
	mMenu.AddItem("", "Recent Map Top 10s");
	mMenu.AddItem("", "Recent Course Records");
	mMenu.AddItem("", "Recent Course Top 10s");
	mMenu.AddItem("", "Recent Bonus Records");
	mMenu.AddItem("", "Recent Bonus Top 10s\n \n ");

	mMenu.Display(client, MENU_TIME_FOREVER);
	
	return Plugin_Handled;
}

public int Recent_records_handler( Menu mMenu, MenuAction action, int client, int item )
{
	if ( action == MenuAction_End ) { delete mMenu; return 0; }
	if ( action != MenuAction_Select ) return 0;

	char query[300];

	if (item == 0)
	{
		g_hDatabase.Format(query, sizeof(query), "SELECT recordid, map, mode, date, (select name from plydata where uid = maprecs.uid), CURRENT_TIMESTAMP FROM maprecs where `rank` = 1 and run = 0 order by date desc limit 100");
		g_hDatabase.Query(RecentRecords_Map_Wr_Callback, query, GetClientUserId( client ));
	}
	if (item == 1)
	{
		g_hDatabase.Format(query, sizeof(query), "SELECT recordid, map, mode, date, `rank`, (select name from plydata where uid = maprecs.uid), CURRENT_TIMESTAMP FROM maprecs where `rank` > 1 and `rank` <= 10 and run = 0 order by date desc limit 100");
		g_hDatabase.Query(RecentRecords_Map_Tt_Callback, query, GetClientUserId( client ));
	}
	if (item == 2)
	{
		g_hDatabase.Format(query, sizeof(query), "SELECT recordid, map, mode, date, run, (select name from plydata where uid = maprecs.uid), CURRENT_TIMESTAMP FROM maprecs where `rank` = 1 and run >= %i and run <= %i order by date desc limit 100", RUN_COURSE1, RUN_COURSE10);
		g_hDatabase.Query(RecentRecords_Course_Wr_Callback, query, GetClientUserId( client ));
	}
	if (item == 3)
	{
		g_hDatabase.Format(query, sizeof(query), "SELECT recordid, map, mode, date, `rank`, run, (select name from plydata where uid = maprecs.uid), CURRENT_TIMESTAMP FROM maprecs where `rank` >= 2 and `rank` <= 10 and run >= %i and run <= %i order by date desc limit 100", RUN_COURSE1, RUN_COURSE10);
		g_hDatabase.Query(RecentRecords_Course_Tt_Callback, query, GetClientUserId( client ));
	}
	if (item == 4)
	{
		g_hDatabase.Format(query, sizeof(query), "SELECT recordid, map, mode, date, run, (select name from plydata where uid = maprecs.uid), CURRENT_TIMESTAMP FROM maprecs where `rank` = 1 and run >= %i and run <= %i order by date desc limit 100", RUN_BONUS1, RUN_BONUS10);
		g_hDatabase.Query(RecentRecords_Bonus_Wr_Callback, query, GetClientUserId( client ));
	}
	if (item == 5)
	{
		g_hDatabase.Format(query, sizeof(query), "SELECT recordid, map, mode, date, `rank`, run, (select name from plydata where uid = maprecs.uid), CURRENT_TIMESTAMP FROM maprecs where `rank` >= 2 and `rank` <= 10 and run >= %i and run <= %i order by date desc limit 100", RUN_BONUS1, RUN_BONUS10);
		g_hDatabase.Query(RecentRecords_Bonus_Tt_Callback, query, GetClientUserId( client ));
	}
	return 0;
}

public void RecentRecords_Map_Wr_Callback( Database hOwner, DBResultSet hQuery, const char[] szError, int client )
{
	if ( !(client = GetClientOfUserId( client )) ) return;
	
	if ( hQuery == null )
	{
		DB_LogError( szError );
		
		return;
	}

	if ( hQuery.RowCount )
	{
		Menu mMenu = new Menu(RecentRecords_Runs_Handler);
		mMenu.SetTitle("<Recent Jump Map Records>\n ");

		char recordid[6];
		int mode;
		char map[60], date[40], name[25], buffer[100], cur_date[100];
		while (hQuery.FetchRow())
		{
			IntToString( hQuery.FetchInt(0), recordid, sizeof(recordid));
			hQuery.FetchString( 1, map, sizeof( map ) );
			mode = hQuery.FetchInt(2);
			hQuery.FetchString( 3, date, sizeof( date ) );
			hQuery.FetchString( 4, name, sizeof( name ) );
			hQuery.FetchString( 5, cur_date, sizeof( cur_date ) );

			ReplaceString(map, sizeof(map), "jump_", "");
			ReplaceString(map, sizeof(map), "sj_", "");
			ReplaceString(map, sizeof(map), "rj_", "");

			FormatTimeDuration(date, sizeof(date), DateTimeToTimestamp(cur_date) - DateTimeToTimestamp(date));

			FormatEx(buffer, sizeof(buffer), "(%s) <%s> - %s - %s", g_szModeName[NAME_SHORT][mode][0], map, name, date);
			mMenu.AddItem(recordid, buffer);
		}
		mMenu.ExitBackButton = true;
		SetNewPrevMenu(client, mMenu);
		mMenu.Display(client, MENU_TIME_FOREVER);
	}
	delete hQuery;
}

public void RecentRecords_Map_Tt_Callback( Database hOwner, DBResultSet hQuery, const char[] szError, int client )
{
	if ( !(client = GetClientOfUserId( client )) ) return;
	
	if ( hQuery == null )
	{
		DB_LogError( szError );
		
		return;
	}

	if ( hQuery.RowCount )
	{
		Menu mMenu = new Menu(RecentRecords_Runs_Handler);
		mMenu.SetTitle("<Recent Jump Map Top 10s>\n ");

		char recordid[6];
		int mode, rank;
		char map[60], date[40], name[25], buffer[100], cur_date[100];
		while (hQuery.FetchRow())
		{
			IntToString( hQuery.FetchInt(0), recordid, sizeof(recordid));
			hQuery.FetchString( 1, map, sizeof( map ) );
			mode = hQuery.FetchInt(2);
			hQuery.FetchString( 3, date, sizeof( date ) );
			rank = hQuery.FetchInt(4);
			hQuery.FetchString( 5, name, sizeof( name ) );
			hQuery.FetchString( 6, cur_date, sizeof( cur_date ) );

			ReplaceString(map, sizeof(map), "jump_", "");
			ReplaceString(map, sizeof(map), "sj_", "");
			ReplaceString(map, sizeof(map), "rj_", "");

			FormatTimeDuration(date, sizeof(date), DateTimeToTimestamp(cur_date) - DateTimeToTimestamp(date));

			FormatEx(buffer, sizeof(buffer), "(%s) <%s> (#%i) - %s - %s", g_szModeName[NAME_SHORT][mode][0], map, rank, name, date);
			mMenu.AddItem(recordid, buffer);
		}
		mMenu.ExitBackButton = true;
		SetNewPrevMenu(client, mMenu);
		mMenu.Display(client, MENU_TIME_FOREVER);
	}
	delete hQuery;
}

public void RecentRecords_Course_Wr_Callback( Database hOwner, DBResultSet hQuery, const char[] szError, int client )
{
	if ( !(client = GetClientOfUserId( client )) ) return;
	
	if ( hQuery == null )
	{
		DB_LogError( szError );
		
		return;
	}

	if ( hQuery.RowCount )
	{
		Menu mMenu = new Menu(RecentRecords_Runs_Handler);
		mMenu.SetTitle("<Recent Jump Course Records>\n ");

		char recordid[6];
		int mode, run;
		char map[60], date[40], name[25], buffer[100], cur_date[100];
		while (hQuery.FetchRow())
		{
			IntToString( hQuery.FetchInt(0), recordid, sizeof(recordid));
			hQuery.FetchString( 1, map, sizeof( map ) );
			mode = hQuery.FetchInt(2);
			hQuery.FetchString( 3, date, sizeof( date ) );
			run = hQuery.FetchInt(4);
			hQuery.FetchString( 5, name, sizeof( name ) );
			hQuery.FetchString( 6, cur_date, sizeof( cur_date ) );

			ReplaceString(map, sizeof(map), "jump_", "");
			ReplaceString(map, sizeof(map), "sj_", "");
			ReplaceString(map, sizeof(map), "rj_", "");

			FormatTimeDuration(date, sizeof(date), DateTimeToTimestamp(cur_date) - DateTimeToTimestamp(date));

			FormatEx(buffer, sizeof(buffer), "(%s) <%s [%s]> - %s - %s", g_szModeName[NAME_SHORT][mode][0], map, g_szRunName[NAME_SHORT][run], name, date);
			mMenu.AddItem(recordid, buffer);
		}
		mMenu.ExitBackButton = true;
		SetNewPrevMenu(client, mMenu);
		mMenu.Display(client, MENU_TIME_FOREVER);
	}
	delete hQuery;
}

public void RecentRecords_Course_Tt_Callback( Database hOwner, DBResultSet hQuery, const char[] szError, int client )
{
	if ( !(client = GetClientOfUserId( client )) ) return;
	
	if ( hQuery == null )
	{
		DB_LogError( szError );
		
		return;
	}

	if ( hQuery.RowCount )
	{
		Menu mMenu = new Menu(RecentRecords_Runs_Handler);
		mMenu.SetTitle("<Recent Jump Course Top 10s>\n ");

		char recordid[6];
		int mode, rank, run;
		char map[60], date[40], name[25], buffer[100], cur_date[100];
		while (hQuery.FetchRow())
		{
			IntToString( hQuery.FetchInt(0), recordid, sizeof(recordid));
			hQuery.FetchString( 1, map, sizeof( map ) );
			mode = hQuery.FetchInt(2);
			hQuery.FetchString( 3, date, sizeof( date ) );
			rank = hQuery.FetchInt(4);
			run = hQuery.FetchInt(5);
			hQuery.FetchString( 6, name, sizeof( name ) );
			hQuery.FetchString( 7, cur_date, sizeof( cur_date ) );

			ReplaceString(map, sizeof(map), "jump_", "");
			ReplaceString(map, sizeof(map), "sj_", "");
			ReplaceString(map, sizeof(map), "rj_", "");

			FormatTimeDuration(date, sizeof(date), DateTimeToTimestamp(cur_date) - DateTimeToTimestamp(date));

			FormatEx(buffer, sizeof(buffer), "(%s) <%s [%s]> (#%i) - %s - %s", g_szModeName[NAME_SHORT][mode][0], map, g_szRunName[NAME_SHORT][run], rank, name, date);
			mMenu.AddItem(recordid, buffer);
		}
		mMenu.ExitBackButton = true;
		SetNewPrevMenu(client, mMenu);
		mMenu.Display(client, MENU_TIME_FOREVER);
	}
	delete hQuery;
}

public void RecentRecords_Bonus_Wr_Callback( Database hOwner, DBResultSet hQuery, const char[] szError, int client )
{
	if ( !(client = GetClientOfUserId( client )) ) return;
	
	if ( hQuery == null )
	{
		DB_LogError( szError );
		
		return;
	}

	if ( hQuery.RowCount )
	{
		Menu mMenu = new Menu(RecentRecords_Runs_Handler);
		mMenu.SetTitle("<Recent Jump Bonus Records>\n ");

		char recordid[6];
		int mode, rank, run;
		char map[60], date[40], name[25], buffer[100], cur_date[100];
		while (hQuery.FetchRow())
		{
			IntToString( hQuery.FetchInt(0), recordid, sizeof(recordid));
			hQuery.FetchString( 1, map, sizeof( map ) );
			mode = hQuery.FetchInt(2);
			hQuery.FetchString( 3, date, sizeof( date ) );
			run = hQuery.FetchInt(4);
			hQuery.FetchString( 5, name, sizeof( name ) );
			hQuery.FetchString( 6, cur_date, sizeof( cur_date ) );

			ReplaceString(map, sizeof(map), "jump_", "");
			ReplaceString(map, sizeof(map), "sj_", "");
			ReplaceString(map, sizeof(map), "rj_", "");

			FormatTimeDuration(date, sizeof(date), DateTimeToTimestamp(cur_date) - DateTimeToTimestamp(date));

			FormatEx(buffer, sizeof(buffer), "(%s) <%s [%s]> - %s - %s", g_szModeName[NAME_SHORT][mode][0], map, g_szRunName[NAME_SHORT][run], name, date);
			mMenu.AddItem(recordid, buffer);
		}
		mMenu.ExitBackButton = true;
		SetNewPrevMenu(client, mMenu);
		mMenu.Display(client, MENU_TIME_FOREVER);
	}
	delete hQuery;
}

public void RecentRecords_Bonus_Tt_Callback( Database hOwner, DBResultSet hQuery, const char[] szError, int client )
{
	if ( !(client = GetClientOfUserId( client )) ) return;
	
	if ( hQuery == null )
	{
		DB_LogError( szError );
		
		return;
	}

	if ( hQuery.RowCount )
	{
		Menu mMenu = new Menu(RecentRecords_Runs_Handler);
		mMenu.SetTitle("<Recent Jump Bonus Top 10s>\n ");

		char recordid[6];
		int mode, rank, run;
		char map[60], date[40], name[25], buffer[100], cur_date[100];
		while (hQuery.FetchRow())
		{
			IntToString( hQuery.FetchInt(0), recordid, sizeof(recordid));
			hQuery.FetchString( 1, map, sizeof( map ) );
			mode = hQuery.FetchInt(2);
			hQuery.FetchString( 3, date, sizeof( date ) );
			rank = hQuery.FetchInt(4);
			run = hQuery.FetchInt(5);
			hQuery.FetchString( 6, name, sizeof( name ) );
			hQuery.FetchString( 7, cur_date, sizeof( cur_date ) );

			ReplaceString(map, sizeof(map), "jump_", "");
			ReplaceString(map, sizeof(map), "sj_", "");
			ReplaceString(map, sizeof(map), "rj_", "");

			FormatTimeDuration(date, sizeof(date), DateTimeToTimestamp(cur_date) - DateTimeToTimestamp(date));

			FormatEx(buffer, sizeof(buffer), "(%s) <%s [%s]> (#%i) - %s - %s", g_szModeName[NAME_SHORT][mode][0], map, g_szRunName[NAME_SHORT][run], rank, name, date);
			mMenu.AddItem(recordid, buffer);
		}
		mMenu.ExitBackButton = true;
		SetNewPrevMenu(client, mMenu);
		mMenu.Display(client, MENU_TIME_FOREVER);
	}
	delete hQuery;
}

public int RecentRecords_Runs_Handler( Menu mMenu, MenuAction action, int client, int item )
{
	if ( action == MenuAction_End ) { return 0; }

	if ( action == MenuAction_Cancel )
	{
		if (item == MenuCancel_ExitBack)
		{
			ClientCommand(client, "sm_rr");
		}
		return 0;
	}

	if ( action != MenuAction_Select ) return 0;

	char szRecordid[6];
	int recordid;

	GetMenuItem( mMenu, item, szRecordid, sizeof( szRecordid ) );

	StringToIntEx(szRecordid, recordid);

	DB_RecordInfo(client, recordid);
	
	return 0;
}

public Action Command_Ranks(int client, int args)
{
	menu_page[client] = 0;
	Menu mMenu = new Menu(Menu_Ranks_Callback);
	Ranks_list(client, mMenu, menu_page[client]);
    return Plugin_Handled;
}

public void Ranks_list(int client, Menu mMenu, int page)
{
    mMenu.SetTitle("<Chat Ranks>\n ");
    mMenu.RemoveAllItems();

    mMenu.AddItem("Emperor", "[1] Emperor");
    mMenu.AddItem("King", "[2] King");
    mMenu.AddItem("Archduke", "[3] Archduke");
    mMenu.AddItem("Lord", "[4] Lord");
    mMenu.AddItem("Duke", "[5] Duke");
    mMenu.AddItem("Prince", "[6-10] Prince");
    mMenu.AddItem("Earl", "[11-15] Earl");
    mMenu.AddItem("Sir", "[16-20] Sir");
    mMenu.AddItem("Count", "[21-25] Count");
    mMenu.AddItem("Baron", "[26-30] Baron");
    mMenu.AddItem("Knight", "[31-35] Knight");
    mMenu.AddItem("Noble", "[36-40] Noble");
    mMenu.AddItem("Esquire", "[41-45] Esquire");
    mMenu.AddItem("Jester", "[46-50] Jester");
    mMenu.AddItem("Plebeian", "[51-55] Plebeian");
    mMenu.AddItem("Peasant", "[56-60] Peasant");
    mMenu.AddItem("Peon", "[61+] Peon");
    
    mMenu.DisplayAt(client, menu_page[client], MENU_TIME_FOREVER);

    return;
}

public int Menu_Ranks_Callback( Menu mMenu, MenuAction action, int client, int item )
{
    if ( action == MenuAction_Cancel ) return 0;

    if ( action != MenuAction_Select ) return 0;
    
    if (action == MenuAction_Select)
	{
	    char szItem[10];
	    menu_page[client] = GetMenuSelectionPosition();

	    Ranks_list(client, mMenu, menu_page[client]);

	    if ( !GetMenuItem( mMenu, item, szItem, sizeof( szItem ) ) ) return 0;
	    
	    if (StrEqual(szItem, "Emperor"))
	    {
	    	mMenu.RemoveItem(item);
	    	mMenu.InsertItem(item, "Emperor", "[1] Emperor Ranks:\nNo Sub-ranks\n ");
	    }
	    else if (StrEqual(szItem, "King"))
	    {
	    	mMenu.RemoveItem(item);
	    	mMenu.InsertItem(item, "King", "[2] King Ranks:\nNo Sub-ranks\n ");
	    }
	    else if (StrEqual(szItem, "Archduke"))
	    {
	    	mMenu.RemoveItem(item);
	    	mMenu.InsertItem(item, "Archduke", "[3] Archduke Ranks:\nNo Sub-ranks\n ");
	    }
	    else if (StrEqual(szItem, "Lord"))
	    {
	    	mMenu.RemoveItem(item);
	    	mMenu.InsertItem(item, "Lord", "[4] Lord Ranks:\nNo Sub-ranks\n ");
	    }
	    else if (StrEqual(szItem, "Duke"))
	    {
	    	mMenu.RemoveItem(item);
	    	mMenu.InsertItem(item, "Duke", "[5] Duke Ranks:\nNo Sub-ranks\n ");
	    }
	    else if (StrEqual(szItem, "Prince"))
	    {
	    	mMenu.RemoveItem(item);
	    	mMenu.InsertItem(item, "Prince", "[6-10] Prince Ranks:\n[6] Prince I\n[7] Prince II\n[8] Prince III\n[9] Prince IV\n[10] Prince V\n ");
	    }
	    else if (StrEqual(szItem, "Earl"))
	    {
	    	mMenu.RemoveItem(item);
	    	mMenu.InsertItem(item, "Earl", "[11-15] Earl Ranks:\n[11] Earl I\n[12] Earl II\n[13] Earl III\n[14] Earl IV\n[15] Earl V\n ");
	    }
	    else if (StrEqual(szItem, "Sir"))
	    {
	    	mMenu.RemoveItem(item);
	    	mMenu.InsertItem(item, "Sir", "[16-20] Sir Ranks:\n[16] Sir I\n[17] Sir II\n[18] Sir III\n[19] Sir IV\n[20] Sir V\n ");
	    }
	    else if (StrEqual(szItem, "Count"))
	    {
	    	mMenu.RemoveItem(item);
	    	mMenu.InsertItem(item, "Count", "[21-25] Count Ranks:\n[21] Count I\n[22] Count II\n[23] Count III\n[24] Count IV\n[25] Count V\n ");
	    }
	    else if (StrEqual(szItem, "Baron"))
	    {
	    	mMenu.RemoveItem(item);
	    	mMenu.InsertItem(item, "Baron", "[26-30] Baron Ranks:\n[26] Baron I\n[27] Baron II\n[28] Baron III\n[29] Baron IV\n[30] Baron V\n ");
	    }
	    else if (StrEqual(szItem, "Knight"))
	    {
	    	mMenu.RemoveItem(item);
	    	mMenu.InsertItem(item, "Knight", "[31-35] Knight Ranks:\n[31] Knight I\n[32] Knight II\n[33] Knight III\n[34] Knight IV\n[35] Knight V\n ");
	    }
	    else if (StrEqual(szItem, "Noble"))
	    {
	    	mMenu.RemoveItem(item);
	    	mMenu.InsertItem(item, "Noble", "[36-40] Noble Ranks:\n[36] Noble I\n[37] Noble II\n[38] Noble III\n[39] Noble IV\n[40] Noble V\n ");
	    }
	    else if (StrEqual(szItem, "Esquire"))
	    {
	    	mMenu.RemoveItem(item);
	    	mMenu.InsertItem(item, "Esquire", "[41-45] Esquire Ranks:\n[41] Esquire I\n[42] Esquire II\n[43] Esquire III\n[44] Esquire IV\n[45] Esquire V\n ");
	    }
	    else if (StrEqual(szItem, "Jester"))
	    {
	    	mMenu.RemoveItem(item);
	    	mMenu.InsertItem(item, "Jester", "[46-50] Jester Ranks:\n[46] Jester I\n[47] Jester II\n[48] Jester III\n[49] Jester IV\n[50] Jester V\n ");
	    }
	    else if (StrEqual(szItem, "Plebeian"))
	    {
	    	mMenu.RemoveItem(item);
	    	mMenu.InsertItem(item, "Plebeian", "[51-55] Plebeian Ranks:\n[51] Plebeian I\n[52] Plebeian II\n[53] Plebeian III\n[54] Plebeian IV\n[55] Plebeian V\n ");
	    }
	    else if (StrEqual(szItem, "Peasant"))
	    {
	    	mMenu.RemoveItem(item);
	    	mMenu.InsertItem(item, "Peasant", "[56-60] Peasant Ranks:\n[56] Peasant I\n[57] Peasant II\n[58] Peasant III\n[59] Peasant IV\n[60] Peasant V\n ");
	    }
	    else if (StrEqual(szItem, "Peon"))
	    {
	    	mMenu.RemoveItem(item);
	    	mMenu.InsertItem(item, "Peon", "[61+] Peon Ranks:\nNo Sub-ranks\n ");
	    }
	    
    	mMenu.DisplayAt(client, menu_page[client], MENU_TIME_FOREVER);
	}

    return 0;
}

public Action Command_Set_Start(int client, int args)
{

	static int target;
    target = client;
	if (!client) return Plugin_Handled;
	if (!IsPlayerAlive(client)) return Plugin_Handled;
	
	if (!(GetEntityFlags(client) & FL_ONGROUND)){
		CPrintToChat( client, CHAT_PREFIX..."This command can only be used on the ground." );
		return Plugin_Handled;
	}
	GetEntPropVector(client, Prop_Send, "m_vecOrigin", g_fClientRespawnPosition[client] );
	GetClientEyePosition(client, g_fClientRespawnEyePos[client] );
	GetClientEyeAngles(client, g_fClientRespawnEyes[client] );
	GetClientAbsAngles(client, g_fClientRespawnAngles[client] );

	if ( g_fClientHideFlags[client] & HIDEHUD_SETSTART_POS )
		g_fClientRespawnEyes[client][0] = 0.00;

	CPrintToChat( client, CHAT_PREFIX..."Starting position set. Use /clearstart or /clear to return to the default starting point." );
	return Plugin_Handled;
}

public Action Command_Clear_Start(int client, int args){
	if (!client) return Plugin_Handled;

	for (int i = 0; i < 3; i++)
	{
		g_fClientRespawnPosition[client][i] = 0.0;
		g_fClientRespawnEyePos[client][i] = 0.0;
		g_fClientRespawnEyes[client][i] = 0.0;
		g_fClientRespawnAngles[client][i] = 0.0;
	}

	CPrintToChat( client, CHAT_PREFIX..."Starting position reset." );
		
		
	return Plugin_Handled;
}

public Action Command_ResentBrokenRecords(int client, int args)
{
	if (!client) return Plugin_Handled;

	char query[600];
	char search_method[200], sArg[32];

	Transaction t = new Transaction();
	if (args)
	{
		GetCmdArgString(sArg, sizeof(sArg));
		g_hDatabase.Format(query, sizeof(query), "select name from plydata where name LIKE '%s%%' order by overall DESC limit 1;", sArg);
		t.AddQuery(query);

		g_hDatabase.Format(query, sizeof(query), "SELECT mode, map, run, recordid, date, CURRENT_TIMESTAMP FROM maprecs where uid = (select uid from plydata where name like '%s%%' order by overall DESC limit 1) and beaten = 1 and `rank` > 1 order by date DESC;", sArg);
		t.AddQuery(query);
	}
	else
	{
		g_hDatabase.Format(query, sizeof(query), "select name from plydata where uid = %i limit 1;", g_iClientId[client]);
		t.AddQuery(query);

		g_hDatabase.Format(query, sizeof(query), "SELECT mode, map, run, recordid, date, CURRENT_TIMESTAMP FROM maprecs where uid = %i and beaten = 1 and `rank` > 1 order by date DESC;", g_iClientId[client]);
		t.AddQuery(query);
	}

	SQL_ExecuteTransaction(g_hDatabase, t, Threaded_ResentBrokenRecords, Threaded_ResentBrokenRecordsError, client);

	return Plugin_Handled;
}

public void Threaded_ResentBrokenRecords(Database g_hDatabase, any client, int numQueries, DBResultSet[] results, any[] queryData)
{
	if ( results[0] == null )
	{
		PrintToServer( "Recent broken records ERROR" );
		
		return;
	}

	int run, mode, recordid;
	char my_name[32], map[40], buffer[100], szId[10];

	Menu mMenu = new Menu( menu_RecentBroken );
	char time_ago[40], cur_date[40], rec_date[40]; 

	if (results[0].FetchRow())
		results[0].FetchString( 0, my_name, sizeof( my_name ));

	if (results[1].RowCount)
	{
		while (results[1].FetchRow())
		{
			mode = results[1].FetchInt( 0 );
			results[1].FetchString( 1, map, sizeof( map ));
			run = results[1].FetchInt( 2 );
			recordid = results[1].FetchInt( 3 );
			results[1].FetchString( 4, rec_date, sizeof( rec_date ));
			results[1].FetchString( 5, cur_date, sizeof( cur_date ));

			FormatTimeDuration(time_ago, sizeof(time_ago), DateTimeToTimestamp(cur_date) - DateTimeToTimestamp(rec_date));

			FormatEx(buffer, sizeof(buffer), "(%s) %s [%s] - %s", g_szModeName[NAME_SHORT][mode], map, g_szRunName[NAME_LONG][run], time_ago);
			IntToString(recordid, szId, sizeof(szId));
			mMenu.AddItem(szId, buffer);
		}
	}
	else
	{
		for (int i; i < 7; i++)
		{
			mMenu.AddItem("", "", ITEMDRAW_SPACER);
		}
	}
	mMenu.SetTitle("<Recently Lost Jump Records>\nPlayer: %s\n ", my_name);
	SetNewPrevMenu(client, mMenu);
	mMenu.Display(client, MENU_TIME_FOREVER);
}

public int menu_RecentBroken( Menu mMenu, MenuAction action, int client, int item )
{
	if ( action == MenuAction_End ) { delete mMenu; return 0; }
	if ( action == MenuAction_Cancel) return 0;
	if ( action != MenuAction_Select ) return 0;
	if ( action == MenuAction_Select )
	{
		char szId[10];

		GetMenuItem( mMenu, item, szId, sizeof( szId ) );

		int id = StringToInt(szId);

		DB_RecordInfo(client, id);
	}
	return 0;
}

public void Threaded_ResentBrokenRecordsError(Database g_hDatabase, any client, int numQueries, const char[] error, int failIndex, any[] queryData)
{
	PrintToServer(error);
	return;
}

public void DestroyProjectilesDemo(int client)
{
    if (!IsValidEntity(client))
    {
        return;
    }

    int entity = -1;
    
    // Stickies 
    while ((entity = FindEntityByClassname(entity, "tf_projectile_pipe_remote")) != -1)
    {
        if (IsValidEntity(entity))
        {
            // Uses different ent property for tracking the owner then Soldier
            if (GetEntPropEnt(entity, Prop_Data, "m_hThrower") == client)
            {
                CreateTimer(0.0, DestroyProjectile, entity, TIMER_FLAG_NO_MAPCHANGE);
            }
        }
    }
    
    // Pipes
    while ((entity = FindEntityByClassname(entity, "tf_projectile_pipe")) != -1)
    {
        if (IsValidEntity(entity))
        {
            // Uses different ent property for tracking the owner then Soldier
            if (GetEntPropEnt(entity, Prop_Data, "m_hThrower") == client)
            {
                CreateTimer(0.0, DestroyProjectile, entity, TIMER_FLAG_NO_MAPCHANGE);
            }
        }
    }  
}

public void DestroyProjectilesSoldier(int client)
{
    if (!IsValidEntity(client))
    {
        return;
    }

    int entity = -1;
    
    // Normal Rockets
    while ((entity = FindEntityByClassname(entity, "tf_projectile_rocket")) != -1)
    {
        if (IsValidEntity(entity))
        {
            if (GetEntPropEnt(entity, Prop_Data, "m_hOwnerEntity") == client)
            {
                CreateTimer(0.0, DestroyProjectile, entity, TIMER_FLAG_NO_MAPCHANGE);
            }
        }
    }

    // Cow Mangler rockets
    while ((entity = FindEntityByClassname(entity, "tf_projectile_energy_ball")) != -1)
    {
        if (IsValidEntity(entity))
        {
            if (GetEntPropEnt(entity, Prop_Data, "m_hOwnerEntity") == client)
            {
                CreateTimer(0.0, DestroyProjectile, entity, TIMER_FLAG_NO_MAPCHANGE);
            }
        }
    }
}

public Action DestroyProjectile(Handle timer, any edict)
{
    if (IsValidEntity(edict))
    {
        RemoveEdict(edict);
    }
}

public Action Command_Practise_SavePoint( int client, int args )
{
	if ( !client ) return Plugin_Handled;
	
	if ( !g_bClientPractising[client] )
	{
		CPrintToChat( client, CHAT_PREFIX..."You have to be in {lightskyblue}timer disabled{white} mode for use save and teleport! ({lightskyblue}!timer{white})" );
		return Plugin_Handled;
	}
	
	if ( !IsValidCommandUser( client ) ) return Plugin_Handled;
	
	float vecTemp[3];
	GetClientAbsOrigin( client, g_SavePointOrig[client] );
	
	GetClientEyeAngles( client, g_SavePointEye[client] );
	
	CPrintToChat( client, CHAT_PREFIX..."Saved location!" );
	
	return Plugin_Handled;
}

public Action Command_Practise_GotoSavedLoc( int client, int args )
{
	if ( !client ) return Plugin_Handled;
	
	if ( !g_bClientPractising[client] )
	{
		CPrintToChat( client, CHAT_PREFIX..."You have to be in {lightskyblue}timer disabled{white} mode for use save and teleport! ({lightskyblue}!timer{white})" );
		return Plugin_Handled;
	}
	
	if ( !IsValidCommandUser( client ) ) return Plugin_Handled;
	
	TeleportEntity( client, g_SavePointOrig[client], g_SavePointEye[client], NULL_VECTOR );

	CPrintToChat( client, CHAT_PREFIX..."Teleported to Saved location!" );
	
	return Plugin_Handled;
}

public Action Command_Bonus(int client, int args)
{
	if (!client) return Plugin_Handled;
	
	if ( !args )
	{
		BonusMenu(client);
		
		return Plugin_Handled;
	}
	char szArg[4];
	GetCmdArgString( szArg, sizeof( szArg ) );
	StripQuotes( szArg );

	int bonus = StringToInt(szArg);
	
	int len = strlen(szArg);
	for (int i=0; i < len; i++)
	{
		if (!IsCharNumeric(szArg[i]))
		{
			CPrintToChat(client, CHAT_PREFIX... "You must enter the bonus number");
			return Plugin_Handled;
		}
	}

	if (!(0 < bonus))
	{
		CPrintToChat(client, CHAT_PREFIX... "The bonus number is not entered correctly");
	  	return Plugin_Handled;
	}
	if ((10+bonus) <= RUN_BONUS10 && g_bIsLoaded[10+bonus] )
	{
		if (TF2_GetPlayerClass(client) == TFClass_DemoMan) {
			SetEntityGravity(client, 1.0);
			SetEntityHealth(client, 175);
	   		DestroyProjectilesDemo(client);
		} else if (TF2_GetPlayerClass(client) == TFClass_Soldier) {
			SetEntityGravity(client, 1.0);
		    DestroyProjectilesSoldier(client);
		}

		TeleportEntity( client, g_vecSpawnPos[10+bonus], g_vecSpawnAngles[10+bonus], g_vecNull );
		TF2_RegeneratePlayer(client);
		g_fClientRespawnPosition[client][0] = 0.0;
		g_fClientRespawnPosition[client][1] = 0.0;
		g_fClientRespawnPosition[client][2] = 0.0;
		
		g_fClientRespawnAngles[client][0] = 0.0;
		g_fClientRespawnAngles[client][1] = 0.0;
		g_fClientRespawnAngles[client][2] = 0.0;

		return Plugin_Handled;
	}

	int bonus_count = 0;
		
	for (int i = RUN_BONUS1; i <= RUN_BONUS10; i++)
	{
		if (g_bIsLoaded[i])
		{
			bonus_count++;
		}
	}

	if (bonus_count > 0)
	{
		CPrintToChat(client, CHAT_PREFIX... "Only {lightskyblue}%i {white}bonuses are available", bonus_count);
	}
	else
	{
		CPrintToChat(client, CHAT_PREFIX... "No bonuses available");
	}
	return Plugin_Handled;
}

public Action Command_Courses(int client, int args)
{
	if (!client) return Plugin_Handled;	
	
	if ( !args )
	{
		CourseMenu(client);
		
		return Plugin_Handled;
	}
	char szArg[4];
	GetCmdArgString( szArg, sizeof( szArg ) );
	StripQuotes( szArg );

	int course = StringToInt(szArg);
	
	int len = strlen(szArg);
	for (int i=0; i < len; i++)
	{
		if (!IsCharNumeric(szArg[i]))
		{
			CPrintToChat(client, CHAT_PREFIX... "You must enter the course number");
			return Plugin_Handled;
		}
	}

	if (!(0 < course))
	{
		CPrintToChat(client, CHAT_PREFIX... "The course number is not entered correctly");
	  	return Plugin_Handled;
	}
	if (course <= RUN_COURSE10 && g_bIsLoaded[course] )
	{
		if (TF2_GetPlayerClass(client) == TFClass_DemoMan) {
			SetEntityGravity(client, 1.0);
			SetEntityHealth(client, 175);
	   		DestroyProjectilesDemo(client);
		} else if (TF2_GetPlayerClass(client) == TFClass_Soldier) {
			SetEntityGravity(client, 1.0);
		    DestroyProjectilesSoldier(client);
		}

		TeleportEntity( client, g_vecSpawnPos[course], g_vecSpawnAngles[course], g_vecNull );
		TF2_RegeneratePlayer(client);
		g_fClientRespawnPosition[client][0] = 0.0;
		g_fClientRespawnPosition[client][1] = 0.0;
		g_fClientRespawnPosition[client][2] = 0.0;
		
		g_fClientRespawnAngles[client][0] = 0.0;
		g_fClientRespawnAngles[client][1] = 0.0;
		g_fClientRespawnAngles[client][2] = 0.0;

		IsMapMode[client] = (course != 1) ? false : true;
		DisplayCpTime[client] = false;

		return Plugin_Handled;
	}

	int course_count = 0;
		
	for (int i = RUN_COURSE1; i <= RUN_COURSE10; i++)
	{
		if (g_bIsLoaded[i])
		{
			course_count++;
		}
	}

	if (course_count > 0)
	{
		CPrintToChat(client, CHAT_PREFIX... "Only {lightskyblue}%i {white}courses are available", course_count);
	}
	else
	{
		CPrintToChat(client, CHAT_PREFIX... "No courses available");
	}
	return Plugin_Handled;
}

stock void ClearStart(int client){
	if (!client) return Plugin_Handled;
	g_fClientRespawnPosition[client][0] = 0.0;
	g_fClientRespawnPosition[client][1] = 0.0;
	g_fClientRespawnPosition[client][2] = 0.0;
	
	g_fClientRespawnAngles[client][0] = 0.0;
	g_fClientRespawnAngles[client][1] = 0.0;
	g_fClientRespawnAngles[client][2] = 0.0;
	
	CPrintToChat( client, CHAT_PREFIX..."Starting position reset." );
	return Plugin_Handled;
}

public Action cmdMapList( int client, int args )
{
	if ( !client ) return Plugin_Handled;

	MapListMenu(client);

	return Plugin_Handled;
}

public void MapListMenu(int client)
{
	Menu mMenu = new Menu(MapListCallback);

	mMenu.SetTitle("Select a Tier\n ");

	mMenu.AddItem("1", "(T1) Very Easy");
	mMenu.AddItem("2", "(T2) Easy");
	mMenu.AddItem("3", "(T3) Medium");
	mMenu.AddItem("4", "(T4) Hard");
	mMenu.AddItem("5", "(T5) Very Hard");
	mMenu.AddItem("6", "(T6) Insane\n ");

	mMenu.AddItem("0", "All Maps\n ");

	mMenu.Display(client, MENU_TIME_FOREVER);
}

public int MapListCallback( Menu mMenu, MenuAction action, int client, int item )
{
	if ( action == MenuAction_End ) { delete mMenu; return 0; }
	if ( action != MenuAction_Select ) return 0;

	int tier;
	char szItem[10];

	GetMenuItem( mMenu, item, szItem, sizeof( szItem ) );

	StringToIntEx(szItem, tier);

	g_tier_MapMenu[client] = tier;

	RunClass[client] = MODE_SOLDIER;

	MapListQuery(client, tier, RunClass[client]);

	return 0;
}

public void MapListQuery(int client, int tier, int mode)
{
	char szQuery[300];

	if (tier > 0)
	{
		g_hDatabase.Format(szQuery, sizeof(szQuery), "SELECT map_name, stier, dtier from map_info where run = 0 and %s = %i", (mode == MODE_SOLDIER) ? "stier" : "dtier", tier);
	}
	else
	{
		g_hDatabase.Format(szQuery, sizeof(szQuery), "SELECT map_name, stier, dtier from map_info where run = 0");
	}
	g_hDatabase.Query(Threaded_MapList, szQuery, client);
}

public void Threaded_MapList( Database hOwner, DBResultSet results, const char[] szError, int client )
{
	if ( results == null )
	{
		DB_LogError( "Couldn't load map list!" );
			
		return;
	}

	Menu mMenu = new Menu(MapListCallback_Final);
	char tierText[50];
	int maps_count=0;
	FormatEx(tierText, sizeof(tierText), "Difficulty: T%i\n ", g_tier_MapMenu[client]);

	if( results.RowCount )
	{
		int stier = -1, dtier = -1, count = 0;
		char map[130], buffer[140];
		while (results.FetchRow())
		{
			
			results.FetchString( 0, map, sizeof(map));
			
			if (FindMap(map, map, sizeof(map)) == FindMap_NotFound) continue;

			stier = results.FetchInt( 1 );
			dtier = results.FetchInt( 2 );
			count++;
			if (g_tier_MapMenu[client] > 0)
			{
				if (count != 6)
				{
					FormatEx(buffer, sizeof(buffer), "S%i|D%i %s", stier, dtier, map);
					mMenu.AddItem(map, buffer);
				}
				else
				{
					FormatEx(buffer, sizeof(buffer), "S%i|D%i %s\n ", stier, dtier, map);
					mMenu.AddItem(map, buffer);

					if (RunClass[client] == MODE_SOLDIER)
					{
						mMenu.AddItem("1", "[Soldier]");
					}
					else
					{
						mMenu.AddItem("1", "[Demoman]");
					}
					count = 0;
				}
				maps_count++;
			}
			else
			{
				FormatEx(buffer, sizeof(buffer), "S%i|D%i %s", stier, dtier, map);
				mMenu.AddItem(map, buffer);
				maps_count++;
			}
			dtier = -1;
			stier = -1;
		}
		if (g_tier_MapMenu[client] > 0)
		{
			if (0 < count < 6)
			{
				for (int i = 1; i <= (6 - count); i++)
				{
					mMenu.AddItem("","", ITEMDRAW_SPACER);
				}

				if (RunClass[client] == MODE_SOLDIER)
				{
					mMenu.AddItem("1", "[Soldier]");
				}
				else
				{
					mMenu.AddItem("1", "[Demoman]");
				}
			}
		}
	}
	mMenu.SetTitle("<Map list :: Total: %i %sMaps>\n%s", maps_count, (g_tier_MapMenu[client] > 0) ? (RunClass[client] == MODE_SOLDIER) ? "Soldier " : "Demoman " : "", (g_tier_MapMenu[client] > 0) ? tierText : " ");
	mMenu.ExitBackButton = true;
	mMenu.Display(client, MENU_TIME_FOREVER);
}

public int MapListCallback_Final( Menu mMenu, MenuAction action, int client, int item )
{
	if ( action == MenuAction_Cancel )
	{
		if (item == MenuCancel_ExitBack)
		{
			MapListMenu(client);
			return 0;
		} 
		return 0;
	}

	if ( action == MenuAction_End ) { delete mMenu; return 0; }
	if ( action != MenuAction_Select ) return 0;

		
	if (action == MenuAction_Select)
	{
		char szItem[10];

		if ( !GetMenuItem( mMenu, item, szItem, sizeof( szItem ) ) ) return 0;

		if (StrEqual(szItem, "1"))
		{
			if (RunClass[client] == MODE_SOLDIER)
			{
				MapListQuery(client, g_tier_MapMenu[client], MODE_DEMOMAN);
				RunClass[client] = MODE_DEMOMAN;
			}
			else
			{
				MapListQuery(client, g_tier_MapMenu[client], MODE_SOLDIER);
				RunClass[client] = MODE_SOLDIER;
			}
		}
	}

	return 0;
}

public Action Command_SVid(int client, int args)
{
	if (!client || IsFakeClient(client) || !IsClientInGame(client)) return Plugin_Handled;

	char map[128], displayName[128];

	if (args > 0)
	{
		GetCmdArg(0, map, sizeof(map));

		if (FindMap(map, displayName, sizeof(displayName)) != FindMap_Found)
		{
			FormatEx(displayName, sizeof(displayName), "%s", g_szCurrentMap);
		}
	}

	http = new HTTPClient(TempusURL);
	http.SetHeader("Accept", "application/json");

	char req[96];
	Format(req, sizeof(req), "api/v0/maps/name/%s/fullOverview", g_szCurrentMap);

	http.Get(req, OnVideoInfoReceivedSolly, client);
}

public Action Command_DVid(int client, int args)
{
	if (!client || IsFakeClient(client) || !IsClientInGame(client)) return Plugin_Handled;

	char map[128], displayName[128];

	if (args > 0)
	{
		GetCmdArg(0, map, sizeof(map));

		if (FindMap(map, displayName, sizeof(displayName)) != FindMap_Found)
		{
			FormatEx(displayName, sizeof(displayName), "%s", g_szCurrentMap);
		}
	}
	else
	{
		FormatEx(displayName, sizeof(displayName), "%s", g_szCurrentMap);
	}

	http = new HTTPClient(TempusURL);
	http.SetHeader("Accept", "application/json");

	char req[96];
	Format(req, sizeof(req), "api/v0/maps/name/%s/fullOverview", displayName);

	http.Get(req, OnVideoInfoReceivedDemo, client);
}

public void OnVideoInfoReceivedSolly(HTTPResponse response, any value) 
{
	int client = value;

	if (response.Status != HTTPStatus_OK) {
		// Failed to retrieve object
		if(response.Status == 404) {
			CPrintToChat(client, CHAT_PREFIX..."Map not on Tempus",response.Status);
			return;
		}
		CPrintToChat(client,"Error %d",response.Status);
		return;
	}
	if (response.Data == null) {
		// Invalid JSON response
		CPrintToChat(client,CHAT_PREFIX..."Invalid JSON response");
		return;
	}

	JSONObject mapObj = view_as<JSONObject>(response.Data);

	char d[8096];
	mapObj.ToString(d, sizeof(d));
	delete mapObj;


	//Store the map datastring
	JSONObject video = JSONObject.FromString(d);
	
	char vid_id[60], link[190];
	JSONObject map_info = view_as<JSONObject>(video.Get("videos"));
	map_info.GetString("soldier",vid_id,sizeof(vid_id));

	if (!StrEqual( vid_id, ""))
	{
		FormatEx(link, sizeof(link), "https://www.youtube.com/embed/%s", vid_id);

		ShowMOTDPanel(client, "Video", link, MOTDPANEL_TYPE_URL);
	}
	else
	{
		CPrintToChat(client, CHAT_PREFIX..."No video.");
	}
	delete video;
	delete map_info;
	return;
}

public void OnVideoInfoReceivedDemo(HTTPResponse response, any value) 
{
	int client = value;

	if (response.Status != HTTPStatus_OK) {
		// Failed to retrieve object
		if(response.Status == 404) {
			CPrintToChat(client, CHAT_PREFIX..."Map not on Tempus",response.Status);
			return;
		}
		CPrintToChat(client,"Error %d",response.Status);
		return;
	}
	if (response.Data == null) {
		// Invalid JSON response
		CPrintToChat(client,CHAT_PREFIX..."Invalid JSON response");
		return;
	}

	JSONObject mapObj = view_as<JSONObject>(response.Data);

	char d[8096];
	mapObj.ToString(d, sizeof(d));
	delete mapObj;


	//Store the map datastring
	JSONObject video = JSONObject.FromString(d);
	
	char vid_id[60], link[190];
	JSONObject map_info = view_as<JSONObject>(video.Get("videos"));
	map_info.GetString("demoman",vid_id,sizeof(vid_id));

	if (!StrEqual( vid_id, ""))
	{
		FormatEx(link, sizeof(link), "https://www.youtube.com/embed/%s", vid_id);

		ShowMOTDPanel(client, "Video", link, MOTDPANEL_TYPE_URL);
	}
	else
	{
		CPrintToChat(client, CHAT_PREFIX..."No video.");
	}
	delete video;
	delete map_info;
	return;
}

public Action Cmd_CallAdmin(int client, int argc) {

	if (argc > 0)
	{
		if(GetTime() < LastUsage[client] + 60) {
			CPrintToChat(client, CHAT_PREFIX..."Please wait before calling an admin again!");
			return Plugin_Continue;
		}

		if (!sCallAdmin_Channel[0])
		{
			CPrintToChat(client, CHAT_PREFIX..."There is no available channel for call admin");
			return Plugin_Continue;
		}

		//Format Message to send
		char message[400];

		char reason[256];

		GetCmdArgString(reason, sizeof(reason));
		
		char name[32];
		GetClientName(client, name, sizeof(name));
		//Replace ` with nothing as we will use `NAME` in discord message 
		ReplaceString(name, sizeof(name), "`", "");
		
		char authid[32];
		GetClientAuthId(client, AuthId_Steam2, authid, sizeof(authid));
		
		char ip[64];
		GetIP(ip, sizeof(ip));
		
		char hostname[64];
		GetConVarString(gHostname, hostname, sizeof(hostname));
		
		FormatEx(message, sizeof(message), "`%s` (`%s`) has called an Admin on %s\nMessage: %s\nConnect: steam://connect/%s", name, authid, hostname, reason, ip);
		
		//Send Message to discord
		dBot.SendMessageToChannelID(sCallAdmin_Channel, message);

		CPrintToChat(client, CHAT_PREFIX..."{lightskyblue}Called {white}an Admin");
		LastUsage[client] = GetTime();
	}
	else
	{
		CPrintToChat(client, CHAT_PREFIX..."Usage {lightskyblue}/calladmin <reason>");
	}
	return Plugin_Continue;
}

stock void GetIP(char[] buffer, int maxlength) {
	int ip[4];
	SteamWorks_GetPublicIP(ip);
	strcopy(buffer, maxlength, "");
			
	FormatEx(buffer, maxlength, "%d.%d.%d.%d:%d", ip[0], ip[1], ip[2], ip[3], gHostPort.IntValue);
}

public Action Command_Spectate( int client, int args )
{
	if ( !client ) return Plugin_Handled;
	
	if (  view_as<int>(GetClientTeam( client )) <=  view_as<int>(TFTeam_Spectator) )
	{
		SpawnPlayer( client );
		return Plugin_Handled;
	}
	
	
	ChangeClientTeam( client,  view_as<int>(TFTeam_Spectator) );
	
	if ( args )
	{
		char szTarget[MAX_NAME_LENGTH];
		GetCmdArgString( szTarget, sizeof( szTarget ) );
		
		StripQuotes( szTarget );
		
		int target = FindTarget( client, szTarget, false, false );
		if ( target > 0 && target <= MaxClients && IsPlayerAlive( target ) )
		{
			SetEntPropEnt( client, Prop_Send, "m_hObserverTarget", target );
			SetEntProp( client, Prop_Send, "m_iObserverMode", OBS_MODE_IN_EYE );
		}
		else
		{
			CPrintToChat( client, CHAT_PREFIX..."Couldn't find the player you were looking for." );
		}
	}
	
	return Plugin_Handled;
}


public Action RegenAmmo( int client, int args )
{
	if (IsPlayerAlive(client))
	{
		if (RegenOn[client])
			RegenOn[client] = false;
		else 
			RegenOn[client] = true;
		
		CPrintToChat(client, CHAT_PREFIX... "Regen {lightskyblue}%s", RegenOn[client] ? "ON" : "OFF");

		if (!g_bClientPractising[client])
			SetPlayerPractice( client, true );	
	}

	return Plugin_Handled;
}

public Action Command_RecordsMenuPoints( int client, int args )
{
	if ( !client ) return Plugin_Handled;
	
	if ( IsSpammingCommand( client ) ) return Plugin_Handled;

	DB_PrintPoints( client, args, 0 );
	
	return Plugin_Handled;
}

public Action Command_SetTier( int client, int args )
{
	if ( !client ) return Plugin_Handled;
	
	if ( IsSpammingCommand( client ) ) return Plugin_Handled;

	SetTier( client );
	
	return Plugin_Handled;
}

public Action Command_SetClass( int client, int args )
{
	if ( !client ) return Plugin_Handled;
	
	if ( IsSpammingCommand( client ) ) return Plugin_Handled;

	
	
	SetClass( client );
	
	return Plugin_Handled;
}

public Action Command_Profile( int client, int args )
{
	if ( !client ) return Plugin_Handled;
	
	
	if ( IsSpammingCommand( client ) ) return Plugin_Handled;
	
	RemoveAllPrevMenus(client);
	char szTarget[32];
	GetCmdArgString( szTarget, sizeof( szTarget ) );
	
	char Name[32];

	int mode = g_iClientMode[client];
	if ( args == 0 )
	{
		GetClientName(client, Name, sizeof( Name ) );
		DB_Profile( client, args, 0, Name, g_iClientId[client], mode );
		return Plugin_Handled;
	}
	else
	{
		int target = FindTarget( client, szTarget, true, false );
		if ( target != -1 )
		{
			DB_Profile( client, args, 0, Name, g_iClientId[target], mode );
			return Plugin_Handled;
		}
		else
		{
			DB_Profile( client, args, 1, szTarget, 0, mode );
			return Plugin_Handled;
		}
	}
}

public Action Command_RecordsPrint( int client, int args )
{
	if ( !client ) return Plugin_Handled;

	char szTarget[32];
	char displayName[100];
	GetCmdArg(1, szTarget, sizeof( szTarget ) );
	menu_page[client] = 0;

	if ( args > 0 && !GetMapDisplayName(szTarget, displayName, sizeof(displayName)) )
	{
		CPrintToChat(client, CHAT_PREFIX..."Map not found");
		return Plugin_Handled;
	}

	ShowMapTop(client, (args == 0) ? g_szCurrentMap : displayName, MAP_RUN);

	return Plugin_Handled;
}

public Action Command_CoursesRecordsPrint( int client, int args )
{
	if ( !client ) return Plugin_Handled;

	char szTarget[32];
	char displayName[100];
	GetCmdArg(1, szTarget, sizeof( szTarget ) );
	menu_page[client] = 0;

	if ( args > 0 && !GetMapDisplayName(szTarget, displayName, sizeof(displayName)) )
	{
		CPrintToChat(client, CHAT_PREFIX..."Map not found");
		return Plugin_Handled;
	}

	ShowMapTop(client, (args == 0) ? g_szCurrentMap : displayName, COURSE_RUN);

	return Plugin_Handled;
}

public Action Command_BonusesRecordsPrint( int client, int args )
{
	if ( !client ) return Plugin_Handled;

	char szTarget[32];
	char displayName[100];
	GetCmdArg(1, szTarget, sizeof( szTarget ) );
	menu_page[client] = 0;

	if ( args > 0 && !GetMapDisplayName(szTarget, displayName, sizeof(displayName)) )
	{
		CPrintToChat(client, CHAT_PREFIX..."Map not found");
		return Plugin_Handled;
	}

	ShowMapTop(client, (args == 0) ? g_szCurrentMap : displayName, BONUS_RUN);

	return Plugin_Handled;
}

public void ShowMapTop(int client, const char[] map, RunType run_type)
{
	char run_type_query[50], query[160];
	last_usage_run_type[client] = run_type;
	FormatEx(db_map[client], sizeof( db_map ), "%s", map);
	switch (run_type)
	{
		case MAP_RUN: {}
		case COURSE_RUN: FormatEx(run_type_query, sizeof(run_type_query), "AND run BETWEEN %i AND %i", RUN_COURSE1, RUN_COURSE10);
		case BONUS_RUN: FormatEx(run_type_query, sizeof(run_type_query), "AND run BETWEEN %i AND %i", RUN_BONUS1, RUN_BONUS10);
	}
	FormatEx(query, sizeof( query ), "SELECT run FROM map_info WHERE map_name = '%s' %s", map, run_type_query );
	g_hDatabase.Query( NormalTop, query, client );
}

public Action Command_PersonalRecords( int client, int args )
{
	if ( !client ) return Plugin_Handled;

	char query[700], cmd_map[50], cmd_player[60], displayName[60];

	int target;

	RunClass[client] = MODE_SOLDIER;

	if (!args)
	{
		g_hDatabase.Format(query, sizeof(query), "SELECT map_name, run, \
		(SELECT time from maprecs where map = map_info.map_name and run = map_info.run and mode = %i and uid = %i), \
		(SELECT `rank` from maprecs where map = map_info.map_name and run = map_info.run and mode = %i and uid = %i), \
		(SELECT `rank` from maprecs where map = map_info.map_name and run = map_info.run and mode = %i order by `rank` desc limit 1), \
		(SELECT pts from maprecs where map = map_info.map_name and run = map_info.run and mode = %i and uid = %i) \
		from map_info where map_name = '%s' ORDER BY run ASC", RunClass[client], g_iClientId[client], RunClass[client], g_iClientId[client], RunClass[client], RunClass[client], g_iClientId[client], g_szCurrentMap);
	}
	else
	{
		GetCmdArg(1, cmd_map, sizeof(cmd_map));
		if ( GetMapDisplayName(cmd_map, displayName, sizeof(displayName)) )
		{
			g_hDatabase.Format(query, sizeof(query), "SELECT map_name, run, \
			(SELECT time from maprecs where map = map_info.map_name and run = map_info.run and mode = %i and uid = %i), \
			(SELECT `rank` from maprecs where map = map_info.map_name and run = map_info.run and mode = %i and uid = %i), \
			(SELECT `rank` from maprecs where map = map_info.map_name and run = map_info.run and mode = %i order by `rank` desc limit 1), \
			(SELECT pts from maprecs where map = map_info.map_name and run = map_info.run and mode = %i and uid = %i) \
			from map_info where map_name = '%s' ORDER BY run ASC", RunClass[client], g_iClientId[client], RunClass[client], g_iClientId[client], RunClass[client], RunClass[client], g_iClientId[client], displayName);
		}
		else
		{
			CPrintToChat(client, CHAT_PREFIX..."Map not found");
			return Plugin_Handled;
		}
	}

	g_hDatabase.Query(PersonalRecordsCallBack, query, client);
	return Plugin_Handled;
}

public Action Command_MapPoints( int client, int args )
{
	if ( !client ) return Plugin_Handled;

	char cmd_map[50], displayName[60];

	RunClass[client] = MODE_SOLDIER;

	if (!args)
	{
		MapPoints(client, g_szCurrentMap, RunClass[client]);
	}
	else
	{
		GetCmdArg(1, cmd_map, sizeof(cmd_map));
		if ( GetMapDisplayName(cmd_map, displayName, sizeof(displayName)) )
		{
			MapPoints(client, displayName, RunClass[client]);
		}
		else
		{
			CPrintToChat(client, CHAT_PREFIX..."Map not found");
			return Plugin_Handled;
		}
	}
	return Plugin_Handled;
}

public void MapPoints(int client, char[] map, int class)
{
	char query[600];

	g_hDatabase.Format(query, sizeof(query), "SELECT run, %s, \
		(select wr_pts from points where tier = map_info.%s and run_type = if (map_info.run > 0, IF (map_info.run <= %i, 'course', 'bonus'), 'map' ) limit 1), \
		(select completion from points where tier = map_info.%s and run_type = if (map_info.run > 0, IF (map_info.run <= %i, 'course', 'bonus'), 'map' ) limit 1), \
		(select time from maprecs where uid = %i and run = map_info.run and mode = %i and map = '%s' limit 1), \
		map_name FROM `map_info` WHERE map_name = '%s'", (class == MODE_SOLDIER) ? "stier" : "dtier", (class == MODE_SOLDIER) ? "stier" : "dtier", RUN_COURSE5, (class == MODE_SOLDIER) ? "stier" : "dtier", RUN_COURSE5, g_iClientId[client], class, map, map);

	g_hDatabase.Query(MapPointsCallBack, query, client);
}

public void MapPointsCallBack( Database hOwner, DBResultSet results, const char[] szError, int client )
{
	if ( results == null )
	{
		DB_LogError( "Error points menu" );
		return;
	}
	char map[60], szItem[100], szRun[40];
	int tier = 0, run, count=0;
	float wrpts, cpts, time = TIME_INVALID;

	Menu mMenu = new Menu(Handler_MapPointsMenu);

	char tier_name[7][30] = {
		"Impossible",
		"Very Easy",
		"Easy",
		"Medium",
		"Hard",
		"Very Hard",
		"Insane"
	};

	if (results.RowCount)
	{
		while (results.FetchRow())
		{
			run = results.FetchInt( 0 );
			tier = results.FetchInt( 1 );
			wrpts = results.FetchFloat( 2 );
			cpts = results.FetchFloat( 3 );
			time = results.FetchFloat( 4 );
			results.FetchString( 5, map, sizeof(map));

			if (StrEqual(map, ""))
			{
				CPrintToChat(client, CHAT_PREFIX..."Map not found");
				delete mMenu;
				return;
			}

			strcopy(profile_map[client], sizeof(profile_map), map);
			count++;

			if (count != 6)
			{
				FormatEx(szItem, sizeof(szItem), "%s (%s)%s\nCpts: %.1f Wrpts: %.1f\n ", g_szRunName[NAME_LONG][run], tier_name[tier], (time > TIME_INVALID) ? " ✔" : "", cpts, wrpts);
				mMenu.AddItem("", szItem);
			}
			else
			{
				FormatEx(szItem, sizeof(szItem), "%s (%s)%s\nCpts: %.1f Wrpts: %.1f\n \n ", g_szRunName[NAME_LONG][run], tier_name[tier], (time > TIME_INVALID) ? " ✔" : "", cpts, wrpts);
				mMenu.AddItem("", szItem);

				if (RunClass[client] == MODE_SOLDIER)
				{
					mMenu.AddItem("1", "[Soldier]");
				}
				else
				{
					mMenu.AddItem("1", "[Demoman]");
				}
				count = 0;
			}
		}

		if (0 < count < 6)
		{
			for (int i = 1; i <= (6 - count); i++)
			{
				mMenu.AddItem("","", ITEMDRAW_SPACER);
			}

			if (RunClass[client] == MODE_SOLDIER)
			{
				mMenu.AddItem("1", "[Soldier]");
			}
			else
			{
				mMenu.AddItem("1", "[Demoman]");
			}
		}

		mMenu.SetTitle("<Map Points Information :: %s>\nCompletion points (Cpts) | WR points\n ", map);
		mMenu.Display(client, MENU_TIME_FOREVER);
	}
	delete results;
	return;
}

public int Handler_MapPointsMenu( Menu mMenu, MenuAction action, int client, int item )
{
	if ( action == MenuAction_Cancel )
	{
		return 0;
	}

	if ( action == MenuAction_End ) { delete mMenu; return 0; }
	if ( action != MenuAction_Select ) return 0;

		
	if (action == MenuAction_Select)
	{
		char szItem[3];

		if ( !GetMenuItem( mMenu, item, szItem, sizeof( szItem ) ) ) return 0;

		if (StrEqual(szItem, "1"))
		{
			if (RunClass[client] == MODE_SOLDIER)
			{
				RunClass[client] = MODE_DEMOMAN;
			}
			else
			{
				RunClass[client] = MODE_SOLDIER;
			}
			MapPoints(client, profile_map[client], RunClass[client]);
		}
	}

	return 0;	
}

public Action Command_IncompleteMaps( int client, int args )
{
	if ( !client ) return Plugin_Handled;

	char cmd_player[60];
	int target;

	if (args > 0)
	{
		GetCmdArg(1, cmd_player, sizeof(cmd_player));

		target = FindTarget( client, cmd_player, true, false );

		if (target != -1)
		{
			IncopleteMaps(client, g_iClientId[target], "");
		}
		else
		{
			IncopleteMaps(client, -1, cmd_player);
		}
	}
	else
	{
		IncopleteMaps(client, g_iClientId[client], "");
	}
	
	return Plugin_Handled;
}

public void IncopleteMaps(int client, int uid, char[] name)
{
	if (!client) return;

	RunClass[client] = MODE_SOLDIER;
	Incomplete_uid[client] = uid;

	if (uid == -1)
		strcopy( profile_playername[client], sizeof(profile_playername), name );

	Menu menu = new Menu(Handler_IncompleteSort);

	menu.SetTitle("Select Incomplete Item:\n ");

	menu.AddItem("map", "Maps\n ");

	menu.AddItem("course", "Courses\n ");

	menu.AddItem("bonus", "Bonuses\n ");

	menu.Display(client, MENU_TIME_FOREVER);
}

public int Handler_IncompleteSort( Menu mMenu, MenuAction action, int client, int item )
{
	if ( action == MenuAction_Cancel )
	{
		return 0;
	}

	if ( action == MenuAction_End ) { delete mMenu; return 0; }
	if ( action != MenuAction_Select ) return 0;

		
	if (action == MenuAction_Select)
	{
		char szItem[30];

		if ( !GetMenuItem( mMenu, item, szItem, sizeof( szItem ) ) ) return 0;

		ChooseSortMethod(client, true, szItem);
	}

	return 0;
}

public void ChooseSortMethod(int client, bool incomplete, char[] run)
{
	if (client <= 0) return;

	Menu menu = new Menu(Handler_IncompleteMenu);

	menu.SetTitle("Select Sorting Method:   \n ");

	menu.AddItem(run, "Sort in ascending order (T1s-T6s)\n ");

	menu.AddItem(run, "Sort in descending order (T6s-T1s)\n ");

	menu.AddItem(run, "Sort by map name\n ");

	menu.ExitBackButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

public int Handler_IncompleteMenu( Menu mMenu, MenuAction action, int client, int item )
{
	if ( action == MenuAction_Cancel )
	{
		if (item == MenuCancel_ExitBack)
		{
			IncopleteMaps(client, Incomplete_uid[client], profile_playername[client]);
		}
		return 0;
	}

	if ( action == MenuAction_End ) { delete mMenu; return 0; }
	if ( action != MenuAction_Select ) return 0;

		
	if (action == MenuAction_Select)
	{
		char query[700];
		char sort[60];
		char szItem[30];

		int mode = (g_iClientMode[client] == MODE_DEMOMAN) ? MODE_DEMOMAN:MODE_SOLDIER;
		RunClass[client] = mode;

		if ( !GetMenuItem( mMenu, item, szItem, sizeof( szItem ) ) ) return 0;

		FormatEx(SortRun[client], sizeof(SortRun), "%s", szItem);
		SortMethod[client] = item;

		if (item == 0)
		{
			FormatEx(sort, sizeof(sort), "ORDER BY %stier ASC", (mode == MODE_DEMOMAN) ? "d":"s");
		}
		else if (item == 1)
		{
			FormatEx(sort, sizeof(sort), "ORDER BY %stier DESC", (mode == MODE_DEMOMAN) ? "d":"s");
		}
		else if (item == 2)
		{
			FormatEx(sort, sizeof(sort), "ORDER BY map_name ASC");
		}

		if (StrEqual(szItem, "map"))
		{
			if (Incomplete_uid[client] > -1)
			{
				g_hDatabase.Format(query, sizeof(query), "SELECT map_name, run, stier, dtier, \
				(SELECT %i), \	
				(SELECT name from plydata where uid = %i) \
				from map_info where NOT EXISTS(SELECT time from maprecs where map = map_info.map_name and run = map_info.run and mode = %i and uid = %i) \
				and EXISTS(SELECT zone from mapbounds where map = map_info.map_name and zone = (map_info.run * 2) and number = 0) \
				and run = 0 and stier > 0 %s", Incomplete_uid[client], Incomplete_uid[client], mode, Incomplete_uid[client], sort);
			}
			else
			{
				g_hDatabase.Format(query, sizeof(query), "SELECT map_name, run, stier, dtier, \
				(SELECT uid from plydata where name LIKE '%s%%' limit 1), \
				(SELECT name from plydata where name LIKE '%s%%' limit 1) \
				from map_info where NOT EXISTS(SELECT time from maprecs where map = map_info.map_name and run = map_info.run and mode = %i and uid = (select uid from plydata where name LIKE '%s%%' limit 1)) \
				and EXISTS(SELECT zone from mapbounds where map = map_info.map_name and zone = (map_info.run * 2) and number = 0) \
				and run = 1 and stier > 0 %s", profile_playername[client], profile_playername[client], mode, profile_playername[client], sort);
			}
			g_hDatabase.Query(IncompleteRecordsCallBack, query, client);
		}
		else if (StrEqual(szItem, "course"))
		{
			if (Incomplete_uid[client] > -1)
			{
				g_hDatabase.Format(query, sizeof(query), "SELECT map_name, run, stier, dtier, \
				(SELECT %i), \	
				(SELECT name from plydata where uid = %i) \
				from map_info where NOT EXISTS(SELECT time from maprecs where map = map_info.map_name and run = map_info.run and mode = %i and uid = %i) \
				and EXISTS(SELECT zone from mapbounds where map = map_info.map_name and zone = (map_info.run * 2) and number = 0) \
				and run BETWEEN %i and %i and stier > 0 %s", Incomplete_uid[client], Incomplete_uid[client], mode, Incomplete_uid[client], RUN_COURSE1, RUN_COURSE10, sort);
			}
			else
			{
				g_hDatabase.Format(query, sizeof(query), "SELECT map_name, run, stier, dtier, \
				(SELECT uid from plydata where name LIKE '%s%%' limit 1), \
				(SELECT name from plydata where name LIKE '%s%%' limit 1) \
				from map_info where NOT EXISTS(SELECT time from maprecs where map = map_info.map_name and run = map_info.run and mode = %i and uid = (select uid from plydata where name LIKE '%s%%' limit 1)) \
				and EXISTS(SELECT zone from mapbounds where map = map_info.map_name and zone = (map_info.run * 2) and number = 0) \
				and run BETWEEN %i and %i and stier > 0 %s", profile_playername[client], profile_playername[client], mode, profile_playername[client], RUN_COURSE1, RUN_COURSE10, sort);
			}
			g_hDatabase.Query(IncompleteRecordsCallBack, query, client);
		}
		else if (StrEqual(szItem, "bonus"))
		{

			if (Incomplete_uid[client] > -1)
			{
				g_hDatabase.Format(query, sizeof(query), "SELECT map_name, run, stier, dtier, \
				(SELECT %i), \	
				(SELECT name from plydata where uid = %i) \
				from map_info where NOT EXISTS(SELECT time from maprecs where map = map_info.map_name and run = map_info.run and mode = %i and uid = %i) \
				and EXISTS(SELECT zone from mapbounds where map = map_info.map_name and zone = (map_info.run * 2) and number = 0) \
				and run BETWEEN %i and %i and stier > 0 %s", Incomplete_uid[client], Incomplete_uid[client], mode, Incomplete_uid[client], RUN_BONUS1, RUN_BONUS10, sort);
			}
			else
			{
				g_hDatabase.Format(query, sizeof(query), "SELECT map_name, run, stier, dtier, \
				(SELECT uid from plydata where name LIKE '%s%%' limit 1), \
				(SELECT name from plydata where name LIKE '%s%%' limit 1) \
				from map_info where NOT EXISTS(SELECT time from maprecs where map = map_info.map_name and run = map_info.run and mode = %i and uid = (select uid from plydata where name LIKE '%s%%' limit 1)) \
				and EXISTS(SELECT zone from mapbounds where map = map_info.map_name and zone = (map_info.run * 2) and number = 0) \
				and run BETWEEN %i and %i and stier > 0 %s", profile_playername[client], profile_playername[client], mode, profile_playername[client], RUN_BONUS1, RUN_BONUS10, sort);
			}
			g_hDatabase.Query(IncompleteRecordsCallBack, query, client);
		}
	}

	return 0;
}

public void IncompleteRecordsCallBack( Database hOwner, DBResultSet results, const char[] szError, int client )
{
	if ( results == null )
	{
		DB_LogError( "Error incomplete menu" );
		return;
	}
	char map[60], player_name[100], szItem[100], szRun[40];
	int run, stier = 0, dtier = 0, count = 0, total = 0;

	Menu mMenu = new Menu(Handler_incompleteMenuDatabase);
	if (results.RowCount)
	{
		while (results.FetchRow())
		{
			results.FetchString(0, map, sizeof(map));

			if (FindMap(map, map, sizeof(map)) == FindMap_NotFound) continue;

			run = results.FetchInt( 1 );
			stier = results.FetchInt( 2 );
			dtier = results.FetchInt( 3 );
			Incomplete_uid[client] = results.FetchInt( 4 );
			results.FetchString(5, player_name, sizeof(player_name));

			if (StrEqual(player_name, ""))
			{
				CPrintToChat(client, CHAT_PREFIX..."No player found");
				return;
			}

			if (RUN_COURSE1 <= run <= RUN_COURSE10)
				strcopy(szRun, sizeof(szRun), "Courses");
			else if (RUN_BONUS1 <= run <= RUN_BONUS10)	
				strcopy(szRun, sizeof(szRun), "Bonuses");
			else
				strcopy(szRun, sizeof(szRun), "Maps");	
			
			count++;

			total++;

			if (count != 6)
			{
				FormatEx(szItem, sizeof(szItem), "S%i|D%i %s [%s]", stier, dtier, map, g_szRunName[NAME_SHORT][run]);
				mMenu.AddItem("", szItem, ITEMDRAW_DISABLED);
			}
			else
			{
				FormatEx(szItem, sizeof(szItem), "S%i|D%i %s [%s]\n ", stier, dtier, map, g_szRunName[NAME_SHORT][run]);
				mMenu.AddItem("", szItem, ITEMDRAW_DISABLED);

				if (RunClass[client] == MODE_SOLDIER)
				{
					mMenu.AddItem(szRun, "[Soldier]");
				}
				else
				{
					mMenu.AddItem(szRun, "[Demoman]");
				}
				count = 0;
			}
		}
	}
	else
	{
		mMenu.AddItem("", "Congratulations! You have completed all maps!", ITEMDRAW_DISABLED);
		count = 1;
	}

	if (0 < count < 6)
	{
		for (int i = 1; i <= (6 - (results.RowCount) ? count : 0); i++)
		{
			mMenu.AddItem("","", ITEMDRAW_SPACER);
		}

		if (RunClass[client] == MODE_SOLDIER)
		{
			mMenu.AddItem(szRun, "[Soldier]");
		}
		else
		{
			mMenu.AddItem(szRun, "[Demoman]");
		}
	}

	mMenu.SetTitle("<Incompleted %s> :: %s\nPlayer: %s :: (%i total)\n ", szRun, (RunClass[client] == MODE_SOLDIER) ? "Soldier" : "Demoman", player_name, total );
	mMenu.ExitBackButton = true;
	mMenu.Display(client, MENU_TIME_FOREVER);
}

public int Handler_incompleteMenuDatabase( Menu mMenu, MenuAction action, int client, int item )
{
	if ( action == MenuAction_Cancel )
	{
		if (item == MenuCancel_ExitBack)
		{
			ChooseSortMethod(client, true, SortRun[client]);
		}
		return 0;
	}

	if ( action == MenuAction_End ) { delete mMenu; return 0; }
	if ( action != MenuAction_Select ) return 0;

		
	if (action == MenuAction_Select)
	{
		char query[700];
		char sort[60];
		char szItem[20];

		if ( !GetMenuItem( mMenu, item, szItem, sizeof( szItem ) ) ) return 0;

		if (SortMethod[client] == 0)
		{
			FormatEx(sort, sizeof(sort), "ORDER BY %s ASC", (RunClass[client] == MODE_SOLDIER) ? "dtier" : "stier");
		}
		else if (SortMethod[client] == 1)
		{
			FormatEx(sort, sizeof(sort), "ORDER BY %s DESC", (RunClass[client] == MODE_SOLDIER) ? "dtier" : "stier");
		}
		else if (SortMethod[client] == 2)
		{
			FormatEx(sort, sizeof(sort), "ORDER BY map_name ASC");
		}

		if (StrEqual(szItem, "Maps"))
		{
			
			if (RunClass[client] == MODE_SOLDIER)
			{
				RunClass[client] = MODE_DEMOMAN;
			}
			else
			{
				RunClass[client] = MODE_SOLDIER;
			}

			g_hDatabase.Format(query, sizeof(query), "SELECT map_name, run, stier, dtier, \
				(SELECT %i), \	
				(SELECT name from plydata where uid = %i) \
				from map_info where NOT EXISTS(SELECT time from maprecs where map = map_info.map_name and run = map_info.run and mode = %i and uid = %i) \
				and EXISTS(SELECT zone from mapbounds where map = map_info.map_name and zone = (map_info.run * 2) and number = 0) \
				and run = 0 and %s > 0 %s", Incomplete_uid[client], Incomplete_uid[client], RunClass[client], Incomplete_uid[client], (RunClass[client] == MODE_SOLDIER) ? "stier" : "dtier", sort);

			g_hDatabase.Query(IncompleteRecordsCallBack, query, client);
		}
		else if (StrEqual(szItem, "Courses"))
		{
			
			if (RunClass[client] == MODE_SOLDIER)
			{
				RunClass[client] = MODE_DEMOMAN;
			}
			else
			{
				RunClass[client] = MODE_SOLDIER;
			}

			g_hDatabase.Format(query, sizeof(query), "SELECT map_name, run, stier, dtier, \
				(SELECT %i), \	
				(SELECT name from plydata where uid = %i) \
				from map_info where NOT EXISTS(SELECT time from maprecs where map = map_info.map_name and run = map_info.run and mode = %i and uid = %i) \
				and EXISTS(SELECT zone from mapbounds where map = map_info.map_name and zone = (map_info.run * 2) and number = 0) \
				and run BETWEEN %i and %i and %s > 0 %s", Incomplete_uid[client], Incomplete_uid[client], RunClass[client], Incomplete_uid[client], RUN_COURSE1, RUN_COURSE10, (RunClass[client] == MODE_SOLDIER) ? "stier" : "dtier", sort);

			g_hDatabase.Query(IncompleteRecordsCallBack, query, client);
		}
		else if (StrEqual(szItem, "Bonuses"))
		{
			
			if (RunClass[client] == MODE_SOLDIER)
			{
				RunClass[client] = MODE_DEMOMAN;
			}
			else
			{
				RunClass[client] = MODE_SOLDIER;
			}

			g_hDatabase.Format(query, sizeof(query), "SELECT map_name, run, stier, dtier, \
				(SELECT %i), \	
				(SELECT name from plydata where uid = %i) \
				from map_info where NOT EXISTS(SELECT time from maprecs where map = map_info.map_name and run = map_info.run and mode = %i and uid = %i) \
				and EXISTS(SELECT zone from mapbounds where map = map_info.map_name and zone = (map_info.run * 2) and number = 0) \
				and run BETWEEN %i and %i and %s > 0 %s", Incomplete_uid[client], Incomplete_uid[client], RunClass[client], Incomplete_uid[client], RUN_BONUS1, RUN_BONUS10, (RunClass[client] == MODE_SOLDIER) ? "stier" : "dtier", sort);

			g_hDatabase.Query(IncompleteRecordsCallBack, query, client);
		}
	}
	return 0;
}

public void PersonalRecordsCallBack( Database hOwner, DBResultSet results, const char[] szError, int client )
{
	if ( results == null )
	{
		DB_LogError( "Error PR menu" );
		return;
	}
	char map[60], szTime[TIME_SIZE_DEF], szItem[100], query[400];
	int run, rank, outof, count = 0;

	float flRec, pts;

	if (results.RowCount)
	{
		Menu mMenu = new Menu(Handler_PrMenu);
		while (results.FetchRow())
		{
			results.FetchString(0, map, sizeof(map));
			if (FindMap(map, map, sizeof(map)) == FindMap_NotFound) continue;
			run = results.FetchInt( 1 );
			flRec = results.FetchFloat( 2 );
			rank = results.FetchInt( 3 );
			outof = results.FetchInt( 4 );
			pts = results.FetchFloat( 5 );
			count++;	


			mMenu.SetTitle("<Personal Records :: %s>\nPlayer: %N\nMap: %s\n ", (RunClass[client] == MODE_SOLDIER) ? "Soldier" : "Demoman", client, map);
			
			if (flRec > 0.0)
			{
				FormatSeconds(flRec, szTime, FORMAT_2DECI);
				FormatEx(szItem, sizeof(szItem), "%s - %s\nRank: %i/%i <%.1f pts>\n ", g_szRunName[NAME_LONG][run], szTime, rank, outof, pts );
			}
			else
			{
				FormatEx(szItem, sizeof(szItem), "%s - None\n ", g_szRunName[NAME_LONG][run]);
			}

			if (count != 6)
			{
				mMenu.AddItem("", szItem);
			}
			else
			{
				mMenu.AddItem("", szItem);

				if (RunClass[client] == MODE_SOLDIER)
				{
					mMenu.AddItem("1", "[Soldier]");
				}
				else
				{
					mMenu.AddItem("1", "[Demoman]");
				}
				count = 0;
			}
		}

		strcopy(profile_map[client], sizeof(profile_map), map);

		if (0 < count < 6)
		{
			for (int i = 1; i <= (6 - count); i++)
			{
				mMenu.AddItem("","", ITEMDRAW_SPACER);
			}

			if (RunClass[client] == MODE_SOLDIER)
			{
				mMenu.AddItem("1", "[Soldier]");
			}
			else
			{
				mMenu.AddItem("1", "[Demoman]");
			}
		}

		mMenu.Display(client, MENU_TIME_FOREVER);
	}
	delete results;
	return;
}

public int Handler_PrMenu( Menu mMenu, MenuAction action, int client, int item )
{
	if ( action == MenuAction_Cancel )
	{ 
		return 0;
	}

	if ( action == MenuAction_End ) { delete mMenu; return 0; }
	if ( action != MenuAction_Select ) return 0;

		
	if (action == MenuAction_Select)
	{
		char query[700];

		char szItem[10];

		if ( !GetMenuItem( mMenu, item, szItem, sizeof( szItem ) ) ) return 0;

		if (StrEqual(szItem, "1"))
		{
			
			if (RunClass[client] == MODE_SOLDIER)
			{
				RunClass[client] = MODE_DEMOMAN;
			}
			else
			{
				RunClass[client] = MODE_SOLDIER;
			}

			g_hDatabase.Format(query, sizeof(query), "SELECT map_name, run, \
			(SELECT time from maprecs where map = map_info.map_name and run = map_info.run and mode = %i and uid = %i), \
			(SELECT `rank` from maprecs where map = map_info.map_name and run = map_info.run and mode = %i and uid = %i), \
			(SELECT `rank` from maprecs where map = map_info.map_name and run = map_info.run and mode = %i order by `rank` desc limit 1), \
			(SELECT pts from maprecs where map = map_info.map_name and run = map_info.run and mode = %i and uid = %i) \
			from map_info where map_name = '%s' ORDER BY run ASC", RunClass[client], g_iClientId[client], RunClass[client], g_iClientId[client], RunClass[client], RunClass[client], g_iClientId[client], profile_map[client]);

			g_hDatabase.Query(PersonalRecordsCallBack, query, client);
		}
	}

	return 0;
}

public void NormalTop( Database hOwner, DBResultSet hQuery, const char[] szError, int client )
{
	if ( hQuery == null )
		{
			DB_LogError( "Error top menu" );
			return;
		}
		Menu mMenu = new Menu( Handler_NormalMenu );
		mMenu.SetTitle( "<Top Times Menu>\nMap: %s\n ", db_map[client] );
		if ( hQuery.RowCount )
		{
			int index;
			char run_name[50];
			char run[32];
			bool courses = false;
			while ( hQuery.FetchRow())
			{
				index = hQuery.FetchInt( 0 );
				if (index == 0)
				{
					mMenu.AddItem( "0", "Map Run\n " );
					continue;
				}

				if (index < RUN_BONUS1)
				{
					courses = true;
				}
				
				FormatEx(run_name, sizeof(run_name), "%s", g_szRunName[NAME_LONG][index]);
				
				IntToString( index, run, sizeof( run ) );

				if (index == RUN_BONUS1 && courses)
					mMenu.AddItem( "", "", ITEMDRAW_SPACER );

				mMenu.AddItem( run, run_name );	
			}
		}
		else
		{
			mMenu.AddItem( "0", "Map Run\n " );
		}
		mMenu.Display( client, MENU_TIME_FOREVER );

}

public Action Command_PrintMapTier( int client, int args )
{
	char query[500], cmd_map[40], displayMap[50];

	if (!args)
	{
		g_hDatabase.Format(query, sizeof(query), "SELECT map_name, stier, dtier, run from map_info where map_name = '%s'", g_szCurrentMap);
	}
	else 
	{
		GetCmdArg(1, cmd_map, sizeof(cmd_map));

		if ( GetMapDisplayName(cmd_map, displayMap, sizeof(displayMap)) )
		{
			g_hDatabase.Format(query, sizeof(query), "SELECT map_name, stier, dtier, run from map_info where map_name = '%s' order by run ASC", displayMap);
		}
		else
		{
			g_hDatabase.Format(query, sizeof(query), "SELECT map_name, stier, dtier, run from map_info where map_name = '%s'", g_szCurrentMap);
		}
	}
	g_hDatabase.Query(GetTiers_CallBack, query);
	return Plugin_Handled;
}

public Action Command_Hide_Chat( int client, int args )
{
	if ( !client ) return Plugin_Handled;

	CPrintToChat(client, CHAT_PREFIX..."Chat {lightskyblue}%s", (g_fClientHideFlags[client] & HIDEHUD_CHAT) ? "ON" : "OFF");

	if (g_fClientHideFlags[client] & HIDEHUD_CHAT)
	{
		g_fClientHideFlags[client] &= ~HIDEHUD_CHAT;
	}
	else
	{
		g_fClientHideFlags[client] |= HIDEHUD_CHAT;
	}
	return Plugin_Handled;
}

public Action Command_Level( int client, int args )
{
	if ( !client ) return Plugin_Handled;
	if (!IsPlayerAlive(client)) return Plugin_Handled;

	if (args > 0)
	{
		char szLevel_id[10];
		int level_id;
		GetCmdArg(1, szLevel_id, sizeof(szLevel_id));
		int len = strlen(szLevel_id);
		for (int i=0; i < len; i++)
		{
			if (!IsCharNumeric(szLevel_id[i]))
			{
				CPrintToChat(client, CHAT_PREFIX... "You must enter the level number");
				return;
			}
		}

		StringToIntEx(szLevel_id, level_id);

		if (!(0 < level_id < 201))
		{
			CPrintToChat(client, CHAT_PREFIX... "The level number is not entered correctly");
		  	return;
		}
		if (g_fClientLevelPos[level_id-1][0] != 0.0 || g_fClientLevelPos[level_id-1][1] != 0.0 || g_fClientLevelPos[level_id-1][2] != 0.0)
		{
			SetPlayerPractice(client, true);
			TeleportEntity(client, g_fClientLevelPos[level_id-1], g_fClientLevelAng[level_id-1], g_vecNull);
			return;
		}

		int levels_count = 0;
		
		for (int i = 0; i < 200; i++)
		{
			if (g_fClientLevelPos[i][0] != 0.0 || g_fClientLevelPos[i][1] != 0.0 || g_fClientLevelPos[i][2] != 0.0)
			{
				levels_count++;
			}
		}

		if (levels_count > 0)
		{
			CPrintToChat(client, CHAT_PREFIX... "Only {lightskyblue}%i {white}levels are available", levels_count);
		}
		else
		{
			CPrintToChat(client, CHAT_PREFIX... "No levels available");
		}
		return;
	}

	menu_page[client] = 0;

	LevelMenu(client);



	return;
}

public void LevelMenu(int client)
{
	Menu mMenu = new Menu(Handler_Levels);

	mMenu.SetTitle("Level menu\n ");
	static char item[10], szItem[30];
	bool find = false;
	for (int i=0; i < 200; i++)
	{
		if (g_fClientLevelPos[i][0] != 0.0 || g_fClientLevelPos[i][1] != 0.0 || g_fClientLevelPos[i][2] != 0.0)
		{
			IntToString(i, item, sizeof(item));
			FormatEx(szItem, sizeof(szItem), "Level %i", i+1);
			mMenu.AddItem(item, szItem);
			find = true;
		}
	}

	if (!find)
	{
		mMenu.AddItem("", "No levels available D:", ITEMDRAW_DISABLED);
	}	

		mMenu.DisplayAt(client, menu_page[client], MENU_TIME_FOREVER);
}

public int Handler_Levels( Menu mMenu, MenuAction action, int client, int item )
{
	if ( action == MenuAction_End ) { delete mMenu; return 0; }
	if ( action != MenuAction_Select ) return 0;
	int level_id;
	char szItem[10];
	if ( !GetMenuItem( mMenu, item, szItem, sizeof( szItem ) ) ) return 0;

	menu_page[client] = GetMenuSelectionPosition();

	StringToIntEx(szItem, level_id);
	SetPlayerPractice(client, true);
	TeleportEntity(client, g_fClientLevelPos[level_id], g_fClientLevelAng[level_id], g_vecNull);
	LevelMenu(client);
	return;
}

public int Handler_NormalMenu( Menu mMenu, MenuAction action, int client, int item )
{
	if ( action == MenuAction_End ) { delete mMenu; return 0; }
	if ( action != MenuAction_Select ) { return 0; }
	int args;
	char szItem[5];
	if ( !GetMenuItem( mMenu, item, szItem, sizeof( szItem ) ) ) return 0;
	StringToIntEx(szItem, args);
	menu_page[client] = 0;
	DB_PrintRecords0( client, args );
}		

public Action DWr( int client, int args)
{
	static char szQuery[192], map[60], displayName[60];

	if (args > 0)
	{
		GetCmdArg(1, map, sizeof(map));
		if (GetMapDisplayName(map, displayName, sizeof(displayName)))
		{
			g_hDatabase.Format(szQuery, sizeof(szQuery), "SELECT (SELECT name FROM plydata where plydata.uid = maprecs.uid), time, map from maprecs where map = '%s' and run = 0 and mode = 3 order by time ASC", displayName);
		}
		else 
		{
			CPrintToChat(client, CHAT_PREFIX... "\x07C8C8C8Wrong map name");
			return Plugin_Handled;
		}
	}
	else
	{
		g_hDatabase.Format(szQuery, sizeof(szQuery), "SELECT (SELECT name FROM plydata where plydata.uid = maprecs.uid), time, map from maprecs where map = '%s' and run = 0 and mode = 3 order by time ASC", g_szCurrentMap);
	}
	g_hDatabase.Query( Threaded_DWr, szQuery, client, DBPrio_Normal );
}

public void Threaded_DWr( Database hOwner, DBResultSet hQuery, const char[] szError, int client )
{

	if ( hQuery == null )
	{
		CPrintToChat(client, CHAT_PREFIX..."\x07C8C8C8No match found");
	
		return;
	}
	if (hQuery.RowCount)
	{
		hQuery.FetchRow();
		char name[32], szTime[TIME_SIZE_DEF], map[40];
		float time;
		hQuery.FetchString( 0, name, sizeof(name));
		time = hQuery.FetchFloat( 1 );
		hQuery.FetchString( 2, map, sizeof(map));

		FormatSeconds(time, szTime, FORMAT_2DECI);
		
		CPrintToChatAll(CHAT_PREFIX..."(Demo WR) {lightskyblue}%s{white} :: {green}%s {white}:: {green}%s", map, szTime, name);
	}
	else
	{
		CPrintToChatAll(CHAT_PREFIX..."\x07C8C8C8No match found");
	}
}

public Action SWr( int client, int args)
{
	static char szQuery[192], map[60], displayName[60];

	if (args > 0)
	{
		GetCmdArg(1, map, sizeof(map));
		if (GetMapDisplayName(map, displayName, sizeof(displayName)))
		{
			g_hDatabase.Format(szQuery, sizeof(szQuery), "SELECT name, time, map from maprecs natural join plydata where map = '%s' and run = 0 and mode = 1 order by time ASC", displayName);
		}
		else 
		{
			CPrintToChat(client, CHAT_PREFIX... "\x07C8C8C8Wrong map name");
			return Plugin_Handled;
		}
	}
	else
	{
		g_hDatabase.Format(szQuery, sizeof(szQuery), "SELECT name, time, map from maprecs natural join plydata where map = '%s' and run = 0 and mode = 1 order by time ASC", g_szCurrentMap);
	}
	g_hDatabase.Query( Threaded_SWr, szQuery, client, DBPrio_Normal );
}

public void Threaded_SWr( Database hOwner, DBResultSet hQuery, const char[] szError, int client )
{

	if ( hQuery == null )
	{
		CPrintToChat(client, CHAT_PREFIX..."\x07C8C8C8No match found");
	
		return;
	}
	if (hQuery.RowCount)
	{
		hQuery.FetchRow();
		char name[32], szTime[TIME_SIZE_DEF], map[40];
		float time;
		hQuery.FetchString( 0, name, sizeof(name));
		time = hQuery.FetchFloat( 1 );
		hQuery.FetchString( 2, map, sizeof(map));

		FormatSeconds(time, szTime, FORMAT_2DECI);

		CPrintToChatAll(CHAT_PREFIX..."(Solly WR) {lightskyblue}%s{white} :: {green}%s {white}:: {green}%s", map, szTime, name);
	}
	else
	{
		CPrintToChatAll(CHAT_PREFIX..."\x07C8C8C8No match found");
	}
}

public Action ORank( int client, int args)
{
	static char szQuery[192], arg_name[32], name[32];
	float points;
	int arg_rank, rank, outof;
	bool is_rank = false;
	if (args > 0)
	{
		GetCmdArg(1, arg_name, sizeof(arg_name));
		for (int i=0; i<strlen(arg_name); i++)
		{
			if (IsCharNumeric(arg_name[i]))
			{
				is_rank = true;
			}
			else
			{
				is_rank = false;
				break;
			}
		}
		if (is_rank) {
			StringToIntEx(arg_name, arg_rank);
			g_hDatabase.Format(szQuery, sizeof(szQuery), "SELECT name, orank, (SELECT max(orank) from plydata), (SELECT SUM(pts) from maprecs where uid = plydata.uid) FROM "...TABLE_PLYDATA..." WHERE orank = %i and orank > 0", arg_rank);
		}
		else {
			g_hDatabase.Format(szQuery, sizeof(szQuery), "SELECT name, orank, (SELECT max(orank) from plydata), (SELECT SUM(pts) from maprecs where uid = plydata.uid) FROM "...TABLE_PLYDATA..." WHERE name LIKE '%s%%' and orank > 0 order by orank asc", arg_name);
		}
	}
	else
	{
		g_hDatabase.Format(szQuery, sizeof(szQuery), "SELECT name, orank, (SELECT max(orank) from plydata), (SELECT SUM(pts) from maprecs where uid = plydata.uid) FROM "...TABLE_PLYDATA..." WHERE uid = %i and orank > 0", g_iClientId[client]);
	}
	g_hDatabase.Query( Threaded_ORank, szQuery, client, DBPrio_Normal );
}

public void Threaded_ORank( Database hOwner, DBResultSet hQuery, const char[] szError, int client )
{

	if ( hQuery == null )
	{
		CPrintToChatAll(CHAT_PREFIX..."\x07C8C8C8No match found");
	
		return;
	}
	if (hQuery.RowCount)
	{
		hQuery.FetchRow();
		char name[32];
		int rank, allranks;
		float points;
		hQuery.FetchString( 0, name, sizeof(name));
		rank = hQuery.FetchInt( 1 );
		allranks = hQuery.FetchInt( 2 );
		points = hQuery.FetchFloat( 3 );
		CPrintToChatAll(CHAT_PREFIX..."(Overall) {green}%s {white}is ranked {lightskyblue}%i/%i {white}with {lightskyblue}%.0f {white}points", name, rank, allranks, points);
	}
	else
	{
		CPrintToChatAll(CHAT_PREFIX..."\x07C8C8C8No match found");
	}
}

public Action DRank( int client, int args)
{
	static char szQuery[192], arg_name[32], name[32];
	float points;
	int arg_rank, rank, outof;
	bool is_rank = false;
	if (args > 0)
	{
		GetCmdArg(1, arg_name, sizeof(arg_name));

		if (IsCharNumeric(arg_name[0]))
				is_rank = true;
				
		if (is_rank) {
			StringToIntEx(arg_name, arg_rank);
			g_hDatabase.Format(szQuery, sizeof(szQuery), "SELECT name, drank, (SELECT max(drank) from plydata), (SELECT SUM(pts) from maprecs where uid = plydata.uid and mode = 3) FROM "...TABLE_PLYDATA..." WHERE drank = %i and drank > 0", arg_rank);
		}
		else {
			g_hDatabase.Format(szQuery, sizeof(szQuery), "SELECT name, drank, (SELECT max(drank) from plydata), (SELECT SUM(pts) from maprecs where uid = plydata.uid and mode = 3) FROM "...TABLE_PLYDATA..." WHERE name LIKE '%s%%' and drank > 0 order by drank asc", arg_name);
		}
	}
	else
	{
		g_hDatabase.Format(szQuery, sizeof(szQuery), "SELECT name, drank, (SELECT max(drank) from plydata), (SELECT SUM(pts) from maprecs where uid = plydata.uid and mode = 3) FROM "...TABLE_PLYDATA..." WHERE uid = %i and drank > 0", g_iClientId[client]);
	}
	g_hDatabase.Query( Threaded_DRank, szQuery, client, DBPrio_Normal );
}

public void Threaded_DRank( Database hOwner, DBResultSet hQuery, const char[] szError, int client )
{

	if ( hQuery == null )
	{
		CPrintToChatAll(CHAT_PREFIX..."\x07C8C8C8No match found");
	
		return;
	}
	if (hQuery.RowCount)
	{
		hQuery.FetchRow();
		char name[32];
		int rank, allranks;
		float points;
		hQuery.FetchString( 0, name, sizeof(name));
		rank = hQuery.FetchInt( 1 );
		allranks = hQuery.FetchInt( 2 );
		points = hQuery.FetchFloat( 3 );
		CPrintToChatAll(CHAT_PREFIX..."(Demoman) {green}%s {white}is ranked {lightskyblue}%i/%i {white}with {lightskyblue}%.0f {white}points", name, rank, allranks, points);
	}
	else
	{
		CPrintToChatAll(CHAT_PREFIX..."\x07C8C8C8No match found");
	}
}

public Action SRank( int client, int args)
{
	static char szQuery[192], arg_name[32];
	int arg_rank;
	bool is_rank = false;
	if (args > 0)
	{
		GetCmdArg(1, arg_name, sizeof(arg_name));
		for (int i=0; i<strlen(arg_name); i++)
		{
			if (IsCharNumeric(arg_name[i]))
			{
				is_rank = true;
			}
			else
			{
				is_rank = false;
				break;
			}
		}
		if (is_rank) {
			StringToIntEx(arg_name, arg_rank);
			g_hDatabase.Format(szQuery, sizeof(szQuery), "SELECT name, srank, (SELECT max(srank) from plydata), (SELECT SUM(pts) from maprecs where uid = plydata.uid and mode = 1) FROM "...TABLE_PLYDATA..." WHERE srank = %i and srank > 0", arg_rank);
		}
		else {
			g_hDatabase.Format(szQuery, sizeof(szQuery), "SELECT name, srank, (SELECT max(srank) from plydata), (SELECT SUM(pts) from maprecs where uid = plydata.uid and mode = 1) FROM "...TABLE_PLYDATA..." WHERE name LIKE '%s%%' and srank > 0 order by srank asc", arg_name);
		}
	}
	else
	{
		g_hDatabase.Format(szQuery, sizeof(szQuery), "SELECT name, srank, (SELECT max(srank) from plydata), (SELECT SUM(pts) from maprecs where uid = plydata.uid and mode = 1) FROM "...TABLE_PLYDATA..." WHERE uid = %i and srank > 0", g_iClientId[client]);
	}
	g_hDatabase.Query( Threaded_SRank, szQuery, client, DBPrio_Normal );
	return Plugin_Handled;
}

public void Threaded_SRank( Database hOwner, DBResultSet hQuery, const char[] szError, int client )
{

	if ( hQuery == null )
	{
		CPrintToChatAll(CHAT_PREFIX..."\x07C8C8C8No match found");
	
		return;
	}
	if (hQuery.RowCount)
	{
		hQuery.FetchRow();
		char name[32];
		int rank, allranks;
		float points;
		hQuery.FetchString( 0, name, sizeof(name));
		rank = hQuery.FetchInt( 1 );
		allranks = hQuery.FetchInt( 2 );
		points = hQuery.FetchFloat( 3 );
		CPrintToChatAll(CHAT_PREFIX..."(Soldier) {green}%s {white}is ranked {lightskyblue}%i/%i {white}with {lightskyblue}%.0f {white}points", name, rank, allranks, points);
	}
	else
	{
		CPrintToChatAll(CHAT_PREFIX..."\x07C8C8C8No match found");
	}
}

public Action STime( int client, int args )
{
	char name[32], map[32], szQuery[300], displayName[32];
	int target, rank;
	bool is_rank;
	GetCmdArg(1, map, sizeof(map));
	GetCmdArg(2, name, sizeof(name));
	if (StrEqual(name, "") && StrEqual(map, ""))
		FormatEx(szQuery, sizeof(szQuery), "SELECT uid, time, `rank`, (select `rank` from maprecs where map = '%s' and run = 0 and mode = 1 order by `rank` desc limit 1), map, name FROM "...TABLE_RECORDS..." NATURAL JOIN "...TABLE_PLYDATA..." WHERE uid = %i AND map = '%s' AND run = 0 AND mode = 1", g_szCurrentMap, g_iClientId[client], g_szCurrentMap);
	else if (StrEqual(name, "") && !StrEqual(map, "") )
	{	
		for (int i=0; i<strlen(map); i++)
		{
			if (IsCharNumeric(map[i]))
			{
				is_rank = true;
			}
			else
			{
				is_rank = false;
				break;
			}
		}
		if (is_rank)
		{
			StringToIntEx(map, rank);
			FormatEx(szQuery, sizeof(szQuery), "SELECT uid, time, `rank`, (select `rank` from maprecs where map = '%s' and run = 0 and mode = 1 order by `rank` desc limit 1), map, name FROM "...TABLE_RECORDS..." NATURAL JOIN "...TABLE_PLYDATA..." WHERE `rank` = %i AND map = '%s' AND run = 0 AND mode = 1", g_szCurrentMap, rank, g_szCurrentMap);
		}
		else
		{
			target = FindTarget( client, map, true, false );
			if (target != -1)
			{
				FormatEx(szQuery, sizeof(szQuery), "SELECT uid, time, `rank`, (select `rank` from maprecs where map = '%s' and run = 0 and mode = 1 order by `rank` desc limit 1), map, name FROM "...TABLE_RECORDS..." NATURAL JOIN "...TABLE_PLYDATA..." WHERE uid = %i AND map = '%s' AND run = 0 AND mode = 1", g_szCurrentMap, g_iClientId[target], g_szCurrentMap);
			}	
			else
			{
				FormatEx(szQuery, sizeof(szQuery), "SELECT uid, time, `rank`, (select `rank` from maprecs where map = '%s' and run = 0 and mode = 1 order by `rank` desc limit 1), map, name FROM "...TABLE_RECORDS..." NATURAL JOIN "...TABLE_PLYDATA..." WHERE name LIKE '%s%%' AND map = '%s' AND run = 0 AND mode = 1", g_szCurrentMap, map, g_szCurrentMap);
			}
			if ( GetMapDisplayName(map, displayName, sizeof(displayName)) )
			{
				FormatEx(szQuery, sizeof(szQuery), "SELECT uid, time, `rank`, (select `rank` from maprecs where map = '%s' and run = 0 and mode = 1 order by `rank` desc limit 1), map, name FROM "...TABLE_RECORDS..." NATURAL JOIN "...TABLE_PLYDATA..." WHERE uid = %i AND map = '%s' AND run = 0 AND mode = 1", displayName, g_iClientId[client], displayName);
			}
			else
			{
				if (target > -1)
					FormatEx(szQuery, sizeof(szQuery), "SELECT uid, time, `rank`, (select `rank` from maprecs where map = '%s' and run = 0 and mode = 1 order by `rank` desc limit 1), map, name FROM "...TABLE_RECORDS..." NATURAL JOIN "...TABLE_PLYDATA..." WHERE uid = %i AND map = '%s' AND run = 0 AND mode = 1", g_szCurrentMap, g_iClientId[target], g_szCurrentMap);
			}
		}
	}
	else if (!StrEqual(name, "") && !StrEqual(map, "") )
	{
		target = FindTarget( client, name, true, false );

		if ( GetMapDisplayName(map, displayName, sizeof(displayName)) )
		{
			for (int i=0; i<strlen(name); i++)
			{
				if (IsCharNumeric(name[i]))
				{
					is_rank = true;
				}
				else
				{
					is_rank = false;
					break;
				}
			}
			if (is_rank)
			{
				StringToIntEx(name, rank);
				FormatEx(szQuery, sizeof(szQuery), "SELECT uid, time, `rank`, (select `rank` from maprecs where map = '%s' and run = 0 and mode = 1 order by `rank` desc limit 1), map, name FROM "...TABLE_RECORDS..." NATURAL JOIN "...TABLE_PLYDATA..." WHERE `rank` = %i AND map = '%s' AND run = 0 AND mode = 1", displayName, rank, displayName);
			}
			else
			{
				if (target != -1)
					FormatEx(szQuery, sizeof(szQuery), "SELECT uid, time, `rank`, (select `rank` from maprecs where map = '%s' and run = 0 and mode = 1 order by `rank` desc limit 1), map, name FROM "...TABLE_RECORDS..." NATURAL JOIN "...TABLE_PLYDATA..." WHERE uid = %i AND map = '%s' AND run = 0 AND mode = 1", displayName, g_iClientId[target], displayName);
				else
					FormatEx(szQuery, sizeof(szQuery), "SELECT uid, time, `rank`, (select `rank` from maprecs where map = '%s' and run = 0 and mode = 1 order by `rank` desc limit 1), map, name FROM "...TABLE_RECORDS..." NATURAL JOIN "...TABLE_PLYDATA..." WHERE name LIKE '%s%%' AND map = '%s' AND run = 0 AND mode = 1", displayName, name, displayName);	
			}
		}
	}
	g_hDatabase.Query( Threaded_STime, szQuery, client, DBPrio_Normal );
	return Plugin_Handled;
}

public void Threaded_STime( Database hOwner, DBResultSet hQuery, const char[] szError, int client )
{

	if ( hQuery == null )
	{
		CPrintToChatAll(CHAT_PREFIX..."\x07C8C8C8No match found");
	
		return;
	}
	if (hQuery.RowCount)
	{
		hQuery.FetchRow();
		char name[32], map[32], rank, allranks, szTime[TIME_SIZE_DEF];
		FormatSeconds(hQuery.FetchFloat( 1), szTime, FORMAT_2DECI);
		rank = hQuery.FetchInt( 2);
		allranks = hQuery.FetchInt( 3);
		hQuery.FetchString( 4, map, sizeof(map));
		hQuery.FetchString( 5, name, sizeof(name));
		CPrintToChatAll(CHAT_PREFIX..."(Solly) {green}%s {white}is ranked {lightskyblue}%i/%i {white}on {green}%s {white}with time: {green}%s", name, rank, allranks, map, szTime);
	}
	else
	{
		CPrintToChatAll(CHAT_PREFIX..."\x07C8C8C8No match found");
	}
}

public Action DTime( int client, int args )
{
	char name[32], map[32], szQuery[300], displayName[32];
	int target, rank;
	bool is_rank;
	GetCmdArg(1, map, sizeof(map));
	GetCmdArg(2, name, sizeof(name));
	if (StrEqual(name, "") && StrEqual(map, ""))
		FormatEx(szQuery, sizeof(szQuery), "SELECT uid, time, `rank`, (select `rank` from maprecs where map = '%s' and run = 0 and mode = 3 order by `rank` desc limit 1), map, name FROM "...TABLE_RECORDS..." NATURAL JOIN "...TABLE_PLYDATA..." WHERE uid = %i AND map = '%s' AND run = 0 AND mode = 3", g_szCurrentMap, g_iClientId[client], g_szCurrentMap);
	else if (StrEqual(name, "") && !StrEqual(map, "") )
	{	
		for (int i=0; i<strlen(map); i++)
		{
			if (IsCharNumeric(map[i]))
			{
				is_rank = true;
			}
			else
			{
				is_rank = false;
				break;
			}
		}
		if (is_rank)
		{
			StringToIntEx(map, rank);
			FormatEx(szQuery, sizeof(szQuery), "SELECT uid, time, `rank`, (select `rank` from maprecs where map = '%s' and run = 0 and mode = 3 order by `rank` desc limit 1), map, name FROM "...TABLE_RECORDS..." NATURAL JOIN "...TABLE_PLYDATA..." WHERE `rank` = %i AND map = '%s' AND run = 0 AND mode = 3", g_szCurrentMap, rank, g_szCurrentMap);
		}
		else
		{
			target = FindTarget( client, map, true, false );
			if (target != -1)
			{
				FormatEx(szQuery, sizeof(szQuery), "SELECT uid, time, `rank`, (select `rank` from maprecs where map = '%s' and run = 0 and mode = 3 order by `rank` desc limit 1), map, name FROM "...TABLE_RECORDS..." NATURAL JOIN "...TABLE_PLYDATA..." WHERE uid = %i AND map = '%s' AND run = 0 AND mode = 3", g_szCurrentMap, g_iClientId[target], g_szCurrentMap);
			}	
			else
			{
				FormatEx(szQuery, sizeof(szQuery), "SELECT uid, time, `rank`, (select `rank` from maprecs where map = '%s' and run = 0 and mode = 3 order by `rank` desc limit 1), map, name FROM "...TABLE_RECORDS..." NATURAL JOIN "...TABLE_PLYDATA..." WHERE name LIKE '%s%%' AND map = '%s' AND run = 0 AND mode = 3", g_szCurrentMap, map, g_szCurrentMap);
			}
			if ( GetMapDisplayName(map, displayName, sizeof(displayName)) )
			{
				FormatEx(szQuery, sizeof(szQuery), "SELECT uid, time, `rank`, (select `rank` from maprecs where map = '%s' and run = 0 and mode = 3 order by `rank` desc limit 1), map, name FROM "...TABLE_RECORDS..." NATURAL JOIN "...TABLE_PLYDATA..." WHERE uid = %i AND map = '%s' AND run = 0 AND mode = 3", displayName, g_iClientId[client], displayName);
			}
			else
			{
				if (target > -1)
					FormatEx(szQuery, sizeof(szQuery), "SELECT uid, time, `rank`, (select `rank` from maprecs where map = '%s' and run = 0 and mode = 3 order by `rank` desc limit 1), map, name FROM "...TABLE_RECORDS..." NATURAL JOIN "...TABLE_PLYDATA..." WHERE uid = %i AND map = '%s' AND run = 0 AND mode = 3", g_szCurrentMap, g_iClientId[target], g_szCurrentMap);
			}
		}
	}
	else if (!StrEqual(name, "") && !StrEqual(map, "") )
	{
		target = FindTarget( client, name, true, false );

		if ( GetMapDisplayName(map, displayName, sizeof(displayName)) )
		{
			for (int i=0; i<strlen(name); i++)
			{
				if (IsCharNumeric(name[i]))
				{
					is_rank = true;
				}
				else
				{
					is_rank = false;
					break;
				}
			}
			if (is_rank)
			{
				StringToIntEx(name, rank);
				FormatEx(szQuery, sizeof(szQuery), "SELECT uid, time, `rank`, (select `rank` from maprecs where map = '%s' and run = 0 and mode = 3 order by `rank` desc limit 1), map, name FROM "...TABLE_RECORDS..." NATURAL JOIN "...TABLE_PLYDATA..." WHERE `rank` = %i AND map = '%s' AND run = 0 AND mode = 3", displayName, rank, displayName);
			}
			else
			{
				if (target != -1)
					FormatEx(szQuery, sizeof(szQuery), "SELECT uid, time, `rank`, (select `rank` from maprecs where map = '%s' and run = 0 and mode = 3 order by `rank` desc limit 1), map, name FROM "...TABLE_RECORDS..." NATURAL JOIN "...TABLE_PLYDATA..." WHERE uid = %i AND map = '%s' AND run = 0 AND mode = 3", displayName, g_iClientId[target], displayName);
				else
					FormatEx(szQuery, sizeof(szQuery), "SELECT uid, time, `rank`, (select `rank` from maprecs where map = '%s' and run = 0 and mode = 3 order by `rank` desc limit 1), map, name FROM "...TABLE_RECORDS..." NATURAL JOIN "...TABLE_PLYDATA..." WHERE name LIKE '%s%%' AND map = '%s' AND run = 0 AND mode = 3", displayName, name, displayName);	
			}
		}
	}
	g_hDatabase.Query( Threaded_DTime, szQuery, client, DBPrio_Normal );
	return Plugin_Handled;
}

public void Threaded_DTime( Database hOwner, DBResultSet hQuery, const char[] szError, int client )
{

	if ( hQuery == null )
	{
		DB_LogError( "Couldn't retrieve player's ranking!" );
	
		return;
	}
	if (hQuery.RowCount)
	{
		hQuery.FetchRow();
		char name[32], map[32], rank, allranks, szTime[TIME_SIZE_DEF];
		FormatSeconds(hQuery.FetchFloat( 1), szTime, FORMAT_2DECI);
		rank = hQuery.FetchInt( 2);
		allranks = hQuery.FetchInt( 3);
		hQuery.FetchString( 4, map, sizeof(map));
		hQuery.FetchString( 5, name, sizeof(name));
		CPrintToChatAll(CHAT_PREFIX..."(Demo) {green}%s {white}is ranked {lightskyblue}%i/%i {white}on {green}%s {white}with time: {green}%s", name, rank, allranks, map, szTime);
	}
	else
	{
		CPrintToChatAll(CHAT_PREFIX..."\x07C8C8C8No match found");
	}
}

public void SetClass( int client )
{
	Menu mMenu = new Menu( Handler_SetClass);
	mMenu.SetTitle( "Set Class for:\n " );
	char id[32];
	mMenu.AddItem("0", g_szRunName[NAME_LONG][RUN_MAIN]);
	for(int j = 1; j < NUM_REALZONES2; j++)
	{
		if (g_bIsLoaded[j])
		{
			IntToString(j, id, sizeof(id));
			mMenu.AddItem(id, g_szRunName[NAME_LONG][j]);
		}
	}
	mMenu.Display( client, MENU_TIME_FOREVER );

}

public int Handler_SetClass( Menu mMenu, MenuAction action, int client, int item )
{
	if ( action == MenuAction_Select )
	{
	int args;
	char szItem[32];
	GetMenuItem( mMenu, item, szItem, sizeof( szItem ) );
	StringToIntEx(szItem, args);
	SetClassDEV( client, args );
	}
}	

public void SetClassDEV( int client, int run )
{
	Menu mMenu = new Menu( Handler_SetClassDEV);
	tier_run[client] = run;
	mMenu.SetTitle( "<Set Class for <%s>\n<%s>\n ", g_szRunName[NAME_LONG][run], g_szCurrentMap );
	
	mMenu.AddItem( "1", "Disable regen for Soldier (Enabled for Demoman)" );
	mMenu.AddItem( "2", "Disable regen for Demoman (Enabled for Soldier)" );
	mMenu.AddItem( "3", "Disable regen for both classes" );
	mMenu.AddItem( "4", "Enable regen for both classes" );

	mMenu.ExitBackButton = true;
	mMenu.Display( client, MENU_TIME_FOREVER );

}

public int Handler_SetClassDEV( Menu mMenu, MenuAction action, int client, int item )
{
	if ( action == MenuAction_End ) { delete mMenu; return 0; }
	if (action == MenuAction_Cancel)
	{
		if (item == MenuCancel_ExitBack)
		{
			SetClass(client);
			return 0;
		}
	}
	if ( action != MenuAction_Select ) return 0;
	if ( action == MenuAction_Select )
	{
		int args;
		char szItem[5];
		char szQuery[195];
		if ( !GetMenuItem( mMenu, item, szItem, sizeof( szItem ) ) ) return 0;
		StringToIntEx(szItem, args);
		if (args == 1)
		{
			FormatEx(szQuery, sizeof(szQuery), "UPDATE "...TABLE_MAPINFO..." SET solly = 1, demo = 0 WHERE map_name = '%s' AND run = %i", g_szCurrentMap, tier_run[client] );
			CPrintToChatAll(CHAT_PREFIX..."Regen for Soldier have been {green}Disabled {white}for {green}%s {white}<{lightskyblue}%s{white}>", g_szCurrentMap, g_szRunName[NAME_LONG][tier_run[client]] );
			szClass[tier_run[client]][MODE_SOLDIER] = 1;
			szClass[tier_run[client]][MODE_DEMOMAN] = 0;
		}
		else if (args == 2)
		{
			FormatEx(szQuery, sizeof(szQuery), "UPDATE "...TABLE_MAPINFO..." SET solly = 0, demo = 1 WHERE map_name = '%s' AND run = %i", g_szCurrentMap, tier_run[client] );
			CPrintToChatAll(CHAT_PREFIX..."Regen for Demoman have been {green}Disabled {white}for {green}%s {white}<{lightskyblue}%s{white}>", g_szCurrentMap, g_szRunName[NAME_LONG][tier_run[client]] );
			szClass[tier_run[client]][MODE_DEMOMAN] = 1;
			szClass[tier_run[client]][MODE_SOLDIER] = 0;	
		}
		else if (args == 3)
		{
			FormatEx(szQuery, sizeof(szQuery), "UPDATE "...TABLE_MAPINFO..." SET solly = 1, demo = 1 WHERE map_name = '%s' AND run = %i", g_szCurrentMap, tier_run[client] );
			CPrintToChatAll(CHAT_PREFIX..."Regen for both classes have been {green}Disabled {white}for {green}%s {white}<{lightskyblue}%s{white}>", g_szCurrentMap, g_szRunName[NAME_LONG][tier_run[client]] );
			szClass[tier_run[client]][MODE_DEMOMAN] = 1;
			szClass[tier_run[client]][MODE_SOLDIER] = 1;
		}
		else if (args == 4)
		{
			FormatEx(szQuery, sizeof(szQuery), "UPDATE "...TABLE_MAPINFO..." SET solly = 0, demo = 0 WHERE map_name = '%s' AND run = %i", g_szCurrentMap, tier_run[client] );
			CPrintToChatAll(CHAT_PREFIX..."Regen for both classes have been {green}Enabled {white}for {green}%s {white}<{lightskyblue}%s{white}>", g_szCurrentMap, g_szRunName[NAME_LONG][tier_run[client]] );
			szClass[tier_run[client]][MODE_DEMOMAN] = 0;
			szClass[tier_run[client]][MODE_SOLDIER] = 0;
		}
		SQL_TQuery(g_hDatabase, Threaded_Empty, szQuery, client);
	}
}

public void SetTier( int client )
{
	Menu mMenu = new Menu( Handler_SetTier);
	mMenu.SetTitle( "Set tier for:\n " );
	char id[32];
	mMenu.AddItem("0", g_szRunName[NAME_LONG][RUN_MAIN]);
	for(int j = 1; j < NUM_REALZONES2; j++)
	{
		if (g_bIsLoaded[j])
		{
			IntToString(j, id, sizeof(id));
			mMenu.AddItem(id, g_szRunName[NAME_LONG][j]);
		}
	}
	mMenu.Display( client, MENU_TIME_FOREVER );

}

public int Handler_SetTier( Menu mMenu, MenuAction action, int client, int item )
{
	if ( action == MenuAction_Select )
	{
	int args;
	char szItem[32];
	GetMenuItem( mMenu, item, szItem, sizeof( szItem ) );
	StringToIntEx(szItem, args);
	SetTierDEV( client, args, 0 );
	}
}		

public void SetTierDEV( int client, int run, int i )
{
	Menu mMenu = new Menu( Handler_SetTierDEV);
	tier_run[client] = run;
	if (i == 0)
		mMenu.SetTitle( "<Set Soldier Tier for %s>\n<%s>\n ", g_szCurrentMap, g_szRunName[NAME_LONG][run] );
	else
		mMenu.SetTitle( "<Set Demoman Tier for %s>\n<%s>\n ", g_szCurrentMap, g_szRunName[NAME_LONG][run] );

	if (i > 0)
		tier_block[client] = 1;
	else
		tier_block[client] = 0;
	
	mMenu.AddItem( "1", "Tier 1" );
	mMenu.AddItem( "2", "Tier 2" );
	mMenu.AddItem( "3", "Tier 3" );
	mMenu.AddItem( "4", "Tier 4" );
	mMenu.AddItem( "5", "Tier 5" );
	mMenu.AddItem( "6", "Tier 6" );
	mMenu.AddItem( "0", "Tier 0 (Not Posible)" );

	mMenu.ExitBackButton = true;
	mMenu.Display( client, MENU_TIME_FOREVER );

}

public int Handler_SetTierDEV( Menu mMenu, MenuAction action, int client, int item )
{
	if ( action == MenuAction_End ) { delete mMenu; return 0; }
	if (action == MenuAction_Cancel)
	{
		if (item == MenuCancel_ExitBack)
		{
			if (tier_block[client] > 0)
				SetTierDEV( client, tier_run[client], 0 );
			else
				SetTier(client);

			return 0;
		}
	}
	if ( action != MenuAction_Select ) return 0;
	if ( action == MenuAction_Select )
	{
	int args;
	char szItem[5];
	char szQuery[195];
	if ( !GetMenuItem( mMenu, item, szItem, sizeof( szItem ) ) ) return 0;
	StringToIntEx(szItem, args);
	if (tier_block[client] > 0)
	{
		FormatEx(szQuery, sizeof(szQuery), "UPDATE "...TABLE_MAPINFO..." SET dtier = %i WHERE map_name = '%s' AND run = %i", args, g_szCurrentMap, tier_run[client] );
		SQL_TQuery(g_hDatabase, Threaded_Empty, szQuery, client);
		CPrintToChatAll(CHAT_PREFIX..."{green}Demoman {white}Tier {lightskyblue}%i {white}have been set for {green}%s {white}<{lightskyblue}%s{white}>", args, g_szCurrentMap, g_szRunName[NAME_LONG][tier_run[client]] );
		SetClassDEV(client, tier_run[client]);
		g_Tiers[tier_run[client]][MODE_DEMOMAN] = args;
	}
	else
	{
		g_hDatabase.Format(szQuery, sizeof(szQuery), "INSERT INTO "...TABLE_MAPINFO..." VALUES ('%s', %i, %i, 0, 0, 0)", g_szCurrentMap, tier_run[client], args);
		if (!SQL_Query( g_hDatabase, szQuery))
		{
			g_hDatabase.Format(szQuery, sizeof(szQuery), "UPDATE "...TABLE_MAPINFO..." SET stier = %i WHERE map_name = '%s' AND run = %i", args, g_szCurrentMap, tier_run[client]);
			SQL_TQuery(g_hDatabase, Threaded_Empty, szQuery, client);
		}
		SetTierDEV( client, tier_run[client], 1 );
		CPrintToChatAll(CHAT_PREFIX..."{green}Soldier {white}Tier {lightskyblue}%i {white}have been set for {green}%s {white}<{lightskyblue}%s{white}>", args, g_szCurrentMap, g_szRunName[NAME_LONG][tier_run[client]] );
		g_Tiers[tier_run[client]][MODE_SOLDIER] = args;	
	}
	}
}

public Action Command_Practise( int client, int args )
{
	if ( !client ) return Plugin_Handled;
	
	if ( !IsValidCommandUser( client ) ) return Plugin_Handled;
	
	if (TF2_GetPlayerClass(client) == TFClass_DemoMan) {
			SetEntityGravity(client, 1.0);
			SetEntityHealth(client, 175);
		   	DestroyProjectilesDemo(client);
		} else if (TF2_GetPlayerClass(client) == TFClass_Soldier) {
			SetEntityGravity(client, 1.0);
		    DestroyProjectilesSoldier(client);
		}
	
	SetPlayerPractice( client, !g_bClientPractising[client] );
	
	return Plugin_Handled;
}

public Action Command_Set_CustomStart( int client, int args )
{
	if ( !client ) return Plugin_Handled;
	
	SetCustomStart(client);

	return Plugin_Handled;
}

public void SetCustomStart(int client )
{
	if ( !client ) return;

	Menu mMenu;
 	mMenu = new Menu( Handler_SetCustimStart );

 	char id[32];

	mMenu.SetTitle("For which zone do you want to set a custom start?\nMap: %s\n ", g_szCurrentMap);
	for (int i = 0; i < NUM_RUNS; i++){
		if (g_bIsLoaded[i]){
			IntToString(i, id, sizeof(id));
			mMenu.AddItem(id,g_szRunName[NAME_LONG][i]);
		}
	}
	
	mMenu.Display(client, MENU_TIME_FOREVER);

}

public void SetCustomStartAdv(int client, int run)
{
	if ( !client ) return;

	SetCustZone[client] = run;

	Menu mMenu;
 	mMenu = new Menu( Handler_SetCustimStartAdv );

	mMenu.SetTitle("Set Custom Start Position\nMap: %s\nZone: %s\n \n ", g_szCurrentMap, g_szRunName[NAME_LONG][run]);
	mMenu.AddItem("1", "Set Custom Start Position\n \n ", isSetCustomStart[run] ? ITEMDRAW_DISABLED : 0);
	mMenu.AddItem("0", "Remove Custom Start Position\n \n \n \n ", isSetCustomStart[run] ? 0 : ITEMDRAW_DISABLED);
	mMenu.Display(client, MENU_TIME_FOREVER);

}

public int Handler_SetCustimStart(Menu mMenu, MenuAction action, int client, int item)
{
	if ( action == MenuAction_Select )
	{
	int args;
	char szItem[32];
	GetMenuItem( mMenu, item, szItem, sizeof( szItem ) );
	StringToIntEx(szItem, args);
	SetCustomStartAdv( client, args );
	}
}

public int Handler_SetCustimStartAdv(Menu mMenu, MenuAction action, int client, int item)
{
	if ( action == MenuAction_End ) { delete mMenu; return 0; }
	if (action == MenuAction_Cancel)
	{
		if (item == MenuCancel_ExitBack)
		{
			SetCustomStart(client);
			return 0;
		}
	}
	if ( action != MenuAction_Select ) return 0;
	if ( action == MenuAction_Select )
	{
		int args;
		char szItem[32];
		char query[192];
		GetMenuItem( mMenu, item, szItem, sizeof( szItem ) );
		StringToIntEx(szItem, args);
		GetEntPropVector(client, Prop_Send, "m_vecOrigin", g_CustomRespawnPos[SetCustZone[client]] );
		GetClientAbsAngles(client, g_CustomRespawnAng[SetCustZone[client]] );
		if (item == 0)
		{
			isSetCustomStart[SetCustZone[client]] = true;
			FormatEx(query, sizeof(query), "INSERT INTO startpos VALUES('%s', '%i', '%.1f', '%.1f', '%.1f', '%.1f', '%.1f', '%.1f')", g_szCurrentMap, SetCustZone[client], g_CustomRespawnPos[SetCustZone[client]][0], g_CustomRespawnPos[SetCustZone[client]][1], g_CustomRespawnPos[SetCustZone[client]][2], g_CustomRespawnAng[SetCustZone[client]][0], g_CustomRespawnAng[SetCustZone[client]][1], g_CustomRespawnAng[SetCustZone[client]][2]);
			CPrintToChatAll(CHAT_PREFIX... "Start Position {lightskyblue}Updated{white}! <{green}%s{white}>", g_szRunName[NAME_LONG][SetCustZone[client]]);
		}
		else if (item == 1)
		{
			isSetCustomStart[SetCustZone[client]] = false;
			FormatEx(query, sizeof(query), "DELETE FROM startpos WHERE map = '%s' AND run = %i", g_szCurrentMap, SetCustZone[client]);
			CPrintToChatAll(CHAT_PREFIX... "Start Position {lightskyblue}Deleted{white}! <{green}%s{white}>", g_szRunName[NAME_LONG][SetCustZone[client]]);
		}

		SQL_TQuery(g_hDatabase, Threaded_Empty, query, client);

		SetupZoneSpawns();

		SetCustomStartAdv( client, SetCustZone[client] );
	}
}

public Action Command_Practise_Noclip( int client, int args )
{
	if ( !client ) return Plugin_Handled;
	
	if ( !IsValidCommandUser( client ) ) return Plugin_Handled;
	
	
	if ( GetEntityMoveType( client ) == MOVETYPE_WALK )
	{	
		if ( !g_bClientPractising[client] )
			SetPlayerPractice( client, true );
		
		SetEntityMoveType( client, MOVETYPE_NOCLIP );
	}
	else SetEntityMoveType( client, MOVETYPE_WALK );

	CPrintToChat(client, "Noclip {lightskyblue}%s", (GetEntityMoveType( client ) == MOVETYPE_WALK) ? "OFF" : "ON");
	
	return Plugin_Handled;
}

public Action Command_JoinTeam( int client, int args )
{
	return ( IsPlayerAlive( client ) ) ? Plugin_Handled : Plugin_Continue;
}
public Action Command_JoinClass( int client, int args )
{
	return Plugin_Handled;
}

public Action Command_Toggle_Speedometer( int client, int args )
{
	g_bClientSpeedometerEnabled[client] = !g_bClientSpeedometerEnabled[client];
}