class_name ItemDrop
extends Area2D

## Tipo de objeto que se recoge: "heal" o "resource".
@export_enum("heal", "resource") var item_type: String = "heal"

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return

	if not body.has_method("add_item"):
		push_warning("ItemDrop: el jugador no implementa add_item(item_type).")
		return

	body.call("add_item", item_type)
	queue_free()
