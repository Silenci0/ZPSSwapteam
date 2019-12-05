# ZPSSwapteam
ZPS-centric swapteam plugin.

NOTE: This plugin is currently unsupported and will not be updated! After ZPS 3.0, the plugin no longer works due to changes in how teams are changed/swapped. In order to fix it, it will need to be updated with the appropriate hooks into methods that can be used to change teams for survivors and zombies. Feel free to fork and use however you see fit!

This plugin allows players to swap teams. There is functionality for admins and donators (can be changed in the configs) to swap as many times as they want (if desired).

1.2 Update (06-11-2018)
-----------------
- Updated code files with separate ZPS-related items and renamed the plugins.
- Compiled for SM 1.9

1.2 Update (06-04-2017)
-----------------
- Compiled codebase for SM 1.8 
- Changed plugin name to zps_swapteam in order to avoid confusion. The configuration file has also had its name updated to plugin.zpsswapteam.
- Changed game_round_restart hook to round_win.
- General code update to fix minor compatability issues.

1.1 Hotfix (06-04-2017)
-----------------
- Used TEAM_SPEC define in team change logic instead of having it hard-coded.

1.1 Update (11-05-2016)
-----------------
- Added admin/donator flags/functionality
- Added player threshholds. This ensures that it can be used after x amount of players are playing and deactivates after x amount of players are on the server.

1.0 Initial Commit (10-28-2016)
-----------------
- Created swap functionality.
- Added cooldown on swap functionality for regular players.