class_name DeathBorder
extends CanvasLayer
## Death Border (GDD §4, §8 Nivel 3, §15.11): accumulated run risk shown as a screen
## vignette that closes in from the edges, plus a minimal non-numeric HUD icon.
## Risk rises when the barrier opens and with every wave fought while it stays open.

## Risk added the moment the barrier opens.
@export_range(0.0, 1.0) var barrier_open_step: float = 0.4
## Risk added for every wave that starts with the barrier open.
@export_range(0.0, 1.0) var open_wave_step: float = 0.12
## Seconds the vignette and icon take to catch up with a risk change.
@export var transition_time: float = 1.5

@onready var _vignette: ColorRect = %Vignette
@onready var _icon: DeathBorderIcon = %Icon

var _risk: float = 0.0
var _shown_risk: float = 0.0
var _barrier_open: bool = false
var _tween: Tween

func _ready() -> void:
	_apply_risk(0.0)
	Events.barrier_opened.connect(_on_barrier_opened)
	Events.wave_started.connect(_on_wave_started)

func _on_barrier_opened() -> void:
	if _barrier_open:
		return
	_barrier_open = true
	_raise_risk(barrier_open_step)

func _on_wave_started(_wave_number: int) -> void:
	if _barrier_open:
		_raise_risk(open_wave_step)

func _raise_risk(amount: float) -> void:
	_risk = minf(_risk + amount, 1.0)
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_tween.tween_method(_apply_risk, _shown_risk, _risk, transition_time)

func _apply_risk(value: float) -> void:
	_shown_risk = value
	(_vignette.material as ShaderMaterial).set_shader_parameter("risk", value)
	_icon.risk = value
