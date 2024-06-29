extends VBoxContainer

export(bool) var discovered = false;

export(Texture) var icon_tex: Texture
export(Texture) var element1_tex: Texture
export(Texture) var element2_tex: Texture
export(Globals.SpellTypes) var spell_type: int
export(String) var spellName_text: String
export(String, MULTILINE) var description_text: String

onready var undiscovered_icon: Texture = preload("res://Assets/Images/UI/Game/SpellIcons/blank_small.png")
onready var icon: TextureRect = $Spell/Icon
onready var element1: TextureRect = $Spell/Control/Element1
onready var element2: TextureRect = $Spell/Control2/Element2
onready var spellName: CheckBox = $Spell/SpellName
onready var descriptionParent: HBoxContainer = $DescriptionParent
onready var description: Label = $DescriptionParent/Description


func _ready():
	element1.texture = element1_tex
	element2.texture = element2_tex
	
	if discovered:
		icon.texture = icon_tex
		spellName.text = spellName_text
		description.text = description_text
	else:
		icon.texture = undiscovered_icon
		spellName.text = "???"
		description.text = "???"



func discover():
	discovered = true
	icon.texture = icon_tex
	spellName.text = spellName_text
	description.text = description_text


func _on_SpellName_toggled(button_pressed):
	descriptionParent.visible = button_pressed
