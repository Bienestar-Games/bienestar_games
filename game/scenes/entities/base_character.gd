class_name BaseCharacter
extends CharacterBody2D
## Base class for every living character (Kade and enemies): health, damage and death.
## Subclasses that override _ready() must call super._ready().

signal health_changed(current_health: int, max_health: int)
signal damaged(amount: int)
signal died

@export var base_health: int = 100

var current_health: int
var is_dead := false


func _ready() -> void:
	current_health = base_health


func take_damage(amount: int) -> void:
	if is_dead or amount <= 0:
		return
	current_health = max(current_health - amount, 0)
	damaged.emit(amount)
	health_changed.emit(current_health, base_health)
	if current_health == 0:
		die()


func heal(amount: int) -> void:
	if is_dead or amount <= 0:
		return
	current_health = min(current_health + amount, base_health)
	health_changed.emit(current_health, base_health)


func die() -> void:
	if is_dead:
		return
	is_dead = true
	died.emit()
	_on_died()


## Override in subclasses for death behaviour (animation, freeing, end of run…).
func _on_died() -> void:
	pass
