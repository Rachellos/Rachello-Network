#if defined _demoparse_included
 #endinput
#endif
#define _demoparse_included


typeset DemoParseCallback
{
	function void (bool success, float time, char[] error);
}


/**
 * Create a JumpBOT recording file from a demo file.
 *
 * @param callback   Callback function
 * @param path       Path of .dem file
 * @param outPath    Path of jump recording file
 * @param steamID    Target player's SteamID3
 * @param startTick  First tick of recording
 * @param endTick    Last tick of recording
 * @return           True on success
 */
native bool ParseDemo(DemoParseCallback callback, const char[] path, const char[] outPath, const char[] steamID, int startTick, int endTick);

public Extension:__ext_demoparse = 
{
	name = "DemoParse",
	file = "demoparse.ext",
#if defined AUTOLOAD_EXTENSIONS
	autoload = 1,
#else
	autoload = 0,
#endif
#if defined REQUIRE_EXTENSIONS
	required = 1,
#else
	required = 0,
#endif
};