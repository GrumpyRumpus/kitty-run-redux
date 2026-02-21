extends Control

@onready var size_option: OptionButton = $MarginContainer/VBoxContainer/TabContainer/Video/SizeOption
@onready var vhs_checkbox: CheckBox = $MarginContainer/VBoxContainer/TabContainer/Video/VHSCheckBox
@onready var sfx_slider: HSlider = $MarginContainer/VBoxContainer/TabContainer/Sound/SFXSlider
@onready var music_slider: HSlider = $MarginContainer/VBoxContainer/TabContainer/Sound/MusicSlider
@onready var mute_checkbox: CheckBox = $MarginContainer/VBoxContainer/TabContainer/Sound/MuteCheckBox
@onready var high_score_value: Label = $MarginContainer/VBoxContainer/TabContainer/Data/HighScoreValue
@onready var reset_score_button: Button = $MarginContainer/VBoxContainer/TabContainer/Data/ResetScoreButton


func _ready() -> void:
	size_option.selected = Settings.window_scale - 1
	vhs_checkbox.button_pressed = Settings.vhs_enabled
	sfx_slider.value = Settings.sfx_volume
	music_slider.value = Settings.music_volume
	mute_checkbox.button_pressed = Settings.muted
	_update_high_score()


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


func _on_reset_score_pressed() -> void:
	HighScore.reset()
	_update_high_score()


func _update_high_score() -> void:
	var best := HighScore.get_high_score()
	high_score_value.text = str(best) if best > 0 else "---"
	reset_score_button.disabled = best == 0
