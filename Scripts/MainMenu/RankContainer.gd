extends Control


export(bool) var use_clients_rank


export(Color) var bronze_color 
export(Color) var silver_color 
export(Color) var gold_color 
export(Color) var diamond_color 


onready var rankLabel = $RankLabel
onready var medals = $Medals
onready var diamond = $Medals/Diamond
onready var gold = $Medals/Gold
onready var silver = $Medals/Silver
onready var bronze = $Medals/Bronze


func _ready():
	if use_clients_rank == true:
		display_rank(AchievementHandler.get_rank())


func display_rank(rank: int) -> Color:
	var color = bronze_color
	for child in medals.get_children():
		child.set_visible(false)
	
	rankLabel.text = str(rank)
	
	var max_rank = AchievementHandler.get_max_rank()
	if rank < max_rank / 3:
		bronze.set_visible(true)
		rankLabel.set("custom_colors/font_color", bronze_color)
		color = bronze_color
	elif rank < (max_rank / 3) * 2:
		silver.set_visible(true)
		rankLabel.set("custom_colors/font_color", silver_color)
		color = silver_color
	elif rank < max_rank:
		gold.set_visible(true)
		rankLabel.set("custom_colors/font_color", gold_color)
		color = gold_color
	elif rank == max_rank:
		diamond.set_visible(true)
		rankLabel.set("custom_colors/font_color", diamond_color)
		color = diamond_color
	
	return color
