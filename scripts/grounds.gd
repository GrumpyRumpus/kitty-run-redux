# Scrolling ground platform -- creates the infinite running surface
#
# Two ground segments alternate: when one scrolls off the left edge,
# it teleports to the right edge with a new random shape. This creates
# the illusion of infinite terrain.
#
# Each segment has multiple pre-built polygon shapes (ground_shapes)
# defined as children of the collision polygon. switch_ground() swaps
# the active polygon and updates the collision shape to match.
#
# Grass lines are drawn along the top edges of the ground polygon using
# Line2D nodes. Points below y=100 are considered "edges" (sides/bottom)
# and are excluded, so grass only appears on the walkable surface.
#
# The ground scrolls at 2x the background's bushes layer speed. This
# matches the fastest parallax layer (where the player stands), keeping
# the illusion consistent. The 2x factor accounts for the ground needing
# to visually move faster since it's at the player's feet.
class_name Grounds
extends StaticBody2D

@export var collision: CollisionPolygon2D
@export var speed: float = 25
@export var speed_multiplier: float = 1

# children of the collision polygon (different ground shapes)
var ground_shapes: Array[Node]
# currently active polygon shape
var ground: Polygon2D
var vp_height: int
var vp_width: int

# Line2D nodes for the grass overlay (rebuilt on each shape switch)
var grass_lines: Array[Line2D] = []

var ground_color := Color(0.271, 0.278, 0.353, 1)
var grass_color := Color(0.651, 0.890, 0.631, 1)


func _ready() -> void:
	vp_height = get_viewport_rect().size.y
	vp_width = get_viewport_rect().size.x
	ground_shapes = collision.get_children()
	# pick a random starting shape
	switch_ground(randi_range(0, 2))


func _process(delta: float) -> void:
	# scroll leftward at 2x the speed (ground moves faster than background)
	position.x -= 2 * speed * delta


# swap to a new ground polygon shape and rebuild the grass overlay
func switch_ground(ground_index: int) -> void:
	if ground:
		ground.visible = false
	ground = ground_shapes.get(ground_index)
	ground.color = ground_color
	ground.visible = true
	# sync the collision polygon to match the visual shape
	collision.polygon = ground.polygon

	# -------------------- Grass Lines --------------------
	# clear old grass lines
	for line in grass_lines:
		line.queue_free()
	grass_lines.clear()

	# walk the polygon points and build line segments for the top surface.
	# points with y < 100 are "top" points (walkable surface).
	# when we hit a point below that threshold, we end the current segment.
	var segment: PackedVector2Array = []
	for point in ground.polygon:
		if point.y < 100:
			segment.append(point)
		else:
			if segment.size() >= 2:
				var line := Line2D.new()
				line.width = 3.0
				line.default_color = grass_color
				add_child(line)
				line.points = segment
				grass_lines.append(line)
			segment = PackedVector2Array()
	# don't forget the last segment if the polygon ends with top points
	if segment.size() >= 2:
		var line := Line2D.new()
		line.width = 3.0
		line.default_color = grass_color
		add_child(line)
		line.points = segment
		grass_lines.append(line)

	# randomize vertical position slightly for terrain variety
	position.y = randi_range(vp_height / 2, vp_height / 2 + 25)


# when this ground segment scrolls fully off the left edge, teleport it
# to the right edge and give it a new random shape
func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	position.x = vp_width
	switch_ground(randi_range(0, 9))
