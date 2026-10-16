extends Node
## Autoload "WaveManager" (B08).
## Listens to Events.wave_started (emitted by GameLoopManager), spawns a fixed number of
## enemies across every EnemySpawnZone of the current map and emits Events.wave_ended
## when all of them are dead. It never decides when a wave starts: that is GameLoopManager (B22).
## TODO(B17): scale enemy_count with the wave number / threat.
## TODO(B20): read enemy_count and spawn_interval from balance_config.tres.

## Emitted every time the number of alive enemies of the current wave changes.
signal enemies_remaining_changed(enemies_remaining: int)

const MIN_ENEMY_COUNT: int = 5
const MAX_ENEMY_COUNT: int = 8
## Safety limit while waiting for the navigation map to sync (~2 s at 60 fps).
const NAVIGATION_WAIT_MAX_FRAMES: int = 120
## Safety limit while waiting for the map to enter the tree (~1 s at 60 fps).
const MAP_WAIT_MAX_FRAMES: int = 60
const MELEE_BASIC_SCENE: PackedScene = preload("res://scenes/entities/enemies/melee_basic/melee_basic.tscn")

## Fixed enemy count per wave (GDD §8, level 1: 5–8 enemies).
var enemy_count: int = 6:
	set(value):
		enemy_count = clampi(value, MIN_ENEMY_COUNT, MAX_ENEMY_COUNT)
## Seconds between spawns, so enemies do not appear all at once.
var spawn_interval: float = 0.4
var enemy_scene: PackedScene = MELEE_BASIC_SCENE

var current_wave: int = 0
var enemies_remaining: int = 0
var is_wave_active: bool = false

var _is_spawning: bool = false
## Increases when a run ends so a spawn loop from a previous run stops.
var _run_id: int = 0


func _ready() -> void:
	Events.wave_started.connect(_on_wave_started)
	Events.run_ended.connect(_on_run_ended)


## Clears the state for a new run.
func reset() -> void:
	_run_id += 1
	current_wave = 0
	enemies_remaining = 0
	is_wave_active = false
	_is_spawning = false


func _on_wave_started(wave_number: int) -> void:
	if is_wave_active:
		push_warning("WaveManager: wave %d started while wave %d is still active." % [wave_number, current_wave])
		return
	var run_id := _run_id
	# The map may not be in the tree yet when the wave starts (game start or
	# retry from the death screen), so wait a few frames for its spawn zones.
	var zones: Array[Node] = []
	for _frame in MAP_WAIT_MAX_FRAMES:
		await get_tree().process_frame
		if run_id != _run_id:
			return
		zones = get_tree().get_nodes_in_group("enemy_spawn_zones")
		if not zones.is_empty():
			break
	if zones.is_empty():
		push_warning("WaveManager: there is no EnemySpawnZone in the current map.")
		return
	_spawn_wave(wave_number, zones, run_id)


func _spawn_wave(wave_number: int, zones: Array[Node], run_id: int) -> void:
	current_wave = wave_number
	is_wave_active = true
	_is_spawning = true
	await _wait_for_navigation(zones[0])
	if run_id != _run_id:
		return
	enemies_remaining = enemy_count
	enemies_remaining_changed.emit(enemies_remaining)

	for i in enemy_count:
		# Round-robin across zones so all of them are used.
		var zone := zones[i % zones.size()] as EnemySpawnZone
		if is_instance_valid(zone):
			_spawn_enemy(zone)
		else:
			_on_enemy_died()
		if spawn_interval > 0.0 and i < enemy_count - 1:
			await get_tree().create_timer(spawn_interval, false).timeout
			if run_id != _run_id:
				return
	_is_spawning = false
	_check_wave_end()


## The navigation map syncs a few frames after the map loads; spawning before that
## would place enemies without snapping them to the navmesh.
func _wait_for_navigation(zone: EnemySpawnZone) -> void:
	for _frame in NAVIGATION_WAIT_MAX_FRAMES:
		if not is_instance_valid(zone):
			return
		if NavigationServer2D.map_get_iteration_id(zone.get_world_2d().navigation_map) > 0:
			return
		await get_tree().physics_frame


func _spawn_enemy(zone: EnemySpawnZone) -> void:
	var enemy := enemy_scene.instantiate() as Enemy
	enemy.hunts_player = true
	enemy.died.connect(_on_enemy_died, CONNECT_ONE_SHOT)
	zone.spawn(enemy)


func _on_enemy_died() -> void:
	if not is_wave_active:
		return
	enemies_remaining = maxi(enemies_remaining - 1, 0)
	enemies_remaining_changed.emit(enemies_remaining)
	_check_wave_end()


func _check_wave_end() -> void:
	if is_wave_active and not _is_spawning and enemies_remaining == 0:
		is_wave_active = false
		Events.wave_ended.emit()


func _on_run_ended(_extracted: bool) -> void:
	reset()
