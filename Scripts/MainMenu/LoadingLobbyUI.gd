extends MainMenuUIChild

onready var loadingStatus: Label = $Loading/Status
onready var passwordPopup: Control = $PasswordPopup
onready var passwordText: Label = $PasswordPopup/Label
onready var passwordEdit: LineEdit = $PasswordPopup/LineEdit
onready var wrongPasswordTip: Label = $PasswordPopup/WrongPasswordTip

onready var loadingControl: Control = $Loading
onready var failedResponse: Control = $FailedResponse
onready var failedResponseText: Label = $FailedResponse/Label


func _ready():
	Lobby.connect("update_loading_status", self, "_set_loading_status")
	Lobby.connect("was_not_accepted_into_lobby", self, "_on_not_accepted_into_lobby")
	_show_loading()
	
	if Lobby.password_required && !Lobby.is_host:
		_password_popup()


func _show_failed_response(response: int):
	loadingControl.visible = false
	passwordPopup.visible = false
	failedResponse.visible = true
	match response:
		SteamValues.RoomEnterResponse.DOESNT_EXSIT:
			failedResponseText.text = "This lobby no longer exists."
		SteamValues.RoomEnterResponse.BANNED:
			failedResponseText.text = "You've been banned from this room."
		SteamValues.RoomEnterResponse.FULL:
			failedResponseText.text = "The room is full."
		_:
			failedResponseText.text = "An error occured whilst trying to join room."


func _password_popup(with_wrong_password_tip: bool = false):
	failedResponse.visible = false
	loadingControl.visible = false
	passwordPopup.visible = true
	wrongPasswordTip.visible = with_wrong_password_tip


func _show_loading():
	failedResponse.visible = false
	passwordPopup.visible = false
	loadingControl.visible = true


func _set_loading_status(text: String) -> void:
	loadingStatus.text = text
	if text == "enter password":
		_password_popup()


func _on_not_accepted_into_lobby(response: int):
	if response == SteamValues.RoomEnterResponse.INCORRECT_PASSWORD:
		passwordText.text = "Incorrect password"
		printerr("Step 5: Wrong password")
		_password_popup(true)
		passwordEdit.text = ""
		
	else:
		_show_failed_response(response)
	

func _on_passwordButton_pressed():
	_show_loading()
	_set_loading_status("Checking if password is correct")
	PacketSender.request_join_lobby(Lobby.get_host_id(), passwordEdit.text)


func _on_Back_pressed():
	Lobby.leave_lobby("back button loading lobby")


func _on_Leave_pressed():
	Lobby.leave_lobby("leave button loading lobby")
