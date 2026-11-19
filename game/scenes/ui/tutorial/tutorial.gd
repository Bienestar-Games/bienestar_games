class_name Tutorial
extends CanvasLayer
## Interactive tutorial shown before the very first run (SaveManager remembers it).
## Walks the player through the game step by step: the goal, movement, shooting,
## reloading, switching weapons, picking up consumables, throwing walls and the menus.
## It can't be skipped and has no buttons: practice steps finish by themselves when the
## player does what they ask, and info steps wait for the `ui_accept` key. Every key shown is read from the InputMap and follows the last
## device used (keyboard/mouse or gamepad), so the text changes when the player swaps.
## No waves run meanwhile: main.gd starts the run when `finished` is emitted.

## Emitted when the player completes or skips the tutorial.
signal finished

enum Goal { NONE, MOVE, SHOOT, RELOAD, SWITCH_WEAPON, PICKUP, THROW_WALL, STATS }

const BALANCE_CONFIG: BalanceConfig = preload("res://resources/config/balance_config.tres")
const THROWABLE_WALL: ItemData = preload("res://resources/items/throwable_wall.tres")
## Dropped next to Kade in the pickup step so the player can practice picking items up.
## Only items that give no lasting advantage, so the tutorial never buffs the run.
const PRACTICE_ITEMS: Array[ItemData] = [
	preload("res://resources/items/bandage.tres"),
	preload("res://resources/items/throwable_wall.tres"),
]

## What each consumable does, by ItemData.item_type.
const ITEM_DESCRIPTIONS: Dictionary[String, String] = {
	"heal": "Restores health",
	"damage_up": "More damage per bullet",
	"bullets_up": "Extra bullets per shot",
	"max_health_up": "Raises max health",
	"throwable_wall": "A wall you can throw",
}

const JOY_BUTTON_NAMES: Dictionary[JoyButton, String] = {
	JOY_BUTTON_A: "A",
	JOY_BUTTON_B: "B",
	JOY_BUTTON_X: "X",
	JOY_BUTTON_Y: "Y",
	JOY_BUTTON_BACK: "Back",
	JOY_BUTTON_GUIDE: "Guide",
	JOY_BUTTON_START: "Start",
	JOY_BUTTON_LEFT_STICK: "L3",
	JOY_BUTTON_RIGHT_STICK: "R3",
	JOY_BUTTON_LEFT_SHOULDER: "LB",
	JOY_BUTTON_RIGHT_SHOULDER: "RB",
	JOY_BUTTON_DPAD_UP: "D-pad Up",
	JOY_BUTTON_DPAD_DOWN: "D-pad Down",
	JOY_BUTTON_DPAD_LEFT: "D-pad Left",
	JOY_BUTTON_DPAD_RIGHT: "D-pad Right",
	JOY_BUTTON_MISC1: "Share",
}

const JOY_AXIS_NAMES: Dictionary[JoyAxis, String] = {
	JOY_AXIS_LEFT_X: "Left Stick",
	JOY_AXIS_LEFT_Y: "Left Stick",
	JOY_AXIS_RIGHT_X: "Right Stick",
	JOY_AXIS_RIGHT_Y: "Right Stick",
	JOY_AXIS_TRIGGER_LEFT: "LT",
	JOY_AXIS_TRIGGER_RIGHT: "RT",
}

const MOUSE_BUTTON_NAMES: Dictionary[MouseButton, String] = {
	MOUSE_BUTTON_LEFT: "Left Click",
	MOUSE_BUTTON_RIGHT: "Right Click",
	MOUSE_BUTTON_MIDDLE: "Middle Click",
	MOUSE_BUTTON_WHEEL_UP: "Mouse Wheel",
	MOUSE_BUTTON_WHEEL_DOWN: "Mouse Wheel",
}

