class_name EnemyAttackRecoveryState extends State

@export var enemy: Enemy

func enter() -> void:
	enemy.stop_moving()
	enemy._ongoing_interaction = false
	enemy.attack_cd_timer = enemy.attack_cooldown

func update(delta: float) -> void:
	if enemy.target == null:
		_leave_combat()
		return
	if not enemy.player_in_attack_area:
		transitioned.emit(self, "chasing")
		return
	if enemy.attack_cd_timer <= 0.0:
		transitioned.emit(self, "attacking")

func _leave_combat() -> void:
	enemy._ongoing_interaction = false
	if enemy.has_last_seen:
		transitioned.emit(self, "searching")
	else:
		transitioned.emit(self, "idle")
