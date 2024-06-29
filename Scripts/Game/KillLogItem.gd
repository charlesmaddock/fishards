extends HBoxContainer


func set_values(killer_name: String, killed_name: String, spell: int) -> void:
	get_node("KillerName").text = killer_name
	get_node("KilledName").text = killed_name
	get_node("SpellIcon/Sprite").texture = Globals.get_spell_icon(spell)


func _on_FreeTimer_timeout():
	queue_free()
