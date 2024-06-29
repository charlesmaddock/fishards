extends Spatial
class_name Map


export(bool) var generate_environment: bool = true 
export(int) var env_density: int = 3
export(float) var env_spawn_chance: float = 0.5
export(Array, String) var environment_types: Array
export(Array, PackedScene) var ground_scenes: Array


export(NodePath) var spawn_area_container = null
export(NodePath) var red_team_spawn_container_path = null
export(NodePath) var blue_team_spawn_container_path = null
export(NodePath) var hand_placed_entity_container = null


var _spawn_areas
var _hand_placed_entity_container: Spatial 
var _time_since_last_powerup: float
var _time_to_next_powerup: float 
var _red_team_spawn_container: Spatial = null
var _blue_team_spawn_container: Spatial = null


func _ready():
	assert("Generate environment is set to true but no environment types have been set for this map, please add some.", environment_types.size() == 0 && generate_environment == true)
	assert("No spawn area container has been added, add the SpawnArea scene to the map.", spawn_area_container == null)
	if spawn_area_container != null:
		_spawn_areas = get_node(spawn_area_container)
	if hand_placed_entity_container != null:
		_hand_placed_entity_container = get_node(hand_placed_entity_container)
	
	if red_team_spawn_container_path != null:
		_red_team_spawn_container = get_node(red_team_spawn_container_path)
	if blue_team_spawn_container_path != null:
		_blue_team_spawn_container = get_node(blue_team_spawn_container_path)
	
	set_time_to_next_power_up()
	
	# Depending on the gamemode show or hide team spawn points
	var current_gamemode_teammode = GamemodeValues.get_current_rounds_teammode()
	if current_gamemode_teammode != GamemodeValues.TeamModes.RED_BLUE_TEAMS && current_gamemode_teammode != GamemodeValues.TeamModes.COOP:
		if _blue_team_spawn_container != null:
			for spawn_collision_shape in _blue_team_spawn_container.get_children():
				spawn_collision_shape.visible = false
		if _red_team_spawn_container != null:
			for spawn_collision_shape in _red_team_spawn_container.get_children():
				spawn_collision_shape.visible = false
	
	# If the user has faster graphics, disable shadows and a few other things
	if UserSettings.use_pretty_graphics() == false:
		# To replace the foam we get the material of the water plane
		var water_plane_material: Material
		if get_node("Water Plane") != null:
			water_plane_material = get_node("Water Plane").get_surface_material(0)
		
		for child in get_children():
			if child is DirectionalLight:
				var light: DirectionalLight = child
				light.set_shadow(false)
			
			# Somethings in the map need to run faster
			remove_pretty_graphics_materials(child, water_plane_material)
			# Some spatials contain meshes with foam in
			if child is Spatial:
				for grand_child in child.get_children():
					remove_pretty_graphics_materials(grand_child, water_plane_material)


func remove_pretty_graphics_materials(search_inside, water_plane_material) -> void:
	if search_inside is MeshInstance:
		var map_model: MeshInstance = search_inside
		for i in map_model.get_surface_material_count():
			if map_model.get_surface_material(i) is ShaderMaterial:
				var shader_mat: Material = map_model.get_surface_material(i)
				if shader_mat.shader.resource_path == "res://Assets/Shaders/foam.shader" || shader_mat.shader.resource_path == "res://Assets/Shaders/new_foam.shader":
					# Give the foam the same color as the water
					map_model.set_surface_material(i, water_plane_material)


func _process(delta: float) -> void:
	check_spawn_power_up(delta)


func check_spawn_power_up(delta: float) -> void:
	if Lobby.is_host == true && RoomSettings.get_powerups_enabled() == true:
		_time_since_last_powerup += delta
	
		if _time_since_last_powerup >= _time_to_next_powerup:
			_time_since_last_powerup = 0
			
			var available_power_ups = [Globals.EnvironmentTypes.HEALTH_POWERUP, Globals.EnvironmentTypes.CLONE_POWERUP]
			var power_up_type = available_power_ups[Util.rand.randi_range(0, available_power_ups.size() -1)]
			
			if Util.get_current_game_state() == GamemodeValues.GameStates.GAME:
				set_time_to_next_power_up()
				var pos = get_spawn_pos(1)
				var power_up_info: Dictionary = Globals.EnvironmentInfo(power_up_type, 0, pos)
				var id: int = Util.generate_id(Globals.EntityTypes.ENVIRONMENT, power_up_type)
				PacketSender.spawn_environment(id, power_up_info)


