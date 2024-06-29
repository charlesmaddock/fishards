extends Node
class_name Gamemode


signal player_respawn(id)
signal round_starting()
signal round_started()
signal round_over()


var _my_client_is_dead: bool = false
var _respawn_time: float = 3
var _timed_rounds: bool = true
var _spectate_index: int 
var _game_state_times: Dictionary = {
	GamemodeValues.GameStates.STARTING: 4.0,
	GamemodeValues.GameStates.GAME: 180.0,
	GamemodeValues.GameStates.ROUND_OVER: 8.0,
}
var _is_first_round: bool = true
var current_game_state: int = -1
var next_game_state: int = -1
var round_almost_over: bool
var _gamemode_child: Node
var _difficulty_health_mod: float = 1
var _count_down_time: int = -1

onready var gamemodeControlParent: Node = $GamemodeControl
onready var gameStateTimer: Timer = $GameStateTimer
onready var allRoundsOverTimer: Timer = $AllRoundsOverTimer
onready var roundOverTimer: Timer = $RoundOverTimer
onready var elementSwitchTimer: Timer = $ElementSwitchTimer

onready var winnersDisplay: Control = $GamemodeControl/WinnersDisplay
onready var gameOverPanel = $GamemodeControl/GameOverPanel
onready var leaderBoard = $GamemodeControl/Leaderboard
onready var mapShrinker = $MapShrinker

onready var deathPanel: Control = $GamemodeControl/DeathPanel
onready var deathPanelText: Label = $GamemodeControl/DeathPanel/Margin/VBox/Text
onready var deathPanelTitle: Label = $GamemodeControl/DeathPanel/Margin/VBox/Title
onready var deathPopup: ColorRect = $GamemodeControl/DeathPopup
onready var spectateTip: Control = $GamemodeControl/SpectateTip

onready var gameStartingScreen: Control = $GamemodeControl/GameStartingScreen
onready var gameStartingScreenTimerText: Label = $GamemodeControl/GameStartingScreen/Panel/Countdown
onready var gamemodeText: Label = $GamemodeControl/GameStartingScreen/Panel/GamemodeText
onready var currentRoundText: Label = $GamemodeControl/GameStartingScreen/Panel/Round
onready var centerScreenTimer: Timer = $CenterScreenTimer

onready var inGameScreen: Control = $GamemodeControl/InGameScreen
onready var inGameScreenLabel: Label = $GamemodeControl/InGameScreen/InGameScreenIconContainer/Text
onready var inGameIcon: TextureRect = $GamemodeControl/InGameScreen/InGameScreenIconContainer/Icon/TextureRect
onready var inGameIconShadow: TextureRect = $GamemodeControl/InGameScreen/InGameScreenIconContainer/Icon/TextureRect2
onready var inGameAnimator: AnimationPlayer = $GamemodeControl/InGameScreen/InGameScreenIconContainer/IngameIconAnimation
onready var timer_icon: Texture = load("res://Assets/Images/UI/Game/timer_icon.png")
onready var fish_icon: Texture = load("res://Assets/Images/UI/Game/fish_icon.png")

onready var killLog: VBoxContainer = $GamemodeControl/KillLog
var kill_log_item_scene = preload("res://Scenes/Game/KillLogItem.tscn")


func start_gamemode(gamemode_child: Node) -> void:
	Globals.set_ui_interaction_mode(Globals.UIInteractionModes.GAMEPLAY)
	AchievementHandler.on_round_start()
	
	add_child(gamemode_child)
	_gamemode_child = gamemode_child
	
	var current_gamemode_info = GamemodeValues.get_current_rounds_gamemodeinfo()
	
	if current_game_state == GamemodeValues.GameStates.GAME:
		MusicAndSfxHandler.play_current_soundtrack()
	
	_timed_rounds = current_gamemode_info["timed_rounds"]
	if current_gamemode_info["respawn_allowed"] == false:
		_respawn_time = -1 
	
	roundOverTimer.wait_time = _game_state_times[GamemodeValues.GameStates.ROUND_OVER]
	
	inGameScreen.call_deferred("set_visible", true)
	if _timed_rounds == true:
		inGameIcon.texture = timer_icon
		inGameIconShadow.texture = timer_icon
	elif RoomSettings.get_rounds_gamemode() == GamemodeValues.Gamemodes.Survive:
		inGameIcon.call_deferred("set_visible", false)
		inGameIconShadow.call_deferred("set_visible", false)
	else:
		inGameIcon.texture = fish_icon
		inGameIconShadow.texture = fish_icon


