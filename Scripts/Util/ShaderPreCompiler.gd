extends Node3D


func _ready():
	for child in get_children():
		activate_children_particles(child)


func activate_children_particles(parent) -> void:
	if parent is Particles:
		parent.emitting = true
	
	if parent is AnimationPlayer:
		parent.stop()
	
	if parent.has_method("set_position"):
		parent.set_position(Vector3(0, -10, 0))
	
	for child in parent.get_children():
		activate_children_particles(child)
