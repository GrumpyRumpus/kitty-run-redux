# Main menu screen
#
# Simple menu with start, options, and exit buttons. Uses preload() for
# the game scene to avoid a loading hitch on "Start" press.
#
# Connects to the Settings autoload's crt_changed signal to toggle the
# CRT overlay in real-time. The signal is explicitly disconnected in
# _exit_tree() because Settings is an autoload (singleton) that outlives
# this scene -- if we don't disconnect, Settings would try to call a
# method on a freed node.
extends Control

const GAME_SCENE: PackedScene = preload("res://game.tscn")

@onready var high_score_label: Label = $VBoxContainer/HighScoreLabel


@onready var crt_layer: CanvasLayer = $CRT


func _ready() -> void:
	MusicManager.play_menu()
	crt_layer.visible = Settings.crt_enabled
	Settings.crt_changed.connect(_on_crt_changed)
	# show high score if one exists
	var best := HighScore.get_high_score()
	if best > 0:
		high_score_label.text = "best: %d" % best
	else:
		high_score_label.text = ""


func _exit_tree() -> void:
	# must disconnect from autoload signals to avoid dangling references
	Settings.crt_changed.disconnect(_on_crt_changed)


func _on_crt_changed(on: bool) -> void:
	crt_layer.visible = on


func _on_start_button_pressed() -> void:
	# change_scene_to_packed uses the preloaded scene (no loading delay)
	get_tree().change_scene_to_packed(GAME_SCENE)


func _on_option_button_pressed() -> void:
	# toggle between the main menu and options panel
	$VBoxContainer.visible = false
	$OptionsLayer.visible = true


func _on_options_back_pressed() -> void:
	$OptionsLayer.visible = false
	$VBoxContainer.visible = true


func _on_exit_button_pressed() -> void:
	get_tree().quit()