func _ready():
	Lobby.connect("room_settings_updated", self, "_on_room_settings_update")
	Lobby.connect("player_killed", self, "_on_player_killed")
	Lobby.connect("force_next_round", self, "_on_force_next_round")
	
	gameStartingScreen.visible = false
	spectateTip.visible = false
	
	gameOverPanel.hide_gameover_panel()
	hide_death_panel()
	
	var current_gamemode = RoomSettings.get_rounds_gamemode()
	if current_gamemode == GamemodeValues.Gamemodes.Training || current_gamemode == GamemodeValues.Gamemodes.Tutorial:
		_game_state_times[GamemodeValues.GameStates.STARTING] = 0


func update_amount_of_alive_players() -> void:
	if _timed_rounds == false && RoomSettings.get_rounds_gamemode() != GamemodeValues.Gamemodes.Survive:
		var amount_left = get_amount_of_players_left()
		inGameScreenLabel.text = str(amount_left)


func set_leaderboard(player_scores: Array) -> void:
	if leaderBoard != null:
		leaderBoard.p2p_set_player_scores(player_scores)


func set_new_wave(wave: int) -> void:
	_gamemode_child.new_round(wave)


func set_wave_text(wave: int) -> void:
	inGameScreenLabel.text = "Wave " + str(wave)


func _input(event):
	var switch_left: bool
	var switched: bool = true
	if event.get_action_strength("ui_left") == 1 || Input.is_key_pressed(KEY_LEFT):
		switch_left = true
	elif event.get_action_strength("ui_right") == 1  || Input.is_key_pressed(KEY_RIGHT):
		switch_left = false
	else:
		switched = false
	
	if switched == true:
		check_switch_spectate(switch_left)


func _process(_delta):
	update_round_timer_label()
	
	if Lobby.is_host && current_game_state == GamemodeValues.GameStates.STARTING:
		var current_gamemode = RoomSettings.get_rounds_gamemode()
		if current_gamemode != GamemodeValues.Gamemodes.Training && current_gamemode != GamemodeValues.Gamemodes.Tutorial:
			var prev_count_down_time: int = _count_down_time
			_count_down_time = ceil(get_state_time_left() -1)
			
			if prev_count_down_time != _count_down_time:
				PacketSender.broadcast_countdown(_count_down_time)


func p2p_set_countdown(count_down_time: int) -> void:
	if count_down_time == 0:
		var fight_phrases = ["Fight!", "Battle!", "Go!", "Brawl!"]
		var rare_fight_phrases = ["Never corner a fish wizard!", "fishwar!", "You're a fishard, Harry!", "Blub!", "Fiskarl!", "Fish it!", "Fish 'em up!", "Something's fishy...", "Fish are aquatic, gill-bearing animals that lack limbs with digits!", "Lycka till!", "Sretno!", "Buona fortuna!", "Bonne chance!", "Buena suerte!"]
		var fight_phrase = ""
		if Util.rand.randf() < 0.03:
			fight_phrase = rare_fight_phrases[Util.rand.randi_range(0, rare_fight_phrases.size() - 1)]
		else:
			fight_phrase = fight_phrases[Util.rand.randi_range(0, fight_phrases.size() - 1)]
		
		MusicAndSfxHandler.play_sound(MusicAndSfxHandler.sounds.COUNT_DOWN_GO)
		gameStartingScreenTimerText.text = fight_phrase
	elif gameStartingScreenTimerText.text != str(count_down_time):
		MusicAndSfxHandler.play_sound(MusicAndSfxHandler.sounds.COUNT_DOWN)
		gameStartingScreenTimerText.text = str(count_down_time)
	
	show_text_center_screen("", 1, true)



func get_game_state_time(key: int):
	return _game_state_times[key]


