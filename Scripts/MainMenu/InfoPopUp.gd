extends CanvasLayer


var _title
var _desc


func init_popup(title: String, desc: String):
	_title = title
	_desc = desc


func _ready():
	get_node("InfoPopup/Panel/Margin/VBox/Title").text = _title
	get_node("InfoPopup/Panel/Margin/VBox/Desc").text = _desc
	get_node("InfoPopup/Panel").rect_size.y = get_node("InfoPopup/Panel").get_minimum_size().y


func _on_Button_pressed():
	queue_free()
