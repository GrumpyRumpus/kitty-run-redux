# Player character controller
#
# This is the central player script. It uses a CharacterBody2D (Godot's
# built-in physics body for characters) and delegates movement logic to a
# state machine. The character itself handles:
#   - gravity and floor detection
#   - shooting input (separate from movement)
#   - damage, health, invincibility frames
#   - powerup collection and tracking
#   - contact damage (stomping enemies vs getting hurt)
#
# Architecture note: the state machine handles MOVEMENT states (standing,
# running, jumping, etc.) but shooting happens independently in _process().
# This avoids duplicating shoot logic across every movement state.
#
# Signals are used to communicate with the game controller (game.gd) and
# HUD without creating tight coupling. The player doesn't need to know
# about the score system or UI -- it just emits events and lets listeners
# decide what to do with them.
class_name Kitty
extends CharacterBody2D

var move_speed: float = 100
# standard gravity for a platformer -- tuned to feel good with the jump velocity
var gravity: float = 980

# ============================================================
# SIGNALS
# ============================================================
# these decouple the player from game systems. the game controller
# connects to these in _ready() and routes them to the HUD, combo
# system, screen shake, etc.
signal game_over
signal health_changed(new_health: int)
# emitted on successful enemy stomp (triggers hitstop + screen shake)
signal stomped
# emitted when any powerup state changes (HUD updates the display)
signal powerup_changed
# emitted when a bullet is fired (triggers camera punch in game.gd)
signal shot_fired(direction: Vector2)

# ============================================================
# CONSTANTS
# ============================================================
const MAX_HEALTH: int = 3
const DUST_PUFF := preload("res://scenes/dust_puff.tscn")
# how high the player bounces after stomping an enemy
const STOMP_BOUNCE_VELOCITY := -350.0
# distance from player to target point for aim direction
const SHOOT_TARGET_DISTANCE := 100.0
# powerup values -- centralized here so balance changes are easy to find
const RAPID_FIRE_DURATION := 8.0
const RAPID_FIRE_RATE := 0.075
const GIANT_BULLET_COUNT := 25
const EXTRA_JUMP_COUNT := 3
const SHIELD_INVULN_DURATION := 0.5
# how often the sprite flickers during invincibility (smaller = faster flicker)
const INVULN_FLICKER_INTERVAL := 0.1

# ============================================================
# STATE
# ============================================================
var health: int = MAX_HEALTH
var is_invincible: bool = false
var can_double_jump: bool = true
# where the last hit came from (used by hurting state for knockback direction)
var last_damage_source_pos: Vector2 = Vector2.ZERO

# -------------------- Powerup State --------------------
# each powerup type uses a different tracking method:
# shield: boolean (one-hit protection, consumed on damage)
# giant bullets: counter (decrements per shot until depleted)
# rapid fire: timer (counts down in real time)
# extra jumps: counter (decrements per air jump)
var has_shield: bool = false
var giant_bullets: int = 0
var rapid_fire_time: float = 0.0
var extra_jumps: int = 0

# -------------------- Node References --------------------
@export_group("Nodes")
@export var animated_sprite: AnimatedSprite2D
@export var audio_stream_player: AudioStreamPlayer2D
@export var state_machine: StateMachine
@export var shoot_component: ShootComponent

# these use unique names (%) for direct access to specific states.
# the player needs these to force transitions on damage/death.
@onready var hurting_state: HurtingState = %Hurting
@onready var dead_state: DeadState = %Dead

# gravity_multiplier is set by the falling state for asymmetric jump arcs
var gravity_multiplier: float = 1.0
# last known aim direction (persists when aim keys are released)
var aim_direction: Vector2 = Vector2.RIGHT
# cached mouse position in viewport coords (updated in _input)
var _mouse_viewport: Vector2 = Vector2.ZERO


# ============================================================
# LIFECYCLE
# ============================================================

func _ready() -> void:
	# draw player above other sprites
	z_index = 1
	# floor_constant_speed prevents speed changes on slopes
	floor_constant_speed = true
	# floor_snap_length keeps the character glued to slopes when walking down
	floor_snap_length = 4.0
	state_machine.init(self)


