class_name EnemyMovingState extends State

@export var enemy: Enemy

const WANDER_MIN: float = 200.0
const WANDER_MAX: float = 400.0
const DIRECTIONS = [
	Vector2(1, 0), Vector2(-1, 0), Vector2(0, -1), Vector2(0, 1),
	Vector2(1, -1), Vector2(-1, -1), Vector2(1, 1), Vector2(-1, 1)
]
var _timer: float = 0.0

func enter() -> void:
	_timer = randf_range(4.0, 7.0)
	var random_dir: Vector2 = DIRECTIONS[randi() % DIRECTIONS.size()]
	var distance: float = randf_range(WANDER_MIN, WANDER_MAX)
	var desired: Vector2 = enemy.global_position + random_dir * distance
	var map_rid: RID = enemy.navigation_agent_2d.get_navigation_map()
	enemy.navigation_agent_2d.target_position = NavigationServer2D.map_get_closest_point(map_rid, desired)

func update(delta: float) -> void:
	enemy.handle_animations("moving")
	if enemy.target:
		transitioned.emit(self, "chasing")
		return
	_timer -= delta
	if enemy.navigation_agent_2d.is_navigation_finished() or _timer <= 0.0:
		transitioned.emit(self, "idle")
		return
	var next_point: Vector2 = enemy.navigation_agent_2d.get_next_path_position()
	var dir: Vector2 = enemy.global_position.direction_to(next_point)
	if dir.length_squared() > 0.0001:
		enemy.move_direction = dir
		enemy.move(dir, delta)
		enemy._last_move_direction = dir