func get_difficulty_health_mod(player_type: int) -> float:
	var is_boss = Util.player_is_boss(player_type)
	var boss_mod = Lobby.client_members.size() if is_boss == true else 1
	return _difficulty_health_mod * boss_mod


func get_respawn_time() -> float:
	if current_game_state == GamemodeValues.GameStates.ROUND_OVER || (next_game_state == GamemodeValues.GameStates.ROUND_OVER && _respawn_time > get_state_time_left() && _timed_rounds == true):
		return -1.0
	return _respawn_time


func get_state_time_left() -> float:
	return gameStateTimer.time_left


func get_wave() -> float:
	if get_child(0).has_method("get_wave"):
		return get_child(0).get_wave()
	return 0.0


func reset_difficulty() -> void:
	_difficulty_health_mod = 1.0


func inc_difficulty() -> void:
	_difficulty_health_mod += 0.17


func set_respawn_time(val: float) -> void:
	_respawn_time = val


func set_game_state_timer(time: float) -> void:
	gameStateTimer.wait_time = time + 0.001
	gameStateTimer.start()


func get_shrink_progress() -> float:
	if mapShrinker != null:
		return mapShrinker.get_shrink_progress()
	else:
		return -1.0


func get_last_player_standing() -> int:
	var non_clone_living_players: Array = []
	var players_node = Util.get_players_node() 
	if players_node != null:
		var living_player_ids = players_node.get_living_player_ids()
		for player_id in living_player_ids:
			var player_entity: Entity = players_node.get_player_entity(player_id)
			if player_entity != null:
				if player_entity.get_component_of_type(Globals.ComponentTypes.Player).get_is_clone() == false:
					non_clone_living_players.append(player_id)
	
	if non_clone_living_players.size() != 1:
		#printerr("Hmm, there was more or less than one player left...")
		return -1
	
	return non_clone_living_players[0]


func get_amount_of_players_left(in_team: Dictionary = {}) -> int:
	var players_node = Util.get_players_node() 
	if players_node != null:
		var living_player_components: Array
		var living_players_ids: Array = players_node.get_living_player_ids()
		var amount_of_living_players: int
		
		if RoomSettings.get_rounds_gamemode() == GamemodeValues.Gamemodes.Survive:
			var team_info = Lobby.get_team_w_name("Red Team")
			if team_info.empty() == false:
				return team_info["member_scores"].size()
		
		if in_team.empty() == true:
			for living_player_id in living_players_ids:
				living_player_components.append(players_node.get_player_component(living_player_id, "get_amount_of_players_left 1"))
		else:
			for player_id in in_team["member_scores"]:
				if living_players_ids.has(player_id):
					living_player_components.append(players_node.get_player_component(player_id, "get_amount_of_players_left 2"))
		
		amount_of_living_players = living_player_components.size()
		
		# Don't include with clone into count
		for living_player_component in living_player_components:
			if living_player_component != null:
				if living_player_component.get_is_clone() == true:
					amount_of_living_players -= 1
		
		return amount_of_living_players
	
	print("Couldn't get amount of players left.")
	return 0


func host_start_new_round() -> void:
	if Lobby.is_host:
		PacketSender.change_game_state(GamemodeValues.GameStates.STARTING, _game_state_times[GamemodeValues.GameStates.STARTING])


func host_set_round_over() -> void:
	if Lobby.is_host:
		PacketSender.change_game_state(GamemodeValues.GameStates.ROUND_OVER, _game_state_times[GamemodeValues.GameStates.ROUND_OVER])


func _on_GameStateTimer_timeout():
	if Lobby.is_host:
		PacketSender.change_game_state(next_game_state, _game_state_times[next_game_state])


func p2p_handle_broadcast_gameover_panel(winner_ids, text, winner_title, loser_title) -> void:
	gameOverPanel.p2p_show_gameover_panel(winner_ids, text, winner_title, loser_title)


