extends Node2D
class_name Magazine

@export var capacity: int
var count: int

func _ready() -> void:
	count = capacity

func consume_bullet() -> void:
	if count > 0:
		count -= 1

func is_empty() -> bool:
	return count <= 0

func reload() -> void:
	count = capacity

func can_be_reloaded() -> bool:
	return count < capacity
