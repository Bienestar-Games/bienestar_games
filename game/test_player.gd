extends BaseCharacter
## TEST-ONLY stand-in for Kade (the real one is B06). Not used in the game.
## Moves with move_* (WASD) and hits nearby enemies with shoot (left click).

@export var move_speed := 220.0
@export var attack_damage := 10
@export var attack_cooldown := 0.3

var _attack_timer := 0.0

@onready var sprite: Sprite2D = $Sprite2D
@onready var attack_area: Area2D = $AttackArea


func _ready() -> void:
	super._ready()
	add_to_group("player")
	damaged.connect(func(_amount): _flash())


func _physics_process(delta: float) -> void:
	if is_dead:
		return
	var direction := Input.get_vector(&"move_left", &"move_right", &"move_up", &"move_down")
	velocity = direction * move_speed
	if direction != Vector2.ZERO:
		sprite.rotation = direction.angle()
	move_and_slide()

	_attack_timer -= delta
	if Input.is_action_pressed(&"shoot") and _attack_timer <= 0.0:
		attack()


func attack() -> void:
	_attack_timer = attack_cooldown
	for body in attack_area.get_overlapping_bodies():
		if body != self and body.is_in_group("enemies"):
			body.take_damage(attack_damage)


func _flash() -> void:
	sprite.modulate = Color(1, 0.3, 0.3)
	create_tween().tween_property(sprite, "modulate", Color.WHITE, 0.2)


func _on_died() -> void:
	velocity = Vector2.ZERO
	sprite.modulate = Color(0.4, 0.4, 0.4)
