extends Node

const SAVE_PATH := "user://highscore.dat"

var best: int = 0


func _ready() -> void:
	_load()


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
	if file:
		file.store_32(best)


func _load() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file:
		best = file.get_32()
