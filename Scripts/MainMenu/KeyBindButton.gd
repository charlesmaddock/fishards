extends Button

signal new_bind(value)

var active: bool = false

func _ready():
	connect("pressed", Callable(self, "_on_pressed"))


func _input(ev):
	if ev is InputEventKey && active:
		text = OS.get_keycode_string(ev.keycode)
		emit_signal("new_bind", ev.keycode, false)
		active = false
	if ev is InputEventMouseButton && active:
		text = get_mouse_button_text(ev.button_index)
		emit_signal("new_bind", ev.button_index, true)
		active = false


func get_mouse_button_text(index: int) -> String:
	match index:
		MOUSE_BUTTON_LEFT:
			return "LMB"
		MOUSE_BUTTON_RIGHT:
			return "RMB"
		MOUSE_BUTTON_MIDDLE: 
			return"MMB"
		_:
			return "OMB"

func _on_pressed():
	if !active:
		active = true
		text = "..."
