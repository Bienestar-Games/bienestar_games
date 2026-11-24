class_name MutantWolf extends MeleeBasic
## Mutant wolf: a big, radioactive green wolf that is fast and hard to kill. One more joins
## every balance_config.mutant_wolf_wave_interval waves (WaveManager). It inherits
## melee_basic.tscn; its size, speed, bite and cooldown are melee_basic's scaled by the
## "Mutant wolf" group of balance_config.tres.
## Its health is sized to the player's own damage: the seconds Kade needs to kill it with his
## best weapon (mutant_wolf_time_to_kill), so it stays tough however many damage buffs he
## stacked. WaveManager applies the adaptive difficulty on top, like on every enemy.


func _ready() -> void:
	super._ready()
	scale *= BALANCE_CONFIG.mutant_wolf_scale
	MAX_SPEED = roundi(MAX_SPEED * BALANCE_CONFIG.mutant_wolf_speed_multiplier)
	base_damage *= BALANCE_CONFIG.mutant_wolf_damage_multiplier
	attack_cooldown = BALANCE_CONFIG.mutant_wolf_attack_cooldown
	base_health = _get_health_for_player()


func spawn_loot() -> void:
	var drops := BALANCE_CONFIG.mutant_wolf_loot_drops
	for i in drops:
		var offset := Vector2.ZERO if drops == 1 else Vector2.RIGHT.rotated(TAU * i / drops) * 24.0
		LootManager.drop_enemy_loot(get_parent(), global_position + offset)


func _get_health_for_player() -> float:
	var player := get_tree().get_first_node_in_group("player") as Player
	var best_dps := 0.0
	if player != null:
		for i in player.get_weapon_count():
			var weapon := player.get_weapon(i)
			if weapon != null:
				best_dps = maxf(best_dps, weapon.get_sustained_dps())
	return maxf(best_dps * BALANCE_CONFIG.mutant_wolf_time_to_kill, BALANCE_CONFIG.mutant_wolf_min_health)
