extends CanvasLayer

const POWERUP_COLORS := {
	"shield": Color("#89b4fa"),
	"giant": Color("#fab387"),
	"rapid": Color("#f9e2af"),
	"jumps": Color("#a6e3a1"),
	"health": Color("#f38ba8"),
}

@onready var score_label: Label = $ScoreLabel
@onready var health_label: Label = $HealthLabel
@onready var combo_label: Label = $ComboLabel
@onready var powerup_label: Label = $PowerupLabel

var _health_flash_tween: Tween


func update_score(value: int) -> void:
	score_label.text = "score: %d" % value


func update_health(health: int) -> void:
	health_label.text = "\u2661 ".repeat(maxi(0, 3 - health)) + "\u2764".repeat(health)


func update_combo(count: int) -> void:
	if count >= 2:
		combo_label.text = "x%d" % count
		combo_label.visible = true
	else:
		combo_label.visible = false


func update_powerup(kitty: Kitty) -> void:
	# pick the most urgent active powerup to display
	# priority: lowest remaining count/time first
	var best_text := ""
	var best_color := Color.WHITE
	var best_priority := INF

	if kitty.has_shield:
		best_text = "\u25C6"
		best_color = POWERUP_COLORS["shield"]
		best_priority = 1.0

	if kitty.giant_bullets > 0 and kitty.giant_bullets < best_priority:
		best_text = "\u2726 x%d" % kitty.giant_bullets
		best_color = POWERUP_COLORS["giant"]
		best_priority = kitty.giant_bullets

	if kitty.rapid_fire_time > 0.0 and kitty.rapid_fire_time < best_priority:
		best_text = "\u00BB %.1fs" % kitty.rapid_fire_time
		best_color = POWERUP_COLORS["rapid"]
		best_priority = kitty.rapid_fire_time

	if kitty.extra_jumps > 0 and kitty.extra_jumps < best_priority:
		best_text = "\u2191 x%d" % kitty.extra_jumps
		best_color = POWERUP_COLORS["jumps"]
		best_priority = kitty.extra_jumps

	if best_text != "":
		powerup_label.text = best_text
		powerup_label.label_settings.font_color = best_color
		powerup_label.visible = true
	else:
		powerup_label.visible = false


func flash_health_pickup() -> void:
	if _health_flash_tween and _health_flash_tween.is_running():
		_health_flash_tween.kill()
	powerup_label.text = "+HP"
	powerup_label.label_settings.font_color = POWERUP_COLORS["health"]
	powerup_label.visible = true
	powerup_label.modulate.a = 1.0
	_health_flash_tween = create_tween()
	_health_flash_tween.tween_interval(0.5)
	_health_flash_tween.tween_property(powerup_label, "modulate:a", 0.0, 0.3)
	_health_flash_tween.tween_callback(func():
		powerup_label.visible = false
		powerup_label.modulate.a = 1.0
	)
