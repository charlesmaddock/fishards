extends ParticleParent

export(NodePath) var Beam: NodePath

var beam: Particles
var beam_meshes: Array = []


func _ready():
	var beam = get_node(Beam)
	if beam == null:
		printerr("add node path beam to beamEffect !!")
	
	for i in range(beam.draw_passes):
		beam_meshes.append(beam.get_draw_pass_mesh(i))
	
	set_beam_shader_length(0)


func play_beam_effect(length: float):
	set_beam_shader_length(length)
	play_all()


func set_beam_shader_length(value):
	# Set all shader parameters
	for mesh in beam_meshes:
		mesh.surface_get_material(0).set_shader_param("beam_length", value)
