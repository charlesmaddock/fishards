extends Node


const CHAT_ROOM_ENTER_RESPONSE_SUCCESS = 1


var offline_files = {}
var offline_achievements = {}
var offline_lobby_data = {}


signal join_requested(lobby_id, friend_id)
signal lobby_joined(lobby_id, permissions, locked, response)
signal p2p_session_request(remote_id)
signal p2p_session_connect_fail(remote_id, session_error)
signal lobby_created(connect_response, lobby_id)
signal lobby_chat_update(lobby_id, changed_id, making_change_id, chat_state)
signal lobby_match_list(lobbies)
signal current_stats_received(game_id, result, user_id)


# ---------------------------------------------------------
# BASIC STEAM INFORMATION
# ---------------------------------------------------------

func steamInit() -> Dictionary:
	return {
		"status": 1,
		"verbal": "Offline development mode"
	}


func loggedOn() -> bool:
	return true


func getSteamID() -> int:
	return 1


func getPersonaName() -> String:
	return "OfflinePlayer"


func isSubscribed() -> bool:
	return true


func run_callbacks() -> void:
	pass


# ---------------------------------------------------------
# ACHIEVEMENTS
# ---------------------------------------------------------

func requestUserStats(_steam_id: int) -> bool:
	return true


func getAchievement(achievement_name: String) -> Dictionary:
	var achieved = false

	if offline_achievements.has(achievement_name):
		achieved = offline_achievements[achievement_name]

	return {
		"ret": true,
		"achieved": achieved
	}


func setAchievement(achievement_name: String) -> bool:
	offline_achievements[achievement_name] = true
	return true


func clearAchievement(achievement_name: String) -> bool:
	offline_achievements[achievement_name] = false
	return true


func storeStats() -> bool:
	return true


func getAchievementDisplayAttribute(
	achievement_name: String,
	attribute: String
) -> String:

	if attribute == "name":
		return achievement_name

	if attribute == "desc":
		return "Offline achievement"

	return ""


# ---------------------------------------------------------
# OFFLINE STEAM CLOUD REPLACEMENT
# ---------------------------------------------------------

func fileExists(file_name: String) -> bool:
	return offline_files.has(file_name)


func fileWrite(
	file_name: String,
	data: PoolByteArray,
	_data_size: int
) -> bool:

	offline_files[file_name] = data
	return true


func getFileSize(file_name: String) -> int:
	if offline_files.has(file_name):
		return offline_files[file_name].size()

	return 0


func fileRead(
	file_name: String,
	_data_size: int
) -> Dictionary:

	if offline_files.has(file_name):
		return {
			"ret": true,
			"buf": offline_files[file_name]
		}

	return {
		"ret": false,
		"buf": PoolByteArray()
	}


func fileDelete(file_name: String) -> bool:
	if offline_files.has(file_name):
		offline_files.erase(file_name)

	return true


# ---------------------------------------------------------
# OFFLINE LOBBY REPLACEMENT
# ---------------------------------------------------------

func setLobbyData(
	lobby_id: int,
	key: String,
	value: String
) -> bool:

	if offline_lobby_data.has(lobby_id) == false:
		offline_lobby_data[lobby_id] = {}

	offline_lobby_data[lobby_id][key] = value

	return true


func getLobbyData(
	lobby_id: int,
	key: String
) -> String:

	if offline_lobby_data.has(lobby_id) == false:
		return ""

	if offline_lobby_data[lobby_id].has(key) == false:
		return ""

	return str(offline_lobby_data[lobby_id][key])


func setLobbyJoinable(
	_lobby_id: int,
	_joinable: bool
) -> bool:

	return true


func allowP2PPacketRelay(_allow: bool) -> bool:
	return true


func getLobbyOwner(_lobby_id: int) -> int:
	return getSteamID()


func getNumLobbyMembers(_lobby_id: int) -> int:
	return 1


func getLobbyMemberByIndex(
	_lobby_id: int,
	index: int
) -> int:

	if index == 0:
		return getSteamID()

	return 0


# ---------------------------------------------------------
# OFFLINE P2P NETWORK REPLACEMENT
# ---------------------------------------------------------

func getAvailableP2PPacketSize(_channel: int = 0) -> int:
	return 0


func readP2PPacket(
	_packet_size: int,
	_channel: int = 0
) -> Dictionary:

	return {
		"steam_id_remote": 0,
		"data": PoolByteArray()
	}


func sendP2PPacket(
	_remote_id: int,
	_data: PoolByteArray,
	_send_type: int,
	_channel: int = 0
) -> bool:

	return true


func acceptP2PSessionWithUser(_remote_id: int) -> bool:
	return true


func closeP2PSessionWithUser(_remote_id: int) -> bool:
	return true


# ---------------------------------------------------------
# OFFLINE PLAYER INFORMATION
# ---------------------------------------------------------

func getFriendPersonaName(remote_id: int) -> String:
	if remote_id == getSteamID():
		return getPersonaName()

	return "OfflinePlayer"
