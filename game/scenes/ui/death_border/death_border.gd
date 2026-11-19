class_name DeathBorder
extends CanvasLayer
## Death Border (GDD §4, §8 Nivel 3, §15.11): accumulated run risk shown as a screen
## vignette that closes in from the edges, plus a minimal non-numeric HUD icon.
## Risk rises with every wave fought. The risk steps live in balance_config.tres.

const BALANCE_CONFIG: BalanceConfig = preload("res://resources/config/balance_config.tres")

## Seconds the vignette and icon take to catch up with a risk change.
@export var transition_time: float = 1.5

@onready var _vignette: ColorRect = %Vignette
@onready var _icon: DeathBorderIcon = %Icon

var _risk: float = 0.0
var _shown_risk: float = 0.0
var _tween: Tween

func _ready() -> void:
	_apply_risk(0.0)
	Events.wave_started.connect(_on_wave_started)

func _on_wave_started(wave_number: int) -> void:
	# First wave of a new run resets the vignette; every later wave raises the risk.
	if wave_number <= 1:
		_risk = 0.0
		_apply_risk(0.0)
		return
	_raise_risk(BALANCE_CONFIG.death_border_open_wave_step)

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
