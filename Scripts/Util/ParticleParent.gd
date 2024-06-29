extends Spatial
class_name ParticleParent

var particle_children: Array = []

export(bool) var emit_on_ready = true

func _ready():
	for child in get_children():
		if child is Particles:
			particle_children.append(child)
			if emit_on_ready:
				child.emitting = true


func play_all():
	for particles in particle_children:
		particles.emitting = true

func stop_all():
	for particles in particle_children:
		particles.emitting = false


func play_index(index: int):
	if get_child(index) is Particles:
		get_child(index).emitting = true
	else:
		printerr("Tried to play an index that is not a particle system!")
