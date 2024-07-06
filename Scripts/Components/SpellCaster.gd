extends Component
class_name SpellCaster
var COMPONENT_TYPE: int = Globals.ComponentTypes.SpellCaster

var spellHUD: Control
var _player_component

var active_spell: int = Globals.SpellTypes.NONE
var _prev_spell: int = Globals.SpellTypes.NONE
var stance: int = Globals.PlayerStances.FLOP_AROUND
var casting_spell_w_cast_time: bool = false
var cast_time_queued_spell: int = Globals.SpellTypes.NONE
var holding_down_spell: bool = false
var joy_right_direction: Vector2 = Vector2.ZERO
var joy_right_active: bool = false
var _latest_dir: Vector2 = Vector2.ZERO
var _children_spell_ids: Array
var amount_of_spells_fired: int = 0
var amount_of_clicks: int = 0
var _immobilized: bool = false
var _is_helpless: bool = false
var _knows_how_to_cast_spell: bool = false
var _knows_how_to_hold_down: bool = false
var _fireballs_cast: int = 0
var _times_cast_one_fireball: int = 0


# By default we have access to all the elements, this is changed in init_spell_caster() however.
var available_elements: Array = [Globals.Elements.FIRE, Globals.Elements.WATER, Globals.Elements.EARTH, Globals.Elements.ARCANE, Globals.Elements.GOO]
var selected_elements: Array = [Globals.Elements.NONE, Globals.Elements.NONE]
# Starts at -1 so that fill_next_element_slot will work the first time
var selected_elements_index: int = -1

var _spell_cooldowns: Dictionary 
var _squishard_mode: bool = false
var _prev_cast_spell_input_successful: bool
var _changed_stance_before_reset_els_timeout: bool
var _stance_before_reset: int

onready var _rock_dash_timer: Timer = $RockDashTimer
var _is_rock_dashing: bool = false

# Transform into spell stuff
export(NodePath) var default_entity_model_path: NodePath
export(NodePath) var transform_container_path: NodePath
onready var _transform_container: Spatial
var _default_entity_model
var is_transformed: bool

var _entity_info_panel: EntityInfoPanel
var _dive_pos: Vector3
var _health_component: Health

var _invisibility_time: float = 2.0

onready var diveCastTimer: Timer = $DiveCastTimer
onready var transformDurationTimer: Timer = $TransformDurationTimer
onready var spellCastTimer: Timer = $SpellCastTimer
onready var elementTip: Control = $ElementTip
onready var holdDownTip: Control = $HoldDownTip
onready var notCastSpellTimer: Timer = $NotCastSpellTimer
onready var resetElementsTimer: Timer = $ResetElementsTimer
onready var oneElementOnlyTimer: Timer = $OneElementOnlyTimer


func init_spell_caster(elements: Array) -> void:
	if parent_entity != null:
		var info_panel = parent_entity.get_component_of_type(Globals.ComponentTypes.EntityInfoPanel)
		if info_panel != null:
			info_panel.update_element_display(elements)
	available_elements = elements
	
	#var player = get_parent().get_component_of_type(Globals.ComponentTypes.Player)
	#if player != null:
	#	print("set elements for ", player._username , elements)


func _ready():
	restart_cooldowns()
	
	spellHUD = get_node("SpellHUD")
	Lobby.connect("destroy_entity", self, "_on_child_spell_destroyed")
	notCastSpellTimer.connect("timeout", self, "_on_not_cast_spell_timeout")
	
	if parent_entity.is_my_client == false:
		if Util.safe_to_use(get_node("SpellMarker")):
			get_node("SpellMarker").queue_free()
		spellHUD.set_visible(false)
		spellHUD.set_process(false)
	else:
		spellHUD.set_visible(true)
	
	_knows_how_to_cast_spell = UserSettings.get_has_cast_spell()
	_knows_how_to_hold_down = UserSettings.get_has_held_down_spell()
	
	if transform_container_path:
		_transform_container = get_node(transform_container_path)
	if default_entity_model_path:
		_default_entity_model = get_node(default_entity_model_path)
	
	_entity_info_panel = parent_entity.get_component_of_type(Globals.ComponentTypes.EntityInfoPanel)
	_player_component = parent_entity.get_component_of_type(Globals.ComponentTypes.Player)
	_health_component = parent_entity.get_component_of_type(Globals.ComponentTypes.Health)
	
	Lobby.connect("lobby_members_updated", self, "_on_lobby_members_updated")
	parent_entity.connect("took_damage", self, "_on_took_damage")
	parent_entity.connect("no_health", self, "_on_no_health")
	parent_entity.get_area().connect("area_entered", self, "_on_entity_collided")
	
	update_player_speed_from_active_spell(is_transformed)


func get_immobilized() -> bool:
	return _immobilized


