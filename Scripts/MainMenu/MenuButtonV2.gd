tool
extends Button

export(Color) var font_color: Color
export(Color) var font_highlight_color: Color
export(String) var button_text: String


onready var label = $Label


func _ready():
	label.set("custom_colors/font_color", font_color)
	label.text = button_text


func set_text(new_text: String) -> void:
	label.text = new_text


func set_disabled(val: bool) -> void:
	disabled = val
	if val == true:
		modulate = Color(0.7, 0.7, 0.7)
	else:
		modulate = Color(1, 1, 1)


func _on_Button_mouse_entered():
	if disabled == false:
		MusicAndSfxHandler.play_sound(MusicAndSfxHandler.sounds.HOVER)
		label.set("custom_colors/font_color", font_highlight_color)


func _on_Button_mouse_exited():
	if label != null:
		label.set("custom_colors/font_color", font_color)


func _on_SKIN_mouse_entered():
	pass # Replace with function body.


func _on_Button_pressed():
	if disabled == false:
		MusicAndSfxHandler.play_sound(MusicAndSfxHandler.sounds.CLICK)


func _on_Button_visibility_changed():
	_on_Button_mouse_exited()
