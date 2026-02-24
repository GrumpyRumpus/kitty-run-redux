# Running state -- player is actively pressing left/right
#
# Uses two different acceleration values depending on whether the player is
# moving in the same direction as their current velocity (normal accel) or
# the opposite direction (skid accel). Higher skid acceleration makes
# direction changes feel snappy without affecting normal movement.
#
# Sprint multiplies both speed and animation playback rate for a satisfying
# "turbo" feel -- faster legs match faster movement.
class_name RunningState
extends State

@export_custom(PROPERTY_HINT_NONE, "suffix:px/s") var speed: float = 100
@export_custom(PROPERTY_HINT_NONE, "suffix:px/s") var sprint_speed: float = 150
# normal acceleration when moving in the current direction
@export var acceleration: float = 4
# higher acceleration when reversing direction (skidding)
@export var skid_acceleration: float = 8

var current_acceleration: float = 0
var target_speed: float = 0


func enter() -> void:
	current_acceleration = acceleration
	target_speed = speed
	kitty.animated_sprite.play("running")


func exit() -> void:
	# reset animation speed in case we were sprinting
	kitty.animated_sprite.speed_scale = 1.0

func handle_input(event: InputEvent) -> State:
	if event.is_action_pressed("up"):
		return jumping_state
	return null


func process(delta: float) -> State:
	return null


func process_physics(delta: float) -> State:
	# left the ground (walked off edge) -- fall
	if not kitty.is_on_floor():
		return falling_state
	# released movement keys -- decelerate to standing
	if state_machine.direction.x == 0:
		return standing_state
	# pick acceleration based on whether we're changing direction.
	# sign comparison: same sign = continuing, different = skidding.
	elif sign(state_machine.direction.x) == sign(kitty.velocity.x) or kitty.velocity.x == 0:
		current_acceleration = acceleration
	else:
		current_acceleration = skid_acceleration
	# hold sprint for a speed + animation boost
	if Input.is_action_pressed("sprint"):
		target_speed = sprint_speed
		kitty.animated_sprite.speed_scale = 1.5
	else:
		target_speed = speed
		kitty.animated_sprite.speed_scale = 1.0
	kitty.update_velocity(state_machine.direction.x * target_speed, current_acceleration)
	return null
