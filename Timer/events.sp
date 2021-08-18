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

//////////
// CHAT //
//////////
public Action OnClientSayCommand( int client, const char[] szCommand, const char[] text )
{
	if ( !client || BaseComm_IsClientGagged( client ) ) return Plugin_Continue;
	
		char live[10];
		char msg[200];
		char alltext[300];
		char alltext2[300];
		FormatEx(msg, sizeof(msg), "%s", text);
		TrimString(msg);
		

		if (StrEqual(msg, "( ͡° ͜ʖ ͡°)") || StrEqual(msg, "( ° ͜ʖ ͡°)") || StrEqual(msg, " ( ͡° ͜ʖ ͡°)") || StrEqual(msg, "( ͡° ͜ʖ ͡°) "))
		{
			PrintToChat(client, CHAT_PREFIX..."Fuck Lenny");
			return Plugin_Handled;
		}
		if ( !IsPlayerAlive(client) )
			FormatEx(live, sizeof(live), "* ");
		else
			FormatEx(live, sizeof(live), "");

		switch ( ranksolly[client] )
			{
				case 1 : 
				{
					FormatEx( alltext, sizeof(alltext), "%s{1}[{white}S{1}]{2}Emperor{1}] {3}%N \x01:  {4}%s", live, client, msg );
				}
				case 2 : 
				{
					FormatEx( alltext, sizeof(alltext), "%s{5}[{white}S{5}]{6}King{5}] {7}%N \x01:  {8}%s", live, client, msg );
				}
				case 3 : 
				{
					FormatEx( alltext, sizeof(alltext), "%s{9}[{white}S{9}]{10}Archduke{9}] {11}%N \x01:  {12}%s", live, client, msg );
				}
				case 4 : 
				{
					FormatEx( alltext, sizeof(alltext), "%s{13}[{white}S{13}]{14}Lord{13}] {15}%N \x01:  {12}%s", live, client, msg );
				}
				case 5 : 
				{
					FormatEx( alltext, sizeof(alltext), "%s{16}[{white}S{16}]{17}Duke{16}] {18}%N \x01:  {12}%s", live, client, msg );
				}
				default :
				{
					if (6 <= ranksolly[client] <= 10 )
					{
						if (ranksolly[client] == 6)
							FormatEx( alltext, sizeof(alltext), "%s{19}[{white}S{19}]{20}Prince I{19}] {10}%N \x01:  {12}%s", live, client, msg );
						else if (ranksolly[client] == 7)
							FormatEx( alltext, sizeof(alltext), "%s{19}[{white}S{19}]{20}Prince II{19}] {10}%N \x01:  {12}%s", live, client, msg );
						else if (ranksolly[client] == 8)
							FormatEx( alltext, sizeof(alltext), "%s{19}[{white}S{19}]{20}Prince III{19}] {10}%N \x01:  {12}%s", live, client, msg );
						else if (ranksolly[client] == 9)
							FormatEx( alltext, sizeof(alltext), "%s{19}[{white}S{19}]{20}Prince IV{19}] {10}%N \x01:  {12}%s", live, client, msg );
						else if (ranksolly[client] == 10)
							FormatEx( alltext, sizeof(alltext), "%s{19}[{white}S{19}]{20}Prince V{19}] {10}%N \x01:  {12}%s", live, client, msg );		
					}
					else if ( 11 <= ranksolly[client] <= 15 )
					{
						if (ranksolly[client] == 11)
							FormatEx( alltext, sizeof(alltext), "%s{21}[{white}S{21}]{22}Earl I{21}] {23}%N \x01:  {12}%s", live, client, msg );
						else if (ranksolly[client] == 12)
							FormatEx( alltext, sizeof(alltext), "%s{21}[{white}S{21}]{22}Earl II{21}] {23}%N \x01:  {12}%s", live, client, msg );
						else if (ranksolly[client] == 13)
							FormatEx( alltext, sizeof(alltext), "%s{21}[{white}S{21}]{22}Earl III{21}] {23}%N \x01:  {12}%s", live, client, msg );
						else if (ranksolly[client] == 14)
							FormatEx( alltext, sizeof(alltext), "%s{21}[{white}S{21}]{22}Earl IV{21}] {23}%N \x01:  {12}%s", live, client, msg );
						else if (ranksolly[client] == 15)
							FormatEx( alltext, sizeof(alltext), "%s{21}[{white}S{21}]{22}Earl V{21}] {23}%N \x01:  {12}%s", live, client, msg );		
					}
					else if ( 16 <= ranksolly[client] <= 20 )
					{
						if (ranksolly[client] == 16)
							FormatEx( alltext, sizeof(alltext), "%s{sirb}[{white}S{sirb}]{sirr}Sir I{sirb}] {sirn}%N \x01:  {sirc}%s", live, client, msg );	
						else if (ranksolly[client] == 17)
							FormatEx( alltext, sizeof(alltext), "%s{sirb}[{white}S{sirb}]{sirr}Sir II{sirb}] {sirn}%N \x01:  {sirc}%s", live, client, msg );	
						else if (ranksolly[client] == 18)
							FormatEx( alltext, sizeof(alltext), "%s{sirb}[{white}S{sirb}]{sirr}Sir III{sirb}] {sirn}%N \x01:  {sirc}%s", live, client, msg );	
						else if (ranksolly[client] == 19)
							FormatEx( alltext, sizeof(alltext), "%s{sirb}[{white}S{sirb}]{sirr}Sir IV{sirb}] {sirn}%N \x01:  {sirc}%s", live, client, msg );	
						else if (ranksolly[client] == 20)
							FormatEx( alltext, sizeof(alltext), "%s{sirb}[{white}S{sirb}]{sirr}Sir V{sirb}] {sirn}%N \x01:  {sirc}%s", live, client, msg );		
					}
					else if ( 21 <= ranksolly[client] <= 25 )
					{
						if (ranksolly[client] == 21)
							FormatEx( alltext, sizeof(alltext), "%s{countb}[{white}S{countb}]{countr}Count I{countb}] {countn}%N \x01:  {countc}%s", live, client, msg );	
						else if (ranksolly[client] == 22)
							FormatEx( alltext, sizeof(alltext), "%s{countb}[{white}S{countb}]{countr}Count II{countb}] {countn}%N \x01:  {countc}%s", live, client, msg );	
						else if (ranksolly[client] == 23)
							FormatEx( alltext, sizeof(alltext), "%s{countb}[{white}S{countb}]{countr}Count III{countb}] {countn}%N \x01:  {countc}%s", live, client, msg );	
						else if (ranksolly[client] == 24)
							FormatEx( alltext, sizeof(alltext), "%s{countb}[{white}S{countb}]{countr}Count IV{countb}] {countn}%N \x01:  {countc}%s", live, client, msg );	
						else if (ranksolly[client] == 25)
							FormatEx( alltext, sizeof(alltext), "%s{countb}[{white}S{countb}]{countr}Count V{countb}] {countn}%N \x01:  {countc}%s", live, client, msg );		
					}
					else if ( 26 <= ranksolly[client] <= 30 )
					{
						if (ranksolly[client] == 26)
							FormatEx( alltext, sizeof(alltext), "%s{baronb}[{white}S{baronb}]{baronr}Baron I{baronb}] {baronn}%N \x01:  {baronc}%s", live, client, msg );	
						else if (ranksolly[client] == 27)
							FormatEx( alltext, sizeof(alltext), "%s{baronb}[{white}S{baronb}]{baronr}Baron II{baronb}] {baronn}%N \x01:  {baronc}%s", live, client, msg );	
						else if (ranksolly[client] == 28)
							FormatEx( alltext, sizeof(alltext), "%s{baronb}[{white}S{baronb}]{baronr}Baron III{baronb}] {baronn}%N \x01:  {baronc}%s", live, client, msg );	
						else if (ranksolly[client] == 29)
							FormatEx( alltext, sizeof(alltext), "%s{baronb}[{white}S{baronb}]{baronr}Baron IV{baronb}] {baronn}%N \x01:  {baronc}%s", live, client, msg );	
						else if (ranksolly[client] == 30)
							FormatEx( alltext, sizeof(alltext), "%s{baronb}[{white}S{baronb}]{baronr}Baron V{baronb}] {baronn}%N \x01:  {baronc}%s", live, client, msg );		
					}
					else if ( 31 <= ranksolly[client] <= 35 )
					{
						if (ranksolly[client] == 31)
							FormatEx( alltext, sizeof(alltext), "%s{knightb}[{white}S{knightb}]{knightr}Knight I{knightb}] {knightn}%N \x01:  {knightc}%s", live, client, msg );	
						else if (ranksolly[client] == 32)
							FormatEx( alltext, sizeof(alltext), "%s{knightb}[{white}S{knightb}]{knightr}Knight II{knightb}] {knightn}%N \x01:  {knightc}%s", live, client, msg );
						else if (ranksolly[client] == 33)
							FormatEx( alltext, sizeof(alltext), "%s{knightb}[{white}S{knightb}]{knightr}Knight III{knightb}] {knightn}%N \x01:  {knightc}%s", live, client, msg );	
						else if (ranksolly[client] == 34)
							FormatEx( alltext, sizeof(alltext), "%s{knightb}[{white}S{knightb}]{knightr}Knight IV{knightb}] {knightn}%N \x01:  {knightc}%s", live, client, msg );	
						else if (ranksolly[client] == 35)
							FormatEx( alltext, sizeof(alltext), "%s{knightb}[{white}S{knightb}]{knightr}Knight V{knightb}] {knightn}%N \x01:  {knightc}%s", live, client, msg );		
					}
					else if ( 36 <= ranksolly[client] <= 40 )
					{
						if (ranksolly[client] == 36)
							FormatEx( alltext, sizeof(alltext), "%s{nobleb}[{white}S{nobleb}]{nobler}Noble I{nobleb}] {noblen}%N \x01:  {noblec}%s", live, client, msg );	
						else if (ranksolly[client] == 37)
							FormatEx( alltext, sizeof(alltext), "%s{nobleb}[{white}S{nobleb}]{nobler}Noble II{nobleb}] {noblen}%N \x01:  {noblec}%s", live, client, msg );		
						else if (ranksolly[client] == 38)
							FormatEx( alltext, sizeof(alltext), "%s{nobleb}[{white}S{nobleb}]{nobler}Noble III{nobleb}] {noblen}%N \x01:  {noblec}%s", live, client, msg );	
						else if (ranksolly[client] == 39)
							FormatEx( alltext, sizeof(alltext), "%s{nobleb}[{white}S{nobleb}]{nobler}Noble IV{nobleb}] {noblen}%N \x01:  {noblec}%s", live, client, msg );		
						else if (ranksolly[client] == 40)
							FormatEx( alltext, sizeof(alltext), "%s{nobleb}[{white}S{nobleb}]{nobler}Noble V{nobleb}] {noblen}%N \x01:  {noblec}%s", live, client, msg );		
					}
					else if ( 41 <= ranksolly[client] <= 45 )
					{
						if (ranksolly[client] == 41)
							FormatEx( alltext, sizeof(alltext), "%s{esquireb}[{white}S{esquireb}]{esquirer}Esquire I{esquireb}] {esquiren}%N \x01:  {esquirec}%s", live, client, msg );	
						else if (ranksolly[client] == 42)
							FormatEx( alltext, sizeof(alltext), "%s{esquireb}[{white}S{esquireb}]{esquirer}Esquire II{esquireb}] {esquiren}%N \x01:  {esquirec}%s", live, client, msg );		
						else if (ranksolly[client] == 43)
							FormatEx( alltext, sizeof(alltext), "%s{esquireb}[{white}S{esquireb}]{esquirer}Esquire III{esquireb}] {esquiren}%N \x01:  {esquirec}%s", live, client, msg );		
						else if (ranksolly[client] == 44)
							FormatEx( alltext, sizeof(alltext), "%s{esquireb}[{white}S{esquireb}]{esquirer}Esquire IV{esquireb}] {esquiren}%N \x01:  {esquirec}%s", live, client, msg );	
						else if (ranksolly[client] == 45)
							FormatEx( alltext, sizeof(alltext), "%s{esquireb}[{white}S{esquireb}]{esquirer}Esquire V{esquireb}] {esquiren}%N \x01:  {esquirec}%s", live, client, msg );		
					}
					else if ( 46 <= ranksolly[client] <= 50 )
					{
						if (ranksolly[client] == 46)
							FormatEx( alltext, sizeof(alltext), "%s{jesterb}[{white}S{jesterb}]{jesterr}Jester I{jesterb}] {jestern}%N \x01:  {jesterc}%s", live, client, msg );	
						else if (ranksolly[client] == 47)
							FormatEx( alltext, sizeof(alltext), "%s{jesterb}[{white}S{jesterb}]{jesterr}Jester II{jesterb}] {jestern}%N \x01:  {jesterc}%s", live, client, msg );
						else if (ranksolly[client] == 48)
							FormatEx( alltext, sizeof(alltext), "%s{jesterb}[{white}S{jesterb}]{jesterr}Jester III{jesterb}] {jestern}%N \x01:  {jesterc}%s", live, client, msg );	
						else if (ranksolly[client] == 49)
							FormatEx( alltext, sizeof(alltext), "%s{jesterb}[{white}S{jesterb}]{jesterr}Jester IV{jesterb}] {jestern}%N \x01:  {jesterc}%s", live, client, msg );
						else if (ranksolly[client] == 50)
							FormatEx( alltext, sizeof(alltext), "%s{jesterb}[{white}S{jesterb}]{jesterr}Jester V{jesterb}] {jestern}%N \x01:  {jesterc}%s", live, client, msg );
					}
					else if ( 51 <= ranksolly[client] <= 55 )
					{
						if (ranksolly[client] == 51)
							FormatEx( alltext, sizeof(alltext), "%s{plebeianb}[{white}S{plebeianb}]{plebeianr}Plebeian I{plebeianb}] {plebeiann}%N \x01:  {plebeianc}%s", live, client, msg );	
						else if (ranksolly[client] == 52)
							FormatEx( alltext, sizeof(alltext), "%s{plebeianb}[{white}S{plebeianb}]{plebeianr}Plebeian II{plebeianb}] {plebeiann}%N \x01:  {plebeianc}%s", live, client, msg );
						else if (ranksolly[client] == 53)
							FormatEx( alltext, sizeof(alltext), "%s{plebeianb}[{white}S{plebeianb}]{plebeianr}Plebeian III{plebeianb}] {plebeiann}%N \x01:  {plebeianc}%s", live, client, msg );	
						else if (ranksolly[client] == 54)
							FormatEx( alltext, sizeof(alltext), "%s{plebeianb}[{white}S{plebeianb}]{plebeianr}Plebeian IV{plebeianb}] {plebeiann}%N \x01:  {plebeianc}%s", live, client, msg );	
						else if (ranksolly[client] == 55)
							FormatEx( alltext, sizeof(alltext), "%s{plebeianb}[{white}S{plebeianb}]{plebeianr}Plebeian V{plebeianb}] {plebeiann}%N \x01:  {plebeianc}%s", live, client, msg );
					}
					else if ( 56 <= ranksolly[client] <= 60 )
					{
						if (ranksolly[client] == 56)
							FormatEx( alltext, sizeof(alltext), "%s{peasantb}[{white}S{peasantb}]{peasantr}Peasant I{peasantb}] {peasantn}%N \x01:  {peasantc}%s", live, client, msg );	
						else if (ranksolly[client] == 57)
							FormatEx( alltext, sizeof(alltext), "%s{peasantb}[{white}S{peasantb}]{peasantr}Peasant II{peasantb}] {peasantn}%N \x01:  {peasantc}%s", live, client, msg );
						else if (ranksolly[client] == 58)
							FormatEx( alltext, sizeof(alltext), "%s{peasantb}[{white}S{peasantb}]{peasantr}Peasant III{peasantb}] {peasantn}%N \x01:  {peasantc}%s", live, client, msg );	
						else if (ranksolly[client] == 59)
							FormatEx( alltext, sizeof(alltext), "%s{peasantb}[{white}S{peasantb}]{peasantr}Peasant IV{peasantb}] {peasantn}%N \x01:  {peasantc}%s", live, client, msg );
						else if (ranksolly[client] == 60)
							FormatEx( alltext, sizeof(alltext), "%s{peasantb}[{white}S{peasantb}]{peasantr}Peasant V{peasantb}] {peasantn}%N \x01:  {peasantc}%s", live, client, msg );		
					}	
					else
					{
						if (ranksolly[client] > 60)
							FormatEx( alltext, sizeof(alltext), "%s{peonb}[{white}S{peonb}]{peonr}Peon{peonb}] {peonn}%N \x01:  {peonc}%s", live, client, msg );		
						else
							FormatEx( alltext, sizeof(alltext), "%s[Unranked] {lightgray}%N \x01:  %s", live, client, msg );
					}	
				}
			}

		/*
		Colours go in this order: brackets, rank, name, chat.
		Emperor: #000000, #525252, #3838FF, #87BBFF
		King: #AD0000, #FF3838, #F56200, #FFFF7A
		Archduke: #0000B3, #45AAF7, #3C4CA5, #FFFFFF
		Lord: #005200, #009900, #626262, #FFFFFF
		Duke: #ACA287, #645456, #E85265, #FFFFFF
		Prince: #2E6994, #00FFCC, #45AAF7, #FFFFFF
		Earl: #292626, #7D7777, #E8E5E5, #FFFFFF
		Sir: #BD5C00, #EC3E00, #FFFFFF, #FFFFFF
		Count: #059605, #54AB31, #FFFFFF, #FFFFFF
		Baron: #35B7EA, #C567E0, #FFFFFF, #FFFFFF
		Knight: #FF8A8A, #D91818, #FFFFFF, #FFFFFF
		Noble: #9EA5CB, #9477D4, #FFFFFF, #FFFFFF
		Esquire: #A9B6B3, #45AAF7, #FFFFFF, #FFFFFF
		Jester: #C5B1A3, #3EBBA0, #FFFFFF, #FFFFFF
		Plebeian: #C2C2A6, #66924C, #FFFFFF, #FFFFFF
		Peasant: #B9B3B3, #AFE06C, #FFFFFF, #FFFFFF
		Peon: #A6A6A6, #EFDA3F, #FFFFFF, #FFFFFF
	*/	
		switch ( rankdemo[client] )
			{
				case 1 : 
				{
					FormatEx( alltext2, sizeof(alltext2), "%s{1}[{white}D{1}]{2}Emperor{1}] {3}%N \x01:  {4}%s", live, client, msg );
				}
				case 2 : 
				{
					FormatEx( alltext2, sizeof(alltext2), "%s{5}[{white}D{5}]{6}King{5}] {7}%N \x01:  {8}%s", live, client, msg );
				}
				case 3 : 
				{
					FormatEx( alltext2, sizeof(alltext2), "%s{9}[{white}D{9}]{10}Archduke{9}] {11}%N \x01:  {12}%s", live, client, msg );
				}
				case 4 : 
				{
					FormatEx( alltext2, sizeof(alltext2), "%s{13}[{white}D{13}]{14}Gay-Lord{13}] {15}%N \x01:  {12}%s", live, client, msg );
				}
				case 5 : 
				{
					FormatEx( alltext2, sizeof(alltext2), "%s{16}[{white}D{16}]{17}Duke{16}] {18}%N \x01:  {12}%s", live, client, msg );
				}
				default :
				{
					if (6 <= rankdemo[client] <= 10 )
					{
						if (rankdemo[client] == 6)
							FormatEx( alltext2, sizeof(alltext2), "%s{19}[{white}D{19}]{20}Prince I{19}] {10}%N \x01:  {12}%s", live, client, msg );
						else if (rankdemo[client] == 7)
							FormatEx( alltext2, sizeof(alltext2), "%s{19}[{white}D{19}]{20}Prince II{19}] {10}%N \x01:  {12}%s", live, client, msg );
						else if (rankdemo[client] == 8)
							FormatEx( alltext2, sizeof(alltext2), "%s{19}[{white}D{19}]{20}Prince III{19}] {10}%N \x01:  {12}%s", live, client, msg );
						else if (rankdemo[client] == 9)
							FormatEx( alltext2, sizeof(alltext2), "%s{19}[{white}D{19}]{20}Prince IV{19}] {10}%N \x01:  {12}%s", live, client, msg );
						else if (rankdemo[client] == 10)
							FormatEx( alltext2, sizeof(alltext2), "%s{19}[{white}D{19}]{20}Prince V{19}] {10}%N \x01:  {12}%s", live, client, msg );		
					}
					else if ( 11 <= rankdemo[client] <= 15 )
					{
						if (rankdemo[client] == 11)
							FormatEx( alltext2, sizeof(alltext2), "%s{21}[{white}D{21}]{22}Earl I{21}] {23}%N \x01:  {12}%s", live, client, msg );
						else if (rankdemo[client] == 12)
							FormatEx( alltext2, sizeof(alltext2), "%s{21}[{white}D{21}]{22}Earl II{21}] {23}%N \x01:  {12}%s", live, client, msg );
						else if (rankdemo[client] == 13)
							FormatEx( alltext2, sizeof(alltext2), "%s{21}[{white}D{21}]{22}Earl III{21}] {23}%N \x01:  {12}%s", live, client, msg );
						else if (rankdemo[client] == 14)
							FormatEx( alltext2, sizeof(alltext2), "%s{21}[{white}D{21}]{22}Earl IV{21}] {23}%N \x01:  {12}%s", live, client, msg );
						else if (rankdemo[client] == 15)
							FormatEx( alltext2, sizeof(alltext2), "%s{21}[{white}D{21}]{22}Earl V{21}] {23}%N \x01:  {12}%s", live, client, msg );		
					}
					else if ( 16 <= rankdemo[client] <= 20 )
					{
						if (rankdemo[client] == 16)
							FormatEx( alltext2, sizeof(alltext2), "%s{sirb}[{white}D{sirb}]{sirr}Sir I{sirb}] {sirn}%N \x01:  {sirc}%s", live, client, msg );	
						else if (rankdemo[client] == 17)
							FormatEx( alltext2, sizeof(alltext2), "%s{sirb}[{white}D{sirb}]{sirr}Sir II{sirb}] {sirn}%N \x01:  {sirc}%s", live, client, msg );	
						else if (rankdemo[client] == 18)
							FormatEx( alltext2, sizeof(alltext2), "%s{sirb}[{white}D{sirb}]{sirr}Sir III{sirb}] {sirn}%N \x01:  {sirc}%s", live, client, msg );	
						else if (rankdemo[client] == 19)
							FormatEx( alltext2, sizeof(alltext2), "%s{sirb}[{white}D{sirb}]{sirr}Sir IV{sirb}] {sirn}%N \x01:  {sirc}%s", live, client, msg );	
						else if (rankdemo[client] == 20)
							FormatEx( alltext2, sizeof(alltext2), "%s{sirb}[{white}D{sirb}]{sirr}Sir V{sirb}] {sirn}%N \x01:  {sirc}%s", live, client, msg );		
					}
					else if ( 21 <= rankdemo[client] <= 25 )
					{
						if (rankdemo[client] == 21)
							FormatEx( alltext2, sizeof(alltext2), "%s{countb}[{white}D{countb}]{countr}Count I{countb}] {countn}%N \x01:  {countc}%s", live, client, msg );	
						else if (rankdemo[client] == 22)
							FormatEx( alltext2, sizeof(alltext2), "%s{countb}[{white}D{countb}]{countr}Count II{countb}] {countn}%N \x01:  {countc}%s", live, client, msg );	
						else if (rankdemo[client] == 23)
							FormatEx( alltext2, sizeof(alltext2), "%s{countb}[{white}D{countb}]{countr}Count III{countb}] {countn}%N \x01:  {countc}%s", live, client, msg );	
						else if (rankdemo[client] == 24)
							FormatEx( alltext2, sizeof(alltext2), "%s{countb}[{white}D{countb}]{countr}Count IV{countb}] {countn}%N \x01:  {countc}%s", live, client, msg );	
						else if (rankdemo[client] == 25)
							FormatEx( alltext2, sizeof(alltext2), "%s{countb}[{white}D{countb}]{countr}Count V{countb}] {countn}%N \x01:  {countc}%s", live, client, msg );		
					}
					else if ( 26 <= ranksolly[client] <= 30 )
					{
						if (rankdemo[client] == 26)
							FormatEx( alltext2, sizeof(alltext2), "%s{baronb}[{white}D{baronb}]{baronr}Baron I{baronb}] {baronn}%N \x01:  {baronc}%s", live, client, msg );	
						else if (rankdemo[client] == 27)
							FormatEx( alltext2, sizeof(alltext2), "%s{baronb}[{white}D{baronb}]{baronr}Baron II{baronb}] {baronn}%N \x01:  {baronc}%s", live, client, msg );	
						else if (rankdemo[client] == 28)
							FormatEx( alltext2, sizeof(alltext2), "%s{baronb}[{white}D{baronb}]{baronr}Baron III{baronb}] {baronn}%N \x01:  {baronc}%s", live, client, msg );	
						else if (rankdemo[client] == 29)
							FormatEx( alltext2, sizeof(alltext2), "%s{baronb}[{white}D{baronb}]{baronr}Baron IV{baronb}] {baronn}%N \x01:  {baronc}%s", live, client, msg );	
						else if (rankdemo[client] == 30)
							FormatEx( alltext2, sizeof(alltext2), "%s{baronb}[{white}D{baronb}]{baronr}Baron V{baronb}] {baronn}%N \x01:  {baronc}%s", live, client, msg );		
					}
					else if ( 31 <= rankdemo[client] <= 35 )
					{
						if (rankdemo[client] == 31)
							FormatEx( alltext2, sizeof(alltext2), "%s{knightb}[{white}D{knightb}]{knightr}Knight I{knightb}] {knightn}%N \x01:  {knightc}%s", live, client, msg );	
						else if (rankdemo[client] == 32)
							FormatEx( alltext2, sizeof(alltext2), "%s{knightb}[{white}D{knightb}]{knightr}Knight II{knightb}] {knightn}%N \x01:  {knightc}%s", live, client, msg );
						else if (rankdemo[client] == 33)
							FormatEx( alltext2, sizeof(alltext2), "%s{knightb}[{white}D{knightb}]{knightr}Knight III{knightb}] {knightn}%N \x01:  {knightc}%s", live, client, msg );	
						else if (rankdemo[client] == 34)
							FormatEx( alltext2, sizeof(alltext2), "%s{knightb}[{white}D{knightb}]{knightr}Knight IV{knightb}] {knightn}%N \x01:  {knightc}%s", live, client, msg );	
						else if (rankdemo[client] == 35)
							FormatEx( alltext2, sizeof(alltext2), "%s{knightb}[{white}D{knightb}]{knightr}Knight V{knightb}] {knightn}%N \x01:  {knightc}%s", live, client, msg );		
					}
					else if ( 36 <= rankdemo[client] <= 40 )
					{
						if (rankdemo[client] == 36)
							FormatEx( alltext2, sizeof(alltext2), "%s{nobleb}[{white}D{nobleb}]{nobler}Noble I{nobleb}] {noblen}%N \x01:  {noblec}%s", live, client, msg );	
						else if (rankdemo[client] == 37)
							FormatEx( alltext2, sizeof(alltext2), "%s{nobleb}[{white}D{nobleb}]{nobler}Noble II{nobleb}] {noblen}%N \x01:  {noblec}%s", live, client, msg );		
						else if (rankdemo[client] == 38)
							FormatEx( alltext2, sizeof(alltext2), "%s{nobleb}[{white}D{nobleb}]{nobler}Noble III{nobleb}] {noblen}%N \x01:  {noblec}%s", live, client, msg );	
						else if (rankdemo[client] == 39)
							FormatEx( alltext2, sizeof(alltext2), "%s{nobleb}[{white}D{nobleb}]{nobler}Noble IV{nobleb}] {noblen}%N \x01:  {noblec}%s", live, client, msg );		
						else if (rankdemo[client] == 40)
							FormatEx( alltext2, sizeof(alltext2), "%s{nobleb}[{white}D{nobleb}]{nobler}Noble V{nobleb}] {noblen}%N \x01:  {noblec}%s", live, client, msg );		
					}
					else if ( 41 <= rankdemo[client] <= 45 )
					{
						if (rankdemo[client] == 41)
							FormatEx( alltext2, sizeof(alltext2), "%s{esquireb}[{white}D{esquireb}]{esquirer}Esquire I{esquireb}] {esquiren}%N \x01:  {esquirec}%s", live, client, msg );	
						else if (rankdemo[client] == 42)
							FormatEx( alltext2, sizeof(alltext2), "%s{esquireb}[{white}D{esquireb}]{esquirer}Esquire II{esquireb}] {esquiren}%N \x01:  {esquirec}%s", live, client, msg );		
						else if (rankdemo[client] == 43)
							FormatEx( alltext2, sizeof(alltext2), "%s{esquireb}[{white}D{esquireb}]{esquirer}Esquire III{esquireb}] {esquiren}%N \x01:  {esquirec}%s", live, client, msg );		
						else if (rankdemo[client] == 44)
							FormatEx( alltext2, sizeof(alltext2), "%s{esquireb}[{white}D{esquireb}]{esquirer}Esquire IV{esquireb}] {esquiren}%N \x01:  {esquirec}%s", live, client, msg );	
						else if (rankdemo[client] == 45)
							FormatEx( alltext2, sizeof(alltext2), "%s{esquireb}[{white}D{esquireb}]{esquirer}Esquire V{esquireb}] {esquiren}%N \x01:  {esquirec}%s", live, client, msg );		
					}
					else if ( 46 <= rankdemo[client] <= 50 )
					{
						if (rankdemo[client] == 46)
							FormatEx( alltext2, sizeof(alltext2), "%s{jesterb}[{white}D{jesterb}]{jesterr}Jester I{jesterb}] {jestern}%N \x01:  {jesterc}%s", live, client, msg );	
						else if (rankdemo[client] == 47)
							FormatEx( alltext2, sizeof(alltext2), "%s{jesterb}[{white}D{jesterb}]{jesterr}Jester II{jesterb}] {jestern}%N \x01:  {jesterc}%s", live, client, msg );
						else if (rankdemo[client] == 48)
							FormatEx( alltext2, sizeof(alltext2), "%s{jesterb}[{white}D{jesterb}]{jesterr}Jester III{jesterb}] {jestern}%N \x01:  {jesterc}%s", live, client, msg );	
						else if (rankdemo[client] == 49)
							FormatEx( alltext2, sizeof(alltext2), "%s{jesterb}[{white}D{jesterb}]{jesterr}Jester IV{jesterb}] {jestern}%N \x01:  {jesterc}%s", live, client, msg );
						else if (rankdemo[client] == 50)
							FormatEx( alltext2, sizeof(alltext2), "%s{jesterb}[{white}D{jesterb}]{jesterr}Jester V{jesterb}] {jestern}%N \x01:  {jesterc}%s", live, client, msg );
					}
					else if ( 51 <= rankdemo[client] <= 55 )
					{
						if (rankdemo[client] == 51)
							FormatEx( alltext2, sizeof(alltext2), "%s{plebeianb}[{white}D{plebeianb}]{plebeianr}Plebeian I{plebeianb}] {plebeiann}%N \x01:  {plebeianc}%s", live, client, msg );	
						else if (rankdemo[client] == 52)
							FormatEx( alltext2, sizeof(alltext2), "%s{plebeianb}[{white}D{plebeianb}]{plebeianr}Plebeian II{plebeianb}] {plebeiann}%N \x01:  {plebeianc}%s", live, client, msg );
						else if (rankdemo[client] == 53)
							FormatEx( alltext2, sizeof(alltext2), "%s{plebeianb}[{white}D{plebeianb}]{plebeianr}Plebeian III{plebeianb}] {plebeiann}%N \x01:  {plebeianc}%s", live, client, msg );	
						else if (rankdemo[client] == 54)
							FormatEx( alltext2, sizeof(alltext2), "%s{plebeianb}[{white}D{plebeianb}]{plebeianr}Plebeian IV{plebeianb}] {plebeiann}%N \x01:  {plebeianc}%s", live, client, msg );	
						else if (rankdemo[client] == 55)
							FormatEx( alltext2, sizeof(alltext2), "%s{plebeianb}[{white}D{plebeianb}]{plebeianr}Plebeian V{plebeianb}] {plebeiann}%N \x01:  {plebeianc}%s", live, client, msg );
					}
					else if ( 56 <= rankdemo[client] <= 60 )
					{
						if (rankdemo[client] == 56)
							FormatEx( alltext2, sizeof(alltext2), "%s{peasantb}[{white}D{peasantb}]{peasantr}Peasant I{peasantb}] {peasantn}%N \x01:  {peasantc}%s", live, client, msg );	
						else if (rankdemo[client] == 57)
							FormatEx( alltext2, sizeof(alltext2), "%s{peasantb}[{white}D{peasantb}]{peasantr}Peasant II{peasantb}] {peasantn}%N \x01:  {peasantc}%s", live, client, msg );
						else if (rankdemo[client] == 58)
							FormatEx( alltext2, sizeof(alltext2), "%s{peasantb}[{white}D{peasantb}]{peasantr}Peasant III{peasantb}] {peasantn}%N \x01:  {peasantc}%s", live, client, msg );	
						else if (rankdemo[client] == 59)
							FormatEx( alltext2, sizeof(alltext2), "%s{peasantb}[{white}D{peasantb}]{peasantr}Peasant IV{peasantb}] {peasantn}%N \x01:  {peasantc}%s", live, client, msg );
						else if (rankdemo[client] == 60)
							FormatEx( alltext2, sizeof(alltext2), "%s{peasantb}[{white}D{peasantb}]{peasantr}Peasant V{peasantb}] {peasantn}%N \x01:  {peasantc}%s", live, client, msg );		
					}	
					else
					{
						if (rankdemo[client] > 60)
							FormatEx( alltext2, sizeof(alltext2), "%s{peonb}[{white}D{peonb}]{peonr}Peon{peonb}] {peonn}%N \x01:  {peonc}%s", live, client, msg );		
						else
							FormatEx( alltext2, sizeof(alltext2), "%s[Unranked] {lightgray}%N \x01:  %s", live, client, msg );
					}
				}
			}	
		

	/*
		Colours go in this order: brackets, rank, name, chat.
		Emperor: #000000, #525252, #3838FF, #87BBFF
		King: #AD0000, #FF3838, #F56200, #FFFF7A
		Archduke: #0000B3, #45AAF7, #3C4CA5, #FFFFFF
		Lord: #005200, #009900, #626262, #FFFFFF
		Duke: #ACA287, #645456, #E85265, #FFFFFF
		Prince: #2E6994, #00FFCC, #45AAF7, #FFFFFF
		Earl: #292626, #7D7777, #E8E5E5, #FFFFFF
		Sir: #BD5C00, #EC3E00, #FFFFFF, #FFFFFF
		Count: #059605, #54AB31, #FFFFFF, #FFFFFF
		Baron: #35B7EA, #C567E0, #FFFFFF, #FFFFFF
		Knight: #FF8A8A, #D91818, #FFFFFF, #FFFFFF
		Noble: #9EA5CB, #9477D4, #FFFFFF, #FFFFFF
		Esquire: #A9B6B3, #45AAF7, #FFFFFF, #FFFFFF
		Jester: #C5B1A3, #3EBBA0, #FFFFFF, #FFFFFF
		Plebeian: #C2C2A6, #66924C, #FFFFFF, #FFFFFF
		Peasant: #B9B3B3, #AFE06C, #FFFFFF, #FFFFFF
		Peon: #A6A6A6, #EFDA3F, #FFFFFF, #FFFFFF
	*/	
			
		for (int i = 1; i <= MaxClients; i++)
		{
			if (IsClientConnected(i) && IsClientInGame(i) && !(g_fClientHideFlags[i] & HIDEHUD_CHAT))
			{
				if (g_fClientHideFlags[client] & HIDEHUD_CHATRANKSOLLY)
				{
					CPrintToChat(i, alltext);
				}
				else if (g_fClientHideFlags[client] & HIDEHUD_CHATRANKDEMO)
				{
					CPrintToChat(i, alltext2);
				}
				else
				{
					if (ranksolly[client] > 0 && rankdemo[client] <= 0)
						CPrintToChat(i, alltext);
					else if (rankdemo[client] > 0 && ranksolly[client] <= 0)
						CPrintToChat(i, alltext2);
					else if (rankdemo[client] >= ranksolly[client] && ranksolly[client] > 0)
						CPrintToChat(i, alltext);
					else if (ranksolly[client] > rankdemo[client] && rankdemo[client] > 0)
						CPrintToChat(i, alltext2);
					else
						CPrintToChat(i, alltext);	
				}
			}
		}
	
	PrintToServer( "%N :  %s", client, msg );

	if((msg[0] == '!') || (msg[0] == '/'))
	{
		if ( IsCharUpper(msg[1]) || IsCharUpper(msg[2]) || IsCharUpper(msg[3]) || IsCharUpper(msg[4]) )
		{
			for(int i = 0; i <= strlen(msg); ++i)
			{
				msg[i] = CharToLower(msg[i]);
			}
			msg[0] = '_';
			FakeClientCommand(client, "sm%s", msg);
		}
	}

	return Plugin_Handled;
}

public void SayText2(int client, int author, const char[] message)
{
	Handle hBuffer = StartMessageOne("SayText2", client);
	BfWriteByte(hBuffer, author);
	BfWriteByte(hBuffer, true);
	BfWriteString(hBuffer, "");
	EndMessage();
}

public Action Listener_Kill( int client, const char[] szCommand, int argc )
{
	if ( client && IsClientInGame( client ) && IsPlayerAlive( client ) )
	{
		FakeClientCommand( client, "sm_spec" );
	}
	
	return Plugin_Handled;
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
				if (g_iClientRun[client] != RUN_MAIN)
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
	
	TeleportEntity( ent, g_vecSkipPos, g_vecSkipAngles, g_vecNull );
}

public void Event_StartTouchPost_CheckPoint( int trigger, int ent )
{
	if ( ent < 1 || ent > MaxClients ) return;
	
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

	if (g_fClientHideFlags[ent] & HIDEHUD_PRTIME)
	{
		flBestTime = f_CpPr[ent][g_iClientMode[ent]][id];
	}
	else
	{
		flBestTime = g_hCPs.Get( cp, CP_INDEX_RECTIME + ( NUM_STYLES * g_iClientMode[ent] + g_iClientStyle[ent] ) );
	}
		
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