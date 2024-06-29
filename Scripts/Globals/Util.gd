extends Node


var rand: RandomNumberGenerator = RandomNumberGenerator.new()
var controller_connected: bool = false


enum InputTypes{
	KEYBOARD,
	MOUSE,
	CONTROLLER,
}


func _ready():
	rand.randomize()
	Input.connect("joy_connection_changed", self, "_on_joy_connection_changed")
	yield(get_tree(), "idle_frame")
	var controller_disabled = UserSettings.get_settings()["disableController"]
	if Input.get_connected_joypads().size() > 0 && !controller_disabled:
		#Globals.create_info_popup("Controller support not fully implemented.", "Using your keyboard and mouse is highly recommended for now. Don't worry though, there will be a update soon that fixes this! If you still want to use a controller press R1 to select element 5.")
		#The game does not work with keyboard if a controller is connected, disconnect it or disable controller in settings it if you wish to play without it"
		controller_connected = false


func log_print(flag: String, message: String) -> void:
	print("[" + flag + "]: " + message)


func force_update_client_elements(element_amount: int, broadcast: bool = true, kill_on_update: bool = true) -> Array:
	var new_player_elements: Array = []
	for i in element_amount:
		var element_id: int = i + 1
		new_player_elements.append(element_id)
	
	if broadcast == true:
		UserSettings.save_and_broadcast_elements(new_player_elements, kill_on_update)
	
	printerr("Force update clients elements, new are ", new_player_elements)
	
	return new_player_elements


func y_rot_to_vector_2(y_rot: float) -> Vector2:
	var v2: Vector2 = Vector2(sin(y_rot), cos(y_rot))
	return v2


func y_rot_to_vector_3(y_rot: float) -> Vector3:
	var v3: Vector3 = Vector3(sin(y_rot), 0, cos(y_rot))
	return v3


func vector_2_to_y_rot(v: Vector2):
	var y_rot: float = v.angle_to(Vector2.DOWN)
	return y_rot


func generate_temp_bot_levels(difficulty_curve: Curve, multiplier: float, bosses_only: bool):
	# Orded after difficulty
	var normal_levels = [
		{"type": Globals.PlayerTypes.FIREARD, "text": ""},
		{"type": Globals.PlayerTypes.DASHARD, "text": ""},
		{"type": Globals.PlayerTypes.METEORARD, "text": ""},
	]
	
	var bosses = [
		{"type": Globals.PlayerTypes.ICEARD, "text": "Iceard"},
		{"type": Globals.PlayerTypes.PUSHARD, "text": "Pushard"},
		{"type": Globals.PlayerTypes.MEGADASHARD, "text": "Mega Dashard"},
		{"type": Globals.PlayerTypes.GRABARD, "text": "Grabard"},
		{"type": Globals.PlayerTypes.SQUISHARD, "text": "Squishard"},
	]
	
	var normal_level_index = -1
	var boss_index = -1
	var bot_amount = 1 * ceil(float(multiplier)/1.6)
	var generated_levels = []
	
	for level in range(1, 300):
		var level_obj = {"text": "", "bots": []}
		var insert_boss_fight: bool = false
		
		normal_level_index += 1
		if normal_level_index >= normal_levels.size():
			insert_boss_fight = true
			bot_amount += 1 * ceil(float(multiplier)/1.6)
			if bot_amount >= 7:
				bot_amount = 6
			elif bot_amount >= 3 * ceil(float(multiplier)/1.6): # Limit amount of bots
				bot_amount = 3 * ceil(float(multiplier)/1.6)
			normal_level_index = 0
		
		if insert_boss_fight == true || bosses_only == true:
			boss_index += 1
			if boss_index >= bosses.size():
				boss_index = 0
			var boss_type = bosses[boss_index].type
			var boss_text = bosses[boss_index]["text"]
			generated_levels.append({"text": boss_text, "bots": [boss_type]})
		
		if normal_level_index < normal_levels.size() && bosses_only == false:
			level_obj["text"] = normal_levels[normal_level_index]["text"]
			for i in bot_amount:
				level_obj["bots"].append(normal_levels[normal_level_index]["type"])
			
			generated_levels.append(level_obj)
	
	return generated_levels


