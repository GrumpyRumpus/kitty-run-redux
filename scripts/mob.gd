# Enemy mob -- a flying creature with simple AI
#
# The mob uses a lightweight state enum (not a full state machine) because
# its behaviors are simpler than the player's. Each state follows a
# pre-authored Path2D and transitions to a random next state when done.
#
# Movement uses PathFollow2D nodes placed in the mob scene. Each path
# defines a flight pattern (figure-8, dive, spiral). The follow_path()
# helper advances the PathFollow2D and applies the delta to this node's
# position, effectively making the mob follow the curve.
#
# Hit feedback uses a shader that flashes the sprite white. This is a
# common technique: a "flash" shader with a uniform (0.0-1.0) that
# controls how much to override the sprite color with pure white.
# Tweening the parameter from 1.0 to 0.0 creates the flash effect.
#
# On death, the mob emits mob_killed (for score) and has a chance to
# spawn a powerup pickup. The drop pool is filtered based on the player's
# current state (no health drops if already full, no shield if already
# shielded) to avoid wasted drops.
class_name Mob
extends AnimatableBody2D

# ============================================================
# SIGNALS
# ============================================================
# mob_killed is connected by the spawner to game.add_kill_score()
signal mob_killed(pos: Vector2)
# mob_hit is connected by the spawner to game.extend_combo()
signal mob_hit

# ============================================================
# CONSTANTS
# ============================================================
const DEATH_PARTICLES := preload("res://scenes/death_particles.tscn")
const FLASH_SHADER := preload("res://scripts/shaders/flash.gdshader")
const PICKUP_SCENE := preload("res://scenes/pickup.tscn")
# 20% chance to drop a powerup on death
const PICKUP_DROP_CHANCE := 0.2
const DEFAULT_HEALTH := 3
# how long the white flash lasts when hit (but not killed)
const HIT_FLASH_DURATION := 0.12
# how long the fade-out takes on death
const DEATH_FADE_DURATION := 0.3
# how far offscreen a mob can drift before being cleaned up
const OFFSCREEN_MARGIN := 200

# ============================================================
# NODE REFERENCES
# ============================================================
# each path defines a flight pattern. the mob picks one based on
# its current state and screen position.
@export var flap_path_left: PathFollow2D
@export var flap_path_right: PathFollow2D
@export var swoop_path: PathFollow2D
@export var spiral_path: PathFollow2D
# reusable shoot component (same class the player uses)
@export var shoot_component: ShootComponent
# reference to the player (set by mob_spawner on instantiation)
@export var target: CharacterBody2D
@export var sprite: AnimatedSprite2D

# ============================================================
# STATE
# ============================================================
# simple enum-based AI. each state maps to a flight pattern + behavior.
enum States {FLAP, SWOOP, SPIRAL, SHOOT}

var state: States = States.FLAP
var health: int = DEFAULT_HEALTH
var is_dead: bool = false


func _ready() -> void:
	# create a unique shader material instance for this mob.
	# without .new(), all mobs would share the same material and
	# flashing one would flash them all.
	sprite.material = ShaderMaterial.new()
	sprite.material.shader = FLASH_SHADER


# ============================================================
# AI BEHAVIOR
# ============================================================

func _physics_process(delta: float) -> void:
	if is_dead or not is_instance_valid(target):
		return
	match state:
		States.FLAP:
			# pick path based on which side of the screen we're on.
			# this makes the mob curve toward the center.
			var flap_path: PathFollow2D
			if global_position.x > get_viewport_rect().size.x / 2:
				flap_path = flap_path_left
			else:
				flap_path = flap_path_right
			# when path completes (ratio reaches 1), pick a new behavior
			if follow_path(delta, flap_path) == 1:
				state = [States.SWOOP, States.SPIRAL].pick_random()
		States.SWOOP:
			if follow_path(delta, swoop_path) > 0.99:
				state = [States.SPIRAL, States.SHOOT].pick_random()
		States.SPIRAL:
			if follow_path(delta, spiral_path) > 0.99:
				state = [States.SWOOP, States.SHOOT].pick_random()
		States.SHOOT:
			# shoot until the bullet timer allows the next shot,
			# then return to a movement state
			if shoot_component.bullet_timer.is_stopped():
				state = [States.SWOOP, States.SPIRAL].pick_random()
			shoot_component.handle_shoot(global_position, target.global_position, true)


