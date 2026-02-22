class_name ShootComponent
extends Node

@export_subgroup("Nodes")
@export var bullet_timer: Timer

@export_subgroup("Settings")
@export var bullet_time: float = 0.15
@export var is_friendly: bool = false

const BULLET_SCENE: PackedScene = preload("res://scenes/bullet.tscn")
var fire_rate_override: float = 0.0
var giant_mode: bool = false


func _ready() -> void:
	bullet_timer.start()


func handle_shoot(initial: Vector2, target: Vector2, want_to_shoot: bool) -> bool:
	if want_to_shoot and able_to_shoot():
		shoot(initial, target)
		return true
	return false


func able_to_shoot() -> bool:
	return bullet_timer.is_stopped()


func shoot(initial: Vector2, target: Vector2) -> void:
	bullet_timer.wait_time = fire_rate_override if fire_rate_override > 0.0 else bullet_time
	bullet_timer.start()
	var instance: Bullet = BULLET_SCENE.instantiate()
	instance.position = initial
	instance.is_friendly = is_friendly
	if is_friendly and giant_mode:
		instance.is_giant = true
	instance.aim(initial, target)
	get_tree().current_scene.add_child(instance)
