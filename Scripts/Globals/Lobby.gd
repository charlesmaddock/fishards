extends Node


enum LobbyStates {
	NO_LOBBY,
	LOADING_LOBBY,
	LOBBY,
	ROUND_LOADING,
	ROUND_STARTING,
	ROUND_JOINED_GAME,
	ROUND_OVER,
}


enum ClientStatus {
	WAITING_TO_JOIN,
	JOINED_GAME
}


var lobby_id: int = 0
var lobby_name: String
var lobby_state: int = LobbyStates.NO_LOBBY
var password_required: bool
var is_host: bool = false
var host_id: int = 0
var SECURE_GAME: bool = true
var _start_round_on_loaded: bool = false
var _searching_for_quickplay: bool = false

var total_ping_time: float
var ping: float
var time_since_last_ping: float
var measuring_ping: bool
var amount_of_measurements: int
var afk_time: float

var client_members_status: Dictionary = {}
var client_members: Array = []
var _bot_members: Array = []
var _temp_bot_members: Array = []
var teams: Array

var game_loaded: bool = false
var accepted_into_lobby: bool = false

signal room_settings_updated()
signal broadcast_leaderboard_req()
signal teams_set()
signal main_menu_loaded()
signal was_not_accepted_into_lobby(response)
signal update_loading_status(text)
signal lobby_chat(sender, message)
signal lobby_message(message)
signal lobby_members_updated()
signal player_killed(killed_id, killer_id, killed_with_spell)
signal player_immobilized(player_id)
signal player_respawn(dead_player_id)
signal destroy_entity(id)
signal update_elements(elements)
signal force_next_round()
signal gooey_god_dead()
signal goal()
signal ping_updated(ping, ping_avg)


func _ready():
	var join_req_res = Steam.connect("join_requested", self, "initial_steam_join_lobby")
	var join_res = Steam.connect("lobby_joined", self, "_on_lobby_joined")
	var p2p_req_res = Steam.connect("p2p_session_request", self, "_on_P2P_session_request")
	var p2p_fail_res = Steam.connect("p2p_session_connect_fail", self, "_on_P2P_session_connect_fail")
	var lbby_crt_res = Steam.connect("lobby_created", self, "_on_lobby_created")
	var chat_upt_res = Steam.connect("lobby_chat_update", self, "_on_lobby_chat_update")
	var get_lobbies_res = Steam.connect("lobby_match_list", self, "_on_get_lobby_match_list")
	
	if join_res != OK || join_req_res != OK || lbby_crt_res != OK || p2p_req_res != OK || chat_upt_res != OK || p2p_fail_res != OK || get_lobbies_res != OK:
		printerr("Error occured in one of gd's signals")


func get_must_wait_to_join() -> bool:
	return SceneLoader.get_is_loading() == true || Util.get_current_game_state() == GamemodeValues.GameStates.ROUND_OVER


func get_all_lobby_player_info(exclude_temp_bots: bool = false) -> Array:
	var all_players = client_members + _bot_members + _temp_bot_members if exclude_temp_bots == false else client_members + _bot_members 
	return all_players


func get_host_id() -> int:
	if host_id != 0:
		return host_id
	else:
		var id: int = set_host_values(lobby_id)
		return id


func generate_bot_members(bot_amount: int, element_amount: int, bot_type: int) -> void:
	var amount_red: int = 0
	var amount_blue: int = 0
	for lobby_member in Lobby.client_members:
		if lobby_member["team"] == "Blue Team":
			amount_blue += 1
		else:
			amount_red += 1
	
	_bot_members.clear()
	for i in range(0, bot_amount):
		var id: int = Util.generate_id(Globals.EntityTypes.PLAYER, bot_type)
		var preferred_team = "Blue Team" if i % 2 == 1 else "Red Team"
		
		if bot_type == -1:
			var chance = Util.rand.randf()
			if chance < 0.5:
				bot_type =  Globals.PlayerTypes.EASY_BOT
			elif chance < 0.85:
				bot_type = Globals.PlayerTypes.MEDIUM_BOT
			elif chance <= 1:
				bot_type = Globals.PlayerTypes.HARD_BOT
		
		var name: String = Util.generate_bot_name(bot_type)
		
		if amount_red > amount_blue:
			preferred_team = "Blue Team"
			amount_blue += 1
		else:
			preferred_team = "Red Team"
			amount_red += 1
		
		var bot_info = Globals.PlayerInfo(id, name, Vector3.ZERO, bot_type, CustomizePlayer.generate_skin(), preferred_team, Util.generate_available_elements(element_amount), -1, -1)
		host_add_player_and_broadcast(bot_info, true, false)


