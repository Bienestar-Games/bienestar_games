class_name EnemySearchingState extends State

@export var enemy: Enemy

const SEARCH_TIMEOUT: float = 10.0
const SEARCH_ROTATION_SPEED: float = TAU / 3.0

var _timer: float = 0.0
var _rotation_accum: float = 0.0

func enter() -> void:
	_timer = SEARCH_TIMEOUT
	_rotation_accum = 0.0
	enemy.navigation_agent_2d.target_position = enemy.last_seen_position

func update(delta: float) -> void:
	if enemy.target:
		transitioned.emit(self, "chasing")
		return
	_timer -= delta
	if _timer <= 0.0:
		enemy.has_last_seen = false
		transitioned.emit(self, "idle")
		return
	# Fase 1: ir al último punto visto
	if not enemy.navigation_agent_2d.is_navigation_finished():
		enemy.handle_animations("moving")
		var next_point: Vector2 = enemy.navigation_agent_2d.get_next_path_position()
		var dir: Vector2 = enemy.global_position.direction_to(next_point)
		if dir.length_squared() > 0.0001:
			enemy.move_direction = dir
			enemy.move(enemy.move_direction, delta)
			enemy._last_move_direction = dir
		return
	# Fase 2: gira una vuelta completa
	enemy.stop_moving()
	enemy.handle_animations("idle")
	var step: float = SEARCH_ROTATION_SPEED * delta
	_rotation_accum += step
	enemy._last_move_direction = enemy._last_move_direction.rotated(step)
	if _rotation_accum >= TAU:
		enemy.has_last_seen = false
		transitioned.emit(self, "idle")
