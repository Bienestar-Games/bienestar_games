extends Resource
class_name  ItemData

## Loot rarity (GDD §8: Common / Uncommon / Rare; Epic is out of the MVP, §9).
enum Rarity { COMMON, UNCOMMON, RARE }

@export var item_name: String
@export var item_icon: Texture2D
@export var action_data: ActionData
## Consumable buff items ("heal", "damage_up", "bullets_up", "max_health_up") are applied the
## moment they are picked up (GDD §15.7: there is no inventory). Each buff reads its amount
## from the item's ConsumableAction.modifier_value.
## "throwable_wall" fills a separate wall carrier the player deploys with `interact`.
@export_enum("heal", "damage_up", "bullets_up", "max_health_up", "throwable_wall") var item_type: String = "heal"
@export var rarity: Rarity = Rarity.COMMON
var item_model_prefab: PackedScene

## Border color of each rarity on ground pickups (GDD §4, §8 level 3).
const RARITY_COLORS: Dictionary[Rarity, Color] = {
	Rarity.COMMON: Color(0.85, 0.85, 0.85),
	Rarity.UNCOMMON: Color(0.3, 0.85, 0.3),
	Rarity.RARE: Color(0.25, 0.55, 1.0),
}

## Border color of `value`.
static func get_rarity_color(value: Rarity) -> Color:
	return RARITY_COLORS.get(value, Color.WHITE)

## Display name of `value`, e.g. "Uncommon".
static func get_rarity_name(value: Rarity) -> String:
	return String(Rarity.find_key(value)).capitalize()
