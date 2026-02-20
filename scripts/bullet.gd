class_name Bullet
extends Area2D

@export var speed: float = 250

var direction: Vector2
var is_friendly: bool = false


func aim(origin: Vector2, target: Vector2) -> void:
	direction = origin.direction_to(target)
	rotation = (target - origin).angle()


func _process(delta: float) -> void:
	translate(direction * speed * delta)


func _on_body_entered(body: Node2D) -> void:
	if body.name.begins_with("Ground"):
		queue_free()
		return
	if is_friendly and body is Mob:
		body.take_damage(1)
		queue_free()
		return
	if not is_friendly and body is Kitty:
		body.take_damage(1)
		queue_free()
		return


func _on_visible_on_screen_enabler_2d_screen_exited() -> void:
	queue_free()
