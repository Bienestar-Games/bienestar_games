extends Node
## Autoload "ThreatManager" (B29, GDD §8 level 3, §15.4).
## Keeps the run's single threat level: a hidden multiplier that grows with the wave
## number and with the arrival of fast melee enemies. Systems read it to scale what the
## threat is worth, e.g. loot quality (B31) or the risk level shown to the player (B30).
## The multiplier is internal; the UI must never show it as a number (pillar a).
##
## Usage:
## - `ThreatManager.multiplier`: threat of the current wave, or of the upcoming wave
##   while the player is deciding between waves.
## - `ThreatManager.threat_type`: enemy mix of that same wave.
## - `ThreatManager.risk_level`: the multiplier as a RiskLevel word (B30), the only form
##   of the threat the player may see.
## - `Events.threat_changed(multiplier)`: emitted every time the multiplier changes.
## - `Events.risk_level_changed(risk_level)`: emitted every time the risk level changes.
## - `get_multiplier_for_wave(n)` / `get_threat_type_for_wave(n)`: same values for any wave,
##   and `get_risk_level_for_multiplier(m)`.

## General kind of enemies in a wave, for the next-wave preview (GDD §10).
enum ThreatType {
	## Only slow melee enemies.
	SLOW_HORDE,
	## Slow and fast melee enemies mixed (B19, from melee_fast_first_wave on).
	FAST_HORDE,
}

## Estimated risk of a wave (GDD §10): low / medium / high / extreme, never a number.
enum RiskLevel { LOW, MEDIUM, HIGH, EXTREME }

const BALANCE_CONFIG: BalanceConfig = preload("res://resources/config/balance_config.tres")

## Wave the current threat refers to (the upcoming one during the decision phase).
var wave_number: int = 0
var multiplier: float = 1.0
var threat_type: ThreatType = ThreatType.SLOW_HORDE
var risk_level: RiskLevel = RiskLevel.LOW


func _ready() -> void:
	Events.wave_started.connect(_on_wave_started)
	Events.decision_phase_started.connect(_on_decision_phase_started)
	Events.run_ended.connect(_on_run_ended)


## Clears the threat for a new run.
func reset() -> void:
	wave_number = 0
	_update_threat()


## Threat multiplier of `wave`. The base escalation grows per wave, with a fixed bonus added
## for every wave that mixes in fast melee enemies, never compounded wave after wave (GDD §4).
func get_multiplier_for_wave(wave: int) -> float:
	var value := 1.0 + BALANCE_CONFIG.threat_wave_step * maxi(wave - 1, 0)
	if get_threat_type_for_wave(wave) == ThreatType.FAST_HORDE:
		value += BALANCE_CONFIG.threat_fast_enemies_bonus
	return value


func get_threat_type_for_wave(wave: int) -> ThreatType:
	if wave >= BALANCE_CONFIG.melee_fast_first_wave:
		return ThreatType.FAST_HORDE
	return ThreatType.SLOW_HORDE


## Risk level of a threat multiplier, using the thresholds in balance_config.tres (B30).
func get_risk_level_for_multiplier(value: float) -> RiskLevel:
	if value >= BALANCE_CONFIG.risk_extreme_threshold:
		return RiskLevel.EXTREME
	if value >= BALANCE_CONFIG.risk_high_threshold:
		return RiskLevel.HIGH
	if value >= BALANCE_CONFIG.risk_medium_threshold:
		return RiskLevel.MEDIUM
	return RiskLevel.LOW


func _on_wave_started(wave: int) -> void:
	wave_number = wave
	_update_threat()


## Between waves the threat already describes the wave the player is about to choose.
func _on_decision_phase_started() -> void:
	wave_number = GameLoopManager.wave_number + 1
	_update_threat()


func _on_run_ended() -> void:
	reset()


func _update_threat() -> void:
	var new_multiplier := get_multiplier_for_wave(maxi(wave_number, 1))
	threat_type = get_threat_type_for_wave(maxi(wave_number, 1))
	if not is_equal_approx(new_multiplier, multiplier):
		multiplier = new_multiplier
		Events.threat_changed.emit(multiplier)
	var new_risk_level := get_risk_level_for_multiplier(multiplier)
	if new_risk_level != risk_level:
		risk_level = new_risk_level
		Events.risk_level_changed.emit(risk_level)
