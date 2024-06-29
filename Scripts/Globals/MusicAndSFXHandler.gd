extends Node


enum tracks {
	MAIN_MENU,
	MAIN_THEME,
	TROPIC1,
	ICE1,
	ICE2,
	LAVA1,
	LAVA2
}


enum sounds {
	CLICK,
	HOVER,
	COUNT_DOWN,
	COUNT_DOWN_GO,
	WIN,
	LOSE,
	ELEMENT_PICKUP,
	ELEMENT_DROP,
	SPELL_SELECTED,
	SPELL_EMPTY,
	ELEMENT_SELECT,
	NEW_ELEMENTS,
	WIN_SCREEN,
	KICKED,
	SENSEI_GREETINGS,
	SENSEI_HAPPY1,
	SENSEI_HAPPY2,
	SENSEI_HAPPY3,
	SENSEI_ANGRY1,
	SENSEI_ANGRY2,
	SENSEI_ANGRY3,
	SENSEI_NEUTRAL1,
	SENSEI_NEUTRAL2,
	SENSEI_NEUTRAL3,
	SENSEI_NEUTRAL4,
	SENSEI_NEUTRAL5,
	SENSEI_NEUTRAL6,
}


var soundtrack_paths: Dictionary = {
	tracks.MAIN_MENU: preload("res://Assets/Music/MainMenu.mp3"),
	tracks.MAIN_THEME: preload("res://Assets/Music/MainTheme(OntoLand).mp3"),
	tracks.TROPIC1: preload("res://Assets/Music/Tropic1(TheLostWall).mp3"),
	tracks.ICE1: preload("res://Assets/Music/ice fast.mp3"),
	tracks.ICE2: preload("res://Assets/Music/ice slow.mp3"),
	tracks.LAVA1: preload("res://Assets/Music/lava fast.mp3"),
	tracks.LAVA2: preload("res://Assets/Music/lava slow.mp3"),
}


var sound_paths: Dictionary = {
	sounds.CLICK: preload("res://Assets/Sounds/click.wav"),
	sounds.HOVER: preload("res://Assets/Sounds/menu hover.wav"),
	sounds.COUNT_DOWN: preload("res://Assets/Sounds/count down.wav"),
	sounds.COUNT_DOWN_GO: preload("res://Assets/Sounds/count down go.wav"),
	sounds.WIN: preload("res://Assets/Sounds/win.wav"),
	sounds.LOSE: preload("res://Assets/Sounds/lose.wav"),
	sounds.ELEMENT_PICKUP: preload("res://Assets/Sounds/element pickup.wav"),
	sounds.ELEMENT_DROP: preload("res://Assets/Sounds/element drop.wav"),
	sounds.SPELL_SELECTED: preload("res://Assets/Sounds/spell select.wav"),
	sounds.SPELL_EMPTY: preload("res://Assets/Sounds/empty spell.wav"),
	sounds.ELEMENT_SELECT: preload("res://Assets/Sounds/element select.wav"),
	sounds.NEW_ELEMENTS: preload("res://Assets/Sounds/random element change.wav"),
	sounds.KICKED: preload("res://Assets/Sounds/kicked.wav"),
	sounds.WIN_SCREEN: preload("res://Assets/Sounds/win screen.wav"),
	sounds.SENSEI_GREETINGS: preload("res://Assets/Sounds/Sensei/greetings1.wav"),
	sounds.SENSEI_HAPPY1: preload("res://Assets/Sounds/Sensei/happy1.wav"),
	sounds.SENSEI_HAPPY2: preload("res://Assets/Sounds/Sensei/happy2.wav"),
	sounds.SENSEI_HAPPY3: preload("res://Assets/Sounds/Sensei/happy3.wav"),
	sounds.SENSEI_ANGRY1: preload("res://Assets/Sounds/Sensei/angry1.wav"),
	sounds.SENSEI_ANGRY2: preload("res://Assets/Sounds/Sensei/angry2.wav"),
	sounds.SENSEI_ANGRY3: preload("res://Assets/Sounds/Sensei/angry3.wav"),
	sounds.SENSEI_NEUTRAL1: preload("res://Assets/Sounds/Sensei/neutral1.wav"),
	sounds.SENSEI_NEUTRAL2: preload("res://Assets/Sounds/Sensei/neutral2.wav"),
	sounds.SENSEI_NEUTRAL3: preload("res://Assets/Sounds/Sensei/neutral3.wav"),
	sounds.SENSEI_NEUTRAL4: preload("res://Assets/Sounds/Sensei/neutral4.wav"),
	sounds.SENSEI_NEUTRAL5: preload("res://Assets/Sounds/Sensei/neutral5.wav"),
	sounds.SENSEI_NEUTRAL6: preload("res://Assets/Sounds/Sensei/neutral6.wav"),
}


