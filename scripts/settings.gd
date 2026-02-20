extends Node

signal vhs_changed(enabled: bool)

const SAVE_PATH := "user://settings.dat"

var vhs_enabled: bool = true:
	set(value):
		vhs_enabled = value
		vhs_changed.emit(value)
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
		AudioServer.set_bus_mute(0, muted)
		_save()


func _ready() -> void:
	_load()
	_apply_window_scale()
	_apply_bus_volume("SFX", sfx_volume)
	_apply_bus_volume("Music", music_volume)
	AudioServer.set_bus_mute(0, muted)


func _apply_window_scale() -> void:
	var base_w := ProjectSettings.get_setting("display/window/size/viewport_width") as int
	var base_h := ProjectSettings.get_setting("display/window/size/viewport_height") as int
	var win := get_window()
	win.size = Vector2i(base_w * window_scale, base_h * window_scale)
	# center window on screen
	var screen_size := DisplayServer.screen_get_size()
	win.position = (screen_size - win.size) / 2


func _apply_bus_volume(bus_name: String, volume: float) -> void:
	var idx := AudioServer.get_bus_index(bus_name)
	if idx >= 0:
		AudioServer.set_bus_volume_db(idx, linear_to_db(volume))


func _save() -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_8(1 if vhs_enabled else 0)
		file.store_8(window_scale)
		file.store_float(sfx_volume)
		file.store_float(music_volume)
		file.store_8(1 if muted else 0)


func _load() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file:
		vhs_enabled = file.get_8() == 1
		window_scale = file.get_8()
		if file.get_position() < file.get_length():
			sfx_volume = file.get_float()
			music_volume = file.get_float()
			muted = file.get_8() == 1
