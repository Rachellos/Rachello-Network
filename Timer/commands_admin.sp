public Action Command_Admin_ZoneEnd( int client, int args )
{
	if ( !client ) return Plugin_Handled;
	
	if ( g_iBuilderZone[client] <= ZONE_INVALID )
	{
		PRINTCHAT( client, CHAT_PREFIX..."You haven't even started to build!" );
		return Plugin_Handled;
	}
	
	
	int zone = g_iBuilderZone[client];

	static float vecPos[3];
	static float vecEye[3];
	static float end[3];

	if (g_ZoneMethod[client] == 0)
	{
		GetClientEyePosition(client, vecPos);
		GetClientEyeAngles(client, vecEye);
	   	TR_TraceRayFilter(vecPos, vecEye, MASK_SOLID, RayType_Infinite, TraceEntityFilterPlayer, client);
		
		TR_GetEndPosition(end);
	}
	else
	{
		GetClientAbsOrigin( client, end );
	}
	float vecMaxs[3];
	
	vecMaxs[0] = end[0];
	vecMaxs[1] = end[1];
	
	
	float flDif = end[2] - g_vecBuilderStart[client][2];
	
	// If player built the mins on the ground and just walks to the other side, we will then automatically make it higher.
	if ( IsBuildingOnGround[client] && ( flDif <= 4.0 && flDif >= -4.0 ) )
		vecMaxs[2] = float( RoundFloat( end[2] + ZONE_DEF_HEIGHT ) );
	else
		vecMaxs[2] = float( RoundFloat( end[2] + 0.5 ) );

	CorrectMinsMaxs( g_vecBuilderStart[client], vecMaxs );
	
	
	int id = 0;
	int run = g_iClientRun[client];
	
	if ( zone == ZONE_BLOCKS || zone == ZONE_COURCE || zone == ZONE_SKIP )
	{
		// Find out which id is available.
		int len = g_hZones.Length;
		
		for ( int j = 0; j <= len; j++ )
		{
			bool bFound;
			
			for ( int i = 0; i < len; i++ )
				if ( g_hZones.Get( i, view_as<int>( ZONE_TYPE ) ) == zone && g_hZones.Get( i, view_as<int>( ZONE_ID ) ) == j )
				{
					// We found a match. Try again.
					bFound = true;
					break;
				}
			
			if ( !bFound )
			{
				id = j;
				break;
			}
		}
	}
	else if ( zone == ZONE_CP )
	{
		// Find out which id is available.
		int len = g_hCPs.Length;
		
		for ( int j = 0; j <= len; j++ )
		{
			bool bFound;
			
			for ( int i = 0; i < len; i++ )
				if ( g_hCPs.Get( i, view_as<int>( CP_ID ) ) == j )
				{
					// We found a match. Try again.
					bFound = true;
					break;
				}
			
			if ( !bFound )
			{
				id = j;
				break;
			}
		}
	}
	else
	{
		ArrayCopy( g_vecBuilderStart[client], g_vecZoneMins[zone][ZoneIndex[client]], 3 );
		ArrayCopy( vecMaxs, g_vecZoneMaxs[zone][ZoneIndex[client]], 3 );
		
		g_bZoneBeingBuilt[zone] = false;
	}
	
	// Save to database.
	DB_SaveMapZone( zone, g_vecBuilderStart[client], vecMaxs, id, run, client );
	
	
	// Notify clients of the change!

	for (int i=0; i < NUM_RUNS+20; i+=2)
	{
		if ( (zone == i || zone == i+1) && g_bZoneExists[i][0] && g_bZoneExists[i+1][0] && ZoneIndex[client] <= 0 )
		{
			SetupZoneSpawns();
			
			g_bIsLoaded[i/2] = true;
			PrintColorChatAll( client, CHAT_PREFIX...""...CLR_TEAM..."%s"...CLR_TEXT..." is now available!", g_szRunName[NAME_LONG][i/2] );
			SetTier( client );
		}
	}
	
	if ( zone != ZONE_CP )
	{
		int iData[ZONE_SIZE];
		
		iData[ZONE_TYPE] = zone;
		iData[ZONE_ID] = id;
		
		ArrayCopy( g_vecBuilderStart[client], iData[ZONE_MINS], 3 );
		ArrayCopy( vecMaxs, iData[ZONE_MAXS], 3 );
		
		CreateZoneEntity( g_hZones.PushArray( iData, view_as<int>( ZoneData ) ) );
	}
	else
	{
		int iData[CP_SIZE];
		
		iData[CP_ID] = id;
		
		ArrayCopy( g_vecBuilderStart[client], iData[CP_MINS], 3 );
		ArrayCopy( vecMaxs, iData[CP_MAXS], 3 );
		
		CreateCheckPoint( g_hCPs.PushArray( iData, view_as<int>( CPData ) ) );
	}
	
	CreateZoneBeams( zone, g_vecBuilderStart[client], vecMaxs, id, ZoneIndex[client] );

	if ( zone == ZONE_CP )
	{
		PRINTCHATV( client, CHAT_PREFIX..."Created "...CLR_TEAM..."%s %i"...CLR_TEXT..." successfully!", g_szZoneNames[zone], id+1 );
	}
	else
	{
		if (ZoneIndex[client] <= 0)
			PRINTCHATV( client, CHAT_PREFIX..."Created "...CLR_TEAM..."%s"...CLR_TEXT..." successfully!", g_szZoneNames[zone] );
		else
			CPrintToChatAll( CHAT_PREFIX..."Created "...CLR_TEAM..."%s {white}::index {orange}%i{white}::"...CLR_TEXT..." successfully!", g_szZoneNames[zone], ZoneIndex[client]+1 );
	}
	
	ResetBuilding( client );

	CreateZone(client, ZoneType[client]);

	
	return Plugin_Handled;
}