func player_is_in_temp_bot(id: int) -> bool:
	for player_info in _temp_bot_members:
		if id == player_info["id"]:
			return true
	
	return false


func remove_player_from_lobby(player_info: Dictionary) -> void:
	if client_members.find(player_info) != -1:
		client_members.remove(client_members.find(player_info))
		var close_p2p_res: bool = Steam.closeP2PSessionWithUser(player_info["id"])
		if close_p2p_res == false:
			Util.log_print("Lobby", "[Host]: Failed to close p2p session with " + player_info["name"])
		else:
			Util.log_print("Lobby", "[Host]: Closed p2p with " + player_info["name"])
	elif _bot_members.find(player_info) != -1:
		_bot_members.remove(_bot_members.find(player_info))
	elif _temp_bot_members.find(player_info) != -1:
		_temp_bot_members.remove(_temp_bot_members.find(player_info))
	
	Util.log_print("Lobby", "[Host]: Removed " + player_info["name"] + " from lobby")
	SceneLoader.remove_loaded_player(player_info["id"])
	PacketSender.host_update_lobby_players(client_members, _bot_members, _temp_bot_members)
	emit_signal("lobby_members_updated")


func set_client_member_status(id: int, status: int, player_info: Dictionary) -> void:
	client_members_status[id] = {"status": status, "player_info": player_info}


func get_players_waiting_to_join() -> Array:
	var waiting_to_join = []
	for id in client_members_status:
		if client_members_status[id].status == ClientStatus.WAITING_TO_JOIN:
			waiting_to_join.append(client_members_status[id].player_info)
	
	return waiting_to_join


func load_waiting_players() -> void:
	var waiting_players = get_players_waiting_to_join()
	for waiting_player_info in waiting_players:
		set_client_member_status(waiting_player_info["id"], ClientStatus.JOINED_GAME, waiting_player_info)
		try_successful_join_lobby_res(waiting_player_info)


func set_lobby_state(state: int) -> void:
	lobby_state = state


func clear_temp_bot_members() -> void:
	_temp_bot_members.clear()


func _on_get_lobby_match_list(lobbies):
	if _searching_for_quickplay == true:
		_searching_for_quickplay = false
		
		var fishards_lobbies: Array = []
		for lobby_id in lobbies:
			var password_required: bool = Steam.getLobbyData(lobby_id, "password_required") == "true"
			var is_fishards: bool = Steam.getLobbyData(lobby_id, "fishards") == "true"
			if password_required == false && is_fishards == true:
				fishards_lobbies.append(lobby_id)
		
		if fishards_lobbies.size() == 0:
			var max_players = 2 if Globals.get_app_mode() == Globals.AppModes.DEMO else 10
			var gamemode = GamemodeValues.Gamemodes.FreeForAll 
			var quickplay_room_settings = RoomSettings.create_settings_dict("", max_players, GamemodeValues.Maps.Island, GamemodeValues.MapSizes.Small, max_players/2, gamemode)
			create_lobby(SteamValues.LobbyType.PUBLIC, quickplay_room_settings.max_players, SteamValues.STEAM_USERNAME + "'s lobby", quickplay_room_settings, true)
		else:
			var best_lobby: Dictionary = {"score": 0, "id": 0}
			for fishard_lobby_id in fishards_lobbies:
				var iterated_lobby: Dictionary = {"score": 0, "id": fishard_lobby_id}
				if Steam.getLobbyData(fishard_lobby_id, "started") == "true":
					iterated_lobby.score += 100
				iterated_lobby.score += Steam.getNumLobbyMembers(fishard_lobby_id)
				if iterated_lobby.score > best_lobby.score:
					best_lobby = iterated_lobby
			
			initial_steam_join_lobby(best_lobby.id, -1)


func _input(event):
	is_not_afk()


func _process(delta):
	handle_afk(delta)
	check_lobby_ping(delta)


func _physics_process(delta):
	Steam.run_callbacks()


func lobby_pong_response(owner_id: int) -> void:
	amount_of_measurements += 1
	measuring_ping = false
	total_ping_time += ping
	var average = total_ping_time / amount_of_measurements
	#print("ping average: ", average)
	#print("ping is ", ping)
	emit_signal("ping_updated", ping, average)


func check_lobby_ping(delta: float) -> void:
	time_since_last_ping += delta
	if time_since_last_ping > 2 && lobby_id != 0:
		time_since_last_ping = 0
		ping = 0
		measuring_ping = true
		PacketSender.ping_request(host_id)
	
	if measuring_ping == true:
		ping += delta


func is_not_afk() -> void:
	afk_time = 0


