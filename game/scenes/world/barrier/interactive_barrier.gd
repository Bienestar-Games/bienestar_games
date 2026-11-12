class_name InteractiveBarrier
extends Area2D
## Shelter barrier (B15, B16). The player opens it by holding `interact` inside its area,
## driven by PlayerInteractingBarrierState. The barrier is drawn with the barrel tiles of the
## dungeon TileSet, which also provide its collision. It works as a door: while closed it blocks
## bodies and (through BarrierNavigationRegion) navigation. Opening is irreversible: the
## barrels go away and Events.barrier_opened fires.
## While the player can open it, a prompt shows the `interact` key; while holding, a bar
## shows how much of the hold is left.

const BALANCE_CONFIG: BalanceConfig = preload("res://resources/config/balance_config.tres")

@export var progress_bar: ProgressBar
@export var prompt_label: Label
## Barrel tiles that block the opening. Paint more barrels here to make the barrier wider.
@export var barrels: TileMapLayer
## Distance (px) around the barrels' collision from where the player can start opening it.
@export var interaction_margin: float = 24.0

var _interaction_elapsed: float = 0.0
var _is_open: bool = false
var _is_interacting: bool = false
var _player: Node2D

func _ready() -> void:
	add_to_group(&"barriers")
	_build_interaction_area()
	if progress_bar != null:
		progress_bar.hide()
	if prompt_label != null:
		prompt_label.text = "Open [%s]" % _get_action_key_label(&"interact")
		prompt_label.hide()

func _process(_delta: float) -> void:
	if prompt_label == null:
		return
	if not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group(&"player") as Node2D
	prompt_label.visible = not _is_interacting and _player != null and can_interact(_player)

## True when `body` is inside the area and the barrier can be opened right now.
## GDD §8: it stays locked until `barrier_unlock_wave` and only opens while a wave is active.
func can_interact(body: Node2D) -> bool:
	return not _is_open \
		and GameLoopManager.current_state == GameLoopManager.RunState.WAVE_ACTIVE \
		and GameLoopManager.wave_number >= BALANCE_CONFIG.barrier_unlock_wave \
		and overlaps_body(body)

func begin_interaction() -> void:
	_is_interacting = true
	_interaction_elapsed = 0.0
	_update_progress_bar(0.0)
	if progress_bar != null:
		progress_bar.show()

## Advances the hold by `delta` seconds. Returns true once the barrier is open.
func advance_interaction(delta: float) -> bool:
	if _is_open:
		return true
	_interaction_elapsed += delta
	var duration := maxf(BALANCE_CONFIG.barrier_interaction_duration, 0.001)
	var progress := clampf(_interaction_elapsed / duration, 0.0, 1.0)
	_update_progress_bar(progress)
	if progress >= 1.0:
		_open()
	return _is_open

func cancel_interaction() -> void:
	_is_interacting = false
	_interaction_elapsed = 0.0
	if progress_bar != null:
		progress_bar.hide()

func _open() -> void:
	_is_open = true
	_is_interacting = false
	set_process(false)
	if prompt_label != null:
		prompt_label.hide()
	# Remove the barrels right away (not deferred) so the navmesh re-bake triggered by
	# Events.barrier_opened no longer sees them and enemies can path through the opening
	barrels.clear()
	if progress_bar != null:
		progress_bar.hide()
	Events.barrier_opened.emit()

## Builds the interaction area from the barrels' tile collision, grown by `interaction_margin`,
## so it always matches the painted barrels.
func _build_interaction_area() -> void:
	if barrels == null:
		push_warning("InteractiveBarrier: no barrels TileMapLayer is assigned.")
		return
	for cell in barrels.get_used_cells():
		var tile_data := barrels.get_cell_tile_data(cell)
		if tile_data == null:
			continue
		var cell_offset := barrels.position + barrels.map_to_local(cell)
		for i in tile_data.get_collision_polygons_count(0):
			var points := tile_data.get_collision_polygon_points(0, i)
			for grown in Geometry2D.offset_polygon(points, interaction_margin, Geometry2D.JOIN_ROUND):
				var shape := CollisionPolygon2D.new()
				shape.polygon = grown
				shape.position = cell_offset
				add_child(shape)

func _update_progress_bar(progress: float) -> void:
	if progress_bar != null:
		progress_bar.value = progress * progress_bar.max_value

## Name of the first keyboard key bound to `action` in the InputMap (never hardcoded).
func _get_action_key_label(action: StringName) -> String:
	for event in InputMap.action_get_events(action):
		if event is InputEventKey:
			var key_event := event as InputEventKey
			if key_event.physical_keycode != KEY_NONE:
				return key_event.as_text_physical_keycode()
			return key_event.as_text_keycode()
	return String(action)
