extends Node


var achievements_data_path: String = "achievement_data"
var UNLOCKED_HATS_PATH: String = "unlocked_hats"


var achievements: Dictionary = {
	ACH_COMPLETE_10_KILLS = "ACH_COMPLETE_10_KILLS",
	ACH_COMPLETE_50_KILLS = "ACH_COMPLETE_50_KILLS",
	ACH_COMPLETE_100_KILLS = "ACH_COMPLETE_100_KILLS",
	ACH_COMPLETE_500_KILLS = "ACH_COMPLETE_500_KILLS",
	ACH_COMPLETE_1000_KILLS = "ACH_COMPLETE_1000_KILLS",
	ACH_COMPLETE_1500_KILLS = "ACH_COMPLETE_1500_KILLS",
	ACH_COMPLETE_2000_KILLS = "ACH_COMPLETE_2000_KILLS",
	ACH_COMPLETE_WIN_50_ROUNDS_TWO_ELEMENTS = "ACH_COMPLETE_WIN_50_ROUNDS_TWO_ELEMENTS",
	ACH_COMPLETE_WIN_50_ROUNDS_FOUR_ELEMENTS = "ACH_COMPLETE_WIN_50_ROUNDS_FOUR_ELEMENTS",
	ACH_COMPLETE_WIN_50_ROUNDS_FIVE_ELEMENTS = "ACH_COMPLETE_WIN_50_ROUNDS_FIVE_ELEMENTS",
	ACH_COMPLETE_WIN_50_ROUNDS_RANDOM_TIME = "ACH_COMPLETE_WIN_50_ROUNDS_RANDOM_TIME",
	ACH_COMPLETE_WIN_50_ROUNDS_RANDOM_SAME = "ACH_COMPLETE_WIN_50_ROUNDS_RANDOM_SAME",
	ACH_COMPLETE_WIN_10_ROUNDS = "ACH_COMPLETE_WIN_10_ROUNDS",
	ACH_COMPLETE_WIN_50_ROUNDS = "ACH_COMPLETE_WIN_50_ROUNDS",
	ACH_COMPLETE_WIN_100_ROUNDS = "ACH_COMPLETE_WIN_100_ROUNDS",
	ACH_COMPLETE_WIN_1000_ROUNDS = "ACH_COMPLETE_WIN_1000_ROUNDS",
	ACH_COMPLETE_100_WINS_CLASSIC = "ACH_COMPLETE_100_WINS_CLASSIC",
	ACH_COMPLETE_100_WINS_BRAWLINBOB = "ACH_COMPLETE_100_WINS_BRAWLINBOB",
	ACH_COMPLETE_100_WINS_CAMPINGCARL = "ACH_COMPLETE_100_WINS_CAMPINGCARL",
	ACH_COMPLETE_100_WINS_FRANZFLAMEWAFFE = "ACH_COMPLETE_100_WINS_FRANZFLAMEWAFFE",
	ACH_COMPLETE_100_WINS_HIDINGHARRY = "ACH_COMPLETE_100_WINS_HIDINGHARRY",
	ACH_COMPLETE_100_WINS_HUNTINGHENRY = "ACH_COMPLETE_100_WINS_HUNTINGHENRY",
	ACH_COMPLETE_100_WINS_BABYFRESH = "ACH_COMPLETE_100_WINS_BABYFRESH",
	ACH_COMPLETE_100_WINS_SKILLSHOTSIMON = "ACH_COMPLETE_100_WINS_SKILLSHOTSIMON",
	ACH_COMPLETE_100_WINS_SLIPPERYSAM = "ACH_COMPLETE_100_WINS_SLIPPERYSAM",
	ACH_COMPLETE_100_WINS_SNIPINGSNYDER = "ACH_COMPLETE_100_WINS_SNIPINGSNYDER",
	ACH_GRAB_100_ENEMIES = "ACH_GRAB_100_ENEMIES",
	ACH_REFLECT_100_PROJECTILES = "ACH_REFLECT_100_PROJECTILES",
	ACH_PUSH_100_ENEMIES = "ACH_PUSH_100_ENEMIES",
}


