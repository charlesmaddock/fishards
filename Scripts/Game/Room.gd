extends Spatial
class_name Room


onready var client: Node = $Client
onready var players: Players = $Players
onready var environment: Node = $Environment
onready var spells: Node = $Spells
onready var gamemode: Node = $Gamemode
onready var entities: Node = $Entities
onready var destroyed_entities: Node = $DestroyedEntities
onready var post_process_texture: ColorRect = $CanvasLayer/PostProcess
onready var post_process_animator: AnimationPlayer = $CanvasLayer/PostProcessAnimations


onready var respawnAllBugFixTimer: Timer = $RespawnAllBugFixTimer
var _respawn_dead_only: bool
var entities_dict: Dictionary = {}


func _ready():
	PacketHandler.connect("handle_room_packet", self, "_on_handle_room_packet")


func _on_handle_room_packet(sender_id: int, data: Dictionary):
	match data["type"]:
		Globals.PacketTypes.CHANGE_GAME_STATE:
			handle_change_game_state(sender_id, data["state"], data["time_until_next"])
		Globals.PacketTypes.BROADCAST_GAMEOVER_PANEL:
			handle_broadcast_gameover_panel(sender_id, data["winner_ids"], data["text"], data["winner_title"], data["loser_title"])
		Globals.PacketTypes.SET_GAMEMODE_DATA:
			set_gamemode_data(sender_id, data["data"])
		Globals.PacketTypes.COUNTDOWN:
			set_countdown(sender_id, data["time"])
		Globals.PacketTypes.WINNER_DISPLAY:
			show_winner_display(sender_id)
		Globals.PacketTypes.UPDATE_ENTITY_POS:
			update_entity_pos(sender_id, data["id"], data["pos"])
		Globals.PacketTypes.UPDATE_PLAYER_TARGET_POS:
			update_player_target_pos(sender_id, data["id"], data["pos"])
		Globals.PacketTypes.UPDATE_PLAYER_ROTATION:
			update_player_rot(sender_id, data["id"], data["rot"])
		Globals.PacketTypes.UPDATE_PLAYER_STANCE:
			update_player_stance(sender_id, data["id"], data["stance"])
		Globals.PacketTypes.TRIGGER_PLAYER_ANIMATION:
			trigger_player_animation(data["id"], data["animation_nr"], data["dir"])
		Globals.PacketTypes.UPDATE_ENTITY_TRANSFORM:
			update_entity_transform(sender_id, data["id"], data["pos"], data["rot"])
		Globals.PacketTypes.UPDATE_HEALTH:
			update_health(data ["id"], data["health"])
		Globals.PacketTypes.UPDATE_MAX_HEALTH:
			update_max_health(data["id"], data["health"])
		Globals.PacketTypes.TRANSFORM_INTO:
			update_transformed_into(sender_id, data["id"], data["into"], data["speed_modifier"], data["duration"])
		Globals.PacketTypes.REQUEST_RESPAWN_PLAYER:
			handle_request_respawn(sender_id)
		Globals.PacketTypes.PLAYER_DEATH:
			handle_player_death(sender_id, data["id"], data["killer_id"], data["death_type"], data["spell"])
		Globals.PacketTypes.RESPAWN_PLAYER:
			handle_player_respawned(sender_id, data["id"])
		Globals.PacketTypes.SET_SCORE:
			set_score(sender_id, data["id"], data["score"], data["to_team"])
		Globals.PacketTypes.SET_LEADERBOARD:
			set_leaderboard(sender_id, data["board"])
		Globals.PacketTypes.START_SHRINK:
			start_shrink(sender_id)
		Globals.PacketTypes.SET_IS_OP:
			set_is_OP(sender_id, data["id"], data["time"], data["spell"])
		Globals.PacketTypes.SET_IS_LOSER:
			set_is_loser(sender_id, data["id"])
		Globals.PacketTypes.DESTROY_ENTITY:
			p2p_handle_despawn_entity(data["id"], data["old"])
		Globals.PacketTypes.SPAWN_SPELL:
			spawn_spell(sender_id, data["player_id"], data["team"], data["spell_id"], data["spell_type"], data["pos"], data["dir"])
		Globals.PacketTypes.LAUNCH:
			launch(data["id"], data["etype"], data["from"], data["to"], data["spd"])
		Globals.PacketTypes.REFLECT_SPELL:
			reflect_spell(sender_id, data["id"], data["spell_id"], data["pos"], data["dir"])
		Globals.PacketTypes.SPAWN_PLAYER:
			p2p_spawn_player(sender_id, data["id"], data["player"])
		Globals.PacketTypes.SPAWN_ENVIRONMENT:
			spawn_environment(sender_id, data["env_id"], data["env_info"], data["parent"])
		Globals.PacketTypes.TRIGGER_PARTICLE_EFFECT:
			trigger_particle_effect(data["id"], data["entity_type"], data["effect_nr"], data["emitting"])
		Globals.PacketTypes.BROADCAST_FREEZE_INFO:
			handle_broadcast_freeze_info(sender_id, data["id"], data["lvl"], data["ice"])
		Globals.PacketTypes.REQUEST_UPDATE_PLAYER_MOVEMENT:
			validate_update_player_movement(data["id"], data["input"])
		Globals.PacketTypes.DEACTIVATE_SPELL:
			deactivate_spell(sender_id, data["spell"])
		Globals.PacketTypes.REQUEST_CAST_DIRECTIONAL_SPELL:
			validate_cast_directional_spell(sender_id, data["player_id"], data["spell_type"], data["dir"])
		Globals.PacketTypes.REQUEST_CAST_POSITIONAL_SPELL:
			validate_cast_positional_spell(sender_id, data["player_id"], data["spell_type"], data["pos"])
		Globals.PacketTypes.REQUEST_ROCK_DASH:
			validate_rock_dash(sender_id, data["id"], data["dir"])
		Globals.PacketTypes.REQUEST_CAST_TRANSFORM_INTO:
			validate_transform_into(sender_id, data["id"], data["into"], data["speed_modifier"], data["duration"])
		Globals.PacketTypes.REQUEST_DEACTIVATE_ARCANE_WALL:
			validate_deactivate_arcane_wall(sender_id, data["id"], data["spawn_wall"])
		Globals.PacketTypes.ELEMENTS_CHANGED:
			handle_elements_changed(sender_id)
		Globals.PacketTypes.NEW_WAVE:
			handle_new_wave(sender_id, data["wave"])
			


