extends KinematicBody


onready var child_entity: Entity = null


func _ready():
	# Add the entities collision shape to our kinematic body
	child_entity = get_child(0)
	var shape: CollisionShape = child_entity.get_collision_shape().duplicate()
	shape.disabled = child_entity.disable_collider_on_ready
	collision_layer = child_entity.get_area().collision_layer
	collision_mask =  child_entity.get_area().collision_mask
	
	# The kinematic shape should be smaller that the area so it doesn't interfear with collision logic
	shape.scale /= 1.3
	add_child(shape)
	
	child_entity.set_kinematic_body(self)
