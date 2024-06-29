extends Control

onready var password: LineEdit = $"LobbySettingsContainer/Password/LineEdit"
onready var maxPlayers: Slider = $"LobbySettingsContainer/MaxPlayers/Slider"
onready var elementMode: OptionButton = $"ElementInfoContainer/ElementMode/OptionButton"
onready var elementAmount: Slider = $"ElementInfoContainer/ElementAmount/Slider"
onready var roundAmount: Slider = $"RoundsContainer/RoundAmount/Slider"
onready var botAmount: Slider = $"BotInfoContainer/BotAmount/Slider"
onready var botDifficulty: OptionButton = $"BotInfoContainer/BotDifficulty/OptionButton"
onready var powerupsCheckBox: CheckBox = $"AdvancedSettings/Vbox/AdvancedContainer1/Powerups/PowerupsCheckBox"

onready var hideAdvancedSettings: Button = $"ButtonContainer/HideAdvancedSettings"
onready var openAdvancedSettings: Button = $"ButtonContainer/OpenAdvancedSettings"
onready var advancedSettingsContainer: PanelContainer = $"AdvancedSettings"

onready var gamemodeGrid: GridContainer = $PanelContainer/VBox/GamemodeGrid
onready var minigamesGrid: GridContainer = $"MiniGamePanelContainer/VBox/GamemodeGrid"

onready var map: OptionButton = $"AdvancedSettings/Vbox/AdvancedContainer1/Map/OptionButton"

var _selected_gamemode: int = GamemodeValues.Gamemodes.FreeForAll


func _ready():
	map.clear()
	botDifficulty.clear()
	advancedSettingsContainer.set_visible(false)
	
	# Demo config
	if Globals.get_app_mode() == Globals.AppModes.DEMO:
		map.get_parent().visible = false
		elementAmount.get_parent().visible = false
		botAmount.max_value = 3
		maxPlayers.max_value = 2
	
	maxPlayers.value = maxPlayers.max_value
	
	var bot_difficulties = [Globals.PlayerTypes.EASY_BOT, Globals.PlayerTypes.MEDIUM_BOT, Globals.PlayerTypes.HARD_BOT]
	for difficulty in bot_difficulties:
		var title = ""
		match difficulty:
			Globals.PlayerTypes.EASY_BOT:
				title = "Easy"
			Globals.PlayerTypes.MEDIUM_BOT:
				title = "Medium"
			Globals.PlayerTypes.HARD_BOT:
				title = "Hard"
		
		botDifficulty.add_item(title, difficulty)
	
	_on_gamemode_selected(GamemodeValues.Gamemodes.FreeForAll)


func _on_gamemode_selected(selected_gamemode: int) -> void:
	map.clear()
	
	_selected_gamemode = selected_gamemode
	var available_maps: Array = GamemodeValues.get_gamemodes_maps(selected_gamemode)
	
	for gamemode_toggle in gamemodeGrid.get_children() + minigamesGrid.get_children():
		if gamemode_toggle.gamemode != selected_gamemode:
			gamemode_toggle.toggle(false)
		else:
			gamemode_toggle.toggle(true)
	
	# Just show the user that the maps will always be random if shuffle is the gamemode
	# Otherwise, display the available maps for the selected gamemode
	if selected_gamemode == GamemodeValues.Gamemodes.Shuffle || available_maps.size() == 0:
		map.add_item(GamemodeValues.get_map_name(GamemodeValues.Maps.Random), GamemodeValues.Maps.Random)
	else:
		if available_maps.size() >= 2:
			map.add_item(GamemodeValues.get_map_name(GamemodeValues.Maps.Random), GamemodeValues.Maps.Random)
		
		for available_map in available_maps:
			var map_id = available_map.map
			var map_name = GamemodeValues.get_map_name(map_id)
			map.add_item(map_name, map_id)
	
	if selected_gamemode == GamemodeValues.Gamemodes.Survive:
		botAmount.set_max(3)
	else:
		botAmount.set_max(10)


func load_values_from_settings_dict():
	var settings: Dictionary = RoomSettings.settings
	
	# Clamp bot amount
	var bot_amount = settings["bot_amount"]
	if bot_amount > botAmount.max_value:
		bot_amount = botAmount.max_value
	botAmount.value = bot_amount
	
	_on_gamemode_selected(settings["gamemode"])
	
	password.text = settings["password"]
	maxPlayers.value = settings["max_players"]
	roundAmount.value = settings["rounds"]
	elementAmount.value = settings["elmts"]
	powerupsCheckBox.set_pressed(settings["powerups"])
	elementMode.select(elementMode.get_item_index(settings["element_mode"]))
	botDifficulty.select(botDifficulty.get_item_index(settings["bot_difficulty"]))


func get_settings_dict() -> Dictionary:
	# For some reason you cant set negative numbers as ids
	var map_type = map.get_item_id(map.selected)
	if map.get_item_id(map.selected) == 999:
		map_type = GamemodeValues.Maps.Random
	
	return {
		"password": password.text,
		"max_players": maxPlayers.value, 
		"map": map_type, 
		"bot_amount": botAmount.value,
		"element_mode": elementMode.get_item_id(elementMode.selected),
		"gamemode": _selected_gamemode,
		"round_amount": roundAmount.value,
		"elements_amount": elementAmount.value,
		"bot_difficulty": botDifficulty.get_item_id(botDifficulty.selected),
		"powerups": powerupsCheckBox.is_pressed()
	}


func _on_OpenAdvancedSettings_pressed():
	openAdvancedSettings.set_visible(false)
	hideAdvancedSettings.set_visible(true)
	advancedSettingsContainer.set_visible(true)
	
	# Dumb shit since they don't update whilst invisible
	_on_gamemode_selected(_selected_gamemode)
	powerupsCheckBox.set_pressed(RoomSettings.get_powerups_enabled())


func _on_HideAdvancedSettings_pressed():
	openAdvancedSettings.set_visible(true)
	hideAdvancedSettings.set_visible(false)
	advancedSettingsContainer.set_visible(false)