onready var achievementHats = {
	achievements.ACH_COMPLETE_10_KILLS: CustomizePlayer.HatTypes.FEZ,
	achievements.ACH_COMPLETE_50_KILLS: CustomizePlayer.HatTypes.WINTER,
	achievements.ACH_COMPLETE_100_KILLS: CustomizePlayer.HatTypes.BEANIE,
	achievements.ACH_COMPLETE_500_KILLS: CustomizePlayer.HatTypes.COOL,
	achievements.ACH_COMPLETE_1000_KILLS: CustomizePlayer.HatTypes.VIKING,
	achievements.ACH_COMPLETE_1500_KILLS: CustomizePlayer.HatTypes.HALO,
	achievements.ACH_COMPLETE_2000_KILLS: CustomizePlayer.HatTypes.CANNON,
	achievements.ACH_COMPLETE_WIN_50_ROUNDS_TWO_ELEMENTS: CustomizePlayer.HatTypes.RHINO,
	achievements.ACH_COMPLETE_WIN_50_ROUNDS_FOUR_ELEMENTS: CustomizePlayer.HatTypes.GOAT,
	achievements.ACH_COMPLETE_WIN_50_ROUNDS_FIVE_ELEMENTS: CustomizePlayer.HatTypes.SPIKY_HORNS,
	achievements.ACH_COMPLETE_WIN_50_ROUNDS_RANDOM_TIME: CustomizePlayer.HatTypes.PIRATE,
	achievements.ACH_COMPLETE_WIN_50_ROUNDS_RANDOM_SAME: CustomizePlayer.HatTypes.ANGRY_BROWS,
	achievements.ACH_COMPLETE_WIN_10_ROUNDS: CustomizePlayer.HatTypes.TOPHAT,
	achievements.ACH_COMPLETE_WIN_50_ROUNDS: CustomizePlayer.HatTypes.SUNGLASSES,
	achievements.ACH_COMPLETE_WIN_100_ROUNDS: CustomizePlayer.HatTypes.FEDORA,
	achievements.ACH_COMPLETE_WIN_1000_ROUNDS: CustomizePlayer.HatTypes.FROG,
	achievements.ACH_COMPLETE_100_WINS_HUNTINGHENRY: CustomizePlayer.HatTypes.SAFARI,
	achievements.ACH_COMPLETE_100_WINS_SLIPPERYSAM: CustomizePlayer.HatTypes.SNORKLE,
	achievements.ACH_COMPLETE_100_WINS_SNIPINGSNYDER: CustomizePlayer.HatTypes.GOGGLES,
	achievements.ACH_COMPLETE_100_WINS_BRAWLINBOB: CustomizePlayer.HatTypes.PLAGUE_DOCTOR,
	achievements.ACH_COMPLETE_100_WINS_CLASSIC: CustomizePlayer.HatTypes.KNIGHT,
	achievements.ACH_COMPLETE_100_WINS_FRANZFLAMEWAFFE: CustomizePlayer.HatTypes.MOHAWK,
	achievements.ACH_COMPLETE_100_WINS_BABYFRESH: CustomizePlayer.HatTypes.COOL_COLOURED,
	achievements.ACH_COMPLETE_100_WINS_CAMPINGCARL: CustomizePlayer.HatTypes.HEART_BOBBERS,
	achievements.ACH_COMPLETE_100_WINS_HIDINGHARRY: CustomizePlayer.HatTypes.DISGUISE,
	achievements.ACH_COMPLETE_100_WINS_SKILLSHOTSIMON: CustomizePlayer.HatTypes.EYE,
	achievements.ACH_GRAB_100_ENEMIES: CustomizePlayer.HatTypes.GOO,
	achievements.ACH_PUSH_100_ENEMIES: CustomizePlayer.HatTypes.WIND,
	achievements.ACH_REFLECT_100_PROJECTILES: CustomizePlayer.HatTypes.WALL,
}


enum classes {
	CLASSIC,
	BOB,
	CARL,
	FRANZ,
	HARRY,
	HENRY,
	BABYFRESH,
	SIMON,
	SAM,
	SNYDER,
}


