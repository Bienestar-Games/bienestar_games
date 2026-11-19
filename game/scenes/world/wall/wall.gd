class_name Wall
extends StaticBody2D
## Deployable wall thrown by the player. Blocks movement and bullets, soaks damage
## through its HitBox, and lives in the "wall" group so enemies can target it over Kade.

signal died

const BALANCE_CONFIG: BalanceConfig = preload("res://resources/config/balance_config.tres")

## Angle of an isometric wall edge against the screen x axis (tiles are 2:1 diamonds).
const ISO_EDGE_ANGLE: float = atan(0.5)

@export_group("Isometric look")
## Region of walls.png for a wall running up-right.
@export var rising_region: Rect2
@export var rising_offset: Vector2
@export var rising_shape: Shape2D
## Region of walls.png for a wall running down-right.
@export var falling_region: Rect2
@export var falling_offset: Vector2
@export var falling_shape: Shape2D

var health: float = 0.0

@onready var _sprite: Sprite2D = $Sprite2D
@onready var _body_shape: CollisionShape2D = $CollisionShape2D
@onready var _hit_shape: CollisionShape2D = $HitBox/CollisionShape2D

func _ready() -> void:
	add_to_group(&"wall")
	health = BALANCE_CONFIG.wall_health
	# The thrower sets our rotation right after add_child(), so read it once that call returns.
	_snap_to_iso_grid.call_deferred()

## Turns the free throw rotation into the closest isometric wall tile, so the wall reads like the
## map's own walls. The body stays unrotated; the sprite and both shapes swap to the chosen variant.
func _snap_to_iso_grid() -> void:
	var long_axis: float = wrapf(rotation, -PI / 2, PI / 2)
	var rising: bool = absf(long_axis + ISO_EDGE_ANGLE) <= absf(long_axis - ISO_EDGE_ANGLE)
	rotation = 0.0
	_sprite.region_rect = rising_region if rising else falling_region
	_sprite.offset = rising_offset if rising else falling_offset
	_body_shape.shape = rising_shape if rising else falling_shape
	_hit_shape.shape = _body_shape.shape

## Called by the wall's HitBox when a bullet or an enemy attack lands on it.
func take_damage(amount: float) -> void:
	if health <= 0.0:
		return
	health -= amount
	if health <= 0.0:
		health = 0.0
		died.emit()
		queue_free()
