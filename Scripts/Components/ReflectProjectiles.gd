extends Component
class_name ReflectProjectiles
var COMPONENT_TYPE: int = Globals.ComponentTypes.ReflectProjectiles


export(bool) var projectile_can_pass_though_one_side
export(bool) var invert_projectile: bool = true


var _creator_id: int 


func _ready():
	parent_entity.get_area().connect("area_entered", self, "_on_entity_collided")
	_creator_id = parent_entity.get_creator_id()


func can_pass_through(passing_through_entity) -> bool:
	if projectile_can_pass_though_one_side:
		var diff = abs(passing_through_entity.get_global_rot() - parent_entity.get_global_rot())
		if diff > PI/2 && diff < 3*PI/2:
			return false
	
	return true


func _on_entity_collided(area: Area):
	# Host checks for a reflection and broadcasts it to everyone
	if Lobby.is_host && area.get_parent() is Entity:
		var new_direction: Vector3 = area.get_parent().transform.basis.z * -1
		var projectile: Projectile = area.get_parent().get_component_of_type(Globals.ComponentTypes.Projectile);
		var diff = abs(area.get_parent().get_global_rot() - parent_entity.get_global_rot())
		var is_facing_wall: bool = PI/2 && diff < 3*PI/2
		if projectile != null:
			if projectile_can_pass_though_one_side:
				if is_facing_wall == true:
					PacketSender.reflect_spell(_creator_id, area.get_parent().get_id(), area.get_parent().global_transform.origin, new_direction)
			else:
				PacketSender.reflect_spell(_creator_id, area.get_parent().get_id(), area.get_parent().global_transform.origin, new_direction)
			
		if is_facing_wall == true:
			var parent_to_creator_component = parent_entity.get_component_of_type(Globals.ComponentTypes.ParentToCreator)
			if parent_to_creator_component != null:
				var room_node = Util.get_room_node()
				if room_node != null:
					var creator_entity = room_node.get_entity(parent_entity.get_creator_id(), "Force to reflect projectiles")
					if creator_entity != null:
						var damage_component: Damage = area.get_parent().get_component_of_type(Globals.ComponentTypes.Damage)
						if damage_component != null:
							creator_entity.add_force(new_direction * -1 * (2.8 + ( damage_component.damage / 2.5)))