func get_available_elements() -> Array: 
	return available_elements


func get_spell_spawn_pos() -> Vector3:
	if Lobby.is_host:
		return Vector3(parent_entity.global_transform.origin.x, parent_entity.global_transform.origin.y + 1.5, parent_entity.global_transform.origin.z)
	else:
		return Vector3(parent_entity._target_position.x, parent_entity._target_position.y + 1.5, parent_entity._target_position.z)


func _input(event):
	if parent_entity.is_my_client:
		if Globals.ui_interaction_mode == Globals.UIInteractionModes.GAMEPLAY && Input.is_action_just_pressed("cast_spell"):
			if active_spell == Globals.SpellTypes.NONE:
				MusicAndSfxHandler.play_sound(MusicAndSfxHandler.sounds.SPELL_EMPTY)
		
		# Controller right stick direction
		if Util.controller_connected:
			var dir: Vector2
			dir.x = Input.get_action_strength("joy_right_right") - Input.get_action_strength("joy_right_left")
			dir.y = Input.get_action_strength("joy_right_down") - Input.get_action_strength("joy_right_up")
			if dir != Vector2.ZERO:
				joy_right_direction = dir.normalized()
				_latest_dir = joy_right_direction
				joy_right_active = true
			else:
				joy_right_direction = _latest_dir
				joy_right_active = false


func _process(delta: float) -> void:
	if parent_entity.is_my_client:
		_check_change_elements()
		
		if Input.is_action_just_pressed("cast_spell"):
			_prev_cast_spell_input_successful = allowed_to_cast_spell(active_spell)
		
		if holding_down_spell == true:
			reset_cooldown_of_spell(active_spell)
			_prev_cast_spell_input_successful = true
		
		if allowed_to_cast_spell(active_spell) == true && Input.is_action_pressed("cast_spell"):
			var has_cast_time = Globals.SpellCooldowns[active_spell].has("cast_time")
			if has_cast_time == true:
				if casting_spell_w_cast_time == false:
					cast_time_queued_spell = active_spell
					casting_spell_w_cast_time = true
					spellCastTimer.start(Globals.SpellCooldowns[active_spell]["cast_time"])
					_check_casting_animation()
			else:
				try_request_cast_spell()
		
		# For when we release a hold down spell or cooldown is over
		var hold_down_spell: bool = Globals.SpellCooldowns[active_spell]["hold_down"]
		if hold_down_spell == true && Input.is_action_just_released("cast_spell"):
			deactivate_spell(active_spell)
			if UserSettings.get_auto_clear_elements() == true:
				reset_elements(true)
		
		if Input.is_action_just_released("cast_spell") && active_spell != Globals.SpellTypes.NONE && _prev_cast_spell_input_successful == true:
			check_show_hold_down_tip()
			if UserSettings.get_auto_clear_elements() == true:
				reset_elements(true)
	
	_update_cooldowns(delta)


func set_squishard_mode(val: bool) -> void:
	_squishard_mode = val


func set_holding_down_spell(val: bool) -> void:
	holding_down_spell = val


func set_immobilized(val: bool, is_helpless: bool = false) -> void:
	# Never become mobilized again if we are helpless
	if _is_helpless == true && val == false:
		return
	
	Lobby.emit_signal("player_immobilized", parent_entity.get_id())
	if val == false && holding_down_spell && UserSettings.get_auto_clear_elements() == true:
		deactivate_spell(active_spell)
	_immobilized = val
	
	if is_helpless == true:
		_is_helpless = true 


