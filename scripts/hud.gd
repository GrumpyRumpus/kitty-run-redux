# In-game HUD -- displays score, health, combo, and active powerup
#
# This is a CanvasLayer so it renders on top of the game world and doesn't
# move with the camera. The game controller (game.gd) calls these update
# functions whenever game state changes.
#
# The HUD doesn't poll game state -- it's purely push-based. This is a
# good pattern: the HUD is "dumb" and only knows how to display data,
# not where to get it. The game controller decides when to update.
extends CanvasLayer

@onready var score_label: Label = $ScoreLabel
@onready var health_label: Label = $HealthLabel
@onready var combo_label: Label = $ComboLabel
@onready var powerup_label: Label = $PowerupLabel

# tween references for effects that might need to be interrupted.
# if a new tween starts while the old one is running, we kill() the old
# one first to prevent overlapping animations.
var _health_flash_tween: Tween
var _combo_tween: Tween


func update_score(value: int) -> void:
	score_label.text = "score: %d" % value


# health display uses Unicode hearts: filled for current HP, hollow for lost
func update_health(health: int) -> void:
	health_label.text = "\u2661 ".repeat(maxi(0, 3 - health)) + "\u2764".repeat(health)


# ============================================================
# COMBO DISPLAY
# ============================================================
# the combo label escalates visually as the multiplier increases:
#   - scale grows from 1.0x (at x2) to 1.5x (at x10)
#   - color shifts from white -> yellow -> pink
#   - each increment gets a "punch" scale (overshoot then settle)
#
# this makes high combos feel exciting and rewards the player visually
# for maintaining kill streaks.

func update_combo(count: int) -> void:
	if count >= 2:
		combo_label.text = "x%d" % count
		combo_label.visible = true
		# normalized progress: 0.0 at x2, 1.0 at x10
		var t := clampf(float(count - 2) / 8.0, 0.0, 1.0)
		var target_scale := lerpf(1.0, 1.5, t)
		# two-phase color gradient: white->yellow in first half, yellow->pink in second
		var color: Color
		if t < 0.5:
			color = Color.WHITE.lerp(Color("#f9e2af"), t * 2.0)
		else:
			color = Color("#f9e2af").lerp(Color("#f38ba8"), (t - 0.5) * 2.0)
		combo_label.label_settings.font_color = color
		# punch-scale: instantly set to 130% of target, then ease down.
		# the overshoot-then-settle makes each increment feel impactful.
		if _combo_tween and _combo_tween.is_running():
			_combo_tween.kill()
		_combo_tween = create_tween()
		combo_label.scale = Vector2(target_scale * 1.3, target_scale * 1.3)
		_combo_tween.tween_property(combo_label, "scale",
			Vector2(target_scale, target_scale), 0.12).set_ease(Tween.EASE_OUT)
	else:
		combo_label.visible = false


# ============================================================
# POWERUP DISPLAY
# ============================================================
# shows the most urgent active powerup. "most urgent" = lowest remaining
# count or time, so the player sees what's about to run out first.
# uses Unicode symbols for a compact display:
#   shield: diamond, giant: sparkle, rapid fire: chevrons, jump: arrow

func update_powerup(kitty: Kitty) -> void:
	var best_text := ""
	var best_color := Color.WHITE
	var best_priority := INF

	if kitty.has_shield:
		best_text = "\u25C6"
		best_color = Pickup.COLORS[Pickup.Type.SHIELD]
		best_priority = 1.0

	if kitty.giant_bullets > 0 and kitty.giant_bullets < best_priority:
		best_text = "\u2726 x%d" % kitty.giant_bullets
		best_color = Pickup.COLORS[Pickup.Type.GIANT_BULLET]
		best_priority = kitty.giant_bullets

	if kitty.rapid_fire_time > 0.0 and kitty.rapid_fire_time < best_priority:
		best_text = "\u00BB %.1fs" % kitty.rapid_fire_time
		best_color = Pickup.COLORS[Pickup.Type.RAPID_FIRE]
		best_priority = kitty.rapid_fire_time

	if kitty.extra_jumps > 0 and kitty.extra_jumps < best_priority:
		best_text = "\u2191 x%d" % kitty.extra_jumps
		best_color = Pickup.COLORS[Pickup.Type.EXTRA_JUMP]
		best_priority = kitty.extra_jumps

	if best_text != "":
		powerup_label.text = best_text
		powerup_label.label_settings.font_color = best_color
		powerup_label.visible = true
	else:
		powerup_label.visible = false


# ============================================================
# FEEDBACK FLASHES
# ============================================================

# combo break: flash the label red and fade it out.
# this gives the player a moment to see their combo ended, rather than
# the label just vanishing.
func flash_combo_break() -> void:
	combo_label.label_settings.font_color = Color("#f38ba8")
	var tween := create_tween()
	tween.tween_property(combo_label, "modulate:a", 0.0, 0.2)
	tween.tween_callback(func():
		combo_label.visible = false
		combo_label.modulate.a = 1.0
	)


# health pickup flash: briefly shows "+HP" in the powerup slot.
# the tween chain: hold for 0.5s -> fade out -> hide and restore alpha.
func flash_health_pickup() -> void:
	# kill any running flash to prevent overlap
	if _health_flash_tween and _health_flash_tween.is_running():
		_health_flash_tween.kill()
	powerup_label.text = "+HP"
	powerup_label.label_settings.font_color = Pickup.COLORS[Pickup.Type.HEALTH]
	powerup_label.visible = true
	powerup_label.modulate.a = 1.0
	_health_flash_tween = create_tween()
	_health_flash_tween.tween_interval(0.5)
	_health_flash_tween.tween_property(powerup_label, "modulate:a", 0.0, 0.3)
	_health_flash_tween.tween_callback(func():
		powerup_label.visible = false
		powerup_label.modulate.a = 1.0
	)
