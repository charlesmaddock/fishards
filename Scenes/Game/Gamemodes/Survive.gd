extends Node


var _alive_enemy_players: int = 0
var _is_first_round: bool = true
var winner_entity_id: int = 0


onready var gamemode: Gamemode = get_parent()
var time: float = 8.0
var _wave: float = 0
var levels: Array
onready var timer_node = $Timer

export(Curve) var difficulty_curve


func _ready():
	Lobby.connect("player_killed", self, "_on_player_killed")
	gamemode.connect("round_over", self, "_on_round_over")
	gamemode.connect("round_started", self, "_on_round_started")
	Lobby.connect("gooey_god_dead", self, "_on_gooey_god_dead")
	
	levels = Util.generate_temp_bot_levels(difficulty_curve, float(Lobby.get_all_lobby_player_info().size()), false)
	new_round(1)
	yield(get_tree(), "idle_frame")
	gamemode.set_respawn_time(6)


func get_wave() -> float:
	return _wave


func set_wave(wave) -> void:
	_wave = float(wave)


func _on_round_started() -> void:
	Lobby.emit_signal("lobby_chat", "Gooey Golden God", "Loyal Fishards, protect me from the horde of evil Wizishes charging from the east.")


func _on_round_over() -> void:
	var winners_dict = gamemode.get_coop_team_members_with_highest_score()
	var winner_text = create_winner_text(winners_dict)
	
	for winner_player_obj in winners_dict.values():
		RoomSettings.set_round_winner(winner_player_obj.id)
	
	gamemode.respawn_all_dead_players()
	
	var title = "You survived " + str(_wave) + " rounds"
	PacketSender.host_broadcast_gameover_panel([], winner_text, title, title)


func _on_gooey_god_dead() -> void:
	gamemode.host_set_round_over()


func _on_player_killed(killed_id, killer_id, killed_with_spell):
	if killed_id != killer_id:
		gamemode.add_score_to_player(killer_id, 1)
	
	if gamemode.current_game_state == GamemodeValues.GameStates.GAME:
		# Update amount of enemies
		var team: Dictionary =  Lobby.get_team_info_from_player_id(killed_id)
		if team.empty() == false:
			if team.name == "Red Team":
				_alive_enemy_players -= 1
				if _alive_enemy_players == 0:
					if Lobby.is_host == true:
						PacketSender.broadcast_new_wave(_wave + 1)
				
				yield(get_tree().create_timer(0.5), "timeout")
				PacketSender.host_broadcast_destroy_entity(killed_id)


func new_round(wave: int) -> void:
	_wave = wave
	
	var level_text = levels[_wave - 1]["text"]
	if level_text != "":
		MusicAndSfxHandler.play_sound(MusicAndSfxHandler.sounds.SENSEI_ANGRY3)
		gamemode.call_deferred("show_text_center_screen", "Boss: " + level_text, 3, false)
	elif _wave > 1:
		MusicAndSfxHandler.play_sound(MusicAndSfxHandler.sounds.COUNT_DOWN)
		gamemode.call_deferred("show_text_center_screen", "Wave " + str(_wave), 3)
	
	gamemode.inc_difficulty()
	gamemode.set_wave_text(_wave)
	timer_node.start(2)


func _on_timer_timeout() -> void:
	var players_node = Util.get_players_node()
	_alive_enemy_players = levels[_wave - 1]["bots"].size()
	if players_node != null:
		for bot_type in levels[_wave - 1]["bots"]:
			yield(get_tree().create_timer(0.5), "timeout")
			players_node.host_spawn_temp_bot("Wizishes", bot_type)
	
	#print("_alive_enemy_players: ", _alive_enemy_players)


func create_winner_text(winners_dict: Dictionary) -> String:
	var winner_text: String 
	
	if winners_dict.size() == 1:
		winner_text = str(winners_dict.keys()[0]) + " killed the most bots. They killed " + str(winners_dict.values()[0].score) + " bots!"
	elif winners_dict.size() >= 1:
		winner_text = "There was a tie between the " + str(winners_dict.keys().size()) + " top players, who all killed " + str(winners_dict.values()[0].score) + " bots!"
		
	return winner_text
