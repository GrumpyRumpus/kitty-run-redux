extends Label

const RISE_DISTANCE := 24.0
const DURATION := 0.6


func _ready() -> void:
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "position:y", position.y - RISE_DISTANCE, DURATION)
	tween.tween_property(self, "modulate:a", 0.0, DURATION)
	tween.chain().tween_callback(queue_free)
