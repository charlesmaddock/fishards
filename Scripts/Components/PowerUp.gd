extends SpatialComponent
class_name PowerUp
var COMPONENT_TYPE: int = Globals.ComponentTypes.PowerUp


enum power_types { HEALTH, RAPID_FIRE, SPEED, CLONE }
export(power_types) var power_type: int


onready var particles = $Particles


func _ready():
	parent_entity.get_area().connect("area_entered", self, "_on_entity_collided")


func _on_entity_collided(area: Area):
	var hit_entity: Entity = Util.get_entity_from_area(area)

	if hit_entity != null && Lobby.is_host:
		if power_type == power_types.HEALTH:
			hit_entity.emit_signal("add_health", 30)
		elif power_type == power_types.RAPID_FIRE:
			PacketSender.host_set_is_OP(hit_entity.get_id(), 6, true)
		elif power_type == power_types.SPEED:
			var player = hit_entity.get_component_of_type(Globals.ComponentTypes.Player)
			if player != null:
				player.set_speed_modifier("speed", 2, 6)
		elif power_type == power_types.CLONE:
			var players_node: Players = Util.get_players_node()
			var my_team = Lobby.get_team_info_from_player_id(hit_entity.get_id())
			var player = hit_entity.get_component_of_type(Globals.ComponentTypes.Player)
			if my_team.empty() == false && player != null && players_node != null && Lobby.player_is_in_temp_bot(hit_entity.get_id()) == false:
				var spawn_point = hit_entity.get_pos() + Vector3((Util.rand.randf() - 0.5) * 4, 0, (Util.rand.randf() - 0.5) * 4)
				players_node.host_spawn_temp_bot(my_team.name, Globals.PlayerTypes.MEDIUM_BOT, spawn_point, player)
				
				var clone_from_new_pos = hit_entity.get_pos() + Vector3((Util.rand.randf() - 0.5) * 4, 0, (Util.rand.randf() - 0.5) * 4)
				hit_entity.set_position(clone_from_new_pos)
				PacketSender.update_entity_pos_directly(hit_entity.get_id(), clone_from_new_pos)
		
		#print("[Despawn, Sending packet]: Removing power up entity with id ", parent_entity.get_id())
		PacketSender.host_broadcast_destroy_entity(parent_entity.get_id())
