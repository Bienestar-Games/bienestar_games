class_name DamageFlash
extends CanvasLayer
## Damage feedback (GDD §4, "Flash rojo en pantalla"): a short full-screen red tint
## every time the player takes damage. It snaps in and fades out fast so it stays
## distinct from the slow, edge-only Death Border vignette.

## Seconds the flash takes to fade out after a hit.
@export var fade_time: float = 0.25

@onready var _overlay: ColorRect = %Overlay

var _tween: Tween

func _ready() -> void:
	_overlay.visible = false
	var player := get_tree().get_first_node_in_group("player") as Player
	if player == null:
		push_warning("DamageFlash: no Player found in group 'player'.")
		return
	player.damage_taken.connect(_on_damage_taken)

func _on_damage_taken() -> void:
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_overlay.visible = true
	_set_intensity(1.0)
	_tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	_tween.tween_method(_set_intensity, 1.0, 0.0, fade_time)
	_tween.tween_callback(_overlay.hide)

func _set_intensity(value: float) -> void:
	(_overlay.material as ShaderMaterial).set_shader_parameter("intensity", value)
