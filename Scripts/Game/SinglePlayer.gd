extends Spatial


onready var instructionsLabel = $Objective/Margin/VBox/Instructions
onready var objectiveContainer = $Objective
onready var objectiveAnim = $Objective/AnimationPlayer
onready var howToPlayPopup = $HowToPlayPopup/Backdrop
onready var howToPlayFirstPart = $HowToPlayPopup/Backdrop/Panel/FirstPart
onready var howToPlaySecondPart = $HowToPlayPopup/Backdrop/Panel/SecondPart
onready var howToPlayThirdPart = $HowToPlayPopup/Backdrop/Panel/ThirdPart
onready var dialog_timer: Timer = $Timer
onready var sensei_animator: AnimationPlayer = $SenseiAnimator
onready var levelTimer: Timer = $LevelTimer
onready var arrow = $Arrow
onready var arrowPoof = $Arrow/Poof
onready var spellHUDTip = $spellHUDTip
onready var comboTipContainer = $Objective/Margin/VBox/ComboTipContainer
onready var spellTipLabel = $Objective/Margin/VBox/SpellTip/Label

export(Curve) var difficulty_curve

export(NodePath) var spawn_area
export(NodePath) var spawn_point_2
export(NodePath) var spawn_point_3

export(NodePath) var dummy_pos_2
export(NodePath) var dummy_pos_3
export(NodePath) var training_dummy_pos

export(NodePath) var island_2_animator
export(NodePath) var island_3_animator

export(NodePath) var island_4_player_pos
export(Array, NodePath) var island_4_spawn_shapes
export(NodePath) var spawn_area_4_spatial


var dialog_index: int = 0
var avoid_barrier_challenge: bool = false
var parkour_challenge: bool = false
var round_up_dummy_id: int
var training_dummy_id: int = 0
var fail_amount: int = 0
var _lerp_to_island_4_pos: bool
var _lerp_with_sensei: bool
var _alive_enemy_players: int = 0
var _level: float = 0
var gamemode_node
var _tutorial_final_challenge: bool = false 
var _dummy_mode: bool = false


var objective_shown: bool
var comboContainer = preload("res://Scenes/MainMenu/Util/ComboContainer.tscn")


signal how_to_play_closed
signal elements_pressed
signal cast_spell_pressed
signal updated_elements
signal first_dummy_killed
signal leaving_island_1
signal island_2_reached
signal island_3_reached
signal dummy_entered
signal island_4_reached


var greeting_sounds = {"index": 0, "sounds": [MusicAndSfxHandler.sounds.SENSEI_GREETINGS]}
var happy_sounds = {"index": 0, "sounds": [MusicAndSfxHandler.sounds.SENSEI_HAPPY1, MusicAndSfxHandler.sounds.SENSEI_HAPPY2, MusicAndSfxHandler.sounds.SENSEI_HAPPY3]}
var angry_sounds = {"index": 0, "sounds": [MusicAndSfxHandler.sounds.SENSEI_ANGRY1, MusicAndSfxHandler.sounds.SENSEI_ANGRY2, MusicAndSfxHandler.sounds.SENSEI_ANGRY3]}
var neutral_sounds = {"index": 0, "sounds": [MusicAndSfxHandler.sounds.SENSEI_NEUTRAL1, MusicAndSfxHandler.sounds.SENSEI_NEUTRAL2, MusicAndSfxHandler.sounds.SENSEI_NEUTRAL3, MusicAndSfxHandler.sounds.SENSEI_NEUTRAL4, MusicAndSfxHandler.sounds.SENSEI_NEUTRAL5, MusicAndSfxHandler.sounds.SENSEI_NEUTRAL6]}


