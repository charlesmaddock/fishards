extends Component
class_name Health
var COMPONENT_TYPE: int = Globals.ComponentTypes.Health


const map_collision_layer: int = 8
const death_collision_layer: int = 16
var _update_iteration: int


export(int) var max_health = 100
export(bool) var despawn_on_no_health = true
export(int) var _regen_amount = 2


var _health: int = -9999
var _recent_damager_id: int = -1
var _recent_damager_spell: int = Globals.SpellTypes.NONE
var _invincible: bool = false
var _inc_health_timer: float


onready var recent_damager_reset: Timer = $RecentDamagerReset
onready var healSound: AudioStreamPlayer3D = $Sound


func _ready():
	var playerbot = parent_entity.get_component_of_type(Globals.ComponentTypes.PlayerBot)
	if playerbot != null:
		max_health = playerbot.get_max_health()
	
	_health = max_health
	
	parent_entity.connect("took_damage", self, "_on_took_damage")
	parent_entity.connect("add_health", self, "_on_add_health")
	parent_entity.connect("update_max_health", self, "_on_update_max_health")


func increase_max_health_with(increase_with: float) -> void:
	if Lobby.is_host:
		parent_entity.emit_signal("update_max_health", (max_health + increase_with))


func _physics_process(delta: float) -> void:
	if is_dead() == false:
		var space_state = parent_entity.get_world().direct_space_state
		_update_iteration += 1
		
		var result = space_state.intersect_ray(parent_entity.global_transform.origin + Vector3.UP * 10, parent_entity.global_transform.origin + Vector3.DOWN * 10, [parent_entity.get_kinematic(), parent_entity.get_area()], map_collision_layer + death_collision_layer)
		if result.get("collider") != null:
			var collider = result.collider
			
			if Lobby.is_host == true && _update_iteration % 10 == 0 && collider.collision_layer == death_collision_layer:
				parent_entity.emit_signal("took_damage", int(delta * 460), parent_entity)
			
			if  parent_entity.get_area().get_child(0).disabled == false:
				if collider.collision_layer == death_collision_layer:
					parent_entity.emit_signal("trigger_player_animation", Globals.PlayerAnimations.ENTER_WATER, Vector2.ZERO)
				else: 
					parent_entity.emit_signal("trigger_player_animation", Globals.PlayerAnimations.EXIT_WATER, Vector2.ZERO)
			
		_inc_health_timer += delta
		if _inc_health_timer >= 1.5:
			_inc_health_timer = 0
			_on_add_health(_regen_amount)
		# If a fishard is in the outer space kill
		elif parent_entity.get_pos().z > 5000:
			if Lobby.is_host == true && _update_iteration % 10 == 0:
				parent_entity.emit_signal("took_damage", int(delta * 400), parent_entity)


func get_health() -> int:
	# If _health hasn't been set yet due to incorrect _ready() order, return max health
	if _health == -9999: 
		return max_health
	
	return _health


func get_invincible() -> bool:
	return _invincible


func get_recent_damager_id() -> int:
	return _recent_damager_id


func get_recent_damager_spell() -> int:
	return _recent_damager_spell


func p2p_set_health(value: int) -> void:
	_health = value
	_update_health_bar()


func p2p_update_max_health(value: int) -> void:
	max_health = value
	_update_health_bar(true)


func reset_recent_damager() -> void:
	_recent_damager_id = -1
	_recent_damager_spell = Globals.SpellTypes.NONE


func set_invincible(value: bool) -> void:
	_invincible = value


func host_reset_health() -> void:
	if Lobby.is_host:
		_health = max_health
		_update_health_bar()
		PacketSender.update_health(parent_entity.get_id(), _health, parent_entity.get_type())


func is_dead() -> bool:
	return _health <= 0


