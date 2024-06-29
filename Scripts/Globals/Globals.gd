extends Node

var _app_mode: int = AppModes.RELEASE

# Spell _icons
export var fireball_icon: Texture 
export var meteor_icon: Texture
export var push_icon: Texture
export var dive_icon: Texture
export var freeze_icon: Texture
export var dash_icon: Texture
export var blast_icon: Texture
export var transform_icon: Texture
export var crab_icon: Texture
export var wall_icon: Texture
export var wildfire_icon: Texture
export var heal_icon: Texture
export var totem_icon: Texture
export var beam_icon: Texture
export var grab_icon: Texture
export var ice_ball_icon: Texture
export var empty_spell_icon: Texture

# Element _icons
export var empty_icon: Texture
export var fire_icon: Texture
export var water_icon: Texture
export var earth_icon: Texture
export var arcane_icon: Texture
export var goo_icon: Texture

# Contants TODO: Move to room settings
const PLAYER_SPEED: float = 4.5
const SPELL_CAST_RANGE: float = 11.0
const SPELL_CAST_MIN_RANGE: float = 6.0
const FIXED_SPELL_RANGE: float = 6.0
const TOTEM_RANGE: float = 4.0
const DIVE_RANGE: float = 8.0
const ROCK_DASH_FORCE: float = 47.0
const GROUND_FRICTION: float = 1.1 # 1 is no friction, 1.03 is like ice, 1.8 gives super high friction
const TOTEM_UPGRADE_DIST: float = 5.0
const METEOR_SPEED = 10
const MAX_FORCE: float = 80.0

var INVIS_SPEED: float = 1.8
var FLOP_AROUND_SPEED: float = 1.4
var AIM_SPEED: float = 1


export(Color) var RED_TEAM_COLOR
export(Color) var BLUE_TEAM_COLOR


const ADJECTIVES = [
  "Anxious", "Naughty", "Stubborn", "Sensitive", "Intelligent", "Nice", "Emotional", "Nervous", "Mean", "Distracted", "Dishonest", "Rude", "Discreet", "Crazy", "Cheeky", "Cheerful",
  "Energetic", "Untidy", "Pessimistic", "Optimistic", "Unpleasant", "Talkative", "Calm", "Passionate", "Proud", "Sincere", "Lazy", "Lively", "Funny", "Silly", "Shy", "Determined", "Versatile", "Sociable", "Worried", "Thoughtful", "Humble", "Friendly",
  "Frank", "Obedient", "Honest", "Fearless", "Unfriendly", "Generous", "Compassionate", "Disobedient", "Selfish", "Imaginative", "Placid", "Jealous", "Helpful", "Enthusiastic", "Persistent", "Sensible", "Rational", "Reserved", "Bossy", "Plucky",
  "Patient", "Impatient", "Easygoing", "Careless", "Messy", "Creative", "Faithful", "Kind", "Courageous", "Loyal", "Modest", "Tidy", "Confident", "Attentive", "Loving", "Reliable", "Scared", "Conscientious",
  "Careful", "Gentle", "Neat", "Dynamic", "Impartial", "Supportive", "Timid", "Intellectual", "Brave", "Ambitious", "Polite", "Happy", "Romantic", "Diplomatic", "Courteous", "Humorous", "Popular", "Smart", "Serious", "Hypocritical", "Adventurous" 
]
const FISH_SPECIES = [
  "Anchovy", "Barb", "Barbel", "Barfish", "Bass", "Batfish", "Boxfish", "Carp", "Catfish", "Cobbler", "Cod", "Cowfish", "Dace", "Dogfish", "Eel", "Gar", "Garpike",
  "Ghoul", "Grunt", "Gulper", "Guppy", "Herring", "Jawfish", "Koi", "Loach", "Longfin", "Marlin", "Mudfish", "Mullet", "Oarfish", "Oilfish", "Perch", "Pigfish", "Pike", "Piranha", "Poacher", "Pupfish",
  "Ragfish","Ratfish","Ray","Redfish","Salmon","Sardine","Sawfish","Shark","Smelt","Snapper","Sunfish","Trout","Tuna","Fish","Fishy","Sharky","Octopus","Swordfish","Whale","Fish",
]
const EXTENSIONS = ["Girl", "Boy", "Dude", "Bro", "Guy", "Master", "Noob", "Slayer", "Killer", ""]
const NAMES = ["Mary", "Florence", "Annie", "Edith", "Alice", "Elizabeth", "Elsie", "Dorothy", "Ethel", "William", "John", "George", "Thomas", "James", "Arthur", "Frederick", "Charles", "Albert", "Robert", "Joseph", "Sigge", "Gabriel", "Zeo", "Ludde", "Hidin' Harry", "Babyfresh", "Fishmcgee"]


