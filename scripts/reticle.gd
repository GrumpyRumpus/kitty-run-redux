extends AnimatedSprite2D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	var cursor_frame = self.sprite_frames.get_frame_texture(self.animation, self.frame)
	Input.set_custom_mouse_cursor(cursor_frame, Input.CURSOR_ARROW, 
	Vector2i(cursor_frame.get_height() / 2, cursor_frame.get_width() / 2))