const classes_info: Dictionary = {
	classes.CLASSIC: {"ach_name": "ACH_COMPLETE_100_WINS_CLASSIC", "name": "Classic Fishard", "elements": [Globals.Elements.FIRE, Globals.Elements.WATER, Globals.Elements.EARTH]},
	classes.BOB: {"ach_name": "ACH_COMPLETE_100_WINS_BRAWLINBOB", "name": "Brawlin' Bob", "elements": [Globals.Elements.FIRE, Globals.Elements.EARTH, Globals.Elements.GOO]},
	classes.CARL: {"ach_name": "ACH_COMPLETE_100_WINS_CAMPINGCARL", "name": "Camping Carl", "elements": [Globals.Elements.WATER, Globals.Elements.EARTH, Globals.Elements.GOO]},
	classes.FRANZ: {"ach_name": "ACH_COMPLETE_100_WINS_FRANZFLAMEWAFFE", "name": "Franz Flammenwerfer", "elements": [Globals.Elements.FIRE, Globals.Elements.ARCANE, Globals.Elements.GOO]},
	classes.HARRY: {"ach_name": "ACH_COMPLETE_100_WINS_HIDINGHARRY", "name": "Hidin' Harry", "elements": [Globals.Elements.EARTH, Globals.Elements.ARCANE, Globals.Elements.GOO]},
	classes.HENRY: {"ach_name": "ACH_COMPLETE_100_WINS_HUNTINGHENRY", "name": "Huntin' Henry", "elements": [Globals.Elements.FIRE, Globals.Elements.EARTH, Globals.Elements.ARCANE]},
	classes.BABYFRESH: {"ach_name": "ACH_COMPLETE_100_WINS_BABYFRESH", "name": "Baby Fancy", "elements": [Globals.Elements.FIRE, Globals.Elements.WATER, Globals.Elements.GOO]},
	classes.SIMON: {"ach_name": "ACH_COMPLETE_100_WINS_SKILLSHOTSIMON", "name": "Skillshot Simon", "elements": [Globals.Elements.FIRE, Globals.Elements.WATER, Globals.Elements.ARCANE]},
	classes.SAM: {"ach_name": "ACH_COMPLETE_100_WINS_SLIPPERYSAM", "name": "Slippery Sam", "elements": [Globals.Elements.WATER, Globals.Elements.EARTH, Globals.Elements.ARCANE]},
	classes.SNYDER: {"ach_name": "ACH_COMPLETE_100_WINS_SNIPINGSNYDER", "name": "Sniping Snyder", "elements": [Globals.Elements.WATER, Globals.Elements.ARCANE, Globals.Elements.GOO]},
}


onready var _default_achievement_data: Dictionary = {
	"kills": 0,
	"class_kills": {
		classes.CLASSIC: 0,
		classes.BOB: 0,
		classes.CARL: 0,
		classes.FRANZ: 0,
		classes.HARRY: 0,
		classes.HENRY: 0,
		classes.BABYFRESH: 0,
		classes.SIMON: 0,
		classes.SAM: 0,
		classes.SNYDER: 0,
	},
	"rounds_won_online": 0,
	"class_rounds_won_online": {
		classes.CLASSIC: 0,
		classes.BOB: 0,
		classes.CARL: 0,
		classes.FRANZ: 0,
		classes.HARRY: 0,
		classes.HENRY: 0,
		classes.BABYFRESH: 0,
		classes.SIMON: 0,
		classes.SAM: 0,
		classes.SNYDER: 0,
	},
	"element_available_rounds_won": {
		2: 0,
		4: 0,
		5: 0
	},
	"element_mode_rounds_won": {
		Globals.ElementModes.RANDOM: 0,
		Globals.ElementModes.TIMED: 0,
	},
	"grabs": 0,
	"reflects": 0,
	"pushes": 0,
}


var achievements_data_dict: Dictionary = {}
var steam_achievements: Dictionary = {}


var _new_cosmetic: Array = []
var _showed_popup_falsely_achieved: bool = false
var _falsely_achieved_achievement: bool = false

var round_aim_movement: float
var prev_joy_dir: Vector2
var round_classes_used: Dictionary
var round_length_time: float
var current_class: int


signal round_won(is_winner)
signal fetched_achievements()
signal achievements_data_dict_updated(data)


func get_is_new_cosmetic() -> bool:
	return _new_cosmetic.size() != 0


func get_new_cosmetics() -> Array:
	return _new_cosmetic


func cosmetic_isnt_new(hat_id: int) -> void:
	var remove_at = _new_cosmetic.find(hat_id)
	if remove_at != -1:
		_new_cosmetic.remove(remove_at)


func set_new_cosmetic(hat_id: int) -> void:
	if _new_cosmetic.find(hat_id) == -1:
		_new_cosmetic.append(hat_id) 


func get_rank() -> int:
	var rank = 0
	for ach_name in steam_achievements:
		if steam_achievements[ach_name] == true:
			rank += 1
	
	return rank