signal main_menu_ready()


# Enums
enum PacketTypes {
	HANDSHAKE,
	PING,
	PING_RES,
	KICK_PLAYER,
	REQUEST_JOIN_LOBBY,
	JOIN_LOBBY_SUCCESS_RESPONSE,
	JOIN_LOBBY_FAIL_RESPONSE,
	START_LOADING_GAME,
	SET_GAMEMODE_DATA,
	CHANGE_GAME_STATE,
	COUNTDOWN,
	BROADCAST_GAMEOVER_PANEL,
	CHANGE_TEAM,
	ROOM_SETTINGS,
	UPDATE_LOBBY_PLAYERS,
	SHOW_LOADING_SCREEN,
	DONE_LOADING_SCENES,
	SET_DONE_LOADING,
	ALL_ROUNDS_OVER,
	START_SHRINK,
	UPDATE_ENTITY_POS,
	UPDATE_PLAYER_TARGET_POS,
	UPDATE_PLAYER_ROTATION,
	UPDATE_PLAYER_STANCE,
	TRIGGER_PLAYER_ANIMATION,
	UPDATE_ENTITY_TRANSFORM,
	UPDATE_HEALTH,
	UPDATE_MAX_HEALTH,
	PLAYER_DEATH,
	RESPAWN_PLAYER,
	REQUEST_RESPAWN_PLAYER,
	WINNER_DISPLAY,
	REQUEST_LEADERBOARD,
	SET_LEADERBOARD,
	SET_SCORE,
	SET_IS_OP,
	SET_IS_LOSER,
	DESTROY_ENTITY,
	SPAWN_PLAYER,
	SPAWN_ENVIRONMENT,
	SPAWN_SPELL,
	LAUNCH,
	REFLECT_SPELL,
	TRANSFORM_INTO,
	TRIGGER_PARTICLE_EFFECT,
	BROADCAST_FREEZE_INFO,
	DEACTIVATE_SPELL,
	ELEMENTS_CHANGED,
	NEW_WAVE,
	REQUEST_JOIN_MID_GAME,
	REQUEST_UPDATE_PLAYER_INFO,
	REQUEST_UPDATE_PLAYER_MOVEMENT,
	REQUEST_CAST_DIRECTIONAL_SPELL,
	REQUEST_CAST_POSITIONAL_SPELL,
	REQUEST_CAST_PARENTED_SPELL,
	REQUEST_ROCK_DASH,
	REQUEST_CAST_TRANSFORM_INTO,
	REQUEST_UPDATE_ACTIVE_SPELL,
	REQUEST_JOIN_TEAM,
	REQUEST_DEACTIVATE_ARCANE_WALL,
	SEND_CHAT_MESSAGE,
}


enum Channels {
	LOBBY,
	IN_GAME
}


enum AppModes {
	DEMO,
	RELEASE,
	DEVELOPMENT,
}


enum ElementModes {
	DEFAULT,
	RANDOM,
	TIMED
}


enum PlayerStances {
	FLOP_AROUND,
	AIM,
	BOMBARD
}


enum PlayerAnimations {
	HURT,
	DEATH,
	PUSHED,
	LAUNCHED,
	LAUNCHED_RECOVER,
	START_ROCK_DASH,
	END_ROCK_DASH,
	DIVE_DOWN,
	DIVE_UP,
	DASH_BEAM_KICK,
	ENTER_WATER,
	EXIT_WATER,
	SPIN,
	START_FLOP,
	END_FLOP,
	DANCE_1,
	BACKFLIP,
	FLOP_ONCE,
}


enum PlayerDeathTypes {
	NORMAL,
	DROWN,
	EXPLODE,
	BURN,
}


enum ParticleEffects {
	FIREBLAST_HURT,
	WILDFIRE_HURT,
	FIRE_HURT,
	WATER_SPLASH,
	LAVA_SPLASH,
	HEALED,
	METEOR_MUZZLE,
	BURNING,
	DASH_BEAM_HURT,
	PUSHED_TRAIL,
	PUSHED_LANDING,
}