func handle_afk(delta: float) -> void:
	if lobby_id != 0 && Globals.in_single_player == false:
		afk_time += delta
		if afk_time > 5 * 60:
			leave_lobby("afk")
			Globals.create_info_popup("You were AFK.", "To avoid inactive lobbies and players we kick players that are away from their keyboards for more than 5 minutes.")


func set_host_values(lobbies_id: int) -> int:
	var owner_id: int
	
	if Globals.in_single_player == true:
		owner_id = SteamValues.STEAM_ID
		host_id = owner_id
		is_host = true
	else:
		owner_id = Steam.getLobbyOwner(lobbies_id)
		host_id = owner_id
		is_host = owner_id == SteamValues.STEAM_ID
	
	return owner_id


func quickplay() -> void:
	Steam.addRequestLobbyListDistanceFilter(SteamValues.SearchDistance.WORLDWIDE)
	Steam.requestLobbyList()
	# in _on_get_lobby_match_list we handle the rooms and auto-join
	_searching_for_quickplay = true
	open_loading_lobby_scene()


#####################
# JOIN LOBBY PIPELINE
# CLIENT STEP 1 - Done through steam button or function call inside game (ex room list)
func initial_steam_join_lobby(lobby_id: int, friend_id: int) -> void:
	Util.log_print("Lobby", "Step 1: Client making steam request to join lobby, lobby id is " + str(lobby_id) + " and friend id is " + str(friend_id))
	Steam.joinLobby(lobby_id) 
	open_loading_lobby_scene()


# HOST STEP 1 
func create_lobby(type, max_players, name: String, room_settings: Dictionary, start_round_on_loaded: bool = false, single_player: bool = false) -> void:
	# Check no other lobby is running
	if lobby_id == 0:
		Util.log_print("Lobby", "Step 1: Host creating lobby")
		lobby_name = ProfanityFilter.filter(name)
		_start_round_on_loaded = start_round_on_loaded
		Globals.in_single_player = single_player
		
		handle_update_room_settings(host_id, room_settings)
		open_loading_lobby_scene()
		
		is_host = true
		host_id = SteamValues.STEAM_ID
		
		if single_player == true:
			_on_lobby_created(1, 100)
			_on_lobby_joined(100, 1, 1, 1)
		else:
			Steam.createLobby(type, max_players)
		
		emit_signal("update_loading_status", "Creating lobby")
	else:
		printerr("Other lobby is running, can't create another one.")


# STEP 2 - Open the loading screen
func open_loading_lobby_scene() -> void:
	set_lobby_state(LobbyStates.LOADING_LOBBY)
	Util.log_print("Lobby", "Step 2: Client or Host opening loading screen")
	
	var scene_tree = get_tree()
	var current_scene = get_tree().get_current_scene()
	if current_scene != null:
		# Main menu scene needed to show loading lobby scene
		if current_scene.name != "MainMenuScene":
			Util.log_print("Lobby", "Not main menu, switching to main menu scene?")
			scene_tree.change_scene(Globals.MAIN_MENU_SCENE)
			yield(get_tree(), "idle_frame")
			
			var main_menu_scene = get_tree().get_current_scene()
			if main_menu_scene.change_to_UI_on_ready != "LoadingLobbyUI": 
				main_menu_scene.change_to_UI_on_ready = "LoadingLobbyUI"
				Util.log_print("Lobby", "change_to_UI_on_ready set to " + "LoadingLobbyUI")
		
		var ui_node = get_node("/root/MainMenuScene/UI")
		if ui_node != null:
			ui_node.change_UI("LoadingLobbyUI")
		else:
			Util.log_print("Lobby", "/root/MainMenuScene/UI was null!!!")
	else: 
		Util.log_print("Lobby", "Couldn't get current Main menu scene")


# STEP 3
func _on_lobby_created(connect_response, lobbyID):
	if connect_response == 1:
		
		lobby_id = lobbyID
		password_required = RoomSettings.settings["password"] != ""
		generate_bot_members(RoomSettings.settings["bot_amount"], RoomSettings.settings["elmts"], RoomSettings.settings["bot_difficulty"])
		
		Steam.setLobbyData(lobbyID, "name", lobby_name)
		Steam.setLobbyData(lobbyID, "started", "false")
		Steam.setLobbyData(lobbyID, "fishards", "true")
		Steam.setLobbyData(lobbyID, "owner", str(SteamValues.STEAM_ID))
		Steam.setLobbyData(lobbyID, "password_required", str(password_required).to_lower())
		Steam.setLobbyJoinable(lobbyID, true)
		
		var relay_res: bool = Steam.allowP2PPacketRelay(true)
		Util.log_print("Lobby", "Step 3: Lobby created. Allowing Steam to be relay backup: " + str(relay_res))


