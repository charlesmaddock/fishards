extends MainMenuUIChild


onready var fishard_button = $Buttons/VBoxContainer/MyFish
onready var controls_button: Button = $Buttons/VBoxContainer/Controls
onready var demo_panel: Panel = $Logo/DemoPanel
onready var indev_panel: Panel = $Logo/InDevPanel
onready var quitDivider: Control = $Buttons/VBoxContainer/Divider
onready var quitAndWishlistContainer: Control = $Buttons/VBoxContainer/QuitAndWishlistContainer

func _ready():
	demo_panel.visible = false
	indev_panel.visible = false
	quitDivider.visible = false
	quitAndWishlistContainer.visible = false
	
	if Globals.get_app_mode() == Globals.AppModes.DEMO:
		fishard_button.visible = false
		controls_button.visible = false
		demo_panel.visible = true
		quitDivider.visible = true
		quitAndWishlistContainer.visible = true
	elif Globals.get_app_mode() == Globals.AppModes.DEVELOPMENT:
		indev_panel.visible = true


func _input(event):
	if Globals.get_app_mode() == Globals.AppModes.DEVELOPMENT:
		if Input.is_key_pressed(KEY_0) || Input.is_key_pressed(KEY_1) || Input.is_key_pressed(KEY_2) || Input.is_key_pressed(KEY_3) ||  Input.is_key_pressed(KEY_TAB):
			var gamemode: int = GamemodeValues.Gamemodes.LastManStanding
			var size = GamemodeValues.MapSizes.Small
			var map = GamemodeValues.Maps.Island
			var round_amount = 10
			var el_amount = 5
			var bot_amount: int = 0
			var bot_difficulty: int = Globals.PlayerTypes.DUMB_BOT
			
			if Input.is_key_pressed(KEY_0):
				bot_amount = 0
				gamemode = GamemodeValues.Gamemodes.FreeForAll
			elif Input.is_key_pressed(KEY_1):
				bot_amount = 1
				el_amount = 3
				gamemode = GamemodeValues.Gamemodes.FreeForAll
				bot_difficulty = Globals.PlayerTypes.EASY_BOT
			elif Input.is_key_pressed(KEY_2):
				bot_amount = 2
				bot_difficulty = Globals.PlayerTypes.DUMB_BOT
				gamemode = GamemodeValues.Gamemodes.FreeForAll
			elif Input.is_key_pressed(KEY_3):
				bot_amount = 3
				bot_difficulty = Globals.PlayerTypes.DUMB_BOT
				round_amount = 2
			elif Input.is_key_pressed(KEY_TAB):
				bot_amount = 10
				bot_difficulty = Globals.PlayerTypes.EASY_BOT
				#bot_difficulty = -1
				#size = GamemodeValues.MapSizes.Medium
				#map = GamemodeValues.Maps.ProtectIsland
				#gamemode = GamemodeValues.Gamemodes.Survive
			
			var dev_lobby_room_settings = RoomSettings.create_settings_dict("", 12, map, size, bot_amount, gamemode, round_amount, el_amount, bot_difficulty, Globals.ElementModes.DEFAULT)
			Lobby.create_lobby(SteamValues.LobbyType.PUBLIC, dev_lobby_room_settings.max_players, "Dev lobby", dev_lobby_room_settings, true)


func _on_Play_pressed():
	parent.change_UI("PlayUI")


func _on_Controls_pressed():
	parent.change_UI("ControlsUI")


func _on_fishard_pressed():
	parent.change_UI("CustomizeUI")


func _on_Settings_pressed():
	parent.change_UI("SettingsUI")


func _on_Quit_pressed():
	get_tree().quit()


func _on_wishlist_button_pressed():
	# Replace 1637140 with your game's app id
	var res: int = OS.shell_open("steam://advertise/1637140")
	# If we couldn't open steam for some reason open the store page in the browser
	if res != OK:
		OS.shell_open("https://store.steampowered.com/app/1637140/Fishards/")
	get_tree().quit()



func _on_MoreButton_pressed():
	parent.change_UI("MoreUI")
