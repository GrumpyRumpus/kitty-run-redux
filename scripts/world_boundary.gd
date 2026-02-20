class_name WorldBoundary
extends Node2D


signal fall_down


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_bottom_body_entered(body: Node2D) -> void:
	if body.name.match("Kitty"):
		emit_signal("fall_down")
