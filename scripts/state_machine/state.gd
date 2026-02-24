# Base class for all character states (State Pattern)
#
# The State Pattern lets each behavior (standing, running, jumping, etc.) live
# in its own class instead of a giant if/else chain. Each state decides:
#   - what happens when it starts (enter)
#   - what happens each frame (process / process_physics)
#   - how to react to input (handle_input)
#   - what to clean up when leaving (exit)
#
# Returning a different State from any handler triggers a transition.
# Returning null means "stay in this state."
#
# Every state has direct references to all sibling states via Godot's unique
# name system (the % prefix). This avoids string lookups and gives type safety
# -- the editor will warn you if a node is missing.
class_name State
extends Node

# set by StateMachine.init() so every state can access the player
var kitty: Kitty
# set by StateMachine.init() so states can read shared data (direction, jump buffer)
var state_machine: StateMachine

# -------------------- Sibling State References --------------------
# these resolve at runtime via unique names (%Name) in the scene tree.
# every state can return any of these from its handler methods to trigger
# a transition, e.g. `return jumping_state`
@onready var standing_state: StandingState = %Standing
@onready var running_state: RunningState = %Running
@onready var jumping_state: JumpingState = %Jumping
@onready var falling_state: FallingState = %Falling
@onready var hurting_state: HurtingState = %Hurting
@onready var dead_state: DeadState = %Dead


func _ready() -> void:
	pass


# called once after the state machine wires up all references.
# use this for one-time setup that needs kitty or state_machine to exist.
func init() -> void:
	pass


# called when transitioning INTO this state
func enter() -> void:
	pass


# called when transitioning OUT of this state
func exit() -> void:
	pass


# called on unhandled input events (keyboard/gamepad presses).
# return a State to transition, or null to stay.
func handle_input(event: InputEvent) -> State:
	return null


# called every visual frame. use for non-physics logic (animation, timers).
# return a State to transition, or null to stay.
func process(delta: float) -> State:
	return null


# called every physics tick (default 60hz). use for movement and collision.
# return a State to transition, or null to stay.
func process_physics(delta: float) -> State:
	return null