onready var dialog: Array = [
	{
		"text": "Welcome " + SteamValues.STEAM_USERNAME + " to my Dojo!",
		"time_until_next_message": 0.1,
		"sounds": greeting_sounds,
		"run_func": "how_to_play_popup",
	},
	{
		"text": "",
		"time_until_next_message": 0.5,
		"run_func": "wait_for_elmt_select",
		"sounds": neutral_sounds
	},
	{
		"text": "",
		"time_until_next_message": 0.5,
		"run_func": "wait_for_cast",
		"sounds": neutral_sounds
	},
	{
		"text": "Good!",
		"time_until_next_message": 1.4,
		"sounds": happy_sounds
	},
	{
		"text": "There are 5 elements...",
		"time_until_next_message": 2,
		"sounds": neutral_sounds
	}, 
	{
		"text": "Fire...",
		"time_until_next_message": 0.8,
		"sounds": neutral_sounds
	},
	{
		"text": "Water...",
		"time_until_next_message": 0.8,
		"sounds": neutral_sounds
	},
		{
		"text": "Earth...",
		"time_until_next_message": 0.8,
		"sounds": neutral_sounds
	},
	{
		"text": "Arcane...",
		"time_until_next_message": 0.8,
		"sounds": neutral_sounds
	},
	{
		"text": "and Goo!",
		"time_until_next_message": 2,
		"sounds": neutral_sounds
	},
	{
		"text": "With these elements you can create many unique spells!",
		"time_until_next_message": 2.5,
		"sounds": happy_sounds
	}, 
	{
		"text": "See the dummy on the other side of the dojo? Destroy it.",
		"time_until_next_message": 0.5,
		"run_func": "kill_first",
		"sounds": neutral_sounds
	},
	{
		"text": "Excellent work, now come with me north.",
		"time_until_next_message": 1,
		"run_func": "second_island",
		"sounds": happy_sounds
	},
	{
		"text": "Now, try destroy that dummy on the small island to the left.",
		"time_until_next_message": 0.5,
		"run_func": "kill_second",
		"sounds": neutral_sounds
	},
	{
		"text": "Good. Follow me.",
		"time_until_next_message": 1,
		"run_func": "third_island",
		"sounds": happy_sounds
	},
	{
		"text": "Here I want you to find and move the dummy into this red circle.",
		"time_until_next_message": 3.5,
		"run_func": "round_up",
		"sounds": neutral_sounds,
	},
	{
		"text": "Now, let me fly you to your final challenge. Hang on!",
		"time_until_next_message": 1,
		"run_func": "forth_island",
		"sounds": neutral_sounds,
	},
	{
		"text": "Here you will be able to test your new skills against other fishards.",
		"time_until_next_message": 4.5,
		"sounds": neutral_sounds,
	},
	{
		"text": "HOWEVER! You are only allowed to use 3 elements...",
		"time_until_next_message": 4,
		"sounds": angry_sounds,
	},
	{
		"text": "You can change your available elements by pressing the ESC key.",
		"time_until_next_message": 2,
		"run_func": "wait_for_esc",
		"sounds": neutral_sounds,
	},
	{
		"text": "Let's see if you can complete all " + str(levels.size()) + " levels. Good luck!",
		"time_until_next_message": 2,
		"run_func": "start_final_challenge",
		"sounds": neutral_sounds,
	},
]


var levels = [
	{"text": "", "bots": [Globals.PlayerTypes.EASY_BOT]},
	{"text": "", "bots": [Globals.PlayerTypes.EASY_BOT]},
	{"text": "", "bots": [Globals.PlayerTypes.EASY_BOT, Globals.PlayerTypes.EASY_BOT]},
	{"text": "", "bots": [Globals.PlayerTypes.MEDIUM_BOT, Globals.PlayerTypes.EASY_BOT]},
	{"text": "", "bots": [Globals.PlayerTypes.HARD_BOT, Globals.PlayerTypes.EASY_BOT]},
]


func how_to_play_popup(time) -> void:
	yield(get_tree().create_timer(4), "timeout")
	howToPlayPopup.set_visible(true)
	yield(self, "how_to_play_closed")
	dialog_timer.start(time)


func wait_for_elmt_select(time) -> void:
	var print_this: String = "Select two elements with these keys: " + get_element_keys()
	
	#spellHUDTip.set_visible(true)
	show_objective(print_this, [], 1)
	yield(self, "elements_pressed")
	yield(get_tree().create_timer(1), "timeout")
	dialog_timer.start(time)
	hide_objective()