func handle_change_game_state(sender_id: int, state: int, time_until_next: float) -> void:
	if sender_id == Lobby.host_id:
		gamemode.p2p_change_game_state(state, time_until_next)


func handle_broadcast_gameover_panel(sender_id: int, winner_ids: Array, text: String, winner_title: String, loser_title: String) -> void:
	if sender_id == Lobby.host_id && gamemode != null:
		gamemode.p2p_handle_broadcast_gameover_panel(winner_ids, text, winner_title, loser_title)


func show_winner_display(sender_id: int) -> void:
	if sender_id == Lobby.host_id:
		gamemode.p2p_show_winners_display()


func set_gamemode_data(sender_id: int, data: Dictionary) -> void:
	if sender_id == Lobby.host_id:
		gamemode.p2p_set_gamemode_data(data)


func set_countdown(sender_id: int, count_down_time: int) -> void:
	if sender_id == Lobby.host_id:
		gamemode.p2p_set_countdown(count_down_time)

func update_entity_pos(sender_id: int, id: int, pos: Vector3) -> void:
	var entity: Entity = get_entity(id, "update_entity_pos")
	if entity != null && sender_id == Lobby.host_id:
		entity.set_position_directly(pos)


func update_player_target_pos(sender_id: int, id: int, pos: Vector3) -> void:
	var entity: Entity = get_entity(id, "update_player_target_pos")
	if entity != null && sender_id == Lobby.host_id:
		entity.set_target_position(pos)


func update_player_rot(sender_id: int, player_id: int, new_rot: float) -> void:
	var entity: Entity = get_entity(player_id, "update_player_rot")
	if entity != null && (player_id == sender_id || sender_id == Lobby.host_id):
		entity.set_target_rotation(new_rot, 10)


