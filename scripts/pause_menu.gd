# Pause menu overlay
#
# Uses Godot's built-in tree pausing: get_tree().paused = true freezes
# all nodes except those with process_mode set to PROCESS_MODE_ALWAYS
# or PROCESS_MODE_WHEN_PAUSED. The pause menu itself runs in ALWAYS mode
# (set in the editor) so it can respond to input while paused.
#
# The ESC key both opens and closes the menu. _unhandled_input checks
# visibility to prevent the pause action from triggering in other contexts
# (like the game-over screen).
extends CanvasLayer

const MAIN_MENU_FILE := "res://scenes/main_menu.tscn"


func _unhandled_input(event: InputEvent) -> void:
	# only handle pause when the menu is actually visible (prevents
	# conflicts with other screens that also listen for pause)
	if event.is_action_pressed("pause") and visible:
		resume()


func pause() -> void:
	visible = true
	get_tree().paused = true


func resume() -> void:
	visible = false
	get_tree().paused = false


func _on_resume_pressed() -> void:
	resume()


func _on_quit_pressed() -> void:
	visible = false
	get_tree().paused = false
	get_tree().change_scene_to_file(MAIN_MENU_FILE)
