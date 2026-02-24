# First-run tutorial overlay -- shows control hints on the first game
#
# Builds the tutorial UI entirely in code (no scene nodes). This is a good
# technique when UI is temporary and data-driven -- the hint content comes
# from an array, so adding/changing hints is just editing data.
#
# Each hint panel is a PanelContainer with an HBoxContainer holding two
# labels: one for the key name (orange) and one for the description (blue).
# They fade in sequentially with increasing delays, creating a natural
# reading flow.
#
# The overlay checks Settings.tutorial_seen on _ready() and immediately
# frees itself if the tutorial was already shown. After completing the
# sequence, it sets tutorial_seen = true so it never shows again.
#
# The key names are read from Settings.input_bindings so they show the
# player's actual bindings, not hardcoded defaults.
extends CanvasLayer

# ============================================================
# VISUAL CONSTANTS
# ============================================================
const BG_COLOR := Color(0.094, 0.094, 0.145, 0.7)
const KEY_COLOR := Color(0.980, 0.702, 0.529, 1)
const TEXT_COLOR := Color(0.804, 0.839, 0.957, 1)
const FONT_SIZE := 10

# hint data: built in _ready() from current key bindings
var hints: Array[Dictionary] = []

# timing for the fade sequence
const FADE_IN := 0.3
const HOLD := 3.0
const FADE_OUT := 1.0


# look up the display name for an input action
func _key_name(action: String) -> String:
	var keycode = Settings.input_bindings.get(action, Settings.DEFAULT_KEYS[action])
	return OS.get_keycode_string(keycode)


func _ready() -> void:
	# skip if already seen
	if Settings.tutorial_seen:
		queue_free()
		return
	# define hints with positions and staggered delays.
	# positions are in screen-space (CanvasLayer ignores camera).
	hints = [
		{"text": _key_name("left") + "/" + _key_name("right"), "desc": " -- Move", "pos": Vector2(16, 200), "delay": 0.0},
		{"text": _key_name("up"), "desc": " -- Jump", "pos": Vector2(16, 216), "delay": 2.0},
		{"text": _key_name("shoot"), "desc": " -- Shoot", "pos": Vector2(380, 200), "delay": 4.0},
		{"text": "Mouse/" + _key_name("aim_up_left") + _key_name("aim_up") + _key_name("aim_up_right") + _key_name("aim_left") + _key_name("aim_down") + _key_name("aim_right"), "desc": " -- Aim", "pos": Vector2(380, 216), "delay": 6.0},
	]
	_show_hints()


func _show_hints() -> void:
	var tween := create_tween()
	var panels: Array[PanelContainer] = []

	# create all panels upfront (invisible)
	for hint in hints:
		var panel := _make_hint(hint.text, hint.desc, hint.pos)
		add_child(panel)
		panel.modulate.a = 0.0
		panels.append(panel)

	# chain fade-in and fade-out for each panel with staggered delays
	for i in panels.size():
		var panel := panels[i]
		var delay: float = hints[i].delay
		tween.tween_property(panel, "modulate:a", 1.0, FADE_IN).set_delay(delay)
		tween.tween_property(panel, "modulate:a", 0.0, FADE_OUT).set_delay(HOLD)

	tween.tween_callback(_finish)


# build a hint panel from scratch (no scene file needed)
func _make_hint(key_text: String, desc_text: String, pos: Vector2) -> PanelContainer:
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = BG_COLOR
	style.set_content_margin_all(4)
	style.corner_radius_top_left = 2
	style.corner_radius_top_right = 2
	style.corner_radius_bottom_left = 2
	style.corner_radius_bottom_right = 2
	panel.add_theme_stylebox_override("panel", style)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 0)
	panel.add_child(hbox)

	# key name in orange
	var key_label := Label.new()
	key_label.text = key_text
	key_label.add_theme_color_override("font_color", KEY_COLOR)
	key_label.add_theme_font_size_override("font_size", FONT_SIZE)
	hbox.add_child(key_label)

	# description in light blue
	var desc_label := Label.new()
	desc_label.text = desc_text
	desc_label.add_theme_color_override("font_color", TEXT_COLOR)
	desc_label.add_theme_font_size_override("font_size", FONT_SIZE)
	hbox.add_child(desc_label)

	panel.position = pos
	return panel


func _finish() -> void:
	# mark as seen so it never shows again
	Settings.tutorial_seen = true
	queue_free()
