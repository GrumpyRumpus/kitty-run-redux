class_name RunningState
extends State

@export_custom(PROPERTY_HINT_NONE, "suffix:px/s") var speed: float = 100
@export_custom(PROPERTY_HINT_NONE, "suffix:px/s") var sprint_speed: float = 150
@export var acceleration: float = 4
@export var skid_acceleration: float = 8

var current_acceleration: float = 0
var current_direction: float = 0
var target_speed: float = 0


func init() -> void:
	pass


func enter() -> void:
	current_acceleration = acceleration
	target_speed = speed
	kitty.animated_sprite.play("running")
	

func exit() -> void:
	kitty.animated_sprite.speed_scale = 1.0

func handle_input(event: InputEvent) -> State:
	if event.is_action_pressed("up"):
		return jumping_state
	return null


func process(delta: float) -> State:
	return null


func process_physics(delta: float) -> State:
	if not kitty.is_on_floor():
		return falling_state
	if state_machine.direction.x == 0:
		return standing_state
	elif sign(state_machine.direction.x) == sign(kitty.velocity.x) or kitty.velocity.x == 0:
		current_acceleration = acceleration
	else:
		current_acceleration = skid_acceleration
	if Input.is_action_pressed("sprint"):
		target_speed = sprint_speed
		kitty.animated_sprite.speed_scale = 1.5
	else:
		target_speed = speed
		kitty.animated_sprite.speed_scale = 1.0
	kitty.update_velocity(state_machine.direction.x * target_speed, current_acceleration)
	return null
