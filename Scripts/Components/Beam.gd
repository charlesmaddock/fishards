extends SpatialComponent


export(NodePath) var beam_effect_path
export(float) var beam_length = 12
export(float) var offset_z = -1.6; # Visual adjustment
export(bool) var repeat_length_check = false
export(bool) var pass_through_hurtables = false


var beam_effect
var entities_to_damage: Array
var _effect_played: bool = true


onready var ray1: RayCast = $RayCast
onready var ray2: RayCast = $RayCast2


func _ready():
	#global_transform.origin.z = offset_back;
	ray1.cast_to = Vector3(-0.1, -0.4, beam_length)
	ray2.cast_to = Vector3(0.1, -0.4, beam_length)
	
	# Just remove hurtable mask
	if pass_through_hurtables == true:
		ray1.collision_mask -= 2
		ray2.collision_mask -= 2
	
	beam_effect = get_node(beam_effect_path)
	if beam_effect == null:
		printerr("No valid beam effect node path in Beam component!")
		return
	
	_effect_played = false


func _physics_process(delta):
	if !_effect_played || repeat_length_check == true:
		var hit_ray_1: bool = check_collision(ray1)
		var hit_ray_2: bool = check_collision(ray2)
		
		# If both beams miss use default length
		if hit_ray_1 == false && hit_ray_2 == false:
			set_beam_length(beam_length)
		
		_effect_played = true


func check_collision(ray) -> bool:
	var beam_stopped: bool = false
	while beam_stopped == false:
		var collision_hit = ray.get_collider()
		if collision_hit == null:
			beam_stopped = true
			break
		
		var hit_entity = Util.get_entity_from_area(collision_hit)
		if hit_entity != null:
			var reflect_projectile_comp = hit_entity.get_component_of_type(Globals.ComponentTypes.ReflectProjectiles)
			if reflect_projectile_comp != null:
				var can_pass_through: bool = reflect_projectile_comp.can_pass_through(parent_entity)
				if can_pass_through == true:
					ray.add_exception(collision_hit)
					ray.force_raycast_update()
				else:
					beam_stopped = true
			else:
				beam_stopped = true
		elif collision_hit is StaticBody:
			beam_stopped = true
		else:
			ray.add_exception(collision_hit)
			ray.force_raycast_update()
	
	if ray.is_colliding():
		var collision_point: Vector3 = ray.get_collision_point()
		var collision_length = get_global_transform().origin.distance_to(collision_point) + offset_z
		if collision_length < 0:
			collision_length = 0
		if parent_entity.get_subtype() == Globals.SpellTypes.DASH_BEAM:
			collision_length += 0.5
		set_beam_length(collision_length)
		return true
	else:
		return false


func set_beam_length(collision_length: float) -> void:
	var area: Area = parent_entity.get_area()
	var shape: CollisionShape = area.get_child(0)
	
	# Fix size of area
	shape.transform.origin = Vector3.ZERO + (Vector3.FORWARD * collision_length / 2)
	var box_extents: Vector3 = Vector3(0.4, collision_length / 2 - 0.5, 1)
	shape.get_shape().set_extents(box_extents)
	
	shape.disabled = false
	beam_effect.play_beam_effect(collision_length)
