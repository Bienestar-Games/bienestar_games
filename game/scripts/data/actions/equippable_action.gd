extends  ActionData
class_name EquippableAction

@export var one_time_use: bool = true
@export var succes: String = "Weapon broken" 

func _init() -> void:
	action_type = ActionType.EQUIPPABLE
