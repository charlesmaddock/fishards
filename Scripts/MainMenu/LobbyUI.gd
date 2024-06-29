extends MainMenuUIChild


onready var lobbyContainer: Control = $Lobby
onready var lobbyName: Label = $Lobby/TitleContainer/LobbyName
onready var pingLabel: RichTextLabel = $Lobby/TitleContainer/Ping
onready var lobbyChat: Panel = $Lobby/Chat
onready var teamList: Panel = $Lobby/Teams
onready var elementSelectPanel: Panel = $Lobby/RoomSettingsContainer/ElementsPanel
onready var noElementSelectPanel = $Lobby/RoomSettingsContainer/NoElementsPanel


onready var roomSettingsText: RichTextLabel = $Lobby/RoomSettingsContainer/RoomSettingsContainer/RoomSettingsList
onready var editSettingsButton: Button = $Lobby/RoomSettingsContainer/EditSettings
onready var elementsDisplay = $Lobby/RoomSettingsContainer/ElementsPanel/ElementsDisplay
onready var roomSettingsContainer: VBoxContainer = $Lobby/RoomSettingsContainer


onready var startButton: Button = $Lobby/Start
onready var leaveButton: Button = $Lobby/Leave
onready var backButton: Button = $"Lobby/RoomSettingsControlContainer/ButtonsContainer/Back"
onready var joinButton: Button = $Lobby/Join
onready var minPlayerBlock: Panel = $Lobby/MinPlayerBlock


onready var updateSettingsButton: Button = $"Lobby/RoomSettingsControlContainer/ButtonsContainer/UpdateSettings"
onready var roomSettingsControl: VBoxContainer = $"Lobby/RoomSettingsControlContainer/RoomSettingsControl"



var _amount_of_players_needed_to_start: int


func _ready():
	Lobby.connect("room_settings_updated", self, "_on_room_settings_update")
	Lobby.connect("lobby_members_updated", self, "_on_lobby_members_updated")
	Lobby.connect("ping_updated", self, "_on_ping_updated")


func init_UI():
	yield(get_tree(), "idle_frame")
	if Globals.get_app_mode() == Globals.AppModes.DEMO:
		Globals.create_info_popup("You're missing out!", "In the full version of Fishards you can choose between more gamemodes, select between one to five available elements per game and have up to 10 players in a lobby! You can also customize your Fishard and rank up.")
		
	lobbyName.text = Lobby.lobby_name
	
	updateSettingsButton.visible = false
	roomSettingsControl.visible = false
	minPlayerBlock.visible = false
	lobbyChat.clear_chat()
	
	update_start_and_join_button()
	
	_on_room_settings_update()


func update_start_and_join_button() -> void:
	if RoomSettings.get_game_started() == true:
		joinButton.set_visible(true)
	else:
		joinButton.set_visible(false)
	
	if Lobby.is_host == false: 
		startButton.visible = false
		editSettingsButton.visible = false
	else:
		if roomSettingsControl.visible == false:
			startButton.visible = true
		editSettingsButton.visible = true
		
		# Block the game from starting if we dont have enough players
		var amount_needed_to_start: int = GamemodeValues.get_amount_players_needed_to_start()
		minPlayerBlock.get_child(0).text = "You need at least " + str(amount_needed_to_start) + " players/bots to play"
		if Lobby.get_all_lobby_player_info().size() < amount_needed_to_start:
			if roomSettingsControl.visible == false:
				minPlayerBlock.visible = true
		else:
			minPlayerBlock.visible = false


func _on_ping_updated(ping, ping_avg) -> void:
	if ping == 0:
		pingLabel.set_visible(false)
	else:
		pingLabel.set_visible(true)
		var ping_ms = round(ping * 1000)
		pingLabel.bbcode_text = "ping: " + str(ping_ms) + " milliseconds. "
		if ping_ms < 100:
			pingLabel.bbcode_text += "[color=#32a852]Your connection is excellent[/color] "
		elif ping_ms < 250:
			pingLabel.bbcode_text += "[color=#82bf3b]Your connection is good.[/color]"
		elif ping_ms < 350:
			pingLabel.bbcode_text += "[color=#bfad3b]Your connection is OK. Things might lag a bit though.[/color]"
		else:
			pingLabel.bbcode_text += "[color=#bf3d3b]Your connection is bad. Try finding a lobby that is hosted closer to you.[/color]"


