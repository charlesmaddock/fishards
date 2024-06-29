extends Control

export(preload("res://Scripts/MainMenu/CustomizePlayer.gd").HatTypes) var hat
export(Texture) var icon: Texture


onready var questionMark: TextureRect = $HatButton/QuestionMark
onready var hatButton: Button = $HatButton
onready var textContainer: VBoxContainer = $HatButton/Control
onready var title: Label = $HatButton/Control/title
onready var desc: Label = $HatButton/Control/desc
onready var new: Panel = $NewNotice


var discovered: bool = false


func _ready():
	hatButton.material = hatButton.material.duplicate()
	hatButton.icon = icon
	hatButton.material.set_shader_param("icon_tex", hatButton.icon)
	
	new.set_visible(false)
	set_discovered(discovered, "Loading...", "Loading...")
	
	if hat == CustomizePlayer.HatTypes.NONE:
		set_discovered(true, "No hat", "")
	
	if discovered == false:
		modulate = Color("#8e8e8e")


func set_discovered(value: bool, title_text: String, desc_text: String):
	if value == false: 
		modulate = Color("#8e8e8e")
	else:
		modulate = Color("#ffffff")
	
	var new_cosmetics = AchievementHandler.get_new_cosmetics()
	if new_cosmetics.find(hat) != -1:
		new.set_visible(true)
	else:
		new.set_visible(false)
	
	if title_text != "":
		title.text = title_text
		desc.text = desc_text
	
	discovered = value
	hatButton.disabled = !value
	questionMark.visible = !value
	hatButton.material.set_shader_param("discovered", value)


func _on_HatButton_pressed():
	CustomizePlayer.set_hat(hat)
	AchievementHandler.cosmetic_isnt_new(hat)
	new.set_visible(false)


func _on_HatButton_mouse_entered():
	if discovered == true:
		textContainer.rect_position += Vector2.UP * 2


func _on_HatButton_mouse_exited():
	if discovered == true:
		textContainer.rect_position -= Vector2.UP * 2
