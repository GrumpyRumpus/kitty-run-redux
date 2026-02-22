extends Control

@onready var size_option: OptionButton = $MarginContainer/VBoxContainer/TabContainer/Video/SizeOption
@onready var vhs_checkbox: CheckBox = $MarginContainer/VBoxContainer/TabContainer/Video/VHSCheckBox
@onready var fullscreen_checkbox: CheckBox = $MarginContainer/VBoxContainer/TabContainer/Video/FullscreenCheckBox
@onready var sfx_slider: HSlider = $MarginContainer/VBoxContainer/TabContainer/Sound/SFXSlider
@onready var music_slider: HSlider = $MarginContainer/VBoxContainer/TabContainer/Sound/MusicSlider
@onready var mute_checkbox: CheckBox = $MarginContainer/VBoxContainer/TabContainer/Sound/MuteCheckBox
@onready var high_score_value: Label = $MarginContainer/VBoxContainer/TabContainer/Data/HighScoreValue
@onready var reset_score_button: Button = $MarginContainer/VBoxContainer/TabContainer/Data/ResetScoreButton
@onready var controls_tab: VBoxContainer = $MarginContainer/VBoxContainer/TabContainer/Controls
@onready var reset_bindings_button: Button = $MarginContainer/VBoxContainer/TabContainer/Controls/ResetBindingsButton

const ACTION_BUTTONS := {
	"left": "LeftButton",
	"right": "RightButton",
	"up": "JumpButton",
	"shoot": "ShootButton",
	"sprint": "SprintButton",
	"aim_left": "AimLeftButton",
	"aim_right": "AimRightButton",
	"aim_up": "AimUpButton",
	"aim_down": "AimDownButton",
	"aim_up_left": "AimUpLeftButton",
	"aim_up_right": "AimUpRightButton",
	"pause": "PauseButton",
}

var _binding_buttons: Dictionary = {}
var _listening_action: String = ""
var _listening_button: Button = null


func _ready() -> void:
	size_option.selected = Settings.window_scale - 1
	vhs_checkbox.button_pressed = Settings.vhs_enabled
	fullscreen_checkbox.button_pressed = Settings.fullscreen
	size_option.disabled = Settings.fullscreen
	sfx_slider.value = Settings.sfx_volume
	music_slider.value = Settings.music_volume
	mute_checkbox.button_pressed = Settings.muted
	_update_high_score()
	for action in ACTION_BUTTONS:
		var btn: Button = controls_tab.find_child(ACTION_BUTTONS[action])
		_binding_buttons[action] = btn
		btn.pressed.connect(_on_binding_pressed.bind(action))
		_update_button_text(action)
	reset_bindings_button.pressed.connect(_on_reset_bindings_pressed)


func _update_button_text(action: String) -> void:
	var btn: Button = _binding_buttons[action]
	var keycode = Settings.input_bindings.get(action, Settings.DEFAULT_KEYS[action])
	btn.text = OS.get_keycode_string(keycode)


func _on_binding_pressed(action: String) -> void:
	if _listening_button:
		_update_button_text(_listening_action)
	_listening_action = action
	_listening_button = _binding_buttons[action]
	_listening_button.text = "..."


func _input(event: InputEvent) -> void:
	if not _listening_button:
		return
	if event is InputEventKey and event.pressed:
		get_viewport().set_input_as_handled()
		if event.physical_keycode == KEY_ESCAPE:
			_update_button_text(_listening_action)
		else:
			Settings.set_binding(_listening_action, event.physical_keycode)
			_update_button_text(_listening_action)
		_listening_action = ""
		_listening_button = null


func _on_reset_bindings_pressed() -> void:
	Settings.reset_bindings()
	for action in _binding_buttons:
		_update_button_text(action)


func _on_sfx_changed(value: float) -> void:
	Settings.sfx_volume = value


func _on_music_changed(value: float) -> void:
	Settings.music_volume = value


func _on_mute_toggled(enabled: bool) -> void:
	Settings.muted = enabled


func _on_size_selected(index: int) -> void:
	Settings.window_scale = index + 1


func _on_vhs_toggled(enabled: bool) -> void:
	Settings.vhs_enabled = enabled


func _on_fullscreen_toggled(enabled: bool) -> void:
	Settings.fullscreen = enabled
	size_option.disabled = enabled


func _on_reset_score_pressed() -> void:
	HighScore.reset()
	_update_high_score()


func _update_high_score() -> void:
	var best := HighScore.get_high_score()
	high_score_value.text = str(best) if best > 0 else "---"
	reset_score_button.disabled = best == 0
