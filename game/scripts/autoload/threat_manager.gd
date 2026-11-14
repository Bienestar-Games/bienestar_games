extends Node
## Autoload "ThreatManager" (B29, GDD §8 level 3, §15.4).
## Keeps the run's single threat level: a hidden multiplier that grows with the wave
## number, with the arrival of fast melee enemies and with every open barrier. It never
## spawns enemies (the barrier is only a door): systems read it to scale what the threat
## is worth, e.g. loot quality (B31) or the risk level shown to the player (B30).
## The multiplier is internal; the UI must never show it as a number (pillar a).
##
## Usage:
## - `ThreatManager.multiplier`: threat of the current wave, or of the upcoming wave
##   while the player is deciding between waves.
## - `ThreatManager.threat_type`: enemy mix of that same wave.
## - `Events.threat_changed(multiplier)`: emitted every time the multiplier changes.
## - `get_multiplier_for_wave(n)` / `get_threat_type_for_wave(n)`: same values for any wave.

## General kind of enemies in a wave, for the next-wave preview (GDD §10).
enum ThreatType {
	## Only slow melee enemies.
	SLOW_HORDE,
	## Slow and fast melee enemies mixed (B19, from melee_fast_first_wave on).
	FAST_HORDE,
}

const BALANCE_CONFIG: BalanceConfig = preload("res://resources/config/balance_config.tres")

## Wave the current threat refers to (the upcoming one during the decision phase).
var wave_number: int = 0
var multiplier: float = 1.0
var threat_type: ThreatType = ThreatType.SLOW_HORDE
## Barriers opened this run. Opening is irreversible, so this only grows.
var open_barriers: int = 0


func _ready() -> void:
	Events.wave_started.connect(_on_wave_started)
	Events.decision_phase_started.connect(_on_decision_phase_started)
	Events.barrier_opened.connect(_on_barrier_opened)
	Events.run_ended.connect(_on_run_ended)


## Clears the threat for a new run.
func reset() -> void:
	wave_number = 0
	open_barriers = 0
	_update_threat()


## Threat multiplier of `wave` with the barriers that are open right now. The barrier bonus
## is a fixed amount per open barrier added on top of the base escalation, never compounded
## wave after wave (GDD §4).
func get_multiplier_for_wave(wave: int) -> float:
	var value := 1.0 + BALANCE_CONFIG.threat_wave_step * maxi(wave - 1, 0)
	if get_threat_type_for_wave(wave) == ThreatType.FAST_HORDE:
		value += BALANCE_CONFIG.threat_fast_enemies_bonus
	value += BALANCE_CONFIG.threat_barrier_open_bonus * open_barriers
	return value


func get_threat_type_for_wave(wave: int) -> ThreatType:
	if wave >= BALANCE_CONFIG.melee_fast_first_wave:
		return ThreatType.FAST_HORDE
	return ThreatType.SLOW_HORDE


func _on_wave_started(wave: int) -> void:
	# A new run starts at wave 1: forget the barriers of the previous run
	if wave <= 1:
		open_barriers = 0
	wave_number = wave
	_update_threat()


## Between waves the threat already describes the wave the player is about to choose.
func _on_decision_phase_started() -> void:
	wave_number = GameLoopManager.wave_number + 1
	_update_threat()


func _on_barrier_opened() -> void:
	open_barriers += 1
	_update_threat()


func _on_run_ended(_extracted: bool) -> void:
	reset()


func _update_threat() -> void:
	var new_multiplier := get_multiplier_for_wave(maxi(wave_number, 1))
	threat_type = get_threat_type_for_wave(maxi(wave_number, 1))
	if is_equal_approx(new_multiplier, multiplier):
		return
	multiplier = new_multiplier
	Events.threat_changed.emit(multiplier)
