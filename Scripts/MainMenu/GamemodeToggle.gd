extends PanelContainer


onready var label = $HBox/Label

export(GamemodeValues.Gamemodes) var gamemode: int
export(Texture) var gamemode_texture: Texture
export(bool) var checked: bool

signal gamemodes_selected(gamemode)


var is_hovering_over: bool = false


func _input(event):
	if Input.is_mouse_button_pressed(BUTTON_LEFT) && is_hovering_over == true:
		_on_CheckBox_pressed()


func _ready():
	get_node("HBox/Icon/sprite").texture = gamemode_texture
	label.text = GamemodeValues.get_gamemode_title(gamemode)
	get_node("HBox/CheckBoxContainer/CheckBox").pressed = checked


func toggle(val: bool) -> void:
	get_node("HBox/CheckBoxContainer/CheckBox").pressed = val
	var color = Color.white if val == true else Color("#656565")
	label.set("custom_colors/font_color", color)


func _on_CheckBox_pressed():
	toggle(true)
	emit_signal("gamemodes_selected", gamemode)


func _on_mouse_entered():
	is_hovering_over = true
	if get_node("HBox/CheckBoxContainer/CheckBox").pressed == false:
		label.set("custom_colors/font_color", Color.white)


func _on_mouse_exited():
	is_hovering_over = false
	if get_node("HBox/CheckBoxContainer/CheckBox").pressed == false:
		label.set("custom_colors/font_color", Color("#656565"))
