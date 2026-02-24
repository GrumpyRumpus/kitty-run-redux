# Hurting state -- brief stun after taking damage
#
# When the player takes a hit, control is temporarily removed. This serves
# two purposes:
#   1. Communicates "you got hit" clearly -- the player sees their character
#      fly backward and can't override it with input
#   2. Creates a risk/reward moment -- the knockback might push you off a
#      ledge, adding stakes to getting hit beyond just losing health
#
# Knockback direction is calculated from the damage source position. The
# player always flies AWAY from whatever hurt them. If the source position
# is unknown (Vector2.ZERO), default to knocking left.
#
# Invincibility frames (i-frames) start immediately so the player can't
# take multiple hits from the same source during the stun. The flicker
# effect is handled by kitty.start_invincibility().
class_name HurtingState
extends State


const KNOCKBACK_X: float = 80.0
# negative = upward in Godot's coordinate system
const KNOCKBACK_Y: float = -150.0
# how long the player is stunned (no input accepted)
const DURATION: float = 0.4

var timer: float = 0.0


func enter() -> void:
	kitty.animated_sprite.play("hurting")
	# determine knockback direction from damage source
	var knockback_dir := 1.0
	if kitty.last_damage_source_pos != Vector2.ZERO:
		knockback_dir = sign(kitty.global_position.x - kitty.last_damage_source_pos.x)
	# fallback: if source is directly above/below, knock left
	if knockback_dir == 0.0:
		knockback_dir = -1.0
	kitty.velocity.x = knockback_dir * KNOCKBACK_X
	kitty.velocity.y = KNOCKBACK_Y
	# grant invincibility for the stun duration + recovery time
	kitty.start_invincibility(1.0)
	timer = 0.0


func exit() -> void:
	pass


# input is completely ignored during the stun
func handle_input(_event: InputEvent) -> State:
	return null


func process(delta: float) -> State:
	return null


func process_physics(delta: float) -> State:
	timer += delta
	# once the stun duration expires, return to normal gameplay.
	# check floor contact to pick the right state.
	if timer >= DURATION:
		if kitty.is_on_floor():
			return standing_state
		return falling_state
	return null
