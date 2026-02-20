class_name MovementComponent
extends Node


@export_subgroup("Settings")
@export var speed: float = 125
@export var ground_accel: float = 6.0
@export var ground_decel: float = 8.0
@export var air_accel: float = 10.0
@export var air_decel: float = 3.0


func handle_horizontal_movement(body: CharacterBody2D, direction: float) -> void:
	var accleration: float = 0.0
	if body.is_on_floor():
		accleration = ground_accel if direction != 0 else ground_decel
	else:
		accleration = air_accel if direction != 0 else air_decel

	body.velocity.x = move_toward(body.velocity.x, direction * speed, accleration)
