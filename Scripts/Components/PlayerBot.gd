extends Component
class_name PlayerBot
var COMPONENT_TYPE: int = Globals.ComponentTypes.PlayerBot


onready var inWaterTimer = $InWaterTimer


const bot_type_values: Dictionary = {
	Globals.PlayerTypes.EASY_BOT: {"scale": Vector3(0.8, 0.8, 0.8), "health": 21, "can_spam": false, "cooldown_mod": 1.2},
	Globals.PlayerTypes.MEDIUM_BOT: {"scale": Vector3(1, 1, 1), "health": 33, "can_spam": false, "cooldown_mod": 0.65 },
	Globals.PlayerTypes.HARD_BOT: {"scale": Vector3(1.2, 1.2, 1.2), "health": 80, "can_spam": false, "cooldown_mod": 0.4},
	
	Globals.PlayerTypes.METEORARD: {"scale": Vector3(1, 1.3, 1), "health": 30, "can_spam": true, "cooldown_mod": 1, "available_spells": [Globals.SpellTypes.METEOR]},
	Globals.PlayerTypes.DASHARD: {"scale": Vector3(1, 0.8, 1), "health": 25, "can_spam": true, "cooldown_mod": 1.2, "available_spells": [Globals.SpellTypes.DASH]},
	Globals.PlayerTypes.FIREARD: {"scale": Vector3(0.9, 0.9, 0.9), "health": 30, "can_spam": false, "cooldown_mod": 0.4, "available_spells": [Globals.SpellTypes.FIREBALL]},
	
	Globals.PlayerTypes.MEGADASHARD: {"scale": Vector3(1.4, 1, 1.4), "health": 130, "can_spam": true, "cooldown_mod": 1, "available_spells": [Globals.SpellTypes.DASH], "sal": 14},
	Globals.PlayerTypes.PUSHARD: {"scale": Vector3(1.5, 1.3, 1.5), "health": 150, "can_spam": true, "cooldown_mod": 1, "available_spells": [Globals.SpellTypes.PUSH, Globals.SpellTypes.DASH], "sal": 16},
	Globals.PlayerTypes.SQUISHARD: {"scale": Vector3(1.6, 1.6, 1.6), "health": 200, "can_spam": true, "cooldown_mod": 1, "available_spells": [Globals.SpellTypes.FIREBLAST], "sal": 14},
	Globals.PlayerTypes.ICEARD: {"scale": Vector3(1.2, 1.2, 1.2), "health": 100, "can_spam": true, "cooldown_mod": 2, "available_spells": [Globals.SpellTypes.ICE_BEAM, Globals.SpellTypes.FREEZE_ORB], "sal": 14},
	Globals.PlayerTypes.GRABARD: {"scale": Vector3(1.4, 1.6, 1.4), "health": 150, "can_spam": true, "cooldown_mod":0.6, "available_spells": [Globals.SpellTypes.GRAB, Globals.SpellTypes.WILDFIRE, Globals.SpellTypes.FIREBLAST], "sal": 14},
}


var max_movement_time = 1.5
var min_movement_time = 0.5
var max_cast_spell_time = 3.0
var min_cast_spell_time = 1.5
var max_search_range = 9999
var _next_spell: int


var _boss_attack_ongoing: bool
var _ready_for_next_boss_attack: bool = true
var _is_boss: bool


var _update_movement_counter: float 
var _update_movement_max_time: float 
var _hunt_counter: float = Util.rand.randf_range(0, 1) # So that bots hunt on different frames
var _hunt_max_time: float = 1.5
var _update_cast_spell_counter: float 
var _update_cast_spell_max_time: float = Util.rand.randf_range(min_cast_spell_time, max_cast_spell_time)
var _pivot_check_counter: float
var _set_next_spell: bool = false


var _player: Player = null
var _spell_caster: SpellCaster = null
var _closest_enemy_id: int = -1
var _bump_into_death_layer_amount: int = 0


func get_max_health() -> int:
	var bot_type_values = get_bot_type_values()
	if Lobby.player_is_in_temp_bot(get_parent().get_id()) == true:
		var room_node = Util.get_room_node()
		if room_node != null && get_parent().get_subtype() != Globals.PlayerTypes.EASY_BOT && get_parent().get_subtype() != Globals.PlayerTypes.MEDIUM_BOT && get_parent().get_subtype() != Globals.PlayerTypes.HARD_BOT:
			return bot_type_values["health"] * room_node.gamemode.get_difficulty_health_mod(get_parent().get_subtype())
		else:
			return bot_type_values["health"]
	else:
		return 100


