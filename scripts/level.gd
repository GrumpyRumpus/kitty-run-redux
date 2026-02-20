extends Node2D

@export var background: Background
@export var world_boundary: WorldBoundary
@export var grounds: Grounds
@export var grounds_two: Grounds

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	grounds.speed = -background.speed
	grounds_two.speed = -background.speed
