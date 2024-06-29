extends SpatialComponent
class_name Player
var COMPONENT_TYPE: int = Globals.ComponentTypes.Player


const DEFAULT_ROTATION_SPEED: float = PI * 5


export(Array, NodePath) var _renderers: Array
export(NodePath) var _fish_model: NodePath # The mesh
export(NodePath) var _fish_wizard_path: NodePath # The fish_wizard node


# Network variables
var steam_name: String = SteamValues.STEAM_USERNAME
var target_pos: Vector3 = Vector3.ZERO
var _username: String = ""
var _player_type: int
var _skin: Dictionary 
var _preferred_team: String
var _is_OP: bool
var _speed_modifiers: Array
var _default_speed: float = 1.0 
var _cloned_from_id: int
var _rank: int = -1
var _rotation_speed: float = PI # rad/s
var is_grabbed: bool
var click_to_move_pos: Vector3

var entity_info_panel: EntityInfoPanel
var _spell_caster: SpellCaster
var _player_bot # :PlayerBot

var _latest_attack_dir: Vector2
var _latest_angle: float
var _input_vector: Vector2
var _prev_req_movement: Vector2
var _stance: int = Globals.PlayerStances.FLOP_AROUND
var _next_spawn_pos: Vector3
var _frozen: bool = false
var _in_water: bool = false
var _death_type: int = Globals.PlayerDeathTypes.NORMAL
var _prev_freeze_level: float
var _footstep_timer: float
var _queue_end_rock_dash: bool = false
var _queue_dive_up: bool = false
var _dived_down: bool = false


onready var grabTimer: Timer = $GrabTimer
onready var _animation_tree: AnimationTree = $AnimationTree
onready var _animation_player: AnimationPlayer = $fish_wizard/AnimationPlayer
onready var _swimAnimator: AnimationPlayer = $SwimAnimator
onready var _respawnTimer: Timer = $RespawnTimer
onready var _fish_wizard: Spatial = $fish_wizard
onready var fireExplosion: Spatial = $FireExplosion
onready var freezeIndicator: Spatial = $FreezeIndicator
onready var OpModeTimer: Timer = $OpModeTimer
onready var damageSkinTimer: Timer = $DamageSkinTimer
onready var listener: Listener = $Listener
onready var footstepSound: AudioStreamPlayer3D = $FootstepSound
onready var moveToPosIndicator: CSGCylinder = $MoveToPosIndicator


func init_player(id: int, new_username: String, skin: Dictionary, preferred_team: String, cloned_from_id: int, player_type: int, rank: int = -1) -> void:
	_username = new_username
	_player_type = player_type
	_preferred_team = preferred_team
	_cloned_from_id = cloned_from_id
	_rank = rank
	set_player_skin(id, preferred_team, cloned_from_id, skin, player_type)


func get_cloned_from_id() -> int:
	return _cloned_from_id


func get_death_type() -> int:
	return _death_type


func get_is_frozen() -> bool:
	return _frozen


func get_in_water() -> bool:
	return _in_water


func _ready():
	_animation_tree.active = true
	parent_entity.connect("no_health", self, "_on_no_health")
	parent_entity.connect("took_damage", self, "_on_took_damage")
	parent_entity.connect("trigger_player_animation", self, "trigger_one_shot_animation")
	
	_spell_caster = parent_entity.get_component_of_type(Globals.ComponentTypes.SpellCaster)
	_player_bot = parent_entity.get_component_of_type(Globals.ComponentTypes.PlayerBot)
	
	set_default_rotation_speed()
	moveToPosIndicator.set_visible(false)
	
	if parent_entity.is_my_client == true:
		set_as_current_listener()
	
	if _cloned_from_id != -1:
		parent_entity.set_age_limit(5)
		_username = "[Clone] "+ _username
	
	entity_info_panel = parent_entity.get_component_of_type(Globals.ComponentTypes.EntityInfoPanel)
	if entity_info_panel != null:
		entity_info_panel.set_username(_username, get_team())
	
	# Avoid ugly spawn glitch
	if Lobby.player_is_in_temp_bot(parent_entity.get_id()):
		toggle_renderer(false)
		yield(get_tree().create_timer(0.2), "timeout")
		call_deferred("toggle_renderer", true)
	
	set_process(parent_entity.is_my_client)


