class_name LootTable
extends Resource
## Weighted rarity roll by threat (B31, GDD §8 level 3).
## Each array has one weight per threat tier, lowest first: low / medium / high / extreme
## (the same order as the risk level of GDD §10). A weight is relative to the other two
## rarities of the same tier, so a tier of 70 / 25 / 5 drops Common 70% of the time.
## The tiers are never shown to the player (pillar a): only the item's rarity border is.

@export var common_weights: PackedFloat32Array = []
@export var uncommon_weights: PackedFloat32Array = []
@export var rare_weights: PackedFloat32Array = []

var _rng := RandomNumberGenerator.new()


## Rolls a rarity for `threat_tier` (0 = low … 3 = extreme). Tiers past the last weight
## use the last one; an empty or all-zero tier falls back to Common.
func roll_rarity(threat_tier: int) -> ItemData.Rarity:
	var weights := PackedFloat32Array([
		_get_weight(common_weights, threat_tier),
		_get_weight(uncommon_weights, threat_tier),
		_get_weight(rare_weights, threat_tier),
	])
	var index := _rng.rand_weighted(weights)
	if index < 0:
		return ItemData.Rarity.COMMON
	return index as ItemData.Rarity


func _get_weight(weights: PackedFloat32Array, threat_tier: int) -> float:
	if weights.is_empty():
		return 0.0
	return maxf(weights[clampi(threat_tier, 0, weights.size() - 1)], 0.0)
