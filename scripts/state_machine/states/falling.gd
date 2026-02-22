class_name FallingState
extends State

@export var fall_gravity_multiplier: float = 1.165
@export_custom(PROPERTY_HINT_NONE, "suffix:px/s") var base_move_speed: float = 100
@export var acceleration: float = 8
@export var coyote_time: float = 0.125
@export var coyote_timer: Timer

var move_speed: float


func _ready() -> void:
	pass


func init() -> void:
	coyote_timer.wait_time = coyote_time
	coyote_timer.one_shot = true


func enter() -> void:
	kitty.animated_sprite.play("falling")
	move_speed = maxf(base_move_speed, abs(kitty.velocity.x))
	kitty.gravity_multiplier = fall_gravity_multiplier
	
	if state_machine.previous_state != jumping_state:
		coyote_timer.start()


func exit() -> void:
	kitty.gravity_multiplier = 1.0


func handle_input(event: InputEvent) -> State:
	if event.is_action_pressed("up"):
		if not coyote_timer.is_stopped():
			return jumping_state
		if kitty.can_double_jump:
			kitty.can_double_jump = false
			return jumping_state
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
		return standing_state
	return null
