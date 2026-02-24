# Level coordinator -- keeps ground and background scroll speeds in sync
#
# In an infinite runner, the world moves while the player stays roughly
# centered. The background scrolls via parallax (handled by background.gd),
# and the ground tiles scroll at a matching speed. This script bridges
# the two by reading the background's current speed and applying it to
# both ground segments.
#
# The negative sign is because the background scrolls left (negative X)
# but the ground's speed value is consumed as a positive magnitude
# elsewhere and negated at the point of use.
extends Node2D

@export var background: Background
@export var world_boundary: WorldBoundary
@export var grounds: Grounds
@export var grounds_two: Grounds

func _process(delta: float) -> void:
	# sync ground scroll speed to match the background's current parallax rate
	grounds.speed = -background.speed
	grounds_two.speed = -background.speed
