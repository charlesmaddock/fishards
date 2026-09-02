extends SubViewportContainer

@onready var file_name: LineEdit = $Save/LineEdit

@onready var animationPlayer: AnimationPlayer = $SubViewport/AnimationPlayer
@onready var position: Node3D = $SubViewport/Position
@onready var viewport: SubViewport = $SubViewport
@onready var label: Label = $Save/Label

var img: Image
var dir_path: String =  "user://generated_icons/"


func capture_img():
	var dir = DirAccess.new()
	if !dir.dir_exists(dir_path):
		dir.make_dir(dir_path)
	
	var path: String = dir_path + file_name.text + ".png"
	if file_name.text != "":
		
		img = viewport.get_texture().get_data()
		img.convert(Image.FORMAT_RGBA8)
		img.flip_y()
		if img.save_png(path) == OK:
			label.text = "image saved!"
		else:
			label.text = "error saving image"
	else:
		label.text = "name the file! (reload the scene)"



func _on_Save_pressed():
	capture_img()
