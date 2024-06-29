extends Node


signal clients_player_added(spell_caster_comp)


var _player_entity: Entity = null
const CAMERA_OFFSET: Vector3 = Vector3(0, 38, 24.8)


func _ready():
	Globals.set_camera_offset(CAMERA_OFFSET)
