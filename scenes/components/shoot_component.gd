class_name ShootComponent
extends Node

@export_subgroup("Nodes")
@export var bullet_timer: Timer

@export_subgroup("Settings")
@export var bullet_time: float = 0.15
@export var is_friendly: bool = false

var bullet = load("res://scenes/bullet.tscn")


func _ready() -> void:
	bullet_timer.start()


func handle_shoot(initial: Vector2, target: Vector2, want_to_shoot: bool):
	if want_to_shoot and able_to_shoot():
		shoot(initial, target)


func able_to_shoot() -> bool:
	return bullet_timer.is_stopped()


func shoot(initial: Vector2, target: Vector2):
	bullet_timer.start()
	var instance = bullet.instantiate()
	instance.position = initial
	instance.is_friendly = is_friendly
	instance.aim(initial, target)
	get_tree().current_scene.add_child(instance)
