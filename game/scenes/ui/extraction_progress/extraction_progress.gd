class_name ExtractionProgress
extends CanvasLayer
## Extraction channel feedback (GDD §8 Nivel 3): progress bar while Kade channels the
## 5 s extraction, and a visible cancel cue when damage or an enemy interrupts it.

@export var channel_color: Color = Color(0.3, 0.8, 0.3)
@export var cancelled_color: Color = Color(0.85, 0.2, 0.2)
## Seconds the "cancelled" / "extracted" message stays on screen before fading out.
@export var result_hold_time: float = 1.2
@export var fade_time: float = 0.4
@export var shake_strength: float = 12.0

@onready var _root: Control = %Root
@onready var _status_label: Label = %StatusLabel
@onready var _progress_bar: ProgressBar = %ProgressBar

var _bar_fill: StyleBoxFlat
var _tween: Tween

func _ready() -> void:
	_bar_fill = _progress_bar.get_theme_stylebox("fill") as StyleBoxFlat
	visible = false
	Events.extraction_started.connect(_on_extraction_started)
	Events.extraction_progress_updated.connect(_on_progress_updated)
	Events.extraction_cancelled.connect(_on_extraction_cancelled)
	Events.extraction_completed.connect(_on_extraction_completed)
	Events.run_ended.connect(_on_run_ended)

func _on_extraction_started() -> void:
	_kill_tween()
	_root.modulate.a = 1.0
	_root.position.x = 0.0
	_bar_fill.bg_color = channel_color
	_status_label.modulate = Color.WHITE
	_status_label.text = "Extracting… don't get hit"
	_progress_bar.value = 0.0
	visible = true

func _on_progress_updated(progress: float) -> void:
	_progress_bar.value = progress

func _on_extraction_cancelled() -> void:
	if not visible:
		return
	_bar_fill.bg_color = cancelled_color
	_status_label.modulate = cancelled_color
	_status_label.text = "Extraction cancelled"
	_kill_tween()
	_tween = create_tween()
	for offset in [shake_strength, -shake_strength, shake_strength * 0.5, -shake_strength * 0.5, 0.0]:
		_tween.tween_property(_root, "position:x", offset, 0.04)
	_fade_out()

func _on_extraction_completed() -> void:
	_progress_bar.value = 1.0
	_status_label.text = "Extracted!"
	_kill_tween()
	_tween = create_tween()
	_fade_out()

# Death during the channel: hide immediately, the death screen takes over
func _on_run_ended(extracted: bool) -> void:
	if not extracted:
		_kill_tween()
		visible = false

func _fade_out() -> void:
	_tween.tween_interval(result_hold_time)
	_tween.tween_property(_root, "modulate:a", 0.0, fade_time)
	_tween.tween_callback(hide)

func _kill_tween() -> void:
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_tween = null
