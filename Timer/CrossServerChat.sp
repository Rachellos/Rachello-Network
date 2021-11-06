public Action CMD_SendMessage(client, args)
{
	if (args < 1)
	{
		CPrintToChat(client, CHAT_PREFIX..."Use \x0750DCFF!msg {white}<message>");
		return Plugin_Handled;
	}

	char Message[256];
	GetCmdArgString(Message, sizeof(Message));

	char finalMessage[999];
	char key[20];
	char serverTag[60];
	char playerName[40];
		
	GetConVarString(CVAR_ServerTag, serverTag, sizeof(serverTag));
	GetConVarString(CVAR_MessageKey, key, sizeof(key));
	GetConVarString(CVAR_MsgFormat, finalMessage, sizeof(finalMessage));
	Format(playerName, sizeof(playerName), "%N", client); //Little hack for chat colors user
	
	ReplaceString(finalMessage, sizeof(finalMessage), SENDERNAME, playerName);
	ReplaceString(finalMessage, sizeof(finalMessage), SERVERTAG, serverTag);
	ReplaceString(finalMessage, sizeof(finalMessage), SENDERMSG, Message);
	Format(finalMessage, sizeof(finalMessage), "%s%s", key, finalMessage);
	
	char text[500];
	DiscordWebHook hook = new DiscordWebHook(WEBHOOK);
	hook.SlackMode = true;
	hook.SetUsername( "Chat" );
	Format(text, sizeof(text), "`%s` **%N:** %s", serverTag, client, Message);	
	hook.SetContent(text);
	hook.Send();
	delete hook;

	if(StrEqual(Message, "Ping", false))
	{
		hook = new DiscordWebHook(WEBHOOK);
		hook.SetUsername("Chat");
		hook.SetContent("Pong!");
		hook.Send();
		delete hook;
	}

	if (IRC_Connected)
		SocketSend(ClientSocket, finalMessage, sizeof(finalMessage));
	else
		PrintToChat(client, CHAT_PREFIX..."IRC server is down now");
}
   
//In case a client get disconnected, reconnect him every X seconds
public Action TimerReconnect(Handle tmr, any arg)
{
	ConnecToMasterServer();
}

//stocks

//Nah.
stock bool IsValidClient(client)
{
	if(client <= 0 ) return false;
	if(client > MaxClients) return false;
	if(!IsClientConnected(client)) return false;
	return IsClientInGame(client);
}

//Socket callback

//When the CLIENT (and not the MCS) connected to the MCS :
public OnClientSocketConnected(Handle socket, any arg)
{
	char ip[65];
	char port[6];
	GetConVarString(CVAR_MasterServerIP, ip, sizeof(ip));
	GetConVarString(CVAR_ConnectionPort, port, sizeof(port));
	
	PrintToServer("Sucessfully connected to IRC server ! (%s:%s)", ip, port);
	//Nothing much to say...
	
	IRC_Connected = true; //Important boolean : Store the state of the connection for this server.
}

//When the client crash
public OnClientSocketError(Handle socket, const int errorType, const int errorNum, any ary)
{
	IRC_Connected = false; //Client NOT connected anymore, this is very important.
	CreateTimer(GetConVarFloat(CVAR_ReconnectTime), TimerReconnect); //Ask for the plugin to reconnect to the MCS in X seconds
}

