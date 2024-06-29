extends Node


var leader_player_id: int = -1

onready var gamemode: Gamemode = get_parent()
onready var crown: Spatial = $Crown


func _ready():
	Lobby.connect("player_killed", self, "_on_player_killed")
	Lobby.connect("destroy_entity", self, "_on_entity_destroyed")
	gamemode.connect("round_over", self, "_on_round_over")


func _process(delta):
	if leader_player_id != -1:
		var room_node = Util.get_room_node()
		if room_node != null:
			var leader = room_node.get_entity(leader_player_id, "crown follow")
			if leader != null:
				crown.transform.origin = crown.transform.origin.linear_interpolate(leader.get_pos() + Vector3.UP * 2.5, delta * 4)
	else:
		crown.transform.origin = crown.transform.origin.linear_interpolate(Vector3.DOWN * 3, delta * 4)


func _on_round_over():
	var winners = gamemode.get_team_infos_with_highest_score()
	var winner_ids = []
	var loser_ids = []
	var winner_text = create_winner_text(winners)
	
	for winner in winners:
		var winner_player_id: int = winner["member_scores"].keys()[0]
		winner_ids.append(winner_player_id)
		PacketSender.host_set_is_OP(winner_player_id, gamemode.get_game_state_time(GamemodeValues.GameStates.ROUND_OVER))
		RoomSettings.set_round_winner(winner_player_id)
	
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
	
	gamemode.respawn_all_dead_players()
	PacketSender.host_broadcast_gameover_panel(winner_ids, winner_text)


func _on_player_killed(killed_id, killer_id, _killed_with_spell):
	if killed_id != killer_id:
		gamemode.add_score_to_player(killer_id, 1)
	
	var leaders = gamemode.get_team_infos_with_highest_score()
	if leaders.size() > 0:
		leader_player_id = leaders[0]["member_scores"].keys()[0]


func _on_entity_destroyed(entity_id: int) -> void:
	if leader_player_id == entity_id:
		leader_player_id = -1


func create_winner_text(winners: Array) -> String:
	var winner_text: String 
	var score: String = String(winners[0]["member_scores"].values()[0])
	if winners.size() == 1:
		winner_text = "The winner is " + str(winners[0]["name"]) + " with " + score + " kills!"
	elif winners.size() >= 1:
		winner_text = "There was a tie between the " + str(winners.size()) + " top players, who all got " + score + " kills!"
		
	return winner_text
