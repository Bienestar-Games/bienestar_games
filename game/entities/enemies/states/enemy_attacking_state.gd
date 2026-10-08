class_name EnemyAttackingState extends State

@export var enemy: Enemy

var _timer: float = 0.0

func enter() -> void:
	enemy._ongoing_interaction = true
	enemy.stop_moving()
	_timer = enemy.attack_duration
	if enemy.target:
		enemy._last_move_direction = (enemy.target.global_position - enemy.global_position).normalized()
		enemy.target.take_damage(enemy.base_damage)
	
func update(delta: float) -> void:
	enemy.handle_animations("attacking")
	_timer -= delta
	if _timer <= 0.0:
		transitioned.emit(self, "attack_recovery")
	