func update_player_stance(sender_id: int, player_id: int, new_stance: int) -> void:
	if sender_id == player_id || sender_id == Lobby.host_id:
		var player_component: Player = players.get_player_component(player_id, "update_player_stance")
		if player_component != null:
			player_component.set_stance(new_stance)


func trigger_player_animation(player_id: int, animation_nr: int, dir: Vector2):
	var player_component: Player = players.get_player_component(player_id, "trigger_player_animation")
	if player_component != null:
		player_component.trigger_one_shot_animation(animation_nr, dir)


func update_entity_transform(sender_id: int, id: int, pos: Vector3, rot: float) -> void:
	var entity: Entity = get_entity(id)
	if entity != null && sender_id == Lobby.host_id:
		entity.set_target_position(pos)
		entity.set_target_rotation(rot)


func update_health(entity_id: int, health: int) -> void:
	var entity: Entity = get_entity(entity_id, "update_health")
	if entity != null:
		if entity.get_component_of_type(Globals.ComponentTypes.Health):
			entity.get_component_of_type(Globals.ComponentTypes.Health).p2p_set_health(health)
		else:
			printerr("Tried to update health of an entity without a health component")


func update_max_health(entity_id: int, health: int) -> void:
	var entity: Entity = get_entity(entity_id, "update max health")
	if entity != null:
		if entity.get_component_of_type(Globals.ComponentTypes.Health):
			entity.get_component_of_type(Globals.ComponentTypes.Health).p2p_update_max_health(health)
		else:
			printerr("Tried to update health of an entity without a health component")


func update_transformed_into(sender_id: int, id: int, transform_into: int, speed_modifier: float, duration: float) -> void:
	var entity: Entity = get_entity(id)
	if entity != null && sender_id == Lobby.host_id:
		# Todo: Check cooldown
		entity.get_component_of_type(Globals.ComponentTypes.SpellCaster).transform_into(transform_into, speed_modifier, duration)


func handle_player_death(sender_id: int, dead_player_id: int, killer_id: int, death_type: int, killed_with_spell: int):
	if sender_id == Lobby.host_id:
		players.p2p_handle_player_death(dead_player_id, gamemode.get_respawn_time(), death_type)
		gamemode.p2p_handle_player_death(dead_player_id, killer_id)
		Lobby.emit_signal("player_killed", dead_player_id, killer_id, killed_with_spell)


func handle_request_respawn(sender_id: int) -> void:
	var player_entity: Entity = get_entity(sender_id, "request respawn")
	host_respawn_player(sender_id, player_entity)


func handle_player_respawned(sender_id: int, player_id: int) -> void:
	if sender_id == Lobby.host_id:
		players.p2p_respawn_player(player_id)
		gamemode.p2p_handle_player_respawn(player_id)


func host_respawn_player(player_id: int, player_entity: Entity) -> void:
	var player_component: Player = players.get_player_component(player_id, "respawn player")
	if Lobby.is_host && player_component != null:
		if player_component.get_is_clone() == true:
			return
		
		var spawn_point: Vector3 = environment.map.get_player_spawn_point(player_component.get_team())
		host_reset_player_values(player_entity, spawn_point)
		PacketSender.update_entity_pos_directly(player_id, spawn_point)
		PacketSender.respawn_player(player_id)


func host_respawn_all_players(respawn_dead_only: bool = false) -> void:
	_respawn_dead_only = respawn_dead_only
	# TODO: Not the best solution but it fixes a bug where player hasn't died in time 
	respawnAllBugFixTimer.start(0.1)


func _on_RespawnAllBugFixTimer_timeout():
	if Lobby.is_host:
		for player_info in Lobby.get_all_lobby_player_info():
			var player_component: Player = players.get_player_component(player_info["id"], "_on_RespawnAllBugFixTimer_timeout")
			if player_component != null && (_respawn_dead_only == false || (_respawn_dead_only == true && players.is_alive(player_info["id"]) == false)):
				var spawn_point: Vector3 = environment.map.get_player_spawn_point(player_component.get_team())
				host_reset_player_values(players.get_player_entity(player_info["id"]), spawn_point)
				PacketSender.update_entity_pos_directly(player_info["id"], spawn_point)
				PacketSender.respawn_player(player_info["id"])


