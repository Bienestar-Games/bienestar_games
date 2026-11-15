class_name LootPickup
extends Area2D

## Item collected when Kade touches the pickup.
@export var item: ItemData

@onready var _sprite: Sprite2D = $Sprite2D

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	if item != null and item.item_icon != null:
		_sprite.region_enabled = false
		_sprite.texture = item.item_icon

func _on_body_entered(body: Node2D) -> void:
	if not body is Player or item == null:
		return

	body.add_item(item)
	queue_free()
