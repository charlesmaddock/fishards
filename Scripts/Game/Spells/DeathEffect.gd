extends Spatial


export(Array, NodePath) var blood_particle_effect

var fish_model_path: NodePath = "fish_wizard/Armature/Skeleton/Fish"
var _death_type: int = Globals.PlayerDeathTypes.NORMAL

onready var player_animator: AnimationPlayer = $fish_wizard/AnimationPlayer
onready var half_player_animator: AnimationPlayer = $fish_wizard_in_half/AnimationPlayer
onready var fish_wizard: Spatial = $fish_wizard
onready var fish_wizard_in_half: Spatial = $fish_wizard_in_half
onready var transform_animator: AnimationPlayer = $TransformAnimator
onready var _iceCube: Spatial = $fish_wizard/ice_cube


func _ready():
	_iceCube.visible = false
	fish_wizard_in_half.visible = false
	fish_wizard.visible = true
	


func trigger_effect():
	match _death_type:
		Globals.PlayerDeathTypes.NORMAL:
			play_particle_effect(blood_particle_effect)
			player_animator.play("Death")
			transform_animator.play("SinkDown")
			transform_animator.connect("animation_finished", self, "done")
		Globals.PlayerDeathTypes.DROWN:
			fish_wizard.global_transform.origin.y = -1.5 # this value is a bit hardcoded and bad, comes from SwimAnimator in player
			if GamemodeValues.current_map_type == GamemodeValues.Maps.Ice:
				player_animator.play("Frozen")
				transform_animator.play("BobbleThenSink")
				transform_animator.connect("animation_finished", self, "done")
				_iceCube.visible = true
			else:
				transform_animator.play("HigherUp")
				player_animator.play("drown")
				player_animator.connect("animation_finished", self, "done")
		Globals.PlayerDeathTypes.EXPLODE:
			play_particle_effect(blood_particle_effect)
			half_player_animator.play("FallDownDeath")
			transform_animator.play("SinkDown")
			transform_animator.connect("animation_finished", self, "done")
		Globals.PlayerDeathTypes.BURN:
			transform_animator.play("Burn")
			transform_animator.connect("animation_finished", self, "done")


func create_from_dead_player(entity: Entity, pos: Vector3, rot: float, scale: Vector3, skin: Dictionary, death_type: int) -> void:
	_death_type = death_type 
	set_scale(scale)
	global_transform.origin = pos
	rotation.y = rot
	var new_skin: Dictionary = skin.duplicate()
	if _death_type == Globals.PlayerDeathTypes.EXPLODE:
		fish_wizard.visible = false
		fish_wizard_in_half.visible = true
		var players_skin = CustomizePlayer.get_players_skin_material(skin)
		fish_wizard_in_half.get_node("Armature/Skeleton/Fish").set_surface_material(1, players_skin)
	elif _death_type == Globals.PlayerDeathTypes.BURN:
		new_skin["inside"] = 3
		new_skin["mouth"] = 2
		new_skin["skin"] = 2
		new_skin["legs"] = 2
	
	if new_skin.has("hat"):
		fish_wizard.show_hat(new_skin["hat"])
	
	CustomizePlayer.apply_skin_to_fishard(entity, new_skin, get_node(fish_model_path))
	
	trigger_effect()


func play_particle_effect(node_path_array: Array):
	for effect in node_path_array:
		get_node(effect).emitting = true


func done(_name: String) -> void:
	if Util.safe_to_use(self):
		queue_free()
