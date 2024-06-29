extends Control

onready var hat_container: GridContainer = $VBoxContainer/Panel/ScrollContainer/GridContainer


func _ready():
	AchievementHandler.connect("fetched_achievements", self, "_load_discovered_hats")
	AchievementHandler.load_achievement_data()
	_undiscover_all_hats()
	_load_discovered_hats()


func _load_discovered_hats():
	var hat_info_array = AchievementHandler.get_unlocked_hats()
	for hat_button in hat_container.get_children():
		for hat_info in hat_info_array:
			if hat_info.hat == hat_button.hat:
				hat_button.set_discovered(hat_info["unlocked"], hat_info["title"], hat_info["desc"])
				break


func _unlock_hat(hat: int):
	for hat_button in hat_container.get_children():
		if hat_button.has_method("discover"):
			hat_button.set_discovered(true)


func _undiscover_all_hats():
	for hat_button in hat_container.get_children():
		if hat_button.has_method("discover"):
			if hat_button.hat != CustomizePlayer.HatTypes.NONE: 
				hat_button.set_discovered(false)
