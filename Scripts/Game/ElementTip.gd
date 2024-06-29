extends Control


onready var title = $Panel/VBoxContainer/tip
onready var text = $Panel/VBoxContainer/text
onready var animationPlayer = $AnimationPlayer


var shown_once: bool = false


func _ready():
	set_visible(false)
	
	# Don't show tip in Tutorial
	if RoomSettings.get_rounds_gamemode() == GamemodeValues.Gamemodes.Tutorial:
		shown_once = true


func show_tip(is_hold_down: bool = false) -> void:
	if shown_once == false:
		set_visible(true)
		shown_once = true
		animationPlayer.play("show")
		
		if is_hold_down == false:
			var print_this: String = "Press "
			for num in RoomSettings.get_element_amount():
				var key_code = Util.get_key_code("element_" + str(num + 1), Util.InputTypes.KEYBOARD)
				print_this += OS.get_scancode_string(key_code)
				if num < RoomSettings.get_element_amount() - 2:
					print_this += ", "
				elif num == RoomSettings.get_element_amount() - 2:
					print_this += " or "
			print_this += " to make spells. Click to fire. Move with W, A, S, D."
			text.text = print_this
			title.text = "How to play:"
		else:
			title.text = "Pro tip:"
			text.text = "Hold down the mouse button to cast fireballs (or any spell) several times!"


func tip_not_necessary() -> void:
	shown_once = true
	set_visible(false) 
