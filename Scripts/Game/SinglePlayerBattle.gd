extends Spatial


onready var enter_area: Area = $EnterArea
onready var perimeter_animator: AnimationPlayer = $PerimeterAnim
onready var no_escape_perimeter_animator: AnimationPlayer = $NoEscapePerimeterAnim
onready var bot_spawn_pos: Spatial = $BotSpawnPos

export(Globals.PlayerTypes) var bot_type: int 
export(int) var amount_of_bots: int
export(int) var level: int
export(bool) var win_on_defeat_bots: bool

var bot_ids: Array
var spawned_bots: bool
var defeated_battle: bool


# Called when the node enters the scene tree for the first time.
func _ready():
	enter_area.connect("area_entered", self, "_on_enter_area_entered")
	Lobby.connect("player_killed", self, "_on_player_killed")
	Lobby.connect("player_respawn", self, "_on_respawn_player")
	get_node("NoEscapePerimeter").global_transform.origin.y = -10
	perimeter_animator.play("up")


func _on_enter_area_entered(area):
	if spawned_bots == false && defeated_battle == false:
		var enter_entity: Entity = Util.get_entity_from_area(area)
		if enter_entity != null:
			if enter_entity.get_type() == Globals.EntityTypes.PLAYER && enter_entity.get_subtype() == Globals.PlayerTypes.CLIENT:
				spawn_bots()


func spawn_bots() -> void:
	var players_node = Util.get_players_node()
	if players_node != null:
		print("Spawn bots in ", name)
		spawned_bots = true
		var spawn_pos: Vector3 = bot_spawn_pos.global_transform.origin
		spawn_pos.y = 0
		no_escape_perimeter_animator.play("up")
		for i in range(amount_of_bots):
			var new_id: int = players_node.host_spawn_temp_bot("Red Team", bot_type, spawn_pos)
			bot_ids.append(new_id)


func _on_player_killed(killed_id, killer_id, killed_with_spell):
	var index: int = bot_ids.find(killed_id)
	if bot_ids.find(killed_id) != -1:
		bot_ids.remove(index)
		PacketSender.host_broadcast_destroy_entity(killed_id)
	
	if killed_id == SteamValues.STEAM_ID:
		gameover()
	
	if bot_ids.empty() == true && spawned_bots == true && defeated_battle == false:
		fight_over()


func fight_over() -> void:
	print("Fight over in ", name)
	defeated_battle = true
	no_escape_perimeter_animator.play("disappear")
	perimeter_animator.play("disappear")
	
	if win_on_defeat_bots == true:
		Lobby.emit_signal("lobby_chat", "Sensei", "Wow, you did it, I guess you were the chosen one after all...")
		yield(get_tree().create_timer(4.2), "timeout")
		Lobby.emit_signal("lobby_chat", "Sensei", "Your reward is this: Try typing '/chosen_one'")


func gameover() -> void:
	print("Game over", name)
	if defeated_battle == false:
		spawned_bots = false
		no_escape_perimeter_animator.play("disappear")
		perimeter_animator.play("up")
		
		yield(get_tree().create_timer(2), "timeout")
		for id in bot_ids:
			PacketSender.host_broadcast_destroy_entity(id)
		
		bot_ids.clear()


func _on_respawn_player(player_id) -> void:
	if player_id == SteamValues.STEAM_ID && defeated_battle == true:
		var room_node = Util.get_room_node()
		if room_node != null:
			var player_e: Entity = room_node.get_entity(SteamValues.STEAM_ID)
			if player_e != null:
				var spawn_pos: Vector3 = bot_spawn_pos.global_transform.origin
				spawn_pos.y = 0
				player_e.set_position(spawn_pos)
