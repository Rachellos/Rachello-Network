
/**
 *	Getting the current TickRate server
 *	-
 *	@noparams
 *	-
 *	@return Current TickRate
*/
native float TickRate_GetCurrentTick();

/**
 *	Getting the default TickRate server
 *	-
 *	@noparams
 *	-
 *	@return Default TickRate Server
*/
native float TickRate_GetDefaultTick();

/**
 *	Sets an arbitrary TickRate
 *	-
 *	@param fTick        New TickRate server (Minimum value - 21.0 / Maximum - 128.0)
 *  @param bforceRetry  true - all players reconnect to the server.
 *	-
 *	@noreturn
*/
native void TickRate_SetTickRate(float fTick, bool bForceRetry = false);

/**
 *	Called when TickRate has been changed.
 *	-
 * 	@param fOld			Previous TickRate
 *	@param fNew			New TickRate
 *	-
 * @noreturn
*/

forward void TickRate_OnTickRateChanged(float fOld, float fNew);