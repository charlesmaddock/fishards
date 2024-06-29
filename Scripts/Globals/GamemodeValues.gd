extends Node

var current_map_type: int = -1

enum Gamemodes {
	Shuffle,
	FreeForAll,
	LastManStanding,
	Survive,
	BombAndShield,
	TeamDeathmatch,
	Training,
	Tutorial,
	FishBall
}


enum SpectateMode {
	OWN_TEAM,
	EVERYONE,
	NONE,
}


enum TeamModes {
	NO_TEAMS,
	RED_BLUE_TEAMS,
	COOP
}


onready var GameModeInfo: Dictionary = {
	Gamemodes.FreeForAll: {
		"title": "Free For All", 
		"short": "FFA", 
		"desc": "The player with the most kills after the timer ends wins.",
		"scene": "res://Scenes/Game/Gamemodes/FreeForAll.tscn",
		"spectate_mode": SpectateMode.NONE,
		"team_mode": TeamModes.NO_TEAMS,
		"timed_rounds": true,
		"respawn_allowed": true,
		"available_maps": [
			{"map": Maps.Island, "sizes": [MapSizes.Small, MapSizes.Medium, MapSizes.Large]},
			{"map": Maps.Ice, "sizes": [MapSizes.Medium]},
			{"map": Maps.Lava, "sizes" : [MapSizes.Small, MapSizes.Large]},
		],
		"min_players": 2,
		"selectable": true,
	}, 
	Gamemodes.FishBall: {
		"title": "Fish Ball!", 
		"short": "Ball", 
		"desc": "Push the ball into the other team's goal.",
		"scene": "res://Scenes/Game/Gamemodes/FishBall.tscn",
		"spectate_mode": SpectateMode.NONE,
		"team_mode": TeamModes.RED_BLUE_TEAMS,
		"timed_rounds": false,
		"respawn_allowed": true,
		"available_maps": [
			{"map": Maps.FishBall, "sizes": [MapSizes.Medium]},
		],
		"min_players": 2,
		"selectable": true,
	}, 
	Gamemodes.LastManStanding: {
		"title":"Last Fish Standing", 
		"short": "LFS", 
		"desc": "Try to be the last fishard alive.",
		"scene": "res://Scenes/Game/Gamemodes/LastManStanding.tscn",
		"spectate_mode": SpectateMode.EVERYONE,
		"team_mode": TeamModes.NO_TEAMS,
		"timed_rounds": false,
		"respawn_allowed": false,
		"available_maps": [
			{"map": Maps.Island, "sizes": [MapSizes.Small, MapSizes.Medium, MapSizes.Large]},
			{"map": Maps.Ice, "sizes": [MapSizes.Medium]},
			{"map": Maps.Lava, "sizes" : [MapSizes.Small, MapSizes.Large]},
		],
		"min_players": 2,
		"selectable": true,
	},
	Gamemodes.TeamDeathmatch: {
		"title": "Team Deathmatch", 
		"short": "Team DM", 
		"desc": "Obliterate the other team with your team mates.",
		"scene": "res://Scenes/Game/Gamemodes/TeamDeathmatch.tscn",
		"spectate_mode": SpectateMode.EVERYONE,
		"team_mode": TeamModes.RED_BLUE_TEAMS,
		"timed_rounds": false,
		"respawn_allowed": false,
		"available_maps": [
			{"map": Maps.Island, "sizes": [MapSizes.Medium, MapSizes.Large]},
			{"map": Maps.Ice, "sizes": [MapSizes.Medium]}
		],
		"min_players": 2,
		"selectable": true,
	},
	Gamemodes.Survive: {
		"title": "Protect Fish God", 
		"short": "protect", 
		"desc": "Protect Golden Gooey Fish God for as long as possible.",
		"scene": "res://Scenes/Game/Gamemodes/Survive.tscn",
		"spectate_mode": SpectateMode.NONE,
		"team_mode": TeamModes.COOP,
		"timed_rounds": false,
		"respawn_allowed": true,
		"available_maps": [
			{"map": Maps.ProtectIsland, "sizes": [MapSizes.Medium]},
		],
		"min_players": 1,
		"selectable": true,
	},
	Gamemodes.Training: {
		"title": "Training", 
		"short": "training", 
		"desc": "Practice the art of fish wizardry alone on a deserted island.",
		"scene": "res://Scenes/Game/Gamemodes/Training.tscn",
		"spectate_mode": SpectateMode.NONE,
		"team_mode": TeamModes.COOP,
		"timed_rounds": false,
		"respawn_allowed": true,
		"available_maps": [
			{"map": Maps.Training, "sizes": [MapSizes.Large]},
		],
		"min_players": 1,
		"selectable": false,
	},
	Gamemodes.Tutorial: {
		"title": "Tutorial", 
		"short": "tutorial", 
		"desc": "Learn how to play Fishards with Sensei on a deserted island!",
		"scene": "res://Scenes/Game/Gamemodes/Training.tscn",
		"spectate_mode": SpectateMode.NONE,
		"team_mode": TeamModes.COOP,
		"timed_rounds": false,
		"respawn_allowed": true,
		"available_maps": [
			{"map": Maps.Training, "sizes": [MapSizes.Large]},
		],
		"min_players": 1,
		"selectable": false,
	},
	Gamemodes.Shuffle: {
		"title": "Shuffle", 
		"desc": "",
		"available_maps": [],
		"selectable": true,
	}, 
}