# WARNING: process is only active for the current client
func _process(delta):
	# Move toward click_to_move_pos only if we hold down the mose
	if Input.is_mouse_button_pressed(BUTTON_RIGHT) && UserSettings.get_allow_click_to_move():
		click_to_move_pos = Util.get_aim_position(parent_entity.get_world().get_direct_space_state())
		click_to_move_pos.y = 0
		moveToPosIndicator.set_visible(true)
		moveToPosIndicator.global_transform.origin = click_to_move_pos
	elif moveToPosIndicator.visible == true:
		click_to_move_pos = Vector3.ZERO
		moveToPosIndicator.set_visible(false)


func _physics_process(delta: float) -> void:
	var my_input: Vector2 = Vector2(Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left"), Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up"))
	
	if my_input == Vector2.ZERO && click_to_move_pos != Vector3.ZERO && parent_entity.is_my_client:
		var my_pos: Vector3 = parent_entity.global_transform.origin
		if my_pos.distance_squared_to(click_to_move_pos) > 0.2:
			var dir: Vector3 = my_pos.direction_to(click_to_move_pos)
			my_input = Vector2(dir.x, dir.z)
		else:
			my_pos = Vector3.ZERO
			moveToPosIndicator.set_visible(false)
	elif my_input != Vector2.ZERO:
		click_to_move_pos = Vector3.ZERO
		moveToPosIndicator.set_visible(false)
	
	if parent_entity.is_my_client:
		if Globals.ui_interaction_mode == Globals.UIInteractionModes.GAMEPLAY:
			update_player_input(my_input)
		else:
			update_player_input(Vector2.ZERO)
	
	# Movement isn't controlled locally is the game is secure, 
	# you only receive your position from the host at a regular interval
	if (Lobby.SECURE_GAME == true && Lobby.is_host) || Lobby.SECURE_GAME == false:
		update_movement()
	
	update_rotation(delta, my_input)
	update_animations(delta)
	update_speed_modifiers(delta)


func get_player_type() -> int:
	return _player_type


func get_is_clone() -> bool:
	return _cloned_from_id != -1


func get_cloned_from() -> int:
	return _cloned_from_id


func get_rank() -> int:
	return _rank


func get_is_OP() -> bool:
	return _is_OP


func get_username() -> String:
	return _username


func get_next_spawn_pos() -> Vector3:
	return _next_spawn_pos


func get_skin() -> Dictionary:
	return _skin


# The player's preferred team is the team that they join if the gamemode has teams
func get_preferred_team() -> String:
	return _preferred_team


# This function actually gets which team a player is in
func get_team() -> String:
	if _cloned_from_id != -1:
		var team_info = Lobby.get_team_info_from_player_id(_cloned_from_id)
		if team_info.has("name") == true:
			return team_info["name"]
	
	var team_info = Lobby.get_team_info_from_player_id(parent_entity.get_id())
	if team_info.has("name") == true:
		# Return red team if entity is a protect fish god temp bot
		if team_info["name"] == "Wizishes" && team_info["solo"] == false:
			return "Red Team"
		
		return team_info["name"]
	else:
		return "Red Team"


func set_as_current_listener() -> void:
	listener.make_current()


func set_death_type(value: int) -> void:
	_death_type = value


func set_default_speed(val: float) -> void:
	_default_speed = val


func set_slowed_rotation(rad_per_sec: float) -> void:
	_rotation_speed = rad_per_sec


func set_default_rotation_speed() -> void:
	_rotation_speed = DEFAULT_ROTATION_SPEED


func set_speed_modifier(id: String, modifier: float, duration: float = -1) -> void:
	# If duration is -1 it is infinite until removed
	_speed_modifiers.append({"id": id, "modifier": modifier, "duration": duration, "time": 0})
	update_freeze_indicator()


