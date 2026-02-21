class_name Kitty
extends CharacterBody2D

var move_speed: float = 100
var gravity: float = 980

signal game_over
signal health_changed(new_health: int)
signal stomped

const MAX_HEALTH: int = 3
const DUST_PUFF := preload("res://scenes/dust_puff.tscn")

var health: int = MAX_HEALTH
var is_invincible: bool = false
var can_double_jump: bool = true
var last_damage_source_pos: Vector2 = Vector2.ZERO

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
var _mouse_viewport: Vector2 = Vector2.ZERO


func _ready() -> void:
	z_index = 1
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
		# landing squash
		animated_sprite.scale = Vector2(1.2, 0.85)
		var land_tween := create_tween()
		land_tween.tween_property(animated_sprite, "scale", Vector2(1.0, 1.0), 0.1)
		_spawn_dust_puff()
	_check_contact_damage()


func _input(event: InputEvent) -> void:
	if event is InputEventMouse:
		_mouse_viewport = event.position


func _get_world_mouse_position() -> Vector2:
	return get_canvas_transform().affine_inverse() * _mouse_viewport


func _get_keyboard_aim() -> Vector2:
	var aim := Vector2.ZERO
	if Input.is_physical_key_pressed(KEY_J):
		aim += Vector2.LEFT
	if Input.is_physical_key_pressed(KEY_L):
		aim += Vector2.RIGHT
	if Input.is_physical_key_pressed(KEY_I):
		aim += Vector2.UP
	if Input.is_physical_key_pressed(KEY_K):
		aim += Vector2.DOWN
	if Input.is_physical_key_pressed(KEY_U):
		aim += Vector2(-1, -1)
	if Input.is_physical_key_pressed(KEY_O):
		aim += Vector2(1, -1)
	return aim.normalized() if aim != Vector2.ZERO else Vector2.ZERO


func _process(delta: float) -> void:
	state_machine._process(delta)
	# shooting input
	var current := state_machine.current_state
	if current != hurting_state and current != dead_state:
		var shoot_dir := Vector2.ZERO
		if Input.is_action_pressed("action"):
			shoot_dir = global_position.direction_to(_get_world_mouse_position())
		else:
			shoot_dir = _get_keyboard_aim()
		if shoot_dir != Vector2.ZERO:
			var target := global_position + shoot_dir * 100.0
			shoot_component.handle_shoot(global_position, target, true)


func _unhandled_input(event: InputEvent) -> void:
	state_machine._unhandled_input(event)


func update_velocity(_velocity: float, _acceleration: float) -> void:
	velocity.x = move_toward(velocity.x, _velocity, _acceleration)


func take_damage(amount: int, source_pos: Vector2 = Vector2.ZERO) -> void:
	if is_invincible or health <= 0:
		return
	last_damage_source_pos = source_pos
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
				# stomp sound (reuse jump sfx at low pitch)
				audio_stream_player.pitch_scale = 0.6
				audio_stream_player.play()
				# squash-stretch
				animated_sprite.scale = Vector2(1.4, 0.6)
				var sq_tween := create_tween()
				sq_tween.tween_property(animated_sprite, "scale", Vector2(0.8, 1.3), 0.08)
				sq_tween.tween_property(animated_sprite, "scale", Vector2(1.0, 1.0), 0.08)
				stomped.emit()
				return
			take_damage(1, collider.global_position)
			return


func die() -> void:
	game_over.emit()


func _spawn_dust_puff() -> void:
	var puff := DUST_PUFF.instantiate()
	puff.global_position = global_position + Vector2(0, 8)
	puff.emitting = true
	get_parent().add_child(puff)
	get_tree().create_timer(puff.lifetime + 0.1).timeout.connect(puff.queue_free)


func _on_world_boundary_fall_down() -> void:
	if health > 0:
		health = 0
		health_changed.emit(health)
	state_machine.change_state(dead_state)