# Should only be called via packet 
func p2p_change_game_state(state: int, time_until_next_state: float) -> void:
	if current_game_state == state:
		printerr("Tried to set ", GamemodeValues.GameStates.keys()[state], " game state when already in that state")
		return
	
	hide_all_state_panels()
	current_game_state = state
	
	match state:
		GamemodeValues.GameStates.STARTING:
			show_text_center_screen("Round " + RoomSettings.get_round_text(), get_game_state_time(GamemodeValues.GameStates.STARTING), true)
			hide_death_panel()
			
			inGameAnimator.play("start")
			
			next_game_state = GamemodeValues.GameStates.GAME
			
			emit_signal("round_starting")
			
			var players_node = Util.get_players_node()
			if players_node != null:
				players_node.trap_all_players_for(get_game_state_time(GamemodeValues.GameStates.STARTING))
			
			set_game_state_timer(time_until_next_state)
			yield(get_tree(), "idle_frame")
			update_amount_of_alive_players()
			
			if RoomSettings.get_element_mode() == Globals.ElementModes.RANDOM:
				set_random_elements(true)
			elif RoomSettings.get_element_mode() == Globals.ElementModes.TIMED:
				set_random_elements(false)
				PacketSender.elements_changed()
				elementSwitchTimer.start(30)
			
		GamemodeValues.GameStates.GAME:
			MusicAndSfxHandler.play_current_soundtrack()
			
			inGameScreen.set_visible(true)
			next_game_state = GamemodeValues.GameStates.ROUND_OVER
			
			emit_signal("round_started")
			
			if _timed_rounds == true:
				set_game_state_timer(time_until_next_state)
			else:
				gameStateTimer.stop()
			
		GamemodeValues.GameStates.ROUND_OVER: 
			next_game_state = GamemodeValues.GameStates.STARTING
			
			inGameScreen.set_visible(false)
			emit_signal("round_over")
			
			mapShrinker.hide()
			gameStateTimer.stop()
			roundOverTimer.start()


func p2p_set_gamemode_data(data: Dictionary) -> void:
	current_game_state = data["game_state"]
	if current_game_state == GamemodeValues.GameStates.GAME:
		var current_gamemode_info = GamemodeValues.get_current_rounds_gamemodeinfo()
		if current_gamemode_info["timed_rounds"] == true:
			set_game_state_timer(data["time"])
		else:
			gameStateTimer.stop()
		
		if mapShrinker != null && data["shrink_prog"] != -1.0:
			print("setting shrink_prog: ", data["shrink_prog"])
			mapShrinker.set_shrink_progress(data["shrink_prog"])
		
		if current_gamemode_info.title == "Protect Fish God" && get_child(0).has_method("set_wave"):
			get_child(0).set_wave(data["wave"])


func hide_all_state_panels() -> void:
	#should be more generics
	for child in gamemodeControlParent.get_children():
		child.visible = false
		gameStateTimer.start()


func show_text_center_screen(text: String, time: float, starting_round: bool = false) -> void:
	gameStartingScreen.visible = true
	gameStartingScreenTimerText.visible = starting_round
	currentRoundText.text = "Round " + RoomSettings.get_round_text()
	currentRoundText.visible = starting_round
	 
	if starting_round == true:
		gamemodeText.text = GamemodeValues.get_current_rounds_gamemodeinfo()["title"]
	else:
		gamemodeText.text = text
	
	centerScreenTimer.start(time)


func show_death_panel(killer_entity: Entity, title: String = "You died!"):
	if gameOverPanel.visible == false:
		deathPanel.visible = true
		deathPanelTitle.text = title
		deathPopup.call_deferred("show_popup", title)
		
		var first_text = ""
		if killer_entity != null:
			var player: Player = killer_entity.get_component_of_type(Globals.ComponentTypes.Player)
			first_text = "You were killed by " + player.get_username() + "!"
			if killer_entity.is_my_client:
				first_text = "You killed yourself"
		
		if GamemodeValues.get_current_rounds_spectate_mode() != GamemodeValues.SpectateMode.NONE:
			spectateTip.visible = true
		
		var time_left_till_respawn = _respawn_time
		deathPanelText.text = first_text


func hide_death_panel() -> void:
	deathPanel.visible = false
	spectateTip.visible = false


