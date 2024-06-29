extends MainMenuUIChild


func _input(event):
	if event.is_action_pressed("ui_cancel") && visible == true:
		get_parent().change_UI("MainMenuUI")


func _on_Back_pressed():
	get_parent().change_UI("MainMenuUI")


func _on_JoinDiscord_pressed():
	var res: int = OS.shell_open("https://discord.com/invite/rPbPNmV")
	if res != OK:
		Globals.create_info_popup("Couldn't open your browser.", "Sorry, something went wrong. You can find a link to our discord on our store page though!")


func _on_RedoTraining_pressed():
	Util.create_singleplayer_lobby(true)