"""
	Gamemodes.BombAndShield: {
		"title":"Bomb and Shield", 
		"short": "Bomb", 
		"desc":"Always have your 'Shield' between yourself and your 'Bomb'.",
		"scene": "res://Scenes/Game/Gamemodes/BombAndShield.tscn",
		"spectate_mode": SpectateMode.NONE,
		"team_mode": TeamModes.NO_TEAMS,
		"available_maps": [
			{"map": Maps.Island, "sizes": [MapSizes.Small]},
			{"map": Maps.Cursed, "sizes": [MapSizes.Small]},
		],
		"min_players": 3
	},
"""


enum Maps {
	Random = 0,
	Island,
	ProtectIsland,
	Lava,
	Ice,
	Training,
	FishBall
}


onready var map_sound_tracks: Dictionary = {
	Maps.Island: [MusicAndSfxHandler.tracks.MAIN_THEME, MusicAndSfxHandler.tracks.TROPIC1],
	Maps.Lava: [MusicAndSfxHandler.tracks.LAVA1, MusicAndSfxHandler.tracks.LAVA2],
	Maps.Ice: [MusicAndSfxHandler.tracks.ICE1, MusicAndSfxHandler.tracks.ICE2],
	Maps.ProtectIsland: [MusicAndSfxHandler.tracks.MAIN_THEME, MusicAndSfxHandler.tracks.TROPIC1],
	Maps.Training: [MusicAndSfxHandler.tracks.MAIN_THEME],
	Maps.FishBall: [MusicAndSfxHandler.tracks.MAIN_THEME, MusicAndSfxHandler.tracks.TROPIC1],
}


enum MapSizes {
	Small = 0,
	Medium = 1,
	Large = 2,
}


var map_scenes: Dictionary = {
	Maps.Island: {
		MapSizes.Small: ["res://Scenes/Maps/Islands/TropicSmall.tscn"],
		MapSizes.Medium: ["res://Scenes/Maps/Islands/TropicMedium.tscn", "res://Scenes/Maps/Islands/TropicMedium2.tscn"],
		MapSizes.Large: ["res://Scenes/Maps/Islands/TropicLarge.tscn"],
	},
	Maps.Lava: {
		MapSizes.Small: ["res://Scenes/Maps/Lava/LavaSmallFfa.tscn"],
		MapSizes.Large: ["res://Scenes/Maps/Lava/LavaLargeFfa.tscn"],
	},
	Maps.Ice: {
		MapSizes.Medium: ["res://Scenes/Maps/Ice/IceFfaMedium.tscn"]
	},
	Maps.ProtectIsland: {
		MapSizes.Medium: ["res://Scenes/Maps/Islands/FortIslandMedium.tscn"]
	},
	Maps.Training: {
		MapSizes.Large: ["res://Scenes/Game/Tutorial.tscn"]
	},
	Maps.FishBall: {
		MapSizes.Medium: ["res://Scenes/Maps/FishBall/FishBall.tscn"]
	}
}


enum GameStates {
	STARTING,
	GAME,
	ROUND_OVER,
}

func _ready():
	match Globals.get_app_mode():
		Globals.AppModes.DEMO:
			for info in GameModeInfo.keys():
				match info:
					Gamemodes.FreeForAll:
						GameModeInfo.get(info)["available_maps"] = [{"map": Maps.Island, "sizes": [MapSizes.Medium]} ]
					_: 
						GameModeInfo.get(info)["selectable"] = false


func get_short_gamemode_name(gamemodes_id: int) -> String:
	return GameModeInfo[gamemodes_id].short


func get_gamemode_title(gamemodes_id: int) -> String:
	return GameModeInfo[gamemodes_id].title


func get_gamemode_desc(gamemodes_id: int) -> String:
	return GameModeInfo[gamemodes_id].desc


func get_gamemodes_maps(gamemodes_id: int) -> Array:
	return GameModeInfo[gamemodes_id].available_maps


func get_current_rounds_gamemodeinfo() -> Dictionary:
	var current_rounds_gamemodeinfo: Dictionary = GameModeInfo[RoomSettings.get_rounds_gamemode()]
	if current_rounds_gamemodeinfo != null:
		return current_rounds_gamemodeinfo
	
	printerr("MAJOR ERROR: Couldn't get the current rounds gamemode info")
	return {}


