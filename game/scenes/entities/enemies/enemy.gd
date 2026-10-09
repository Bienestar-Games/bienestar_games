class_name Enemy
extends BaseCharacter
## Base melee enemy: chases Kade with NavigationAgent2D, hits him in melee and dies.
## Behaviour lives in the states under scripts/states/enemy/.
## Concrete enemies (melee_basic, melee_fast) inherit enemy.tscn and only change the numbers.
## TODO(B20): read these values from balance_config.tres instead of @export defaults.

@export_group("Movement")
@export var move_speed: float = 60.0
## Seconds between path recalculations while chasing.
@export var repath_interval: float = 0.25

@export_group("Melee attack")
@export var attack_damage: int = 10
## Distance to Kade at which the enemy stops and starts the attack.
@export var attack_range: float = 40.0
## Telegraph time before the hit lands (lets the player dodge).
@export var attack_windup: float = 0.4
## Time standing still after the hit before chasing again.
@export var attack_recovery: float = 0.8

## Current target (Kade). Found through the "player" group.
var target: Node2D

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var navigation_agent: NavigationAgent2D = $NavigationAgent2D
@onready var hit_box: Area2D = $HitBox
@onready var state_machine: StateMachine = $StateMachine


func _ready() -> void:
	super._ready()
	add_to_group("enemies")
	navigation_agent.target_desired_distance = attack_range * 0.8
	find_target()


## Returns true when there is a living target.
func find_target() -> bool:
	if has_valid_target():
		return true
	target = get_tree().get_first_node_in_group("player") as Node2D
	return has_valid_target()


func has_valid_target() -> bool:
	if not is_instance_valid(target):
		return false
	if "is_dead" in target and target.is_dead:
		return false
	return true


func distance_to_target() -> float:
	return global_position.distance_to(target.global_position)


## Kenney top-down sprites look to the right, so we rotate the sprite toward the direction.
func face(direction: Vector2) -> void:
	if direction.length_squared() > 0.001:
		sprite.rotation = direction.angle()


func _on_died() -> void:
	state_machine.stop()
	velocity = Vector2.ZERO
	collision_shape.set_deferred("disabled", true)
	hit_box.set_deferred("monitoring", false)
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.3)
	tween.tween_callback(queue_free)
