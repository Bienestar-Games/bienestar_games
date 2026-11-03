class_name WeaponShootingState extends State

@export var weapon: Weapon

func enter() -> void:
	weapon.magazine.consume_bullet()
	weapon._animation_player.play("shoot")
	weapon._spawn_bullet()
	weapon.shoot_cd.start()

func update(delta: float) -> void:
	if weapon.shoot_cd.is_stopped():
		transitioned.emit(self, "idle")
