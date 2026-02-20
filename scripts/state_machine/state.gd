class_name State
extends Node2D

static var kitty: Kitty
static var state_machine: StateMachine
static var direction: Vector2

@onready var standing_state: StandingState = %Standing
@onready var running_state: RunningState = %Running
@onready var jumping_state: JumpingState = %Jumping
@onready var falling_state: FallingState = %Falling
@onready var hurting_state: HurtingState = %Hurting
@onready var dead_state: DeadState = %Dead


func _ready() -> void:
	pass


func init() -> void:
	pass


func enter() -> void:
	pass


func exit() -> void:
	pass


func handle_input(event: InputEvent) -> State:
	return null
	

func process(delta: float) -> State:
	return null


func process_physics(delta: float) -> State:
	return null