func try_request_cast_spell(cast_pos: Vector3 = Vector3.DOWN, team_name: String = "", spell: int = active_spell, ignore_cooldown: bool = false) -> bool:
	var allowed_to_cast: bool = false
	var gameplay_mode: bool = Globals.ui_interaction_mode == Globals.UIInteractionModes.GAMEPLAY 
	var is_bot: bool = parent_entity.get_type() == Globals.EntityTypes.PLAYER && parent_entity.get_subtype() != Globals.PlayerTypes.CLIENT
	
	var available_spells = Util.get_spell_array_from_elements(get_available_elements())
	if available_spells.find(spell) == -1:
		return false
	
	check_show_cast_tip(spell)
	
	if (gameplay_mode || is_bot):
		if check_cooldown_of_spell_over(spell) && casting_spell_w_cast_time == false && holding_down_spell == false:
			# Some spells only reset after letting them go
			if Globals.SpellCooldowns[spell]["hold_down"] == false: 
				reset_cooldown_of_spell(spell)
			allowed_to_cast = true
		elif ignore_cooldown == true:
			allowed_to_cast = true
	
	# Discover spell if not yet discovered
	if allowed_to_cast && parent_entity.is_my_client:
		UserSettings.discover_spell(active_spell)
	
	# Logic so hold_down spells do not repeat
	if Globals.SpellCooldowns[spell]["hold_down"] == true:
		if check_cooldown_of_spell_over(spell):
			if holding_down_spell == false:
				holding_down_spell = true
	
	if allowed_to_cast == true:
		var cast_direction: Vector2
		var player_pos: Vector3 = parent_entity.get_global_transform().origin
		
		# If we haven't specified the spells pos, use the mouse to generate the pos:
		if cast_pos == Vector3.DOWN:
			cast_pos = Util.get_aim_position(parent_entity.get_world().get_direct_space_state())
			var cast_direction3d = get_spell_spawn_pos().direction_to(cast_pos)
			cast_direction = Vector2(cast_direction3d.x, cast_direction3d.z)
			
			if Util.controller_connected:
				cast_direction = joy_right_direction
		else:
			var cast_direction3d = get_spell_spawn_pos().direction_to(cast_pos)
			cast_direction = Vector2(cast_direction3d.x, cast_direction3d.z)
		
		if active_spell == Globals.SpellTypes.FIREBALL:
			_fireballs_cast += 1
		else:
			_fireballs_cast = 0
		
		match spell:
			Globals.SpellTypes.FIREBALL, Globals.SpellTypes.FIREBLAST, Globals.SpellTypes.DASH_BEAM, Globals.SpellTypes.PUSH, Globals.SpellTypes.WILDFIRE, Globals.SpellTypes.GRAB, Globals.SpellTypes.HEAL, Globals.SpellTypes.FREEZE_ORB, Globals.SpellTypes.ICE_BEAM:
				request_cast_spell_direction(cast_direction, team_name, spell)
			Globals.SpellTypes.DASH:
				_rock_dash(cast_direction)
			Globals.SpellTypes.INVISIBILITY:
				_invisibility()
			Globals.SpellTypes.METEOR: # TODO: Make all spells directional instead
				cast_pos = player_pos + Vector3(cast_direction.x, 0, cast_direction.y)* Globals.FIXED_SPELL_RANGE
				request_cast_spell_position(cast_pos, team_name, spell)
			Globals.SpellTypes.DIVE: # TODO: Make all spells directional instead
				cast_pos = player_pos + Vector3(cast_direction.x, 0, cast_direction.y)* Globals.DIVE_RANGE
				request_cast_spell_position(cast_pos, team_name, spell)
				clear_parented_spells() # Clear child spells
			Globals.SpellTypes.TOTEM:
				cast_pos = player_pos + Vector3(cast_direction.x, 0, cast_direction.y)* Globals.TOTEM_RANGE
				request_cast_spell_position(cast_pos, team_name, spell)
			_:
				request_cast_spell_position(cast_pos, team_name, spell)
		
		# Some spells slow rotation
		var player_component = parent_entity.get_component_of_type(Globals.ComponentTypes.Player)
		if player_component != null:
			if spell == Globals.SpellTypes.ICE_BEAM:
				player_component.set_slowed_rotation(PI * 0.35)
			elif spell == Globals.SpellTypes.WILDFIRE:
				player_component.set_slowed_rotation(PI * 1.5)
		
		return true
	
	return false


func request_cast_spell_position(cast_position: Vector3, team_name: String, spell: int = active_spell) -> void:
	PacketSender.request_cast_positional_spell(parent_entity.get_id(), spell, cast_position)


func request_cast_spell_direction(cast_direction: Vector2, team_name: String, spell: int = active_spell) -> void:
	PacketSender.request_cast_directional_spell(parent_entity.get_id(), spell, cast_direction) 


func _rock_dash(direction: Vector2) -> void:
	PacketSender.request_rock_dash(parent_entity.get_id(), direction)


func _invisibility() -> void:
	PacketSender.request_transform_into(parent_entity.get_id(), Globals.EnvironmentTypes.INVISIBILITY_BALL, Globals.INVIS_SPEED, _invisibility_time)


func host_activate_dive(pos: Vector3) -> void:
	if diveCastTimer.is_stopped():
		_health_component.set_invincible(true)
		if _immobilized == false:
			PacketSender.trigger_player_animation(parent_entity, Globals.PlayerAnimations.DIVE_DOWN)
		_spawn_effect_environment(Globals.EnvironmentTypes.SMALL_SPLASH)
		pos.y = 0;
		_dive_pos = pos
		diveCastTimer.start()


func activate_rock_dash(dir: Vector2) -> void:
	_is_rock_dashing = true
	_health_component.set_invincible(true)
	parent_entity.add_force(Vector3(dir.x, 0, dir.y) * Globals.ROCK_DASH_FORCE)
	_rock_dash_timer.start()
	request_cast_spell_direction(dir, "", Globals.SpellTypes.DASH)
	
	if parent_entity.get_type() == Globals.EntityTypes.PLAYER && _immobilized == false:
		PacketSender.trigger_player_animation(parent_entity, Globals.PlayerAnimations.START_ROCK_DASH)


