extends Component
class_name ParentTo_creator
var COMPONENT_TYPE: int = Globals.ComponentTypes.ParentToCreator


export(float) var z_offset: float = 1.5
export(float) var y_offset: float = 0
var follow_parent: bool = true


func _ready():
	Lobby.connect("destroy_entity", self, "_on_entity_destroyed")
	Lobby.connect("player_killed", self, "_on_player_killed")
	Lobby.connect("player_immobilized", self, "_on_player_immobilized")
	
	var room_node = Util.get_room_node()
	if room_node != null:
		var creator_entity = room_node.get_entity(parent_entity.get_creator_id())
		if creator_entity != null:
			var spellcaster = creator_entity.get_component_of_type(Globals.ComponentTypes.SpellCaster)
			if spellcaster != null:
				spellcaster.add_child_spell(parent_entity)
	
	set_parents_pos()

func _on_player_immobilized(entity_id: int):
	if entity_id == parent_entity.get_creator_id():
		follow_parent = false
		PacketSender.host_broadcast_destroy_entity(parent_entity.get_id())


func _on_player_killed(killed_id: int, killer_id: int, _with_spell: int) -> void:
	if killed_id == parent_entity.get_creator_id():
		follow_parent = false
		PacketSender.host_broadcast_destroy_entity(parent_entity.get_id())


func _on_entity_destroyed(entity_id: int) -> void:
	if entity_id == parent_entity.get_creator_id():
		follow_parent = false
		PacketSender.host_broadcast_destroy_entity(parent_entity.get_id())


func _process(delta):
	set_parents_pos()


func set_parents_pos() -> void:
	if follow_parent == true:
		var room_node = Util.get_room_node()
		if room_node != null:
			var creator_entity = room_node.get_entity(parent_entity.get_creator_id(), "Parent to entity")
			if creator_entity != null:
				var spellcaster = creator_entity.get_component_of_type(Globals.ComponentTypes.SpellCaster)
				if spellcaster != null:
					parent_entity.global_transform.origin = creator_entity.global_transform.origin + (Util.y_rot_to_vector_3(creator_entity.get_global_rot()) * z_offset) + (Vector3.UP * y_offset)
					if parent_entity.get_subtype() != Globals.SpellTypes.GRAB:
						parent_entity.set_rot(creator_entity.get_global_rot())
