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

	decl String:date[64], String:map[64];
	GetCurrentMap(map, sizeof(map));

	if (!ServerOSIsLinux) {
		FormatTime(date, sizeof(date), "%Y-%m-%d_%H-%S", GetTime());
		Format(currentDemoFilename, sizeof(currentDemoFilename), "%s.dem", date);
		FormatEx(DemoUrl, sizeof(DemoUrl), "%s.dem.bz2", date);
	}
	else {
		FormatTime(date, sizeof(date), "%Y-%m-%d_%H-%M-%S", GetTime());
		Format(currentDemoFilename, sizeof(currentDemoFilename), "%s__%s.dem", date, map);
		FormatEx(DemoUrl, sizeof(DemoUrl), "%s__%s.dem.bz2", date, map);
	}
	decl String:path[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, path, sizeof(path), "recordings/%s", currentDemoFilename);
	ServerCommand("tv_record %s", path);
}

public Action Timer_CompressDemo(Handle timer, any pack) {
	ResetPack(pack);
	char query[300];
	char filename[128];
	ReadPackString(pack, filename, sizeof(filename));
	char input[PLATFORM_MAX_PATH], output[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, input, sizeof(input), "recordings/%s", filename);
	if (FileSize(input) < 10)
	{
		g_hDatabase.Format(query, sizeof(query), "UPDATE maprecs SET demo_status = %i WHERE demourl = '%s.bz2'", DEMO_ERROR, filename);
		SQL_TQuery(g_hDatabase, Threaded_Empty, query);
		CloseHandle(pack);
		return Plugin_Handled;
	}
	BuildPath(Path_SM, output, sizeof(output), "recordings/bz2/%s.bz2", filename);
	BZ2_CompressFile(input, output, 2, OnDemoCompressed, pack);
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
		SQL_TQuery(g_hDatabase, Threaded_Empty, query);

		PrintToAdmins("{red}Failed {white}compressing %s.bz2...", filename);

		return;
	}
	decl String:path[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, path, sizeof(path), "recordings\\bz2\\%s.bz2", filename);
	
	if ( FileExists(path) && FileSize(path) < 10)
	{
		g_hDatabase.Format(query, sizeof(query), "UPDATE maprecs SET demo_status = %i WHERE demourl = '%s.bz2'", DEMO_ERROR, filename);
		SQL_TQuery(g_hDatabase, Threaded_Empty, query);

		DeleteFile(path);

		BuildPath(Path_SM, path, sizeof(path), "recordings\\%s", filename);

		if (!FileExists(path) || FileSize(path) < 10)
		{
			PrintToAdmins("{red}Fatal Error{white}. The file is corrupted or deleted");
			return;
		}

		BuildPath(Path_SM, path, sizeof(path), "recordings\\%s", filename);
		pack = CreateDataPack();
		WritePackString(pack, path);
		CreateTimer(0.5, Timer_CompressDemo, pack);
		return;
	}
	g_hDatabase.Format(query, sizeof(query), "UPDATE maprecs SET demo_status = %i WHERE demourl = '%s.bz2'", DEMO_READY, filename);
	SQL_TQuery(g_hDatabase, Threaded_Empty, query);

	BuildPath(Path_SM, path, sizeof(path), "recordings\\%s", filename);
	DeleteFile(path);

	if (requested || requestedByMenu)
	{
		BuildPath(Path_SM, path, sizeof(path), "recordings\\bz2\\%s.bz2", filename);
		
		EasyFTP_UploadFile("demos", path, "/", EasyFTP_CallBack);

		if (!requestedByMenu)
			requested = false;
		else
			requestedByMenu = false;

		
		g_hDatabase.Format(query, sizeof(query), "UPDATE maprecs SET demo_status = %i WHERE demourl = '%s.bz2'", DEMO_UPLOADING, filename);
		SQL_TQuery(g_hDatabase, Threaded_Empty, query);

		PrintToAdmins("Uploading %s.bz2...", currentDemoFilename);
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
		if (!ServerOSIsLinux)
    		ReplaceString(demo, sizeof(demo), "addons\\sourcemod\\recordings\\bz2\\", "");
		else
			ReplaceString(demo, sizeof(demo), "addons/sourcemod/recordings/bz2/", "");
    	g_hDatabase.Format(query, sizeof(query), "UPDATE maprecs SET demo_status = %i WHERE demourl = '%s'", DEMO_UPLOADED, demo);
		SQL_TQuery(g_hDatabase, Threaded_Empty, query);

		if (!ServerOSIsLinux)
		{
			g_hDatabase.Format(query, sizeof(query), "UPDATE maprecs SET demourl = '%s' WHERE demourl = '%s'", sLocalFile, demo);
			SQL_TQuery(g_hDatabase, Threaded_Empty, query);
		}

        PrintToServer("Success. File %s uploaded.", sLocalFile);
		PrintToAdmins("{lightskyblue}Success. {white}Demo Uploaded!");

    } else {
        PrintToServer("Failed uploading %s.", sLocalFile);   

		PrintToAdmins("{red}ERROR {white}| Failed uploading demo");
    }
}  