# STEP 3 HOST AND CLIENT - Both host and client get this steam callback
func _on_lobby_joined(lobbyID, _permissions, _locked, response):
	if Lobby.is_host == false:
		Util.log_print("Lobby", "Step 3: Client _on_lobby_joined. Response: " + str(response)) 
	else:
		Util.log_print("Lobby", "Step 4: Host _on_lobby_joined. Response: " + str(response))
	
	# If joining was successful
	if response == Steam.CHAT_ROOM_ENTER_RESPONSE_SUCCESS:
		lobby_id = lobbyID
		var lobbies_host_id = set_host_values(lobbyID)
		
		_searching_for_quickplay = false
		password_required = Steam.getLobbyData(lobbyID, "password_required") == "true"
		
		# Get the lobby name
		lobby_name = Steam.getLobbyData(lobbyID, "name")
		
		var step = "Step 4.5" if Lobby.is_host else "Step 3.5"
		Util.log_print("Lobby", step + ": Broadcasting handshake.")
		PacketSender.handshake(lobbyID)
		
		if (Lobby.is_host || password_required == false):
			Util.log_print("Lobby", "Step 5: No password or is host. Sending join request.")
			# Automatically join the lobby since we are the host
			PacketSender.request_join_lobby(lobbies_host_id)
		else:
			Util.log_print("Lobby", "Step 5: Password required. Opening password screen.")
			emit_signal("update_loading_status", "enter password")
	else:
		Util.log_print("Lobby", "An error occured in _on_lobby_joined: " + str(response))
		emit_signal("was_not_accepted_into_lobby", response)


# STEP 4.5 || HANDLE CLIENT JOIN STEP 1 - if we are the host or a client joining the logic is different
func p2p_host_handle_join_lobby_request(id: int, name: String, skin: Dictionary, elements: Array, rank: int, password: String) -> void:
	var new_player_info = Globals.PlayerInfo(id, name, Vector3.ZERO, Globals.PlayerTypes.CLIENT, skin, get_available_team(), elements, -1, rank)
	var validated_elements = validate_elements(elements, new_player_info)
	new_player_info["elmts"] = validated_elements
	
	if client_members.has(id):
		Util.log_print("Lobby", "Handle Client Join Step 1: ERROR: " + name + " is already in the lobby?.")
	
	# If the host is requesting to join their own room
	if id == SteamValues.STEAM_ID:
		try_successful_join_lobby_res(new_player_info)
	else:
		
		if new_player_info["id"] != SteamValues.STEAM_ID:
			Util.log_print("Lobby", "Handle Client Join Step 1: " + name + " has requested to join the lobby, the host is handling it now.")
		
		if RoomSettings.settings.has("password"):
			if password == RoomSettings.settings["password"]:
				var must_wait_to_join: bool = get_must_wait_to_join()
				# Players cannot join whilst the game is loading, that would mess stuff up probably
				if must_wait_to_join == true:
					if new_player_info["id"] != SteamValues.STEAM_ID:
						Util.log_print("Lobby", "Handle Client Join Step 1: WARNING: Player tried to join whilst the game was loading.")
					set_client_member_status(id, ClientStatus.WAITING_TO_JOIN, new_player_info)
				else:
					try_successful_join_lobby_res(new_player_info)
			else:
				PacketSender.join_lobby_fail_response(id)
				if new_player_info["id"] != SteamValues.STEAM_ID:
					Util.log_print("Lobby", "Handle Client Join Step 1: ...they gave the incorrect password")
		elif new_player_info["id"] != SteamValues.STEAM_ID:
			Util.log_print("Lobby", "Handle Client Join Step 1: Host's room settings did not have password?")


func host_add_player_and_broadcast(player_info: Dictionary, is_bot: bool, is_temp_bot: bool) -> bool:
	# Only the host actually modifies the lobby members, then the host send them all to the other clients
	if player_info["id"] != SteamValues.STEAM_ID:
		if is_bot == false:
			Util.log_print("Lobby", "Handle Client Join Step 2: Adding " + player_info.name + " to lobby members and broadcasting new player info arrays")
	
	for other_player_info in client_members + _bot_members + _temp_bot_members:
		if other_player_info["id"] == player_info["id"]:
			Util.log_print("Lobby", "Handle Client Join Step 2: ERROR: This player is already in the lobby: " + str(player_info.name))
			return false
	
	if is_bot == false && is_temp_bot == false:
		client_members.append(player_info)
	elif is_bot == true && is_temp_bot == false:
		_bot_members.append(player_info)
	else:
		_temp_bot_members.append(player_info)
	
	PacketSender.host_update_lobby_players(client_members, _bot_members, _temp_bot_members)
	emit_signal("lobby_members_updated")
	return true


