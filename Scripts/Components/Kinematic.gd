extends Component
class_name Kinematic
var COMPONENT_TYPE: int = Globals.ComponentTypes.Kinematic


onready var kinematic_body: KinematicBody = $KinematicBody


func _ready():
	# Add the entities collision shape to our kinematic body
	var shape: CollisionShape = parent_entity.get_collision_shape().duplicate(true)
	shape.disabled = parent_entity.disable_collider_on_ready
	disable_collision(false)
	
	# The kinematic shape should be smaller that the area so it doesn't interfear with collision logic
	shape.scale /= 1.3
	kinematic_body.add_child(shape)
	
	parent_entity.call_deferred("set_kinematic_body", kinematic_body)


func disable_collision(value: bool) -> void:
	if kinematic_body != null:
		if value == true:
			kinematic_body.collision_layer = 0
			kinematic_body.collision_mask =  0
		else:
			kinematic_body.collision_layer = parent_entity.get_area().collision_layer
			kinematic_body.collision_mask =  parent_entity.get_area().collision_mask
