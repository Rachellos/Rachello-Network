
#undef REQUIRE_EXTENSIONS
#undef REQUIRE_PLUGIN

bool g_ripext_loaded = false;
char g_mapName[64];

#define MAP_GENERAL 0
#define TOP_TIMES 1

#define SOLDIER 0
#define DEMOMAN 1

HTTPClient httpClient;

//Map info requests
char g_mapReqName[MAXPLAYERS+1][64];
char g_mapReqData[MAXPLAYERS+1][999999];

//Top time requests
char g_recordReqName[MAXPLAYERS+1][999999];
char g_recordReqData[MAXPLAYERS+1][999999];
int g_menuPage[MAXPLAYERS+1];
int g_menuClass[MAXPLAYERS+1];

//Demo requests
int g_demoTicks[MAXPLAYERS+1][2]; //start, end
int g_recordReqId[MAXPLAYERS+1];
char g_steam3IDs[MAXPLAYERS+1][32];

//Single record requests
char g_runReqData[MAXPLAYERS+1][999999];
char g_demoLink[MAXPLAYERS+1][256];
static const char g_serverNames[36][64] = {
	"Unknown",
	"Jump (AU) Beginner",
	"Jump Academy (Chicago) Advanced",
	"jump.tf (Germany) Beginner",
	"AsiaFortress.com Beginner #1",
	"jump.tf - US WEST - Advanced",
	"jump.tf (Germany) Adv #1",
	"AsiaFortress.com Advanced #1",
	"Jump Academy (Chicago) Beginners",
	"jump.tf - US WEST - Beginners",
	"Jump (AU) Advanced",
	"Unknown",
	"Unknown",
	"RG #15 (Russia)",
	"jump.tf (Germany) Adv #2",
	"Dev Server",
	"AsiaFortress.com Beginner #2",
	"AsiaFortress.com Advanced #2",
	"TF2RJWeekly US - NY - All Maps",
	"TF2RJWeekly US - NY - Rank 200 Only",
	"jump.tf (France) Rookie Maps",
	"jump.tf (France) All Maps",
	"jump.tf (France) Rank 100 Only",
	"jump.tf (France) Rank 50 Only",
	"jump.tf (South Africa) All Maps",
	"Echo Jump (Seattle, US) All Maps",
	"Jump (NZ) All Maps",
	"Jump (AU) Rank 200 Only",
	"Jump (AU) Advanced #2",
	"jump.tf (France) (Expiring Jul 11) All Maps #1",
	"jump.tf (France) (Expiring Jul 11) All Maps #2",
	"servers/jump.tf (France) (Expiring Jul 11) Rank 100 Only",
	"servers/jump.tf (France) (Expiring Jul 11) All Maps #3",
	"공식 한국 템퍼스 점프 서버 #2",
	"공식 한국 템퍼스 점프 서버 #1",
	"Finland Testing"
};




/* Map info menus */

public void UpdateMaplistByTempus()
{
	httpClient = new HTTPClient(TempusURL);
	httpClient.SetHeader("Accept", "application/json");

	char req[96];
	Format(req, sizeof(req), "api/v0/maps/list");

	httpClient.Get(req, OnGetMapListFromTempus);
}

public void OnGetMapListFromTempus(HTTPResponse response, any value) 
{
	if (response.Status != HTTPStatus_OK) {
		// Failed to retrieve object
		if(response.Status == 404) {
			PrintToServer("Maps not on Tempus",response.Status);
			return;
		}
		PrintToServer("Error %d",response.Status);
		return;
	}
	if (response.Data == null) {
		// Invalid JSON response
		PrintToServer("Invalid JSON response");
		return;
	}

	JSONArray maps = view_as<JSONArray>(response.Data);
	JSONObject map;
	char map_name[50], buffer[150];

	Transaction t = new Transaction();
	bool isTransEmpty = true;

	for (int i = 0; i < maps.Length; i++)
	{
		map = view_as<JSONObject>(maps.Get(i));
		map.GetString("name", map_name, sizeof(map_name));

		if (g_aMapListFromDB.FindString(map_name) == -1)
		{
			g_aMapListFromDB.PushString(map_name);
			FormatEx(buffer, sizeof(buffer), "INSERT INTO maplist (map) VALUES ('%s')", map_name);
			t.AddQuery(buffer);

			isTransEmpty = false;
		}	
	}

	if (!isTransEmpty)
		g_hDatabase.Execute(t, Threaded_OnMapsFromTempusUpdated);

	delete map;
	delete maps;
}

