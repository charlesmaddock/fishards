extends Component
class_name Grab
var COMPONENT_TYPE: int = Globals.ComponentTypes.Grab


onready var grabArea: Area = $GrabArea 
onready var animationPlayer: AnimationPlayer = $AnimationPlayer 
onready var solidHitRayDectector: RayCast = $SolidHitRayDectector 
onready var solidHitRayDectector2: RayCast = $SolidHitRayDectector2
export(NodePath) var grab_hit_path
var grabbed_entities_ids: Array = []
var invert_grab: bool = false
var original_pos: Vector3


func _ready():
	grabArea.connect("area_entered", self, "_on_grab_area_collided")
	grabArea.connect("body_entered", self, "_on_grab_area_collided")
	animationPlayer.connect("animation_finished", self, "_on_grab_anim_finished")
	Lobby.connect("destroy_entity", self, "_on_entity_destroyed")
	
	grabArea.transform.origin = Vector3.ZERO
	
	animationPlayer.play("grab")
	animationPlayer.set_speed_scale(0.77)
	parent_entity.set_age_limit(animationPlayer.get_current_animation_length() + 1)
	
	# Only the host calculates grabbed positions
	if Lobby.is_host == false:
		set_process(false)


func _process(_delta: float) -> void:
	var room_node = Util.get_room_node()
	if room_node != null:
		if invert_grab:
			var grab_relative_pos: Vector3 = grabArea.global_transform.origin - parent_entity.global_transform.origin
			var player_entity = room_node.get_entity(parent_entity.get_creator_id(), "grab effect own player")
			if player_entity != null:
				var inverse_position: Vector3 = player_entity.get_pos().linear_interpolate(original_pos - grab_relative_pos, _delta * 24)
				player_entity.set_position(inverse_position)
		
		for grabbed_entity_id in grabbed_entities_ids:
			if grabbed_entity_id != -1:
				var grabbed_entity = room_node.get_entity(grabbed_entity_id, "grab effect other player")
				if grabbed_entity != null:
					var grabbed_pos: Vector3 = grabbed_entity.get_pos().linear_interpolate(grabArea.global_transform.origin, _delta * 24)
					grabbed_pos.y = 0
					grabbed_entity.set_position(grabbed_pos)


# Destroyed entities must be removed from grabbed entities
func _on_entity_destroyed(entity_id: int) -> void:
	if entity_id == parent_entity.get_creator_id():
		grabbed_entities_ids.clear()
	
	for id in grabbed_entities_ids:
		if entity_id == id:
			var index: int = grabbed_entities_ids.find(entity_id)
			grabbed_entities_ids.remove(index)
			break


# Stop settings grabbed positions
func _on_grab_anim_finished(_anim_name: String) -> void:
	self.visible = false
	set_process(false)


func _on_grab_area_collided(area) -> void:
	var grabbed_entity = Util.get_entity_from_area(area)
	if grabbed_entity != null:
		
		if (get_node(grab_hit_path).is_playing() == false && grabbed_entity.get_id() != parent_entity.get_creator_id()):
			get_node(grab_hit_path).play()
		
		if grabbed_entity.get_type() == Globals.EntityTypes.ENVIRONMENT && grabbed_entity.get_subtype() == Globals.EnvironmentTypes.FISH_BALL:
			var res = parent_entity.transform.basis.z * -5
			res.y = 0
			grabbed_entity.add_force(res)
		elif grabbed_entity.get_type() == Globals.EntityTypes.ENVIRONMENT && grabbed_entity.get_subtype() != Globals.EnvironmentTypes.DUMMY && grabbed_entity.get_subtype() != Globals.EnvironmentTypes.STRONG_DUMMY:
			hit_solid(area)
		elif grabbed_entity.get_type() == Globals.EntityTypes.PLAYER && grabbed_entity.get_id() != parent_entity.get_creator_id():
			var added = try_add_to_grabbed(grabbed_entity)
			if added == true && parent_entity.get_creator_id() == SteamValues.STEAM_ID:
				AchievementHandler.inc_grabs()
		elif grabbed_entity.get_type() == Globals.EntityTypes.ENVIRONMENT && grabbed_entity.get_subtype() == Globals.EnvironmentTypes.DUMMY && grabbed_entity.get_subtype() != Globals.EnvironmentTypes.STRONG_DUMMY:
			try_add_to_grabbed(grabbed_entity)
	
	elif area is StaticBody:
		hit_solid(area)


func hit_solid(hit_area: Area) -> void:
	if grabbed_entities_ids.size() == 0:
		grabbed_entities_ids.append(-1)
		if solidHitRayDectector.get_collider() != null:
			invert_grab = true
			var hit_point = solidHitRayDectector.get_collision_point()
			original_pos = hit_point
		elif solidHitRayDectector2.get_collider() != null:
			invert_grab = true
			var hit_point = solidHitRayDectector2.get_collision_point()
			original_pos = hit_point


func try_add_to_grabbed(entity: Entity) -> bool:
	var id = entity.get_id()
	var player_component = entity.get_component_of_type(Globals.ComponentTypes.Player)
	if player_component != null:
		if player_component.is_grabbed == true:
			return false
	
	if grabbed_entities_ids.size() == 0 && grabbed_entities_ids.find(id) == -1 && entity.is_grabbed == false:
		var time_left: float = animationPlayer.get_current_animation_length() - animationPlayer.get_current_animation_position()
		if player_component != null:
			player_component.set_is_grabbed(true, time_left)
		
		grabbed_entities_ids.append(id)
		entity.emit_signal("took_damage", 3, parent_entity)
		return true
	return false