func get_amount_players_needed_to_start() -> int:
	# Check if we have enough players to start
	var gamemode = RoomSettings.settings["gamemode"]
	var gamemode_info = get_current_rounds_gamemodeinfo()
	var amount_of_players_needed_to_start: int
	
	if gamemode_info != {}:
		# Find the gamemode with the largest amount of min players since we are shuffling
		if gamemode == GamemodeValues.Gamemodes.Shuffle:
			for gamemode_id in GamemodeValues.GameModeInfo:
				if GamemodeValues.GameModeInfo[gamemode_id].has("min_players"):
					if GamemodeValues.GameModeInfo[gamemode_id].min_players > amount_of_players_needed_to_start:
						amount_of_players_needed_to_start = GamemodeValues.GameModeInfo[gamemode_id].min_players
		else:
			if gamemode_info.has("min_players"):
				amount_of_players_needed_to_start = gamemode_info.min_players
	
	return amount_of_players_needed_to_start


func generate_current_rounds_map_ref(amount_of_players: int) -> String:
	var room_settings: Dictionary = RoomSettings.settings
	var map_size: int = room_settings["map_size"]
	var map_type: int = room_settings["map_type"]
	var map_dict: Dictionary = {} # {"map": "String/Ref/To/Scene", "sizes": [0,1,2]}
	var available_maps = GamemodeValues.get_gamemodes_maps(RoomSettings.get_rounds_gamemode())
	
	if amount_of_players <= 3:
		map_size = GamemodeValues.MapSizes.Small
	elif amount_of_players <= 6:
		map_size = GamemodeValues.MapSizes.Medium
	else:
		map_size = GamemodeValues.MapSizes.Large
	
	if map_type == Maps.Random:
		# First we try to create a list with all the maps that are the correct size
		var maps_with_correct_size: Array
		for interated_map_dict in available_maps:
			var has_requested_map_size = false
			for size in interated_map_dict.sizes:
				if size == map_size:
					has_requested_map_size = true
					break
			
			if has_requested_map_size == true:
				maps_with_correct_size.append(interated_map_dict)
		
		# If we find a few with the correct size, pick a random one of them
		if maps_with_correct_size.size() > 0:
			map_dict = maps_with_correct_size[Util.rand.randi_range(0, maps_with_correct_size.size() - 1)]
		# Otherwise we just pick one of the gamemode's random available maps
		else:
			var rand_index = Util.rand.randi_range(0, available_maps.size() - 1)
			map_dict = available_maps[rand_index]
			
		
		map_type = map_dict.map
	else:
		for available_map_dict in available_maps:
			if available_map_dict.map == map_type:
				map_dict = available_map_dict
	
	# If we for some reason couldnt get a valid map into map_dict, just select an available one
	if map_dict.empty() == true:
		map_dict = available_maps[Util.rand.randi_range(0, available_maps.size() - 1)]
		map_type = map_dict.map
		print("available_maps: ", available_maps)
		printerr("Couldn't find an available map, selecting one that the gamemode accepts")
	
	if map_scenes.has(map_type) == false:
		printerr("This map scene doesn't exist, did you forget to add it to map_scenes?")
	
	var found_requested_size: bool = false
	
	if map_dict.has("sizes"):
		for size in map_dict.sizes:
			if size == map_size:
				found_requested_size = true
				break
		
		if found_requested_size == false:
			printerr("WARNING: This map doesn't have the requested size, setting the first available size...")
			map_size = map_dict.sizes[0]
		
		# If there are variants of a size select a random one
		var rand_index = Util.rand.randi_range(0, map_scenes[map_type][map_size].size() - 1)
		var map_ref = map_scenes[map_type][map_size][rand_index]
		
		return map_ref
	else:
		printerr("map_dict doesn't have sizes: ", map_dict)
		return ""


func get_map_name(id: int) -> String:
	return Maps.keys()[id]


func get_size_name(id: int) -> String:
	return MapSizes.keys()[id]


func get_current_rounds_teammode() -> int:
	var current_round_gamemode_info = GameModeInfo[RoomSettings.get_rounds_gamemode()]
	if current_round_gamemode_info != null:
		if current_round_gamemode_info.has("team_mode"):
			return current_round_gamemode_info["team_mode"]
	
	printerr("Couldn't get the current rounds team mode")
	return GamemodeValues.TeamModes.NO_TEAMS


func get_current_rounds_spectate_mode() -> int:
	var current_rounds_gamemode_info = GameModeInfo[RoomSettings.get_rounds_gamemode()]
	if current_rounds_gamemode_info != null:
		if current_rounds_gamemode_info.has("spectate_mode"):
			return current_rounds_gamemode_info["spectate_mode"]
	
	printerr("Couldn't get the current rounds spectate mode")
	return SpectateMode.NONE
