
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

	if(isMasterServer)
	{
		SendToAllClients(finalMessage, sizeof(finalMessage), INVALID_HANDLE);

		ReplaceString(finalMessage, sizeof(finalMessage), key, ""); //Remove the key from the message
		CPrintToChatAll(finalMessage);
	}
	else
	{
		if (connected)
			SocketSend(globalClientSocket, finalMessage, sizeof(finalMessage));
	}
}

public Action OnChatMessage(&author, ArrayList recipients, char[] name, char[] message)
{
	//If the author of the message if already sending anthoer message, skip
	//This boolean is made to avoid to send 423141 the same message.
	if(!processing[author])
	{
		processing[author] = true;		
		char finalMessage[999];
		char key[20];
		char serverTag[60];
		char sendChar[2];
		char playerName[40];
		
		//Get the character to define if the message is a net message (default '+')
		GetConVarString(CVAR_SendMessageTag, sendChar, sizeof(sendChar));	
		if(FindCharInString(message, sendChar[0]) == 0) //'+' as been found, continue :
		{
			//<-------------------------------------------------------------------
			GetConVarString(CVAR_ServerTag, serverTag, sizeof(serverTag));
			GetConVarString(CVAR_MessageKey, key, sizeof(key));
			GetConVarString(CVAR_MsgFormat, finalMessage, sizeof(finalMessage));
			Format(playerName, sizeof(playerName), "%N", author); //Little hack for chat colors user
			
			ReplaceString(finalMessage, sizeof(finalMessage), SENDERNAME, playerName);
			ReplaceString(finalMessage, sizeof(finalMessage), SERVERTAG, serverTag);
			ReplaceString(finalMessage, sizeof(finalMessage), SENDERMSG, message);
			Format(finalMessage, sizeof(finalMessage), "%s%s", key, finalMessage);
			//------------------------------------------------------------------->
			
			//This block above is just to build message, could make a function but too lazy.
		
		
			if(isMasterServer) //If the this server is the MCS, then send the message to all clients
				SendToAllClients(finalMessage, sizeof(finalMessage), INVALID_HANDLE);
			else // If the this server is NOT the MCS, send it to the MCS and he will send to all other clients
				SocketSend(globalClientSocket, finalMessage, sizeof(finalMessage));
		}
		
		processing[author] = false; //Processing is done, ready for next hook
	}
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

//When someone sucessfully connected to the server :
public OnSocketIncoming(Handle socket, Handle newSocket, char[] remoteIP, remotePort, any arg)
{
	if(isMasterServer) //This is the job of the MCS, he have to handle clients :
	{
		PrintToServer("Another server connected to the chat server ! (%s:%d)", remoteIP, remotePort);

		SocketSetReceiveCallback(newSocket, OnChildSocketReceive);			//Bla bla bla, you got it.	
		SocketSetDisconnectCallback(newSocket, OnChildSocketDisconnected);	//Bla bla bla, you got it.
		SocketSetErrorCallback(newSocket, OnChildSocketError);				//Bla bla bla, you got it.
		PushArrayCell(ARRAY_Connections, newSocket); //Save the handle to the connection into a array to send futur messages
	}
}

//When the CLIENT (and not the MCS) connected to the MCS :
public OnClientSocketConnected(Handle socket, any arg)
{
	char ip[65];
	char port[6];
	GetConVarString(CVAR_MasterServerIP, ip, sizeof(ip));
	GetConVarString(CVAR_ConnectionPort, port, sizeof(port));
	
	PrintToServer("Sucessfully connected to master chat server ! (%s:%s)", ip, port);
	//Nothing much to say...
	
	connected = true; //Important boolean : Store the state of the connection for this server.
}

//When the server crash, we can't do something but wait for a admin to reload the plugin.
public OnServerSocketError(Handle socket, const int errorType, const int errorNum, any ary)
{
	if (socket != null)
	{
		CloseHandle(socket);
		socket = null;
	}
}

//When the client crash
public OnClientSocketError(Handle socket, const int errorType, const int errorNum, any ary)
{
	connected = false; //Client NOT connected anymore, this is very important.
	int index = FindValueInArray(ARRAY_Connections, socket); //Look in the array of connection to see if the clients his inside
	if(index != -1) //Of the client is inside :
	{
		RemoveFromArray(ARRAY_Connections, index); //Remove the client from connection, since he is disconnected
	}

	if (globalClientSocket != null)
	{
		CloseHandle(globalClientSocket);
		globalClientSocket = null;
	}
	CreateTimer(GetConVarFloat(CVAR_ReconnectTime), TimerReconnect); //Ask for the plugin to reconnect to the MCS in X seconds
}

//When a client sent a message to the MCS OR the MCS sent a message to the client, and the MCS have to handle it :
public OnChildSocketReceive(Handle socket, char[] receiveData, const int dataSize, any hFile)
{
	char key[20];
	GetConVarString(CVAR_MessageKey, key, sizeof(key));
	char szQuery[500];
	//If the message is coming from a client, then the server has to send it to ALL other clients :
	if(isMasterServer)
		SendToAllClients(receiveData, dataSize, socket);

	if(StrContains(receiveData, key) != -1) //The message contain the security key ?
	{
		ReplaceString(receiveData, dataSize, key, ""); //Remove the key from the message
		if(StrContains(receiveData, DISCONNECTSTR) != -1) //Is the message a quit message ?
		{
			ReplaceString(receiveData, dataSize, DISCONNECTSTR, ""); //Remove the quit string from the message
			int index = FindValueInArray(ARRAY_Connections, socket); //Look in the array of connection to see if the clients his inside
			if(index != -1) //Of the client is inside :
			{
				PrintToServer("Lost connection to %s. Removing from clients.", receiveData);
				SocketDisconnect(socket);
				RemoveFromArray(ARRAY_Connections, index); //Remove the client from connection, since he is disconnected
			}
		}
		else //The message is a simple message, print it.
		{
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
				CPrintToChatAll(receiveData);
			}
		}
	}
}

