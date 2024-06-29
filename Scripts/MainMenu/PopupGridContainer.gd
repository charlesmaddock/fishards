extends VBoxContainer

onready var gridContainer: GridContainer = $GridContainer
onready var label: Label = $Label

export(bool) var button_disabled = true
export(String) var category_name = "none"

func _ready():
	label.text = category_name


func add_color_button(color_button: Button):
	gridContainer.add_child(color_button)


