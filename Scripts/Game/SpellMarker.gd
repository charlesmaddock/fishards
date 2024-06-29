extends Sprite3D

var _spell_caster
var _active_spell: int
var _previous_spell: int

var _controller_dir: Vector2
var _camera: Camera
var ray_length: float = 1000
var clamped: bool = true
var marker_target_pos: Vector3
onready var upgrade_arrow: CSGPolygon = $Upgrade


func _ready():
	_spell_caster = get_parent()
	_camera = get_viewport().get_camera()
	
	upgrade_arrow.set_visible(false)
	set_visible(false)


func _process(delta):
	rotation.y += delta * 3
	
	if _spell_caster != null:
		if Util.safe_to_use(_spell_caster) == false:
			_spell_caster = null
			return
		
		_follow_mouse(delta)
		_update_marker_color()
	
	global_transform.origin = global_transform.origin.linear_interpolate(marker_target_pos, delta * 14)
	global_transform.origin.y = 0.2


func _update_marker_color() -> void:
	_active_spell = _spell_caster.active_spell
	if _previous_spell != _active_spell:
		_previous_spell = _active_spell
		set_visible(true)
		
		match _active_spell:
			Globals.SpellTypes.DIVE:
				material_override.albedo_color = Color("#6b8de3")
			Globals.SpellTypes.CRAB:
				material_override.albedo_color = Color("#a1d0ed")
			Globals.SpellTypes.METEOR:
				material_override.albedo_color = Color("#e37a5f")
			Globals.SpellTypes.TOTEM:
				material_override.albedo_color = Color("#7dd47e")
			#Globals.SpellTypes.HEAL:
			#	material_override.albedo_color = Color("#91e3dc")
			_:
				set_visible(false)


func _follow_mouse(delta) -> void:
	var mouse_pos = Util.get_aim_position(get_world().get_direct_space_state())
	if mouse_pos != Vector3.DOWN:
	
		if Util.controller_connected:
			var dir: Vector2
			dir.x = Input.get_action_strength("joy_right_right") - Input.get_action_strength("joy_right_left")
			dir.y = Input.get_action_strength("joy_right_down") - Input.get_action_strength("joy_right_up")
			if dir != Vector2.ZERO:
				_controller_dir = dir.normalized()
			mouse_pos = _spell_caster.parent_entity.get_pos() + Vector3(_controller_dir.x, 0, _controller_dir.y)
		
		var clamped_pos: Vector3 = Util.clamp_spell_pos(_spell_caster.parent_entity.get_pos(), mouse_pos, _active_spell)
		marker_target_pos = clamped_pos

