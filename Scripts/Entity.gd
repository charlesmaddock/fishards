tool
extends Spatial
class_name Entity, "res://Assets/Textures/Sprites/Node Icons/entityIcon.png"


var _id: int
var _creator_id: int = -1
var local_transform_update: bool = false
var is_my_client: bool = false
var entity_area: Area = null
var _default_hurtable_mask_colbit: bool
var _default_knockbackable_mask_colbit: bool
var is_grabbed: bool = false
export(bool) var disable_collider_on_ready: bool = false 


# Simple check to see if collision mask and layers have been set when we for
# example try to get the entity area (We don't want to get an area without the correct collision layers)
var _entity_area_setup_done: bool = false


export(int) var manually_set_entity_type: int = -1
export(String) var subtype_name: String = ""
var _entity_type: int = Globals.EntityTypes.UNDEFINED
var _subtype: int = -1


export(bool) var can_move: bool = true 
var broadcast_transform: bool = true
var _lock_rotation_for: float = 0.0
var _lock_direction_for: float = 0.0


# If age_limit is -1 it will live forever
export var age_limit_seconds: float = -1 
var _age: float = 0
var _is_destroyed: bool = false


# Force is slowly decreased with friction, used by ex. knockback
var _force: Vector3 
# Direction is reset every update, used by ex. projectile and player input
var _direction: Vector3 
var _prev_pos: Vector3
var _is_trapped: bool = false 
var _trapped_for: float
var _trapped_time: float
var _kinematic_body: KinematicBody = null


# All clients except the player who sent the target value will lerp towards these
var _target_position: Vector3
var _lerp_time: float = 0.001
var _time_between_prev_and_target_pos: float = 0.001
var _time_since_previous_pos_packet: float = 0.001
var _is_lerping_pos: bool
var _target_rotation: float
var _rot_speed: float = 25
var _is_lerping_to_target_rot: bool


# Entity acts as a signal hub/event bus where components can listen
# and emit signals creating complex decoupled behaviour.
signal dealt_damage(amount, hit_entity)
signal took_damage(amount, damager_entity)
signal add_health(amount)
signal update_max_health(value)
signal no_health()
signal destroyed(id, of_old_age)
signal landed()
signal trigger_player_animation(animation_nr, dir)
signal trigger_particle_effect(particle_nr, emitting, y_rot)
signal cast_spell(spell_type, cast_pos)
signal released_spell()


"""
Getter Functions
"""
func get_id() -> int:
	return _id


func get_age() -> float:
	return _age


func get_is_trapped() -> bool:
	var player_component = get_component_of_type(Globals.ComponentTypes.Player)
	if player_component != null:
		return _is_trapped || player_component.get_is_frozen()
	
	return _is_trapped


func get_rot() -> float:
	return get_rotation().y


func get_global_rot() -> float:
	return global_transform.basis.get_euler().y


func get_pos() -> Vector3:
	return global_transform.origin


func get_type() -> int:
	return _entity_type


func get_subtype() -> int:
	return _subtype


func get_target_pos_move_dir() -> Vector3:
	var dir = _target_position - _prev_pos 
	dir.y = 0
	return dir


func get_move_dir_v3() -> Vector3:
	return _target_position - _prev_pos


func get_move_dir_v2() -> Vector2:
	var v3: Vector3 = _target_position - _prev_pos
	return Vector2(v3.x, v3.z)


func get_force() -> Vector3:
	return _force


func get_area() -> Area:
	if _entity_area_setup_done == false:
		_entity_area_setup()
	
	if entity_area != null:
		return entity_area
	
	var children = get_children()
	for child in children:
		if child is Area:
			return child
	
	printerr("This entity doesn't have an area: ", get_type_names())
	return null


func get_static_body() -> StaticBody:
	var children = get_children()
	for child in children:
		if child is StaticBody:
			return child
	
	return null


func get_creator_id() -> int:
	if _creator_id == -1:
		printerr("Tried to access the creator id of an entity without one ", name)
	return _creator_id


func get_kinematic() -> KinematicBody:
	return _kinematic_body


func allowed_to_move() -> bool:
	if _is_trapped == false:
		return true
	return false

"""
Setter Functions
"""
func set_target_rotation(target_rotation: float, speed: float = -1) -> void:
	_is_lerping_to_target_rot = true
	_target_rotation = target_rotation
	if speed != -1:
		_rot_speed = speed


func set_target_position(pos: Vector3) -> void:
	if pos != Vector3.ZERO:
		_is_lerping_pos = true
		_prev_pos = global_transform.origin
		_lerp_time = 0
		_time_between_prev_and_target_pos = 1 / float(ProjectSettings.get_setting("physics/common/physics_fps")) # _time_since_previous_pos_packet + 0.001
		_time_since_previous_pos_packet = 0
		_target_position = pos