func get_max_rank() -> int:
	return steam_achievements.size()


func inc_grabs() -> void:
	achievements_data_dict["grabs"] = achievements_data_dict["grabs"] + 1 
	save_achievement_data(achievements_data_dict)
	check_spell_achievement(achievements_data_dict["grabs"], achievements.ACH_GRAB_100_ENEMIES)


func inc_reflects() -> void:
	achievements_data_dict["reflects"] = achievements_data_dict["reflects"] + 1 
	save_achievement_data(achievements_data_dict)
	check_spell_achievement(achievements_data_dict["reflects"], achievements.ACH_REFLECT_100_PROJECTILES)


func inc_pushes() -> void:
	achievements_data_dict["pushes"] = achievements_data_dict["pushes"] + 1 
	save_achievement_data(achievements_data_dict)
	check_spell_achievement(achievements_data_dict["pushes"], achievements.ACH_PUSH_100_ENEMIES)


func _ready():
	connect("round_won", self, "_on_round_won")
	Lobby.connect("player_killed", self, "_on_kill")
	Lobby.connect("lobby_members_updated", self, "_on_lobby_members_updated")
	Steam.connect("current_stats_received", self, "_on_steam_stats_received")
	
	load_achievement_data()
	
	
	_on_steam_stats_received(0,0,0) # So that single player doesnt crash


# Track aiming since its a good metric for how active a player is 
func _input(event):
	if Input.is_key_pressed(KEY_C) && Globals.get_app_mode() == Globals.AppModes.DEVELOPMENT:
		for ach_name in steam_achievements:
			steam_achievements[ach_name] = true
			store_achievement(ach_name)
		emit_signal("fetched_achievements")

	
	if event is InputEventMouseMotion:
		round_aim_movement += event.relative.normalized().length_squared()
	
	var dir: Vector2
	dir.x = Input.get_action_strength("joy_right_right") - Input.get_action_strength("joy_right_left")
	dir.y = Input.get_action_strength("joy_right_down") - Input.get_action_strength("joy_right_up")
	if dir != Vector2.ZERO && dir != prev_joy_dir:
		prev_joy_dir = dir
		round_aim_movement += dir.normalized().length_squared()


func _process(delta):
	round_length_time += delta
	if round_classes_used.has(current_class):
		round_classes_used[current_class] += delta


func _on_lobby_members_updated() -> void:
	for player_info in Lobby.get_all_lobby_player_info():
		if player_info["id"] == SteamValues.STEAM_ID:
			for class_id in classes_info:
				if str(classes_info[class_id].elements) == str(player_info["elmts"]):
					current_class = class_id
					round_classes_used[class_id] = 0
					break


func on_round_start():
	round_aim_movement = 0
	round_length_time = 0
	round_classes_used = {current_class: 0}


func _on_round_won(is_winner):
	var is_online = Lobby.client_members.size() >= 1
	var actually_played_the_game = true # Not just standing still doing nothing
	if round_aim_movement/(round_length_time + 0.01) < 2: # Moved mouse like nothing, either afk or not doing anything
		actually_played_the_game = false
	
	if actually_played_the_game && is_winner && is_online:
		# Increase amount of rounds won
		achievements_data_dict["rounds_won_online"] = achievements_data_dict["rounds_won_online"] + 1 
		check_win_achievement(10, achievements.ACH_COMPLETE_WIN_10_ROUNDS, achievements_data_dict)
		check_win_achievement(50, achievements.ACH_COMPLETE_WIN_50_ROUNDS, achievements_data_dict)
		check_win_achievement(100, achievements.ACH_COMPLETE_WIN_100_ROUNDS, achievements_data_dict)
		check_win_achievement(1000, achievements.ACH_COMPLETE_WIN_1000_ROUNDS, achievements_data_dict)
		
		# Check if we won a round with a special element amount 
		var element_amount = RoomSettings.get_element_amount()
		
		if achievements_data_dict["element_available_rounds_won"].has(element_amount):
			achievements_data_dict["element_available_rounds_won"][element_amount] = achievements_data_dict["element_available_rounds_won"][element_amount] + 1
			save_achievement_data(achievements_data_dict)
		
		check_available_element_win_achievement(achievements.ACH_COMPLETE_WIN_50_ROUNDS_TWO_ELEMENTS, achievements_data_dict, 2)
		check_available_element_win_achievement(achievements.ACH_COMPLETE_WIN_50_ROUNDS_FOUR_ELEMENTS, achievements_data_dict, 4)
		check_available_element_win_achievement(achievements.ACH_COMPLETE_WIN_50_ROUNDS_FIVE_ELEMENTS, achievements_data_dict, 5)
		
		var element_mode = RoomSettings.get_element_mode()
		check_element_mode_win(element_mode)
		
		# Check that we didn't just switch class at the end of the round to farm achievments
		var won_with_current_class = true
		var time_played_as_current_class = round_classes_used[current_class]
		for class_id in round_classes_used:
			var time_class_was_used = round_classes_used[class_id] 
			# If we used another class twice as much as the current one it doesn't count 
			if time_class_was_used >= time_played_as_current_class * 2:
				won_with_current_class = false
				break
		
		if won_with_current_class == true:
			var elements = UserSettings.get_elements()
			for class_id in classes_info:
				if classes_info[class_id].elements == elements:
					achievements_data_dict["class_rounds_won_online"][class_id] = achievements_data_dict["class_rounds_won_online"][class_id] + 1
					check_class_win_achievement(class_id, achievements_data_dict)
					break


