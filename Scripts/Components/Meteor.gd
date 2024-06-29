extends Component
class_name Meteor
var COMPONENT_TYPE: int = Globals.ComponentTypes.Meteor


export(NodePath) var fire_explosion_path
export(NodePath) var meteor_impact_animator_path
export(NodePath) var meteor_path
export(NodePath) var meteor_trail_path
export(NodePath) var damage_component_path
export(NodePath) var knockback_component_path
export(NodePath) var cracks_animator_path
export(NodePath) var perimiter_path


onready var _timer: Timer = $disappear_timer
var time_to_disappear: bool = false


func _ready():
	parent_entity.connect("landed", self, "_on_has_landed")
	

func _on_has_landed() -> void:
	get_node(meteor_path).visible = false
	get_node(meteor_trail_path).emitting = false
	get_node(fire_explosion_path).play_all()
	get_node(perimiter_path).emitting = true
	get_node(meteor_impact_animator_path).play("show")
	get_node(cracks_animator_path).emitting = true
	_timer.start(0.1)


func disappear_timer_timeout() -> void:
	if time_to_disappear == false:
		parent_entity.disable_collider(true)
		_timer.start(3)
		time_to_disappear = true
	else:
		get_node(meteor_impact_animator_path).play("hide")
		PacketSender.host_broadcast_destroy_entity(parent_entity.get_id())
