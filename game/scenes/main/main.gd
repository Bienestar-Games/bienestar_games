extends Node2D

const DEATH_SCREEN := "res://scenes/ui/death_screen/death_screen.tscn"
const RESULTS_SCREEN := "res://scenes/ui/results_screen/results_screen.tscn"

func _ready() -> void:
	Events.run_ended.connect(_on_run_ended)

func _on_run_ended(extracted: bool) -> void:
	if not extracted:
		get_tree().change_scene_to_file.call_deferred(DEATH_SCREEN)
		return
	var player := get_tree().get_first_node_in_group("player") as Player
	ResultsScreen.kept_items.clear()
	if player != null:
		ResultsScreen.kept_items.assign(player.inventory)
	# Extraction only starts from decision_state, so the current wave was cleared
	ResultsScreen.waves_survived = GameLoopManager.wave_number
	get_tree().change_scene_to_file.call_deferred(RESULTS_SCREEN)
