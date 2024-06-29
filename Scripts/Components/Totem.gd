extends Component


onready var totemAnimationPlayer: AnimationPlayer = $totem/AnimationPlayer
onready var rocks: MeshInstance = $totem/Armature/Skeleton/Plane
onready var muzzle: MeshInstance = $totem/Armature/Skeleton/Sphere001
export(NodePath) var transform_animator


var _only_upgrade: bool = false
var _totem_to_upgrade_id: int
var _has_landed: bool
var _creator_pos_offset: Vector3
var _spell_caster: SpellCaster
var _creator_team_name: String


func get_team_name() -> String:
	return _creator_team_name


func _ready():
	Lobby.connect("destroy_entity", self, "_on_entity_destroyed")
	parent_entity.connect("destroyed", self, "_on_self_destroyed")
	_spell_caster = parent_entity.get_component_of_type(Globals.ComponentTypes.SpellCaster)
	rocks.visible = false
	muzzle.visible = false
	#parent_entity.connect("landed", self, "_on_landed")
	_on_landed()


func _on_self_destroyed(_id, _of_old_age) -> void:
	get_node("Die").play()


# If creator dies, despawn totem too
func _on_entity_destroyed(entity_id: int) -> void:
	if entity_id == parent_entity.get_creator_id():
		PacketSender.host_broadcast_destroy_entity(parent_entity.get_id())


func _on_landed():
	if get_node(transform_animator):
		get_node(transform_animator).play("show")
	totemAnimationPlayer.play("construct001", -1, 1.5)
	rocks.visible = true
	muzzle.visible = true
	_has_landed = true
	totemAnimationPlayer.connect("animation_finished", self, "idle")
	parent_entity.disable_collider(false)
	
	var creator = get_creator_entity()
	var team = Lobby.get_team_info_from_player_id(parent_entity.get_creator_id())
	if creator != null && team.empty() == false:
		_creator_team_name = team.name
		_creator_pos_offset = parent_entity.get_pos() - creator.get_pos() 
		creator.connect("cast_spell", self, "_on_creator_cast_spell")
		creator.connect("released_spell", self, "_on_released_spell")


func _on_creator_cast_spell(active_spell: int, cast_pos: Vector3) -> void:
	if Lobby.is_host:
		# Totem cant cast a totem
		if active_spell == Globals.SpellTypes.TOTEM:
			return 
		
		var creator = get_creator_entity()
		if creator != null:
			var totem_cast_pos = (cast_pos - creator.get_pos()) + parent_entity.get_pos()
			totem_cast_pos.y = 0
			
			_spell_caster.update_active_spell(active_spell)
			_spell_caster.try_request_cast_spell(totem_cast_pos, _creator_team_name)
		
		if active_spell == Globals.SpellTypes.DIVE:
			get_node(transform_animator).play("diveDown")
			var tree = get_tree()
			if tree != null:
				yield(tree.create_timer(0.5), "timeout")
				if get_node(transform_animator) != null:
					get_node(transform_animator).play("diveUp")


func _on_released_spell() -> void:
	_spell_caster.deactivate_spell()


func play_shoot_anim(up: bool) -> void:
	if !up:
		totemAnimationPlayer.play("shoot")
	elif up:
		totemAnimationPlayer.play("shoot_up")


func _process(delta):
	if _has_landed == true && Lobby.is_host:
		var room = Util.get_room_node()
		if room != null:
			var creator: Entity = room.get_entity(parent_entity.get_creator_id(), "totem_process")
			if creator != null:
				parent_entity.set_target_rotation(creator.get_rot(), 10)


func get_creator_entity() -> Entity:
	var room = Util.get_room_node()
	if room != null:
		var creator: Entity = room.get_entity(parent_entity.get_creator_id())
		if creator != null:
			return creator
	
	return null


func idle(_name: String) -> void:
	totemAnimationPlayer.play("idle-loop")