func get_bot_type_values() -> Dictionary:
	if bot_type_values.has(get_parent().get_subtype()):
		return bot_type_values[get_parent().get_subtype()]
	else:
		printerr("This bot type hasnt been added to bot_type_values yet: ", get_parent().get_subtype())
		return {}


func get_closest_enemy() -> Entity:
	if _closest_enemy_id != -1:
		var room_node = Util.get_room_node()
		if room_node != null:
			return room_node.get_entity(_closest_enemy_id)
	
	return null


func _ready():
	# Only start the bot if we are the host
	if Lobby.is_host:
		_player = parent_entity.get_component_of_type(Globals.ComponentTypes.Player)
		_spell_caster = parent_entity.get_component_of_type(Globals.ComponentTypes.SpellCaster)
	
	# temp_bots look different
	if Lobby.player_is_in_temp_bot(parent_entity.get_id()):
		var bot_type_values = get_bot_type_values()
		
		if bot_type_values.has("available_spells"):
			var info_panel = parent_entity.get_component_of_type(Globals.ComponentTypes.EntityInfoPanel)
			if info_panel != null:
				info_panel.hide_element_display()
		
		parent_entity.set_scale(bot_type_values["scale"]) 
		if _spell_caster != null && bot_type_values["can_spam"] == true:
			_spell_caster.set_squishard_mode(true)
	
	if parent_entity.get_subtype() == Globals.PlayerTypes.SQUISHARD && _player != null:
		_player.call_deferred("p2p_set_is_OP", 99999, false, false)
	
	_is_boss = Util.player_is_boss(parent_entity.get_subtype())


func kill_bot() -> void:
	set_process(false)


func respawn_bot() -> void:
	set_process(true)


func _process(delta: float) -> void:
	# Only update the bot if we are the host
	if Lobby.is_host && RoomSettings.get_game_started() == true && parent_entity.get_subtype() != Globals.PlayerTypes.DUMB_BOT && !Globals.game_paused:
		var in_water = check_in_water(delta)
		
		if in_water == false:
			_check_update_movement(delta)
			_check_cast_spell(delta)
			_check_pivot(delta)
		
		_find_closest_enemy(delta)
		_aim_at_closest_enemy()


func check_in_water(delta: float) -> bool:
	if Util.safe_to_use(_player):
		var in_water = _player.get_in_water()
		if in_water == true:
			
			var to_land: Vector2 = get_land_direction()
			if to_land != Vector2.INF:
				_player.set_input(to_land)
			
			if inWaterTimer.is_stopped():
				inWaterTimer.start(0.5 + Util.rand.randf())
		
		return in_water
	
	return false


func _find_closest_enemy(delta: float):
	_hunt_counter += delta
	var room_node = Util.get_room_node()
	if room_node != null:
		if _hunt_counter > _hunt_max_time && Util.safe_to_use(_player):
			_hunt_counter = 0
			
			var closest_player = room_node.players.get_closest_enemy_player(parent_entity.get_pos(), parent_entity.get_id(), _player.get_team(), true)
			var closest_totem = room_node.spells.get_closest_enemy_totem(parent_entity.get_pos(), _player.get_team())
			var closest_turret = room_node.environment.get_closest_enemy_turret(parent_entity.get_pos(), _player.get_team())
			
			var closest_enemy: Entity = null
			if closest_player != null:
				if closest_turret != null:
					# Prioritise killing players over turrets
					if closest_player.get_pos().distance_squared_to(parent_entity.get_pos()) < closest_turret.get_pos().distance_squared_to(parent_entity.get_pos()) * 2:
						_closest_enemy_id = closest_player.get_id()
						closest_enemy = closest_player
					else:
						_closest_enemy_id = closest_turret.get_id()
						closest_enemy = closest_turret
				elif closest_totem != null:
					# Prioritise killing players over totems
					if closest_player.get_pos().distance_squared_to(parent_entity.get_pos()) < closest_totem.get_pos().distance_squared_to(parent_entity.get_pos()) * 2:
						_closest_enemy_id = closest_player.get_id()
						closest_enemy = closest_player
					else:
						_closest_enemy_id = closest_totem.get_id()
						closest_enemy = closest_totem
				else:
					_closest_enemy_id = closest_player.get_id()
					closest_enemy = closest_player
			
			# If we are playing survival enemy bots should attack the googey god
			var current_gamemode: int = RoomSettings.get_rounds_gamemode()
			if current_gamemode == GamemodeValues.Gamemodes.Survive:
				if room_node != null && _player.get_team() == "Red Team":
					var gooey_god = room_node.get_gooey_god()
					if Util.safe_to_use(gooey_god):
						var dist_to_player = 9999
						if closest_player != null:
							dist_to_player = closest_player.get_pos().distance_squared_to(parent_entity.get_pos())
							
						var attack_player_chance = 40 / clamp(dist_to_player, 40, 9999)
						if attack_player_chance < 0.3 + Util.rand.randf()/5:
							_closest_enemy_id = gooey_god.get_id()
							closest_enemy = gooey_god
			
			if closest_enemy == null:
				_closest_enemy_id = -1


