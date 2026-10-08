# weapon.gd
class_name Weapon extends Node2D

@export var weapon_sprite: AnimatedSprite2D
@export var magazine: Magazine
@export var bullet_scene: PackedScene
@export var pivot_node: Node2D
@export var muzzle: Node2D
@export var _animation_player: AnimationPlayer
@export var _weapon_root: Node2D
@export var shoot_cd: Timer
@export var reload_cd: Timer

const ORBIT_RADIUS: float = 30.0

#func _process(delta: float) -> void:
	#_update_orbit_and_aim()
func _update_orbit_and_aim() -> void:
	if pivot_node == null:
		return
	var pivot: Vector2 = pivot_node.global_position
	var to_mouse: Vector2 = get_global_mouse_position() - pivot
	if to_mouse.length_squared() < 0.01:
		return
	var direction: Vector2 = to_mouse.normalized()
	global_position = pivot + direction * ORBIT_RADIUS
	rotation = direction.angle()
	_weapon_root.scale.y = -1.0 if direction.x < 0.0 else 1.0

func _spawn_bullet() -> void:
	var bullet: Bullet = bullet_scene.instantiate()
	get_tree().current_scene.add_child(bullet)
	bullet.global_position = muzzle.global_position
	bullet.global_rotation = global_rotation + _get_weapon_inaccuracy()

func _get_weapon_inaccuracy() -> float:
	return randf_range(-40,40)/360
