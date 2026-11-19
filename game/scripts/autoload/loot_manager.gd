extends Node
## Autoload "LootManager" (B21, B31).
## Decides which items drop and places them in the map as LootPickups:
## every enemy drops one item when it dies (B09), its rarity rolled on ENEMY_LOOT_TABLE
## with the current threat tier (B31): the higher the threat, the better the loot.

const LOOT_PICKUP_SCENE: PackedScene = preload("res://scenes/world/loot_pickup/loot_pickup.tscn")
const ENEMY_LOOT_TABLE: LootTable = preload("res://resources/loot_tables/enemy_drop.tres")
const BALANCE_CONFIG: BalanceConfig = preload("res://resources/config/balance_config.tres")
## Threat tiers of LootTable: low / medium / high / extreme.
const THREAT_TIER_COUNT: int = 4
## Every item that can drop. Add new ItemData .tres from resources/items/ here.
const ITEM_POOL: Array[ItemData] = [
	preload("res://resources/items/bandage.tres"),
	preload("res://resources/items/damage_boost.tres"),
	preload("res://resources/items/max_health_boost.tres"),
	preload("res://resources/items/bullet_boost.tres"),
	preload("res://resources/items/throwable_wall.tres"),
]


## Drops the loot of an enemy that just died at `position`, as a child of `parent`.
func drop_enemy_loot(parent: Node, position: Vector2) -> void:
	drop_item(pick_item(ENEMY_LOOT_TABLE.roll_rarity(get_threat_tier())), parent, position)


## Threat tier (0 = low … 3 = extreme) that weights the loot rarity.
## Hook point for B29/B30: once ThreatManager is merged this returns ThreatManager.risk_level,
## whose values use the same order. Until then it is derived from the wave number.
func get_threat_tier() -> int:
	var tier := floori((GameLoopManager.wave_number - 1) / float(BALANCE_CONFIG.loot_fallback_waves_per_threat_tier))
	return clampi(tier, 0, THREAT_TIER_COUNT - 1)


## Adds a LootPickup with `item` to `parent` at the global `position`.
func drop_item(item: ItemData, parent: Node, position: Vector2) -> LootPickup:
	if item == null or not is_instance_valid(parent):
		return null
	var pickup := LOOT_PICKUP_SCENE.instantiate() as LootPickup
	pickup.item = item
	parent.add_child(pickup)
	pickup.global_position = position
	return pickup


## A random item of `rarity` from ITEM_POOL, or null if there is none.
func pick_item(rarity: ItemData.Rarity) -> ItemData:
	var candidates := ITEM_POOL.filter(func(item: ItemData) -> bool: return item.rarity == rarity)
	if candidates.is_empty():
		push_warning("LootManager: no item of rarity %s in ITEM_POOL." % ItemData.get_rarity_name(rarity))
		return null
	return candidates.pick_random()
