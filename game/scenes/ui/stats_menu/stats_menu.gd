class_name StatsMenu
extends CanvasLayer
## Player stats view: Tab / Y pauses the run and shows what pickups have done to Kade.
## Read-only: it reads the player in the `player` group when opened and holds no game logic.

@onready var _stats_grid: GridContainer = %StatsGrid
@onready var _weapons_grid: GridContainer = %WeaponsGrid

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false

func _unhandled_input(event: InputEvent) -> void:
	if visible:
		# Pause also closes the view so Esc / Start never feels stuck
		if event.is_action_pressed("stats") or event.is_action_pressed("pause"):
			_close()
			get_viewport().set_input_as_handled()
	elif event.is_action_pressed("stats"):
		# Don't stack on top of another pause owner (pause menu, decision panel…)
		if not get_tree().paused:
			_open()
		get_viewport().set_input_as_handled()

func _open() -> void:
	var player := get_tree().get_first_node_in_group("player") as Player
	if player == null:
		return
	_refresh(player)
	get_tree().paused = true
	visible = true

func _close() -> void:
	visible = false
	get_tree().paused = false

func _refresh(player: Player) -> void:
	_clear(_stats_grid)
	_add_row(_stats_grid, "Health", "%d / %d" % [ceili(player.base_health), ceili(player.max_health)])
	_add_row(_stats_grid, "Damage", "x%.2f" % player.damage_multiplier)
	_add_row(_stats_grid, "Extra bullets per shot", "+%d" % player.extra_bullets_per_shot)
	_add_row(_stats_grid, "Move speed", str(player.MAX_SPEED))
	_add_row(_stats_grid, "Walls carried", str(player.get_throwable_wall_count()))

	_clear(_weapons_grid)
	for i in player.get_weapon_count():
		var weapon := player.get_weapon(i)
		if weapon == null:
			continue
		var name_text := weapon.get_display_name()
		if weapon == player.get_active_weapon():
			name_text += " (equipped)"
		var capacity := weapon.magazine.capacity if weapon.magazine else 0
		_add_row(_weapons_grid, name_text, "%d rounds" % capacity)

func _clear(grid: GridContainer) -> void:
	for child in grid.get_children():
		grid.remove_child(child)
		child.queue_free()

func _add_row(grid: GridContainer, label_text: String, value_text: String) -> void:
	var label := Label.new()
	label.text = label_text
	label.add_theme_font_size_override("font_size", 24)
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_child(label)
	var value := Label.new()
	value.text = value_text
	value.add_theme_font_size_override("font_size", 24)
	value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	grid.add_child(value)
