class_name InteractiveBarrier
extends Area2D
## Shelter barrier (B15, B16). The player opens it by holding `interact` inside its area,
## driven by PlayerInteractingBarrierState. Opening is irreversible: the blocker and its
## sprite go away, Events.barrier_opened fires and its own EnemySpawnZone joins the next waves.

const BALANCE_CONFIG: BalanceConfig = preload("res://resources/config/balance_config.tres")

@export var progress_bar: ProgressBar
@export var spawn_zone: EnemySpawnZone
@export var sprite: Sprite2D
@export var blocker_shape: CollisionShape2D

var _interaction_elapsed: float = 0.0
var _is_open: bool = false

func _ready() -> void:
	add_to_group(&"barriers")
	# Spawned enemies must join the map (Y-sorted), not the barrier itself
	if spawn_zone != null and spawn_zone.spawn_parent == null:
		spawn_zone.spawn_parent = get_parent()
	if progress_bar != null:
		progress_bar.hide()

## True when `body` is inside the area and the barrier can be opened right now.
## GDD §8: it stays locked until `barrier_unlock_wave` and only opens while a wave is active.
func can_interact(body: Node2D) -> bool:
	return not _is_open \
		and GameLoopManager.current_state == GameLoopManager.RunState.WAVE_ACTIVE \
		and GameLoopManager.wave_number >= BALANCE_CONFIG.barrier_unlock_wave \
		and overlaps_body(body)

func begin_interaction() -> void:
	_interaction_elapsed = 0.0
	_update_progress_bar(0.0)
	if progress_bar != null:
		progress_bar.show()

## Advances the hold by `delta` seconds. Returns true once the barrier is open.
func advance_interaction(delta: float) -> bool:
	if _is_open:
		return true
	_interaction_elapsed += delta
	var duration := maxf(BALANCE_CONFIG.barrier_interaction_duration, 0.001)
	var progress := clampf(_interaction_elapsed / duration, 0.0, 1.0)
	_update_progress_bar(progress)
	if progress >= 1.0:
		_open()
	return _is_open

func cancel_interaction() -> void:
	_interaction_elapsed = 0.0
	if progress_bar != null:
		progress_bar.hide()

func _open() -> void:
	_is_open = true
	# Let the player and enemies walk through the opening
	blocker_shape.set_deferred("disabled", true)
	sprite.hide()
	if progress_bar != null:
		progress_bar.hide()
	if spawn_zone != null:
		spawn_zone.set_enabled(true)
	else:
		push_warning("InteractiveBarrier: no spawn zone is assigned.")
	Events.barrier_opened.emit()

func _update_progress_bar(progress: float) -> void:
	if progress_bar != null:
		progress_bar.value = progress * progress_bar.max_value
