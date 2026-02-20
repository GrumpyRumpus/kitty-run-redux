class_name DeadState
extends State


var original_collision_layer: int
var original_collision_mask: int
var has_died: bool = false


func enter() -> void:
	has_died = false
	kitty.animated_sprite.play("hurting")
	kitty.velocity.y = -200
	kitty.velocity.x = 0
	original_collision_layer = kitty.collision_layer
	original_collision_mask = kitty.collision_mask
	kitty.collision_layer = 0
	kitty.collision_mask = 0


func exit() -> void:
	kitty.collision_layer = original_collision_layer
	kitty.collision_mask = original_collision_mask


func handle_input(_event: InputEvent) -> State:
	return null


func process(_delta: float) -> State:
	return null


func process_physics(_delta: float) -> State:
	if not has_died and kitty.global_position.y > 300:
		has_died = true
		kitty.die()
	return null
