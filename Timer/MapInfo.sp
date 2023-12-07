#pragma semicolon 1

#define DEBUG


#undef REQUIRE_PLUGIN
#include <mapchooser>

#define Menu_MapInfoList	0
#define Menu_MapInfoIdx		1

ConVar g_hJoinMessageHold;

StringMap g_hMapInfo;
any g_aMenu[MAXPLAYERS + 1][2];


// Custom callbacks

public Action Timer_MapStartInfo(Handle hTimer) {
	int iHold = g_hJoinMessageHold.IntValue;
	if (iHold != -1) {
		for (int i = 1; i <= MaxClients; i++) {
			if (IsClientInGame(i) && !IsFakeClient(i)) {
				showMapInfoPanel(i, g_hMapInfo, iHold);
			}
		}
	}
}

public void OnMapInfoReceived2(ArrayList hMapInfoList, int iCaller) {
	if (hMapInfoList == null || !hMapInfoList.Length) {
		if (iCaller <= 0) {
			LogToGame("Tempus| No map info was found");
		} else {
			PrintToChat(iCaller, "\x04Tempus| \x01No map info was found");
		}
		
		return;
	}
	
	
	if (iCaller == -1) {
		if (hMapInfoList.Length == 1) {
			StringMap hMapInfo = view_as<StringMap>(hMapInfoList.Get(0));
			g_hMapInfo = hMapInfo;
		}
	} else {
		g_aMenu[iCaller][Menu_MapInfoList] = hMapInfoList;
		g_aMenu[iCaller][Menu_MapInfoIdx] = 0;
		
		showMapInfoPanel(iCaller);
	}
}

public Action Timer_MapChange(Handle hTimer, Handle hHandle) {
	DataPack hDataPack = view_as<DataPack>(hHandle);
	hDataPack.Reset();
	
	char sMapName[32];
	hDataPack.ReadString(sMapName, sizeof(sMapName));
	ForceChangeLevel(sMapName, "Admin forced map change");
}

// Commands

public Action cmdMapInfo(int iClient, int iArgC) {
	char sMapName[32];
	if (iArgC == 0) {
		GetCurrentMap(sMapName, sizeof(sMapName));
		g_hMapInfo.SetString("name", sMapName);
		if (g_hMapInfo == null) {
			PrintToChat(iClient, "\x04Tempus| \x01No map info was found");
			iClass = 999;
			return Plugin_Handled;
		}
		
		char sBuffer[1024];
		printMapInfo(g_hMapInfo, sBuffer, sizeof(sBuffer));
		if (iClient <= 0) {
			LogToGame(sBuffer);
		} else {
			showMapInfoPanel(iClient, g_hMapInfo);
		}
	} else {
		Regex hRegex = new Regex("[^A-Za-z0-9_\\-]");
		ArrayList hMapList = CreateArray(ByteCountToCells(32));
		for (int i = 0; i < iArgC; i++) {
			GetCmdArg(i+1, sMapName, 32);
			if (hRegex.Match(sMapName)) {
				ReplyToCommand(iClient, "\x04Tempus| \x01Ignoring invalid map substring: %s", sMapName);
			} else if (strlen(sMapName) < 3) {
				ReplyToCommand(iClient, "\x04Tempus| \x01Query string must be at least 3 characters: %s", sMapName);
			} else {
				hMapList.PushString(sMapName);
			}
		}
		
		fetchMapsInfo(hMapList, iClient, OnMapInfoReceived2);
	}
	
	return Plugin_Handled;
}

// Helpers

void TF2_GetClassName(TFClassType iClass, char[] sName, int iLength) {
  static char sClass[10][10] = {"unknown", "scout", "sniper", "soldier", "demoman", "medic", "heavy", "pyro", "spy", "engineer"};
  strcopy(sName, iLength, sClass[view_as<int>(iClass)]);
}

