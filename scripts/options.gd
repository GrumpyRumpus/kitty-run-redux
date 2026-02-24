# Options menu -- video, sound, data, and control settings
#
# All settings are stored in the Settings autoload (singleton). This screen
# just provides the UI to read and write those values. Settings handles
# persistence, validation, and applying changes to the engine.
#
# Key rebinding uses a "listen" pattern:
#   1. Player clicks a binding button (e.g., "Jump: W")
#   2. Button text changes to "..." and the menu enters "listening" mode
#   3. Next key press is captured in _input() and applied as the new binding
#   4. ESC cancels the rebind
#
# _input() is used instead of _unhandled_input() because we need to
# intercept the key BEFORE it triggers game actions. set_input_as_handled()
# prevents the captured key from also firing game actions.
extends Control

@onready var size_option: OptionButton = $MarginContainer/VBoxContainer/TabContainer/Video/SizeOption
@onready var crt_checkbox: CheckBox = $MarginContainer/VBoxContainer/TabContainer/Video/CRTCheckBox
@onready var fullscreen_checkbox: CheckBox = $MarginContainer/VBoxContainer/TabContainer/Video/FullscreenCheckBox
@onready var sfx_slider: HSlider = $MarginContainer/VBoxContainer/TabContainer/Sound/SFXSlider
@onready var music_slider: HSlider = $MarginContainer/VBoxContainer/TabContainer/Sound/MusicSlider
@onready var mute_checkbox: CheckBox = $MarginContainer/VBoxContainer/TabContainer/Sound/MuteCheckBox
@onready var high_score_value: Label = $MarginContainer/VBoxContainer/TabContainer/Data/HighScoreValue
@onready var reset_score_button: Button = $MarginContainer/VBoxContainer/TabContainer/Data/ResetScoreButton
@onready var controls_tab: VBoxContainer = $MarginContainer/VBoxContainer/TabContainer/Controls
@onready var reset_bindings_button: Button = $MarginContainer/VBoxContainer/TabContainer/Controls/ResetBindingsButton

# maps action names to their button node names in the Controls tab
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

# runtime references to binding buttons (populated in _ready)
var _binding_buttons: Dictionary = {}
# which action we're currently rebinding (empty = not listening)
var _listening_action: String = ""
var _listening_button: Button = null


func _ready() -> void:
	# sync UI controls to current Settings values
	size_option.selected = Settings.window_scale - 1
	crt_checkbox.button_pressed = Settings.crt_enabled
	fullscreen_checkbox.button_pressed = Settings.fullscreen
	size_option.disabled = Settings.fullscreen
	sfx_slider.value = Settings.sfx_volume
	music_slider.value = Settings.music_volume
	mute_checkbox.button_pressed = Settings.muted
	_update_high_score()
	# set up binding buttons: find each button, store a reference,
	# connect its pressed signal, and display the current key
	for action in ACTION_BUTTONS:
		var btn: Button = controls_tab.find_child(ACTION_BUTTONS[action])
		_binding_buttons[action] = btn
		btn.pressed.connect(_on_binding_pressed.bind(action))
		_update_button_text(action)
	reset_bindings_button.pressed.connect(_on_reset_bindings_pressed)


# -------------------- Key Rebinding --------------------

func _update_button_text(action: String) -> void:
	# display the human-readable key name on the button
	var btn: Button = _binding_buttons[action]
	var keycode = Settings.input_bindings.get(action, Settings.DEFAULT_KEYS[action])
	btn.text = OS.get_keycode_string(keycode)


func _on_binding_pressed(action: String) -> void:
	# cancel previous listen if one was active
	if _listening_button:
		_update_button_text(_listening_action)
	# enter listening mode for this action
	_listening_action = action
	_listening_button = _binding_buttons[action]
	_listening_button.text = "..."


func _input(event: InputEvent) -> void:
	if not _listening_button:
		return
	if event is InputEventKey and event.pressed:
		# consume the event so it doesn't trigger game actions
		get_viewport().set_input_as_handled()
		if event.physical_keycode == KEY_ESCAPE:
			# ESC cancels the rebind
			_update_button_text(_listening_action)
		else:
			# apply the new binding
			Settings.set_binding(_listening_action, event.physical_keycode)
			_update_button_text(_listening_action)
		_listening_action = ""
		_listening_button = null


func _on_reset_bindings_pressed() -> void:
	Settings.reset_bindings()
	for action in _binding_buttons:
		_update_button_text(action)


# -------------------- Video/Sound/Data Callbacks --------------------
# these are connected to UI signals in the editor.
# each one writes directly to the Settings autoload, which handles
# validation, applying the change, and saving to disk.

func _on_sfx_changed(value: float) -> void:
	Settings.sfx_volume = value


func _on_music_changed(value: float) -> void:
	Settings.music_volume = value


func _on_mute_toggled(enabled: bool) -> void:
	Settings.muted = enabled


func _on_size_selected(index: int) -> void:
	Settings.window_scale = index + 1


func _on_crt_toggled(enabled: bool) -> void:
	Settings.crt_enabled = enabled


func _on_fullscreen_toggled(enabled: bool) -> void:
	Settings.fullscreen = enabled
	# disable window scale when fullscreen (it doesn't apply)
	size_option.disabled = enabled


func _on_reset_score_pressed() -> void:
	HighScore.reset()
	_update_high_score()


func _update_high_score() -> void:
	var best := HighScore.get_high_score()
	high_score_value.text = str(best) if best > 0 else "---"
	reset_score_button.disabled = best == 0