# Kind of hacky
func set_position_directly(pos: Vector3) -> void:
	_is_lerping_pos = false
	_prev_pos = pos
	_lerp_time = 1
	_time_between_prev_and_target_pos = 1
	_target_position = pos
	set_position(pos, true)


func untrap() -> void:
	var player = get_component_of_type(Globals.ComponentTypes.Player)
	if player != null:
		PacketSender.broadcast_freeze_info(_id, 0, false)
	
	_is_trapped = false


func set_trapped_w_duration(trap_time: float, ice_freeze: bool = false) -> void:
	# Cannot set a player trapped whilst they are trapped
	if _is_trapped == false:
		_trapped_for = 0
		_trapped_time = trap_time
		_is_trapped = true
		if ice_freeze == true:
			var player = get_component_of_type(Globals.ComponentTypes.Player)
			if player != null:
				lock_rotation_w_duration(trap_time)
				PacketSender.broadcast_freeze_info(_id, 0, true)


func lock_rotation_w_duration(time: float) -> void:
	 _lock_rotation_for = time


func set_rot(new_rotation: float, ignore_lock: bool = true) -> void:
	if _lock_rotation_for <= 0.0 || ignore_lock == false:
		_is_lerping_to_target_rot = false
		set_rotation(Vector3(0, new_rotation, 0))


# Recommended way of positioning entities
# Actually sets the postion of the entire entity.
func set_position(new_position: Vector3, force: bool = false) -> void:
	if local_transform_update == true || force == true:
		if _kinematic_body != null:
			# Force kinematics so to be on the ground
			if new_position.y != 0:
				new_position.y = 0
			
			_kinematic_body.transform.origin = new_position
		else:
			transform.origin = new_position
	else:
		printerr("Tried to set position of ", get_type_names(), " that isn't controlled locally, this may result in positions in the host and others clients being unsyncronised.")


func add_force(dir: Vector3) -> void:
	_force += dir
	
	if _force.length_squared() > Globals.MAX_FORCE * Globals.MAX_FORCE: 
		_force = _force.normalized() * Globals.MAX_FORCE


func set_force(force: Vector3) -> void:
	_force = force


func add_direction(dir: Vector3) -> void:
	if allowed_to_move() == true:
		_direction += dir


func set_age(val: float) -> void:
	_age = val


func set_age_limit(val: float) -> void:
	age_limit_seconds = val


func set_kinematic_body(kinematic_body: KinematicBody) -> void:
	_kinematic_body = kinematic_body
	kinematic_body.transform.origin = transform.origin
	transform.origin = Vector3.ZERO
	kinematic_body.name = str(_id)


func set_creator_id(value: int) -> void:
	_creator_id = value


func disable_collider(val: bool) -> void:
	if Util.safe_to_use(get_area()):
		get_area().get_child(0).disabled = val
		if _kinematic_body != null:
			_kinematic_body.get_child(0).disabled = val
		
		var static_body: StaticBody = get_static_body()
		if static_body != null:
			static_body.get_child(0).disabled = val


func _exit_tree():
	if not Engine.editor_hint:
		self.queue_free()


"""
Starter Functions
"""
func _ready():
	_entity_area_setup()
	
	# If these values have been set manually, which they normally do not 
	# have to since it is done automatically, set the right values 
	if subtype_name != "" && manually_set_entity_type != Globals.EntityTypes.UNDEFINED:
		_entity_type = manually_set_entity_type
		
		if _entity_type == Globals.EntityTypes.ENVIRONMENT:
			_subtype = Globals.EnvironmentTypes[subtype_name]
		elif _entity_type == Globals.EntityTypes.SPELL:
			_subtype = Globals.SpellTypes[subtype_name]
		elif _entity_type == Globals.EntityTypes.PLAYER:
			_subtype = Globals.PlayerTypes[subtype_name]


func init_entity(id: int, is_client: bool, should_update_transform_locally: bool, entity_type: int, entity_subtype: int, spawn_point: Vector3, creator_id: int = -1) -> void:
	_id = id
	is_my_client = is_client
	local_transform_update = should_update_transform_locally
	_entity_type = entity_type
	_subtype = entity_subtype
	_creator_id = creator_id
	
	if spawn_point != Vector3.ZERO:
		set_position_directly(spawn_point)