func get_achievement_data() -> Dictionary:
	return achievements_data_dict


func _on_kill(killed_id, killer_id, _killed_with_spell):
	if achievements_data_dict.has("kills") == false:
		printerr("Couldn't get kills from achievment data? Here is achievements_data_dict: ", achievements_data_dict)
		return
		
	if killer_id == SteamValues.STEAM_ID:
		# Increment global kills
		achievements_data_dict["kills"] = achievements_data_dict["kills"] + 1
		
		# Increment class kills
		var elements = UserSettings.get_elements()
		for class_id in classes_info:
			if classes_info[class_id].elements == elements:
				achievements_data_dict["class_kills"][class_id]  = 1 + achievements_data_dict["class_kills"][class_id] 
				break
		
		# Check if achievement is reached
		check_kill_achievement(10, achievements.ACH_COMPLETE_10_KILLS)
		check_kill_achievement(50, achievements.ACH_COMPLETE_50_KILLS)
		check_kill_achievement(100, achievements.ACH_COMPLETE_100_KILLS)
		check_kill_achievement(500, achievements.ACH_COMPLETE_500_KILLS)
		check_kill_achievement(1000, achievements.ACH_COMPLETE_1000_KILLS)
		check_kill_achievement(1500, achievements.ACH_COMPLETE_1500_KILLS)
		check_kill_achievement(2000, achievements.ACH_COMPLETE_2000_KILLS)
		
		save_achievement_data(achievements_data_dict)


func verify_got_achievements() -> void:
	check_kill_achievement(10, achievements.ACH_COMPLETE_10_KILLS, true)
	check_kill_achievement(50, achievements.ACH_COMPLETE_50_KILLS, true)
	check_kill_achievement(100, achievements.ACH_COMPLETE_100_KILLS, true)
	check_kill_achievement(500, achievements.ACH_COMPLETE_500_KILLS, true)
	check_kill_achievement(1000, achievements.ACH_COMPLETE_1000_KILLS, true)
	check_kill_achievement(1500, achievements.ACH_COMPLETE_1500_KILLS, true)
	check_kill_achievement(2000, achievements.ACH_COMPLETE_2000_KILLS, true)
	
	check_available_element_win_achievement(achievements.ACH_COMPLETE_WIN_50_ROUNDS_TWO_ELEMENTS, achievements_data_dict, 2, true)
	check_available_element_win_achievement(achievements.ACH_COMPLETE_WIN_50_ROUNDS_FOUR_ELEMENTS, achievements_data_dict, 4, true)
	check_available_element_win_achievement(achievements.ACH_COMPLETE_WIN_50_ROUNDS_FIVE_ELEMENTS, achievements_data_dict, 5, true)
	
	check_win_achievement(10, achievements.ACH_COMPLETE_WIN_10_ROUNDS, achievements_data_dict, true)
	check_win_achievement(50, achievements.ACH_COMPLETE_WIN_50_ROUNDS, achievements_data_dict, true)
	check_win_achievement(100, achievements.ACH_COMPLETE_WIN_100_ROUNDS, achievements_data_dict, true)
	check_win_achievement(1000, achievements.ACH_COMPLETE_WIN_1000_ROUNDS, achievements_data_dict, true)
	
	check_spell_achievement(achievements_data_dict["grabs"], achievements.ACH_GRAB_100_ENEMIES, true)
	check_spell_achievement(achievements_data_dict["reflects"], achievements.ACH_REFLECT_100_PROJECTILES, true)
	check_spell_achievement(achievements_data_dict["pushes"], achievements.ACH_PUSH_100_ENEMIES, true)
	
	check_element_mode_win(Globals.ElementModes.RANDOM, true)
	check_element_mode_win(Globals.ElementModes.TIMED, true)
	
	for class_id in classes_info:
		check_class_win_achievement(class_id, achievements_data_dict, true)
	
	if _falsely_achieved_achievement == true && _showed_popup_falsely_achieved == false:
		_showed_popup_falsely_achieved = true
		Globals.create_info_popup("Couldn't verify achievement(s)", "One or more of your achievements didn't match up with your stats. Did you try to set an achievement without legitimately gaining it? Make sure Steam is running too.")


