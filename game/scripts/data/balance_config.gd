class_name BalanceConfig
extends Resource

@export_group("Loot")
## Waves per loot threat tier (low / medium / high / extreme) until ThreatManager's risk
## level is available (B31 fallback, see LootManager.get_threat_tier).
@export_range(1, 10) var loot_fallback_waves_per_threat_tier: int = 2
## Seconds a dropped item stays on the ground before it disappears.
@export var loot_despawn_time: float = 10.0
## Last seconds of loot_despawn_time during which the item blinks to warn it is about to vanish.
@export var loot_despawn_warning_time: float = 3.0
@export_group("")

## Death Border risk (0–1, never shown as a number) added the moment the barrier opens.
## DEPRECATED: the barrier was removed; kept so existing .tres files still load.
@export_range(0.0, 1.0) var death_border_barrier_open_step: float = 0.4
## Death Border risk added for every wave that starts.
@export_range(0.0, 1.0) var death_border_open_wave_step: float = 0.12
## Seconds the player must hold `interact` to open a barrier.
## DEPRECATED: the barrier was removed; kept so existing .tres files still load.
@export var barrier_interaction_duration: float = 2.0
## First wave in which the barrier can be opened (GDD §8: wave 1 keeps it locked).
## DEPRECATED: the barrier was removed; kept so existing .tres files still load.
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
@export var melee_basic_speed: int = 135
@export var melee_basic_health: float = 100.0
## Damage of one melee_basic attack.
@export var melee_basic_damage: float = 10.0

@export_group("Player")
@export var player_speed: int = 300
@export var player_health: float = 100.0
## Starting max-health ceiling; "heal" items cannot push base_health above it until
## a "max_health_up" buff raises the player's current cap. Defaults to player_health.
@export var player_max_health: float = 100.0
## Hard runtime ceiling: "max_health_up" buffs can never raise the player's cap past this.
@export var player_max_health_cap: float = 300.0

@export_group("Consumable Buffs")
## Damage multiplier added to the player per "damage_up" stack (modifier_value = stacks).
## Example: 0.25 with a Rare drop of modifier_value = 1 raises damage from x1.00 to x1.25.
@export var consumable_damage_up_step: float = 0.25
## Hard cap for the player's damage multiplier, so stacks never go past it.
@export var consumable_damage_multiplier_cap: float = 3.0
## Hard cap for extra bullets per shot added by "bullets_up" stacks.
@export var consumable_bullets_up_cap: int = 6

@export_group("Decision phase")
## Seconds of pause between a wave ending and the next one starting so the next-wave
## preview (B34) has time to read.
@export var decision_phase_duration: float = 3.0

@export_group("Threat")
## Threat multiplier added per wave after the first (base escalation, GDD §15.4). Wave 1 is 1.0.
@export var threat_wave_step: float = 0.25
## Threat added to every wave that mixes in fast melee enemies (from melee_fast_first_wave on).
@export var threat_fast_enemies_bonus: float = 0.25
## Fixed threat added per open barrier, on top of each wave's base threat (not compounded, GDD §4).
## It raises the threat (and the loot that reads it) but never adds enemies.
## DEPRECATED: the barrier was removed; kept so existing .tres files still load.
@export var threat_barrier_open_bonus: float = 0.5

@export_group("Throwable wall")
## Health of a deployed throwable wall before it breaks. Enemies chip at it from attack range.
@export var wall_health: float = 120.0
## Distance (px) in front of Kade at which the wall spawns when thrown.
@export var wall_throw_distance: float = 72.0
## Max walls Kade can carry at once. A pickup over this limit is rejected.
@export_range(1, 20) var max_throwable_walls: int = 5

@export_group("Risk")
## Lowest threat multiplier shown as "medium" risk (GDD §10). Below it the risk is "low".
@export var risk_medium_threshold: float = 1.5
## Lowest threat multiplier shown as "high" risk.
@export var risk_high_threshold: float = 2.0
## Lowest threat multiplier shown as "extreme" risk.
@export var risk_extreme_threshold: float = 2.75