func _on_not_cast_spell_timeout() -> void:
	if parent_entity.is_my_client && _knows_how_to_cast_spell == false:
		elementTip.show_tip()


func _on_rockdash_timer_over() -> void:
	if _is_rock_dashing == true:
		deactivate_rock_dash()


func _on_entity_collided(area: Area) -> void:
	var hit_entity: Entity = Util.get_entity_from_area(area)
	
	if hit_entity != null:
		# Some spells don't stop rockdashes
		if hit_entity.get_type() == Globals.EntityTypes.SPELL:
			if hit_entity.get_subtype() != Globals.SpellTypes.ARCANE_WALL && hit_entity.get_subtype() != Globals.SpellTypes.TOTEM:
				return
		
		if _is_rock_dashing == true:
			deactivate_rock_dash()


func deactivate_rock_dash() -> void:
	_health_component.set_invincible(false)
	_is_rock_dashing = false
	parent_entity.add_force(parent_entity.get_force() * -0.75)
	PacketSender.trigger_player_animation(parent_entity, Globals.PlayerAnimations.END_ROCK_DASH)


func _on_lobby_members_updated() -> void:
	for player_info in Lobby.get_all_lobby_player_info():
		# Temp bots dont update their elements
		if player_info["id"] == parent_entity.get_id() && Lobby.player_is_in_temp_bot(player_info["id"]) == false:
			init_spell_caster(player_info["elmts"])
			break


func _on_took_damage(_damage: float, _damager_entity: Entity) -> void:
	# If the host detects that a player is hit and they are transformed, transform back.
	if Lobby.is_host && is_transformed == true && !_health_component.get_invincible():
		PacketSender.transform_into(parent_entity.get_id(), -1)


func _on_no_health() -> void:
	if Lobby.is_host && is_transformed == true && !_health_component.get_invincible():
		PacketSender.transform_into(parent_entity.get_id(), -1)


func transform_into(transform_into: int, move_speed_change: float = 1.0, duration: float = -1) -> void:
	if _default_entity_model == null || _transform_container == null:
		printerr("This Spellcaster doesn't have a default_entity_model or _transform_container specified, it can't transform.")
		return
	
	var transforming_into_invisible: bool = false
	if transform_into == Globals.EnvironmentTypes.INVISIBILITY_BALL:
		transforming_into_invisible = true
	
	# Transform back
	if transform_into == -1 && is_transformed == true:
		# Things that might need to be reset
		_health_component.set_invincible(false)
		#parent_entity.disable_collider(false)
		transformDurationTimer.stop()
		
		_default_entity_model.visible = true
		is_transformed = false
		_entity_info_panel.show_panel()
		
		update_player_speed_from_active_spell(is_transformed)
		
		for i in range(0, _transform_container.get_child_count()):
			if Util.safe_to_use(_transform_container.get_child(i)):
				_transform_container.get_child(i).queue_free()
	
	# Transform into something
	elif is_transformed == false && transform_into != -1:
		if transforming_into_invisible:
			_health_component.set_invincible(true)
			#parent_entity.disable_collider(true)
		
		if duration != -1:
			transformDurationTimer.wait_time = duration
			transformDurationTimer.start()
		
		_default_entity_model.visible = false
		is_transformed = true
		
		if _player_component != null:
			_player_component.set_default_speed(Globals.INVIS_SPEED)
		
		if parent_entity.is_my_client == false:
			_entity_info_panel.hide_panel()
		
		var room_node = Util.get_room_node()
		if room_node != null:
			if room_node.environment != null:
				var env_scene = room_node.environment.get_scene_from_type(transform_into)
				if env_scene != null:
					var env = env_scene.instance()
					env.can_move = true;
					env.broadcast_transform = true
					
					_transform_container.add_child(env)
					
					# If the transformed entity has a collider it will collide with the player and cause jittery movement
					if env.get_area() != null:
						env.get_area().monitorable = false
						env.get_area().monitoring = false
					
					for env_child in env.get_children():
						if env_child is StaticBody:
							env_child.disabled = true


func _check_change_elements() -> void:
	if Globals.ui_interaction_mode == Globals.UIInteractionModes.GAMEPLAY:
		if Input.is_action_just_pressed("reset_elements"):
			reset_elements(true);
		
		for i in available_elements.size():
			var element_key = i + 1
			if Input.is_action_just_pressed("element_" + str(element_key)):
				fill_next_element_slot(available_elements[i])


