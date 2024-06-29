extends Control


onready var fish1 = $Panel/ViewportContainer/Viewport/Scene/Winners2/fish1/Armature/Skeleton/Fish
onready var fish2 = $Panel/ViewportContainer/Viewport/Scene/Winners2/fish2/Armature/Skeleton/Fish
onready var fish3 = $Panel/ViewportContainer/Viewport/Scene/Winners2/fish3/Armature/Skeleton/Fish
onready var fishName1 = $Panel/winnerPlacesUI/winnerName1
onready var fishName2 = $Panel/winnerPlacesUI/winnerName2
onready var fishName3 = $Panel/winnerPlacesUI/winnerName3
onready var title = $Panel/Title
onready var desc = $Panel/Desc


func _ready():
	set_visible(false)


func show_all_round_winners() -> void:
	Util.log_print("WinnersDisplay", "show_all_round_winners()")
	var players_node = Util.get_players_node()
	if players_node != null:
		var all_round_winners_obj = RoomSettings.get_all_round_winners()
		
		set_visible(true)
		
		for i in 3:
			get("fish" + str(i+1)).set_visible(false)
			get("fishName" + str(i+1)).set_visible(false)
		
		var i = 1
		var sorted_all_round_winners = all_round_winners_obj["first"] + all_round_winners_obj["second"] + all_round_winners_obj["third"]
		for winner_obj in sorted_all_round_winners:
			if get("fish" + str(i)) != null:
				var player_component: Player = players_node.get_player_component(winner_obj.player_id, "show all round winners")
				if player_component != null:
					var fish_model = get("fish" + str(i))
					var fish_name = get("fishName" + str(i))
					
					fish_model.set_visible(true)
					fish_name.set_visible(true)
					fish_name.text = player_component.get_username()
					CustomizePlayer.apply_skin_to_fishard(player_component.parent_entity, player_component.get_skin(), fish_model)
					
				i += 1
		
		if all_round_winners_obj["first"].size() == 1:
			var winner_obj = all_round_winners_obj["first"][0]
			var player_component: Player = players_node.get_player_component(winner_obj["player_id"], "show all round winners 1")
			if player_component != null:
				title.text = player_component.get_username() + " won the game!"
				desc.text = "They won " + str(winner_obj["score"]) + " out of " + str(RoomSettings.settings["rounds"]) + " rounds and got " + str(winner_obj["kills"]) + " kills!"
		else:
			var winner_obj = all_round_winners_obj["first"][0]
			var first_place_usernames = []
			for leaderboard_obj in all_round_winners_obj["first"]:
				var player_component: Player = players_node.get_player_component(leaderboard_obj["player_id"], "show all round winners 2")
				if player_component != null:
					first_place_usernames.append(player_component.get_username())
			
			var title_text = Util.generate_pretty_list(first_place_usernames) + " tied!"
			var desc_text = "However, " + first_place_usernames[0] + " got the most kills and is therefore the game's winner!"
			title.text = title_text
			desc.text = desc_text
	
	MusicAndSfxHandler.play_sound(MusicAndSfxHandler.sounds.WIN_SCREEN)
	Util.log_print("WinnersDisplay", "show_all_round_winners() complete")