func try_successful_join_lobby_res(new_player_info: Dictionary) -> void:
	var added_successfully = host_add_player_and_broadcast(new_player_info, false, false)
	if added_successfully == true:
		if new_player_info["id"] != SteamValues.STEAM_ID:
			Util.log_print("Lobby", "Handle Client Join Step 3: ...they gave the correct password, adding them, sending settings and returning success packet!")
		PacketSender.join_lobby_success_response(new_player_info["id"])
		set_client_member_status(new_player_info["id"], ClientStatus.JOINED_GAME, new_player_info)
	elif new_player_info["id"] != SteamValues.STEAM_ID:
		Util.log_print("Lobby", "Handle Client Join Step 3: ERROR! Something went wrong whilst adding a player")


# STEP 5 - if a client or host is successful in joining their room
func p2p_handle_join_lobby_successfully(sender_id: int, settings: Dictionary) -> void:
	if sender_id == host_id:
		if is_host == true:
			Util.log_print("Lobby", "Step 6: (Host) Successfully joined own lobby. Setting new room settings." )
		else:
			Util.log_print("Lobby", "Step 5: (Client) Successfully joined the lobby. Setting new room settings." )
		
		accepted_into_lobby = true
		
		if _start_round_on_loaded == true:
			host_start_game()
		
		# Join a game that has started straight away
		RoomSettings.p2p_set_values(settings, false)
		
		if RoomSettings.get_game_started() == true:
			if is_host == false:
				Util.log_print("Lobby", "Step 6: (Client) Since the game has started request joining it in game.")
				PacketSender.request_join_game()
		else:
			if is_host == true:
				Util.log_print("Lobby", "Step 7: Open the lobby scene")
			else:
				Util.log_print("Lobby", "Step 6: Since the game hasn't started open the lobby")
			_open_lobby_scene(0)
	else:
		Util.log_print("Lobby", "ERROR: p2p_handle_join_lobby_response was sent from someone who wasn't a host")


# STEP 5 - if a client fails to join  
func p2p_handle_join_lobby_fail(sender_id: int) -> void:
	if sender_id == host_id:
		accepted_into_lobby = false
		Util.log_print("Lobby", "Step 5: Not accepted into lobby!")
		emit_signal("was_not_accepted_into_lobby", SteamValues.RoomEnterResponse.INCORRECT_PASSWORD)
	else:
		Util.log_print("Lobby", "Step 5: p2p_handle_join_lobby_response was sent from someone who wasn't a host")


func _open_lobby_scene(wait_time: float) -> void:
	# Go back to the main menu with wait_time period without messages
	Globals.in_game = false
	yield(get_tree().create_timer(wait_time), "timeout")
	
	if get_tree().get_root().has_node("MainMenuScene") == false:
		var scene_response = get_tree().change_scene(Globals.MAIN_MENU_SCENE)
		if scene_response != OK: printerr("Error changing scene to main menu: " + str(scene_response))
		yield(Globals, "main_menu_ready")
	
	var UI_node: Control = get_tree().get_root().get_node("MainMenuScene/UI")
	if UI_node != null:
		UI_node.change_UI("LobbyUI")


func host_start_game() -> void:
	if client_members.size() > 0 && is_host:
		# Don't broadcast since we will send the room setting directly after this line anyways
		RoomSettings.edit_settings({"game_started": true}, false)
		RoomSettings.host_start_next_round(true)
		var start_res: bool = Steam.setLobbyData(lobby_id, "started", "true")
		if start_res == false:
			Util.log_print("Lobby", "ERROR: Couldn't add started flag to lobby data")


func refresh_lobby_members() -> void:
	emit_signal("lobby_members_updated")


func handle_update_room_settings(updater_id: int, settings: Dictionary) -> void:
	if updater_id == host_id:
		RoomSettings.p2p_set_values(settings)


func handle_player_left(leaving_player_id: int, name: String = "") -> void:
	Util.log_print("Lobby", "Player left, " + name)
	
	if leaving_player_id == SteamValues.STEAM_ID:
		Util.log_print("Lobby", "I left! ")
	
	if name != "":
		emit_signal("lobby_message", (str(name) + " left the lobby"))
	
	if is_host:
		for player_info in client_members:
			if player_info["id"] == leaving_player_id:
				PacketSender.host_broadcast_destroy_entity(leaving_player_id)
				if leaving_player_id == SteamValues.STEAM_ID:
					Util.log_print("Lobby", "Removing player anyways?")
				remove_player_from_lobby(player_info)
				return
				
		Util.log_print("Lobby", "ERROR: Couldn't find the player to remove???")
	
	# If the host left, force all players to leave for now
	if leaving_player_id == host_id:
		leave_lobby("host left")
		if SceneLoader.get_is_loading() == true:
			Globals.create_info_popup("The host left the game", "Whilst the game was loading the host disconnected. You cannot play without the host, so you were kicked out.")
		else:
			Globals.create_info_popup("The host left the game", "The host disconnected. You cannot play without the host, so you were kicked out.")
	else:
		RoomSettings.remove_player_from_leaderboard(leaving_player_id)


