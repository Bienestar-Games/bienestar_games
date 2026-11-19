class_name GameOverScreen
extends Control
## Game-over screen (GDD §12). Waves escalate forever, so a run only ends when the
## player dies — this is the only final screen. Shows the waves cleared before dying
## and lets the player retry or quit.

const MAIN_SCENE := "res://scenes/main/main.tscn"

## Waves cleared before dying. Set it before loading this scene.
static var waves_survived: int = 0

@onready var _waves_label: Label = %WavesLabel
@onready var _retry_button: Button = %RetryButton
@onready var _quit_button: Button = %QuitButton

func _ready() -> void:
	_waves_label.text = "Waves survived: %d" % waves_survived
	_retry_button.pressed.connect(_on_retry_pressed)
	_quit_button.pressed.connect(_on_quit_pressed)
	_retry_button.grab_focus()

func _on_retry_pressed() -> void:
	waves_survived = 0
	GameLoopManager.restart_run()
	get_tree().change_scene_to_file(MAIN_SCENE)

func _on_quit_pressed() -> void:
	get_tree().quit()