public void DisplayMapInfo( int client, int type,char m[64]) {
	for(int i = 0; i < MAXPLAYERS+1;i++) {
		if(strcmp(m, g_mapReqName[i], false) == 0) {
			//Map info has already been downloaded
			g_mapReqData[client] = g_mapReqData[i];
			g_mapReqName[client] = m;
			HandleMapRequest(client,type);
			return;
		}
	}
	g_mapReqName[client] = m;

	httpClient = new HTTPClient(TempusURL);
	httpClient.SetHeader("Accept", "application/json");

	char req[96];
	Format(req, sizeof(req), "api/v0/maps/name/%s/fullOverview",m);

	//Pass the client and the type of request to the data receiving function
	int client_type = client*2 + type;
	httpClient.Get(req, OnMapInfoReceived, client_type);
}

public void OnMapInfoReceived(HTTPResponse response, any value) 
{
	int type = value % 2;
	int client = value / 2;

	if (response.Status != HTTPStatus_OK) {
		// Failed to retrieve object
		if(response.Status == 404) {
			CPrintToChat(client,"Map not on Tempus",response.Status);
			return;
		}
		CPrintToChat(client,"Error %d",response.Status);
		return;
	}
	if (response.Data == null) {
		// Invalid JSON response
		CPrintToChat(client,"Invalid JSON response");
		return;
	}

	JSONObject mapObj = view_as<JSONObject>(response.Data);

	char d[8096];
	mapObj.ToString(d, sizeof(d));
	delete mapObj;


	//Store the map datastring
	g_mapReqData[client] = d;

	HandleMapRequest(client,type);
}

public void DisplayMapInfoFromQuery(int client,int type,char mapQuery[64]) {

	httpClient = new HTTPClient(TempusURL);
	httpClient.SetHeader("Accept", "application/json");

	char req[96];
	Format(req, sizeof(req), "api/v0/search/playersAndMaps/%s",mapQuery);

	//Pass the client and the type of request to the data receiving function
	int client_type = client*2 + type;
	httpClient.Get(req, OnMapInfoReceivedFromQuery, client_type);
}

public void OnMapInfoReceivedFromQuery(HTTPResponse response, any value) {
	int type = value % 2;
	int client = value / 2;

	if (response.Status != HTTPStatus_OK) {
		// Failed to retrieve object
		CPrintToChat(client,"Error %d",response.Status);
		return;
	}
	if (response.Data == null) {
		// Invalid JSON response
		CPrintToChat(client,"Invalid JSON response");
		return;
	}

	JSONObject qResults = view_as<JSONObject>(response.Data);
	JSONArray mResults = view_as<JSONArray>(qResults.Get("maps"));

	if(mResults.Length == 0) {
		CPrintToChat(client,"No maps found");
		delete mResults;
		delete qResults;
		return;
	}

	char mName[64];
	JSONObject m = view_as<JSONObject>(mResults.Get(0));
	m.GetString("name",mName,sizeof(mName));

	delete m;
	delete mResults;
	delete qResults;

	DisplayMapInfo(client,type,mName);
}

public void HandleMapRequest(int client, int type) {
	if(type == MAP_GENERAL) {
		DisplayMapGeneral(client);
	} else {
		Panel hPanel = new Panel();
		hPanel.DrawText( "..." );
		hPanel.Send( client, Handler_Empty, MENU_TIME_FOREVER );
		
		DisplayTopTimeMenu(client);
		delete hPanel;
	}
}

