extends Control


var classContainer = preload("res://Scenes/MainMenu/ClassContainer.tscn")
var textStat = preload("res://Scenes/MainMenu/textStat.tscn")


onready var statsContainer = $VBoxContainer/Panel/ScrollContainer/VBoxContainer


func _ready():
	AchievementHandler.connect("achievements_data_dict_updated", self, "_on_achievements_data_dict_updated")
	
	if AchievementHandler.achievements_data_dict.empty() == false:
		_on_achievements_data_dict_updated(AchievementHandler.achievements_data_dict)


func _on_achievements_data_dict_updated(data: Dictionary) -> void:
	for child in statsContainer.get_children():
		child.queue_free()
	
	for key in data:
		if key == "class_kills" || key == "class_rounds_won_online":
			for class_id in data[key]:
				var class_title = AchievementHandler.classes_info[class_id].name
				var class_elements = AchievementHandler.classes_info[class_id].elements
				var score = data[key][class_id]
				var suffix = "kills" if key == "class_kills" else "wins"
				if score == 1:
					suffix = suffix.replace("s", "")
				var class_container = classContainer.instance()
				statsContainer.add_child(class_container)
				class_container.set_class_values(class_title, class_elements, score, suffix)
		elif key == "element_available_rounds_won" || key == "element_mode_rounds_won":
			var title = ""
			if key == "element_available_rounds_won":
				title = "Element Available"
			elif key == "element_mode_rounds_won":
				title = "Element Modes"
			create_stat_text(title)
			for available_element_amount in data[key]:
				var text = ""
				if key == "element_available_rounds_won":
					text = "Rounds won with " + str(available_element_amount) + " elements"
				elif key == "element_mode_rounds_won":
					var element_mode = "'Random Timed'" if available_element_amount == Globals.ElementModes.TIMED else "'Random Same'"
					text = "Rounds won with " + element_mode
				
				var score = data[key][available_element_amount]
				var class_container = classContainer.instance()
				statsContainer.add_child(class_container)
				class_container.set_class_values(text, [], score, "")
				
		else:
			create_stat_text(str(key.replace("_", " ")) + ": " + str(data[key]))


func create_stat_text(text: String) -> void:
	var textStatMarginContainer = textStat.instance()
	textStatMarginContainer.get_node("label").text = text
	statsContainer.add_child(textStatMarginContainer)
