extends SpatialComponent
class_name ParticlePlayer, "res://Assets/Textures/Sprites/Node Icons/componentIcon.png"
var COMPONENT_TYPE: int = Globals.ComponentTypes.ParticlePlayer

onready var fireblastHurtEffect = $FireblastHurtEffect
onready var wildfireHurtEffect = $WildfireHurtEffect
onready var fireHurtEffect = $FireHurtEffect
onready var waterSplashEffect = $WaterSplashEffect
onready var lavaSplashEffect =  $LavaSplashEffect
onready var healed = $Healed
onready var meteorMuzzle = $MeteorMuzzle
onready var burningEffect = $BurningEffect
onready var dashBeamHurt = $DashBeamHurt
onready var pushedTrail = $PushedTrail
onready var pushedLanding = $PushedLanding

func _ready():
	parent_entity.connect("trigger_particle_effect", self, "_on_trigger_effect")
	
	for child in burningEffect.get_children():
		child.visible = false

func _on_trigger_effect(effect_nr: int, emitting: bool, y_rot: float):
	rotation.y = 0
	rotation.y -= parent_entity.rotation.y
	rotation.y += y_rot
	
	var effect: Spatial
	
	match effect_nr:
		Globals.ParticleEffects.FIREBLAST_HURT:
			effect = fireblastHurtEffect
		Globals.ParticleEffects.WILDFIRE_HURT:
			effect = wildfireHurtEffect
		Globals.ParticleEffects.FIRE_HURT:
			effect = fireHurtEffect
		Globals.ParticleEffects.WATER_SPLASH:
			effect = waterSplashEffect
		Globals.ParticleEffects.LAVA_SPLASH:
			effect = lavaSplashEffect
		Globals.ParticleEffects.HEALED:
			effect = healed
		Globals.ParticleEffects.METEOR_MUZZLE:
			effect = meteorMuzzle
		Globals.ParticleEffects.BURNING:
			effect = burningEffect
		Globals.ParticleEffects.DASH_BEAM_HURT:
			effect = dashBeamHurt
		Globals.ParticleEffects.PUSHED_TRAIL:
			effect = pushedTrail
		Globals.ParticleEffects.PUSHED_LANDING:
			effect = pushedLanding
		
	for particles in effect.get_children():
		if particles is Particles:
			particles.emitting = emitting
		if particles is MeshInstance:
			particles.visible = emitting