public void DisplayMapGeneral(int client) 
{

	JSONObject mapObj = JSONObject.FromString(g_mapReqData[client]);

	char name[32];
	JSONObject map_info = view_as<JSONObject>(mapObj.Get("map_info"));
	map_info.GetString("name",name,sizeof(name));
	delete map_info;

	char author[32];
	JSONArray authors = view_as<JSONArray>(mapObj.Get("authors"));
	if(authors.Length > 1) {
		author = "Multiple Authors";
	} else {
		JSONObject map_author = view_as<JSONObject>(authors.Get(0));
		map_author.GetString("name",author,sizeof(author));
		delete map_author;
	}
	delete authors;

	char s_tier[3];
	char d_tier[3];
	JSONObject tier_info = view_as<JSONObject>(mapObj.Get("tier_info"));
	Format(s_tier,sizeof(s_tier),"T%d",tier_info.GetInt("soldier"));
	Format(d_tier,sizeof(d_tier),"T%d",tier_info.GetInt("demoman"));

	delete tier_info;
	delete mapObj;

	CPrintToChatAll("\x07C8C8C8Tempus | {lightskyblue}%s \x07FFFFFFby {green}%s", name, author);
	CPrintToChatAll("\x07C8C8C8Tempus | \x07FFFFFFSolly {lightskyblue}%s \x07FFFFFF| Demo {lightskyblue}%s", s_tier, d_tier);

}






/* Top Time Menus */

public int Menu_Top(Menu menu, MenuAction action, int client, int item) {
	if (action == MenuAction_Select) {
		char info[16];
		menu.GetItem(item, info, sizeof(info));
		Panel hPanel = new Panel();
		hPanel.DrawText( "..." );
		hPanel.Send( client, Handler_Empty, MENU_TIME_FOREVER );
		
		DisplayTopTimes(client,SOLDIER,g_mapReqName[client],info,100);
		delete hPanel;
	}
}

public void DisplayTopTimeMenu(int client) {

	JSONObject mapObj = JSONObject.FromString(g_mapReqData[client]);

	JSONObject zones = view_as<JSONObject>(mapObj.Get("zone_counts"));

	char buffer[1024];

	zones.ToString(buffer,sizeof(buffer));

	int bonuses;
	int courses;

	if(StrContains(buffer,"bonus") != -1 || StrContains(buffer,"course") != -1) {

		if(StrContains(buffer,"bonus") != -1)
			bonuses = zones.GetInt("bonus");
		if(StrContains(buffer,"course") != -1)
			courses = zones.GetInt("course");

	} else {
		bonuses = 0;
		courses = 0;
	}

	delete zones;
	delete mapObj;

	Menu menu = new Menu(Menu_Top);

	menu.AddItem("map/1", "Map Run\n ");

	char info[16];
	char disp[16];

	int i;

	if(courses > 0) {
		for(i = 1; i < courses;i++) {
			Format(info,sizeof(info),"course/%d",i);
			Format(disp,sizeof(disp),"Course %d",i);
			menu.AddItem(info,disp);
		}
		Format(info,sizeof(info),"course/%d",i);
		Format(disp,sizeof(disp),"Course %d\n ",i);
		menu.AddItem(info,disp);
	}

	if(bonuses > 0) {
		for(i = 1; i < bonuses+1;i++) {
			Format(info,sizeof(info),"bonus/%d",i);
			Format(disp,sizeof(disp),"Bonus %d",i);
			menu.AddItem(info,disp);
		}
	}

	char title[64];

	Format(title,sizeof(title),"<Top Times Menu :: Soldier>\nMap: %s\n ",g_mapReqName[client]);

	menu.SetTitle(title);

	menu.Display(client,MENU_TIME_FOREVER);
}


public void DisplayTopTimes(int client,int type,char m[64],char info[16],int maxRecords) {
	char request[72];
	Format(request,sizeof(request),"%s/",m);
	StrCat(request,sizeof(request),info);
	for(int i = 0; i < MAXPLAYERS+1;i++) {
		if(strcmp(request, g_recordReqName[i], false) == 0) {
			//Record have already been downloaded
			g_recordReqData[client] = g_recordReqData[i];
			g_recordReqName[client] = request;
			DisplayRecords(client,0,type);
			return;
		}
	}
	g_recordReqName[client] = request;

	httpClient = new HTTPClient(TempusURL);
	httpClient.SetHeader("Accept", "application/json");

	char req[128];
	Format(req, sizeof(req), "api/v0/maps/name/%s/zones/typeindex/%s/records/list?limit=%d",m,info,maxRecords);

	int client_type = client*2 + type;

	httpClient.Get(req, OnTopTimesDownloaded, client_type);
}