func get_combined_speed_mod() -> float:
	var total: float = 1.0
	for speed_modifier_obj in _speed_modifiers:
		total += speed_modifier_obj["modifier"]
	
	return clamp(total, 0.2, 5)


func remove_speed_modifier(modifier_id: String)  -> void:
	for i in range(0, _speed_modifiers.size()):
		if _speed_modifiers[i]["id"] == modifier_id:
			_speed_modifiers.remove(i)
			update_freeze_indicator()
			return
	# READD
	#printerr("Couldn't find a modifier to remove")


func update_speed_modifiers(delta: float) -> void:
	for i in range(0, _speed_modifiers.size()):
		var speed_modifier = _speed_modifiers[i]
		speed_modifier["time"] += delta
		if speed_modifier["time"] > speed_modifier["duration"] && speed_modifier["duration"] != -1:
			_speed_modifiers.remove(i)
			return # If there is another one that is over remove it next process
	
	update_freeze_indicator()


func update_freeze_indicator() -> void:
	if Lobby.is_host:
		var freeze_level: float = 0.0
		for speed_mod_obj in _speed_modifiers:
			if speed_mod_obj["id"] == "freezearea" || speed_mod_obj["id"] == "icebeam":
				freeze_level += speed_mod_obj["modifier"]
		
		if freeze_level != _prev_freeze_level:
			_prev_freeze_level = freeze_level
			PacketSender.broadcast_freeze_info(parent_entity.get_id(), freeze_level, _frozen)


func update_footstep_sound(delta:float, move_speed: float) ->void:
	_footstep_timer += delta
	if get_combined_speed_mod() != 0 && move_speed != 0 && !_in_water:
		if _footstep_timer > (0.354 / get_combined_speed_mod()):
			footstepSound.play()
			_footstep_timer = 0


func p2p_set_freeze_info(freeze_level: float, ice_cubed: bool) -> void:
	if ice_cubed == true:
		freezeIndicator.set_ice_cube(true)
		_animation_tree.set("parameters/full_body_override_blend/rock_dash_state_machine/conditions/disengage", true)
		_animation_tree.set("parameters/full_body_override_blend/frozen_state_machine/conditions/unfreeze", false)
		_animation_tree.set("parameters/full_body_override_blend/frozen/active", true)
		full_body_override()
		
		if _spell_caster != null:
			_spell_caster.deactivate_spell()
		
		_frozen = true
		if _dived_down:
			_queue_dive_up = true
			trigger_one_shot_animation(Globals.PlayerAnimations.DIVE_UP, Vector2.ZERO)
	else:
		freezeIndicator.set_ice_cube(false)
		_frozen = false
		_animation_tree.set("parameters/full_body_override_blend/frozen_state_machine/conditions/unfreeze", true)
	
	freezeIndicator.set_freeze_level(freeze_level)


func p2p_set_is_OP(time: float, spellcaster_only: bool, change_speed: bool = true) -> void:
	var health_component = parent_entity.get_component_of_type(Globals.ComponentTypes.Health)
	_spell_caster.set_squishard_mode(true)
	if spellcaster_only == false:
		_is_OP = true
		parent_entity.emit_signal("trigger_particle_effect", Globals.ParticleEffects.BURNING, true, 0);
		if parent_entity.scale == Vector3.ONE:
			parent_entity.scale = Vector3.ONE * 1.3
		if change_speed == true:
			set_speed_modifier("op", 1.5, time)
		
		health_component.host_reset_health()
	
	OpModeTimer.start(time - 0.1)


func _on_op_mode_timer_timeout() -> void:
	var health_component = parent_entity.get_component_of_type(Globals.ComponentTypes.Health)
	parent_entity.emit_signal("trigger_particle_effect", Globals.ParticleEffects.BURNING, false, 0);
	if health_component != null:
		_spell_caster.set_squishard_mode(false)
		_animation_player.stop()
		parent_entity.scale = Vector3.ONE
		_is_OP = false
		health_component.max_health = health_component.max_health
		health_component.host_reset_health()


