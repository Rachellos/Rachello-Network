Sourcemod version the Tempus Timer for servers

## Installation

* Download and install [Metamod](https://www.sourcemm.net/downloads.php/?branch=stable) and [SourceMod](https://www.sourcemod.net/downloads.php?branch=stable) (latest stable)
* Download this repo and upload all the files to tf/addons/sourcemod directory
* Add this in tf/addons/sourcemod/configs/databases.cfg :
    
    ```
    "Timer"
	{
		 "driver"    "mysql"
		 "host"    "Your database host ip"
		 "database"    "Your database" //Database name
		 "user"    "Your user" //Name of database user
		 "pass"    "Your pass" //Database user password
	}
    ```
Before launching, I recommend filling in the configuration file if you want to use all available functions
```addons/sourcemod/configs/TimerSettings.cfg```


	"Settings"
	{
		"server_id"	"" //dont works yet.

		// Сreate a discord bot, set token here and give it privileges to view channels, write in channels and enable MESSAGE CONTENT INTENT
		// Also create channels on your discord server to use all the functionality:
		//cross-server , server-actions , chat-logs , call-admin
		"discord"	"<BOT TOKEN>"

		// Insert the ip of the server running the IRC server here, or if you want to start the server right here, then switch Create_IRC_server to 1.
		"IRC_Host"	"<IRC SERVER HOST>"

		//here, insert the port to connect/create the server (I recommend using the port of the game server if you are creating)
		/// !!! it is important that the port is open.
		"IRC_Port"	"<IRC SERVER PORT>"

		// 0 to just CONNECT to the IRC server
		// 1 to CREATE IRC server
		"Create_IRC_server"	"0 | 1"
	}


Discord for help: rachello_
