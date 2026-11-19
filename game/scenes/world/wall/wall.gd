class_name Wall
extends StaticBody2D
## Deployable wall thrown by the player. Blocks movement and bullets, soaks damage
## through its HitBox, and lives in the "wall" group so enemies can target it over Kade.

signal died

const BALANCE_CONFIG: BalanceConfig = preload("res://resources/config/balance_config.tres")

var health: float = 0.0

func _ready() -> void:
	add_to_group(&"wall")
	health = BALANCE_CONFIG.wall_health

## Called by the wall's HitBox when a bullet or an enemy attack lands on it.
func take_damage(amount: float) -> void:
	if health <= 0.0:
		return
	health -= amount
	if health <= 0.0:
		health = 0.0
		died.emit()
		queue_free()