func set_input(_input: Vector2) -> void:
	_input_vector.x = _input.x
	_input_vector.y = _input.y
	_input_vector = _input_vector.normalized()


func set_stance(stance: int) -> void:
	_stance = stance
	
	if _spell_caster.is_transformed == false:
		set_default_speed(Globals.FLOP_AROUND_SPEED if stance == Globals.PlayerStances.FLOP_AROUND else Globals.AIM_SPEED)
	
	if _frozen == false:
		change_animation_stance(stance)


func set_player_skin(id: int, team_name: String, cloned_from_id: int, skin: Dictionary, player_type: int) -> void:
	if cloned_from_id != -1:
		var room = Util.get_room_node()
		if room != null:
			var cloned_from = room.get_entity(cloned_from_id)
			if cloned_from != null:
				var player_component: Player = cloned_from.get_component_of_type(Globals.ComponentTypes.Player)
				if player_component != null:
					_skin = CustomizePlayer.apply_skin_to_fishard(get_parent(), player_component.get_skin(), get_node(_fish_model), player_component.get_team())
	else:
		if GamemodeValues.get_current_rounds_teammode() == GamemodeValues.TeamModes.NO_TEAMS:
			_skin = CustomizePlayer.apply_skin_to_fishard(get_parent(), skin, get_node(_fish_model))
		elif GamemodeValues.get_current_rounds_teammode() == GamemodeValues.TeamModes.RED_BLUE_TEAMS:
			_skin = CustomizePlayer.apply_skin_to_fishard(get_parent(), skin, get_node(_fish_model), team_name)
		elif GamemodeValues.get_current_rounds_teammode() == GamemodeValues.TeamModes.COOP:
			var team_info: Dictionary = Lobby.get_team_info_from_player_id(id)
			if player_type == Globals.PlayerTypes.CLIENT:
				team_name = "Blue Team"
			elif team_info.empty() == false:
				team_name = "Red Team" if team_name == "Wizishes" && team_info["solo"] == false else "Blue Team"
			else:
				team_name = "Red Team"
			_skin = CustomizePlayer.apply_skin_to_fishard(get_parent(), skin, get_node(_fish_model), team_name)
	
	if skin.has("hat"):
		_fish_wizard = get_node(_fish_wizard_path)
		_fish_wizard.show_hat(skin["hat"], true)


func kill_player(respawn_time: float) -> void:
	# Bots automatically respawn, players must request via respawn button
	if respawn_time != -1 && Lobby.is_host && parent_entity.get_subtype() != Globals.PlayerTypes.CLIENT:
		_respawnTimer.start(respawn_time)
		
		if Util.player_is_boss(parent_entity.get_subtype()) == true:
			for i in range(-1, 2):
				var pos = parent_entity.get_pos() + Vector3.LEFT * i
				var power_up_info: Dictionary = Globals.EnvironmentInfo(Globals.EnvironmentTypes.HEALTH_POWERUP, 0, pos)
				var id: int = Util.generate_id(Globals.EntityTypes.ENVIRONMENT, Globals.EnvironmentTypes.HEALTH_POWERUP)
				PacketSender.spawn_environment(id, power_up_info)
	
	var death_sound = $DeathSound
	if death_sound != null:
		death_sound.play()
	
	toggle_collider(false)
	toggle_renderer(false)
	
	if _spell_caster != null:
		_spell_caster.clear_parented_spells()
	
	# Remove snowpile and ice on death
	_speed_modifiers.clear()
	_frozen = false
	update_freeze_indicator()
	
	entity_info_panel.hide_panel()
	
	if _player_bot != null:
		_player_bot.kill_bot()
	
	if _fish_wizard != null:
		_fish_wizard.hide_all_hats()
	
	# Due to async respawn calls in beginning of round, only untrap when respawning ingame
	if Util.get_current_game_state() != GamemodeValues.GameStates.STARTING:
		parent_entity.untrap()
	
	if Util.safe_to_use(parent_entity) == true:
		parent_entity.broadcast_transform = false
		parent_entity.set_process(false)
		parent_entity.set_physics_process(false)
	
	set_physics_process(false)
	_spell_caster.set_process(false)


