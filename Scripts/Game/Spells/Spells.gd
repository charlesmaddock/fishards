extends Node


export(PackedScene) var land_anticipation_indicator_scene 


const fireball_scene = preload("res://Scenes/Entities/Spells/Fireball.tscn")
const push_scene = preload("res://Scenes/Entities/Spells/Push.tscn")
const fireblast_scene = preload("res://Scenes/Entities/Spells/Fireblast.tscn")
const ice_beam_scene = preload("res://Scenes/Entities/Spells/IceBeam.tscn")
const meteor_scene = preload("res://Scenes/Entities/Spells/Meteor.tscn")
const crab_scene = preload("res://Scenes/Entities/Spells/CrabEntity.tscn")
const arcane_wall_scene = preload("res://Scenes/Entities/Spells/ArcaneWall.tscn")
const wildfire_scene = preload("res://Scenes/Entities/Spells/Wildfire.tscn")
const heal_scene = preload("res://Scenes/Entities/Spells/HealArea.tscn")
const totem_scene = preload("res://Scenes/Entities/Spells/Totem.tscn")
const beam_scene = preload("res://Scenes/Entities/Spells/DashBeam.tscn")
const rockdash_boulder_scene = preload("res://Scenes/Entities/Spells/RockDashBoulder.tscn")
const grab_scene = preload("res://Scenes/Entities/Spells/Grab.tscn")
const arcane_wall_placed_scene = preload("res://Scenes/Entities/Spells/ArcaneWallPlaced.tscn")
const freeze_orb_scene = preload("res://Scenes/Entities/Spells/FreezeOrb.tscn")
const freeze_area_scene = preload("res://Scenes/Entities/Spells/FreezeArea.tscn")
const dive_stun_scene = preload("res://Scenes/Entities/Spells/DiveStun.tscn")

var spell_ids: Array # Array of id ints
var _transform_update_timer: float


func _physics_process(delta):
	_transform_update_timer += delta
	if Lobby.is_host:
		_transform_update_timer = 0
		for id in spell_ids:
			var spell_entity: Entity = get_parent().get_entity(id, "Spells process")
			if spell_entity != null:
				if spell_entity.broadcast_transform == true:
					PacketSender.broadcast_entity_transform(spell_entity.get_id(), spell_entity.global_transform.origin, spell_entity.get_rot())


func clear_all_spells() -> void:
	spell_ids.clear()


func get_closest_enemy_totem(my_pos: Vector3, my_team_name: String):
	var closest_totem: Entity = null
	var closest_dist: float = 9999
	for spell_id in spell_ids:
		var spell: Entity = get_parent().get_entity(spell_id, "get_closest_enemy_totem")
		if spell != null:
			if spell.get_subtype() == Globals.SpellTypes.TOTEM && Lobby.is_on_same_team_as(spell.get_creator_id(), my_team_name) == false:
				var dist = spell.global_transform.origin.distance_to(my_pos)
				if dist < closest_dist:
					closest_dist = dist
					closest_totem = spell
	
	return closest_totem


