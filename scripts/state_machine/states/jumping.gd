class_name JumpingState
extends State

@export var jump_velocity: float = 350
@export_custom(PROPERTY_HINT_NONE, "suffix:px/s") var base_move_speed: float = 100
@export var acceleration: float = 8

var move_speed: float = 0


func _ready() -> void:
	pass


func init() -> void:
	pass


func enter() -> void:
	kitty.animated_sprite.play("jumping")
	var is_double_jump := not kitty.is_on_floor()
	kitty.audio_stream_player.pitch_scale = 1.4 if is_double_jump else 1.0
	kitty.audio_stream_player.play()
	kitty.velocity.y = -jump_velocity
	if is_double_jump:
		kitty._spawn_dust_puff()
	else:
		kitty.can_double_jump = true
	move_speed = maxf(base_move_speed, abs(kitty.velocity.x))


func exit() -> void:
	pass


func handle_input(event: InputEvent) -> State:
	if event.is_action_released("up"):
		kitty.velocity.y *= 0.3
		return falling_state
	return null


func process(delta: float) -> State:
	return null


func process_physics(delta: float) -> State:
	if kitty.velocity.y >= 0:
		return falling_state
	return null