public void OnTopTimesDownloaded(HTTPResponse response, any value) {

	int type = value % 2; //Soldier or demo times
	int client = value / 2;

	if (response.Status != HTTPStatus_OK) {
		// Failed to retrieve object
		CPrintToChat(client,"Error %d",response.Status);
		return;
	}
	if (response.Data == null) {
		// Invalid JSON response
		CPrintToChat(client,"Invalid JSON response");
		return;
	}

	JSONObject records = view_as<JSONObject>(response.Data);
	
	char d[655362];
	records.ToString(d, sizeof(d));
	delete records;

	//Store the records
	g_recordReqData[client] = d;

	DisplayRecords(client,0,type);
}



public void DisplayRecordInfo(int client, int index, int class) {
	//Show detailed information about a run
	JSONObject zoneObj = JSONObject.FromString(g_recordReqData[client]);
	JSONObject results = view_as<JSONObject>(zoneObj.Get("results"));
	delete zoneObj;
	JSONArray records;
	if(class == SOLDIER) {
		records = view_as<JSONArray>(results.Get("soldier"));
	} else {
		records = view_as<JSONArray>(results.Get("demoman"));
	}
	delete results;

	JSONObject record = view_as<JSONObject>(records.Get(index));
	delete records;

	int record_id = record.GetInt("id");

	delete record;

	DownloadSingleRecord(client,record_id);
}

public void DownloadSingleRecord(int client, int record_id) {

	g_recordReqId[client] = record_id;

	char request[72];

	httpClient = new HTTPClient(TempusURL);
	httpClient.SetHeader("Accept", "application/json");

	char req[128];
	Format(req, sizeof(req), "api/v0/records/id/%d/overview",record_id);

	httpClient.Get(req, OnSingleRecordDownloaded, client);
}

public void OnSingleRecordDownloaded(HTTPResponse response, int client) {

	if (response.Status != HTTPStatus_OK) {
		// Failed to retrieve object
		CPrintToChat(client,"Error %d",response.Status);
		return;
	}
	if (response.Data == null) {
		// Invalid JSON response
		CPrintToChat(client,"Invalid JSON response");
		return;
	}

	JSONObject record = view_as<JSONObject>(response.Data);
	
	char d[8096];
	record.ToString(d, sizeof(d));
	delete record;

	//Store the record
	g_runReqData[client] = d;

	DisplaySingleRecord(client);
}

