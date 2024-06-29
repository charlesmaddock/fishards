extends Component
class_name Rotation
var COMPONENT_TYPE: int = Globals.ComponentTypes.Rotation


export(float) var rotSpeed: float = 0.025 # I assume this refers to standard value?


func _process(delta):
	parent_entity.rotate(Vector3(0,1,0), rotSpeed * delta) # Not working? Inserting fixed value instead works.
