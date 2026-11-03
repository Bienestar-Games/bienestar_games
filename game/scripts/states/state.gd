extends Node
class_name State
signal transitioned(state: State, new_state_name: String)

func enter() -> void:
	pass

func exit() -> void:
	pass

func update(_delta) -> void:
	pass
	
func phyisics_update(_delta) -> void:
	pass
