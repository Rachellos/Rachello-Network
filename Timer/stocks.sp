stock void ArrayCopy( const any[] oldArray, any[] newArray, int size = 1 )
{
	for ( int i = 0; i < size; i++ ) newArray[i] = oldArray[i];
}

stock void ArraySet( any[] Array, any data, int index )
{
	Array[index] = data;
}

stock any ArrayGet( any[] Array, int index )
{
	return Array[index];
}

stock void CorrectMinsMaxs( float vecMins[3], float vecMaxs[3] )
{
	// Corrects map zones.
	float f;
	
	if ( vecMins[0] > vecMaxs[0] )
	{
		f = vecMins[0];
		vecMins[0] = vecMaxs[0];
		vecMaxs[0] = f;
	}
	
	if ( vecMins[1] > vecMaxs[1] )
	{
		f = vecMins[1];
		vecMins[1] = vecMaxs[1];
		vecMaxs[1] = f;
	}
	
	if ( vecMins[2] > vecMaxs[2] )
	{
		f = vecMins[2];
		vecMins[2] = vecMaxs[2];
		vecMaxs[2] = f;
	}
}

// Format seconds and make them look nice.
stock void FormatSeconds( float flSeconds, char szTarget[TIME_SIZE_DEF], int fFlags = 0 )
{
	static int		iMins;
	static char		szSec[7];
	static int		iHours;
	static int      iDay;
	iHours = 0;
	iMins = 0;
	iDay = 0;
	while ( flSeconds >= 60.0 )
	{
		iMins++;
		flSeconds -= 60.0;
	}
	
	while ( iMins >= 60 )
	{
		iHours++;
		iMins -= 60;
	}
	
	while ( iHours >= 24 )
	{
		iDay++;
		iHours -= 24;
	}
	
	switch ( fFlags )
	{
		case FORMAT_3DECI :
		{
			FormatEx( szSec, sizeof( szSec ), "%06.3f", flSeconds );
		}
		case FORMAT_2DECI :
		{
			FormatEx( szSec, sizeof( szSec ), "%05.2f", flSeconds );
		}
		case FORMAT_DESI :
		{
			FormatEx( szSec, sizeof( szSec ), "%04.1f", flSeconds );
		}
		default :
		{
			FormatEx( szSec, sizeof( szSec ), "%05.2f", flSeconds );
		}
	}
	
	// "XX.XX" to "XX:XX"
	szSec[sizeof( szSec ) - 5] = '.';
	
	// "XX:XX:XXX" - [10] (DEF)
	
	
	if ( iHours != TIME_INVALID )
	{
	FormatEx( szTarget, TIME_SIZE_DEF, "%i:%02i:%s", iHours, iMins, szSec );
    }
	else
	{
	FormatEx( szTarget, TIME_SIZE_DEF, "%02i:%s", iMins, szSec );
	}
	if ( iDay != TIME_INVALID )
	{
	FormatEx( szTarget, TIME_SIZE_DEF, "%id:%i:%02i:%s", iDay, iHours, iMins, szSec );
    }
	
	
}

public int FormatTimeDuration(char[] buffer, int maxlen, int time)
{
	float years = float(time) / float(31536000);
	float month = float(time) / float(2592000);
	int weeks = time / 604800;
    int days = time / 86400;
    int hours = time / 3600;
    int minutes = time / 60;
    int seconds = time;
    
    if (years >= 1.0)
    	return Format(buffer, maxlen, "%.1f year%s ago", years, (years < 2.0) ? "" : "s");
    else if (month >= 1.0)
        return Format(buffer, maxlen, "%.1f month%s ago", month, (month >= 2.0) ? "s" : "");
    else if (weeks > 0)
    	return Format(buffer, maxlen, "%i week%s ago", weeks, (weeks == 1) ? "" : "s");
    else if (days > 0)
        return Format(buffer, maxlen, "%i day%s ago", days, (days > 1) ? "s" : "");
    else if (hours > 0)
        return Format(buffer, maxlen, "%i %s ago", hours, (hours == 1) ? "hr." : "hrs.");        
    else if (minutes > 0)
        return Format(buffer, maxlen, "%i min%s. ago", minutes, (minutes > 1) ? "s" : "");        
    else
        return Format(buffer, maxlen, "%i sec. ago", seconds);        
}

