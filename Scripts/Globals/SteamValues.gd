extends Node


enum SendType{
	UNRELIABLE,
	UNRELIABLE_NO_DELAY,
	RELIABLE,
	RELIABLE_W_BUFFERING,
}


enum LobbyType {
	PRIVATE,
	FRIENDS,
	PUBLIC,
	INVISIBLE,
}


enum SearchDistance {
	CLOSE,
	DEFAULT,
	FAR,
	WORLDWIDE
}


enum RoomEnterResponse {
	INCORRECT_PASSWORD,
	SUCCESS = Steam.CHAT_ROOM_ENTER_RESPONSE_SUCCESS,
	DOESNT_EXSIT = Steam.CHAT_ROOM_ENTER_RESPONSE_DOESNT_EXIST,
	NOT_ALLOWED = Steam.CHAT_ROOM_ENTER_RESPONSE_NOT_ALLOWED,
	FULL = Steam.CHAT_ROOM_ENTER_RESPONSE_FULL,
	ERROR = Steam.CHAT_ROOM_ENTER_RESPONSE_ERROR,
	BANNED = Steam.CHAT_ROOM_ENTER_RESPONSE_BANNED,
	# There are more just don't think we'll need them
}

# Steam variables
var OWNED = false
var ONLINE = false
var STEAM_ID = 0
var STEAM_USERNAME = ""
var init_status


signal attempted_to_connect()


func _ready():
	attempt_connect()


func attempt_connect(show_popup: bool = true):
	init_status = Steam.steamInit()
	ONLINE = Steam.loggedOn()
	STEAM_ID = Steam.getSteamID()
	STEAM_USERNAME = Steam.getPersonaName()
	OWNED = Steam.isSubscribed()
	
	if OWNED == false:
		if show_popup == true:
			Globals.create_info_popup("Couldn't connect to steam.", "Restart the game and make sure steam is open.")
		printerr("User does not own this game, DID YOU FORGET TO OPEN STEAM?!")
	elif init_status['status'] != 1:
		if show_popup == true:
			Globals.create_info_popup("You are offline", "Make sure you are connected to the internet.")
		printerr("Failed to initialize Steam.")
	
	emit_signal("attempted_to_connect")
