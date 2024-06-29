tool
extends VBoxContainer

export(Globals.Elements) var element: int
export(Texture) var element_icon


onready var sprite = $TextureRect
onready var picker = $PickerContainer/Picker
onready var label = $PickerContainer/Label
onready var selected = $PickerContainer
onready var greyCover = $TextureRect/greyCover
onready var element_display = get_parent()
onready var background = $Control/Sprite

var label_color: Color
var _selected: bool


func _ready():
	sprite.texture = element_icon


func set_selected(val: bool, display_only: bool, show_key: bool, color: Color, selected_index: String = "") -> void:
	_selected = val
	
	# These are needed before _ready() in some cases
	picker = $PickerContainer/Picker
	label = $PickerContainer/Label
	selected = $PickerContainer
	
	picker.visible = !display_only
	label.visible = show_key
	label_color = color
	background.set_visible(display_only == false && val == true)
	
	if val == false:
		selected.modulate = Color(0,0,0,0)
		sprite.modulate = Color("#8e8e8e")
		
	else:
		selected.modulate = label_color
		label.modulate = Color.white
		if sprite: # STRANGE BUG BUT IT WORKS LIKE THIS OK?
			sprite.modulate = Color.white
	
	label.text = selected_index


func set_preview_picker(visible: bool):
	if _selected == false:
		if visible == true:
			selected.modulate = label_color
			label.modulate = Color(0,0,0,0)
			picker.modulate = Color.white
			background.set_visible(true)
		else:
			selected.modulate = Color(0,0,0,0)
			background.set_visible(false)


func _on_picker_mouse_entered():
	if selected.modulate != Color(0,0,0,0):
		selected.modulate = Color(1, 1, 1, 1)
	
	# We can only move already selected elements
	if _selected == true:
		element_display.handle_element_entered(self)
		CursorHandler.set_drag()
		


func _on_picker_mouse_exited():
	if selected.modulate != Color(0,0,0,0):
		selected.modulate = label_color
	element_display.handle_element_exited(self)
	CursorHandler.set_default()
