// Terror-Strike: VScript edition

::TEAM_UNAS <- 0
::TEAM_SPEC <- 1
::TEAM_T    <- 2
::TEAM_CT   <- 3
::MaxPlayers <- MaxClients().tointeger()
local deadCTs = []
local timers = [] // to keep timers to clear any additional ones that have been left after we won

local world_spawn = Entities.FindByClassname(null, "worldspawn")
world_spawn.ValidateScriptScope()
local world_spawn_scope = world_spawn.GetScriptScope()

// settings
::zombie_speedModifier <- 1 // This is a speed multiplier adding over the default of 250
::zombie_spawnAfter <- 45 // after killing a zombie, how many seconds to then spawn it again
// zombie_itemPreset - what extra weapons we should be giving to the player
::zombie_itemPreset <- [] //["weapon_m249", "item_assaultsuit", "weapon_frag", "weapon_flashbang", "weapon_smokegrenade"]

CBaseMultiplayerPlayer.GiveItem <- function(item, ammo_amount = 0)
{   // Gives an item to the player. Returns the weapon handle. For "item_*" entities. It won't return the handle.
    if (!startswith(item, "weapon_") && !startswith(item, "item_"))
        return;

    // For some reason, item_ entities don't always equip on player, meaning they still exist in the world, adding to the edict count.
    // The best way to avoid this is just faking the pickup
    local my_item = SpawnEntityFromTable(item, {origin = GetOrigin() ammo = ammo_amount});

    // mv: the entity is probably already destroyed because the player grabbed it
    //if (IsValidSafe(my_item))
    //    return my_item;
}

CBaseMultiplayerPlayer.GetMyWeapons <- function (bShouldPrint = false)
{   // Basically returns the netprop array "m_hMyWeapons" from a player.
    local m_hMyWeapons = [];
    local array_size = NetProps.GetPropArraySize(this, "m_hMyWeapons");   // Just in case.
    
    if (bShouldPrint)
        printl("====== m_hMyWeapons for: " + GetPlayerName() + " ======");
    for (local i = 0; i < array_size;  i++)
    {
        local wep = NetProps.GetPropEntityArray(this, "m_hMyWeapons", i);

        m_hMyWeapons.push(wep);
        if (bShouldPrint)
            printl("\tslot[" + i + "] = " + wep);
    }
    if (bShouldPrint)
        printl("=====================================================");

    return m_hMyWeapons;
}

function delayedRespawnZombie(zombie) {
  local func_name = UniqueString()
  world_spawn_scope[func_name] <- function() {
    delete world_spawn_scope[func_name]
    deadCTs.remove(deadCTs.find(zombie))
    timers.remove(timers.find(func_name))
    NetProps.SetPropInt(zombie, "m_iPlayerState", 0);   // 0 is alive.
    zombie.DispatchSpawn();
  }
	
  EntFireByHandle(world_spawn, "CallScriptFunction", func_name, zombie_spawnAfter, null, null)
  return func_name
}

function GetTeamArray(team, onlyAlive = false) {
  local playersArray = []

  for (local i = 1; i <= MaxPlayers; i++) {
    local player = PlayerInstanceFromIndex(i)
    if (player == null)
      continue
    if (!player.IsAlive() && onlyAlive)
      continue
    if (player.GetTeam() != team)
      continue

    playersArray.append(player)
  }

  return playersArray;
}

function respawnAllZombies() {
  local i = 0;
  foreach (zombie in deadCTs) {
    NetProps.SetPropInt(zombie, "m_iPlayerState", 0);   // 0 is alive.
    zombie.DispatchSpawn();
  }
  deadCTs.clear()
}

m_Events <- {
  OnGameEvent_player_hurt = function(params) {
    local victim = GetPlayerFromUserID(params.userid)
    local attckr = GetPlayerFromUserID(params.attacker)
    local isCTandAboutToDie = (params.health == 0 && victim.GetTeam() == TEAM_CT)

    if (isCTandAboutToDie) {
      deadCTs.append(victim)
      timers.append(delayedRespawnZombie(victim))
    }

    // mv: this condition really sucks but i don't want to [mp_ignore_round_win_conditions 1] and have to implement everything else myself
    // mv: this is done so that the game doesn't abruptly end, we still have to plant the bomb
    if (isCTandAboutToDie && GetTeamArray(TEAM_CT, true).len() == 1) {
      EntFireByHandle(victim, "SetHealth", "100", 0, null, null)
      victim.DispatchSpawn()
      // move our zombie to the little corner
      // mv: this sucks cause its specific to zombie_city_v2
      victim.SetOrigin(Vector(3149.758,3765.385,156.636))
      //victim.setMoveType(0,0) // MOVETYPE_NONE, MOVECOLLIDE_DEFAULT

      NetProps.SetPropInt(attckr, "m_iAccount", NetProps.GetPropInt(attckr, "m_iAccount") + 300)
    }
  }

  OnGameEvent_player_spawn = function(params) {
    local player = GetPlayerFromUserID(params.userid)
    if (!IsPlayerABot(player) && player.GetTeam() == TEAM_CT) {
      NetProps.SetPropInt(player, "m_iClass", 3) // elite crew
      NetProps.SetPropInt(player, "m_iTeamNum", TEAM_T)
      player.SetModelSimple("models/player/t_leet.mdl")
      player.SetOrigin(Entities.FindByClassname(null, "info_player_terrorist").GetOrigin())
    }

    if (IsPlayerABot(player) && player.GetTeam() == TEAM_CT) {
      if (zombie_speedModifier > 1)
        NetProps.SetPropFloat(player, "m_flLaggedMovementValue", zombie_speedModifier);
    }
	
	if (player.GetTeam() == TEAM_T) {
		if (zombie_itemPreset.len() > 0) {
			for (local i = 0; i < zombie_itemPreset.len(); i++) {
				player.GiveItem(zombie_itemPreset[i], 320)
			}
		}
	}
  }

  OnGameEvent_bomb_planted = function(params) {
    foreach (timer in timers) {
      if (timer in world_spawn_scope)
        delete world_spawn_scope[timer]
    }

    respawnAllZombies()
  }

  OnGameEvent_round_start = function(params) {
    deadCTs.clear()

    foreach (timer in timers) {
      if (timer in world_spawn_scope)
        delete world_spawn_scope[timer]
    }
  }
}

// initalize
Convars.SetValue("bot_allow_pistols", 0)
Convars.SetValue("bot_allow_shotguns", 0)
Convars.SetValue("bot_allow_sub_machine_guns", 0)
Convars.SetValue("bot_allow_rifles", 0)
Convars.SetValue("bot_allow_machine_guns", 0)
Convars.SetValue("bot_allow_grenades", 0)
Convars.SetValue("bot_allow_snipers", 0)
Convars.SetValue("bot_join_team", "ct")
Convars.SetValue("mp_limitteams", "0")
Convars.SetValue("mp_autoteambalance", "0")
Convars.SetValue("mp_flashlight", "1")

if (Convars.GetInt("bot_quota") < 1)
  Convars.SetValue("bot_quota", "15")

__CollectGameEventCallbacks(m_Events)