func respawn() -> void:
	if _fish_wizard != null:
		var skin = get_skin()
		if skin.has("hat"):
			_fish_wizard.show_hat(skin["hat"])
	
	set_physics_process(true)
	_spell_caster.set_process(true)
	parent_entity.set_process(true)
	parent_entity.set_physics_process(true)
	
	_speed_modifiers.clear()
	_frozen = false
	update_freeze_indicator()
	freezeIndicator.set_ice_cube(false)
	parent_entity.untrap()
	click_to_move_pos = Vector3.ZERO
	
	_spell_caster.restart_cooldowns()
	_spell_caster.update_stance(Globals.PlayerStances.FLOP_AROUND)
	parent_entity.get_component_of_type(Globals.ComponentTypes.Health).host_reset_health()
	
	# Once we respawn always make sure the camera is following us
	if parent_entity.is_my_client == true:
		Globals.set_camera_following(parent_entity)
	
	parent_entity.broadcast_transform = true 
	
	var health_component = parent_entity.get_component_of_type(Globals.ComponentTypes.Health)
	if health_component != null:
		health_component.reset_recent_damager()
	
	Lobby.emit_signal("player_respawn", parent_entity.get_id())
	
	# Wait a bit until we show play again for visual reasons
	var tree = get_tree()
	if tree != null:
		yield(tree.create_timer(0.15), "timeout")
		if is_inside_tree() == true:
			if _player_bot != null:
				_player_bot.respawn_bot()
			_animation_player.play("DiveUp")
	
	if tree != null:
		yield(tree, "idle_frame")
		if is_inside_tree() == true:
			toggle_collider(true)
			toggle_renderer(true) 
	
	if tree != null:
		yield(tree.create_timer(0.2), "timeout")
		if is_inside_tree() == true:
			entity_info_panel.show_panel()


func update_animations(delta: float) -> void:
	if _frozen == false:
		# If we are the host just use the positions we have, otherwise we must get target pos and prev target pos
		var move_dir_vec3: Vector3 = parent_entity.get_move_dir_v3() if Lobby.is_host else parent_entity.get_target_pos_move_dir()
		var move_direction: Vector2 = Vector2(move_dir_vec3.x, move_dir_vec3.z)
		
		var rotation: float = parent_entity.get_rot()
		var rot_direction: Vector2 = Vector2(sin(rotation), cos(rotation))
		
		var angle_between_rot_and_dir: float = move_direction.angle_to(rot_direction)
		var run_animation_vector: Vector2 = Vector2(sin(angle_between_rot_and_dir), cos(angle_between_rot_and_dir))
		
		var move_speed: float = move_direction.length() / delta
		update_footstep_sound(delta, move_speed)
		
		var blend = (clamp(move_speed/4, 0, 1) * -1) + 1.2
		_animation_tree.set("parameters/move_blend/blend_amount", blend)
		_animation_tree.set("parameters/run/blend_position", run_animation_vector)
		_animation_tree.set("parameters/full_body_override_blend/pushed_states/pushed_blend/blend_position", vec2_to_blend_area_2d_dir(_latest_attack_dir))
		_animation_tree.set("parameters/upper_body_override_blend/push_blend/blend_position", vec2_to_blend_area_2d_dir(_latest_attack_dir))
		_animation_tree.set("parameters/upper_body_override_blend/hurt_blend/blend_position", vec2_to_blend_area_2d_dir(_latest_attack_dir))
	
	if _queue_dive_up:
		if !_frozen:
			trigger_one_shot_animation(Globals.PlayerAnimations.DIVE_UP, Vector2.ZERO)
			_queue_dive_up = false
	
	if _queue_end_rock_dash:
		if !_frozen:
			trigger_one_shot_animation(Globals.PlayerAnimations.END_ROCK_DASH, Vector2.ZERO)
			_queue_end_rock_dash = false