## Seconds Kade has to move to finish the movement step.
@export var move_time_required: float = 1.0
## Shots needed to finish the shooting step.
@export var shots_required: int = 3
## Seconds the "Done!" feedback stays before the next step shows.
@export var step_complete_delay: float = 0.8
## Distance (px) from Kade at which the practice items drop.
@export var practice_item_distance: float = 110.0
## Stick deflection that counts as "the player is using the gamepad".
@export_range(0.0, 1.0) var joypad_axis_threshold: float = 0.5
@export var key_color: Color = Color(1.0, 0.8, 0.3)
@export var done_color: Color = Color(0.4, 0.9, 0.4)
@export var goal_color: Color = Color(0.8, 0.8, 0.8)
@export var item_icon_size: float = 32.0

@onready var _title_label: Label = %TitleLabel
@onready var _step_label: Label = %StepLabel
@onready var _body_label: RichTextLabel = %BodyLabel
@onready var _item_list: VBoxContainer = %ItemList
@onready var _goal_label: RichTextLabel = %GoalLabel

## Each step: title, body (with {placeholders}, see _get_placeholders) and the goal that
## finishes it. Goal.NONE steps wait for `ui_accept`.
var _steps: Array[Dictionary] = [
	{
		"title": "Welcome to Death Border",
		"body": "Enemies come in [b]endless waves[/b], each one bigger than the last. "
			+ "There is no way out: the run only ends when Kade dies, so survive as many waves as you can.\n\n"
			+ "Your best wave so far: {best_wave}",
		"goal": Goal.NONE,
	},
	{
		"title": "Move",
		"body": "Move Kade with {move}.",
		"goal": Goal.MOVE,
	},
	{
		"title": "Aim and shoot",
		"body": "Aim with {aim} and shoot with {shoot}.",
		"goal": Goal.SHOOT,
	},
	{
		"title": "Reload",
		"body": "Each weapon has a magazine. When it runs dry, reload with {reload}. Reloading leaves you exposed, so pick your moment.",
		"goal": Goal.RELOAD,
	},
	{
		"title": "Weapons",
		"body": "Kade carries {weapons}. Switch with {weapon_1} / {weapon_2} or {weapon_next}. Try every weapon.",
		"goal": Goal.SWITCH_WEAPON,
	},
	{
		"title": "Consumables",
		"body": "Every enemy drops an item when it dies. Walk over it to pick it up: its effect applies [b]instantly[/b], there is no inventory. "
			+ "Items vanish after a while and blink right before.\n"
			+ "The border shows the rarity: {rarities}. The higher the danger, the better the loot.\n"
			+ "Pick up the items next to Kade.",
		"goal": Goal.PICKUP,
		"show_items": true,
	},
	{
		"title": "Throwable walls",
		"body": "Walls block the enemies until they break through. Aim and press {interact} to throw one in front of Kade. "
			+ "You can carry up to {max_walls}. Throw one now.",
		"goal": Goal.THROW_WALL,
	},
	{
		"title": "Stats and pause",
		"body": "Press {stats} to see what your pickups have done to Kade, and {pause} to pause the game. Open your stats now.",
		"goal": Goal.STATS,
	},
	{
		"title": "Ready?",
		"body": "Between waves you get a short breather to get ready. Later waves bring [b]faster enemies[/b].\n\n"
			+ "Your best wave is saved. Good luck!",
		"goal": Goal.NONE,
	},
]

var _player: Player
var _step_index: int = -1
var _goal_done: bool = false
var _using_joypad: bool = false

# Progress of the current practice step
var _move_time: float = 0.0
var _shots: int = 0
var _weapons_seen: Array[Weapon] = []
var _items_picked: int = 0
var _items_to_pick: int = 0
## Walls carried before the last change, to tell a throw from a pickup.
var _last_wall_count: int = 0
## Practice items still on the ground, dropped again if they vanish before being picked up.
var _practice_pickups: Array[LootPickup] = []


func _ready() -> void:
	_player = get_tree().get_first_node_in_group("player") as Player
	Events.item_picked_up.connect(_on_item_picked_up)
	if _player != null:
		_last_wall_count = _player.get_throwable_wall_count()
		_player.throwable_wall_count_changed.connect(_on_wall_count_changed)
	_show_step(0)


