extends Label

var bright_color

export(bool) var has_opacity: bool

func _ready():
	if has_opacity == true:
		if GamemodeValues.current_map_type == GamemodeValues.Maps.Lava:
			self_modulate = "#a3e2d6cf"
		else:
			self_modulate = "#a3605a56"
	else:
		if GamemodeValues.current_map_type == GamemodeValues.Maps.Lava:
			self_modulate = "#a3e2d6cf"
		else:
			self_modulate = "#a3605a56"

