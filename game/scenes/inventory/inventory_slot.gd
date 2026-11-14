extends Control
class_name InventorySlot

## Slot background while warning that the inventory is full (GDD §4).
@export var full_warning_color: Color = Color(0.85, 0.1, 0.1, 0.85)
## Width (px) of the rarity border of a slot holding an item (B31).
@export var rarity_border_width: int = 3

@onready var _icon: TextureRect = $TextureRect

var _empty_style: StyleBox
var _empty_hover_style: StyleBox
var _item_style: StyleBox
var _item_hover_style: StyleBox
var _full_warning_style: StyleBoxFlat
var _full_warning: bool = false

func _ready() -> void:
	_empty_style = get_theme_stylebox("normal")
	_empty_hover_style = get_theme_stylebox("hover")
	_full_warning_style = _empty_style.duplicate() as StyleBoxFlat
	_full_warning_style.bg_color = full_warning_color
	set_item(null)

## Shows `item`'s icon with a border in its rarity color, or an empty slot when null.
func set_item(item: ItemData) -> void:
	_icon.texture = item.item_icon if item != null else null
	if item == null:
		_item_style = _empty_style
		_item_hover_style = _empty_hover_style
	else:
		var color := ItemData.get_rarity_color(item.rarity)
		_item_style = _with_border(_empty_style, color)
		_item_hover_style = _with_border(_empty_hover_style, color)
	_apply_styles()

## Turns the red "inventory full" look on or off.
func set_full_warning(enabled: bool) -> void:
	_full_warning = enabled
	_apply_styles()

func _apply_styles() -> void:
	add_theme_stylebox_override("normal", _full_warning_style if _full_warning else _item_style)
	add_theme_stylebox_override("hover", _item_hover_style)

func _with_border(style: StyleBox, color: Color) -> StyleBox:
	var bordered := style.duplicate() as StyleBoxFlat
	if bordered == null:
		return style
	bordered.set_border_width_all(rarity_border_width)
	bordered.border_color = color
	return bordered


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
