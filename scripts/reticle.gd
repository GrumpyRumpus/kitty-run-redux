# Custom animated mouse cursor
#
# Uses an AnimatedSprite2D's frames as a cursor texture. Each frame of
# the animation is extracted and set as the mouse cursor, creating an
# animated crosshair that follows the mouse.
#
# The cursor hotspot is centered on the sprite so it points at the
# exact pixel the player is aiming at.
#
# This is an autoload scene (set in project.godot) so it persists
# across all scenes.
extends AnimatedSprite2D


func _process(delta: float) -> void:
	var cursor_frame = sprite_frames.get_frame_texture(animation, frame)
	# set_custom_mouse_cursor replaces the OS cursor with our sprite.
	# the hotspot (3rd argument) centers the cursor on the sprite.
	Input.set_custom_mouse_cursor(cursor_frame, Input.CURSOR_ARROW,
	Vector2i(cursor_frame.get_width() / 2, cursor_frame.get_height() / 2))
