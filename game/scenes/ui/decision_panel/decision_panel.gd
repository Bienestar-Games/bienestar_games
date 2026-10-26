class_name DecisionPanel
extends CanvasLayer
## Simplified extraction panel (GDD §4, §8 Nivel 2). Shown during decision_state:
## compares the loot Kade keeps if he extracts now against continuing to the next wave.

@onready var _wave_label: Label = %WaveLabel
@onready var _loot_label: Label = %LootLabel
@onready var _continue_label: Label = %ContinueLabel
@onready var _continue_button: Button = %ContinueButton
@onready var _extract_button: Button = %ExtractButton

func _ready() -> void:
	visible = false
	_continue_button.pressed.connect(_on_continue_pressed)
	_extract_button.pressed.connect(_on_extract_pressed)
	Events.decision_phase_started.connect(_show_panel)
	Events.wave_started.connect(_hide_panel.unbind(1))
	Events.extraction_started.connect(_hide_panel)
	Events.run_ended.connect(_hide_panel.unbind(1))

func _show_panel() -> void:
	var wave_number: int = GameLoopManager.wave_number
	_wave_label.text = "Wave %d cleared" % wave_number
	_loot_label.text = _build_loot_text()
	_continue_label.text = "Next: wave %d\nMore enemies, better loot.\nDie and you lose everything." % (wave_number + 1)
	visible = true
	_continue_button.grab_focus()

func _hide_panel() -> void:
	visible = false

func _build_loot_text() -> String:
	var player := get_tree().get_first_node_in_group("player") as Player
	if player == null or player.inventory.is_empty():
		return "No loot yet."
	var counts: Dictionary[String, int] = {}
	for item in player.inventory:
		counts[item] = counts.get(item, 0) + 1
	var lines: PackedStringArray = ["Loot secured: %d / %d" % [player.inventory.size(), Player.BALANCE_CONFIG.max_inventory_slots]]
	for item in counts:
		lines.append("- %s x%d" % [item.capitalize(), counts[item]])
	return "\n".join(lines)

func _on_continue_pressed() -> void:
	GameLoopManager.continue_run()

func _on_extract_pressed() -> void:
	GameLoopManager.request_extraction()