stock int DateTimeToTimestamp( const char[ ] szDate ) {
    char szBuffer[ 64 ];
    strcopy( szBuffer, sizeof( szBuffer ), szDate );
    
    ReplaceString( szBuffer, sizeof( szBuffer ), "-", " " );
    ReplaceString( szBuffer, sizeof( szBuffer ), ".", " " );
    ReplaceString( szBuffer, sizeof( szBuffer ), ":", " " );
    
    char szTime[ 6 ][ 6 ];
    ExplodeString( szBuffer, " ", szTime, sizeof( szTime ), sizeof( szTime[ ] ) );
    
    int iYear = StringToInt( szTime[ 0 ] );
    int iMonth  = StringToInt( szTime[ 1 ] );
    int iDay = StringToInt( szTime[ 2 ] );
    
    int iHour = StringToInt( szTime[ 3 ] );
    int iMinute  = StringToInt( szTime[ 4 ] );
    int iSecond = StringToInt( szTime[ 5 ] );
    
    return TimeToUnix( iYear, iMonth, iDay, iHour, iMinute, iSecond, UT_TIMEZONE_SERVER );
}

/*stock bool IsValidPlayerPosition( float vecPos[3] )
{
	static const float vecMins[] = { -16.0, -16.0, 0.0 };
	static const float vecMaxs[] = { 16.0, 16.0, 72.0 };
	
	TR_TraceHullFilter( vecPos, vecPos, vecMins, vecMaxs, MASK_SOLID );
	
	return ( !TR_DidHit( null ) );
}*/

stock int GetClientSpecTarget( int client )
{
	// Bad observer mode?
	return ( GetEntProp( client, Prop_Send, "m_iObserverMode" ) == OBS_MODE_ROAMING ) ? -1 : GetEntPropEnt( client, Prop_Send, "m_hObserverTarget" );
}

stock void HideEntity( int ent )
{
	SetEntityRenderMode( ent, RENDER_TRANSALPHA );
	SetEntityRenderColor( ent, _, _, _, 0 );
}

stock int FindSlotByWeapon( int client, int weapon )
{
	for ( int i = 0; i < SLOTS_SAVED; i++ )
	{
		if ( weapon == GetPlayerWeaponSlot( client, i ) ) return i;
	}
	
	return -1;
}

stock void SetClientPredictedAirAcceleration( int client, float aa )
{
	char szValue[8];
	FormatEx( szValue, sizeof( szValue ), "%0.f", aa );
	
	SendConVarValue( client, g_ConVar_AirAccelerate, szValue );
}

stock void SetClientFrags( int client, int frags )
{
	SetEntProp( client, Prop_Data, "m_iFrags", frags );
}

stock int GetActivePlayers( int ignore = 0 )
{
	int clients;
	
	for ( int i = 1; i <= MaxClients; i++ )
	{
		if ( i == ignore ) continue;
		
		if ( IsClientInGame( i ) && !IsFakeClient( i ) )
			clients++;
	}
	
	return clients;
}

public bool RunIsBonus(int run)
{
	if (RUN_BONUS1 <= run <= RUN_BONUS10)
		return true;

	return false;
}

public bool RunIsCourse(int run)
{
	if (RUN_COURSE1 <= run <= RUN_COURSE10)
		return true;

	return false;
}

// Used for players and other entities.
stock bool IsInsideBounds( int ent, float vecMins[3], float vecMaxs[3] )
{
	static float vecPos[3];
	GetEntPropVector( ent, Prop_Send, "m_vecOrigin", vecPos );
	
	// As of 1.4.4, we correct zone mins and maxs.
	if ( (vecMins[0] <= vecPos[0] <= vecMaxs[0] ) && ( vecMins[1] <= vecPos[1] <= vecMaxs[1] ) && ( vecMins[2] <= vecPos[2] <= vecMaxs[2] ) )
		return true;
	else
		return false;
}