public void DisplaySingleRecord( int client ) {


	JSONObject recordObj = JSONObject.FromString(g_runReqData[client]);

	JSONObject record = view_as<JSONObject>(recordObj.Get("record_info"));

	JSONObject player = view_as<JSONObject>(recordObj.Get("player_info"));

	char steamid32[32];
	char playerName[32];
	int player_id = record.GetInt("user_id");
	int server_id = record.GetInt("server_id");
	float duration;
	char date[20];
	char time[12];
	char playerClass[8];

	player.GetString("steamid", steamid32, sizeof(steamid32));
	player.GetString("name",playerName,sizeof(playerName));
	duration = record.GetFloat("duration");

	ConvertToSteam3ID(steamid32, g_steam3IDs[client]);

	if(record.GetInt("class") == 3) {
		playerClass = "Soldier";
	} else {
		playerClass = "Demoman";
	}

	int hours = RoundToFloor(duration / 3600);
	int minutes = RoundToFloor(duration / 60)%60;
	float seconds = duration - RoundToFloor(duration / 60)*60;

	if(hours > 0) {
		//Round to 2 decimal places
		Format(time,sizeof(time),"%2d:%02d:%05.2f",hours,minutes,seconds);
	} else if (minutes > 0) {
		//Round to 4 decimal places
		Format(time,sizeof(time),"%2d:%07.4f",minutes,seconds);
	} else {
		//Round to 6 decimal places
		Format(time,sizeof(time),"%9.6f",seconds);
	}

	FormatTime(date,sizeof(date),"%Y-%m-%d %H:%M:%S",RoundFloat(record.GetFloat("date")));

	//SID32_3 * 2 + SID32_2;

	delete record;
	delete recordObj;
	delete player;

	Panel panel = new Panel();
	char buffer[64];

	DrawPanelText(panel,"<Expanded Record Info>");
	Format(buffer,sizeof(buffer),"Player: %s",playerName);
	DrawPanelText(panel,buffer);
	Format(buffer,sizeof(buffer),"Zone: %s (%s)",g_recordReqName[client],playerClass);
	DrawPanelText(panel,buffer);
	DrawPanelText(panel," ");
	Format(buffer,sizeof(buffer),"Duration: %s",time);
	DrawPanelText(panel,buffer);
	Format(buffer,sizeof(buffer),"Date: %s (GMT +00)",date);
	DrawPanelText(panel,buffer);
	Format(buffer,sizeof(buffer),"Server: %s",g_serverNames[server_id]);
	DrawPanelText(panel,buffer);

	DrawPanelText(panel," ");
	DrawPanelItem(panel,"Open Player Menu",ITEMDRAW_DISABLED);
	DrawPanelItem(panel,"Find Demo");
	DrawPanelText(panel," ");

	panel.CurrentKey = 8;
	DrawPanelItem(panel,"[<<]");
	DrawPanelText(panel," ");
	panel.CurrentKey = 10;
	DrawPanelItem(panel,"[X]");

	SendPanelToClient(panel, client, SingleRecordHandler, MENU_TIME_FOREVER);
	CloseHandle(panel);
}

public void ConvertToSteam3ID(char[] steam32, char[] buffer) {
	//steam32 -> steam3
	int a = StringToInt(steam32[6]);
	int b = StringToInt(steam32[8]);
	char cs[16] = "";
	for (int i = 10; i < strlen(steam32); i++) {
		cs[i-10] = steam32[i];
	}
	int c = StringToInt(cs);

	int steam3 = c * 2 + b;

	Format(buffer, 32, "[U:1:%d]", steam3);
}

public int SingleRecordHandler(Menu mMenu, MenuAction action, int client, int item) {
	int page = g_menuPage[client];
	int class = g_menuClass[client];
	if (action == MenuAction_Select) {
		if(item == 1) {
			//Display player info
		} else if(item == 2) {
		//Display demo info
			DisplayDemoInfo(client);
		} else if(item == 8) {
			//Back to top times
			DisplayRecords(client, page, class);
		}
	}
}

public void DisplayDemoInfo( int client ) {

	JSONObject recordObj = JSONObject.FromString(g_runReqData[client]);

	JSONObject demo = view_as<JSONObject>(recordObj.Get("demo_info"));

	JSONObject record = view_as<JSONObject>(recordObj.Get("record_info"));

	int server_id = record.GetInt("server_id");
	int startTick = record.GetInt("demo_start_tick");
	int endTick = record.GetInt("demo_end_tick");
	bool expired = demo.GetBool("expired");
	bool deleted = demo.GetBool("deleted");
	bool srequested = demo.GetBool("requested");
	char fileName[64];
	char status[32];
	char link[256];

	demo.GetString("filename",fileName,sizeof(fileName));

	if(demo.IsNull("url")) {
		if(srequested) {
			status = "Requested";
		} else if(expired) {
			status = "Expired";
		} else if(deleted) {
			status = "Deleted";
		} else {
			status = "Ready for upload";
		}
	} else {
		status = "Uploaded";
		demo.GetString("url",link,sizeof(link));
		g_demoLink[client] = link;
		g_demoTicks[client][0] = startTick;
		g_demoTicks[client][1] = endTick;
	}

	delete record;
	delete recordObj;
	delete demo;

	Panel panel = new Panel();
	char buffer[128];

	Format(buffer,sizeof(buffer),"Demo: %s.dem",fileName);
	DrawPanelText(panel,buffer);
	Format(buffer,sizeof(buffer),"Server: %s",g_serverNames[server_id]);
	DrawPanelText(panel,buffer);
	Format(buffer,sizeof(buffer),"Start Tick: %d",startTick);
	DrawPanelText(panel,buffer);
	Format(buffer,sizeof(buffer),"End Tick: %d",endTick);
	DrawPanelText(panel,buffer);

	Format(buffer,sizeof(buffer),"Status: %s",status);
	DrawPanelText(panel,buffer);

	DrawPanelItem(panel,"Print link");

	panel.CurrentKey = 8;
	DrawPanelItem(panel,"[<<]");
	DrawPanelText(panel," ");
	panel.CurrentKey = 10;
	DrawPanelItem(panel,"[X]");

	SendPanelToClient(panel, client, DemoInfoHandler, MENU_TIME_FOREVER);
	CloseHandle(panel);
}

