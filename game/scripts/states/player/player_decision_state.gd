class_name PlayerDecisionState
extends State

@export var player: Player

func enter() -> void:
	player.stop_moving()

func exit() -> void:
	pass

# No movement or combat input — the decision panel (B25) drives
# GameLoopManager.continue_run() or GameLoopManager.request_extraction()
func update(_delta: float) -> void:
	pass
