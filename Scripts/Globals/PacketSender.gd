extends Node


# Special function that always works, even if client members isn't set
func handshake(lobby_id: int) -> void:
	var byte_data: PoolByteArray = var2bytes({"type": Globals.PacketTypes.HANDSHAKE})
	var client_amount: int = Steam.getNumLobbyMembers(lobby_id)
	for client_index in range(0, client_amount):
		var client_id: int = Steam.getLobbyMemberByIndex(lobby_id, client_index)
		if client_id != SteamValues.STEAM_ID:
			var sent: bool = Steam.sendP2PPacket(client_id, byte_data, SteamValues.SendType.RELIABLE, Globals.Channels.LOBBY)
			if sent == false:
				printerr("Failed to send packet a handshake to ", client_id)


func ping_request(id: int) -> void:
	var packet: Dictionary = {
		"type": Globals.PacketTypes.PING,
	}
	send_to(id, packet, SteamValues.SendType.RELIABLE)


func pong_response(id: int) -> void:
	var packet: Dictionary = {
		"type": Globals.PacketTypes.PING_RES,
	}
	send_to(id, packet, SteamValues.SendType.RELIABLE) 


func kick_player(id: int, message: String) -> void:
	var packet: Dictionary = {
		"type": Globals.PacketTypes.KICK_PLAYER,
		"message": message
	}
	
	send_to(id, packet, SteamValues.SendType.RELIABLE)


func request_join_lobby(host_id: int, password: String = "") -> void:
	var packet: Dictionary = {
		"type": Globals.PacketTypes.REQUEST_JOIN_LOBBY,
		"name": SteamValues.STEAM_USERNAME, 
		"skin": CustomizePlayer.get_my_skin(), 
		"elmts": UserSettings.get_elements(), 
		"password": password,
		"rank": AchievementHandler.get_rank()
	}
	
	send_to(host_id, packet, SteamValues.SendType.RELIABLE)


func join_lobby_success_response(to: int) -> void:
	var packet: Dictionary = {
		"type": Globals.PacketTypes.JOIN_LOBBY_SUCCESS_RESPONSE,
		"settings": RoomSettings.settings
	}
	send_to(to, packet, SteamValues.SendType.RELIABLE)


func join_lobby_fail_response(to: int) -> void:
	var packet: Dictionary = {
		"type": Globals.PacketTypes.JOIN_LOBBY_FAIL_RESPONSE,
	}
	send_to(to, packet, SteamValues.SendType.RELIABLE)


func set_gamemode_data(to: int) -> void:
	var room = Util.get_room_node()
	if room != null:
		if room.gamemode != null:
			var gamemode_data: Dictionary = {
				"time": room.gamemode.get_state_time_left(),
				"wave": room.gamemode.get_wave(),
				"game_state": room.gamemode.current_game_state,
				"shrink_prog": room.gamemode.get_shrink_progress()
			}
			
			var packet: Dictionary = {
				"type": Globals.PacketTypes.SET_GAMEMODE_DATA,
				"data": gamemode_data, 
			}
			
			send_to(to, packet, SteamValues.SendType.RELIABLE)
		else:
			printerr("The Gamemode node is null, cannot get state.")


func request_update_player_info(kill_on_update: bool = true) -> void:
	var packet: Dictionary = {
		"type": Globals.PacketTypes.REQUEST_UPDATE_PLAYER_INFO, 
		"name": SteamValues.STEAM_USERNAME, 
		"skin": CustomizePlayer.get_my_skin(), 
		"elmts": UserSettings.get_elements(),
		"kill": kill_on_update,
	}
	
	send_to(Lobby.host_id, packet, SteamValues.SendType.RELIABLE)


func elements_changed() -> void:
	var packet: Dictionary = {
		"type": Globals.PacketTypes.ELEMENTS_CHANGED, 
	}
	
	broadcast_data(packet, SteamValues.SendType.RELIABLE)


func broadcast_winner_display() -> void:
	var packet: Dictionary = {
		"type": Globals.PacketTypes.WINNER_DISPLAY, 
	}
	
	broadcast_data(packet, SteamValues.SendType.RELIABLE)


func broadcast_new_wave(wave: int) -> void:
	var packet: Dictionary = {
		"type": Globals.PacketTypes.NEW_WAVE, 
		"wave": wave
	}
	
	broadcast_data(packet, SteamValues.SendType.RELIABLE)


