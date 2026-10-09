extends Node
## Autoload "WaveManager" (B08).
## Spawns a fixed, configurable number of enemies (5–8) across every EnemySpawnZone
## of the current map and detects when the wave ends (every spawned enemy died).
## The game loop (B22) decides when to call start_wave().
## TODO(B17): wave scaling. TODO(B20): read enemy_count / spawn_interval from balance_config.tres.

signal wave_started(wave_number: int, enemy_count: int)
signal enemy_spawned(enemy: Node2D)
signal enemies_remaining_changed(enemies_remaining: int)
signal wave_ended(wave_number: int)

const MIN_ENEMY_COUNT := 5
const MAX_ENEMY_COUNT := 8
## Safety limit while waiting for the navigation map to sync (~2 s).
const NAVIGATION_WAIT_MAX_FRAMES := 120
const ENEMY_SCENE :=preload("res://scenes/entities/enemies/melee_basic/melee_basic.tscn")

## Fixed enemy count per wave (GDD §8, level 1).
var enemy_count := 6:
	set(value):
		enemy_count = clampi(value, MIN_ENEMY_COUNT, MAX_ENEMY_COUNT)
## Seconds between spawns, so enemies do not appear all at once.
var spawn_interval := 0.4
var enemy_scene: PackedScene = ENEMY_SCENE

var current_wave := 0
var enemies_remaining := 0
var is_wave_active := false

var _is_spawning := false
## Increases on reset() so a spawn loop from a previous run stops.
var _run_id := 0


func start_wave() -> void:
	if is_wave_active:
		push_warning("WaveManager: a wave is already active.")
		return
	var zones := get_tree().get_nodes_in_group("enemy_spawn_zones")
	if zones.is_empty():
		push_error("WaveManager: there is no EnemySpawnZone in the current map.")
		return

	current_wave += 1
	is_wave_active = true
	_is_spawning = true
	var run_id := _run_id
	await _wait_for_navigation(zones[0])
	if run_id != _run_id:
		return
	enemies_remaining = enemy_count
	wave_started.emit(current_wave, enemy_count)
	enemies_remaining_changed.emit(enemies_remaining)

	for i in enemy_count:
		# Round-robin across zones so they are all used evenly.
		var zone: EnemySpawnZone = zones[i % zones.size()]
		if not is_instance_valid(zone):
			_on_enemy_died()
			continue
		_spawn_enemy(zone)
		if spawn_interval > 0.0 and i < enemy_count - 1:
			await get_tree().create_timer(spawn_interval, false).timeout
			if run_id != _run_id:
				return
	_is_spawning = false
	_check_wave_end()


## The navigation map syncs a few frames after the map loads; spawning before that
## would place enemies without snapping them to the navmesh.
func _wait_for_navigation(zone: EnemySpawnZone) -> void:
	var map := zone.get_world_2d().navigation_map
	for _frame in NAVIGATION_WAIT_MAX_FRAMES:
		if NavigationServer2D.map_get_iteration_id(map) > 0:
			var closest := NavigationServer2D.map_get_closest_point(map, zone.global_position)
			if closest.distance_to(zone.global_position) <= zone.size.length():
				return
		await get_tree().physics_frame
		if not is_instance_valid(zone):
			return


## Clears the state for a new run (call it when the map is reloaded or Kade dies).
func reset() -> void:
	_run_id += 1
	current_wave = 0
	enemies_remaining = 0
	is_wave_active = false
	_is_spawning = false


func _spawn_enemy(zone: EnemySpawnZone) -> void:
	var enemy: Node2D = enemy_scene.instantiate()
	var spawn_point := zone.get_spawn_point()
	zone.get_spawn_parent().add_child(enemy)
	enemy.global_position = spawn_point
	enemy.died.connect(_on_enemy_died, CONNECT_ONE_SHOT)
	enemy_spawned.emit(enemy)


func _on_enemy_died() -> void:
	enemies_remaining = maxi(enemies_remaining - 1, 0)
	enemies_remaining_changed.emit(enemies_remaining)
	_check_wave_end()


func _check_wave_end() -> void:
	if is_wave_active and not _is_spawning and enemies_remaining == 0:
		is_wave_active = false
		wave_ended.emit(current_wave)
