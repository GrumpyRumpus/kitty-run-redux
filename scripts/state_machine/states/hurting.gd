class_name HurtingState
extends State


const KNOCKBACK_X: float = 80.0
const KNOCKBACK_Y: float = -150.0
const DURATION: float = 0.4

var timer: float = 0.0


func enter() -> void:
	kitty.animated_sprite.play("hurting")
	var knockback_dir := -1.0 if kitty.velocity.x >= 0 else 1.0
	kitty.velocity.x = knockback_dir * KNOCKBACK_X
	kitty.velocity.y = KNOCKBACK_Y
	kitty.start_invincibility(1.0)
	timer = 0.0


func exit() -> void:
	pass


func handle_input(_event: InputEvent) -> State:
	return null


func process(delta: float) -> State:
	return null


func process_physics(delta: float) -> State:
	timer += delta
	if timer >= DURATION:
		if kitty.is_on_floor():
			return standing_state
		return falling_state
	return null
