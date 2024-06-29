extends CanvasLayer


onready var _fade_animation: AnimationPlayer = $"Fade Animation"
onready var _color_rect: ColorRect = $ColorRect
onready var _loading_sprite: Control = $ColorRect/loading/LoadingSprite
onready var _progress: Label = $ColorRect/loading/Label
onready var gamemodeTips: VBoxContainer = $ColorRect/gamemodeTips
onready var roundCount: Label = $ColorRect/gamemodeTips/round
onready var title: Label = $ColorRect/gamemodeTips/title
onready var desc: Label = $ColorRect/gamemodeTips/desc
onready var slowPlayerTimer: Timer = $SlowPlayerTimer
onready var cancelLoading: Button = $ColorRect/loading/Button


signal room_node_ready
signal on_progress
signal on_scene_loaded
signal done_loading


var print_info: bool = false 
var _loading_game: bool
var _quit_loading_requested: bool
var _loaded_players: Array
var _time_since_loading_start: float


func _ready():
	_color_rect.visible = false
	_loading_game = false


func disable_cancel_loading(val: bool) -> void:
	var opacity = 0.4 if val == true else 1
	cancelLoading.disabled = val
	cancelLoading.modulate = Color(1, 1, 1, opacity)


func _process(delta):
	if _loading_game == true:
		_time_since_loading_start += delta


func player_has_loaded(id: int) -> bool:
	return _loaded_players.find(id) != -1


func get_is_loading() -> bool:
	return _loading_game


func remove_loaded_player(id: int) -> void:
	var remove_at = _loaded_players.find(id)
	if remove_at != -1:
		_loaded_players.remove(remove_at)


func set_is_loading(val: bool) -> void:
	_loading_game = val


func is_allowed_to_load() -> bool:
	# We only do some functions if a player is accepted into lobby 
	# and loading the game, hence _loading_game
	return _loading_game


func check_quit_loading() -> bool:
	var host_gone: bool = true
	for player_info in Lobby.client_members:
		if player_info["id"] == Lobby.host_id:
			host_gone = false
			break
	
	if _quit_loading_requested == true || host_gone == true:
		Lobby.leave_lobby("check_quit_loading " + str(_quit_loading_requested) + " " + str(host_gone))
		return true
	
	return false


func host_generate_next_rounds_info(settings: Dictionary, map_ref: String, gamemode_ref: String) -> void:
	PacketSender.broadcast_loading_screen()
	disable_cancel_loading(true)
	yield(get_tree().create_timer(_fade_animation.get_current_animation_length() + 0.2), "timeout")
	
	# Load the game scene
	set_progress("Generating the map...")
	get_tree().change_scene(Globals.ROOM_SCENE)
	yield(get_tree().create_timer(1), "timeout")
	
	var room_node: Room = Util.get_room_node()
	if room_node != null:
		var map_node_res = load(map_ref)
		if map_node_res != null:
			var map_node = map_node_res.instance()
			room_node.environment.set_map_node(map_node)
			RoomSettings.edit_settings({"map": map_ref}, false)
			
			var initial_environment: Dictionary = map_node.generate_environment(room_node, room_node.environment)
			var initial_players: Dictionary = room_node.players.generate_inital_player_data(map_node)
			PacketSender.broadcast_or_send_start_loading_game(settings, initial_environment, initial_players)
		else:
			Lobby.leave_lobby("map gen crash")
			Globals.create_info_popup("Something went wrong", "You encountered a game breaking bug, we ejected you from the lobby to avoid a crash. Sorry for any inconvenience caused.")


func cancel_loading() -> void:
	Lobby.leave_lobby("Pressed cancel during loading")


func p2p_start_loading_game(map_ref: String, gamemode_ref: String, all_environment_info: Dictionary, all_player_info: Dictionary) -> void:
	if _loading_game == false:
		_quit_loading_requested = false
		_time_since_loading_start = 0
		_loading_game = true
		Globals.in_game = false
		_loaded_players.clear()
		
		if Lobby.is_host == false:
			show_loading_screen(true)
			yield(get_tree().create_timer(_fade_animation.get_current_animation_length() + 0.2), "timeout")
		
		status_print("1")
		disable_cancel_loading(true)
		
		Lobby.divide_players_into_teams(GamemodeValues.get_current_rounds_teammode())
		
		status_print("2")
		
		# Load the game scene, host has already done this in host_generate_next_rounds_info
		if Lobby.is_host == false:
			set_progress("Loading game logic...")
			get_tree().change_scene(Globals.ROOM_SCENE)
			yield(get_tree(), "idle_frame")
		
		status_print("3")
		
		# If we press cancel whilst yielding until room_node_ready we can get strange bugs,
		# therefore we check if the room exists
		var room_node: Room = Util.get_room_node()
		if Util.safe_to_use(room_node):
			status_print("4")
			
			# Begin loading the map scene if we aren't the host, since the host already did this in host_generate_next_rounds_info()
			if Lobby.is_host == false:
				set_progress("Loading the map...")
				var map_node = load(map_ref).instance()
				room_node.environment.set_map_node(map_node)
			
			MusicAndSfxHandler.set_upcoming_soundtrack_map_path(map_ref)
			GamemodeValues.current_map_type = Util.get_map_type_from_path(map_ref)
			
			status_print("5")
			
			# Then we load the gamemode
			set_progress("Loading the gamemode logic...")
			var gamemode_child_node = load(gamemode_ref).instance()
			room_node.gamemode.start_gamemode(gamemode_child_node)
			
			# All scenes are loaded, next step is to wait for players and env in process()
			status_print("6")
			
			set_progress("Loading players and environment...")
			load_initial_players(room_node, all_player_info)
			load_initial_environment(room_node, all_environment_info)
			
			status_print("7")
			
			set_progress("Waiting for others")
			disable_cancel_loading(false)
			PacketSender.done_loading_scenes()
		else:
			printerr("room_node wasn't safe to use, stopping the sceneloader now.")
			Lobby.leave_lobby()


