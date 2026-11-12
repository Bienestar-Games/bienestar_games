extends Control
class_name InventorySlot

## Slot background while warning that the inventory is full (GDD §4).
@export var full_warning_color: Color = Color(0.85, 0.1, 0.1, 0.85)

var _normal_style: StyleBox
var _full_warning_style: StyleBoxFlat

func _ready() -> void:
	_normal_style = get_theme_stylebox("normal")
	_full_warning_style = _normal_style.duplicate() as StyleBoxFlat
	_full_warning_style.bg_color = full_warning_color

## Turns the red "inventory full" look on or off.
func set_full_warning(enabled: bool) -> void:
	add_theme_stylebox_override("normal", _full_warning_style if enabled else _normal_style)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
