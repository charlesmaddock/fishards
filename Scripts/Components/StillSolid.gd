extends Component
class_name StillSolid
var COMPONENT_TYPE: int = Globals.ComponentTypes.StillSolid


@export var can_move: bool = false
@export var broadcast_transform: bool = false
@export var disable_collider_on_ready: bool = false


func _ready():
	parent_entity.can_move = can_move 
	parent_entity.broadcast_transform = broadcast_transform
	
	var collisionShape = parent_entity.get_collision_shape()
	var collisionPolygon = parent_entity.get_collision_polygon()
	
	if collisionShape != null:
		add_static_body(collisionShape)
	elif collisionPolygon != null:
		add_static_polygon(collisionPolygon)


func add_static_body(collisionShape: CollisionShape3D) -> void:
	var body: StaticBody3D = StaticBody3D.new()
	body.collision_layer = parent_entity.get_area().collision_layer
	body.collision_mask = parent_entity.get_area().collision_mask
	body.add_child(collisionShape.duplicate())
	body.get_child(0).disabled = disable_collider_on_ready
	get_parent().call_deferred("add_child", body)


func add_static_polygon(collisionPolygon: CollisionPolygon3D) -> void:
	var body: StaticBody3D = StaticBody3D.new()
	body.collision_layer = parent_entity.get_area().collision_layer
	body.collision_mask = parent_entity.get_area().collision_mask
	body.add_child(collisionPolygon.duplicate())
	body.get_child(0).disabled = disable_collider_on_ready
	get_parent().call_deferred("add_child", body)
