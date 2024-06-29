extends Node


onready var gamemode: Gamemode = get_parent()


func _ready():
	Lobby.connect("goal", self, "_on_goal")
	yield(get_tree(), "idle_frame")
	gamemode.set_respawn_time(6)


func _on_goal(is_blue_team: bool) -> void:
	# Give all the players in the winning team a score
	gamemode.host_set_round_over()
	
	var winner_team = "Red Team" if is_blue_team == true else "Blue Team"
	var winner_ids: Array = []
	for team in Lobby.teams:
		if team.name == winner_team:
			for team_member_id in team.member_scores:
				winner_ids.append(team_member_id)
				PacketSender.host_set_is_OP(team_member_id, gamemode.get_game_state_time(GamemodeValues.GameStates.ROUND_OVER))
				RoomSettings.set_round_winner(team_member_id)
	
	# Set losers
	for player_info in Lobby.get_all_lobby_player_info():
		var player_id = player_info["id"]
		var is_loser: bool = true
		
		for winner_id in winner_ids:
			if player_id == winner_id:
				is_loser = false
				break
		
		if is_loser == true:
			PacketSender.host_set_is_loser(player_id)
	
	PacketSender.host_broadcast_gameover_panel(winner_ids, "", "GOOOAL!", "Your team lost!")


