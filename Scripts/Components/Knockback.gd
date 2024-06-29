extends Component
class_name Knockback
var COMPONENT_TYPE: int = Globals.ComponentTypes.Knockback


"""
Moves an entity in the direction it is rotated with a given speed
and does damage when hit
"""


export(float) var strength = 30
export(bool) var can_knockback_on_ready = true
export(bool) var always_knockback_on_collide = true
export(bool) var directional: bool = false
export(bool) var knockback_spells: bool = false
export(bool) var knockback_creator: bool = false
export(bool) var knockback_teammates: bool = true
export(bool) var launch: bool = false
export(float) var launch_speed: float = 7.5

var _manual_knockback_dir: Vector2 = Vector2.ZERO
var entities_in_area: Array
var _can_knockback: bool 
var _dont_push_player_with_id: int = 0 


func _ready():
	init(parent_entity.get_area())


func set_manual_knock_dir(dir: Vector2):
	_manual_knockback_dir = dir


func set_dont_push_player_with_id(val: int) -> void:
	_dont_push_player_with_id = val


func init(collision_detection_area: Area) -> void:
	collision_detection_area.connect("area_entered", self, "_on_entity_entered_area")
	_can_knockback = can_knockback_on_ready
	_dont_push_player_with_id = parent_entity.get_creator_id()


func knockback_entity(hit_entity: Entity) -> void:
	if hit_entity != null && _can_knockback == true && (hit_entity.get_id() != _dont_push_player_with_id || knockback_creator == true):
		# If we specify that we don't knockback spells
		if hit_entity.get_type() == Globals.EntityTypes.SPELL && knockback_spells == false:  
			return
		
		# If we have a block inbetween us
		var space_state = parent_entity.get_world().direct_space_state
		var result = space_state.intersect_ray(parent_entity.global_transform.origin, hit_entity.global_transform.origin, [], int(pow(2, Globals.ColBits.BLOCK_DAMAGE)), true, true)
		
		if result.get("collider") != null:
			return
		
		# Check if on the opposite team
		if !knockback_teammates && hit_entity.get_type() == Globals.EntityTypes.PLAYER && Lobby.is_on_my_team(hit_entity.get_id(), parent_entity.get_creator_id()):
			return
		
		# Do not knockback invincible stuff
		#if hit_entity.get_component_of_type(Globals.ComponentTypes.Health):
		#	if hit_entity.get_component_of_type(Globals.ComponentTypes.Health).get_invincible():
		#		return
		
		if parent_entity.get_creator_id() == SteamValues.STEAM_ID && parent_entity.get_type() == Globals.EntityTypes.SPELL && parent_entity.get_subtype() == Globals.SpellTypes.PUSH:
			AchievementHandler.inc_pushes()
		
		var force: Vector3
		if launch && Lobby.is_host:
			if hit_entity.get_component_of_type(Globals.ComponentTypes.Launchable) != null:
				var from: Vector3 = hit_entity.get_pos()
				var dir: Vector3 = Util.y_rot_to_vector_3(parent_entity.rotation.y)
				var to: Vector3 = from + (dir * strength/6)
				PacketSender.launch(hit_entity.get_id(), Globals.EntityTypes.PLAYER, from, to, launch_speed)
		elif directional == true:
			if _manual_knockback_dir != Vector2.ZERO:
				force = Vector3(_manual_knockback_dir.x, 0, _manual_knockback_dir.y).normalized() * strength
			else:
				force = parent_entity.get_move_dir_v3().normalized() * strength
		else:
			var between: Vector3 = (hit_entity.global_transform.origin - parent_entity.global_transform.origin).normalized();
			force = between * strength
		
		force.y = 0
		hit_entity.add_force(force)
		#hit_entity.set_trapped_w_duration(strength / 60, false)
		hit_entity.emit_signal("trigger_player_animation", Globals.PlayerAnimations.PUSHED, Vector2(force.normalized().x, force.normalized().z))


func _on_entity_entered_area(area: Area):
	# Put Entity in dict
	var entity: Entity = Util.get_entity_from_area(area)
	if entity != null:
		var entity_id: int = entity.get_id()
		if entities_in_area.find(entity_id) == -1 && _can_knockback == true:
			knockback_entity(entity)
		
		entities_in_area.append(entity.get_id())
