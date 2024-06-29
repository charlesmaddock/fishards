extends Button

signal new_bind(value)

var active: bool = false

func _ready():
	connect("pressed", self, "_on_pressed")


func _input(ev):
	if ev is InputEventKey && active:
		text = OS.get_scancode_string(ev.scancode)
		emit_signal("new_bind", ev.scancode, false)
		active = false
	if ev is InputEventMouseButton && active:
		text = get_mouse_button_text(ev.button_index)
		emit_signal("new_bind", ev.button_index, true)
		active = false


func get_mouse_button_text(index: int) -> String:
	match index:
		BUTTON_LEFT:
			return "LMB"
		BUTTON_RIGHT:
			return "RMB"
		BUTTON_MIDDLE: 
			return"MMB"
		_:
			return "OMB"

func _on_pressed():
	if !active:
		active = true
		text = "..."
