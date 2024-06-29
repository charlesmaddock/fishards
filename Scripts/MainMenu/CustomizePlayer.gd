extends Node

export(Array, Material) var palette_array

export(Array, Material) var skin_colors
export(Array, Material) var legs_colors
export(Array, Material) var mouth_colors
export(Array, Material) var eyes_colors

signal hat_set(hat)

enum HatTypes {
	NONE,
	TEST,
	FEZ,
	SAFARI,
	TOPHAT,
	VIKING,
	COOL,
	COOL_COLOURED,
	WIND,
	WALL,
	GOO,
	BEANIE,
	GOGGLES,
	MOHAWK,
	PLAGUE_DOCTOR,
	SNORKLE,
	SUNGLASSES,
	WINTER,
	CANNON,
	EYE,
	FEDORA,
	HALO,
	KNIGHT,
	ANGRY_BROWS,
	RHINO,
	SPIKY_HORNS,
	PIRATE,
	FROG,
	GOAT,
	HEART_BOBBERS,
	DISGUISE,
}

onready var hat_icons: Dictionary = {
	HatTypes.NONE: preload("res://Assets/Images/UI/GeneratedIcons/test.png"),
	HatTypes.TEST: preload("res://Assets/Images/UI/GeneratedIcons/test.png"),
}


var my_skin: Dictionary
onready var hurt_skin: Dictionary = {
	"mouth": palette_array.find(6),
	"eyes": palette_array.find(6),
	"skin": palette_array.find(6),
	"legs": palette_array.find(6)
}

func _ready():
	my_skin = {
		"skin"   : palette_array.find(skin_colors[0]),
		"legs"   : palette_array.find(legs_colors[0]),
		"mouth"  : palette_array.find(mouth_colors[0]),
		"eyes"   : palette_array.find(eyes_colors[0]),
		"inside" : 1,
		"hat"    : 0,
	}
	_load_customizations()


func generate_skin() -> Dictionary:
	var new_skin: Dictionary = {}
	new_skin["mouth"] = palette_array.find(mouth_colors[Util.rand.randi_range(0, mouth_colors.size()-1)])
	new_skin["eyes"] = palette_array.find(eyes_colors[0])
	new_skin["skin"] = palette_array.find(skin_colors[Util.rand.randi_range(0, skin_colors.size()-1)])
	new_skin["legs"] = palette_array.find(legs_colors[Util.rand.randi_range(0, legs_colors.size()-1)])
	#new_skin["hat"] = Util.rand.randi_range(0, 4)
	return new_skin


func SkinObj(mouth_color, eyes_color, skin_color, legs_color, hat: int = 0) -> Dictionary:
	var obj = {
		"mouth": palette_array.find(mouth_color),
		"eyes": palette_array.find(eyes_color),
		"skin": palette_array.find(skin_color),
		"legs": palette_array.find(legs_color),
		"hat": hat
	}
	return obj


func create_bot_skin(player_type: int, clone_from: Player) -> Dictionary:
	var skin: Dictionary = CustomizePlayer.generate_skin() if clone_from == null else clone_from.get_skin()
	match player_type:
		Globals.PlayerTypes.FIREARD:
			skin = SkinObj(mouth_colors[4], eyes_colors[0], skin_colors[7], palette_array[23])
		Globals.PlayerTypes.ICEARD:
			skin = SkinObj(palette_array[6], eyes_colors[0], palette_array[15], palette_array[17], HatTypes.WINTER)
		Globals.PlayerTypes.SQUISHARD:
			skin = SkinObj(palette_array[1], palette_array[20], palette_array[2], palette_array[3], HatTypes.COOL)
		Globals.PlayerTypes.DASHARD:
			skin = SkinObj(palette_array[2], palette_array[3], palette_array[2], palette_array[3], HatTypes.RHINO)
		Globals.PlayerTypes.MEGADASHARD:
			skin = SkinObj(palette_array[2], palette_array[3], palette_array[2], palette_array[3], HatTypes.RHINO)
		Globals.PlayerTypes.METEORARD:
			skin = SkinObj(mouth_colors[4], palette_array[24], palette_array[23], palette_array[2], HatTypes.VIKING)
		Globals.PlayerTypes.GRABARD:
			skin = SkinObj(mouth_colors[3], eyes_colors[0], skin_colors[0], skin_colors[0], HatTypes.GOO)
		
	return skin


# Just a fun lil thing I did to celebrate fixing seg fault, we can remove :D
func apply_damage_skin(entity: Entity, prev_skin: Dictionary, fishard_model: Spatial) -> void:
	apply_skin_to_fishard(entity, hurt_skin, fishard_model)


