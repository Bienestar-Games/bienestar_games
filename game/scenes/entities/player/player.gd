class_name Player
extends BaseCharacter

const BALANCE_CONFIG: BalanceConfig = preload("res://resources/config/balance_config.tres")
const WALL_SCENE: PackedScene = preload("res://scenes/world/wall/wall.tscn")

signal active_weapon_changed(weapon: Weapon)
## Emitted when an item can't be picked up because the inventory is full.
signal pickup_rejected
## Emitted after an item is added to the inventory.
signal inventory_changed(inventory: Array[ItemData])
## Emitted when the number of throwable walls Kade carries changes.
signal throwable_wall_count_changed(count: int)

@onready var f_arm_2 = %f_arm_2
@onready var b_arm_2 = %b_arm_2
@onready var player_sprite = $Body
@onready var aim_pivot = %WeaponPivot
@onready var hand = $Body/UpperBody/f_arm_2/Hand
@onready var _state_machine = $StateMachine
#@onready var head = %Head

var _weapons: Array[Weapon] = []
var _current_weapon_index: int = 0
var inventory: Array[ItemData] = []
var _throwable_wall_count: int = 0

func add_item(item: ItemData) -> bool:
	if item.item_type == "heal":
		# TODO: Apply the healing amount defined by the balance configuration.
		print("Player healed")
		return true

	if item.item_type == "resource":
		if inventory.size() >= BALANCE_CONFIG.max_inventory_slots:
			print("Inventory full")
			pickup_rejected.emit()
			return false
		inventory.append(item)
		inventory_changed.emit(inventory)
		print(inventory.map(func(i: ItemData) -> String: return i.item_name))
		return true

	if item.item_type == "throwable_wall":
		if _throwable_wall_count >= BALANCE_CONFIG.max_throwable_walls:
			pickup_rejected.emit()
			return false
		_throwable_wall_count += 1
		throwable_wall_count_changed.emit(_throwable_wall_count)
		return true

	return false

## Walls Kade still carries. Each throw spends one.
func get_throwable_wall_count() -> int:
	return _throwable_wall_count

## Spawns a wall in front of Kade along the aim direction, consuming one from the stock.
## Returns true when a wall was deployed.
func try_throw_wall() -> bool:
	if _throwable_wall_count <= 0:
		return false
	var to_mouse: Vector2 = get_global_mouse_position() - global_position
	if to_mouse.length_squared() < 0.01:
		return false
	var dir: Vector2 = to_mouse.normalized()
	var wall: Wall = WALL_SCENE.instantiate()
	get_tree().current_scene.add_child(wall)
	wall.global_position = global_position + dir * BALANCE_CONFIG.wall_throw_distance
	# The rectangle shape is wider than tall; rotate so its long side blocks the throw direction.
	wall.rotation = dir.angle() + PI / 2
	_throwable_wall_count -= 1
	throwable_wall_count_changed.emit(_throwable_wall_count)
	return true

func _ready() -> void:
	MAX_SPEED = BALANCE_CONFIG.player_speed
	base_health = BALANCE_CONFIG.player_health
	died.connect(_on_died)
	Events.decision_phase_started.connect(_on_decision_phase_started)
	Events.wave_started.connect(_on_wave_started)
	Events.extraction_started.connect(_on_extraction_started)
	Events.extraction_cancelled.connect(_on_extraction_cancelled)
	_init_weapons()

func _init_weapons() -> void:
	for child in f_arm_2.get_children():
		if child is Weapon:
			_weapons.append(child)
	_update_active_weapon()

func _update_active_weapon() -> void:
	for i in _weapons.size():
		var w: Weapon = _weapons[i]
		var active: bool = (i == _current_weapon_index)
		if active:
			w.visible = true
			w.set_deferred("process_mode", Node.PROCESS_MODE_INHERIT)
		else:
			w.process_mode = Node.PROCESS_MODE_DISABLED
			w.visible = false
	active_weapon_changed.emit(get_active_weapon())

## Disables the active weapon (no shooting or reloading) while `enabled` is false.
func set_weapons_enabled(enabled: bool) -> void:
	if enabled:
		_update_active_weapon()
	elif not _weapons.is_empty():
		_weapons[_current_weapon_index].process_mode = Node.PROCESS_MODE_DISABLED

func get_active_weapon() -> Weapon:
	if _weapons.is_empty():
		return null
	return _weapons[_current_weapon_index]

## Number of weapons the player carries (GDD §8: Kade starts with 2).
func get_weapon_count() -> int:
	return _weapons.size()

## Weapon at `index`, or null when out of range.
func get_weapon(index: int) -> Weapon:
	if index < 0 or index >= _weapons.size():
		return null
	return _weapons[index]

func switch_weapon(index: int) -> void:
	if _weapons.is_empty() or index == _current_weapon_index:
		return
	_current_weapon_index = clamp(index, 0, _weapons.size() - 1)
	_update_active_weapon()

func switch_to_next_weapon() -> void:
	if _weapons.is_empty():
		return
	_current_weapon_index = (_current_weapon_index + 1) % _weapons.size()
	_update_active_weapon()

func _on_died() -> void:
	GameLoopManager.end_run(false)

func _on_decision_phase_started() -> void:
	_state_machine.force_transition("decision")

func _on_wave_started(_wave_number: int) -> void:
	_state_machine.force_transition("idle")

func _on_extraction_started() -> void:
	_state_machine.force_transition("extracting")

func _on_extraction_cancelled() -> void:
	_state_machine.force_transition("idle")

func aim(pos: Vector2):
	flip_player_sprite(pos.x < self.global_position.x)
	if (pos.x < self.global_position.x):
		f_arm_2.rotation = lerp_angle(f_arm_2.rotation, - (aim_pivot.global_position - pos).angle(), (0.10))
	else:
		f_arm_2.rotation = lerp_angle(f_arm_2.rotation, (pos - aim_pivot.global_position).angle(), (0.10))
	b_arm_2.look_at(hand.global_position)
	#head.look_at(pos)


func _player_input():
	move_direction.x = int(Input.is_action_pressed("move_right")) - int(Input.is_action_pressed("move_left"))
	move_direction.y = int(Input.is_action_pressed("move_down")) - int(Input.is_action_pressed("move_up"))

func handle_animation(state: String):

	match state:
		"moving":
			animation_tree["parameters/conditions/idle"] = false
			animation_tree["parameters/conditions/moving"] = true
			animation_tree["parameters/Moving/blend_position"] = move_direction.normalized()
		"idle":
			animation_tree["parameters/conditions/moving"] = false
			animation_tree["parameters/conditions/idle"] = true
			animation_tree["parameters/Moving/blend_position"] = Vector2.ZERO
