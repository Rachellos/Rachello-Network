#include <morecolors>
#include <sourcemod>
#include <nextmap>
#include <tf2>
#include <ripext>
#include <tf2_stocks>
#include <regex>
#include <geoip>
#include <sdktools>
#include <sdkhooks>
#include <basecomm>
#include <stocks>
#include <tEasyFTP>
#include <Timer_core>
#include <smlib/entities>
#include <SteamWorks>
#include <idlesystem>
#include <discord>
#include <socket>
#undef REQUIRE_PLUGIN
#include <updater>
#define UPDATE_URL    "https://raw.githubusercontent.com/Rachellos/rachellos-tempus/master/Timer-Updater.txt"
#include <tEasyFTP>
#include <unixtime_sourcemod>

#undef REQUIRE_EXTENSIONS
#include <bzip2>
#include <color_literals>

#define DEV

#define ZONE_EDIT_ADMFLAG	ADMFLAG_CHANGEMAP // Admin level that allows zone editing.
#define RECORDS_ADMFLAG		ADMFLAG_ROOT // Admin level that allows record deletion.


// Don't change things under this unless you know what you are doing!!
// -------------------------------------------------------------------

// Variadic preprocessor function doesn't actually require anything significant, it seems.

#pragma semicolon 1
//#pragma newdecls required
#pragma dynamic 645221
#pragma tabsize 0

// -----------------
// All globals here.
// -----------------


///////////////////
// MISC. DEFINES //
///////////////////
#define HIDEHUD_ZONEMSG			( 1 << 0 )
#define HIDEHUD_PRTIME			( 1 << 1 )
#define HIDEHUD_VM				( 1 << 2 )
#define HIDEHUD_PLAYERS			( 1 << 3 )
#define HIDEHUD_CENTRAL_HUD		( 1 << 4 )
#define HIDEHUD_SIDEINFO		( 1 << 5 )
#define HIDEHUD_CHAT			( 1 << 6 )
#define HIDEHUD_BOTS			( 1 << 7 )
#define HIDEHUD_SHOWZONES		( 1 << 8 )
#define HIDEHUD_SPEED			( 1 << 9 )
#define HIDEHUD_CPINFO			( 1 << 10 )
#define HIDEHUD_RECSOUNDS		( 1 << 11 )
#define HIDEHUD_STYLEFLASH		( 1 << 12 )
#define HIDEHUD_CHATRANKAUTO	( 1 << 13 )
#define HIDEHUD_CHATRANKSOLLY	( 1 << 14 )
#define HIDEHUD_CHATRANKDEMO	( 1 << 15 )
#define HIDEHUD_CHAT_AD			( 1 << 16 )
#define HIDEHUD_TEMPUSWR		( 1 << 17 )
#define HIDEHUD_TEMPUSPR		( 1 << 18 )
#define HIDEHUD_SPECTYPE		( 1 << 19 )
#define HIDEHUD_TIMEREMAINING	( 1 << 20 )
#define HIDEHUD_CLASS			( 1 << 21 )
#define HIDEHUD_PERSONALREC		( 1 << 22 )
#define HIDEHUD_WORLDREC		( 1 << 23 )
#define HIDEHUD_TIMER			( 1 << 24 )
#define HIDEHUD_FAST_HUD		( 1 << 25 )
#define HIDEHUD_RUN_NAME		( 1 << 26 )
#define HIDEHUD_MODE_NAME		( 1 << 27 )
#define HIDEHUD_CP_SPLIT		( 1 << 28 )
#define HIDEHUD_SETSTART_POS	( 1 << 29 )
#define AUTO_EXTEND_MAP_OPTION	( 1 << 30 )

// HUD flags to hide specific objects.
#define HIDE_FLAGS				3946

#define OBS_MODE_IN_EYE			4
#define OBS_MODE_ROAMING		6

// "XX:XX:XXX"
#define TIME_SIZE_DEF			15

#define FORMAT_3DECI			( 2 << 0 )
#define FORMAT_2DECI			( 2 << 1 )
#define FORMAT_DESI				( 2 << 2 )

#define TIME_INVALID			0.0

#define TIMER_UPDATE_INTERVAL	0.5 // HUD Timer.
#define ZONE_BUILD_INTERVAL		0.1
#define ZONE_WIDTH				1.0
#define ZONE_DEF_HEIGHT			128.0

// Anti-spam and warning interval
// There are commands that I do not want players to spam. Commands that use database queries, etc.
#define WARNING_INTERVAL		1.0

#define MAX_ID_LENGTH			64 // It's actually 64 in engine.
#define MAX_MAP_NAME			32

#define MATH_PI					3.14159

#define DISCONNECTSTR	"DISCONNECTMEPLSTHX"
#define SENDERNAME		"[SENDER NAME]"
#define SERVERTAG		"[SERVER TAG]"
#define SENDERMSG		"[MESSAGE]"

bool ServerOSIsLinux;

Socket ClientSocket;

Menu PrevMenu[MAXPLAYERS+1][10];

int gagState[MAXPLAYERS+1];

bool IRC_Connected;
bool requested = false;

// Zones
bool g_bIsLoaded[NUM_RUNS];

bool g_bZoneExists[NUM_REALZONES][30];
bool g_bZoneBeingBuilt[NUM_REALZONES];
float g_vecZoneMins[NUM_REALZONES][30][3];
float g_vecZoneMaxs[NUM_REALZONES][30][3];
ArrayList g_hBeams;
ArrayList g_hZones;
ArrayList g_hCPs;
ArrayList g_hMaps;

HTTPClient http;


// Building
bool isSetCustomStart[NUM_RUNS];
bool g_bStartBuilding[MAXPLAYERS+1];
int g_iBuilderZone[MAXPLAYERS+1] = { ZONE_INVALID, ... };
int g_iBuilderZoneIndex[MAXPLAYERS+1] = { -1, ... };
float g_vecBuilderStart[MAXPLAYERS+1][3];
int g_iSprite;
int rank;

// Running
int SortMethod[MAXPLAYERS+1];
char SortRun[MAXPLAYERS+1][10];
char currentDemoFilename[400];
int CpBlock[MAXPLAYERS+1];
char szWrName[NUM_RUNS][NUM_MODES][32];
PlayerState g_iClientState[MAXPLAYERS+1]; // Player's previous state (in start/end/running?)
int g_iClientRun[MAXPLAYERS+1]; // Which run client is doing (main/bonus)?
int g_iClientStyle[MAXPLAYERS+1]; // Styles W-ONLY/HSW/RHSW etc.
int g_iClientMode[MAXPLAYERS+1]; // Modes AUTO/SCROLL/VELCAP.
float g_flClientStartTime[MAXPLAYERS+1]; // When we started our run? Engine time.
int g_flTicks_Start[MAXPLAYERS+1];
int g_flTicks_End[MAXPLAYERS+1];
int g_flTicks_Cource_Start[MAXPLAYERS+1];
int g_flTicks_Cource_End[MAXPLAYERS+1];
float g_flClientCourseStartTime[MAXPLAYERS+1]; // When we started our Course? Engine time.
float flNewTimeCourse[MAXPLAYERS+1];
float g_flClientFinishTime[MAXPLAYERS+1]; // This is to tell the client's finish time in the end.
float g_flClientBestTime[MAXPLAYERS+1][NUM_RUNS][NUM_MODES];
float f_CpPr[MAXPLAYERS+1][NUM_MODES][50];
float f_CpWr[NUM_MODES][50];

int g_iClientCurCP[MAXPLAYERS+1];
ArrayList g_hClientCPData[MAXPLAYERS+1];

int ZoneIndex[MAXPLAYERS+1];

Handle TimerEye[MAXPLAYERS+1] = null;

// Misc player stuff.
float Weather_delayTime[MAXPLAYERS+1];
float ClientConnectTime[MAXPLAYERS+1];
int EnteredZone[MAXPLAYERS+1];
bool IsBuildingOnGround[MAXPLAYERS+1];
int menu_page[MAXPLAYERS+1];
int ZoneType[MAXPLAYERS+1];
char profile_map[MAXPLAYERS+1][70];
char profile_playername[MAXPLAYERS+1][70];
int profile_mode[MAXPLAYERS+1];
int Incomplete_uid[MAXPLAYERS+1];
int profile_run[MAXPLAYERS+1];
int SetCustZone[MAXPLAYERS+1];
int tier_block[MAXPLAYERS+1];
int tier_run[MAXPLAYERS+1];
int db_style[MAXPLAYERS+1];

int g_iClientIdle[MAXPLAYERS+1];

int ranksolly[MAXPLAYERS+1];
int rankdemo[MAXPLAYERS+1];
int RunPagep[MAXPLAYERS+1];
int g_iClientId[MAXPLAYERS+1]; // IMPORTANT!!
int g_tier_MapMenu[MAXPLAYERS+1];
char db_map[MAXPLAYERS+1][100];

bool isHudDrawed[MAXPLAYERS+1];
float LastHudDrawing[MAXPLAYERS+1];

float g_CustomRespawnPos[NUM_RUNS][3];
float g_CustomRespawnAng[NUM_RUNS][3];
float g_fClientRespawnPosition[MAXPLAYERS+1][3];
float g_fClientRespawnAngles[MAXPLAYERS+1][3];
float g_fClientRespawnEyes[MAXPLAYERS+1][3];
float g_fClientRespawnEyePos[MAXPLAYERS+1][3];
float g_fClientLevelPos[200][3];
float g_fClientLevelAng[200][3];
bool g_bClientSpeedometerEnabled[MAXPLAYERS+1];
float g_flClientWarning[MAXPLAYERS+1]; // Used for anti-spam.

Function Func; 

// Practice
bool g_bClientPractising[MAXPLAYERS+1];


// Client settings (bonus stuff);
int g_fClientHideFlags[MAXPLAYERS+1];
int RunClass[MAXPLAYERS+1];
int last_usage_run_type[MAXPLAYERS+1];

char DemoUrl[400];
char DemoUrlClient[MAXPLAYERS+1][500];
float points3;
int db_id[MAXPLAYERS+1];
ConVar gHostPort;
ConVar gHostname;
ConVar srv_id = null;

//To prevent spam
int LastUsage[MAXPLAYERS + 1];

Handle g_VoteTimer = null;

bool secure = false;
int iClass;
int CpPlusSplit[MAXPLAYERS+1];
char CpTimeSplit[MAXPLAYERS+1][TIME_SIZE_DEF];
bool DisplayCpTime[MAXPLAYERS+1] = { false, ... };
bool requestedByMenu = false;
char DBS_Name[32][MAXPLAYERS+1];
float szOldTime[MAXPLAYERS+1];
float szOldTimePts[MAXPLAYERS+1][NUM_RUNS][NUM_MODES];
float szOldTimeWr;
bool IsMapMode[MAXPLAYERS+1];
char szAmmo[MAXPLAYERS+1][32];
char szTimerMode[MAXPLAYERS+1][32];
char			szCPTime[TIME_SIZE_DEF];
char g_szCurrentMap[MAX_MAP_NAME];
float g_vecSpawnPos[NUM_RUNS][3];
float g_vecSpawnAngles[NUM_RUNS][3];
float g_flMapBestTime[NUM_RUNS][NUM_STYLES][NUM_MODES];
float g_TempusPrTime[MAXPLAYERS+1][NUM_RUNS][NUM_MODES];
float g_TempusWrTime[NUM_RUNS][NUM_MODES];
char sz_TempusWrName[NUM_RUNS][NUM_MODES][40];
int g_Tiers[NUM_RUNS][NUM_MODES];
int g_iBeam;
int g_iSkipMode;

float g_SavePointOrig[MAXPLAYERS+1][3];
float g_SavePointEye[MAXPLAYERS+1][3];

float g_vecSkipAngles[3], g_vecSkipPos[3]; 

bool RegenOn[MAXPLAYERS+1] = false;

int STVTickStart;
float g_iClientPoints[MAXPLAYERS+1];
float g_iClientPointsSolly[MAXPLAYERS+1];
float g_iClientPointsDemo[MAXPLAYERS+1];
float db_time[MAXPLAYERS+1];
//id, time, class
int g_iClientCpsEntered[MAXPLAYERS+1][100];
int DemoInfoId[MAXPLAYERS+1];
int szClass[NUM_RUNS][NUM_MODES];

int g_ZoneMethod[MAXPLAYERS+1];

char server_name[NUM_NAMES][][] =
{
	{
		"N/A",
	 	"RG #1488 - Finland | Rachello Network",
		"RG #1488 - London | Rachello Network",
		"RG #1488 - Australia | Rachello Network", 
		"RG #1488 - US East | Rachello Network", 
		"RG #1488 US West California | Rachello Network",
	 	"RG #1488 Asia Singapore | Rachello Network" 
	},
	{ 
		"N/A", 
		"Finland",
		"London",
		"AU", 
		"US-East", 
		"US-West", 
		"SG" 
	}
};

Handle hPlugin = INVALID_HANDLE;
int server_id=0;

enum { COMMAND, COMMAND_DESC };
char command_list[2][][] = 
{
    //commands
    {
     "!msg <text>",
     "!goto <player>", 
     "!respawn",
     "!reset", 
     "!restart",
     "!r", 
     "!re",
     "!start", 
     "!setstart",
     "!set", 
     "!clearstart",
     "!clear", 
     "!spectate",
     "!spec", 
     "!hud",
     "!settings", 
     "!mt <map>",
     "!m <map>", 
     "!mi <map>",
     "!mapinfo <map>", 
     "!maplist",
     "!ml", 
     "!maps",
     "!ttop <map>", 
     "!top <map>",
     "!ptop",
     "!pointstop",
     "!toppoints",
     "!ammo",
     "!dz",
     "!dzl",
     "!dzlist",
     "!over",
     "!time <player>",
     "!rr",
     "!resentrecords",
     "!rrb",
     "!rcc",
     "!rb",
     "!resentbroken",
	 "!broken",
     "!bonus",
     "!b <number>",
     "!c <number>",
     "!course <number>",
     "!courses <number>",
     "!timer",
     "!stime",
     "!dtime",
     "!swr",
     "!dwr",
     "!srank",
     "!drank",
     "!rank",
     "!orank",
     "!profile",
     "!p",
     "!ranks",
     "!pr",
     "!personalrecords",
     "!pts",
     "!points",
     "!saveloc",
     "!save",
     "!s",
     "!hidechat",
     "!l",
     "!lvl",
     "!level",
     "!levels",
     "!t",
     "!tp",
     "!tele",
     "!teleport",
     "!noclip",
     "!fly",
     "!commands",
     "!help",
     "!version",
     "!incomplete",
     "!calladmin",
	 "!weather",
 	},
    //DESCRIPTION
    {
     "Send a message to all server",
     "Teleport to player",
     "Teleport to start position",
     "Teleport to start position",
     "Teleport to start position",
     "Teleport to start position",
     "Teleport to start position",
     "Teleport to start position",
     "Set your custom start position",
     "Set your custom start position",
     "Remove your custom start position",
     "Remove your custom start position",
     "Go to spectate mode",
     "Go to spectate mode",
     "Open HUD settings menu",
     "Open HUD settings menu",
     "Show map info",
     "Show map info",
     "Show map info menu",
     "Show map info menu",
     "Show the map list",
     "Show the map list",
     "Show Tempus map Top Times",
     "Show map Top Times",
     "Open top players by overall points menu",
     "Open top players by overall points menu",
     "Open top players by overall points menu",
     "Toggle ammo regen",
     "Draw zone",
     "Open the zone list",
     "Open the zone list",
     "Show all overall points",
     "Show your map run time",
     "Open Recent map records menu",
     "Open Recent map records menu",
     "Open Recent bonus records menu",
     "Open Recent course records menu",
     "Open your recently lost records menu",
     "Open your recenlty lost records menu",
	 "Open your recenlty lost records menu",
     "Open bonus menu",
     "Open bonus menu",
     "Open courses menu",
     "Open courses menu",
     "Toggle timer",
     "Show yours or other player's Solly run time",
     "Show yours or other player's Demoman run time",
     "Show Solly WR",
     "Show Demoman WR",
     "Show yours or other player's Solly rank",
     "Show yours or other player's Demoman rank",
     "Show yours or other player's overall rank",
     "Show yours or other player's Profile",
     "Show yours or other player's Profile",
     "Open ranks menu",
     "Show your personal map record",
     "Show your personal map record",
     "Open map points menu",
     "Open map points menu",
     "Saving your current location",
     "Saving your current location",
     "Saving your current location",
     "Show/Hide chat",
     "Open level menu\n!level <number> - Teleport to level",
     "Open level menu\n!level <number> - Teleport to level",
     "Open level menu\n!level <number> - Teleport to level",
     "Open level menu\n!level <number> - Teleport to level",
     "Teleports you to saved location",
     "Teleports you to saved location",
     "Teleports you to saved location",
     "Teleports you to saved location",
     "Toggle noclip",
     "Toggle noclip",
     "[YOU ARE HERE]",
     "Help",
     "Show current server plugin version",
     "Show info about the server",
     "Show Solly map video",
     "Show Demoman map video",
     "Open yours or other player's incomplete maps menu",
     "Call Admin",
	 "Show Current Temp in your city",
 	}
};

int clrBeam[NUM_ZONE_COLORS][4] =
{
    { 0, 255, 0, 255 }, // GREEN_ZONE

    { 0, 255, 0, 255 }, // DEV_GREEN_ZONE
    { 255, 0, 0, 255 }, // DEV_ZONE_RED
    { 0, 0, 255, 255 }, // DEV_ZONE_BLUE
    { 255, 255, 255, 255 }, // DEV_ZONE_WHITE
    { 128, 0, 128, 255 }, // DEV_ZONE_PURPLE
};

