class_name Player
extends BaseCharacter

const BALANCE_CONFIG: BalanceConfig = preload("res://resources/config/balance_config.tres")

signal active_weapon_changed(weapon: Weapon)
## Emitted when an item can't be picked up because the inventory is full.
signal pickup_rejected
## Emitted after an item is added to the inventory.
signal inventory_changed(inventory: Array[ItemData])

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
		"resource":
			if inventory.size() >= BALANCE_CONFIG.max_inventory_slots:
				print("Inventory full")
				pickup_rejected.emit()
				return false
			inventory.append(item)
			inventory_changed.emit(inventory)
			print(inventory.map(func(i: ItemData) -> String: return i.item_name))
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

func _ready() -> void:
	MAX_SPEED = BALANCE_CONFIG.player_speed
	base_health = BALANCE_CONFIG.player_health
	max_health = BALANCE_CONFIG.player_max_health
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

## Returns the barrier the player can start opening right now, or null.
func get_interactable_barrier() -> InteractiveBarrier:
	for barrier: InteractiveBarrier in get_tree().get_nodes_in_group(&"barriers"):
		if barrier.can_interact(self):
			return barrier
	return null

func get_active_weapon() -> Weapon:
	if _weapons.is_empty():
		return null
	return _weapons[_current_weapon_index]

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