func update_round_timer_label() -> void:
	if _timed_rounds:
		if current_game_state == GamemodeValues.GameStates.STARTING:
			inGameScreenLabel.text = str(int(get_state_time_left()) + get_game_state_time(GamemodeValues.GameStates.GAME))
		elif current_game_state == GamemodeValues.GameStates.GAME:
			inGameScreenLabel.text = str(int(get_state_time_left()))
			if round_almost_over == false && get_state_time_left() < 20:
				round_almost_over = true
				inGameScreenLabel.set("custom_colors/font_color", Color.red)
				inGameIcon.set_modulate(Color.red) 
				inGameAnimator.play("warning")


func check_shrink_map() -> void:
	if Lobby.is_host:
		var players_node = Util.get_players_node()
		if players_node != null:
			var amount_left = players_node.get_living_player_ids().size()
			var total_amount = players_node.player_ids.size()
			if amount_left <= total_amount / 2.5:
				PacketSender.start_shrink()


func p2p_start_shrink() -> void:
	if mapShrinker != null:
		mapShrinker.check_start_shrink()


func p2p_handle_player_death(killed_id: int, killer_id: int) -> void:
	update_amount_of_alive_players()
	check_shrink_map()
	
	var players_node = Util.get_players_node()
	if players_node != null:
		if killed_id == SteamValues.STEAM_ID:
			_my_client_is_dead = true
			show_death_panel(players_node.get_player_entity(killer_id))
		
		# If the person we are spectating or ourselves die, spectate someone else
		if killed_id == SteamValues.STEAM_ID || killed_id == Globals.camera_following_id:
			if GamemodeValues.get_current_rounds_spectate_mode() == GamemodeValues.SpectateMode.EVERYONE:
				var spectate_player: Entity = players_node.get_living_player_entity(killer_id) 
				if spectate_player != null:
					# Find the person who killed us and spectate them, if we killed ourselves, dont spectate
					_spectate_index = players_node.get_living_player_ids().find(spectate_player, 0)
					Globals.set_camera_following(spectate_player)
				else:
					spectate_player = players_node.get_random_living_player()
					if spectate_player != null:
						Globals.set_camera_following(spectate_player)
			elif GamemodeValues.get_current_rounds_spectate_mode() == GamemodeValues.SpectateMode.OWN_TEAM:
				# Just spectate a player on our team by calling the switch spectate function 
				_spectate_index = 0
				check_switch_spectate(true)


func p2p_handle_player_respawn(id: int) -> void:
	if id == SteamValues.STEAM_ID:
		_my_client_is_dead = false
		hide_death_panel()


func p2p_handle_all_players_respawn() -> void:
	_my_client_is_dead = false
	hide_death_panel()


func set_random_elements(same_elements: bool) -> void:
	if Lobby.is_host:
		var elements = Util.generate_available_elements(RoomSettings.get_element_amount())
		
		for player_info in Lobby.get_all_lobby_player_info():
			player_info["elmts"] = elements
			if same_elements == false:
				elements = Util.generate_available_elements(RoomSettings.get_element_amount()).duplicate(true)
		
		PacketSender.host_update_lobby_players(Lobby.client_members, Lobby._bot_members, Lobby._temp_bot_members)
		Lobby.emit_signal("lobby_members_updated")


func respawn_all_players() -> void:
	var room_node = Util.get_room_node()
	if room_node != null:
		room_node.host_respawn_all_players()


func respawn_all_dead_players() -> void:
	var room_node = Util.get_room_node()
	if room_node != null:
		room_node.host_respawn_all_players(true)


func add_score_to_player(player_id: int, score: int) -> void:
	if Lobby.is_host:
		for team in Lobby.get_teams():
			if team["member_scores"].has(player_id):
				PacketSender.set_score(player_id, team["member_scores"][player_id] + score, false)
				return


func get_coop_team_members_with_highest_score() -> Dictionary:
	var players_node = Util.get_players_node()
	if players_node != null:
		var largest_score: int = -1
		var best_players: Dictionary = {} 
		var coop_team = Lobby.get_team_w_name("Blue Team")
		
		for player_id in coop_team["member_scores"]:
			var member_score: int = coop_team["member_scores"][player_id]
			var player = players_node.get_player_component(player_id, "get_coop_team_members_with_highest_score")
			if player != null:
				if member_score > largest_score:
					best_players.clear()
					best_players[player.get_username()] = {"score": member_score, "id": player_id}
					largest_score = member_score
				elif member_score == largest_score:
					best_players[player.get_username()] = {"score": member_score, "id": player_id}
		
		return best_players
	return {}


