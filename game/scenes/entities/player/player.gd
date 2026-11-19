class_name Player
extends BaseCharacter

const BALANCE_CONFIG: BalanceConfig = preload("res://resources/config/balance_config.tres")
const WALL_SCENE: PackedScene = preload("res://scenes/world/wall/wall.tscn")

signal active_weapon_changed(weapon: Weapon)
## Emitted when an item can't be picked up because Kade already carries the maximum
## (currently only throwable walls).
signal pickup_rejected
## Emitted when the number of throwable walls Kade carries changes.
signal throwable_wall_count_changed(count: int)
## Emitted whenever Kade's current health (`base_health`) or its ceiling (`max_health`)
## changes: damage, death, heals and max-health buffs.
signal health_changed(health: float, max_health: float)

@onready var f_arm_2 = %f_arm_2
@onready var b_arm_2 = %b_arm_2
@onready var player_sprite = $Body
@onready var aim_pivot = %WeaponPivot
@onready var hand = $Body/UpperBody/f_arm_2/Hand
@onready var _state_machine = $StateMachine
#@onready var head = %Head

var _weapons: Array[Weapon] = []
var _current_weapon_index: int = 0
var _throwable_wall_count: int = 0

## Run-scoped consumable buffs. Weapons read these when they shoot.
var max_health: float = 0.0
var damage_multiplier: float = 1.0
var extra_bullets_per_shot: int = 0

func add_item(item: ItemData) -> bool:
	match item.item_type:
		"heal":
			_apply_heal(item)
			return true
		"damage_up":
			_apply_damage_up(item)
			return true
		"bullets_up":
			_apply_bullets_up(item)
			return true
		"max_health_up":
			_apply_max_health_up(item)
			return true
		"throwable_wall":
			if _throwable_wall_count >= BALANCE_CONFIG.max_throwable_walls:
				pickup_rejected.emit()
				return false
			_throwable_wall_count += 1
			throwable_wall_count_changed.emit(_throwable_wall_count)
			return true
	return false

## Reads `modifier_value` from the item's ConsumableAction, or 0 when the item has none.
func _get_modifier_value(item: ItemData) -> int:
	if item.action_data is ConsumableAction:
		return (item.action_data as ConsumableAction).modifier_value
	push_warning("Player: consumable '%s' has no ConsumableAction, buff is ignored." % item.item_name)
	return 0

func _apply_heal(item: ItemData) -> void:
	var amount := _get_modifier_value(item)
	if amount <= 0:
		return
	base_health = minf(base_health + float(amount), max_health)
	_emit_health_changed()

func _apply_damage_up(item: ItemData) -> void:
	var stacks := _get_modifier_value(item)
	if stacks <= 0:
		return
	var step := BALANCE_CONFIG.consumable_damage_up_step
	damage_multiplier = minf(damage_multiplier + step * float(stacks), BALANCE_CONFIG.consumable_damage_multiplier_cap)

func _apply_bullets_up(item: ItemData) -> void:
	var extra := _get_modifier_value(item)
	if extra <= 0:
		return
	extra_bullets_per_shot = clampi(extra_bullets_per_shot + extra, 0, BALANCE_CONFIG.consumable_bullets_up_cap)

func _apply_max_health_up(item: ItemData) -> void:
	var amount := _get_modifier_value(item)
	if amount <= 0:
		return
	var new_max := minf(max_health + float(amount), BALANCE_CONFIG.player_max_health_cap)
	var raised_by := new_max - max_health
	max_health = new_max
	# Also grants the same amount of current HP as a shield-like bonus, clamped to the new cap.
	base_health = minf(base_health + raised_by, max_health)
	_emit_health_changed()

## Notifies listeners (HUD) of the current health and max health.
func _emit_health_changed() -> void:
	health_changed.emit(base_health, max_health)

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
	# Sibling of Kade, so the map's y-sorted parent draws it in front of or behind him.
	get_parent().add_child(wall)
	wall.global_position = global_position + dir * BALANCE_CONFIG.wall_throw_distance
	# The rectangle shape is wider than tall; rotate so its long side blocks the throw direction.
	wall.rotation = dir.angle() + PI / 2
	_throwable_wall_count -= 1
	throwable_wall_count_changed.emit(_throwable_wall_count)
	return true

func _ready() -> void:
	MAX_SPEED = BALANCE_CONFIG.player_speed
	base_health = BALANCE_CONFIG.player_health
	max_health = BALANCE_CONFIG.player_max_health
	died.connect(_on_died)
	damage_taken.connect(_emit_health_changed)
	died.connect(_emit_health_changed)
	Events.wave_started.connect(_on_wave_started)
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
	GameLoopManager.end_run()

func _on_wave_started(_wave_number: int) -> void:
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
