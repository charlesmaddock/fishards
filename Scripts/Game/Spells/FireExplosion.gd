extends Spatial


export(Array, NodePath) var on_play_particle_effects


func _ready():
	for i in range(on_play_particle_effects.size()):
		if get_node(on_play_particle_effects[i]) is Particles:
			get_node(on_play_particle_effects[i]).set_emitting(false)
			get_node(on_play_particle_effects[i]).set_one_shot(true)


func play_explosion_anim() -> void:
	for i in range(on_play_particle_effects.size()):
		if get_node(on_play_particle_effects[i]) is Particles:
			get_node(on_play_particle_effects[i]).set_emitting(true)
