extends State
## Follows Kade along the navigation mesh until he is within attack range.

@onready var enemy: Enemy = owner

var _repath_timer := 0.0


func enter(_msg: Dictionary = {}) -> void:
	_repath_timer = 0.0


func physics_update(delta: float) -> void:
	if not enemy.has_valid_target():
		state_machine.transition_to(&"Idle")
		return

	if enemy.distance_to_target() <= enemy.attack_range:
		state_machine.transition_to(&"Attacking")
		return

	_repath_timer -= delta
	if _repath_timer <= 0.0:
		_repath_timer = enemy.repath_interval
		enemy.navigation_agent.target_position = enemy.target.global_position

	var agent := enemy.navigation_agent
	if agent.is_navigation_finished():
		enemy.velocity = Vector2.ZERO
	else:
		var direction := enemy.global_position.direction_to(agent.get_next_path_position())
		enemy.velocity = direction * enemy.move_speed
		enemy.face(direction)
	enemy.move_and_slide()
