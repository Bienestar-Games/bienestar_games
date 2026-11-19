extends Node
## Autoload "DifficultyManager".
## Adaptive difficulty driven by TelemetryManager: after every wave it scores how well
## the player did (health kept, clear speed, accuracy) and nudges a hidden difficulty
## value up or down inside [difficulty_min, difficulty_max]. Dying lowers it for the next
## run. WaveManager reads it through get_scale() to scale enemy count, health, speed and
## spawn rate. Like the threat, the difficulty is internal and never shown (pillar a).
## Every number lives in balance_config.tres → "Adaptive difficulty".

const BALANCE_CONFIG: BalanceConfig = preload("res://resources/config/balance_config.tres")
const SAVE_SECTION := "difficulty"
const SAVE_KEY := "level"

## Current difficulty: 1.0 plays balance_config as is, lower is easier, higher is harder.
var difficulty: float = 1.0


func _ready() -> void:
	if not BALANCE_CONFIG.adaptive_difficulty_enabled:
		difficulty = 1.0
		return
	# The difficulty carries over between runs and sessions
	difficulty = _clamp_difficulty(float(SaveManager.get_value(SAVE_SECTION, SAVE_KEY, 1.0)))


## Multiplier for a knob that takes `influence` (0–1) of the difficulty.
## E.g. difficulty 1.2 with influence 0.5 returns 1.1.
func get_scale(influence: float) -> float:
	return lerpf(1.0, difficulty, clampf(influence, 0.0, 1.0))


## Performance (0 = terrible, 1 = flawless) of a wave report from TelemetryManager.
func score_wave(report: Dictionary) -> float:
	var max_health := maxf(float(report.get("max_health", 1.0)), 1.0)
	var health_score := 1.0 - clampf(float(report.get("damage_taken", 0.0)) / max_health, 0.0, 1.0)

	var expected_time := float(report.get("enemies", 0)) * BALANCE_CONFIG.difficulty_seconds_per_enemy
	var duration := maxf(float(report.get("duration", 0.0)), 0.01)
	var speed_score := clampf(expected_time / duration, 0.0, 1.0)

	var shots := int(report.get("shots", 0))
	# Neutral when the player did not shoot at all
	var accuracy_score := 0.5 if shots == 0 else clampf(float(report.get("hits", 0)) / shots, 0.0, 1.0)

	var weights := BALANCE_CONFIG.difficulty_health_weight + BALANCE_CONFIG.difficulty_speed_weight + BALANCE_CONFIG.difficulty_accuracy_weight
	if weights <= 0.0:
		return 0.5
	return (health_score * BALANCE_CONFIG.difficulty_health_weight
		+ speed_score * BALANCE_CONFIG.difficulty_speed_weight
		+ accuracy_score * BALANCE_CONFIG.difficulty_accuracy_weight) / weights


## Adjusts the difficulty from a finished wave (or the wave the player died in) and
## returns what changed, so TelemetryManager can log it.
func apply_wave_report(report: Dictionary) -> Dictionary:
	var before := difficulty
	var score := score_wave(report)
	if BALANCE_CONFIG.adaptive_difficulty_enabled:
		if report.get("died", false):
			difficulty -= BALANCE_CONFIG.difficulty_death_step
		elif score >= BALANCE_CONFIG.difficulty_good_score:
			difficulty += BALANCE_CONFIG.difficulty_step_up
		elif score <= BALANCE_CONFIG.difficulty_bad_score:
			difficulty -= BALANCE_CONFIG.difficulty_step_down
		difficulty = _clamp_difficulty(difficulty)
		if not is_equal_approx(before, difficulty):
			SaveManager.set_value(SAVE_SECTION, SAVE_KEY, difficulty)
	return {
		"score": snappedf(score, 0.01),
		"difficulty_before": snappedf(before, 0.01),
		"difficulty_after": snappedf(difficulty, 0.01),
	}


func _clamp_difficulty(value: float) -> float:
	return clampf(value, BALANCE_CONFIG.difficulty_min, BALANCE_CONFIG.difficulty_max)
