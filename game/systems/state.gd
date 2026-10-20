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

# The StateMachine always processes; only states that drive their own pause
# (e.g. inventory) should keep updating while the tree is paused.
func runs_while_paused() -> bool:
	return false
