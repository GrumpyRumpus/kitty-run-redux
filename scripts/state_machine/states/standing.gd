# Idle state -- player isn't pressing movement keys
#
# In an infinite runner the character is always visually running (the world
# scrolls beneath them), so "standing" means the player's input is idle,
# not that the character is literally still. The running animation keeps
# playing to match the scrolling ground.
#
# This state applies deceleration to bleed off any leftover velocity from
# the running state, so the character slides to a gradual stop rather than
# snapping to zero.
class_name StandingState
extends State


# how fast horizontal velocity decays toward zero (pixels/frame via lerp weight)
@export var deceleration: float = 8


func enter() -> void:
	# keep the running animation since the world is always scrolling
	kitty.animated_sprite.play("running")


func exit() -> void:
	pass

func handle_input(event: InputEvent) -> State:
	if event.is_action_pressed("up"):
		return jumping_state
	return null


func process(delta: float) -> State:
	# any horizontal input switches to the running state
	if state_machine.direction.x != 0:
		return running_state
	return null


func process_physics(delta: float) -> State:
	# decelerate toward zero (move_toward with weight, not raw friction)
	kitty.update_velocity(0, deceleration)
	# walked off a ledge -- switch to falling
	if not kitty.is_on_floor():
		return falling_state
	return null
