class_name EnemySpawnZone
extends Node

var _total_enemies: int	

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var enemies := get_children()
	_total_enemies = enemies.size()
	
	for enemy in enemies:
		enemy.enemy_spawn_zone = self
		
func _remove_enemy() -> void:
	queue_free()