//When a client sent a message to the MCS OR the MCS sent a message to the client, and the MCS have to handle it :
public OnChildSocketReceive(Handle socket, char[] receiveData, const int dataSize, any hFile)
{
	char key[20];
	GetConVarString(CVAR_MessageKey, key, sizeof(key));
	char szQuery[500];

	if(StrContains(receiveData, key) != -1) //The message contain the security key ?
	{
		ReplaceString(receiveData, dataSize, key, ""); //Remove the key from the message

		//The message is a simple message, print it.
		PrintToServer(receiveData);

		if (StrContains(receiveData, "wrnotifycode") != -1)
		{
			ReplaceString(receiveData, dataSize, "wrnotifycode", "");

			CPrintToChatAll(receiveData);
			
			for (int i=0; i < NUM_RUNS; i++)
			{
				if (!g_bIsLoaded[i]) continue;
				
				for (int b=1; b < 4; b+=2)
				{
					FormatEx( szQuery, sizeof( szQuery ), "SELECT uid, run, style, mode, time, name FROM maprecs natural join plydata WHERE map = '%s' and run = %i and mode = %i order by time asc", g_szCurrentMap, i, b );
					
					g_hDatabase.Query( Threaded_Init_Records, szQuery, _, DBPrio_Normal );
				}
			}

			g_hDatabase.Format( szQuery, sizeof( szQuery ), "SELECT uid, run, id, mode, time, map FROM mapcprecs WHERE uid = (select maprecs.uid from maprecs where maprecs.map = '%s' and maprecs.run = mapcprecs.run and maprecs.mode = mapcprecs.mode order by maprecs.time ASC limit 1) and map = '%s' group by map, run, mode, id ORDER BY time ASC", g_szCurrentMap, g_szCurrentMap );
			
			g_hDatabase.Query( Threaded_Init_CP_WR_Times, szQuery, _, DBPrio_High );

			for ( int i = 1; i <= MaxClients; i++ )
			{
				if ( IsClientInGame( i ) )
				{
					if ( !(g_fClientHideFlags[i] & HIDEHUD_RECSOUNDS) )
					{
						EmitSoundToClient( i, g_szWrSoundsNo[0] );
					}
				}
			}
		}
		else if (StrContains(receiveData, "update_records") != -1)
		{
			for (int i=0; i < NUM_RUNS; i++)
			{
				if (!g_bIsLoaded[i]) continue;
				
				for (int b=1; b < 4; b+=2)
				{
					FormatEx( szQuery, sizeof( szQuery ), "SELECT uid, run, style, mode, time, name FROM maprecs natural join plydata WHERE map = '%s' and run = %i and mode = %i order by time asc", g_szCurrentMap, i, b );
					
					g_hDatabase.Query( Threaded_Init_Records, szQuery, _, DBPrio_Normal );
				}
			}

			g_hDatabase.Format( szQuery, sizeof( szQuery ), "SELECT uid, run, id, mode, time, map FROM mapcprecs WHERE uid = (select maprecs.uid from maprecs where maprecs.map = '%s' and maprecs.run = mapcprecs.run and maprecs.mode = mapcprecs.mode order by maprecs.time ASC limit 1) and map = '%s' group by map, run, mode, id ORDER BY time ASC", g_szCurrentMap, g_szCurrentMap );
			
			g_hDatabase.Query( Threaded_Init_CP_WR_Times, szQuery, _, DBPrio_High );
		}
		else
		{
			if (strlen(receiveData) > 0)
				CPrintToChatAll(receiveData);
		}
	}
}

//Called when the MCS disconnect, force the client to reconnect :
public OnChildSocketDisconnected(Handle socket, any hFile)
{
	PrintToServer("Lost connection to IRC server, reconnecting...");
	IRC_Connected = false; //Very important.
	CreateTimer(GetConVarFloat(CVAR_ReconnectTime), TimerReconnect); //Reconnecting timer
}

stock void DisconnectFromMasterServer()
{
	SocketDisconnect(ClientSocket);
	CloseHandle(ClientSocket);
}

//Connect to the MCS
stock void ConnecToMasterServer()
{	
	IRC_Connected = false;
	ClientSocket = SocketCreate(SOCKET_TCP, OnClientSocketError);
	char chatServerIP[60];
	int port = GetConVarInt(CVAR_ConnectionPort);
	GetConVarString(CVAR_MasterServerIP, chatServerIP, sizeof(chatServerIP));
	SocketConnect(ClientSocket, OnClientSocketConnected, OnChildSocketReceive, OnChildSocketDisconnected, chatServerIP, port);	
}