enum Elements {
	NONE,
	FIRE,
	WATER,
	EARTH,
	ARCANE,
	GOO
}


enum EntityTypes {
	UNDEFINED = -1,
	SPELL = 0,
	ENVIRONMENT = 1,
	PLAYER = 2,
}


enum EnvironmentTypes {
	BIG_ROCK_1,
	BIG_ROCK_2,
	PALM_TREE,
	CRAB,
	METEOR_UP,
	BIG_SPLASH,
	SMALL_SPLASH,
	DEAD_TREE,
	LEAF_TREE,
	TURRET,
	SPEED_POWERUP,
	HEALTH_POWERUP,
	RAPIDFIRE_POWERUP,
	CLONE_POWERUP,
	INVISIBILITY_BALL,
	WATER_ROCK_1,
	WATER_ROCK_2,
	WATER_ROCK_3,
	WATER_ROCK_4,
	WATER_ROCK_5,
	WATER_ROCK_6,
	ROCK_1,
	ROCK_2,
	ROCK_3,
	ROCK_4,
	ROCK_5,
	ROCK_6,
	BURNT_TREE_1,
	GOOEY_GOD_STATUE,
	DUMMY,
	STRONG_DUMMY,
	FISH_BALL,
}


enum PlayerTypes {
	CLIENT,
	DUMB_BOT,
	EASY_BOT,
	MEDIUM_BOT,
	HARD_BOT,
	SQUISHARD,
	FIREARD,
	DASHARD,
	MEGADASHARD,
	GRABARD,
	ICEARD,
	CRABARD,
	PUSHARD,
	METEORARD,
}


# Contains the spawn chances
onready var RARE_ENV_TYPES = {
	EnvironmentTypes.BIG_ROCK_1: 0.1,
	EnvironmentTypes.BIG_ROCK_2: 0.25
}


# These are the names of the different components
enum ComponentTypes {
	Damage,
	EntityInfoPanel,
	Health,
	Kinematic,
	Knockback,
	Player,
	PlayerBot,
	Projectile,
	Sounds,
	SpellCaster,
	TrapOnCollide,
	PrettyDestroy,
	Rotation,
	SpellMarker,
	Crab,
	ReflectProjectiles,
	Meteor,
	ParticlePlayer,
	StillSolid,
	Turret,
	RockDashable,
	PowerUp,
	ChangeSpeedOnCollide,
	Launchable,
	Heal,
	SpellRecoil,
	ParentToCreator,
	Beam,
	Grab,
}


enum SpellTypes {
	NONE, #0
	FIREBALL, #1
	PUSH, #2
	METEOR, #3
	FIREBLAST, #4
	DIVE, #5
	ICE_BEAM, #6
	CRAB, #7
	DASH, #8
	INVISIBILITY, #9
	ARCANE_WALL, #10
	WILDFIRE, #11
	HEAL, #12
	TOTEM, #13
	DASH_BEAM, #14
	GRAB, #15
	ARCANE_WALL_PLACED, #16
	FREEZE_ORB, #17
	FREEZE_AREA, #18
	DIVE_STUN, #Bababoyi
}

# Note: cast_time should not be more than 1 sec, might be wierd since you can cast another spell while casting
onready var SpellCooldowns: Dictionary = {
	SpellTypes.NONE: 		{"cooldown": 0, "max_charges": 0, "hold_down": false},
	SpellTypes.FIREBALL: 	{"cooldown": 0.3, "max_charges": 1, "hold_down": false},
	SpellTypes.PUSH: 		{"cooldown": 5, "max_charges": 1, "hold_down": false},
	SpellTypes.METEOR: 		{"cooldown": 4, "max_charges": 1, "hold_down": false},
	SpellTypes.FIREBLAST: 	{"cooldown": 4, "max_charges": 1, "hold_down": false},
	SpellTypes.DIVE: 		{"cooldown": 8, "max_charges": 1, "hold_down": false, "between_charge_cooldown": 0.7},
	SpellTypes.ICE_BEAM: 	{"cooldown": 1.5, "max_charges": 1, "hold_down": true},
	SpellTypes.CRAB: 		{"cooldown": 2, "max_charges": 3, "hold_down": false},
	SpellTypes.DASH: 		{"cooldown": 2.4, "max_charges": 1, "hold_down": false},
	SpellTypes.INVISIBILITY:{"cooldown": 10, "max_charges": 1, "hold_down": false},
	SpellTypes.ARCANE_WALL: {"cooldown": 12, "max_charges": 1, "hold_down": true},
	SpellTypes.WILDFIRE: 	{"cooldown": 1.5, "max_charges": 1, "hold_down": true},
	SpellTypes.HEAL: 		{"cooldown": 8, "max_charges": 1, "hold_down": false, "cast_time": 0.5},
	SpellTypes.TOTEM: 		{"cooldown": 12, "max_charges": 1, "hold_down": false},
	SpellTypes.DASH_BEAM: 	{"cooldown": 3, "max_charges": 1, "hold_down": false, "cast_time": 0.23},
	SpellTypes.GRAB: 		{"cooldown": 5, "max_charges": 1, "hold_down": false},
	SpellTypes.FREEZE_ORB:  {"cooldown": 10, "max_charges": 1, "hold_down": false}
}

