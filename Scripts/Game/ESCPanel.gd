extends Node


onready var _color_rect = $ColorRect
onready var containerPanel = $ColorRect/Panel
onready var UI = $ColorRect/UI
onready var elementSelectPanel = $ColorRect/Panel/MarginContainer/VBoxContainer/Panel
onready var noElementSelectPanel = $ColorRect/Panel/MarginContainer/VBoxContainer/NoElementsPanel



func _ready():
	_color_rect.visible = false
	
	var is_default_element_mode = RoomSettings.get_element_mode() == Globals.ElementModes.DEFAULT
	elementSelectPanel.set_visible(is_default_element_mode)
	noElementSelectPanel.set_visible(!is_default_element_mode)
	
	containerPanel.rect_size.y = containerPanel.get_minimum_size().y


func _input(event):
	if event.is_action_pressed("ui_cancel"):
		toggle_visible(!_color_rect.visible)
		UI.change_UI("")


func toggle_visible(value: bool) -> void:
	_color_rect.visible = value
	if value == false:
		Globals.set_ui_interaction_mode(Globals.UIInteractionModes.GAMEPLAY)
	else:
		Globals.set_ui_interaction_mode(Globals.UIInteractionModes.UI)


func _on_resume_button_pressed():
	toggle_visible(false)


func _on_leave_button_pressed():
	if Lobby.is_host == true && Globals.in_single_player == false:
		Util.log_print("ESCPanel", "Host: Pressed leave, opening the lobby")
		PacketSender.broadcast_all_rounds_over()
	else:
		Lobby.leave_lobby("esc panel")


func _on_settings_button_pressed():
	UI.change_UI("SettingsUI")


func _on_update_elements_button_pressed():
	_on_resume_button_pressed()
