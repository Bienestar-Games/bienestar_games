class_name ItemDrop
extends Area2D

## Item type to collect: "heal" or "resource".
@export_enum("heal", "resource") var item_type: String = "heal"

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if not body is Player:
		return

	body.add_item(item_type)
	queue_free()
