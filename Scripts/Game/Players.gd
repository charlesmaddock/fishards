extends Spatial
class_name Players

export(PackedScene) var player_scene: PackedScene
export(PackedScene) var fishard_bot_scene: PackedScene
export(PackedScene) var dead_player_scene: PackedScene
export(PackedScene) var poof_scene: PackedScene
export(NodePath) var client_node

var player_ids: Array      
var living_player_ids: Array  


var _time_since_update: float = 0


func get_living_player_ids() -> Array:
	return living_player_ids


func add_living_player_id(id: int) -> void:
	if living_player_ids.find(id) == -1:
		living_player_ids.append(id)


func has_player(id) -> bool:
	return player_ids.find(id) != -1


func get_closest_enemy_player(my_pos: Vector3, dont_target_player_w_id: int, my_team_name: String, is_bot: bool = false, search_dist: float = 9999) -> Entity:
	var closest_player: Entity = null
	var closest_dist: float = search_dist
	var room_node = Util.get_room_node()
	if room_node != null:
		for player_id in living_player_ids:
			var player: Entity = room_node.get_entity(player_id, "get_closest_enemy_player")
			if player != null:
				if player_id != dont_target_player_w_id && Lobby.is_on_same_team_as(player_id, my_team_name) == false:
					var dist = player.global_transform.origin.distance_to(my_pos)
					if is_bot == true:
						if player.get_component_of_type(Globals.ComponentTypes.Player).get_is_OP() == true:
							dist /= 10
						
						if dist < closest_dist:
							var spell_caster: SpellCaster = player.get_component_of_type(Globals.ComponentTypes.SpellCaster)
							var see_transformed_player: bool = Util.rand.randf() > 0.9 && dist < 15 || player.get_move_dir_v3() != Vector3.ZERO
							if see_transformed_player || spell_caster.is_transformed == false:
								closest_dist = dist
								closest_player = player
					else:
						if dist < closest_dist:
							closest_dist = dist
							closest_player = player
	
	return closest_player


func get_random_living_player() -> Entity:
	if living_player_ids.size() > 0:
		var index = Util.rand.randi_range(0, living_player_ids.size() - 1)
		var id = living_player_ids[index]
		return get_parent().get_entity(id)
	else:
		return null


func is_alive(id: int) -> bool:
	return living_player_ids.find(id) != -1


func trap_all_players_for(time: float) -> void:
	for player_id in player_ids:
		var player_entity: Entity = get_parent().get_entity(player_id)
		if player_entity != null:
			player_entity.set_trapped_w_duration(time, false)


func get_living_player_with_index(index: int) -> Entity:
	if index < living_player_ids.size() && index >= 0:
		return get_parent().get_entity(living_player_ids[index])
	else:
		return null


func get_living_player_entity(id: int) -> Entity:
	if living_player_ids.find(id) != -1:
		return get_parent().get_entity(id)
	else:
		return null


func get_player_entity(id: int) -> Entity:
	if player_ids.find(id) != -1:
		return get_parent().get_entity(id)
	else:
		if id != -1:
			printerr("[Players]: Couldn't get the requested player entity")
		return null


func get_player_component(id: int, from: String = "somewhere") -> Player:
	if player_ids.find(id) != -1:
		var player_entity: Entity = get_parent().get_entity(id, from)
		if player_entity != null:
			var player_component: Player = player_entity.get_component_of_type(Globals.ComponentTypes.Player)
			if player_component != null:
				return player_component
	
	#printerr("Something went wrong whilst getting a player component from ", from)
	return null


func get_all_player_info() -> Dictionary:
	var all_player_info: Dictionary
	
	for id in player_ids:
		var player_entity = get_parent().get_entity(id, "get all player info")
		if player_entity != null:
			var player_component = player_entity.get_component_of_type(Globals.ComponentTypes.Player)
			var spell_caster_component = player_entity.get_component_of_type(Globals.ComponentTypes.SpellCaster)
			var player_info = Globals.PlayerInfo(
				player_component.parent_entity.get_id(),
				player_component.get_username(),
				player_component.parent_entity.global_transform.origin,
				player_component.get_player_type(),
				player_component.get_skin(),
				player_component.get_preferred_team(),
				spell_caster_component.get_available_elements(),
				player_component.get_cloned_from_id(),
				player_component.get_rank()
			)
			all_player_info[player_component.parent_entity.get_id()] = player_info
		
	return all_player_info