func _on_lobby_members_updated() -> void:
	# Should the player see a start or join button?
	update_start_and_join_button()
	
	# Update amount of elements allowed
	#print("Room settings updated, these are my elements: ", UserSettings.get_elements())
	yield(get_tree(), "idle_frame")
	elementsDisplay.set_elements(UserSettings.get_elements(), false, RoomSettings.get_element_amount())


func _on_room_settings_update() -> void:
	update_start_and_join_button()
	
	var is_default_element_mode = RoomSettings.get_element_mode() == Globals.ElementModes.DEFAULT
	elementSelectPanel.set_visible(is_default_element_mode)
	noElementSelectPanel.set_visible(!is_default_element_mode)
	
	# Display room settings
	roomSettingsText.bbcode_text = ""
	var keys: Array = RoomSettings.settings.keys()
	var values: Array = RoomSettings.settings.values()
	for i in range(0, RoomSettings.settings.size()):
		var hidden_settings = ["game_started", "teams", "bot_difficulty", "round_gamemode_order", "leaderboard", "map", "bot_amount", "elmts", "current_round"]
		if hidden_settings.find(keys[i]) != -1:
			continue
		
		# Show others without "_" and some values should be displayed differently
		var key: String = str(keys[i]).replace("_", " ")
		var value: String = str(values[i])
		
		if value == "True":
			value = "On"
		elif value == "False":
			value = "Off"
		
		if keys[i] == "map_type":
			value = GamemodeValues.get_map_name(values[i])
		elif keys[i] == "password" && value == "":
			continue
		elif keys[i] == "elmts":
			key = "amount of elements"
		elif keys[i] == "map_size":
			value = GamemodeValues.get_size_name(values[i])
		elif keys[i] == "gamemode":
			value = GamemodeValues.get_gamemode_title(values[i])
		elif keys[i] == "element_mode":
			if values[i] == Globals.ElementModes.DEFAULT:
				value = "Default"
			elif values[i] == Globals.ElementModes.RANDOM:
				value = "Random Same"
			elif values[i] == Globals.ElementModes.TIMED:
				value = "Random Every 30 Seconds"
		elif keys[i] == "round_gamemode_order":
			key = "rounds"
			value = ""
			for gamemode_index in values[i]:
				var comma = "." if values[i].find(gamemode_index) == values[i].size() - 1 else ", "
				value += GamemodeValues.get_short_gamemode_name(gamemode_index) + comma
		
		key = key.capitalize()
		roomSettingsText.bbcode_text += "[color=#404040]" + key + ": [/color][color=#757575]" + value + "[/color]\n"


func _toggle_update_settings(value: bool):
	if value:
		roomSettingsControl.load_values_from_settings_dict()
	roomSettingsControl.visible = value
	updateSettingsButton.visible = value
	
	startButton.visible = !value
	minPlayerBlock.visible = !value
	leaveButton.visible = !value
	backButton.visible = value
	lobbyChat.visible = !value
	teamList.visible = !value
	roomSettingsContainer.visible = !value


func _on_edit_settings_pressed():
	_toggle_update_settings(true)


func _on_update_settings_pressed():
	_toggle_update_settings(false)
	
	var new_room_settings: Dictionary = roomSettingsControl.get_settings_dict()
	RoomSettings.edit_settings({
		"max_players": new_room_settings.max_players,
		"map_type": new_room_settings.map,
		"bot_amount": new_room_settings.bot_amount,
		"rounds": new_room_settings.round_amount,
		"gamemode": new_room_settings.gamemode,
		"elmts": new_room_settings.elements_amount,
		"bot_difficulty": new_room_settings.bot_difficulty,
		"element_mode": new_room_settings.element_mode,
	}, true)


func _on_Start_pressed():
	Lobby.host_start_game()


func _on_Join_pressed():
	PacketSender.request_join_game()


func _on_Leave_pressed():
	Lobby.leave_lobby("leave button")


func _on_Back_pressed():
	_toggle_update_settings(false)
