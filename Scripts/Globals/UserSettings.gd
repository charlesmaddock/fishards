extends Node

var settings_dict: Dictionary = {}
var save_path: String = "user://settings.save"


signal user_settings_updated()
signal spell_discovered(spell_type)


onready var _default_user_settings: Dictionary = {
	"volumes": {
		"Master": 100,
		"Music": 100,
		"SFX": 100,
	},
	"keybinds": {
		"element_1": Util.get_key_code("element_1", Util.InputTypes.KEYBOARD), 
		"element_2": Util.get_key_code("element_2", Util.InputTypes.KEYBOARD),
		"element_3": Util.get_key_code("element_3", Util.InputTypes.KEYBOARD),
		"element_4": Util.get_key_code("element_4", Util.InputTypes.KEYBOARD),
		"element_5": Util.get_key_code("element_5", Util.InputTypes.KEYBOARD),
		"ui_right": Util.get_key_code("ui_right", Util.InputTypes.KEYBOARD, true),
		"ui_left": Util.get_key_code("ui_left", Util.InputTypes.KEYBOARD, true),
		"ui_up": Util.get_key_code("ui_up", Util.InputTypes.KEYBOARD, true),
		"ui_down": Util.get_key_code("ui_down", Util.InputTypes.KEYBOARD, true),
		"cast_spell": BUTTON_LEFT,
		"reset_elements": Util.get_key_code("reset_elements", Util.InputTypes.KEYBOARD),
		"toggle_leaderboard": Util.get_key_code("toggle_leaderboard", Util.InputTypes.KEYBOARD),
		"open_chat": Util.get_key_code("open_chat", Util.InputTypes.KEYBOARD)
	},
	"fullscreen" : true,
	"aspect_ratio" : Vector2(16, 9),
	"elements": [Globals.Elements.FIRE, Globals.Elements.WATER, Globals.Elements.EARTH],
	"prettyGraphics": true,
	"disableSpellHUD": false,
	"autoClearElements": false,
	"disableController": false,
	"allow_click_to_move": false,
	"show_spell_cooldowns": false,
	"minimal_HUD": false,
	"spells_discovered": [Globals.SpellTypes.FIREBALL],
	"firstTimePlaying": true,
	"pb_training_time": -1,
	"has_cast_spell": false,
	"has_held_down_spell": false,
}


#### SETTINGS ####

func _ready():
	load_settings()
	Lobby.connect("lobby_members_updated", self, "_on_lobby_members_updated")
	
	check_first_time_playing()


func check_first_time_playing() -> void:
	if settings_dict["firstTimePlaying"] == true || Globals.get_app_mode() == Globals.AppModes.DEVELOPMENT:
		var popup = load("res://Scenes/MainMenu/Util/TutorialPopUp.tscn").instance()
		add_child(popup)
		settings_dict["firstTimePlaying"] = false
		save_settings()


func _on_lobby_members_updated() -> void:
	for player_info in Lobby.get_all_lobby_player_info():
		if player_info["id"] == SteamValues.STEAM_ID:
			if player_info["elmts"] != get_elements():
				save_elements(player_info["elmts"])


func use_pretty_graphics() -> bool:
	return settings_dict["prettyGraphics"]


func get_allow_click_to_move() -> bool:
	return settings_dict["allow_click_to_move"]


func get_show_spell_cooldowns() -> bool:
	return settings_dict["show_spell_cooldowns"]


func get_minimal_HUD() -> bool:
	return settings_dict["minimal_HUD"]


func get_has_cast_spell() -> bool:
	return settings_dict["has_cast_spell"]


func set_has_cast_spell() -> void:
	if settings_dict["has_cast_spell"] == false:
		settings_dict["has_cast_spell"] = true
		save_settings()


func get_has_held_down_spell() -> bool:
	return settings_dict["has_held_down_spell"]


func set_has_held_down_spell() -> void:
	if settings_dict["has_held_down_spell"] == false:
		settings_dict["has_held_down_spell"] = true
		save_settings()


func get_settings() -> Dictionary:
	return settings_dict


func get_disable_spell_hud() -> bool:
	return settings_dict["disableSpellHUD"]


func get_auto_clear_elements() -> bool:
	return settings_dict["autoClearElements"]


func get_elements() -> Array:
	return settings_dict["elements"].duplicate(true)


func save_elements(elements: Array):
	settings_dict["elements"] = elements
	save_settings()


func save_pb_training_time(time: int) -> Dictionary:
	var pb_training_time = settings_dict["pb_training_time"]
	var new_highscore: bool = false
	if pb_training_time == -1 || time > pb_training_time:
		settings_dict["pb_training_time"] = time
		new_highscore = true
		save_settings()
	
	return {"pb": settings_dict["pb_training_time"], "highscore": new_highscore}


func save_and_broadcast_elements(elements: Array, kill_on_update: bool = true) -> void:
	# Broadcast changes if we are in a lobby
	save_elements(elements)
	if (Lobby.lobby_id != 0 || Globals.in_single_player == true): 
		print("[request_update_player_info]: sending elements ", elements)
		PacketSender.request_update_player_info(kill_on_update)


