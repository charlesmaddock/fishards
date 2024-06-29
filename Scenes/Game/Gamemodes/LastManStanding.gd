extends Node


var _is_first_round: bool = true
onready var gamemode: Gamemode = get_parent()


func _ready():
	Lobby.connect("player_killed", self, "_on_player_killed")
	gamemode.connect("round_over", self, "_on_round_over")


func _on_round_over() -> void:
	var player_node = Util.get_players_node()
	if player_node != null:
		var winner_entity_id = gamemode.get_last_player_standing()
		var winners_team = Lobby.get_team_info_from_player_id(winner_entity_id)
		if winner_entity_id != -1:
			var winner_entity: Entity = Util.get_players_node().get_player_entity(winner_entity_id)
			if winner_entity != null:
				var player = winner_entity.get_component_of_type(Globals.ComponentTypes.Player)
				if player != null:
					RoomSettings.set_round_winner(winner_entity.get_id())
					PacketSender.host_set_is_OP(winner_entity.get_id(), gamemode.get_game_state_time(GamemodeValues.GameStates.ROUND_OVER))
					# Respawn all the players so winner can kill them
					gamemode.respawn_all_dead_players()
					PacketSender.host_broadcast_gameover_panel([winner_entity_id], player.get_username() + " is the last fish standing!")
		
			# Set losers
			for player_info in Lobby.get_all_lobby_player_info():
				var player_id = player_info["id"]
				if player_id != winner_entity_id:
					PacketSender.host_set_is_loser(player_id)
		
		else:
			PacketSender.host_broadcast_gameover_panel([], "Noone won...")


func _on_player_killed(killed_id, killer_id, killed_with_spell):
	if killed_id != killer_id:
		gamemode.add_score_to_player(killer_id, 1)
	
	if gamemode.current_game_state == GamemodeValues.GameStates.GAME:
		var alive_players = gamemode.get_amount_of_players_left()
		if alive_players == 1:
			gamemode.host_set_round_over()
		elif alive_players < 1:
			gamemode.host_set_round_over()
