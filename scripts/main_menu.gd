extends Control

var game = preload("res://game.tscn")

@onready var high_score_label: Label = $VBoxContainer/HighScoreLabel


@onready var vhs_layer: CanvasLayer = $VHS


func _ready() -> void:
	MusicManager.play_menu()
	vhs_layer.visible = Settings.vhs_enabled
	Settings.vhs_changed.connect(func(on): vhs_layer.visible = on)
	var best := HighScore.get_high_score()
	if best > 0:
		high_score_label.text = "best: %d" % best
	else:
		high_score_label.text = ""


func _process(delta: float) -> void:
	pass


func _on_start_button_pressed() -> void:
	get_tree().change_scene_to_packed(game)


func _on_option_button_pressed() -> void:
	$VBoxContainer.visible = false
	$Options.visible = true


func _on_options_back_pressed() -> void:
	$Options.visible = false
	$VBoxContainer.visible = true


func _on_exit_button_pressed() -> void:
	get_tree().quit()