func apply_skin_to_fishard(entity: Entity, apply_skin: Dictionary, fishard_model: Spatial, team_name: String = "") -> Dictionary:
	var new_skin = apply_skin.duplicate()
	var ignore_team_color = false
	if entity != null:
		ignore_team_color = entity.get_subtype() != Globals.PlayerTypes.CLIENT && entity.get_subtype() != Globals.PlayerTypes.EASY_BOT && entity.get_subtype() != Globals.PlayerTypes.MEDIUM_BOT && entity.get_subtype() != Globals.PlayerTypes.HARD_BOT
		
	if apply_skin.has("mouth"):
		fishard_model.set_surface_material(0, palette_array[apply_skin["mouth"]])
	if apply_skin.has("eyes"):
		fishard_model.set_surface_material(1, palette_array[apply_skin["eyes"]])
	if apply_skin.has("legs"):
		fishard_model.set_surface_material(3, palette_array[apply_skin["legs"]])
	if apply_skin.has("inside"):
		fishard_model.set_surface_material(4, palette_array[apply_skin["inside"]])
	
	if team_name == "Red Team" && ignore_team_color == false:
		fishard_model.set_surface_material(2, palette_array[25])
		new_skin["skin"] = 25
	elif team_name == "Blue Team" && ignore_team_color == false:
		fishard_model.set_surface_material(2, palette_array[14])
		new_skin["skin"] = 14
	elif apply_skin.has("skin"):
		fishard_model.set_surface_material(2, palette_array[apply_skin["skin"]])
	
	return new_skin


func set_hat(hat: int) -> void:
	my_skin["hat"] = hat
	emit_signal("hat_set", hat)
	_save_customizations()


func get_hat() -> int:
	return my_skin["hat"]


func get_players_skin_material(players_skin: Dictionary) -> Material:
	return palette_array[players_skin["skin"]]


func get_my_skin() -> Dictionary:
	return my_skin


func set_mat(key: String, index: int, material: Material = null):
	var color_array: Array
	if   key == "skin":
		color_array = skin_colors
	elif key == "legs":
		color_array = legs_colors
	elif key == "mouth":
		color_array = mouth_colors
	elif key == "eyes":
		color_array = eyes_colors
	else:
		printerr("[CustomizePlayer]: This key doesn't exist")
	
	if material != null:
		my_skin[key] = palette_array.find(material)
	else:
		my_skin[key] = palette_array.find(color_array[index])
	
	PacketSender.request_update_player_info()
	_save_customizations()
	return my_skin


func randomize_skin() -> Dictionary:
	my_skin["mouth"] = palette_array.find(mouth_colors[Util.rand.randi_range(0, mouth_colors.size()-1)])
	my_skin["eyes"] = palette_array.find(eyes_colors[Util.rand.randi_range(0, eyes_colors.size()-1)])
	my_skin["skin"] = palette_array.find(skin_colors[Util.rand.randi_range(0, skin_colors.size()-1)])
	my_skin["legs"] = palette_array.find(legs_colors[Util.rand.randi_range(0, legs_colors.size()-1)])
	#my_skin["hat"] = Util.rand.randi_range(0, 4)
	_save_customizations()
	return my_skin


func fancy_pants(fishard_model: Spatial) -> void:
	my_skin["legs"] = palette_array.find(palette_array[Util.rand.randi_range(0, palette_array.size()-1)])
	_save_customizations()
	apply_skin_to_fishard(null, my_skin, fishard_model)


# Save skin data
func _save_customizations():
	var save_file = File.new()
	var error = save_file.open_encrypted_with_pass("user://skin.dat", File.WRITE, "JackoBertoIsACheekyGuy_10")
	if error == OK:
		save_file.store_var(my_skin)
		save_file.close()
	else:
		printerr("There was an error whilst trying to save skin data.")


# Load skin data
func _load_customizations():
	var load_file = File.new()
	if load_file.file_exists("user://skin.dat") == false:
		return # Error! No file to load from
	
	var error = load_file.open_encrypted_with_pass("user://skin.dat", File.READ, "JackoBertoIsACheekyGuy_10")
	if error == OK:
		var stored_skin_data = load_file.get_var()
		
		# For people with an old unencrypted save file
		if stored_skin_data == null:
			_save_customizations()
			return
		
		my_skin = stored_skin_data
		if Globals.get_app_mode() == Globals.AppModes.DEMO:
			my_skin["hat"] = 0
		load_file.close()
	else:
		printerr("There was an error whilst trying to load skin data.")

