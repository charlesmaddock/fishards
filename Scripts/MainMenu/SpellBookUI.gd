extends MainMenuUIChild


onready var spells: VBoxContainer = $Panel/ScrollContainer/Spells

onready var discovered_toggle: CheckBox = $FilterOptions/DiscoveredOnly

onready var fire_toggle: CheckBox = $FilterOptions/ElementFilter/Fire
onready var water_toggle: CheckBox = $FilterOptions/ElementFilter/Water
onready var earth_toggle: CheckBox = $FilterOptions/ElementFilter/Earth
onready var arcane_toggle: CheckBox = $FilterOptions/ElementFilter/Arcane
onready var goo_toggle: CheckBox = $FilterOptions/ElementFilter/Goo


func _ready():
	UserSettings.connect("spell_discovered", self, "_on_spell_discovered")


func filter_elements():
	var toggled: Array = []
	
	if !fire_toggle.pressed:
		toggled.append(Globals.Elements.FIRE)
	if !water_toggle.pressed:
		toggled.append(Globals.Elements.WATER)
	if !earth_toggle.pressed:
		toggled.append(Globals.Elements.EARTH)
	if !arcane_toggle.pressed:
		toggled.append(Globals.Elements.ARCANE)
	if !goo_toggle.pressed:
		toggled.append(Globals.Elements.GOO)
	
	var available_spells: Array = Util.get_spell_array_from_elements(toggled)
	
	for spell in spells.get_children():
		
		spell.visible = true
		
		if discovered_toggle.pressed:
			spell.visible = spell.discovered
		
		if spell.visible && discovered_toggle.pressed:
			spell.visible = available_spells.has(spell.spell_type)
		elif !discovered_toggle.pressed:
			spell.visible = available_spells.has(spell.spell_type)


func _on_SpellBook_visibility_changed():
	var settings: Dictionary = UserSettings.get_settings()
	for spell in spells.get_children():
		for element in settings["spells_discovered"]:
			if spell.spell_type == element:
				spell.discover()


func _on_spell_discovered(spell_type: int):
	for spell in spells.get_children():
		if spell.spell_type == spell_type:
			if spell.discovered == false:
				spell.discover()


func _on_DiscoveredOnly_toggled(button_pressed):
	for spell in spells.get_children():
		if !button_pressed: 
			spell.visible = true
		else:
			spell.visible = spell.discovered
	filter_elements()


func _on_Fire_toggled(button_pressed):
	if button_pressed:
		fire_toggle.modulate = Color("#8e8e8e")
	else:
		fire_toggle.modulate = Color("#ffffff")
	filter_elements()


func _on_Water_toggled(button_pressed):
	if button_pressed:
		water_toggle.modulate = Color("#8e8e8e")
	else:
		water_toggle.modulate = Color("#ffffff")
	filter_elements()


func _on_Earth_toggled(button_pressed):
	if button_pressed:
		earth_toggle.modulate = Color("#8e8e8e")
	else:
		earth_toggle.modulate = Color("#ffffff")
	filter_elements()


func _on_Arcane_toggled(button_pressed):
	if button_pressed:
		arcane_toggle.modulate = Color("#8e8e8e")
	else:
		arcane_toggle.modulate = Color("#ffffff")
	filter_elements()


func _on_Goo_toggled(button_pressed):
	if button_pressed:
		goo_toggle.modulate = Color("#8e8e8e")
	else:
		goo_toggle.modulate = Color("#ffffff")
	filter_elements()
