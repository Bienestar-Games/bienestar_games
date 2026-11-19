extends Node2D
## Root of a run. Shows the tutorial the first time the game is ever played (saved in
## SaveManager) and starts the waves once it is finished or skipped; every later run
## starts right away.

const GAME_OVER_SCREEN := "res://scenes/ui/game_over_screen/game_over_screen.tscn"
const TUTORIAL_SCENE: PackedScene = preload("res://scenes/ui/tutorial/tutorial.tscn")

func _ready() -> void:
	Events.run_ended.connect(_on_run_ended)
	if SaveManager.tutorial_completed:
		GameLoopManager.start_run()
		return
	var tutorial := TUTORIAL_SCENE.instantiate() as Tutorial
	tutorial.finished.connect(_on_tutorial_finished, CONNECT_ONE_SHOT)
	add_child(tutorial)

func _on_tutorial_finished() -> void:
	SaveManager.mark_tutorial_completed()
	GameLoopManager.start_run()

func _on_run_ended() -> void:
	GameOverScreen.waves_survived = GameLoopManager.wave_number
	get_tree().change_scene_to_file.call_deferred(GAME_OVER_SCREEN)
