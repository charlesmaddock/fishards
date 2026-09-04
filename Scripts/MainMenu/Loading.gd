extends Control


@onready var text: Label = $Label
@export var loading_text: String = ""
@export var loading_text_color: Color
var counter: int


func _ready():
	if loading_text != "":
		text.text = loading_text + "..."
		text.modulate = loading_text_color
	else:
		text.text = ""


func _on_timer_timeout():
	counter += 1
	if loading_text != "":
		if counter % 3 == 0:
			text.text = loading_text + "."
		elif counter % 3 == 1:
			text.text = loading_text + ".."
		elif counter % 3 == 2:
			text.text = loading_text + "..."
