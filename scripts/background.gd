class_name Background
extends Node2D

@export var speed_multiplier: float = 1
@export var max_speed: float = 200
@export var speed: float
@export var menu_mode: bool = false

@onready var base = $"Base Layer"
@onready var farthest = $"Farthest Trees"
@onready var farther = $"Farther Trees"
@onready var far = $"Far Trees"
@onready var trees = $"Trees"
@onready var bushes = $"Bushes"


func _ready() -> void:
	if menu_mode:
		base.autoscroll = Vector2(0, 0)
		farthest.autoscroll = Vector2(2, 0)
		farther.autoscroll = Vector2(4, 0)
		far.autoscroll = Vector2(6, 0)
		trees.autoscroll = Vector2(8, 0)
		bushes.autoscroll = Vector2(10, 0)
	else:
		base.autoscroll = Vector2(0, 0)
		farthest.autoscroll = Vector2(-5, 0)
		farther.autoscroll = Vector2(-10, 0)
		far.autoscroll = Vector2(-15, 0)
		trees.autoscroll = Vector2(-20, 0)
		bushes.autoscroll = Vector2(-25, 0)


func _process(delta: float) -> void:
	if menu_mode:
		return
	speed_multiplier += delta * 0.00001
	if bushes.autoscroll.x > -max_speed:
		farthest.autoscroll.x *= speed_multiplier
		farther.autoscroll.x *= speed_multiplier
		far.autoscroll.x *= speed_multiplier
		trees.autoscroll.x *= speed_multiplier
		bushes.autoscroll.x *= speed_multiplier
	speed = bushes.autoscroll.x
