# State machine controller -- orchestrates state transitions for the player
#
# This node sits in the Kitty scene tree as a parent of all State nodes.
# It delegates _process, _physics_process, and _unhandled_input to whatever
# state is currently active. When a state returns a new state from any of
# its handlers, the machine performs the transition (exit old, enter new).
#
# The machine also owns shared data that multiple states need:
#   - direction: current input vector (updated every input event)
#   - jump_buffer_time: how long ago the player pressed jump
#
# Jump buffering explained:
#   Without buffering, pressing jump 1 frame before landing does nothing
#   because the falling state doesn't allow jumping when airborne (unless
#   you have double jump). The buffer records "player wants to jump" and
#   the falling state checks it on landing. This makes the game feel
#   responsive even with imperfect timing.
class_name StateMachine
extends Node

# how long a jump press stays "buffered" (consumed on next landing)
const JUMP_BUFFER_WINDOW := 0.15

var current_state: State
var previous_state: State
# combined input direction: x for left/right, y for up/down
var direction: Vector2
# counts down from JUMP_BUFFER_WINDOW; positive = jump press is buffered
var jump_buffer_time: float = 0.0

var kitty: Kitty


func _ready() -> void:
	# start disabled -- init() enables processing once states are wired up.
	# this prevents states from running before they have references to kitty.
	process_mode = Node.PROCESS_MODE_DISABLED


# -------------------- Frame Delegation --------------------

func _process(delta: float) -> void:
	var new_state: State = current_state.process(delta)
	change_state(new_state)


func _physics_process(delta: float) -> void:
	# tick down the jump buffer each physics frame
	if jump_buffer_time > 0.0:
		jump_buffer_time -= delta
	var new_state: State = current_state.process_physics(delta)
	change_state(new_state)


func _unhandled_input(event: InputEvent) -> void:
	# record jump presses into the buffer (even if the current state ignores them)
	if event.is_action_pressed("up"):
		jump_buffer_time = JUMP_BUFFER_WINDOW
	# snapshot the current input direction as a normalized vector.
	# sign() gives -1, 0, or 1 so diagonal input stays unit-length.
	direction = Vector2(
		sign(Input.get_axis("left", "right")),
		sign(Input.get_axis("up", "down"))
	)
	var new_state: State = current_state.handle_input(event)
	change_state(new_state)


# -------------------- State Transitions --------------------

func change_state(new_state: State) -> void:
	# null means "no transition requested"
	# same-state guard prevents re-entry bugs (exit+enter on the same state)
	if new_state == null or new_state == current_state:
		return
	if current_state:
		current_state.exit()
	previous_state = current_state
	current_state = new_state
	current_state.enter()


# -------------------- Initialization --------------------

# called by Kitty._ready() to wire up all child states.
# iterates children, gives each one a reference to kitty and this machine,
# calls init() for one-time setup, then enters the first state found.
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
	# enable processing now that everything is wired up
	process_mode = Node.PROCESS_MODE_INHERIT
