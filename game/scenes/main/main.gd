extends Node2D

const GAME_OVER_SCREEN := "res://scenes/ui/game_over_screen/game_over_screen.tscn"

func _ready() -> void:
	Events.run_ended.connect(_on_run_ended)

func _on_run_ended() -> void:
	GameOverScreen.waves_survived = GameLoopManager.wave_number
	get_tree().change_scene_to_file.call_deferred(GAME_OVER_SCREEN)
