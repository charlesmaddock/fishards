extends Component

signal rock_dash_hit()

func _ready():
	parent_entity.get_area().connect("area_entered", self, "_on_entity_collide")
	parent_entity.get_area().set_collision_mask_bit(Globals.ColBits.SOLID, true)
	parent_entity.get_area().set_collision_mask_bit(Globals.ColBits.MAP, false)
	var knockback: Knockback = parent_entity.get_component_of_type(Globals.ComponentTypes.Knockback)
	if knockback != null:
		var dir: Vector2 = Util.y_rot_to_vector_2(parent_entity.get_global_rot())
		knockback.set_manual_knock_dir(dir)


func _on_entity_collide(area):
	var hit_entity: Entity = Util.get_entity_from_area(area)
	if hit_entity != null:
		if hit_entity.get_id() == parent_entity.get_creator_id():
			return
		emit_signal("rock_dash_hit")
		var room_node = Util.get_room_node()
		if room_node != null:
			var creator_spellcaster: SpellCaster = room_node.get_spellcaster_component(parent_entity.get_creator_id())
			if creator_spellcaster != null:
				creator_spellcaster.deactivate_rock_dash()
	else:
		emit_signal("rock_dash_hit")
