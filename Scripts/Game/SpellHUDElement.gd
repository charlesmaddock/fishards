extends Control


export(bool) var is_left


onready var elementTexture = $"ElementTexture"
onready var elementTextureRect = $"ElementTexture/ElementTextureRect1"
onready var spellHUDElementAnimator = $"SpellHUDElementAnimator"


func set_default() -> void:
	spellHUDElementAnimator.play("Default")


func set_element(element: int, new_spell_created: bool) -> void:
	elementTextureRect.texture = Globals.get_element_icon(element)
	
	# Skip all the animations if we auto clear
	if UserSettings.get_auto_clear_elements() == true:
		return
	
	if element != Globals.Elements.NONE:
		spellHUDElementAnimator.play("Select")
		yield(get_tree().create_timer(spellHUDElementAnimator.get_current_animation_length()), "timeout")
		var anim = spellHUDElementAnimator.get_current_animation()
		if anim != "CombineLeft" && anim != "CombineRight":
			spellHUDElementAnimator.play("Hover")
	else:
		spellHUDElementAnimator.play("Default")
	
	elementTextureRect.set_scale(Vector2.ONE)
	
	if new_spell_created == true:
		combine_element(is_left)


func combine_element(is_left: bool) -> void:
	var animation = "CombineLeft" if is_left == true else "CombineRight" 
	spellHUDElementAnimator.play(animation)


func one_element_too_long() -> void:
	spellHUDElementAnimator.play_backwards("Select")
