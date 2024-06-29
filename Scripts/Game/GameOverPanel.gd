extends PanelContainer


onready var gameOverPanelTitle = $Margin/VBox/Title
onready var gameOverPanelText = $Margin/VBox/Text
onready var confetti: Node2D = $Confetti


func p2p_show_gameover_panel(winner_ids: Array, text: String, winner_title: String, loser_title: String):
	var is_winner = false
	for id in winner_ids:
		if id == SteamValues.STEAM_ID:
			is_winner = true
			break
	
	AchievementHandler.emit_signal("round_won", is_winner)
	
	var title = ""
	if is_winner == true:
		MusicAndSfxHandler.play_sound(MusicAndSfxHandler.sounds.WIN)
		modulate = Color("#a1e099")
		#play_confetti() #ugly rn so don't play
		if winner_title == "":
			title = "You Won!"
		else:
			title = winner_title
	else:
		MusicAndSfxHandler.play_sound(MusicAndSfxHandler.sounds.LOSE)
		modulate = Color("#f76868")
		if loser_title == "":
			title = "You Lost!"
		else:
			title = loser_title
	
	call_deferred("set_visible", true)
	
	gameOverPanelTitle.text = title
	gameOverPanelText.text = text


func hide_gameover_panel() -> void:
	set_visible(false)


func play_confetti() -> void:
	for particles in confetti.get_children():
		if particles is Particles2D:
			particles.emitting = true