func change_animation_stance(stance: int) -> void:
	match stance:
		Globals.PlayerStances.FLOP_AROUND:
			_animation_tree.set("parameters/upper_body_blend/blend_amount", 0)
		Globals.PlayerStances.AIM:
			_animation_tree.set("parameters/upper_body_blend/blend_amount", 1)
			_animation_tree.set("parameters/stance_tree/stance_blend/blend_amount", 0)
		Globals.PlayerStances.BOMBARD:
			_animation_tree.set("parameters/upper_body_blend/blend_amount", 1)
			_animation_tree.set("parameters/stance_tree/stance_blend/blend_amount", 1)


func trigger_shoot_animation(spell_type: int) -> void:
	match _stance:
		Globals.PlayerStances.BOMBARD:
			_animation_tree.set("parameters/stance_tree/bombard_shoot/active", true)
			
		Globals.PlayerStances.AIM:
			_animation_tree.set("parameters/stance_tree/aim_shoot/active", true)
	match spell_type:
		Globals.SpellTypes.METEOR:
			parent_entity.emit_signal("trigger_particle_effect", Globals.ParticleEffects.METEOR_MUZZLE, true, 0)


func trigger_one_shot_animation(animation_nr: int, dir: Vector2) -> void:
	_latest_attack_dir = dir
	if _frozen == false:
		dir = vec2_to_blend_area_2d_dir(dir)
		match animation_nr:
			Globals.PlayerAnimations.HURT:
				_animation_tree.set("parameters/upper_body_override/active", true)
				if get_skin().empty() == false && Util.safe_to_use(self) == true:
					CustomizePlayer.apply_damage_skin(parent_entity, get_skin(), get_node(_fish_model))
					damageSkinTimer.start()
			Globals.PlayerAnimations.PUSHED:
				_animation_tree.set("parameters/upper_body_override_blend/push/active", true)
				upper_body_override()
			Globals.PlayerAnimations.LAUNCHED:
				_animation_tree.set("parameters/upper_body_override_blend/push/active", true)
				upper_body_override()
			Globals.PlayerAnimations.LAUNCHED_RECOVER:
				pass
				#_animation_tree.set("parameters/full_body_override_blend/pushed_states/conditions/recover", true)
				#_animation_tree.set("parameters/full_body_override_blend/pushed/active", true)
				#full_body_override()
			Globals.PlayerAnimations.START_ROCK_DASH:
				var dash_sound = $DashSound
				if dash_sound != null:
					dash_sound.play()
				_animation_tree.set("parameters/full_body_override_blend/rock_dash_state_machine/conditions/disengage", false)
				_animation_tree.set("parameters/full_body_override_blend/rock_dash/active", true)
				full_body_override()
			Globals.PlayerAnimations.END_ROCK_DASH:
				if !_frozen:
					_animation_tree.set("parameters/full_body_override_blend/rock_dash_state_machine/conditions/disengage", true)
				else:
					_queue_end_rock_dash = true
			Globals.PlayerAnimations.DIVE_DOWN:
				_dived_down = true
				_animation_tree.set("parameters/full_body_override_blend/dive_state_machine/conditions/up", false)
				_animation_tree.set("parameters/full_body_override_blend/dive_state_machine/conditions/dive_again", true)
				_animation_tree.set("parameters/full_body_override_blend/dive/active", true)
				full_body_override()
			Globals.PlayerAnimations.DIVE_UP:
				if !_frozen:
					_dived_down = false
					_animation_tree.set("parameters/full_body_override_blend/dive_state_machine/conditions/dive_again", false)
					_animation_tree.set("parameters/full_body_override_blend/dive_state_machine/conditions/up", true)
				else:
					_queue_dive_up = true
			Globals.PlayerAnimations.DASH_BEAM_KICK:
				_animation_tree.set("parameters/full_body_override_blend/dash_beam/active", true)
				full_body_override()
			Globals.PlayerAnimations.SPIN:
				_animation_tree.set("parameters/full_body_override_blend/spin/active", true)
				full_body_override()
			Globals.PlayerAnimations.ENTER_WATER:
				if !_in_water:
					_swimAnimator.play("enter_water")
					if GamemodeValues.current_map_type == GamemodeValues.Maps.Lava:
						parent_entity.emit_signal("trigger_particle_effect", Globals.ParticleEffects.LAVA_SPLASH, true, 0)
					else:
						parent_entity.emit_signal("trigger_particle_effect", Globals.ParticleEffects.WATER_SPLASH, true, 0)
					_in_water = true
					set_death_type(Globals.PlayerDeathTypes.DROWN)
			Globals.PlayerAnimations.EXIT_WATER:
				if _in_water:
					_swimAnimator.play("exit_water")
					_in_water = false
					set_death_type(Globals.PlayerDeathTypes.NORMAL)
			Globals.PlayerAnimations.START_FLOP:
				_animation_tree.set("parameters/full_body_override_blend/flop/active", true)
				full_body_override()
			Globals.PlayerAnimations.DANCE_1:
				_animation_tree.set("parameters/full_body_override_blend/dance/active", true)
				full_body_override()
			Globals.PlayerAnimations.FLOP_ONCE:
				_animation_tree.set("parameters/full_body_override_blend/flop_once/active", true)
				full_body_override()
			Globals.PlayerAnimations.BACKFLIP:
				_animation_tree.set("parameters/full_body_override_blend/backflip/active", true)
				full_body_override()

