extends State
@export var player: Player
@export var inventory_controller: CanvasLayer

func enter() -> void:
	# Only this StateMachine stays awake during the pause, so it can detect the key that closes the inventory
	get_parent().process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().paused = true
	inventory_controller.visible = true
	#Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func exit() -> void:
	get_parent().process_mode = Node.PROCESS_MODE_INHERIT
	get_tree().paused = false
	inventory_controller.visible = false

func update(_delta) -> void:
	if Input.is_action_just_pressed("inventory"):
		transitioned.emit(self, "idle")