func _aim_at_closest_enemy():
	var closest_enemy = get_closest_enemy()
	if closest_enemy != null:
		var cast_direction: Vector3 = parent_entity.global_transform.origin.direction_to(closest_enemy.global_transform.origin)
		var cast_direction2d = Vector2(cast_direction.x, cast_direction.z)
		parent_entity.set_target_rotation(cast_direction2d.angle_to(Vector2.DOWN), 10)


func _check_cast_spell(delta: float) -> void:
	_update_cast_spell_counter += delta
	var closest_enemy = get_closest_enemy()
	
	# Decide our next spell before we cast it
	if _update_cast_spell_counter > _update_cast_spell_max_time - 0.1 && _set_next_spell == false:
		_set_next_spell = true
		var prev_spell: int = _next_spell
		var available_spells = Util.get_spell_array_from_elements(_spell_caster.get_available_elements())
		var bot_type_values = get_bot_type_values()
		if bot_type_values.has("available_spells"):
			available_spells = bot_type_values["available_spells"]
		
		var index: int = Util.rand.randi_range(0, available_spells.size() - 1)
		if index >= 0 && index < available_spells.size():
			_next_spell = available_spells[Util.rand.randi_range(0, available_spells.size() - 1)]
		else:
			printerr("Tried to get a spell that was out of index, available spells are: ", available_spells)
		
		# If we aren't casting the same spell next time, deactivate so thing feel more natural
		if _next_spell != prev_spell && _spell_caster.check_cooldown_of_spell_over(_next_spell) == true:
			_spell_caster.deactivate_spell()
	
	if _update_cast_spell_counter > _update_cast_spell_max_time && closest_enemy != null:
		_update_cast_spell_counter = 0
		_set_next_spell = false
		
		try_boss_attack(closest_enemy)
		
		# Only shoot if we are close enough
		var dist: float = closest_enemy.get_pos().distance_squared_to(parent_entity.get_pos())
		if dist < 200 && _boss_attack_ongoing == false:
			if Util.safe_to_use(_player):
				if _player.get_is_OP() == true:
					_update_cast_spell_max_time = 0.2
				else:
					var cooldown_mod = get_bot_type_values()["cooldown_mod"]
					_update_cast_spell_max_time = Util.rand.randf_range(min_cast_spell_time * cooldown_mod, max_cast_spell_time * cooldown_mod)
			
			# Temp bots cannot shoot arcane wall, its too annoying
			if _next_spell == Globals.SpellTypes.ARCANE_WALL && Lobby.player_is_in_temp_bot(parent_entity.get_id()) && (parent_entity.get_subtype() == Globals.PlayerTypes.EASY_BOT || parent_entity.get_subtype() == Globals.PlayerTypes.MEDIUM_BOT || parent_entity.get_subtype() == Globals.PlayerTypes.HARD_BOT):
				return
			
			cast_spell(closest_enemy.global_transform.origin, _next_spell)


func cast_spell(cast_point: Vector3, spell: int, ignore_cooldown: bool = false) -> void:
	_spell_caster.update_active_spell(spell, false, true)
	_spell_caster.try_request_cast_spell(cast_point, "", spell, ignore_cooldown)


