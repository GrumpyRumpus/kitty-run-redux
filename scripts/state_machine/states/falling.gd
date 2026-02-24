# Falling state -- downward arc of a jump, walking off edges, or post-hurt
#
# This state handles two important game-feel mechanics:
#
# 1. Coyote Time: a short grace period after walking off a ledge where you
#    can still jump. Named after Wile E. Coyote running off cliffs. Without
#    this, players feel cheated because they pressed jump "on time" but the
#    game disagrees. The timer only starts when entering from a non-jump
#    state (walking off an edge), not after the peak of a jump.
#
# 2. Jump Buffering: if the player pressed jump slightly before landing,
#    the state machine recorded it. On the frame we detect floor contact,
#    we check that buffer and immediately transition to jumping instead
#    of standing. This makes the game feel responsive at high speeds.
#
# The gravity multiplier (1.165x) makes the downward arc faster than the
# upward arc. This is a classic game-feel trick -- asymmetric gravity makes
# jumps feel "snappy" and gives the player more time at the peak (where
# they're making decisions) while spending less time falling (which is
# less interesting). See: "The Game Feel of Jump" by Jan Willem Nijman.
class_name FallingState
extends State

# multiplier applied to gravity while falling (>1.0 = faster descent)
@export var fall_gravity_multiplier: float = 1.165
@export_custom(PROPERTY_HINT_NONE, "suffix:px/s") var base_move_speed: float = 100
@export var acceleration: float = 8
# grace period for jumping after walking off an edge
@export var coyote_time: float = 0.15
# timer node wired up in the editor (one-shot)
@export var coyote_timer: Timer

# locked at enter() like the jumping state
var move_speed: float


func init() -> void:
	# configure the timer once at startup
	coyote_timer.wait_time = coyote_time
	coyote_timer.one_shot = true


func enter() -> void:
	kitty.animated_sprite.play("falling")
	move_speed = maxf(base_move_speed, abs(kitty.velocity.x))
	# heavier gravity on the way down
	kitty.gravity_multiplier = fall_gravity_multiplier
	# only start coyote time if we walked off an edge (not after a jump).
	# checking previous_state lets us distinguish "fell off" from "jumped".
	if state_machine.previous_state != jumping_state:
		coyote_timer.start()


func exit() -> void:
	# restore normal gravity for other states
	kitty.gravity_multiplier = 1.0


func handle_input(event: InputEvent) -> State:
	if event.is_action_pressed("up"):
		# coyote time: timer still running = treat this as a grounded jump
		if not coyote_timer.is_stopped():
			return jumping_state
		# standard double jump (one per grounded jump)
		if kitty.can_double_jump:
			kitty.can_double_jump = false
			return jumping_state
		# extra jumps from the powerup pickup
		if kitty.extra_jumps > 0:
			kitty.extra_jumps -= 1
			kitty.powerup_changed.emit()
			return jumping_state
	return null


func process(delta: float) -> State:
	return null


func process_physics(delta: float) -> State:
	kitty.update_velocity(state_machine.direction.x * move_speed, acceleration)
	if kitty.is_on_floor():
		# jump buffer: player pressed jump just before landing -- honor it
		if state_machine.jump_buffer_time > 0.0:
			state_machine.jump_buffer_time = 0.0
			return jumping_state
		return standing_state
	return null