"""
Update Functions
"""
func _process(delta):
	_time_since_previous_pos_packet += delta
	if _is_lerping_pos == true:
		_lerp_time += delta
		if local_transform_update == true:
			if _kinematic_body != null && Lobby.is_host:
				_kinematic_body.move_and_slide((_direction + _force))
				_kinematic_body.global_transform.origin.y = 0
				global_transform.origin = _kinematic_body.global_transform.origin
			else:
				global_transform.origin = _prev_pos.linear_interpolate(_target_position, clamp(_lerp_time / _time_between_prev_and_target_pos, 0, 1))
		else:
			global_transform.origin = _prev_pos.linear_interpolate(_target_position, clamp(_lerp_time / _time_between_prev_and_target_pos, 0, 1))


func _physics_process(delta: float) -> void:
	# Don't _physics_process() this node in the editor, only in game
	if not Engine.editor_hint:
		_lock_rotation_for -= delta
		_lock_direction_for -= delta
		
		_check_trapped_over(delta)
		
		# Remote and local clients can lerp rotation
		_lerp_towards_target_rot(delta)
		
		_check_inside_solid()
		
		if can_move == true:
			# Only the client with "local_transform_update" set to true does these functions
			if local_transform_update:
				_calculate_next_position(delta)
		
		_update_age(delta)


func _check_inside_solid() -> void:
	if Lobby.is_host && can_move == true && (_entity_type != Globals.EntityTypes.SPELL || (_entity_type == Globals.EntityTypes.SPELL && _subtype == Globals.SpellTypes.TOTEM)):
		var area = get_area()
		if Util.safe_to_use(area) == true:
			if area.get_child(0).disabled == false:
				var result = get_world().get_direct_space_state().intersect_ray(global_transform.origin + Vector3.UP * 10, global_transform.origin + Vector3.DOWN * 10, [area, get_kinematic(), get_static_body()], pow(2, Globals.ColBits.SOLID))
				if result.get("collider") != null:
					var collided_entity = result.get("collider").get_parent()
					if Util.safe_to_use(collided_entity) == true:
						var dir: Vector3 = global_transform.origin - collided_entity.global_transform.origin
						dir.y = 0
						set_position(global_transform.origin + (dir.normalized() * 0.3), true)


func _check_trapped_over(delta: float) -> void:
	_trapped_for += delta
	if _is_trapped == true:
		if _trapped_for >= _trapped_time:
			untrap()


func _lerp_towards_target_rot(delta: float) -> void:
	if _is_lerping_to_target_rot == true:
		set_rot(lerp_angle(rotation.y, _target_rotation, _rot_speed * delta))


func _update_age(delta: float) -> void:
	if(_age > age_limit_seconds && age_limit_seconds != -1):
		PacketSender.host_broadcast_destroy_entity(_id, true)
		age_limit_seconds = -1;
	else:
		_age += delta;


func _calculate_next_position(delta: float) -> void:
	_is_lerping_pos = true
	_time_between_prev_and_target_pos = delta
	_lerp_time = 0
	_prev_pos = global_transform.origin
	
	_target_position = global_transform.origin + (_direction + _force) * delta
	
	# Reset _direction so that it doesn't increase exponentially for each tick!
	_direction = Vector3.ZERO
	
	# Add friction to force
	set_force((_force / Globals.GROUND_FRICTION) * delta * 26) 
	if _force.length_squared() < 0.05:
		set_force(Vector3.ZERO)


"""
Entity Utility Functions

func destroy(of_old_age: bool = false) -> void:
	# Don't destroy() this node in the editor, only in game
	if not Engine.editor_hint:
		if _is_destroyed == false:
			emit_signal("destroyed", _id)
			
			_is_destroyed = true
			
			Lobby.emit_signal("destroy_entity", _id)
			
			#var sounds = get_component_of_type(Globals.ComponentTypes.Sounds)
			#if sounds != null:
			#	sounds.play_on_destroy()
			#var pretty_destroy_node = get_component_of_type(Globals.ComponentTypes.PrettyDestroy)
			#if pretty_destroy_node == null:
			#else:
			#	pretty_destroy_node.pretty_destroy(of_old_age)
"""



func get_component_of_type(component_type: int) -> Node:
	for i in range(0, get_child_count()):
		var child = get_child(i)
		if child.get("COMPONENT_TYPE") != null:
			if child.COMPONENT_TYPE == component_type:
				# TODO: Safe but slow maybe
				if Util.safe_to_use(child) == true:
					return child
				else:
					printerr("Component not safe to use: ", child.name)
	
	return null


# Acts as a getter and a check if an entity has a collision shape
func get_collision_shape() -> CollisionShape:
	var area = get_area()
	if area != null:
		var childs_children = area.get_children()
		for childs_child in childs_children:
			if(childs_child is CollisionShape):
				return childs_child
	
	return null


