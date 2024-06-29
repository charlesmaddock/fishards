extends Component
class_name Crab
var COMPONENT_TYPE: int = Globals.ComponentTypes.Crab


export(float) var speed = 14
export(float) var seconds_to_damage_after = 2
export(float) var egg_poop_magnitude = 10
export(NodePath) var _egg_node: NodePath
export(NodePath) var _explosion_egg_particles: NodePath
export(NodePath) var _crab_node: NodePath
export(NodePath) var _crab_animator: NodePath
const max_search_range = 9999


var _has_activated: bool
var _closest_player: Entity = null


func _ready():
	parent_entity.connect("dealt_damage", self, "_on_crab_dealt_damage")
	parent_entity.connect("landed", self, "_on_egg_landed")
	get_node(_crab_node).visible = false
	parent_entity.broadcast_transform = false


func init_crab(caster_id: int, team_name: String, spawn_pos: Vector3) -> void:
	var players_node = Util.get_players_node()
	if players_node != null:
		_closest_player = players_node.get_closest_enemy_player(spawn_pos, caster_id, team_name)
	else:
		print("Couldn't find target player since players node was null")


func _physics_process(delta) -> void:
	# Only host should process the crab AI
	if Lobby.is_host:
		# Move towards closest player
		if Util.safe_to_use(_closest_player) == true && _has_activated:
			var closest_player_pos: Vector3 = _closest_player.global_transform.origin
			var dir: Vector3 = parent_entity.global_transform.origin.direction_to(closest_player_pos)
			var rot: float = Vector2(dir.x, dir.z).angle_to(Vector2.DOWN)
			parent_entity.add_direction(dir * speed * delta)
			parent_entity.set_rot(rot)


func _on_egg_landed() -> void:
	get_node(_egg_node).visible = false
	get_node(_crab_node).visible = true
	get_node(_crab_animator).play("run-loop")
	get_node(_explosion_egg_particles).emitting = true
	
	var damage_component: Damage = parent_entity.get_component_of_type(Globals.ComponentTypes.Damage)
	if damage_component != null:
		damage_component.set_enabled(true)
	
	_has_activated = true
	
	parent_entity.broadcast_transform = true
	if Lobby.is_host:
		PacketSender.update_entity_pos_directly(parent_entity.get_id(), parent_entity.global_transform.origin)


func _on_crab_dealt_damage(_amount: int, hit_entity: Entity) -> void:
	# Die if we deal damage to something, unless it is another crab or environment
	if hit_entity.get_type() == Globals.EntityTypes.SPELL && hit_entity.get_subtype() == Globals.SpellTypes.CRAB || hit_entity.get_type() == Globals.EntityTypes.ENVIRONMENT:
		return
	
	parent_entity.emit_signal("took_damage", 100, parent_entity)
