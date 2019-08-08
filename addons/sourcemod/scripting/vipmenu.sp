#pragma semicolon 1

#define DEBUG

#define chat_tag "\x0B[VIPMENU]"

#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <store>

#pragma newdecls required

ConVar g_gunc;
ConVar g_buffc;
ConVar VipHealth;
ConVar NormalKill;
ConVar HeadKill;
ConVar RegenEveryTime;
ConVar RegenEveryAmmount;

float RegenTime;

int e_gunc;
int e_buffc;
int RespawnUsage[MAXPLAYERS+1];
int RespawnUsageMax = 1;

public Plugin myinfo = 
{
	name = "VipMenu with credits by spirt",
	author = "SpirT",
	description = "VIPMenu with credts",
	version = "2.2.0",
	url = "https://www.paypal.me/spirtcfg" /* donate if possible :D */
};

public void OnPluginStart()
{
	//Commands & Actions
	RegAdminCmd("sm_vipmenu", vipmenu, ADMFLAG_CUSTOM1, "VIPMenu command description");
	RegAdminCmd("sm_vipspawn", CommandSpirtVipMenuVipSpawn, ADMFLAG_CUSTOM1, "This command allows the VIP to respawn 1 time per round!");
	HookEvent("round_start", EventRoundStart, EventHookMode_PostNoCopy);
	HookEvent("player_death", OnPlayerDeath);
	
	//ConVars
	g_gunc = CreateConVar("sm_guns_credits", "1000", "Guns Price In The Menu");
	g_buffc = CreateConVar("sm_buffs_credits", "500", "Buffs Price In The Menu");
	VipHealth = CreateConVar("sm_viphealth_ammount", "120", "This is the ammount of HP the VIP player should have on the round start! WARNING: SET 100 FOR DEFAULT");
	NormalKill = CreateConVar("sm_viphealth_normal_ammount", "15", "This is the ammount of health that the VIP player should receive for killing a player with no headshot");
	HeadKill = CreateConVar("sm_viphealth_head_ammount", "25", "This is the ammount of health that the VIP player should receive for killing with an headshot");
	RegenEveryTime = CreateConVar("sm_viphealth_regen_time", "15", "This the ammount of seconds that the VIP player 'wait' to receive health every x to x seconds");
	RegenEveryAmmount = CreateConVar("sm_viphealth_regen_ammount", "5", "This is the ammount of health that the VIP player should receive ");
	
	//Menus
	CreateVipMenu();
	CreateGunsMenu();
	CreateBuffsMenu();
	
	//Timers
	RegenTime = GetConVarFloat(RegenEveryTime);
	CreateTimer(RegenTime * 1.0, RegenTimer, TIMER_REPEAT);
	
	//Configs
	AutoExecConfig(true, "spirt_vipmenu");
}

public Action RegenTimer(Handle timer)
{
	for (int i = 1; i < MaxClients; i++)
	{
		if(CheckCommandAccess(i, "sm_vipmenu_regen_health", ADMFLAG_CUSTOM1))
		{
			int regen = GetConVarInt(RegenEveryAmmount);
			int old = GetClientHealth(i);
			int sethp = regen + old;
			SetEntityHealth(i, sethp);
		}
	}
}

public Action OnPlayerDeath(Event event, char[] name, bool dontBroadCast)
{
	int client = GetClientOfUserId(GetEventInt(event, "attacker"));
	if(CheckCommandAccess(client, "sm_vipmenu_regenkill", ADMFLAG_CUSTOM1))
	{
		bool headshot = GetEventBool(event, "headshot");
		if(headshot == false)
		{
			int kill = GetConVarInt(NormalKill);
			int old = GetClientHealth(client);
			int sethp = kill + old;
			SetEntityHealth(client, sethp);
		}
		else if(headshot == true)
		{
			int head = GetConVarInt(HeadKill);
			int old = GetClientHealth(client);
			int sethp = head + old;
			SetEntityHealth(client, sethp);
		}
	}
}

public Action EventRoundStart(Event event, char[] name, bool bDontBroadCast)
{
	for (int i = 1; i <= MaxClients; i++) RespawnUsage[i] = 0;
	return Plugin_Continue;
}

public Action CommandSpirtVipMenuVipSpawn(int client, int args)
{
	if(CheckCommandAccess(client, "sm_override_vip", ADMFLAG_CUSTOM1))
	{
		int IntVipHealth = GetConVarInt(VipHealth);
		SetEntityHealth(client, IntVipHealth);
		if(IsPlayerAlive(client))
		{
			PrintToChat(client, "\x07You can't use \x04VIPSPAWN \x03because you're alive!");
			return Plugin_Handled;
		}
		else
		{
			if(RespawnUsage[client] < RespawnUsageMax)
			{
				SpirtVipMenuRespawnPlayerAction(client);
				RespawnUsage[client]++;
				return Plugin_Handled;
			}
			else if(RespawnUsage[client] > RespawnUsageMax)
			{
				PrintToChat(client, "\x07You already used \x04VIPSPAWN \x03in this round!");
				return Plugin_Handled;
			}
		}
		return Plugin_Handled;
	}
	return Plugin_Handled;
}

public Action SpirtVipMenuRespawnPlayerAction(int client)
{
	CS_RespawnPlayer(client);
}

public Action vipmenu(int client, int args)
{
	CreateVipMenu().Display(client, MENU_TIME_FOREVER);
	CreateGunsMenu();
	CreateBuffsMenu();
}

