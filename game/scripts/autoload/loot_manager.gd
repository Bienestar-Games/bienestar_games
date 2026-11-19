extends Node
## Autoload "LootManager" (B21, B31).
## Decides which items drop and places them in the map as LootPickups:
## - every enemy drops one item when it dies (B09), its rarity rolled on ENEMY_LOOT_TABLE
##   with the current threat tier (B31): the higher the threat, the better the loot;
## - every wave that ends with the barrier open drops one guaranteed Uncommon item
##   (GDD §8 level 2), next to the drop of the wave's last enemy.
## The barrier stays a door: it only reports Events.barrier_opened, the reward lives here.

const LOOT_PICKUP_SCENE: PackedScene = preload("res://scenes/world/loot_pickup/loot_pickup.tscn")
const ENEMY_LOOT_TABLE: LootTable = preload("res://resources/loot_tables/enemy_drop.tres")
const BALANCE_CONFIG: BalanceConfig = preload("res://resources/config/balance_config.tres")
## Threat tiers of LootTable: low / medium / high / extreme.
const THREAT_TIER_COUNT: int = 4
## Every item that can drop. Add new ItemData .tres from resources/items/ here.
const ITEM_POOL: Array[ItemData] = [
	preload("res://resources/items/bandage.tres"),
	preload("res://resources/items/scrap.tres"),
	preload("res://resources/items/spare_parts.tres"),
	preload("res://resources/items/weapon_parts.tres"),
]
## Gap (px) between the last enemy's drop and the barrier reward so both stay visible.
const REWARD_DROP_OFFSET: Vector2 = Vector2(40, 0)

var _barrier_open: bool = false
## Where the latest enemy drop landed; the barrier reward is placed next to it.
var _last_drop_parent: Node
var _last_drop_position: Vector2 = Vector2.ZERO


func _ready() -> void:
	Events.barrier_opened.connect(_on_barrier_opened)
	Events.wave_ended.connect(_on_wave_ended)
	Events.run_ended.connect(_on_run_ended)


## Drops the loot of an enemy that just died at `position`, as a child of `parent`.
func drop_enemy_loot(parent: Node, position: Vector2) -> void:
	_last_drop_parent = parent
	_last_drop_position = position
	drop_item(pick_item(ENEMY_LOOT_TABLE.roll_rarity(get_threat_tier())), parent, position)


## Threat tier (0 = low … 3 = extreme) that weights the loot rarity.
## Hook point for B29/B30: once ThreatManager is merged this returns ThreatManager.risk_level,
## whose values use the same order. Until then it is derived from the wave number, plus one
## tier while the barrier is open (the same two factors as the threat multiplier, GDD §15.4).
func get_threat_tier() -> int:
	var tier := floori((GameLoopManager.wave_number - 1) / float(BALANCE_CONFIG.loot_fallback_waves_per_threat_tier))
	if _barrier_open:
		tier += 1
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


func _on_barrier_opened() -> void:
	_barrier_open = true


func _on_wave_ended() -> void:
	if not _barrier_open:
		return
	# Deferred: WaveManager ends the wave from the last enemy's `died` signal, before
	# that enemy has dropped its own loot, so wait for that drop to know where to place it.
	_drop_open_barrier_reward.call_deferred()


func _drop_open_barrier_reward() -> void:
	var parent := _last_drop_parent
	var position := _last_drop_position + REWARD_DROP_OFFSET
	if not is_instance_valid(parent):
		# No enemy died this run (e.g. every spawn zone was gone): fall back to the barrier.
		var barrier := get_tree().get_first_node_in_group(&"barriers") as Node2D
		if barrier == null:
			return
		parent = barrier.get_parent()
		position = barrier.global_position
	drop_item(pick_item(ItemData.Rarity.UNCOMMON), parent, position)


func _on_run_ended() -> void:
	_barrier_open = false
	_last_drop_parent = null