func _physics_process(delta: float) -> void:
	var was_on_floor := is_on_floor()
	# apply gravity only when airborne
	if not was_on_floor:
		velocity.y += gravity * delta * gravity_multiplier
	elif velocity.y > 0:
		# clamp downward velocity to zero on floor (prevents accumulation)
		velocity.y = 0
	# delegate movement to the current state (standing, running, etc.)
	state_machine._physics_process(delta)
	# move_and_slide applies velocity and handles collisions
	move_and_slide()
	# -------------------- Landing Effects --------------------
	# detect the exact frame of landing (was airborne, now grounded)
	if not was_on_floor and is_on_floor():
		velocity.x = 0
		# squash-and-stretch: widen + shorten on impact, then tween back.
		# this is a classic animation principle that adds weight and impact.
		animated_sprite.scale = Vector2(1.2, 0.85)
		var land_tween := create_tween()
		land_tween.tween_property(animated_sprite, "scale", Vector2(1.0, 1.0), 0.1)
		_spawn_dust_puff()
	_check_contact_damage()


# ============================================================
# AIMING
# ============================================================
# the game supports both mouse and keyboard aiming simultaneously.
# mouse: aim toward cursor position (via "action" input / mouse click)
# keyboard: 8-direction aiming using dedicated aim keys (IJKL + UO)
# the last-used aim direction persists so "shoot" fires in a remembered direction.

func _input(event: InputEvent) -> void:
	# cache mouse viewport position -- used by _get_world_mouse_position()
	if event is InputEventMouse:
		_mouse_viewport = event.position


func _get_world_mouse_position() -> Vector2:
	# convert viewport coords to world coords (accounts for camera transform)
	return get_canvas_transform().affine_inverse() * _mouse_viewport


func _get_keyboard_aim() -> Vector2:
	# build aim vector from all pressed aim keys (supports diagonals)
	var aim := Vector2.ZERO
	if Input.is_action_pressed("aim_left"):
		aim += Vector2.LEFT
	if Input.is_action_pressed("aim_right"):
		aim += Vector2.RIGHT
	if Input.is_action_pressed("aim_up"):
		aim += Vector2.UP
	if Input.is_action_pressed("aim_down"):
		aim += Vector2.DOWN
	if Input.is_action_pressed("aim_up_left"):
		aim += Vector2(-1, -1)
	if Input.is_action_pressed("aim_up_right"):
		aim += Vector2(1, -1)
	return aim.normalized() if aim != Vector2.ZERO else Vector2.ZERO


# ============================================================
# SHOOTING
# ============================================================
# shooting runs in _process (every visual frame) independent of the state
# machine. this way the player can shoot while standing, running, jumping,
# or falling without duplicating code in each state.

func _process(delta: float) -> void:
	state_machine._process(delta)
	# tick down rapid fire powerup timer
	if rapid_fire_time > 0.0:
		rapid_fire_time -= delta
		if rapid_fire_time <= 0.0:
			rapid_fire_time = 0.0
			shoot_component.fire_rate_override = 0.0
			powerup_changed.emit()
	# don't allow shooting during hurt/dead states
	var current := state_machine.current_state
	if current != hurting_state and current != dead_state:
		var shoot_dir := Vector2.ZERO
		# mouse aim: click to shoot toward cursor
		if Input.is_action_pressed("action"):
			shoot_dir = global_position.direction_to(_get_world_mouse_position())
		else:
			# keyboard aim: dedicated aim keys set direction
			var kb_aim := _get_keyboard_aim()
			if kb_aim != Vector2.ZERO:
				aim_direction = kb_aim
				shoot_dir = kb_aim
			# shoot key without aim keys: fire in last known direction
			elif Input.is_action_pressed("shoot"):
				shoot_dir = aim_direction
		if shoot_dir != Vector2.ZERO:
			var target := global_position + shoot_dir * SHOOT_TARGET_DISTANCE
			if shoot_component.handle_shoot(global_position, target, true):
				# notify game.gd for camera punch effect
				shot_fired.emit(shoot_dir)
				# decrement giant bullet counter
				if giant_bullets > 0:
					giant_bullets -= 1
					if giant_bullets == 0:
						shoot_component.giant_mode = false
					powerup_changed.emit()


func _unhandled_input(event: InputEvent) -> void:
	state_machine._unhandled_input(event)


# ============================================================
# MOVEMENT HELPER
# ============================================================

# called by states to smoothly approach a target horizontal speed.
# move_toward is like lerp but moves by a fixed step, giving consistent
# acceleration regardless of current speed.
func update_velocity(target_velocity: float, accel: float) -> void:
	velocity.x = move_toward(velocity.x, target_velocity, accel)


# ============================================================
# DAMAGE AND HEALTH
# ============================================================

