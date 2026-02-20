class_name StateMachine
extends Node2D

var states: Array[State]
var current_state: State:
	get: return states.front()
var previous_state: State:
	get: return states[1]

var kitty: Kitty


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_DISABLED


func _process(delta: float) -> void:
	var new_state = current_state.process(delta)
	change_state(new_state)


func _physics_process(delta: float) -> void:
	var new_state = current_state.process_physics(delta)
	change_state(new_state)


func _unhandled_input(event: InputEvent) -> void:
	current_state.direction = Vector2(
		sign(Input.get_axis("left", "right")),
		sign(Input.get_axis("up", "down"))
	)
	var new_state = current_state.handle_input(event)
	change_state(new_state)


func change_state(new_state: State) -> void:
	if new_state == null:
		return
	#if new_state == current_state:
	#	print("Already in state: ", new_state)
	#	return
	if current_state:
		current_state.exit()
	states.push_front(new_state)
	current_state.enter()
	states.resize(3)
	#print(states)


func init(kitty: Kitty) -> void:
	states = []
	for c in get_children():
		if c is State:
			states.append(c)
	if states.size() == 0:
		return
	current_state.kitty = kitty
	current_state.state_machine = self
	for state in states:
		state.init()
	change_state(current_state)
	process_mode = Node.PROCESS_MODE_INHERIT