func _process(delta: float) -> void:
	if is_dead:
		return
	# clean up mobs that drift too far offscreen (prevents memory leaks)
	var vp := get_viewport_rect()
	if position.x < -OFFSCREEN_MARGIN or position.x > vp.size.x + OFFSCREEN_MARGIN \
		or position.y < -OFFSCREEN_MARGIN or position.y > vp.size.y + OFFSCREEN_MARGIN:
		queue_free()
		return
	# pick animation based on current behavior
	match state:
		States.FLAP | States.SWOOP | States.SPIRAL:
			sprite.play("flap")
		States.SHOOT:
			sprite.play("shoot")


# ============================================================
# DAMAGE AND DEATH
# ============================================================

func take_damage(amount: int) -> void:
	if is_dead or health <= 0:
		return
	health -= amount
	if health <= 0:
		_die()
	else:
		# non-lethal hit: emit for combo extension + flash feedback
		mob_hit.emit()
		sprite.play("hurt")
		# set flash to full white, then tween it back to normal.
		# the shader interpolates between the sprite texture and white
		# based on flash_amount (1.0 = fully white, 0.0 = normal).
		sprite.material.set_shader_parameter("flash_amount", 1.0)
		var tween := create_tween()
		tween.tween_property(sprite.material, "shader_parameter/flash_amount", 0.0, HIT_FLASH_DURATION)
		await tween.finished
		if not is_dead:
			sprite.play("flap")


func _die() -> void:
	is_dead = true
	# emit position for score popup placement
	mob_killed.emit(global_position)
	_try_spawn_pickup()
	# spawn death particles at the mob's position
	FX.spawn_particles(DEATH_PARTICLES, global_position, get_tree())
	# fade out the mob sprite, then remove from tree
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, DEATH_FADE_DURATION)
	await tween.finished
	queue_free()


# ============================================================
# PICKUP DROPS
# ============================================================
# smart loot: the drop pool is filtered based on what the player
# already has, so you don't get a shield when you already have one
# or health when you're already full. this makes every drop feel useful.

func _try_spawn_pickup() -> void:
	# 80% chance to drop nothing
	if randf() >= PICKUP_DROP_CHANCE:
		return
	var pool: Array[Pickup.Type] = [
		Pickup.Type.HEALTH,
		Pickup.Type.SHIELD,
		Pickup.Type.GIANT_BULLET,
		Pickup.Type.RAPID_FIRE,
		Pickup.Type.EXTRA_JUMP,
	]
	# remove redundant pickups from the pool
	if is_instance_valid(target) and target is Kitty:
		if target.has_shield:
			pool.erase(Pickup.Type.SHIELD)
		if target.health >= Kitty.MAX_HEALTH:
			pool.erase(Pickup.Type.HEALTH)
	var pickup := PICKUP_SCENE.instantiate()
	pickup.type = pool.pick_random()
	pickup.global_position = global_position
	var level := get_tree().current_scene.get_node_or_null("World/Level")
	if level:
		level.add_child(pickup)
	else:
		pickup.queue_free()


# ============================================================
# PATH FOLLOWING
# ============================================================
# PathFollow2D nodes advance along a Path2D curve. we calculate the
# position delta each frame and apply it to the mob. this creates
# smooth curved movement without manual math.
#
# the progress_ratio (0.0 to 1.0) tells us how far along the path
# we are, which states use to detect "path complete" and transition.

func follow_path(delta: float, path: PathFollow2D, speed: int = 50) -> float:
	var previous_position = path.position
	path.progress += speed * delta
	var current_position = path.position
	self.position += current_position - previous_position
	return path.progress_ratio
