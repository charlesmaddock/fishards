extends Component
class_name EntityInfoPanel
var COMPONENT_TYPE: int = Globals.ComponentTypes.EntityInfoPanel


export(float) var _margin_top = 2
export(String) var default_name = ""
export(NodePath) var show_panel_above_path = null

onready var _name_control: Control = $"Control/Name"
onready var _label: Label = $"Control/Name/Label"
onready var _hp_progress: TextureProgress = $"Control/Control/TextureProgress"
onready var _control: Control = $"Control"
onready var _hp_background_sprite: Sprite = $"Control/Control/health_bar_background"
onready var healthControl: Control = $Control/Control 
onready var elementDisplay = $"Control/Elements/ElementsDisplay"


var _show_panel_above: Spatial = null


func get_element_display():
	return get_node("Control/Elements/ElementsDisplay")


func set_username(username: String, team_name: String):
	if default_name == "":
		default_name = username
		if _label != null:
			_label.text = username
			if team_name == "Blue Team":
				_label.modulate = Globals.BLUE_TEAM_COLOR
				_label.self_modulate = Color.white
			elif team_name == "Red Team":
				_label.modulate = Globals.RED_TEAM_COLOR
				_label.self_modulate = Color.white
			else:
				_label.modulate = Color.white


func hide_panel() -> void:
	_control.visible = false


func show_panel() -> void:
	_control.visible = true


func _ready():
	Lobby.connect("lobby_members_updated", self, "_on_lobby_members_updated")
	UserSettings.connect("user_settings_updated", self, "_on_user_settings_updated")
	_on_user_settings_updated()
	_label.text = default_name
	hide_panel()
	
	var spellcaster = parent_entity.get_component_of_type(Globals.ComponentTypes.SpellCaster)
	if spellcaster != null && parent_entity.get_type() == Globals.EntityTypes.PLAYER:
		var elements: Array = spellcaster.get_available_elements()
		elementDisplay.set_elements(elements, false)
	else:
		elementDisplay.set_visible(false)
	
	if show_panel_above_path != null:
		_show_panel_above = get_node(show_panel_above_path)
	else:
		_show_panel_above = parent_entity
	
	var health_comp: Health = parent_entity.get_component_of_type(Globals.ComponentTypes.Health)
	if health_comp != null:
		_hp_progress.max_value = health_comp.max_health
		_hp_progress.value = health_comp.get_health()
	else:
		_hp_progress.visible = false
		_hp_background_sprite.visible = false
	
	# Avoid ugly bug where name shows up in corner of screen
	if Lobby.player_is_in_temp_bot(parent_entity.get_id()) || parent_entity.get_type() == Globals.EntityTypes.SPELL:
		yield(get_tree().create_timer(0.2), "timeout")
		call_deferred("show_panel")
	else:
		show_panel()


func _on_user_settings_updated() -> void:
	_name_control.set_visible(!UserSettings.get_minimal_HUD())
	healthControl.set_visible(!UserSettings.get_minimal_HUD())
	
	var spellcaster = parent_entity.get_component_of_type(Globals.ComponentTypes.SpellCaster)
	if spellcaster != null && parent_entity.get_type() == Globals.EntityTypes.PLAYER:
		elementDisplay.set_visible(!UserSettings.get_minimal_HUD())


func _on_lobby_members_updated() -> void:
	for player_info in Lobby.get_all_lobby_player_info():
		if player_info["id"] == parent_entity.get_id():
			update_element_display(player_info["elmts"])
			break


func update_element_display(elements) -> void:
	elementDisplay.set_elements(elements, false)


func hide_element_display() -> void:
	elementDisplay.set_visible(false)


func _process(_delta: float) -> void:
	var screen_pos: Vector2 = get_viewport().get_camera().unproject_position(_show_panel_above.get_global_transform().origin + (Vector3.UP * _margin_top) + Vector3.UP * 1.2)
	_control.rect_position = Vector2(screen_pos.x, screen_pos.y) - _control.rect_size / 2


func update_health(health: int):
	_hp_progress.call_deferred("set_value", health)


func update_max_health(value: int):
	_hp_progress.call_deferred("set_max", value)

