extends Spatial


onready var IceCube = $IceCube
onready var SnowPile = $Snowpile
onready var SnowFlakes = $SnowFlakes


func _ready():
	IceCube.set_visible(false)
	SnowPile.set_visible(false)
	SnowFlakes.set_visible(false)


func set_ice_cube(visible: bool):
	if visible == true && IceCube.visible == false:
		get_node("Frozen").play()
	
	IceCube.set_visible(visible)


func set_freeze_level(speed_modifier: float):
	if speed_modifier == 0:
		SnowPile.set_visible(false)
		SnowFlakes.set_visible(false)
	elif IceCube.visible == false:
		SnowPile.set_visible(true)
		SnowFlakes.set_visible(true)
	
	if speed_modifier != 0:
		SnowFlakes.amount = int(ceil(speed_modifier * -3))
	
	var y_scale = (Vector3.UP * clamp((speed_modifier * -1) * 2, 0, 2))
	var pile_scale: Vector3 = Vector3.ONE * (clamp((speed_modifier * -1) * 2, 0, 2) + 0.2) + y_scale
	SnowPile.scale = pile_scale
