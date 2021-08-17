Handle lockedConVars;


public OnLockedConVarChanged(Handle:convar, const String:oldValue[], const String:newValue[]) {
	decl String:name[64];
	GetConVarName(convar, name, sizeof(name));
	new requiredValue;
	GetTrieValue(lockedConVars, name, requiredValue);
	if(GetConVarInt(convar) != requiredValue) {
		PrintToServer("ConVar %s changed from required value of %i. Setting back to %i.", name, requiredValue, requiredValue);
		SetConVarInt(convar, requiredValue);
	}
}

public Action:Timer_Delay(Handle:timer) {

	decl String:time[64], String:map[64];
	FormatTime(time, sizeof(time), "%Y-%m-%d_%H-%M-%S", GetTime());
	decl String:time2[64];

	strcopy(time2, sizeof(time2), time);
	GetCurrentMap(map, sizeof(map));
	Format(currentDemoFilename, sizeof(currentDemoFilename), "%s__%s.dem", time2, map);
	decl String:path[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, path, sizeof(path), "recordings/%s", currentDemoFilename);
	ServerCommand("tv_record %s", path);
}

public Action:Timer_CompressDemo(Handle:timer, any:pack) {
	ResetPack(pack);
	char query[300];
	decl String:filename[128];
	ReadPackString(pack, filename, sizeof(filename));
	decl String:input[PLATFORM_MAX_PATH], String:output[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, input, sizeof(input), "recordings/%s", filename);
	if (FileSize(input) < 100)
	{
		g_hDatabase.Format(query, sizeof(query), "UPDATE maprecs SET demo_status = %i WHERE demourl = '%s.bz2'", DEMO_ERROR, filename);
		g_hDatabase.Query(Threaded_Empty, query);
		CloseHandle(pack);
		return Plugin_Handled;
	}
	BuildPath(Path_SM, output, sizeof(output), "recordings/bz2/%s.bz2", filename);
	BZ2_CompressFile(input, output, 2, OnDemoCompressed, pack);
}

public void FtpResponseCallback(bool success, const char[] error, System2FTPRequest request, System2FTPResponse response) {
    if (success) {
        char file[PLATFORM_MAX_PATH];
        request.GetInputFile(file, sizeof(file));

        if (strlen(file) > 0) {
            PrintToServer("Uploaded %d bytes with %d bytes / second", response.UploadSize, response.UploadSpeed);
        } else {
            PrintToServer("Downloaded %d bytes with %d bytes / second", response.DownloadSize, response.DownloadSpeed);
        }
    }
}