func p2p_validate_update_player_info(sender_id: int, name: String, skin: Dictionary, elements: Array, kill_on_update: bool) -> void:
	# TODO: Validate
	var updated_player: bool
	for i in client_members.size():
		if client_members[i].id == sender_id:
			var new_elements: Array = validate_elements(elements, client_members[i])
			#print("HOST: changed elements are ", elements, " el amount is ", element_amount)
			#print(name, ":", str(client_members[i]["rank"]))
			
			var new_player_info = Globals.PlayerInfo(sender_id, name, client_members[i]["spwnpnt"], client_members[i]["plyr_type"], skin, client_members[i]["team"], elements, -1, client_members[i]["rank"])
			client_members[i] = new_player_info
			
			#print("kill_on_update: ", kill_on_update)
			if kill_on_update == true:
				Util.log_print("Lobby", "Trying to kill player if room exists.")
				Util.log_print("Lobby", "Has player loaded? " + str(SceneLoader.player_has_loaded(sender_id)))
				var room_node = Util.get_room_node()
				if SceneLoader.player_has_loaded(sender_id) && room_node != null && Util.get_current_game_state() == GamemodeValues.GameStates.GAME:
					var updater_entity = room_node.get_entity(sender_id, "update player info")
					if updater_entity != null:
						var health_component: Health = updater_entity.get_component_of_type(Globals.ComponentTypes.Health)
						var player_component: Player = updater_entity.get_component_of_type(Globals.ComponentTypes.Player)
						if health_component != null && player_component != null:
							var recent_damager_id = health_component.get_recent_damager_id()
							var recent_spell_type = health_component.get_recent_damager_spell()
							var death_type = player_component.get_death_type()
							PacketSender.broadcast_player_death(sender_id, recent_damager_id, recent_spell_type, death_type)
			
			updated_player = true
			break
	
	if updated_player == true:
		emit_signal("lobby_members_updated")
		PacketSender.host_update_lobby_players(client_members, _bot_members, _temp_bot_members)


func validate_elements(elements: Array, player_info: Dictionary) -> Array:
	var new_elements: Array = []
	var element_amount = RoomSettings.get_element_amount()
	
	if RoomSettings.get_element_mode() == Globals.ElementModes.RANDOM:
		# In random same the joining player gets the same as the host
		var host_elements: Array = player_info["elmts"]
		for other_player_info in Lobby.get_all_lobby_player_info():
			if other_player_info["id"] == Lobby.host_id:
				host_elements = other_player_info["elmts"]
				break
		new_elements = host_elements
	elif RoomSettings.get_element_mode() != Globals.ElementModes.DEFAULT:
		new_elements = player_info["elmts"]
	elif elements.size() != element_amount:
		var i = 0
		for element_id in element_amount:
			i += 1
			new_elements.append(i)
	else:
		new_elements = elements
	
	return new_elements


func p2p_handle_lobby_members_updated(sender_id: int, packet: Dictionary) -> void:
	if sender_id == host_id:
		client_members = packet["clients"]
		_bot_members = packet["bots"]
		_temp_bot_members = packet["temp_bots"]
		divide_players_into_teams(GamemodeValues.get_current_rounds_teammode())
		Lobby.emit_signal("lobby_members_updated")


func all_rounds_over() -> void:
	RoomSettings.reset_gamemode_data()
	
	var start_res: bool = Steam.setLobbyData(lobby_id, "started", "false")
	if start_res == false:
		printerr("Couldn't add started flag to lobby data")
	
	_open_lobby_scene(0)
	
	if Lobby.is_host:
		Lobby.load_waiting_players()


func handle_chat_message(id: int, message: String) ->void:
	if Lobby.lobby_state != Lobby.LobbyStates.NO_LOBBY:
		var sender = Steam.getFriendPersonaName(id)
		emit_signal("lobby_chat", str(sender), str(message))