func generate_pretty_list(array_of_string: Array) -> String:
	var res = ""
	for index in array_of_string.size():
		var suffix = "" 
		if index == array_of_string.size() - 1:
			suffix = " "
		elif index == array_of_string.size() - 2:
			suffix = " and " 
		else:
			suffix = ", "
		res += array_of_string[index] + suffix
	return res


func generate_available_elements(amount_elements: int) -> Array:
	var available_elements: Array = [Globals.Elements.FIRE, Globals.Elements.WATER, Globals.Elements.EARTH, Globals.Elements.ARCANE, Globals.Elements.GOO]
	var remove_amount = available_elements.size() - amount_elements
	for i in remove_amount:
		available_elements.remove(rand.randi_range(0, available_elements.size() - 1))
	
	return available_elements


func generate_bot_name(bot_type: int, is_boss: bool = false) -> String:
	var name: String = ""
	
	if is_boss == false:
		name += Globals.ADJECTIVES[Util.rand.randi_range(0, Globals.ADJECTIVES.size() - 1)] + " "
	
	if bot_type != Globals.PlayerTypes.EASY_BOT && bot_type != Globals.PlayerTypes.MEDIUM_BOT && bot_type != Globals.PlayerTypes.HARD_BOT:
		return name + Globals.PlayerTypes.keys()[bot_type].to_lower().capitalize()
	
	if Util.rand.randf() > 0.2:
		name += Globals.FISH_SPECIES[Util.rand.randi_range(0, Globals.FISH_SPECIES.size() - 1)]
		if Util.rand.randf() > 0.5:
			name += Globals.EXTENSIONS[Util.rand.randi_range(0, Globals.EXTENSIONS.size() - 1)]
	else:
		name += Globals.NAMES[Util.rand.randi_range(0, Globals.NAMES.size() - 1)]
	
	#if name.length() < 14 && Util.rand.randf() > 0.5:
	#	name += " " + str(Util.rand.randi_range(1, 99))
	
	# Indicate level in name
	if bot_type == Globals.PlayerTypes.MEDIUM_BOT:
		name = "Pro " + name
	elif bot_type == Globals.PlayerTypes.HARD_BOT:
		name = "Lord " + name
	elif bot_type == Globals.PlayerTypes.SQUISHARD:
		name = "Squishard"
	
	name = "[Bot] " + name
	
	return name


func player_is_boss(player_type: int) -> bool:
	match player_type:
		Globals.PlayerTypes.CRABARD, Globals.PlayerTypes.PUSHARD, Globals.PlayerTypes.MEGADASHARD, Globals.PlayerTypes.GRABARD, Globals.PlayerTypes.ICEARD, Globals.PlayerTypes.SQUISHARD:
			return true 
	return false


func clamp_spell_pos(player_pos: Vector3, requested_pos: Vector3, spell_type: int) -> Vector3:
	var clamp_outer = spell_type == Globals.SpellTypes.DIVE || spell_type == Globals.SpellTypes.TOTEM || spell_type == Globals.SpellTypes.CRAB || spell_type == Globals.SpellTypes.DIVE || Globals.SpellTypes.METEOR
	var clamp_inner = spell_type == Globals.SpellTypes.METEOR
	var fixed_range = spell_type == Globals.SpellTypes.METEOR
	var dive_range = spell_type == Globals.SpellTypes.DIVE
	var totem_range = spell_type == Globals.SpellTypes.TOTEM
	var pos: Vector3 = Vector3(requested_pos.x, 0, requested_pos.z)
	
	if fixed_range:
		return player_pos + (pos - player_pos).normalized() * Globals.FIXED_SPELL_RANGE
	if dive_range:
		return player_pos + (pos - player_pos).normalized() * Globals.DIVE_RANGE
	if totem_range:
		return player_pos + (pos - player_pos).normalized() * Globals.TOTEM_RANGE
	
	if (pos - player_pos).length() >  Globals.SPELL_CAST_RANGE && clamp_outer == true:
		return player_pos + (pos - player_pos).normalized() * Globals.SPELL_CAST_RANGE
	elif (pos - player_pos).length() < Globals.SPELL_CAST_MIN_RANGE && clamp_inner == true:
		return player_pos + (pos - player_pos).normalized() * Globals.SPELL_CAST_MIN_RANGE
	else:
		return pos