func host_update_lobby_players(client_members, bot_members, temp_bot_members) -> void:
	if Lobby.is_host:
		var packet: Dictionary = {
			"type": Globals.PacketTypes.UPDATE_LOBBY_PLAYERS,
			"clients":  client_members,
			"bots": bot_members,
			"temp_bots": temp_bot_members,
		}
		
		broadcast_data_except(Lobby.host_id, packet, SteamValues.SendType.RELIABLE)


func request_join_team(team: String) -> void:
	var packet: Dictionary = {
		"type": Globals.PacketTypes.REQUEST_JOIN_TEAM, 
		"team": team,
	}
	
	send_to(Lobby.host_id, packet, SteamValues.SendType.RELIABLE)


func change_team(id: int, team: String) -> void:
	var packet: Dictionary = {
		"type": Globals.PacketTypes.CHANGE_TEAM, 
		"id": id,
		"team": team,
	}
	
	broadcast_data(packet, SteamValues.SendType.RELIABLE)


func update_player_rotation(sender_id: int, player_id: int, rot: float) -> void:
	var packet: Dictionary = {
		"type": Globals.PacketTypes.UPDATE_PLAYER_ROTATION,
		"id": player_id,
		"rot": rot,
	}
	
	broadcast_data_except(sender_id, packet, SteamValues.SendType.UNRELIABLE, Globals.Channels.IN_GAME)


func update_player_stance(player_id: int, stance: int) -> void:
	var packet: Dictionary = {
		"type": Globals.PacketTypes.UPDATE_PLAYER_STANCE, 
		"id": player_id,
		"stance": stance,
	}
	
	broadcast_data_except(player_id, packet, SteamValues.SendType.RELIABLE, Globals.Channels.IN_GAME)


func broadcast_player_target_pos(id: int, pos: Vector3) -> void:
	var packet: Dictionary = {
		"type": Globals.PacketTypes.UPDATE_PLAYER_TARGET_POS, 
		"id": id, 
		"pos": pos,
	}
	
	broadcast_data_except(Lobby.host_id, packet, SteamValues.SendType.UNRELIABLE, Globals.Channels.IN_GAME)


func update_entity_pos_directly(id: int, pos: Vector3) -> void:
	var packet: Dictionary = {
		"type": Globals.PacketTypes.UPDATE_ENTITY_POS, 
		"id": id, 
		"pos": pos,
	}
	
	broadcast_data(packet, SteamValues.SendType.UNRELIABLE, Globals.Channels.IN_GAME)


func host_broadcast_room_settings(settings: Dictionary) -> void:
	if Lobby.is_host:
		var packet: Dictionary = {
			"type": Globals.PacketTypes.ROOM_SETTINGS,
			"settings": settings
		}
		broadcast_data(packet, SteamValues.SendType.RELIABLE)


func broadcast_loading_screen() -> void:
	var packet: Dictionary = {
		"type": Globals.PacketTypes.SHOW_LOADING_SCREEN,
	}
	
	broadcast_data(packet, SteamValues.SendType.RELIABLE)


func broadcast_or_send_start_loading_game(room_settings: Dictionary, all_env_info: Dictionary, all_player_info: Dictionary, send_to: int = -1) -> void:
	var packet: Dictionary = {
		"type": Globals.PacketTypes.START_LOADING_GAME,
		"map": room_settings["map"],
		"gamemode": RoomSettings.get_rounds_gamemode_ref(),
		"settings": room_settings,
		"env": all_env_info,
		"players": all_player_info
	}
	
	if send_to == -1:
		broadcast_data(packet, SteamValues.SendType.RELIABLE)
	else:
		send_to(send_to, packet, SteamValues.SendType.RELIABLE)


func broadcast_all_rounds_over() -> void:
	var packet: Dictionary = {
		"type": Globals.PacketTypes.ALL_ROUNDS_OVER,
	}
	
	broadcast_data(packet, SteamValues.SendType.RELIABLE)


func host_broadcast_gameover_panel(winner_ids: Array, text: String, winner_title: String = "", loser_title: String = "") -> void: 
	if Lobby.is_host:
		var packet: Dictionary = {
			"type": Globals.PacketTypes.BROADCAST_GAMEOVER_PANEL,
			"winner_ids": winner_ids,
			"text": text,
			"winner_title": winner_title,
			"loser_title": loser_title,
		}
		
		broadcast_data(packet, SteamValues.SendType.RELIABLE)