func circle_attack(spell: int, amount: int) -> void:
	for i in amount:
		yield(get_tree().create_timer(0.03), "timeout")
		var rotation = deg2rad((float(i) / float(amount)) * 360.0)
		var cast_point = Util.y_rot_to_vector_3(rotation)
		cast_spell(parent_entity.get_pos() + cast_point.normalized() * 2, spell, true)
		


func try_boss_attack(closest_enemy: Entity) -> void:
	if _ready_for_next_boss_attack == true && _is_boss == true:
		_ready_for_next_boss_attack = false
		_boss_attack_ongoing = true
		
		var special_attack_length = bot_type_values[Globals.PlayerTypes.MEGADASHARD]["sal"]
		$BossAttackTimer.start(special_attack_length)
		
		if parent_entity.get_subtype() == Globals.PlayerTypes.ICEARD:
			iceard_boss_attack(closest_enemy)
		
		if parent_entity.get_subtype() == Globals.PlayerTypes.MEGADASHARD:
			megadashard_boss_attack(closest_enemy)
		
		if parent_entity.get_subtype() == Globals.PlayerTypes.PUSHARD:
			pushard_boss_attack(closest_enemy)
		
		if parent_entity.get_subtype() == Globals.PlayerTypes.GRABARD:
			grabard_boss_attack(closest_enemy)
		
		if parent_entity.get_subtype() == Globals.PlayerTypes.SQUISHARD:
			squishard_boss_attack(closest_enemy)


func pushard_boss_attack(closest_enemy) -> void:
	cast_spell(closest_enemy.global_transform.origin, Globals.SpellTypes.HEAL)
	parent_entity.set_trapped_w_duration(0.5)
	
	yield(get_tree().create_timer(0.6), "timeout")
	if closest_enemy_not_safe(closest_enemy):
		return
	cast_spell(closest_enemy.global_transform.origin, Globals.SpellTypes.DASH)
	
	yield(get_tree().create_timer(0.4), "timeout")
	circle_attack(Globals.SpellTypes.PUSH, 5)
	
	yield(get_tree().create_timer(0.7), "timeout")
	_boss_attack_ongoing = false


func grabard_boss_attack(closest_enemy) -> void:
	cast_spell(closest_enemy.global_transform.origin, Globals.SpellTypes.HEAL)
	parent_entity.set_trapped_w_duration(1)
	
	yield(get_tree().create_timer(1.1), "timeout")
	if closest_enemy_not_safe(closest_enemy):
		return
	cast_spell(closest_enemy.global_transform.origin, Globals.SpellTypes.DIVE)
	parent_entity.set_trapped_w_duration(0.5)
	
	yield(get_tree().create_timer(0.6), "timeout")
	if closest_enemy_not_safe(closest_enemy):
		return
	circle_attack(Globals.SpellTypes.GRAB, 6)
	
	yield(get_tree().create_timer(1), "timeout")
	circle_attack(Globals.SpellTypes.FIREBLAST, 4)
	
	yield(get_tree().create_timer(0.2), "timeout")
	circle_attack(Globals.SpellTypes.METEOR, 3)
	
	yield(get_tree().create_timer(0.7), "timeout")
	_boss_attack_ongoing = false


func iceard_boss_attack(closest_enemy) -> void:
	cast_spell(closest_enemy.global_transform.origin, Globals.SpellTypes.INVISIBILITY)
	parent_entity.set_trapped_w_duration(1)
	
	yield(get_tree().create_timer(1.1), "timeout")
	if closest_enemy_not_safe(closest_enemy):
		return
	cast_spell(closest_enemy.global_transform.origin, Globals.SpellTypes.DIVE, true)
	
	yield(get_tree().create_timer(0.6), "timeout")
	circle_attack(Globals.SpellTypes.FREEZE_ORB, 3)
	
	yield(get_tree().create_timer(1.2), "timeout")
	circle_attack(Globals.SpellTypes.FREEZE_ORB, 4)
	
	yield(get_tree().create_timer(1.2), "timeout")
	_boss_attack_ongoing = false


