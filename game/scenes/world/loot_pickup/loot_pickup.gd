class_name LootPickup
extends Area2D

## Item collected when Kade touches the pickup.
@export var item: ItemData
## Rarity border drawn around the icon (B31): width and gap to the icon, in px.
@export var border_width: float = 3.0
@export var border_padding: float = 4.0
## Opacity of the rarity-colored backdrop behind the icon.
@export_range(0.0, 1.0) var backdrop_alpha: float = 0.25
## Size (px) of the longest side of every icon on the ground, so big textures such as the
## wall don't drop larger than the 64x64 consumable icons.
@export var icon_size: float = 64.0

## Blinks per second while the item is about to disappear.
@export var despawn_blink_rate: float = 4.0

const BALANCE_CONFIG: BalanceConfig = preload("res://resources/config/balance_config.tres")

@onready var _sprite: Sprite2D = $Sprite2D

## Seconds left before the item disappears. Counted in _process, so it stops while paused.
var _time_left: float = 0.0

func _ready() -> void:
	_time_left = BALANCE_CONFIG.loot_despawn_time
	body_entered.connect(_on_body_entered)
	if item != null and item.item_icon != null:
		_sprite.region_enabled = false
		_sprite.texture = item.item_icon
	_fit_icon()
	queue_redraw()

## Scales the sprite so its longest side is icon_size, whatever the icon's texture size.
func _fit_icon() -> void:
	var size: Vector2 = _sprite.get_rect().size
	var longest: float = maxf(size.x, size.y)
	if longest > 0.0:
		_sprite.scale = Vector2.ONE * (icon_size / longest)

func _process(delta: float) -> void:
	_time_left -= delta
	if _time_left <= 0.0:
		queue_free()
		return
	if _time_left <= BALANCE_CONFIG.loot_despawn_warning_time:
		# Square-wave blink: visible half of each cycle, faded the other half.
		var phase: float = fmod(_time_left * despawn_blink_rate, 1.0)
		modulate.a = 1.0 if phase < 0.5 else 0.25

func _draw() -> void:
	if item == null:
		return
	var color := ItemData.get_rarity_color(item.rarity)
	var icon_rect: Rect2 = _sprite.get_rect()
	var rect := Rect2(icon_rect.position * _sprite.scale, icon_rect.size * _sprite.scale).grow(border_padding)
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
