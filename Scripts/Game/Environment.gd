extends Node
class_name EnvironmentNode


export(PackedScene) var big_rock_1_scene: PackedScene
export(PackedScene) var big_rock_2_scene: PackedScene 
export(PackedScene) var palm_tree_scene: PackedScene 
export(PackedScene) var meteor_up_scene: PackedScene 
export(PackedScene) var big_splash: PackedScene
export(PackedScene) var small_splash: PackedScene
export(PackedScene) var dead_tree: PackedScene
export(PackedScene) var leaf_tree: PackedScene
export(PackedScene) var turret_scene: PackedScene
export(PackedScene) var speed_powerup_scene: PackedScene
export(PackedScene) var health_powerup_scene: PackedScene
export(PackedScene) var clone_powerup_scene: PackedScene
export(PackedScene) var rapidfire_powerup_scene: PackedScene
export(PackedScene) var water_rock_1: PackedScene
export(PackedScene) var water_rock_2: PackedScene
export(PackedScene) var water_rock_3: PackedScene
export(PackedScene) var water_rock_4: PackedScene
export(PackedScene) var water_rock_5: PackedScene
export(PackedScene) var water_rock_6: PackedScene
export(PackedScene) var rock_1: PackedScene
export(PackedScene) var rock_2: PackedScene
export(PackedScene) var rock_3: PackedScene
export(PackedScene) var rock_4: PackedScene
export(PackedScene) var rock_5: PackedScene
export(PackedScene) var rock_6: PackedScene
export(PackedScene) var burnt_tree_1: PackedScene
export(PackedScene) var gooey_golden_fishard: PackedScene
export(PackedScene) var invisibility_ball: PackedScene
export(PackedScene) var dummy_scene: PackedScene
export(PackedScene) var strong_dummy_scene: PackedScene
export(PackedScene) var fish_ball_scene: PackedScene


var environment_ids: Array
var map: Node = null


func get_environment_ids() -> Array:
	return environment_ids


func get_closest_enemy_turret(my_pos: Vector3, my_team_name: String):
	var closest_totem: Entity = null
	var closest_dist: float = 9999
	for env_id in environment_ids:
		var environment: Entity = get_parent().get_entity(env_id, "get_closest_enemy_turret")
		if environment != null:
			if environment.get_subtype() == Globals.EnvironmentTypes.TURRET && my_team_name == "Red Team":
				var dist = environment.global_transform.origin.distance_to(my_pos)
				if dist < closest_dist:
					closest_dist = dist
					closest_totem = environment
	
	return closest_totem


func set_map_node(map_node: Map) -> void:
	add_child(map_node)
	map = map_node
	map_node.generate_ground_decoration()


func _physics_process(delta: float):
	if Lobby.is_host:
		for id in environment_ids:
			var environment: Entity = get_parent().get_entity(id, "environment process")
			if environment != null:
				if environment.broadcast_transform == true:
					PacketSender.broadcast_entity_transform(environment.get_id(), environment.global_transform.origin, environment.get_rot())


func get_all_environment_info() -> Dictionary:
	var all_env_info: Dictionary = {}
	for id in environment_ids:
		var environment: Entity = get_parent().get_entity(id)
		if environment != null:
			var env_info = Globals.EnvironmentInfo(
				environment.get_subtype(),
				environment.get_rot(),
				environment.global_transform.origin
			)
			all_env_info[environment.get_id()] = env_info
		else:
			print("tried to add env to all environment list but it was null")
	
	return all_env_info


func remove_environment(id: int) -> void:
	var remove_at: int = environment_ids.find(id)
	if remove_at != -1:
		environment_ids.remove(remove_at)


func clear_all_environment() -> void:
	environment_ids.clear()


func add_environment(env_info: Dictionary, id: int = -1, parent_id: int = -1) -> void:
	var environment_scene: PackedScene = get_scene_from_type(env_info.type)
	var environment_entity: Entity
	
	if id == -1:
		id = Util.generate_id()
	
	if environment_scene != null:
		environment_entity = environment_scene.instance()
		environment_entity.init_entity(id, false, Lobby.is_host, Globals.EntityTypes.ENVIRONMENT, env_info.type, env_info.pos, parent_id)
		environment_entity.set_rot(env_info.rot)
		environment_ids.append(id)
		get_parent().add_entity(id, environment_entity)
		return
		
	printerr("[Environment]: Couldn't add an environment")


func get_scene_from_type(type: int) -> PackedScene:
	match type:
		Globals.EnvironmentTypes.BIG_ROCK_1:
			return big_rock_1_scene
		Globals.EnvironmentTypes.BIG_ROCK_2:
			return big_rock_2_scene
		Globals.EnvironmentTypes.PALM_TREE:
			return palm_tree_scene
		Globals.EnvironmentTypes.METEOR_UP:
			return meteor_up_scene
		Globals.EnvironmentTypes.BIG_SPLASH:
			return big_splash
		Globals.EnvironmentTypes.SMALL_SPLASH:
			return small_splash
		Globals.EnvironmentTypes.DEAD_TREE:
			return dead_tree
		Globals.EnvironmentTypes.LEAF_TREE:
			return leaf_tree
		Globals.EnvironmentTypes.TURRET:
			return turret_scene
		Globals.EnvironmentTypes.HEALTH_POWERUP:
			return health_powerup_scene
		Globals.EnvironmentTypes.SPEED_POWERUP:
			return speed_powerup_scene
		Globals.EnvironmentTypes.CLONE_POWERUP:
			return clone_powerup_scene
		Globals.EnvironmentTypes.RAPIDFIRE_POWERUP:
			return rapidfire_powerup_scene
		Globals.EnvironmentTypes.INVISIBILITY_BALL:
			return invisibility_ball
		Globals.EnvironmentTypes.WATER_ROCK_1:
			return water_rock_1
		Globals.EnvironmentTypes.WATER_ROCK_2:
			return water_rock_2
		Globals.EnvironmentTypes.WATER_ROCK_3:
			return water_rock_3
		Globals.EnvironmentTypes.WATER_ROCK_4:
			return water_rock_4
		Globals.EnvironmentTypes.WATER_ROCK_5:
			return water_rock_5
		Globals.EnvironmentTypes.WATER_ROCK_6:
			return water_rock_6
		Globals.EnvironmentTypes.ROCK_1:
			return rock_1
		Globals.EnvironmentTypes.ROCK_2:
			return rock_2
		Globals.EnvironmentTypes.ROCK_3:
			return rock_3
		Globals.EnvironmentTypes.ROCK_4:
			return rock_4
		Globals.EnvironmentTypes.ROCK_5:
			return rock_5
		Globals.EnvironmentTypes.ROCK_6:
			return rock_6
		Globals.EnvironmentTypes.BURNT_TREE_1:
			return burnt_tree_1
		Globals.EnvironmentTypes.GOOEY_GOD_STATUE:
			return gooey_golden_fishard
		Globals.EnvironmentTypes.DUMMY:
			return dummy_scene
		Globals.EnvironmentTypes.STRONG_DUMMY:
			return strong_dummy_scene
		Globals.EnvironmentTypes.FISH_BALL:
			return fish_ball_scene
	
	printerr("The requested environment type which is ", type, " ", Globals.EnvironmentTypes.keys()[type]," hasn't been added. Did you forget to add the packed scene to the environment script?")	
	return null

