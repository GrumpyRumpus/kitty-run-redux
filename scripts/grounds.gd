class_name Grounds
extends StaticBody2D

@export var collision: CollisionPolygon2D
@export var speed: float = 25
@export var speed_multiplier: float = 1

var ground_shapes: Array[Node]
var ground: Polygon2D
var vp_height: int
var vp_width: int

var grass_lines: Array[Line2D] = []

var ground_color := Color(0.271, 0.278, 0.353, 1)
var grass_color := Color(0.651, 0.890, 0.631, 1)


func _ready() -> void:
	vp_height = get_viewport_rect().size.y
	vp_width = get_viewport_rect().size.x
	ground_shapes = collision.get_children()

	switch_ground(randi_range(0, 2))


func _process(delta: float) -> void:
	self.position.x -= 2 * speed * delta


func switch_ground(ground_index: int) -> void:
	if ground:
		ground.visible = false
	ground = ground_shapes.get(ground_index)
	ground.color = ground_color
	ground.visible = true
	collision.polygon = ground.polygon

	for line in grass_lines:
		line.queue_free()
	grass_lines.clear()

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
	if segment.size() >= 2:
		var line := Line2D.new()
		line.width = 3.0
		line.default_color = grass_color
		add_child(line)
		line.points = segment
		grass_lines.append(line)

	self.position.y = randi_range(vp_height / 2, vp_height / 2 + 25)


func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	self.position.x = vp_width
	switch_ground(randi_range(0, 9))
