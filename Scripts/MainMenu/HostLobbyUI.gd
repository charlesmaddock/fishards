extends MainMenuUIChild

onready var lobbySetName: LineEdit = $"Control/Container/HBox/Name/LineEdit"
onready var lobbyType: OptionButton = $"Control/Container/HBox/Type/OptionButton"
onready var roomSettings: Control = $"Control/Container/RoomSettingsControl"


func init_UI():
	lobbySetName.text = SteamValues.STEAM_USERNAME + "'s lobby"


func _on_Host_pressed() -> void:
	var room_setting_values: Dictionary = roomSettings.get_settings_dict()
	var room_settings: Dictionary = RoomSettings.create_settings_dict(
		room_setting_values.password,
		room_setting_values.max_players, 
		room_setting_values.map, 
		0, 
		room_setting_values.bot_amount,
		room_setting_values.gamemode,
		room_setting_values.round_amount,
		room_setting_values.elements_amount,
		room_setting_values.bot_difficulty,
		room_setting_values.element_mode,
		room_setting_values.powerups
	)
	Lobby.create_lobby(lobbyType.selected, room_setting_values.max_players, lobbySetName.text, room_settings)


func _on_Back_pressed() -> void:
	get_parent().change_UI("PlayUI")
