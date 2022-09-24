Fake version of the Tempus Timer


Finland server: 141.98.169.181:27015

For offline players, please write to me to provide data to the database
Discord: Rachello#8326

## Installation

* Download and install [Metamod 1.11](https://www.sourcemm.net/downloads.php/?branch=stable)
* Download and install [SourceMod 1.10](https://www.sourcemod.net/downloads.php?branch=stable) (latest stable) or [SourceMod 1.11](https://www.sourcemod.net/downloads.php?branch=master&all=1) (required for some recommended plugins)
* Download this repo and upload all the files to tf/addons/sourcemod directory
* Add this in tftf/addons/sourcemod/configs/databases.cfg :
    
    ```"Timer"
	{
		 "driver"    "mysql"
		 "host"    "Your database host ip"
		 "database"    "Your database" //Database name
		 "user"    "Your user" //Name of database user
		 "pass"    "Your pass" //Database user password
	}```

Discord: Rachello#8326