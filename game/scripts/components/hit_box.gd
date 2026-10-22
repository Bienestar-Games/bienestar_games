# hitbox.gd (script del Area2D del hitbox)
extends Area2D

@export var owner_character: Node

func take_damage(amount: int) -> void:
	owner_character.take_damage(amount)
