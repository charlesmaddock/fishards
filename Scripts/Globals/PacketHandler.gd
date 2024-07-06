extends Node


var MAX_BYTE_READ_COUNT_PER_TICK: int = 1500

# Vars for testing
var process_iteration: int
var amount_of_packets: int
var packet_types: Dictionary
var time: float
var print_packet_info: bool = false

signal handle_room_packet(sender_id, data)
signal chat_message(data)

func _process(delta: float) -> void:
	process_iteration += 1
	if Lobby.lobby_state != Lobby.LobbyStates.NO_LOBBY:
		_read_packets(Globals.Channels.LOBBY)
	
	if Globals.in_game == true:
		_read_packets(Globals.Channels.IN_GAME)
	
	if print_packet_info == true:
		time += delta
		if time >= 5:
			print("====================")
			print("Packets per second: ", amount_of_packets / 5)
			for type in packet_types:
				print(packet_types[type], " packets which is ", (stepify((packet_types[type] / amount_of_packets), 0.001) * 100), "% are ", Globals.PacketTypes.keys()[type])
			print("====================")
			
			amount_of_packets = 0
			time = 0
			packet_types.clear()


func _read_packets(channel: int) -> void:
	var packet_size: int = Steam.getAvailableP2PPacketSize(channel)
	while packet_size > 0:
		var packet: Dictionary = Steam.readP2PPacket(packet_size, channel)
		open_packet(packet["steamIDRemote"], bytes2var(packet["data"]))
		packet_size = Steam.getAvailableP2PPacketSize(channel)


func host_read_packet_directly(sender_id: int, data: Dictionary, channel: int) -> void:
	if Globals.in_game == false && channel == Globals.Channels.IN_GAME:
		return
	
	open_packet(sender_id, data)


# Handle incoming packets
func open_packet(sender_id: int, data: Dictionary):
	if data["type"] == null:
		print('ERROR: data received without a "type"')
		return
	
	amount_of_packets += 1
	if packet_types.has(data["type"]):
		var amount = float(packet_types[data["type"]]) + 1.0
		packet_types[data["type"]] = amount
	else:
		packet_types[data["type"]] = 1.0
	
	match data["type"]:
		Globals.PacketTypes.HANDSHAKE:
			pass
		Globals.PacketTypes.PING:
			handle_ping(sender_id)
		Globals.PacketTypes.PING_RES:
			handle_pong(sender_id)
		Globals.PacketTypes.KICK_PLAYER:
			handle_kick(sender_id, data["message"])
		Globals.PacketTypes.REQUEST_JOIN_LOBBY:
			Lobby.p2p_host_handle_join_lobby_request(sender_id, data["name"], data["skin"], data["elmts"], data["rank"], data["password"])
		Globals.PacketTypes.JOIN_LOBBY_SUCCESS_RESPONSE:
			Lobby.p2p_handle_join_lobby_successfully(sender_id, data["settings"])
		Globals.PacketTypes.JOIN_LOBBY_FAIL_RESPONSE:
			Lobby.p2p_handle_join_lobby_fail(sender_id)
		Globals.PacketTypes.REQUEST_UPDATE_PLAYER_INFO:
			Lobby.p2p_validate_update_player_info(sender_id, data["name"], data["skin"], data["elmts"], data["kill"])
		Globals.PacketTypes.UPDATE_LOBBY_PLAYERS:
			Lobby.p2p_handle_lobby_members_updated(sender_id, data)
		Globals.PacketTypes.REQUEST_JOIN_TEAM:
			Lobby.p2p_handle_join_team(sender_id, data["team"])
		Globals.PacketTypes.CHANGE_TEAM:
			Lobby.p2p_handle_change_team(sender_id, data["id"], data["team"])
		Globals.PacketTypes.ROOM_SETTINGS:
			Lobby.handle_update_room_settings(sender_id, data["settings"])
		Globals.PacketTypes.SHOW_LOADING_SCREEN:
			SceneLoader.show_loading_screen(true)
		Globals.PacketTypes.START_LOADING_GAME:
			p2p_handle_start_loading_game(sender_id, data["gamemode"], data["settings"], data["env"], data["players"])
		Globals.PacketTypes.REQUEST_JOIN_MID_GAME:
			p2p_handle_join_mid_game_request(sender_id)
		Globals.PacketTypes.DONE_LOADING_SCENES:
			SceneLoader.p2p_host_handle_player_has_loaded_scenes(sender_id)
		Globals.PacketTypes.SET_DONE_LOADING:
			SceneLoader.handle_set_done_loading(sender_id)
		Globals.PacketTypes.REQUEST_LEADERBOARD:
			Lobby.emit_signal("broadcast_leaderboard_req")
		Globals.PacketTypes.ALL_ROUNDS_OVER:
			SceneLoader.all_rounds_over(sender_id)
		Globals.PacketTypes.SEND_CHAT_MESSAGE:
			Lobby.handle_chat_message(sender_id, data["message"])
		_:
			emit_signal("handle_room_packet", sender_id, data)