func check_spell_achievement(value: int, ach_name: String, verify_aquired: bool = false) -> void:
	if value >= 100:
		if steam_achievements[ach_name] == false && verify_aquired == false:
			store_achievement(ach_name)
		
		if verify_aquired == true:
			store_achievement(ach_name, false)


func check_available_element_win_achievement(ach_name: String, updated_ach_data: Dictionary, element_amount: int, verify_aquired: bool = false) -> void:
	var amount_wins_for_achievement = 50
	if updated_ach_data["element_available_rounds_won"][element_amount] >= amount_wins_for_achievement:
		
		if steam_achievements[ach_name] == false && verify_aquired == false:
			#print("Setting kill achievement ", ach_name)
			store_achievement(ach_name)
		
		if verify_aquired == true:
			store_achievement(ach_name, false)


func check_element_mode_win(element_mode: int, verify_aquired: bool = false) -> void:
	if verify_aquired == false:
		if element_mode == Globals.ElementModes.RANDOM && achievements_data_dict["element_mode_rounds_won"].has(Globals.ElementModes.RANDOM):
			achievements_data_dict["element_mode_rounds_won"][Globals.ElementModes.RANDOM] = achievements_data_dict["element_mode_rounds_won"][Globals.ElementModes.RANDOM] + 1
			if achievements_data_dict["element_mode_rounds_won"][Globals.ElementModes.RANDOM] >= 50:
				if steam_achievements[achievements.ACH_COMPLETE_WIN_50_ROUNDS_RANDOM_SAME] == false && verify_aquired == false:
					store_achievement(achievements.ACH_COMPLETE_WIN_50_ROUNDS_RANDOM_SAME)
				
				if verify_aquired == true:
					store_achievement(achievements.ACH_COMPLETE_WIN_50_ROUNDS_RANDOM_SAME, false)
		
		if element_mode == Globals.ElementModes.TIMED && achievements_data_dict["element_mode_rounds_won"].has(Globals.ElementModes.TIMED):
			achievements_data_dict["element_mode_rounds_won"][Globals.ElementModes.TIMED] = achievements_data_dict["element_mode_rounds_won"][Globals.ElementModes.TIMED] + 1
			if achievements_data_dict["element_mode_rounds_won"][Globals.ElementModes.TIMED] >= 50:
				if steam_achievements[achievements.ACH_COMPLETE_WIN_50_ROUNDS_RANDOM_TIME] == false && verify_aquired == false:
					store_achievement(achievements.ACH_COMPLETE_WIN_50_ROUNDS_RANDOM_TIME)
					
				if verify_aquired == true:
					store_achievement(achievements.ACH_COMPLETE_WIN_50_ROUNDS_RANDOM_TIME, false)


func check_win_achievement(amount: int, ach_name: String, updated_ach_data: Dictionary, verify_aquired: bool = false) -> void:
	if updated_ach_data["rounds_won_online"] >= amount:
		if steam_achievements[ach_name] == false && verify_aquired == false:
			#print("Setting kill achievement ", ach_name)
			store_achievement(ach_name)
		
		if verify_aquired == true:
			store_achievement(ach_name, false)


func check_class_win_achievement(class_id: int, updated_ach_data: Dictionary, verify_aquired: bool = false) -> void:
	var achievement_name = classes_info[class_id]["ach_name"]
	var wins = updated_ach_data["class_rounds_won_online"][class_id]
	if wins >= 30:
		if steam_achievements[achievement_name] == false && verify_aquired == false:
			#print("Setting class achievement ", achievement_name)
			store_achievement(achievement_name)
		
		if verify_aquired == true:
			store_achievement(achievement_name, false)


