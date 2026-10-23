class_name InteractiveBarrier
extends Area2D

signal interaction_progress_changed(progress: float)
signal barrier_opened

const BALANCE_CONFIG: BalanceConfig = preload("res://resources/config/balance_config.tres")

@export var interaction_action: StringName = &"interact"
@export var progress_bar: ProgressBar
@export var spawn_zone: EnemySpawnZone

var _player_in_range: Player
var _interaction_elapsed: float = 0.0
var _is_open: bool = false

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	if spawn_zone != null and spawn_zone.spawn_parent == null:
		spawn_zone.spawn_parent = get_parent()
	if progress_bar != null:
		progress_bar.hide()

func _process(delta: float) -> void:
	if _is_open or _player_in_range == null:
		return

	if not Input.is_action_pressed(interaction_action):
		_reset_interaction()
		return

	_interaction_elapsed += delta
	var duration := maxf(BALANCE_CONFIG.barrier_interaction_duration, 0.001)
	var progress := clampf(_interaction_elapsed / duration, 0.0, 1.0)
	interaction_progress_changed.emit(progress)
	_update_progress_bar(progress)

	if progress >= 1.0:
		_open_barrier()

func _open_barrier() -> void:
	if _is_open:
		return
	_is_open = true
	if spawn_zone != null:
		spawn_zone.set_enabled(true)
	else:
		push_warning("InteractiveBarrier: no spawn zone is assigned.")
	barrier_opened.emit()
	Events.barrier_opened.emit()
	if progress_bar != null:
		progress_bar.hide()

func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		_player_in_range = body
		if progress_bar != null and not _is_open:
			progress_bar.show()

func _on_body_exited(body: Node2D) -> void:
	if body == _player_in_range:
		_player_in_range = null
		_reset_interaction()
		if progress_bar != null:
			progress_bar.hide()

func _reset_interaction() -> void:
	if _interaction_elapsed == 0.0:
		return
	_interaction_elapsed = 0.0
	interaction_progress_changed.emit(0.0)
	_update_progress_bar(0.0)

func _update_progress_bar(progress: float) -> void:
	if progress_bar != null:
		progress_bar.value = progress * progress_bar.max_value
