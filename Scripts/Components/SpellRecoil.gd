extends Component
class_name SpellRecoil
var COMPONENT_TYPE: int = Globals.ComponentTypes.SpellRecoil


export(bool) var add_force_on_ready = true
export(bool) var add_force_to_entity_creator = true
export(float) var force_magnitude = 30.0
# Use as a Vector2(x, z) relative to spell
export(Vector2) var force_dir = Vector2(0, -1) # Default is opposite facing spell


func _ready():
	if parent_entity.get_creator_id() != -1:
		var room: Spatial = Util.get_room_node()
		var creator_entity = room.get_entity(parent_entity.get_creator_id())
		if Util.safe_to_use(creator_entity):
			var angle_between = force_dir.angle_to(Util.y_rot_to_vector_2(parent_entity.rotation.y))
			force_dir = Util.y_rot_to_vector_2(angle_between)
			force_dir.x = -force_dir.x # I really need to start understanding trigonometry and not just doing some random shit and then changing after testing but hey it works fuck you
			
			var force: Vector3 = force_magnitude * Vector3(force_dir.x, 0, force_dir.y)
			creator_entity.add_force(force)
		else:
			printerr("Couldn't find a creator entity for this spell recoil")
