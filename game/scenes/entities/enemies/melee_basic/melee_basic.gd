class_name MeleeBasic extends Enemy
## Slow melee enemy (B07, GDD §8 level 1). Its speed, health and damage come from
## balance_config.tres (B20) so they can be tuned without opening the scene.

const BALANCE_CONFIG: BalanceConfig = preload("res://resources/config/balance_config.tres")


func _ready() -> void:
	MAX_SPEED = BALANCE_CONFIG.melee_basic_speed
	base_health = BALANCE_CONFIG.melee_basic_health
	base_damage = BALANCE_CONFIG.melee_basic_damage
	super._ready()
