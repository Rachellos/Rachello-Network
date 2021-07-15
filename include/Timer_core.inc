#if defined _Timer_core_included
	#endinput
#endif
#define _Timer_core_included


#define PLUGIN_VERSION_CORE	"2.2"
#define PLUGIN_AUTHOR_CORE	"Rachello"
#define PLUGIN_NAME_CORE	"Timer"
#define PLUGIN_URL_CORE		"https://github.com/Rachellos"


#define CONSOLE_PREFIX		"["...PLUGIN_NAME_CORE..."] " // Used only for console/server.

enum PlayerState
{
	STATE_START = 0,
	STATE_CSTART2,
	STATE_CSTART3,
	STATE_CSTART4,
	STATE_CSTART5,
	STATE_CSTART6,
	STATE_CSTART7,
	STATE_CSTART8,
	STATE_CSTART9,
	STATE_CSTART10,
	STATE_RUNNING,
	STATE_END,
	STATE_END_MAIN,
	STATE_SETSTART,

	STATE_NOT_MAIN
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


forward void Timer_OnStateChanged( int client, PlayerState state );

forward void Timer_OnModeChanged( int client, int mode );

native int Timer_HasScroll( int client );
native PlayerState Timer_GetState( int client );

native int Timer_GetRun( int client );
native int Timer_GetStyle( int client );
native int Timer_GetMode( int client );