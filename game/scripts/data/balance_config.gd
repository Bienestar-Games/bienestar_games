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

@export_group("Waves")
## Enemies in wave 1 (GDD §8 level 1: 5–8 enemies).
@export_range(1, 50) var wave_base_enemy_count: int = 6
## Enemies added to every wave after the first (GDD §8 level 2: +2 per wave, not compounded).
@export_range(0, 20) var wave_enemy_increment: int = 2
## Seconds between two spawns of the same wave, so enemies do not appear all at once.
@export var wave_spawn_interval: float = 0.4

@export_group("Melee basic enemy")
@export var melee_basic_speed: int = 90
@export var melee_basic_health: float = 100.0
## Damage of one melee_basic attack.
@export var melee_basic_damage: float = 10.0

@export_group("Player")
@export var player_speed: int = 200
@export var player_health: float = 100.0

@export_group("Extraction")
## Seconds Kade must stay undisturbed in the extraction channel (GDD §8: 5 s).
@export var extraction_channel_duration: float = 5.0
