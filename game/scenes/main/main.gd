extends Node2D

func _ready() -> void:
	Events.run_ended.connect(_on_run_ended)

func _on_run_ended(extracted: bool) -> void:
	# TODO B36: load results screen / B12: load death screen depending on extracted
	print("Run ended — extracted: ", extracted)
