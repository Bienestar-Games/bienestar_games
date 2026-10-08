class_name BaseCharacter
extends CharacterBody2D

signal died
signal damage_taken

@export var MAX_SPEED    : int = 200
@export var ACCELERATION : int = 1500
@export var FRICTION: int = 1800

@export var animation_tree: AnimationTree
@export var entity_sprite: Sprite2D

var move_direction: Vector2 = Vector2.ZERO
var _last_move_direction: Vector2 = Vector2.DOWN
var base_health: float = 100
var immortal: bool = false
var base_damage: float = 5

func take_damage(damage: float) -> void:
	if !immortal:
		var was_alive := _is_alive()
		base_health -= damage
		damage_taken.emit()
		if was_alive and base_health <= 0:
			base_health = 0
			died.emit()

func _is_alive() -> bool:
	return base_health > 0

func move(input_dir: Vector2, delta: float) -> void:
	if input_dir != Vector2.ZERO:
		input_dir = input_dir.normalized()
		velocity.x += input_dir.x * ACCELERATION * delta
		velocity.y += input_dir.y * ACCELERATION * delta
	else:
		velocity.x = move_toward(velocity.x, 0, FRICTION * delta)
		velocity.y = move_toward(velocity.y, 0, FRICTION * delta)

	velocity = velocity.limit_length(MAX_SPEED)
	move_and_slide()


func stop_moving() -> void:
	self.move_direction = Vector2.ZERO
	
func is_idle() -> bool:
	return move_direction == Vector2.ZERO and velocity.length() < 1.0
	
func flip_player_sprite( value: bool) -> void:
	match value:
		true:
			self.entity_sprite.scale.x = -1.0
		false:
			self.entity_sprite.scale.x = 1.0

func handle_flip_h_sprite():
	if move_direction.x > 0:
		flip_player_sprite(false)
	elif move_direction.x < 0:
		flip_player_sprite(true)
