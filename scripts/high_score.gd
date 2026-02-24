# High score persistence (autoload singleton)
#
# Saves and loads the best score to a binary file. Uses Godot's "user://"
# path which maps to an OS-specific app data directory:
#   - Windows: %APPDATA%/Godot/app_userdata/<project>/
#   - Linux:   ~/.local/share/godot/app_userdata/<project>/
#   - macOS:   ~/Library/Application Support/Godot/app_userdata/<project>/
#
# The file is just a single 32-bit unsigned integer. Binary is used instead
# of JSON or ConfigFile because the data is trivial -- no need for a
# human-readable format for one number.
#
# submit_score() returns true if the score is a new best, which the game
# controller uses to show "NEW BEST!" on the game-over screen.
extends Node

const SAVE_PATH := "user://highscore.dat"

var best: int = 0


func _ready() -> void:
	_load()


# returns true if this score beats the previous best
func submit_score(score: int) -> bool:
	if score > best:
		best = score
		_save()
		return true
	return false


func get_high_score() -> int:
	return best


func reset() -> void:
	best = 0
	_save()


func _save() -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		# log the error but don't crash -- the game can continue without saving
		push_warning("HighScore: failed to save -- %s" % error_string(FileAccess.get_open_error()))
		return
	file.store_32(best)


func _load() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file:
		best = file.get_32()