func host_reset_player_values(player_entity: Entity, spawn_pos: Vector3):
	if Lobby.is_host && Util.safe_to_use(player_entity):
		player_entity.set_position(spawn_pos)
		player_entity.set_force(Vector3.ZERO)


func set_leaderboard(sender_id: int, player_scores: Array) -> void:
	if sender_id == Lobby.host_id && gamemode != null:
		gamemode.set_leaderboard(player_scores)


func start_shrink(sender_id: int) -> void:
	if sender_id == Lobby.host_id && gamemode != null:
		gamemode.p2p_start_shrink()


func set_score(sender_id: int, player_id: int, score: int, to_team: bool) -> void:
	if sender_id == Lobby.host_id:
		Lobby.set_team_member_score(player_id, score)


func set_is_OP(sender_id: int, player_id: int, time: float, spellcaster_only: bool) -> void:
	if sender_id == Lobby.host_id:
		if players.get_player_component(player_id, "set_is_OP") != null:
			players.get_player_component(player_id).p2p_set_is_OP(time, spellcaster_only)


func set_is_loser(sender_id: int, player_id: int) -> void:
	if sender_id == Lobby.host_id:
		var loser_entity: Entity = get_entity(player_id, "set_is_loser")
		
		if loser_entity != null:
			loser_entity.emit_signal("trigger_player_animation", Globals.PlayerAnimations.START_FLOP, Vector2.ZERO)
			
			var spellcaster = loser_entity.get_component_of_type(Globals.ComponentTypes.SpellCaster)
			if spellcaster != null:
				spellcaster.set_immobilized(true, true)


func spawn_spell(sender_id: int, caster_id: int, creator_team: String, spell_id: int, spell_type: int, pos: Vector3, dir: Vector2) -> void:
	if sender_id == Lobby.host_id:
		var caster_entity: Entity = get_entity(caster_id, "spawn_spell")
		if caster_entity != null:
			if caster_entity.get_type() == Globals.EntityTypes.PLAYER:
				players.on_player_cast_spell(caster_entity, spell_type)
			
			elif caster_entity.get_type() == Globals.EntityTypes.SPELL && caster_entity.get_subtype() == Globals.SpellTypes.TOTEM:
				var totem_component = caster_entity.get_node("Totem")
				if totem_component != null:
					var up: bool = false
					if spell_type == Globals.SpellTypes.METEOR:
						up = true
					totem_component.play_shoot_anim(up)
			
			spells.p2p_spawn_spell(players, caster_entity, creator_team, spell_id, spell_type, pos, dir)
		else:
			printerr("Couldn't find the caster entity for spawning a spell")


func launch(id: int, entity_type: int, from: Vector3, to: Vector3, speed: float) -> void:
	var entity: Entity = get_entity(id)
	if entity != null:
		entity.get_component_of_type(Globals.ComponentTypes.Launchable).launch(from, to, null, speed)


func reflect_spell(sender_id: int, creator_id: int, spell_id: int, pos: Vector3, new_dir: Vector3) -> void:
	if sender_id == Lobby.host_id:
		spells.reflect_spell(creator_id, spell_id, pos, new_dir)


func spawn_environment(sender_id: int, env_id: int, env_info: Dictionary, parent_id: int = -1) -> void:
	if sender_id == Lobby.host_id:
		environment.add_environment(env_info, env_id, parent_id)


func p2p_spawn_player(sender_id: int, player_id: int, player_info: Dictionary) -> void:
	if sender_id == Lobby.host_id:
		players.spawn_player(player_id, player_info)


func trigger_particle_effect(entity_id: int, entity_type: int, effect_nr: int, emitting: bool):
	var entity: Entity = get_entity(entity_id, "trigger_particle_effect")
	if entity != null:
		if entity.get_component_of_type(Globals.ComponentTypes.ParticlePlayer) != null:
			entity.get_component_of_type(Globals.ComponentTypes.ParticlePlayer).trigger_effect(effect_nr, emitting)


func handle_broadcast_freeze_info(sender_id: int, player_id: int, level: float, icecubed: bool) -> void:
	if sender_id == Lobby.host_id:
		var player_component: Player = players.get_player_component(player_id, "handle_broadcast_freeze_info")
		if player_component != null:
			player_component.p2p_set_freeze_info(level, icecubed)


