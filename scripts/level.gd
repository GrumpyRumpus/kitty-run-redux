extends Node2D

@export var background: Background
@export var world_boundary: WorldBoundary
@export var grounds: Grounds
@export var grounds_two: Grounds

func _process(delta: float) -> void:
	grounds.speed = -background.speed
	grounds_two.speed = -background.speed
