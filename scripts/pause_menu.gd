extends CanvasLayer

const MAIN_MENU_FILE := "res://scenes/main_menu.tscn"


func _unhandled_input(event: InputEvent) -> void:
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
