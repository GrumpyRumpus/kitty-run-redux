# Dead state -- game over death sequence
#
# When health reaches zero, the character launches upward and falls off
# screen with all collision disabled. This "ragdoll launch" is a common
# death animation in platformers -- it's dramatic, clearly communicates
# death, and buys time for the game-over UI to prepare.
#
# Collision layers are zeroed out so the corpse doesn't interact with
# anything during the fall. They're restored in exit() in case the state
# machine is ever reset (e.g., for a retry system).
#
# The actual game-over trigger fires when the body falls below a Y
# threshold, not immediately on entering this state. This gives the
# death animation time to play out before the UI takes over.
class_name DeadState
extends State

# upward launch speed on death (negative = up)
const DEATH_LAUNCH_VELOCITY := -200.0
# how far below the screen the body must fall before triggering game over
const DEATH_Y_THRESHOLD := 300.0

# saved collision state so we can restore it on exit
var original_collision_layer: int
var original_collision_mask: int
# prevents die() from firing multiple times during the fall
var has_died: bool = false


func enter() -> void:
	has_died = false
	kitty.animated_sprite.play("hurting")
	# launch upward for the dramatic death arc
	kitty.velocity.y = DEATH_LAUNCH_VELOCITY
	kitty.velocity.x = 0
	# save and clear collision so the body passes through everything
	original_collision_layer = kitty.collision_layer
	original_collision_mask = kitty.collision_mask
	kitty.collision_layer = 0
	kitty.collision_mask = 0


func exit() -> void:
	# restore collision (needed if the game resets without destroying the scene)
	kitty.collision_layer = original_collision_layer
	kitty.collision_mask = original_collision_mask


func handle_input(_event: InputEvent) -> State:
	return null


func process(_delta: float) -> State:
	return null


func process_physics(_delta: float) -> State:
	# wait for the body to fall off screen before triggering game over
	if not has_died and kitty.global_position.y > DEATH_Y_THRESHOLD:
		has_died = true
		kitty.die()
	return null
