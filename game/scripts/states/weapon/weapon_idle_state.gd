class_name WeaponIdleState extends State

@export var weapon: Weapon

func enter() -> void:
	weapon._animation_player.play("idle")

func update(delta: float) -> void:
	if Input.is_action_just_pressed("shoot"):
		if weapon.magazine.is_empty():
			weapon._animation_player.play("dry_shoot")
			return
		transitioned.emit(self, "shooting")
		return

	if Input.is_action_just_pressed("reload") and weapon.magazine.can_be_reloaded():
		transitioned.emit(self, "reloading")