func set_time_to_next_power_up() -> void:
	var amount_of_players: float = Lobby.client_members.size() + Lobby._bot_members.size()
	_time_to_next_powerup = Util.rand.randf_range(30 - amount_of_players/2.5, 40 - amount_of_players/2.5)


func clear_hand_placed_entities() -> void:
	if not Engine.editor_hint && _hand_placed_entity_container != null:
		_hand_placed_entity_container.queue_free()


func generate_ground_decoration() -> void:
	if _spawn_areas != null:
		for spawn_area in _spawn_areas.get_children():
			var shape = spawn_area.get_shape()
			var size = Vector2()
			
			if spawn_area.get_shape() is CylinderShape:
				size = Vector2(shape.radius * 2, shape.radius * 2)
			elif spawn_area.get_shape() is BoxShape:
				size = Vector2(shape.extents.x * 2, shape.extents.z * 2)
			else:
				printerr("Spawn area must be a cylinder or box.")
			
			var x: int = 0
			var y: int = 0
			var ground_env_step: int = 8
			while x <= size.x:
				y = 0
				while y <= size.y:
					var interated_pos = Vector2((float(x - (size.x / 2.0))), (float(y - (size.y / 2.0))))
					
					if x % ground_env_step == 0 && y % ground_env_step == 0:
						try_generate_ground_particle(spawn_area, interated_pos)
					y += 1
				x += 1


func generate_environment(room_node: Node, environment_node: Node) -> Dictionary:
	# Fills the Environment node's environment_dict with entites and then 
	# converts them to info array and broadcasts it 
	if generate_environment == true:
		for spawn_area in _spawn_areas.get_children():
			var shape = spawn_area.get_shape()
			var size = Vector2()
			
			if spawn_area.get_shape() is CylinderShape:
				size = Vector2(shape.radius * 2, shape.radius * 2)
			elif spawn_area.get_shape() is BoxShape:
				size = Vector2(shape.extents.x * 2, shape.extents.z * 2)
			else:
				printerr("Spawn area must be a cylinder or box.")
			
			var x: int = 0
			var y: int = 0
			while x <= size.x:
				y = 0
				while y <= size.y:
					var interated_pos = Vector2((float(x - (size.x / 2.0))), (float(y - (size.y / 2.0))))
					
					if x % env_density == 0 && y % env_density == 0:
						var res = try_generate_environment(spawn_area, interated_pos * env_density)
						if res.success == true:
							# Spawn the environment for the HOST so collisions can be checked before sending to players
							environment_node.add_environment(res.env_info, res.id)
					y += 1
				x += 1
	
	add_hand_placed_entities_to_env_node(environment_node)
	
	return environment_node.get_all_environment_info()


func add_hand_placed_entities_to_env_node(environment_node: Node) -> void:
	# Add all the hand placed entities properly to the environment node
	if _hand_placed_entity_container != null:
		for hand_placed_entity in _hand_placed_entity_container.get_children():
			var hand_placed_id: int = Util.generate_id()
			environment_node.add_environment(
				Globals.EnvironmentInfo(
					hand_placed_entity.get_subtype(), 
					hand_placed_entity.get_rot(), 
					hand_placed_entity.global_transform.origin
				), 
				hand_placed_id
			)
			if hand_placed_entity.get_type() != Globals.EntityTypes.ENVIRONMENT:
				printerr("The hand placed entity with the name ", hand_placed_entity.name,"  isn't and environment, if it is just visual, give it a static body with the collision layer 'environment' and place it somewhere else.")
	
	clear_hand_placed_entities()


