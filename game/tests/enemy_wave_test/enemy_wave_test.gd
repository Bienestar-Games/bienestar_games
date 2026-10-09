extends Node2D
## Sandbox for B07 + B08 on the real shelter map.
## Starts a wave on load and another one 3 s after each wave ends.

@onready var player: BaseCharacter = $Shelter/TestPlayer
@onready var label: Label = $HUD/Label

var _status := ""


func _ready() -> void:
	WaveManager.reset()
	WaveManager.wave_started.connect(_on_wave_started)
	WaveManager.enemies_remaining_changed.connect(func(_n): _refresh())
	WaveManager.wave_ended.connect(_on_wave_ended)
	player.health_changed.connect(func(_c, _m): _refresh())
	player.died.connect(func(): _status = "Kade died"; _refresh())
	# Wait one physics frame so the TileMap navigation map is synced.
	await get_tree().physics_frame
	await get_tree().physics_frame
	WaveManager.start_wave()


func _exit_tree() -> void:
	WaveManager.reset()


func _on_wave_started(wave_number: int, count: int) -> void:
	_status = "Wave %d started (%d enemies)" % [wave_number, count]
	_refresh()


func _on_wave_ended(wave_number: int) -> void:
	_status = "Wave %d ended. Next one in 3 s" % wave_number
	_refresh()
	await get_tree().create_timer(3.0).timeout
	if is_inside_tree() and not player.is_dead:
		WaveManager.start_wave()


func _refresh() -> void:
	label.text = "HP %d   |   Enemies left %d   |   %s\nArrows: move   Space: hit" % [
		player.current_health, WaveManager.enemies_remaining, _status]
