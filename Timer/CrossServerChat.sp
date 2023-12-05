char IRC_ServerIp[60];
int IRC_ServerPort;
bool isMasterServer = false;

public void GuildList(DiscordBot bot, char[] id, char[] name, char[] icon, bool owner, int permissions, any data)
{
	bot.GetGuildChannels(id, ChannelList);
}

public void ChannelList(DiscordBot bot, char[] guild, DiscordChannel Channel, any data)
{
	//Verify that the channel is a text channel
	if(Channel.IsText) {
		char name[32];
		Channel.GetName(name, sizeof(name));
		
		//Compare name of channel to 'cross-server'
		if( StrEqual(name, "cross-server", false) )
		{
			PrintToServer("Added Cross Server Channel");
			
			dBot.StartListeningToChannel(Channel, OnMessage);
			Channel.GetID(sIRC_Channel, sizeof(sIRC_Channel));
		}

		if( StrEqual(name, "server-actions", false) )
		{
			PrintToServer("Added actions Channel");
			
			Channel.GetID(sActions_Channel, sizeof(sActions_Channel));
		}

		if( StrEqual(name, "chat-logs", false) )
		{
			PrintToServer("Added chat logs Channel");
			
			Channel.GetID(sChatLogs_Channel, sizeof(sChatLogs_Channel));
		}

		if( StrEqual(name, "call-admin", false) )
		{
			PrintToServer("Added call admin Channel");
			
			Channel.GetID(sCallAdmin_Channel, sizeof(sCallAdmin_Channel));
		}
	}
}

public void OnMessage(DiscordBot Bot, DiscordChannel Channel, DiscordMessage hMsg)
{
	DiscordUser user = hMsg.GetAuthor();

	if (!user.IsBot())
	{
		char message[128], author[32];

		hMsg.GetContent(message, sizeof(message));
		user.GetUsername(author, sizeof(author));

		CPrintToChatAll("| {lightskyblue}(Discord) - {green}%s{grey}: %s", author, message);
	}
}

public Action CMD_SendMessage(client, args)
{
	if (args < 1)
	{
		CPrintToChat(client, CHAT_PREFIX..."Use {lightskyblue}!msg {white}<message>");
		return Plugin_Handled;
	}

	char Message[256];
	GetCmdArgString(Message, sizeof(Message));

	char finalMessage[999];
	char playerName[40];

	Format(playerName, sizeof(playerName), "%N", client); //Little hack for chat colors user
	Format(finalMessage, sizeof(finalMessage), "| {lightskyblue}(%s) - {green}%s{grey}: %s",
												ServerRegionCode,
												playerName,
												Message);
	
	char text[500];
	
	Format(text, sizeof(text), "`%s` **%N:** %s", ServerRegionCode, client, Message);

	bool bMessageSentToDiscord = false;

	if (sIRC_Channel[0])
	{
		dBot.SendMessageToChannelID(sIRC_Channel, text);

		if(StrEqual(Message, "Ping", false))
		{
			dBot.SendMessageToChannelID(sIRC_Channel, "Pong!");
		}
		bMessageSentToDiscord = true;
	}

	if (IRC_Connected)
		SocketSend(ClientSocket, finalMessage, sizeof(finalMessage));
	else
		CPrintToChat(client, CHAT_PREFIX..."IRC server is down now%s", bMessageSentToDiscord ? ", but message sent to discord" : "");
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
	PrintToServer("Sucessfully connected to IRC server !");
	//Nothing much to say...
	
	IRC_Connected = true; //Important boolean : Store the state of the connection for this server.
}

//When the client crash
public OnClientSocketError(Handle socket, const int errorType, const int errorNum, any ary)
{
	IRC_Connected = false; //Client NOT connected anymore, this is very important.
	if (SocketIsConnected(ClientSocket))
		SocketDisconnect(ClientSocket);
	CreateTimer(5.0, TimerReconnect); //Ask for the plugin to reconnect to the MCS in X seconds
}

public OnServerSocketError(Handle socket, const int errorType, const int errorNum, any ary)
{
	if (ServerSocket != INVALID_HANDLE)
		CloseHandle(ServerSocket);

	CreateMasterServer();
}

//When a client sent a message to the MCS OR the MCS sent a message to the client, and the MCS have to handle it :
public OnChildSocketReceive(Handle socket, char[] receiveData, const int dataSize, any hFile)
{
	char szQuery[500];

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

//Called when the MCS disconnect, force the client to reconnect :
public OnChildSocketDisconnected(Handle socket, any hFile)
{
	PrintToServer("Lost connection to IRC server, reconnecting...");
	if (SocketIsConnected(ClientSocket))
		SocketDisconnect(ClientSocket);
	IRC_Connected = false; //Very important.
	CreateTimer(20.0, TimerReconnect); //Reconnecting timer
}

stock void DisconnectFromMasterServer()
{
	SocketDisconnect(ClientSocket);
	IRC_Connected = false;
}

//Connect to the MCS
stock void ConnecToMasterServer()
{	
	IRC_Connected = false;
	char chatServerIP[60];
	SocketConnect(ClientSocket, OnClientSocketConnected, OnChildSocketReceive, OnChildSocketDisconnected, IRC_ServerIp, IRC_ServerPort);	
}

stock void CreateMasterServer()
{
	ServerSocket = SocketCreate(SOCKET_TCP, OnServerSocketError);
	ServerSocket.Bind("0.0.0.0", IRC_ServerPort);
	ServerSocket.Listen(OnSocketIncoming);
}

public void OnSocketIncoming(Handle socket, Handle newSocket, char[] remoteIP, remotePort, any arg)
{
    if(isMasterServer) //This is the job of the server, he have to handle clients :
    {
        PrintToServer("Another server connected to the chat server ! (%s:%d)", remoteIP, remotePort);
        SocketSetReceiveCallback(newSocket, OnServerChildSocketReceive);
        SocketSetDisconnectCallback(newSocket, OnServerChildSocketDisconnected);
        SocketSetErrorCallback(newSocket, OnChildSocketError);
		
		if (IRC_Connections_Array == INVALID_HANDLE)
			IRC_Connections_Array = new ArrayList();

        IRC_Connections_Array.Push(newSocket);
    }
}

//When a client sent a message to the server OR the server sent a message to the client :
public OnServerChildSocketReceive(Handle socket, char[] receiveData, const int dataSize, any hFile)
{
    PrintToServer("IRC MSG: %s", receiveData); //In any case, always print the message
    
    if(isMasterServer) //If the game server is the server, then send the message to all clients
        SendToAllClients(receiveData, dataSize, socket);
}

//When a client disconnect
public OnServerChildSocketDisconnected(Handle socket, any hFile)
{
	int index = IRC_Connections_Array.FindValue(socket);

	if (index != -1)
		IRC_Connections_Array.Erase(index);

    CloseHandle(socket);
}

//When a client crash :
public OnChildSocketError(Handle socket, const int errorType, const int errorNum, any ary)
{
    LogError("child socket error %d (errno %d)", errorType, errorNum);
	int index = IRC_Connections_Array.FindValue(socket);

	if (index != -1)
		IRC_Connections_Array.Erase(index);

    CloseHandle(socket);
}

stock void SendToAllClients(char[] finalMessage, int msgSize, Handle sender)
{
    //Loop through all clients :
    for(int i = 0; i < IRC_Connections_Array.Length; i++)
    {
        //Get client :
        Socket client = IRC_Connections_Array.Get(i);

        //If the handle to the client socket and the socket is connected, send the message :
		if(client && SocketIsConnected(client))
			SocketSend(client, finalMessage, msgSize);
    }
} 