func broadcast_countdown(count_down_time: int) -> void:
	var packet: Dictionary = {
		"type": Globals.PacketTypes.COUNTDOWN,
		"time": count_down_time
	}
	
	broadcast_data(packet, SteamValues.SendType.RELIABLE)


func change_game_state(state: int, time_until_next: float) -> void:
	var packet: Dictionary = {
		"type": Globals.PacketTypes.CHANGE_GAME_STATE,
		"state": state,
		"time_until_next": time_until_next
	}
	
	broadcast_data(packet, SteamValues.SendType.RELIABLE)


func request_join_game() -> void:
	var packet: Dictionary = {
		"type": Globals.PacketTypes.REQUEST_JOIN_MID_GAME,
	}
	
	send_to(Lobby.host_id, packet, SteamValues.SendType.RELIABLE)


func spawn_player(player_id: int, player_info: Dictionary, to: int = -1) -> void:
	var packet: Dictionary = {
		"type": Globals.PacketTypes.SPAWN_PLAYER,
		"id": player_id,
		"player": player_info
	}
	
	if to == -1:
		broadcast_data_except(Lobby.host_id, packet, SteamValues.SendType.RELIABLE)
	else:
		send_to(to, packet, SteamValues.SendType.RELIABLE)


func broadcast_entity_transform(env_id: int, pos: Vector3, rot: float) -> void:
	var packet: Dictionary = {
		"type": Globals.PacketTypes.UPDATE_ENTITY_TRANSFORM, 
		"id": env_id,
		"pos": pos,
		"rot": rot
	}
	
	broadcast_data_except(Lobby.host_id, packet, SteamValues.SendType.UNRELIABLE, Globals.Channels.IN_GAME)


func done_loading_scenes() -> void:
	var packet: Dictionary = {
		"type": Globals.PacketTypes.DONE_LOADING_SCENES,
	}
	
	send_to(Lobby.host_id, packet, SteamValues.SendType.RELIABLE)


# Exit the loading screen for a client
func set_done_loading(to_player: int = -1) -> void:
	var packet: Dictionary = {
		"type": Globals.PacketTypes.SET_DONE_LOADING
	}
	
	if to_player == -1:
		broadcast_data(packet, SteamValues.SendType.RELIABLE)
	else:
		send_to(to_player, packet, SteamValues.SendType.RELIABLE)


func update_health(entity_id: int, health: int, entity_type: int) -> void:
	var packet: Dictionary = {
		"type" : Globals.PacketTypes.UPDATE_HEALTH,
		"id" : entity_id,
		"health" : health,
	}
	
	broadcast_data(packet, SteamValues.SendType.UNRELIABLE, Globals.Channels.IN_GAME)


func update_max_health(entity_id: int, max_health: int) -> void:
	var packet: Dictionary = {
		"type" : Globals.PacketTypes.UPDATE_MAX_HEALTH,
		"id": entity_id,
		"health": max_health
	}
	broadcast_data(packet, SteamValues.SendType.RELIABLE, Globals.Channels.IN_GAME)


func broadcast_player_death(player_id: int, killer_id: int = -1, with_spell_type: int = Globals.SpellTypes.NONE, death_type: int = Globals.PlayerDeathTypes.NORMAL) -> void:
	if Lobby.is_host:
		var packet: Dictionary = {
			"type": Globals.PacketTypes.PLAYER_DEATH,
			"id": player_id,
			"killer_id": killer_id,
			"death_type": death_type,
			"spell": with_spell_type
		}
		
		broadcast_data(packet, SteamValues.SendType.RELIABLE, Globals.Channels.IN_GAME)


func send_player_death(to: int, player_id: int, killer_id: int = -1, death_type: int = Globals.PlayerDeathTypes.NORMAL) -> void:
	if Lobby.is_host:
		var packet: Dictionary = {
			"type": Globals.PacketTypes.PLAYER_DEATH,
			"id": player_id,
			"killer_id": killer_id,
			"death_type": death_type,
			"spell": Globals.SpellTypes.NONE,
		}
		
		send_to(to, packet, SteamValues.SendType.RELIABLE, Globals.Channels.IN_GAME)