void printMapInfo(StringMap hMapInfo, char[] sBuffer, int iBufferLength) {
	if (hMapInfo == null) {
		return;
	}
	
	char sMapName[32];
	char sAuthorID[20];
	char sAuthorName[64];
	char sClass[32];
	char sType[32];
	int iType, iTier, iTierS, iTierD, iCourses, iJumps, iBonus;
	
	hMapInfo.GetString("name", sMapName, sizeof(sMapName));
	StringMap hAuthors;
	hMapInfo.GetValue("authors", hAuthors);
	
	if (hAuthors.Size > 0) {
		FormatEx(sBuffer, iBufferLength, "%s by", sMapName);
		
		StringMapSnapshot hAuthorIDs = hAuthors.Snapshot();
		for (int j = 0; j < hAuthorIDs.Length; j++) {
			hAuthorIDs.GetKey(j, sAuthorID, sizeof(sAuthorID));
			hAuthors.GetString(sAuthorID, sAuthorName, sizeof(sAuthorName));
			if (j < hAuthorIDs.Length - 2) {
				Format(sBuffer, iBufferLength, "%s %s,", sBuffer, sAuthorName);
			} else if (j == hAuthorIDs.Length - 1 && hAuthorIDs.Length > 1) {
				Format(sBuffer, iBufferLength, "%s and %s", sBuffer, sAuthorName);
			} else {
				Format(sBuffer, iBufferLength, "%s %s", sBuffer, sAuthorName);
			}
		}
	} else {
		FormatEx(sBuffer, iBufferLength, "%s", sMapName);
	}
	
	hMapInfo.GetValue("class", iClass);
	hMapInfo.GetValue("type", iType);
	hMapInfo.GetValue("tier_s", iTierS);
	hMapInfo.GetValue("tier_d", iTierD);
	
	TF2_GetClassName(view_as<TFClassType>(iClass), sClass, sizeof(sClass));
	
	switch (view_as<TFClassType>(iClass)) {
		case TFClass_Soldier: {
			iTier = iTierS;
		}
		case TFClass_DemoMan: {
			iTier = iTierD;
		}
		default: {
			iTier = -1;
			sClass[0] = 0;
		}
	}
	
	char sTypes[3][16] = {"freestyle ", "linear ", "Courses " };
	switch (iType) {
		case 0, 1, 2: {
			FormatEx(sType, sizeof(sType), sTypes[iType]);
		}
		default: {
			sType[0] = 0;
		}
	}
	
	if (iTier == -1) {
		if (sType[0]) {
			sType[0] = CharToUpper(sType[0]);
			Format(sBuffer, iBufferLength, "%s\n%s%s map", sBuffer, sType, sClass);
		}
	} else {
		Format(sBuffer, iBufferLength, "%s\nTier %d %s%s map", sBuffer, iTier, sType, sClass);
	}
	
	hMapInfo.GetValue("courses", iCourses);
	hMapInfo.GetValue("jumps", iJumps);
	hMapInfo.GetValue("bonus", iBonus);
	
	Format(sBuffer, iBufferLength, "%s\n  Courses: %d\n    Jumps: %d\n    Bonus: %d\n", sBuffer, iCourses, iJumps, iBonus);
}