public int DemoInfoHandler(Menu mMenu, MenuAction action, int client, int item) {
	if (action == MenuAction_Select) {
		if(item == 1) {
			//Print demo link to client
			CPrintToChat(client,"\x07C8C8C8Tempus | {lightskyblue}%s",g_demoLink[client]);
		} else if(item == 3) {
			//Refresh panel
			DisplayDemoInfo(client);
		} else if(item == 8) {
			//Back to record info
			DisplaySingleRecord(client);
		}
	}
}


public void DisplayRecords(int client, int page, int class) {
	g_menuPage[client] = page;
	g_menuClass[client] = class;

	JSONObject zoneObj = JSONObject.FromString(g_recordReqData[client]);
	JSONObject results = view_as<JSONObject>(zoneObj.Get("results"));
	delete zoneObj;
	JSONArray records;
	if(class == SOLDIER) {
		records = view_as<JSONArray>(results.Get("soldier"));
	} else {
		records = view_as<JSONArray>(results.Get("demoman"));
	}
	delete results;

	Panel panel = new Panel();

	if(class == SOLDIER) {
		DrawPanelText(panel,"<Top Times Menu :: Soldier>");
	} else {
		DrawPanelText(panel,"<Top Times Menu :: Demoman>");
	}

	char buffer[64];

	Format(buffer,sizeof(buffer),"%s\n ",g_recordReqName[client]);

	DrawPanelText(panel,buffer);
	DrawPanelText(panel,"");

	//Get WR time
	JSONObject record = view_as<JSONObject>(records.Get(0));
	float WRTime = record.GetFloat("duration");
	delete record;

	int i = page*6;
	while(i < (page+1)*6 && i < records.Length) {
		JSONObject record = view_as<JSONObject>(records.Get(i));

		char place[8];
		Format(place,sizeof(place),"[#%d]",i+1); //[#1] , [#2] ... etc

		char time[12];
		float duration = record.GetFloat("duration");

		int hours = RoundToFloor(duration / 3600);
		int minutes = RoundToFloor(duration / 60)%60;
		float seconds = duration - RoundToFloor(duration / 60)*60;

		if(hours > 0) {
			//Round to 2 decimal places
			Format(time,sizeof(time),"%2i:%2i:%2.2f",hours,minutes,seconds);
		} 
		else
		{
			//Round to 4 decimal places
			Format(time,sizeof(time),"%2i:%2.2f",minutes,seconds);
		}

		char timeDiff[12];
		duration = duration-WRTime;

		hours = RoundToFloor(duration / 3600);
		minutes = RoundToFloor(duration / 60)%60;
		seconds = duration - RoundToFloor(duration / 60)*60;
		if(hours > 0) {
			//Round to 2 decimal places
			Format(timeDiff,sizeof(timeDiff),"+%2i:%2i:%2.3f",hours,minutes,seconds);
		}
		else
		{
			//Round to 6 decimal places
			Format(timeDiff,sizeof(timeDiff),"+%2i:%2.3f",minutes,seconds);
		}

		char playerName[16];
		record.GetString("name",playerName,sizeof(playerName));

		char itemText[50];

		Format(itemText,sizeof(itemText),"%s %s %s :: %s",place,time,timeDiff,playerName);

		i++;

		if(i == (page+1)*6 || i == records.Length) {
			//Last record on page
			Format(itemText,sizeof(itemText),"%s\n ",itemText);
		}


		DrawPanelItem(panel, itemText);

		delete record;
	}
	while(i < (page+1)*6) {
		//Number of records is not an even multiple of 6
		DrawPanelItem(panel, "", ITEMDRAW_SPACER);
		i++;
	}

	if(class == SOLDIER) {
		DrawPanelItem(panel, "[Demoman]");
	} else {
		DrawPanelItem(panel, "[Soldier]");
	}

	if(page > 0) {
		DrawPanelItem(panel, "[<]");
	} else {
		DrawPanelItem(panel, "[<<]");
	}


	if(page < (records.Length / 6)) {
		DrawPanelItem(panel, "[>]");
	} else {
		DrawPanelItem(panel, "", ITEMDRAW_SPACER);
	}

	delete records;

	DrawPanelItem(panel, "[X]");

	SendPanelToClient(panel, client, RecordsMenuHandler, MENU_TIME_FOREVER);
	CloseHandle(panel);
}

