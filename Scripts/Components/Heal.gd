extends Component
class_name Heal
var COMPONENT_TYPE: int = Globals.ComponentTypes.Heal

export(int) var heal_amount: int = 10
export(bool) var heal_enemies: bool = false
export(bool) var heal_once_only: bool = false
export(float) var repeat_time: float = 1
export(bool) var heal_self: bool = true

var area: Area
var entities_in_area: Dictionary
var heal_creator_team: String

onready var repeatHeal: Timer = $RepeatHeal


func _ready():
	area = parent_entity.get_area()
	area.connect("area_entered", self, "_on_entity_entered_area")
	area.connect("area_exited", self, "_on_entity_exited_area")
	
	if !heal_once_only:
		repeatHeal.wait_time = repeat_time
		repeatHeal.start()
	
	var team: Dictionary = Lobby.get_team_info_from_player_id(parent_entity.get_creator_id())
	var totem_team_name = get_totem_team()
	
	if totem_team_name != "":
		heal_creator_team = totem_team_name
	elif team.empty() == false:
		heal_creator_team = team.name


func get_totem_team() -> String:
	var room_node = Util.get_room_node()
	if room_node != null:
		var creator_entity = room_node.get_entity(parent_entity.get_creator_id(), "get_heal_creator_team")
		if creator_entity != null:
			if creator_entity.get_type() == Globals.EntityTypes.SPELL && creator_entity.get_subtype() == Globals.SpellTypes.TOTEM:
				var totem_component = creator_entity.get_node("Totem")
				if totem_component != null:
					return totem_component.get_team_name()
	return ""



func heal_all() -> void:
	for entity in entities_in_area.values():
		if Util.safe_to_use(entity):
			heal(entity)


func heal(entity: Entity) -> void:
	var is_enemy = entity.get_type() == Globals.EntityTypes.PLAYER && !Lobby.is_on_same_team_as(entity.get_id(), heal_creator_team)
	if heal_enemies == false && is_enemy && parent_entity.get_creator_id() != entity.get_id():
		return
	
	if heal_self == false && entity.get_id() == parent_entity.get_creator_id():
		return
	
	entity.emit_signal("add_health", heal_amount)


func _on_entity_entered_area(entering_area: Area):
	# Put Entity in dict
	var entity: Entity = Util.get_entity_from_area(entering_area)
	if entity != null:
		var entity_id: int = entity.get_id()
		#print("entity id: ", entity_id)
		if heal_once_only && !entities_in_area.has(entity_id):
			heal(entity)
		
		entities_in_area[entity_id] = entity


func _on_entity_exited_area(leaving_area: Area):
	# Only remove if we should be able to heal again
	if !heal_once_only:
		var entity: Entity = Util.get_entity_from_area(leaving_area)
		entities_in_area.erase(entity.get_id())


func _on_RepeatHeal_timeout():
	heal_all()
	repeatHeal.start()