func kill_dead_players_for_joining_player(joiner_id: int) -> void:
	var dead_player_ids: Array = []
	for player_id in player_ids:
		var is_alive: bool = living_player_ids.find(player_id) != -1
		if is_alive == false:
			dead_player_ids.append(player_id)
	
	for dead_id in dead_player_ids:
		PacketSender.send_player_death(joiner_id, dead_id)


func clear_all_players() -> void:
	player_ids.clear()
	living_player_ids.clear()
	print("removed all players")


func _physics_process(delta):
	if Lobby.is_host:
		update_players()


func update_players() -> void:
	for id in living_player_ids:
		var player_entity: Entity = get_parent().get_entity(id, "update players")
		if player_entity != null:
			PacketSender.broadcast_player_target_pos(player_entity.get_id(), player_entity.global_transform.origin)
		else:
			printerr("Failed to loop through a player in update players")


# Updates the player's input inside the host's client
func update_player_movement(id: int, move_dir: Vector2) -> void:
	var player_component: Player = get_player_component(id, "update_player_movement")
	if player_component != null:
		player_component.set_input(move_dir)
		return 
	
	print("[Players]: Couldn't find the player whoms't input shall be updated")


func generate_inital_player_data(map_node: Map) -> Dictionary:
	var inital_players: Dictionary = {}
	
	var bots_and_player_info = Lobby.get_all_lobby_player_info()
	for player_info in bots_and_player_info:
		player_info["spwnpnt"] = map_node.get_player_spawn_point(player_info["team"])
		inital_players[player_info["id"]] = player_info
	
	return inital_players


func host_spawn_temp_bot(team_name: String, bot_type: int, spawn_pos: Vector3 = Vector3.ZERO, clone_from: Player = null) -> int:
	if Lobby.is_host:
		var map_node: Map = get_parent().environment.map
		var skin = CustomizePlayer.create_bot_skin(bot_type, clone_from)
		var is_boss = Util.player_is_boss(bot_type)
		var name: String = Util.generate_bot_name(bot_type, is_boss) if clone_from == null else clone_from.get_username()
		var cloned_from_id: int = -1
		if clone_from != null:
			cloned_from_id = clone_from.parent_entity.get_id()
			poof_at(clone_from.parent_entity.get_pos())
			poof_at(spawn_pos)
		var pos = map_node.get_player_spawn_point("Wizishes") if spawn_pos == Vector3.ZERO else spawn_pos
		var id = Util.generate_id()
		
		var available_elements = Util.generate_available_elements(RoomSettings.get_element_amount())
		if clone_from != null:
			var spell_caster = clone_from.parent_entity.get_component_of_type(Globals.ComponentTypes.SpellCaster)
			if spell_caster != null:
				available_elements = spell_caster.get_available_elements()
		
		# Special bots have all elements available but only cast a select few
		if bot_type != Globals.PlayerTypes.EASY_BOT && bot_type != Globals.PlayerTypes.MEDIUM_BOT && bot_type != Globals.PlayerTypes.HARD_BOT:
			 available_elements = [1,2,3,4,5]
		
		var temp_bot_info = Globals.PlayerInfo(id, name, pos, bot_type, skin, team_name, available_elements, cloned_from_id, -1)
		
		Lobby.host_add_player_and_broadcast(temp_bot_info, true, true)
		spawn_player(id, temp_bot_info)
		PacketSender.spawn_player(id, temp_bot_info)
		return id
	
	return 0


func poof_at(pos: Vector3) -> void:
	var poof = poof_scene.instance()
	poof.transform.origin = pos 
	poof.emitting = true
	add_child(poof)


func remove_player(player_entity: Entity) -> void:
	poof_at(player_entity.global_transform.origin)
	
	# client are removed via remove_player_from_lobby
	if player_entity.get_subtype() != Globals.PlayerTypes.CLIENT:
		for bot_info in Lobby._bot_members:
			if bot_info["id"] == player_entity.get_id():
				var remove_at: int = Lobby._bot_members.find(bot_info) 
				if remove_at != -1:
					Lobby._bot_members.remove(remove_at)
					break
		for bot_info in Lobby._temp_bot_members:
			if bot_info["id"] == player_entity.get_id():
				var remove_at: int = Lobby._temp_bot_members.find(bot_info) 
				if remove_at != -1:
					Lobby._temp_bot_members.remove(remove_at)
					break
	
	var remove_at: int = player_ids.find(player_entity.get_id()) 
	if remove_at != -1:
		player_ids.remove(remove_at)
	var remove_living_at: int = living_player_ids.find(player_entity.get_id()) 
	if remove_living_at != -1:
		living_player_ids.remove(remove_living_at)


