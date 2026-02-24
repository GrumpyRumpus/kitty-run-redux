# Powerup pickup -- dropped by enemies, collected by the player
#
# Pickups use Area2D for overlap detection (no physics response needed).
# They simulate their own gravity and ground collision using a manual
# raycast rather than a physics body. This avoids issues with pickups
# getting stuck in terrain or interacting with other physics objects.
#
# Lifecycle: spawn with upward velocity -> fall with gravity -> land on
# ground -> hover in place with bob animation -> blink warning -> despawn.
#
# The ground detection uses a direct space state raycast. This is more
# efficient than adding a CollisionShape2D + physics body for a simple
# "fall until you hit the floor" behavior.
#
# Pickups also scroll with the ground (the world is an infinite runner)
# and clean themselves up when they fall off the left edge.
class_name Pickup
extends Area2D

enum Type { HEALTH, SHIELD, GIANT_BULLET, RAPID_FIRE, EXTRA_JUMP }

# color per type -- used by the pickup's visual and the HUD display
const COLORS := {
	Type.HEALTH: Color("#f38ba8"),
	Type.SHIELD: Color("#89b4fa"),
	Type.GIANT_BULLET: Color("#fab387"),
	Type.RAPID_FIRE: Color("#f9e2af"),
	Type.EXTRA_JUMP: Color("#a6e3a1"),
}

const GRAVITY := 400.0
# total time before the pickup disappears
const DESPAWN_TIME := 6.0
# when to start blinking (warning that it's about to vanish)
const BLINK_START := 4.0
# how high above the ground surface the pickup hovers
const HOVER_HEIGHT := 12.0

# set by the mob before adding to the tree
var type: Type = Type.HEALTH
# initial upward velocity so pickups "pop" out of the enemy
var velocity_y: float = -60.0
var on_ground: bool = false

@onready var color_rect: ColorRect = $ColorRect


func _ready() -> void:
	# color the visual to match the pickup type
	color_rect.color = COLORS[type]
	# looping bob animation: gentle up-and-down float using sine easing
	var bob := create_tween().set_loops()
	bob.tween_property(color_rect, "position:y", -2.0, 0.4).set_trans(Tween.TRANS_SINE)
	bob.tween_property(color_rect, "position:y", 2.0, 0.4).set_trans(Tween.TRANS_SINE)
	# start blinking before despawn so the player knows it's about to vanish
	get_tree().create_timer(BLINK_START).timeout.connect(_start_blink)
	# hard despawn after full duration
	get_tree().create_timer(DESPAWN_TIME).timeout.connect(queue_free)


func _physics_process(delta: float) -> void:
	# -------------------- Ground Scrolling --------------------
	# pickups scroll with the ground so they don't float in place
	# while the world moves underneath them
	var level := get_parent()
	if level and "grounds" in level:
		position.x -= 2 * level.grounds.speed * delta
	# clean up if scrolled off the left edge
	if position.x < -32:
		queue_free()
		return
	# once on the ground, stop simulating
	if on_ground:
		return
	# -------------------- Gravity Simulation --------------------
	velocity_y += GRAVITY * delta
	var move_y := velocity_y * delta
	# raycast downward to find the ground surface.
	# using direct space state avoids needing a physics body on the pickup.
	var space := get_world_2d().direct_space_state
	if space:
		var from := global_position
		var to := Vector2(global_position.x, global_position.y + move_y + 4.0)
		var query := PhysicsRayQueryParameters2D.create(from, to)
		var result := space.intersect_ray(query)
		if result and result.collider is Grounds:
			# snap to hover height above the ground
			global_position.y = result.position.y - HOVER_HEIGHT
			velocity_y = 0.0
			on_ground = true
			return
	position.y += move_y
	# fell off the bottom of the screen -- clean up
	if position.y > 300:
		queue_free()


func _start_blink() -> void:
	# rapid alpha flicker warns the player the pickup is about to vanish
	var blink := create_tween().set_loops()
	blink.tween_property(color_rect, "modulate:a", 0.2, 0.1)
	blink.tween_property(color_rect, "modulate:a", 1.0, 0.1)


# connected to the Area2D's body_entered signal in the editor
func _on_body_entered(body: Node2D) -> void:
	if body is Kitty:
		body.collect_powerup(type)
		queue_free()
