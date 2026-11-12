class_name MeleeFast extends Enemy
## Fast melee enemy (B19, GDD §8 level 3): the basic melee enemy with more speed and
## damage. It inherits melee_basic.tscn, so its stats are melee_basic's scaled by the
## multipliers in balance_config.tres. WaveManager spawns it from melee_fast_first_wave on.

const BALANCE_CONFIG: BalanceConfig = preload("res://resources/config/balance_config.tres")


func _ready() -> void:
	super._ready()
	MAX_SPEED = roundi(MAX_SPEED * BALANCE_CONFIG.melee_fast_speed_multiplier)
	base_damage *= BALANCE_CONFIG.melee_fast_damage_multiplier