void showMapInfoPanel(int iClient, StringMap hMapInfo = null, int iTime = 0) {
	ArrayList hMapInfoList = null;
	if (hMapInfo == null) {
		hMapInfoList = view_as<ArrayList>(g_aMenu[iClient][Menu_MapInfoList]);
		if (hMapInfoList == null)
			return;
		
		hMapInfo = hMapInfoList.Get(g_aMenu[iClient][Menu_MapInfoIdx]);
	}
	
	char sBuffer[256];
	char sAuthorID[20];
	char sAuthorName[64];
	char sClass[32];
	char sType[32];
	int iClass, iType, iTierS, iTierD, iCourses, iJumps, iBonus;
	
	printMapInfo(hMapInfo, sBuffer, sizeof(sBuffer));
	PrintToConsole(iClient, "Tempus| %s", sBuffer);
	
	hMapInfo.GetValue("class", iClass);
	hMapInfo.GetValue("type", iType);
	hMapInfo.GetValue("tier_s", iTierS);
	hMapInfo.GetValue("tier_d", iTierD);
	
	hMapInfo.GetValue("courses", iCourses);
	hMapInfo.GetValue("jumps", iJumps);
	hMapInfo.GetValue("bonus", iBonus);
	
	// Title and class
	TF2_GetClassName(view_as<TFClassType>(iClass), sClass, sizeof(sClass));
	
	char sTypes[3][16] = {"Freestyle", "Linear", "Sectional"};
	switch (iType) {
		case 0, 1, 2: {
			FormatEx(sType, sizeof(sType), sTypes[iType]);
		}
		default: {
			sType[0] = 0;
		}
	}
	
	Format(sBuffer, sizeof(sBuffer), "==");
	
	if (sType[0]) {
		Format(sBuffer, sizeof(sBuffer), "%s %s", sBuffer, sType);
	}
	
	if (sClass[0]) {
		for (int i = 0; i < strlen(sClass); i++) {
			sClass[i] = CharToUpper(sClass[i]);
		}
		
		Format(sBuffer, sizeof(sBuffer), "%s %s", sBuffer, sClass);
	}
	
	Format(sBuffer, sizeof(sBuffer), "%s map ==", sBuffer);
	
	Panel hPanel = new Panel();
	hPanel.SetTitle(sBuffer);
	
	hMapInfo.GetString("name", sBuffer, sizeof(sBuffer));
	
	int iLength = strlen(sBuffer);
	for (int i = 0; i < 14 - iLength/2; i++) {
		Format(sBuffer, sizeof(sBuffer), " %s", sBuffer);
	}
	
	hPanel.DrawText(sBuffer);
	
	// Authors
	StringMap hAuthors;
	hMapInfo.GetValue("authors", hAuthors);
	
	if (hAuthors.Size > 0) {
		FormatEx(sBuffer, sizeof(sBuffer), "by");
		
		StringMapSnapshot hAuthorIDs = hAuthors.Snapshot();
		for (int j = 0; j < hAuthorIDs.Length; j++) {
			hAuthorIDs.GetKey(j, sAuthorID, sizeof(sAuthorID));
			hAuthors.GetString(sAuthorID, sAuthorName, sizeof(sAuthorName));
			if (j < hAuthorIDs.Length - 2) {
				Format(sBuffer, sizeof(sBuffer), "%s %s,", sBuffer, sAuthorName);
			} else if (j == hAuthorIDs.Length - 1 && hAuthorIDs.Length > 1) {
				Format(sBuffer, sizeof(sBuffer), "%s and %s", sBuffer, sAuthorName);
			} else {
				Format(sBuffer, sizeof(sBuffer), "%s %s", sBuffer, sAuthorName);
			}
			
			if (strlen(sBuffer) > 14 && j < hAuthorIDs.Length - 1) {
				Format(sBuffer, sizeof(sBuffer), "%s (+%d)", sBuffer, hAuthorIDs.Length - j - 1);
				break;
			}
		}
		
		iLength = strlen(sBuffer);
		for (int i = 0; i < 14 - iLength/2; i++) {
			Format(sBuffer, sizeof(sBuffer), " %s", sBuffer);
		}
		
		hPanel.DrawText(sBuffer);
	}
	
	hPanel.DrawText(" ");
	
	// Tiers
	if (iTierS != -1 || iTierD != -1) {
		char sRoman[7][3] =  { "0", "1", "2", "3", "4", "5", "6" };
		FormatEx(sBuffer, sizeof(sBuffer), "Tier:  ");
		
		if (iTierS != -1) {
			Format(sBuffer, sizeof(sBuffer), "%sSolly %s  ", sBuffer, sRoman[iTierS]);
		}
		
		if (iTierS != -1 && iTierD != -1) {
			Format(sBuffer, sizeof(sBuffer), "%s|  ", sBuffer, sRoman[iTierD]);
		}
		
		
		if (iTierD != -1) {
			Format(sBuffer, sizeof(sBuffer), "%sDemo %s", sBuffer, sRoman[iTierD]);
		}
		
		hPanel.DrawText(sBuffer);
		hPanel.DrawText(" ");
	}
	
	if (iType != 0) {
		FormatEx(sBuffer, sizeof(sBuffer), "Courses:  %d\n  Jumps:  %d", iCourses, iJumps);
		if (iBonus > 0) {
			Format(sBuffer, sizeof(sBuffer), "%s (%d bonus)", sBuffer, iBonus);
		}
		hPanel.DrawText(sBuffer);
		hPanel.DrawText(" ");
	}


	if (hMapInfoList != null) {
		hMapInfo.GetString("name", sBuffer, sizeof(sBuffer));
		char sMapName[32];
		if (FindMap(sBuffer, sMapName, sizeof(sMapName)) != FindMap_NotFound) {
			if (GetFeatureStatus(FeatureType_Native, "NominateMap") == FeatureStatus_Available && CheckCommandAccess(iClient, "sm_nominate", 0)) {
				hPanel.CurrentKey = 1;
				hPanel.DrawItem("Nominate");
			}
			
			if (CheckCommandAccess(iClient, "", ADMFLAG_CHANGEMAP, true)) {
				hPanel.CurrentKey = 2;
				hPanel.DrawItem("Change Map");
			}
			
			hPanel.DrawText(" ");
		}

		if (g_aMenu[iClient][Menu_MapInfoIdx] > 0) {
			hPanel.CurrentKey = 8;
			hPanel.DrawItem("Previous");
		} else {
			hPanel.DrawText(" ");
		}
		
		if (g_aMenu[iClient][1] < hMapInfoList.Length-1) {
			hPanel.CurrentKey = 9;
			hPanel.DrawItem("Next");
		} else {
			hPanel.DrawText(" ");
		}
	}
	
	hPanel.CurrentKey = 10;
	
	hPanel.DrawItem("Exit", ITEMDRAW_CONTROL);
	hPanel.Send(iClient, MenuHandler_MapInfo, iTime);
}