func megadashard_boss_attack(closest_enemy) -> void:
	cast_spell(closest_enemy.global_transform.origin, Globals.SpellTypes.INVISIBILITY)
	parent_entity.set_trapped_w_duration(1)
	
	yield(get_tree().create_timer(1), "timeout")
	if closest_enemy_not_safe(closest_enemy):
		return
	cast_spell(closest_enemy.global_transform.origin, Globals.SpellTypes.DASH)
	
	yield(get_tree().create_timer(0.3), "timeout")
	if closest_enemy_not_safe(closest_enemy):
		return
	cast_spell(closest_enemy.global_transform.origin, Globals.SpellTypes.DASH)
	
	yield(get_tree().create_timer(0.3), "timeout")
	if closest_enemy_not_safe(closest_enemy):
		return
	cast_spell(closest_enemy.global_transform.origin, Globals.SpellTypes.DASH)
	
	yield(get_tree().create_timer(0.7), "timeout")
	_boss_attack_ongoing = false


func squishard_boss_attack(closest_enemy) -> void:
	circle_attack(Globals.SpellTypes.FIREBALL, 5)
	
	yield(get_tree().create_timer(1.1), "timeout")
	if closest_enemy_not_safe(closest_enemy):
		return
	cast_spell(closest_enemy.global_transform.origin, Globals.SpellTypes.DIVE)
	
	yield(get_tree().create_timer(0.5), "timeout")
	circle_attack(Globals.SpellTypes.METEOR, 4)
	
	yield(get_tree().create_timer(1.2), "timeout")
	if closest_enemy_not_safe(closest_enemy):
		return
	cast_spell(closest_enemy.global_transform.origin, Globals.SpellTypes.DASH)
	
	yield(get_tree().create_timer(1), "timeout")
	circle_attack(Globals.SpellTypes.METEOR, 4)
	
	yield(get_tree().create_timer(0.8), "timeout")
	_boss_attack_ongoing = false


func closest_enemy_not_safe(closest_enemy) -> bool:
	return !Util.safe_to_use(closest_enemy)


func _on_BossAttackTimer_timeout():
	_boss_attack_ongoing = false
	_ready_for_next_boss_attack = true


func set_bot_active_spell(spell: int, available_spells: Array) -> bool:
	if available_spells.has(spell) && _spell_caster != null:
		_spell_caster.update_active_spell(spell, false, true)
		return true
	return false


func _check_update_movement(delta: float):
	_update_movement_counter += delta
	if(_update_movement_counter > _update_movement_max_time):
		_update_movement_counter = 0
		
		if _bump_into_death_layer_amount > 0:
			_bump_into_death_layer_amount -= 1
		
		if Util.safe_to_use(_player):
			# If a bot isn't fighting don't strafe. Also, if we have bumped around into 
			# different sides of a bridge for instance decrease movement time so we can get out
			if _bump_into_death_layer_amount > 3 || _closest_enemy_id == null:
				_update_movement_max_time = Util.rand.randf_range(min_movement_time / 6, max_movement_time / 6)
			elif _player.get_is_OP() == false || parent_entity.get_subtype() != Globals.PlayerTypes.SQUISHARD:
				_update_movement_max_time = Util.rand.randf_range(min_movement_time, max_movement_time)
			else:
				_update_movement_max_time = Util.rand.randf_range(min_movement_time / 2, max_movement_time / 2)
			
			var closest_enemy = get_closest_enemy()
			if closest_enemy != null:
				var dir: Vector3 = parent_entity.global_transform.origin.direction_to(closest_enemy.global_transform.origin)
				
				var too_close = parent_entity.get_pos().distance_squared_to(closest_enemy.get_pos()) < 15
				if too_close == true:
					dir *= -1
				
				var x_dir = 1 if dir.x > 0 else -1
				var y_dir = 1 if dir.z > 0 else -1
				
				# Add some randomness to the movement
				var rand = Util.rand.randf()
				if rand > 0.9:
					x_dir = 0
					y_dir = 0
				#elif rand > 0.75:
				#	x_dir += Util.rand.randi_range(-1, 1)
				#elif rand > 0.5:
				#	y_dir += Util.rand.randi_range(-1, 1)
				
				_player.set_input(Vector2(x_dir, y_dir))
			else:
				_player.set_input(Vector2(Util.rand.randi_range(-1, 1), Util.rand.randi_range(-1, 1)))


