class_name PlayerExtractingState
extends State

@export var player: Player

# Seconds the player must remain undisturbed to complete extraction (§8 MVP)
const CHANNEL_TIME: float = 5.0

var _timer: float = 0.0

signal extraction_progress_updated(progress: float)

func enter() -> void:
	_timer = CHANNEL_TIME
	player.stop_moving()
	player.damage_taken.connect(_on_damage_taken)
	Events.extraction_cancelled.connect(_on_cancelled)

func exit() -> void:
	if player.damage_taken.is_connected(_on_damage_taken):
		player.damage_taken.disconnect(_on_damage_taken)
	if Events.extraction_cancelled.is_connected(_on_cancelled):
		Events.extraction_cancelled.disconnect(_on_cancelled)

func update(delta: float) -> void:
	_timer -= delta
	extraction_progress_updated.emit(1.0 - (_timer / CHANNEL_TIME))
	if _timer <= 0.0:
		Events.extraction_completed.emit()
		transitioned.emit(self, "idle")

func _on_damage_taken() -> void:
	# Let _on_cancelled handle the transition after emitting the cancel signal
	Events.extraction_cancelled.emit()

func _on_cancelled() -> void:
	# Disconnect first to prevent re-entry if emitting cancelled again
	if Events.extraction_cancelled.is_connected(_on_cancelled):
		Events.extraction_cancelled.disconnect(_on_cancelled)
	if player.damage_taken.is_connected(_on_damage_taken):
		player.damage_taken.disconnect(_on_damage_taken)
	transitioned.emit(self, "idle")
