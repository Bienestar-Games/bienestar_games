class_name DecisionPanel
extends CanvasLayer
## Simplified extraction panel (GDD §4, §8 Nivel 2). Shown during decision_state:
## compares the loot Kade keeps if he extracts now against continuing to the next wave.
## The next-wave preview (B34, GDD §10) shows the general threat type and the risk level
## as words and a color, never numbers. Both come from ThreatManager through the Events bus.

## Threat type of the next wave, by ThreatManager.ThreatType.
const THREAT_TYPE_TEXTS: Dictionary[int, String] = {
	ThreatManager.ThreatType.SLOW_HORDE: "A slow horde",
	ThreatManager.ThreatType.FAST_HORDE: "A horde with fast runners",
}
## Risk word of the next wave, by ThreatManager.RiskLevel.
const RISK_LEVEL_TEXTS: Dictionary[int, String] = {
	ThreatManager.RiskLevel.LOW: "LOW",
	ThreatManager.RiskLevel.MEDIUM: "MEDIUM",
	ThreatManager.RiskLevel.HIGH: "HIGH",
	ThreatManager.RiskLevel.EXTREME: "EXTREME",
}

@export var risk_low_color: Color = Color(0.3, 0.8, 0.3)
@export var risk_medium_color: Color = Color(0.95, 0.8, 0.2)
@export var risk_high_color: Color = Color(0.95, 0.45, 0.15)
@export var risk_extreme_color: Color = Color(0.85, 0.1, 0.1)

@onready var _wave_label: Label = %WaveLabel
@onready var _loot_label: Label = %LootLabel
@onready var _next_wave_label: Label = %NextWaveLabel
@onready var _threat_label: Label = %ThreatLabel
@onready var _risk_swatch: ColorRect = %RiskSwatch
@onready var _risk_label: Label = %RiskLabel
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
	Events.threat_changed.connect(_on_threat_changed.unbind(1))
	Events.risk_level_changed.connect(_update_risk)
	_on_threat_changed()
	_update_risk(ThreatManager.risk_level)

func _show_panel() -> void:
	var wave_number: int = GameLoopManager.wave_number
	_wave_label.text = "Wave %d cleared" % wave_number
	_loot_label.text = _build_loot_text()
	_next_wave_label.text = "Next: wave %d" % (wave_number + 1)
	# The threat type can change with the wave even when the multiplier does not
	_on_threat_changed()
	visible = true
	_continue_button.grab_focus()

## ThreatManager already describes the upcoming wave when the decision phase starts.
func _on_threat_changed() -> void:
	_threat_label.text = THREAT_TYPE_TEXTS.get(ThreatManager.threat_type, "")

func _update_risk(risk_level: int) -> void:
	_risk_label.text = RISK_LEVEL_TEXTS.get(risk_level, "")
	var color := _get_risk_color(risk_level)
	_risk_label.add_theme_color_override("font_color", color)
	_risk_swatch.color = color

func _get_risk_color(risk_level: int) -> Color:
	match risk_level:
		ThreatManager.RiskLevel.MEDIUM:
			return risk_medium_color
		ThreatManager.RiskLevel.HIGH:
			return risk_high_color
		ThreatManager.RiskLevel.EXTREME:
			return risk_extreme_color
	return risk_low_color

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
