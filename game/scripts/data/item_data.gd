extends Resource
class_name  ItemData

## Loot rarity (GDD §8: Common / Uncommon / Rare; Epic is out of the MVP, §9).
enum Rarity { COMMON, UNCOMMON, RARE }

@export var item_name: String
@export var item_icon: Texture2D
@export var action_data: ActionData
## "heal" is applied the moment it is picked up; "resource" takes an inventory slot (GDD §15.7).
@export_enum("heal", "resource") var item_type: String = "resource"
@export var rarity: Rarity = Rarity.COMMON
var item_model_prefab: PackedScene

## Display name of `value`, e.g. "Uncommon".
static func get_rarity_name(value: Rarity) -> String:
	return String(Rarity.find_key(value)).capitalize()

## One "- Name (Rarity) xN" line per kind of item, for the decision, death and results screens.
static func summarize(items: Array[ItemData]) -> PackedStringArray:
	var counts: Dictionary[String, int] = {}
	for item in items:
		var label := "%s (%s)" % [item.item_name, get_rarity_name(item.rarity)]
		counts[label] = counts.get(label, 0) + 1
	var lines: PackedStringArray = []
	for label in counts:
		lines.append("- %s x%d" % [label, counts[label]])
	return lines
