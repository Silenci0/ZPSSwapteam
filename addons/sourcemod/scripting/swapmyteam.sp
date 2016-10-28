/************************************************************************
*************************************************************************
[ZPS] Swap My Team
Description: Main functionality is to simply allow donators to swap teams.
	Also gives a bit more flexibility/control over how the plugin works.
	Users of this plugin can set a cool down time on how often
	the functionality is used (to prevent swap abuse).
    
Original Author:
    Kana

Updated by:
    Mr. Silence
    
*************************************************************************
*************************************************************************
This plugin is free software: you can redistribute 
it and/or modify it under the terms of the GNU General Public License as
published by the Free Software Foundation, either version 3 of the License, or
later version. 

This plugin is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this plugin.  If not, see <http://www.gnu.org/licenses/>.
*************************************************************************
*************************************************************************/
// Make sure it reads semicolons as endlines.
#pragma semicolon 1

// Includes
#include <sourcemod>
#include <sdktools>

// Get some defines up in this piece!
// But seriously, define some common, easier to deal with stuff.
#define VERSION "1.0"
#define TEAM_HUMAN 2
#define TEAM_ZOMBIE 3
#define TEAM_SPEC 1
#define TEAM_WAITING 0
#define TEAM_COPS 4
#define SMTP_PREFIX "\x01\x04[SM]\x01"

// Create our new cvar handles for use later.
new Handle:cvar_SwapMyTeamDFlag     	= INVALID_HANDLE;	// Donator flag that allows people to use the command
new Handle:cvar_SwapMyTeamCMD			= INVALID_HANDLE;	// Command used to swap teams
new	Handle:cvar_SwapMyTeamCoolDown 		= INVALID_HANDLE;	// Cool Down cvar
new Handle:cvar_SwapMyTeamMaxPlayers    = INVALID_HANDLE;   // Handle for maximum amount of players to enable the swap ability
new Handle:cvar_SwapMyTeamMinPlayers    = INVALID_HANDLE;   // Handle for minimum amount of players to disable the swap ability
new	Handle:cvar_SMTVersion 				= INVALID_HANDLE;	// Version display cvar

// Create our timer handel for each player.
new Handle:g_SMTTimerHandle;//[MAXPLAYERS+1];

// Get a global variable to determine whether cooldown for the player is in effect.
new bool:g_bCanSwap[MAXPLAYERS+1];
new bool:g_bSMTCommandCreated;
new bool:g_bRoundTimeLimit;
new bool:g_bSwapEnable;
//new bool:g_bSwapDisable;

// Global string for swap commands
new String:g_sSMTCommands[3][65];

// Plugin info/credits.
public Plugin:myinfo = 
{
    name = "[ZPS] Swap My Team",
    author = "Original: Kana, Updated by: Mr.Silence",
    description = "Allows players to swap their team once.",
    version = VERSION,
    url = "www.kanaisgod.com"
}

