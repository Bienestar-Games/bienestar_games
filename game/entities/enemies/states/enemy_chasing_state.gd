class_name EnemyChasingState extends State

@export var enemy: Enemy

const REPATH_THRESHOLD: float = 8.0

func enter() -> void:
	if enemy.target:
		enemy.navigation_agent_2d.target_position = enemy.target.global_position

func update(delta: float) -> void:
	enemy.handle_animations("moving")
	if enemy.target == null:
		_leave_combat()
		return
	if enemy.player_in_attack_area:
		if enemy.attack_cd_timer <= 0.0 and not enemy.vision_ray.is_colliding():
			transitioned.emit(self, "attacking")
		else:
			transitioned.emit(self, "attack_recovery")
		return
	_update_path(delta)

func _update_path(delta) -> void:
	if enemy.navigation_agent_2d.target_position.distance_to(enemy.target.global_position) > REPATH_THRESHOLD:
		enemy.navigation_agent_2d.target_position = enemy.target.global_position
	if enemy.navigation_agent_2d.is_navigation_finished():
		enemy.stop_moving()
		return
	var next_point: Vector2 = enemy.navigation_agent_2d.get_next_path_position()
	var dir: Vector2 = enemy.global_position.direction_to(next_point)
	if dir.length_squared() > 0.0001:
		enemy.move_direction = dir
		enemy.move(enemy.move_direction, delta)
		enemy._last_move_direction = dir

func _leave_combat() -> void:
	enemy._ongoing_interaction = false
	if enemy.has_last_seen:
		transitioned.emit(self, "searching")
	else:
		transitioned.emit(self, "idle")
