extends Control


func set_values(element1: int, element2: int, spell: int) -> void:
	$number1.text = str(element1)
	$number2.text = str(element2)
	$element1.texture = Globals.get_element_icon(element1)
	$element2.texture = Globals.get_element_icon(element2)
	# Goo is smaller as an icon for some reason
	$element1.scale = Vector2(2, 2)
	$element2.scale = Vector2(2, 2) 
	$spell.texture = Globals.get_spell_icon(spell)
