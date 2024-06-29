extends Spatial


onready var flameSound1 = $FlameSound1
onready var flameSound2 = $FlameSound2


var sound_length = 0.9
var flame_delta_1: float = sound_length / 2
var flame_delta_2: float = sound_length
var stop: bool


func _ready():
	get_parent().connect("destroyed", self, "_on_destroyed")


func _on_destroyed(_id, _of_old_age):
	stop = true


# Create cool flame sound basically
func _process(delta):
	if stop == false:
		flame_delta_1 += delta
		flame_delta_2 += delta
		
		if flame_delta_1 >= sound_length:
			flame_delta_1 = 0
			play1()
		
		if flame_delta_2 >= sound_length:
			flame_delta_2 = 0
			play2()


func play1():
	var pitch: float = 1 + Util.rand.randf_range(-0.1, 0.1)
	flameSound1.pitch_scale = pitch
	flameSound1.play()


func play2():
	var pitch: float = 1 + Util.rand.randf_range(-0.1, 0.1)
	flameSound2.pitch_scale = pitch
	flameSound2.play()
