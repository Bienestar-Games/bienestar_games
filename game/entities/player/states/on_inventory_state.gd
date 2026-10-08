extends State
@export var player: Player
@export var inventory_controller: CanvasLayer

func enter() -> void:
	get_tree().paused = true
	inventory_controller.visible = true
	#Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func update(_delta) -> void:
	if Input.is_action_just_pressed("inventory"):
		get_tree().paused = false
		inventory_controller.visible = false
		transitioned.emit(self, "idle")
