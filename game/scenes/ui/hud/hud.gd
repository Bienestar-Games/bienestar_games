class_name Hud
extends CanvasLayer
## HUD layer (GDD §4). Permanent: health bar, ammo counter, active weapon (icon + name),
## weapon switch hint. Situational: current wave and enemies left alive.

@export_range(0.0, 1.0) var warning_threshold: float = 0.5
@export_range(0.0, 1.0) var critical_threshold: float = 0.25
## Health ratio under which the health bar blinks (GDD §4), and duration of one blink half (seconds).
@export_range(0.0, 1.0) var low_health_blink_threshold: float = 0.3
@export var low_health_blink_time: float = 0.25
## Health bar opacity at the dim point of each blink.
@export_range(0.0, 1.0) var low_health_blink_alpha: float = 0.25
@export var healthy_color: Color = Color(0.3, 0.8, 0.3)
@export var warning_color: Color = Color(0.95, 0.8, 0.2)
@export var critical_color: Color = Color(0.85, 0.2, 0.2)

@onready var _health_bar: ProgressBar = %HealthBar
@onready var _health_label: Label = %HealthLabel
@onready var _weapon_icon: TextureRect = %WeaponIcon
@onready var _weapon_name_label: Label = %WeaponNameLabel
@onready var _weapon_switch_hint: Label = %WeaponSwitchHint
@onready var _ammo_label: Label = %AmmoLabel
@onready var _wave_label: Label = %WaveLabel
@onready var _enemies_label: Label = %EnemiesLabel
@onready var _wall_label: Label = %WallLabel

var _player: Player
var _magazine: Magazine
var _health_fill: StyleBoxFlat
var _low_health_tween: Tween
var _alive_enemies: Array[Enemy] = []

func _ready() -> void:
	_health_fill = _health_bar.get_theme_stylebox("fill") as StyleBoxFlat
	_bind_waves()
	var player := get_tree().get_first_node_in_group("player") as Player
	if player == null:
		push_warning("Hud: no Player found in group 'player'.")
		return
	if not player.is_node_ready():
		await player.ready
	_bind_player(player)

func _bind_player(player: Player) -> void:
	_player = player
	_player.health_changed.connect(_update_health)
	_player.active_weapon_changed.connect(_on_active_weapon_changed)
	_player.throwable_wall_count_changed.connect(_on_throwable_wall_count_changed)
	_update_health(_player.base_health, _player.max_health)
	_on_active_weapon_changed(_player.get_active_weapon())
	_on_throwable_wall_count_changed(_player.get_throwable_wall_count())
	_update_switch_hint()

## Refreshes the health bar, label, colour and low-health blink from the player's values.
func _update_health(current_health: float, max_health: float) -> void:
	_health_bar.max_value = maxf(max_health, 1.0)
	var health: float = clampf(current_health, 0.0, _health_bar.max_value)
	_health_bar.value = health
	_health_label.text = str(ceili(health))
	var ratio: float = health / _health_bar.max_value
	if ratio < critical_threshold:
		_health_fill.bg_color = critical_color
	elif ratio < warning_threshold:
		_health_fill.bg_color = warning_color
	else:
		_health_fill.bg_color = healthy_color
	_update_low_health_blink(ratio < low_health_blink_threshold)

# Blinking is a non-color cue on top of the bar color (GDD §14, color blindness).
func _update_low_health_blink(low: bool) -> void:
	if low == (_low_health_tween != null):
		return
	if low:
		_low_health_tween = create_tween().set_loops()
		_low_health_tween.tween_property(_health_bar, "modulate:a", low_health_blink_alpha, low_health_blink_time)
		_low_health_tween.tween_property(_health_bar, "modulate:a", 1.0, low_health_blink_time)
	else:
		_low_health_tween.kill()
		_low_health_tween = null
		_health_bar.modulate.a = 1.0

