# Parallax scrolling background
#
# Creates depth illusion by scrolling layers at different speeds. Layers
# closer to the "camera" move faster, distant layers move slower. This
# is called parallax scrolling and is used in almost every 2D side-scroller.
#
# Layer order (back to front):
#   Base (stationary) -> Farthest Trees -> Farther Trees -> Far Trees -> Trees -> Bushes
#
# Each layer uses Godot's Parallax2D node, which handles infinite tiling
# automatically. We just set the autoscroll speed and Godot does the rest.
#
# The speed_multiplier increases very slowly over time (0.00001 per frame),
# creating a subtle acceleration that makes the game feel progressively
# faster without sudden jumps. It caps at max_speed to prevent the game
# from becoming unplayable.
#
# Menu mode uses positive (rightward) scrolling at gentler speeds for the
# main menu background. Game mode uses negative (leftward) scrolling to
# create the illusion of the player running right.
class_name Background
extends Node2D

@export var speed_multiplier: float = 1
@export var max_speed: float = 200
# current speed of the fastest layer (read by level.gd for ground sync)
@export var speed: float
@export var menu_mode: bool = false

@onready var base: Parallax2D = $"Base Layer"
@onready var farthest: Parallax2D = $"Farthest Trees"
@onready var farther: Parallax2D = $"Farther Trees"
@onready var far: Parallax2D = $"Far Trees"
@onready var trees: Parallax2D = $"Trees"
@onready var bushes: Parallax2D = $"Bushes"


func _ready() -> void:
	if menu_mode:
		# gentle rightward scroll for the menu background
		base.autoscroll = Vector2(0, 0)
		farthest.autoscroll = Vector2(2, 0)
		farther.autoscroll = Vector2(4, 0)
		far.autoscroll = Vector2(6, 0)
		trees.autoscroll = Vector2(8, 0)
		bushes.autoscroll = Vector2(10, 0)
	else:
		# game mode: leftward scroll (player "runs right").
		# each layer is ~5px/s faster than the one behind it.
		base.autoscroll = Vector2(0, 0)
		farthest.autoscroll = Vector2(-5, 0)
		farther.autoscroll = Vector2(-10, 0)
		far.autoscroll = Vector2(-15, 0)
		trees.autoscroll = Vector2(-20, 0)
		bushes.autoscroll = Vector2(-25, 0)


func _process(delta: float) -> void:
	if menu_mode:
		return
	# very gradually increase scroll speed over time.
	# multiplied every frame compounds subtly (like compound interest).
	speed_multiplier += delta * 0.00001
	# only accelerate if we haven't hit the speed cap
	if bushes.autoscroll.x > -max_speed:
		farthest.autoscroll.x *= speed_multiplier
		farther.autoscroll.x *= speed_multiplier
		far.autoscroll.x *= speed_multiplier
		trees.autoscroll.x *= speed_multiplier
		bushes.autoscroll.x *= speed_multiplier
	# expose the bushes (fastest layer) speed for other systems to read
	speed = bushes.autoscroll.x
