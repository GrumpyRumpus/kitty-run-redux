# Music manager (autoload singleton)
#
# Handles background music across scenes. As an autoload, it persists when
# scenes change, so music can play continuously across the menu->game
# transition without restarting.
#
# PROCESS_MODE_ALWAYS ensures music keeps playing when the game is paused
# (e.g., during the pause menu).
#
# play_track() checks if the requested track is already playing to avoid
# restarting music when the same scene is reloaded (e.g., game restart).
extends AudioStreamPlayer

var menu_track := preload("res://assets/music/flowerbed_fields.ogg")
var game_track := preload("res://assets/music/happy_tune.mp3")


func _ready() -> void:
	# route through the Music audio bus (volume controlled by Settings)
	bus = &"Music"
	# keep playing during pause screens
	process_mode = Node.PROCESS_MODE_ALWAYS
	# enable looping on both tracks
	menu_track.loop = true
	game_track.loop = true


# only switch tracks if we're not already playing the requested one
func play_track(track: AudioStream) -> void:
	if stream == track and playing:
		return
	stream = track
	play()


func play_menu() -> void:
	play_track(menu_track)


func play_game() -> void:
	play_track(game_track)
