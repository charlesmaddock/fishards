extends Spatial


onready var goalArea = $Area

export(bool) var is_blue_team 


# Called when the node enters the scene tree for the first time.
func _ready():
	goalArea.connect("area_entered", self, "_on_area_entered")


func _on_area_entered(area: Area) -> void:
	var entity = Util.get_entity_from_area(area)
	if Util.get_entity_from_area(area) != null:
		if entity.get_type() == Globals.EntityTypes.ENVIRONMENT && entity.get_subtype() == Globals.EnvironmentTypes.FISH_BALL:
			Lobby.emit_signal("goal", is_blue_team)
