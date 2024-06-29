extends MainMenuUIChild

var local_settings: Dictionary

onready var masterVolume: Slider = $Control/MarginContainer/VBoxContainer/MasterVolume/MasterVolume
onready var musicVolume: Slider = $Control/MarginContainer/VBoxContainer/MusicContainer/MusicVolume/MusicVolume
onready var SFXVolume: Slider = $Control/MarginContainer/VBoxContainer/MusicContainer/SFXVolume/SFXVolume


onready var spell_bind_buttons: Dictionary = {
	"element_1": $Control/MarginContainer/VBoxContainer/ElementButtons/Element1/Element1,
	"element_2":  $Control/MarginContainer/VBoxContainer/ElementButtons/Element2/Element2,
	"element_3": $Control/MarginContainer/VBoxContainer/ElementButtons/Element3/Element3,
	"element_4": $Control/MarginContainer/VBoxContainer/ElementButtons/Element4/Element4,
	"element_5": $Control/MarginContainer/VBoxContainer/ElementButtons/Element5/Element5,
	"ui_left": $Control/MarginContainer/VBoxContainer/Movement/left/left,
	"ui_up": $Control/MarginContainer/VBoxContainer/Movement/up/up,
	"ui_down": $Control/MarginContainer/VBoxContainer/Movement/down/down,
	"ui_right": $Control/MarginContainer/VBoxContainer/Movement/right/right,
	"cast_spell":  $Control/MarginContainer/VBoxContainer/CastKeybindContainers/CastSpell/CastSpell,
	"reset_elements": $Control/MarginContainer/VBoxContainer/CastKeybindContainers/ResetElements/ResetElements,
	"open_chat": $Control/MarginContainer/VBoxContainer/OtherKeybinds/ChatLabel/Chat,
	"toggle_leaderboard": $Control/MarginContainer/VBoxContainer/OtherKeybinds/LeaderboardLabel/Leaderboard,
}

#onready var aspectRatio : OptionButton = $Control/MarginContainer/VBoxContainer/AspectRatio/AspectRatio
onready var fullscreen: CheckBox = $Control/MarginContainer/VBoxContainer/FirstOtherContainer/Fullscreen/Fullscreen
onready var rightClickToMove: CheckBox = $Control/MarginContainer/VBoxContainer/FiscondOtherContainer/RightClickToMove/RightClickToMove
onready var showCooldowns: CheckBox = $Control/MarginContainer/VBoxContainer/FiscondOtherContainer/ShowCooldowns/ShowCooldowns
onready var minimalHUD: CheckBox = $Control/MarginContainer/VBoxContainer/SecondOtherContainer/MinimalHUD/MinimalHUD
onready var prettyGraphics: CheckBox = $Control/MarginContainer/VBoxContainer/FirstOtherContainer/PrettyGraphics/PrettyGraphics
onready var disableSpellHUD: CheckBox = $Control/MarginContainer/VBoxContainer/SecondOtherContainer/DisableSpellHUD/DisableSpellHUD
onready var disableController: CheckBox = $Control/MarginContainer/VBoxContainer/SecondOtherContainer/DisableController/DisableController
onready var autoClearElements: CheckBox = $"Control/MarginContainer/VBoxContainer/SecondOtherContainer/AutoClearElements/toggle"


func init_UI():
	load_settings()


func _input(event):
	if event.is_action("ui_cancel") && visible == true:
		get_parent().change_UI("MainMenuUI")