func get_element_keys() -> String:
	var element_keys: String = ""
	for num in RoomSettings.get_element_amount():
		var key_code = Util.get_key_code("element_" + str(num + 1), Util.InputTypes.KEYBOARD)
		element_keys += OS.get_scancode_string(key_code)
		if num < RoomSettings.get_element_amount() - 1:
			element_keys += ", "
	
	return element_keys


func wait_for_cast(time) -> void:
	show_objective("Hold down the left mouse button to cast a spell.", [], 1.5)
	yield(self, "cast_spell_pressed")
	dialog_timer.start(time)
	#spellHUDTip.set_visible(false)
	hide_objective()


func kill_first(time) -> void: 
	var used_spells: Array = []
	var spell_tip = [
		{"element1": Globals.Elements.FIRE, "element2": Globals.Elements.FIRE, "spell": Globals.SpellTypes.FIREBALL}, 
		{"element1": Globals.Elements.EARTH, "element2": Globals.Elements.FIRE, "spell": Globals.SpellTypes.METEOR},
		{"element1": Globals.Elements.EARTH, "element2": Globals.Elements.EARTH, "spell": Globals.SpellTypes.DASH},
		{"element1": Globals.Elements.ARCANE, "element2": Globals.Elements.GOO, "spell": Globals.SpellTypes.DASH_BEAM},
	]
	
	show_objective("Destroy the dummy.", spell_tip)
	
	while used_spells.size() < 3:
		yield(get_tree().create_timer(0.5), "timeout")
		var id: int = spawn_dojo_dummy()
		var room_node = Util.get_room_node()
		if room_node != null:
			var dummy = room_node.get_entity(id)
			yield(dummy, "no_health")
			room_node = Util.get_room_node()
			if room_node != null:
				var my_client: Entity = room_node.get_entity(SteamValues.STEAM_ID)
				if my_client != null:
					var active_spell: int = my_client.get_component_of_type(Globals.ComponentTypes.SpellCaster).active_spell
					if active_spell == Globals.SpellTypes.NONE:
						active_spell = my_client.get_component_of_type(Globals.ComponentTypes.SpellCaster).get_prev_spell()
					if used_spells.has(active_spell) == false:
						used_spells.append(active_spell)
						
						# Remove "try this" spell if we used it
						for tip_obj in spell_tip:
							if active_spell == tip_obj["spell"]:
								spell_tip.remove(spell_tip.find(tip_obj))
						
						if used_spells.size() == 1:
							sensei_message("Good! Now I want to you to destroy this dummy with a different spell.", happy_sounds)
						elif used_spells.size() == 2:
							sensei_message("Nice. Destroy the dummy one last time with yet a new spell.", happy_sounds)
						hide_objective()
						show_objective("Destroy the dummy with a different spell.", spell_tip, 1)
					else:
						sensei_message("No, you need to use a spell you haven't used previously! Try again.", angry_sounds)
	
	dialog_timer.start(time)
	hide_objective()


func spawn_dojo_dummy() -> int:
	var id: int = Util.generate_id()
	var pos = $Dummy1Pos.global_transform.origin
	var dummy_info: Dictionary = Globals.EnvironmentInfo(Globals.EnvironmentTypes.DUMMY, 0, pos)
	PacketSender.spawn_environment(id, dummy_info)
	return id


func second_island(time) -> void:
	yield(get_tree().create_timer(3), "timeout")
	sensei_animator.play("first_travel")
	arrow.set_visible(true)
	arrowPoof.emitting = true
	get_node(island_2_animator).play("rise")
	yield(self, "island_2_reached")
	avoid_barrier_challenge = true
	get_node(spawn_area).get_child(0).transform.origin = get_node(spawn_point_2).global_transform.origin
	dialog_timer.start(time)
	hide_objective()


