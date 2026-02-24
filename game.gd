# Main game controller -- orchestrates all gameplay systems
#
# This script is the central hub that connects the player, enemies, HUD,
# scoring, and game-feel effects. It doesn't own gameplay logic directly
# (that lives in kitty.gd, mob.gd, etc.) but instead listens to signals
# and coordinates responses.
#
# Architecture: signal-driven communication. The player emits events
# (stomped, health_changed, shot_fired), and this controller decides
# what happens (screen shake, combo update, camera punch). This keeps
# systems decoupled -- the player doesn't know about screen shake.
#
# Game feel ("juice") is concentrated here: hitstop, screen shake, camera
# punch, and combo feedback all live in one place so they're easy to tune.
extends Node2D

const MAIN_MENU_FILE := "res://scenes/main_menu.tscn"
const SCORE_POPUP := preload("res://scenes/score_popup.tscn")

# ============================================================
# NODE REFERENCES
# ============================================================
@onready var kitty: Kitty = $World/Level/Kitty
@onready var hud: CanvasLayer = $World/HUD
@onready var mob_spawner: Node2D = $World/Level/MobSpawner
@onready var game_over_layer: CanvasLayer = $GameOverLayer
@onready var game_over_score_label: Label = $GameOverLayer/CenterContainer/VBoxContainer/ScoreLabel
@onready var high_score_label: Label = $GameOverLayer/CenterContainer/VBoxContainer/HighScoreLabel
@onready var crt_layer: CanvasLayer = $World/CRT
@onready var camera: Camera2D = $World/Camera2D
@onready var pause_menu: CanvasLayer = $PauseMenu
@onready var transition_layer: CanvasLayer = $TransitionLayer
@onready var transition_rect: ColorRect = $TransitionLayer/ColorRect

# ============================================================
# CONSTANTS
# ============================================================
# how long after a kill the combo stays active before resetting
const COMBO_WINDOW := 3.0
# combo multiplier caps here (prevents runaway scores)
const MAX_COMBO := 10
# difficulty ramp: mob spawn interval lerps from max to min over this score range
const DIFFICULTY_MIN_INTERVAL := 2.0
const DIFFICULTY_MAX_INTERVAL := 5.0
const DIFFICULTY_SCORE_CAP := 500.0

# ============================================================
# STATE
# ============================================================
var score: int = 0
# accumulator for score-over-time (ticks up by delta, awards 1 point per second)
var score_tick: float = 0.0
var is_game_over: bool = false
# combo system: kills within the combo window increase the multiplier
var combo_count: int = 0
var combo_timer: float = 0.0
# track previous health to detect damage vs healing
var _last_health: int = Kitty.MAX_HEALTH


# ============================================================
# SETUP AND TEARDOWN
# ============================================================

func _ready() -> void:
	MusicManager.play_game()
	game_over_layer.visible = false
	transition_layer.visible = false
	crt_layer.visible = Settings.crt_enabled
	# connect to the Settings autoload signal for CRT toggle
	Settings.crt_changed.connect(_on_crt_changed)
	hud.update_score(score)
	hud.update_health(kitty.health)
	# connect player signals for game-feel responses.
	# signals let the player remain unaware of the score/HUD/camera systems.
	kitty.health_changed.connect(_on_kitty_health_changed)
	kitty.stomped.connect(_on_kitty_stomped)
	kitty.powerup_changed.connect(_on_kitty_powerup_changed)
	kitty.shot_fired.connect(_on_kitty_shot_fired)


func _exit_tree() -> void:
	# disconnect from the Settings autoload (it outlives this scene).
	# if we don't disconnect, the autoload holds a reference to a freed node,
	# causing errors on the next scene change.
	Settings.crt_changed.disconnect(_on_crt_changed)
	# kitty signals technically auto-disconnect when the scene is freed
	# (both ends are freed together), but explicit cleanup is safer.
	if is_instance_valid(kitty):
		kitty.health_changed.disconnect(_on_kitty_health_changed)
		kitty.stomped.disconnect(_on_kitty_stomped)
		kitty.powerup_changed.disconnect(_on_kitty_powerup_changed)
		kitty.shot_fired.disconnect(_on_kitty_shot_fired)


func _on_crt_changed(on: bool) -> void:
	crt_layer.visible = on


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		if is_game_over:
			return
		if pause_menu.visible:
			pause_menu.resume()
		else:
			pause_menu.pause()


# ============================================================
# GAME LOOP
# ============================================================

func _process(delta: float) -> void:
	if is_game_over:
		return
	# -------------------- Passive Score --------------------
	# the player earns 1 point per second just for surviving.
	# this rewards survival even without kills.
	score_tick += delta
	if score_tick >= 1.0:
		score_tick -= 1.0
		score += 1
		hud.update_score(score)
	# -------------------- Combo Timer --------------------
	# combo decays after no kills within the window
	if combo_timer > 0.0:
		combo_timer -= delta
		if combo_timer <= 0.0:
			_reset_combo()
	# -------------------- Difficulty Scaling --------------------
	# mob spawn interval shrinks linearly from 5s to 2s as score increases.
	# lerpf with a clamped ratio creates a smooth ramp that caps out.
	var interval := lerpf(DIFFICULTY_MAX_INTERVAL, DIFFICULTY_MIN_INTERVAL, clampf(float(score) / DIFFICULTY_SCORE_CAP, 0.0, 1.0))
	mob_spawner.set_spawn_interval(interval)
	# live HUD update for timed powerups (rapid fire countdown display)
	if kitty.rapid_fire_time > 0.0:
		hud.update_powerup(kitty)