func reset_elements(reset_spell_too: bool) -> void:
	selected_elements =  [Globals.Elements.NONE, Globals.Elements.NONE]
	selected_elements_index = -1
	if reset_spell_too == true:
		update_active_spell(Globals.SpellTypes.NONE, true, true)


# Keep track of which slot we are selecting, reset if we reach the
# max amount of 'spell slots'.
func fill_next_element_slot(element: int) -> void:
	selected_elements_index += 1;
	
	# Reset the selected slot when we all slots are full
	if selected_elements_index >= selected_elements.size():
		selected_elements_index = 0;
	
	# Reset the slots if we are at slot zero
	if (selected_elements_index == 0):
		for i in range(selected_elements.size()):
			selected_elements[i] = Globals.Elements.NONE
	
	# If we have two elements selected 
	if selected_elements_index == selected_elements.size() - 1:
		MusicAndSfxHandler.play_sound(MusicAndSfxHandler.sounds.SPELL_SELECTED)
		oneElementOnlyTimer.stop()
	# If we have one element selected
	elif selected_elements_index == 0:
		oneElementOnlyTimer.start()
		MusicAndSfxHandler.play_sound(MusicAndSfxHandler.sounds.ELEMENT_SELECT)
	
	# Set the requested element
	selected_elements[selected_elements_index] = element
	
	update_active_spell();


func update_active_spell(requested_spell: int = Globals.SpellTypes.NONE, delay_stance: bool = false, set_spell_without_correct_elements: bool = false) -> void:
	var new_spell: int = requested_spell
	
	# If we haven't requested a specific spell use the elements to decide the new spell
	if requested_spell == Globals.SpellTypes.NONE:
		new_spell = get_new_spell_from_stored_elements()
	
	# If we don't auto clear the spell shouldn't change once we don't have our element slots full
	if new_spell == Globals.SpellTypes.NONE && UserSettings.get_auto_clear_elements() == false:
		new_spell = active_spell
	
	# Force set the requested spell if set_spell_without_correct_elements is true
	if set_spell_without_correct_elements == true:
		new_spell = requested_spell
	
	var previous_spell: int = active_spell
	if previous_spell != Globals.SpellTypes.NONE:
		_prev_spell = previous_spell
	active_spell = new_spell
	
	update_stance_from_active_spell(delay_stance)
	
	if parent_entity.is_my_client:
		spellHUD.update_spell_config(selected_elements, active_spell, previous_spell)
		spellHUD.set_cooldown_values(_get_cooldown_progress_of_spell(active_spell), _get_max_cooldown_of_spell(active_spell), _get_charge_amount(active_spell), _get_max_charges(active_spell))
	
	if previous_spell != new_spell:
		var is_client = (parent_entity.get_type() == Globals.EntityTypes.PLAYER && parent_entity.get_type() == Globals.PlayerTypes.CLIENT)
		if parent_entity.is_my_client || Lobby.is_host && is_client == false:
			deactivate_spell(previous_spell)


func update_player_speed_from_active_spell(is_transformed: bool) -> void:
	# Players move faster if the have no spell selected
	if _player_component != null && is_transformed == false:
		_player_component.set_default_speed(Globals.FLOP_AROUND_SPEED if active_spell == Globals.SpellTypes.NONE else Globals.AIM_SPEED)


func update_stance_from_active_spell(delay_stance: bool) -> void:
	var new_player_stance = Globals.PlayerStances.FLOP_AROUND
	
	match active_spell:
		Globals.SpellTypes.FIREBALL:
			new_player_stance = Globals.PlayerStances.AIM
		Globals.SpellTypes.DIVE:
			new_player_stance = Globals.PlayerStances.BOMBARD
		Globals.SpellTypes.DASH:
			new_player_stance = Globals.PlayerStances.BOMBARD
		Globals.SpellTypes.ARCANE_WALL:
			new_player_stance = Globals.PlayerStances.AIM
		Globals.SpellTypes.METEOR:
			new_player_stance = Globals.PlayerStances.BOMBARD
		Globals.SpellTypes.PUSH:
			new_player_stance = Globals.PlayerStances.AIM
		Globals.SpellTypes.ICE_BEAM:
			new_player_stance = Globals.PlayerStances.AIM
		Globals.SpellTypes.FIREBLAST:
			new_player_stance = Globals.PlayerStances.AIM
		Globals.SpellTypes.CRAB:
			new_player_stance = Globals.PlayerStances.BOMBARD
		Globals.SpellTypes.INVISIBILITY:
			new_player_stance = Globals.PlayerStances.FLOP_AROUND
		Globals.SpellTypes.WILDFIRE:
			new_player_stance = Globals.PlayerStances.AIM
		Globals.SpellTypes.HEAL:
			new_player_stance = Globals.PlayerStances.BOMBARD
		Globals.SpellTypes.TOTEM:
			new_player_stance = Globals.PlayerStances.BOMBARD
		Globals.SpellTypes.DASH_BEAM:
			new_player_stance = Globals.PlayerStances.AIM
		Globals.SpellTypes.GRAB:
			new_player_stance = Globals.PlayerStances.AIM
		Globals.SpellTypes.FREEZE_ORB:
			new_player_stance = Globals.PlayerStances.AIM
	
	if delay_stance == true:
		_changed_stance_before_reset_els_timeout = false
		_stance_before_reset = new_player_stance
		resetElementsTimer.start(0.2)
	else:
		_changed_stance_before_reset_els_timeout = true
		update_stance(new_player_stance)


