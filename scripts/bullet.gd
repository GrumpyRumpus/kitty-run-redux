# Bullet projectile -- used by both the player and enemies
#
# Bullets are Area2D nodes (not physics bodies) because they don't need
# collision response -- they just detect overlaps and react. Area2D is
# cheaper than CharacterBody2D/RigidBody2D for projectiles.
#
# The is_friendly flag determines who the bullet can hit:
#   - Friendly bullets (player): damage mobs, ignore the player
#   - Hostile bullets (enemy): damage the player, ignore mobs
# This is checked in _on_body_entered() rather than using collision layers,
# keeping the logic readable and easy to extend.
#
# Giant bullets (from the powerup) deal 3x damage and are visually scaled
# up 3x with an orange tint for clear feedback.
class_name Bullet
extends Area2D

const IMPACT := preload("res://scenes/bullet_impact.tscn")

@export var speed: float = 250

# set by ShootComponent before the bullet enters the tree
var direction: Vector2
var is_friendly: bool = false
var is_giant: bool = false


# called by ShootComponent after instantiation to set direction and rotation.
# also applies visual modifiers (enemy tint, giant scale).
func aim(origin: Vector2, target: Vector2) -> void:
	direction = origin.direction_to(target)
	# rotate the sprite to face the travel direction
	rotation = (target - origin).angle()
	# enemy bullets are tinted red so the player can distinguish them
	if not is_friendly:
		modulate = Color(1.0, 0.3, 0.3)
	# giant bullets are 3x size with orange tint
	if is_giant:
		scale = Vector2(3.0, 3.0)
		modulate = Color("#fab387")


func _process(delta: float) -> void:
	# simple linear movement (no physics integration needed)
	translate(direction * speed * delta)


func _spawn_impact() -> void:
	# spawn particle effect at impact point using the centralized FX helper
	FX.spawn_particles(IMPACT, global_position, get_tree())


# ============================================================
# COLLISION HANDLING
# ============================================================
# connected to the Area2D's body_entered signal in the editor.
# checks what we hit and responds accordingly.

func _on_body_entered(body: Node2D) -> void:
	# hit terrain: impact effect, destroy bullet
	if body is Grounds:
		_spawn_impact()
		queue_free()
		return
	# friendly bullet hit an enemy: deal damage
	if is_friendly and body is Mob:
		body.take_damage(3 if is_giant else 1)
		_spawn_impact()
		queue_free()
		return
	# enemy bullet hit the player: deal 1 damage, pass position for knockback
	if not is_friendly and body is Kitty:
		body.take_damage(1, global_position)
		_spawn_impact()
		queue_free()
		return


# auto-cleanup when the bullet leaves the visible screen
func _on_visible_on_screen_enabler_2d_screen_exited() -> void:
	queue_free()
