class_name State
extends Node
## Base state for a StateMachine. Override only the callbacks you need.

## Set by the StateMachine before the first enter().
var state_machine: StateMachine


func enter(_msg: Dictionary = {}) -> void:
	pass


func exit() -> void:
	pass


func update(_delta: float) -> void:
	pass


func physics_update(_delta: float) -> void:
	pass


func handle_input(_event: InputEvent) -> void:
	pass