// Constants
// Because 1.7 is bugged, you cannot const them.
char g_szZoneNames[NUM_ZONES_W_CP][32] =
{
	"Start", "End",
	"Course 1 Start", "Course 1 End",
	"Course 2 Start", "Course 2 End",
	"Course 3 Start", "Course 3 End",
	"Course 4 Start", "Course 4 End",
	"Course 5 Start", "Course 5 End",
	"Course 6 Start", "Course 6 End",
	"Course 7 Start", "Course 7 End",
	"Course 8 Start", "Course 8 End",
	"Course 9 Start", "Course 9 End",
	"Course 10 Start", "Course 10 End",
	"Bonus 1 Start", "Bonus 1 End",
	"Bonus 2 Start", "Bonus 2 End",
	"Bonus 3 Start", "Bonus 3 End",
	"Bonus 4 Start", "Bonus 4 End",
	"Bonus 5 Start", "Bonus 5 End",
	"Bonus 6 Start", "Bonus 6 End",
	"Bonus 7 Start", "Bonus 7 End",
	"Bonus 8 Start", "Bonus 8 End",
	"Bonus 9 Start", "Bonus 9 End",
	"Bonus 10 Start", "Bonus 10 End",
	"Cource teleport", "Skip level", "Block", "Checkpoint"
};

char g_szRunName[NUM_NAMES][NUM_RUNS][20] =
{
	{ "Map", "Course 1", "Course 2", "Course 3", "Course 4", "Course 5", "Course 6", "Course 7", "Course 8", "Course 9", "Course 10", "Bonus 1", "Bonus 2", "Bonus 3", "Bonus 4", "Bonus 5", "Bonus 6", "Bonus 7", "Bonus 8", "Bonus 9", "Bonus 10", "Setstart" },
	{ "M", "C1", "C2", "C3", "C4", "C5", "C6", "C7", "C8", "C9", "C10", "B1", "B2", "B3", "B4", "B5", "B6", "B7", "B8", "B9", "B10", "start" }
};

char g_szStyleName[NUM_NAMES][NUM_STYLES][16] =
{
	{ "Soldier", "Demoman"},
	{ "Solly", "Demo"}
};

char g_szModeName[NUM_NAMES][NUM_MODES2][16] =
{
	{ "", "Soldier", "", "Demoman"},
	{ "", "S", "", "D"}
};

char g_szDemoStatus[NUM_DEMO][44] =
{
	"None", "Uploaded",
	"Requested", "Ready for uploading",
	"Recording", "Uploading...",
	"Deleted", "Compression Error"
};
// First one is always the normal ending sound!
	char g_szWinningSounds[][] =
	{
		"npc/scanner/combat_scan1.wav",
	};
	
	char g_szWrSounds[][] =
	{
		"misc/killstreak.wav",
	};

	char g_szWrSoundsNo[][] =
	{
		"weapons/guitar_strum.wav",
	};

	char g_szWrSoundsBonus[][] =
	{
		"items/scout_boombox_04.wav",
	};
	char g_szSoundsCourse[][] =
	{
		"misc/freeze_cam.wav"
	};
	char g_szSoundsCourseWr[][] =
	{
		"items/spawn_item.wav"
	};
	char g_szSoundsMissCp[][] =
	{
		"player/taunt_burp.wav"
	};


float g_vecNull[3] = { 0.0, 0.0, 0.0 };

// Forwards
Handle g_hForward_Timer_OnStateChanged;

// ------------------------
// End of globals.
// ------------------------

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max) {

	MarkNativeAsOptional("ParseDemo");

	MarkNativeAsOptional("EasyFTP_UploadFile");

	MarkNativeAsOptional("JSONArray.JSONArray");
	MarkNativeAsOptional("JSONArray.Push");
	MarkNativeAsOptional("JSONArray.FromString");
	MarkNativeAsOptional("JSONArray.ToString");
	MarkNativeAsOptional("JSONArray.Length.get");
	MarkNativeAsOptional("JSONArray.Get");

	MarkNativeAsOptional("JSONObject.JSONObject");
	MarkNativeAsOptional("JSONObject.GetString");
	MarkNativeAsOptional("JSONObject.SetString");
	MarkNativeAsOptional("JSONObject.ToString");
	MarkNativeAsOptional("JSONObject.FromString");
	MarkNativeAsOptional("JSONObject.GetInt");
	MarkNativeAsOptional("JSONObject.SetInt");
	MarkNativeAsOptional("JSONObject.Get");
	MarkNativeAsOptional("JSONObject.Set");
	MarkNativeAsOptional("JSONObject.SetFloat");
	MarkNativeAsOptional("JSONObject.GetFloat");
	MarkNativeAsOptional("JSONObject.GetBool");
	MarkNativeAsOptional("JSONObject.SetBool");
	MarkNativeAsOptional("JSONObject.IsNull");

	MarkNativeAsOptional("JSON.ToString");

	MarkNativeAsOptional("HTTPClient.HTTPClient");
	MarkNativeAsOptional("HTTPClient.SetHeader");
	MarkNativeAsOptional("HTTPClient.Get");

	MarkNativeAsOptional("HTTPResponse.Status.get");
	MarkNativeAsOptional("HTTPResponse.Data.get");

	CreateNative("IsAutoExtendEnabled", Native_IsAutoExtendEnabled);

	return APLRes_Success;
}

#include "Timer/stocks.sp"
#include "Timer/usermsg.sp"
#include "Timer/database.sp"
#include "Timer/database_thread.sp"
#include "Timer/events.sp"
#include "Timer/commands.sp"
#include "Timer/commands_admin.sp"
#include "Timer/timers.sp"
#include "Timer/menus.sp"
#include "Timer/menus_admin.sp"
#include "Timer/tempuslite.sp"
#include "Timer/CrossServerChat.sp"
#include "Timer/autodemo_recorder.sp"
#include "Timer/mapchooser.sp"
#include "Timer/weather.sp"


public Plugin myinfo = // Note: must be 'myinfo'. Compiler accepts everything but only that works.
{
	author = PLUGIN_AUTHOR_CORE,
	name = PLUGIN_NAME_CORE,
	description = "Timer & ranks and more for Rachello Network",
	url = PLUGIN_URL_CORE,
	version = PLUGIN_VERSION_CORE
};

public void OnPluginEnd() {
	if (IRC_Connected)
		DisconnectFromMasterServer();

	if (secure)
	{
		PrintToServer("Ending recording of %s", currentDemoFilename);
		ServerCommand("tv_stoprecord");
		Handle pack = CreateDataPack();
		WritePackString(pack, currentDemoFilename);
		CreateTimer(1.0, Timer_CompressDemo, pack);
	}
}

public int Native_IsAutoExtendEnabled(Handle handler, int numParams)
{
	return (g_fClientHideFlags[GetNativeCell(1)] & AUTO_EXTEND_MAP_OPTION);
}

public Action Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast) {
	int userid = event.GetInt("userid");
	int client = GetClientOfUserId(userid);

	g_iClientState[client] = STATE_SETSTART;
	g_iClientRun[client] = RUN_SETSTART;
	if (TF2_GetPlayerClass(client) != TFClass_Soldier && TF2_GetPlayerClass(client) != TFClass_DemoMan)
	{
		CPrintToChat(client, CHAT_PREFIX..."Timer only works for the {lightskyblue}Soldier {white}and {lightskyblue}Demoman");
	}
	else
	{
		if (TF2_GetPlayerClass(client) == TFClass_Soldier)
		{
		    SetPlayerStyle( client, STYLE_SOLLY );
		}
		if (TF2_GetPlayerClass(client) == TFClass_DemoMan)
		{
		   SetPlayerStyle( client, STYLE_DEMOMAN );
		}
	}
	IsMapMode[client] = false;
	RespawnPlayerRun( client );
	return Plugin_Continue;
}