func take_damage(amount: int, source_pos: Vector2 = Vector2.ZERO) -> void:
	# can't take damage while invincible or already dead
	if is_invincible or health <= 0:
		return
	# shield absorbs one hit with visual feedback instead of health loss
	if has_shield:
		has_shield = false
		powerup_changed.emit()
		# flash blue to show the shield absorbed the hit
		animated_sprite.modulate = Color("#89b4fa")
		var flash_tween := create_tween()
		flash_tween.tween_property(animated_sprite, "modulate", Color.WHITE, 0.2)
		start_invincibility(SHIELD_INVULN_DURATION)
		return
	# record where the hit came from (hurting state uses this for knockback)
	last_damage_source_pos = source_pos
	health -= amount
	health_changed.emit(health)
	if health <= 0:
		state_machine.change_state(dead_state)
	else:
		state_machine.change_state(hurting_state)


# invincibility frames (i-frames): a period after taking damage where
# the player can't be hurt again. the flickering sprite communicates
# this state visually. uses a tween chain: alternate between transparent
# and opaque for the duration, then restore full visibility.
func start_invincibility(duration: float = 1.0) -> void:
	is_invincible = true
	var tween := create_tween()
	var flicker_count := int(duration / INVULN_FLICKER_INTERVAL)
	for i in flicker_count:
		tween.tween_property(animated_sprite, "modulate:a", 0.3, 0.05)
		tween.tween_property(animated_sprite, "modulate:a", 1.0, 0.05)
	tween.tween_callback(func():
		is_invincible = false
		animated_sprite.modulate.a = 1.0
	)


# ============================================================
# CONTACT DAMAGE (STOMPING)
# ============================================================
# after move_and_slide(), check all collisions from this frame.
# if we landed on top of an enemy (normal pointing up), it's a stomp.
# if we hit them from the side or below, we take damage.
#
# the normal.y < -0.5 check means the surface is mostly facing upward
# (floor-like). this gives a generous stomp detection angle.

func _check_contact_damage() -> void:
	if is_invincible or health <= 0:
		return
	for i in get_slide_collision_count():
		var collision := get_slide_collision(i)
		var collider := collision.get_collider()
		if collider is Mob and not collider.is_dead:
			var normal := collision.get_normal()
			# stomp: landing on top of the enemy
			if normal.y < -0.5:
				# one-hit kill via full health damage
				collider.take_damage(collider.health)
				# bounce upward (like Mario)
				velocity.y = STOMP_BOUNCE_VELOCITY
				# reset double jump so the player can chain stomps
				can_double_jump = true
				# reuse the jump sound at a lower pitch for a satisfying "thunk"
				audio_stream_player.pitch_scale = 0.6
				audio_stream_player.play()
				# squash-stretch sequence: flatten on impact, stretch tall, settle.
				# two-step tween: squash -> overshoot stretch -> return to normal
				animated_sprite.scale = Vector2(1.4, 0.6)
				var sq_tween := create_tween()
				sq_tween.tween_property(animated_sprite, "scale", Vector2(0.8, 1.3), 0.08)
				sq_tween.tween_property(animated_sprite, "scale", Vector2(1.0, 1.0), 0.08)
				stomped.emit()
				return
			# side/bottom hit: take damage
			take_damage(1, collider.global_position)
			return


func die() -> void:
	game_over.emit()


# ============================================================
# POWERUPS
# ============================================================
# each powerup type has different mechanics but they all emit
# powerup_changed so the HUD stays in sync.

func collect_powerup(type: Pickup.Type) -> void:
	match type:
		Pickup.Type.HEALTH:
			health = MAX_HEALTH
			health_changed.emit(health)
		Pickup.Type.SHIELD:
			has_shield = true
		Pickup.Type.GIANT_BULLET:
			giant_bullets = GIANT_BULLET_COUNT
			shoot_component.giant_mode = true
		Pickup.Type.RAPID_FIRE:
			rapid_fire_time = RAPID_FIRE_DURATION
			shoot_component.fire_rate_override = RAPID_FIRE_RATE
		Pickup.Type.EXTRA_JUMP:
			extra_jumps = EXTRA_JUMP_COUNT
	powerup_changed.emit()


func _spawn_dust_puff() -> void:
	# offset slightly below the character's feet
	FX.spawn_particles(DUST_PUFF, global_position + Vector2(0, 8), get_tree())


# connected via the editor to the WorldBoundary's fall_down signal
func _on_world_boundary_fall_down() -> void:
	if health > 0:
		health = 0
		health_changed.emit(health)
	state_machine.change_state(dead_state)
