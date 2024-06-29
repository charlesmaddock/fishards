extends Component
class_name StillSolid
var COMPONENT_TYPE: int = Globals.ComponentTypes.StillSolid


export(bool) var can_move = false
export(bool) var broadcast_transform = false
export(bool) var disable_collider_on_ready = false


func _ready():
	parent_entity.can_move = can_move 
	parent_entity.broadcast_transform = broadcast_transform
	
	var collisionShape = parent_entity.get_collision_shape()
	var collisionPolygon = parent_entity.get_collision_polygon()
	
	if collisionShape != null:
		add_static_body(collisionShape)
	elif collisionPolygon != null:
		add_static_polygon(collisionPolygon)


func add_static_body(collisionShape: CollisionShape) -> void:
	var body: StaticBody = StaticBody.new()
	body.collision_layer = parent_entity.get_area().collision_layer
	body.collision_mask = parent_entity.get_area().collision_mask
	body.add_child(collisionShape.duplicate())
	body.get_child(0).disabled = disable_collider_on_ready
	get_parent().call_deferred("add_child", body)


func add_static_polygon(collisionPolygon: CollisionPolygon) -> void:
	var body: StaticBody = StaticBody.new()
	body.collision_layer = parent_entity.get_area().collision_layer
	body.collision_mask = parent_entity.get_area().collision_mask
	body.add_child(collisionPolygon.duplicate())
	body.get_child(0).disabled = disable_collider_on_ready
	get_parent().call_deferred("add_child", body)
