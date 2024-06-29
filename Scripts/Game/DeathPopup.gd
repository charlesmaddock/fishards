extends ColorRect


onready var timer = $Timer
onready var title = $Control/Title
onready var button = $Control/VBoxContainer/Button
onready var elementSelectPanel = $Control/VBoxContainer/ElementSelectPanel
export(NodePath) var gamemodeNodePath


var _gamemode_node = null
var _respawn_allowed: bool 


func _ready():
	Lobby.connect("player_respawn", self, "_on_respawn_player")
	
	_gamemode_node = get_node(gamemodeNodePath)
	var is_default_element_mode = RoomSettings.get_element_mode() == Globals.ElementModes.DEFAULT
	elementSelectPanel.set_visible(is_default_element_mode)
	var current_gamemode_info = GamemodeValues.get_current_rounds_gamemodeinfo()
	_respawn_allowed =  current_gamemode_info["respawn_allowed"]
	set_visible(false)


func show_popup(text: String) -> void:
	set_visible(true)
	title.text = text
	var timeout_time = 2
	if _gamemode_node != null:
		timeout_time = _gamemode_node.get_respawn_time()
	
	timer.start(timeout_time)
	
	# Respawn is instant inside singleplayer games
	if Globals.in_single_player == true:
		elementSelectPanel.set_visible(false)
		button.set_visible(false)
	else:
		button.set_disabled(_respawn_allowed)
		if _respawn_allowed == false:
			button.set_text("Spectate")
		else:
			button.set_text("Respawn")


func _on_Timer_timeout():
	button.set_disabled(false)
	
	# Respawn directly in singleplayer
	if Globals.in_single_player == true:
		PacketSender.request_respawn()


func _on_Button_pressed():
	if _respawn_allowed == true:
		PacketSender.request_respawn()
	set_visible(false)


# When we respawn hide this panel
func _on_respawn_player(player_id) -> void:
	if player_id == SteamValues.STEAM_ID:
		set_visible(false)