func _on_took_damage(damage: int, damager_entity: Entity):
	if is_dead() == false:
		if _invincible == false:
			if parent_entity.get_type() == Globals.EntityTypes.PLAYER && damager_entity.get_type() == Globals.EntityTypes.SPELL:
				var player_component = parent_entity.get_component_of_type(Globals.ComponentTypes.Player)
				match damager_entity.get_subtype():
					Globals.SpellTypes.METEOR, Globals.SpellTypes.DASH_BEAM:
						player_component.set_death_type(Globals.PlayerDeathTypes.EXPLODE)
					Globals.SpellTypes.FIREBALL, Globals.SpellTypes.FIREBLAST, Globals.SpellTypes.WILDFIRE:
						player_component.set_death_type(Globals.PlayerDeathTypes.BURN)
					_: 
						player_component.set_death_type(Globals.PlayerDeathTypes.NORMAL)
			
			if damager_entity.get_type() == Globals.EntityTypes.SPELL:
				_recent_damager_id = damager_entity.get_creator_id()
				_recent_damager_spell = damager_entity.get_subtype()
				recent_damager_reset.start()
				
				# If a totem created the spell, make sure the _recent_damager_id is the creator of that turret
				var room_node = Util.get_room_node()
				if room_node != null:
					var damage_creator: Entity = room_node.get_entity(damager_entity.get_creator_id(), "health somewhere")
					if damage_creator != null:
						if damage_creator.get_type() == Globals.EntityTypes.SPELL && damage_creator.get_subtype() == Globals.SpellTypes.TOTEM:
							_recent_damager_id = damage_creator.get_creator_id()
						
					var recent_damage_creator: Entity = room_node.get_entity(_recent_damager_id, "health somewhere")
					if recent_damage_creator != null:
						if recent_damage_creator.get_type() == Globals.EntityTypes.PLAYER:
							var player_component = recent_damage_creator.get_component_of_type(Globals.ComponentTypes.Player)
							if player_component != null:
								if player_component.get_is_clone() == true:
									_recent_damager_id = player_component.get_cloned_from()
				
				# Hurt particle effects
				match damager_entity.get_subtype():
					Globals.SpellTypes.FIREBLAST:
						parent_entity.emit_signal("trigger_particle_effect", Globals.ParticleEffects.FIREBLAST_HURT, true, damager_entity.rotation.y)
					Globals.SpellTypes.WILDFIRE:
						parent_entity.emit_signal("trigger_particle_effect", Globals.ParticleEffects.WILDFIRE_HURT, true, damager_entity.rotation.y)
					Globals.SpellTypes.FIREBALL:
						parent_entity.emit_signal("trigger_particle_effect", Globals.ParticleEffects.FIRE_HURT, true, damager_entity.rotation.y)
					Globals.SpellTypes.DASH_BEAM:
						parent_entity.emit_signal("trigger_particle_effect", Globals.ParticleEffects.DASH_BEAM_HURT, true, damager_entity.rotation.y)
			
			if Lobby.is_host:
				_health -= damage
				PacketSender.update_health(parent_entity.get_id(), _health, parent_entity.get_type())
			
		if _health <= 0:
			# Custom logic for player death types
			parent_entity.emit_signal("no_health")
			
			if despawn_on_no_health:
				#print("[Despawn, Sending packet]: Removing entity with no health with id ", parent_entity.get_id())
				PacketSender.host_broadcast_destroy_entity(parent_entity.get_id())


func _on_add_health(amount: int):
	if amount != _regen_amount: # TODO: a bit hardcoded sorry
		parent_entity.emit_signal("trigger_particle_effect", Globals.ParticleEffects.HEALED, true, 0)
		healSound.global_transform.origin = get_parent().get_pos()
		healSound.play()
	
	if Lobby.is_host:
		if (_health + amount) > max_health:
			_health = max_health
		else:
			_health += amount
		PacketSender.update_health(parent_entity.get_id(), _health, parent_entity.get_type())


func _on_update_max_health(value: int):
	if Lobby.is_host:
		max_health = value
		PacketSender.update_max_health(parent_entity.get_id(), max_health)


func _update_health_bar(update_max_health: bool = false) -> void:
	var entity_info_panel = parent_entity.get_component_of_type(Globals.ComponentTypes.EntityInfoPanel)
	if Util.safe_to_use(entity_info_panel):
		if update_max_health:
			entity_info_panel.update_max_health(max_health)
		
		entity_info_panel.update_health(_health)


func _on_RecentDamagerReset_timeout():
	reset_recent_damager()