func destroy(node: Node) -> void:
	node.set_process(false)
	node.set_physics_process(false)
	node.set_process_input(false)
	node.set_process_internal(false)
	node.set_physics_process_internal(false)
	node.set_process_unhandled_input(false)
	node.set_process_unhandled_key_input(false)
	
	if node is Area:
		set_deferred("monitorable", false)
		set_deferred("monitoring", false)
	
	if node is PhysicsBody:
		node.collision_layer = 0
		node.collision_mask = 0
	
	if node.has_method("set_visible"):
		node.set_visible(false)
	
	if node.has_method("set_translation"):
		node.set_translation(Vector3(9999,0,9999))


func destroy_w_children(root_node: Node) -> void:
	return
	destroy(root_node)
	for node in root_node.get_children():
		destroy_w_children(node)


func remap_range(value, input_a, input_b, output_a, output_b):
	return(value - input_a) / (input_b - input_a) * (output_b - output_a) + output_a


func reparent_node(child: Node, new_parent: Node):
	var old_parent = child.get_parent()
	old_parent.remove_child(child)
	new_parent.add_child(child)


func generate_id(type: int = 9, subtype: int = 9) -> int:
	var padded_subtype = str(subtype)
	if padded_subtype.length() == 1:
		padded_subtype = "0" + padded_subtype
	
	var id = str(rand.randi_range(0, 9999999)) + str(type) + padded_subtype
	return int(id)


func get_type_names(e_type, subtype) -> String:
	if e_type + 1 < Globals.EntityTypes.keys().size():
		var type_name = Globals.EntityTypes.keys()[e_type + 1]
		var subtype_name = str(subtype)
		if e_type == Globals.EntityTypes.PLAYER:
			subtype_name = Globals.PlayerTypes.keys()[subtype]
		elif e_type == Globals.EntityTypes.ENVIRONMENT:
			subtype_name = Globals.EnvironmentTypes.keys()[subtype]
		elif e_type == Globals.EntityTypes.SPELL:
			subtype_name = Globals.SpellTypes.keys()[subtype]
			
		return type_name + " of subtype " + str(subtype_name)
	elif(e_type == 9 && subtype == 9):
		return "untyped"
	else:
		return "unknown (probably player tho)"


func get_aim_position(space_state: PhysicsDirectSpaceState) -> Vector3:
	var ray_length = 1000
	var mouse_pos = get_viewport().get_mouse_position()
	var camera = get_viewport().get_camera()
	var from = camera.project_ray_origin(mouse_pos)
	var to = from + camera.project_ray_normal(mouse_pos) * ray_length
	
	var result = space_state.intersect_ray(from, to, [], pow(2, Globals.ColBits.AIM_PLAIN), true, true)
	if result.get("position") != null:
		return result.position
	
	return Vector3.DOWN


func get_room_node() -> Node:
	var room_node = get_node("/root/Room")
	if safe_to_use(room_node) == false:
		printerr("Room node is not safe to use!")
		return null
	return room_node


func get_current_game_state() -> int:
	var room_node = get_node("/root/Room")
	if is_instance_valid(room_node) == true:
		var gamemode_node = room_node.gamemode
		if is_instance_valid(gamemode_node):
			return gamemode_node.current_game_state
		else:
			printerr("get_current_game_state: Gamemode node is not safe to use!")
	
	return -1