func _input(event: InputEvent) -> void:
	_track_device(event)
	if _goal_done or _step_index < 0:
		return
	match _current_goal():
		Goal.NONE:
			if event.is_action_pressed("ui_accept") and not event.is_echo():
				get_viewport().set_input_as_handled()
				_next_step()
		Goal.SHOOT:
			if event.is_action_pressed("shoot"):
				_shots += 1
				_update_goal()
		Goal.RELOAD:
			if event.is_action_pressed("reload"):
				_complete_goal()
		Goal.STATS:
			# The stats menu pauses the game; the next step shows once it is closed
			if event.is_action_pressed("stats"):
				_complete_goal()


func _process(delta: float) -> void:
	if _goal_done or _player == null:
		return
	match _current_goal():
		Goal.MOVE:
			if _player.move_direction != Vector2.ZERO:
				_move_time += delta
				_update_goal()
		Goal.SWITCH_WEAPON:
			var weapon := _player.get_active_weapon()
			if weapon != null and not _weapons_seen.has(weapon):
				_weapons_seen.append(weapon)
				_update_goal()
		Goal.PICKUP:
			# The tutorial can't be skipped, so items that vanished are dropped again
			# Freed pickups can't be passed to a typed lambda, so drop them by index
			for i in range(_practice_pickups.size() - 1, -1, -1):
				if not is_instance_valid(_practice_pickups[i]):
					_practice_pickups.remove_at(i)
			if _practice_pickups.is_empty() and _items_picked < _items_to_pick:
				_drop_practice_items(_items_to_pick - _items_picked)


func _current_goal() -> Goal:
	return _steps[_step_index].get("goal", Goal.NONE)


func _show_step(index: int) -> void:
	_step_index = index
	_goal_done = false
	_move_time = 0.0
	_shots = 0
	_weapons_seen.clear()
	_items_picked = 0
	_items_to_pick = 0
	_practice_pickups.clear()

	match _current_goal():
		Goal.SWITCH_WEAPON:
			if _player != null and _player.get_active_weapon() != null:
				_weapons_seen.append(_player.get_active_weapon())
		Goal.PICKUP:
			_items_to_pick = _drop_practice_items(PRACTICE_ITEMS.size())
		Goal.THROW_WALL:
			# Make sure there is a wall to practice with
			if _player != null and _player.get_throwable_wall_count() == 0:
				_player.add_item(THROWABLE_WALL)

	_title_label.text = _steps[index]["title"]
	_step_label.text = "%d / %d" % [index + 1, _steps.size()]
	_build_item_list(_steps[index].get("show_items", false))
	_refresh_text()


func _refresh_text() -> void:
	if _step_index < 0:
		return
	_body_label.text = String(_steps[_step_index]["body"]).format(_get_placeholders())
	_update_goal()


## Shows the progress of the current practice step and finishes it once its goal is met.
func _update_goal() -> void:
	var goal := _current_goal()
	if _goal_done:
		_set_goal_text("Done!", done_color)
		return
	match goal:
		Goal.NONE:
			var verb := "start" if _step_index == _steps.size() - 1 else "continue"
			_set_goal_text("Press %s to %s" % [_key(_action_text(&"ui_accept")), verb], goal_color)
		Goal.MOVE:
			if _move_time >= move_time_required:
				_complete_goal()
			else:
				_set_goal_text("Keep moving...", goal_color)
		Goal.SHOOT:
			if _shots >= shots_required:
				_complete_goal()
			else:
				_set_goal_text("Shots: %d / %d" % [_shots, shots_required], goal_color)
		Goal.RELOAD:
			_set_goal_text("Reload once", goal_color)
		Goal.SWITCH_WEAPON:
			var total := _player.get_weapon_count() if _player != null else 0
			if _weapons_seen.size() >= total:
				_complete_goal()
			else:
				_set_goal_text("Weapons tried: %d / %d" % [_weapons_seen.size(), total], goal_color)
		Goal.PICKUP:
			if _items_picked >= _items_to_pick:
				_complete_goal()
			else:
				_set_goal_text("Items picked up: %d / %d" % [_items_picked, _items_to_pick], goal_color)
		Goal.THROW_WALL:
			_set_goal_text("Throw a wall", goal_color)
		Goal.STATS:
			_set_goal_text("Open your stats", goal_color)


