extends Spatial


onready var animationPlayer = $AnimationPlayer
onready var enterArea: Area = $EnterArea
onready var wallContainer: Spatial = $WallContainer


export(bool) var on_enter_area_raise: bool


var raised: bool 


signal enter_area_entered()


func _ready():
	enterArea.connect("area_entered", self, "_on_enter_area_entered")
	
	if on_enter_area_raise == true:
		raised = false
		wallContainer.transform.origin.y = -8


func raise() -> void:
	raised = true
	animationPlayer.play("up")


func down() -> void:
	raised = false
	animationPlayer.play("down")


func _on_enter_area_entered(area) -> void:
	var enter_entity: Entity = Util.get_entity_from_area(area)
	if enter_entity != null:
		if enter_entity.get_type() == Globals.EntityTypes.PLAYER && enter_entity.get_subtype() == Globals.PlayerTypes.CLIENT:
			if raised == false:
				emit_signal("enter_area_entered")
				
				if on_enter_area_raise == true:
					raise()
