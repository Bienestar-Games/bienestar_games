class_name EnemyIdleState extends State

@export var enemy: Enemy

const IDLE_MIN: float = 3.0
const IDLE_MAX: float = 5.0
var _timer: float = 0.0

func enter() -> void:
	enemy.stop_moving()
	_timer = randf_range(IDLE_MIN, IDLE_MAX)

func update(delta: float) -> void:
	enemy.handle_animations("idle")
	if enemy.target:
		transitioned.emit(self, "chasing")
		return
	if enemy.hunts_player and enemy.has_last_seen:
		transitioned.emit(self, "searching")
		return
	_timer -= delta
	if _timer <= 0.0:
		transitioned.emit(self, "moving")