func _set_goal_text(text: String, color: Color) -> void:
	_goal_label.text = text
	_goal_label.visible = not text.is_empty()
	_goal_label.add_theme_color_override("default_color", color)


func _complete_goal() -> void:
	if _goal_done:
		return
	_goal_done = true
	_update_goal()
	var index := _step_index
	await get_tree().create_timer(step_complete_delay, false).timeout
	if index == _step_index and is_inside_tree():
		_next_step()


func _next_step() -> void:
	if _step_index + 1 >= _steps.size():
		_finish()
	else:
		_show_step(_step_index + 1)


func _finish() -> void:
	if _step_index < 0:
		return
	_step_index = -1
	_clear_practice_leftovers()
	finished.emit()
	queue_free()


## Removes what the practice left in the map (thrown walls and items not picked up),
## so the run starts clean.
func _clear_practice_leftovers() -> void:
	# No enemies run during the tutorial, so every wall on the map was thrown in it
	for wall in get_tree().get_nodes_in_group(&"wall"):
		wall.remove_from_group(&"wall")
		wall.queue_free()
	# By index: a freed pickup can't be bound to the typed loop variable
	for i in _practice_pickups.size():
		if is_instance_valid(_practice_pickups[i]):
			_practice_pickups[i].queue_free()
	_practice_pickups.clear()


## Drops the first `count` practice items around Kade and returns how many are on the ground.
func _drop_practice_items(count: int) -> int:
	if _player == null:
		return 0
	var parent := _player.get_parent()
	count = mini(count, PRACTICE_ITEMS.size())
	for i in count:
		# Spread them around Kade so each one is a short walk away
		var angle := TAU * i / count
		var drop_position := _player.global_position + Vector2.RIGHT.rotated(angle) * practice_item_distance
		var pickup := LootManager.drop_item(PRACTICE_ITEMS[i], parent, drop_position)
		if pickup != null:
			_practice_pickups.append(pickup)
	return _practice_pickups.size()


func _on_item_picked_up(_item: ItemData) -> void:
	if _current_goal_or_none() == Goal.PICKUP and not _goal_done:
		_items_picked += 1
		_update_goal()


func _on_wall_count_changed(count: int) -> void:
	if _current_goal_or_none() == Goal.THROW_WALL and not _goal_done and count < _last_wall_count:
		_complete_goal()
	_last_wall_count = count


func _current_goal_or_none() -> Goal:
	return Goal.NONE if _step_index < 0 else _current_goal()


func _build_item_list(show_items: bool) -> void:
	for child in _item_list.get_children():
		_item_list.remove_child(child)
		child.queue_free()
	_item_list.visible = show_items
	if not show_items:
		return
	for item: ItemData in LootManager.ITEM_POOL:
		var color := ItemData.get_rarity_color(item.rarity)
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)

		var frame := PanelContainer.new()
		frame.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		var style := StyleBoxFlat.new()
		style.bg_color = Color(color, 0.25)
		style.border_color = color
		style.set_border_width_all(2)
		style.set_content_margin_all(3)
		frame.add_theme_stylebox_override("panel", style)
		var icon := TextureRect.new()
		icon.texture = item.item_icon
		icon.custom_minimum_size = Vector2.ONE * item_icon_size
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		frame.add_child(icon)
		row.add_child(frame)

		var text := VBoxContainer.new()
		text.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		text.add_theme_constant_override("separation", 0)
		var name_label := Label.new()
		name_label.text = item.item_name
		name_label.add_theme_color_override("font_color", color)
		name_label.add_theme_font_size_override("font_size", 15)
		text.add_child(name_label)
		var description := Label.new()
		description.text = ITEM_DESCRIPTIONS.get(item.item_type, "")
		description.add_theme_font_size_override("font_size", 13)
		description.add_theme_color_override("font_color", goal_color)
		text.add_child(description)
		row.add_child(text)
		_item_list.add_child(row)


# --- Input labels ----------------------------------------------------------------------

