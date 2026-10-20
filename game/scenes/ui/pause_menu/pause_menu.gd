class_name PauseMenu
extends CanvasLayer
## Minimal pause menu (GDD §12): Esc / Start pauses the run and offers resume or quit.

@onready var _resume_button: Button = %ResumeButton
@onready var _quit_button: Button = %QuitButton

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	_resume_button.pressed.connect(_resume)
	_quit_button.pressed.connect(_on_quit_pressed)

func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("pause"):
		return
	if visible:
		_resume()
	# Don't stack on top of another pause owner such as the inventory
	elif not get_tree().paused:
		_pause()
	get_viewport().set_input_as_handled()

func _pause() -> void:
	get_tree().paused = true
	visible = true
	_resume_button.grab_focus()

func _resume() -> void:
	visible = false
	get_tree().paused = false

func _on_quit_pressed() -> void:
	get_tree().quit()
