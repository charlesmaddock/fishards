extends Control

# Slots 
onready var spellHUDElement1: Control = $SpellHUDElement1
onready var spellHUDElement2: Control = $SpellHUDElement2
onready var spell_slot: TextureRect = $SpellIconHudVBox/CenterAlign1/SpellHolderContainer/SpellHolderRect/SpellTextureRect

# Cooldown
onready var _spell_charge_label: Label = $SpellCharges/Label
onready var _spell_charge_container: Control = $SpellCharges

# Cooldown without spell HUD
onready var cooldown2_slider: TextureProgress = $SpellIconHudVBox/CenterAlign0/Cooldown2/CooldownSlider
onready var cooldown_slider: TextureProgress = $SpellIconHudVBox/CenterAlign1/SpellHolderContainer/SpellHolderRect/SpellTextureRect/CoolDownSlider
onready var cooldown2: TextureRect = $SpellIconHudVBox/CenterAlign0/Cooldown2

onready var spellHolderRect: TextureRect = $"SpellIconHudVBox/CenterAlign1/SpellHolderContainer/SpellHolderRect"
onready var spellHolderAnimator: AnimationPlayer = $"SpellIconHudVBox/CenterAlign1/SpellHolderContainer/SpellHolderAnimator"

onready var spellCooldownPreviewContainer: GridContainer = $SpellIconHudVBox/CenterAlign2/SpellCooldownPreviewContainer
export(PackedScene) var spellCooldownPreview

var _cooldown: float = 0  
var _cooldown_max: float = 0
var spell_cooldown_previews: Dictionary


func _ready():
	UserSettings.connect("user_settings_updated", self, "on_settings_updated")
	_spell_charge_label.get_parent().visible = false
	
	for spell_type in Globals.SpellTypes.values():
		var icon = Globals.get_spell_icon(spell_type)
		if spell_type != Globals.SpellTypes.NONE && icon != Globals.empty_spell_icon:
			var preview = spellCooldownPreview.instance()
			preview.texture = icon
			preview.set_visible(false)
			spell_cooldown_previews[spell_type] = preview
			spellCooldownPreviewContainer.add_child(preview)
	
	yield(get_tree(), "idle_frame")
	on_settings_updated()


func _process(delta: float):
	cooldown2_slider.value -= delta
	cooldown_slider.value -= delta
	
	if cooldown_slider.value > 0: 
		if spell_slot.modulate != Color("#b9b9b9"):
			if UserSettings.get_auto_clear_elements() == true:
				spellHUDElement1.modulate = Color("#b9b9b9")
				spellHUDElement2.modulate = Color("#b9b9b9")
			spell_slot.modulate = Color("#b9b9b9")
	else:
		if spell_slot.modulate != Color("#ffffff"):
			if UserSettings.get_auto_clear_elements() == true:
				spellHUDElement1.modulate = Color("#ffffff")
				spellHUDElement2.modulate = Color("#ffffff")
			spell_slot.modulate = Color("#ffffff")
			


func update_cooldown(cooldown: float, cooldown_max: float) -> void:
	cooldown2_slider.max_value = float(cooldown_max + 0.01)
	cooldown2_slider.value = float(cooldown)
	cooldown_slider.max_value = float(cooldown_max + 0.01)
	cooldown_slider.value = float(cooldown)


func update_cooldown_preview(active_spell: int, spell_type: int, cooldown_prog: float) -> void:
	if spell_cooldown_previews.has(spell_type) && UserSettings.get_show_spell_cooldowns():
		var preview = spell_cooldown_previews[spell_type]
		if preview != null:
			if active_spell == spell_type:
				preview.set_visible(false)
			elif (preview.visible == true && cooldown_prog <= 0):
				preview.set_visible(false)
			elif preview.visible == false && cooldown_prog > 0:
				preview.set_visible(true)
			
			if preview.visible == true:
				preview.get_node("CoolDownSlider").value = cooldown_prog / Globals.SpellCooldowns[spell_type].cooldown


func update_spell_config(elements: Array, active_spell: int, prev_spell: int) -> void:
	var new_spell_created = elements.find(Globals.Elements.NONE) == -1
	
	spellHUDElement1.set_element(elements[0], new_spell_created)
	spellHUDElement2.set_element(elements[1], new_spell_created)
	
	var auto_clear_spells = UserSettings.get_auto_clear_elements()
	if auto_clear_spells == false && new_spell_created == true:
		spellHolderAnimator.play("Appear")
	elif auto_clear_spells == false && active_spell == Globals.SpellTypes.NONE:
		spellHolderAnimator.play("Disappear")
	elif auto_clear_spells == false && new_spell_created == false && prev_spell != Globals.SpellTypes.NONE:
		spellHolderAnimator.play("Standby")
	elif auto_clear_spells == true:
		spellHolderRect.get_rect().position = Vector2.ZERO
	
	spell_slot.texture = Globals.get_spell_icon(active_spell)
	spell_slot.set_visible(active_spell != Globals.SpellTypes.NONE)


func has_had_one_element_too_long() -> void:
	spellHUDElement1.one_element_too_long()
	spellHolderAnimator.play("RevertStandby")


func set_cooldown_values(cooldown: float, cooldown_max: float, charge_amount: int, max_charge_amount: int) -> void:
	# Set the spell cooldowns for animation
	update_cooldown(cooldown, cooldown_max)
	
	if max_charge_amount <= 1:
		_spell_charge_container.visible = false
	else:
		_spell_charge_container.visible = true
		_spell_charge_label.text = str(charge_amount)


func on_settings_updated():
	var disableSpellIcon = UserSettings.settings_dict["disableSpellHUD"]
	
	var spellHolderConfig = "AutoClearSpellsConfig" if UserSettings.get_auto_clear_elements() == true else "NormalSpellConfig"
	spellHolderAnimator.play(spellHolderConfig)
	
	if UserSettings.get_auto_clear_elements() == false:
		spellHUDElement1.set_default()
		spellHUDElement2.set_default()
	
	spellHolderRect.visible = true
	if disableSpellIcon == true && UserSettings.get_auto_clear_elements() == true:
		spellHolderRect.visible = false
	
	#cooldown2.visible = UserSettings.settings_dict["disableSpellHUD"]
	#visible = !UserSettings.get_minimal_HUD()
	#spellHolderRect.visible = !UserSettings.settings_dict["disableSpellHUD"]
	#cooldown2.visible = UserSettings.settings_dict["disableSpellHUD"]


func _on_OneElementOnlyTimer_timeout():
	has_had_one_element_too_long()
