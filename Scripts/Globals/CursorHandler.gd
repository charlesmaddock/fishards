extends Node


var cross_hair_light = preload("res://Assets/Images/Cursors/crosshair_light.png")
var cross_hair_dark = preload("res://Assets/Images/Cursors/crosshair_dark.png")
var cross_hair_large_dark = preload("res://Assets/Images/Cursors/crosshair_large_dark.png")
var cross_hair_large_light = preload("res://Assets/Images/Cursors/crosshair_large_light.png")
var default = preload("res://Assets/Images/Cursors/fish_cursor2.png")
var drag = preload("res://Assets/Images/Cursors/drag.png")


func set_cross_hair() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CONFINED)
	if OS.window_size.x <= 1920:
		var colored = cross_hair_light if GamemodeValues.current_map_type == GamemodeValues.Maps.Lava else cross_hair_dark
		Input.set_custom_mouse_cursor(colored, Input.CURSOR_ARROW, Vector2(13, 13))
	else:
		var colored = cross_hair_large_light if GamemodeValues.current_map_type == GamemodeValues.Maps.Lava else cross_hair_large_dark
		Input.set_custom_mouse_cursor(colored, Input.CURSOR_ARROW, Vector2(20, 20))


func set_default() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	Input.set_custom_mouse_cursor(default, Input.CURSOR_ARROW, Vector2.ZERO)


func set_drag() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	Input.set_custom_mouse_cursor(drag, Input.CURSOR_ARROW, Vector2(13, 13))
