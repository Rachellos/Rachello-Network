
#if defined _Timer_core_included
	#endinput
#endif
#define _Timer_core_included


#define PLUGIN_VERSION_CORE	"2.2"
#define PLUGIN_AUTHOR_CORE	"Rachello"
#define PLUGIN_NAME_CORE	"Rachello Debug | "
#define PLUGIN_URL_CORE		"https://github.com/Rachellos"


#define CONSOLE_PREFIX		"["...PLUGIN_NAME_CORE..."] " // Used only for console/server.

#define BRUSH_MODEL				"models/props/cs_office/vending_machine.mdl"

#define CHAT_PREFIX		"\x07C8C8C8Rachellos| {white}"
#define CHAT_PREFIX_TIP		"\x07C8C8C8Hint| {white}"

#define NUM_REALZONES	42
#define NUM_REALZONES2	21
#define STYLEPOSTFIX_LENGTH		10
#define ZONE_SIZE			60
#define BEAM_SIZE		100
#define CP_INDEX_PRTIME		3
#define C_CP_SIZE		3


enum
{
	STYLE_INVALID = -1,
	
	STYLE_SOLLY,
	STYLE_DEMOMAN,
	NUM_STYLES
};

enum
{
	MODE_SCOUT2,
	MODE_SOLDIER2,
	MODE_PYRO2,
	MODE_DEMOMAN2,

	NUM_MODES2
};

enum
{
	MODE_INVALID = -1,
	 
	MODE_SCOUT,
	MODE_SOLDIER,
	MODE_PYRO,
	MODE_DEMOMAN,
	MODE_HEAVY,
	MODE_ENGINEER,
	MODE_SNIPER,
	MODE_MEDIC,
	MODE_SPY,
	
	NUM_MODES
};

#define CP_SIZE				40 + ( NUM_STYLES * NUM_MODES )

//////////////////////
// ZONE/MODES ENUMS //
//////////////////////
enum
{
	ZONE_INVALID = -1,
	ZONE_START,
	ZONE_END,
	ZONE_COURSE_1_START,
	ZONE_COURSE_1_END,
	ZONE_COURSE_2_START,
	ZONE_COURSE_2_END,
	ZONE_COURSE_3_START,
	ZONE_COURSE_3_END,
	ZONE_COURSE_4_START,
	ZONE_COURSE_4_END,
	ZONE_COURSE_5_START,
	ZONE_COURSE_5_END,
	ZONE_COURSE_6_START,
	ZONE_COURSE_6_END,
	ZONE_COURSE_7_START,
	ZONE_COURSE_7_END,
	ZONE_COURSE_8_START,
	ZONE_COURSE_8_END,
	ZONE_COURSE_9_START,
	ZONE_COURSE_9_END,
	ZONE_COURSE_10_START,
	ZONE_COURSE_10_END,
	ZONE_BONUS_1_START,
	ZONE_BONUS_1_END,
	ZONE_BONUS_2_START,
	ZONE_BONUS_2_END,
	ZONE_BONUS_3_START,
	ZONE_BONUS_3_END,
	ZONE_BONUS_4_START,
	ZONE_BONUS_4_END,
	ZONE_BONUS_5_START,
	ZONE_BONUS_5_END,
	ZONE_BONUS_6_START,
	ZONE_BONUS_6_END,
	ZONE_BONUS_7_START,
	ZONE_BONUS_7_END,
	ZONE_BONUS_8_START,
	ZONE_BONUS_8_END,
	ZONE_BONUS_9_START,
	ZONE_BONUS_9_END,
	ZONE_BONUS_10_START,
	ZONE_BONUS_10_END,
	// End of real zones

	// Start of "unlimited"/special zones
	ZONE_COURCE,
	ZONE_SKIP,
	ZONE_BLOCKS,
	ZONE_CP,

	NUM_ZONES_W_CP
};


enum
{
	RESENT_MAP_WRS,
	RESENT_MAP_TTS,
	RESENT_COURSE_WRS,
	RESENT_COURSE_TTS,
	RESENT_BONUS_WRS,
	RESENT_BONUS_TTS
};

enum ZoneData
{
	ZONE_ID = 0,
	ZONE_TYPE,
	ZONE_ENTREF,
	ZONE_ENT,

	Float:ZONE_MINS[3],
	Float:ZONE_MAXS[3]
};

enum BeamData
{
	BEAM_TYPE = 0,
	BEAM_ID,
	BEAM_INDEX,

	Float:BEAM_POS_BOTTOM1[3],
	Float:BEAM_POS_BOTTOM2[3],
	Float:BEAM_POS_BOTTOM3[3],
	Float:BEAM_POS_BOTTOM4[3],
	Float:BEAM_POS_TOP1[3],
	Float:BEAM_POS_TOP2[3],
	Float:BEAM_POS_TOP3[3],
	Float:BEAM_POS_TOP4[3]
};

enum CPData
{
	CP_RUN = 0,
	CP_ID,
	CP_ENTREF,

	Float:CP_MINS[3],
	Float:CP_MAXS[3]
};

enum MapData
{
	STIER,
	DTIER
};

enum C_CPData
{
	C_CP_ID = 0,
	C_CP_INDEX,
	Float:C_CP_GAMETIME
};

enum PlayerState
{
	STATE_START = 0,
	STATE_RUNNING,
	STATE_END,
	STATE_SETSTART,

	STATE_INVALID
};

enum RunType
{
	MAP_RUN=0,
	COURSE_RUN=1,
	BONUS_RUN=2
};

enum { NAME_LONG = 0, NAME_SHORT, NUM_NAMES };

enum
{
	GREEN_ZONE,

	DEV_ZONE_RED,
	DEV_GREEN_ZONE,
	DEV_ZONE_BLUE,
	DEV_ZONE_WHITE,
	DEV_ZONE_PURPLE,

	NUM_ZONE_COLORS
}

enum
{
	DEMO_NONE = 0,
	DEMO_UPLOADED,
	DEMO_REQUESTED,
	DEMO_READY,
	DEMO_RECORDING,
	DEMO_UPLOADING,
	DEMO_DELETED,
	DEMO_ERROR,

	NUM_DEMO
};

enum
{
	RUN_INVALID = -1,
	
	RUN_MAIN,
	RUN_COURSE1,
	RUN_COURSE2,
	RUN_COURSE3,
	RUN_COURSE4,
	RUN_COURSE5,
	RUN_COURSE6,
	RUN_COURSE7,
	RUN_COURSE8,
	RUN_COURSE9,
	RUN_COURSE10,
	RUN_BONUS1,
	RUN_BONUS2,
	RUN_BONUS3,
	RUN_BONUS4,
	RUN_BONUS5,
	RUN_BONUS6,
	RUN_BONUS7,
	RUN_BONUS8,
	RUN_BONUS9,
	RUN_BONUS10,
	RUN_SETSTART,

	NUM_RUNS
};


forward void Timer_OnStateChanged( int client, PlayerState state );

forward void Timer_OnModeChanged( int client, int mode );

native int Timer_HasScroll( int client );
native PlayerState Timer_GetState( int client );

native int Timer_GetRun( int client );
native int Timer_GetStyle( int client );
native int Timer_GetMode( int client );

native bool IsAutoExtendEnabled(int client);

#if !defined REQUIRE_EXTENSIONS
public void __ext_Timer_SetNTVOptional()
{
	MarkNativeAsOptional("IsAutoExtendEnabled");
}
#endif