func kill_second(time) -> void: 
	var spell_tip = [
		{"element1": Globals.Elements.FIRE, "element2": Globals.Elements.EARTH, "spell": Globals.SpellTypes.METEOR}, 
		{"element1": Globals.Elements.WATER, "element2": Globals.Elements.EARTH, "spell": Globals.SpellTypes.DIVE}
	]
	show_objective("Destroy the dummy on the small island to the left.", spell_tip)
	var pos = get_node(dummy_pos_2).global_transform.origin
	var dummy_info: Dictionary = Globals.EnvironmentInfo(Globals.EnvironmentTypes.DUMMY, 0, pos)
	var id: int = Util.generate_id()
	PacketSender.spawn_environment(id, dummy_info)
	var room_node = Util.get_room_node()
	if room_node != null:
		var dummy = room_node.get_entity(id)
		yield(dummy, "no_health")
		avoid_barrier_challenge = false
	
	dialog_timer.start(time)
	hide_objective()


func third_island(time) -> void:
	sensei_animator.play("second_travel")
	get_node(island_3_animator).play("rise")
	yield(get_tree().create_timer(2), "timeout")
	sensei_message("Hmm, looks like the bridge has collapsed. Use a mobility spell to get to the other side - try earth + earth or earth + arcane", neutral_sounds)
	parkour_challenge = true
	yield(self, "island_3_reached")
	parkour_challenge = false
	get_node(spawn_area).get_child(0).transform.origin = get_node(spawn_point_3).global_transform.origin
	dialog_timer.start(time)
	hide_objective()


func round_up(time) -> void:
	var spell_tip = [
		{"element1": Globals.Elements.FIRE, "element2": Globals.Elements.WATER, "spell": Globals.SpellTypes.PUSH}, 
		{"element1": Globals.Elements.GOO, "element2": Globals.Elements.GOO, "spell": Globals.SpellTypes.GRAB}
	]
	show_objective("Move the dummy to the red circle.", spell_tip)
	create_round_up_dummy()
	yield(self, "dummy_entered")
	dialog_timer.start(time)
	hide_objective()


func create_round_up_dummy() -> void:
	var pos = get_node(dummy_pos_3).global_transform.origin
	var dummy_info: Dictionary = Globals.EnvironmentInfo(Globals.EnvironmentTypes.STRONG_DUMMY, 0, pos)
	var id: int = Util.generate_id()
	PacketSender.spawn_environment(id, dummy_info)
	round_up_dummy_id = id


func create_training_dummy() -> void:
	yield(get_tree().create_timer(0.6), "timeout")
	var pos = get_node(training_dummy_pos).global_transform.origin
	var dummy_info: Dictionary = Globals.EnvironmentInfo(Globals.EnvironmentTypes.STRONG_DUMMY, 0, pos)
	var id: int = Util.generate_id()
	PacketSender.spawn_environment(id, dummy_info)
	training_dummy_id = id


func forth_island(time) -> void:
	sensei_animator.play("third_travel")
	_lerp_with_sensei = true
	var room_node = Util.get_room_node()
	if room_node != null:
		var my_client: Entity = room_node.get_entity(SteamValues.STEAM_ID)
		if my_client != null:
			my_client.get_component_of_type(Globals.ComponentTypes.Health).set_invincible(true)
			my_client.set_trapped_w_duration(7.5, true)
		
	yield(self, "island_4_reached")
	arrive_at_fourth_island()
	change_spawn_to_island_4()
	dialog_timer.start(time)


func arrive_at_fourth_island() -> void:
	_lerp_with_sensei = false
	_lerp_to_island_4_pos = true
	RoomSettings.edit_settings({"elmts": 3}, false, false)
	var room_node = Util.get_room_node()
	if room_node != null:
		var my_client = room_node.get_entity(SteamValues.STEAM_ID)
		if my_client != null:
			my_client.get_component_of_type(Globals.ComponentTypes.Health).set_invincible(false)


func change_spawn_to_island_4() -> void:
	get_node(spawn_area).get_child(0).queue_free()
	get_node(spawn_area).global_transform.origin = get_node(spawn_area_4_spatial).global_transform.origin
	for spawn_shape_path in island_4_spawn_shapes:
		Util.reparent_node(get_node(spawn_shape_path), get_node(spawn_area))


func wait_for_esc(time) -> void:
	show_objective("Press ESC, drag the arrows and press update.")
	yield(self, "updated_elements")
	dialog_timer.start(time)
	hide_objective()


