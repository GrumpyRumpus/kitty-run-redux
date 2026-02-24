# Settings persistence and application (autoload singleton)
#
# This singleton owns ALL player preferences: video, audio, controls, and
# misc flags. Every property uses a setter that:
#   1. Validates/clamps the value
#   2. Applies the change to the engine (InputMap, AudioServer, etc.)
#   3. Saves to disk
#
# The save format is a binary file with fixed field order. This is fragile
# (adding fields requires careful version handling) but simple and fast.
# The _load() function uses position checks to handle files from older
# versions that have fewer fields.
#
# Key rebinding works by modifying Godot's InputMap at runtime. The default
# keys from project.godot are overwritten with the player's custom bindings.
# Arrow key alternatives for movement are always added alongside the custom
# key, so both WASD and arrow keys work.
#
# The _loading flag prevents save loops: setting properties during _load()
# would trigger their setters, which call _save(), creating an infinite cycle.
extends Node

signal crt_changed(enabled: bool)

const SAVE_PATH := "user://settings.dat"

# ============================================================
# KEY BINDINGS
# ============================================================
# all actions that can be rebound by the player
const REBINDABLE_ACTIONS: Array[String] = [
	"left", "right", "up", "shoot", "sprint",
	"aim_left", "aim_right", "aim_up", "aim_down", "aim_up_left", "aim_up_right",
	"pause",
]

# factory defaults
const DEFAULT_KEYS := {
	"left": KEY_A, "right": KEY_D, "up": KEY_W,
	"shoot": KEY_SPACE, "sprint": KEY_SHIFT,
	"aim_left": KEY_J, "aim_right": KEY_L, "aim_up": KEY_I,
	"aim_down": KEY_K, "aim_up_left": KEY_U, "aim_up_right": KEY_O,
	"pause": KEY_ESCAPE,
}

# arrow keys are always available for movement (in addition to custom keys)
const ARROW_EXTRAS := {
	"left": KEY_LEFT, "right": KEY_RIGHT, "up": KEY_UP,
}

# prevents save loops during _load()
var _loading: bool = false
# current key bindings (action name -> keycode)
var input_bindings: Dictionary = {}

# ============================================================
# SETTINGS PROPERTIES
# ============================================================
# each setter validates, applies, and saves. this pattern means you can
# just write `Settings.crt_enabled = true` from anywhere and the change
# is immediately applied and persisted.

var crt_enabled: bool = true:
	set(value):
		crt_enabled = value
		crt_changed.emit(value)
		_save()

var window_scale: int = 2:
	set(value):
		window_scale = clampi(value, 1, 3)
		_apply_window_scale()
		_save()

var sfx_volume: float = 1.0:
	set(value):
		sfx_volume = clampf(value, 0.0, 1.0)
		_apply_bus_volume("SFX", sfx_volume)
		_save()

var music_volume: float = 0.8:
	set(value):
		music_volume = clampf(value, 0.0, 1.0)
		_apply_bus_volume("Music", music_volume)
		_save()

var muted: bool = false:
	set(value):
		muted = value
		# bus index 0 is always the Master bus
		AudioServer.set_bus_mute(0, muted)
		_save()

var tutorial_seen: bool = false:
	set(value):
		tutorial_seen = value
		_save()

var fullscreen: bool = false:
	set(value):
		fullscreen = value
		_apply_fullscreen()
		_save()


func _ready() -> void:
	_load()
	_apply_bindings()
	_apply_window_scale()
	_apply_fullscreen()
	_apply_bus_volume("SFX", sfx_volume)
	_apply_bus_volume("Music", music_volume)
	AudioServer.set_bus_mute(0, muted)


# ============================================================
# INPUT BINDING
# ============================================================

# apply all bindings to Godot's InputMap. this clears existing key events
# for each action and adds the custom binding (plus arrow key extras).
func _apply_bindings() -> void:
	if input_bindings.is_empty():
		input_bindings = DEFAULT_KEYS.duplicate()
	for action in REBINDABLE_ACTIONS:
		if not input_bindings.has(action):
			input_bindings[action] = DEFAULT_KEYS[action]
		# remove existing keyboard events (preserve non-keyboard events like mouse)
		for event in InputMap.action_get_events(action):
			if event is InputEventKey:
				InputMap.action_erase_event(action, event)
		# add the player's custom binding
		var key_event := InputEventKey.new()
		key_event.physical_keycode = input_bindings[action]
		InputMap.action_add_event(action, key_event)
		# add arrow key alternative for movement actions
		if ARROW_EXTRAS.has(action):
			var arrow_event := InputEventKey.new()
			arrow_event.physical_keycode = ARROW_EXTRAS[action]
			InputMap.action_add_event(action, arrow_event)


func set_binding(action: String, keycode: Key) -> void:
	input_bindings[action] = keycode
	_apply_bindings()
	_save()


func reset_bindings() -> void:
	input_bindings = DEFAULT_KEYS.duplicate()
	_apply_bindings()
	_save()


# ============================================================
# DISPLAY
# ============================================================

func _apply_window_scale() -> void:
	if fullscreen:
		return
	# read the base viewport size from project settings
	var base_w := ProjectSettings.get_setting("display/window/size/viewport_width") as int
	var base_h := ProjectSettings.get_setting("display/window/size/viewport_height") as int
	var win := get_window()
	win.size = Vector2i(base_w * window_scale, base_h * window_scale)
	# center the window on screen after resizing
	var screen_size := DisplayServer.screen_get_size()
	win.position = (screen_size - win.size) / 2


func _apply_fullscreen() -> void:
	if fullscreen:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		_apply_window_scale()


# ============================================================
# AUDIO
# ============================================================

# convert linear volume (0.0-1.0) to decibels for the audio bus.
# linear_to_db handles the logarithmic curve so 0.5 feels like "half volume."
func _apply_bus_volume(bus_name: String, volume: float) -> void:
	var idx := AudioServer.get_bus_index(bus_name)
	if idx >= 0:
		AudioServer.set_bus_volume_db(idx, linear_to_db(volume))


# ============================================================
# PERSISTENCE
# ============================================================
# binary format: fields are written in a fixed order.
# the _load() function uses position checks to handle older save files
# that may not have all fields.

func _save() -> void:
	if _loading:
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_8(1 if crt_enabled else 0)
		file.store_8(window_scale)
		file.store_float(sfx_volume)
		file.store_float(music_volume)
		file.store_8(1 if muted else 0)
		file.store_8(1 if tutorial_seen else 0)
		file.store_8(1 if fullscreen else 0)
		for action in REBINDABLE_ACTIONS:
			file.store_32(input_bindings.get(action, DEFAULT_KEYS[action]))


func _load() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file:
		# _loading flag prevents setter -> _save() loops
		_loading = true
		crt_enabled = file.get_8() == 1
		window_scale = file.get_8()
		# position checks handle save files from older versions
		if file.get_position() < file.get_length():
			sfx_volume = file.get_float()
			music_volume = file.get_float()
			muted = file.get_8() == 1
		if file.get_position() < file.get_length():
			tutorial_seen = file.get_8() == 1
			fullscreen = file.get_8() == 1
		if file.get_position() < file.get_length():
			for action in REBINDABLE_ACTIONS:
				if file.get_position() + 4 <= file.get_length():
					input_bindings[action] = file.get_32()
		_loading = false
