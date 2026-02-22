class_name Mob
extends AnimatableBody2D

signal mob_killed(pos: Vector2)
signal mob_hit

const DEATH_PARTICLES := preload("res://scenes/death_particles.tscn")
const FLASH_SHADER := preload("res://shaders/flash.gdshader")
const PICKUP_SCENE := preload("res://scenes/pickup.tscn")

@export var flap_path_left: PathFollow2D
@export var flap_path_right: PathFollow2D
@export var swoop_path: PathFollow2D
@export var spiral_path: PathFollow2D
@export var shoot_component: ShootComponent
@export var target: CharacterBody2D
@export var sprite: AnimatedSprite2D

enum States {FLAP, SWOOP, SPIRAL, SHOOT}

var state: States = States.FLAP
var health: int = 3
var is_dead: bool = false


func _ready() -> void:
	sprite.material = ShaderMaterial.new()
	sprite.material.shader = FLASH_SHADER


func _physics_process(delta: float) -> void:
	if is_dead or not is_instance_valid(target):
		return
	match state:
		States.FLAP:
			var flap_path: PathFollow2D
			if global_position.x > get_viewport_rect().size.x / 2:
				flap_path = flap_path_left
			else:
				flap_path = flap_path_right
			if follow_path(delta, flap_path) == 1:
				state = [States.SWOOP, States.SPIRAL].pick_random()
		States.SWOOP:
			if follow_path(delta, swoop_path) > 0.99:
				state = [States.SPIRAL, States.SHOOT].pick_random()
		States.SPIRAL:
			if follow_path(delta, spiral_path) > 0.99:
				state = [States.SWOOP, States.SHOOT].pick_random()
		States.SHOOT:
			if shoot_component.bullet_timer.is_stopped():
				state = [States.SWOOP, States.SPIRAL].pick_random()
			shoot_component.handle_shoot(global_position, target.global_position, true)


func _process(delta: float) -> void:
	if is_dead:
		return
	# off-screen cleanup
	var vp := get_viewport_rect()
	if position.x < -200 or position.x > vp.size.x + 200 \
		or position.y < -200 or position.y > vp.size.y + 200:
		queue_free()
		return
	match state:
		States.FLAP | States.SWOOP | States.SPIRAL:
			sprite.play("flap")
		States.SHOOT:
			sprite.play("shoot")


func take_damage(amount: int) -> void:
	if is_dead or health <= 0:
		return
	health -= amount
	if health <= 0:
		_die()
	else:
		mob_hit.emit()
		sprite.play("hurt")
		sprite.material.set_shader_parameter("flash_amount", 1.0)
		var tween := create_tween()
		tween.tween_property(sprite.material, "shader_parameter/flash_amount", 0.0, 0.12)
		await tween.finished
		if not is_dead:
			sprite.play("flap")


func _die() -> void:
	is_dead = true
	mob_killed.emit(global_position)
	_try_spawn_pickup()
	# spawn death particles
	var particles := DEATH_PARTICLES.instantiate()
	particles.global_position = global_position
	var level := get_tree().current_scene.get_node_or_null("World/Level")
	if level:
		level.add_child(particles)
	else:
		particles.queue_free()
		return
	particles.emitting = true
	# auto-free particles after lifetime
	get_tree().create_timer(particles.lifetime + 0.1).timeout.connect(particles.queue_free)
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.3)
	await tween.finished
	queue_free()


func _try_spawn_pickup() -> void:
	if randf() >= 0.2:
		return
	var pool: Array[Pickup.Type] = [
		Pickup.Type.HEALTH,
		Pickup.Type.SHIELD,
		Pickup.Type.GIANT_BULLET,
		Pickup.Type.RAPID_FIRE,
		Pickup.Type.EXTRA_JUMP,
	]
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


func follow_path(delta: float, path: PathFollow2D, speed: int = 50) -> float:
	var previous_position = path.position
	path.progress += speed * delta
	var current_position = path.position
	self.position += current_position - previous_position
	return path.progress_ratio
