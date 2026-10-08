# weapon_reloading_state.gd
class_name WeaponReloadingState extends State

@export var weapon: Weapon

func enter() -> void:
	weapon._animation_player.play("reload")
	weapon.magazine.reload()
	weapon.reload_cd.start()

func update(delta: float) -> void:
	if weapon.reload_cd.is_stopped():
		transitioned.emit(self, "idle")