## REQUESTS TO HOST ##
## Players that aren't the host must request doing things to the host and 
## the host validates and confirms them by broadcasting the players request.
func validate_update_player_movement(id: int, input: Vector2) -> void:
	players.update_player_movement(id, input)


func deactivate_spell(sender_id: int, deactivated_spell: int) -> void:
	var spell_caster: SpellCaster = get_spellcaster_component(sender_id)
	if spell_caster != null:
		spell_caster.deactivate_spell(deactivated_spell)


func validate_cast_directional_spell(sender_id: int, player_id: int, spell_type: int, dir: Vector2) -> void:
	# TODO: sender_id == player_id || is_host
	var player_entity: Entity = get_entity(player_id, "validate_cast_directional_spell")
	if player_entity != null:
		var spell_caster: SpellCaster = get_spellcaster_component(player_id)
		if validate_spell_cast(sender_id, player_id, spell_type, spell_caster):
			var spell_pos: Vector3 = player_entity.get_component_of_type(Globals.ComponentTypes.SpellCaster).get_spell_spawn_pos()
			var spell_id: int = Util.generate_id(Globals.EntityTypes.SPELL, spell_type)
			var player_team: Dictionary = Lobby.get_team_info_from_player_id(player_id)
			var team_name: String = ""
			if player_team.empty() == false:
				team_name = player_team["name"] 
			
			if Globals.SpellCooldowns[spell_type]["hold_down"] == true:
				spell_caster.set_holding_down_spell(true)
			
			player_entity.emit_signal("cast_spell", spell_type, spell_pos + Vector3(dir.x, 0, dir.y))
			PacketSender.spawn_spell(player_id, team_name, spell_id, spell_type, spell_pos, dir)
			
			# If transformed, transform back to player
			if spell_caster.is_transformed:
				PacketSender.transform_into(player_id, -1)


func validate_cast_positional_spell(sender_id: int, player_id: int, spell_type: int, requested_pos: Vector3) -> void:
	var player_entity: Entity = get_entity(player_id, "validate_cast_positional_spell")
	if player_entity != null:
		var spell_caster: SpellCaster = player_entity.get_component_of_type(Globals.ComponentTypes.SpellCaster)
		if spell_caster != null && validate_spell_cast(sender_id, player_id, spell_type, spell_caster):
			var player_pos: Vector3 = player_entity.global_transform.origin
			var spell_pos: Vector3 = Util.clamp_spell_pos(player_pos, requested_pos, spell_type)
			var spell_id: int = Util.generate_id(Globals.EntityTypes.SPELL, spell_type)
			var player_team: Dictionary = Lobby.get_team_info_from_player_id(player_id)
			var team_name: String = ""
			var direction: Vector2 = Vector2(player_pos.x, player_pos.z).direction_to(Vector2(spell_pos.x, spell_pos.z))
			if player_team.empty() == false:
				team_name = player_team["name"] 
			
			player_entity.emit_signal("cast_spell", spell_type, spell_pos)
			
			if Globals.SpellCooldowns[spell_type]["hold_down"] == true:
				spell_caster.set_holding_down_spell(true)
			
			# If statement for teleport, check valid range, update player position
			if spell_type == Globals.SpellTypes.DIVE:
				spell_caster.host_activate_dive(spell_pos)
			
			if spell_type == Globals.SpellTypes.ARCANE_WALL || spell_type == Globals.SpellTypes.METEOR || spell_type == Globals.SpellTypes.TOTEM:
				PacketSender.spawn_spell(player_id, team_name, spell_id, spell_type, spell_pos, direction)
				
			if spell_type == Globals.SpellTypes.CRAB:
				# To avoid two crabs landing on eachother perfectly and flying away
				var rand_spread: Vector3 = Vector3((Util.rand.randf()-0.5), 0, (Util.rand.randf()-0.5))
				PacketSender.spawn_spell(player_id, team_name, spell_id, spell_type, spell_pos + rand_spread, direction)
			
			if spell_caster.is_transformed:
				PacketSender.transform_into(player_id, -1)