func get_map_type_from_path(path: String) -> int:
	for map_scene_key in GamemodeValues.map_scenes:
		for map_size_key in GamemodeValues.map_scenes[map_scene_key]:
			for map_size_variant in GamemodeValues.map_scenes[map_scene_key][map_size_key]:
				if map_size_variant == path:
					return map_scene_key
	
	printerr("Could not find a map type with that path")
	return -1


func get_spell_array_from_elements(elements: Array) -> Array:
	var spell_comp_dict = Globals.SpellCompositions.duplicate(true)
	var inverted_element_array = Globals.Elements.values()
	
	# Invert to get all elements to remove
	for element in elements:
		inverted_element_array.erase(element)
	
	# Loop through all elements, loop through spells, if spell has element -> remove
	for element in inverted_element_array:
		for key in spell_comp_dict.keys():
			if spell_comp_dict[key].has(element):
				spell_comp_dict.erase(key)
	
	# Return remaining spell types
	return spell_comp_dict.keys()


func get_players_node() -> Players:
	var player_node = get_node("/root/Room/Players")
	if safe_to_use(player_node) == false:
		printerr("Players node is not safe to use!")
		return null
	return player_node


func get_entity_from_area(area):
	if area == null:
		return null
	
	if area.get_parent() is Entity:
		if Util.safe_to_use(area.get_parent()):
			return area.get_parent()
	
	return null


func get_key_code(input_name: String, type: int, is_movement: bool = false) -> int:
	var key_code: int
	match type:
		InputTypes.KEYBOARD:
			for input in InputMap.get_action_list(input_name):
				if input is InputEventKey:
					if is_movement && (input.scancode == KEY_DOWN || input.scancode == KEY_UP || input.scancode == KEY_LEFT || input.scancode == KEY_RIGHT):
						continue
					
					key_code = input.scancode
					break
	
	return key_code


func create_singleplayer_lobby(is_tutorial: bool) -> void:
	var gamemode: int = GamemodeValues.Gamemodes.Tutorial if is_tutorial == true else GamemodeValues.Gamemodes.Training
	var element_amount: int = 5 if is_tutorial == true else 3
	var have_powerups: bool = !is_tutorial 
	var singleplayer_room_settings = RoomSettings.create_settings_dict("", 12, 0, 0, 0, gamemode, 1, element_amount, 0, Globals.ElementModes.DEFAULT, have_powerups)
	Lobby.create_lobby(SteamValues.LobbyType.PRIVATE, singleplayer_room_settings.max_players, "Singleplayer room", singleplayer_room_settings, true, true)


func _on_joy_connection_changed(device_id, connected):
	if !UserSettings.settings_dict["disableController"] && connected == true:
		pass
		#controller_connected = connected #CONTROLLER DISABLED
	elif connected == false:
		pass
		#controller_connected = connected #CONTROLLER DISABLED
	else:
		pass
		#Globals.create_info_popup("Controller connected but was disabled in settings!", "Enable it and reconnect if you wish to use the controller")


func safe_to_use(node, show: bool = false) -> bool:
	if node == null:
		return false
	
	return is_instance_valid(node)


func steam_cloud_write(file_name: String, data):
	var byte_data: PoolByteArray = var2bytes(data)
	var data_size: int = byte_data.size()
	Steam.fileWrite(file_name, byte_data, data_size)


func steam_cloud_read(file_name: String):
	if Steam.fileExists(file_name):
		var data_size: int = Steam.getFileSize(file_name)
		var data_dict: Dictionary = Steam.fileRead(file_name, data_size)
		var byte_data: PoolByteArray =  data_dict["buf"]
		var data = bytes2var(byte_data)
		return data
	else:
		printerr("Tried to read a file that does not exist!: ", file_name)
		return null


func steam_cloud_delete(file_name: String):
	if Steam.fileExists(file_name):
		Steam.fileDelete(file_name)
	else:
		printerr("Tried to delete a file that does not exist!: ", file_name)
