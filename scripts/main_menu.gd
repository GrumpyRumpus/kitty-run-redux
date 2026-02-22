extends Control

const GAME_SCENE: PackedScene = preload("res://game.tscn")

@onready var high_score_label: Label = $VBoxContainer/HighScoreLabel


@onready var crt_layer: CanvasLayer = $CRT


func _ready() -> void:
	MusicManager.play_menu()
	crt_layer.visible = Settings.crt_enabled
	Settings.crt_changed.connect(_on_crt_changed)
	var best := HighScore.get_high_score()
	if best > 0:
		high_score_label.text = "best: %d" % best
	else:
		high_score_label.text = ""


func _exit_tree() -> void:
	Settings.crt_changed.disconnect(_on_crt_changed)


func _on_crt_changed(on: bool) -> void:
	crt_layer.visible = on


func _on_start_button_pressed() -> void:
	get_tree().change_scene_to_packed(GAME_SCENE)


func _on_option_button_pressed() -> void:
	$VBoxContainer.visible = false
	$OptionsLayer.visible = true


func _on_options_back_pressed() -> void:
	$OptionsLayer.visible = false
	$VBoxContainer.visible = true


func _on_exit_button_pressed() -> void:
	get_tree().quit()