func _track_device(event: InputEvent) -> void:
	var joypad := _using_joypad
	if event is InputEventJoypadButton:
		joypad = true
	elif event is InputEventJoypadMotion:
		if absf((event as InputEventJoypadMotion).axis_value) >= joypad_axis_threshold:
			joypad = true
	elif event is InputEventKey or event is InputEventMouseButton:
		joypad = false
	elif event is InputEventMouseMotion and (event as InputEventMouseMotion).relative.length() > 2.0:
		joypad = false
	if joypad != _using_joypad:
		_using_joypad = joypad
		_refresh_text()


func _get_placeholders() -> Dictionary:
	var placeholders := {
		"move": _move_label(),
		"aim": _key(_action_text(&"aim_right")) if _using_joypad else _key("Mouse"),
		"weapons": _weapon_names(),
		"best_wave": _key(str(SaveManager.best_wave)),
		"max_walls": str(BALANCE_CONFIG.max_throwable_walls),
		"rarities": _rarity_legend(),
	}
	for action: StringName in [&"shoot", &"reload", &"weapon_1", &"weapon_2", &"weapon_next", &"interact", &"stats", &"pause"]:
		placeholders[String(action)] = _key(_action_text(action))
	return placeholders


func _move_label() -> String:
	if _using_joypad:
		return _key(_action_text(&"move_up"))
	var keys: PackedStringArray = []
	for action: StringName in [&"move_up", &"move_left", &"move_down", &"move_right"]:
		keys.append(_action_text(action))
	return _key(" ".join(keys))


func _key(text: String) -> String:
	return "[b][color=#%s]%s[/color][/b]" % [key_color.to_html(false), text]


## Name of the first binding of `action` for the device in use, or of any device if the
## action has no binding for it.
func _action_text(action: StringName) -> String:
	if not InputMap.has_action(action):
		return "?"
	var fallback := ""
	for event in InputMap.action_get_events(action):
		var text := _event_text(event)
		if text.is_empty():
			continue
		if _is_joypad_event(event) == _using_joypad:
			return text
		if fallback.is_empty():
			fallback = text
	return fallback if not fallback.is_empty() else "?"


func _is_joypad_event(event: InputEvent) -> bool:
	return event is InputEventJoypadButton or event is InputEventJoypadMotion


func _event_text(event: InputEvent) -> String:
	if event is InputEventKey:
		var key_event := event as InputEventKey
		var keycode := key_event.keycode
		if key_event.physical_keycode != KEY_NONE:
			# Follows the player's keyboard layout
			keycode = DisplayServer.keyboard_get_keycode_from_physical(key_event.physical_keycode)
		return OS.get_keycode_string(keycode)
	if event is InputEventMouseButton:
		var button := (event as InputEventMouseButton).button_index
		return MOUSE_BUTTON_NAMES.get(button, "Mouse %d" % button)
	if event is InputEventJoypadButton:
		var joy_button := (event as InputEventJoypadButton).button_index
		return JOY_BUTTON_NAMES.get(joy_button, "Button %d" % joy_button)
	if event is InputEventJoypadMotion:
		var axis := (event as InputEventJoypadMotion).axis
		return JOY_AXIS_NAMES.get(axis, "Axis %d" % axis)
	return ""


func _weapon_names() -> String:
	if _player == null or _player.get_weapon_count() == 0:
		return "a weapon"
	var names: PackedStringArray = []
	for i in _player.get_weapon_count():
		var weapon := _player.get_weapon(i)
		if weapon != null:
			names.append(_key(weapon.get_display_name()))
	if names.size() == 1:
		return names[0]
	return ", ".join(names.slice(0, names.size() - 1)) + " and " + names[names.size() - 1]


func _rarity_legend() -> String:
	var parts: PackedStringArray = []
	for rarity: ItemData.Rarity in ItemData.Rarity.values():
		parts.append("[b][color=#%s]%s[/color][/b]" % [ItemData.get_rarity_color(rarity).to_html(false), ItemData.get_rarity_name(rarity)])
	return ", ".join(parts)
