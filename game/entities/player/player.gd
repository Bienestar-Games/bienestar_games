class_name Player
extends BaseCharacter

@onready var f_arm_2 = %f_arm_2
@onready var b_arm_2 = %b_arm_2
@onready var player_sprite = $Body
@onready var aim_pivot = %WeaponPivot
@onready var hand = $Body/UpperBody/f_arm_2/Hand
@onready var _state_machine = $StateMachine
#@onready var head = %Head

var _weapons: Array[Weapon] = []
var _current_weapon_index: int = 0

func _ready() -> void:
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
		w.process_mode = Node.PROCESS_MODE_INHERIT if active else Node.PROCESS_MODE_DISABLED
		w.visible = active

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