func _on_lobby_chat_update(chat_lobby_id, _changed_id, updater_id, chat_state):
	if Lobby.lobby_state != Lobby.LobbyStates.NO_LOBBY:
		if chat_lobby_id == lobby_id:
			var updater_name: String = Steam.getFriendPersonaName(updater_id)
			if updater_name == "":
				updater_name = "Someone"
			
			match chat_state:
				1: 
					Util.log_print("Lobby", "Handle Client Join Step 0: " + updater_name + "(" + str(updater_id) + ") wants to join!")
					emit_signal("lobby_message", updater_name + " is connecting to the lobby...")
				2: 
					handle_player_left(updater_id, updater_name)
				8: 
					emit_signal("lobby_message", (str(updater_name) + " has been kicked from the lobby"))
					PacketSender.host_broadcast_destroy_entity(updater_id)
					handle_player_left(updater_id)
				16:
					emit_signal("lobby_message", (str(updater_name) + " has been banned"))
					PacketSender.host_broadcast_destroy_entity(updater_id)
					handle_player_left(updater_id)
				_: 
					emit_signal("lobby_message", (str(updater_name) + " did... something...?"))


func kick_player(id: int) -> void:
	for player_info in client_members:
		if player_info["id"] == id:
			MusicAndSfxHandler.play_sound(MusicAndSfxHandler.sounds.KICKED)
			PacketSender.kick_player(id, "The host kicked you.")
	
	# If player still hasn't left, remove them manually
	yield(get_tree().create_timer(1), "timeout")
	for player_info in client_members:
		if player_info["id"] == id:
			remove_player_from_lobby(player_info)


# When the player leaves a lobby for whatever reason
func leave_lobby(from: String = "") -> void:
	Util.log_print("Lobby", "Leave lobby called from " + from)
	
	if lobby_id != 0 && Globals.in_single_player == false:
		Steam.leaveLobby(lobby_id)
	else:
		Util.log_print("Lobby", "Wasn't in a lobby, cannot leave one?")
	
	lobby_id = 0
	is_host = false
	host_id = 0
	client_members.clear()
	_bot_members.clear()
	_temp_bot_members.clear()
	accepted_into_lobby = false
	password_required = false
	_start_round_on_loaded = false
	_searching_for_quickplay = false
	afk_time = 0
	
	RoomSettings.reset_gamemode_data()
	
	set_lobby_state(LobbyStates.NO_LOBBY)
	Globals.in_game = false
	Globals.in_single_player = false
	
	# Go back to the main menu
	Util.log_print("Lobby", "Switching to main menu from leave_lobby().")
	
	SceneLoader.show_loading_screen(false)
	yield(get_tree().create_timer(SceneLoader._fade_animation.get_current_animation_length() + 0.2), "timeout")
	SceneLoader.set_done_loading()
	
	get_tree().change_scene(Globals.MAIN_MENU_SCENE)
	emit_signal("main_menu_loaded")


func _on_P2P_session_request(remoteID: int) -> void:
	# Get the requester's name
	var yourself = " (yourself)" if remoteID == SteamValues.STEAM_ID else ""
	Util.log_print("Lobby", "Handle Client Join Step 0.5: Accepting P2P session with " + str(remoteID) + yourself)
	
	# Accept the P2P session; can apply logic to deny this request if needed
	var accpt_res: bool = Steam.acceptP2PSessionWithUser(remoteID)
	if accpt_res == false:
		Util.log_print("Lobby", "Error accepting p2p request with " + str(remoteID))


func _on_P2P_session_connect_fail(lobbyID: int, session_error: int) -> void:
	# If no error was given
	if session_error == 0:
		Util.log_print("Lobby", "WARNING: Session failure with "+str(lobbyID)+" [no error given].")

	# Else if target user was not running the same game
	elif session_error == 1:
		Util.log_print("Lobby", "WARNING: Session failure with "+str(lobbyID)+" [target user not running the same game].")

	# Else if local user doesn't own app / game
	elif session_error == 2:
		Util.log_print("Lobby", "WARNING: Session failure with "+str(lobbyID)+" [local user doesn't own app / game].")

	# Else if target user isn't connected to Steam
	elif session_error == 3:
		Util.log_print("Lobby", "WARNING: Session failure with "+str(lobbyID)+" [target user isn't connected to Steam].")

	# Else if connection timed out
	elif session_error == 4:
		Util.log_print("Lobby", "WARNING: Session failure with "+str(lobbyID)+" [connection timed out].")
		if lobby_id != 0 && is_host == false && lobbyID == host_id:
			Globals.create_info_popup("An error occured whilst connecting", "Your connection with the host failed. Try again later or join a different room.")
			leave_lobby("connection timed out")

	# Else if unused
	elif session_error == 5:
		Util.log_print("Lobby", "WARNING: Session failure with "+str(lobbyID)+" [unused].")

	# Else no known error
	else:
		Util.log_print("Lobby", "WARNING: Session failure with "+str(lobbyID)+" [unknown error "+str(session_error)+"].")

"""
TEAMS CODE
"""
func is_on_my_team(my_id: int, their_id: int) -> bool:
	for team_info in teams:
		if team_info["member_scores"].has(my_id) && team_info["member_scores"].has(their_id):
			return true
	
	return false


