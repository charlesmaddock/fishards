extends Control


func _ready():
	zoom_camera(true)


func change_UI(name: String) -> void:
	if name == "":
		for ui_child in get_children():
			ui_child.visible = false
		return
	
	var ui_found: bool = false
	for ui_child in get_children():
		ui_child.visible = false
		if ui_child.name == name:
			ui_child.visible = true
			zoom_camera(ui_child.zoomed_in)
			if ui_child.has_method("init_UI"):
				ui_child.init_UI()
			ui_found = true
	
	if !ui_found:
		if name != "MainMenuUI":
			Util.log_print("UI", "ERROR: Tried to change to a UI that does not exist: " + name)
	else:
		pass
		#Util.log_print("UI", "Switched to " + name)


func zoom_camera(zoom_out: bool):
	if zoom_out:
		Globals.camera_lerp_to = Globals.camera_zoom_out_pos
		Globals.camera_lerp_to_rot = Globals.camera_standard_rot
	else: 
		Globals.camera_lerp_to = Globals.camera_zoom_in_pos
		Globals.camera_lerp_to_rot = Globals.camera_standard_rot


func zoom_to_fishard_sceen():
	Globals.camera_lerp_to = Globals.fishard_ui_zoom_pos
	#Globals.camera.rotation_degrees = Globals.fishard_ui_rot
	Globals.camera_lerp_to_rot = Globals.fishard_ui_rot
