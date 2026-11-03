extends Node

@export var player: Player
@export var item_area_2d: Area2D
@export var item_data: ItemData

func _ready() -> void:
	item_area_2d.body_entered.connect(on_item_area_2d_body_entered)


func on_item_area_2d_body_entered(_body: Node2D):
	if _body.is_in_group("player"):
		_body.getHealth(50)
	queue_free()
