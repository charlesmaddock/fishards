extends MainMenuUIChild


onready var notConnectedPanel = $NotConnected


func _ready():
	SteamValues.connect("attempted_to_connect", self, "_on_attempted_to_connect")
	if Globals.get_app_mode() != Globals.AppModes.DEMO:
		$Logo/Panel.visible = false


func _on_attempted_to_connect() -> void:
	check_connection()


func init_UI():
	var not_connected = check_connection()
	if not_connected == true:
		SteamValues.attempt_connect(false)


func check_connection() -> bool:
	
	
	var not_connected: bool = false
	if SteamValues.OWNED == false || SteamValues.init_status['status'] != 1:
		not_connected = true
	
	notConnectedPanel.set_visible(not_connected)
	return not_connected


func _input(event) -> void:
	if event.is_action_pressed("ui_cancel") && visible == true:
		get_parent().change_UI("MainMenuUI")


func _on_Back_pressed():
	get_parent().change_UI("MainMenuUI")


func _on_Host_pressed():
	get_parent().change_UI("HostLobbyUI")


func _on_Join_pressed():
	get_parent().change_UI("JoinLobbyUI")


func _on_quickplay_pressed() -> void:
	# Check no other lobby is running
	Lobby.quickplay()


func _on_Training_pressed():
	Util.create_singleplayer_lobby(false)