func validate_rock_dash(sender_id: int, id: int, dir: Vector2) -> void:
	var entity: Entity = get_entity(id, "validate_rock_dash")
	if entity != null:
		var spell_caster: SpellCaster = get_spellcaster_component(id)
		if spell_caster != null && validate_spell_cast(sender_id, id, Globals.SpellTypes.DASH, spell_caster):
			spell_caster.activate_rock_dash(dir)


func validate_transform_into(sender_id: int, id: int, transform_into: int, speed_modifier: float, duration: float) -> void:
	var spell_caster: SpellCaster = get_spellcaster_component(id)
	if spell_caster != null:
		if validate_spell_cast(sender_id, id, Globals.SpellTypes.INVISIBILITY, spell_caster):
			PacketSender.transform_into(id, transform_into, speed_modifier, duration)


func validate_deactivate_arcane_wall(sender_id: int, id: int, spawn_wall: bool):
	var entity: Entity = get_entity(id, "validate_deactivate_arcane_wall")
	if entity != null:
		var spell_caster: SpellCaster = get_spellcaster_component(id)
		if spell_caster != null:
			spell_caster.reset_cooldown_of_spell(Globals.SpellTypes.ARCANE_WALL)
		
		# Spawn wall
		if spawn_wall:
			var player_entity: Entity = get_entity(id, "deactivate wall")
			var dir: Vector2 = Util.y_rot_to_vector_2(player_entity.rotation.y)
			var offset: Vector3 = Vector3(dir.x, 0, dir.y) * 1.5
			
			var player_team: Dictionary = Lobby.get_team_info_from_player_id(id)
			var team_name: String = ""
			if player_team.empty() == false:
				team_name = player_team["name"] 
			
			PacketSender.spawn_spell(id, team_name, Util.generate_id(Globals.EntityTypes.SPELL, Globals.SpellTypes.ARCANE_WALL_PLACED), Globals.SpellTypes.ARCANE_WALL_PLACED, player_entity.global_transform.origin + offset, dir)


func handle_elements_changed(sender_id: int) -> void:
	if sender_id == Lobby.host_id:
		MusicAndSfxHandler.play_sound(MusicAndSfxHandler.sounds.NEW_ELEMENTS)
		gamemode.show_text_center_screen("Elements Changed!", 1)
		for player_info in Lobby.get_all_lobby_player_info():
			var spell_caster = get_spellcaster_component(player_info["id"])
			if spell_caster != null:
				spell_caster.reset_elements(true)


func handle_new_wave(sender_id: int, wave: int) -> void:
	if sender_id == Lobby.host_id:
		gamemode.set_new_wave(wave)


## UTIL ##
func get_clamped_pos(player_pos: Vector3, requested_pos: Vector3) -> Vector3:
	if (requested_pos - player_pos).length() > Globals.SPELL_CAST_RANGE:
		return player_pos + (requested_pos - player_pos).normalized() * Globals.SPELL_CAST_RANGE + Vector3(0, 0.05, 0)
	elif (requested_pos - player_pos).length() < Globals.SPELL_CAST_MIN_RANGE:
		return player_pos + player_pos.direction_to(requested_pos) * Globals.SPELL_CAST_MIN_RANGE + Vector3(0, 0.05, 0)
	else:
		return requested_pos + Vector3(0, 0.05, 0)


func get_spellcaster_component(id: int) -> SpellCaster:
	var entity: Entity = get_entity(id, "get_spellcaster_component")
	if entity != null:
		var spell_caster: SpellCaster = entity.get_component_of_type(Globals.ComponentTypes.SpellCaster)
		return spell_caster
	
	printerr("Something went wrong whilst getting a spellcaster component")
	return null


