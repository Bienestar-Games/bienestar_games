extends State
@export var player: Player

func update(_delta) -> void:
	player._player_input()
	player.aim(player.get_global_mouse_position())
	player.handle_animation("idle")
	if Input.is_action_just_pressed("inventory"):
		transitioned.emit(self, "inventory")
	if Input.is_action_just_pressed("weapon_1"):
		player.switch_weapon(0)
	elif Input.is_action_just_pressed("weapon_2"):
		player.switch_weapon(1)
	elif Input.is_action_just_pressed("weapon_next"):
		player.switch_to_next_weapon()
	if !player.is_idle():
		transitioned.emit(self, "moving")
