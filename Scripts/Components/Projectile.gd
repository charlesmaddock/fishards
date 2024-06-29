extends SpatialComponent
class_name Projectile
var COMPONENT_TYPE: int = Globals.ComponentTypes.Projectile


"""
Moves an entity in the direction it is rotated with a given speed
and does damage when hit
"""


export var speed: int = 6
export(Array, NodePath) var play_on_spawn_particles: Array

var _reflect_amount: int = 0
var _spell_caster_team_name: String
var _direction: Vector3
var _collided: bool = false


func get_direction() -> Vector3:
	return _direction


func reflect(new_dir: Vector3, new_caster_id: int = -1):
	# In the old game a new fireball was created, so this replicates that
	parent_entity.set_age(0)
	
	var reflect_sound = $Reflect
	if reflect_sound != null:
		reflect_sound.play()
	
	_reflect_amount += 1
	if _reflect_amount > 4:
		PacketSender.host_broadcast_destroy_entity(parent_entity.get_id())
	
	_direction = new_dir.normalized() * speed
	_direction.y = 0
	var rot = Vector2(_direction.x, _direction.z).angle_to(Vector2.DOWN)
	parent_entity.set_rot(rot)
	
	parent_entity.set_creator_id(new_caster_id)
	var new_team = Lobby.get_team_info_from_player_id(new_caster_id).duplicate(true)
	
	if new_team.empty() == false:
		if new_team.name == _spell_caster_team_name:
			_spell_caster_team_name = ""
		else:
			_spell_caster_team_name = new_team.name
	else:
		_spell_caster_team_name = ""


func init_spell(direction: Vector2, caster_team: String) -> void:
	_spell_caster_team_name = caster_team
	_direction = Vector3(direction.x, 0, direction.y).normalized() * speed


func _ready():
	parent_entity.get_area().connect("area_entered", self, "_on_entity_collided")
	parent_entity.get_area().connect("body_entered", self, "_on_entity_collided")
	parent_entity.broadcast_transform = false
	for node_path in play_on_spawn_particles:
		var particle_system: Particles = get_node(node_path)
		particle_system.emitting = true


# Since this happens for host and normal players it can update in all clients.
func _physics_process(_delta: float):
	parent_entity.add_direction(_direction)


func _on_entity_collided(area_or_body):
	if _collided == false:
		var entity: Entity = Util.get_entity_from_area(area_or_body)
		if entity != null:
			var on_same_team: bool = false
			if entity.get_type() == Globals.EntityTypes.PLAYER:
				on_same_team = Lobby.is_on_same_team_as(entity.get_id(), _spell_caster_team_name)
			
			#print("on_same_team false?: ", on_same_team)
			#print("not creator: ", entity.get_id() != parent_entity.get_creator_id())
			#print("no reflect? ", entity.get_component_of_type(Globals.ComponentTypes.ReflectProjectiles) == null)
			if on_same_team == false && entity.get_id() != parent_entity.get_creator_id() && entity.get_component_of_type(Globals.ComponentTypes.ReflectProjectiles) == null && (entity.get_type() != Globals.EntityTypes.SPELL || entity.get_type() == Globals.EntityTypes.SPELL && entity.get_subtype() == Globals.SpellTypes.TOTEM):
				PacketSender.host_broadcast_destroy_entity(parent_entity.get_id())
				_collided = true
				return
		
		if area_or_body is StaticBody:
			_collided = true
			PacketSender.host_broadcast_destroy_entity(parent_entity.get_id())