func get_team_infos_with_highest_score() -> Array:
	var largest_team_score: int = -1
	var best_team_infos: Array # of team info Dictionaries
	for team_info in Lobby.get_teams():
		var teams_score: int = Lobby.get_team_total_score(team_info)
		
		if teams_score > largest_team_score:
			best_team_infos.clear()
			best_team_infos.append(team_info)
			largest_team_score = teams_score
		elif teams_score == largest_team_score:
			best_team_infos.append(team_info)
	
	return best_team_infos


func check_switch_spectate(switch_left: bool = false) -> void:
	var players_node = Util.get_players_node()
	if players_node != null && _my_client_is_dead && GamemodeValues.get_current_rounds_spectate_mode() != GamemodeValues.SpectateMode.NONE:
		# Create a list of player IDs that we can spectate
		var spectatable_players: Array # Array of player IDs
		if GamemodeValues.get_current_rounds_spectate_mode() == GamemodeValues.SpectateMode.OWN_TEAM:
			var my_team = Lobby.get_team_info_from_player_id(SteamValues.STEAM_ID)
			if my_team.empty() == false:
				var my_teams_player_ids = my_team["member_scores"].keys()
				for player_id in my_teams_player_ids:
					if players_node.is_alive(player_id) == true:
						spectatable_players.append(player_id)
		elif GamemodeValues.get_current_rounds_spectate_mode() == GamemodeValues.SpectateMode.EVERYONE:
			for living_player_id in players_node.get_living_player_ids():
				spectatable_players.append(living_player_id)
		 
		# Jump left or right in the created list
		if switch_left == true:
			_spectate_index -= 1
			if _spectate_index < 0:
				_spectate_index = spectatable_players.size() - 1
		else:
			_spectate_index += 1
			if _spectate_index >= spectatable_players.size():
				_spectate_index = 0

		if _spectate_index >= 0 && spectatable_players.empty() == false:
			Globals.set_camera_following(players_node.get_player_entity(spectatable_players[_spectate_index]))


func _on_player_killed(killed_id, killer_id, killed_with_spell): 
	var killer_name = ""
	var killed_name = ""
	for player_info in Lobby.get_all_lobby_player_info():
		if player_info["id"] == killer_id:
			killer_name = player_info["name"]
		if player_info["id"] == killed_id:
			killed_name = player_info["name"]
	
	if killer_name != "" && killed_name != "" && killed_with_spell != Globals.SpellTypes.NONE:
		killLog.set_visible(true)
		var kill_log_item = kill_log_item_scene.instance()
		kill_log_item.set_values(killer_name, killed_name, killed_with_spell)
		killLog.add_child(kill_log_item)


func _on_room_settings_update():
	update_amount_of_alive_players()


func _on_force_next_round() -> void:
	host_set_round_over()


func _on_CenterScreenTimer_timeout():
	gameStartingScreen.visible = false


func _on_RoundOverTimer_timeout():
	Util.log_print("Gamemode", "Round over timeout")
	var next_round_status: Dictionary = RoomSettings.next_round_status()
	if next_round_status.all_rounds_over == true:
		
		if Lobby.is_host:
			PacketSender.broadcast_winner_display()
		
		Util.log_print("Gamemode", "Host: Starting all rounds over timer.")
		allRoundsOverTimer.start()
	else:
		RoomSettings.host_start_next_round(false)


func p2p_show_winners_display() -> void:
	if winnersDisplay != null:
		winnersDisplay.show_all_round_winners()


func _on_AllRoundsOverTimer_timeout():
	if Lobby.is_host == true:
		Util.log_print("Gamemode", "Host: All rounds over time out, running SceneLoader.all_rounds_over()")
		PacketSender.broadcast_all_rounds_over()
		Util.log_print("Gamemode", "Host: Broadcasted.")


func _on_ElementSwitchTimer_timeout():
	if RoomSettings.get_element_mode() == Globals.ElementModes.TIMED:
		set_random_elements(false)
		PacketSender.elements_changed()