func request_respawn() -> void:
	var packet: Dictionary = {
		"type": Globals.PacketTypes.REQUEST_RESPAWN_PLAYER,
	}
	
	send_to(Lobby.host_id, packet, SteamValues.SendType.RELIABLE)


func respawn_player(player_id: int) -> void:
	var packet: Dictionary = {
		"type": Globals.PacketTypes.RESPAWN_PLAYER,
		"id": player_id,
	}
	
	broadcast_data(packet, SteamValues.SendType.RELIABLE)


func set_score(player_or_team_id: int, score: int, to_team: bool = false) -> void:
	if Lobby.is_host:
		var packet: Dictionary = {
			"type": Globals.PacketTypes.SET_SCORE,
			"id": player_or_team_id,
			"score": score,
			"to_team": to_team
		}
		
		broadcast_data(packet, SteamValues.SendType.RELIABLE)


func broadcast_updated_leaderboard(player_scores: Array) -> void:
	var packet: Dictionary = {
		"type": Globals.PacketTypes.SET_LEADERBOARD,
		"board": player_scores,
	}
	
	broadcast_data(packet, SteamValues.SendType.RELIABLE)


func request_leaderboard() -> void:
	var packet: Dictionary = {
		"type": Globals.PacketTypes.REQUEST_LEADERBOARD
	}
	
	send_to(Lobby.host_id, packet, SteamValues.SendType.RELIABLE)


func start_shrink() -> void:
	var gamemodeInfo = GamemodeValues.get_current_rounds_gamemodeinfo()
	if gamemodeInfo.respawn_allowed == false:
		var packet: Dictionary = {
			"type": Globals.PacketTypes.START_SHRINK,
		}
		
		broadcast_data(packet, SteamValues.SendType.RELIABLE)


func host_set_is_OP(player_id: int, time: float, only_spellcaster: bool = false) -> void:
	if Lobby.is_host:
		var packet: Dictionary = {
			"type": Globals.PacketTypes.SET_IS_OP,
			"id": player_id,
			"time": time,
			"spell": only_spellcaster
		}
		
		broadcast_data(packet, SteamValues.SendType.RELIABLE, Globals.Channels.IN_GAME)


func host_set_is_loser(player_id: int) -> void:
	if Lobby.is_host:
		var packet: Dictionary = {
			"type": Globals.PacketTypes.SET_IS_LOSER,
			"id": player_id,
		}
		
		broadcast_data(packet, SteamValues.SendType.RELIABLE, Globals.Channels.IN_GAME)


func trigger_player_animation(entity: Entity, animation_nr: int):
	if entity.get_type() == Globals.EntityTypes.PLAYER:
		var packet: Dictionary = {
			"type": Globals.PacketTypes.TRIGGER_PLAYER_ANIMATION,
			"id": entity.get_id(),
			"animation_nr": animation_nr,
			"dir": entity.get_move_dir_v2(),
		}
		
		broadcast_data(packet, SteamValues.SendType.UNRELIABLE, Globals.Channels.IN_GAME)


func host_broadcast_destroy_entity(entity_id: int, of_old_age: bool = false):
	if Lobby.is_host:
		var packet: Dictionary = {
			"type": Globals.PacketTypes.DESTROY_ENTITY,
			"id": entity_id,
			"old": of_old_age
		}
		
		broadcast_data(packet, SteamValues.SendType.RELIABLE)


func spawn_spell(player_id: int, player_team: String, spell_id: int, spell_type: int, pos: Vector3, dir: Vector2):
	var packet: Dictionary = {
		"type": Globals.PacketTypes.SPAWN_SPELL,
		"player_id": player_id,
		"team": player_team,
		"spell_id": spell_id,
		"spell_type": spell_type,
		"pos": pos,
		"dir": dir,
	}
	
	broadcast_data(packet, SteamValues.SendType.RELIABLE)


func reflect_spell(creator_id: int, spell_id: int, pos: Vector3, new_dir: Vector3):
	var packet: Dictionary = {
		"type": Globals.PacketTypes.REFLECT_SPELL,
		"id": creator_id,
		"spell_id": spell_id,
		"pos": pos,
		"dir": new_dir
	}
	
	broadcast_data(packet, SteamValues.SendType.RELIABLE, Globals.Channels.IN_GAME)