func start_final_challenge(time) -> void: 
	clear_temp_bots()
	
	_tutorial_final_challenge = true
	_level = 0
	_new_round()


func _ready():
	howToPlayPopup.set_visible(false)
	arrow.set_visible(false)
	objectiveContainer.set_visible(false)
	instructionsLabel.text = ""
	
	var room = Util.get_room_node()
	if room != null:
		gamemode_node = room.gamemode
	
	Lobby.connect("lobby_chat", self, "_on_lobby_chat")
	Lobby.connect("player_killed", self, "_on_player_killed")
	Lobby.connect("destroy_entity", self, "_on_entity_destroyed")
	
	if RoomSettings.get_rounds_gamemode() == GamemodeValues.Gamemodes.Training:
		start_training()
	else:
		yield(get_tree().create_timer(2), "timeout")
		next_dialog()


func start_training() -> void:
	levels = Util.generate_temp_bot_levels(difficulty_curve, 1.0, false)
	
	change_spawn_to_island_4()
	sensei_animator.play("third_travel")
	sensei_animator.set_speed_scale(10)
	yield(get_tree().create_timer(1), "timeout")
	sensei_message("Welcome to Training Island!", greeting_sounds)
	yield(get_tree().create_timer(2), "timeout")
	if _dummy_mode == true:
		return 
	sensei_message("Type '/dummy' by pressing 'T' to toggle training against dummies.", neutral_sounds)
	yield(get_tree().create_timer(3.5), "timeout")
	if _dummy_mode == true:
		return 
	sensei_message("Try to survive as long as possible, good luck!", neutral_sounds)
	start_final_challenge(0)


func _process(delta):
	if _lerp_to_island_4_pos == true:
		var room_node = Util.get_room_node()
		if room_node != null:
			var my_client = room_node.get_entity(SteamValues.STEAM_ID)
			if my_client != null:
				my_client.set_position(my_client.global_transform.origin.linear_interpolate(get_node(island_4_player_pos).global_transform.origin, delta * 3))
				if my_client.get_pos().distance_to(get_node(island_4_player_pos).global_transform.origin) < 0.2:
					_lerp_to_island_4_pos = false
					my_client.set_position(get_node(island_4_player_pos).global_transform.origin, true)
	
	if _lerp_with_sensei == true:
		var room_node = Util.get_room_node()
		if room_node != null:
			var my_client = room_node.get_entity(SteamValues.STEAM_ID)
			if my_client != null:
				my_client.set_position(my_client.global_transform.origin.linear_interpolate(get_node("Sensei").global_transform.origin, delta * 2))


func _on_dummy_1_death() -> void:
	emit_signal("first_dummy_killed")


func _input(event):
	for num in RoomSettings.get_element_amount():
		if event.is_action_pressed("element_" + str(num + 1)):
			emit_signal("elements_pressed")
	
	if event.is_action_pressed("cast_spell"):
		emit_signal("cast_spell_pressed")


func _on_lobby_chat(_sender: String, message: String) -> void:
	if message.begins_with("/dummy") && RoomSettings.get_gamemode() == GamemodeValues.Gamemodes.Training:
		_dummy_mode = !_dummy_mode
		if _dummy_mode == true:
			clear_temp_bots()
			create_training_dummy()
		else:
			if training_dummy_id != 0:
				PacketSender.host_broadcast_destroy_entity(training_dummy_id)
			start_final_challenge(0)


func _on_player_killed(killed_id, killer_id, killed_with_spell):
	if killed_id == SteamValues.STEAM_ID:
		emit_signal("updated_elements")
		
		if avoid_barrier_challenge == true:
			sensei_message("Oops. Try teleporting with water + earth (2 + 3) or by casting a meteor with fire + earth (1 + 3)", angry_sounds)
		
		if parkour_challenge == true:
			sensei_message("Try using earth + earth (3 + 3) or earth + arcane (3 + 4)", angry_sounds)
		
		if _tutorial_final_challenge == true && _dummy_mode == false: 
			if RoomSettings.get_gamemode() == GamemodeValues.Gamemodes.Training:
				restart_training_endless()
			else:
				restart_tutorial_challenge()
	
	# Update amount of enemies
	var team: Dictionary = Lobby.get_team_info_from_player_id(killed_id)
	if team.empty() == false:
		if team.name == "Red Team":
			_alive_enemy_players -= 1
			if _alive_enemy_players <= 0:
				_new_round()
			
			yield(get_tree().create_timer(0.5), "timeout")
			PacketSender.host_broadcast_destroy_entity(killed_id)


