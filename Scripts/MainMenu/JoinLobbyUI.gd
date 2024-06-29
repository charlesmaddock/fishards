extends MainMenuUIChild


onready var roomButtonContainer: VBoxContainer = $Panel/ScrollContainer/VBoxContainer
onready var statusLabel: Label = $Status/StatusLabel
onready var buttons: Control = $Status/Buttons
onready var distances: OptionButton = $Panel2/distances


var found_lobbies: Array = []
var currently_searching: int = SteamValues.SearchDistance.CLOSE
signal received_lobbies()


func _ready():
	Steam.connect("lobby_match_list", self, "_on_Lobby_Match_List")


func init_UI():
	start_ping_search()


func start_ping_search() -> void:
	refresh()
	
	currently_searching = SteamValues.SearchDistance.CLOSE
	Steam.addRequestLobbyListDistanceFilter(currently_searching)
	Steam.requestLobbyList()
	yield(self, "received_lobbies")
	if _is_open() == false:
		refresh()
		return
	
	currently_searching = SteamValues.SearchDistance.FAR
	Steam.addRequestLobbyListDistanceFilter(currently_searching)
	Steam.requestLobbyList()
	yield(self, "received_lobbies")
	if _is_open() == false:
		refresh()
		return
	
	currently_searching = SteamValues.SearchDistance.WORLDWIDE
	Steam.addRequestLobbyListDistanceFilter(currently_searching)
	Steam.requestLobbyList()
	
	if found_lobbies.size() == 0:
		statusLabel.set_visible(true)
		statusLabel.text = "No lobbies found. Host one yourself or do some training alone!"
		buttons.set_visible(true)
	else:
		statusLabel.set_visible(false)


func _is_open() -> bool:
	return visible


func _on_Lobby_Match_List(lobbies):
	if _is_open() == true:
		for fishard_lobby_id in lobbies:
			if Steam.getLobbyData(fishard_lobby_id, "fishards") == "true" && found_lobbies.has(fishard_lobby_id) == false:
				found_lobbies.append(fishard_lobby_id)
				var lobby_name = Steam.getLobbyData(fishard_lobby_id, "name")
				if lobby_name == "":
					lobby_name = "Unnamed"
				var lobby_members = Steam.getNumLobbyMembers(fishard_lobby_id)
				
				var connection_text = ""
				if currently_searching == SteamValues.SearchDistance.WORLDWIDE:
					connection_text = "Bad"
				elif currently_searching == SteamValues.SearchDistance.FAR:
					connection_text = "OK"
				elif currently_searching == SteamValues.SearchDistance.CLOSE:
					connection_text = "Good"
				
				if lobby_name.length() > 28:
					lobby_name = lobby_name.substr(0, 28) + "..."
				
				var LOBBY_BUTTON = Button.new()
				var player_suffix: String = " Player" if lobby_members == 1 else " Players"
				LOBBY_BUTTON.set_text(str(lobby_name) + " - " + str(lobby_members) + player_suffix + " - ping: " + connection_text)
				LOBBY_BUTTON.set_name("lobby_"+str(fishard_lobby_id))
				LOBBY_BUTTON.rect_min_size = Vector2(256, 0)
				LOBBY_BUTTON.set_text_align(Button.ALIGN_LEFT)
				LOBBY_BUTTON.connect("pressed", Lobby, "initial_steam_join_lobby", [fishard_lobby_id, -1])
				
				roomButtonContainer.add_child(LOBBY_BUTTON)
		
		emit_signal("received_lobbies")


func refresh() -> void:
	# Delete previous rooms
	for child in roomButtonContainer.get_children():
		if child is Button:
			child.queue_free()
	
	found_lobbies = []
	statusLabel.visible = true
	statusLabel.text = "Loading..."
	buttons.set_visible(false)


func _on_refresh_pressed() -> void:
	start_ping_search()


func _on_Button_pressed():
	get_parent().change_UI("PlayUI")


func _on_Train_pressed():
	Util.create_singleplayer_lobby(false)


func _on_host_pressed():
	get_parent().change_UI("HostLobbyUI")


func _on_distances_item_selected(index):
	var search_distance = distances.get_item_id(index)
	#init_UI(search_distance)


func _on_JoinDiscord_pressed():
	var res: int = OS.shell_open("https://discord.com/invite/rPbPNmV")
	if res != OK:
		Globals.create_info_popup("Couldn't open your browser.", "Sorry, something went wrong. You can find a link to our discord on our store page though!")
