extends Node

enum RunState { WAVE_ACTIVE, DECISION, EXTRACTING, DEAD }

var current_state: RunState = RunState.WAVE_ACTIVE
var wave_number: int = 0

func _ready() -> void:
	Events.wave_ended.connect(_on_wave_ended)
	Events.extraction_completed.connect(_on_extraction_completed)
	Events.extraction_cancelled.connect(_on_extraction_cancelled)
	# Defer so all scene nodes are ready before the first wave starts
	call_deferred("_start_next_wave")

func _start_next_wave() -> void:
	wave_number += 1
	current_state = RunState.WAVE_ACTIVE
	Events.wave_started.emit(wave_number)

# Called by the death screen before reloading the main scene for a new run
func restart_run() -> void:
	wave_number = 0
	current_state = RunState.WAVE_ACTIVE
	call_deferred("_start_next_wave")

# Called by UI decision panel when player chooses to continue
func continue_run() -> void:
	if current_state != RunState.DECISION:
		return
	_start_next_wave()

# Called by UI decision panel when player chooses to extract
func request_extraction() -> void:
	if current_state != RunState.DECISION:
		return
	current_state = RunState.EXTRACTING
	Events.extraction_started.emit()

# Called by extracting_state on completion or by player on death
func end_run(extracted: bool) -> void:
	if current_state == RunState.DEAD:
		return
	current_state = RunState.DEAD
	Events.run_ended.emit(extracted)

func _on_wave_ended() -> void:
	if current_state != RunState.WAVE_ACTIVE:
		return
	current_state = RunState.DECISION
	Events.decision_phase_started.emit()

func _on_extraction_completed() -> void:
	end_run(true)

# A cancelled channel costs time and risk, not the run (GDD §15): go back to the
# decision so the player can choose again between extracting and continuing.
func _on_extraction_cancelled() -> void:
	if current_state != RunState.EXTRACTING:
		return
	current_state = RunState.DECISION
	# Deferred: player.gd and PlayerExtractingState force "idle" on the same signal,
	# so emitting now would leave the player in idle instead of decision.
	call_deferred("_resume_decision_phase")

func _resume_decision_phase() -> void:
	# A lethal hit cancels the channel and kills the player in the same frame
	if current_state != RunState.DECISION:
		return
	Events.decision_phase_started.emit()
