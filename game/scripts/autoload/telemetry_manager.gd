extends Node
## Autoload "TelemetryManager".
## Records how every wave went and hands it to DifficultyManager, which adapts the
## difficulty. Each run is also written to user://telemetry/run_<date>.jsonl, one JSON
## object per line, so the team can tune balance_config.tres from real playtests (B40):
## - {"type": "wave", "wave", "duration", "enemies", "kills", "shots", "hits", "accuracy",
##    "damage_taken", "health_start", "health_end", "max_health", "pickups", "died",
##    "score", "difficulty_before", "difficulty_after"}
## - {"type": "run_end", "wave", "total_time", "total_kills", "best_wave"}
## Nothing here is shown to the player.

const TELEMETRY_DIR := "user://telemetry"

## Report of the wave in progress; empty between waves.
var _wave: Dictionary = {}
var _wave_active: bool = false
var _player: Player
var _last_health: float = 0.0
var _file: FileAccess
var _run_time: float = 0.0
var _run_kills: int = 0


func _ready() -> void:
	Events.wave_started.connect(_on_wave_started)
	Events.wave_ended.connect(_on_wave_ended)
	Events.run_ended.connect(_on_run_ended)
	Events.item_picked_up.connect(_on_item_picked_up)
	# Bullets and enemies are created all the time; catch them as they enter the tree
	get_tree().node_added.connect(_on_node_added)


func _process(delta: float) -> void:
	# Paused with the game, so pause and stats menus don't count as playing time
	if _wave_active:
		_wave["duration"] += delta
		_run_time += delta


func _on_wave_started(wave_number: int) -> void:
	if wave_number == 1:
		_open_run_file()
	_bind_player()
	var health := _player.base_health if _player != null else 0.0
	_wave = {
		"type": "wave",
		"wave": wave_number,
		"duration": 0.0,
		"enemies": 0,
		"kills": 0,
		"shots": 0,
		"hits": 0,
		"damage_taken": 0.0,
		"health_start": health,
		"max_health": _player.max_health if _player != null else 0.0,
		"pickups": 0,
		"died": false,
	}
	_wave_active = true


func _on_wave_ended() -> void:
	_finish_wave(false)


func _on_run_ended() -> void:
	_finish_wave(true)
	_write({
		"type": "run_end",
		"wave": GameLoopManager.wave_number,
		"total_time": snappedf(_run_time, 0.01),
		"total_kills": _run_kills,
		"best_wave": SaveManager.best_wave,
	})
	_close_run_file()


func _finish_wave(died: bool) -> void:
	if not _wave_active:
		return
	_wave_active = false
	_wave["died"] = died
	_wave["health_end"] = _player.base_health if is_instance_valid(_player) else 0.0
	_wave["duration"] = snappedf(_wave["duration"], 0.01)
	var shots: int = _wave["shots"]
	_wave["accuracy"] = 0.0 if shots == 0 else snappedf(float(_wave["hits"]) / shots, 0.01)
	_wave.merge(DifficultyManager.apply_wave_report(_wave), true)
	_write(_wave)
	_wave = {}


# --- Data sources ----------------------------------------------------------------------

func _bind_player() -> void:
	var player := get_tree().get_first_node_in_group("player") as Player
	if player == _player:
		return
	_player = player
	if _player != null:
		_last_health = _player.base_health
		_player.health_changed.connect(_on_player_health_changed)


func _on_player_health_changed(health: float, _max_health: float) -> void:
	if _wave_active and health < _last_health:
		_wave["damage_taken"] += _last_health - health
	_last_health = health


func _on_node_added(node: Node) -> void:
	if not _wave_active:
		return
	if node is Bullet:
		_wave["shots"] += 1
	elif node is Enemy:
		_wave["enemies"] += 1
		var enemy := node as Enemy
		enemy.damage_taken.connect(_on_enemy_hit)
		enemy.died.connect(_on_enemy_died, CONNECT_ONE_SHOT)


func _on_enemy_hit() -> void:
	if _wave_active:
		_wave["hits"] += 1


func _on_enemy_died() -> void:
	if _wave_active:
		_wave["kills"] += 1
		_run_kills += 1


func _on_item_picked_up(_item: ItemData) -> void:
	if _wave_active:
		_wave["pickups"] += 1


# --- File ------------------------------------------------------------------------------

func _open_run_file() -> void:
	_close_run_file()
	_run_time = 0.0
	_run_kills = 0
	DirAccess.make_dir_recursive_absolute(TELEMETRY_DIR)
	var stamp := Time.get_datetime_string_from_system().replace(":", "-").replace("T", "_")
	var path := "%s/run_%s.jsonl" % [TELEMETRY_DIR, stamp]
	_file = FileAccess.open(path, FileAccess.WRITE)
	if _file == null:
		push_warning("TelemetryManager: could not open %s (error %d)." % [path, FileAccess.get_open_error()])


func _write(entry: Dictionary) -> void:
	if _file == null:
		return
	_file.store_line(JSON.stringify(entry))
	# Flush every line so a crash or a quit mid-run still keeps the data
	_file.flush()


func _close_run_file() -> void:
	if _file != null:
		_file.close()
		_file = null