func check_kill_achievement(amount: int, ach_name: String, verify_aquired: bool = false) -> void:
	if achievements_data_dict["kills"] >= amount: 
		if steam_achievements[ach_name] == false && verify_aquired == false:
			#print("Setting kill achievement ", ach_name)
			store_achievement(ach_name)
	
		if verify_aquired == true:
			store_achievement(ach_name, false)


func store_achievement(name: String, set_steam_achievement: bool = true) -> void:
	steam_achievements[name] = true
	var storeSucess = Steam.storeStats()

	var setSuccess: bool = true
	if set_steam_achievement == true:
		setSuccess = Steam.setAchievement(name)
	
	if setSuccess && storeSucess && achievementHats.has(name) == true && set_steam_achievement == true:
		set_new_cosmetic(achievementHats[name])
		print("New hat: ", name)
	elif set_steam_achievement == true:
		print("Couldn't add hat since something went wrong whilst connecting to steam. Or hat hasn't been added.")


func reset() -> void:
	for achievement_name in achievements:
		Steam.clearAchievement(achievements[achievement_name])
	
	# Create a new empty file 
	achievements_data_dict = _default_achievement_data.duplicate(true)
	save_achievement_data(achievements_data_dict)


func _on_steam_stats_received(_game: int, _result: int, _user: int) -> void:
	# Get achievements and pass them to variables
	for achievement_name in achievements:
		get_achievement_from_steam(achievements[achievement_name])
	
	verify_got_achievements()
	#print("Received Steam stats, steam_achievements: ", steam_achievements)
	emit_signal("fetched_achievements")


func get_achievement_from_steam(value: String) -> void:
	var steam_stored_achievement: Dictionary = Steam.getAchievement(value)
	
	# Achievement exists
	if steam_stored_achievement['ret']:
		# Achievement is unlocked
		if steam_stored_achievement['achieved']:
			# Check if actually unlocked from achdata
			steam_achievements[value] = true
		# Achievement is locked
		else:
			steam_achievements[value] = false
	# Achievement does not exist
	else:
		#printerr("Couldn't find the achievement: ", value)
		steam_achievements[value] = false


func load_achievement_data() -> void:
	Steam.requestUserStats(SteamValues.STEAM_ID)
	if Steam.fileExists(achievements_data_path):
		var fetched_achievements_data_dict = Util.steam_cloud_read(achievements_data_path)
		
		# If the settings dont have the same key due to an update or something
		for key in _default_achievement_data.keys():
			if fetched_achievements_data_dict.has(key) == false:
				printerr("Didn't find the key '", key,"' in steam achievement data, adding default")
				fetched_achievements_data_dict[key] = _default_achievement_data[key]
			elif _default_achievement_data[key] is Dictionary:
				for dict_key in _default_achievement_data[key]:
					if fetched_achievements_data_dict[key].has(dict_key) == false:
						printerr("Didn't find the key '", key,"' in steam achievement data dict, adding default")
						fetched_achievements_data_dict[key][dict_key] = _default_achievement_data[key][dict_key]
		
		achievements_data_dict = fetched_achievements_data_dict
		emit_signal("achievements_data_dict_updated", achievements_data_dict)
		#print("loaded achievements_data_dict: ", achievements_data_dict)
	else:
		# Create a new file if it doesn't exist
		achievements_data_dict = _default_achievement_data.duplicate(true)
		save_achievement_data(achievements_data_dict)


func save_achievement_data(new_achievements_data_dict: Dictionary) -> void:
	Util.steam_cloud_write(achievements_data_path, new_achievements_data_dict)


func get_unlocked_hats() -> Array:
	var hat_info_array = []
	for achievement_name in steam_achievements:
		if achievementHats.has(achievement_name):
			var unlocked = steam_achievements[achievement_name] == true
			var hat = achievementHats[achievement_name]
			var title = Steam.getAchievementDisplayAttribute(achievement_name, "name")
			var desc = Steam.getAchievementDisplayAttribute(achievement_name, "desc")
			hat_info_array.append({"unlocked": unlocked, "hat": hat, "title": title, "desc": desc})
	
	return hat_info_array
