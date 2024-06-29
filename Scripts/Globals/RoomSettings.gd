extends Node


var settings: Dictionary # settings.teams: [{"team_name": name, "members": {"id": name}}]
var print_room_setting_updates: bool = false


func _ready():
	Lobby.connect("player_killed", self, "_on_player_killed")


func _on_player_killed(_killed_id: int, killer_id: int, _with_spell: int) -> void:
	var new_leaderboard = settings["leaderboard"].duplicate(true)
	for leaderboard_obj in new_leaderboard:
		if leaderboard_obj.player_id == killer_id:
			leaderboard_obj.kills += 1
			break
	
	edit_settings({"leaderboard": new_leaderboard}, false)


func get_bot_difficulty() -> int:
	if settings.has("bot_difficulty"):
		return settings["bot_difficulty"]
	else:
		printerr("Settings doesn't have bot_difficulty")
		return -1


func get_powerups_enabled() -> bool:
	if settings.has("powerups"):
		return settings["powerups"]
	else:
		printerr("Settings doesn't have powerups")
		return true


func get_element_amount() -> int:
	if settings.has("elmts"):
		return settings["elmts"]
	else:
		printerr("Settings doesn't have gamemode")
		return 3


func get_element_mode() -> int:
	if settings.has("element_mode"):
		return settings["element_mode"]
	else:
		printerr("Settings doesn't have element mode")
		return Globals.ElementModes.DEFAULT


func get_gamemode() -> int:
	if settings.has("gamemode"):
		return settings["gamemode"]
	else:
		printerr("Settings doesn't have gamemode")
		return -1


func get_game_started() -> bool:
	if settings.has("game_started"):
		return settings["game_started"]
	else:
		printerr("Settings doesn't have game_started")
		return false


func get_rounds_gamemode() -> int:
	if settings.has("round_gamemode_order"):
		return settings.round_gamemode_order[get_current_round()]
	else:
		printerr("Settings doesn't have round_gamemode_order for get_rounds_gamemode()")
		return GamemodeValues.Gamemodes.Shuffle


func get_rounds_gamemode_ref() -> String:
	if settings.has("round_gamemode_order"):
		return GamemodeValues.GameModeInfo[settings.round_gamemode_order[get_current_round()]].scene
	else:
		printerr("Settings doesn't have round_gamemode_order for get_rounds_gamemode_ref()")
		return ""


func get_round_text() -> String:
	if settings.has("round_gamemode_order"):
		return str(get_current_round() + 1) + "/" + str(settings.round_gamemode_order.size())
	else:
		printerr("Settings doesn't have round_gamemode_order for get_round_text()")
		return ""


func get_map_type() -> int:
	return settings["map_type"]


func create_settings_dict(password: String = "", max_players: int = 12, map_type: int = 0, map_size: int = 0, bot_amount: int = 1, gamemode: int = 0, round_amount: int = 4, elements_amount: int = 3, bot_difficulty: int = Globals.PlayerTypes.EASY_BOT, element_mode: int = Globals.ElementModes.DEFAULT, powerups: bool = true) -> Dictionary:
	var new_settings = {
		"password": password,
		"max_players": max_players,
		"map_type": map_type,
		"map_size": map_size,
		"bot_amount": bot_amount,
		"bot_difficulty": bot_difficulty,
		"gamemode": gamemode,
		"game_started": false,
		"round_gamemode_order": generate_gamemode_rounds_array(round_amount, gamemode),
		"current_round": 0,
		"map": "",
		"powerups": powerups,
		"element_mode": element_mode,
		"leaderboard": [], # [{"player_id": 812938, "score": 1}]
		"rounds": round_amount,
		"elmts": elements_amount
	}
	return new_settings


func edit_settings(edited_values: Dictionary, broadcast_changes: bool, kill_on_update: bool = true) -> void:
	var update_gamemodes: bool = false
	var updated_bots: bool = false
	var new_settings: Dictionary = settings.duplicate(true)
	
	for edited_key in edited_values:
		if new_settings.has(edited_key):
			new_settings[edited_key] = edited_values[edited_key]
			if edited_key == "rounds" || edited_key == "gamemode":
				update_gamemodes = true
			if edited_key == "bot_amount" || edited_key == "bot_difficulty":
				updated_bots = true
		else:
			printerr("Tried to add a setting key that doesn't exist: ", edited_key)
	
	# Only the host should decide ex. rounds and bots 
	if Lobby.is_host:
		# We need to set all other values until we can set these values
		if update_gamemodes == true:
			new_settings["round_gamemode_order"] = generate_gamemode_rounds_array(new_settings.rounds, new_settings.gamemode)
		if updated_bots == true:
			Lobby.generate_bot_members(new_settings.bot_amount, new_settings.elmts, new_settings.bot_difficulty)
	
	# If we broadcast the change we will receive the change though a packet ourselves,
	# else fake that a room settings packet was received
	if broadcast_changes == true:
		PacketSender.host_broadcast_room_settings(new_settings)
	else:
		p2p_set_values(new_settings, kill_on_update)


