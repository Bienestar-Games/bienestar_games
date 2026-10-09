extends State
## Melee attack: stops, telegraphs the hit (arms raised + tint) and, after the windup,
## damages Kade if he is still inside the HitBox.

const TELEGRAPH_COLOR := Color(1.0, 0.55, 0.55)

## Texture shown while winding up (zombie with arms up). Set in enemy.tscn.
@export var windup_texture: Texture2D

@onready var enemy: Enemy = owner

var _timer := 0.0
var _idle_texture: Texture2D


func enter(_msg: Dictionary = {}) -> void:
	_timer = enemy.attack_windup
	enemy.velocity = Vector2.ZERO
	var direction := enemy.global_position.direction_to(enemy.target.global_position)
	enemy.face(direction)
	# Put the hit box in front of the enemy, toward Kade.
	enemy.hit_box.position = direction * enemy.attack_range * 0.6
	_idle_texture = enemy.sprite.texture
	if windup_texture:
		enemy.sprite.texture = windup_texture
	enemy.sprite.modulate = TELEGRAPH_COLOR


func exit() -> void:
	enemy.sprite.texture = _idle_texture
	enemy.sprite.modulate = Color.WHITE


func physics_update(delta: float) -> void:
	_timer -= delta
	if _timer > 0.0:
		return
	for body in enemy.hit_box.get_overlapping_bodies():
		if body.is_in_group("player") and body.has_method("take_damage"):
			body.take_damage(enemy.attack_damage)
	state_machine.transition_to(&"AttackRecovery")
