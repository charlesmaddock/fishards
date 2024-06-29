extends Component
class_name TrapOnCollide 
var COMPONENT_TYPE: int = Globals.ComponentTypes.TrapOnCollide


export(float) var trap_time = 3.0


var _time: float = 0
var _dont_trap_player_with_id: int




func _ready():
	parent_entity.get_area().connect("area_entered", self, "_on_entity_collided")
	_dont_trap_player_with_id = parent_entity.get_creator_id()


func _on_entity_collided(area: Area) -> void:
	if area.get_parent() is Entity:
		var hit_entity: Entity = area.get_parent()
		if hit_entity.get_id() != _dont_trap_player_with_id && !(hit_entity.get_type() == Globals.EntityTypes.PLAYER && hit_entity.get_subtype() == Globals.PlayerTypes.ICEARD):
			hit_entity.set_trapped_w_duration(trap_time, true)