# TODO: Make the spellcaster use this
onready var SpellCompositions: Dictionary = {
	SpellTypes.FIREBALL: 	[Globals.Elements.FIRE, Globals.Elements.FIRE],
	SpellTypes.PUSH: 		[Globals.Elements.FIRE, Globals.Elements.WATER],
	SpellTypes.METEOR:	 	[Globals.Elements.FIRE, Globals.Elements.EARTH],
	SpellTypes.FIREBLAST: 	[Globals.Elements.FIRE, Globals.Elements.ARCANE],
	SpellTypes.WILDFIRE: 	[Globals.Elements.FIRE, Globals.Elements.GOO],
	SpellTypes.ICE_BEAM: 	[Globals.Elements.WATER, Globals.Elements.WATER],
	SpellTypes.DIVE:	 	[Globals.Elements.WATER, Globals.Elements.EARTH],
	SpellTypes.FREEZE_ORB: 	[Globals.Elements.WATER, Globals.Elements.ARCANE],
	SpellTypes.HEAL:	 	[Globals.Elements.WATER, Globals.Elements.GOO],
	SpellTypes.DASH: 		[Globals.Elements.EARTH, Globals.Elements.EARTH],
	SpellTypes.INVISIBILITY:[Globals.Elements.EARTH, Globals.Elements.ARCANE],
	SpellTypes.TOTEM: 		[Globals.Elements.EARTH, Globals.Elements.GOO],
	SpellTypes.ARCANE_WALL: [Globals.Elements.ARCANE, Globals.Elements.ARCANE],
	SpellTypes.DASH_BEAM: 	[Globals.Elements.ARCANE, Globals.Elements.GOO],
	SpellTypes.GRAB: 		[Globals.Elements.GOO, Globals.Elements.GOO],
	
}

# Must be synced with the physics 3d layer in project.godot
enum ColBits {
	KNOCKBACKABLE = 0,
	HURTABLE,
	SOLID,
	MAP,
	INSTAKILL,
	PROJECTILE,
	PLAYER,
	DAMAGE,
	BLOCK_DAMAGE,
	AIM_PLAIN,
	BARRIER,
}


enum UIInteractionModes {
	GAMEPLAY,
	UI
}
var ui_interaction_mode = UIInteractionModes.GAMEPLAY


func set_ui_interaction_mode(mode: int) -> void: 
	ui_interaction_mode = mode
	if mode == UIInteractionModes.GAMEPLAY:
		CursorHandler.set_cross_hair()
	elif mode == UIInteractionModes.UI:
		CursorHandler.set_default()


func EnvironmentInfo(type: int, rot: float, pos: Vector3) -> Dictionary:
	var environment_info: Dictionary = {
		"type": type,
		"rot": rot,
		"pos": pos,
	}
	return environment_info


func PlayerInfo(id: int, name: String, pos: Vector3, player_type: int, skin: Dictionary, preferred_team: String, available_elements: Array, cloned_from_id: int, rank: int = -1) -> Dictionary:
	var player_info: Dictionary = {
		"id": id,
		"name": name,
		"spwnpnt": pos,
		"plyr_type": player_type,
		"skin": skin,
		"team": preferred_team,
		"elmts": available_elements,
		"clone": cloned_from_id,
		"rank": rank
	}
	return player_info


# Scene references
const ROOM_SCENE: String = "res://Scenes/Game/Room.tscn"


