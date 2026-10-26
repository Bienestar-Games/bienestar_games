extends Node2D

const DEATH_SCREEN := "res://scenes/ui/death_screen/death_screen.tscn"

func _ready() -> void:
	Events.run_ended.connect(_on_run_ended)

func _on_run_ended(extracted: bool) -> void:
	if not extracted:
		get_tree().change_scene_to_file.call_deferred(DEATH_SCREEN)
		return
	# TODO B36: load results screen
	print("Run ended — extracted: ", extracted)