func host_start_next_round(first_round: bool) -> void:
	if Lobby.is_host == true:
		#printerr("Stray nodes: ", print_stray_nodes())
		
		if settings.has("round_gamemode_order"):
			if first_round == false:
				var next_round = settings["current_round"] + 1
				edit_settings({"current_round": next_round}, true)
			
			var amount_of_players = Lobby.get_all_lobby_player_info(true).size()
			
			Lobby.clear_temp_bot_members()
			
			var gamemode_scene_ref: String = get_rounds_gamemode_ref()
			var map_scene_ref: String = GamemodeValues.generate_current_rounds_map_ref(amount_of_players)
			SceneLoader.host_generate_next_rounds_info(settings, map_scene_ref, gamemode_scene_ref)


func p2p_set_values(room_settings: Dictionary, kill_on_update: bool = true) -> void:
	_settings_print("# NEW ROOM SETTINGS ", OS.get_time() )
	var none: bool = true
	var elements_amount_changed: bool = false
	
	for new_setting_key in room_settings:
		if settings.has(new_setting_key):
			# Convert to string so that large dictionaries can be compared
			if str(settings[new_setting_key]) != str(room_settings[new_setting_key]):
				if new_setting_key == "elmts":
					elements_amount_changed = true
				
				settings[new_setting_key] = room_settings[new_setting_key]
				none = false
				_pretty_print(new_setting_key, room_settings[new_setting_key], "SET")
		else:
			if new_setting_key == "elmts":
				elements_amount_changed = true
			
			settings[new_setting_key] = room_settings[new_setting_key]
			none = false
			_pretty_print(new_setting_key, room_settings[new_setting_key], "ADD")
	
	if elements_amount_changed == true:
		var room_allowed_element_amount = settings["elmts"]
		# Amount of allowed elements has changed, save and broadcast new allowed combination of elements
		if UserSettings.get_elements().size() != room_allowed_element_amount:
			#print("room_allowed_element_amount has changed due to room settings update. New is ", room_allowed_element_amount, ", I have ", UserSettings.get_elements().size())
			Util.force_update_client_elements(room_allowed_element_amount, true, kill_on_update)
	
	Lobby.emit_signal("room_settings_updated")
	
	if none == true:
		_settings_print("# no changes      ")


func set_round_winner(id: int) -> void:
	var new_leaderboard = settings["leaderboard"].duplicate(true)
	for winner_obj in new_leaderboard:
		if winner_obj.player_id == id:
			winner_obj.score += 1
			break
	
	edit_settings({"leaderboard": new_leaderboard}, true)


func get_amount_of_rounds_won(id: int) -> int:
	var leaderboard: Array = settings["leaderboard"]
	for leaderboard_obj in leaderboard:
		if leaderboard_obj["player_id"] == id:
			return leaderboard_obj["score"]
	return 0


func host_add_player_to_leaderboard(id: int) -> void:
	var new_leaderboard = settings["leaderboard"].duplicate(true)
	var already_has: bool = false
	for winner_obj in new_leaderboard:
		if winner_obj.player_id == id:
			already_has = true
			break
	
	if already_has == false:
		new_leaderboard.append({"player_id": id, "score": 0, "kills": 0})
	
	edit_settings({"leaderboard": new_leaderboard}, true)


func remove_player_from_leaderboard(player_id: int) -> void:
	var new_leaderboard = settings["leaderboard"].duplicate(true)
	for winner_obj in new_leaderboard:
		if winner_obj.player_id == player_id:
			var remove_at = new_leaderboard.find(winner_obj)
			new_leaderboard.remove(remove_at)
	
	edit_settings({"leaderboard": new_leaderboard}, true)


