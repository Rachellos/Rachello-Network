public Action Command_Say(int client, const char[] command, int argc)
{
	if(!IsValidClient(client))
	{
		return Plugin_Continue;
	}
	static char name[32];
	GetClientName(client, name, sizeof( name ) );
	static char sText[300];
	GetCmdArgString(sText, sizeof(sText));
	StripQuotes(sText);
	if((sText[0] == '!') || (sText[0] == '/'))
	{
		if(IsCharUpper(sText[1]))
		{
			for(int i = 0; i <= strlen(sText); ++i)
			{
				sText[i] = CharToLower(sText[i]);
			}
			sText[0] = '_';
			FakeClientCommand(client, "sm%s", sText);
			return Plugin_Handled;
		}
	}
	return Plugin_Continue;
}

public bool IsValidClient(int client)
{
	if (!(1 <= client <= MaxClients) || !IsClientInGame(client) || IsFakeClient(client))
	{
		return false;
	}
	return true;
}