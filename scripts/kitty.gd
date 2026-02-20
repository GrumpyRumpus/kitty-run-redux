class_name Kitty
extends CharacterBody2D

var move_speed: float = 100
var gravity: float = 980

signal game_over
signal health_changed(new_health: int)

const MAX_HEALTH: int = 3
var health: int = MAX_HEALTH
var is_invincible: bool = false
var can_double_jump: bool = true

@export_group("Nodes")
@export var animated_sprite: AnimatedSprite2D
@export var audio_stream_player: AudioStreamPlayer2D
@export var state_machine: StateMachine
@export var shoot_component: ShootComponent

@onready var standing_state: StandingState = %Standing
@onready var running_state: RunningState = %Running
@onready var jumping_state: JumpingState = %Jumping
@onready var falling_state: FallingState = %Falling
@onready var hurting_state: HurtingState = %Hurting
@onready var dead_state: DeadState = %Dead

var gravity_multiplier = 1


func _ready() -> void:
	state_machine.init(self)


func _physics_process(delta: float) -> void:
	var was_on_floor := is_on_floor()
	if not was_on_floor:
		velocity.y += gravity * delta * gravity_multiplier
	elif velocity.y > 0:
		velocity.y = 0
	state_machine._physics_process(delta)
	move_and_slide()
	if not was_on_floor and is_on_floor():
		velocity.x = 0
	_check_contact_damage()


func _process(delta: float) -> void:
	state_machine._process(delta)
	# shooting input
	var current := state_machine.current_state
	if current != hurting_state and current != dead_state:
		if Input.is_action_pressed("action"):
			var target := get_global_mouse_position()
			shoot_component.handle_shoot(global_position, target, true)


func _unhandled_input(event: InputEvent) -> void:
	state_machine._unhandled_input(event)


func update_velocity(_velocity: float, _acceleration: float) -> void:
	velocity.x = move_toward(velocity.x, _velocity, _acceleration)


func take_damage(amount: int) -> void:
	if is_invincible or health <= 0:
		return
	health -= amount
	health_changed.emit(health)
	if health <= 0:
		state_machine.change_state(dead_state)
	else:
		state_machine.change_state(hurting_state)


func start_invincibility(duration: float = 1.0) -> void:
	is_invincible = true
	var tween := create_tween()
	# flicker alpha for the duration
	var flicker_count := int(duration / 0.1)
	for i in flicker_count:
		tween.tween_property(animated_sprite, "modulate:a", 0.3, 0.05)
		tween.tween_property(animated_sprite, "modulate:a", 1.0, 0.05)
	tween.tween_callback(func():
		is_invincible = false
		animated_sprite.modulate.a = 1.0
	)


func _check_contact_damage() -> void:
	if is_invincible or health <= 0:
		return
	for i in get_slide_collision_count():
		var collision := get_slide_collision(i)
		var collider := collision.get_collider()
		if collider is Mob and not collider.is_dead:
			var normal := collision.get_normal()
			if normal.y < -0.5:
				collider.take_damage(collider.health)
				velocity.y = -350
				can_double_jump = true
				return
			take_damage(1)
			return


func die() -> void:
	game_over.emit()


func _on_world_boundary_fall_down() -> void:
	if health > 0:
		health = 0
		health_changed.emit(health)
	state_machine.change_state(dead_state)
