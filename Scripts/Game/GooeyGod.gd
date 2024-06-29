extends Node


func _ready():
	get_parent().connect("no_health", self, "_on_no_health")


func _on_no_health() -> void:
	Lobby.emit_signal("gooey_god_dead")
