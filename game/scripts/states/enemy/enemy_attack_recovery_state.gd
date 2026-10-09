extends State
## Short pause after a hit so the slow enemy can be punished before attacking again.

@onready var enemy: Enemy = owner

var _timer := 0.0


func enter(_msg: Dictionary = {}) -> void:
	_timer = enemy.attack_recovery
	enemy.velocity = Vector2.ZERO


func physics_update(delta: float) -> void:
	_timer -= delta
	if _timer <= 0.0:
		state_machine.transition_to(&"Chasing" if enemy.has_valid_target() else &"Idle")
