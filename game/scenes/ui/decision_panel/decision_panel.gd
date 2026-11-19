class_name DecisionPanel
extends CanvasLayer
## Short pause panel between waves (B22, B34, GDD §10). Waves escalate forever, so this
## is only a preview + countdown: the next wave's threat type and risk level (words and
## colors, never numbers) come from ThreatManager via the Events bus. The panel never
## allows a decision — GameLoopManager advances on its own after
## balance_config.decision_phase_duration.

const BALANCE_CONFIG: BalanceConfig = preload("res://resources/config/balance_config.tres")

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
@onready var _next_wave_label: Label = %NextWaveLabel
@onready var _threat_label: Label = %ThreatLabel
@onready var _risk_swatch: ColorRect = %RiskSwatch
@onready var _risk_label: Label = %RiskLabel
@onready var _countdown_label: Label = %CountdownLabel

var _countdown_remaining: float = 0.0

func _ready() -> void:
	visible = false
	set_process(false)
	Events.decision_phase_started.connect(_show_panel)
	Events.wave_started.connect(_hide_panel.unbind(1))
	Events.run_ended.connect(_hide_panel)
	Events.threat_changed.connect(_on_threat_changed.unbind(1))
	Events.risk_level_changed.connect(_update_risk)
	_on_threat_changed()
	_update_risk(ThreatManager.risk_level)

func _show_panel() -> void:
	var wave_number: int = GameLoopManager.wave_number
	_wave_label.text = "Wave %d cleared" % wave_number
	_next_wave_label.text = "Next: wave %d" % (wave_number + 1)
	# The threat type can change with the wave even when the multiplier does not
	_on_threat_changed()
	_countdown_remaining = maxf(BALANCE_CONFIG.decision_phase_duration, 0.0)
	_update_countdown()
	visible = true
	set_process(_countdown_remaining > 0.0)

func _process(delta: float) -> void:
	_countdown_remaining = maxf(_countdown_remaining - delta, 0.0)
	_update_countdown()
	if _countdown_remaining <= 0.0:
		set_process(false)

func _update_countdown() -> void:
	_countdown_label.text = "Next wave in %d…" % ceili(_countdown_remaining)

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
	set_process(false)
