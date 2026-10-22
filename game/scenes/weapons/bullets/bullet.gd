extends Node2D
class_name Bullet

@export var ray: RayCast2D

@export var SPEED: float = 1000.0
@export var LIFETIME: float = 2.0
@export var DAMAGE: float = 50.0

var _age: float = 0.0

func _physics_process(delta: float) -> void:
	var motion: Vector2 = transform.x * SPEED * delta
	ray.target_position = Vector2(motion.length(), 0)  # local, hacia +X
	ray.force_raycast_update()

	if ray.is_colliding():
		global_position = ray.get_collision_point()
		var collider: Object = ray.get_collider()
		if collider is Area2D and collider.has_method("take_damage"):
			collider.take_damage(DAMAGE)
		queue_free()
		return

	position += motion
	_age += delta
	if _age >= LIFETIME:
		queue_free()
