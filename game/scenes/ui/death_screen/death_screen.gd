class_name DeathScreen
extends Control
## Minimal death screen (GDD §12): shows the loot lost in the run and lets the player retry or quit.

const MAIN_SCENE := "res://scenes/main/main.tscn"

## Items Kade was carrying when he died. Set it before loading this scene.
static var lost_items: Array[ItemData] = []

@onready var _loot_label: Label = %LootLabel
@onready var _retry_button: Button = %RetryButton
@onready var _quit_button: Button = %QuitButton

func _ready() -> void:
	_loot_label.text = _build_loot_text()
	_retry_button.pressed.connect(_on_retry_pressed)
	_quit_button.pressed.connect(_on_quit_pressed)
	_retry_button.grab_focus()

func _build_loot_text() -> String:
	if lost_items.is_empty():
		return "You had no loot to lose."
	var lines: PackedStringArray = ["Loot lost:"]
	for item in lost_items:
		lines.append("- " + item.item_name)
	return "\n".join(lines)

func _on_retry_pressed() -> void:
	lost_items.clear()
	GameLoopManager.restart_run()
	get_tree().change_scene_to_file(MAIN_SCENE)

func _on_quit_pressed() -> void:
	get_tree().quit()
