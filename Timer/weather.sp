float delayTime[MAXPLAYERS+1];

HTTPRequest httpRequest;

public Action CMD_Weather(int client, int args)
{
	char request[300], ip[64];
	int iPublicIP[4];

	if (System2_GetOS() == OS_WINDOWS)
	{
		if (SteamWorks_GetPublicIP(iPublicIP))
		{
			Format(ip, sizeof(ip), "%d.%d.%d.%d:%d", iPublicIP[0], iPublicIP[1], iPublicIP[2], iPublicIP[3]);
		}
		else 
		{
			PrintToChat(client, CHAT_PREFIX... "Can not get your IP.");
			return Plugin_Handled;
    	}
	}
	else if (!GetClientIP(client, ip, sizeof(ip), true))
	{
		PrintToChat(client, CHAT_PREFIX... "Can not get your IP.");
		return Plugin_Handled;
	}


	if (Weather_delayTime[client] > GetEngineTime())
	{
		CPrintToChat(client, CHAT_PREFIX... "You can use this command after {lightskyblue}%d {white}seconds",
																		RoundToCeil(Weather_delayTime[client] - GetEngineTime()));
		return Plugin_Handled;
	}
	
	Weather_delayTime[client] = GetEngineTime() + 30.0;

	FormatEx(request, sizeof(request), "http://api.weatherapi.com/v1/forecast.json?key=95cd5f06cf374a65aba184217221507&q=%s&days=1&aqi=no&alerts=no", ip);

	httpRequest = new HTTPRequest(request);
	httpRequest.SetHeader("Accept", "application/json");

	httpRequest.Get(OnWeatherInfoReceived, client);

	delete httpRequest;
	return Plugin_Handled;
}

public void OnWeatherInfoReceived(HTTPResponse response, any client, const char[] error) 
{

	if (response.Status != HTTPStatus_OK ||
		response.Data == null) 
	{
		CPrintToChat(client, "{red}ERROR {white}| Failed to get weather data.\n%s", error);
		return;
	}

	char city[100], country[100], text[100], FinallText[256], TempColor[60];
	float temp;

	JSONObject WeatherObj = view_as<JSONObject>(response.Data);
	JSONObject LocationObj = WeatherObj;

	WeatherObj = view_as<JSONObject>(WeatherObj.Get("current"));

	temp = WeatherObj.GetFloat("temp_c");

	LocationObj = view_as<JSONObject>(LocationObj.Get("location"));

	LocationObj.GetString("region", city, sizeof(city));
	LocationObj.GetString("country", country, sizeof(country));

	WeatherObj = view_as<JSONObject>(WeatherObj.Get("condition"));

	WeatherObj.GetString("text", text, sizeof(text));


	if ( temp >= 30.0)
		FormatEx(TempColor, sizeof(TempColor), "{tomato}");
	else if ( temp >= 20.0) 
		FormatEx(TempColor, sizeof(TempColor), "{orange}");
	else 
		FormatEx(TempColor, sizeof(TempColor), "{cyan}");
			
	FormatEx(FinallText, sizeof(FinallText), CHAT_PREFIX..."In the \x0764E664%s/%s {white}now %s%.0f℃ {white}(%s).", country, city, TempColor, temp, text);

	CPrintToChatAll(FinallText);

	return;
}