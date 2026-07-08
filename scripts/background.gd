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
# Scroll speed ramps up exponentially with ELAPSED TIME (doubling every
# speed_double_time seconds), making the game feel progressively faster.
# Deriving the ramp from elapsed time instead of compounding per frame
# keeps it frame-rate independent -- a 144Hz player gets the same
# difficulty curve as a 60Hz player. It caps once the fastest layer
# reaches max_speed to prevent the game from becoming unplayable.
#
# Menu mode uses positive (rightward) scrolling at gentler speeds for the
# main menu background. Game mode uses negative (leftward) scrolling to
# create the illusion of the player running right.
class_name Background
extends Node2D

# seconds for layer speeds to double. base 25 -> cap 200 is 3 doublings,
# so the ramp tops out after 3x this value (default: 2 minutes in)
@export var speed_double_time: float = 40.0
@export var max_speed: float = 200
# current speed of the fastest layer (read by level.gd for ground sync)
@export var speed: float
@export var menu_mode: bool = false

# scrolling layers back to front (excluding the stationary base) and
# their starting speeds, captured in _ready() so the ramp can scale
# them directly from elapsed time
var _layers: Array[Parallax2D] = []
var _layer_bases: Array[float] = []
# gameplay time elapsed (drives the speed ramp)
var _elapsed: float = 0.0

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
	# capture base speeds so _process() can scale them from elapsed time
	_layers = [farthest, farther, far, trees, bushes]
	for layer in _layers:
		_layer_bases.append(layer.autoscroll.x)


func _process(delta: float) -> void:
	if menu_mode:
		return
	_elapsed += delta
	# exponential ramp driven by elapsed time, not frame count: speeds
	# double every speed_double_time seconds regardless of frame rate.
	# the factor is capped so the fastest layer (bushes) tops out at
	# max_speed; scaling every layer by the same factor preserves the
	# parallax depth ratios.
	var factor := minf(
		pow(2.0, _elapsed / speed_double_time),
		max_speed / absf(_layer_bases[_layer_bases.size() - 1])
	)
	for i in _layers.size():
		_layers[i].autoscroll.x = _layer_bases[i] * factor
	# expose the bushes (fastest layer) speed for other systems to read
	speed = bushes.autoscroll.x