public Menu CreateVipMenu()
{
	Menu vmenu = new Menu(handler, MENU_ACTIONS_ALL);
	vmenu.SetTitle("VIPMenu");
	vmenu.AddItem("gm", "Guns");
	vmenu.AddItem("bm", "Buffs");
	vmenu.ExitButton = true;
	
	return vmenu;
}

public Menu CreateGunsMenu()
{
	Menu gmenu = new Menu(handler2, MENU_ACTIONS_ALL);
	gmenu.SetTitle("Guns Menu");
	gmenu.AddItem("AK47D", "AK47 + Deagle [1000]");
	gmenu.AddItem("M4A4D", "M4A4 + Deagle [1000]");
	gmenu.AddItem("M4A1-SD", "M4A1-S + Deagle [1000]");
	gmenu.AddItem("AWPD", "AWP + Deagle [1000]");
	gmenu.ExitBackButton = true;
	gmenu.ExitButton = true;
	
	return gmenu;

}

public Menu CreateBuffsMenu()
{
	Menu bmenu = new Menu(handler3, MENU_ACTIONS_ALL);
	bmenu.SetTitle("Buffs Menu");
	bmenu.AddItem("MK", "Medic Kit [500]");
	bmenu.AddItem("WHG", "Whallhack Grenade [500]");
	bmenu.ExitBackButton = true;
	bmenu.ExitButton = true;
	
	return bmenu;
}

public int handler(Menu vmenu, MenuAction action, int client, int item)
{
	char choice[32];
	vmenu.GetItem(item, choice, sizeof(item));
	if (action == MenuAction_Select)
	{
		if (StrEqual(choice, "gm"))
		{
			delete vmenu;
			CreateGunsMenu().Display(client, MENU_TIME_FOREVER);
		}
		else if (StrEqual(choice, "bm"))
		{
			delete vmenu;
			CreateBuffsMenu().Display(client, MENU_TIME_FOREVER);
		}
	}
	else if (action == MenuAction_End)
	{
		delete vmenu;
	}
}

public int handler2(Menu gmenu, MenuAction action, int client, int item)
{
	char choice[32];
	e_gunc = GetConVarInt(g_gunc);
	gmenu.GetItem(item, choice, sizeof(item));
	if (action == MenuAction_Select)
	{
		if (StrEqual(choice, "AK47D"))
		{
			if (Store_GetClientCredits(client) > e_gunc)
			{
				GivePlayerItem(client, "weapon_ak47");
				GivePlayerItem(client, "weapon_deagle");
				PrintToChat(client, "%s \x07You got \x03AK47 + DEAGLE \x04with 1000 credits", chat_tag);
				Store_SetClientCredits(client, -1000);
			}
		}
		if (StrEqual(choice, "M4A4D"))
		{
			Store_GetClientCredits(client);
			if (Store_GetClientCredits(client) > e_gunc)
			{
				GivePlayerItem(client, "weapon_m4a1");
				GivePlayerItem(client, "weapon_deagle");
				PrintToChat(client, "%s \x07You got \x03M4A4 + DEAGLE \x04with 1000 credits", chat_tag);
				Store_SetClientCredits(client, -1000);
			}
		}
		if (StrEqual(choice, "M4A1-SD"))
		{
			Store_GetClientCredits(client);
			if (Store_GetClientCredits(client) > e_gunc)
			{
				GivePlayerItem(client, "weapon_m4a1_silencer");
				GivePlayerItem(client, "weapon_deagle");
				PrintToChat(client, "%s \x07You got \x03M4A1-S + DEAGLE \x04with 1000 credits", chat_tag);
				Store_SetClientCredits(client, -1000);
			}
		}
		if (StrEqual(choice, "AWPD"))
		{
			Store_GetClientCredits(client);
			if (Store_GetClientCredits(client) > e_gunc)
			{
				GivePlayerItem(client, "weapon_awp");
				GivePlayerItem(client, "weapon_deagle");
				PrintToChat(client, "%s \x07You got \x03AWP + DEAGLE \x04with 1000 credits", chat_tag);
				Store_SetClientCredits(client, -1000);
			}
		}
	}
	else if (action == MenuAction_Cancel)
	{
		delete gmenu;
		CreateVipMenu().Display(client, MENU_TIME_FOREVER);
	}
	else if (action == MenuAction_End)
	{
		delete gmenu;
	}
}

public int handler3(Menu bmenu, MenuAction action, int client, int item)
{
	char choice[32];
	e_buffc = GetConVarInt(g_buffc);
	bmenu.GetItem(item, choice, sizeof(item));
	if (action == MenuAction_Select)
	{
		if (StrEqual(choice, "MK"))
		{
			Store_GetClientCredits(client);
			if (Store_GetClientCredits(client) > e_buffc)
			{
				GivePlayerItem(client, "weapon_healthshot");
				PrintToChat(client, "%s \x07You got \x03Medic Kit \x04with 500 credits", chat_tag);
				Store_SetClientCredits(client, -500);
			}
		}
		if (StrEqual(choice, "WHG"))
		{
			Store_GetClientCredits(client);
			if (Store_GetClientCredits(client) > e_buffc)
			{
				GivePlayerItem(client, "weapon_tagrenade");
				PrintToChat(client, "%s \x07You got \x03Whallhack Grenade \x04with 500 credits", chat_tag);
				Store_SetClientCredits(client, -500);
			}
		}
	}
	else if (action == MenuAction_Cancel)
	{
		delete bmenu;
		CreateVipMenu().Display(client, MENU_TIME_FOREVER);
	}
	else if (action == MenuAction_End)
	{
		delete bmenu;
	}
}