// Menu Handlers
public int MenuHandler_MapInfo(Menu hMenu, MenuAction hAction, int iClient, int iParam) {
	ArrayList hMapInfoList = g_aMenu[iClient][Menu_MapInfoList];
	delete hMenu;
	
	if (hAction == MenuAction_End) {
		if (hMapInfoList != null) {
			deleteMapInfoList(hMapInfoList);
		}
	} else if (hAction == MenuAction_Select) {
		if (hMapInfoList != null) {
			char sMapName[32];
			StringMap hMapInfo = view_as<StringMap>(hMapInfoList.Get(g_aMenu[iClient][Menu_MapInfoIdx]));
			hMapInfo.GetString("name", sMapName, sizeof(sMapName));
			
			switch (iParam) {
				case 1: {
					ArrayList hExcludeNominateList = new ArrayList();
					GetExcludeMapList(hExcludeNominateList);
					
					if (hExcludeNominateList.FindString(sMapName) != -1) {
						PrintToChat(iClient, "\x04Tempus| \x01%t", "Map in Exclude List");
						return;
					}
					
					char sCurrentMapName[32];
					GetCurrentMap(sCurrentMapName, sizeof(sCurrentMapName));
					
					if (StrEqual(sMapName, sCurrentMapName, false)) {
						PrintToChat(iClient, "\x04Tempus| \x01%t", "Can't Nominate Current Map");
						return;
					}
					
					switch (NominateMap(sMapName, false, iClient)) {
						case Nominate_AlreadyInVote: {
							PrintToChat(iClient, "\x04Tempus| \x01%t", "Map Already In Vote", sMapName);
						}
						case Nominate_InvalidMap: {
							PrintToChat(iClient, "\x04Tempus| \x01%t", "Map was not found", sMapName);
						}
						case Nominate_VoteFull: {
							PrintToChat(iClient, "\x04Tempus| \x01%t", "Map Already Nominated", sMapName);
						}
						default: {
							char sName[MAX_NAME_LENGTH];
							GetClientName(iClient, sName, sizeof(sName));
							PrintToChatAll("\x04Tempus| \x01%t", "Map Nominated", sName, sMapName);
						}
					}
				}
				case 2: {
					DataPack hDataPack = new DataPack();
					hDataPack.WriteString(sMapName);
					CreateTimer(5.0, Timer_MapChange, hDataPack);
					PrintToChatAll("\x04Tempus| \x01%t", "Changing map", sMapName);
				}
				case 8: {
					g_aMenu[iClient][Menu_MapInfoIdx]--;
					showMapInfoPanel(iClient);
				}
				case 9: {
					g_aMenu[iClient][Menu_MapInfoIdx]++;
					showMapInfoPanel(iClient);
				}
			}
		}
	}
}