# Reusable shooting component (Component Pattern)
#
# This component encapsulates all bullet-spawning logic and is used by both
# the player (Kitty) and enemies (Mob). By putting it in a separate node
# instead of duplicating code, changes to bullet behavior apply everywhere.
#
# The fire rate is controlled by a Timer node. When the timer is running,
# able_to_shoot() returns false. After the timer expires (one-shot), the
# next shot is allowed. This is simpler than tracking cooldowns manually
# and integrates with Godot's node system.
#
# fire_rate_override allows powerups (like rapid fire) to temporarily
# change the fire rate without touching the base bullet_time value.
# When the override is 0.0, the default rate is used.
class_name ShootComponent
extends Node

@export_subgroup("Nodes")
@export var bullet_timer: Timer

@export_subgroup("Settings")
# default time between shots (seconds)
@export var bullet_time: float = 0.15
# false = enemy bullets (red tint, hit player)
# true = player bullets (normal tint, hit mobs)
@export var is_friendly: bool = false

const BULLET_SCENE: PackedScene = preload("res://scenes/bullet.tscn")
# when > 0, overrides bullet_time (used by rapid fire powerup)
var fire_rate_override: float = 0.0
# when true, spawned bullets are giant (used by giant bullet powerup)
var giant_mode: bool = false


func _ready() -> void:
	# start the timer so the first shot can fire immediately
	# (timer starts expired = is_stopped() returns true)
	bullet_timer.start()


# public API: try to shoot. returns true if a bullet was actually fired.
# the caller (kitty.gd or mob.gd) checks the return value to know
# whether to trigger side effects (camera punch, ammo decrement, etc.)
func handle_shoot(initial: Vector2, target: Vector2, want_to_shoot: bool) -> bool:
	if want_to_shoot and able_to_shoot():
		shoot(initial, target)
		return true
	return false


func able_to_shoot() -> bool:
	# timer running = still on cooldown
	return bullet_timer.is_stopped()


func shoot(initial: Vector2, target: Vector2) -> void:
	# set the timer for the next shot's cooldown
	bullet_timer.wait_time = fire_rate_override if fire_rate_override > 0.0 else bullet_time
	bullet_timer.start()
	# instantiate and configure the bullet
	var instance: Bullet = BULLET_SCENE.instantiate()
	instance.position = initial
	instance.is_friendly = is_friendly
	if is_friendly and giant_mode:
		instance.is_giant = true
	instance.aim(initial, target)
	# add to the scene root so bullets persist even if the shooter is freed
	get_tree().current_scene.add_child(instance)