func p2p_spawn_spell(players: Players, caster_entity: Entity, creator_team: String, spell_id: int, spell_type: int, pos: Vector3, dir: Vector2 = Vector2.ZERO, dash_beam_hit_history: Array = []) -> void:
	if Globals.game_paused == false:
		var spell_instance: Entity = null
		
		match spell_type:
			Globals.SpellTypes.FIREBALL:
				spell_instance = fireball_scene.instance()
			Globals.SpellTypes.PUSH:
				spell_instance = push_scene.instance()
			Globals.SpellTypes.FIREBLAST:
				spell_instance = fireblast_scene.instance()
			Globals.SpellTypes.ICE_BEAM:
				spell_instance = ice_beam_scene.instance()
			Globals.SpellTypes.METEOR:
				spell_instance = meteor_scene.instance()
			Globals.SpellTypes.CRAB:
				spell_instance = crab_scene.instance()
			Globals.SpellTypes.ARCANE_WALL:
				spell_instance = arcane_wall_scene.instance()
			Globals.SpellTypes.WILDFIRE:
				spell_instance = wildfire_scene.instance()
			Globals.SpellTypes.HEAL:
				spell_instance = heal_scene.instance()
			Globals.SpellTypes.TOTEM:
				spell_instance = totem_scene.instance()
			Globals.SpellTypes.DASH:
				spell_instance = rockdash_boulder_scene.instance()
			Globals.SpellTypes.DASH_BEAM:
				spell_instance = beam_scene.instance()
			Globals.SpellTypes.GRAB:
				spell_instance = grab_scene.instance()
			Globals.SpellTypes.ARCANE_WALL_PLACED:
				spell_instance = arcane_wall_placed_scene.instance()
			Globals.SpellTypes.FREEZE_ORB:
				spell_instance = freeze_orb_scene.instance()
			Globals.SpellTypes.FREEZE_AREA:
				spell_instance = freeze_area_scene.instance()
			Globals.SpellTypes.DIVE_STUN:
				spell_instance = dive_stun_scene.instance()
		
		if spell_instance != null:
			var spawn_rot: float = dir.angle_to(Vector2.DOWN)
			
			# Spells are updated by each client, so set is controlled locally to true
			spell_instance.init_entity(spell_id, false, true, Globals.EntityTypes.SPELL, spell_type, pos, caster_entity.get_id())
			spell_instance.set_rot(spawn_rot)
			
			# Some spells change the speed of a player
			if caster_entity.get_type() == Globals.EntityTypes.PLAYER:
				var player: Player = caster_entity.get_component_of_type(Globals.ComponentTypes.Player)
				if player == null:
					printerr("Couldn't find the player component??")
				
				if spell_type == Globals.SpellTypes.WILDFIRE:
					player.set_speed_modifier("wildfire", -0.47, spell_instance.age_limit_seconds)
				elif spell_type == Globals.SpellTypes.ARCANE_WALL:
					player.set_speed_modifier("wall", -0.4, spell_instance.age_limit_seconds)
				elif spell_type == Globals.SpellTypes.ICE_BEAM:
					player.set_speed_modifier("icebeamslowdebuff", -0.36, spell_instance.age_limit_seconds)
				elif spell_type == Globals.SpellTypes.GRAB:
					caster_entity.set_target_rotation(spawn_rot)
					caster_entity.lock_rotation_w_duration(0.8)
				
			var dont_knockback_creator: bool = true
			# AOE attacks should push the creator. TODO: this get_component_of_type undermines the loop at the bottom, improve if possible
			
			var damage_comp = spell_instance.get_component_of_type(Globals.ComponentTypes.Damage)
			if damage_comp != null:
				# Totems do less meteor damage to prevent instakill combos
				if caster_entity.get_type() == Globals.EntityTypes.SPELL && caster_entity.get_subtype() == Globals.SpellTypes.TOTEM:
					if spell_type == Globals.SpellTypes.METEOR:
						damage_comp.set_damage(damage_comp.damage/2)
				elif caster_entity.get_type() == Globals.EntityTypes.PLAYER:
					var player: Player = caster_entity.get_component_of_type(Globals.ComponentTypes.Player)
					if player != null:
						if player.get_is_OP() == true:
							damage_comp.set_damage(damage_comp.damage * 2)
				
				if damage_comp.repeat_damage:
					dont_knockback_creator = false
			
			# Set the components if they exist
			for child in spell_instance.get_children():
				if child.get("COMPONENT_TYPE") != null:
					match child.COMPONENT_TYPE:
						Globals.ComponentTypes.Projectile:
							child.init_spell(dir, creator_team)
						Globals.ComponentTypes.Launchable:
							if spell_type == Globals.SpellTypes.METEOR:
								var landing_indicator = land_anticipation_indicator_scene.instance()
								add_child(landing_indicator)
								landing_indicator.global_transform.origin = pos + (Vector3.UP * 0.2)
								child.launch(caster_entity.get_pos(), pos, landing_indicator, Globals.METEOR_SPEED)
							else:
								child.launch(caster_entity.get_pos(), pos)
						Globals.ComponentTypes.Turret:
							child.init_turret(creator_team)
						Globals.ComponentTypes.Crab:
							spell_instance.local_transform_update = Lobby.is_host
							child.init_crab(caster_entity.get_id(), creator_team, pos)
			
			spell_ids.append(spell_id)
			get_parent().add_entity(spell_id, spell_instance)
	else:
		printerr(str(caster_entity.get_id()) + "Tried to spawn spell while game was paused")


func remove_spell(id: int) -> void:
	var remove_at: int = spell_ids.find(id)
	if remove_at != -1:
		spell_ids.remove(remove_at)
	else:
		printerr("Couldn't find spell to remove with id ",id)


func reflect_spell(creator_id: int, spell_id: int, new_pos: Vector3, new_dir: Vector3) -> void:
	var spell_to_reflect: Entity = get_parent().get_entity(spell_id, "reflect spell")
	if Util.safe_to_use(spell_to_reflect):
		if creator_id == SteamValues.STEAM_ID:
			AchievementHandler.inc_reflects()
		
		var projectile: Projectile = spell_to_reflect.get_component_of_type(Globals.ComponentTypes.Projectile)
		var damage: Damage = spell_to_reflect.get_component_of_type(Globals.ComponentTypes.Damage)
		var knockback: Knockback = spell_to_reflect.get_component_of_type(Globals.ComponentTypes.Knockback)
		
		# Once reflected, it seems reasonable that it would push anyone
		if knockback != null:
			knockback.set_dont_push_player_with_id(-1) 
		
		if projectile != null:
			spell_to_reflect.set_position(new_pos)
			projectile.reflect(new_dir, creator_id)