public int RecordsMenuHandler(Menu mMenu, MenuAction action, int client, int item) {
	int page = g_menuPage[client];
	int class = g_menuClass[client];
	if (action == MenuAction_Select) {
		if(item == 9) {
			//Next page
			DisplayRecords(client, page+1, class);
		} else if(item == 8) {
			//Back a page
			if(page == 0) {
				DisplayTopTimeMenu(client);
			} else {
				Panel hPanel = new Panel();
				hPanel.Send( client, Handler_Empty, MENU_TIME_FOREVER );
				DisplayRecords(client, page-1, class);
			}
		} else if(item == 7) {
			//Toggle class
			if(class == SOLDIER) {
				DisplayRecords(client, 0, DEMOMAN);
			} else {
				DisplayRecords(client, 0, SOLDIER);
			}
		} else if(item < 7) {
			//Selected a record
			DisplayRecordInfo(client,page*6 + item - 1, class);
		}
	}
}

/* Main methods */


public Action SM_MapInfo(int client, int args) {
	if (!g_ripext_loaded) {
		ReplyToCommand(client, "\x07C8C8C8Tempus | \x07FFFFFF REST in Pawn extension not loaded.");
		return Plugin_Handled;
	}
	if (!client) {
		ReplyToCommand(client, "\x07C8C8C8Tempus | \x07FFFFFF Cannot get map info from rcon");
		return Plugin_Handled;
	}
	if(!args) {
		GetCurrentMap(g_mapName, sizeof(g_mapName));
		//Pass current map

		DisplayMapInfo(client,MAP_GENERAL,g_mapName);

		return Plugin_Handled;
	}

	//Search for maps containing the substring provided
	//tempus.xyz/api/v0/search/playersAndMaps/""

	char query[64];
	GetCmdArg(1,query,sizeof(query));
	DisplayMapInfoFromQuery(client,MAP_GENERAL,query);

	return Plugin_Handled;
}

public Action SM_TopTimes(int client, int args) {
	if (!g_ripext_loaded) {
		ReplyToCommand(client, "\x07C8C8C8Tempus | \x07FFFFFF REST in Pawn extension not loaded.");
		return Plugin_Handled;
	}
	if (!client) {
		ReplyToCommand(client, "\x07C8C8C8Tempus | \x07FFFFFF Cannot get top times from rcon");
		return Plugin_Handled;
	}
	if(!args) {
		//Pass current map
		GetCurrentMap(g_mapName, sizeof(g_mapName));
		DisplayMapInfo(client,TOP_TIMES,g_mapName);

		return Plugin_Handled;
	}

	char query[64];
	GetCmdArg(1,query,sizeof(query));
	DisplayMapInfoFromQuery(client,TOP_TIMES,query);

	return Plugin_Handled;
}

public Action SM_PlayerInfo(int client, int args) {
	if (!g_ripext_loaded) {
		ReplyToCommand(client, "\x07C8C8C8Tempus | \x07FFFFFF REST in Pawn extension not loaded.");
		return Plugin_Handled;
	}
	if(!args) {
		//Pass player id

		return Plugin_Handled;
	}

	return Plugin_Handled;
}