# Menu scenes
const MAIN_MENU_SCENE: String = "res://Scenes/MainMenu/MainMenu.tscn"
const LOBBY_SCENE: String = "res://Scenes/MainMenu/Lobby.tscn"
const LOADING_LOBBY_UI: String = "res://Scenes/MainMenu/MainMenuUIChildren/LoadingLobbyUI.tscn"
const MAIN_MENU_UI: String = "res://Scenes/MainMenu/MainMenuUIChildren/MainMenuUI.tscn"
const PLAY_UI: String = "res://Scenes/MainMenu/MainMenuUIChildren/PlayUI.tscn"
const HOST_LOBBY_UI: String = "res://Scenes/MainMenu/MainMenuUIChildren/HostLobbyUI.tscn"
const JOIN_LOBBY_UI: String = "res://Scenes/MainMenu/MainMenuUIChildren/JoinLobbyUI.tscn"
const CONTROLS_UI: String = "res://Scenes/MainMenu/MainMenuUIChildren/ControlsUI.tscn"
const CUSTOMIZE_UI: String = "res://Scenes/MainMenu/MainMenuUIChildren/CustomizeUI.tscn"
const SETTINGS_UI: String = "res://Scenes/MainMenu/MainMenuUIChildren/SettingsUI.tscn"

var game_paused: bool = false
var in_single_player: bool = false
var in_game: bool = false
var play_splash_anim: bool = true

# Probably not the best practice but since scenes are swapped 
# it is easier to keep track of camera zoom in this global script
var camera_zoom_out_pos = Vector3(0, 90, 24)
var camera_zoom_in_pos = Vector3(0, 40, 3)
var camera_standard_rot = Vector3(-70, 0, 0)
var fishard_ui_zoom_pos = Vector3(-28.547, 8.58, 14.688)
var fishard_ui_rot = Vector3(-27.467, -10.159, -0.075)
var camera_lerp_to: Vector3 = camera_zoom_out_pos
var camera_lerp_to_rot: Vector3 = camera_standard_rot
# Before scene swap for instance
var prev_camera_pos: Vector3 = camera_zoom_out_pos

onready var camera: Camera = $Camera
var camera_offset: Vector3 = Vector3(0, 37.8, 28.8)
var camera_following: Entity = null
var camera_following_id: int = 0

export(PackedScene) var infoPopupScene


func _ready():
	camera.global_transform.origin = camera_zoom_out_pos
	#test_size()


func _process(delta: float) -> void:
	#packet_speed_test(delta)
	if camera_following != null:
		if Util.safe_to_use(camera_following) == true:
			var to_position: Vector3 = camera_following.get_pos() + camera_offset
			var lerp_pos: Vector3 = camera.global_transform.origin.linear_interpolate(to_position, delta * 16)
			camera.global_transform.origin = lerp_pos
		else:
			camera_following = null
			camera_following_id = 0


# Cursed af haha
func create_info_popup(title: String, desc: String) -> void:
	var popup = infoPopupScene.instance()
	popup.init_popup(title, desc)
	add_child(popup)


func toggle_stats_visible() -> void:
	var stats_node = get_node("/root/Room/Client/Stats")
	if stats_node != null:
		stats_node.set_process(!stats_node.is_processing())
		stats_node.visible = !stats_node.visible


func get_app_mode() -> int:
	return _app_mode


func get_spell_icon(spell: int) -> Texture:
	var spell_icons = {
		Globals.SpellTypes.NONE: empty_spell_icon,
		Globals.SpellTypes.FIREBALL: fireball_icon,
		Globals.SpellTypes.PUSH: push_icon,
		Globals.SpellTypes.METEOR: meteor_icon,
		Globals.SpellTypes.FIREBLAST: blast_icon,
		Globals.SpellTypes.DIVE: dive_icon,
		Globals.SpellTypes.ICE_BEAM: freeze_icon,
		Globals.SpellTypes.CRAB: crab_icon,
		Globals.SpellTypes.DASH: dash_icon,
		Globals.SpellTypes.INVISIBILITY: transform_icon,
		Globals.SpellTypes.ARCANE_WALL: wall_icon,
		Globals.SpellTypes.WILDFIRE: wildfire_icon,
		Globals.SpellTypes.HEAL: heal_icon,
		Globals.SpellTypes.TOTEM: totem_icon,
		Globals.SpellTypes.DASH_BEAM: beam_icon,
		Globals.SpellTypes.GRAB: grab_icon,
		Globals.SpellTypes.FREEZE_ORB: ice_ball_icon,
	}
	
	if spell_icons.has(spell):
		return spell_icons[spell]
	else:
		return empty_spell_icon


