class_name StandingState
extends State


@export var deceleration: float = 8


func _ready() -> void:
	pass


func init() -> void:
	pass


func enter() -> void:
	kitty.animated_sprite.play("running")


func exit() -> void:
	pass

func handle_input(event: InputEvent) -> State:
	if event.is_action_pressed("up"):
		return jumping_state
	return null


func process(delta: float) -> State:
	if direction.x != 0:
		return running_state
	return null


func process_physics(delta: float) -> State:
	kitty.update_velocity(0, deceleration)
	if not kitty.is_on_floor():
		return falling_state
	return null
