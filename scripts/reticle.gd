extends AnimatedSprite2D


func _process(delta: float) -> void:
	var cursor_frame = sprite_frames.get_frame_texture(animation, frame)
	Input.set_custom_mouse_cursor(cursor_frame, Input.CURSOR_ARROW, 
	Vector2i(cursor_frame.get_width() / 2, cursor_frame.get_height() / 2))