func full_body_override():
	_animation_tree.set("parameters/full_body_override/active", true)


func upper_body_override():
	_animation_tree.set("parameters/upper_body_override/active", true)


func update_player_input(req_movement: Vector2) -> void:
	# If a game is secure all movement is to be checked by the host
	if Lobby.SECURE_GAME == true:
		if req_movement != _prev_req_movement:
			_prev_req_movement = req_movement
			PacketSender.request_update_player_input(parent_entity.get_id(), req_movement)
	else:
		_input_vector = req_movement


func update_rotation(delta: float, my_input: Vector2) -> void:
	if parent_entity.is_my_client && _player_type == Globals.PlayerTypes.CLIENT || Lobby.is_host && _player_type != Globals.PlayerTypes.CLIENT:
		if _stance == Globals.PlayerStances.FLOP_AROUND:
			# Since the host updates positions directly it cant get the target pos to define the movement
			var move_dir: Vector2 = parent_entity.get_move_dir_v2() if Lobby.is_host else my_input
			if move_dir != Vector2.ZERO && parent_entity.get_is_trapped() == false:
				parent_entity.set_target_rotation(move_dir.angle_to(Vector2.DOWN), 10) 
		elif _stance == Globals.PlayerStances.AIM || _stance == Globals.PlayerStances.BOMBARD:
			if parent_entity.is_my_client == true && _player_type == Globals.PlayerTypes.CLIENT && get_is_frozen() == false:
				var aim_pos = Util.get_aim_position(parent_entity.get_world().get_direct_space_state())
				var cast_direction3d = _spell_caster.get_spell_spawn_pos().direction_to(aim_pos)
				var target_angle: float = Vector2(cast_direction3d.x, cast_direction3d.z).angle_to(Vector2.DOWN)
				# Controller rotation
				if Util.controller_connected:
					var dir: Vector2
					dir.x = Input.get_action_strength("joy_right_right") - Input.get_action_strength("joy_right_left")
					dir.y = Input.get_action_strength("joy_right_down") - Input.get_action_strength("joy_right_up")
					if dir != Vector2.ZERO:
						target_angle = Util.vector_2_to_y_rot(dir)
						_latest_angle = target_angle
					else:
						target_angle = _latest_angle
				
				if _rotation_speed == DEFAULT_ROTATION_SPEED:
					parent_entity.set_rot(lerp_angle(parent_entity.get_global_rot(), target_angle, _rotation_speed * delta))
				else:
					var aim_vector = Vector2(cast_direction3d.x, cast_direction3d.z).normalized()
					var player_rotation_vector = Util.y_rot_to_vector_2(parent_entity.get_rot()).normalized()
					var mod = 0.4 if aim_vector.distance_squared_to(player_rotation_vector) < 0.16 else 1 # It's to fast whilst dragging the mouse short distances otherwise
					var new_player_rotation = player_rotation_vector.move_toward(aim_vector, _rotation_speed * delta * mod).angle_to(Vector2.DOWN)
					parent_entity.set_rot(new_player_rotation)
		
		PacketSender.update_player_rotation(SteamValues.STEAM_ID, parent_entity.get_id(), parent_entity.get_rot())