func host_remove_colliding_entities(room_node: Node) -> void:
	var entity_ids_to_remove: Array = []
	var environment_node = get_parent()
	for env_entity_id in environment_node.get_environment_ids():
		var env_entity = room_node.get_entity(env_entity_id, "host_remove_colliding_entities")
		if env_entity != null:
			var env_area: Area = env_entity.get_area()
			if env_area != null:
				if env_area.get_overlapping_areas().size() > 0:
					entity_ids_to_remove.append(env_entity_id)
	
	for id in entity_ids_to_remove:
		#print("[Despawn, Sending packet]: Removing colliding entity with id ", id)
		PacketSender.host_broadcast_destroy_entity(id)


func try_generate_ground_particle(spawn_area: CollisionShape, pos: Vector2) -> void:
	if ground_scenes.size() > 0:
		var spawn_point = get_spawn_pos(-1, false, spawn_area, pos)
		if spawn_point != Vector3.DOWN:
			var ground_scene: PackedScene = ground_scenes[Util.rand.randi_range(0, ground_scenes.size() - 1)]
			var ground_thingy = ground_scene.instance()
			ground_thingy.transform.origin = Vector3(spawn_point.x, 0, spawn_point.z)
			ground_thingy.rotation.y = Util.rand.randf_range(-PI, PI)
			add_child(ground_thingy)


func try_generate_environment(spawn_area: CollisionShape, pos: Vector2) -> Dictionary:
	var env_type: int
	
	var spawn_point = get_spawn_pos(-1, false, spawn_area, pos)
	if spawn_point == Vector3.DOWN:
		return {"success": false}
	
	# Find a good environment - lower chance to spawn rare environments such as large rocks
	var set_envtype: bool = false
	while set_envtype == false:
		# There is a chance that nothing with spawn
		if Util.rand.randf() > env_spawn_chance:
			return {"success": false}
		
		# Try to get an random env type
		var rand_env_type_index: int = Util.rand.randi_range(0, environment_types.size() - 1)
		env_type = Globals.EnvironmentTypes[environment_types[rand_env_type_index]]
		# If the entity should spawn less often check RARE_ENV_TYPES and see the spawn chance
		if Globals.RARE_ENV_TYPES.has(env_type):
			if Util.rand.randf() < Globals.RARE_ENV_TYPES[env_type]:
				set_envtype = true
		else:
			set_envtype = true
	
	var rand_rotation = Util.rand.randf_range(-PI, PI)
	
	# Generate the environment info
	var env_id: int = Util.generate_id()
	var environment_info = Globals.EnvironmentInfo(env_type, rand_rotation, spawn_point)
	return {"success": true, "env_info": environment_info, "id": env_id}


func get_player_spawn_point(team: String) -> Vector3:
	var current_gamemodes_teammode: int = GamemodeValues.get_current_rounds_teammode()
	var spawn_area: CollisionShape = null
	
	if RoomSettings.get_rounds_gamemode() == GamemodeValues.Gamemodes.Survive:
		if team == "Wizishes":
			var rand_child_index: int = Util.rand.randi_range(0, _red_team_spawn_container.get_child_count() - 1)
			spawn_area = _red_team_spawn_container.get_child(rand_child_index)
		else:
			var rand_child_index: int = Util.rand.randi_range(0, _blue_team_spawn_container.get_child_count() - 1)
			spawn_area = _blue_team_spawn_container.get_child(rand_child_index)
	# In training team spawns aren't used
	elif RoomSettings.get_rounds_gamemode() != GamemodeValues.Gamemodes.Training:
		if current_gamemodes_teammode == GamemodeValues.TeamModes.RED_BLUE_TEAMS || current_gamemodes_teammode == GamemodeValues.TeamModes.COOP:
			if team == "Blue Team":
				if _blue_team_spawn_container != null:
					var rand_child_index: int = Util.rand.randi_range(0, _blue_team_spawn_container.get_child_count() - 1)
					spawn_area = _blue_team_spawn_container.get_child(rand_child_index)
				else:
					printerr("blue_team_spawn_collision_shape wasn't defined")
			elif team == "Red Team":
				if _red_team_spawn_container != null:
					var rand_child_index: int = Util.rand.randi_range(0, _red_team_spawn_container.get_child_count() - 1)
					spawn_area = _red_team_spawn_container.get_child(rand_child_index)
				else:
					printerr("red_team_spawn_collision_shape wasn't defined")
			else:
				printerr("Invalid team name.")
	
	return get_spawn_pos(1, true, spawn_area)


