extends Component


func _ready():
	parent_entity.connect("destroyed", self , "_on_destroyed")


func _on_destroyed(id: int, of_old_age: bool) -> void:
	if Lobby.is_host:
		PacketSender.request_deactivate_arcane_wall(parent_entity.get_creator_id(), true)
