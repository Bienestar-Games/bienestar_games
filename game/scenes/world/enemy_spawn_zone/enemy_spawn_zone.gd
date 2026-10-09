@tool
class_name EnemySpawnZone
extends Node2D
## Rectangular area of the map where WaveManager can spawn enemies.
## Place several in the map and adjust `size` in the inspector.

@export var size := Vector2(128, 128):
	set(value):
		size = value
		queue_redraw()
## Snap the random point to the closest navigable point so enemies never spawn inside a wall.
@export var snap_to_navigation := true
## Where spawned enemies are added. Empty = this zone's parent (the map).
@export var spawn_parent: Node


func _ready() -> void:
	add_to_group("enemy_spawn_zones")


func get_spawn_point() -> Vector2:
	var offset := Vector2(randf_range(-size.x, size.x), randf_range(-size.y, size.y)) * 0.5
	var point := global_position + offset
	if snap_to_navigation and not Engine.is_editor_hint():
		var map := get_world_2d().navigation_map
		if NavigationServer2D.map_get_iteration_id(map) > 0:
			var snapped := NavigationServer2D.map_get_closest_point(map, point)
			# Ignore far-away results (e.g. the zone was placed outside the navigable area).
			if snapped.distance_to(point) <= size.length():
				point = snapped
	return point


func get_spawn_parent() -> Node:
	return spawn_parent if spawn_parent else get_parent()


func _draw() -> void:
	# Only drawn in the editor, so the zone is invisible in game.
	if Engine.is_editor_hint():
		var rect := Rect2(-size * 0.5, size)
		draw_rect(rect, Color(1.0, 0.4, 0.1, 0.15), true)
		draw_rect(rect, Color(1.0, 0.4, 0.1, 0.9), false, 2.0)
