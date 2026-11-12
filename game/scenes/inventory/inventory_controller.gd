extends CanvasLayer
@export var inventory_slot_prefab: PackedScene
## Red blinks shown when a pickup hits a full inventory, and seconds each on/off half lasts (GDD §4).
@export var full_blink_count: int = 3
@export var full_blink_time: float = 0.12
@onready var inventory_grid: GridContainer = %GridContainer

var item_slots_count: int = 9
var inventory_slots: Array[InventorySlot] = []
var inventory_full: bool = false
var _blink_tween: Tween
var _peeking: bool = false

func _ready() -> void:
	for i in item_slots_count:
		var slot = inventory_slot_prefab.instantiate() as InventorySlot
		inventory_grid.add_child(slot)
		inventory_slots.append(slot)
	var player := get_tree().get_first_node_in_group("player") as Player
	if player != null:
		player.pickup_rejected.connect(_on_pickup_rejected)

func _on_pickup_rejected() -> void:
	if _blink_tween != null and _blink_tween.is_valid():
		_blink_tween.kill()
	# Pickups only happen while the inventory is closed, so it opens briefly to show the slots.
	if not visible:
		visible = true
		_peeking = true
	_set_full_warning(true)
	_blink_tween = create_tween()
	for i in full_blink_count:
		if i > 0:
			_blink_tween.tween_callback(_set_full_warning.bind(true))
		_blink_tween.tween_interval(full_blink_time)
		_blink_tween.tween_callback(_set_full_warning.bind(false))
		_blink_tween.tween_interval(full_blink_time)
	_blink_tween.tween_callback(_end_peek)

func _set_full_warning(enabled: bool) -> void:
	for slot in inventory_slots:
		slot.set_full_warning(enabled)

func _end_peek() -> void:
	if _peeking:
		_peeking = false
		visible = false


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
