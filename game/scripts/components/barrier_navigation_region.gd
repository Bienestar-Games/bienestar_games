class_name BarrierNavigationRegion
extends NavigationRegion2D
## Navigation region that keeps its navmesh in sync with the barrier (B16).
## It bakes once when the map loads, so the closed barrier cuts the sealed building off the
## rest of the map, and bakes again when the barrier opens so enemies can path through it.
## Baking only parses the nodes in the navigation polygon's source group (e.g. "navigation").

func _ready() -> void:
	Events.barrier_opened.connect(_rebake)
	_rebake()

func _rebake() -> void:
	if is_baking():
		await bake_finished
	bake_navigation_polygon()
