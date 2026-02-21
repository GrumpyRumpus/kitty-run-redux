class_name Bullet
extends Area2D

const IMPACT := preload("res://scenes/bullet_impact.tscn")

@export var speed: float = 250

var direction: Vector2
var is_friendly: bool = false


func aim(origin: Vector2, target: Vector2) -> void:
	direction = origin.direction_to(target)
	rotation = (target - origin).angle()
	if not is_friendly:
		modulate = Color(1.0, 0.3, 0.3)


func _process(delta: float) -> void:
	translate(direction * speed * delta)


func _spawn_impact() -> void:
	var fx := IMPACT.instantiate()
	fx.global_position = global_position
	fx.emitting = true
	var level := get_tree().current_scene.get_node_or_null("World/Level")
	if level:
		level.add_child(fx)
		get_tree().create_timer(fx.lifetime + 0.1).timeout.connect(fx.queue_free)
	else:
		fx.queue_free()


func _on_body_entered(body: Node2D) -> void:
	if body is Grounds:
		_spawn_impact()
		queue_free()
		return
	if is_friendly and body is Mob:
		body.take_damage(1)
		_spawn_impact()
		queue_free()
		return
	if not is_friendly and body is Kitty:
		body.take_damage(1, global_position)
		_spawn_impact()
		queue_free()
		return


func _on_visible_on_screen_enabler_2d_screen_exited() -> void:
	queue_free()