func restart_training_endless() -> void:
	var message: String = "You made it to level " + str(_level) + ". "
	var personal_best_obj: Dictionary = UserSettings.save_pb_training_time(_level)
	
	if personal_best_obj["highscore"] == true:
		message += "That's a new high score!"
	else:
		message += "Your high score is level " + str(personal_best_obj["pb"]) + "."
	
	gamemode_node.reset_difficulty()
	clear_temp_bots()
	sensei_message(message, happy_sounds)
	yield(get_tree().create_timer(4), "timeout")
	
	sensei_message("Restarting the challenge, get ready...", neutral_sounds)
	yield(get_tree().create_timer(2), "timeout")
	start_final_challenge(0)


func restart_tutorial_challenge() -> void:
	sensei_message("You failed, restarting level " + str(_level) + "...", angry_sounds)
	clear_temp_bots()
	gamemode_node.reset_difficulty()
	yield(get_tree().create_timer(3), "timeout")
	_level -= 1
	# Delete any bots that spawned whilst we were waiting
	clear_temp_bots()
	_new_round()


func clear_temp_bots() -> void:
	var remove_ids = []
	for player_info in Lobby._temp_bot_members:
		remove_ids.append(player_info["id"])
	
	for id in remove_ids:
		PacketSender.host_broadcast_destroy_entity(id)


func _new_round() -> void:
	if _dummy_mode == false:
		_level += 1
		
		var gamemode = RoomSettings.get_rounds_gamemode()
		
		if _level <= levels.size():
			var level_time = 3 if gamemode == GamemodeValues.Gamemodes.Tutorial else 1
			
			_alive_enemy_players = levels[_level - 1]["bots"].size()
			
			gamemode_node.inc_difficulty()
			
			var level_text = levels[_level - 1]["text"]
			if level_text != "":
				gamemode_node.call_deferred("show_text_center_screen", "Boss: " + level_text, 3, false)
				MusicAndSfxHandler.play_sound(MusicAndSfxHandler.sounds.SENSEI_ANGRY3)
			else:
				gamemode_node.call_deferred("show_text_center_screen", "Level " + str(_level), level_time)
				MusicAndSfxHandler.play_sound(MusicAndSfxHandler.sounds.COUNT_DOWN)
			
			levelTimer.start(level_time)
		else:
			if gamemode == GamemodeValues.Gamemodes.Training:
				sensei_message("What? You actually made it this far?? Impossible, are you hacking???", angry_sounds)
				pass
			else:
				MusicAndSfxHandler.play_sound(MusicAndSfxHandler.sounds.COUNT_DOWN)
				gamemode_node.call_deferred("show_text_center_screen", "Tutorial complete!", 4)
				
				sensei_message("Congratulations! You won all the levels.", happy_sounds)
				yield(get_tree().create_timer(5), "timeout")
				sensei_message("You are ready to play against real players now!", neutral_sounds)
				yield(get_tree().create_timer(4), "timeout")
				sensei_message("I'm sending you back to the main menu now, bye bye!", neutral_sounds)
				yield(get_tree().create_timer(3), "timeout")
				Lobby.leave_lobby()


func _on_level_timer_timeout() -> void:
	var players_node = Util.get_players_node()
	if players_node != null:
		for bot_type in levels[_level - 1]["bots"]:
			players_node.host_spawn_temp_bot("Wizishes", bot_type)
	
	gamemode_node.update_amount_of_alive_players()


func next_dialog() -> void:
	if dialog_index < dialog.size():
		var dialog_info = dialog[dialog_index]
		dialog_index += 1
		
		var text = dialog_info["text"]
		if text != "":
			sensei_message(text, dialog_info["sounds"])
		
		if dialog_info.has("run_func"):
			call(dialog_info["run_func"], dialog_info["time_until_next_message"])
		else:
			dialog_timer.start(dialog_info["time_until_next_message"])