public Action Command_Admin_ZoneCancel( int client, int args )
{
	if ( !client ) return Plugin_Handled;
	
	if ( g_iBuilderZone[client] == ZONE_INVALID )
	{
		PRINTCHAT( client, CHAT_PREFIX..."You have no zone to cancel!" );
		FakeClientCommand(client, "sm_zone");
		return Plugin_Handled;
	}
	
	ResetBuilding( client );

	FakeClientCommand(client, "sm_zone");
	
	return Plugin_Handled;
}

public Action Command_Admin_ZoneEdit_SelectCur( int client, int args )
{
	if ( !client ) return Plugin_Handled;
	
	int len = g_hZones.Length;
	if ( g_hZones == null || !len )
	{
		PRINTCHAT( client, CHAT_PREFIX..."There are no zones to change!" );
		
		FakeClientCommand( client, "sm_zone" );
		
		return Plugin_Handled;
	}
	
	// Only one to choose from...
	if ( len == 1 )
	{
		g_iBuilderZoneIndex[client] = 0;
		
		FakeClientCommand( client, "sm_zonepermissions" );
		
		return Plugin_Handled;
	}
	
	
	int iData[ZONE_SIZE];
	
	float vecMins[3];
	float vecMaxs[3];
	
	for ( int i = 0; i < len; i++ )
	{
		g_hZones.GetArray( i, iData, view_as<int>( ZoneData ) );
		
		ArrayCopy( iData[ZONE_MINS], vecMins, 3 );
		ArrayCopy( iData[ZONE_MAXS], vecMaxs, 3 );
		
		if ( IsInsideBoundsPlayer( client, vecMins, vecMaxs ) )
		{
			g_iBuilderZoneIndex[client] = i;
			
			FakeClientCommand( client, "sm_zonepermissions" );
			
			return Plugin_Handled;
		}
	}
	
	PRINTCHAT( client, CHAT_PREFIX..."Sorry, couldn't find zones." );
	
	FakeClientCommand( client, "sm_zoneedit" );
	
	return Plugin_Handled;
}

public Action Command_Admin_ForceZoneCheck( int client, int args )
{
	CheckZones();
	return Plugin_Handled;
}