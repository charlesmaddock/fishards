extends Spatial

export(float) var beam_max_length = 14.0;

var beam_meshes: Array = []

onready var startEffect: Spatial = $StartEffect
onready var endEffect: Spatial = $EndEffect
onready var beam: Spatial = $Beam

func _ready():
	for mesh in beam.get_children():
		if mesh is MeshInstance:
			beam_meshes.append(mesh)


func play_beam_effect(length: float):
	length -= 1 # Just for the looks
	
	if length > beam_max_length:
		length = beam_max_length
	for mesh in beam_meshes:
		mesh.get_surface_material(0).set_shader_param("beam_length", length)
	beam.scale.z = length
	endEffect.translation.z = length
