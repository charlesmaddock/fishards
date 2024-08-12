extends Panel


onready var chatInput: LineEdit = $LineEdit
onready var sendChatMsg: Button = $LineEdit/SendChatMsg
onready var chatContainer: VBoxContainer = $ScrollContainer/ChatContainer
onready var scrollbar = $ScrollContainer.get_v_scrollbar()
onready var scrollContainer = $ScrollContainer
onready var InGameMessages = $InGameMessages


export var in_game_chat: bool = false
var _focused: bool = true
var _sent_bad_connection: bool
var _messages_amount_sent_short_period: int

var chat_message: PackedScene = preload("res://Scenes/MainMenu/ChatMessage.tscn")


func _ready():
	Lobby.connect("lobby_chat", self, "_on_display_chat")
	Lobby.connect("lobby_message", self, "_on_display_message")
	Lobby.connect("ping_updated", self, "_on_ping_updated")
	
	_focused = !in_game_chat
	if in_game_chat == true:
		close_chat()
		chatInput.self_modulate = Color(1,1,1,0.5)
	else:
		open_chat()
		self_modulate = Color(1,1,1,1)
		InGameMessages.visible = false
	
	scrollContainer.scroll_vertical = scrollbar.max_value


func _process(delta) -> void:
	if chatInput.text.length() > 512:
		sendChatMsg.disabled = true
	else:
		sendChatMsg.disabled = false
	
	if Input.is_action_just_pressed("ui_accept") && _focused: 
		send_chat_message()
		return
	
	if Input.is_action_just_pressed("ui_cancel"): 
		close_chat()
		return
	
	if Input.is_action_just_pressed("open_chat") && not _focused: 
		open_chat()
		return


func open_chat():
	if in_game_chat == true:
		Globals.set_ui_interaction_mode(Globals.UIInteractionModes.UI)
		self_modulate = Color(1,1,1,0.5)
		scrollContainer.visible = true
		InGameMessages.visible = false
		_focused = true
		chatInput.grab_focus()
		chatInput.visible = true
		
		yield(get_tree(), "idle_frame")
		scrollContainer.scroll_vertical = scrollbar.max_value


func close_chat():
	if in_game_chat == true && self_modulate != Color(1,1,1,0):
		Globals.set_ui_interaction_mode(Globals.UIInteractionModes.GAMEPLAY)
		InGameMessages.visible = true
		self_modulate = Color(1,1,1,0)
		_focused = false
		chatInput.visible = false
		scrollContainer.visible = false


func clear_chat():
	for message in chatContainer.get_children():
		message.queue_free()


func send_chat_message() -> void:
	var message: String = chatInput.text
	
	if message.begins_with("/stats"):
		Globals.toggle_stats_visible()
	elif message.begins_with("/dance"):
		trigger_animation(Globals.PlayerAnimations.DANCE_1)
	elif message.begins_with("/flop"):
		trigger_animation(Globals.PlayerAnimations.FLOP_ONCE)
	elif message.begins_with("/backflip"):
		trigger_animation(Globals.PlayerAnimations.BACKFLIP)
	#elif message.begins_with("/Resetachdata1"):
	#	AchievementHandler.reset()
	#elif message.begins_with("/Forcenextround1"):
	#	Lobby.emit_signal("force_next_round")
	elif _messages_amount_sent_short_period > 3:
		Lobby.emit_signal("lobby_message", "ERROR: Spam not allowed")
	elif message.length() >= 512:
		Lobby.emit_signal("lobby_message", "ERROR: Message too long")
	elif message != "":
		_messages_amount_sent_short_period += 1
		var censored_message = ProfanityFilter.filter(message)
		PacketSender.send_chat_message(SteamValues.STEAM_ID, censored_message)
	
	
	if Globals.get_app_mode() == Globals.AppModes.DEVELOPMENT:
		if message.begins_with("/packet_info"):
			PacketSender.print_packet_info = true
		elif message.begins_with("/kill_bots"):
			for player in Lobby.get_all_lobby_player_info():
				if player["plyr_type"] != Globals.PlayerTypes.CLIENT:
					PacketSender.broadcast_player_death(player["id"])
		elif message.begins_with("/spawn_bot"):
			var players_node = Util.get_players_node()
			if players_node != null:
				var amount = float(message.split(" ")[1])
				for i in amount:
					players_node.host_spawn_temp_bot(Util.generate_bot_name(Globals.PlayerTypes.HARD_BOT), Globals.PlayerTypes.HARD_BOT)
		elif message.begins_with("/next"):
			Lobby.emit_signal("force_next_round")
		elif message.begins_with("/chosen_one"):
			var players_node = Util.get_players_node()
			if players_node != null:
				var player: Player = players_node.get_player_component(SteamValues.STEAM_ID)
				if player != null:
					player.fancy_pants()
	
	chatInput.text = ""
	
	if in_game_chat == true:
		close_chat()


func trigger_animation(animation_nr: int):
	var room_node = Util.get_room_node()
	if room_node != null:
		var player: Entity = room_node.get_entity(SteamValues.STEAM_ID)
		if player != null:
			PacketSender.trigger_player_animation(player, animation_nr)


func _on_display_chat(sender: String, message: String) -> void:
	_display(message, sender)


func _on_display_message(message: String) -> void:
	_display(message)


func _on_ping_updated(ping, ping_avg) -> void:
	if _sent_bad_connection == false && ping > 300:
		_sent_bad_connection = true
		_display("Your connection is bad. This is probably due to the room being hosted far away from you.")


func _display(message, sender = "") -> void:
	# Create the open chat message
	var chat_message_instance = chat_message.instance()
	chat_message_instance.create_chat_message(str(message), sender, false)
	chatContainer.add_child(chat_message_instance)
	
	# If necessary, create the ingame chat message that disappears after a few secs
	if in_game_chat == true:
		var ingame_chat_message_inst = chat_message.instance()
		ingame_chat_message_inst.create_chat_message(str(message), sender, true)
		InGameMessages.add_child(ingame_chat_message_inst)
	
	# Scroll to the latest message
	yield(get_tree(), "idle_frame")
	scrollContainer.scroll_vertical = scrollbar.max_value


func _on_send_chat_msg_pressed():
	send_chat_message()


func _on_input_focus_entered():
	_focused = true


func _on_SpamLimitTimer_timeout():
	if _messages_amount_sent_short_period > 0:
		_messages_amount_sent_short_period -= 1