# Returns Vector3.DOWN if it failed to find a spawn point
func get_spawn_pos(radius: float = -1, guarantee_spawn: bool = true, spawn_area: CollisionShape = null, pos: Vector2 = Vector2.LEFT) -> Vector3:
	var spawn_point: Vector3 = Vector3.DOWN
	var failed_to_find_spawn_point: bool = true
	var fail_amount: int = 0
	var get_random_spawn_point: bool = pos == Vector2.LEFT
	
	# Select a random spawn area if one isn't specified
	if spawn_area == null:
		var child_amount: int = 0
		for child in _spawn_areas.get_children():
			if child is CollisionShape:
				child_amount += 1
		
		var spawn_area_index = Util.rand.randi_range(0, child_amount - 1)
		spawn_area = _spawn_areas.get_child(spawn_area_index)
	
	# If we have specified a position, add random variation
	if get_random_spawn_point == false:
		pos.x += Util.rand.randf_range(-3, 3)
		pos.y += Util.rand.randf_range(-3, 3)
	
	var fail_collided_with: Array = []
	
	while failed_to_find_spawn_point == true:
		fail_amount += 1
		
		if spawn_area.get_shape() is CylinderShape:
			var shape: CylinderShape = spawn_area.get_shape()
			# Generate a random pos if one wasn't specified
			if get_random_spawn_point == true:
				var x: float = shape.radius * Util.rand.randf_range(-1, 1)
				var z: float = shape.radius * Util.rand.randf_range(-1, 1)
				pos = Vector2(x, z)
			
			# Check if the spawn point is valid
			spawn_point = Vector3(pos.x, 0, pos.y)
			if spawn_point.length_squared() <= shape.radius * shape.radius:
				failed_to_find_spawn_point = false
			else:
				if guarantee_spawn == false:
					return Vector3.DOWN # Vector3.DOWN means it failed
		
		elif spawn_area.get_shape() is BoxShape:
			var shape: BoxShape = spawn_area.get_shape()
			# Generate a random pos if one wasn't specified
			if get_random_spawn_point == true:
				var x: float = shape.extents.x * Util.rand.randf_range(-1, 1)
				var z: float = shape.extents.z * Util.rand.randf_range(-1, 1)
				pos = Vector2(x, z)
			
			spawn_point = Vector3(pos.x, 0, pos.y)
			
			# Clamp
			if spawn_point.x > shape.extents.x || spawn_point.z > shape.extents.z || spawn_point.z < -shape.extents.z ||  spawn_point.x < -shape.extents.x:
				if guarantee_spawn == false:
					return Vector3.DOWN # Vector3.DOWN means it failed
			else:
				failed_to_find_spawn_point = false
		
		# Check if we are colliding with something, if so choose another spawn point
		if radius != -1:
			var space_state = get_world().get_direct_space_state()
			var cast_order: Array = [Vector3(radius, 0, 0), Vector3(-radius, 0, 0), Vector3(0, 0, radius), Vector3(0, 0, -radius)]
			for i in range(4):
				var collision_mask = 2 + 4 + 64 + 32 # + 16
				var result = space_state.intersect_ray(spawn_point + (cast_order[i] + Vector3.UP * 4), spawn_point + (cast_order[i] + Vector3.DOWN * 4), [], collision_mask)
				if result.get("collider") != null:
					failed_to_find_spawn_point = true
		
		if guarantee_spawn == true && fail_amount > 50:
			if guarantee_spawn == true:
				printerr("Warning: Failed to find a spawn point that should be guaranteed! Normal cause: You have an area that is invisible (maybe spawnAreas?) that the thing we tried to spawn very frequently collided with. ")
				printerr("fail_collided_with: ")
				printerr(fail_collided_with)
				spawn_point = Vector3.ZERO
				failed_to_find_spawn_point = false
	
	var global_pos = spawn_area.to_global(spawn_point)
	return global_pos