func sensei_message(message: String, sounds_dict: Dictionary) -> void:
	Lobby.emit_signal("lobby_chat", "Sensei", message)
	# Loop through all the sounds 
	sounds_dict["index"] += 1
	if sounds_dict["index"] >= sounds_dict["sounds"].size():
		sounds_dict["index"] = 0
	MusicAndSfxHandler.play_sound(sounds_dict["sounds"][sounds_dict["index"]])


func show_objective(text: String, spell_tips: Array = [], time_until_show: float = 3.0) -> void:
	objective_shown = true
	yield(get_tree().create_timer(time_until_show), "timeout")
	if objective_shown == true:
		for child in comboTipContainer.get_children():
			child.queue_free()
		
		objectiveAnim.play("show")
		if spell_tips.empty() == false:
			spellTipLabel.set_visible(true)
			comboTipContainer.set_visible(true)
			for spell_tip in spell_tips:
				var combo_tip = comboContainer.instance()
				comboTipContainer.add_child(combo_tip)
				combo_tip.set_values(spell_tip["element1"], spell_tip["element2"], spell_tip["spell"])
		else:
			spellTipLabel.set_visible(false)
			comboTipContainer.set_visible(false)
		
		yield(get_tree(), "idle_frame")
		MusicAndSfxHandler.play_sound(MusicAndSfxHandler.sounds.ELEMENT_PICKUP)
		objectiveContainer.set_visible(true)
		instructionsLabel.text = text
		yield(get_tree(), "idle_frame")
		objectiveContainer.rect_size = objectiveContainer.get_minimum_size()


func hide_objective() -> void:
	objective_shown = false
	objectiveContainer.set_visible(false)


func first_next_how_to_play() -> void:
	howToPlayFirstPart.set_visible(false)
	howToPlaySecondPart.set_visible(true)


func go_back_1() -> void:
	howToPlayFirstPart.set_visible(true)
	howToPlaySecondPart.set_visible(false)


func second_next_how_to_play() -> void:
	howToPlaySecondPart.set_visible(false)
	howToPlayThirdPart.set_visible(true)


func go_back_2() -> void:
	howToPlaySecondPart.set_visible(true)
	howToPlayThirdPart.set_visible(false)


func close_how_to_play_popup() -> void:
	howToPlayPopup.set_visible(false)
	emit_signal("how_to_play_closed")


func _on_dialog_timer_timeout():
	next_dialog()


func _on_ReachedIsland2Area_entered(area):
	var entity: Entity = Util.get_entity_from_area(area)
	if entity != null:
		if entity.is_my_client == true:
			emit_signal("island_2_reached")


func _on_ReachedIsland3Area_area_entered(area):
	var entity: Entity = Util.get_entity_from_area(area)
	if entity != null:
		if entity.is_my_client == true:
			emit_signal("island_3_reached")


func _on_DummyArea_entered(area):
	var entity: Entity = Util.get_entity_from_area(area)
	if entity != null:
		if entity.get_id() == round_up_dummy_id:
			sensei_message("Well done!", happy_sounds)
			emit_signal("dummy_entered")


func _on_entity_destroyed(entity_id: int):
	if entity_id == training_dummy_id && _dummy_mode == true:
		create_training_dummy()
	
	if entity_id == round_up_dummy_id:
		fail_amount += 1
		if fail_amount == 1:
			sensei_message("No, don't destroy it, move it to the circle!", angry_sounds)
			create_round_up_dummy()
		elif fail_amount == 2:
			sensei_message("Oops, you destroyed it again... Try using water + fire or goo + goo.", angry_sounds)
			create_round_up_dummy()
		elif fail_amount == 3:
			sensei_message("OK, this isn't working, let's move on...", angry_sounds)
			emit_signal("dummy_entered")


func _on_ReachedIsland4Area_entered(area):
	var entity: Entity = Util.get_entity_from_area(area)
	if entity != null:
		if entity.is_my_client == true:
			emit_signal("island_4_reached")