onready var MusicPlayer: AudioStreamPlayer = $MusicPlayer
onready var SFXPlayer: AudioStreamPlayer = $SFXPlayer
onready var SFXPlayerBackup: AudioStreamPlayer = $SFXPlayerBackup
onready var SFXPlayerBackup2: AudioStreamPlayer = $SFXPlayerBackup2
onready var SFXPlayerBackup3: AudioStreamPlayer = $SFXPlayerBackup3
onready var SFXPlayerBackup4: AudioStreamPlayer = $SFXPlayerBackup4
onready var SFXPlayerBackup5: AudioStreamPlayer = $SFXPlayerBackup5
onready var tween_out = get_node("Tween")


var music_volume_db = -5
var transition_duration = 1


func set_upcoming_soundtrack_map_path(path: String) -> void:
	MusicPlayer.stop()
	var current_map: int = -1
	for map_scene_key in GamemodeValues.map_scenes:
		for map_size_key in GamemodeValues.map_scenes[map_scene_key]:
			for map_size_variant in GamemodeValues.map_scenes[map_scene_key][map_size_key]:
				if map_size_variant == path:
					current_map = map_scene_key
	
	var available_tracks: Array = GamemodeValues.map_sound_tracks[current_map]
	var sound_nr = available_tracks[Util.rand.randi_range(0, available_tracks.size() - 1)]
	MusicPlayer.stream = soundtrack_paths[sound_nr]


func play_current_soundtrack() -> void:
	MusicPlayer.volume_db = music_volume_db
	MusicPlayer.play()


func play_track(track_nr: int) -> void:
	MusicPlayer.stream = soundtrack_paths[track_nr]
	MusicPlayer.volume_db = music_volume_db
	MusicPlayer.play()


func stop_current_track() -> void:
	if tween_out != null:
		MusicPlayer.volume_db = -90
		# tween music volume down to 0
		#tween_out.interpolate_property(MusicPlayer, "volume_db", music_volume_db, -90, transition_duration, 1, Tween.EASE_IN, 0)
		#tween_out.start()


func play_sound(sound_nr: int) -> void:
	if SFXPlayer.playing == false:
		SFXPlayer.stream = sound_paths[sound_nr]
		SFXPlayer.play()
	elif SFXPlayerBackup.playing == false:
		SFXPlayerBackup.stream = sound_paths[sound_nr]
		SFXPlayerBackup.play()
	elif SFXPlayerBackup2.playing == false:
		SFXPlayerBackup2.stream = sound_paths[sound_nr]
		SFXPlayerBackup2.play()
	elif SFXPlayerBackup3.playing == false:
		SFXPlayerBackup3.stream = sound_paths[sound_nr]
		SFXPlayerBackup3.play()
	elif SFXPlayerBackup4.playing == false:
		SFXPlayerBackup4.stream = sound_paths[sound_nr]
		SFXPlayerBackup4.play()
	else:
		SFXPlayerBackup5.stream = sound_paths[sound_nr]
		SFXPlayerBackup5.play()
		print("Warning: All SFX players are occupied.")
