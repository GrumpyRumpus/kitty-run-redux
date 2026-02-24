# Floating score popup -- rises and fades after a kill
#
# Spawned by game.gd at the enemy's death position. Uses a parallel tween
# (both properties animate simultaneously) to rise upward while fading out.
# The chain() call after the parallel block ensures queue_free() runs only
# after both animations complete.
#
# This is a common "juice" technique -- floating numbers give immediate
# feedback about how much score the player earned and where.
extends Label

# how far the label rises (in pixels)
const RISE_DISTANCE := 24.0
# total animation duration
const DURATION := 0.6


func set_value(amount: int) -> void:
	text = "+%d" % amount


func _ready() -> void:
	var tween := create_tween()
	# set_parallel(true): both tweens below run at the same time
	tween.set_parallel(true)
	tween.tween_property(self, "position:y", position.y - RISE_DISTANCE, DURATION)
	tween.tween_property(self, "modulate:a", 0.0, DURATION)
	# chain() switches back to sequential mode, so queue_free runs after both finish
	tween.chain().tween_callback(queue_free)
