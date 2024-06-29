extends Control

onready var fpsLabel: Label = $PanelContainer/VBoxContainer/FPSLabel
onready var memLabel: Label = $PanelContainer/VBoxContainer/MemLabel
var _process_iteration: int


func _ready():
	set_process(false)
	visible = false


func _process(delta):
	_process_iteration += 1
	if _process_iteration % 30 == 0:
		fpsLabel.text = "FPS: " + str(Engine.get_frames_per_second())
		memLabel.text = "Mem: " + str(OS.get_static_memory_usage() / 1000000) + " mb"