stock bool IsInsideBoundsPlayer( int client, float vecMins[3], float vecMaxs[3] )
{
	/*static float vecPos[3];
	GetEntPropVector( ent, Prop_Send, "m_vecOrigin", vecPos );
	
	// As of 1.4.4, we correct zone mins and maxs.
	if ( (vecMins[0] <= vecPos[0] <= vecMaxs[0] ) && ( vecMins[1] <= vecPos[1] <= vecMaxs[1] ) && ( vecMins[2] <= vecPos[2] <= vecMaxs[2] ) )
		return true;
	else
		return false;*/
	if (IsClientInGame(client) && IsClientConnected(client) && IsPlayerAlive(client))
	{
		float eyePos[3];
		GetClientEyePosition(client,eyePos);

		float playerWidth = 49.0;
		float playerHeight = 83.0;
		float eyeHeight = 68.0;

		if(GetEntityFlags(client) & FL_DUCKING) {
			//Player is crouched
			playerHeight = 63.0;
			eyeHeight = 48.0;
		}
		if(NumberIsInbetween(eyePos[0],playerWidth/2.0,vecMins[0],vecMaxs[0])) {
			if(NumberIsInbetween(eyePos[1],playerWidth/2.0,vecMins[1],vecMaxs[1])) {
				if(NumberIsInbetween(eyePos[2]-eyeHeight+(playerHeight/2.0),playerHeight/2.0,vecMins[2],vecMaxs[2])) {
					return true;
				}
			}
		}
	}
	return false;
}

public int NumberIsInbetween(float x, float w, float c1, float c2) {
	if(c1 > c2) {
		if(x+w >= c2 && x-w <= c1) {
			return 1;
		}
	} else {
		if(x-w <= c2 && x+w >= c1) {
			return 1;
		}
	}
	return 0;
}

stock int CreateTrigger( float vecMins[3], float vecMaxs[3] )
{
	int ent = CreateEntityByName( "trigger_multiple" );
	
	if ( ent < 1 )
	{
		LogError( CONSOLE_PREFIX..."Couldn't create block entity!" );
		return 0;
	}
	
	DispatchKeyValue( ent, "wait", "0" );
	DispatchKeyValue( ent, "StartDisabled", "0" );
	DispatchKeyValue( ent, "spawnflags", "1" ); // Clients only!
	
	if ( !DispatchSpawn( ent ) )
	{
		LogError( CONSOLE_PREFIX..."Couldn't spawn block entity!" );
		return 0;
	}
	
	ActivateEntity( ent );
	
	SetEntityModel( ent, BRUSH_MODEL );
	
	SetEntProp( ent, Prop_Send, "m_fEffects", 32 ); // NODRAW
	
	
	float vecPos[3];
	float vecNewMaxs[3];
	
	// Determine the entity's origin.
	// This means the bounds will be just opposite numbers of each other.
	vecNewMaxs[0] = ( vecMaxs[0] - vecMins[0] ) / 2;
	vecPos[0] = vecMins[0] + vecNewMaxs[0];

	vecNewMaxs[1] = ( vecMaxs[1] - vecMins[1] ) / 2;
	vecPos[1] = vecMins[1] + vecNewMaxs[1];

	vecNewMaxs[2] = ( vecMaxs[2] - vecMins[2] ) / 2;
	vecPos[2] = vecMins[2] + vecNewMaxs[2];
	
	TeleportEntity( ent, vecPos, NULL_VECTOR, NULL_VECTOR );
	
	// We then set the mins and maxs of the zone according to the center.
	float vecNewMins[3];
	
	vecNewMins[0] = -1 * vecNewMaxs[0];
	vecNewMins[1] = -1 * vecNewMaxs[1];
	vecNewMins[2] = -1 * vecNewMaxs[2];
	
	SetEntPropVector( ent, Prop_Send, "m_vecMins", vecNewMins );
	SetEntPropVector( ent, Prop_Send, "m_vecMaxs", vecNewMaxs );
	SetEntProp( ent, Prop_Send, "m_nSolidType", 2 ); // Essential! Use bounding box instead of model's bsp(?) for input.
	
	return ent;
}

stock int NumberOfActivePlayers(int mode, int style){
	int count = 0;
	for ( int i = 1; i <= MaxClients; i++ )
		if (IsClientConnected(i) && !IsFakeClient(i) && !(TF2_GetClientTeam(i) == TFTeam_Spectator) && g_iClientMode[i] == mode && g_iClientStyle[i] == style) count++;
	return count;
}