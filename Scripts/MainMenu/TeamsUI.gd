extends Panel


export(PackedScene) var display_player_row_scene: PackedScene

onready var redContainer = $ScrollContainer/VBoxContainer/RedContainer
onready var blueContainer = $ScrollContainer/VBoxContainer/BlueContainer
onready var allContainer = $ScrollContainer/VBoxContainer/AllContainer
onready var redTeamTitle = $ScrollContainer/VBoxContainer/RedContainer/TeamTitle/TeamName
onready var blueTeamTitle = $ScrollContainer/VBoxContainer/BlueContainer/TeamTitle/TeamName
onready var redTeamSwitch = $ScrollContainer/VBoxContainer/RedContainer/TeamTitle/RedSwitch
onready var blueTeamSwitch = $ScrollContainer/VBoxContainer/BlueContainer/TeamTitle/BlueSwitch


func _ready():
	Lobby.connect("lobby_members_updated", self, "_on_lobby_members_updated")
	Lobby.connect("room_settings_updated", self, "_on_room_settings_updated")
	redTeamTitle.modulate = Globals.RED_TEAM_COLOR
	blueTeamTitle.modulate = Globals.BLUE_TEAM_COLOR
	
	yield(get_tree(), "idle_frame")
	update_players()


func _on_switch_red() -> void:
	PacketSender.request_join_team("Red Team")


func _on_switch_blue() -> void:
	PacketSender.request_join_team("Blue Team")


func _on_lobby_members_updated() -> void:
	update_players()


func _on_room_settings_updated() -> void:
	update_players()


func update_players() -> void:
	var lobby_gamemode = RoomSettings.get_gamemode()
	var display_as_teams = lobby_gamemode == GamemodeValues.Gamemodes.TeamDeathmatch || lobby_gamemode == GamemodeValues.Gamemodes.FishBall
	
	for child in redContainer.get_children() + blueContainer.get_children() + allContainer.get_children():
		if child.get_name() != "TeamTitle" && child.get_name() != "Title":
			child.queue_free()
		else: 
			# If we are in a team death match, show team headers, otherwise dont
			if child.get_name() == "TeamTitle":
				child.set_visible(display_as_teams)
			elif child.get_name() == "Title":
				child.set_visible(!display_as_teams)
	
	var my_preferred_team: String
	
	for player_info in Lobby.client_members + Lobby._bot_members:
		var display_player_row = display_player_row_scene.instance()
		
		if display_as_teams == true:
			var container = redContainer if player_info["team"] == "Red Team" else blueContainer
			container.add_child(display_player_row)
		else:
			allContainer.add_child(display_player_row)
		
		display_player_row.display(player_info, display_as_teams)
		if player_info["id"] == SteamValues.STEAM_ID:
			my_preferred_team = player_info["team"]
	
	# Update switch buttons 
	if my_preferred_team == "Red Team":
		redTeamSwitch.hide()
		#if Lobby.can_join_team(my_preferred_team, "Blue Team") == false:
		#	blueTeamSwitch.hide()
		#else:
		blueTeamSwitch.show()
	else:
		blueTeamSwitch.hide()
		#if Lobby.can_join_team(my_preferred_team, "Red Team") == false:
		#	redTeamSwitch.hide()
		#else:
		redTeamSwitch.show()
