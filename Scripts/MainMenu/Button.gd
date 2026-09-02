@tool
extends Button

@export var image: Texture2D

@onready var sprite: Sprite2D = $Sprite2D

func _ready():
	sprite.texture = image


func _on_Button_mouse_entered():
	MusicAndSfxHandler.play_sound(MusicAndSfxHandler.sounds.HOVER)
	sprite.frame = 1


func _on_Button_mouse_exited():
	sprite.frame = 0


func _on_Button_pressed():
	MusicAndSfxHandler.play_sound(MusicAndSfxHandler.sounds.CLICK)


func _on_Button_visibility_changed():
	if sprite != null:
		sprite.frame = 0
