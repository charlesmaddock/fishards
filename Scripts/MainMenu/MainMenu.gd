extends Spatial


onready var camera: Camera = Globals.camera
onready var _ui: Control = $UI


var change_to_UI_on_ready: String = ""
 

func _ready():
	if has_node("CameraTransform") && has_node("FishardIslandCameraTransform") && Globals.camera != null:
		var camera_transform = get_node("CameraTransform")
		var fishard_island_transform = get_node("FishardIslandCameraTransform")
		#Globals.fishard_ui_transform = fishard_island_transform
		camera.set_translation(Globals.prev_camera_pos)
		camera.rotation = camera_transform.rotation
	
	Globals.set_ui_interaction_mode(Globals.UIInteractionModes.UI)
	MusicAndSfxHandler.play_track(MusicAndSfxHandler.tracks.MAIN_MENU)
	
	if change_to_UI_on_ready != "":
		_ui.change_UI(change_to_UI_on_ready)
	
	if Globals.play_splash_anim == true:
		Globals.play_splash_anim = false 
		get_node("ColorRect/AnimationPlayer").play("fade")
	else:
		get_node("ColorRect").set_visible(false)
	
	Globals.emit_signal("main_menu_ready")


func _process(delta: float):
	if Util.safe_to_use(camera) == true:
		camera.set_translation(camera.global_transform.origin.linear_interpolate(Globals.camera_lerp_to, delta * 5))
		camera.set_rotation_degrees(camera.rotation_degrees.linear_interpolate(Globals.camera_lerp_to_rot, delta * 7))
		Globals.prev_camera_pos = camera.global_transform.origin