func load_settings() -> void:
	var file: File = File.new()
	if file.file_exists(save_path) == true:
		var open_res: int = file.open(save_path, File.READ)
		if open_res == OK:
			var saved_user_settings = file.get_var()
			# If the settings dont have the same key
			for key in _default_user_settings.keys():
				if saved_user_settings.has(key) == false:
					printerr("Didn't find the key '", key,"' in saved settings, adding default")
					saved_user_settings[key] = _default_user_settings[key]
			
			settings_dict = saved_user_settings
			save_settings()
			file.close()
		else:
			printerr("Failed to open user settings file")
	else:
		settings_dict = _default_user_settings.duplicate(true)
		save_settings()
	
	for key in settings_dict["keybinds"].keys():
		set_key_bind(key, settings_dict["keybinds"][key], settings_dict["keybinds"][key] < 10) # fyfan vi måste göra deta bättre asså
	
	for key in settings_dict["volumes"].keys():
		set_bus_volume(key, settings_dict["volumes"][key])
	
	#set_aspect_ratio(settings_dict["aspect_ratio"])
	toggle_fullscreen(true)
	toggle_pretty_graphics(settings_dict["prettyGraphics"])
	toggle_allow_click_to_move(settings_dict["allow_click_to_move"])
	toggle_minimal_HUD(settings_dict["minimal_HUD"])
	toggle_show_spell_cooldowns(settings_dict["show_spell_cooldowns"])


func save_settings() -> void:
	var file: File = File.new()
	var open_res: int = file.open(save_path, File.WRITE)
	if open_res == OK:
		emit_signal("user_settings_updated")
		file.store_var(settings_dict)
		file.close()
	else:
		printerr("Failed to write user settings to file")


func reset_to_default() -> void:
	var new_settings_dict = _default_user_settings.duplicate(true)
	# Some things shouldn't reset
	new_settings_dict["spells_discovered"] = settings_dict["spells_discovered"]
	new_settings_dict["firstTimePlaying"] = settings_dict["firstTimePlaying"]
	new_settings_dict["has_cast_spell"] = settings_dict["has_cast_spell"]
	new_settings_dict["has_held_down_spell"] = settings_dict["has_held_down_spell"]
	settings_dict = new_settings_dict
	InputMap.load_from_globals()
	save_settings()
	load_settings()


func set_bus_volume(bus_name: String, volume: float) -> void:
	settings_dict["volumes"][bus_name] = volume
	
	var volume_db: float = Util.remap_range(volume, 0, 100, -30, 0)
	if volume == 0:
		volume_db = -80
	
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index(bus_name), volume_db)


func set_key_bind(name: String, keycode: int, is_mouse: bool, is_movement: bool = false) -> void:
	var actionlist = InputMap.get_action_list(name)
	if !actionlist.empty():
		if is_movement == false:
			for action in actionlist:
				if is_mouse == true && action is InputEventMouseButton:
					InputMap.action_erase_event(name, action)
					break
				elif is_mouse == false && action is InputEventKey:
					InputMap.action_erase_event(name, action)
					break
		else:
			for action in actionlist:
				if action is InputEventKey:
					if is_movement && (action.scancode == KEY_DOWN || action.scancode == KEY_UP || action.scancode == KEY_LEFT || action.scancode == KEY_RIGHT):
						continue
					InputMap.action_erase_event(name, action)
				
				if action is InputEventMouseButton:
					InputMap.action_erase_event(name, action)
	
	if is_mouse == false:
		var new_key = InputEventKey.new()
		new_key.set_scancode(keycode)
		InputMap.action_add_event(name, new_key)
	else:
		var new_key = InputEventMouseButton.new()
		new_key.set_button_index(keycode)
		InputMap.action_add_event(name, new_key)
	
	settings_dict["keybinds"][name] = keycode


# Not used but may be useful in the future
func set_aspect_ratio(aspect_ratio: Vector2) -> void:
	var pixel_width: float = ProjectSettings.get_setting("display/window/size/width")
	var pixel_height: float = pixel_width * (aspect_ratio.y/ aspect_ratio.x)
	
	var window_width: float = ProjectSettings.get_setting("display/window/size/test_width")
	var window_height: float = window_width * (aspect_ratio.y / aspect_ratio.x)
	
	get_tree().get_root().set_size(Vector2(pixel_width, pixel_height))
	OS.set_window_size(Vector2(window_width, window_height))
	
	settings_dict["aspect_ratio"] = aspect_ratio


func toggle_fullscreen(value: bool) -> void:
	OS.set_window_fullscreen(value)
	settings_dict["fullscreen"] = value


func toggle_pretty_graphics(value: bool) -> void:
	settings_dict["prettyGraphics"] = value


func toggle_allow_click_to_move(value: bool) -> void:
	settings_dict["allow_click_to_move"] = value


func toggle_show_spell_cooldowns(value: bool) -> void:
	settings_dict["show_spell_cooldowns"] = value


func toggle_minimal_HUD(value: bool) -> void:
	settings_dict["minimal_HUD"] = value


func disable_spell_HUD(value: bool) -> void:
	settings_dict["disableSpellHUD"] = value


func toggle_auto_clear_elements(value: bool) -> void:
	settings_dict["autoClearElements"] = value


func disable_controller(value: bool) -> void:
	settings_dict["disableController"] = value


func discover_spell(spell: int) -> void:
	if !settings_dict["spells_discovered"].has(spell):
		settings_dict["spells_discovered"].append(spell)
		emit_signal("spell_discovered", spell)
		save_settings()
		