func get_all_round_winners() -> Dictionary:
	var all_rounds_leaderboard = settings["leaderboard"].duplicate(true)
	
	var first_place_players = find_players_w_highest_score(all_rounds_leaderboard)
	all_rounds_leaderboard = remove_high_scorers(first_place_players, all_rounds_leaderboard)
	
	var second_place_players = find_players_w_highest_score(all_rounds_leaderboard)
	all_rounds_leaderboard = remove_high_scorers(second_place_players, all_rounds_leaderboard)
	
	var third_place_players = find_players_w_highest_score(all_rounds_leaderboard)
	all_rounds_leaderboard = remove_high_scorers(third_place_players, all_rounds_leaderboard)
	
	return {"first": first_place_players, "second": second_place_players, "third": third_place_players}


func remove_high_scorers(high_scorers_objs: Array, all_rounds_leaderboard: Array) -> Array:
	for winner_obj in high_scorers_objs:
		for leader_board_obj in all_rounds_leaderboard:
			if winner_obj.player_id == leader_board_obj.player_id:
				var remove_at = all_rounds_leaderboard.find(leader_board_obj)
				if remove_at != -1:
					all_rounds_leaderboard.remove(remove_at)
					break
	
	return all_rounds_leaderboard


func find_players_w_highest_score(all_rounds_leaderboard: Array) -> Array:
	# Find all the winners and their kills
	var highest_kills = -1
	var has_most_kills_id = 0
	var most_rounds_won = -1
	var most_round_winner_objs = []
	for leaderboard_obj in all_rounds_leaderboard:
		if leaderboard_obj.score > most_rounds_won:
			most_round_winner_objs.clear()
			most_round_winner_objs.append(leaderboard_obj)
			most_rounds_won = leaderboard_obj.score
		elif leaderboard_obj.score == most_rounds_won:
			most_round_winner_objs.append(leaderboard_obj)
			most_round_winner_objs.sort_custom(kill_sorter, "sort")
			most_round_winner_objs.invert()
	return most_round_winner_objs


class kill_sorter:
	static func sort(a, b) -> bool:
		if a.kills < b.kills:
			return true
		return false


class score_sorter:
	static func sort(a, b) -> bool:
		if a.score < b.score:
			return true
		return false


func _pretty_print(key_to_print, val_to_print, type: String) -> void:
	if val_to_print is Array && str(val_to_print).length() > 124:
		_settings_print("# ", type, " ", key_to_print, ": [")
		for val in val_to_print:
			if val is Dictionary:
				var print_to_line = ""
				for key in val:
					if key == "skin":
						print_to_line += str(key) + ": ..., "
					elif key == "spwnpnt":
						print_to_line += "pos: Vctr3, "
					else:
						print_to_line +=  str(key) + ": "  + str(val[key]) + ", "
				_settings_print("#   {", print_to_line, "},")
			else:
				_settings_print("#   ", val, ",")
		_settings_print("# ]")
	else:
		_settings_print("# ", type, " ", key_to_print, ": ", str(val_to_print))


func _settings_print(t1, t2="", t3="", t4="", t5="", t6="", t7="", t8="") -> void:
	if print_room_setting_updates == true:
		print(t1, t2, t3, t4, t5, t6, t7, t8)


func reset_gamemode_data() -> void:
	edit_settings({"game_started": false, "current_round": 0, "leaderboard": []}, true)


func get_current_round() -> int:
	return settings["current_round"]


func generate_gamemode_rounds_array(rounds: int, gamemode: int) -> Array:
	var round_gamemode_order: Array = []
	
	if gamemode != GamemodeValues.Gamemodes.Shuffle: 
		for _i in range(rounds):
			round_gamemode_order.append(gamemode)
	else:
		var shuffleable_gamemodes = [GamemodeValues.Gamemodes.FreeForAll, GamemodeValues.Gamemodes.LastManStanding, GamemodeValues.Gamemodes.TeamDeathmatch]
		var repeat_array = floor(rounds / shuffleable_gamemodes.size())
		var generated_rounds = []
		for i in repeat_array:
			generated_rounds.append_array(shuffleable_gamemodes)
		
		if generated_rounds.size() != rounds:
			var amount_left = rounds - generated_rounds.size()
			for i in amount_left:
				generated_rounds.append(shuffleable_gamemodes[i])
		round_gamemode_order = generated_rounds
	
	return round_gamemode_order


func next_round_status() -> Dictionary:
	var res: bool
	if get_current_round() + 1 < settings.round_gamemode_order.size():
		res = settings.round_gamemode_order[get_current_round()] == settings.round_gamemode_order[get_current_round() + 1]
	return {"is_same_gamemode": res, "all_rounds_over": get_current_round() == settings.round_gamemode_order.size() - 1}
