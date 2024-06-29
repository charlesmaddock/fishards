extends Component
class_name Launchable
var COMPONENT_TYPE: int = Globals.ComponentTypes.Launchable


# This is just a model that gives the impression of 
export(Array, NodePath) var launch_spatial_paths
export(bool) var rotate = false
export(bool) var launch_directly = true
export(float) var height: float = 6.0


var _from: Vector3 = Vector3.DOWN
var _to: Vector3 = Vector3.DOWN
var _ground_y_pos: float
var _speed: float
var _dist: float
var _air_time: float
var _total_air_time: float
var _height_modifier: float
var _max_height: float
var _launch_spatials: Array = []
var _landed: bool = false
var _set_invincible: bool = false
var _launch_over: bool = true # A bit confusing but prevents launch directly if needed.
var _landing_indicator

func _ready():
	if launch_directly:
		initialize_launch()


func initialize_launch():
	_launch_spatials.clear()
	for spatial in launch_spatial_paths:
		_launch_spatials.append(get_node(spatial))
	
	if _launch_spatials.size() >= 1:
		if _launch_spatials[0] != null:
			_ground_y_pos = _launch_spatials[0].global_transform.origin.y # bad now player can not be moved relative to its entity
	
	_launch_over = false
	parent_entity.disable_collider(true)
	parent_entity.set_position(_from, true)
	
	if parent_entity.get_type() == Globals.EntityTypes.PLAYER:
		parent_entity.emit_signal("trigger_particle_effect", Globals.ParticleEffects.PUSHED_TRAIL, true, 0)
		parent_entity.emit_signal("trigger_player_animation", Globals.PlayerAnimations.LAUNCHED, Vector2(_to.normalized().x,_to.normalized().z))
		
	var spellcaster = parent_entity.get_component_of_type(Globals.ComponentTypes.SpellCaster)
	if spellcaster != null:
		spellcaster.set_immobilized(true)
	
	# So that a launched player has time to be damaged
	yield(get_tree(), "idle_frame")
	_set_invincible = true
	var health = parent_entity.get_component_of_type(Globals.ComponentTypes.Health)
	if health != null:
		health.set_invincible(true)


func _process(delta: float) -> void:
	var all_safe_to_use = true
	for spatial in _launch_spatials:
		if Util.safe_to_use(spatial) == false:
			all_safe_to_use = false
	
	if all_safe_to_use && _from != Vector3.DOWN && _landed == false && _launch_over == false:
		# In the middle of the arch it should slow down slightly
		var new_pos = _from.linear_interpolate(_to, _air_time / _total_air_time)
		new_pos.y = 0
		var current_dist: float = new_pos.distance_to(_to)
		var current_height = get_height(current_dist)
		
		var temp_speed: float = (((_max_height - current_height) / 3) + 1) * _speed
		_air_time += delta #* temp_speed
		
		parent_entity.set_position(new_pos, true)
		for spatial in _launch_spatials:
			spatial.transform.origin.y = current_height
		
		var x_rotation: float = -80 + (160 * ((_dist - current_dist) / _dist))
		if rotate == true:
			#var dir_3d = _from.direction_to(_to)
			#var y_rot = Util.vector_2_to_y_rot(Vector2(dir_3d.x, dir_3d.y))
			#print("y_rot: ", y_rot)
			for spatial in _launch_spatials:
				spatial.set_rotation_degrees(Vector3(x_rotation, 0, 0)) 
			
		
		if _air_time > _total_air_time:
			_landed = true
		# Shouldn't become non invincible right when landed but a moment before
		elif _air_time > _total_air_time - 0.2 && _set_invincible == true:
			_set_invincible = false
			var health = parent_entity.get_component_of_type(Globals.ComponentTypes.Health)
			if health != null:
				health.set_invincible(false)
	
	if _landed == true && _launch_over == false:
		parent_entity.disable_collider(false)
		parent_entity.emit_signal("landed")
		
		if parent_entity.get_type() == Globals.EntityTypes.PLAYER:
			parent_entity.emit_signal("trigger_particle_effect", Globals.ParticleEffects.PUSHED_TRAIL, false, 0)
			parent_entity.emit_signal("trigger_particle_effect", Globals.ParticleEffects.PUSHED_LANDING, true, 0)
			parent_entity.emit_signal("trigger_player_animation", Globals.PlayerAnimations.LAUNCHED_RECOVER, Vector2.ZERO)
		
		var spellcaster = parent_entity.get_component_of_type(Globals.ComponentTypes.SpellCaster)
		if spellcaster != null:
			spellcaster.set_immobilized(false)
		
		_launch_over = true 
		_landed = false
		for spatial in _launch_spatials:
			spatial.global_transform.origin.y = _ground_y_pos
		if Util.safe_to_use(_landing_indicator):
			_landing_indicator.queue_free()


func get_height(current_dist: float) -> float:
	var x: float = _dist - current_dist
	return (x)*(x-_dist)*_height_modifier
	#return ((_dist * x) + (-1 * pow(x, 2))) / _height_modifier


func launch(from: Vector3, to: Vector3, landing_indicator = null, speed: float = 10) -> void:
	_from = from
	_from.y = 0
	_to = to
	_to.y = 0
	_dist = _from.distance_to(_to)
	_total_air_time = (_dist / speed) 
	_height_modifier = 4*height / (-1*pow(_dist,2))
	_speed = speed
	_landed = false
	_launch_over = false
	_max_height = get_height(_dist / 2)
	_air_time = 0
	
	if !launch_directly:
		initialize_launch()
	
	if landing_indicator != null:
		_landing_indicator = landing_indicator
