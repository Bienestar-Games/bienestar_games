extends State
@export var player : Player

func update(delta: float) -> void:
	player._player_input()
	player.aim(player.get_global_mouse_position())
	player.move(player.move_direction, delta)
	player.handle_animation("moving")
	
	if player.is_idle():
		transitioned.emit(self, "idle")
