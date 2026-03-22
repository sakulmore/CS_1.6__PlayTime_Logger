# CS 1.6 - PlayTime Logger
With this plugin, you can log players' playtime on the server without the need for a database (such as SQL). You can also choose whether you want players who are in Spectator mode to be logged or not (to prevent time farming).

# Installation
- Just download the plugin and upload the .amxx file to your plugins folder on your server (or you can of course compile the .sma file and then upload the compilated .amxx file to your server).
- Then write the plugin name (with .amxx) to `/cstrike/addons/amxmodx/configs/plugins.ini`.

# Requirements
- AMX Mod X 1.10

# Commands
| Command | Chat or Console? | Possible Values | Required Admin Flag | Description |
| - | - | - | - | - |
| /rtp | Chat | - | ADMIN_RCON | Deletes the contents of the "playtime_logger.txt" file (and thus also deletes the record of players' playtime). |
| playtime_resetfile | Console | - | ADMIN_RCON | Deletes the contents of the "playtime_logger.txt" file (and thus also deletes the record of players' playtime). |
| playtime_allowspectator | Console | 1, 0 | ADMIN_RCON | Enables or disables logging of player time when the player is in Spectator mode. |

# Showcases
To be added later...

# Support
If you having any issues please feel free to write your issue to the issue section :) .