public OnDemoCompressed(BZ_Error:iError, String:inFile[], String:outFile[], any:pack) {
	ResetPack(pack);
	decl String:filename[128];
	decl String:query[400];
	ReadPackString(pack, filename, sizeof(filename));
	CloseHandle(pack);
	if(_:iError < 0) {
		decl String:suffix[256];
		Format(suffix, sizeof(suffix), "while compressing %s", filename);
		LogBZ2Error(iError, suffix);
		g_hDatabase.Format(query, sizeof(query), "UPDATE maprecs SET demo_status = %i WHERE demourl = '%s.bz2'", DEMO_ERROR, filename);
		g_hDatabase.Query(Threaded_Empty, query);
		for (int client = 1; client <= MaxClients; client++)
		{
			if (IsClientInGame(client) && IsClientConnected(client) && (GetUserFlagBits(client) & ADMFLAG_ROOT))
			{
				CPrintToChat(client, CHAT_PREFIX..."{red}Failed {white}compressing %s.bz2...", filename);
			}
		}
		return;
	}
	decl String:path[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, path, sizeof(path), "recordings/bz2/%s.bz2", filename);
	
	if ( FileExists(path) && FileSize(path) < 10)
	{
		g_hDatabase.Format(query, sizeof(query), "UPDATE maprecs SET demo_status = %i WHERE demourl = '%s.bz2'", DEMO_ERROR, filename);
		g_hDatabase.Query(Threaded_Empty, query);

		DeleteFile(path);

		BuildPath(Path_SM, path, sizeof(path), "recordings/%s", filename);

		if (FileExists(path) && FileSize(path) > 10)
		{
			for (int client = 1; client <= MaxClients; client++)
			{
				if (IsClientInGame(client) && IsClientConnected(client) && (GetUserFlagBits(client) & ADMFLAG_ROOT))
				{
					CPrintToChat(client, CHAT_PREFIX..."{red}An error occurred{white}. Repeat compression...");
				}
			}
		}
		else
		{
			for (int client = 1; client <= MaxClients; client++)
			{
				if (IsClientInGame(client) && IsClientConnected(client) && (GetUserFlagBits(client) & ADMFLAG_ROOT))
				{
					CPrintToChat(client, CHAT_PREFIX..."{red}Fatal Error{white}. The file is corrupted or deleted");
				}
			}
			return;
		}

		BuildPath(Path_SM, path, sizeof(path), "recordings/%s", filename);
		pack = CreateDataPack();
		WritePackString(pack, path);
		CreateTimer(0.5, Timer_CompressDemo, pack);
		return;
	}
	g_hDatabase.Format(query, sizeof(query), "UPDATE maprecs SET demo_status = %i WHERE demourl = '%s.bz2'", DEMO_READY, filename);
	g_hDatabase.Query(Threaded_Empty, query);

	

	BuildPath(Path_SM, path, sizeof(path), "recordings/%s", filename);
	DeleteFile(path);

	if (requested || requestedByMenu)
	{
		BuildPath(Path_SM, path, sizeof(path), "recordings/bz2/%s.bz2", filename);
		
		EasyFTP_UploadFile("demos", path, "/", EasyFTP_CallBack);

		if (!requestedByMenu)
			requested = false;
		else
			requestedByMenu = false;

		
		g_hDatabase.Format(query, sizeof(query), "UPDATE maprecs SET demo_status = %i WHERE demourl = '%s.bz2'", DEMO_UPLOADING, filename);
		g_hDatabase.Query(Threaded_Empty, query);
		for (int client = 1; client <= MaxClients; client++)
		{
			if (IsClientInGame(client) && IsClientConnected(client) && (GetUserFlagBits(client) & ADMFLAG_ROOT))
			{
				CPrintToChat(client, CHAT_PREFIX..."Uploading %s.bz2...", currentDemoFilename);
			}
		}
	}
}

public OnFileUploaded(const String:target[], const String:localFile[], const String:remoteFile[], errorCode, any:data) {
	if(errorCode != 0) {
		LogError("Problem uploading %s. Error code: %i", localFile, errorCode);
	}
}

public EasyFTP_CallBack(const String:sTarget[], const String:sLocalFile[], const String:sRemoteFile[], iErrorCode, any:data) 
{ 
    if(iErrorCode == 0)        // These are the cURL error codes 
    {
    	char demo[400], query[400];
    	FormatEx(demo, sizeof(demo), "%s", sLocalFile);
    	ReplaceString(demo, sizeof(demo), "addons/sourcemod/recordings/bz2/", "");
    	g_hDatabase.Format(query, sizeof(query), "UPDATE maprecs SET demo_status = %i WHERE demourl = '%s'", DEMO_UPLOADED, demo);
		g_hDatabase.Query(Threaded_Empty, query);
        PrintToServer("Success. File %s uploaded.", sLocalFile);
        for (int client = 1; client <= MaxClients; client++)
		{
			if (IsClientInGame(client) && IsClientConnected(client) && (GetUserFlagBits(client) & ADMFLAG_ROOT))
			{
				CPrintToChat(client, CHAT_PREFIX..."{lightskyblue}Success. {white}Demo Uploaded!");
			}
		}

    } else { 
        PrintToServer("Failed uploading %s.", sLocalFile);   

        for (int client = 1; client <= MaxClients; client++)
		{
			if (IsClientInGame(client) && IsClientConnected(client) && (GetUserFlagBits(client) & ADMFLAG_ROOT))
			{
				CPrintToChat(client, "{red}ERROR {white}| Failed uploading demo");
			}
		}
    }
}  