func p2p_handle_player_death(id: int, respawn_time: float, death_type: int) -> void:
	var remove_living_at: int = living_player_ids.find(id) 
	if remove_living_at != -1:
		living_player_ids.remove(remove_living_at)
		var player_component: Player = get_player_component(id, "handle player death")
		var spell_caster: SpellCaster = get_parent().get_spellcaster_component(id)
		
		if player_component != null && spell_caster != null:
			var dead_player = dead_player_scene.instance()
			add_child(dead_player)
			player_component.kill_player(respawn_time)
			if player_component.get_in_water() == true:
				death_type = Globals.PlayerDeathTypes.DROWN
			dead_player.create_from_dead_player(player_component.parent_entity, player_component.global_transform.origin, player_component.parent_entity.get_rot(), player_component.parent_entity.scale, player_component.get_skin(), death_type)
			
			if id == SteamValues.STEAM_ID:
				spell_caster.reset_elements(true)
		else:
			printerr("Couldn't get player and spellcaster component of dead player")


func p2p_respawn_player(id: int) -> void:
	if player_ids.find(id) != -1:
		add_living_player_id(id)
		
		var player: Player = get_player_component(id, "respawn player")
		if player != null:
			player.respawn()
		
		if id == SteamValues.STEAM_ID:
			var spell_caster: SpellCaster = get_parent().get_spellcaster_component(id)
			if spell_caster != null:
				spell_caster.reset_elements(true)


func on_player_cast_spell(caster_entity: Entity, spell_type: int) -> void:
	if player_ids.find(caster_entity.get_id()) != -1:
		if spell_type != Globals.SpellTypes.DIVE && spell_type != Globals.SpellTypes.DASH && spell_type != Globals.SpellTypes.DASH_BEAM && spell_type != Globals.SpellTypes.HEAL:
			var player_comp = caster_entity.get_component_of_type(Globals.ComponentTypes.Player)
			if player_comp != null:
				player_comp.trigger_shoot_animation(spell_type)
				return
	else:
		printerr("Couldn't find the player who cast this spell: ", caster_entity.name)


func spawn_player(id: int, player_info: Dictionary) -> void:
	var is_clients_player = id == SteamValues.STEAM_ID;
	var player_entity: Entity
	var username = player_info["name"] 
	var spawn_point = player_info["spwnpnt"] 
	var skin = player_info["skin"]
	var preferred_team = player_info["team"]
	var available_elements = player_info["elmts"]
	var cloned_from_id = player_info["clone"]
	var player_type = player_info["plyr_type"]
	
	if player_type == Globals.PlayerTypes.CLIENT:
		player_entity = player_scene.instance()
	else:
		player_entity = fishard_bot_scene.instance()
	
	var player_component: Player = player_entity.get_component_of_type(Globals.ComponentTypes.Player)
	var spell_caster_component: SpellCaster = player_entity.get_component_of_type(Globals.ComponentTypes.SpellCaster)
	var info_panel_component: EntityInfoPanel = player_entity.get_component_of_type(Globals.ComponentTypes.EntityInfoPanel)
	
	var should_update_transform_locally: bool = (Lobby.SECURE_GAME == true && Lobby.is_host || player_type != Globals.PlayerTypes.CLIENT && Lobby.is_host || Lobby.SECURE_GAME == false && is_clients_player == true)
	player_entity.init_entity(id, is_clients_player, should_update_transform_locally, Globals.EntityTypes.PLAYER, player_info["plyr_type"], spawn_point)
	
	if player_component != null:
		player_component.init_player(id, username, skin, preferred_team, cloned_from_id, player_info["plyr_type"], player_info["rank"])
	
	if spell_caster_component != null:
		spell_caster_component.init_spell_caster(available_elements)
	
	if info_panel_component != null:
		info_panel_component.get_element_display().set_owner_id(id)
	
	player_ids.append(id)
	add_living_player_id(id)
	get_parent().add_entity(id, player_entity)
	
	Lobby.add_player_to_team(GamemodeValues.get_current_rounds_teammode(), player_info)
	RoomSettings.host_add_player_to_leaderboard(id)
	
	if is_clients_player:
		Globals.set_camera_following(player_entity, player_entity.get_pos())