func is_on_same_team_as(their_id: int, my_teams_name: String) -> bool:
	for team_info in teams:
		if team_info["member_scores"].has(their_id) && team_info.name == my_teams_name:
			return true
	
	return false


func get_team_info_from_player_id(id: int) -> Dictionary:
	for team_info in teams:
		if team_info["member_scores"].has(id):
			return team_info
	
	return {}


func get_teams() -> Array:
	return teams


func get_team_w_name(name: String) -> Dictionary:
	for team_info in teams:
		if team_info["name"] == name:
			return team_info
	
	return {}


func get_team_total_score(team_info: Dictionary) -> int:
	var teams_score: int
	for player_id in team_info["member_scores"]:
		teams_score += team_info["member_scores"][player_id] 
	return teams_score


class team_sorter:
	static func sort(a, b) -> bool:
		if Lobby.get_team_total_score(a) < Lobby.get_team_total_score(b):
			return true
		return false


func set_team_member_score(player_id: int, score: int) -> void:
	for i in teams.size():
		if teams[i]["member_scores"].has(player_id):
			teams[i]["member_scores"][player_id] = score
			return


func reset_team_scores() -> void:
	var added_to_team: bool
	for i in teams.size():
		for member_id in teams[i]["member_scores"]:
			teams[i]["member_scores"][member_id] = 0


func divide_players_into_teams(current_round_team_mode: int) -> void:
	teams.clear()
	for player_info in get_all_lobby_player_info():
		add_player_to_team(current_round_team_mode, player_info)
	emit_signal("teams_set")


func add_player_to_team(current_round_team_mode: int, player_info: Dictionary) -> void:
	var to_team_w_name: String = "" 
	var solo_team: bool
	
	if player_info["clone"] != -1:
		var room = Util.get_room_node()
		if room != null:
			var cloned_from = room.get_entity(player_info["clone"])
			if cloned_from != null:
				to_team_w_name = cloned_from.get_component_of_type(Globals.ComponentTypes.Player).get_team()
	else:
		if current_round_team_mode == GamemodeValues.TeamModes.NO_TEAMS:
			to_team_w_name = player_info["name"] 
			solo_team = true
		elif current_round_team_mode == GamemodeValues.TeamModes.RED_BLUE_TEAMS:
			to_team_w_name = player_info["team"] 
			solo_team = false
		elif current_round_team_mode == GamemodeValues.TeamModes.COOP:
			solo_team = false
			if _temp_bot_members.find(player_info) == -1: # If it is a temp bot in coop make red
				to_team_w_name = "Blue Team"
			else:
				to_team_w_name = "Red Team"
	
	# Try to find the team, if we can't find it create a new teamInfo and append that
	var added_to_team: bool
	for i in teams.size():
		if teams[i]["name"] == to_team_w_name && teams[i]["member_scores"].has(player_info["id"]) == false:
			teams[i]["member_scores"][player_info["id"]] = 0
			added_to_team = true
			break
		elif teams[i]["member_scores"].has(player_info["id"]) == true:
			added_to_team = true
	
	if added_to_team == false:
		var new_team_info = TeamInfo(to_team_w_name, solo_team, player_info["id"])
		teams.append(new_team_info)


func get_players_with_preferred_team(team_name: String) -> Array:
	var player_info_with_team: Array = []
	for player_info in get_all_lobby_player_info():
		if player_info["team"] == team_name:
			player_info_with_team.append(player_info)
	return player_info_with_team


func can_join_team(prev_team: String, new_team: String) -> bool:
	return  get_players_with_preferred_team(prev_team).size() >= get_players_with_preferred_team(new_team).size()


func get_available_team() -> String:
	if get_players_with_preferred_team("Blue Team").size() < get_players_with_preferred_team("Red Team").size():
		return "Blue Team"
	else:
		return "Red Team"


func p2p_handle_join_team(sender_id: int, team: String) -> void:
	for player_info in get_all_lobby_player_info():
		if player_info["id"] == sender_id:
			if can_join_team(player_info["team"], team):
				PacketSender.change_team(sender_id, team)
				break


func p2p_handle_change_team(sender_id: int, id: int, team: String) -> void:
	if sender_id == host_id:
		for player_info in get_all_lobby_player_info():
			if player_info["id"] == id:
				player_info["team"] = team
				refresh_lobby_members()
				break


func TeamInfo(name: String, solo: bool, first_member_id: int) -> Dictionary:
	return {
		"name": name,
		"solo": solo, # If there is only one person in the team, ex FFA
		"member_scores": {first_member_id: 0},
		"score": 0,
		"place": 0,
	}

