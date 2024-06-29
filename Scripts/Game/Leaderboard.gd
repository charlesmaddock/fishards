extends Control


onready var displayPlayers: VBoxContainer = $PanelContainer/MarginContainer/VBoxContainer/DisplayPlayersContainer
onready var vbox: VBoxContainer = $PanelContainer/MarginContainer/VBoxContainer
onready var margin = $PanelContainer/MarginContainer
onready var panel = $PanelContainer
onready var pingLabel: Label = $PanelContainer/MarginContainer/VBoxContainer/Title/ping


var displayPlayerScene: PackedScene = preload("res://Scenes/MainMenu/DisplayPlayer.tscn")
var _player_scores: Array


func _ready():
	Lobby.connect("player_killed", self, "_on_player_killed")
	AchievementHandler.connect("round_won", self, "_on_round_won")
	Lobby.connect("lobby_members_updated", self, "_on_lobby_members_updated")
	Lobby.connect("ping_updated", self, "_on_ping_updated")
	set_visible(false)
	for i in 20:
		var display_player = displayPlayerScene.instance()
		displayPlayers.add_child(display_player)
	
	if Lobby.is_host:
		Lobby.connect("broadcast_leaderboard_req", self, "_on_broadcast_leaderboard_req")
		Lobby.connect("teams_set", self, "_on_teams_set")
	else:
		PacketSender.call_deferred("request_leaderboard")


func _on_ping_updated(ping, ping_avg) -> void:
	if ping == 0:
		pingLabel.set_visible(false)
	else:
		pingLabel.set_visible(true)
		var ping_ms = round(ping * 1000)
		pingLabel.text = "ping: " + str(ping_ms) + " ms"


func _on_player_killed(_killed_id: int, _killer_id: int, _with_spell: int) -> void:
	yield(get_tree(), "idle_frame")
	host_refresh_leaderboard()


func _on_round_won(_is_winner) -> void:
	host_refresh_leaderboard()


func _on_lobby_members_updated() -> void:
	yield(get_tree(), "idle_frame")
	host_refresh_leaderboard()


func _on_broadcast_leaderboard_req() -> void:
	yield(get_tree(), "idle_frame")
	host_refresh_leaderboard()


func _on_teams_set() -> void:
	yield(get_tree(), "idle_frame")
	host_refresh_leaderboard()


func _input(event):
	if event.is_action_pressed("toggle_leaderboard"):
		set_visible(true)
		render_player_scores(_player_scores)
	
	if event.is_action_released("toggle_leaderboard"):
		set_visible(false)


func host_refresh_leaderboard() -> void:
	if Lobby.is_host:
		var teams = Lobby.get_teams()
		var player_scores: Array
		
		for team_info in teams:
			for player_id in team_info["member_scores"]:
				player_scores.append({"id": player_id, "score": team_info["member_scores"][player_id], "rounds_won": RoomSettings.get_amount_of_rounds_won(player_id)})
		
		player_scores.sort_custom(RoomSettings.score_sorter, "sort")
		player_scores.invert()
		
		PacketSender.broadcast_updated_leaderboard(player_scores)


func p2p_set_player_scores(player_scores: Array) -> void:
	_player_scores = player_scores
	render_player_scores(player_scores)


func render_player_scores(player_scores) -> void:
	var team_mode = GamemodeValues.get_current_rounds_teammode()
	var show_team_color = team_mode == GamemodeValues.TeamModes.RED_BLUE_TEAMS
	
	# Clear previous texts
	for child in displayPlayers.get_children():
		child.set_visible(false)
	
	var child_index: int = 0
	for player_score_obj in player_scores:
		var scorers_player_info = null
		for player_info in Lobby.client_members + Lobby._bot_members:
			if player_info["id"] == player_score_obj["id"]:
				scorers_player_info = player_info
				break
		
		if scorers_player_info != null && child_index < displayPlayers.get_child_count():
			var display_player = displayPlayers.get_child(child_index)
			display_player.set_visible(true)
			display_player.display(scorers_player_info, show_team_color, player_score_obj["score"], player_score_obj["rounds_won"])
			child_index += 1
	
	shrink_size()


func shrink_size():
	displayPlayers.rect_size.y = displayPlayers.get_minimum_size().y
	vbox.rect_size.y = vbox.get_minimum_size().y
	margin.rect_size.y = margin.get_minimum_size().y
	panel.rect_size.y = panel.get_minimum_size().y
	