func _on_ResetElementsTimer_timeout():
	if _changed_stance_before_reset_els_timeout == false:
		update_stance(_stance_before_reset)


func update_stance(stance: int) -> void:
	if _player_component != null:
		_player_component.set_stance(stance)
		PacketSender.update_player_stance(parent_entity.get_id(), stance)


func get_prev_spell() -> int:
	return _prev_spell


func get_new_spell_from_stored_elements() -> int:
	if get_spell_from_elements(Globals.Elements.FIRE, Globals.Elements.FIRE):
		return Globals.SpellTypes.FIREBALL
	elif get_spell_from_elements(Globals.Elements.WATER, Globals.Elements.WATER):
		return Globals.SpellTypes.ICE_BEAM
	elif get_spell_from_elements(Globals.Elements.EARTH, Globals.Elements.EARTH):
		return Globals.SpellTypes.DASH
	elif get_spell_from_elements(Globals.Elements.ARCANE, Globals.Elements.ARCANE):
		return Globals.SpellTypes.ARCANE_WALL
	elif get_spell_from_elements(Globals.Elements.FIRE, Globals.Elements.EARTH):
		return Globals.SpellTypes.METEOR
	elif get_spell_from_elements(Globals.Elements.FIRE, Globals.Elements.WATER):
		return Globals.SpellTypes.PUSH
	elif get_spell_from_elements(Globals.Elements.WATER, Globals.Elements.EARTH):
		return Globals.SpellTypes.DIVE
	elif get_spell_from_elements(Globals.Elements.FIRE, Globals.Elements.ARCANE):
		return Globals.SpellTypes.FIREBLAST
	elif get_spell_from_elements(Globals.Elements.WATER, Globals.Elements.ARCANE):
		return Globals.SpellTypes.FREEZE_ORB
	elif get_spell_from_elements(Globals.Elements.EARTH, Globals.Elements.ARCANE):
		return Globals.SpellTypes.INVISIBILITY
	elif get_spell_from_elements(Globals.Elements.GOO, Globals.Elements.FIRE):
		return Globals.SpellTypes.WILDFIRE
	elif get_spell_from_elements(Globals.Elements.GOO, Globals.Elements.WATER):
		return Globals.SpellTypes.HEAL
	elif get_spell_from_elements(Globals.Elements.GOO, Globals.Elements.EARTH):
		return Globals.SpellTypes.TOTEM
	elif get_spell_from_elements(Globals.Elements.GOO, Globals.Elements.ARCANE):
		return Globals.SpellTypes.DASH_BEAM
	elif get_spell_from_elements(Globals.Elements.GOO, Globals.Elements.GOO):
		return Globals.SpellTypes.GRAB
	elif get_spell_from_elements(Globals.Elements.NONE, Globals.Elements.NONE):
		return Globals.SpellTypes.NONE
	
	return Globals.SpellTypes.NONE


func get_spell_from_elements(firstEl: int, secondEl: int) -> bool:
	if((selected_elements[0] == firstEl && selected_elements[1] == secondEl) 
	|| (selected_elements[0] == secondEl && selected_elements[1] == firstEl)):
		return true;
	else:
		return false;


func _get_default_cooldowns() -> Dictionary:
	var new_cooldowns: Dictionary = {}
	for spell_type in Globals.SpellCooldowns:
		new_cooldowns[spell_type] = {
			"cooldown_progress": 0,
			"charges": _get_max_charges(spell_type),
			"charge_regen_cooldown": 0,
		}
	
	return new_cooldowns


