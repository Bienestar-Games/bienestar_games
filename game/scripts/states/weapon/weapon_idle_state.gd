class_name WeaponIdleState extends State

@export var weapon: Weapon

func enter() -> void:
	weapon._animation_player.play("idle")

func update(delta: float) -> void:
	# An empty magazine reloads on its own, without pressing `reload`.
	if weapon.magazine.is_empty():
		transitioned.emit(self, "reloading")
		return

	# Holding `shoot` fires automatically, paced by the weapon's ShootCooldown.
	if Input.is_action_pressed("shoot"):
		transitioned.emit(self, "shooting")
		return

	# Holding `reload` reloads a partially used magazine.
	if Input.is_action_pressed("reload") and weapon.magazine.can_be_reloaded():
		transitioned.emit(self, "reloading")
