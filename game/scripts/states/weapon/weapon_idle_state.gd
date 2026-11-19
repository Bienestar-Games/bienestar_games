class_name WeaponIdleState extends State

@export var weapon: Weapon

func enter() -> void:
	weapon._animation_player.play("idle")

func update(delta: float) -> void:
	# Holding `shoot` fires automatically, paced by the weapon's ShootCooldown.
	if Input.is_action_pressed("shoot"):
		if weapon.magazine.is_empty():
			# Only click once on an empty magazine instead of every frame while held.
			if Input.is_action_just_pressed("shoot"):
				weapon._animation_player.play("dry_shoot")
		else:
			transitioned.emit(self, "shooting")
			return

	# Holding `reload` reloads as soon as the magazine can be reloaded.
	if Input.is_action_pressed("reload") and weapon.magazine.can_be_reloaded():
		transitioned.emit(self, "reloading")