func spawn_environment(env_id: int, env_info: Dictionary, dont_send_to_id: int = -1, parent_to_id: int = -1):
	var packet: Dictionary = {
		"type": Globals.PacketTypes.SPAWN_ENVIRONMENT,
		"env_id": env_id,
		"env_info": env_info, # {"type": int, "pos": vec2, "rot": float}
		"parent": parent_to_id,
	}
	
	if dont_send_to_id == -1:
		broadcast_data(packet, SteamValues.SendType.RELIABLE)
	else:
		broadcast_data_except(dont_send_to_id, packet, SteamValues.SendType.RELIABLE)


func launch(id: int, entity_type: int, from: Vector3, to: Vector3, speed: float) -> void:
	var packet: Dictionary = {
		"type": Globals.PacketTypes.LAUNCH,
		"id": id,
		"etype": entity_type, 
		"from": from,
		"to": to,
		"spd": speed
	}
	
	broadcast_data(packet, SteamValues.SendType.RELIABLE, Globals.Channels.IN_GAME)


func transform_into(player_id: int, transform_into: int, speed_modifier: float = 1.0, duration: float = -1) -> void:
	var packet: Dictionary = {
		"type": Globals.PacketTypes.TRANSFORM_INTO,
		"id": player_id,
		"into": transform_into,
		"speed_modifier": speed_modifier,
		"duration": duration
	}
	
	broadcast_data(packet, SteamValues.SendType.RELIABLE, Globals.Channels.IN_GAME)


func trigger_particle_effect(entity_id: int, entity_type: int, effect_nr: int, emitting: bool = true):
	var packet: Dictionary = {
		"type": Globals.PacketTypes.TRIGGER_PARTICLE_EFFECT,
		"id": entity_id,
		"entity_type": entity_type,
		"effect_nr": effect_nr,
		"emitting": emitting
	}
	
	broadcast_data(packet, SteamValues.SendType.UNRELIABLE, Globals.Channels.IN_GAME)


# If freeze level == -1 we dont want to change icecubed or not
func broadcast_freeze_info(id: int, freeze_level: float, ice_cube: bool) -> void:
	var packet: Dictionary = {
		"type": Globals.PacketTypes.BROADCAST_FREEZE_INFO,
		"id": id,
		"lvl": freeze_level,
		"ice": ice_cube
	}
	
	broadcast_data(packet, SteamValues.SendType.UNRELIABLE, Globals.Channels.IN_GAME)


func deactivate_spell(deactivated_spell: int):
	var packet: Dictionary = {
		"type": Globals.PacketTypes.DEACTIVATE_SPELL,
		"spell": deactivated_spell
	}
	
	send_to(Lobby.host_id, packet, SteamValues.SendType.RELIABLE, Globals.Channels.IN_GAME)


func request_update_active_spell(player_id: int, active_spell: int):
	var packet: Dictionary = {
		"type": Globals.PacketTypes.REQUEST_UPDATE_ACTIVE_SPELL,
		"player_id": player_id,
		"active_spell": active_spell,
	}
	
	send_to(Lobby.host_id, packet, SteamValues.SendType.RELIABLE, Globals.Channels.IN_GAME)


func request_cast_directional_spell(player_id: int, spell_type: int, dir: Vector2):
	var packet: Dictionary = {
		"type": Globals.PacketTypes.REQUEST_CAST_DIRECTIONAL_SPELL,
		"player_id": player_id,
		"spell_type": spell_type,
		"dir": dir,
	}
	
	send_to(Lobby.host_id, packet, SteamValues.SendType.RELIABLE, Globals.Channels.IN_GAME)


func request_cast_positional_spell(player_id: int, spell_type: int, pos: Vector3):
	var packet: Dictionary = {
		"type": Globals.PacketTypes.REQUEST_CAST_POSITIONAL_SPELL,
		"player_id": player_id,
		"spell_type": spell_type,
		"pos": pos,
	}
	
	send_to(Lobby.host_id, packet, SteamValues.SendType.RELIABLE, Globals.Channels.IN_GAME)


func request_cast_parented_spell(player_id: int, spell_type: int, parent_to_id: Vector3):
	var packet: Dictionary = {
		"type": Globals.PacketTypes.REQUEST_CAST_PARENTED_SPELL,
		"player_id": player_id,
		"spell_type": spell_type,
		"parent_to_id": parent_to_id,
	}
	
	send_to(Lobby.host_id, packet, SteamValues.SendType.RELIABLE, Globals.Channels.IN_GAME)