func _update_cooldowns(delta: float) -> void:
	for spell_id in _spell_cooldowns:
		_spell_cooldowns[spell_id].cooldown_progress -= delta
		_spell_cooldowns[spell_id].charge_regen_cooldown -= delta
		
		if parent_entity.is_my_client:
			spellHUD.update_cooldown_preview(active_spell, spell_id, _spell_cooldowns[spell_id].cooldown_progress)
		
		# For spells with charges slowly regen them
		if _get_max_charges(spell_id) > 1 && _spell_cooldowns[spell_id].charge_regen_cooldown < 0: 
			_spell_cooldowns[spell_id].charge_regen_cooldown = Globals.SpellCooldowns[spell_id].cooldown
			if _spell_cooldowns[spell_id].charges < _get_max_charges(spell_id):
				_spell_cooldowns[spell_id].charges += 1
			
			# If the cooldown is over and we have the spell selected, show the new charges amount
			if active_spell == spell_id && parent_entity.is_my_client && active_spell != Globals.SpellTypes.NONE:
				spellHUD.set_cooldown_values(_get_cooldown_progress_of_spell(active_spell), _get_max_cooldown_of_spell(active_spell), _get_charge_amount(active_spell), _get_max_charges(active_spell))


func _check_casting_animation(spell: int = active_spell) -> void:
	match spell:
		Globals.SpellTypes.DASH_BEAM:
			PacketSender.trigger_player_animation(parent_entity, Globals.PlayerAnimations.DASH_BEAM_KICK)
		Globals.SpellTypes.HEAL:
			PacketSender.trigger_player_animation(parent_entity, Globals.PlayerAnimations.SPIN)


func check_show_hold_down_tip() -> void:
	if _knows_how_to_hold_down == false && parent_entity.is_my_client && Globals.ui_interaction_mode == Globals.UIInteractionModes.GAMEPLAY:
		if _fireballs_cast == 1: 
			_times_cast_one_fireball += 1
			_fireballs_cast = 0 
		elif _fireballs_cast > 1:
			holdDownTip.tip_not_necessary()
			UserSettings.set_has_held_down_spell()
		
		if _times_cast_one_fireball >= 5:
			holdDownTip.show_tip(true)
			yield(get_tree().create_timer(12), "timeout")
			holdDownTip.tip_not_necessary()



# Show a helpful tip if a player is firing without a spell selected
func check_show_cast_tip(spell: int) -> void:
	if parent_entity.is_my_client && Globals.ui_interaction_mode == Globals.UIInteractionModes.GAMEPLAY:
		amount_of_clicks += 1
		if spell == Globals.SpellTypes.NONE && _knows_how_to_cast_spell == false:
			if amount_of_clicks == 3:
				elementTip.show_tip()
		else:
			elementTip.tip_not_necessary()
			UserSettings.set_has_cast_spell()


func deactivate_spell(spell_type: int = active_spell) -> void:
	var removed_child_entity: bool = false
	
	# Let the host know that we deactivated the spell and call this function in the host
	if Lobby.is_host == false:
		PacketSender.deactivate_spell(spell_type)
	
	# Only hold down spells should reset cooldown when we change spell or stop holding down cast button
	if holding_down_spell == true && Globals.SpellCooldowns[spell_type]["hold_down"] == true:
		reset_hold_down_spell_cooldown(spell_type)
		
		# Hold down spells are children of spellcasters and should be deleted once we stop holding down
		var spell_entity: Entity = get_child_spell(spell_type)
		if spell_entity != null:
			#print("[Despawn, Sending packet]: Removing hold down entity with id", parent_entity.get_id())
			PacketSender.host_broadcast_destroy_entity(spell_entity.get_id())
			removed_child_entity = true
	
		# We should spawn a wall on the ground if we are holding a wall
		if spell_type == Globals.SpellTypes.ARCANE_WALL:
			if _player_component != null:
				_player_component.remove_speed_modifier("wall")
		
		if spell_type == Globals.SpellTypes.ICE_BEAM && _player_component != null:
			_player_component.remove_speed_modifier("icebeamslowdebuff")
		
		if spell_type == Globals.SpellTypes.WILDFIRE && _player_component != null:
			_player_component.remove_speed_modifier("wildfire")
	
	# Set normal rotation speed
	if _player_component != null:
		_player_component.set_default_rotation_speed()


func allowed_to_cast_spell(spell: int) -> bool:
	return check_cooldown_of_spell_over(spell) == true && _immobilized == false && parent_entity.get_is_trapped() == false && Util.get_current_game_state() != GamemodeValues.GameStates.STARTING && Globals.ui_interaction_mode == Globals.UIInteractionModes.GAMEPLAY


func _get_cooldown_progress_of_spell(spell_type: int) -> float:
	return _spell_cooldowns[spell_type].cooldown_progress


func _get_max_cooldown_of_spell(spell_type: int) -> float:
	var max_cooldown: float = Globals.SpellCooldowns[spell_type].cooldown
	if _squishard_mode == true:
		max_cooldown = 0.3
	
	# If we haven't finished our charges the cooldown is always 0.4 seconds, unless specified in between_charge_cooldown
	if _get_max_charges(spell_type) > 1:
		if _spell_cooldowns[spell_type].charges > 0:
			if Globals.SpellCooldowns[spell_type].has("between_charge_cooldown"):
				max_cooldown = Globals.SpellCooldowns[spell_type]["between_charge_cooldown"]
			else:
				max_cooldown = 0.4
	
	return max_cooldown


