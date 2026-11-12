class_name BalanceConfig
extends Resource

## Death Border risk (0–1, never shown as a number) added the moment the barrier opens.
@export_range(0.0, 1.0) var death_border_barrier_open_step: float = 0.4
## Death Border risk added for every wave that starts with the barrier open.
@export_range(0.0, 1.0) var death_border_open_wave_step: float = 0.12
@export var max_inventory_slots: int = 9
## Seconds the player must hold `interact` to open a barrier.
@export var barrier_interaction_duration: float = 2.0
## First wave in which the barrier can be opened (GDD §8: wave 1 keeps it locked).
@export var barrier_unlock_wave: int = 2
## First wave that mixes fast melee enemies in with the basic ones (GDD §8 level 3).
@export var melee_fast_first_wave: int = 3
## Share (0–1) of each wave's enemies that are fast melee enemies from melee_fast_first_wave on.
@export_range(0.0, 1.0) var melee_fast_wave_share: float = 0.33
## Fast melee enemy speed relative to melee_basic.
@export var melee_fast_speed_multiplier: float = 1.6
## Fast melee enemy damage relative to melee_basic.
@export var melee_fast_damage_multiplier: float = 1.5
