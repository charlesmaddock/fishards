extends Node3D

@export var beam_max_length: float = 14.0;

var beam_meshes: Array = []

@onready var startEffect: Node3D = $StartEffect
@onready var endEffect: Node3D = $EndEffect
@onready var beam: Node3D = $Beam

func _ready():
	for mesh in beam.get_children():
		if mesh is MeshInstance3D:
			beam_meshes.append(mesh)


func play_beam_effect(length: float):
	length -= 1 # Just for the looks
	
	if length > beam_max_length:
		length = beam_max_length
	for mesh in beam_meshes:
		mesh.get_surface_override_material(0).set_shader_parameter("beam_length", length)
	beam.scale.z = length
	endEffect.position.z = length
