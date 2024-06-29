tool
extends HBoxContainer


export(bool) var on_spell_hud = false
export(bool) var display_only = false
export(bool) var show_keys = true
export(bool) var use_clients_elements = true
export(bool) var update_elements_with_button = false
export(bool) var kill_on_update = true

export(Color) var label_color = Color.white


var _is_dragging: bool = false
var _hovering_over_container: VBoxContainer = null
var _dragging_el: int = -1
var element_owner_id: int
var _current_elements: Array


func set_owner_id(id: int) -> void:
	element_owner_id = id


func _ready():
	get_node("UpdateElements").set_visible(update_elements_with_button)
	
	Lobby.connect("lobby_members_updated", self, "_on_lobby_members_updated")
	
	add_constant_override("separation", 1 if display_only else 3)
	
	if use_clients_elements == true:
		element_owner_id = SteamValues.STEAM_ID
		# Load previously saved elements
		set_elements(UserSettings.get_elements(), true)
	
	# Show / hide grey outline
	for child in get_children():
		if child is VBoxContainer:
			child.greyCover.visible = on_spell_hud


func _on_lobby_members_updated() -> void:
	for player_info in Lobby.get_all_lobby_player_info():
		if player_info["id"] == element_owner_id:
			set_elements(player_info["elmts"], true)
			break


func _process(delta):
	if not Engine.editor_hint:
		if Input.is_action_just_pressed("click"):
			handle_click()
		elif Input.is_action_just_released("click"): 
			handle_release()
		
		if _is_dragging == true:
			hide_all_preview_pickers()
			var closest_el_container_info = find_closest_el_container()
			if closest_el_container_info["closest_container"] != null:
				closest_el_container_info["closest_container"].set_preview_picker(true)


func handle_click() -> void:
	if _hovering_over_container != null:
		MusicAndSfxHandler.play_sound(MusicAndSfxHandler.sounds.ELEMENT_PICKUP)
		_is_dragging = true
		_dragging_el = _hovering_over_container.element
		_hovering_over_container.set_selected(false, display_only, show_keys, label_color, "")


func handle_release() -> void:
	if _is_dragging == true:
		MusicAndSfxHandler.play_sound(MusicAndSfxHandler.sounds.ELEMENT_DROP)
		_is_dragging = false
		var closest_el_container_info = find_closest_el_container()
		if closest_el_container_info["closest_container"] != null:
			_current_elements.remove(_current_elements.find(_dragging_el))
			_current_elements.append(closest_el_container_info["closest_container"].element)
			_current_elements.sort() 
			
			if update_elements_with_button == false:
				UserSettings.save_and_broadcast_elements(_current_elements, kill_on_update)
			
			set_elements(_current_elements, true)
			_dragging_el = -1 
			_hovering_over_container = null


func _on_update_elements_button_pressed() -> void:
	print("Updated elements from update button!")
	UserSettings.save_and_broadcast_elements(_current_elements, kill_on_update)
	set_elements(_current_elements, true)


func handle_element_entered(element_container: VBoxContainer) -> void:
	_hovering_over_container = element_container


func handle_element_exited(element_container: VBoxContainer) -> void:
	if _hovering_over_container == element_container:
		_hovering_over_container = null


func hide_all_preview_pickers() -> void:
	for child in get_children():
		if child is VBoxContainer:
			child.set_preview_picker(false)


func set_elements(_players_elements: Array, update_client_elements: bool, element_amount: int = -1) -> void:
	var new_elements: Array
	
	# If the lobby has an allowed amount of spells that doesn't align with 
	# the stored players elements amount we need to allow the player to select more or less elements 
	if update_client_elements == true && element_amount != -1 && _players_elements.size() != element_amount:
		var new_player_elements: Array = Util.force_update_client_elements(element_amount)
		new_elements = new_player_elements
	
	# Display elements in inspector
	if not Engine.editor_hint:
		new_elements = _players_elements.duplicate(true)
	else:
		new_elements = [Globals.Elements.FIRE, Globals.Elements.WATER, Globals.Elements.GOO]
	
	for child in get_children():
		if child is VBoxContainer:
			child.visible = true
			if new_elements.find(child.element) != -1:
				var key_code = 0
				if show_keys == true:
					key_code = Util.get_key_code("element_" + str(new_elements.find(child.element) + 1), Util.InputTypes.KEYBOARD)
				child.set_selected(true, display_only, show_keys, label_color, OS.get_scancode_string(key_code))
			elif display_only == false:
				child.set_selected(false, display_only, show_keys, label_color)
			elif not Engine.editor_hint:
				child.visible = false
	
	_current_elements = new_elements


func find_closest_el_container() -> Dictionary:
	var mouse_pos = get_viewport().get_mouse_position()
	var closest_dist: float = 1000
	var closest_container: VBoxContainer = null
	for child in get_children():
		if child is VBoxContainer:
			var child_pos = Vector2(child.rect_global_position.x + child.rect_size.x/2, child.rect_global_position.y + child.rect_size.y/2)
			var dist = child_pos.distance_to(mouse_pos)
			if dist < closest_dist && child._selected == false:
				closest_dist = dist
				closest_container = child
	return {"closest_container": closest_container, "dist": closest_dist}
