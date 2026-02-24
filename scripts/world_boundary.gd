# World boundary -- invisible area below the screen that detects falls
#
# An Area2D positioned below the visible screen. When the player falls
# through it, it emits fall_down which is connected to kitty's death
# handler. This catches edge cases where the player walks off a platform
# and falls below the level.
class_name WorldBoundary
extends Node2D


signal fall_down


func _on_bottom_body_entered(body: Node2D) -> void:
	if body is Kitty:
		fall_down.emit()