func get_element_icon(element: int) -> Texture:
	match element:
		Globals.Elements.FIRE:
			return fire_icon;
		Globals.Elements.WATER:
			return water_icon;
		Globals.Elements.EARTH:
			return earth_icon;
		Globals.Elements.ARCANE:
			return arcane_icon;
		Globals.Elements.GOO:
			return goo_icon;
	
	return empty_icon;


func set_camera_offset(offset: Vector3) -> void:
	camera_offset = offset
	camera.global_transform.origin = offset


func set_camera_following(entity_to_follow: Entity, reset_camera_pos: Vector3 = Vector3.DOWN) -> void:
	if Util.safe_to_use(entity_to_follow):
		camera_following = entity_to_follow
		camera_following_id = entity_to_follow.get_id()
		
		camera = get_viewport().get_camera()
		
		if entity_to_follow.get_type() == EntityTypes.PLAYER:
			var player_component = entity_to_follow.get_component_of_type(Globals.ComponentTypes.Player)
			if player_component != null:
				player_component.set_as_current_listener()
		
		if reset_camera_pos != Vector3.DOWN:
			camera.look_at_from_position(reset_camera_pos + camera_offset, reset_camera_pos, Vector3.UP)
	else:
		print("entity_to_follow wasn't safe to use")


func test_size() -> void:
	var packet: Dictionary = {
		"type": Globals.PacketTypes.SPAWN_SPELL,
		"player_id": Util.generate_id(),
		"team": "player_team",
		"spell_id": Util.generate_id(),
		"spell_type": Globals.SpellTypes.FIREBALL,
		"pos": Vector3.ZERO,
		"dir": Vector2.ZERO,
	}
	var byte_data: PoolByteArray = var2bytes(packet)
	
	var stream: StreamPeerBuffer = StreamPeerBuffer.new()
	stream.put_u8(Globals.PacketTypes.SPAWN_SPELL)
	stream.put_64(Util.generate_id())
	stream.put_string("player_team")
	stream.put_64(Util.generate_id())
	stream.put_u8(Globals.SpellTypes.FIREBALL)
	# Vector3
	stream.put_float(0)
	stream.put_float(0)
	stream.put_float(0)
	# Vector2
	stream.put_float(0)
	stream.put_float(0)
	
	print("Dictionary byte size: ", byte_data.size())
	print("Stream byte size: ", stream.get_size())


var iterations: float
var total_delta: float
var skip_first: int
func packet_speed_test(delta) -> void:
	skip_first += 1
	if skip_first > 4:
		if delta > 0.03:
			total_delta += delta
			iterations += 1.0
			print("delta_avg is: ", total_delta / iterations)
	
		"""
		for i in 3000:
			var packet: Dictionary = {
				"type": Globals.PacketTypes.SPAWN_SPELL,
				"player_id": Util.generate_id(),
				"team": "player_team",
				"spell_id": Util.generate_id(),
				"spell_type": Globals.SpellTypes.FIREBALL,
				"pos": Vector3.ZERO,
				"dir": Vector2.ZERO,
			}
			var byte_data: PoolByteArray = var2bytes(packet)
			var data: Dictionary = bytes2var(byte_data)
		
		for i in 3000:
			var stream: StreamPeerBuffer = StreamPeerBuffer.new()
			stream.put_u8(Globals.PacketTypes.SPAWN_SPELL)
			stream.put_64(Util.generate_id())
			stream.put_16("player_team".length())
			stream.put_string("player_team")
			stream.put_64(Util.generate_id())
			stream.put_u8(Globals.SpellTypes.FIREBALL)
			# Vector3
			stream.put_float(0)
			stream.put_float(0)
			stream.put_float(0)
			# Vector2
			stream.put_float(0)
			stream.put_float(0)
			
			var type = stream.get_8()
			var id = stream.get_64()
			var team_lgth = stream.get_16()
			var team = stream.get_string(team_lgth)
			var spell_id = stream.get_64()
			var spell_type = stream.get_8()
			var x = stream.get_float()
			var y = stream.get_float()
			var z = stream.get_float()
			
			var xdir = stream.get_float()
			var ydir = stream.get_float()
		"""


