extends CanvasLayer

const BG_COLOR := Color(0.094, 0.094, 0.145, 0.7)
const KEY_COLOR := Color(0.980, 0.702, 0.529, 1)
const TEXT_COLOR := Color(0.804, 0.839, 0.957, 1)
const FONT_SIZE := 10

const HINTS := [
	{"text": "A/D", "desc": " -- Move", "pos": Vector2(16, 200), "delay": 0.0},
	{"text": "W", "desc": " -- Jump", "pos": Vector2(16, 216), "delay": 2.0},
	{"text": "Space", "desc": " -- Shoot", "pos": Vector2(380, 200), "delay": 4.0},
	{"text": "Mouse/IJKL", "desc": " -- Aim", "pos": Vector2(380, 216), "delay": 6.0},
]

const FADE_IN := 0.3
const HOLD := 3.0
const FADE_OUT := 1.0


func _ready() -> void:
	if Settings.tutorial_seen:
		queue_free()
		return
	_show_hints()


func _show_hints() -> void:
	var tween := create_tween()
	var panels: Array[PanelContainer] = []

	for hint in HINTS:
		var panel := _make_hint(hint.text, hint.desc, hint.pos)
		add_child(panel)
		panel.modulate.a = 0.0
		panels.append(panel)

	for i in panels.size():
		var panel := panels[i]
		var delay: float = HINTS[i].delay
		tween.tween_property(panel, "modulate:a", 1.0, FADE_IN).set_delay(delay)
		tween.tween_property(panel, "modulate:a", 0.0, FADE_OUT).set_delay(HOLD)

	tween.tween_callback(_finish)


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

	var key_label := Label.new()
	key_label.text = key_text
	key_label.add_theme_color_override("font_color", KEY_COLOR)
	key_label.add_theme_font_size_override("font_size", FONT_SIZE)
	hbox.add_child(key_label)

	var desc_label := Label.new()
	desc_label.text = desc_text
	desc_label.add_theme_color_override("font_color", TEXT_COLOR)
	desc_label.add_theme_font_size_override("font_size", FONT_SIZE)
	hbox.add_child(desc_label)

	panel.position = pos
	return panel


func _finish() -> void:
	Settings.tutorial_seen = true
	queue_free()