func _on_active_weapon_changed(weapon: Weapon) -> void:
	if _magazine != null:
		_magazine.ammo_changed.disconnect(_on_ammo_changed)
		_magazine = null
	if weapon == null:
		_weapon_icon.texture = null
		_weapon_name_label.text = ""
		_ammo_label.text = ""
		return
	_weapon_icon.texture = weapon.icon
	_weapon_name_label.text = weapon.get_display_name()
	_magazine = weapon.magazine
	_magazine.ammo_changed.connect(_on_ammo_changed)
	_on_ammo_changed(_magazine.count, _magazine.capacity)

func _on_ammo_changed(count: int, capacity: int) -> void:
	_ammo_label.text = "%d / %d" % [count, capacity]
	_ammo_label.modulate = critical_color if count <= 0 else Color.WHITE

func _on_throwable_wall_count_changed(count: int) -> void:
	var throw_key := _get_action_key_label(&"interact")
	if throw_key.is_empty():
		_wall_label.text = "Walls: %d" % count
	else:
		_wall_label.text = "Walls: %d  [%s]" % [count, throw_key]

# Builds "1 Revolver · 2 Sawed-off · Next [Q]" from the player's weapons and the InputMap,
# so key bindings are never hardcoded (GDD §11).
func _update_switch_hint() -> void:
	if _player == null:
		_weapon_switch_hint.text = ""
		return
	var parts: PackedStringArray = []
	var slot_actions: Array[StringName] = [&"weapon_1", &"weapon_2"]
	for i in _player.get_weapon_count():
		var weapon := _player.get_weapon(i)
		if weapon == null:
			continue
		var weapon_label := weapon.get_display_name()
		if i < slot_actions.size():
			var key := _get_action_key_label(slot_actions[i])
			parts.append("%s %s" % [key, weapon_label])
		else:
			parts.append(weapon_label)
	var next_key := _get_action_key_label(&"weapon_next")
	if not next_key.is_empty():
		parts.append("Next [%s]" % next_key)
	_weapon_switch_hint.text = " · ".join(parts)

## Name of the first keyboard key or mouse button bound to `action` in the InputMap.
func _get_action_key_label(action: StringName) -> String:
	for event in InputMap.action_get_events(action):
		if event is InputEventKey:
			var key_event := event as InputEventKey
			if key_event.physical_keycode != KEY_NONE:
				return key_event.as_text_physical_keycode()
			return key_event.as_text_keycode()
		if event is InputEventMouseButton:
			var mouse_event := event as InputEventMouseButton
			match mouse_event.button_index:
				MOUSE_BUTTON_WHEEL_UP:
					return "Wheel Up"
				MOUSE_BUTTON_WHEEL_DOWN:
					return "Wheel Down"
				MOUSE_BUTTON_LEFT:
					return "LMB"
				MOUSE_BUTTON_RIGHT:
					return "RMB"
				_:
					return "Mouse %d" % mouse_event.button_index
	return ""

func _bind_waves() -> void:
	Events.wave_started.connect(_on_wave_started)
	_on_wave_started(GameLoopManager.wave_number)
	get_tree().node_added.connect(_on_node_added)
	for enemy in get_tree().root.find_children("*", "Enemy", true, false):
		_track_enemy(enemy)
	_update_enemy_count()

func _on_wave_started(wave_number: int) -> void:
	_wave_label.visible = wave_number > 0
	_wave_label.text = "Wave %d" % wave_number

func _on_node_added(node: Node) -> void:
	if node is Enemy:
		_track_enemy(node)

func _track_enemy(enemy: Enemy) -> void:
	if enemy in _alive_enemies:
		return
	_alive_enemies.append(enemy)
	enemy.died.connect(_untrack_enemy.bind(enemy))
	enemy.tree_exiting.connect(_untrack_enemy.bind(enemy))
	_update_enemy_count()

func _untrack_enemy(enemy: Enemy) -> void:
	if enemy not in _alive_enemies:
		return
	_alive_enemies.erase(enemy)
	_update_enemy_count()

func _update_enemy_count() -> void:
	_enemies_label.text = "Enemies left: %d" % _alive_enemies.size()
