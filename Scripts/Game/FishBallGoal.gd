extends Node3D


@onready var goalArea = $Area3D

@export var is_blue_team: bool 


# Called when the node enters the scene tree for the first time.
func _ready():
	goalArea.connect("area_entered", Callable(self, "_on_area_entered"))


func _on_area_entered(area: Area3D) -> void:
	var entity = Util.get_entity_from_area(area)
	if Util.get_entity_from_area(area) != null:
		if entity.get_type() == Globals.EntityTypes.ENVIRONMENT && entity.get_subtype() == Globals.EnvironmentTypes.FISH_BALL:
			Lobby.emit_signal("goal", is_blue_team)
