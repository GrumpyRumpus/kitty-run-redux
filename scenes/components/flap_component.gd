class_name FlapComponent
extends Node

@export_subgroup("Nodes")
@export var flap_timer: Timer

func flap(body: AnimatableBody2D, delta_time: float) -> void:
	var flap_x = randf_range(0,1) * cos(flap_timer.time_left) * 60 * delta_time
	var flap_y = randf_range(0,0.5) * sin(flap_timer.time_left) * 60 * delta_time
	body.rotation += PI * delta_time
	body.translate(Vector2(flap_x, flap_y))
	#body.position.x -= sin(flap_timer.time_left) * 60 * delta_time #+ randi_range(0, 3)
	#body.position.y -= sin(flap_timer.time_left) * 60 * delta_time #+ randi_range(0, 3)
	
