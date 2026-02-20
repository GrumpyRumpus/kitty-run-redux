extends Node2D

const MAIN_MENU_FILE := "res://scenes/main_menu.tscn"
const SCORE_POPUP := preload("res://scenes/score_popup.tscn")

@onready var kitty: Kitty = $World/Level/Kitty
@onready var hud = $World/HUD
@onready var mob_spawner = $World/Level/MobSpawner
@onready var game_over_layer = $GameOverLayer
@onready var game_over_score_label: Label = $GameOverLayer/CenterContainer/VBoxContainer/ScoreLabel
@onready var high_score_label: Label = $GameOverLayer/CenterContainer/VBoxContainer/HighScoreLabel
@onready var vhs_layer: CanvasLayer = $World/VHS
@onready var camera: Camera2D = $World/Camera2D
@onready var pause_menu = $PauseMenu
@onready var transition_layer: CanvasLayer = $TransitionLayer
@onready var transition_rect: ColorRect = $TransitionLayer/ColorRect

var score: int = 0
var score_tick: float = 0.0
var is_game_over: bool = false


func _ready() -> void:
	MusicManager.play_game()
	game_over_layer.visible = false
	transition_layer.visible = false
	vhs_layer.visible = Settings.vhs_enabled
	Settings.vhs_changed.connect(func(on): vhs_layer.visible = on)
	hud.update_score(score)
	hud.update_health(kitty.health)
	kitty.health_changed.connect(_on_kitty_health_changed)
	# game_over is wired in game.tscn -- no duplicate connect needed
	# backup fall_down connection in case .tscn wiring is missing
	var wb = $World/Level/WorldBoundary
	if wb and not wb.fall_down.is_connected(kitty._on_world_boundary_fall_down):
		wb.fall_down.connect(kitty._on_world_boundary_fall_down)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		if is_game_over:
			return
		if pause_menu.visible:
			pause_menu.resume()
		else:
			pause_menu.pause()


func _process(delta: float) -> void:
	if is_game_over:
		return
	# score over time
	score_tick += delta
	if score_tick >= 1.0:
		score_tick -= 1.0
		score += 1
		hud.update_score(score)
	# difficulty scaling -- spawn interval 5s -> 2s over 500 points
	var interval := lerpf(5.0, 2.0, clampf(float(score) / 500.0, 0.0, 1.0))
	mob_spawner.set_spawn_interval(interval)


func add_kill_score(pos: Vector2) -> void:
	score += 1
	hud.update_score(score)
	# spawn score popup at kill position
	var popup := SCORE_POPUP.instantiate()
	popup.position = pos
	$World/Level.add_child(popup)


func _on_kitty_health_changed(new_health: int) -> void:
	hud.update_health(new_health)
	_screen_shake(4.0, 0.2)


func _on_kitty_game_over() -> void:
	if is_game_over:
		return
	is_game_over = true

	# capture gameplay screen before showing game over UI
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	var from_texture := ImageTexture.create_from_image(img)

	# set up game over UI
	var is_new_best := HighScore.submit_score(score)
	game_over_score_label.text = "score: %d" % score
	if is_new_best:
		high_score_label.text = "NEW BEST!"
	else:
		high_score_label.text = "best: %d" % HighScore.get_high_score()
	game_over_layer.visible = true
	hud.visible = false
	get_tree().paused = true

	# pixel transition: from gameplay capture to game over screen
	var mat := transition_rect.material as ShaderMaterial
	mat.set_shader_parameter("from_tex", from_texture)
	mat.set_shader_parameter("progress", 0.0)
	transition_layer.visible = true

	var tween := create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(mat, "shader_parameter/progress", 1.0, 1.0)
	tween.tween_callback(func(): transition_layer.visible = false)


func _on_restart_pressed() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()


func _on_quit_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file(MAIN_MENU_FILE)


func _screen_shake(intensity: float, duration: float) -> void:
	var tween := create_tween()
	var steps := int(duration / 0.05)
	for i in steps:
		var offset := Vector2(
			snappedf(randf_range(-intensity, intensity), 1.0),
			snappedf(randf_range(-intensity, intensity), 1.0)
		)
		tween.tween_property(camera, "offset", offset, 0.05)
	tween.tween_property(camera, "offset", Vector2.ZERO, 0.05)