// Initialization method, the place where we fill out cvar details and other things.
public OnPluginStart()
{
	// Create our variables for use in the plugin.
    cvar_SwapMyTeamDFlag     	= CreateConVar("sm_swapmyteam_flag", "s", "Flag necessary for admins/donators to use this functionality (use only one flag!).", FCVAR_PLUGIN);
    cvar_SwapMyTeamCMD			= CreateConVar("sm_swapmyteam_cmd", "swapmyteam", "Command used on the server for players/admins to swap teams.", FCVAR_PLUGIN);
    cvar_SwapMyTeamCoolDown		= CreateConVar("sm_swapmyteam_cooldown", "300.0", "Count down timer (in seconds) before the swapteam is disabled for the rest of the round.", FCVAR_PLUGIN, true, 0.0, false);
    cvar_SwapMyTeamMaxPlayers	= CreateConVar("sm_swapmyteam_max_players", "4", "The number of players that need to be on the server to enable this ability.", FCVAR_PLUGIN, true, 0.0, false);
    cvar_SwapMyTeamMinPlayers	= CreateConVar("sm_swapmyteam_min_players", "2", "The number of players on the server in which this ability is disabled.", FCVAR_PLUGIN, true, 0.0, false);
    cvar_SMTVersion				= CreateConVar("sm_swapmyteam_version", VERSION, "[ZPS] Swap My Team Version.", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	
	// Create a config file for the plugin
    AutoExecConfig(true, "plugin.swapmyteam");	
    
    // Hook round start time
    HookEvent("game_round_restart", ZPSRoundStart, EventHookMode_PostNoCopy);
}

///////////////////////////////////
//===============================//
//=====[ ACTIONS ]===============//
//===============================//
///////////////////////////////////
public Action:Command_SwapMyTeam(client, args)
{
    if (!IsFakeClient(client))
    {  
        // Gets the client's current team then determines which to switch too.
        new team = GetClientTeam(client);
        
        // Check if they are an admin
        if (IsAdmin(client))
        {            
            // Set the flag to true since admins can swap any time
            g_bCanSwap[client] = true;
                    
            // Determine which team the player gets swaped to. If in spec, tell them to join a team.
            switch (team)
            {
                case 2: ChangeClientTeamZPS(client, TEAM_ZOMBIE);
                case 3: ChangeClientTeamZPS(client, TEAM_HUMAN);
                default: ReplyToCommand(client, "%s Unknown Team.", SMTP_PREFIX);
            }
			
            return Plugin_Continue;
        }
		
        // Check if they are in spectate 
        if(team == TEAM_COPS || team <= TEAM_SPEC)
        {
            ReplyToCommand(client, "%s Join a valid team first.", SMTP_PREFIX);
            return Plugin_Continue;
        }
        
        // If the user tries to use this feature, let them know how many more players are needed
        // for activation
        if(!g_bSwapEnable)
		{
            new currCount = GetConVarInt(cvar_SwapMyTeamMaxPlayers) - RealPlayerCount();
            ReplyToCommand(client, "%s Swap is currently disabled. %d more players are needed.", SMTP_PREFIX, currCount);
            return Plugin_Continue;
        }
        
        // If the Player can swap teams and the round limit hasn't been reached, swap the teams
        if(g_bCanSwap[client] && g_bRoundTimeLimit)
        {
            // Determine which team the player gets swaped to. If in spec, tell them to join a team.
            switch (team)
            {
                case 2: ChangeClientTeamZPS(client, TEAM_ZOMBIE);
                case 3: ChangeClientTeamZPS(client, TEAM_HUMAN);
                default: ReplyToCommand(client, "%s Unknown Team.", SMTP_PREFIX);
            }
			
            // Set the flag so that it registers the cooldown effect.
            g_bCanSwap[client] = false;
				
            return Plugin_Continue;
        }
        
        // If the round timer has been reached...
        if(!g_bRoundTimeLimit)
        {
            ReplyToCommand(client, "%s Round timer has reached its limit. You cannot swap until next round.", SMTP_PREFIX);
            return Plugin_Continue;
        }
        
        // Tell the player they cannot swap again.
        else
        {
            ReplyToCommand(client, "%s Only one team swap per round! You cannot swap until next round.", SMTP_PREFIX);
        }
		
        return Plugin_Continue;
    }
	
    return Plugin_Continue;
}

// Command cool down timer
public Action:Timer_SwapCoolDown(Handle:timer)
{
    // Set up the cooldown timer
    new Float:fCoolDown = GetConVarFloat(cvar_SwapMyTeamCoolDown);
	
    // Set the variable to the current time
    new Float:fCurrentTime = GetTickedTime();

    // If the time reaches 0 and our flag is still false.
    if(fCurrentTime >= fCoolDown)
    {
        // Reset the current time global and give them back the command.
        fCurrentTime = 0.0;
        g_bRoundTimeLimit = false;
        
        // Ensure that the value of CanSwap is, for each client, set to false after the timer is finished
        for(new i = 1; i <= MaxClients; i++)
        {
            g_bCanSwap[i] = false;
        }
        PrintToChatAll("Swap timer has ended. No one can switch teams with this plugin until next round!");
        ClearTimer(g_SMTTimerHandle);
        return Plugin_Handled;
    }
	
    return Plugin_Continue;
}

// Round Start for ZPS. We need this to be hooked so we have a "trigger" in which to start 
// our round timer to disable the swapteam feature.
public ZPSRoundStart(Handle:event, const String:name[], bool:dontBroadcast) 
{
    // First things first, reset everything!
    if(g_SMTTimerHandle!= INVALID_HANDLE)
    {
        ClearTimer(g_SMTTimerHandle);
    }
    
    // Ensure that the value of CanSwap is, for each client, set to true initially.
    for(new i = 1; i <= MaxClients; i++)
    {
        g_bCanSwap[i] = true;
    }
	
    // Round limit is reset
    g_bRoundTimeLimit = true;
    
    // Start our timer
    g_SMTTimerHandle = CreateTimer(GetConVarFloat(cvar_SwapMyTeamCoolDown), Timer_SwapCoolDown, TIMER_REPEAT);
}

///////////////////////////////////
//===============================//
//=====[ EVENTS ]================//
//===============================//
///////////////////////////////////
// Get the proper info upon our configs being executed.
public OnConfigsExecuted()
{
    // Set our plugins version to display
    SetConVarString(cvar_SMTVersion, VERSION);

    // Create our swap commands
    CreateSwapCommand();
}

// Set our values to true for use once more!
public OnMapStart()
{
    // Ensure that the value of CanSwap is, for each client, set to true initially.
    for(new i = 1; i <= MaxClients; i++)
    {
        g_bCanSwap[i] = true;
    }
	
    g_bRoundTimeLimit = true;
    g_bSwapEnable = false;
}

// Clean up, clean up!
public OnMapEnd()
{
    if(g_SMTTimerHandle!= INVALID_HANDLE)
    {
        ClearTimer(g_SMTTimerHandle);
    }
}

// Kill our client's timer on disconnect and check playercount
public OnClientDisconnect(client)
{
    g_bCanSwap[client] = true;
    if(RealPlayerCount() <= GetConVarInt(cvar_SwapMyTeamMinPlayers) && g_bSwapEnable == true)
    {
        //g_bSwapDisable = true;
        g_bSwapEnable = false;
        PrintToChatAll("Swap functionality is disabled due to having less than %s players.", GetConVarFloat(cvar_SwapMyTeamMaxPlayers));
    }
}

// Get the current player count and enable functionality if we reach the correct amount of users
public OnClientConnected(client)
{
    if(RealPlayerCount() >= GetConVarInt(cvar_SwapMyTeamMaxPlayers) && g_bSwapEnable == false)
    {
        //g_bSwapDisable = false;
        g_bSwapEnable = true;
        PrintToChatAll("Swap functionality is now enabled!");
    }
}

///////////////////////////////////
//===============================//
//=====[ STOCKS ]================//
//===============================//
///////////////////////////////////
// Kill/clear our client's timer handles. Wouldn't want them eating up precious memory.
stock ClearTimer(&Handle:timer)
{
    if (timer != INVALID_HANDLE)
    {
        KillTimer(timer);
        timer = INVALID_HANDLE;
    }     
}

// Create the commands our plugin uses in game
stock CreateSwapCommand()
{
    if (!g_bSMTCommandCreated)
    {
        decl String:sSMTCommand[256];		
		
        GetConVarString(cvar_SwapMyTeamCMD, sSMTCommand, sizeof(sSMTCommand));
		
        // Pull the commmands from the string used in our 
        ExplodeString(sSMTCommand, ",", g_sSMTCommands, 3, sizeof(g_sSMTCommands[]));
		
        // Set all of our commands up for use
        for (new i; i < 3; i++)
        {
            if (strlen(g_sSMTCommands[i]) > 2)
            {
                g_bSMTCommandCreated = true;
                RegConsoleCmd(g_sSMTCommands[i], Command_SwapMyTeam);
            }
        }
    }
}

// Method used to check if a player has access to the commands
stock bool:IsAdmin(client)
{
    // Get our admin flags
    new String:userFlags[32];
    GetConVarString(cvar_SwapMyTeamDFlag, userFlags, sizeof(userFlags));
    
    // Checks to see if the person has root access 
    new clientFlags = GetUserFlagBits(client);	
    if (clientFlags & ADMFLAG_ROOT)
    {
        return true;
    }
	
    // Checks to see if the user has the appropriate flags
    new iFlags = ReadFlagString(userFlags);
    if (clientFlags & iFlags)
    {
        return true;	
    }
	
    // If no flags, they don't have access
    return false;
}

// Because ZPS will just change the player without changing the HUD or respawning the player,
// We need to change them to spectator, then change their actual team.
stock ChangeClientTeamZPS(client, team)
{
    ChangeClientTeam(client, 1);
    ChangeClientTeam(client, team);
}

// Player count based on actual players. This method does not count bots.
RealPlayerCount()
{
    new players;
    for (new i = 1; i <= MaxClients; i++)
    {
        if (IsClientInGame(i) && !IsFakeClient(i))
        {
            players++;
        }
    }
    return players;
}  