//Called when the MCS disconnect, force the client to reconnect :
public OnChildSocketDisconnected(Handle socket, any hFile)
{
	if(!isMasterServer)
	{
		PrintToServer("Lost connection to master chat server, reconnecting...");
		connected = false; //Very important.
		if (globalClientSocket != null)
		{
			CloseHandle(globalClientSocket);
			globalClientSocket = null;
		}
		CreateTimer(GetConVarFloat(CVAR_ReconnectTime), TimerReconnect); //Reconnecting timer
	}
}

//When a client crash :
public OnChildSocketError(Handle socket, const int errorType, const int errorNum, any ary)
{
	LogError("child socket error %d (errno %d)", errorType, errorNum);
	int index = FindValueInArray(ARRAY_Connections, socket); //Look in the array of connection to see if the clients his inside
	if(index != -1) //Of the client is inside :
		RemoveFromArray(ARRAY_Connections, index); //Remove the client from connection, since he is disconnected
	
	if (socket != null)
	{
		CloseHandle(socket);
		socket = INVALID_HANDLE;
	}
}

//stocks

//Stock to send a message to all clients :
stock void SendToAllClients(char[] finalMessage, int msgSize, Handle sender)
{
	//Loop through all clients :
	for(int i = 0; i < GetArraySize(ARRAY_Connections); i++)
	{
		//Get client :
		Handle clientSocket = GetArrayCell(ARRAY_Connections, i);
		SocketSend(clientSocket, finalMessage, msgSize);
	}
}

//Create the server
stock void CreateServer()
{
	if(serverSocket == INVALID_HANDLE)
	{
		serverSocket = SocketCreate(SOCKET_TCP, OnServerSocketError);
		SocketBind(serverSocket, "0.0.0.0", GetConVarInt(CVAR_ConnectionPort)); //Listen everything
		SocketListen(serverSocket, OnSocketIncoming);	
		PrintToServer("Server created succesfullly ! Waiting for clients...");
	}
}

stock void DisconnectFromMasterServer()
{
	//Build the disconnecting message
	char finalMessage[400];
	char serverName[45];
	char key[45];
	GetConVarString(CVAR_MessageKey, key, sizeof(key));
	GetConVarString(FindConVar("hostname"), serverName, sizeof(serverName));
	Format(finalMessage, sizeof(finalMessage), "%s%s%s", key, DISCONNECTSTR, serverName);
	//Send the disconnecting message
	if (globalClientSocket != null && globalClientSocket != INVALID_HANDLE)
	{
		SocketSend(globalClientSocket, finalMessage, sizeof(finalMessage));
		CloseHandle(globalClientSocket);
		globalClientSocket = null;	
	}
}

//Connect to the MCS
stock void ConnecToMasterServer()
{
	if(isMasterServer)
		return;
		
	connected = false;
	globalClientSocket = SocketCreate(SOCKET_TCP, OnClientSocketError);
	char chatServerIP[60];
	int port = GetConVarInt(CVAR_ConnectionPort);
	GetConVarString(CVAR_MasterServerIP, chatServerIP, sizeof(chatServerIP));
	SocketConnect(globalClientSocket, OnClientSocketConnected, OnChildSocketReceive, OnChildSocketDisconnected, chatServerIP, port);	
}