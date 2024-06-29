extends Node


onready var gamemode: Gamemode = get_parent()
var _my_team_won: bool
var winner_team: String

func _ready():
	Lobby.connect("player_killed", self, "_on_player_killed")
	gamemode.connect("round_over", self, "_on_round_over")


func _on_round_over() -> void:
	# Give all the players in the winning team a score
	var winner_ids: Array = []
	for team in Lobby.teams:
		if team.name == winner_team:
			for team_member_id in team.member_scores:
				winner_ids.append(team_member_id)
				RoomSettings.set_round_winner(team_member_id)
	
	PacketSender.host_broadcast_gameover_panel(winner_ids, "", "Your team won!", "Your team lost!")


func _on_player_killed(killed_id, killer_id, killed_with_spell):
	var player_node = Util.get_players_node()
	if player_node != null:
		if gamemode.current_game_state == GamemodeValues.GameStates.GAME:
			if killed_id != killer_id:
				gamemode.add_score_to_player(killer_id, 1)
			var dead_players_team: Dictionary = Lobby.get_team_info_from_player_id(killed_id)
			var anyone_alive = false
			if dead_players_team.has("member_scores"):
				for member_id in dead_players_team["member_scores"]:
					if player_node.get_living_player_entity(member_id) != null && member_id != killed_id:
						anyone_alive = true
						break
			
			if anyone_alive == false:
				# Check if you are in the dead players team
				_my_team_won = dead_players_team["member_scores"].has(SteamValues.STEAM_ID) == false
				
				if dead_players_team.name == "Blue Team":
					winner_team = "Red Team"
				else:
					winner_team = "Blue Team"
				
				gamemode.host_set_round_over()
