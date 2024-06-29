extends Component
class_name Damage
var COMPONENT_TYPE: int = Globals.ComponentTypes.Damage


export(int) var damage: int = 10
export(bool) var _enabled: bool = true
export(bool) var trigger_manually = false

export(bool) var damage_allies: bool = false
export(bool) var can_damage_multiple = true
export(bool) var damage_crabs = true
export(bool) var damage_depends_on_dist_from_centre = false
export(bool) var repeat_damage: bool = false
export(float) var repeat_time: float = 1


var _area: Area
var entities_in_area: Dictionary
var recently_exited_entities: Dictionary
var repeat_damage_wait_time: float


func _ready():
	_area = parent_entity.get_area()
	if !trigger_manually:
		_area.connect("area_entered", self, "_on_entity_entered_area")
		_area.connect("area_exited", self, "_on_entity_exited_area")
		repeat_damage_wait_time = 0


func _process(delta: float) -> void:
	if repeat_damage == true:
		repeat_damage_wait_time -= delta
		if repeat_damage_wait_time < 0:
			_on_repeat_damage_timeout()
	
	for id in recently_exited_entities:
		recently_exited_entities[id] += delta
		if recently_exited_entities[id] > 0.5:
			recently_exited_entities.erase(id)


func set_damage(val: int) -> void:
	damage = val


func set_enabled(value: bool) -> void:
	_enabled = value


func can_damage_again() -> void:
	entities_in_area.clear()


func damage_all() -> void:
	if can_damage_multiple:
		for entity in entities_in_area.values():
			if Util.safe_to_use(entity):
				damage_entity(entity)
	else:
		printerr("Tried to damage multiple enemies but can_damage_multiple was set to false: ", parent_entity.name)


func get_damage_creator_team() -> String:
	var room_node = Util.get_room_node()
	if room_node != null:
		var creator_entity = room_node.get_entity(parent_entity.get_creator_id(), "get_damage_creator_team")
		if creator_entity != null:
			if creator_entity.get_type() == Globals.EntityTypes.SPELL && creator_entity.get_subtype() == Globals.SpellTypes.TOTEM:
				var totem_component = creator_entity.get_node("Totem")
				if totem_component != null:
					return totem_component.get_team_name()
			elif creator_entity.get_type() == Globals.EntityTypes.ENVIRONMENT && creator_entity.get_subtype() == Globals.EnvironmentTypes.TURRET:
				return "Blue Team"
			else:
				var team: Dictionary = Lobby.get_team_info_from_player_id(parent_entity.get_creator_id())
				if team.empty() == false:
					return team.name
				else:
					printerr("[Damage]: Couldn't find a team for this damage component")

		else:
			pass # RE-ADD
			#printerr("[Damage]: Couldn't find a creator entity for this damage")
	
	return ""


func damage_entity(entity: Entity) -> void:
	if entity != null:
		var damage_amount = damage
		
		var space_state = parent_entity.get_world().direct_space_state
		var result = space_state.intersect_ray(parent_entity.global_transform.origin, entity.global_transform.origin, [], int(pow(2, Globals.ColBits.BLOCK_DAMAGE)), true, true)
		if result.get("collider") != null:
			
			# Check if it is a wall, and do not block from right direction
			var collided_entity = result.get("collider").get_parent()
			if collided_entity.get_type() == Globals.EntityTypes.SPELL && collided_entity.get_subtype() == Globals.SpellTypes.ARCANE_WALL_PLACED:
				var diff = abs(parent_entity.get_global_rot() - collided_entity.get_global_rot())
				if diff > PI/2 && diff < 3*PI/2:
					return
			else:
				return
		
		if damage_crabs == false && entity.get_type() == Globals.EntityTypes.SPELL && entity.get_subtype() == Globals.SpellTypes.CRAB:
			return
		
		# Check if on the opposite team
		if !damage_allies && Lobby.is_on_same_team_as(entity.get_id(), get_damage_creator_team()):
			return
		
		# Check if totem should be damaged
		if !damage_allies && entity.get_type() == Globals.EntityTypes.SPELL && entity.get_subtype() == Globals.SpellTypes.TOTEM:
			if entity.get_creator_id() == parent_entity.get_creator_id() || entity.get_id() == parent_entity.get_creator_id():
				return
		
		var is_gooey_god = entity.get_type() == Globals.EntityTypes.ENVIRONMENT && entity.get_subtype() == Globals.EnvironmentTypes.GOOEY_GOD_STATUE
		if is_gooey_god == true && Lobby.player_is_in_temp_bot(parent_entity.get_creator_id()) == false:
			return
		
		if damage_depends_on_dist_from_centre == true:
			if _area.get_child(0).get_shape() is CylinderShape:
				var shape: CylinderShape = _area.get_child(0).get_shape() 
				var dist = entity.get_pos().distance_to(parent_entity.get_pos())
				damage_amount = (((shape.radius - dist) / shape.radius) * damage / 2)  + (damage / 1.5)
			else:
				printerr("damage_depends_on_dist_from_centre must have cylinder shape")
		
		entity.emit_signal("took_damage", damage_amount, parent_entity)
		parent_entity.emit_signal("dealt_damage", damage_amount, entity)


func _on_entity_entered_area(area: Area):
	# Put Entity in dict
	if _enabled:
		var entity: Entity = Util.get_entity_from_area(area)
		if entity != null:
			var entity_id: int = entity.get_id()
			if !entities_in_area.has(entity_id) && _enabled && recently_exited_entities.has(entity_id) == false:
				damage_entity(entity)
			
			entities_in_area[entity_id] = entity


func _on_entity_exited_area(area: Area):
	var entity: Entity = Util.get_entity_from_area(area)
	if entity != null:
		if repeat_damage:
			entities_in_area.erase(entity.get_id())
		
		if recently_exited_entities.has(entity.get_id()) == false:
			recently_exited_entities[entity.get_id()] = 0



func _on_repeat_damage_timeout() -> void:
	if _enabled:
		damage_all()
	repeat_damage_wait_time = repeat_time

