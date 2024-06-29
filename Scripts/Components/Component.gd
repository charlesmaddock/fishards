extends Node
class_name Component, "res://Assets/Textures/Sprites/Node Icons/componentIcon.png"

"""
Base node for all components that can be attached to a entity
"""


var parent_entity: Entity = null


func _ready():
	var parent_node = get_parent()
	if parent_node is Entity:
		parent_entity = parent_node
	else:
		printerr("WARNING: This component isn't attached to an 'Entity' node. A component must be a child of a Entity.")
