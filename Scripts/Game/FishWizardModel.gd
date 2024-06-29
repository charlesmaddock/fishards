extends Spatial

export(bool) var menu_fish: bool = false

onready var fish_mesh = $Armature/Skeleton/Fish

var selected_hat: int
var has_set: bool = false

var _hat_container_path: String
onready var _hatContainer: Position3D = $Hat/HatContainer


func _ready():
	hide_all_hats()
	if has_set:
		show_hat(selected_hat)
	elif menu_fish:
		show_hat(CustomizePlayer.get_my_skin()["hat"])
	
	Util.reparent_node($Hat, $Armature/Skeleton)


func show_hat(hat: int, wait_until_ready: bool = false):
	if wait_until_ready:
		selected_hat = hat
		has_set = true
	else:
		selected_hat = hat
		for child in _hatContainer.get_children():
			if child.hat_type != null:
				if child.hat_type == hat:
					child.visible = true
				else:
					child.visible = false
			else:
				child.visible = false
				printerr("You have something that does not inherit from Hat in the Hat container!")


func hide_all_hats():
	if _hatContainer != null:
		for child in _hatContainer.get_children():
			child.visible = false
	else:
		printerr("tried to hide all hats but hatContainer was null")

