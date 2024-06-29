extends Component
class_name Turret
var COMPONENT_TYPE: int = Globals.ComponentTypes.Turret


signal shoot()


export(float) var cast_spell_time = 0.4
export(float) var max_search_range = 9999
export(String) var team_name = "Blue Team"
export(NodePath) var turret_model 


var _hunt_counter: float 
var _hunt_max_time: float = 1
var _update_cast_spell_counter: float 
var _spell_caster: SpellCaster = null
var _closest_player_id: int = -1


func init_turret(name: String) -> void:
	team_name = name


func _ready():
	parent_entity.connect("landed", self, "_on_landed")
	parent_entity.set_creator_id(parent_entity.get_id())
	if Lobby.is_host:
		_spell_caster = parent_entity.get_component_of_type(Globals.ComponentTypes.SpellCaster)


func get_closest_enemy() -> Entity:
	if _closest_player_id != -1:
		var room_node = Util.get_room_node()
		if room_node != null:
			return room_node.get_entity(_closest_player_id)
	return null


func _process(delta) -> void:
	if Lobby.is_host && RoomSettings.get_game_started() == true && !Globals.game_paused:
		_find_closest_player(delta)
		_aim_at_closest_player()
		_check_turret_cast_spell(delta)


func _find_closest_player(delta: float):
	_hunt_counter += delta
	var players_node = Util.get_players_node()
	if players_node != null && _hunt_counter > _hunt_max_time:
		_hunt_counter = 0
		var closest_player = players_node.get_closest_enemy_player(parent_entity.get_pos(), parent_entity.get_creator_id(), team_name, true, 25)
		if closest_player != null:
			_closest_player_id = closest_player.get_id()
		else:
			_closest_player_id = -1


func _aim_at_closest_player():
	var closest_player = get_closest_enemy()
	if closest_player != null:
		var cast_direction: Vector3 = parent_entity.global_transform.origin.direction_to(closest_player.global_transform.origin)
		var cast_direction2d = Vector2(cast_direction.x, cast_direction.z) 
		parent_entity.set_target_rotation(cast_direction2d.angle_to(Vector2.DOWN), 5)


func _check_turret_cast_spell(delta: float) -> void:
	_update_cast_spell_counter += delta
	if _update_cast_spell_counter > cast_spell_time && _closest_player_id != -1:
		_update_cast_spell_counter = 0
		var dir2 = Util.y_rot_to_vector_2(parent_entity.get_rot())
		var cast_pos = Vector3(dir2.x, 0, dir2.y) + parent_entity.global_transform.origin
		var rand = Util.rand.randf()
		if rand < 0.9:
			_spell_caster.update_active_spell(Globals.SpellTypes.FIREBALL)
		else:
			_spell_caster.update_active_spell(Globals.SpellTypes.HEAL)
		
		emit_signal("shoot")
		_spell_caster.try_request_cast_spell(cast_pos, team_name)