func load_settings():
	local_settings = UserSettings.get_settings()
	
	masterVolume.value = local_settings["volumes"]["Master"]
	musicVolume.value = local_settings["volumes"]["Music"]
	SFXVolume.value = local_settings["volumes"]["SFX"]
	fullscreen.pressed = local_settings["fullscreen"]
	prettyGraphics.pressed = local_settings["prettyGraphics"]
	disableSpellHUD.pressed = local_settings["disableSpellHUD"]
	showCooldowns.pressed = local_settings["show_spell_cooldowns"]
	minimalHUD.pressed = local_settings["minimal_HUD"]
	rightClickToMove.pressed = local_settings["allow_click_to_move"]
	autoClearElements.pressed = UserSettings.get_auto_clear_elements()
	#disableController.pressed = local_settings["disableController"] #DISABLED FOR NOW
	
	for key in local_settings["keybinds"].keys():
		if spell_bind_buttons.has(key):
			if local_settings["keybinds"][key] > 10:
				spell_bind_buttons[key].text = OS.get_scancode_string(local_settings["keybinds"][key])
			else:
				spell_bind_buttons[key].text = spell_bind_buttons[key].get_mouse_button_text(local_settings["keybinds"][key])
		else:
			printerr("Could not find node reference to " + key + " add one! (and make sure it has the same key as in the settings dict)")


func _on_Back_pressed():
	get_parent().change_UI("MainMenuUI")
	UserSettings.save_settings()


func _on_MasterVolume_value_changed(value):
	UserSettings.set_bus_volume("Master", value)


func _on_MusicVolume_value_changed(value):
	UserSettings.set_bus_volume("Music", value)


func _on_SFXVolume_value_changed(value):
	UserSettings.set_bus_volume("SFX", value)


func _on_Save_pressed():
	UserSettings.save_settings()


func _on_Reset_pressed():
	UserSettings.reset_to_default()
	UserSettings.save_settings()
	load_settings()


func _on_Element1_new_bind(value, is_mouse):
	UserSettings.set_key_bind("element_1", value, is_mouse)


func _on_Element2_new_bind(value, is_mouse):
	UserSettings.set_key_bind("element_2", value, is_mouse)


func _on_Element3_new_bind(value, is_mouse):
	UserSettings.set_key_bind("element_3", value, is_mouse)


func _on_Element4_new_bind(value, is_mouse):
	UserSettings.set_key_bind("element_4", value, is_mouse)


func _on_Element5_new_bind(value, is_mouse):
	UserSettings.set_key_bind("element_5", value, is_mouse)


func _on_CastSpell_new_bind(value, is_mouse):
	UserSettings.set_key_bind("cast_spell", value, is_mouse)


func _on_ResetSpell_new_bind(value, is_mouse):
	UserSettings.set_key_bind("reset_elements", value, is_mouse)


func _on_Chat_new_bind(value, is_mouse):
	UserSettings.set_key_bind("open_chat", value, is_mouse)


func _on_Leaderboard_new_bind(value, is_mouse):
	UserSettings.set_key_bind("toggle_leaderboard", value, is_mouse)


func _on_Fullscreen_toggled(button_pressed):
	UserSettings.toggle_fullscreen(button_pressed)
	local_settings["fullscreen"] = OS.is_window_fullscreen()
	fullscreen.pressed = local_settings["fullscreen"]


func _on_PrettyGraphics_toggled(button_pressed):
	UserSettings.toggle_pretty_graphics(button_pressed)


func _on_DisableSpellHUD_toggled(button_pressed):
	UserSettings.disable_spell_HUD(button_pressed)


func _on_AutoClearElements_toggled(button_pressed):
	UserSettings.toggle_auto_clear_elements(button_pressed)


func _on_DisableController_toggled(button_pressed):
	UserSettings.disable_controller(button_pressed)


func _on_up_new_bind(value, is_mouse):
	UserSettings.set_key_bind("ui_up", value, is_mouse, true)


func _on_left_new_bind(value, is_mouse):
	UserSettings.set_key_bind("ui_left", value, is_mouse, true)


func _on_down_new_bind(value, is_mouse):
	UserSettings.set_key_bind("ui_down", value, is_mouse, true)


func _on_right_new_bind(value, is_mouse):
	UserSettings.set_key_bind("ui_right", value, is_mouse, true)


func _on_RightClickToMove_toggled(button_pressed):
	UserSettings.toggle_allow_click_to_move(button_pressed)


func _on_ShowCooldowns_toggled(button_pressed):
	UserSettings.toggle_show_spell_cooldowns(button_pressed)


func _on_MinimalHUD_toggled(button_pressed):
	UserSettings.toggle_minimal_HUD(button_pressed)
