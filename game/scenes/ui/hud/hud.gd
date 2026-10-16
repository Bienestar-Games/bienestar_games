class_name Hud
extends CanvasLayer
## Permanent HUD layer (GDD §4): health bar, ammo counter and active weapon icon.

@export_range(0.0, 1.0) var warning_threshold: float = 0.5
@export_range(0.0, 1.0) var critical_threshold: float = 0.25
@export var healthy_color: Color = Color(0.3, 0.8, 0.3)
@export var warning_color: Color = Color(0.95, 0.8, 0.2)
@export var critical_color: Color = Color(0.85, 0.2, 0.2)

@onready var _health_bar: ProgressBar = %HealthBar
@onready var _health_label: Label = %HealthLabel
@onready var _weapon_icon: TextureRect = %WeaponIcon
@onready var _ammo_label: Label = %AmmoLabel

var _player: Player
var _magazine: Magazine
var _health_fill: StyleBoxFlat

func _ready() -> void:
	_health_fill = _health_bar.get_theme_stylebox("fill") as StyleBoxFlat
	var player := get_tree().get_first_node_in_group("player") as Player
	if player == null:
		push_warning("Hud: no Player found in group 'player'.")
		return
	if not player.is_node_ready():
		await player.ready
	_bind_player(player)

func _bind_player(player: Player) -> void:
	_player = player
	_health_bar.max_value = _player.base_health
	_player.damage_taken.connect(_update_health)
	_player.died.connect(_update_health)
	_player.active_weapon_changed.connect(_on_active_weapon_changed)
	_update_health()
	_on_active_weapon_changed(_player.get_active_weapon())

func _update_health() -> void:
	var health: float = clampf(_player.base_health, 0.0, _health_bar.max_value)
	_health_bar.value = health
	_health_label.text = str(ceili(health))
	var ratio: float = health / _health_bar.max_value
	if ratio < critical_threshold:
		_health_fill.bg_color = critical_color
	elif ratio < warning_threshold:
		_health_fill.bg_color = warning_color
	else:
		_health_fill.bg_color = healthy_color

func _on_active_weapon_changed(weapon: Weapon) -> void:
	if _magazine != null:
		_magazine.ammo_changed.disconnect(_on_ammo_changed)
		_magazine = null
	if weapon == null:
		_weapon_icon.texture = null
		_ammo_label.text = ""
		return
	_weapon_icon.texture = weapon.icon
	_magazine = weapon.magazine
	_magazine.ammo_changed.connect(_on_ammo_changed)
	_on_ammo_changed(_magazine.count, _magazine.capacity)

func _on_ammo_changed(count: int, capacity: int) -> void:
	_ammo_label.text = "%d / %d" % [count, capacity]
	_ammo_label.modulate = critical_color if count <= 0 else Color.WHITE
