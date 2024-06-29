extends MainMenuUIChild


export(NodePath) var fishard_model_path
export(NodePath) var fish_mesh_path
export(PackedScene) var color_select_button_scene: PackedScene

onready var sidePanel: Control = $SidePanel
onready var colors: Label = $SidePanel/Colors
onready var spells: Control = $SidePanel/Spells
onready var cosmetics: Control = $SidePanel/Cosmetics
onready var stats: Control = $SidePanel/StatsSidePanel

onready var tabs: VBoxContainer = $YourFishard/Tabs
onready var colorsToggle: CheckBox = $YourFishard/Tabs/ColorsToggle
onready var spellsToggle: CheckBox = $YourFishard/Tabs/SpellsToggle
onready var cosmeticsToggle: CheckBox = $YourFishard/Tabs/CosmeticsToggle
onready var statsToggle: CheckBox = $YourFishard/Tabs/StatsToggle


#onready var name_label: Label = $Fishard/NAME
var _fishard_model: Spatial
var _fishard_mesh: Spatial

func _ready():
	#name_label.text = SteamValues.STEAM_USERNAME
	
	_fishard_model = get_node(fishard_model_path)
	_fishard_mesh = get_node(fish_mesh_path)
	var fishard_skin = CustomizePlayer.get_my_skin()
	
	CustomizePlayer.connect("hat_set", self, "_on_hat_set")
	
	CustomizePlayer.apply_skin_to_fishard(null, fishard_skin, _fishard_mesh)
	_generate_icons("skin", CustomizePlayer.skin_colors, "SidePanel/Colors/Panel/VBoxContainer/Body")
	_generate_icons("legs", CustomizePlayer.legs_colors, "SidePanel/Colors/Panel/VBoxContainer/Legs")
	_generate_icons("mouth", CustomizePlayer.mouth_colors, "SidePanel/Colors/Panel/VBoxContainer/Mouth")
	
	_on_Colors_pressed()
	


func init_UI():
	get_parent().zoom_to_fishard_sceen()


func hide_all_side_panels():
	for child in tabs.get_children():
		child.pressed = false
	
	for child in sidePanel.get_children():
		child.visible = false


func _on_hat_set(hat: int):
	if _fishard_model != null:
		_fishard_model.show_hat(hat)


func _on_random_pressed():
	var new_skin = CustomizePlayer.randomize_skin()
	CustomizePlayer.apply_skin_to_fishard(null, new_skin, _fishard_mesh)


# Once we select a new color, just update the model
func _on_color_selected():
	CustomizePlayer.apply_skin_to_fishard(null, CustomizePlayer.get_my_skin(), _fishard_mesh)


func _generate_icons(key: String, color_array: Array, popup_panel_button_path: String) -> void:
	for material in color_array:
		var color_select_button = color_select_button_scene.instance()
		color_select_button.set_values(material, key)
		color_select_button.connect("on_selected", self, "_on_color_selected")
		get_node(popup_panel_button_path).add_color_button(color_select_button)


func _on_Back_pressed():
	get_parent().change_UI("MainMenuUI")


func _on_SpellBook_pressed():
	get_parent().change_UI("SpellBookUI")


func _on_Spells_pressed():
	hide_all_side_panels()
	spellsToggle.pressed = true
	spells.visible = true


func _on_Colors_pressed():
	hide_all_side_panels()
	colorsToggle.pressed = true
	colors.visible = true


func _on_CosmeticsToggle_pressed():
	hide_all_side_panels()
	cosmeticsToggle.pressed = true
	cosmetics.visible = true


func _on_StatsToggle_pressed():
	hide_all_side_panels()
	statsToggle.pressed = true
	stats.visible = true
