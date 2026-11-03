class_name ResultsScreen
extends Control
## Minimal results screen (GDD §12): shown after a successful extraction with the loot
## Kade kept and the waves he survived. Lets the player start a new run or quit.

const MAIN_SCENE := "res://scenes/main/main.tscn"

## Items Kade extracted with. Set it before loading this scene.
static var kept_items: Array[String] = []
## Waves cleared before extracting. Set it before loading this scene.
static var waves_survived: int = 0

@onready var _waves_label: Label = %WavesLabel
@onready var _loot_label: Label = %LootLabel
@onready var _play_again_button: Button = %PlayAgainButton
@onready var _quit_button: Button = %QuitButton

func _ready() -> void:
	_waves_label.text = "Waves survived: %d" % waves_survived
	_loot_label.text = _build_loot_text()
	_play_again_button.pressed.connect(_on_play_again_pressed)
	_quit_button.pressed.connect(_on_quit_pressed)
	_play_again_button.grab_focus()

func _build_loot_text() -> String:
	if kept_items.is_empty():
		return "You extracted with no loot."
	var counts: Dictionary[String, int] = {}
	for item in kept_items:
		counts[item] = counts.get(item, 0) + 1
	var lines: PackedStringArray = ["Loot kept: %d" % kept_items.size()]
	for item in counts:
		lines.append("- %s x%d" % [item.capitalize(), counts[item]])
	return "\n".join(lines)

func _on_play_again_pressed() -> void:
	kept_items.clear()
	waves_survived = 0
	GameLoopManager.restart_run()
	get_tree().change_scene_to_file(MAIN_SCENE)

func _on_quit_pressed() -> void:
	get_tree().quit()
