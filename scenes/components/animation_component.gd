class_name AnimationComponent
extends Node

@export_subgroup("Nodes")
@export var sprite: AnimatedSprite2D


func handle_move_animation(move_direction: float) -> void:
	sprite.play("running")

func handle_jump_animation(is_jumping: bool, is_falling: bool) -> void:
	if is_jumping:
		sprite.play("jumping")
	elif is_falling:
		sprite.play("falling")
