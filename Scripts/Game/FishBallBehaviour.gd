extends MeshInstance


var x_rot: float


func _ready():
	get_parent().connect("took_damage", self, "_on_took_damage")
	yield(get_tree(), "idle_frame")
	get_parent().get_kinematic().set_collision_mask_bit(Globals.ColBits.BARRIER, true)


func _process(delta):
	var parent_entity = get_parent() 
	if Lobby.is_host:
		var basis_z = parent_entity.transform.basis.z
		var from = parent_entity.rotation.y
		var force = parent_entity.get_force().normalized()
		var to = Util.vector_2_to_y_rot(Vector2(force.x, force.z)) 
		var lerped_angle = lerp_angle(from, to, 10 * delta)
		if force != Vector3.ZERO:
			get_parent().rotation.y = lerped_angle
	
	var length = parent_entity.get_target_pos_move_dir().length()
	x_rot += length
	self.rotation.x = x_rot


func _on_took_damage(damage, damager_entity) -> void:
	var parent_entity = get_parent()
	var between = (parent_entity.get_pos() - damager_entity.get_pos()).normalized()
	var res = (between * 3) + (between * (damage/2.5))
	if damager_entity.get_subtype() == Globals.SpellTypes.PUSH || damager_entity.get_subtype() == Globals.SpellTypes.DIVE_STUN:
		res = between * 25
	# Meteors give knockback anyways
	if damager_entity.get_subtype() == Globals.SpellTypes.METEOR:
		res /= 2
	
	res.y = 0
	parent_entity.add_force(res)
