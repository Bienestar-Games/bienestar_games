extends Node
## Autoload "GameLoopManager" (B22).
## Drives the only loop the game has: wave → short pause → next wave, forever. The run
## ends only when the player dies (end_run), so there is no extraction and no win screen.
## The pause between waves exists so the next-wave preview (B34) can show; its length lives
## in balance_config.decision_phase_duration.
## A run never starts by itself: main.gd calls start_run() once the scene is ready
## (after the tutorial on the first run of a session).

enum RunState { WAVE_ACTIVE, DECISION, DEAD }

const BALANCE_CONFIG: BalanceConfig = preload("res://resources/config/balance_config.tres")

var current_state: RunState = RunState.WAVE_ACTIVE
var wave_number: int = 0

func _ready() -> void:
	Events.wave_ended.connect(_on_wave_ended)

func _start_next_wave() -> void:
	wave_number += 1
	current_state = RunState.WAVE_ACTIVE
	Events.wave_started.emit(wave_number)

## Starts a new run from wave 1. Called by main.gd every time the main scene loads.
func start_run() -> void:
	wave_number = 0
	current_state = RunState.WAVE_ACTIVE
	# Defer so all scene nodes are ready before the first wave starts
	call_deferred("_start_next_wave")

# Called by player.gd on death — the only path out of a run.
func end_run() -> void:
	if current_state == RunState.DEAD:
		return
	current_state = RunState.DEAD
	Events.run_ended.emit()

func _on_wave_ended() -> void:
	if current_state != RunState.WAVE_ACTIVE:
		return
	current_state = RunState.DECISION
	Events.decision_phase_started.emit()
	var duration := maxf(BALANCE_CONFIG.decision_phase_duration, 0.0)
	if duration > 0.0:
		await get_tree().create_timer(duration, false).timeout
	# The player may have died during the pause
	if current_state != RunState.DECISION:
		return
	_start_next_wave()
