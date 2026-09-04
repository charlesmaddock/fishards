extends Node3D


@onready var fireblast_effect: Particles = $Particles


func _ready():
	fireblast_effect.emitting = true
