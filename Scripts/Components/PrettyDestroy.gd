extends Component
class_name PrettyDestroy
var COMPONENT_TYPE: int = Globals.ComponentTypes.PrettyDestroy


export(float) var time_until_destroy = 1


onready var _timer: Timer = $Timer
onready var _on_destroyed_buffer: bool = false


export(Array, NodePath) var destroy_particles_array
export(Array, NodePath) var collide_particles_array
export(Array, NodePath) var destroy_node_array
export(Array, NodePath) var stop_particle_node_array
export(bool) var destroy_area_directly = true
export(NodePath) var on_destroy_animator = null
export(String) var on_destroy_animation_name = ""
export(bool) var set_all_particles_to_one_shots = true


func _ready():
	for i in range(destroy_particles_array.size()):
		if get_node(destroy_particles_array[i]):
			get_node(destroy_particles_array[i]).set_emitting(false)
			if set_all_particles_to_one_shots == true:
				get_node(destroy_particles_array[i]).set_one_shot(true)


func pretty_destroy(of_old_age: bool) -> void:
	if of_old_age == false: 
		play_collided_particles()
	
	if _on_destroyed_buffer == false:
		_timer.set_wait_time(time_until_destroy)
		_timer.connect("timeout", self, "_on_timer_timeout")
		_timer.start()
		_on_destroyed_buffer = true
		
		if destroy_area_directly == true:
			parent_entity.disable_collider(true)
		
		if on_destroy_animator != null && on_destroy_animation_name:
			var animation_player: AnimationPlayer = get_node(on_destroy_animator)
			animation_player.play(on_destroy_animation_name)
		
		# Instead of queue_free we set visible to false to avoid seg fault
		for i in range(destroy_node_array.size()):
			var to_destroy = get_node(destroy_node_array[i])
			if to_destroy != null:
				if to_destroy.has_method("set_visible"):
					to_destroy.set_visible(false)
				if to_destroy.has_method("set_process"):
					to_destroy.set_process(false)
				if to_destroy.has_method("set_physics_process"):
					to_destroy.set_physics_process(false)
		
		# For historical reference: This causes a segmentation fault if 
		# the egg node is added to destroy_node_array
		#for i in range(destroy_node_array.size()):
		#	get_node(destroy_node_array[i]).queue_free()
		
		for j in range(stop_particle_node_array.size()):
			if get_node(stop_particle_node_array[j]) is Particles:
				get_node(stop_particle_node_array[j]).set_emitting(false)
		
		for i in range(destroy_particles_array.size()):
			if get_node(destroy_particles_array[i]) is Particles:
				get_node(destroy_particles_array[i]).set_emitting(true)


func _on_timer_timeout() -> void:
	var room_node = Util.get_room_node()
	if room_node != null:
		room_node.call_deferred("despawn_entity", parent_entity)


func play_collided_particles() -> void:
	for i in range(collide_particles_array.size()):
		if Util.safe_to_use(get_node(collide_particles_array[i])):
			get_node(collide_particles_array[i]).set_emitting(true)
