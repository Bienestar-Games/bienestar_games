class_name PickupNotification
extends VBoxContainer

## Stack of short on-screen messages telling the player what Kade just picked up
## (or why a pickup was rejected). Listens to the `Events` bus only; no game logic.

## Seconds each message takes to fade in.
@export var fade_in_time: float = 0.15
## Seconds each message stays fully visible.
@export var hold_time: float = 1.5
## Seconds each message takes to fade out.
@export var fade_out_time: float = 0.4
## Max messages on screen at once; the oldest one is dropped when a new one arrives.
@export_range(1, 10) var max_visible: int = 3
## Size of the item icon next to the text, in px.
@export var icon_size: Vector2 = Vector2(32, 32)
@export var font_size: int = 20
## Text color of rejection messages (e.g. "Walls full").
@export var rejected_color: Color = Color(1.0, 0.45, 0.4)

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	Events.item_picked_up.connect(_on_item_picked_up)
	Events.item_pickup_rejected.connect(_on_item_pickup_rejected)

func _on_item_picked_up(item: ItemData) -> void:
	_push(item, describe_pickup(item), Color.WHITE)

func _on_item_pickup_rejected(item: ItemData) -> void:
	_push(item, describe_rejection(item), rejected_color)

## Player-facing text for a successful pickup, e.g. "Bandage +25 HP".
static func describe_pickup(item: ItemData) -> String:
	var amount := _get_amount(item)
	match item.item_type:
		"heal":
			return "%s +%d HP" % [item.item_name, amount]
		"damage_up":
			return item.item_name
		"bullets_up":
			return "%s: +%d bullet%s per shot" % [item.item_name, amount, "" if amount == 1 else "s"]
		"max_health_up":
			return "%s +%d" % [item.item_name, amount]
	return item.item_name

## Player-facing text for a rejected pickup, e.g. "Walls full".
static func describe_rejection(item: ItemData) -> String:
	if item.item_type == "throwable_wall":
		return "Walls full"
	return "Can't carry %s" % item.item_name

static func _get_amount(item: ItemData) -> int:
	if item.action_data is ConsumableAction:
		return (item.action_data as ConsumableAction).modifier_value
	return 0

func _push(item: ItemData, text: String, text_color: Color) -> void:
	while get_child_count() >= max_visible:
		var oldest := get_child(0)
		remove_child(oldest)
		oldest.queue_free()

	var entry := _build_entry(item, text, text_color)
	add_child(entry)

	entry.modulate.a = 0.0
	var tween := entry.create_tween()
	tween.tween_property(entry, "modulate:a", 1.0, fade_in_time)
	tween.tween_interval(hold_time)
	tween.tween_property(entry, "modulate:a", 0.0, fade_out_time)
	tween.tween_callback(entry.queue_free)

func _build_entry(item: ItemData, text: String, text_color: Color) -> PanelContainer:
	var rarity_color := ItemData.get_rarity_color(item.rarity)

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.08, 0.08, 0.75)
	style.border_color = rarity_color
	style.set_border_width_all(2)
	style.set_corner_radius_all(4)
	style.set_content_margin_all(6)
	style.content_margin_left = 10
	style.content_margin_right = 12

	var panel := PanelContainer.new()
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	panel.add_theme_stylebox_override("panel", style)

	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override("separation", 8)
	panel.add_child(row)

	if item.item_icon != null:
		var icon := TextureRect.new()
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		icon.texture = item.item_icon
		icon.custom_minimum_size = icon_size
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		row.add_child(icon)

	var label := Label.new()
	label.text = text
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", text_color)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 4)
	row.add_child(label)

	return panel
