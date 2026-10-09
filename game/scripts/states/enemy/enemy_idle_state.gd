extends State
## Enemy without a living target: stands still and keeps looking for Kade.

@onready var enemy: Enemy = owner


func enter(_msg: Dictionary = {}) -> void:
	enemy.velocity = Vector2.ZERO


func physics_update(_delta: float) -> void:
	if enemy.find_target():
		state_machine.transition_to(&"Chasing")