func p2p_host_handle_player_has_loaded_scenes(sender_id: int) -> void:
	if Lobby.is_host:
		PacketSender.set_gamemode_data(sender_id)
		
		if _loaded_players.find(sender_id) == -1:
			_loaded_players.append(sender_id)
		else:
			printerr("WARNING: Tried to add a loaded player twice")
		
		set_progress("Waiting for others...")
		
		if _loading_game == true:
			if slowPlayerTimer.is_stopped() == true:
				slowPlayerTimer.start()
		
		status_print("Player with id " + str(sender_id) + " has loaded all their scenes ")
		
		print("Handle Client Join Step Final: ", _loaded_players.size(), " ", Lobby.client_members.size(), " _loading_game: ", _loading_game)
		
		# If the game is loading for the host and everyone is in the loaded players array, load everyone into the game at the same time
		if _loading_game == true && _loaded_players.size() == Lobby.client_members.size():
			yield(get_tree().create_timer(1), "timeout")
			print("Handle Client Join Step Final: Since everyone has loaded, start the round for everyone")
			for loaded_player_id in _loaded_players:
				PacketSender.set_done_loading(loaded_player_id)
		# Otherwise we just join the game
		elif _loading_game == false:
			print("Handle Client Join Step Final: Since the game has already started and a player is joining mid game, send them the everyone has loaded packet. Kill all dead players if respawn isn't allowed")
			var players_node = Util.get_players_node()
			if players_node != null:
				players_node.kill_dead_players_for_joining_player(sender_id)
			PacketSender.set_done_loading(sender_id)


func set_done_loading() -> void:
	emit_signal("done_loading")
	slowPlayerTimer.stop()
	
	close_loading_screen()
	gamemodeTips.visible = false
	_loading_game = false
	
	Globals.in_game = true
	disable_cancel_loading(false)
	
	if Lobby.is_host:
		Lobby.load_waiting_players()
	
	status_print("Set done loading, this should be the last print from the sceneloader")


func handle_set_done_loading(sender_id: int) -> void:
	if sender_id == Lobby.host_id:
		status_print("p2p Set done loading")
		var room_node = Util.get_room_node()
		if room_node != null:
		
			#room_node.environment.map.host_remove_colliding_entities(room_node)
			status_print("Host start new round...")
			room_node.gamemode.host_start_new_round()
			
			set_done_loading()
		else:
			printerr("Room node was null whilst trying to set done loading.")


func load_initial_environment(room_node: Room, inital_env_to_load_dict: Dictionary) -> void:
	if Lobby.is_host == false:
		status_print("Loading initial environment from received env dict!")
		for env_id in inital_env_to_load_dict:
			var env_info: Dictionary = inital_env_to_load_dict[env_id]
			room_node.environment.add_environment(env_info, env_id)
		
		room_node.environment.map.clear_hand_placed_entities()
		
		status_print("Done loading initial environment.")
	else:
		status_print("HOST: Host has already loaded initial environment.")


func load_initial_players(room_node: Room, inital_players_to_load_dict: Dictionary) -> void:
	# Load the new players
	for player_id in inital_players_to_load_dict:
		var player_info = inital_players_to_load_dict[player_id]
		room_node.players.spawn_player(player_id, player_info)


func set_progress(text: String, percent_done: float = -1):
	if percent_done == -1:
		_progress.text = text
	else:
		_progress.text = text + " " + str(abs(round(percent_done * 100))) + " %"


func show_loading_screen(show_gamemode_tips: bool) -> void:
	status_print("Showing loading screen...")
	set_progress("Loading...")
	
	if _color_rect.visible == false:
		disable_cancel_loading(false)
		
		_color_rect.visible = true
		_color_rect.color.a = 0
		_loading_sprite.modulate = Color(1, 1, 1, 0)
		_fade_animation.play("Fade")
		MusicAndSfxHandler.stop_current_track()
		
		# Show information about the gamemode that is about to start
		if RoomSettings.settings.empty() == false:
			gamemodeTips.visible = show_gamemode_tips
			var rounds_gamemode: int = RoomSettings.get_rounds_gamemode()
			if RoomSettings.get_round_text() != "1/1":
				roundCount.text = "Round " + RoomSettings.get_round_text()
			else:
				roundCount.text = ""
			title.text = GamemodeValues.get_gamemode_title(rounds_gamemode)
			desc.text = GamemodeValues.get_gamemode_desc(rounds_gamemode)
		else:
			status_print("Room settings weren't loaded in time.")


func close_loading_screen() -> void:
	_fade_animation.play_backwards("Fade")
	
	# Don't hide until animation has played
	yield(get_tree().create_timer(_fade_animation.get_current_animation_length() + 0.2), "timeout")
	_color_rect.visible = false


func all_rounds_over(sender_id: int) -> void:
	if sender_id == Lobby.host_id:
		show_loading_screen(false)
		yield(get_tree().create_timer(_fade_animation.get_current_animation_length() + 0.2), "timeout")
		
		Lobby.all_rounds_over()
		yield(get_tree().create_timer(_fade_animation.get_current_animation_length() + 1), "timeout")
		close_loading_screen()


func status_print(message: String) -> void:
	if print_info == true:
		print("[SceneLoader]: " + message)


func _on_SlowPlayerTimer_timeout():
	status_print("Starting without slow players due to slowPlayerTimer timeout")
	set_progress("Starting without slow players...")
	for loaded_player_id in _loaded_players:
		PacketSender.set_done_loading(loaded_player_id)
