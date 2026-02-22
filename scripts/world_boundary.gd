class_name WorldBoundary
extends Node2D


signal fall_down


func _on_bottom_body_entered(body: Node2D) -> void:
	if body is Kitty:
		fall_down.emit()
