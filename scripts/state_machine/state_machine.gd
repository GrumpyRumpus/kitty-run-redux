class_name StateMachine
extends Node

var current_state: State
var previous_state: State
var direction: Vector2

var kitty: Kitty


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_DISABLED


func _process(delta: float) -> void:
	var new_state: State = current_state.process(delta)
	change_state(new_state)


func _physics_process(delta: float) -> void:
	var new_state: State = current_state.process_physics(delta)
	change_state(new_state)


func _unhandled_input(event: InputEvent) -> void:
	direction = Vector2(
		sign(Input.get_axis("left", "right")),
		sign(Input.get_axis("up", "down"))
	)
	var new_state: State = current_state.handle_input(event)
	change_state(new_state)


func change_state(new_state: State) -> void:
	if new_state == null:
		return
	if current_state:
		current_state.exit()
	previous_state = current_state
	current_state = new_state
	current_state.enter()


func init(kitty: Kitty) -> void:
	for c in get_children():
		if c is State:
			c.kitty = kitty
			c.state_machine = self
			c.init()
			if current_state == null:
				current_state = c
	if current_state == null:
		return
	current_state.enter()
	process_mode = Node.PROCESS_MODE_INHERIT
