class_name ExtractionZone
extends Area2D

@export var label: Label

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	Events.extraction_started.connect(_on_extraction_started)
	Events.extraction_cancelled.connect(_on_extraction_cancelled)
	Events.extraction_completed.connect(_on_extraction_completed)

func _on_body_entered(body: Node2D) -> void:
	# An enemy entering during active extraction cancels the channel (§8 MVP)
	if body.is_in_group("enemy") and GameLoopManager.current_state == GameLoopManager.RunState.EXTRACTING:
		Events.extraction_cancelled.emit()

func _on_body_exited(_body: Node2D) -> void:
	pass

func _on_extraction_started() -> void:
	if label:
		label.text = "Extracting…"

func _on_extraction_cancelled() -> void:
	if label:
		label.text = "Extraction cancelled"

func _on_extraction_completed() -> void:
	if label:
		label.text = "Extracted!"
