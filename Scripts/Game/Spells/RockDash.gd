extends Spatial


onready var dash1: MeshInstance = $dash1
onready var dash2: MeshInstance = $dash2
onready var explosion: Particles = $Explosion


func hit():
	explosion.emitting = true


func play() -> void:
	dash1.visible = true
	dash2.visible = true

func stop() -> void:
	if Util.safe_to_use(dash1) && Util.safe_to_use(dash2):
		dash1.visible = false
		dash2.visible = false

func _on_RockDash_rock_dash_hit():
	hit()
	stop()