# TODO: Move this to spellCaster so that everyone validates the same way
func validate_spell_cast(sender_id: int, spell_caster_id: int, spell_type: int, spell_caster: SpellCaster) -> bool:
	if gamemode.current_game_state == GamemodeValues.GameStates.STARTING:
		return false
	
	if spell_caster != null:
		if spell_caster.parent_entity.get_is_trapped() == true:
			return false
		
		if spell_caster.get_immobilized() == true:
			return false
		
		# Host has already reset cooldown for themselves and bots, return true
		if sender_id == Lobby.host_id:
			return true
		
		if Globals.SpellCooldowns[spell_type]["hold_down"] == true && spell_caster.holding_down_spell == true:
			return false
		
		# TODO: RE-ADD 
		#if spell_caster.check_cooldown_of_spell_over(spell_type):
		#	spell_caster.reset_cooldown_of_spell(spell_type)
		#	return true
		
		return true
	else:
		printerr("Couldn't validate cooldown since there was no spellcaster")
		return false
	
	return false


func p2p_handle_despawn_entity(entity_id: int, of_old_age: bool) -> void:
	#print("[Despawn]: Despawning entity with id ", entity_id)
	var entity: Entity = get_entity(entity_id, "p2p_handle_despawn_entity")
	#print("[Despawn]: Entity is ", entity)
	if entity != null:
		Lobby.emit_signal("destroy_entity", entity_id)
		entity.emit_signal("destroyed", entity_id, of_old_age)
		
		# Temporary shit
		#var kinematic_body = entity.get_kinematic()
		#if kinematic_body != null:
		#	kinematic_body.collision_layer = 0
		#	kinematic_body.collision_mask = 0
		
		match entity.get_type():
			Globals.EntityTypes.ENVIRONMENT:
				environment.remove_environment(entity_id)
			Globals.EntityTypes.SPELL:
				spells.remove_spell(entity_id)
			Globals.EntityTypes.PLAYER:
				players.remove_player(entity)
		
		var pretty_destroy = entity.get_component_of_type(Globals.ComponentTypes.PrettyDestroy)
		if pretty_destroy != null:
			# Calls despawn_entity() in x seconds so that things can 'fade' away
			pretty_destroy.pretty_destroy(of_old_age)
		else:
			despawn_entity(entity)
		
		entities_dict.erase(entity_id)
		#print("[Despawn]: Removing it as a child now")
		#print(".")
		
		#Util.destroy_w_children(entity)
	else:
		#printerr("[Despawn]: Couldn't despawn entity since it was null...")
		pass


# Be careful how you use this, ask charles if you aren't sure
func despawn_entity(entity) -> void:
	entities.call_deferred("remove_child", entity)


func add_entity(id: int, entity: Entity) -> void:
	if entities_dict.has(id) == false:
		entities.add_child(entity)
		entities_dict[id] = entity
		entity.name = str(id)
	else:
		print("Tried to add entity that was already added.")


func destroy_all_entities() -> void:
	environment.clear_all_environment()
	players.clear_all_players()
	spells.clear_all_spells()
	
	for entity in entities.get_children():
		p2p_handle_despawn_entity(int(entity.name), false)
	
	print("Destroyed all entities.")


func has_entity(id: int) -> bool:
	return entities.has_node(str(id))


func get_entity(id: int, from: String = "somewhere") -> Node:
	if entities_dict.has(id):
		var entity = entities_dict[id]
		if Util.safe_to_use(entity) && entity is Entity:
			return entity
		else:
			printerr("Requested entity wasn't safe to use or wasn't an Entity")
			return null
	else:
		if str(id).length() > 3:
			var type = str(id)[str(id).length() - 3]
			var subtype = str(id).substr(str(id).length() - 2, str(id).length() - 1)
			#printerr("Couldn't get entity ", Util.get_type_names(int(type), int(subtype)), " from ", from)
		else:
			printerr("Couldn't get entity with id",id ," from ", from)
			
		return null


func get_gooey_god() -> Entity:
	for child in entities.get_children():
		if child is Entity:
			if child.get_subtype() == Globals.EnvironmentTypes.GOOEY_GOD_STATUE:
				return child
	return null


func play_post_process_ripple(pos: Vector3):
	var screen_pos: Vector2 = Globals.camera.unproject_position(pos)
	screen_pos /= Vector2(ProjectSettings.get("display/window/size/width"), ProjectSettings.get("display/window/size/height"))
	
	screen_pos = Vector2(screen_pos.x, 1.0 - screen_pos.y)
	
	post_process_texture.get_material().set_shader_param("ripple_pos", screen_pos)
	post_process_animator.play("ripple")
