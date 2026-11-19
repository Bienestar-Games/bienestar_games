class_name LootPickup
extends Area2D

## Item collected when Kade touches the pickup.
@export var item: ItemData
## Rarity border drawn around the icon (B31): width and gap to the icon, in px.
@export var border_width: float = 3.0
@export var border_padding: float = 4.0
## Opacity of the rarity-colored backdrop behind the icon.
@export_range(0.0, 1.0) var backdrop_alpha: float = 0.25

@onready var _sprite: Sprite2D = $Sprite2D

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	if item != null and item.item_icon != null:
		_sprite.region_enabled = false
		_sprite.texture = item.item_icon
	queue_redraw()

func _draw() -> void:
	if item == null:
		return
	var color := ItemData.get_rarity_color(item.rarity)
	var rect := _sprite.get_rect().grow(border_padding)
	draw_rect(rect, Color(color, backdrop_alpha))
	draw_rect(rect, color, false, border_width)

func _on_body_entered(body: Node2D) -> void:
	if not body is Player or item == null:
		return

	if body.add_item(item):
		Events.item_picked_up.emit(item)
		queue_free()
	else:
		# Rejected (e.g. walls full): the pickup stays on the ground for later.
		Events.item_pickup_rejected.emit(item)