func toggle_collider(value: bool):
	if Util.safe_to_use(parent_entity):
		if Util.safe_to_use(parent_entity.get_area()):
			parent_entity.get_area().monitorable = value 
			parent_entity.get_area().monitoring = value 
			
			if parent_entity.get_component_of_type(Globals.ComponentTypes.Kinematic) != null:
				parent_entity.get_component_of_type(Globals.ComponentTypes.Kinematic).disable_collision(!value)
			
			# Hack to avoid collision with dead player
			parent_entity.get_area().transform.origin = int(!value) * Vector3.DOWN * 10
	else:
		printerr("Couldn't toggle collider")


func toggle_renderer(value: bool):
	if _renderers:
		for renderer in _renderers:
			get_node(renderer).visible = value
	else:
		printerr("Invalid node path for the renderer, assign one!")


func update_movement() -> void:
	var speed = Globals.PLAYER_SPEED * get_combined_speed_mod() * _default_speed
	var move_vector: Vector3 = Vector3(_input_vector.x * speed, 0, _input_vector.y * speed)
	parent_entity.add_direction(move_vector)


func vec2_to_blend_area_2d_dir(vec2: Vector2) -> Vector2:
	var parent_rot: float = parent_entity.rotation.y
	var dir_angle: float = parent_rot - Util.vector_2_to_y_rot(vec2)
	return Util.y_rot_to_vector_2(dir_angle)


func _on_no_health() -> void:
	# Only the host broadcasts a player's death so all players are synced
	if Lobby.is_host:
		var health_component = parent_entity.get_component_of_type(Globals.ComponentTypes.Health)
		if !health_component.get_invincible():
			var killer_id: int = health_component.get_recent_damager_id()
			var killer_spell_type: int = health_component.get_recent_damager_spell()
			
			PacketSender.broadcast_player_death(parent_entity.get_id(), killer_id, killer_spell_type, _death_type)


func _on_took_damage(damage: int, damager: Entity) -> void:
	var health_component = parent_entity.get_component_of_type(Globals.ComponentTypes.Health)
	if health_component != null:
		if health_component.get_invincible() == false:
			var hurt_sound = $HurtSound
			if hurt_sound != null:
				hurt_sound.set_pitch_scale(1 + Util.rand.randf_range(-0.1, 0.1))
				hurt_sound.play()
			
			var damager_dir: Vector2 = Util.y_rot_to_vector_2(damager.rotation.y)
			trigger_one_shot_animation(Globals.PlayerAnimations.HURT, damager_dir)


func _on_RespawnTimer_timeout():
	var room_node = Util.get_room_node()
	if room_node != null:
		room_node.host_respawn_player(parent_entity.get_id(), parent_entity)


func _on_DamageSkinTimer_timeout():
	if Util.safe_to_use(self) == true:
		CustomizePlayer.apply_skin_to_fishard(parent_entity, _skin, get_node(_fish_model))


func fancy_pants() -> void:
	CustomizePlayer.fancy_pants(get_node(_fish_model))


func set_is_grabbed(val: bool, grab_time_left: float) -> void:
	is_grabbed = val
	# Insure that is_grabbed is reset
	grabTimer.start(grab_time_left + 0.5)


func _on_GrabTimer_timeout():
	is_grabbed = false