# ============================================================
# COMBO SYSTEM
# ============================================================
# kills award points equal to the current combo multiplier.
# killing quickly chains combos: x1, x2, x3... up to MAX_COMBO.
# hits (non-lethal damage) extend the combo window without incrementing.
# taking damage or letting the timer expire resets the combo.

func add_kill_score(pos: Vector2) -> void:
	combo_count = mini(combo_count + 1, MAX_COMBO)
	combo_timer = COMBO_WINDOW
	# score scales with combo: first kill = +1, second = +2, etc.
	score += combo_count
	hud.update_score(score)
	hud.update_combo(combo_count)
	# floating score popup at the kill position
	var popup := SCORE_POPUP.instantiate()
	popup.position = pos
	popup.set_value(combo_count)
	$World/Level.add_child(popup)
	# subtle feedback on bullet kills (less intense than stomp)
	_screen_shake(3.0, 0.08)
	_hitstop(0.3, 0.03)


func extend_combo() -> void:
	# non-lethal hits refresh the combo timer (keeps it alive longer)
	if combo_count > 0:
		combo_timer = COMBO_WINDOW


func _reset_combo() -> void:
	# visual feedback when a combo of x2 or higher breaks
	if combo_count >= 2:
		hud.flash_combo_break()
		_screen_shake(2.0, 0.1)
	combo_count = 0
	combo_timer = 0.0
	hud.update_combo(0)


# ============================================================
# GAME FEEL -- PLAYER EVENT RESPONSES
# ============================================================
# each player event gets a tuned combination of screen shake, hitstop,
# and/or camera effects. the intensity hierarchy:
#   stomp (biggest):  shake 6.0 + hitstop 0.05 at 5%
#   damage taken:     shake 4.0 (no hitstop, already stunned)
#   bullet kill:      shake 3.0 + hitstop 0.03 at 30%
#   combo break:      shake 2.0 (emotional feedback, no hitstop)
#   shooting:         camera punch only (constant, subtle)

func _on_kitty_stomped() -> void:
	_screen_shake(6.0, 0.15)
	# heavy hitstop: near-freeze for 0.05s sells the impact
	_hitstop(0.05, 0.05)


# camera punch: instantly offset the camera opposite to the shot direction,
# then tween it back. this creates a subtle recoil effect that makes
# shooting feel impactful without disrupting gameplay.
func _on_kitty_shot_fired(dir: Vector2) -> void:
	var punch := -dir * 1.5
	camera.offset = punch
	var tween := create_tween()
	tween.tween_property(camera, "offset", Vector2.ZERO, 0.06)


func _on_kitty_health_changed(new_health: int) -> void:
	var prev_health := _last_health
	_last_health = new_health
	hud.update_health(new_health)
	if new_health < prev_health:
		# damage taken: shake + break combo (punishment for getting hit)
		_screen_shake(4.0, 0.2)
		_reset_combo()
	elif new_health > prev_health:
		# healed: flash the HUD to acknowledge the pickup
		hud.flash_health_pickup()


func _on_kitty_powerup_changed() -> void:
	hud.update_powerup(kitty)


# ============================================================
# GAME OVER
# ============================================================

func _on_kitty_game_over() -> void:
	if is_game_over:
		return
	is_game_over = true

	# capture the current gameplay frame BEFORE showing UI.
	# await frame_post_draw ensures the frame is fully rendered.
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	var from_texture := ImageTexture.create_from_image(img)

	# set up game over UI with score and high score
	var is_new_best := HighScore.submit_score(score)
	game_over_score_label.text = "score: %d" % score
	if is_new_best:
		high_score_label.text = "NEW BEST!"
	else:
		high_score_label.text = "best: %d" % HighScore.get_high_score()
	game_over_layer.visible = true
	hud.visible = false
	get_tree().paused = true

	# pixel dissolve transition: feeds the captured gameplay frame to a
	# shader that pixelates and dissolves it, revealing the game-over screen
	# underneath. the shader's "progress" uniform drives the animation.
	var mat := transition_rect.material as ShaderMaterial
	mat.set_shader_parameter("from_tex", from_texture)
	mat.set_shader_parameter("progress", 0.0)
	transition_layer.visible = true

	# TWEEN_PAUSE_PROCESS lets this tween run even while the tree is paused
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


# ============================================================
# GAME FEEL UTILITIES
# ============================================================

# Hitstop: briefly slows time to emphasize an impact.
# Games like Hollow Knight, Celeste, and Dead Cells use this extensively.
# The key insight is that the DURATION should be very short (30-50ms) --
# just enough for the brain to register the pause without feeling laggy.
#
# The timer uses process_always=true so it ticks in real time even though
# Engine.time_scale is slowed. ignore_time_scale=true (4th arg) ensures
# the timer isn't affected by the very time_scale change we just made.
func _hitstop(time_scale: float, duration: float) -> void:
	Engine.time_scale = time_scale
	get_tree().create_timer(duration, true, false, true).timeout.connect(
		func(): Engine.time_scale = 1.0
	)


# Screen shake: rapidly offsets the camera with random jitter, then
# returns to center. Higher intensity = wider jitter, longer duration =
# more shake steps. snappedf rounds to whole pixels for crisp pixel art.
func _screen_shake(intensity: float, duration: float) -> void:
	var tween := create_tween()
	var steps := int(duration / 0.05)
	for i in steps:
		var offset := Vector2(
			snappedf(randf_range(-intensity, intensity), 1.0),
			snappedf(randf_range(-intensity, intensity), 1.0)
		)
		tween.tween_property(camera, "offset", offset, 0.05)
	# always return to center after the last shake step
	tween.tween_property(camera, "offset", Vector2.ZERO, 0.05)