func _check_pivot(delta: float):
	# Dont check this every process
	_pivot_check_counter += delta
	if _pivot_check_counter > 0.2 && Util.safe_to_use(_player) && Util.safe_to_use(parent_entity):
		_pivot_check_counter = 0
		
		var space_state = parent_entity.get_world().get_direct_space_state()
		var result0 = space_state.intersect_ray(parent_entity.global_transform.origin + Vector3.UP + Vector3(1, 0, 0), Vector3(parent_entity.global_transform.origin.x + 1, parent_entity.global_transform.origin.y - 10, parent_entity.global_transform.origin.z), [], 8)
		var result1 = space_state.intersect_ray(parent_entity.global_transform.origin + Vector3.UP + Vector3(-1, 0, 0), Vector3(parent_entity.global_transform.origin.x - 1, parent_entity.global_transform.origin.y - 10, parent_entity.global_transform.origin.z), [], 8)
		var result2 = space_state.intersect_ray(parent_entity.global_transform.origin + Vector3.UP + Vector3(0, 0, 1), Vector3(parent_entity.global_transform.origin.x, parent_entity.global_transform.origin.y - 10, parent_entity.global_transform.origin.z + 1), [], 8)
		var result3 = space_state.intersect_ray(parent_entity.global_transform.origin + Vector3.UP + Vector3(0, 0, -1), Vector3(parent_entity.global_transform.origin.x, parent_entity.global_transform.origin.y - 10, parent_entity.global_transform.origin.z - 1), [], 8)
		if result0.get("collider") == null:
			_player.set_input(Vector2(-1, 0))
			_bump_into_death_layer_amount += 1
		elif result1.get("collider") == null:
			_player.set_input(Vector2(1, 0))
			_bump_into_death_layer_amount += 1
		elif result2.get("collider") == null:
			_player.set_input(Vector2(0, -1))
			_bump_into_death_layer_amount += 1
		elif result3.get("collider") == null:
			_player.set_input(Vector2(0, 1))
			_bump_into_death_layer_amount += 1


func get_land_direction() -> Vector2:
	var above_player = parent_entity.global_transform.origin + Vector3.UP
	var under_player = parent_entity.global_transform.origin + Vector3.DOWN * 10
	var space_state = parent_entity.get_world().get_direct_space_state()
	var check_dist = 5
	var dir: Vector2 = Vector2.INF
	
	var result0 = space_state.intersect_ray(above_player + Vector3(check_dist, 0, 0), under_player + Vector3(check_dist, 0, 0), [], 8)
	var result1 = space_state.intersect_ray(above_player + Vector3(-check_dist, 0, 0), under_player + Vector3(-check_dist, 0, 0), [], 8)
	var result2 = space_state.intersect_ray(above_player + Vector3(0, 0, check_dist), under_player + Vector3(0, 0, check_dist), [], 8)
	var result3 = space_state.intersect_ray(above_player + Vector3(0, 0, -check_dist), under_player + Vector3(0, 0, -check_dist), [], 8)
	
	if result0.get("collider") != null:
		dir = Vector2(1, 0)
	elif result1.get("collider") != null:
		dir = Vector2(-1, 0)
	elif result2.get("collider") != null:
		dir = Vector2(0, 1)
	elif result3.get("collider") != null:
		dir = Vector2(0, -1)
	
	return dir


func _on_InWaterTimer_timeout():
	# Random chance that bot will use spell to get to land
	var closest_enemy = get_closest_enemy()
	if closest_enemy != null:
		var available_spells = Util.get_spell_array_from_elements(_spell_caster.get_available_elements())
		var bot_type_values = get_bot_type_values()
		if bot_type_values.has("available_spells"):
			available_spells = bot_type_values["available_spells"]
		
		if available_spells.has(Globals.SpellTypes.DASH):
			_spell_caster.update_active_spell(Globals.SpellTypes.DASH, false, true)
			_spell_caster.try_request_cast_spell(closest_enemy.global_transform.origin)
		elif available_spells.has(Globals.SpellTypes.INVISIBILITY):
			_spell_caster.update_active_spell(Globals.SpellTypes.INVISIBILITY, false, true)
			_spell_caster.try_request_cast_spell(closest_enemy.global_transform.origin)
		elif available_spells.has(Globals.SpellTypes.DIVE):
			_spell_caster.update_active_spell(Globals.SpellTypes.DIVE, false, true)
			_spell_caster.try_request_cast_spell(closest_enemy.global_transform.origin)
