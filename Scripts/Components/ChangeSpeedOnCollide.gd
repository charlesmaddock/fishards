extends Component
class_name ChangeSpeedOnCollide 
var COMPONENT_TYPE: int = Globals.ComponentTypes.ChangeSpeedOnCollide


export(bool) var affect_teammates = false
export(bool) var affect_creator = false
export(float) var speed_modifier = 1.0
export(String) var modifier_name
export(float) var duration = -1 # If it is -1 it will last forever
export(float) var repeat_time = -1 # If it is -1 it wont repeat
export(bool) var freeze_on_collide = false


var entity_ids_in_area: Array = []
var _dont_affect_player_with_id: int


var _not_freezable_entites = [{"type": Globals.EntityTypes.PLAYER, "subtype": Globals.PlayerTypes.ICEARD}]


func _ready():
	Lobby.connect("destroy_entity", self, "_on_entity_destroyed")
	parent_entity.get_area().connect("area_entered", self, "_on_entity_collided")
	parent_entity.get_area().connect("area_exited", self, "_on_entity_left_area")
	parent_entity.connect("destroyed", self, "_on_destroyed")
	Lobby.connect("player_killed", self, "_on_player_killed")
	
	if repeat_time != -1:
		$Repeat.wait_time = repeat_time
		$Repeat.start()
	
	if !affect_creator:
		_dont_affect_player_with_id = parent_entity.get_creator_id()


func _set_speed_modifier(entity: Entity) -> void:
	if affect_teammates == false && affect_creator == false && entity.get_type() == Globals.EntityTypes.PLAYER && Lobby.is_on_my_team(entity.get_id(), parent_entity.get_creator_id()):
		return
	
	# Dont add the same entity twice
	if entity_ids_in_area.find(entity.get_id()) != -1:
		return
	
	entity_ids_in_area.append(entity.get_id())
	
	if entity.get_id() != _dont_affect_player_with_id && entity.get_type() == Globals.EntityTypes.PLAYER:
		if modifier_name != "":
			var player = entity.get_component_of_type(Globals.ComponentTypes.Player)
			if player != null:
				player.set_speed_modifier(modifier_name, speed_modifier, duration)
			else:
				printerr("Player component missing")
		else:
			printerr("Please give ChangeSpeedOnCollide a modifier name inside ", parent_entity.get_type_names())


func _remove_speed_modifier(entity_id: int) -> void:
	var room_node = Util.get_room_node()
	if room_node != null:
		var entity = room_node.get_entity(entity_id, "remove speed modifier")
		if entity != null:
			if entity.get_type() == Globals.EntityTypes.PLAYER:
				if modifier_name != "":
					var player = entity.get_component_of_type(Globals.ComponentTypes.Player)
					if player != null:
						var index: int = entity_ids_in_area.find(entity_id)
						if index != -1:
							entity_ids_in_area.remove(index)
							player.remove_speed_modifier(modifier_name)
					else:
						printerr("Player component missing")
				else:
					printerr("Please give ChangeSpeedOnCollide a modifier name inside ", parent_entity.get_type_names())


func _on_entity_destroyed(entity_id: int) -> void:
	var remove_at = entity_ids_in_area.find(entity_id)
	if remove_at != -1:
		entity_ids_in_area.remove(remove_at)


func _on_entity_collided(area: Area) -> void:
	var hit_entity = Util.get_entity_from_area(area)
	if hit_entity != null:
		if hit_entity.can_move == false:
			return
		
		# Don't freeze invis 
		var spell_caster = hit_entity.get_component_of_type(Globals.ComponentTypes.SpellCaster)
		if spell_caster != null:
			if spell_caster.is_transformed == true:
				return
		
		if affect_creator == false && hit_entity.get_id() == parent_entity.get_creator_id():
			return
		
		_set_speed_modifier(hit_entity)
		
		if freeze_on_collide == true:
			# Dont freeze teammates
			if affect_teammates == false && Lobby.is_on_my_team(hit_entity.get_id(), parent_entity.get_creator_id()):
				return
			
			for entity_type_data in _not_freezable_entites:
				if entity_type_data.type == hit_entity.get_type() && entity_type_data.subtype == hit_entity.get_subtype():
					return
			
			hit_entity.set_trapped_w_duration(duration, true)


func _on_destroyed(_id, _of_old_age) -> void:
	if duration == -1:
		for id in entity_ids_in_area:
			_remove_speed_modifier(id)
	
	entity_ids_in_area.clear()


# Dead players must be removed from entities with speed modifier
func _on_player_killed(dead_player_id: int, _killer_id: int, _with_spell: int) -> void:
	for id in entity_ids_in_area:
		if dead_player_id == id:
			_remove_speed_modifier(id)


func _on_entity_left_area(area: Area):
	var hit_entity = Util.get_entity_from_area(area)
	if hit_entity != null:
		_remove_speed_modifier(hit_entity.get_id())


func _on_Repeat_timeout():
	if repeat_time != -1:
		var room_node = Util.get_room_node()
		if room_node != null:
			for id in entity_ids_in_area:
				var entity = room_node.get_entity(id, "_on_Repeat_timeout")
				if entity != null:
					var player = entity.get_component_of_type(Globals.ComponentTypes.Player)
					if modifier_name != "" && player != null:
						player.set_speed_modifier(modifier_name, speed_modifier, duration)
