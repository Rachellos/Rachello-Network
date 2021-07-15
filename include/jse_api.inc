#if defined _JSE_API_included
 #endinput
#endif
#define _JSE_API_included

#include <sourcemod>

public SharedPlugin __pl_jse_api = 
{
	name = "jse_api",
	file = "jse_api.smx",
#if defined REQUIRE_PLUGIN
	required = 1,
#else
	required = 0,
#endif
};


#if !defined REQUIRE_PLUGIN
public void __pl_jse_api_SetNTVOptional()
{
	MarkNativeAsOptional("fetchMapsInfo");
}
#endif

typedef OnMapInfoReceived = function void(ArrayList hMapInfoList, int iCaller);

native void fetchMapsInfo(ArrayList hMapList, int iCaller, OnMapInfoReceived iCallback, bool bExact = false, bool bWP = false);

stock void fetchMapInfo(char sMapName[32], int iCaller, OnMapInfoReceived iCallback, bool bExact = false, bool bWP = false) {
	ArrayList hMapList = new ArrayList(ByteCountToCells(32));
	hMapList.PushString(sMapName);
	fetchMapsInfo(hMapList, iCaller, iCallback, bExact, bWP);
}

stock void deleteMapInfo(StringMap &hMapInfo) {
	if (hMapInfo != null) {
		StringMap hAuthors;
		hMapInfo.GetValue("authors", hAuthors);
		delete hAuthors;
		delete hMapInfo;
		hMapInfo = null;
	}
}

stock void deleteMapInfoList(ArrayList &hMapInfoList) {
	for (int i = 0; i < hMapInfoList.Length; i++) {
		StringMap hMapInfo = view_as<StringMap>(hMapInfoList.Get(i));
		deleteMapInfo(hMapInfo);
	}
	
	delete hMapInfoList;
	hMapInfoList = null;
}