func handle_ping(sender_id: int) -> void:
	PacketSender.pong_response(sender_id)


func handle_pong(sender_id: int) -> void:
	Lobby.lobby_pong_response(sender_id)


func handle_kick(sender_id: int, message: String) -> void:
	if sender_id == Lobby.host_id:
		Lobby.leave_lobby("Kicked")
		MusicAndSfxHandler.play_sound(MusicAndSfxHandler.sounds.KICKED)
		Globals.create_info_popup("You were kicked.", message)


func p2p_handle_start_loading_game(sender_id: int, gamemode_ref: String, settings: Dictionary, all_environment_info: Dictionary,  all_player_info: Dictionary) -> void:
	print("[Client]: p2p_handle_start_loading_game")
	Lobby.handle_update_room_settings(sender_id, settings)
	SceneLoader.p2p_start_loading_game(settings["map"], gamemode_ref, all_environment_info, all_player_info)


func p2p_handle_join_mid_game_request(requester_id: int) -> void:
	var joining_mid_game: bool = SceneLoader.get_is_loading() == false
	if joining_mid_game == false:
		printerr("Handle Client Join Step 3: WARNING: This function is only ment to be called mid-game, but it was called whilst the game was loading.")
	
	var room_node = Util.get_room_node()
	if room_node != null:
		var joining_player_info: Dictionary = {}
		
		if room_node.players.has_player(requester_id) == true:
			printerr("Handle Client Join Step 3: ERROR: Player was already added!? Exiting function.")
			return
		
		# Find the new players id, create their player and spawn it in the host directly
		for player_info in Lobby.client_members:
			if player_info["id"] == requester_id:
				if room_node.environment.map != null:
					joining_player_info = player_info
					joining_player_info["spwnpnt"] = room_node.environment.map.get_player_spawn_point(player_info["team"])
					print("Handle Client Join Step 3: Good, found the joining player. Host setting their spawn point: ", joining_player_info["spwnpnt"])
					break
		
		if joining_player_info.empty() == false:
			# Spawn the new player for everyone except the joining player, who receives themselves in broadcast_or_send_start_loading_game
			print("Handle Client Join Step 3: Sending the new player to everyone except the new player")
			for player_info in Lobby.client_members:
				if player_info["id"] != requester_id:
					PacketSender.spawn_player(requester_id, joining_player_info, player_info["id"])
			
			# Kill the player if we are not allowing respawns
			var gamemode_info = GamemodeValues.get_current_rounds_gamemodeinfo()
			if gamemode_info.empty() == false:
				if gamemode_info["respawn_allowed"] == false:
					PacketSender.broadcast_player_death(requester_id)
			
			# Begin loading for the new player
			# If the player is joining mid game send them all the entities.
			# Players that join the game together from start get their initial entites there
			var initial_players: Dictionary = room_node.players.get_all_player_info()
			var initial_environment: Dictionary = room_node.environment.get_all_environment_info()
			print("Handle Client Join Step 3: Start loading for the new player, initial env:", initial_environment.values().size())
			PacketSender.broadcast_or_send_start_loading_game(RoomSettings.settings, initial_environment, initial_players, requester_id)
		else:
			printerr("Handle Client Join Step 3: ERROR: Couldn't create the joining player for some reason.")
	else:
		printerr("Handle Client Join Step 3: ERROR: Couldn't create the new player since the room node was null")

