extends ColorRect

var players_id: int 

func display(player_info: Dictionary, show_team_color: bool, score: int = -1, round_won: int = -1) -> void:
	players_id = player_info["id"]
	
	if show_team_color == true:
		if player_info["team"] == "Blue Team":
			color = Globals.BLUE_TEAM_COLOR
		elif player_info["team"] == "Red Team":
			color = Globals.RED_TEAM_COLOR
	
	get_node("vbox/Score/Label").set_visible(score != -1)
	get_node("vbox/Score/Label").text = str(score)
	
	get_node("vbox/RoundsWon/Label").set_visible(round_won != -1)
	get_node("vbox/RoundsWon/Label").text = str(round_won)
	
	get_node("vbox/Name/HBoxContainer/Label").text = player_info["name"]
	get_node("vbox/ElementsDisplay").set_elements(player_info["elmts"], false) # False since we only display
	
	get_node("vbox/Name/HBoxContainer/RankContainer").set_visible(player_info["rank"] != -1)
	
	var rank_color = get_node("vbox/Name/HBoxContainer/RankContainer").display_rank(player_info["rank"])
	get_node("vbox/Name/HBoxContainer/Label").set("custom_colors/font_color", rank_color)
	
	var is_client = player_info["plyr_type"] == Globals.PlayerTypes.CLIENT
	var isnt_me = player_info["id"] != SteamValues.STEAM_ID
	get_node("vbox/KickButtonContainer/KickButton").call_deferred("set_visible", Lobby.is_host && is_client && isnt_me)


func _on_KickButton_pressed():
	Lobby.kick_player(players_id)
