#if defined _idlesystem_included_
  #endinput
#endif
#define _idlesystem_included_

/**
 * Called when a client has become idle
 *
 * @param client        Client index
 */
forward void IdleSys_OnClientIdle(int client);

/**
 * Called when a client has ended their idle state
 *
 * @param client        Client index
 */
forward void IdleSys_OnClientReturn(int client, int time);

/**
 * Returns the client idle state
 *
 * @param client        Client index
 * @return              True if idle, else false
 * @error               If the client is not connected or the index is invalid.
 */
native bool IdleSys_IsClientIdle(int client);

/**
 * Returns the clients idle time
 *
 * @param client        Client index
 * @return              Current idle time in seconds
 * @error               If the client is not connected or the index is invalid.
 */
native int IdleSys_GetIdleTime(int client);


public SharedPlugin __pl_idlesystem = {
	name = "idlesystem",
	file = "idlesystem.smx",
#if defined REQUIRE_PLUGIN
	required = 1,
#else
	required = 0,
#endif
};

#if !defined REQUIRE_PLUGIN
public void __pl_idlesystem_SetNTVOptional() {
	MarkNativeAsOptional("IdleSys_IsClientIdle");
	MarkNativeAsOptional("IdleSys_GetIdleTime");
}
#endif