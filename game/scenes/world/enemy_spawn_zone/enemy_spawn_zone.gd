@tool
class_name EnemySpawnZone
extends Node2D
## Rectangular area of the map where WaveManager spawns enemies (B08).
## Place one or more in a map and adjust `size` in the inspector.
## The rectangle is only drawn in the editor.

@export var size: Vector2 = Vector2(256, 256):
	set(value):
		size = value
		queue_redraw()
## Snap the random point to the closest navigable point so enemies never spawn inside a wall.
@export var snap_to_navigation: bool = true
## Where spawned enemies are added. Empty = this zone's parent (the map).
@export var spawn_parent: Node
## Scale applied to every spawned enemy, to match the scale used by the map.
@export var enemy_scale: Vector2 = Vector2.ONE
## z_index applied to every spawned enemy, to match the player's.
@export var enemy_z_index: int = 0
@export var enabled: bool = true


func _ready() -> void:
	if not Engine.is_editor_hint():
		set_enabled(enabled)


## Enables or disables this zone in the group used by WaveManager.
func set_enabled(value: bool) -> void:
	enabled = value
	if Engine.is_editor_hint():
		return
	if enabled and not is_in_group("enemy_spawn_zones"):
		add_to_group("enemy_spawn_zones")
	elif not enabled and is_in_group("enemy_spawn_zones"):
		remove_from_group("enemy_spawn_zones")


## Returns a random global position inside the zone, snapped to the navmesh when possible.
func get_spawn_point() -> Vector2:
	var offset := Vector2(randf_range(-size.x, size.x), randf_range(-size.y, size.y)) * 0.5
	var point := global_position + offset
	if snap_to_navigation:
		var map := get_world_2d().navigation_map
		if NavigationServer2D.map_get_iteration_id(map) > 0:
			var snapped := NavigationServer2D.map_get_closest_point(map, point)
			# Ignore far-away results (e.g. the zone was placed outside the navigable area).
			if snapped.distance_to(point) <= size.length():
				point = snapped
	return point


func get_spawn_parent() -> Node:
	return spawn_parent if spawn_parent else get_parent()


## Adds an already instantiated enemy to the map at a random point of the zone.
func spawn(enemy: Node2D) -> void:
	enemy.scale = enemy_scale
	enemy.z_index = enemy_z_index
	if "enemy_spawn_zone" in enemy:
		enemy.enemy_spawn_zone = self
	get_spawn_parent().add_child(enemy)
	enemy.global_position = get_spawn_point()


func _draw() -> void:
	if Engine.is_editor_hint():
		var rect := Rect2(-size * 0.5, size)
		draw_rect(rect, Color(1.0, 0.4, 0.1, 0.15), true)
		draw_rect(rect, Color(1.0, 0.4, 0.1, 0.9), false, 2.0)