func _get_charge_amount(spell_type: int) -> int:
	return _spell_cooldowns[spell_type].charges


func _get_max_charges(spell_type: int) -> int:
	return Globals.SpellCooldowns[spell_type].max_charges


func check_cooldown_of_spell_over(spell_type: int) -> bool:
	return _spell_cooldowns[spell_type].cooldown_progress <= 0 && _get_charge_amount(spell_type) > 0


func restart_cooldowns() -> void:
	_spell_cooldowns = _get_default_cooldowns()


func reset_hold_down_spell_cooldown(spell_type: int) -> void:
	reset_cooldown_of_spell(spell_type)
	holding_down_spell = false
	parent_entity.emit_signal("released_spell")


func reset_cooldown_of_spell(spell_type: int) -> void:
	# Only decrease charges for spells with charges
	if _get_max_charges(spell_type) > 1:
		_spell_cooldowns[spell_type].charges -= 1
	
	_spell_cooldowns[spell_type].cooldown_progress = _get_max_cooldown_of_spell(spell_type)
	_spell_cooldowns[spell_type].charge_regen_cooldown = Globals.SpellCooldowns[spell_type].cooldown
	
	if parent_entity.is_my_client:
		spellHUD.set_cooldown_values(_get_cooldown_progress_of_spell(active_spell), _get_max_cooldown_of_spell(active_spell), _get_charge_amount(active_spell), _get_max_charges(active_spell))


func _spawn_effect_environment(environment_type: int, pos: Vector3 = parent_entity.global_transform.origin, rot: float = 0):
	if Lobby.is_host:
		var env_info: Dictionary =  Globals.EnvironmentInfo(environment_type, rot, pos)
		PacketSender.spawn_environment(Util.generate_id(), env_info)


func clear_parented_spells():
	for id in _children_spell_ids:
		PacketSender.host_broadcast_destroy_entity(id)
	
	_children_spell_ids.clear()


func get_child_spell(spell_type: int) -> Entity:
	var room_node = Util.get_room_node()
	if room_node != null:
		for id in _children_spell_ids:
			var spell_entity: Entity = room_node.get_entity(id, "get_child_spell")
			if spell_entity != null:
				if spell_entity.get_type() == Globals.EntityTypes.SPELL && spell_entity.get_subtype() == spell_type:
					return spell_entity
	
	return null


func _on_child_spell_destroyed(entity_id: int) -> void:
	var child_index = _children_spell_ids.find(entity_id)
	if child_index != -1:
		_children_spell_ids.remove(child_index)
	
		var room_node = Util.get_room_node()
		if room_node != null:
			var spell_entity: Entity = room_node.get_entity(entity_id, "get_child_spell")
			if spell_entity != null:
				if spell_entity.get_creator_id() == parent_entity.get_id() && Globals.SpellCooldowns[spell_entity.get_subtype()]["hold_down"] == true:
					reset_hold_down_spell_cooldown(spell_entity.get_subtype())


func add_child_spell(entity) -> void:
	_children_spell_ids.append(entity.get_id())


func _on_DiveCastTimer_timeout():
	var between = _dive_pos - parent_entity.get_pos()
	_health_component.set_invincible(false)
	PacketSender.trigger_player_animation(parent_entity, Globals.PlayerAnimations.DIVE_UP)
	parent_entity.set_position(_dive_pos)
	PacketSender.update_entity_pos_directly(parent_entity.get_id(), _dive_pos)
	yield(get_tree(), "physics_frame")
	yield(get_tree(), "physics_frame")
	# If the dive was canceled by a push or grab dont create the second splash and stun
	if _dive_pos.distance_squared_to(parent_entity.get_pos()) < 2:
		var dir = Vector2(between.x, between.z).normalized()
		if _player_component != null:
			PacketSender.spawn_spell(parent_entity.get_id(), _player_component.get_team(), Util.generate_id(), Globals.SpellTypes.DIVE_STUN, _dive_pos, dir)
			_spawn_effect_environment(Globals.EnvironmentTypes.BIG_SPLASH, _dive_pos)


func _on_TransformDurationTimer_timeout():
	if Lobby.is_host && is_transformed == true:
		PacketSender.transform_into(parent_entity.get_id(), -1)


func _on_SpellCastTimer_timeout():
	casting_spell_w_cast_time = false
	try_request_cast_spell(Vector3.DOWN, "", cast_time_queued_spell)


func _on_OneElementOnlyTimer_timeout():
	if UserSettings.get_auto_clear_elements() == false:
		reset_elements(false)
		spellHUD.has_had_one_element_too_long()