# Acts as a getter and a check if an entity has a collision polygon
func get_collision_polygon() -> CollisionPolygon:
	var area = get_area()
	if area != null:
		var childs_children = area.get_children()
		for childs_child in childs_children:
			if(childs_child is CollisionPolygon):
				return childs_child
	
	return null


# Gets the area in the entity and adds the correct collision layers and masks
func _entity_area_setup() -> void:
	if _entity_area_setup_done == false:
		_entity_area_setup_done = true
		
		var new_area: Area
		
		# First find the area
		for child in get_children():
			if child is Area:
				new_area = child
				break
		
		if new_area == null:
			print("Warning: This entity has no area: ", get_type_names())
			return 
		
		# Reset collision bitmap
		new_area.collision_layer = 0
		new_area.collision_mask = 0
		
		
		# Set the collision bitmap depending on entity values and components
		if _entity_type == Globals.EntityTypes.SPELL && (_subtype == Globals.SpellTypes.ARCANE_WALL || _subtype == Globals.SpellTypes.ARCANE_WALL_PLACED):
			new_area.set_collision_mask_bit(Globals.ColBits.BLOCK_DAMAGE, true)
			new_area.set_collision_layer_bit(Globals.ColBits.BLOCK_DAMAGE, true)
		
		var has_health = get_component_of_type(Globals.ComponentTypes.Health) != null
		
		for child in get_children():
			if child.get("COMPONENT_TYPE") != null:
				match child.COMPONENT_TYPE:
					Globals.ComponentTypes.Health:
						new_area.set_collision_layer_bit(Globals.ColBits.HURTABLE, true)
						new_area.set_collision_layer_bit(Globals.ColBits.INSTAKILL, true)
					Globals.ComponentTypes.Damage, Globals.ComponentTypes.Heal:
						new_area.set_collision_mask_bit(Globals.ColBits.HURTABLE, true)
					Globals.ComponentTypes.Knockback:
						new_area.set_collision_mask_bit(Globals.ColBits.KNOCKBACKABLE, true)
					Globals.ComponentTypes.StillSolid:
						new_area.set_collision_layer_bit(Globals.ColBits.SOLID, true)
						new_area.set_collision_mask_bit(Globals.ColBits.SOLID, true)
						if has_health == false:
							new_area.set_collision_mask_bit(Globals.ColBits.BLOCK_DAMAGE, true)
							new_area.set_collision_layer_bit(Globals.ColBits.BLOCK_DAMAGE, true)
					Globals.ComponentTypes.Kinematic:
						new_area.set_collision_layer_bit(Globals.ColBits.KNOCKBACKABLE, true)
						new_area.set_collision_mask_bit(Globals.ColBits.SOLID, true)
					Globals.ComponentTypes.Projectile:
						new_area.set_collision_mask_bit(Globals.ColBits.SOLID, true)
						new_area.set_collision_layer_bit(Globals.ColBits.PROJECTILE, true)
					Globals.ComponentTypes.Grab:
						new_area.set_collision_mask_bit(Globals.ColBits.SOLID, true)
					Globals.ComponentTypes.ReflectProjectiles:
						new_area.set_collision_mask_bit(Globals.ColBits.PROJECTILE, true)
					Globals.ComponentTypes.Player:
						new_area.set_collision_layer_bit(Globals.ColBits.PLAYER, true)
					Globals.ComponentTypes.TrapOnCollide:
						new_area.set_collision_mask_bit(Globals.ColBits.PLAYER, true)
					Globals.ComponentTypes.PowerUp:
						new_area.set_collision_mask_bit(Globals.ColBits.PLAYER, true)
					Globals.ComponentTypes.ChangeSpeedOnCollide:
						new_area.set_collision_mask_bit(Globals.ColBits.PLAYER, true)
		
		_default_hurtable_mask_colbit = new_area.get_collision_mask_bit(Globals.ColBits.HURTABLE)
		_default_knockbackable_mask_colbit = new_area.get_collision_mask_bit(Globals.ColBits.KNOCKBACKABLE)
		entity_area = new_area
		disable_collider(disable_collider_on_ready)


func get_type_names() -> String:
	return Util.get_type_names(_entity_type, _subtype)


func _get_configuration_warning():
	var warning: String = ""
	var collisionShape = get_collision_shape()
	var collisionPolygon = get_collision_polygon()
	
	if(collisionShape == null && collisionPolygon == null):
		warning = "This entity doesn't have a 'Area' node with a 'CollisionShape' or a 'CollisionPolygon'. Please add one."
	
	return warning
