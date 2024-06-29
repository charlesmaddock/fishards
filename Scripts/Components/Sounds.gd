extends SpatialComponent
class_name Sounds 
var COMPONENT_TYPE: int = Globals.ComponentTypes.Sounds


onready var _on_create: AudioStreamPlayer3D = $OnCreate
onready var _on_live: AudioStreamPlayer3D = $OnLive
onready var _on_landed: AudioStreamPlayer3D = $OnLanded
onready var _on_destroy: AudioStreamPlayer3D = $OnDestroy


export var on_create_stream: AudioStream
export var on_live_stream: AudioStream
export var on_landed_stream: AudioStream
export var on_destroy_stream: AudioStream
export var stop_create_stream_on_landed: bool


# An entity can die from collision and from old age, this prevents the sound from playing twice
var _on_destroy_sound_played: bool 


func _ready():
	parent_entity.connect("destroyed", self, "_on_destroyed")
	_on_create.stream  = on_create_stream
	_on_live.stream    = on_live_stream
	_on_landed.stream  = on_landed_stream
	_on_destroy.stream = on_destroy_stream
	
	parent_entity.connect("landed", self, "_on_landed")
	
	var pitch: float = Util.rand.randf_range(-0.06, 0.06)
	_on_create.pitch_scale += pitch
	_on_live.pitch_scale += pitch
	_on_destroy.pitch_scale += pitch
	
	_on_create.play()
	_on_live.play()


func _on_destroyed(_id, _of_old_age) -> void:
	if _on_destroy_sound_played == false:
		_on_destroy_sound_played = true
		_on_live.stop()
		_on_destroy.play()


func _on_landed() -> void:
	if stop_create_stream_on_landed == true:
		_on_create.stop()
	_on_landed.play()