func request_deactivate_arcane_wall(id: int, spawn_wall: bool):
	var packet: Dictionary = {
		"type": Globals.PacketTypes.REQUEST_DEACTIVATE_ARCANE_WALL,
		"id": id,
		"spawn_wall": spawn_wall,
	}
	
	send_to(Lobby.host_id, packet, SteamValues.SendType.RELIABLE, Globals.Channels.IN_GAME)



func request_rock_dash(id: int, dir: Vector2) -> void:
	var packet: Dictionary = {
		"type": Globals.PacketTypes.REQUEST_ROCK_DASH,
		"id": id,
		"dir": dir,
	}
	
	send_to(Lobby.host_id, packet, SteamValues.SendType.RELIABLE, Globals.Channels.IN_GAME)


func request_transform_into(id: int, transform_into: int, speed_modifier: float = 1.0, duration: float = -1) -> void:
	var packet: Dictionary = {
		"type": Globals.PacketTypes.REQUEST_CAST_TRANSFORM_INTO,
		"id": id,
		"into": transform_into,
		"speed_modifier": speed_modifier,
		"duration": duration
	}
	
	broadcast_data(packet, SteamValues.SendType.RELIABLE, Globals.Channels.IN_GAME)


func request_update_player_input(player_id: int, input: Vector2):
	var packet: Dictionary = {
		"type": Globals.PacketTypes.REQUEST_UPDATE_PLAYER_MOVEMENT, 
		"id": player_id, 
		"input": input,
	}
	
	# Player movement, send request to host
	send_to(Lobby.host_id, packet, SteamValues.SendType.UNRELIABLE, Globals.Channels.IN_GAME)


func send_chat_message(sender_id: int, message: String):
	var packet: Dictionary = {
		"type": Globals.PacketTypes.SEND_CHAT_MESSAGE,
		"id": sender_id,
		"message": message,
	}
	
	broadcast_data(packet, SteamValues.SendType.RELIABLE, Globals.Channels.LOBBY)

##################
# SEND FUNCTIONS #
##################
func broadcast_data_except(except_id: int, packet: Dictionary, send_type: int, channel: int = Globals.Channels.LOBBY):
	if Lobby.lobby_state != Lobby.LobbyStates.NO_LOBBY:
		var byte_data: PoolByteArray = var2bytes(packet)
		for player_info in Lobby.client_members:
			if player_info["id"] != except_id:
				if player_info["id"] == Lobby.host_id && Lobby.is_host:
					PacketHandler.host_read_packet_directly(SteamValues.STEAM_ID, packet, channel)
				else:
					var sent: bool = Steam.sendP2PPacket(player_info["id"], byte_data, send_type, channel)
					if sent == false:
						printerr("broadcast_data_except(): Failed to send packet")


func broadcast_data(packet: Dictionary, send_type: int, channel: int = Globals.Channels.LOBBY):
	if Lobby.lobby_state != Lobby.LobbyStates.NO_LOBBY:
		var byte_data: PoolByteArray = var2bytes(packet)
		for player_info in Lobby.client_members:
			# Host doesn't need to send a packet to itself, they can just update the room node directly
			if player_info["id"] == Lobby.host_id && Lobby.is_host:
				PacketHandler.host_read_packet_directly(SteamValues.STEAM_ID, packet, channel)
				continue
				
			var sent: bool = Steam.sendP2PPacket(player_info["id"], byte_data, send_type, channel)
			if sent == false:
				printerr("broadcast_data(): Failed to send packet")


func send_to(to_player: int, packet: Dictionary, send_type: int, channel: int = Globals.Channels.LOBBY):
	if Lobby.lobby_state != Lobby.LobbyStates.NO_LOBBY:
		# Host doesn't need to send a packet to itself, they can just update the room node directly
		if to_player == Lobby.host_id && Lobby.is_host:
			PacketHandler.host_read_packet_directly(SteamValues.STEAM_ID, packet, channel)
			return
		
		var byte_data: PoolByteArray = var2bytes(packet)
		var sent: bool = Steam.sendP2PPacket(to_player, byte_data, send_type, channel)
		if sent == false:
			printerr("send_to(): Failed to send packet to client with id ", to_player)
