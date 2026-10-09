class_name StateMachine
extends Node
## Generic finite state machine. Every child node must be a State.
## Transition with transition_to("StateNodeName").

signal state_changed(from_state: StringName, to_state: StringName)

@export var initial_state: State

var current_state: State
var _states: Dictionary = {}


func _ready() -> void:
	for child in get_children():
		if child is State:
			_states[child.name] = child
			child.state_machine = self
	# Wait until the owner (the character) has finished its own _ready().
	if owner and not owner.is_node_ready():
		await owner.ready
	current_state = initial_state if initial_state else get_child(0) as State
	if current_state:
		current_state.enter()


func _process(delta: float) -> void:
	if current_state:
		current_state.update(delta)


func _physics_process(delta: float) -> void:
	if current_state:
		current_state.physics_update(delta)


func _unhandled_input(event: InputEvent) -> void:
	if current_state:
		current_state.handle_input(event)


func transition_to(state_name: StringName, msg: Dictionary = {}) -> void:
	var next: State = _states.get(state_name)
	if next == null:
		push_error("StateMachine: state '%s' does not exist in %s." % [state_name, owner.name])
		return
	var previous := current_state.name if current_state else &""
	if current_state:
		current_state.exit()
	current_state = next
	current_state.enter(msg)
	state_changed.emit(previous, state_name)


## Stops every state callback (for example, when the character dies).
func stop() -> void:
	if current_state:
		current_state.exit()
	current_state = null
	set_process(false)
	set_physics_process(false)
	set_process_unhandled_input(false)
