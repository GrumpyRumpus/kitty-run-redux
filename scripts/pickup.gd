class_name Pickup
extends Area2D

enum Type { HEALTH, SHIELD, GIANT_BULLET, RAPID_FIRE, EXTRA_JUMP }

const COLORS := {
	Type.HEALTH: Color("#f38ba8"),
	Type.SHIELD: Color("#89b4fa"),
	Type.GIANT_BULLET: Color("#fab387"),
	Type.RAPID_FIRE: Color("#f9e2af"),
	Type.EXTRA_JUMP: Color("#a6e3a1"),
}

const GRAVITY := 400.0
const DESPAWN_TIME := 6.0
const BLINK_START := 4.0
const HOVER_HEIGHT := 12.0

var type: Type = Type.HEALTH
var velocity_y: float = -60.0
var on_ground: bool = false

@onready var color_rect: ColorRect = $ColorRect


func _ready() -> void:
	color_rect.color = COLORS[type]
	# bob tween
	var bob := create_tween().set_loops()
	bob.tween_property(color_rect, "position:y", -2.0, 0.4).set_trans(Tween.TRANS_SINE)
	bob.tween_property(color_rect, "position:y", 2.0, 0.4).set_trans(Tween.TRANS_SINE)
	# blink warning before despawn
	get_tree().create_timer(BLINK_START).timeout.connect(_start_blink)
	# auto despawn
	get_tree().create_timer(DESPAWN_TIME).timeout.connect(queue_free)


func _physics_process(delta: float) -> void:
	# scroll with ground
	var level := get_parent()
	if level and "grounds" in level:
		position.x -= 2 * level.grounds.speed * delta
	# fall off left edge -- cleanup
	if position.x < -32:
		queue_free()
		return
	if on_ground:
		return
	velocity_y += GRAVITY * delta
	var move_y := velocity_y * delta
	# raycast downward to detect ground surface
	var space := get_world_2d().direct_space_state
	if space:
		var from := global_position
		var to := Vector2(global_position.x, global_position.y + move_y + 4.0)
		var query := PhysicsRayQueryParameters2D.create(from, to)
		var result := space.intersect_ray(query)
		if result and result.collider is Grounds:
			global_position.y = result.position.y - HOVER_HEIGHT
			velocity_y = 0.0
			on_ground = true
			return
	position.y += move_y
	# fell off bottom -- cleanup
	if position.y > 300:
		queue_free()


func _start_blink() -> void:
	var blink := create_tween().set_loops()
	blink.tween_property(color_rect, "modulate:a", 0.2, 0.1)
	blink.tween_property(color_rect, "modulate:a", 1.0, 0.1)


func _on_body_entered(body: Node2D) -> void:
	if body is Kitty:
		body.collect_powerup(type)
		queue_free()