public Action OnClientSayCommand( int client, const char[] szCommand, const char[] text )
{
	if ( !client || BaseComm_IsClientGagged( client ) ) return Plugin_Continue;

	char sCodes[8][] = {"\x01", "\x02", "\x03", "\x04", "\x05", "\x06", "\x07", "\x08"};

	char live[10];
	char msg[200], discord_msg[256];
	char alltext[300];
	int rank;
	char class[1];

	FormatEx(msg, sizeof(msg), "%s", text);
	TrimString(msg);

	for ( int i = 0; i < 8; i++)
		ReplaceString(msg, sizeof(msg), sCodes[i], "");
	
	if (StrEqual(msg, "( ͡° ͜ʖ ͡°)") || StrEqual(msg, "( ° ͜ʖ ͡°)") || StrEqual(msg, " ( ͡° ͜ʖ ͡°)") || StrEqual(msg, "( ͡° ͜ʖ ͡°) "))
	{
		CPrintToChat(client, CHAT_PREFIX..."Fuck Lenny");
	}
	if ( !IsPlayerAlive(client) )
		FormatEx(live, sizeof(live), "* ");
	else
		FormatEx(live, sizeof(live), "");

	DiscordWebHook hook = new DiscordWebHook(CHATLOGS_WEBHOOK);
	FormatEx(discord_msg, sizeof(discord_msg), "``%s`` **%N:** %s", server_name[NAME_SHORT][server_id], client, msg);
	hook.SetUsername("Chat");
	hook.SetContent(discord_msg);
	hook.Send();
	delete hook;

	if (g_fClientHideFlags[client] & HIDEHUD_CHATRANKSOLLY)
	{
		class[0] = 'S';
		rank = ranksolly[client];
	}
	else if (g_fClientHideFlags[client] & HIDEHUD_CHATRANKDEMO)
	{
		class[0] = 'D';
		rank = rankdemo[client];
	}
	else
	{
		if (ranksolly[client] <= 0)
		{
			class[0] = 'D';
			rank = rankdemo[client];
		}
		else if (rankdemo[client] <= 0)
		{
			class[0] = 'S';
			rank = ranksolly[client];
		}
		else
		{
			if (ranksolly[client] <= rankdemo[client])
			{
				class[0] = 'S';
				rank = ranksolly[client];
			}
			else
			{
				class[0] = 'D';
				rank = rankdemo[client];
			}
		}
	}

	switch ( rank )
	{
		case 1 : 
		{
			FormatEx( alltext, sizeof(alltext), "%s{1}[{white}%s{1}]{2}Emperor{1}] {3}%N \x01:  {4}%s", live, class, client, msg );
		}
		case 2 : 
		{
			FormatEx( alltext, sizeof(alltext), "%s{5}[{white}%s{5}]{6}King{5}] {7}%N \x01:  {8}%s", live, class, client, msg );
		}
		case 3 : 
		{
			FormatEx( alltext, sizeof(alltext), "%s{9}[{white}%s{9}]{10}Archduke{9}] {11}%N \x01:  {12}%s", live, class, client, msg );
		}
		case 4 : 
		{
			FormatEx( alltext, sizeof(alltext), "%s{13}[{white}%s{13}]{14}Lord{13}] {15}%N \x01:  {12}%s", live, class, client, msg );
		}
		case 5 : 
		{
			FormatEx( alltext, sizeof(alltext), "%s{16}[{white}%s{16}]{17}Duke{16}] {18}%N \x01:  {12}%s", live, class, client, msg );
		}
		default :
		{
			if (6 <= rank <= 10 )
			{
				if (rank == 6)
					FormatEx( alltext, sizeof(alltext), "%s{19}[{white}%s{19}]{20}Prince I{19}] {10}%N \x01:  {12}%s", live, class, client, msg );
				else if (rank == 7)
					FormatEx( alltext, sizeof(alltext), "%s{19}[{white}%s{19}]{20}Prince II{19}] {10}%N \x01:  {12}%s", live, class, client, msg );
				else if (rank == 8)
					FormatEx( alltext, sizeof(alltext), "%s{19}[{white}%s{19}]{20}Prince III{19}] {10}%N \x01:  {12}%s", live, class, client, msg );
				else if (rank == 9)
					FormatEx( alltext, sizeof(alltext), "%s{19}[{white}%s{19}]{20}Prince IV{19}] {10}%N \x01:  {12}%s", live, class, client, msg );
				else if (rank == 10)
					FormatEx( alltext, sizeof(alltext), "%s{19}[{white}%s{19}]{20}Prince V{19}] {10}%N \x01:  {12}%s", live, class, client, msg );		
			}
			else if ( 11 <= rank <= 15 )
			{
				if (rank == 11)
					FormatEx( alltext, sizeof(alltext), "%s{21}[{white}%s{21}]{22}Earl I{21}] {23}%N \x01:  {12}%s", live, class, client, msg );
				else if (rank == 12)
					FormatEx( alltext, sizeof(alltext), "%s{21}[{white}%s{21}]{22}Earl II{21}] {23}%N \x01:  {12}%s", live, class, client, msg );
				else if (rank == 13)
					FormatEx( alltext, sizeof(alltext), "%s{21}[{white}%s{21}]{22}Earl III{21}] {23}%N \x01:  {12}%s", live, class, client, msg );
				else if (rank == 14)
					FormatEx( alltext, sizeof(alltext), "%s{21}[{white}%s{21}]{22}Earl IV{21}] {23}%N \x01:  {12}%s", live, class, client, msg );
				else if (rank == 15)
					FormatEx( alltext, sizeof(alltext), "%s{21}[{white}%s{21}]{22}Earl V{21}] {23}%N \x01:  {12}%s", live, class, client, msg );		
			}
			else if ( 16 <= rank <= 20 )
			{
				if (rank == 16)
					FormatEx( alltext, sizeof(alltext), "%s{sirb}[{white}%s{sirb}]{sirr}Sir I{sirb}] {sirn}%N \x01:  {sirc}%s", live, class, client, msg );	
				else if (rank == 17)
					FormatEx( alltext, sizeof(alltext), "%s{sirb}[{white}%s{sirb}]{sirr}Sir II{sirb}] {sirn}%N \x01:  {sirc}%s", live, class, client, msg );	
				else if (rank == 18)
					FormatEx( alltext, sizeof(alltext), "%s{sirb}[{white}%s{sirb}]{sirr}Sir III{sirb}] {sirn}%N \x01:  {sirc}%s", live, class, client, msg );	
				else if (rank == 19)
					FormatEx( alltext, sizeof(alltext), "%s{sirb}[{white}%s{sirb}]{sirr}Sir IV{sirb}] {sirn}%N \x01:  {sirc}%s", live, class, client, msg );	
				else if (rank == 20)
					FormatEx( alltext, sizeof(alltext), "%s{sirb}[{white}%s{sirb}]{sirr}Sir V{sirb}] {sirn}%N \x01:  {sirc}%s", live, class, client, msg );		
			}
			else if ( 21 <= rank <= 25 )
			{
				if (rank == 21)
					FormatEx( alltext, sizeof(alltext), "%s{countb}[{white}%s{countb}]{countr}Count I{countb}] {countn}%N \x01:  {countc}%s", live, class, client, msg );	
				else if (rank == 22)
					FormatEx( alltext, sizeof(alltext), "%s{countb}[{white}%s{countb}]{countr}Count II{countb}] {countn}%N \x01:  {countc}%s", live, class, client, msg );	
				else if (rank == 23)
					FormatEx( alltext, sizeof(alltext), "%s{countb}[{white}%s{countb}]{countr}Count III{countb}] {countn}%N \x01:  {countc}%s", live, class, client, msg );	
				else if (rank == 24)
					FormatEx( alltext, sizeof(alltext), "%s{countb}[{white}%s{countb}]{countr}Count IV{countb}] {countn}%N \x01:  {countc}%s", live, class, client, msg );	
				else if (rank == 25)
					FormatEx( alltext, sizeof(alltext), "%s{countb}[{white}%s{countb}]{countr}Count V{countb}] {countn}%N \x01:  {countc}%s", live, class, client, msg );		
			}
			else if ( 26 <= rank <= 30 )
			{
				if (rank == 26)
					FormatEx( alltext, sizeof(alltext), "%s{baronb}[{white}%s{baronb}]{baronr}Baron I{baronb}] {baronn}%N \x01:  {baronc}%s", live, class, client, msg );	
				else if (rank == 27)
					FormatEx( alltext, sizeof(alltext), "%s{baronb}[{white}%s{baronb}]{baronr}Baron II{baronb}] {baronn}%N \x01:  {baronc}%s", live, class, client, msg );	
				else if (rank == 28)
					FormatEx( alltext, sizeof(alltext), "%s{baronb}[{white}%s{baronb}]{baronr}Baron III{baronb}] {baronn}%N \x01:  {baronc}%s", live, class, client, msg );	
				else if (rank == 29)
					FormatEx( alltext, sizeof(alltext), "%s{baronb}[{white}%s{baronb}]{baronr}Baron IV{baronb}] {baronn}%N \x01:  {baronc}%s", live, class, client, msg );	
				else if (rank == 30)
					FormatEx( alltext, sizeof(alltext), "%s{baronb}[{white}%s{baronb}]{baronr}Baron V{baronb}] {baronn}%N \x01:  {baronc}%s", live, class, client, msg );		
			}
			else if ( 31 <= rank <= 35 )
			{
				if (rank == 31)
					FormatEx( alltext, sizeof(alltext), "%s{knightb}[{white}%s{knightb}]{knightr}Knight I{knightb}] {knightn}%N \x01:  {knightc}%s", live, class, client, msg );	
				else if (rank == 32)
					FormatEx( alltext, sizeof(alltext), "%s{knightb}[{white}%s{knightb}]{knightr}Knight II{knightb}] {knightn}%N \x01:  {knightc}%s", live, class, client, msg );
				else if (rank == 33)
					FormatEx( alltext, sizeof(alltext), "%s{knightb}[{white}%s{knightb}]{knightr}Knight III{knightb}] {knightn}%N \x01:  {knightc}%s", live, class, client, msg );	
				else if (rank == 34)
					FormatEx( alltext, sizeof(alltext), "%s{knightb}[{white}%s{knightb}]{knightr}Knight IV{knightb}] {knightn}%N \x01:  {knightc}%s", live, class, client, msg );	
				else if (rank == 35)
					FormatEx( alltext, sizeof(alltext), "%s{knightb}[{white}%s{knightb}]{knightr}Knight V{knightb}] {knightn}%N \x01:  {knightc}%s", live, class, client, msg );		
			}
			else if ( 36 <= rank <= 40 )
			{
				if (rank == 36)
					FormatEx( alltext, sizeof(alltext), "%s{nobleb}[{white}%s{nobleb}]{nobler}Noble I{nobleb}] {noblen}%N \x01:  {noblec}%s", live, class, client, msg );	
				else if (rank == 37)
					FormatEx( alltext, sizeof(alltext), "%s{nobleb}[{white}%s{nobleb}]{nobler}Noble II{nobleb}] {noblen}%N \x01:  {noblec}%s", live, class, client, msg );		
				else if (rank == 38)
					FormatEx( alltext, sizeof(alltext), "%s{nobleb}[{white}%s{nobleb}]{nobler}Noble III{nobleb}] {noblen}%N \x01:  {noblec}%s", live, class, client, msg );	
				else if (rank == 39)
					FormatEx( alltext, sizeof(alltext), "%s{nobleb}[{white}%s{nobleb}]{nobler}Noble IV{nobleb}] {noblen}%N \x01:  {noblec}%s", live, class, client, msg );		
				else if (rank == 40)
					FormatEx( alltext, sizeof(alltext), "%s{nobleb}[{white}%s{nobleb}]{nobler}Noble V{nobleb}] {noblen}%N \x01:  {noblec}%s", live, class, client, msg );		
			}
			else if ( 41 <= rank <= 45 )
			{
				if (rank == 41)
					FormatEx( alltext, sizeof(alltext), "%s{esquireb}[{white}%s{esquireb}]{esquirer}Esquire I{esquireb}] {esquiren}%N \x01:  {esquirec}%s", live, class, client, msg );	
				else if (rank == 42)
					FormatEx( alltext, sizeof(alltext), "%s{esquireb}[{white}%s{esquireb}]{esquirer}Esquire II{esquireb}] {esquiren}%N \x01:  {esquirec}%s", live, class, client, msg );		
				else if (rank == 43)
					FormatEx( alltext, sizeof(alltext), "%s{esquireb}[{white}%s{esquireb}]{esquirer}Esquire III{esquireb}] {esquiren}%N \x01:  {esquirec}%s", live, class, client, msg );		
				else if (rank == 44)
					FormatEx( alltext, sizeof(alltext), "%s{esquireb}[{white}%s{esquireb}]{esquirer}Esquire IV{esquireb}] {esquiren}%N \x01:  {esquirec}%s", live, class, client, msg );	
				else if (rank == 45)
					FormatEx( alltext, sizeof(alltext), "%s{esquireb}[{white}%s{esquireb}]{esquirer}Esquire V{esquireb}] {esquiren}%N \x01:  {esquirec}%s", live, class, client, msg );		
			}
			else if ( 46 <= rank <= 50 )
			{
				if (rank == 46)
					FormatEx( alltext, sizeof(alltext), "%s{jesterb}[{white}%s{jesterb}]{jesterr}Jester I{jesterb}] {jestern}%N \x01:  {jesterc}%s", live, class, client, msg );	
				else if (rank == 47)
					FormatEx( alltext, sizeof(alltext), "%s{jesterb}[{white}%s{jesterb}]{jesterr}Jester II{jesterb}] {jestern}%N \x01:  {jesterc}%s", live, class, client, msg );
				else if (rank == 48)
					FormatEx( alltext, sizeof(alltext), "%s{jesterb}[{white}%s{jesterb}]{jesterr}Jester III{jesterb}] {jestern}%N \x01:  {jesterc}%s", live, class, client, msg );	
				else if (rank == 49)
					FormatEx( alltext, sizeof(alltext), "%s{jesterb}[{white}%s{jesterb}]{jesterr}Jester IV{jesterb}] {jestern}%N \x01:  {jesterc}%s", live, class, client, msg );
				else if (rank == 50)
					FormatEx( alltext, sizeof(alltext), "%s{jesterb}[{white}%s{jesterb}]{jesterr}Jester V{jesterb}] {jestern}%N \x01:  {jesterc}%s", live, class, client, msg );
			}
			else if ( 51 <= rank <= 55 )
			{
				if (rank == 51)
					FormatEx( alltext, sizeof(alltext), "%s{plebeianb}[{white}%s{plebeianb}]{plebeianr}Plebeian I{plebeianb}] {plebeiann}%N \x01:  {plebeianc}%s", live, class, client, msg );	
				else if (rank == 52)
					FormatEx( alltext, sizeof(alltext), "%s{plebeianb}[{white}%s{plebeianb}]{plebeianr}Plebeian II{plebeianb}] {plebeiann}%N \x01:  {plebeianc}%s", live, class, client, msg );
				else if (rank == 53)
					FormatEx( alltext, sizeof(alltext), "%s{plebeianb}[{white}%s{plebeianb}]{plebeianr}Plebeian III{plebeianb}] {plebeiann}%N \x01:  {plebeianc}%s", live, class, client, msg );	
				else if (rank == 54)
					FormatEx( alltext, sizeof(alltext), "%s{plebeianb}[{white}%s{plebeianb}]{plebeianr}Plebeian IV{plebeianb}] {plebeiann}%N \x01:  {plebeianc}%s", live, class, client, msg );	
				else if (rank == 55)
					FormatEx( alltext, sizeof(alltext), "%s{plebeianb}[{white}%s{plebeianb}]{plebeianr}Plebeian V{plebeianb}] {plebeiann}%N \x01:  {plebeianc}%s", live, class, client, msg );
			}
			else if ( 56 <= rank <= 60 )
			{
				if (rank == 56)
					FormatEx( alltext, sizeof(alltext), "%s{peasantb}[{white}%s{peasantb}]{peasantr}Peasant I{peasantb}] {peasantn}%N \x01:  {peasantc}%s", live, class, client, msg );	
				else if (rank == 57)
					FormatEx( alltext, sizeof(alltext), "%s{peasantb}[{white}%s{peasantb}]{peasantr}Peasant II{peasantb}] {peasantn}%N \x01:  {peasantc}%s", live, class, client, msg );
				else if (rank == 58)
					FormatEx( alltext, sizeof(alltext), "%s{peasantb}[{white}%s{peasantb}]{peasantr}Peasant III{peasantb}] {peasantn}%N \x01:  {peasantc}%s", live, class, client, msg );	
				else if (rank == 59)
					FormatEx( alltext, sizeof(alltext), "%s{peasantb}[{white}%s{peasantb}]{peasantr}Peasant IV{peasantb}] {peasantn}%N \x01:  {peasantc}%s", live, class, client, msg );
				else if (rank == 60)
					FormatEx( alltext, sizeof(alltext), "%s{peasantb}[{white}%s{peasantb}]{peasantr}Peasant V{peasantb}] {peasantn}%N \x01:  {peasantc}%s", live, class, client, msg );		
			}	
			else
			{
				if (rank > 60)
					FormatEx( alltext, sizeof(alltext), "%s{peonb}[{white}%s{peonb}]{peonr}Peon{peonb}] {peonn}%N \x01:  {peonc}%s", live, class, client, msg );		
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
		
	for (int i = 1; i <= MaxClients; i++)
		if (IsClientConnected(i) && IsClientInGame(i) && !(g_fClientHideFlags[i] & HIDEHUD_CHAT))
			CPrintToChat(i, alltext);
	
	PrintToServer( "%N :  %s", client, msg );

	if(msg[0] == '!' || msg[0] == '/')
	{
		int isCaps = false;

		for(int i = 0; i <= strlen(msg); ++i)
		{
			if (IsCharUpper(msg[i]))
			{
				isCaps = true;
				break;
			}
		}

		if ( isCaps )
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

public Action OnRestrictCommand(int client, const char[] command, int argc)
{
	CPrintToChat(client, CHAT_PREFIX..."Command {lightskyblue}%s {white}blocked due to security reasons.", command);
	return Plugin_Handled;
}

public void OnPluginStart()
{
	ServerOSIsLinux = IsLinux();

	ServerCommand("sv_hudhint_sound 0");
	AddCommandListener(OnRestrictCommand, "setpos");
	AddCommandListener(OnRestrictCommand, "setpos_exact");
	AddCommandListener(OnRestrictCommand, "noclip");
	Handle pIterator = GetPluginIterator();
	hPlugin = ReadPlugin(pIterator);
	CloseHandle(pIterator);

	ClientSocket = SocketCreate(SOCKET_TCP, OnClientSocketError);
	ConnecToMasterServer();

	requested = false;
	char path[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, path, sizeof(path), "recordings/bz2/");
	if(!DirExists(path)) {
		CreateDirectory(path, FPERM_U_READ|FPERM_U_WRITE|FPERM_U_EXEC|FPERM_G_READ|FPERM_G_EXEC|FPERM_O_READ|FPERM_O_EXEC);
	}
	
	lockedConVars = CreateTrie();
	SetTrieValue(lockedConVars, "tv_enable", 1);
	SetTrieValue(lockedConVars, "tv_autorecord", 0);
	
	Handle convar = FindConVar("tv_enable");
	SetConVarInt(convar, 1);
	HookConVarChange(convar, OnLockedConVarChanged);
	convar = FindConVar("tv_autorecord");
	SetConVarInt(convar, 0);
	HookConVarChange(convar, OnLockedConVarChanged);
	/*RegConsoleCmd("sm_irc", cmdIRC, "Toggles IRC chat");
	RegAdminCmd("sm_irccolor", cmdIRCColor, ADMFLAG_ROOT, "Set IRC tag color")*
	g_cvAllowHide = CreateConVar("irc_allow_hide", "1", "Sets whether players can hide IRC chat", FCVAR_NOTIFY);
	g_cvAllowFilter = CreateConVar("irc_allow_filter", "1", "Sets whether IRC filters messages beginning with !", FCVAR_NOTIFY);
	g_cvHideDisconnect = CreateConVar("irc_disconnect_filter", "1", "Sets whether IRC filters disconnect messages", FCVAR_NOTIFY);
	g_cvColor = CreateConVar("irc_color", "65bca6", "Set irc tag color");

	g_cvarPctRequired = CreateConVar("anti_caps_lock_percent", "0.9", "Force all letters to lowercase when this percent of letters is uppercase (not counting symbols)", _, true, 0.0, true, 1.0);
	g_cvarMinLength = CreateConVar("anti_caps_lock_min_length", "5", "Only force letters to lowercase when a message has at least this many letters (not counting symbols)", _, true, 0.0);

	g_cvColor.AddChangeHook(cvarColorChanged);

	LoadTranslations("sourceirc.phrases");
	g_cvColor.GetString(g_sColor, sizeof(g_sColor));*/

	srv_id = CreateConVar("server_id", "0", "Server id");

	AutoExecConfig(true, "Timer");

	LoadTranslations("nominations.phrases");
	g_hForward_Timer_OnStateChanged = CreateGlobalForward( "Timer_OnStateChanged", ET_Ignore, Param_Cell, Param_Cell );
	//g_hForward_Timer_OnModeChanged = CreateGlobalForward( "Timer_OnModeChanged", ET_Ignore, Param_Cell, Param_Cell );
	LoadTranslations("common.phrases");

	RegConsoleCmd( "sm_goto", Command_Gotos );
	RegConsoleCmd("sm_msg", CMD_SendMessage, "Send a message to all servers.");

	// HOOKS
	HookEvent("player_spawn", Event_PlayerSpawn);
	HookEvent("player_disconnect", EventDisconnect, EventHookMode_Post);
	HookEvent( "player_spawn", Event_ClientSpawn );
	HookEvent( "player_death", Event_ClientDeath );

	HookEvent( "teamplay_round_start", Event_RoundRestart, EventHookMode_PostNoCopy );
	HookEvent( "round_start", OnRoundStartPost );

	g_aMapList = new ArrayList( ByteCountToCells(PLATFORM_MAX_PATH) );
	g_aMapTiersSolly = new ArrayList();
	g_aMapTiersDemo = new ArrayList();
	g_aNominateList = new ArrayList( ByteCountToCells(PLATFORM_MAX_PATH) );
	g_aOldMaps = new ArrayList( ByteCountToCells(PLATFORM_MAX_PATH) );
		
	g_cvMapVoteBlockMapInterval = CreateConVar( "smc_mapvote_blockmap_interval", "1", "How many maps should be played before a map can be nominated again", _, true, 0.0, false );
	g_cvMapVoteExtendTime = CreateConVar( "smc_mapvote_extend_time", "10", "How many minutes should the map be extended by if the map is extended through a mapvote", _, true, 1.0, false );
	g_cvMapVoteDuration = CreateConVar( "smc_mapvote_duration", "1", "Duration of time in minutes that map vote menu should be displayed for", _, true, 0.1, false );
	g_cvMapVoteStartTime = CreateConVar( "smc_mapvote_start_time", "3", "Time in minutes before map end that map vote starts", _, true, 1.0, false );
	
	AutoExecConfig();
	
	RegAdminCmd( "sm_extend", Command_Extend, ADMFLAG_CHANGEMAP, "Admin command for extending map" );
	RegAdminCmd( "sm_forcemapvote", Command_ForceMapVote, ADMFLAG_RCON, "Admin command for forcing the end of map vote" );
	RegAdminCmd( "sm_reloadmaplist", Command_ReloadMaplist, ADMFLAG_CHANGEMAP, "Admin command for forcing maplist to be reloaded" );
	
	RegConsoleCmd( "sm_nominate", Command_Nominate, "Lets players nominate maps to be on the end of map vote" );
	RegConsoleCmd( "sm_nom", Command_Nominate, "Alias for sm_nominate" );
	RegConsoleCmd( "sm_unnominate", Command_UnNominate, "Removes nominations" );
	RegConsoleCmd( "sm_rtv", Command_RockTheVote, "Lets players Rock The Vote" );
	RegConsoleCmd( "sm_unrtv", Command_UnRockTheVote, "Lets players un-Rock The Vote" );
	RegConsoleCmd("sm_ve", Command_VE);
	RegConsoleCmd("sm_voteextend", Command_VE);
	RegConsoleCmd("sm_revote", Command_Revote);	

	// SPAWNING
	RegConsoleCmd( "sm_respawn", Command_Spawn );
	RegConsoleCmd( "sm_reset", Command_Spawn );
	RegConsoleCmd( "sm_spawn", Command_Spawn );
	RegConsoleCmd( "sm_restart", Command_Spawn );
	RegConsoleCmd( "sm_r", Command_Spawn );
	RegConsoleCmd( "sm_re", Command_Spawn );
	RegConsoleCmd( "sm_start", Command_Spawn );

	RegConsoleCmd("sm_setstart", Command_Set_Start);
	RegConsoleCmd("sm_set", Command_Set_Start);
	RegConsoleCmd("sm_clearstart", Command_Clear_Start);
	RegConsoleCmd("sm_clear", Command_Clear_Start);


	// SPEC
	RegConsoleCmd( "sm_spectate", Command_Spectate );
	RegConsoleCmd( "sm_spec", Command_Spectate );


	// CLIENT SETTINGS
	RegConsoleCmd( "sm_hud", Command_ToggleHUD ); // Menu

	RegConsoleCmd( "sm_settings", Command_ToggleHUD );

	RegConsoleCmd("sm_mt", SM_MapInfo, "sm_mt <mapname> - Show map tier tempus");

	RegConsoleCmd("sm_m", Command_PrintMapTier, "sm_m <mapname> - Show map tier");

	RegConsoleCmd("sm_maplist", cmdMapList, "Show the map list");
	RegConsoleCmd("sm_ml", cmdMapList, "Show the map list");
	RegConsoleCmd("sm_maps", cmdMapList, "Show the map list");

	RegConsoleCmd("sm_ttop", SM_TopTimes, "sm_top <mapname> - Show map top times");

	RegConsoleCmd("sm_runmode", Command_RunMode, "Switch Run Mode");



	// RECORDS
	RegConsoleCmd( "sm_top", Command_RecordsPrint );
	RegConsoleCmd( "sm_btop", Command_BonusesRecordsPrint );
	RegConsoleCmd( "sm_ctop", Command_CoursesRecordsPrint );

	RegConsoleCmd( "sm_ptop", Command_RecordsMenuPoints );
	RegConsoleCmd( "sm_pointstop", Command_RecordsMenuPoints );
	RegConsoleCmd( "sm_toppoints", Command_RecordsMenuPoints );

	RegConsoleCmd( "sm_ammo", RegenAmmo );
	RegConsoleCmd( "sm_dz", Timer_DrawZoneBeams );

	RegConsoleCmd( "sm_dzl", Timer_DrawZoneBeamsList );
	RegConsoleCmd( "sm_dzlist", Timer_DrawZoneBeamsList );

	RegConsoleCmd( "sm_overall", Command_Overall );	
	RegConsoleCmd( "sm_time", Command_Time );

	RegConsoleCmd( "sm_rr", Command_ResentRecords );	
	RegConsoleCmd( "sm_resentrecords", Command_ResentRecords );	

	RegConsoleCmd( "sm_rrb", Command_ResentRecords_Bonus );
	RegConsoleCmd( "sm_rrc", Command_ResentRecords_Course );	

	RegConsoleCmd( "sm_rb", Command_ResentBrokenRecords );	
	RegConsoleCmd( "sm_recentbroken", Command_ResentBrokenRecords );
	RegConsoleCmd( "sm_broken", Command_ResentBrokenRecords );

	RegConsoleCmd( "sm_bonus", Command_Bonus );
	RegConsoleCmd( "sm_b", Command_Bonus );

	RegConsoleCmd( "sm_c", Command_Courses );
	RegConsoleCmd( "sm_course", Command_Courses );
	RegConsoleCmd( "sm_courses", Command_Courses );

	RegConsoleCmd( "sm_timer", Command_Practise );
	RegConsoleCmd( "sm_stime", STime );
	RegConsoleCmd( "sm_dtime", DTime );
	RegConsoleCmd( "sm_swr", SWr );
	RegConsoleCmd( "sm_dwr", DWr );
	RegConsoleCmd( "sm_srank", SRank );
	RegConsoleCmd( "sm_drank", DRank );
	RegConsoleCmd( "sm_rank", ORank );
	RegConsoleCmd( "sm_orank", ORank );
	RegConsoleCmd( "sm_profile", Command_Profile );
	RegConsoleCmd( "sm_p", Command_Profile );
	RegConsoleCmd( "sm_ranks", Command_Ranks );

	RegConsoleCmd( "sm_pr", Command_PersonalRecords );
	RegConsoleCmd( "sm_personalrecord", Command_PersonalRecords );

	RegConsoleCmd( "sm_pts", Command_MapPoints );
	RegConsoleCmd( "sm_points", Command_MapPoints );
	RegConsoleCmd( "sm_mi", Command_MapPoints );
	
	RegConsoleCmd( "sm_saveloc", Command_Practise_SavePoint );
	RegConsoleCmd( "sm_save", Command_Practise_SavePoint );
	RegConsoleCmd( "sm_s", Command_Practise_SavePoint );
	
	RegConsoleCmd( "sm_hidechat", Command_Hide_Chat );
	

	RegConsoleCmd( "sm_l", Command_Level );
	RegConsoleCmd( "sm_lvl", Command_Level );
	RegConsoleCmd( "sm_level", Command_Level );
	RegConsoleCmd( "sm_levels", Command_Level );
	
	RegConsoleCmd("sm_t", Command_Practise_GotoSavedLoc, "Teleports you to your saved location.");
	RegConsoleCmd("sm_tp", Command_Practise_GotoSavedLoc, "Teleports you to your saved location.");
	RegConsoleCmd("sm_tele", Command_Practise_GotoSavedLoc, "Teleports you to your saved location.");
	RegConsoleCmd("sm_teleport", Command_Practise_GotoSavedLoc, "Teleports you to your saved location.");
	
	RegConsoleCmd( "sm_noclip", Command_Practise_Noclip );
	RegConsoleCmd( "sm_fly", Command_Practise_Noclip );

	RegConsoleCmd( "sm_commands", Command_AllCommands );

	RegConsoleCmd( "sm_help", Command_Help );

	RegConsoleCmd( "sm_version", Command_Version );

	RegConsoleCmd( "sm_info", Command_Credits );
	RegConsoleCmd( "sm_discord", Command_Discord );

	RegConsoleCmd( "sm_svid", Command_SVid );
	RegConsoleCmd( "sm_dvid", Command_DVid );

	RegConsoleCmd( "sm_incomplete", Command_IncompleteMaps );
	RegConsoleCmd( "sm_incompletions", Command_IncompleteMaps );

	RegConsoleCmd("sm_weather", CMD_Weather);


	// ADMIN STUFF
	// ZONES
	RegAdminCmd( "sm_settier", Command_SetTier, ZONE_EDIT_ADMFLAG, "Tier menu." ); // Menu
	RegAdminCmd( "sm_setclass", Command_SetClass, ZONE_EDIT_ADMFLAG, "Tier menu." ); // Menu

	RegAdminCmd( "sm_customstart", Command_Set_CustomStart, ZONE_EDIT_ADMFLAG );
	

	RegAdminCmd( "sm_zone", Command_Admin_ZoneMenu, ZONE_EDIT_ADMFLAG, "Zone menu." ); // Menu
	RegConsoleCmd( "sm_unzoned", Command_Admin_UnzonedMenu); // Menu
	RegConsoleCmd( "sm_unzonedmaps", Command_Admin_UnzonedMenu); // Menu
	RegAdminCmd( "sm_changezone", Change_zone_pints, ZONE_EDIT_ADMFLAG, "Zone menu." ); // Menu
	RegAdminCmd( "sm_cz", Change_zone_pints, ZONE_EDIT_ADMFLAG, "Zone menu." ); // Menu
	RegAdminCmd( "sm_z", Command_Admin_ZoneMenu, ZONE_EDIT_ADMFLAG, "Zone menu." );
	RegAdminCmd( "sm_addskip", Command_Admin_AddSkipLevel, ZONE_EDIT_ADMFLAG, "Add skip." );
	RegAdminCmd( "sm_delskip", Command_Admin_DelSkipLevel, ZONE_EDIT_ADMFLAG, "Delete skip." );
	RegAdminCmd( "sm_zonemenu", Command_Admin_ZoneMenu, ZONE_EDIT_ADMFLAG, "Zone menu." );

	RegAdminCmd( "sm_startlevels", Command_Admin_Levels, ZONE_EDIT_ADMFLAG, "Begin to make a zone." ); // Menu
	RegAdminCmd( "sm_endzone", Command_Admin_ZoneEnd, ZONE_EDIT_ADMFLAG, "Finish the zone." );
	RegAdminCmd( "sm_cancelzone", Command_Admin_ZoneCancel, ZONE_EDIT_ADMFLAG, "Cancel the zone." );

	RegAdminCmd( "sm_zoneedit", Command_Admin_ZoneEdit, ZONE_EDIT_ADMFLAG, "Choose zone to edit." ); // Menu
	RegAdminCmd( "sm_selectcurzone", Command_Admin_ZoneEdit_SelectCur, ZONE_EDIT_ADMFLAG, "Choose the zone you are currently in." );
	RegAdminCmd( "sm_deletezone", Command_Admin_ZoneDelete, ZONE_EDIT_ADMFLAG, "Delete a zone." ); // Menu
	RegAdminCmd( "sm_deletezone2", Command_Admin_ZoneDelete2, ZONE_EDIT_ADMFLAG, "Delete a freestyle/block zone." ); // Menu
	RegAdminCmd( "sm_deletecp", Command_Admin_ZoneDelete_CP, ZONE_EDIT_ADMFLAG, "Delete a checkpoint." ); // Menu

	RegAdminCmd( "sm_forcezonecheck", Command_Admin_ForceZoneCheck, ZONE_EDIT_ADMFLAG, "Force a zone check." );

	RegConsoleCmd("sm_calladmin", Cmd_CallAdmin);


	
	gHostname = FindConVar("hostname");
	gHostPort = FindConVar("hostport");

	//RegConsoleCmd("sm_irc", cmdIRC, "Toggles IRC chat");
	//RegAdminCmd("sm_irccolor", cmdIRCColor, ADMFLAG_ROOT, "Set IRC tag color");
	// CONVARS
	
	/*g_cvAllowHide = CreateConVar("irc_allow_hide", "0", "Sets whether players can hide IRC chat", FCVAR_NOTIFY);
	g_cvAllowFilter = CreateConVar("irc_allow_filter", "0", "Sets whether IRC filters messages beginning with !", FCVAR_NOTIFY);
	g_cvHideDisconnect = CreateConVar("irc_disconnect_filter", "0", "Sets whether IRC filters disconnect messages", FCVAR_NOTIFY);
	g_cvColor = CreateConVar("irc_color", "65bca6", "Set irc tag color");

	g_cvarPctRequired = CreateConVar("anti_caps_lock_percent", "0.9", "Force all letters to lowercase when this percent of letters is uppercase (not counting symbols)", _, true, 0.0, true, 1.0);
	g_cvarMinLength = CreateConVar("anti_caps_lock_min_length", "5", "Only force letters to lowercase when a message has at least this many letters (not counting symbols)", _, true, 0.0);

	g_cvColor.AddChangeHook(cvarColorChanged);

	LoadTranslations("sourceirc.phrases");
	g_cvColor.GetString(g_sColor, sizeof(g_sColor));*/

	LoadTranslations( "common.phrases" ); // So FindTarget() can work.
	//LoadTranslations( "opentimer.phrases" );

	DB_InitializeDatabase();
}

public void OnAllPluginsLoaded()
{
    if (LibraryExists("updater"))
    {
        Updater_AddPlugin(UPDATE_URL);
    }
	g_ripext_loaded = LibraryExists("ripext");
    RegServerCmd("sm_plugins_update", cmdPluginUpdate);
}

public Action cmdPluginUpdate(int args)
{
    if (LibraryExists("updater"))
    {
        Updater_ForceUpdate();
    }
}

public int Updater_OnPluginUpdated()
{

    if (LibraryExists("updater"))
    {
        ReloadPlugin();
    }
}

public Action EventDisconnect(Handle event, const char[] name, bool dontBroadcast)
{
    SetEventBroadcast(event, true);
    return Plugin_Continue;
}  

public Action Command_Gotos(int client, int args)
{

	if (args != 1)
	{
		ReplyToCommand(client, CHAT_PREFIX..."Usage  !goto <name>");
		return Plugin_Handled;
	}

	float fTeleportOrigin[3];
	float fPlayerOrigin[3];

	char sArg1[MAX_NAME_LENGTH];
	GetCmdArg(1, sArg1, sizeof(sArg1));
	int iTarget = FindTarget(client, sArg1, true, false);

	if (iTarget == -1)
	{
		ReplyToCommand(client, CHAT_PREFIX..."No player found.");
		return Plugin_Handled;
	}
	else
	{
		SetPlayerPractice( client, true );
	}
	GetClientAbsOrigin(iTarget, fPlayerOrigin);
	fTeleportOrigin[0] = fPlayerOrigin[0];
	fTeleportOrigin[1] = fPlayerOrigin[1];
	fTeleportOrigin[2] = (fPlayerOrigin[2] + 73);

	TeleportEntity(client, fTeleportOrigin, NULL_VECTOR, NULL_VECTOR);
	CPrintToChat(iTarget, "[SM] %N has been brought to you!", client);
	CPrintToChat(client, "[SM] You have been brought to %N!", iTarget);
	return Plugin_Handled;
}

public Action OnGetMaxHealth(int client, int &maxhealth)
{
    if (client > 0 && client <= MaxClients)
    {
        if (TF2_GetPlayerClass(client) == TFClass_Soldier)
        {
            maxhealth = 900;
        }
        else if (TF2_GetPlayerClass(client) == TFClass_DemoMan)
        {
            maxhealth = 175;
        }
        return Plugin_Handled;
    }
    return Plugin_Continue;
}

public void OnConfigsExecuted()
{
	server_id = srv_id.IntValue;
	for (int i = 1; i <= MaxClients; i++)
    {
        if (IsClientInGame(i))
        {
            SDKHook(i, SDKHook_GetMaxHealth, OnGetMaxHealth);
        }
    }
	//SetupTimeleftTimer();
}

public void OnMapStart()
{
	char vote_plugins[3][100] = {"mapchooser", "nominations", "rockthevote"};
	char filename[200], newfilename[200];

	if (!DirExists("plugins/disabled/"))
		CreateDirectory("plugins/disabled/", FPERM_U_READ|FPERM_U_WRITE|FPERM_U_EXEC|FPERM_G_READ|FPERM_G_EXEC|FPERM_O_READ|FPERM_O_EXEC);

	for (int i; i < 3; i++)
	{
		BuildPath(Path_SM, filename, sizeof(filename), "plugins/%s.smx", vote_plugins[i]);
		if(FileExists(filename))
		{
			BuildPath(Path_SM, newfilename, sizeof(newfilename), "plugins/disabled/%s.smx", vote_plugins[i]);
			ServerCommand("sm plugins unload %s", vote_plugins[i]);
			if(FileExists(newfilename))
				DeleteFile(newfilename);
			RenameFile(newfilename, filename);
		}
	}
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if ( g_hClientCPData[i] != null ) { delete g_hClientCPData[i]; g_hClientCPData[i] = null; }
		RegenOn[i] = false;
		ChangeClientState(i, STATE_INVALID);
		g_flClientStartTime[i] = TIME_INVALID;
		g_flClientFinishTime[i] = TIME_INVALID;
		flNewTimeCourse[i] = TIME_INVALID;
		szOldTimeWr = TIME_INVALID;
		szOldTime[i] = TIME_INVALID;

		for (int j = 0; j < NUM_RUNS; j++)
			for (int d = 0; d < NUM_MODES; d++)
				szOldTimePts[i][j][d] = TIME_INVALID;

		TimerEye[i] = null;	

		RemoveAllPrevMenus(i);
	}

secure = false;

/*for (int i = 1; i <= MaxClients; i++) {
        g_bShowIRC[i] = true;
    }
if (g_bLateLoad) {
}*/
GetCurrentMap( g_szCurrentMap, sizeof( g_szCurrentMap ) );
/*IRC_MsgFlaggedChannels("relay", "%t", "Map Changed", g_szCurrentMap);*/
ServerCommand("mp_timelimit 30");
int iCP = -1;
while ((iCP = FindEntityByClassname(iCP, "trigger_capture_area")) != -1)
	{
		SetVariantString("2 0");
		AcceptEntityInput(iCP, "SetTeamCanCap");
		SetVariantString("3 0");
		AcceptEntityInput(iCP, "SetTeamCanCap");
	}

	// Do the precaching first. See if that is causing client crashing.
	int i;
	g_iBeam = PrecacheModel( "materials/sprites/laserbeam.vmt" );
	g_iSprite = PrecacheModel( "materials/sprites/redglow2.vmt" );
	PrecacheModel( BRUSH_MODEL );

	for ( i = 0; i < sizeof( g_szWinningSounds ); i++ )
	{
		PrecacheSound( g_szWinningSounds[i] );
		PrefetchSound( g_szWinningSounds[i] );

		PrecacheSound( g_szWrSounds[i] );
		PrefetchSound( g_szWrSounds[i] );

		PrecacheSound( g_szWrSoundsNo[i] );
		PrefetchSound( g_szWrSoundsNo[i] );

		PrecacheSound( g_szWrSoundsBonus[i] );
		PrefetchSound( g_szWrSoundsBonus[i] );

		PrecacheSound( g_szSoundsCourse[i] );
		PrefetchSound( g_szSoundsCourse[i] );

		PrecacheSound( g_szSoundsCourseWr[i] );
		PrefetchSound( g_szSoundsCourseWr[i] );

		PrecacheSound( g_szSoundsMissCp[i] );
		PrefetchSound( g_szSoundsMissCp[i] );
	}

	// Just in case there are maps that use uppercase letters

	int len = strlen( g_szCurrentMap );

	for ( i = 0; i < len; i++ )
		CharToLower( g_szCurrentMap[i] );


	// Resetting/precaching stuff.
	for ( int run = 0; run < NUM_RUNS; run++ )
		for ( int style = 0; style < NUM_STYLES; style++ )
			for ( int mode = 0; mode < NUM_MODES; mode++ )
			{
				g_flMapBestTime[run][style][mode] = TIME_INVALID;
			}	

	for ( int run = 0; run < NUM_RUNS; run++ )
		for ( int mode = 0; mode < NUM_MODES; mode++ )
		{
			g_Tiers[run][mode] = -1;
			szClass[run][mode] = 0;
			g_CustomRespawnAng[run][0] = 0.0;
			g_CustomRespawnAng[run][1] = 0.0;
			g_CustomRespawnAng[run][2] = 0.0;
			g_CustomRespawnPos[run][0] = 0.0;
			g_CustomRespawnPos[run][1] = 0.0;
			g_CustomRespawnPos[run][2] = 0.0;
			FormatEx(sz_TempusWrName[run][mode], sizeof(sz_TempusWrName), "");
			g_TempusWrTime[run][mode] == TIME_INVALID;
		}

	for (int j=0; j < NUM_REALZONES; j++)
		for (int i=0; i < 30; i++)
			for (int a=0; a < 3; a++)
			{
				g_vecZoneMins[j][i][a] = 0.0;
				g_vecZoneMaxs[j][i][a] = 0.0;
			}	

	for (int a=0; a < 3; a++)
		for (int i=0; i<200; i++)
		{
			g_fClientLevelPos[i][a] = 0.0;
			g_fClientLevelAng[i][a] = 0.0;
		}
	// In case we don't try to fetch the zones.
	for ( i = 0; i < NUM_RUNS; i++ )
	{
		g_bIsLoaded[i] = false;
		isSetCustomStart[i] = false;
	}

	for ( i = 0; i < NUM_REALZONES; i++ )
	{
		for ( int b = 0; b < 30; b++ )
			g_bZoneExists[i][b] = false;
	}

	for ( i = 0; i < NUM_REALZONES; i++ )
	{
		g_bZoneBeingBuilt[i] = false;
	}

	if ( g_hCPs != null ) delete g_hCPs;
	if ( g_hZones != null ) delete g_hZones;
	if ( g_hBeams != null ) delete g_hBeams;
	if ( g_hMaps != null ) delete g_hMaps;


	g_hMaps = new ArrayList( view_as<int>( MapData ) );
	g_hCPs = new ArrayList( view_as<int>( CPData ) );
	g_hZones = new ArrayList( view_as<int>( ZoneData ) );
	g_hBeams = new ArrayList( view_as<int>( BeamData ) );

	// Get map data (zones, cps, cp times) from database.

	DB_InitializeMap();

	httpClient = new HTTPClient("https://tempus.xyz");
	httpClient.SetHeader("Accept", "application/json");

	char req[96];
	Format(req, sizeof(req), "api/maps/name/%s/fullOverview",g_szCurrentMap);

	//Pass the client and the type of request to the data receiving function
	httpClient.Get(req, OnMapInfoGained);

	// Repeating timer that sends the zones to the clients every X seconds.

	CreateTimer( 1.0, Timer_EndMap, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE );
	CreateTimer( 2.5, Timer_regencheck, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE );
	CreateTimer( 60.0, Timer_Ad, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE );

	for (int q = 0; q < MAXPLAYERS; q++){
		for (int j = 0; j < 3; j++){
			g_fClientRespawnPosition[q][j] = 0.0;
			g_fClientRespawnAngles[q][j] = 0.0;
		}
	}

	GetCurrentMap( g_cMapName, sizeof(g_cMapName) );
	
	// disable rtv if delay time is > 0
	g_fMapStartTime = GetGameTime();
	
	g_bMapVoteFinished = false;
	g_bMapVoteStarted = false;
	
	g_aNominateList.Clear();
	for( int i = 1; i <= MaxClients; i++ )
	{
		g_cNominatedMap[i][0] = '\0';
	}
	ClearRTV();
	
	// reload maplist array
	LoadMapList();
	// cache the nominate menu so that it isn't being built every time player opens it
	CreateNominateMenu();
	
	CreateTimer( 1.0, Timer_OnSecond, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE );
}

public void OnMapInfoGained(HTTPResponse response, any value) 
{
	if (response.Status != HTTPStatus_OK) {
		// Failed to retrieve object
		if(response.Status == 404) {
			return;
		}
		return;
	}
	if (response.Data == null) {
		// Invalid JSON response
		return;
	}

	JSONObject mapObj = view_as<JSONObject>(response.Data);

	char d[8096];
	mapObj.ToString(d, sizeof(d));
	delete mapObj;


	//Store the map datastring

	mapObj = JSONObject.FromString(d);

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

	char info[16], query[120];

	int i;

	http = new HTTPClient("https://tempus.xyz");
	http.SetHeader("Accept", "application/json");


	Format(query, sizeof(query), "api/maps/name/%s/zones/typeindex/map/1/records/list?limit=1", g_szCurrentMap);

	http.Get(query, OnTempusWrInfoReceived, 0);

	int run;
	if(courses > 0) {
		run = RUN_COURSE1-1;
		for(i = 1; i < courses+1;i++) {
			Format(query, sizeof(query), "api/maps/name/%s/zones/typeindex/course/%d/records/list?limit=1", g_szCurrentMap, i);
			run++;
			http.Get(query, OnTempusWrInfoReceived, run);
		}
	}

	if(bonuses > 0) {
		run = RUN_BONUS1-1;
		for(i = 1; i < bonuses+1;i++) {
			Format(query, sizeof(query), "api/maps/name/%s/zones/typeindex/bonus/%d/records/list?limit=1", g_szCurrentMap, i);
			run++;
			http.Get(query, OnTempusWrInfoReceived, run);
		}
	}
}

public void OnTempusWrInfoReceived(HTTPResponse response, any run) 
{

	if (response.Status != HTTPStatus_OK) {
		// Failed to retrieve object
		if(response.Status == 404) {
			return;
		}
		return;
	}
	if (response.Data == null) {
		// Invalid JSON response
		return;
	}

	JSONObject mapObj = view_as<JSONObject>(response.Data);

	char d[8096];
	mapObj.ToString(d, sizeof(d));
	delete mapObj;


	//Store the map datastring
	JSONObject records = JSONObject.FromString(d);
	
	char name[60];

	JSONObject rec_info = view_as<JSONObject>(records.Get("results"));
	JSONArray solly_info = view_as<JSONArray>(rec_info.Get("soldier"));

	JSONObject solly_record = view_as<JSONObject>(solly_info.Get(0));

	if (!(solly_record.IsNull("duration")))
	{
		g_TempusWrTime[run][MODE_SOLDIER] = solly_record.GetFloat("duration");
		solly_record.GetString("name",sz_TempusWrName[run][MODE_SOLDIER],sizeof(sz_TempusWrName));
	}

	JSONArray demo_info = view_as<JSONArray>(rec_info.Get("demoman"));

	JSONObject demo_record = view_as<JSONObject>(demo_info.Get(0));

	if (!(demo_record.IsNull("duration")))
	{
		g_TempusWrTime[run][MODE_DEMOMAN] = demo_record.GetFloat("duration");
		demo_record.GetString("name",sz_TempusWrName[run][MODE_DEMOMAN],sizeof(sz_TempusWrName));
	}

	records.Clear();
	rec_info.Clear();
 	solly_info.Clear();
	demo_info.Clear();
	demo_record.Clear();
	solly_record.Clear();

	delete records;
	delete rec_info;
	delete solly_info;
	delete demo_info;
	delete demo_record;
	delete demo_record;
	delete solly_record;

	return;
}

/*
public void OnMapInfoGainedPR(HTTPResponse response, any client) 
{
	if (response.Status != HTTPStatus_OK) {
		// Failed to retrieve object
		if(response.Status == 404) {
			return;
		}
		return;
	}
	if (response.Data == null) {
		// Invalid JSON response
		return;
	}

	JSONObject mapObj = view_as<JSONObject>(response.Data);

	char d[8096];
	mapObj.ToString(d, sizeof(d));
	delete mapObj;


	//Store the map datastring

	mapObj = JSONObject.FromString(d);

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

	char info[16], query[120];

	int i;


	http = new HTTPClient("https://tempus.xyz");
	http.SetHeader("Accept", "application/json");

	Format(query, sizeof(query), "api/maps/name/%s/zones/typeindex/map/1/records/list?limit=300", g_szCurrentMap);

	http.Get(query, OnTempusPrInfoReceived, client);

	int run;
	if(courses > 0) {
		run = RUN_COURSE1-1;
		for(i = 1; i < courses+1;i++) {
			Format(query, sizeof(query), "api/maps/name/%s/zones/typeindex/course/%d/records/list?limit=300", g_szCurrentMap, i);
			http.Get(query, OnTempusPrInfoReceived, client);
		}
	}

	if(bonuses > 0) {
		run = RUN_BONUS1-1;
		for(i = 1; i < bonuses+1;i++) {
			Format(query, sizeof(query), "api/maps/name/%s/zones/typeindex/bonus/%d/records/list?limit=300", g_szCurrentMap, i);
			http.Get(query, OnTempusPrInfoReceived, client);
		}
	}
}

public void OnTempusPrInfoReceived(HTTPResponse response, any client) 
{
	if (response.Status != HTTPStatus_OK) {
		// Failed to retrieve object
		if(response.Status == 404) {
			return;
		}
		return;
	}
	if (response.Data == null) {
		// Invalid JSON response
		return;
	}


	char i_SteamID[50];
	GetClientAuthId(client, AuthId_Steam2, i_SteamID, sizeof(i_SteamID));
	JSONObject mapObj = view_as<JSONObject>(response.Data);

	char d[999999], szzone[40];
	mapObj.ToString(d, sizeof(d));
	delete mapObj;


	//Store the map datastring
	JSONObject records = JSONObject.FromString(d);

	JSONObject zone_info = view_as<JSONObject>(records.Get("zone_info"));

	zone_info.GetString("type",szzone,sizeof(szzone));
	int zone_id = zone_info.GetInt("zoneindex");
	zone_info.Clear();
	int run;

	if (StrEqual(szzone, "map"))
		run = 0;
	else if (StrEqual(szzone, "bonus"))
		run = (RUN_BONUS1-1) + zone_id;
	else if (StrEqual(szzone, "course"))
		run = (RUN_COURSE1-1) + zone_id;	

	JSONObject rec_info = view_as<JSONObject>(records.Get("results"));
	JSONArray solly_info = view_as<JSONArray>(rec_info.Get("soldier"));
	JSONObject info;

	for (int i = 0; i < solly_info.Length; i++)
	{
		info = view_as<JSONObject>(solly_info.Get(i));
		char steamid[50];

		if (!(info.IsNull("steamid")))
			info.GetString("steamid",steamid,sizeof(steamid));

		if (StrEqual( i_SteamID, steamid ) )
		{
			PrintToServer("FINDED REC RUN: %i Client: %N", run, client);
			g_TempusPrTime[client][run][MODE_SOLDIER] = info.GetFloat("duration");
			break;
		}
	}

	info.Clear();
	solly_info.Clear();

	JSONArray demo_info = view_as<JSONArray>(rec_info.Get("demoman"));

	for (int i = 0; i < demo_info.Length; i++)
	{
		info = view_as<JSONObject>(demo_info.Get(i));
		char steamid[50];

		if (!(info.IsNull("steamid")))
			info.GetString("steamid",steamid,sizeof(steamid));

		if (StrEqual( i_SteamID, steamid ) )
		{

			PrintToServer("FINDED REC RUN: %i Client: %N", run, client);
			g_TempusPrTime[client][run][MODE_DEMOMAN] = info.GetFloat("duration");
			break;
		}
	}

	records.Clear();
	rec_info.Clear();
	solly_info.Clear();
	demo_info.Clear();
	delete records;
	delete info;
	delete zone_info;
	delete rec_info;
	delete solly_info;
	delete demo_info;
	return;
}*/

public void OnMapEnd()
{
	for (int i = 1; i <= MaxClients; i++)
	{	
		for (int d = 0; d < 3; d++)
		{
			g_SavePointOrig[i][d] = 0.0;
	 		g_SavePointEye[i][d] = 0.0;
	 	}
	}

	if( g_cvMapVoteBlockMapInterval.IntValue > 0 )
	{
		g_aOldMaps.PushString( g_cMapName );
		if( g_aOldMaps.Length > g_cvMapVoteBlockMapInterval.IntValue )
		{
			g_aOldMaps.Erase( 0 );
		}
	}
	g_VotesNeededVe = 0;

	if (secure)
	{
		PrintToServer("Ending recording of %s", currentDemoFilename);

		ServerCommand("tv_stoprecord");
		if(LibraryExists("bzip2")) {
			new Handle:pack = CreateDataPack();
			WritePackString(pack, currentDemoFilename);
			CreateTimer(1.0, Timer_CompressDemo, pack);
		}
	}

	g_VoteTimer = null;
	// Save zones.
	//g_bLateLoad = false;
	//IRC_MsgFlaggedChannels("relay", "%t", "Map Changing")

	if ( g_hMaps != null ) delete g_hMaps; g_hMaps = null;
	if ( g_hBeams != null ) { delete g_hBeams; g_hBeams = null; }

	if (g_hZones != null)
	{
		int ent = 0;
		int len = g_hZones.Length;
		for (int i=0; i < len; i++)
		{
			if ( g_hZones.Get( i, view_as<int>( ZONE_ENT ) ) )
			{
				ent = g_hZones.Get( i, view_as<int>( ZONE_ENT ) );
				SDKUnhook( ent, SDKHook_Touch, Event_Touch_Zone );
				SDKUnhook( ent, SDKHook_EndTouch, Event_EndTouchPost_Zone );
			}
		}
		delete g_hZones; g_hZones = null;
	}
	//if (IRC_Connected)
		//DisconnectFromMasterServer();
}

public void OnClientPutInServer( int client )
{
	IsMapMode[client] = true;
	LastUsage[client] = 0;
	isHudDrawed[client] = false;
	LastHudDrawing[client] = GetEngineTime();
	char szSteam[100];
	char szQuery[200];
	GetClientSteam(client, szSteam, sizeof( szSteam )	);
	char szLink[192];
    GetClientAuthId( client, AuthId_SteamID64, szLink, sizeof(szLink) );
	char IP[99], Country[99], vadim[100];
	FormatEx(vadim, sizeof( vadim ), "[U:1:46265336]");
	if (StrEqual(szSteam, vadim) )
	{
		CPrintToChatAll(CHAT_PREFIX..."Гандон заходит в игру....");
	}
	GetClientIP(client, IP, sizeof(IP), true);
	if(!GeoipCountry(IP, Country, sizeof(Country)))
	{
		Country = "None";
	}
	FormatEx( szQuery, sizeof( szQuery ), "UPDATE "...TABLE_PLYDATA..." SET lastseen = CURRENT_TIMESTAMP, country = '%s', link = '%s', ip = '%s' WHERE steamid = '%s'",
	Country,
	szLink,
	IP,
	szSteam );
	SQL_TQuery(g_hDatabase, Threaded_Empty, szQuery, client);
	g_flClientStartTime[client] = TIME_INVALID;
	g_flClientCourseStartTime[client] = TIME_INVALID;

	g_iClientRun[client] = RUN_SETSTART;
	GetClientUserId(client);
	SDKHook( client, SDKHook_OnTakeDamage, Event_OnTakeDamage_Client );
	SDKHook( client, SDKHook_WeaponDropPost, Event_WeaponDropPost ); // No more weapon dropping.
	SDKHook( client, SDKHook_SetTransmit, Event_SetTransmit_Client ); // Has to be hooked to everybody(?)
	SDKHook(client, SDKHook_GetMaxHealth, OnGetMaxHealth);
	// States
	g_iClientStyle[client] = STYLE_SOLLY;


	// Times
	g_flClientFinishTime[client] = TIME_INVALID;

	for ( int i = 0; i < NUM_RUNS; i++ )
		for ( int k = 0; k < NUM_MODES; k++ )
			g_flClientBestTime[client][i][k] = TIME_INVALID;

	for (int i = 0; i < 100; i++)
		g_iClientCpsEntered[client][i] = false;

	// Practicing
	g_bClientPractising[client] = false;

	g_flClientWarning[client] = TIME_INVALID;


	// Welcome message for players.
	CreateTimer( 5.0, Timer_Connected, GetClientUserId( client ), TIMER_FLAG_NO_MAPCHANGE );


	// These are right below us.
}

public void IdleSys_OnClientIdle(int client) 
{
	CPrintToChat(client, CHAT_PREFIX... "You have been marked as idle");
	g_iClientIdle[client] = true;

	int time;
	GetMapTimeLeft(time);

	CheckRTV();
	
	VeVotersCount();
	if (g_VotesVe && 
		g_VotersVe && 
		g_VotesVe >= g_VotesNeededVe ) 
	{
		if (time > 180)
		{
			return;
		}
		
		StartVE();
	}
}

public void IdleSys_OnClientReturn(int client, int time) 
{
	CPrintToChat(client, CHAT_PREFIX... "You are no longer an idle");
	g_iClientIdle[client] = false;

	VeVotersCount();
	int time;
	GetMapTimeLeft(time);

	CheckRTV();

	if (g_VotesVe && 
		g_VotersVe && 
		g_VotesVe >= g_VotesNeededVe ) 
	{
		if (time > 180)
		{
			return;
		}
		
		StartVE();
	}
	return;
}
/*public Action IRCchat(int client, int args)
{
	char msg[256];
	GetCmdArgString(msg, sizeof(msg));
	int team;
	if (args <= 0 || msg[0] == ' ')
	{
		CPrintToChat(client, CHAT_PREFIX... "Try use {lightskyblue}!msg <message>");
		return Plugin_Handled;
	}
	
	char result[256];
	team = client ? IRC_GetTeamColor(GetClientTeam(client)) : 0;
	char clientname[MAX_NAME_LENGTH];
	Format(clientname, sizeof(clientname), "%N", client);
	ReplaceString(clientname, sizeof(clientname), ":", "ː");
	if (team == -1) {
		Format(result, sizeof(result), "%s: %s", clientname, msg);
	}
	else {
		Format(result, sizeof(result), "\x03%02d%s\x03: %s", team, clientname, msg);
	}

	IRC_MsgFlaggedChannels("relay", "%s", result);
	CPrintToChatAll("%s", result);
	return Plugin_Handled;
}*/

public void GetJoiningRank( int client )
{
	static char szQuery[162];
	static char szSteam[MAX_ID_LENGTH];

	if ( !GetClientSteam( client, szSteam, sizeof( szSteam ) ) ) return;
	
	g_hDatabase.Format( szQuery, sizeof( szQuery ), "SELECT solly, demo, srank, drank FROM "...TABLE_PLYDATA..." WHERE steamid = '%s'", szSteam );
			
			
	g_hDatabase.Query( Threaded_GetRank, szQuery, client, DBPrio_High );
}	

public void OnClientConnected(int client) {
	if (!secure)
	{
		if (GetClientCount(true) > 0)
		{
			secure = true;
			char time3[64];
			char map3[64];
			FormatTime(time3, sizeof(time3), "%Y-%m-%d_%H-%M-%S", GetTime());
			GetCurrentMap(map3, sizeof(map3));
			CreateTimer(0.0, Timer_Delay, _);
			STVTickStart = GetGameTickCount();
		}
	}

	/*
	httpClient = new HTTPClient("https://tempus.xyz");
	httpClient.SetHeader("Accept", "application/json");

	char req[96];
	Format(req, sizeof(req), "api/maps/name/%s/fullOverview",g_szCurrentMap);
	//Pass the client and the type of request to the data receiving function
	httpClient.Get(req, OnMapInfoGainedPR, client);*/
}

public void OnClientPostAdminCheck( int client )
{
	if ( !IsFakeClient( client ) )
	{
		DB_RetrieveClientData( client );
		GetJoiningRank(client);
		
		ClientConnectTime[client] = GetEngineTime();

		char query[200];
		DB_SaveClientData(client);

		char szSteam[100];
		GetClientSteam(client, szSteam, sizeof( szSteam ) );

		g_hDatabase.Format(query, sizeof(query), "SELECT id, run, style, mode, min(time) FROM "...TABLE_CP_RECORDS..." where uid = (select uid from plydata where steamid = '%s') and map = '%s' group by id", szSteam, g_szCurrentMap);
		g_hDatabase.Query( Threaded_Init_CP_PR_Times, query, client, DBPrio_High );

		g_hDatabase.Format(query, sizeof(query), "Update plydata set online = 1 where steamid = '%s'", szSteam);
		SQL_TQuery(g_hDatabase, Threaded_Empty, query, client);
		// Get their Id and other settings from DB.
	}	
}

public void OnClientDisconnect( int client )
{
	if ( IsFakeClient( client ) )
	{
		return;
	}
	
	SDKUnhook( client, SDKHook_OnTakeDamage, Event_OnTakeDamage_Client );
	SDKUnhook( client, SDKHook_SetTransmit, Event_SetTransmit_Client );
	SDKUnhook( client, SDKHook_WeaponDropPost, Event_WeaponDropPost );
	SDKUnhook( client, SDKHook_GetMaxHealth, OnGetMaxHealth);

	char name[99];
		
	GetClientName(client, name, sizeof(name));

	CPrintToChatAll("{lightskyblue}%s {white}has left the server.", name);	
	
	g_bRockTheVote[client] = false;
	g_cNominatedMap[client][0] = '\0';
	g_iClientIdle[client] = false;

	g_VotedVe[client] = false;
	
	CheckRTV();

	ranksolly[client] = -1;
 	rankdemo[client] = -1;

 	for (int i = 0; i < 3; i++)
 	{
 		g_SavePointOrig[client][i] = 0.0;
 		g_SavePointEye[client][i] = 0.0;
 		g_fClientRespawnPosition[client][i] = 0.0;
 		g_fClientRespawnAngles[client][i] = 0.0;
 	}

 	for (int i = 0; i < NUM_RUNS; i++)
 	{
 		for (int a = 0; a < NUM_MODES; a++)
 			g_TempusPrTime[client][i][a] = TIME_INVALID;
 	}

	char szSteam[100];
	GetClientSteam(client, szSteam, sizeof( szSteam )	);
	char szQuery[192];
	char sTime[32];
	FormatTime(sTime, sizeof(sTime), "%Y-%m-%d %H:%M:%S", GetTime() );

	Weather_delayTime[client] = 0.0;
	ClientConnectTime[client] = GetEngineTime() - ClientConnectTime[client];

	// Id can be 0 if quitting before getting authorized.
	if (g_iClientId[client] > 0)
	{
		FormatEx( szQuery, sizeof( szQuery ), "UPDATE "...TABLE_PLYDATA..." SET hideflags = %i, lastseen = CURRENT_TIMESTAMP, total_hours = total_hours + %.1f, online = 0 WHERE steamid = '%s'",
		g_fClientHideFlags[client],
		ClientConnectTime[client],
		szSteam );
		SQL_TQuery(g_hDatabase, Threaded_Empty, szQuery, client);

		DB_SaveClientData(client);
	}

	RemoveAllPrevMenus(client);

	if ( g_iBuilderZone[client] != ZONE_INVALID )
	{
		ResetBuilding( client );

		g_iBuilderZoneIndex[client] = ZONE_INVALID;
	}

	g_bStartBuilding[client] = false;

	if ( g_hClientCPData[client] != null ) { delete g_hClientCPData[client]; g_hClientCPData[client] = null; }

}

public void DB_Completions( int client, int uid, int style )
{
	char szQuery[192];
	db_style[client] = style;
	FormatEx( szQuery, sizeof( szQuery ), "SELECT map, recordid, style FROM "...TABLE_RECORDS..." WHERE uid = %i AND run = 0 AND style = %i",
	uid,
	style );
	g_hDatabase.Query( Threaded_Completions, szQuery, GetClientUserId( client ), DBPrio_Normal );
}

public void DB_TopTimes( int client, int style )
{
	char szQuery[192];

	Transaction t = new Transaction();
	g_hDatabase.Format( szQuery, sizeof( szQuery ), "SELECT %i", style);
	t.AddQuery(szQuery);
	g_hDatabase.Format( szQuery, sizeof( szQuery ), "SELECT map, style, run, `rank` FROM "...TABLE_RECORDS..." WHERE uid = %i AND style = %i AND `rank` > 1 AND `rank` < 11",
	db_id[client],
	style );
	t.AddQuery(szQuery);
	g_hDatabase.Execute(t, Threaded_TopTimes, _, client);
}

public void Threaded_TopTimes(Database g_hDatabase, any client, int numQueries, DBResultSet[] results, any[] queryData)
{
	Menu mMenu;
	mMenu = new Menu( Handler_TopTimes );

	char map[32], info[50];
	int run, rank, count=0, num=0;
	
	results[0].FetchRow();
	int style = results[0].FetchInt(0);

	mMenu.SetTitle("<Top Times> :: %s\nPlayer: %s\n ", g_szStyleName[NAME_LONG][style], DBS_Name[client] );

	while (results[1].FetchRow())
	{
		num++;
		count++;
		results[1].FetchString( 0, map, sizeof(map));
		run = results[1].FetchInt(2);
		rank = results[1].FetchInt(3);
		if (count != 6)
		{
			FormatEx(info, sizeof(info), "%s [#%i] [%s]", map, rank, g_szRunName[NAME_SHORT][run]);
			mMenu.AddItem("", info, ITEMDRAW_DISABLED);
		}

		if (count == 6)
		{	
			FormatEx(info, sizeof(info), "%s [#%i] [%s]\n ", map, rank, g_szRunName[NAME_SHORT][run]);
			mMenu.AddItem("", info, ITEMDRAW_DISABLED);

			if (style == STYLE_SOLLY)
			{
				mMenu.AddItem("a", "[Soldier]", ITEMDRAW_CONTROL);
			}
			else
			{
				mMenu.AddItem("b", "[Demoman]", ITEMDRAW_CONTROL);
			}
			count = 0;
		}
	}
	if (0 < count < 6)
	{
		for (int i = 1; i <= (6 - count); i++)
		{
			mMenu.AddItem("","", ITEMDRAW_SPACER);
		}
		if (style == STYLE_SOLLY)
		{
			mMenu.AddItem("a", "[Soldier]", ITEMDRAW_CONTROL);
		}
		else
		{
			mMenu.AddItem("b", "[Demoman]", ITEMDRAW_CONTROL);
		}
	}

	if (num == 0)
	{
		for (int i = 1; i < 7; i++)
		{
			mMenu.AddItem("","", ITEMDRAW_SPACER);
		}
		if (style == STYLE_SOLLY)
		{
			mMenu.AddItem("a", "[Soldier]", ITEMDRAW_CONTROL);
		}
		else
		{
			mMenu.AddItem("b", "[Demoman]", ITEMDRAW_CONTROL);
		}
	}	
	mMenu.ExitBackButton = (GetLastPrevMenuIndex(client) != -1) ? true : false;
	SetNewPrevMenu(client, mMenu);
	mMenu.Display( client, MENU_TIME_FOREVER );
}

public int Handler_TopTimes( Menu mMenu, MenuAction action, int client, int item )
{
	if ( action == MenuAction_End ) { delete mMenu; return 0; }
	if ( action == MenuAction_Cancel)
	{
	    if (item == MenuCancel_ExitBack)
		{
			RemoveLastPrevMenu(client);
			CallPrevMenu(client);
			return 0;
	    }
	}
	if ( action != MenuAction_Select ) { return 0; }
	if ( action == MenuAction_Select )
	{
		char szId[10];
		GetMenuItem( mMenu, item, szId, sizeof( szId ) );
		if (StrEqual(szId, "a"))
		{
			RemoveLastPrevMenu(client);
			DB_TopTimes(client, STYLE_DEMOMAN);
		}
		if (StrEqual(szId, "b"))
		{
			RemoveLastPrevMenu(client);
			DB_TopTimes(client, STYLE_SOLLY);
		}
	}
	return 0;
}

public void DB_RecTimes( int client, int style )
{
	char szQuery[192];

	Transaction t = new Transaction();

	g_hDatabase.Format( szQuery, sizeof( szQuery ), "SELECT %i", style);
	t.AddQuery(szQuery);
	g_hDatabase.Format( szQuery, sizeof( szQuery ), "SELECT map, run FROM "...TABLE_RECORDS..." WHERE uid = %i AND style = %i AND `rank` = 1",
	db_id[client],
	style );
	t.AddQuery(szQuery);
	g_hDatabase.Execute(t, Threaded_WorldRecords, _, client);
}

public void Threaded_WorldRecords(Database g_hDatabase, any client, int numQueries, DBResultSet[] results, any[] queryData)
{
	Menu mMenu;
	mMenu = new Menu( Handler_RecTimes );
	char map[32], info[50];
	int run, style, count = 0;

	results[0].FetchRow();
	style = results[0].FetchInt(0);

	mMenu.SetTitle("<World Records> :: %s\nPlayer: %s\n ", g_szStyleName[NAME_LONG][style], DBS_Name[client] );

	if (results[1].RowCount)
	{
		while (results[1].FetchRow())
		{
			count++;
			results[1].FetchString( 0, map, sizeof(map));
			run = results[1].FetchInt(1);
			if (count != 6)
			{
				FormatEx(info, sizeof(info), "%s [%s]", map, g_szRunName[NAME_SHORT][run]);
				mMenu.AddItem("", info, ITEMDRAW_DISABLED);
			}

			if (count == 6)
			{
						
				FormatEx(info, sizeof(info), "%s [%s]\n ", map, g_szRunName[NAME_SHORT][run]);
				mMenu.AddItem("", info, ITEMDRAW_DISABLED);

				if (style == STYLE_SOLLY)
				{
					mMenu.AddItem("a", "[Soldier]");
				}
				else
				{
					mMenu.AddItem("b", "[Demoman]");
				}
				count = 0;
			}
		}
		if (0 < count < 6)
		{
			for (int i = 1; i <= (6 - count); i++)
			{
				mMenu.AddItem("","", ITEMDRAW_SPACER);
			}
			if (style == STYLE_SOLLY)
			{
				mMenu.AddItem("a", "[Soldier]");
			}
			else
			{
				mMenu.AddItem("b", "[Demoman]");
			}
		}
	}
	else
	{
		for (int i = 1; i < 7; i++)
		{
			mMenu.AddItem("","", ITEMDRAW_SPACER);
		}
		if (style == STYLE_SOLLY)
		{
			mMenu.AddItem("a", "[Soldier]");
		}
		else
		{
			mMenu.AddItem("b", "[Demoman]");
		}
	}
	mMenu.ExitBackButton = (GetLastPrevMenuIndex(client) != -1) ? true : false;
	SetNewPrevMenu(client,mMenu);
	mMenu.Display( client, MENU_TIME_FOREVER );
}

public int Handler_RecTimes( Menu mMenu, MenuAction action, int client, int item )
{
	if ( action == MenuAction_End ) { delete mMenu; return 0; }
	if ( action == MenuAction_Cancel)
	{
	    if (item == MenuCancel_ExitBack)
		{
			RemoveLastPrevMenu(client);
			CallPrevMenu(client);
	    }
	}
	if ( action != MenuAction_Select ) { return 0; }
	if ( action == MenuAction_Select )
	{
		char szId[10];
		GetMenuItem( mMenu, item, szId, sizeof( szId ) );
		if (StrEqual(szId, "a"))
		{
			RemoveLastPrevMenu(client);
			DB_RecTimes(client, STYLE_DEMOMAN);
		}
		if (StrEqual(szId, "b"))
		{
			RemoveLastPrevMenu(client);
			DB_RecTimes(client, STYLE_SOLLY);
		}
	}
	return 0;
}

stock void ChangeClientState( int client, PlayerState state )
{
	if ( g_iClientState[client] != state )
	{
		Call_StartForward( g_hForward_Timer_OnStateChanged );
		Call_PushCell( client );
		Call_PushCell( state );
		Call_Finish();

		g_iClientState[client] = state;
	}
}

stock void GetStylePostfix( int mode, char szTarget[STYLEPOSTFIX_LENGTH], bool bShort = false )
{
}

stock void TeleportPlayerToStart( int client )
{

	g_flClientStartTime[client] = TIME_INVALID;
	ChangeClientState( client, STATE_SETSTART );


	if(g_fClientRespawnPosition[client][0] != 0){
		TeleportEntity(client, g_fClientRespawnPosition[client], g_fClientRespawnAngles[client], g_vecNull);
		//SetPlayerPractice(client, true);
		return;
	}


	if ( g_bIsLoaded[RUN_MAIN] )
	{
		TeleportEntity( client, g_vecSpawnPos[RUN_MAIN], g_vecSpawnAngles[RUN_MAIN], g_vecNull );
	}
	if ( g_bIsLoaded[RUN_COURSE1] )
	{
		TeleportEntity( client, g_vecSpawnPos[RUN_COURSE1], g_vecSpawnAngles[RUN_COURSE1], g_vecNull );
	
	}
}

stock void SetPlayerStyle( int client, int reqstyle )
{
	g_iClientStyle[client] = reqstyle;
	PrintStyle( client );
}

stock void SetPlayerMode( int client, int mode )
{
	mode = getClass(client);

	g_iClientMode[client] = mode;

	PrintStyle( client );

}

stock void PrintStyle( int client )
{
	char szStyleFix[STYLEPOSTFIX_LENGTH];
	GetStylePostfix( g_iClientMode[client], szStyleFix );
}

stock void RespawnPlayerRun( int client)
{
	if(g_fClientRespawnPosition[client][0] != 0){
		if (TF2_GetPlayerClass(client) == TFClass_DemoMan) {
			SetEntityGravity(client, 1.0);
			SetEntityHealth(client, 175);
		   	DestroyProjectilesDemo(client);
		} else if (TF2_GetPlayerClass(client) == TFClass_Soldier) {
			SetEntityGravity(client, 1.0);
		    DestroyProjectilesSoldier(client);
		}

		TeleportEntity(client, g_fClientRespawnPosition[client], g_fClientRespawnEyes[client], g_vecNull );
		
		//SetPlayerPractice(client, true);
		return;
	}
	if ( !g_bIsLoaded[RUN_MAIN] && !g_bIsLoaded[RUN_COURSE1] )
	{
		CPrintToChat( client, CHAT_PREFIX..."%s is not available!", g_szRunName[NAME_LONG][RUN_MAIN] );
		return;
	}
	if ( !IsPlayerAlive( client ) )
	{
		return;
	}
	if ( g_bIsLoaded[RUN_COURSE1] )
	{
		if (TF2_GetPlayerClass(client) == TFClass_DemoMan) {
			SetEntityGravity(client, 1.0);
			SetEntityHealth(client, 175);
		   	DestroyProjectilesDemo(client);
		} else if (TF2_GetPlayerClass(client) == TFClass_Soldier) {
			SetEntityGravity(client, 1.0);
		    DestroyProjectilesSoldier(client);
		}
		SetPlayerRun(client, RUN_COURSE1);
		return;
	}
	if ( g_bIsLoaded[RUN_MAIN] )
	{
		if (TF2_GetPlayerClass(client) == TFClass_DemoMan) {
			SetEntityGravity(client, 1.0);
			SetEntityHealth(client, 175);
		   	DestroyProjectilesDemo(client);
		} else if (TF2_GetPlayerClass(client) == TFClass_Soldier) {
			SetEntityGravity(client, 1.0);
		    DestroyProjectilesSoldier(client);
		}
		SetPlayerRun(client, RUN_MAIN);
		return;
	}
	if (TF2_GetPlayerClass(client) == TFClass_DemoMan) {
		SetEntityGravity(client, 1.0);
		SetEntityHealth(client, 175);
	   	DestroyProjectilesDemo(client);
	} else if (TF2_GetPlayerClass(client) == TFClass_Soldier) {
		SetEntityGravity(client, 1.0);
		DestroyProjectilesSoldier(client);
	}
}

stock void SetPlayerRun( int client, int reqrun )
{
	if ( !g_bIsLoaded[reqrun] )
	{
		CPrintToChat( client, CHAT_PREFIX..."%s is not available!", g_szRunName[NAME_LONG][reqrun] );
		return;
	}

	if ( !IsPlayerAlive( client ) )
	{
		CPrintToChat( client, CHAT_PREFIX..."You must be alive to change your run!" );
		return;
	}


	TeleportPlayerToStart( client );

}

public void CheckpointTimes( int client, int uid, char[] map, int mode )
{
	char query[800];
	g_hDatabase.Format(query, sizeof(query), "SELECT id, (select @curId := id), time, (select time from maprecs where uid = %i and map = '%s' and run = 0 and mode = %i), (select time from maprecs where map = '%s' and run = 0 and mode = %i order by time ASC limit 1), (SELECT time FROM mapcprecs WHERE uid = (select maprecs.uid from maprecs where maprecs.map = '%s' and maprecs.run = mapcprecs.run and maprecs.mode = mapcprecs.mode order by maprecs.time ASC limit 1) and map = '%s' and run = 0 and mode = %i and id = (@curId) ORDER BY id ASC) FROM "...TABLE_CP_RECORDS..." WHERE map = '%s' and mode = %i and uid = %i ORDER BY id ASC", uid, map, mode, map, mode, map, map, mode, map, mode, uid);

	g_hDatabase.Query(Threaded_Checkpoint_Times, query, client);
}

public void Threaded_Checkpoint_Times( Database hOwner, DBResultSet hQuery, const char[] szError, int client )
{
	if ( hQuery == null )
	{
		DB_LogError( szError );
		
		return;
	}

	char buffer[60];
	char buffermap[80];
	int count = 0;
	Menu mMenu = new Menu(checkpoint_control);
	mMenu.SetTitle("<Map PR vs WR :: %s Checkpoint Entry>\nPlayer: %s\nMap: %s\n ", (profile_mode[client] == MODE_SOLDIER) ? "Soldier" : "Demoman", profile_playername[client], profile_map[client]);
	char szInterval[TIME_SIZE_DEF];
	char szTime[TIME_SIZE_DEF];
	char szIntervalMap[TIME_SIZE_DEF];
	char szTimeMap[TIME_SIZE_DEF];

	char ClassChange[30];
	FormatEx(ClassChange, sizeof(ClassChange), "[%s]", (profile_mode[client] == MODE_SOLDIER) ? "Demoman" : "Soldier");

	if (hQuery.RowCount)
	{
		if ( hQuery.FetchRow() )
		{
			count++;
			int id = hQuery.FetchInt( 0 ) + 1;
			int prefixmap;
			float time = hQuery.FetchFloat( 2 );
			float wrtime = hQuery.FetchFloat( 5 );

			float prtime = hQuery.FetchFloat( 3 );
			float wrtimemap = hQuery.FetchFloat( 4 );
			float intervalmap;

			if (prtime >= wrtimemap )
			{
				intervalmap = prtime - wrtimemap;
				prefixmap = '+';
			}
			else
			{
				intervalmap = wrtimemap - prtime;
				prefixmap = '-';
			}

			FormatSeconds( prtime, szTimeMap, FORMAT_2DECI );
			FormatSeconds( intervalmap, szIntervalMap, FORMAT_2DECI );

			FormatEx(buffermap,sizeof(buffermap),"Total:          %s (%c%s)\n ", szTimeMap, prefixmap, szIntervalMap );
			int prefix;
			float interval;
			if (time >= wrtime )
			{
				interval = time - wrtime;
				prefix = '+';
			}
			else
			{
				interval = wrtime - time;
				prefix = '-';
			}
			
			FormatSeconds( time, szTime, FORMAT_2DECI );
			FormatSeconds( interval, szInterval, FORMAT_2DECI );

			FormatEx(buffer,sizeof(buffer),"[CP %i]:        %s (%c%s)", id, szTime, prefix, szInterval );
			mMenu.AddItem("", buffer, ITEMDRAW_DISABLED );	
		}
		while ( hQuery.FetchRow() )
		{
			count++;
			int id = hQuery.FetchInt( 0 ) + 1;
			float time = hQuery.FetchFloat( 2 );
			float wrtime = hQuery.FetchFloat( 5 );
			int prefix;
			float interval;
			if (time >= wrtime )
			{
				interval = time - wrtime;
				prefix = '+';
			}
			else
			{
				interval = wrtime - time;
				prefix = '-';
			}
			
			FormatSeconds( time, szTime, FORMAT_2DECI );
			FormatSeconds( interval, szInterval, FORMAT_2DECI );
			if (count != 6)
			{
				FormatEx(buffer,sizeof(buffer),"[CP %i]:        %s (%c%s)", id, szTime, prefix, szInterval );
				mMenu.AddItem("", buffer, ITEMDRAW_DISABLED );
			}
			if (count == 6)
			{
				FormatEx(buffer,sizeof(buffer),"[CP %i]:        %s (%c%s)\n ", id, szTime, prefix, szInterval );
				mMenu.AddItem("", buffer, ITEMDRAW_DISABLED );

				mMenu.AddItem("", ClassChange);
				count = 0;
			}	
		}

		mMenu.AddItem("", buffermap, ITEMDRAW_DISABLED );
		count++;

		for (int i = 1; i <= (6 - count); i++)
		{
			mMenu.AddItem("","", ITEMDRAW_SPACER);
		}
		mMenu.AddItem("", ClassChange);
	}
	else
	{
		mMenu.AddItem("", "Failed to load checkpoint times.", ITEMDRAW_DISABLED );	
		for (int i = 1; i < 6; i++)
		{
			mMenu.AddItem("","", ITEMDRAW_SPACER);
		}
		mMenu.AddItem("", ClassChange);
	}
	
	mMenu.ExitBackButton = true;
	mMenu.Display(client, MENU_TIME_FOREVER);
}

public int checkpoint_control(Menu mMenu, MenuAction action, int client, int item) {
	if (action == MenuAction_Cancel) {
		if(item == MenuCancel_ExitBack) {
			//Back to top times
			Call_StartFunction(INVALID_HANDLE, Func);
		    Call_PushCell(client);
		    Call_PushCell(DemoInfoId[client]);

		    Call_Finish();
		    delete mMenu;
		    return 0;
		}
	}

	if (action == MenuAction_Select)
	{
		if (profile_mode[client] == MODE_SOLDIER)
		{
			profile_mode[client] = MODE_DEMOMAN;
			CheckpointTimes( client, db_id[client], profile_map[client], MODE_DEMOMAN );
			delete mMenu;
			return 0;
		}
		else
		{
			profile_mode[client] = MODE_SOLDIER;
			CheckpointTimes( client, db_id[client], profile_map[client], MODE_SOLDIER );
			delete mMenu;
			return 0;
		}
	}
	return 0;
}

stock void SetPlayerPractice( int client, bool mode )
{

	if ( mode )
	{
		if ( mode != g_bClientPractising[client] && !IsSpamming( client ) )
			CPrintToChat( client, CHAT_PREFIX..."Timer disabled! Type {lightskyblue}!timer{white} to enable." );
	}
	else
	{
		if ( g_iClientState[client] != STATE_START )
			TeleportPlayerToStart( client );
		}

		if ( mode != g_bClientPractising[client] && !IsSpamming( client ) )
		{
			SetEntityMoveType( client, MOVETYPE_WALK );
			CPrintToChat( client, CHAT_PREFIX..."Timer enabled" );
			RegenOn[client] = false;
	}

	g_bClientPractising[client] = mode;
}

stock bool IsSpamming( int client )
{
	if ( g_flClientWarning[client] > GetEngineTime() )
	{
		return true;
	}

	g_flClientWarning[client] = GetEngineTime() + WARNING_INTERVAL;

	return false;
}

stock bool IsSpammingCommand( int client )
{
	if ( IsSpamming( client ) )
	{
		CPrintToChat( client, CHAT_PREFIX..."Please wait before using this command again, thanks." );
		return true;
	}

	return false;
}

stock bool IsAllowedStyle( int style )
{
	switch( style )
	{
		case STYLE_SOLLY : return true;
		case STYLE_DEMOMAN : return GetConVarBool( g_ConVar_Allow_AutoBhop );
	}

	return false;
}

stock void SetupZoneSpawns()
{
	// Find an angle for the starting zones.
	// Find suitable team for players.
	// Spawn block zones.
	bool	bFoundAng[NUM_RUNS];
	float	vecAngle[3];
	int		ent = -1;

	while ( (ent = FindEntityByClassname( ent, "info_teleport_destination" )) != -1 )
	{
		for (int i = 0; i < NUM_RUNS+20; i+=2 )
		{
			if ( g_bZoneExists[i][0] && !bFoundAng[i/2] && IsInsideBounds( ent, g_vecZoneMins[i][0], g_vecZoneMaxs[i][0] ) )
			{
				GetEntPropVector( ent, Prop_Data, "m_angRotation", vecAngle );

				ArrayCopy( vecAngle, g_vecSpawnAngles[i/2], 2 );

				bFoundAng[i/2] = true;
			}
		}
	}

	// Give each starting zone a spawn position.
	// If no angle was previous found, we make it face the ending trigger.
	for (int i = 0; i < NUM_RUNS+20; i+=2 )
	{
		if ( g_bZoneExists[i][0] )
		{
			if (!isSetCustomStart[i/2])
			{
				g_vecSpawnPos[i/2][0] = g_vecZoneMins[i][0][0] + ( g_vecZoneMaxs[i][0][0] - g_vecZoneMins[i][0][0] ) / 2;
				g_vecSpawnPos[i/2][1] = g_vecZoneMins[i][0][1] + ( g_vecZoneMaxs[i][0][1] - g_vecZoneMins[i][0][1] ) / 2;
				g_vecSpawnPos[i/2][2] = g_vecZoneMins[i][0][2] + 16.0;
			}
			else 
			{
				g_vecSpawnPos[i/2][0] = g_CustomRespawnPos[i/2][0];
				g_vecSpawnPos[i/2][1] = g_CustomRespawnPos[i/2][1];
				g_vecSpawnPos[i/2][2] = g_CustomRespawnPos[i/2][2];
				g_vecSpawnAngles[i/2][1] = g_CustomRespawnAng[i/2][1];
			}
			// Direction of the end!
			if ( !bFoundAng[i/2] )
			{
				if (!isSetCustomStart[i/2])
					g_vecSpawnAngles[i/2][1] = ArcTangent2( g_vecZoneMins[i+1][0][1] - g_vecZoneMins[i][0][1], g_vecZoneMins[i+1][0][0] - g_vecZoneMins[i][0][0] ) * 180 / MATH_PI;
				else
					ArrayCopy(g_CustomRespawnAng[i/2], g_vecSpawnAngles[i/2], 1 );
			}
		}
	}
}

stock void CreateZoneEntity( int zone )
{
	int iData[ZONE_SIZE];
	g_hZones.GetArray( zone, iData, view_as<int>( ZoneData ) );

	float vecMins[3];
	float vecMaxs[3];

	ArrayCopy( iData[ZONE_MINS], vecMins, 3 );
	ArrayCopy( iData[ZONE_MAXS], vecMaxs, 3 );

	int ent;
	if ( !(ent = CreateTrigger( vecMins, vecMaxs )) )
	{
		LogError("Cant create trigger");
		return;
	}

	SetTriggerIndex( ent, zone );

	switch ( iData[ZONE_TYPE] )
	{
		case ZONE_BLOCKS :
		{
			SDKHook( ent, SDKHook_StartTouchPost, Event_StartTouchPost_Block );
		}
		case ZONE_COURCE :
		{
			SDKHook( ent, SDKHook_StartTouchPost, Event_StartTouchPost_NextCours );
		}
		case ZONE_SKIP :
		{
			SDKHook( ent, SDKHook_StartTouchPost, Event_StartTouchPost_Skip );
		}
		default :
		{
			SDKHook( ent, SDKHook_Touch, Event_Touch_Zone );
			SDKHook( ent, SDKHook_EndTouch, Event_EndTouchPost_Zone );
		}
	}

	g_hZones.Set( zone, EntIndexToEntRef( iData[ZONE_ID] ), view_as<int>( ZONE_ENTREF ) );
	g_hZones.Set( zone, ent, view_as<int>( ZONE_ENT ) );
}

stock void CreateCheckPoint( int cp )
{
	int iData[CP_SIZE];
	g_hCPs.GetArray( cp, iData, view_as<int>( CPData ) );

	float vecMins[3];
	float vecMaxs[3];

	ArrayCopy( iData[CP_MINS], vecMins, 3 );
	ArrayCopy( iData[CP_MAXS], vecMaxs, 3 );

	int ent;
	if ( !(ent = CreateTrigger( vecMins, vecMaxs )) )
		return;

	SetTriggerIndex( ent, cp );
	SDKHook( ent, SDKHook_Touch, Event_StartTouchPost_CheckPoint );

	g_hCPs.Set( cp, EntIndexToEntRef( ent ), view_as<int>( CP_ENTREF ) );
}

stock int GetTriggerIndex( int ent )
{
	return GetEntProp( ent, Prop_Data, "m_iHealth" );
}

stock int SetTriggerIndex( int ent, int index )
{
	SetEntProp( ent, Prop_Data, "m_iHealth", index );
}

stock int FindCPIndex( int run, int id )
{
	int len = g_hCPs.Length;

	for ( int i = 0; i < len; i++ )
		if ( g_hCPs.Get( i, view_as<int>( CP_ID ) ) == id )
		{
			return i;
		}

	return -1;
}

stock void SetWrCpTime( int index, int mode, float flTime )
{
	f_CpWr[mode][index] = flTime;

	return;
}

stock void SetPrCpTime( int index, int mode, float flTime, int client  )
{
	f_CpPr[client][mode][index] = flTime;

	return;
}

stock void DeleteZoneBeams( int zone, int id = 0, int index = 0 )
{
	for ( int i = 0; i < GetArraySize(g_hBeams); i++ )
	{
		if ( g_hBeams.Get( i, view_as<int>( BEAM_TYPE ) ) == zone && g_hBeams.Get( i, view_as<int>( BEAM_ID ) ) == id && g_hBeams.Get( i, view_as<int>( BEAM_INDEX ) ) == index )
		{
			g_hBeams.Erase( i );
			break;
		}
	}
	
	int ent = 0;
	for (int i=0; i < GetArraySize(g_hZones); i++)
	{
		if ( g_hZones.Get( i, view_as<int>( ZONE_TYPE ) ) == zone
			&& g_hZones.Get( i, view_as<int>( ZONE_ID ) ) == index )
		{
			ent = g_hZones.Get( i, view_as<int>( ZONE_ENT ) );
			SDKUnhook( ent, SDKHook_Touch, Event_Touch_Zone );
			SDKUnhook( ent, SDKHook_EndTouch, Event_EndTouchPost_Zone );
			return;
		}
	}

	LogError( CONSOLE_PREFIX..."Failed to remove zone beams!" );
}

stock void CreateZoneBeams( int zone, float vecMins[3], float vecMaxs[3], int id = 0, int index = 0 )
{
	// Called after zone mins and maxs are fixed.
	// Clock-wise (start from mins)

	int iData[BEAM_SIZE];
	float vecTemp[3];

	iData[BEAM_TYPE] = zone;
	iData[BEAM_ID] = id;
	iData[BEAM_INDEX] = index;

	// Bottom
	vecTemp[0] = vecMins[0] + ZONE_WIDTH;
	vecTemp[1] = vecMins[1] + ZONE_WIDTH;
	vecTemp[2] = vecMins[2] + ZONE_WIDTH;
	ArrayCopy( vecTemp, iData[BEAM_POS_BOTTOM1], 3 );

	vecTemp[0] = vecMaxs[0] - ZONE_WIDTH;
	vecTemp[1] = vecMins[1] + ZONE_WIDTH;
	vecTemp[2] = vecMins[2] + ZONE_WIDTH;
	ArrayCopy( vecTemp, iData[BEAM_POS_BOTTOM2], 3 );

	vecTemp[0] = vecMaxs[0] - ZONE_WIDTH;
	vecTemp[1] = vecMaxs[1] - ZONE_WIDTH;
	vecTemp[2] = vecMins[2] + ZONE_WIDTH;
	ArrayCopy( vecTemp, iData[BEAM_POS_BOTTOM3], 3 );

	vecTemp[0] = vecMins[0] + ZONE_WIDTH;
	vecTemp[1] = vecMaxs[1] - ZONE_WIDTH;
	vecTemp[2] = vecMins[2] + ZONE_WIDTH;
	ArrayCopy( vecTemp, iData[BEAM_POS_BOTTOM4], 3 );

	// Top
	vecTemp[0] = vecMins[0] + ZONE_WIDTH;
	vecTemp[1] = vecMins[1] + ZONE_WIDTH;
	vecTemp[2] = vecMaxs[2] - ZONE_WIDTH;
	ArrayCopy( vecTemp, iData[BEAM_POS_TOP1], 3 );

	vecTemp[0] = vecMaxs[0] - ZONE_WIDTH;
	vecTemp[1] = vecMins[1] + ZONE_WIDTH;
	vecTemp[2] = vecMaxs[2] - ZONE_WIDTH;
	ArrayCopy( vecTemp, iData[BEAM_POS_TOP2], 3 );

	vecTemp[0] = vecMaxs[0] - ZONE_WIDTH;
	vecTemp[1] = vecMaxs[1] - ZONE_WIDTH;
	vecTemp[2] = vecMaxs[2] - ZONE_WIDTH;
	ArrayCopy( vecTemp, iData[BEAM_POS_TOP3], 3 );

	vecTemp[0] = vecMins[0] + ZONE_WIDTH;
	vecTemp[1] = vecMaxs[1] - ZONE_WIDTH;
	vecTemp[2] = vecMaxs[2] - ZONE_WIDTH;
	ArrayCopy( vecTemp, iData[BEAM_POS_TOP4], 3 );

	g_hBeams.PushArray( iData, view_as<int>( BeamData ) );
}

stock void StartToBuild( int client, int zone, bool eye )
{
	if (zone < NUM_REALZONES)
	{
		for (int i=0; i < 30; i++)
		{
			if (g_bZoneExists[zone][i])
			{
				g_bZoneExists[zone][i]++;
			}
		}
	}

	static float vecPos[3];
	static float vecEye[3];
	static float end[3];
	if (eye)
	{
		GetClientEyePosition(client, vecPos);
		GetClientEyeAngles(client, vecEye);
	   	TR_TraceRayFilter(vecPos, vecEye, MASK_SOLID, RayType_Infinite, TraceEntityFilterPlayer, client);
		
		TR_GetEndPosition(end);
		
		g_vecBuilderStart[client][0] = end[0];
		g_vecBuilderStart[client][1] = end[1];
		g_vecBuilderStart[client][2] = float( RoundFloat( end[2] - 0.5 ) );
	}
	else
	{
		GetClientAbsOrigin( client, vecPos );
		
		g_vecBuilderStart[client][0] = vecPos[0];
		g_vecBuilderStart[client][1] = vecPos[1];
		g_vecBuilderStart[client][2] = float( RoundFloat( vecPos[2] - 0.5 ) );
	}

	if ( zone < NUM_REALZONES )
	{
		g_bZoneBeingBuilt[zone] = true;
	}

	SetPlayerPractice( client, true );

	g_iBuilderZone[client] = zone;

	if (eye)
		CreateTimer( ZONE_BUILD_INTERVAL, Timer_DrawBuildZoneBeamsEye, client, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE );
	else
		CreateTimer( ZONE_BUILD_INTERVAL, Timer_DrawBuildZoneBeamsOrigin, client, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE );

	if ( zone < NUM_REALZONES )
	{
		if (g_bZoneExists[zone][0])
			CPrintToChat( client, CHAT_PREFIX..."You started {lightskyblue}%s {white} zone! {white} :: index {orange}%i{white}::", g_szZoneNames[zone], ZoneIndex[client]+1 );
		else
			CPrintToChat( client, CHAT_PREFIX..."You started {lightskyblue}%s {white} zone!", g_szZoneNames[zone] );	
	}
}

stock void ResetBuilding( int client )
{
	if ( g_iBuilderZone[client] < NUM_REALZONES )
	{
		g_bZoneBeingBuilt[ g_iBuilderZone[client] ] = false;
	}

	g_iBuilderZone[client] = ZONE_INVALID;
}

stock bool HasScroll( int client )
{
	return ( g_iClientStyle[client] != STYLE_SOLLY );
}

stock void CheckZones()
{
	// Spawn zones and checkpoints if they do not exist.
	int len;
	int i;

	if ( g_hCPs != null )
	{
		len = g_hCPs.Length;

		for ( i = 0; i < len; i++ )
		{
			if ( EntRefToEntIndex( g_hCPs.Get( i, view_as<int>( CP_ENTREF ) ) ) < 1 )
			{
				CreateCheckPoint( i );
			}
		}
	}

	if ( g_hZones != null )
	{
		len = g_hZones.Length;
		int zone;
		for ( i = 0; i < len; i++ )
		{
			CreateZoneEntity( i );
		}
	}
}

stock TFClassType ClassTypeFromMode(int mode){
	switch (mode){
		case MODE_SCOUT:return TFClass_Scout;
		case MODE_SOLDIER:return TFClass_Soldier;
		case MODE_PYRO:return TFClass_Pyro;
		case MODE_DEMOMAN:return TFClass_DemoMan;
		case MODE_HEAVY:return TFClass_Heavy;
		case MODE_ENGINEER:return TFClass_Engineer;
		case MODE_SNIPER:return TFClass_Sniper;
		case MODE_MEDIC:return TFClass_Medic;
		case MODE_SPY:return TFClass_Spy;
	}
	return TFClass_Soldier;
}

stock void WipePlayer( int client, int id, char[] name )
{
	char yes[10];
	char szid[10];
	FormatEx(szid, sizeof( szid ), "%i", id);
	FormatEx(yes, sizeof( yes ), "Yes" );
	Menu mMenu;
	mMenu = new Menu( Handler_Wipe );
	mMenu.SetTitle("Wipe user :: %s <%i> ?\n ", name, id);
	mMenu.AddItem(szid, yes);
	mMenu.AddItem("", "No");
	mMenu.Display( client, MENU_TIME_FOREVER );

}

public int Handler_Wipe( Menu mMenu, MenuAction action, int client, int item )
{
	if ( action == MenuAction_End ) { delete mMenu; return 0; }
	if ( action != MenuAction_Select ) return 0;
	if ( action == MenuAction_Select )
	{
		char szId[12];
		GetMenuItem( mMenu, item, szId, sizeof( szId ) );
		int id = StringToInt(szId);
		if (item == 0)
		{
			char szQuery[192];
			FormatEx( szQuery, sizeof( szQuery ), "DELETE FROM "...TABLE_RECORDS..." WHERE uid = '%s'", szId );
			SQL_TQuery(g_hDatabase, Threaded_Empty, szQuery, client);
			FormatEx( szQuery, sizeof( szQuery ), "UPDATE "...TABLE_PLYDATA..." SET solly = 0.0, demo = 0.0, overall = 0.0, srank = -1, drank = -1, orank = -1 WHERE uid = '%s'", szId );
			SQL_TQuery(g_hDatabase, Threaded_Empty, szQuery, client);
			CPrintToChat(client, CHAT_PREFIX..."User has been {lightskyblue}wiped{white}!");
			for (int i = 1; i <= MaxClients; i++)
				if (IsClientInGame(i) && g_iClientId[i] == id)
				{
					ranksolly[i] = -1;
					rankdemo[i] = -1;
					g_iClientPoints[i] = 0.0;
					g_iClientPointsSolly[i] = 0.0;
					g_iClientPointsDemo[i] = 0.0;
					DB_RetrieveClientData(i);
					break;
				}
		}
	}
	return 0;
}	

stock void DoRecordNotification( int client, int run, int style, int mode, float flNewTime, float flOldBestTime, float flPrevMapBest )
{
	static char		szTxt[256];
	char			szImproveTime[TIME_SIZE_DEF];
	char			szStyleFix[STYLEPOSTFIX_LENGTH];
	char wr_notify[999];
	char update_records[200];
	char server_tag[15];
	GetStylePostfix( mode, szStyleFix, true );
	char			szFormTime[TIME_SIZE_DEF], szName[32];
	GetClientName( client, szName, sizeof( szName ) );
	FormatSeconds( flNewTime, szFormTime, FORMAT_2DECI );
	Format(server_tag, sizeof(server_tag), (ServerOSIsLinux) ? server_name[NAME_SHORT][server_id] : "LOCAL");

	char buffer[500];

	DiscordWebHook hook = new DiscordWebHook( WEBHOOK_SERVER_ACTIONS );


	static float flImprove;
	flImprove = flOldBestTime - flNewTime;
	
	if ( flPrevMapBest > flNewTime )
	{
		if (run == RUN_MAIN)
		{
			FormatEx( szTxt, sizeof( szTxt ), CHAT_PREFIX..."(%s%s) {green}%s {white}beat the %s record: {green}%s{white}! ",
		    g_szStyleName[NAME_SHORT][style], szStyleFix,
			szName,
			g_szRunName[NAME_LONG][run],
			szFormTime );

			requested = true;
			float flLeftSeconds;
			char wr_improve[TIME_SIZE_DEF];			

			flLeftSeconds = flPrevMapBest - flNewTime;

			FormatSeconds( flLeftSeconds, wr_improve, FORMAT_2DECI );

			FormatEx(buffer, sizeof(buffer), "(*%s*) **%N** Beat the **%s** • ***%s (WR -%s)!***", g_szModeName[NAME_SHORT][mode], client, g_szCurrentMap, szFormTime, wr_improve);

			hook.SetContent( buffer );
			hook.Send();

			Format(wr_notify, sizeof(wr_notify), "wrnotifycode| {lightskyblue}(%s) {white}:: (%s) {green}%N {white}broke the {lightskyblue}%s {white}:: {green}%s {white}({lightskyblue}WR -%s{white})!", server_tag, g_szModeName[NAME_SHORT][mode], client, g_szCurrentMap, szFormTime, wr_improve);
			if (IRC_Connected)
				SocketSend(ClientSocket, wr_notify, sizeof(wr_notify));
		}
		else
		{
			FormatEx( szTxt, sizeof( szTxt ), CHAT_PREFIX..."(%s%s) {green}%s {white}broke {lightskyblue}%s {green}%s{white}! ",
		    g_szStyleName[NAME_SHORT][style], szStyleFix,
			szName,
			g_szRunName[NAME_LONG][run],
			szFormTime );

			if (RUN_COURSE1 <= run <= RUN_COURSE10)
			{
				char wr_improve[TIME_SIZE_DEF];			

				float flLeftSeconds = flPrevMapBest - flNewTime;

				FormatSeconds( flLeftSeconds, wr_improve, FORMAT_2DECI );

				FormatEx(buffer, sizeof(buffer), "(*%s*) **%N** broke ***%s*** on **%s** • ***%s (WR -%s)!***", g_szModeName[NAME_SHORT][mode], client, g_szRunName[NAME_LONG][run], g_szCurrentMap, szFormTime, wr_improve);

				hook.SetContent( buffer );
				hook.Send();
			}

			Format(update_records, sizeof(update_records), "update_records");
			if (IRC_Connected)
				SocketSend(ClientSocket, update_records, sizeof(update_records));
		}
	}
	else if (run == RUN_MAIN)
	{
		FormatEx( szTxt, sizeof( szTxt ), CHAT_PREFIX..."(%s%s) {green}%s {white}map run: {green}%s",
			g_szStyleName[NAME_SHORT][style], szStyleFix,
			szName,
			szFormTime );
	}
	else
	{
		FormatEx( szTxt, sizeof( szTxt ), CHAT_PREFIX..."(%s%s) Completed {lightskyblue}%s {green}%s",
			g_szStyleName[NAME_SHORT][style], szStyleFix,
			g_szRunName[NAME_LONG][run],
			szFormTime );
	}

    if ( flPrevMapBest <= TIME_INVALID )
	{
		FormatEx( szTxt, sizeof( szTxt ), CHAT_PREFIX..."(%s%s) {green}%s {white}set the %s: {green}%s",
		    g_szStyleName[NAME_SHORT][style], szStyleFix,
			szName,
			g_szRunName[NAME_LONG][run],
			szFormTime );

		if (run == RUN_MAIN)
		{
			requested = true;
			float flLeftSeconds;
			char wr_improve[TIME_SIZE_DEF];

			flLeftSeconds = flPrevMapBest - flNewTime;

			FormatSeconds( flLeftSeconds, wr_improve, FORMAT_2DECI );

			FormatEx(buffer, sizeof(buffer), "(*%s*) **%N** Set the **%s** • ***%s***", g_szModeName[NAME_SHORT][mode], client, g_szCurrentMap, szFormTime);

			hook.SetContent( buffer );
			hook.Send();

			Format(wr_notify, sizeof(wr_notify), "wrnotifycode| {lightskyblue}(%s) {white}:: {green}%N {white}set the {lightskyblue}%s {white}:: {green}%s{white}!", server_tag, client, g_szCurrentMap, szFormTime);
			
			if (IRC_Connected)
				SocketSend(ClientSocket, wr_notify, sizeof(wr_notify));
		}
		else
		{
			Format(update_records, sizeof(update_records), "update_records");
			if (IRC_Connected)
				SocketSend(ClientSocket, update_records, sizeof(update_records));
		}
	}

	delete hook;

	if ( g_fClientHideFlags[client] & HIDEHUD_PRTIME )	
	{
		if ( flPrevMapBest <= TIME_INVALID )
		{
		}
		else 
		{
			float flLeftSeconds;
			int prefix = '+';

			if ( flNewTime < flOldBestTime )
			{
				flLeftSeconds = flOldBestTime - flNewTime;
				prefix = '-';
				
			}
			else
			{
				flLeftSeconds = flNewTime - flOldBestTime;
			}
			if ( flOldBestTime > TIME_INVALID )
			{
			FormatSeconds( flLeftSeconds, szFormTime, FORMAT_2DECI );
			FormatEx( szTxt, sizeof( szTxt ), "%s {white}({lightskyblue}PR %c%s{white})",
				szTxt,
				prefix,
				szFormTime );
			}
		}	
	}
	if ( flPrevMapBest > TIME_INVALID && !(g_fClientHideFlags[client] & HIDEHUD_PRTIME) )
	{
			float flLeftSeconds;
			int prefix = '+';

			if ( flNewTime < flPrevMapBest )
			{
				flLeftSeconds = flPrevMapBest - flNewTime;
				prefix = '-';
				
			}
			else
			{
				flLeftSeconds = flNewTime - flPrevMapBest;
			}

			FormatSeconds( flLeftSeconds, szFormTime, FORMAT_2DECI );
			Format( szTxt, sizeof( szTxt ), "%s {white}({lightskyblue}WR %c%s{white})",
				szTxt,
				prefix,
				szFormTime );	
	}
	if ( flOldBestTime > flNewTime )
	{
		FormatSeconds( flImprove, szImproveTime, FORMAT_2DECI );
		Format( szTxt, sizeof( szTxt ), "%s | %s improvement!",
		szTxt,
		szImproveTime );
	}


	int[] clients = new int[MaxClients];
	int numClients;

	if ( g_iClientRun[client] == RUN_MAIN || flPrevMapBest > flNewTime || flPrevMapBest <= TIME_INVALID )
	{
		for ( int i = 1; i <= MaxClients; i++ )
		{
			if ( IsClientInGame( i ) && !(g_fClientHideFlags[i] & HIDEHUD_ZONEMSG) )
			{
				if ( !(g_fClientHideFlags[i] & HIDEHUD_ZONEMSG) )
				{
					clients[numClients++] = i;
					CPrintToChat( i, "%s", szTxt );
				}
			}
		}
	}
	else 
	{
		for ( int i = 1; i <= MaxClients; i++ )
		{
			if ( i == client && IsClientInGame( i ) && !(g_fClientHideFlags[i] & HIDEHUD_ZONEMSG) )
			{
				SetGlobalTransTarget( i );
				if ( !(g_fClientHideFlags[i] & HIDEHUD_ZONEMSG))
				{
					CPrintToChat( i, "%s", szTxt );
				}
			}
			if (IsClientInGame(i) && !IsPlayerAlive(i) && !(g_fClientHideFlags[i] & HIDEHUD_ZONEMSG))
			{
				if (GetEntPropEnt(i, Prop_Send, "m_hObserverTarget") == client)
				{
					CPrintToChat( i, "%s", szTxt );
				}
			}
		}
	}

	if ( flNewTime >= flPrevMapBest && flPrevMapBest != TIME_INVALID )
	{
		if (run == RUN_MAIN)
			EmitSound( clients, numClients, g_szWinningSounds[0] );
		else if (RunIsCourse(run))
			EmitSoundToClient( client, g_szSoundsCourse[0] );
	}

	if ( flNewTime < flPrevMapBest || flPrevMapBest <= TIME_INVALID )
	{
		for ( int i = 1; i <= MaxClients; i++ )
		{
			if ( IsClientInGame( i ) && IsClientConnected( i ))
			{
				SetGlobalTransTarget( i );
				{
					if ( !(g_fClientHideFlags[i] & HIDEHUD_RECSOUNDS) )
					{
						if (run == RUN_MAIN)
							EmitSoundToClient( i, (i == client) ? g_szWrSounds[0] : g_szWrSoundsNo[0] );
						else if (RunIsCourse(run))
							EmitSoundToClient( i, g_szSoundsCourseWr[0] );
						else if (RunIsBonus(run))
							EmitSoundToClient( i, g_szWrSoundsBonus[0] );
					}
				}
			}
		}
	}
}

stock int FindEmptyMimic()
{
	for ( int i = 1; i <= MaxClients; i++ )
	{
		if ( IsClientInGame( i ) && IsFakeClient( i ) && !g_bClientMimicing[i] )
		{
			return i;
		}
	}

	return 0;
}

stock void SpawnPlayer( int client )
{
	// Spawning players are automatically teleported to start.
	if (  view_as<int>(GetClientTeam( client )) <=  view_as<int>(TFTeam_Spectator) )
	{
		TF2_RespawnPlayer( client );
	}
	else if ( !IsPlayerAlive( client ) || !g_bIsLoaded[ RUN_MAIN ] )
	{
		TF2_RespawnPlayer( client );
	}
	else
	{
		TeleportPlayerToStart( client );
	}


	if (TF2_GetPlayerClass(client) == TFClass_Soldier)
	{
   		SetPlayerStyle( client, STYLE_SOLLY );
	}
	if (TF2_GetPlayerClass(client) == TFClass_DemoMan)
	{
   		SetPlayerStyle( client, STYLE_DEMOMAN );
	}
	if (TF2_GetPlayerClass(client) != TFClass_Soldier && TF2_GetPlayerClass(client) != TFClass_DemoMan)
	{
		CPrintToChat( client, CHAT_PREFIX..."Timer works only for {lightskyblue}Demoman {white}and {lightskyblue}Soldier");
		SetPlayerPractice( client, true );
	}
}

stock bool IsValidCommandUser( int client )
{
	if ( !IsPlayerAlive( client ) )
	{
		CPrintToChat( client, CHAT_PREFIX..."You must be alive to use this command!" );
		return false;
	}

	return true;
}

public int getClass(int client)
{
	int class = 0;
	if (IsClientInGame(client) && IsPlayerAlive(client))
	{

		TFClassType playerClass = TF2_GetPlayerClass(client);

		switch(playerClass)
		{
			case TFClass_Scout    : class = 0;
			case TFClass_Soldier  : class = 1;
			case TFClass_Pyro     : class = 2;
			case TFClass_DemoMan  : class = 3;
			case TFClass_Heavy    : class = 4;
			case TFClass_Engineer : class = 5;
			case TFClass_Sniper   : class = 6;
			case TFClass_Medic    : class = 7;
			case TFClass_Spy      : class = 8;
		}
	}
	return class;
}



