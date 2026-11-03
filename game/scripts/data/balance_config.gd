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
