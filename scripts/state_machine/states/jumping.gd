# Jumping state -- upward arc of a jump
#
# Implements variable-height jumping: the initial press launches at full
# velocity, but releasing the button early multiplies velocity by 0.3,
# cutting the jump short. This gives the player precise height control
# with a single button -- tap for small hops, hold for full jumps.
#
# Double jumps are tracked on the player (kitty.can_double_jump). The
# first grounded jump enables double jump; using it in the air spawns
# a dust puff for visual feedback and plays the sound at a higher pitch
# so the player can hear the difference.
#
# Air speed is locked to whichever is higher: base_move_speed or the
# player's current horizontal speed at jump time. This preserves sprint
# momentum through jumps without allowing air acceleration beyond it.
class_name JumpingState
extends State

@export var jump_velocity: float = 350
@export_custom(PROPERTY_HINT_NONE, "suffix:px/s") var base_move_speed: float = 100
@export var acceleration: float = 8

# locked at enter() to preserve momentum through the jump
var move_speed: float = 0


func enter() -> void:
	# clear jump buffer so we don't double-trigger on landing
	state_machine.jump_buffer_time = 0.0
	kitty.animated_sprite.play("jumping")
	# detect double jump: if we're not on the floor, this is an air jump
	var is_double_jump := not kitty.is_on_floor()
	# pitch the jump sound up for double jumps (audio feedback for game state)
	kitty.audio_stream_player.pitch_scale = 1.4 if is_double_jump else 1.0
	kitty.audio_stream_player.play()
	# apply upward velocity (negative y = up in Godot's coordinate system)
	kitty.velocity.y = -jump_velocity
	if is_double_jump:
		# visual feedback: puff of dust in the air sells the "second push"
		kitty._spawn_dust_puff()
	else:
		# first jump from ground grants one double jump
		kitty.can_double_jump = true
	# lock horizontal speed: max of base speed or current speed.
	# this means sprinting into a jump keeps the sprint speed.
	move_speed = maxf(base_move_speed, abs(kitty.velocity.x))


func exit() -> void:
	pass


func handle_input(event: InputEvent) -> State:
	# variable jump height: releasing the button early cuts upward velocity.
	# multiplying by 0.3 (not 0) keeps a small upward arc so it doesn't
	# feel like you hit a ceiling.
	if event.is_action_released("up"):
		kitty.velocity.y *= 0.3
		return falling_state
	return null


func process(delta: float) -> State:
	return null


func process_physics(delta: float) -> State:
	# once velocity turns downward, transition to falling.
	# the falling state applies a gravity multiplier for a faster descent
	# (makes jumps feel punchy rather than floaty).
	if kitty.velocity.y >= 0:
		return falling_state
	return null
