extends VBoxContainer

@onready var gridContainer: GridContainer = $GridContainer
@onready var label: Label = $Label

@export var button_disabled: bool = true
@export var category_name: String = "none"

func _ready():
	label.text = category_name


func add_color_button(color_button: Button):
	gridContainer.add_child(color_button)


