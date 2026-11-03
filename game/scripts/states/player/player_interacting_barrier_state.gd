class_name PlayerInteractingBarrierState
extends State
## Hold `interact` next to an InteractiveBarrier to open it (B15, GDD §11).
## The player can neither move nor fight while holding: opening is a deliberate commitment.

@export var player: Player

var _barrier: InteractiveBarrier

func enter() -> void:
	_barrier = player.get_interactable_barrier()
	player.stop_moving()
	player.handle_animation("idle")
	player.set_weapons_enabled(false)
	if _barrier != null:
		_barrier.begin_interaction()

func exit() -> void:
	if is_instance_valid(_barrier):
		_barrier.cancel_interaction()
	_barrier = null
	player.set_weapons_enabled(true)

func update(delta: float) -> void:
	if _barrier == null or not Input.is_action_pressed("interact") or not _barrier.can_interact(player):
		transitioned.emit(self, "idle")
		return
	if _barrier.advance_interaction(delta):
		transitioned.emit(self, "idle")
