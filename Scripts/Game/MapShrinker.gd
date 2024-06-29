extends Spatial


onready var animationPlayer: AnimationPlayer = $AnimationPlayer
onready var water = $water
onready var foam = $foam
onready var iceWater = $ice
onready var iceFoam = $icefoam
onready var lavaWater = $lava
onready var lavaFoam = $lavafoam

var shrinking: bool = false


func _ready():
	set_visible(false)


func get_shrink_progress() -> float:
	if animationPlayer.is_playing() == true:
		return animationPlayer.get_current_animation_position()
	else:
		return -1.0


func set_shrink_progress(position: float) -> void:
	check_start_shrink()
	animationPlayer.call_deferred("advance", position)


func check_start_shrink():
	# Gamemodes with no respawns need to shrink so that last players are forced to battle
	if shrinking == false:
		shrinking = true
		
		if GamemodeValues.current_map_type == GamemodeValues.Maps.Lava:
			lavaWater.set_visible(true)
			lavaFoam.set_visible(true)
		elif GamemodeValues.current_map_type == GamemodeValues.Maps.Island:
			water.set_visible(true)
			foam.set_visible(true)
		elif GamemodeValues.current_map_type == GamemodeValues.Maps.Ice:
			iceWater.set_visible(true)
			iceFoam.set_visible(true)
	
		set_visible(true)
		animationPlayer.play("shrink")


func hide():
	if shrinking == true:
		animationPlayer.play("hide")


# After 4 mins it starts shrinking either way
func _on_ShrinkTimer_timeout():
	PacketSender.start_shrink()
