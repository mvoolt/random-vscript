::TEAM_UNAS <- 0
::TEAM_SPEC <- 1
::TEAM_T    <- 2
::TEAM_CT   <- 3
::MaxPlayers <- MaxClients().tointeger()

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

//::startingTime <- -1
::gotAchievement <- false

m_Events <- {
  OnGameEvent_player_spawn = function(params) {
    local player = GetPlayerFromUserID(params.userid)
    if (!IsPlayerABot(player) && player.GetTeam() == TEAM_T) {
		player.SetTeam(TEAM_CT);
    }

	//if (!IsPlayerABot(player) && player.GetTeam() == TEAM_CT)
	//	if (startingTime == -1)
	//		startingTime = Time()

  }

  OnGameEvent_round_freeze_end = function(params) {
	local CTScore = NetProps.GetPropInt(CSTeamMgr, "m_iScore")
	if (gotAchievement || CTScore < 101) {
		foreach (player in GetTeamArray(TEAM_T)) {
			player.TakeDamage(player.GetHealth() * player.GetHealth(), 0, Entities.First())
		}
	}// else {
	//	print("DONE!\n")
	//	print("starting time " + startingTime + "\n")
	//	print("end time " + Time() + "\n")
	//}
  }
  
  OnGameEvent_achievement_earned = function(params) {
    ::gotAchievement = true // could lock this to the map achievements but i'm lazy
  }
}

Convars.SetValue("bot_join_team", "t")
Convars.SetValue("mp_limitteams", "0")
Convars.SetValue("mp_roundtime", "1")
Convars.SetValue("mp_autoteambalance", "0")
Convars.SetValue("bot_quota", "1")
Convars.SetValue("mp_freezetime", "0")

// Chances are a 0.1s round restart delay could kick the player out of the server, it didn't for me so /shrug
if (Convars.GetInt("mp_round_restart_delay") == 5.0) // 5.0 is def of convar
	Convars.SetValue("mp_round_restart_delay", "0.1")
	// Minimum possible without getting kicked out due to "Buffer overflow in net message." is 0.025 which manages to get 100 wins
	// in 7.53 seconds, 0.1 gets 100 wins in 15.03 seconds


for (local team; team = Entities.FindByClassname(team, "cs_team_manager");) {
	//print("finding team manager" + NetProps.GetPropInt(team, "m_iTeamNum") + "\n");
	if (NetProps.GetPropInt(team, "m_iTeamNum") == TEAM_CT) {
		//print("found it\n")
		::CSTeamMgr <- team
	}
}

__CollectGameEventCallbacks(m_Events)
