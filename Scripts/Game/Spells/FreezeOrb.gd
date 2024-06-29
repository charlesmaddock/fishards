extends Component


func _ready():
	parent_entity.connect("destroyed", self, "_on_destroyed")


func _on_destroyed(_id, _of_old_age):
	# Get all values
	var creator_id: int = parent_entity.get_creator_id()
	
	var team_name: String = ""
	var player_team = Lobby.get_team_info_from_player_id(creator_id)
	if player_team.empty() == false:
		team_name = player_team["name"]
	
	var spell_type = Globals.SpellTypes.FREEZE_AREA
	var spell_id = Util.generate_id(Globals.EntityTypes.SPELL, spell_type)
	var pos: Vector3 = parent_entity.get_pos()
	var dir: Vector2 = Vector2.ZERO
	# Send packet
	PacketSender.spawn_spell(creator_id, team_name, spell_id, spell_type, pos, dir)
